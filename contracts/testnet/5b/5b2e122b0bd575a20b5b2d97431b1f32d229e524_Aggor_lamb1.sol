// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {IUniswapV3PoolImmutables} from
    "uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol";

import {IChronicle} from "chronicle-std/IChronicle.sol";
import {Auth} from "chronicle-std/auth/Auth.sol";
import {Toll} from "chronicle-std/toll/Toll.sol";

import {LibCalc} from "./libs/LibCalc.sol";
import {LibUniswapOracles} from "./libs/LibUniswapOracles.sol";

import {IAggor} from "./IAggor.sol";

import {IChainlinkAggregatorV3} from
    "./interfaces/_external/IChainlinkAggregatorV3.sol";

/**
 * @title Aggor
 *
 * @notice Aggor combines oracle values from multiple providers into a single
 *         value
 */
contract Aggor is IAggor, Auth, Toll {
    /// @dev Percentage scale is in basis points (BPS).
    uint16 internal constant _pscale = 10_000;

    /// @inheritdoc IAggor
    uint32 public constant minUniSecondsAgo = 5 minutes;

    /// @inheritdoc IAggor
    uint8 public constant decimals = 18;

    /// @inheritdoc IChronicle
    bytes32 public immutable wat;

    /// @inheritdoc IAggor
    address public immutable chronicle;

    /// @inheritdoc IAggor
    address public immutable chainlink;

    /// @inheritdoc IAggor
    address public immutable uniPool;

    /// @inheritdoc IAggor
    address public immutable uniBasePair;

    /// @inheritdoc IAggor
    address public immutable uniQuotePair;

    /// @inheritdoc IAggor
    uint8 public immutable uniBaseDec;

    /// @inheritdoc IAggor
    uint8 public immutable uniQuoteDec;

    /// @inheritdoc IAggor
    uint32 public uniSecondsAgo;

    /// @inheritdoc IAggor
    uint32 public stalenessThreshold;

    /// @inheritdoc IAggor
    uint16 public spread;

    /// @inheritdoc IAggor
    bool public uniswapSelected;

    // This is the last agreed upon mean price.
    uint128 private _val;
    uint32 private _age;

    /// @notice You only get once chance per deploy to setup Uniswap. If it
    ///         will not be used, just pass in address(0) for uniPool_.
    /// @param initialAuthed Address to be initially auth'ed
    /// @param chronicle_ Address of Chronicle oracle
    /// @param chainlink_ Address of Chainlink oracle
    /// @param uniPool_ Address of Uniswap oracle (optional)
    /// @param uniUseToken0AsBase If true, selects Pool.token0 as base pair, if not,
    //         it uses Pool.token1 as the base pair.
    constructor(
        address initialAuthed,
        address chronicle_,
        address chainlink_,
        address uniPool_,
        bool uniUseToken0AsBase
    ) Auth(initialAuthed) {
        require(chronicle_ != address(0));
        require(chainlink_ != address(0));

        chronicle = chronicle_;
        chainlink = chainlink_;

        // Note that IChronicle::wat() is constant and save to cache.
        wat = IChronicle(chronicle_).wat();

        // Optionally initialize Uniswap.
        address uniPoolInitializer;
        address uniBasePairInitializer;
        address uniQuotePairInitializer;
        uint8 uniBaseDecInitializer;
        uint8 uniQuoteDecInitializer;

        if (uniPool_ != address(0)) {
            uniPoolInitializer = uniPool_;

            if (uniUseToken0AsBase) {
                uniBasePairInitializer =
                    IUniswapV3PoolImmutables(uniPoolInitializer).token0();
                uniQuotePairInitializer =
                    IUniswapV3PoolImmutables(uniPoolInitializer).token1();
            } else {
                uniBasePairInitializer =
                    IUniswapV3PoolImmutables(uniPoolInitializer).token1();
                uniQuotePairInitializer =
                    IUniswapV3PoolImmutables(uniPoolInitializer).token0();
            }

            uniBaseDecInitializer = IERC20(uniBasePairInitializer).decimals();
            uniQuoteDecInitializer = IERC20(uniQuotePairInitializer).decimals();
        }

        uniPool = uniPoolInitializer;
        uniBasePair = uniBasePairInitializer;
        uniQuotePair = uniQuotePairInitializer;
        uniBaseDec = uniBaseDecInitializer;
        uniQuoteDec = uniQuoteDecInitializer;

        // Default config values
        _setStalenessThreshold(1 days);
        _setSpread(500); // 5%

        if (uniPool != address(0)) {
            _setUniSecondsAgo(5 minutes);
        }
    }

    /// @inheritdoc IAggor
    function poke() external {
        _poke();
    }

    /// @dev Optimized function selector: 0x00000000.
    ///      Note that this function is _not_ defined via the IAggor interface
    ///      and one should _not_ depend on it.
    function poke_optimized_3923566589() external {
        _poke();
    }

    function _poke() internal {
        bool ok;

        // Read chronicle.
        uint valChronicle;
        (ok, valChronicle) = _tryReadChronicle();
        if (!ok) {
            revert OracleReadFailed(chronicle);
        }
        // assert(valChronicle != 0);
        // assert(valChronicle <= type(uint128).max);

        // Read second oracle, either Chainlink or Uniswap TWAP.
        uint valOther;
        if (!uniswapSelected) {
            // Read Chainlink.
            (ok, valOther) = _tryReadChainlink();
            if (!ok) {
                revert OracleReadFailed(chainlink);
            }
        } else {
            // assert(uniPool != address(0));

            // Read Uniswap.
            (ok, valOther) = _tryReadUniswap();
            if (!ok) {
                revert OracleReadFailed(uniPool);
            }
        }
        // assert(valOther != 0);
        // assert(valOther <= type(uint128).max);

        // Compute difference of oracle values.
        uint diff =
            LibCalc.pctDiff(uint128(valChronicle), uint128(valOther), _pscale);

        if (diff > spread) {
            // If difference is bigger than acceptable spread, let _val be the
            // oracle's value with less difference to the current _val.
            // forgefmt: disable-next-item
            _val = LibCalc.distance(_val, valChronicle) < LibCalc.distance(_val, valOther)
                ? uint128(valChronicle)
                : uint128(valOther);
        } else {
            // If difference is within acceptable spread, let _val be the mean
            // of the oracles' values.
            // Note that unsafe computation is fine because both arguments are
            // less than or equal to type(uint128).max.
            _val = uint128(LibCalc.unsafeMean(valChronicle, valOther));
        }
        // assert(_val <= type(uint128).max);

        // Update _val's age to current timestamp.
        _age = uint32(block.timestamp);
    }

    // -- Read Functionality --

    // -- IChronicle

    /// @inheritdoc IChronicle
    function read() external view toll returns (uint) {
        require(_val != 0);
        return _val;
    }

    /// @inheritdoc IChronicle
    function tryRead() external view toll returns (bool, uint) {
        return (_val != 0, _val);
    }

    /// @inheritdoc IChronicle
    function readWithAge() external view toll returns (uint, uint) {
        require(_val != 0);
        return (_val, _age);
    }

    /// @inheritdoc IChronicle
    function tryReadWithAge() external view toll returns (bool, uint, uint) {
        return (_val != 0, _val, _age);
    }

    // -- IChainlinkAggregatorV3

    /// @inheritdoc IAggor
    function latestRoundData()
        external
        view
        virtual
        toll
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 1;
        answer = _toInt(_val);
        // assert(uint(answer) == uint(_val));
        startedAt = 0;
        updatedAt = _age;
        answeredInRound = roundId;
    }

    /// @inheritdoc IAggor
    function latestAnswer() external view toll returns (int) {
        return _toInt(_val);
    }

    // -- Auth'ed Functionality --

    /// @inheritdoc IAggor
    function setStalenessThreshold(uint32 stalenessThreshold_) external auth {
        _setStalenessThreshold(stalenessThreshold_);
    }

    function _setStalenessThreshold(uint32 stalenessThreshold_) internal {
        require(stalenessThreshold_ != 0);

        if (stalenessThreshold != stalenessThreshold_) {
            emit StalenessThresholdUpdated(
                msg.sender, stalenessThreshold, stalenessThreshold_
            );
            stalenessThreshold = stalenessThreshold_;
        }
    }

    /// @inheritdoc IAggor
    function setSpread(uint16 spread_) external auth {
        _setSpread(spread_);
    }

    function _setSpread(uint16 spread_) internal {
        require(spread_ <= _pscale);

        if (spread != spread_) {
            emit SpreadUpdated(msg.sender, spread, spread_);
            spread = spread_;
        }
    }

    /// @inheritdoc IAggor
    function useUniswap(bool selected) external auth {
        // Uniswap pool must be configured
        require(uniPool != address(0));

        // Revert unless there is something to change
        require(uniswapSelected != selected);

        emit UniswapSelectedUpdated({
            caller: msg.sender,
            oldValue: uniswapSelected,
            newValue: selected
        });

        uniswapSelected = selected;
    }

    /// @inheritdoc IAggor
    function setUniSecondsAgo(uint32 uniSecondsAgo_) external auth {
        _setUniSecondsAgo(uniSecondsAgo_);
    }

    function _setUniSecondsAgo(uint32 uniSecondsAgo_) internal {
        // Uniswap is optional, make sure it's configured
        require(uniPool != address(0));
        require(uniSecondsAgo_ >= minUniSecondsAgo);

        if (uniSecondsAgo != uniSecondsAgo_) {
            emit UniswapSecondsAgoUpdated(
                msg.sender, uniSecondsAgo, uniSecondsAgo_
            );
            uniSecondsAgo = uniSecondsAgo_;
        }

        // Ensure that the pool works within the desired "lookback" period.
        (bool ok,) = _tryReadUniswap();
        require(ok);
    }

    // -- Private Helpers --

    function _tryReadUniswap() internal view returns (bool, uint) {
        // assert(uniPool != address(0));

        uint val = LibUniswapOracles.readOracle(
            uniPool, uniBasePair, uniQuotePair, uniBaseDec, uniSecondsAgo
        );

        // We always scale to 'decimals', up OR down.
        if (uniQuoteDec != decimals) {
            val = LibCalc.scale(val, uniQuoteDec, decimals);
        }

        // Fail if value is zero.
        if (val == 0) {
            return (false, 0);
        }

        // Also fail if could cause overflow.
        if (val > type(uint128).max) {
            return (false, 0);
        }

        return (true, val);
    }

    function _tryReadChronicle() internal view returns (bool, uint) {
        bool ok;
        uint val;
        uint age;
        (ok, val, age) = IChronicle(chronicle).tryReadWithAge();
        // assert(!ok || val != 0);

        // Fail if value stale.
        uint diff = block.timestamp - age;
        if (diff > stalenessThreshold) {
            return (false, 0);
        }

        return (ok, val);
    }

    function _tryReadChainlink() internal view returns (bool, uint) {
        int answer;
        uint updatedAt;
        (, answer,, updatedAt,) =
            IChainlinkAggregatorV3(chainlink).latestRoundData();

        // Fail if value stale.
        uint diff = block.timestamp - updatedAt;
        if (diff > stalenessThreshold) {
            return (false, 0);
        }

        // Fail if value negative.
        if (answer < 0) {
            return (false, 0);
        }

        // Adjust decimals, if necessary.
        uint val = uint(answer);
        uint decimals_ = IChainlinkAggregatorV3(chainlink).decimals();
        if (decimals_ != decimals) {
            val = LibCalc.scale(val, decimals_, decimals);
        }

        // Fail if value is zero.
        if (val == 0) {
            return (false, 0);
        }

        // Otherwise value is ok.
        return (true, val);
    }

    function _toInt(uint128 val) private pure returns (int) {
        // Note that int(type(uint128).max) == type(uint128).max.
        return int(uint(val));
    }

    // -- Overridden Toll Functions --

    /// @dev Defines authorization for IToll's authenticated functions.
    function toll_auth() internal override(Toll) auth {}
}

/**
 * @dev Contract overwrite to deploy contract instances with specific naming.
 *
 *      For more info, see docs/Deployment.md.
 */
contract Aggor_lamb1 is Aggor {
    // @todo   ^^^^^^^ Adjust name of Aggor instance
    constructor(
        address initialAuthed,
        address chronicle_,
        address chainlink_,
        address uniPool_,
        bool uniUseToken0AsBase
    )
        Aggor(initialAuthed, chronicle_, chainlink_, uniPool_, uniUseToken0AsBase)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title IChronicle
 *
 * @notice Interface for Chronicle Protocol's oracle products
 */
interface IChronicle {
    /// @notice Returns the oracle's identifier.
    /// @return wat The oracle's identifier.
    function wat() external view returns (bytes32 wat);

    /// @notice Returns the oracle's current value.
    /// @dev Reverts if no value set.
    /// @return value The oracle's current value.
    function read() external view returns (uint value);

    /// @notice Returns the oracle's current value and its age.
    /// @dev Reverts if no value set.
    /// @return value The oracle's current value.
    /// @return age The value's age.
    function readWithAge() external view returns (uint value, uint age);

    /// @notice Returns the oracle's current value.
    /// @return isValid True if value exists, false otherwise.
    /// @return value The oracle's current value if it exists, zero otherwise.
    function tryRead() external view returns (bool isValid, uint value);

    /// @notice Returns the oracle's current value and its age.
    /// @return isValid True if value exists, false otherwise.
    /// @return value The oracle's current value if it exists, zero otherwise.
    /// @return age The value's age if value exists, zero otherwise.
    function tryReadWithAge()
        external
        view
        returns (bool isValid, uint value, uint age);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IAuth} from "./IAuth.sol";

/**
 * @title Auth Module
 *
 * @dev The `Auth` contract module provides a basic access control mechanism,
 *      where a set of addresses are granted access to protected functions.
 *      These addresses are said to be _auth'ed_.
 *
 *      Initially, the address given as constructor argument is the only address
 *      auth'ed. Through the `rely(address)` and `deny(address)` functions,
 *      auth'ed callers are able to grant/renounce auth to/from addresses.
 *
 *      This module is used through inheritance. It will make available the
 *      modifier `auth`, which can be applied to functions to restrict their
 *      use to only auth'ed callers.
 */
abstract contract Auth is IAuth {
    /// @dev Mapping storing whether address is auth'ed.
    /// @custom:invariant Image of mapping is {0, 1}.
    ///                     ∀x ∊ Address: _wards[x] ∊ {0, 1}
    /// @custom:invariant Only address given as constructor argument is authenticated after deployment.
    ///                     deploy(initialAuthed) → (∀x ∊ Address: _wards[x] == 1 → x == initialAuthed)
    /// @custom:invariant Only functions `rely` and `deny` may mutate the mapping's state.
    ///                     ∀x ∊ Address: preTx(_wards[x]) != postTx(_wards[x])
    ///                                     → (msg.sig == "rely" ∨ msg.sig == "deny")
    /// @custom:invariant Mapping's state may only be mutated by authenticated caller.
    ///                     ∀x ∊ Address: preTx(_wards[x]) != postTx(_wards[x]) → _wards[msg.sender] = 1
    mapping(address => uint) private _wards;

    /// @dev List of addresses possibly being auth'ed.
    /// @dev May contain duplicates.
    /// @dev May contain addresses not being auth'ed anymore.
    /// @custom:invariant Every address being auth'ed once is element of the list.
    ///                     ∀x ∊ Address: authed(x) -> x ∊ _wardsTouched
    address[] private _wardsTouched;

    /// @dev Ensures caller is auth'ed.
    modifier auth() {
        assembly ("memory-safe") {
            // Compute slot of _wards[msg.sender].
            mstore(0x00, caller())
            mstore(0x20, _wards.slot)
            let slot := keccak256(0x00, 0x40)

            // Revert if caller not auth'ed.
            let isAuthed := sload(slot)
            if iszero(isAuthed) {
                // Store selector of `NotAuthorized(address)`.
                mstore(0x00, 0x4a0bfec1)
                // Store msg.sender.
                mstore(0x20, caller())
                // Revert with (offset, size).
                revert(0x1c, 0x24)
            }
        }
        _;
    }

    constructor(address initialAuthed) {
        _wards[initialAuthed] = 1;
        _wardsTouched.push(initialAuthed);

        // Note to use address(0) as caller to indicate address was auth'ed
        // during deployment.
        emit AuthGranted(address(0), initialAuthed);
    }

    /// @inheritdoc IAuth
    function rely(address who) external auth {
        if (_wards[who] == 1) return;

        _wards[who] = 1;
        _wardsTouched.push(who);
        emit AuthGranted(msg.sender, who);
    }

    /// @inheritdoc IAuth
    function deny(address who) external auth {
        if (_wards[who] == 0) return;

        _wards[who] = 0;
        emit AuthRenounced(msg.sender, who);
    }

    /// @inheritdoc IAuth
    function authed(address who) public view returns (bool) {
        return _wards[who] == 1;
    }

    /// @inheritdoc IAuth
    /// @custom:invariant Only contains auth'ed addresses.
    ///                     ∀x ∊ authed(): _wards[x] == 1
    /// @custom:invariant Contains all auth'ed addresses.
    ///                     ∀x ∊ Address: _wards[x] == 1 → x ∊ authed()
    function authed() public view returns (address[] memory) {
        // Initiate array with upper limit length.
        address[] memory wardsList = new address[](_wardsTouched.length);

        // Iterate through all possible auth'ed addresses.
        uint ctr;
        for (uint i; i < wardsList.length; i++) {
            // Add address only if still auth'ed.
            if (_wards[_wardsTouched[i]] == 1) {
                wardsList[ctr++] = _wardsTouched[i];
            }
        }

        // Set length of array to number of auth'ed addresses actually included.
        assembly ("memory-safe") {
            mstore(wardsList, ctr)
        }

        return wardsList;
    }

    /// @inheritdoc IAuth
    function wards(address who) public view returns (uint) {
        return _wards[who];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IToll} from "./IToll.sol";

/**
 * @title Toll Module
 *
 * @notice "Toll paid, we kiss - but dissension looms, maybe diss?"
 *
 * @dev The `Toll` contract module provides a basic access control mechanism,
 *      where a set of addresses are granted access to protected functions.
 *      These addresses are said the be _tolled_.
 *
 *      Initially, no address is tolled. Through the `kiss(address)` and
 *      `diss(address)` functions, auth'ed callers are able to toll/de-toll
 *      addresses. Authentication for these functions is defined via the
 *      downstream implemented `toll_auth()` function.
 *
 *      This module is used through inheritance. It will make available the
 *      modifier `toll`, which can be applied to functions to restrict their
 *      use to only tolled callers.
 */
abstract contract Toll is IToll {
    /// @dev Mapping storing whether address is tolled.
    /// @custom:invariant Image of mapping is {0, 1}.
    ///                     ∀x ∊ Address: _buds[x] ∊ {0, 1}
    /// @custom:invariant Only functions `kiss` and `diss` may mutate the mapping's state.
    ///                     ∀x ∊ Address: preTx(_buds[x]) != postTx(_buds[x])
    ///                                     → (msg.sig == "kiss" ∨ msg.sig == "diss")
    /// @custom:invariant Mapping's state may only be mutated by authenticated caller.
    ///                     ∀x ∊ Address: preTx(_buds[x]) != postTx(_buds[x])
    ///                                     → toll_auth()
    mapping(address => uint) private _buds;

    /// @dev List of addresses possibly being tolled.
    /// @dev May contain duplicates.
    /// @dev May contain addresses not being tolled anymore.
    /// @custom:invariant Every address being tolled once is element of the list.
    ///                     ∀x ∊ Address: tolled(x) → x ∊ _budsTouched
    address[] private _budsTouched;

    /// @dev Ensures caller is tolled.
    modifier toll() {
        assembly ("memory-safe") {
            // Compute slot of _buds[msg.sender].
            mstore(0x00, caller())
            mstore(0x20, _buds.slot)
            let slot := keccak256(0x00, 0x40)

            // Revert if caller not tolled.
            let isTolled := sload(slot)
            if iszero(isTolled) {
                // Store selector of `NotTolled(address)`.
                mstore(0x00, 0xd957b595)
                // Store msg.sender.
                mstore(0x20, caller())
                // Revert with (offset, size).
                revert(0x1c, 0x24)
            }
        }
        _;
    }

    /// @dev Reverts if caller not allowed to access protected function.
    /// @dev Must be implemented in downstream contract.
    function toll_auth() internal virtual;

    /// @inheritdoc IToll
    function kiss(address who) external {
        toll_auth();

        if (_buds[who] == 1) return;

        _buds[who] = 1;
        _budsTouched.push(who);
        emit TollGranted(msg.sender, who);
    }

    /// @inheritdoc IToll
    function diss(address who) external {
        toll_auth();

        if (_buds[who] == 0) return;

        _buds[who] = 0;
        emit TollRenounced(msg.sender, who);
    }

    /// @inheritdoc IToll
    function tolled(address who) public view returns (bool) {
        return _buds[who] == 1;
    }

    /// @inheritdoc IToll
    /// @custom:invariant Only contains tolled addresses.
    ///                     ∀x ∊ tolled(): _tolled[x]
    /// @custom:invariant Contains all tolled addresses.
    ///                     ∀x ∊ Address: _tolled[x] == 1 → x ∊ tolled()
    function tolled() public view returns (address[] memory) {
        // Initiate array with upper limit length.
        address[] memory budsList = new address[](_budsTouched.length);

        // Iterate through all possible tolled addresses.
        uint ctr;
        for (uint i; i < budsList.length; i++) {
            // Add address only if still tolled.
            if (_buds[_budsTouched[i]] == 1) {
                budsList[ctr++] = _budsTouched[i];
            }
        }

        // Set length of array to number of tolled addresses actually included.
        assembly ("memory-safe") {
            mstore(budsList, ctr)
        }

        return budsList;
    }

    /// @inheritdoc IToll
    function bud(address who) public view returns (uint) {
        return _buds[who];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title LibCalc
 *
 * @notice Library for common calculations.
 */
library LibCalc {
    /// @dev Computes the percent difference of two numbers with a precision of
    ///      pscale (e.g. 10_000 == 99.99%).
    function pctDiff(uint128 a, uint128 b, uint pscale)
        internal
        pure
        returns (uint)
    {
        if (a == b) return 0;
        return a > b
            ? pscale - (((uint(b) * 1e18) / uint(a)) * pscale / 1e18)
            : pscale - (((uint(a) * 1e18) / uint(b)) * pscale / 1e18);
    }

    /// @dev Computes the numerical distance between two numbers.
    function distance(uint a, uint b) internal pure returns (uint) {
        // Unchecked as subtractions are guaranteed to not underflow.
        unchecked {
            return (a > b) ? a - b : b - a;
        }
    }

    /// @dev This allows you to scale uint decimals up or down, e.g. you can
    ///      scale a WETH value (decimals 18) to a USDT value (decimals 6)
    ///      and vice versa.
    function scale(uint n, uint dec, uint destDec)
        internal
        pure
        returns (uint)
    {
        // No need to scale if value is zero.
        if (n == 0) return 0;

        require(dec > 0 && destDec > 0);

        return destDec > dec
            ? n * (10 ** (destDec - dec)) // Scale up
            : n / (10 ** (dec - destDec)); // Scale down
    }

    /// @dev Optimized mean calculation at the expense of safety. Careful!
    function unsafeMean(uint a, uint b) internal pure returns (uint) {
        uint mean;
        unchecked {
            // Note that >> 1 equals a division by 2.
            mean = (a + b) >> 1;
        }
        return mean;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {OracleLibrary} from
    "uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

/**
 * @title LibUniswapOracles
 *
 * @notice Library for Uniswap oracle related functionality.
 */
library LibUniswapOracles {
    /// @dev The maximum number of decimals for the base asset supported.
    ///      Note that this constraint comes from Uniswap's OracleLibrary which
    ///      takes the base asset amount as type uint128.
    uint internal constant MAX_UNI_BASE_DEC = 38;

    /// @notice Reads the TWAP derived price from a Uniswap oracle.
    /// @dev The Uniswap pool address + pair addresses can be discovered at
    ///      https://app.uniswap.org/#/swap
    /// @param uniPool The Uniswap pool that wil be observed.
    /// @param uniBasePair The base pair for the pool, e.g. WETH in WETHUSDT.
    /// @param uniQuotePair The quote pair for the pool, e.g. USDT in WETHUSDT.
    /// @param uniBaseDec The decimals of the base pair ERC-20 token.
    /// @param secondsAgo The time in seconds to "look back" per TWAP.
    function readOracle(
        address uniPool,
        address uniBasePair,
        address uniQuotePair,
        uint8 uniBaseDec,
        uint32 secondsAgo
    ) internal view returns (uint) {
        // Note that 10**(MAX_UNI_BASE_DEC + 1) would overflow type uint128.
        require(uniBaseDec <= MAX_UNI_BASE_DEC);

        (int24 tick,) = OracleLibrary.consult(address(uniPool), secondsAgo);

        // Calculate exactly 1 unit of the base pair for quote
        uint128 amt = uint128(1 * (10 ** uniBaseDec));

        uint val =
            OracleLibrary.getQuoteAtTick(tick, amt, uniBasePair, uniQuotePair);
        return val;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IChronicle} from "chronicle-std/IChronicle.sol";

interface IAggor is IChronicle {
    /// @notice Thrown if an oracle read fails.
    /// @param oracle The oracle address which read's failed.
    error OracleReadFailed(address oracle);

    /// @notice Emitted when staleness threshold updated.
    /// @param caller The caller's address.
    /// @param oldStalenessThreshold The old staleness threshold.
    /// @param newStalenessThreshold The new staleness threshold.
    event StalenessThresholdUpdated(
        address indexed caller,
        uint32 oldStalenessThreshold,
        uint32 newStalenessThreshold
    );

    /// @notice Emitted when Uniswap is selected or deselected
    /// @param caller The caller's address.
    /// @param oldValue The previous value.
    /// @param newValue The updated value.
    event UniswapSelectedUpdated(
        address indexed caller, bool oldValue, bool newValue
    );

    /// @notice Emitted when spread is updated.
    /// @param caller The caller's address.
    /// @param oldSpread The old spread value.
    /// @param newSpread The new spread value.
    event SpreadUpdated(
        address indexed caller, uint16 oldSpread, uint16 newSpread
    );

    /// @notice Emitted when Uniswap TWAP's lookback period is updated.
    /// @param caller The caller's address.
    /// @param oldUniswapSecondsAgo The old uniswapSecondsAgo value.
    /// @param newUniswapSecondsAgo The new uniswapSecondsAgo value.
    event UniswapSecondsAgoUpdated(
        address indexed caller,
        uint32 oldUniswapSecondsAgo,
        uint32 newUniswapSecondsAgo
    );

    /// @notice Emitted when Chainlink's oracle delivered a zero value.
    event ChainlinkValueZero();

    /// @notice The Chronicle oracle to aggregate.
    /// @return The address of the Chronicle oracle being aggregated.
    function chronicle() external view returns (address);

    /// @notice The Chainlink oracle to aggregate.
    /// @return The address of the Chainlink oracle being aggregated.
    function chainlink() external view returns (address);

    /// @notice The Uniswap pool that wil be observed.
    function uniPool() external view returns (address);

    /// @notice The base pair for the pool, e.g. WETH in WETHUSDT.
    function uniBasePair() external view returns (address);

    /// @notice The quote pair for the pool, e.g. USDT in WETHUSDT.
    function uniQuotePair() external view returns (address);

    /// @notice The decimals of the base pair ERC-20 token.
    function uniBaseDec() external view returns (uint8);

    /// @notice The decimals of the quote pair ERC-20 token.
    function uniQuoteDec() external view returns (uint8);

    /// @notice The time in seconds to "look back" per TWAP.
    function uniSecondsAgo() external view returns (uint32);

    /// @notice Determines which secondary oracle is selected. If false
    //          (default), use Chainlink.
    function uniswapSelected() external view returns (bool);

    /// @notice The minimum allowed lookback period for the Uniswap TWAP.
    /// @dev Value is constant and save to cache.
    /// @return The minimum allowed value for uniSecondsAgo.
    function minUniSecondsAgo() external view returns (uint32);

    /// @notice Pokes aggor, i.e. updates aggor's value to the mean of
    ///         Chronicle's and Chainlink's current values.
    /// @dev Reverts if an oracle's value cannot be read.
    /// @dev Reverts if an oracle's value is zero.
    /// @dev Reverts if Chainlink's oracle value is negative.
    /// @dev Reverts if Chainlink's oracle value is stale as being defined via
    ///      staleness threshold.
    function poke() external;

    /// @notice Returns the number of decimals of the oracle's value.
    /// @dev Provides partial compatibility with Chainlink's
    ///      IAggregatorV3Interface.
    /// @return decimals The oracle value's number of decimals.
    function decimals() external view returns (uint8 decimals);

    /// @notice Returns the oracle's latest value.
    /// @dev Provides partial compatibility to Chainlink's
    ///      IAggregatorV3Interface.
    /// @return roundId 1.
    /// @return answer The oracle's latest value.
    /// @return startedAt 0.
    /// @return updatedAt The timestamp of oracle's latest update.
    /// @return answeredInRound 1.
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );

    /// @notice Returns the oracle's latest value.
    /// @custom:deprecated See https://docs.chain.link/data-feeds/api-reference/#latestanswer.
    /// @return answer The oracle's latest value.
    function latestAnswer() external view returns (int);

    /// @notice Defines the allowed age of an oracle's value before being
    ///         declared stale.
    /// @return The staleness threshold parameter.
    function stalenessThreshold() external view returns (uint32);

    /// @notice Updates the staleness threshold parameter to
    ///         `stalenessThreshold`.
    /// @dev Only callable by auth'ed address.
    /// @dev Reverts if `stalenessThreshold` is zero.
    /// @param stalenessThreshold The value to update stalenessThreshold to.
    function setStalenessThreshold(uint32 stalenessThreshold) external;

    /// @notice The percentage difference between the price gotten from
    ///         oracles, used as a trigger to detect a potentially
    ///         compromised oracle.
    /// @dev The percent spread (difference in price) we can tolerate between
    ///      sources. If the difference is over this amount, assume one of the
    ///      sources is sussy. Defaults to 5%. Acceptable range 0 - 9999 (99.99%).
    /// @return The spread as a percentage difference between oracle prices
    function spread() external view returns (uint16);

    /// @notice Updates the spread parameter to `spread`.
    /// @dev Only callable by auth'ed address.
    /// @dev Revert is `spread` is more than 10000.
    /// @param spread The value to which to update spread.
    function setSpread(uint16 spread) external;

    /// @notice Switch from default oracle (Chainlink) to alt (Uniswap),
    ///         and back.
    /// @dev Only callable by auth'ed address.
    /// @param select If true will swap to Uniswap. If false will select
    ///        Chainlink (default).
    function useUniswap(bool select) external;

    /// @notice Set the Uniswap TWAP lookback period. If never called, default
    //          is 5m.
    /// @dev Only callable by auth'ed address.
    /// @dev Reverts if uniSecondsAgo less than minUniSecondsAgo.
    /// @param uniSecondsAgo Time in seconds used in the TWAP lookback.
    function setUniSecondsAgo(uint32 uniSecondsAgo) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IAuth {
    /// @notice Thrown by protected function if caller not auth'ed.
    /// @param caller The caller's address.
    error NotAuthorized(address caller);

    /// @notice Emitted when auth granted to address.
    /// @param caller The caller's address.
    /// @param who The address auth got granted to.
    event AuthGranted(address indexed caller, address indexed who);

    /// @notice Emitted when auth renounced from address.
    /// @param caller The caller's address.
    /// @param who The address auth got renounced from.
    event AuthRenounced(address indexed caller, address indexed who);

    /// @notice Grants address `who` auth.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to grant auth.
    function rely(address who) external;

    /// @notice Renounces address `who`'s auth.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to renounce auth.
    function deny(address who) external;

    /// @notice Returns whether address `who` is auth'ed.
    /// @param who The address to check.
    /// @return True if `who` is auth'ed, false otherwise.
    function authed(address who) external view returns (bool);

    /// @notice Returns full list of addresses granted auth.
    /// @dev May contain duplicates.
    /// @return List of addresses granted auth.
    function authed() external view returns (address[] memory);

    /// @notice Returns whether address `who` is auth'ed.
    /// @custom:deprecated Use `authed(address)(bool)` instead.
    /// @param who The address to check.
    /// @return 1 if `who` is auth'ed, 0 otherwise.
    function wards(address who) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IToll {
    /// @notice Thrown by protected function if caller not tolled.
    /// @param caller The caller's address.
    error NotTolled(address caller);

    /// @notice Emitted when toll granted to address.
    /// @param caller The caller's address.
    /// @param who The address toll got granted to.
    event TollGranted(address indexed caller, address indexed who);

    /// @notice Emitted when toll renounced from address.
    /// @param caller The caller's address.
    /// @param who The address toll got renounced from.
    event TollRenounced(address indexed caller, address indexed who);

    /// @notice Grants address `who` toll.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to grant toll.
    function kiss(address who) external;

    /// @notice Renounces address `who`'s toll.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to renounce toll.
    function diss(address who) external;

    /// @notice Returns whether address `who` is tolled.
    /// @param who The address to check.
    /// @return True if `who` is tolled, false otherwise.
    function tolled(address who) external view returns (bool);

    /// @notice Returns full list of addresses tolled.
    /// @dev May contain duplicates.
    /// @return List of addresses tolled.
    function tolled() external view returns (address[] memory);

    /// @notice Returns whether address `who` is tolled.
    /// @custom:deprecated Use `tolled(address)(bool)` instead.
    /// @param who The address to check.
    /// @return 1 if `who` is tolled, 0 otherwise.
    function bud(address who) external view returns (uint);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.17;

import 'uniswap/v3-core/contracts/libraries/FullMath.sol';
import 'uniswap/v3-core/contracts/libraries/TickMath.sol';
import 'uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, 'BP');

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) =
            IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta =
            secondsPerLiquidityCumulativeX128s[1] - secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, 'NI');

        (uint32 observationTimestamp, , , bool initialized) =
            IUniswapV3Pool(pool).observations((observationIndex + 1) % observationCardinality);

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        secondsAgo = uint32(block.timestamp) - observationTimestamp;
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool) internal view returns (int24, uint128) {
        (, int24 tick, uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, 'NEO');

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (uint32 observationTimestamp, int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128, ) =
            IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, 'ONI');

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - prevTickCumulative) / int56(uint56(delta)));
        uint128 liquidity =
            uint128(
                (uint192(delta) * type(uint160).max) /
                    (uint192(secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128) << 32)
            );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
        internal
        pure
        returns (int24 weightedArithmeticMeanTick)
    {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator += weightedTickData[i].tick * int256(int128(weightedTickData[i].weight));
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0)) weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, 'DL');
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i] ? syntheticTick += ticks[i - 1] : syntheticTick -= ticks[i - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.17;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = uint256(-int256(denominator) & int256(denominator));
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.17;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}