/**
 *Submitted for verification at Arbiscan on 2023-06-09
*/

/* Tribeone: Depot.sol
* Latest source (may be newer): https://github.com/TribeOneDefi/tribeone-v3-contracts/blob/master/contracts/Depot.sol
* Docs: https://docs.tribeone.io/contracts/Depot
*
* Contract Dependencies: 
*	- IAddressResolver
*	- IDepot
*	- MixinResolver
*	- Owned
*	- Pausable
*	- ReentrancyGuard
* Libraries: 
*	- SafeDecimalMath
*	- SafeMath
*
* MIT License
* ===========
*
* Copyright (c) 2023 Tribeone
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;

// https://docs.tribeone.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// Inheritance


// https://docs.tribeone.io/contracts/source/contracts/pausable
contract Pausable is Owned {
    uint public lastPauseTime;
    bool public paused;

    constructor() internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = now;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


// https://docs.tribeone.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getTribe(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// https://docs.tribeone.io/contracts/source/interfaces/itribe
interface ITribe {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableTribes(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Tribeone
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/iissuer
interface IIssuer {
    // Views

    function allNetworksDebtInfo()
        external
        view
        returns (
            uint256 debt,
            uint256 sharesSupply,
            bool isStale
        );

    function anyTribeOrHAKARateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableTribeCount() external view returns (uint);

    function availableTribes(uint index) external view returns (ITribe);

    function canBurnTribes(address account) external view returns (bool);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint debtBalance);

    function issuanceRatio() external view returns (uint);

    function lastIssueEvent(address account) external view returns (uint);

    function maxIssuableTribes(address issuer) external view returns (uint maxIssuable);

    function minimumStakeTime() external view returns (uint);

    function remainingIssuableTribes(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function tribes(bytes32 currencyKey) external view returns (ITribe);

    function getTribes(bytes32[] calldata currencyKeys) external view returns (ITribe[] memory);

    function tribesByAddress(address tribeAddress) external view returns (bytes32);

    function totalIssuedTribes(bytes32 currencyKey, bool excludeOtherCollateral) external view returns (uint);

    function transferableTribeoneAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid);

    function liquidationAmounts(address account, bool isSelfLiquidation)
        external
        view
        returns (
            uint totalRedeemed,
            uint debtToRemove,
            uint escrowToLiquidate,
            uint initialDebtBalance
        );

    // Restricted: used internally to Tribeone
    function addTribes(ITribe[] calldata tribesToAdd) external;

    function issueTribes(address from, uint amount) external;

    function issueTribesOnBehalf(
        address issueFor,
        address from,
        uint amount
    ) external;

    function issueMaxTribes(address from) external;

    function issueMaxTribesOnBehalf(address issueFor, address from) external;

    function burnTribes(address from, uint amount) external;

    function burnTribesOnBehalf(
        address burnForAddress,
        address from,
        uint amount
    ) external;

    function burnTribesToTarget(address from) external;

    function burnTribesToTargetOnBehalf(address burnForAddress, address from) external;

    function burnForRedemption(
        address deprecatedTribeProxy,
        address account,
        uint balance
    ) external;

    function setCurrentPeriodId(uint128 periodId) external;

    function liquidateAccount(address account, bool isSelfLiquidation)
        external
        returns (
            uint totalRedeemed,
            uint debtRemoved,
            uint escrowToLiquidate
        );

    function issueTribesWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external returns (bool rateInvalid);

    function burnTribesWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external returns (bool rateInvalid);

    function modifyDebtSharesForMigration(address account, uint amount) external;
}


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getTribe(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.tribes(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/mixinresolver
contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}


// https://docs.tribeone.io/contracts/source/interfaces/idepot
interface IDepot {
    // Views
    function fundsWallet() external view returns (address payable);

    function maxEthPurchase() external view returns (uint);

    function minimumDepositAmount() external view returns (uint);

    function tribesReceivedForEther(uint amount) external view returns (uint);

    function totalSellableDeposits() external view returns (uint);

    // Mutative functions
    function depositTribes(uint amount) external;

    function exchangeEtherForTribes() external payable returns (uint);

    function exchangeEtherForTribesAtRate(uint guaranteedRate) external payable returns (uint);

    function withdrawMyDepositedTribes() external;

    // Note: On mainnet no wHAKA has been deposited. The following functions are kept alive for testnet wHAKA faucets.
    function exchangeEtherForHAKA() external payable returns (uint);

    function exchangeEtherForHAKAAtRate(uint guaranteedRate, uint guaranteedTribeoneRate) external payable returns (uint);

    function exchangeTribesForHAKA(uint tribeAmount) external returns (uint);

    function tribeetixReceivedForEther(uint amount) external view returns (uint);

    function tribeetixReceivedForTribes(uint amount) external view returns (uint);

    function withdrawTribeone(uint amount) external;
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// Libraries


// https://docs.tribeone.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint a, uint b) internal pure returns (uint) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int x) internal pure returns (uint) {
        return uint(signedAbs(x));
    }
}


// https://docs.tribeone.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


pragma experimental ABIEncoderV2;

// https://docs.tribeone.io/contracts/source/interfaces/IDirectIntegration
interface IDirectIntegrationManager {
    struct ParameterIntegrationSettings {
        bytes32 currencyKey;
        address dexPriceAggregator;
        address atomicEquivalentForDexPricing;
        uint atomicExchangeFeeRate;
        uint atomicTwapWindow;
        uint atomicMaxVolumePerBlock;
        uint atomicVolatilityConsiderationWindow;
        uint atomicVolatilityUpdateThreshold;
        uint exchangeFeeRate;
        uint exchangeMaxDynamicFee;
        uint exchangeDynamicFeeRounds;
        uint exchangeDynamicFeeThreshold;
        uint exchangeDynamicFeeWeightDecay;
    }

    function getExchangeParameters(address integration, bytes32 key)
        external
        view
        returns (ParameterIntegrationSettings memory settings);

    function setExchangeParameters(
        address integration,
        bytes32[] calldata currencyKeys,
        ParameterIntegrationSettings calldata params
    ) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint[] calldata roundIds) external view returns (bool);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        );

    function effectiveAtomicValueAndRates(
        IDirectIntegrationManager.ParameterIntegrationSettings calldata sourceSettings,
        uint sourceAmount,
        IDirectIntegrationManager.ParameterIntegrationSettings calldata destinationSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings calldata usdSettings
    )
        external
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        );

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint);

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint numRounds,
        uint roundId
    ) external view returns (uint[] memory rates, uint[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory);

    function tribeTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool);

    function tribeTooVolatileForAtomicExchange(IDirectIntegrationManager.ParameterIntegrationSettings calldata settings)
        external
        view
        returns (bool);

    function rateWithSafetyChecks(bytes32 currencyKey)
        external
        returns (
            uint rate,
            bool broken,
            bool invalid
        );
}


// Inheritance


// Libraries


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/depot
contract Depot is Owned, Pausable, ReentrancyGuard, MixinResolver, IDepot {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 internal constant wHAKA = "wHAKA";
    bytes32 internal constant ETH = "ETH";

    /* ========== STATE VARIABLES ========== */

    // Address where the ether and Tribes raised for selling wHAKA is transfered to
    // Any ether raised for selling Tribes gets sent back to whoever deposited the Tribes,
    // and doesn't have anything to do with this address.
    address payable public fundsWallet;

    /* Stores deposits from users. */
    struct TribeDepositEntry {
        // The user that made the deposit
        address payable user;
        // The amount (in Tribes) that they deposited
        uint amount;
    }

    /* User deposits are sold on a FIFO (First in First out) basis. When users deposit
       tribes with us, they get added this queue, which then gets fulfilled in order.
       Conceptually this fits well in an array, but then when users fill an order we
       end up copying the whole array around, so better to use an index mapping instead
       for gas performance reasons.

       The indexes are specified (inclusive, exclusive), so (0, 0) means there's nothing
       in the array, and (3, 6) means there are 3 elements at 3, 4, and 5. You can obtain
       the length of the "array" by querying depositEndIndex - depositStartIndex. All index
       operations use safeAdd, so there is no way to overflow, so that means there is a
       very large but finite amount of deposits this contract can handle before it fills up. */
    mapping(uint => TribeDepositEntry) public deposits;
    // The starting index of our queue inclusive
    uint public depositStartIndex;
    // The ending index of our queue exclusive
    uint public depositEndIndex;

    /* This is a convenience variable so users and dApps can just query how much hUSD
       we have available for purchase without having to iterate the mapping with a
       O(n) amount of calls for something we'll probably want to display quite regularly. */
    uint public totalSellableDeposits;

    // The minimum amount of hUSD required to enter the FiFo queue
    uint public minimumDepositAmount = 50 * SafeDecimalMath.unit();

    // A cap on the amount of hUSD you can buy with ETH in 1 transaction
    uint public maxEthPurchase = 500 * SafeDecimalMath.unit();

    // If a user deposits a tribe amount < the minimumDepositAmount the contract will keep
    // the total of small deposits which will not be sold on market and the sender
    // must call withdrawMyDepositedTribes() to get them back.
    mapping(address => uint) public smallDeposits;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_TRIBEONEHUSD = "TribehUSD";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_TRIBEONEETIX = "Tribeone";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address payable _fundsWallet,
        address _resolver
    ) public Owned(_owner) Pausable() MixinResolver(_resolver) {
        fundsWallet = _fundsWallet;
    }

    /* ========== SETTERS ========== */

    function setMaxEthPurchase(uint _maxEthPurchase) external onlyOwner {
        maxEthPurchase = _maxEthPurchase;
        emit MaxEthPurchaseUpdated(maxEthPurchase);
    }

    /**
     * @notice Set the funds wallet where ETH raised is held
     * @param _fundsWallet The new address to forward ETH and Tribes to
     */
    function setFundsWallet(address payable _fundsWallet) external onlyOwner {
        fundsWallet = _fundsWallet;
        emit FundsWalletUpdated(fundsWallet);
    }

    /**
     * @notice Set the minimum deposit amount required to depoist hUSD into the FIFO queue
     * @param _amount The new new minimum number of hUSD required to deposit
     */
    function setMinimumDepositAmount(uint _amount) external onlyOwner {
        // Do not allow us to set it less than 1 dollar opening up to fractional desposits in the queue again
        require(_amount > SafeDecimalMath.unit(), "Minimum deposit amount must be greater than UNIT");
        minimumDepositAmount = _amount;
        emit MinimumDepositAmountUpdated(minimumDepositAmount);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Fallback function (exchanges ETH to hUSD)
     */
    function() external payable nonReentrant rateNotInvalid(ETH) notPaused {
        _exchangeEtherForTribes();
    }

    /**
     * @notice Exchange ETH to hUSD.
     */
    /* solhint-disable multiple-sends, reentrancy */
    function exchangeEtherForTribes()
        external
        payable
        nonReentrant
        rateNotInvalid(ETH)
        notPaused
        returns (
            uint // Returns the number of Tribes (hUSD) received
        )
    {
        return _exchangeEtherForTribes();
    }

    function _exchangeEtherForTribes() internal returns (uint) {
        require(msg.value <= maxEthPurchase, "ETH amount above maxEthPurchase limit");
        uint ethToSend;

        // The multiplication works here because exchangeRates().rateForCurrency(ETH) is specified in
        // 18 decimal places, just like our currency base.
        uint requestedToPurchase = msg.value.multiplyDecimal(exchangeRates().rateForCurrency(ETH));
        uint remainingToFulfill = requestedToPurchase;

        // Iterate through our outstanding deposits and sell them one at a time.
        for (uint i = depositStartIndex; remainingToFulfill > 0 && i < depositEndIndex; i++) {
            TribeDepositEntry memory deposit = deposits[i];

            // If it's an empty spot in the queue from a previous withdrawal, just skip over it and
            // update the queue. It's already been deleted.
            if (deposit.user == address(0)) {
                depositStartIndex = depositStartIndex.add(1);
            } else {
                // If the deposit can more than fill the order, we can do this
                // without touching the structure of our queue.
                if (deposit.amount > remainingToFulfill) {
                    // Ok, this deposit can fulfill the whole remainder. We don't need
                    // to change anything about our queue we can just fulfill it.
                    // Subtract the amount from our deposit and total.
                    uint newAmount = deposit.amount.sub(remainingToFulfill);
                    deposits[i] = TribeDepositEntry({user: deposit.user, amount: newAmount});

                    totalSellableDeposits = totalSellableDeposits.sub(remainingToFulfill);

                    // Transfer the ETH to the depositor. Send is used instead of transfer
                    // so a non payable contract won't block the FIFO queue on a failed
                    // ETH payable for tribes transaction. The proceeds to be sent to the
                    // tribeone foundation funds wallet. This is to protect all depositors
                    // in the queue in this rare case that may occur.
                    ethToSend = remainingToFulfill.divideDecimal(exchangeRates().rateForCurrency(ETH));

                    // We need to use send here instead of transfer because transfer reverts
                    // if the recipient is a non-payable contract. Send will just tell us it
                    // failed by returning false at which point we can continue.
                    if (!deposit.user.send(ethToSend)) {
                        fundsWallet.transfer(ethToSend);
                        emit NonPayableContract(deposit.user, ethToSend);
                    } else {
                        emit ClearedDeposit(msg.sender, deposit.user, ethToSend, remainingToFulfill, i);
                    }

                    // And the Tribes to the recipient.
                    // Note: Fees are calculated by the Tribe contract, so when
                    //       we request a specific transfer here, the fee is
                    //       automatically deducted and sent to the fee pool.
                    tribehUSD().transfer(msg.sender, remainingToFulfill);

                    // And we have nothing left to fulfill on this order.
                    remainingToFulfill = 0;
                } else if (deposit.amount <= remainingToFulfill) {
                    // We need to fulfill this one in its entirety and kick it out of the queue.
                    // Start by kicking it out of the queue.
                    // Free the storage because we can.
                    delete deposits[i];
                    // Bump our start index forward one.
                    depositStartIndex = depositStartIndex.add(1);
                    // We also need to tell our total it's decreased
                    totalSellableDeposits = totalSellableDeposits.sub(deposit.amount);

                    // Now fulfill by transfering the ETH to the depositor. Send is used instead of transfer
                    // so a non payable contract won't block the FIFO queue on a failed
                    // ETH payable for tribes transaction. The proceeds to be sent to the
                    // tribeone foundation funds wallet. This is to protect all depositors
                    // in the queue in this rare case that may occur.
                    ethToSend = deposit.amount.divideDecimal(exchangeRates().rateForCurrency(ETH));

                    // We need to use send here instead of transfer because transfer reverts
                    // if the recipient is a non-payable contract. Send will just tell us it
                    // failed by returning false at which point we can continue.
                    if (!deposit.user.send(ethToSend)) {
                        fundsWallet.transfer(ethToSend);
                        emit NonPayableContract(deposit.user, ethToSend);
                    } else {
                        emit ClearedDeposit(msg.sender, deposit.user, ethToSend, deposit.amount, i);
                    }

                    // And the Tribes to the recipient.
                    // Note: Fees are calculated by the Tribe contract, so when
                    //       we request a specific transfer here, the fee is
                    //       automatically deducted and sent to the fee pool.
                    tribehUSD().transfer(msg.sender, deposit.amount);

                    // And subtract the order from our outstanding amount remaining
                    // for the next iteration of the loop.
                    remainingToFulfill = remainingToFulfill.sub(deposit.amount);
                }
            }
        }

        // Ok, if we're here and 'remainingToFulfill' isn't zero, then
        // we need to refund the remainder of their ETH back to them.
        if (remainingToFulfill > 0) {
            msg.sender.transfer(remainingToFulfill.divideDecimal(exchangeRates().rateForCurrency(ETH)));
        }

        // How many did we actually give them?
        uint fulfilled = requestedToPurchase.sub(remainingToFulfill);

        if (fulfilled > 0) {
            // Now tell everyone that we gave them that many (only if the amount is greater than 0).
            emit Exchange("ETH", msg.value, "hUSD", fulfilled);
        }

        return fulfilled;
    }

    /* solhint-enable multiple-sends, reentrancy */

    /**
     * @notice Exchange ETH to hUSD while insisting on a particular rate. This allows a user to
     *         exchange while protecting against frontrunning by the contract owner on the exchange rate.
     * @param guaranteedRate The exchange rate (ether price) which must be honored or the call will revert.
     */
    function exchangeEtherForTribesAtRate(uint guaranteedRate)
        external
        payable
        rateNotInvalid(ETH)
        notPaused
        returns (
            uint // Returns the number of Tribes (hUSD) received
        )
    {
        require(guaranteedRate == exchangeRates().rateForCurrency(ETH), "Guaranteed rate would not be received");

        return _exchangeEtherForTribes();
    }

    function _exchangeEtherForHAKA() internal returns (uint) {
        // How many wHAKA are they going to be receiving?
        uint tribeetixToSend = tribeetixReceivedForEther(msg.value);

        // Store the ETH in our funds wallet
        fundsWallet.transfer(msg.value);

        // And send them the wHAKA.
        tribeone().transfer(msg.sender, tribeetixToSend);

        emit Exchange("ETH", msg.value, "wHAKA", tribeetixToSend);

        return tribeetixToSend;
    }

    /**
     * @notice Exchange ETH to wHAKA.
     */
    function exchangeEtherForHAKA()
        external
        payable
        rateNotInvalid(wHAKA)
        rateNotInvalid(ETH)
        notPaused
        returns (
            uint // Returns the number of wHAKA received
        )
    {
        return _exchangeEtherForHAKA();
    }

    /**
     * @notice Exchange ETH to wHAKA while insisting on a particular set of rates. This allows a user to
     *         exchange while protecting against frontrunning by the contract owner on the exchange rates.
     * @param guaranteedEtherRate The ether exchange rate which must be honored or the call will revert.
     * @param guaranteedTribeoneRate The tribeone exchange rate which must be honored or the call will revert.
     */
    function exchangeEtherForHAKAAtRate(uint guaranteedEtherRate, uint guaranteedTribeoneRate)
        external
        payable
        rateNotInvalid(wHAKA)
        rateNotInvalid(ETH)
        notPaused
        returns (
            uint // Returns the number of wHAKA received
        )
    {
        require(guaranteedEtherRate == exchangeRates().rateForCurrency(ETH), "Guaranteed ether rate would not be received");
        require(
            guaranteedTribeoneRate == exchangeRates().rateForCurrency(wHAKA),
            "Guaranteed tribeone rate would not be received"
        );

        return _exchangeEtherForHAKA();
    }

    function _exchangeTribesForHAKA(uint tribeAmount) internal returns (uint) {
        // How many wHAKA are they going to be receiving?
        uint tribeetixToSend = tribeetixReceivedForTribes(tribeAmount);

        // Ok, transfer the Tribes to our funds wallet.
        // These do not go in the deposit queue as they aren't for sale as such unless
        // they're sent back in from the funds wallet.
        tribehUSD().transferFrom(msg.sender, fundsWallet, tribeAmount);

        // And send them the wHAKA.
        tribeone().transfer(msg.sender, tribeetixToSend);

        emit Exchange("hUSD", tribeAmount, "wHAKA", tribeetixToSend);

        return tribeetixToSend;
    }

    /**
     * @notice Exchange hUSD for wHAKA
     * @param tribeAmount The amount of tribes the user wishes to exchange.
     */
    function exchangeTribesForHAKA(uint tribeAmount)
        external
        rateNotInvalid(wHAKA)
        notPaused
        returns (
            uint // Returns the number of wHAKA received
        )
    {
        return _exchangeTribesForHAKA(tribeAmount);
    }

    /**
     * @notice Exchange hUSD for wHAKA while insisting on a particular rate. This allows a user to
     *         exchange while protecting against frontrunning by the contract owner on the exchange rate.
     * @param tribeAmount The amount of tribes the user wishes to exchange.
     * @param guaranteedRate A rate (tribeone price) the caller wishes to insist upon.
     */
    function exchangeTribesForHAKAAtRate(uint tribeAmount, uint guaranteedRate)
        external
        rateNotInvalid(wHAKA)
        notPaused
        returns (
            uint // Returns the number of wHAKA received
        )
    {
        require(guaranteedRate == exchangeRates().rateForCurrency(wHAKA), "Guaranteed rate would not be received");

        return _exchangeTribesForHAKA(tribeAmount);
    }

    /**
     * @notice Allows the owner to withdraw wHAKA from this contract if needed.
     * @param amount The amount of wHAKA to attempt to withdraw (in 18 decimal places).
     */
    function withdrawTribeone(uint amount) external onlyOwner {
        tribeone().transfer(owner, amount);

        // We don't emit our own events here because we assume that anyone
        // who wants to watch what the Depot is doing can
        // just watch ERC20 events from the Tribe and/or Tribeone contracts
        // filtered to our address.
    }

    /**
     * @notice Allows a user to withdraw all of their previously deposited tribes from this contract if needed.
     *         Developer note: We could keep an index of address to deposits to make this operation more efficient
     *         but then all the other operations on the queue become less efficient. It's expected that this
     *         function will be very rarely used, so placing the inefficiency here is intentional. The usual
     *         use case does not involve a withdrawal.
     */
    function withdrawMyDepositedTribes() external {
        uint tribesToSend = 0;

        for (uint i = depositStartIndex; i < depositEndIndex; i++) {
            TribeDepositEntry memory deposit = deposits[i];

            if (deposit.user == msg.sender) {
                // The user is withdrawing this deposit. Remove it from our queue.
                // We'll just leave a gap, which the purchasing logic can walk past.
                tribesToSend = tribesToSend.add(deposit.amount);
                delete deposits[i];
                //Let the DApps know we've removed this deposit
                emit TribeDepositRemoved(deposit.user, deposit.amount, i);
            }
        }

        // Update our total
        totalSellableDeposits = totalSellableDeposits.sub(tribesToSend);

        // Check if the user has tried to send deposit amounts < the minimumDepositAmount to the FIFO
        // queue which would have been added to this mapping for withdrawal only
        tribesToSend = tribesToSend.add(smallDeposits[msg.sender]);
        smallDeposits[msg.sender] = 0;

        // If there's nothing to do then go ahead and revert the transaction
        require(tribesToSend > 0, "You have no deposits to withdraw.");

        // Send their deposits back to them (minus fees)
        tribehUSD().transfer(msg.sender, tribesToSend);

        emit TribeWithdrawal(msg.sender, tribesToSend);
    }

    /**
     * @notice depositTribes: Allows users to deposit tribes via the approve / transferFrom workflow
     * @param amount The amount of hUSD you wish to deposit (must have been approved first)
     */
    function depositTribes(uint amount) external {
        // Grab the amount of tribes. Will fail if not approved first
        tribehUSD().transferFrom(msg.sender, address(this), amount);

        // A minimum deposit amount is designed to protect purchasers from over paying
        // gas for fullfilling multiple small tribe deposits
        if (amount < minimumDepositAmount) {
            // We cant fail/revert the transaction or send the tribes back in a reentrant call.
            // So we will keep your tribes balance seperate from the FIFO queue so you can withdraw them
            smallDeposits[msg.sender] = smallDeposits[msg.sender].add(amount);

            emit TribeDepositNotAccepted(msg.sender, amount, minimumDepositAmount);
        } else {
            // Ok, thanks for the deposit, let's queue it up.
            deposits[depositEndIndex] = TribeDepositEntry({user: msg.sender, amount: amount});
            emit TribeDeposit(msg.sender, amount, depositEndIndex);

            // Walk our index forward as well.
            depositEndIndex = depositEndIndex.add(1);

            // And add it to our total.
            totalSellableDeposits = totalSellableDeposits.add(amount);
        }
    }

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](3);
        addresses[0] = CONTRACT_TRIBEONEHUSD;
        addresses[1] = CONTRACT_EXRATES;
        addresses[2] = CONTRACT_TRIBEONEETIX;
    }

    /**
     * @notice Calculate how many wHAKA you will receive if you transfer
     *         an amount of tribes.
     * @param amount The amount of tribes (in 18 decimal places) you want to ask about
     */
    function tribeetixReceivedForTribes(uint amount) public view returns (uint) {
        // And what would that be worth in wHAKA based on the current price?
        return amount.divideDecimal(exchangeRates().rateForCurrency(wHAKA));
    }

    /**
     * @notice Calculate how many wHAKA you will receive if you transfer
     *         an amount of ether.
     * @param amount The amount of ether (in wei) you want to ask about
     */
    function tribeetixReceivedForEther(uint amount) public view returns (uint) {
        // How much is the ETH they sent us worth in hUSD (ignoring the transfer fee)?
        uint valueSentInTribes = amount.multiplyDecimal(exchangeRates().rateForCurrency(ETH));

        // Now, how many wHAKA will that USD amount buy?
        return tribeetixReceivedForTribes(valueSentInTribes);
    }

    /**
     * @notice Calculate how many tribes you will receive if you transfer
     *         an amount of ether.
     * @param amount The amount of ether (in wei) you want to ask about
     */
    function tribesReceivedForEther(uint amount) public view returns (uint) {
        // How many tribes would that amount of ether be worth?
        return amount.multiplyDecimal(exchangeRates().rateForCurrency(ETH));
    }

    /* ========== INTERNAL VIEWS ========== */

    function tribehUSD() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_TRIBEONEHUSD));
    }

    function tribeone() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_TRIBEONEETIX));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    // ========== MODIFIERS ==========

    modifier rateNotInvalid(bytes32 currencyKey) {
        require(!exchangeRates().rateIsInvalid(currencyKey), "Rate invalid or not a tribe");
        _;
    }

    /* ========== EVENTS ========== */

    event MaxEthPurchaseUpdated(uint amount);
    event FundsWalletUpdated(address newFundsWallet);
    event Exchange(string fromCurrency, uint fromAmount, string toCurrency, uint toAmount);
    event TribeWithdrawal(address user, uint amount);
    event TribeDeposit(address indexed user, uint amount, uint indexed depositIndex);
    event TribeDepositRemoved(address indexed user, uint amount, uint indexed depositIndex);
    event TribeDepositNotAccepted(address user, uint amount, uint minimum);
    event MinimumDepositAmountUpdated(uint amount);
    event NonPayableContract(address indexed receiver, uint amount);
    event ClearedDeposit(
        address indexed fromAddress,
        address indexed toAddress,
        uint fromETHAmount,
        uint toAmount,
        uint indexed depositIndex
    );
}