/**
 *Submitted for verification at Arbiscan on 2023-01-05
*/

pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    /**
     * @dev Computes 2^exp with limited precision where -100 <= exp <= 100 * one
     * @param one 1.0 represented in the same fixed point number format as exp
     * @param exp The power to raise 2 to -100 <= exp <= 100 * one
     * @return 2^exp represented with same number of decimals after the point as one
     */
    function twoPower(int256 exp, int256 one) internal pure returns (int256) {
        bool reciprocal = false;
        if (exp < 0) {
            reciprocal = true;
            exp = abs(exp);
        }

        // Precomputed values for 2^(1/2^i) in 18 decimals fixed point numbers
        int256[5] memory ks = [
            int256(1414213562373095049),
            1189207115002721067,
            1090507732665257659,
            1044273782427413840,
            1021897148654116678
        ];
        int256 whole = div(exp, one);
        require(whole <= 100);
        int256 result = mul(int256(uint256(1) << uint256(whole)), one);
        int256 remaining = sub(exp, mul(whole, one));

        int256 current = div(one, 2);
        for (uint256 i = 0; i < 5; i++) {
            if (remaining >= current) {
                remaining = sub(remaining, current);
                result = div(mul(result, ks[i]), 10**18); // 10**18 to match hardcoded ks values
            }
            current = div(current, 2);
        }
        if (reciprocal) {
            result = div(mul(one, one), result);
        }
        return result;
    }
}

/**
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {
    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        require(a <= MAX_INT256);
        return int256(a);
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool wasInitializing = initializing;
        initializing = true;
        initialized = true;

        _;

        initializing = wasInitializing;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.

        // MINOR CHANGE HERE:

        // previous code
        // uint256 cs;
        // assembly { cs := extcodesize(address) }
        // return cs == 0;

        // current code
        address _self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(_self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address sender) public virtual initializer {
        _owner = sender;
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

interface IUFragmentsPolicy {
    function rebase() external;
}

interface IUFragments {
    function totalSupply() external view returns (uint256);

    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);
}

interface IOracle {
    function getData() external returns (uint256, bool);
}

/**
 * @title uFragments Monetary Supply Policy
 * @dev This is an implementation of the uFragments Ideal Money protocol.
 *
 *      This component regulates the token supply of the uFragments ERC20 token in response to
 *      market oracles.
 */
contract AmplForkPolicy is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    event LogRebase(
        uint256 indexed epoch,
        uint256 exchangeRate,
        uint256 cpi,
        int256 requestedSupplyAdjustment,
        uint256 timestampSec
    );

    IUFragments public uFrags;

    // Provides the current CPI, as an 18 decimal fixed point number.
    IOracle public cpiOracle;

    // Market oracle provides the token/USD exchange rate as an 18 decimal fixed point number.
    // (eg) An oracle value of 1.5e18 it would mean 1 Ample is trading for $1.50.
    IOracle public marketOracle;

    // CPI value at the time of launch, as an 18 decimal fixed point number.
    uint256 private baseCpi;

    // If the current exchange rate is within this fractional distance from the target, no supply
    // update is performed. Fixed point number--same format as the rate.
    // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
    // DECIMALS Fixed point number.
    uint256 public deviationThreshold;

    uint256 private rebaseLagDeprecated;

    // More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    // Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    // The rebase window begins this many seconds into the minRebaseTimeInterval period.
    // For example if minRebaseTimeInterval is 24hrs, it represents the time of day in seconds.
    uint256 public rebaseWindowOffsetSec;

    // The length of the time window where a rebase operation is allowed to execute, in seconds.
    uint256 public rebaseWindowLengthSec;

    // The number of rebase cycles since inception
    uint256 public epoch;

    uint256 private constant DECIMALS = 18;

    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 10**6 * 10**DECIMALS;
    // MAX_SUPPLY = MAX_INT256 / MAX_RATE
    uint256 private constant MAX_SUPPLY = uint256(type(int256).max) / MAX_RATE;

    // This module orchestrates the rebase execution and downstream notification.
    address public orchestrator;

    // DECIMALS decimal fixed point numbers.
    // Used in computation of  (Upper-Lower)/(1-(Upper/Lower)/2^(Growth*delta))) + Lower
    int256 public rebaseFunctionLowerPercentage;
    int256 public rebaseFunctionUpperPercentage;
    int256 public rebaseFunctionGrowth;

    int256 private constant ONE = int256(10**DECIMALS);

    modifier onlyOrchestrator() {
        require(msg.sender == orchestrator);
        _;
    }

    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     * @dev Changes supply with percentage of:
     *  (Upper-Lower)/(1-(Upper/Lower)/2^(Growth*NormalizedPriceDelta))) + Lower
     */
    function rebase() external onlyOrchestrator {
        require(inRebaseWindow());

        // This comparison also ensures there is no reentrancy.
        require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < block.timestamp);

        // Snap the rebase time to the start of this window.
        lastRebaseTimestampSec = block
            .timestamp
            .sub(block.timestamp.mod(minRebaseTimeIntervalSec))
            .add(rebaseWindowOffsetSec);

        epoch = epoch.add(1);

        uint256 cpi;
        bool cpiValid;
        (cpi, cpiValid) = cpiOracle.getData();
        require(cpiValid);

        uint256 targetRate = cpi.mul(10**DECIMALS).div(baseCpi);

        uint256 exchangeRate;
        bool rateValid;
        (exchangeRate, rateValid) = marketOracle.getData();
        require(rateValid);

        if (exchangeRate > MAX_RATE) {
            exchangeRate = MAX_RATE;
        }

        int256 supplyDelta = computeSupplyDelta(exchangeRate, targetRate);

        if (supplyDelta > 0 && uFrags.totalSupply().add(uint256(supplyDelta)) > MAX_SUPPLY) {
            supplyDelta = (MAX_SUPPLY.sub(uFrags.totalSupply())).toInt256Safe();
        }

        uint256 supplyAfterRebase = uFrags.rebase(epoch, supplyDelta);
        assert(supplyAfterRebase <= MAX_SUPPLY);
        emit LogRebase(epoch, exchangeRate, cpi, supplyDelta, block.timestamp);
    }

    /**
     * @notice Sets the reference to the CPI oracle.
     * @param cpiOracle_ The address of the cpi oracle contract.
     */
    function setCpiOracle(IOracle cpiOracle_) external onlyOwner {
        cpiOracle = cpiOracle_;
    }

    /**
     * @notice Sets the reference to the market oracle.
     * @param marketOracle_ The address of the market oracle contract.
     */
    function setMarketOracle(IOracle marketOracle_) external onlyOwner {
        marketOracle = marketOracle_;
    }

    /**
     * @notice Sets the reference to the orchestrator.
     * @param orchestrator_ The address of the orchestrator contract.
     */
    function setOrchestrator(address orchestrator_) external onlyOwner {
        orchestrator = orchestrator_;
    }

    function setRebaseFunctionGrowth(int256 rebaseFunctionGrowth_) external onlyOwner {
        require(rebaseFunctionGrowth_ >= 0);
        rebaseFunctionGrowth = rebaseFunctionGrowth_;
    }

    function setRebaseFunctionLowerPercentage(int256 rebaseFunctionLowerPercentage_)
        external
        onlyOwner
    {
        require(rebaseFunctionLowerPercentage_ <= 0);
        rebaseFunctionLowerPercentage = rebaseFunctionLowerPercentage_;
    }

    function setRebaseFunctionUpperPercentage(int256 rebaseFunctionUpperPercentage_)
        external
        onlyOwner
    {
        require(rebaseFunctionUpperPercentage_ >= 0);
        rebaseFunctionUpperPercentage = rebaseFunctionUpperPercentage_;
    }

    /**
     * @notice Sets the deviation threshold fraction. If the exchange rate given by the market
     *         oracle is within this fractional distance from the targetRate, then no supply
     *         modifications are made. DECIMALS fixed point number.
     * @param deviationThreshold_ The new exchange rate threshold fraction.
     */
    function setDeviationThreshold(uint256 deviationThreshold_) external onlyOwner {
        deviationThreshold = deviationThreshold_;
    }

    /**
     * @notice Sets the parameters which control the timing and frequency of
     *         rebase operations.
     *         a) the minimum time period that must elapse between rebase cycles.
     *         b) the rebase window offset parameter.
     *         c) the rebase window length parameter.
     * @param minRebaseTimeIntervalSec_ More than this much time must pass between rebase
     *        operations, in seconds.
     * @param rebaseWindowOffsetSec_ The number of seconds from the beginning of
              the rebase interval, where the rebase window begins.
     * @param rebaseWindowLengthSec_ The length of the rebase window in seconds.
     */
    function setRebaseTimingParameters(
        uint256 minRebaseTimeIntervalSec_,
        uint256 rebaseWindowOffsetSec_,
        uint256 rebaseWindowLengthSec_
    ) external onlyOwner {
        require(minRebaseTimeIntervalSec_ > 0);
        require(rebaseWindowOffsetSec_ < minRebaseTimeIntervalSec_);

        minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
        rebaseWindowOffsetSec = rebaseWindowOffsetSec_;
        rebaseWindowLengthSec = rebaseWindowLengthSec_;
    }

    /**
     * @notice A multi-chain AMPL interface method. The Ampleforth monetary policy contract
     *         on the base-chain and XC-AmpleController contracts on the satellite-chains
     *         implement this method. It atomically returns two values:
     *         what the current contract believes to be,
     *         the globalAmpleforthEpoch and globalAMPLSupply.
     * @return globalAmpleforthEpoch The current epoch number.
     * @return globalAMPLSupply The total supply at the current epoch.
     */
    function globalAmpleforthEpochAndAMPLSupply() external view returns (uint256, uint256) {
        return (epoch, uFrags.totalSupply());
    }

    /**
     * @dev ZOS upgradable contract initialization method.
     *      It is called at the time of contract creation to invoke parent class initializers and
     *      initialize the contract's state variables.
     */
    function initialize(
        address owner_,
        IUFragments uFrags_,
        uint256 baseCpi_
    ) public initializer {
        Ownable.initialize(owner_);

        // deviationThreshold = 0.05e18 = 5e16
        deviationThreshold = 5 * 10**(DECIMALS - 2);

        rebaseFunctionGrowth = int256(3 * (10**DECIMALS));
        rebaseFunctionUpperPercentage = int256(10 * (10**(DECIMALS - 2))); // 0.1
        rebaseFunctionLowerPercentage = int256((-10) * int256(10**(DECIMALS - 2))); // -0.1

        minRebaseTimeIntervalSec = 1 days;
        rebaseWindowOffsetSec = 7200; // 2AM UTC
        rebaseWindowLengthSec = 20 minutes;

        lastRebaseTimestampSec = 0;
        epoch = 0;

        uFrags = uFrags_;
        baseCpi = baseCpi_;
    }

    /**
     * @return If the latest block timestamp is within the rebase time window it, returns true.
     *         Otherwise, returns false.
     */
    function inRebaseWindow() public view returns (bool) {
        return (block.timestamp.mod(minRebaseTimeIntervalSec) >= rebaseWindowOffsetSec &&
            block.timestamp.mod(minRebaseTimeIntervalSec) <
            (rebaseWindowOffsetSec.add(rebaseWindowLengthSec)));
    }

    /**
     * Computes the percentage of supply to be added or removed:
     * Using the function in https://github.com/ampleforth/AIPs/blob/master/AIPs/aip-5.md
     * @param normalizedRate value of rate/targetRate in DECIMALS decimal fixed point number
     * @return The percentage of supply to be added or removed.
     */
    function computeRebasePercentage(
        int256 normalizedRate,
        int256 lower,
        int256 upper,
        int256 growth
    ) public pure returns (int256) {
        int256 delta;

        delta = (normalizedRate.sub(ONE));

        // Compute: (Upper-Lower)/(1-(Upper/Lower)/2^(Growth*delta))) + Lower

        int256 exponent = growth.mul(delta).div(ONE);
        // Cap exponent to guarantee it is not too big for twoPower
        if (exponent > ONE.mul(100)) {
            exponent = ONE.mul(100);
        }
        if (exponent < ONE.mul(-100)) {
            exponent = ONE.mul(-100);
        }

        int256 pow = SafeMathInt.twoPower(exponent, ONE); // 2^(Growth*Delta)
        if (pow == 0) {
            return lower;
        }
        int256 numerator = upper.sub(lower); //(Upper-Lower)
        int256 intermediate = upper.mul(ONE).div(lower);
        intermediate = intermediate.mul(ONE).div(pow);
        int256 denominator = ONE.sub(intermediate); // (1-(Upper/Lower)/2^(Growth*delta)))

        int256 rebasePercentage = (numerator.mul(ONE).div(denominator)).add(lower);
        return rebasePercentage;
    }

    /**
     * @return Computes the total supply adjustment in response to the exchange rate
     *         and the targetRate.
     */
    function computeSupplyDelta(uint256 rate, uint256 targetRate) internal view returns (int256) {
        if (withinDeviationThreshold(rate, targetRate)) {
            return 0;
        }
        int256 targetRateSigned = targetRate.toInt256Safe();
        int256 normalizedRate = rate.toInt256Safe().mul(ONE).div(targetRateSigned);
        int256 rebasePercentage = computeRebasePercentage(
            normalizedRate,
            rebaseFunctionLowerPercentage,
            rebaseFunctionUpperPercentage,
            rebaseFunctionGrowth
        );

        return uFrags.totalSupply().toInt256Safe().mul(rebasePercentage).div(ONE);
    }

    /**
     * @param rate The current exchange rate, an 18 decimal fixed point number.
     * @param targetRate The target exchange rate, an 18 decimal fixed point number.
     * @return If the rate is within the deviation threshold from the target rate, returns true.
     *         Otherwise, returns false.
     */
    function withinDeviationThreshold(uint256 rate, uint256 targetRate)
        internal
        view
        returns (bool)
    {
        uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold).div(10**DECIMALS);

        return
            (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold) ||
            (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
    }

    /**
     * To maintain abi backward compatibility
     */
    function rebaseLag() public pure returns (uint256) {
        return 1;
    }
}