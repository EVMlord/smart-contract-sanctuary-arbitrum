// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IMarginBank.sol";
import "./interfaces/IEndpoint.sol";
import "./interfaces/ITradingState.sol";

contract MarginBank is IMarginBank, Initializable, Ownable2StepUpgradeable {
    using SafeERC20 for IERC20;

    uint256 constant LIQUIDATION_FEE = 1e6; // $1
    uint256 constant WITHDRAW_FEE = 1e6; // $1

    IERC20 public usdc;

    // @token => @account => amount
    mapping(address => uint256) public balances;
    uint256 public totalBalance;
    uint256 public sequencerFee;

    address public endpoint;
    ITradingState public traingState;

    modifier onlyEndpoint() {
        require(msg.sender == endpoint, "Unauthorized");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _endpoint, address _tradingState, address _usdc) external initializer {
        if (_endpoint == address(0) || _tradingState == address(0) || _usdc == address(0)) {
            revert ZeroAddress();
        }
        __Ownable_init(0x962B5B9a4D512c21512Bf24197C94E199A6ce8c5);
        endpoint = _endpoint;
        traingState = ITradingState(_tradingState);
        usdc = IERC20(_usdc);
    }

    // VIEWS

    function getHealth(address _account) public view returns (int256 _health) {
        uint256 _balance = balances[_account];
        int256 _pnl = traingState.getUnRealizedPnl(_account);
        _health = int256(_balance) + _pnl;
    }

    function isUnderMaintenance(address _account) public view returns (bool) {
        return getHealth(_account) < 0;
    }

    function handleDepositTransfer(address _account, uint256 _amount) external onlyEndpoint {
        balances[_account] += _amount;
        totalBalance += _amount;
        usdc.safeTransferFrom(endpoint, address(this), _amount);
        emit Deposited(_account, _amount);
    }

    function withdrawCollateral(IEndpoint.WithdrawCollateral memory _txn) external virtual onlyEndpoint {
        if (_txn.account == address(0)) {
            revert ZeroAddress();
        }

        if (balances[_txn.account] < _txn.amount) {
            revert InsufficientFunds();
        }

        uint256 _balance = balances[_txn.account];
        int256 _pnl = traingState.getUnRealizedPnl(_txn.account);
        if (int256(_balance) + _pnl + int256(WITHDRAW_FEE) < int256(_txn.amount)) {
            revert InsufficientFunds();
        }
        chargeFee(_txn.account, WITHDRAW_FEE);
        balances[_txn.account] -= _txn.amount;
        totalBalance -= _txn.amount;

        IERC20(_txn.token).safeTransfer(_txn.account, _txn.amount);
        emit Withdrawn(_txn.account, _txn.amount);
    }

    function liquidate(IEndpoint.Liquidate calldata _txn) external onlyEndpoint {
        if (!isUnderMaintenance(_txn.account)) {
            revert NotUnderMaintenance();
        }
        chargeFee(_txn.account, LIQUIDATION_FEE);
        // TODO:
    }

    // ADMIN
    function setEndpoint(address _endpoint) public onlyOwner {
        if (_endpoint == address(0)) {
            revert ZeroAddress();
        }
        endpoint = _endpoint;
        emit EndpointSet(_endpoint);
    }

    function setUSDC(address _usdc) external onlyOwner {
        if (_usdc == address(0)) {
            revert ZeroAddress();
        }
        usdc = IERC20(_usdc);
    }

    // INTERNALS

    function chargeFee(address _account, uint256 _fee) internal {
        balances[_account] -= _fee;
        sequencerFee += _fee;
    }

    function claimTradeFees() external pure {
        /// @dev todo implement
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "./OwnableUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable2Step
    struct Ownable2StepStorage {
        address _pendingOwner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable2Step")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant Ownable2StepStorageLocation = 0x237e158222e3e6968b72b9db0d8043aacf074ad9f650f0d1606b4d82ee432c00;

    function _getOwnable2StepStorage() private pure returns (Ownable2StepStorage storage $) {
        assembly {
            $.slot := Ownable2StepStorageLocation
        }
    }

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    function __Ownable2Step_init() internal onlyInitializing {
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        return $._pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        $._pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        delete $._pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ITradingState {
    function getUnRealizedPnl(address _account) external view returns(int256 _value);
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
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