// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EndpointGatedUpgradeable} from "../endpoint/EndpointGatedUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeCast} from "../lib/SafeCast.sol";
import {MathUtils} from "../lib/MathUtils.sol";
import {Constants} from "../lib/Constants.sol";
import "../interfaces/IPerpEngine.sol";

contract PerpEngine is IPerpEngine, Initializable, EndpointGatedUpgradeable {
    using SafeCast for uint256;
    using SafeCast for int256;

    IMarginBank public bank;
    IPriceFeed public priceFeed;
    IFundingRateManager public fundingManager;
    IFeeCalculator public feeCalculator;

    IERC20Metadata public USDC;

    address[] internal marketIds;

    mapping(address => IOffchainBook) public markets;
    mapping(address => bool) public isListed;
    mapping(address => bool) internal canApplyDeltas;

    mapping(address market => State) public states;
    mapping(address market => mapping(address account => Balance)) public balances;

    function initialize(
        address _initialOwner,
        address _endpoint,
        address _bank,
        address _priceFeed,
        address _fundingManager,
        address _feeCalculator,
        address _usdc
    ) external initializer {
        if (_initialOwner == address(0)) revert ZeroAddress();
        if (_endpoint == address(0)) revert ZeroAddress();
        if (_bank == address(0)) revert ZeroAddress();
        if (_priceFeed == address(0)) revert ZeroAddress();
        if (_fundingManager == address(0)) revert ZeroAddress();
        // if (_feeCalculator == address(0)) revert ZeroAddress();
        if (_usdc == address(0)) revert ZeroAddress();

        __Ownable_init(_initialOwner);
        setEndpoint(_endpoint);

        bank = IMarginBank(_bank);
        priceFeed = IPriceFeed(_priceFeed);
        fundingManager = IFundingRateManager(_fundingManager);
        feeCalculator = IFeeCalculator(_feeCalculator);
        USDC = IERC20Metadata(_usdc);

        canApplyDeltas[_endpoint] = true;
        canApplyDeltas[_bank] = true;
    }

    // =============== VIEWS FUNCTIONS ===============
    function getMarketIds() external view returns (address[] memory) {
        return marketIds;
    }

    function getConfig() external view returns (address, address, address, address) {
        return (address(bank), address(priceFeed), address(fundingManager), address(feeCalculator));
    }

    function getOffchainBook(address _market) external view returns (address) {
        return address(markets[_market]);
    }

    function getBalance(address _market, address _account) public view returns (Balance memory) {
        Balance memory _balance = balances[_market][_account];
        _updateBalance(_market, states[_market], _balance, 0, 0);
        return _balance;
    }

    function getBalanceAmount(address _market, address _account) external view returns (int256) {
        return getBalance(_market, _account).amount;
    }

    function getUnRealizedPnl(address[] calldata _markets, address _account)
        external
        view
        returns (int256 _unRealizedPnl)
    {
        uint256 _length = _markets.length;
        for (uint256 _i = 0; _i < _length;) {
            address _market = _markets[_i];
            (, Balance memory _balance) = _getStatesAndBalances(_market, _account);
            _unRealizedPnl += _calcUnRealizedPnl(_market, _balance);
            unchecked {
                ++_i;
            }
        }
    }

    function getUnRealizedPnl(address _account) external view returns (int256 _unRealizedPnl) {
        uint256 _length = marketIds.length;
        for (uint256 _i = 0; _i < _length;) {
            address _market = marketIds[_i];
            (, Balance memory _balance) = _getStatesAndBalances(_market, _account);
            _unRealizedPnl += _calcUnRealizedPnl(_market, _balance);
            unchecked {
                ++_i;
            }
        }
    }

    // =============== USED FUNCTIONS ===============
    function accrueFunding(address _market) external onlyEndpoint returns (int256) {
        State memory _state = states[_market];
        (State memory _newState, int256 _fundingIndex) = _accrueFunding(_market, _state);
        states[_market] = _newState;
        return _fundingIndex;
    }

    function applyDeltas(MarketDelta[] calldata _deltas) external {
        _checkCanApplyDeltas();
        for (uint32 i = 0; i < _deltas.length; i++) {
            address _market = _deltas[i].market;
            if ((_deltas[i].amountDelta == 0 && _deltas[i].quoteDelta == 0)) {
                continue;
            }

            address _account = _deltas[i].account;
            int256 _amountDelta = _deltas[i].amountDelta;
            int256 _quoteDelta = _deltas[i].quoteDelta;

            State memory _state = states[_market];
            Balance memory _balance = balances[_market][_account];

            _updateBalance(_market, _state, _balance, _amountDelta, _quoteDelta);

            states[_market] = _state;
            balances[_market][_account] = _balance;
        }
    }

    function settlePnl(address[] memory _markets, address _account) external returns (int256 _totalSettled) {
        _checkCanApplyDeltas();
        uint256 _length = _markets.length;
        for (uint256 _i = 0; _i < _length;) {
            address _market = _markets[_i];
            (int256 _canSettle, State memory _state, Balance memory _balance) = _getSettlementState(_market, _account);

            _state.availableSettle -= _canSettle;
            _balance.quoteAmount -= _canSettle;

            _totalSettled += _canSettle;

            states[_market] = _state;
            balances[_market][_account] = _balance;

            unchecked {
                ++_i;
            }
        }

        return _totalSettled;
    }

    /// @dev todo implement after testnet release
    function socializeAccount(address _account, int256 _insurance) external returns (int256) {}

    // =============== RESTRICTED ===============
    function addMarket(
        IOffchainBook _book,
        IOffchainBook.RiskStore memory _riskStore,
        IOffchainBook.FeeStore memory _feeStore,
        address _indexToken,
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize
    ) external onlyOwner {
        if (address(_book) == address(0)) revert ZeroAddress();
        if (_indexToken == address(0)) revert ZeroAddress();
        if (isListed[_indexToken]) revert DuplicateMarket();

        _book.initialize(
            owner(),
            address(getEndpoint()),
            this,
            _indexToken,
            address(USDC),
            _maxLeverage,
            _minSize,
            _tickSize,
            _stepSize
        );
        _book.modifyRiskStore(_riskStore);
        _book.modifyFeeStore(_feeStore);

        markets[_indexToken] = _book;
        isListed[_indexToken] = true;
        canApplyDeltas[address(_book)] = true;
        marketIds.push(_indexToken);

        emit MarketAdded(_indexToken, address(_book));
    }

    function updateMarket(bytes calldata _params) external onlyOwner {
        UpdateMarketTx memory _tx = abi.decode(_params, (UpdateMarketTx));
        IOffchainBook _book = markets[_tx.market];
        _book.modifyMarket(_tx.maxLeverage, _tx.minSize, _tx.tickSize, _tx.stepSize);
        _book.modifyRiskStore(_tx.riskStore);
        _book.modifyFeeStore(_tx.feeStore);
    }

    function setBank(address _bank) external onlyOwner {
        if (_bank == address(0)) revert ZeroAddress();
        bank = IMarginBank(_bank);
        emit BankSet(_bank);
    }

    function setPriceFeed(address _priceFeed) external onlyOwner {
        if (_priceFeed == address(0)) revert ZeroAddress();
        priceFeed = IPriceFeed(_priceFeed);
        emit PriceFeedSet(_priceFeed);
    }

    function setFundingManager(address _fundingManager) external onlyOwner {
        if (_fundingManager == address(0)) revert ZeroAddress();
        fundingManager = IFundingRateManager(_fundingManager);
        emit FundingRateManagerSet(_fundingManager);
    }

    function setFeeCalculator(address _feeCalculator) external onlyOwner {
        if (_feeCalculator == address(0)) revert ZeroAddress();
        feeCalculator = IFeeCalculator(_feeCalculator);
        emit FeeCalculatorSet(_feeCalculator);
    }

    // =============== INTERNAL FUNCTIONS ===============
    function _updateBalance(
        address _market,
        State memory _state,
        Balance memory _balance,
        int256 _amountDelta,
        int256 _quoteDelta
    ) internal view {
        (State memory _newState, int256 _fundingIndex) = _accrueFunding(_market, _state);
        _state = _newState;
        {
            int256 _fundingDiff = _fundingIndex - _balance.fundingIndex;
            int256 _indexPrice = priceFeed.getIndexPrice(_market).toInt256();
            int256 _fundingFee =
                _fundingDiff * _balance.amount * _indexPrice / Constants.PRECISION / Constants.QUOTE_PRECISION;
            _quoteDelta = _quoteDelta - _fundingFee;
        }

        _balance.amount += _amountDelta;
        _balance.quoteAmount += _quoteDelta;
        _balance.fundingIndex = _fundingIndex;
    }

    function _accrueFunding(address _market, State memory _state) internal view returns (State memory, int256) {
        int256 _now = block.timestamp.toInt256();
        int256 _lastAccrualFundingTime = _state.lastAccrualFundingTime;
        int256 _fundingIndex = _state.fundingIndex;
        int256 _fundingInterval = fundingManager.FUNDING_INTERVAL().toInt256();
        if (_lastAccrualFundingTime == 0) {
            _lastAccrualFundingTime = (_now / _fundingInterval) * _fundingInterval;
            _fundingIndex = fundingManager.lastFundingRate(_market);
        } else {
            int256 _nInterval = (_now - _lastAccrualFundingTime) / _fundingInterval;
            _fundingIndex += _nInterval * fundingManager.lastFundingRate(_market);
            _lastAccrualFundingTime += _nInterval * _fundingInterval;
        }
        _state.fundingIndex = _fundingIndex;
        _state.lastAccrualFundingTime = _lastAccrualFundingTime;
        return (_state, _fundingIndex);
    }

    function _getStatesAndBalances(address _market, address _account)
        internal
        view
        returns (State memory, Balance memory)
    {
        State memory _state = states[_market];
        Balance memory _balance = balances[_market][_account];
        /// @dev todo implement
        _updateBalance(_market, _state, _balance, 0, 0);
        return (_state, _balance);
    }

    function _calcUnRealizedPnl(address _market, Balance memory _balance) internal view returns (int256) {
        uint256 _markPrice = priceFeed.getMarkPrice(_market);
        if (_balance.quoteAmount == 0) {
            return 0;
        }
        uint256 _missingDecimals = Constants.VALUE_DECIMALS - Constants.QUOTE_TOKEN_DECIMALS;
        /// @dev round to quote token decimals
        return (
            (_balance.amount * _markPrice.toInt256()) + (_balance.quoteAmount * (10 ** _missingDecimals).toInt256())
        ) / (10 ** _missingDecimals).toInt256();
    }

    function _getSettlementState(address _market, address _account)
        internal
        view
        returns (int256 _canSettle, State memory _state, Balance memory _balance)
    {
        (_state, _balance) = _getStatesAndBalances(_market, _account);
        _canSettle = _min(_balance.quoteAmount, _state.availableSettle);
    }

    function _checkCanApplyDeltas() internal view {
        if (!canApplyDeltas[msg.sender]) revert Unauthorized();
    }

    function _min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IEndpoint} from "../interfaces/IEndpoint.sol";

contract EndpointGatedUpgradeable is OwnableUpgradeable {
    IEndpoint private endpoint;

    modifier onlyEndpoint() {
        if (msg.sender != address(endpoint)) revert Unauthorized();
        _;
    }

    // =============== VIEWS FUNCTIONS ===============
    function getEndpoint() public view returns (IEndpoint) {
        return endpoint;
    }

    // =============== USER FUNCTIONS ===============
    function setEndpoint(address _endpoint) public onlyOwner {
        if (_endpoint == address(0)) revert ZeroAddress();
        endpoint = IEndpoint(_endpoint);
        emit EndpointSet(_endpoint);
    }

    // =============== ERRORS ===============
    error ZeroAddress();
    error Unauthorized();

    // =============== EVENTS ===============
    event EndpointSet(address _endpoint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20Metadata} from "../token/ERC20/extensions/IERC20Metadata.sol";

pragma solidity >=0.8.0;

library SafeCast {
    error Overflow();

    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert Overflow();
        }
        return uint256(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert Overflow();
        }
        return int256(value);
    }
}

pragma solidity >= 0.8.0;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

library MathUtils {
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a > b ? a - b : b - a;
        }
    }

    function zeroCapSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a > b ? a - b : 0;
        }
    }

    function frac(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        return FixedPointMathLib.mulDiv(x, y, denominator);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /// @dev a + (b - c) * x / y
    function addThenSubWithFraction(uint256 orig, uint256 add, uint256 sub, uint256 num, uint256 denum)
        internal
        pure
        returns (uint256)
    {
        return zeroCapSub(orig + frac(add, num, denum), frac(sub, num, denum));
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     * extract from OZ Math
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

library Constants {
    uint256 constant VALUE_DECIMALS = 30;
    uint256 constant QUOTE_TOKEN_DECIMALS = 6;

    int256 constant TAKER_SEQUENCER_FEE = 1e5; // 0.1 USDC
    int128 constant MAX_LEVERAGE = 50; // 50x

    uint256 constant VALUE_PRECISION = 10 ** VALUE_DECIMALS;
    int256 constant FEE_PRECISION = 1e10;
    int256 constant PRECISION = 1e18;
    int256 constant QUOTE_PRECISION = 1e18;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IOffchainBook} from "./IOffchainBook.sol";
import {IMarginBank} from "./IMarginBank.sol";
import {IPriceFeed} from "./IPriceFeed.sol";
import {IFundingRateManager} from "./IFundingRateManager.sol";
import {IFeeCalculator} from "./IFeeCalculator.sol";

interface IPerpEngine {
    /// @dev data of market.
    struct State {
        int256 availableSettle;
        int256 fundingIndex;
        int256 lastAccrualFundingTime;
    }

    /// @dev balance of user in market
    struct Balance {
        int256 amount;
        int256 quoteAmount;
        int256 fundingIndex;
    }

    struct MarketDelta {
        address market;
        address account;
        int256 amountDelta;
        int256 quoteDelta;
    }

    struct UpdateMarketTx {
        address market;
        int128 maxLeverage;
        int128 minSize;
        int128 tickSize;
        int128 stepSize;
        IOffchainBook.RiskStore riskStore;
        IOffchainBook.FeeStore feeStore;
    }

    // =============== FUNCTIONS ===============
    function addMarket(
        IOffchainBook _book,
        IOffchainBook.RiskStore memory _risk,
        IOffchainBook.FeeStore memory _fee,
        address _indexToken,
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize
    ) external;
    function updateMarket(bytes calldata _params) external;
    function applyDeltas(MarketDelta[] calldata _deltas) external;
    function settlePnl(address[] memory _markets, address _account) external returns (int256 _totalSettled);
    function socializeAccount(address _account, int256 _insurance) external returns (int256);
    function accrueFunding(address _market) external returns (int256);

    // =============== VIEWS ===============
    function getMarketIds() external view returns (address[] memory);
    function getConfig()
        external
        view
        returns (address _bank, address _priceFeed, address _fundingManager, address _feeCalculator);
    function getOffchainBook(address _market) external view returns (address);
    function getBalance(address _market, address _account) external view returns (Balance memory);
    function getBalanceAmount(address _market, address _account) external view returns (int256);
    function getUnRealizedPnl(address[] calldata _markets, address _account)
        external
        view
        returns (int256 _unRealizedPnl);
    function getUnRealizedPnl(address _account) external view returns (int256 _unRealizedPnl);

    // =============== ERRORS ===============
    error DuplicateMarket();
    error InvalidOffchainBook();
    error InvalidDecimals();

    // =============== EVENTS ===============
    event BankSet(address indexed _bank);
    event PriceFeedSet(address indexed _priceFeed);
    event FundingRateManagerSet(address indexed _fundingManager);
    event FeeCalculatorSet(address indexed _fundingManager);
    event MarketAdded(address indexed _indexToken, address indexed _book);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IOffchainBook} from "./IOffchainBook.sol";

interface IEndpoint {
    enum TransactionType {
        ExecuteSlowMode,
        UpdateFundingRate,
        WithdrawCollateral,
        MatchOrders,
        SettlePnl,
        ClaimExecutionFees,
        ClaimTradeFees,
        Liquidate
    }

    struct WithdrawCollateral {
        address account;
        uint64 nonce;
        address token;
        uint256 amount;
    }

    struct SignedWithdrawCollateral {
        WithdrawCollateral tx;
        bytes signature;
    }

    struct Liquidate {
        bytes[] priceData;
        address account;
        address market;
        uint64 nonce;
    }

    struct UpdateFundingRate {
        address[] markets;
        int256[] values;
    }

    struct Order {
        address account;
        int256 price;
        int256 amount;
        bool reduceOnly;
        uint64 nonce;
    }

    struct SignedOrder {
        Order order;
        bytes signature;
    }

    struct SignedMatchOrders {
        address market;
        SignedOrder taker;
        SignedOrder maker;
    }

    struct MatchOrders {
        address market;
        Order taker;
        Order maker;
    }

    struct SettlePnl {
        address[] markets;
        address account;
    }

    // =============== FUNCTIONS ===============
    function depositCollateral(address _account, uint256 _amount) external;
    function submitTransactions(bytes[] calldata _txs) external;
    function setMarginBank(address _marginBank) external;
    function setPerpEngine(address _perpEngine) external;
    function setFundingRateManager(address _fundingRateManager) external;
    function setPriceFeed(address _priceFeed) external;
    function setSequencer(address _sequencer) external;

    // =============== VIEWS ===============
    function getNonce(address account) external view returns (uint64);
    function getOrderDigest(Order memory _order) external view returns (bytes32);
    function getAllMarkets()
        external
        view
        returns (
            IOffchainBook.Market[] memory _markets,
            IOffchainBook.FeeStore[] memory _fees,
            IOffchainBook.RiskStore[] memory _risks
        );

    // =============== EVENTS ===============
    event MarginBankSet(address indexed _marginBank);
    event SequencerSet(address indexed _sequencer);
    event PerpEngineSet(address indexed _perpEngine);
    event FundingRateManagerSet(address indexed _fundingRateManager);
    event PriceFeedSet(address indexed _fundingRateManager);
    event SubmitTransactions();

    // =============== ERRORS ===============
    error Unauthorized();
    error ZeroAddress();
    error ZeroAmount();
    error InvalidNonce();
    error InvalidSignature();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an overflow.
    error RPowOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    mstore(0x00, 0xa37bfec9) // `ExpOverflow()`.
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k)
            );
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    mstore(0x00, 0x1615e638) // `LnWadUndefined()`.
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, x))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, x))))
                k := or(k, shl(4, lt(0xffff, shr(k, x))))
                k := or(k, shl(3, lt(0xff, shr(k, x))))
                k := or(k, shl(2, lt(0xf, shr(k, x))))
                k := sub(or(k, byte(shr(k, x), hex"00000101020202020303030303030303")), 96)
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x = int256(uint256(x << uint256(159 - k)) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                // 512-bit multiply `[p1 p0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = p1 * 2**256 + p0`.

                // Least significant 256 bits of the product.
                let p0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let p1 := sub(mm, add(p0, lt(mm, p0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(p1) {
                    if iszero(d) {
                        mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                        revert(0x1c, 0x04)
                    }
                    result := div(p0, d)
                    break
                }

                // Make sure the result is less than `2**256`. Also prevents `d == 0`.
                if iszero(gt(d, p1)) {
                    mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                    revert(0x1c, 0x04)
                }

                /*------------------- 512 by 256 division --------------------*/

                // Make division exact by subtracting the remainder from `[p1 p0]`.
                // Compute remainder using mulmod.
                let r := mulmod(x, y, d)
                // `t` is the least significant bit of `d`.
                // Always greater or equal to 1.
                let t := and(d, sub(0, d))
                // Divide `d` by `t`, which is a power of two.
                d := div(d, t)
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result :=
                    mul(
                        // Divide [p1 p0] by the factors of two.
                        // Shift in bits from `p1` into `p0`. For this we need
                        // to flip `t` such that it is `2**256 / t`.
                        or(mul(sub(p1, gt(r, p0)), add(div(sub(0, t), t), 1)), div(sub(p0, r), t)),
                        // inverse mod 2**256
                        mul(inv, sub(2, mul(d, inv)))
                    )
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                result := add(result, 1)
                if iszero(result) {
                    mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                mstore(0x00, 0xad251c27) // `MulDivFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                mstore(0x00, 0xad251c27) // `MulDivFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                mstore(0x00, 0x65244e4e) // `DivFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Exponentiate `x` to `y` by squaring, denominated in base `b`.
    /// Reverts if the computation overflows.
    function rpow(uint256 x, uint256 y, uint256 b) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(b, iszero(y)) // `0 ** 0 = 1`. Otherwise, `0 ** n = 0`.
            if x {
                z := xor(b, mul(xor(b, x), and(y, 1))) // `z = isEven(y) ? scale : x`
                let half := shr(1, b) // Divide `b` by 2.
                // Divide `y` by 2 every iteration.
                for { y := shr(1, y) } y { y := shr(1, y) } {
                    let xx := mul(x, x) // Store x squared.
                    let xxRound := add(xx, half) // Round to the nearest number.
                    // Revert if `xx + half` overflowed, or if `x ** 2` overflows.
                    if or(lt(xxRound, xx), shr(128, x)) {
                        mstore(0x00, 0x49f7642b) // `RPowOverflow()`.
                        revert(0x1c, 0x04)
                    }
                    x := div(xxRound, b) // Set `x` to scaled `xxRound`.
                    // If `y` is odd:
                    if and(y, 1) {
                        let zx := mul(z, x) // Compute `z * x`.
                        let zxRound := add(zx, half) // Round to the nearest number.
                        // If `z * x` overflowed or `zx + half` overflowed:
                        if or(xor(div(zx, x), z), lt(zxRound, zx)) {
                            // Revert if `x` is non-zero.
                            if iszero(iszero(x)) {
                                mstore(0x00, 0x49f7642b) // `RPowOverflow()`.
                                revert(0x1c, 0x04)
                            }
                        }
                        z := div(zxRound, b) // Return properly scaled `zxRound`.
                    }
                }
            }
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`. We check `y >= 2**(k + 8)`
            // but shift right by `k` bits to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the cube root of `x`.
    /// Credit to bout3fiddy and pcaversaccio under AGPLv3 license:
    /// https://github.com/pcaversaccio/snekmate/blob/main/src/utils/Math.vy
    function cbrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))

            z := div(shl(div(r, 3), shl(lt(0xf, shr(r, x)), 0xf)), xor(7, mod(r, 3)))

            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)

            z := sub(z, lt(div(x, mul(z, z)), z))
        }
    }

    /// @dev Returns the square root of `x`, denominated in `WAD`.
    function sqrtWad(uint256 x) internal pure returns (uint256 z) {
        unchecked {
            z = 10 ** 9;
            if (x <= type(uint256).max / 10 ** 36 - 1) {
                x *= 10 ** 18;
                z = 1;
            }
            z *= sqrt(x);
        }
    }

    /// @dev Returns the cube root of `x`, denominated in `WAD`.
    function cbrtWad(uint256 x) internal pure returns (uint256 z) {
        unchecked {
            z = 10 ** 12;
            if (x <= (type(uint256).max / 10 ** 36) * 10 ** 18 - 1) {
                if (x >= type(uint256).max / 10 ** 36) {
                    x *= 10 ** 18;
                    z = 10 ** 6;
                } else {
                    x *= 10 ** 36;
                    z = 1;
                }
            }
            z *= cbrt(x);
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 58)) {
                mstore(0x00, 0xaba0f2a2) // `FactorialOverflow()`.
                revert(0x1c, 0x04)
            }
            for { result := 1 } x { x := sub(x, 1) } { result := mul(result, x) }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    /// Returns 0 if `x` is zero.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, byte(shr(r, x), hex"00000101020202020303030303030303"))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        r = log2(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(shl(r, 1), x))
        }
    }

    /// @dev Returns the log10 of `x`.
    /// Returns 0 if `x` is zero.
    function log10(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 100000000000000000000000000000000000000)) {
                x := div(x, 100000000000000000000000000000000000000)
                r := 38
            }
            if iszero(lt(x, 100000000000000000000)) {
                x := div(x, 100000000000000000000)
                r := add(r, 20)
            }
            if iszero(lt(x, 10000000000)) {
                x := div(x, 10000000000)
                r := add(r, 10)
            }
            if iszero(lt(x, 100000)) {
                x := div(x, 100000)
                r := add(r, 5)
            }
            r := add(r, add(gt(x, 9), add(gt(x, 99), add(gt(x, 999), gt(x, 9999)))))
        }
    }

    /// @dev Returns the log10 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log10Up(uint256 x) internal pure returns (uint256 r) {
        r = log10(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(exp(10, r), x))
        }
    }

    /// @dev Returns the log256 of `x`.
    /// Returns 0 if `x` is zero.
    function log256(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(shr(3, r), lt(0xff, shr(r, x)))
        }
    }

    /// @dev Returns the log256 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log256Up(uint256 x) internal pure returns (uint256 r) {
        r = log256(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(shl(shl(3, r), 1), x))
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(sub(0, shr(255, x)), add(sub(0, shr(255, x)), x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(mul(xor(sub(y, x), sub(x, y)), sgt(x, y)), sub(y, x))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue)
        internal
        pure
        returns (uint256 z)
    {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, minValue), gt(minValue, x)))
            z := xor(z, mul(xor(z, maxValue), lt(maxValue, z)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, minValue), sgt(minValue, x)))
            z := xor(z, mul(xor(z, maxValue), slt(maxValue, z)))
        }
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            for { z := x } y {} {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IEndpoint} from "./IEndpoint.sol";
import {IPerpEngine} from "./IPerpEngine.sol";

interface IOffchainBook {
    struct OrderDigest {
        bytes32 taker;
        bytes32 maker;
    }

    struct Market {
        address indexToken;
        uint8 indexDecimals;
        address quoteToken;
        uint8 quoteDecimals;
        /// @dev max leverage of market, default 20x.
        int128 maxLeverage;
        /// @dev min size of position, ex 0.01 btc-usdc perp.
        int128 minSize;
        /// @dev min price increment of order, ex 1 usdc.
        int128 tickSize;
        /// @dev min size increment of order, ex 0.001 btc-usdc perp.
        int128 stepSize;
    }

    struct RiskStore {
        int64 longWeightInitial;
        int64 shortWeightInitial;
        int64 longWeightMaintenance;
        int64 shortWeightMaintenance;
    }

    struct FeeStore {
        int256 makerFees;
        int256 talkerFees;
    }

    // =============== FUNCTIONS ===============
    function initialize(
        address _owner,
        address _endpoint,
        IPerpEngine _engine,
        address _indexToken,
        address _quoteToken,
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize
    ) external;
    function claimTradeFees() external returns (int256 _feeAmount);
    function claimExecutionFees() external returns (int256 _feeAmount);
    function modifyMarket(int128 _maxLeverage, int128 _minSize, int128 _tickSize, int128 _stepSize) external;
    function modifyRiskStore(RiskStore calldata _risk) external;
    function modifyFeeStore(FeeStore calldata _fee) external;
    function matchOrders(IEndpoint.MatchOrders calldata _params) external;

    // =============== VIEWS ===============
    function getRiskStore() external view returns (RiskStore memory);
    function getFeeStore() external view returns (FeeStore memory);
    function getMarket() external view returns (Market memory);
    function getIndexToken() external view returns (address);
    function getQuoteToken() external view returns (address);
    function getMaxLeverage() external view returns (int128);
    function getFees() external view returns (uint256, uint256);

    // =============== ERRORS ===============
    error NotHealthy();
    error InvalidSignature();
    error InvalidOrderPrice();
    error InvalidOrderAmount();
    error OrderCannotBeMatched();
    error BadRiskStoreConfig();
    error BadFeeStoreConfig();
    error BadMarketConfig();
    error MaxLeverageTooHigh();

    // =============== EVENTS ===============
    event TradeFeeClaimed(int256 _feeAmount);
    event ExecutionFeeClaimed(int256 _feeAmount);
    event MarketModified(int128 _maxLeverage, int128 _minSize, int128 _tickSize, int128 _stepSize);
    event RiskStoreModified(RiskStore _risk);
    event FeeStoreModified(FeeStore _fee);
    event FillOrder(
        bytes32 indexed _digest,
        address indexed _account,
        int256 _price,
        int256 _amount,
        // whether this order is taking or making
        bool _isTaker,
        // amount paid in fees (in quote)
        int256 _feeAmount,
        // change in this account's base balance from this fill
        int256 _amountDelta,
        // change in this account's quote balance from this fill
        int256 _quoteAmountDelta
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IEndpoint.sol";

interface IMarginBank {
    function handleDepositTransfer(address _account, uint256 _amount) external;

    function withdrawCollateral(IEndpoint.WithdrawCollateral memory _txn) external;

    function liquidate(IEndpoint.Liquidate calldata _txn) external;

    function claimTradeFees() external;

    // EVENTS
    event Deposited(address indexed account, uint256 amount);
    event EndpointSet(address indexed endpoint);
    event Withdrawn(address indexed account, uint256 amount);

    // ERRORS
    error UnknownToken();
    error ZeroAddress();
    error InsufficientFunds();
    error NotUnderMaintenance();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAggregatorV3Interface} from "./IAggregatorV3Interface.sol";

interface IPriceFeed {
    enum PriceSource {
        Pyth,
        Chainlink
    }

    struct MarketConfig {
        /// @dev precision of base token
        uint256 baseUnits;
        /// @dev use chainlink or pyth oracle
        PriceSource priceSource;
        /// @dev chainlink price feed
        IAggregatorV3Interface chainlinkPriceFeed;
        /// @dev market id of pyth
        bytes32 pythId;
    }

    function configMarket(
        address _market,
        PriceSource _priceSource,
        IAggregatorV3Interface _chainlinkPriceFeed,
        bytes32 _pythId
    ) external;
    function setFundingRateManager(address _fundingRateManager) external;
    function updatePrice(bytes[] calldata _data) external payable;

    // =============== VIEW FUNCTIONS ===============
    function getIndexPrice(address _market) external view returns (uint256);
    function getMarkPrice(address _market) external view returns (uint256);

    // =============== ERRORS ===============
    error InvalidPythId();
    error UnknownMarket();

    // =============== EVENTS ===============
    event MarketAdded(address indexed _market);
    event FundingRateManagerSet(address indexed _fundingRateManager);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IFundingRateManager {
    // =============== FUNCTIONS ===============
    function addMarket(address _market, uint256 _startTime) external;
    function update(address[] calldata _markets, int256[] calldata _values) external;

    // =============== VIEWS ===============
    function PRECISION() external view returns (uint256);
    function FUNDING_INTERVAL() external view returns (uint256);

    function lastFundingRate(address _market) external view returns (int256);
    function nextFundingTime(address _market) external view returns (uint256);

    // =============== ERRORS ===============
    error Outdated();
    error OutOfRange();

    error DuplicateMarket();
    error MarketNotExits();
    error InvalidUpdateData();

    // =============== EVENTS ===============
    event MarketAdded(address indexed _market, uint256 _startTime);
    event ValueUpdated(address indexed _market, int256 _value);
    event FundingRateUpdated(address indexed _market, int256 _value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IFeeCalculator {
    function getFeeRate(address _market, address _account, bool _isTaker) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}