// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import './ChainlinkUSDMultiOracle.sol';


/**
 * @title ChainlinkL2USDMultiOracle: ChainlinkUSDMultiOracle that's safe to use on L2
 * @notice Chainlink recommends checking the sequencer status on some L2 networks to avoid
  reading stale data

  https://docs.chain.link/docs/l2-sequencer-flag/
 */
contract ChainlinkL2USDMultiOracle is ChainlinkUSDMultiOracle {
    using CastBytes32Bytes6 for bytes32;

    FlagsInterface public chainlinkFlags;
    // https://docs.chain.link/docs/l2-sequencer-flag/
    address internal constant FLAG_ARBITRUM_SEQ_OFFLINE =
        address(bytes20(bytes32(uint256(keccak256('chainlink.flags.arbitrum-seq-offline')) - 1)));

    constructor(FlagsInterface flags) {
        require(address(flags) != address(0), 'FlagsInterface has to be set');
        chainlinkFlags = flags;
    }

    modifier onlyFresh() {
        // If flag is raised we shouldn't perform any critical operations
        require(!chainlinkFlags.getFlag(FLAG_ARBITRUM_SEQ_OFFLINE), 'Chainlink feeds are not being updated');
        _;
    }

    /// @dev Convert amountBase base into quote at the latest oracle price.
    function peek(
        bytes32 baseId,
        bytes32 quoteId,
        uint256 amountBase
    ) external view virtual override onlyFresh returns (uint256 amountQuote, uint256 updateTime) {
        if (baseId == quoteId) return (amountBase, block.timestamp);

        (amountQuote, updateTime) = _peekThroughUSD(baseId.b6(), quoteId.b6(), amountBase);
    }

    /// @dev Convert amountBase base into quote at the latest oracle price, updating state if necessary. Same as `peek` for this oracle.
    function get(
        bytes32 baseId,
        bytes32 quoteId,
        uint256 amountBase
    ) external virtual override onlyFresh returns (uint256 amountQuote, uint256 updateTime) {
        if (baseId == quoteId) return (amountBase, block.timestamp);

        (amountQuote, updateTime) = _peekThroughUSD(baseId.b6(), quoteId.b6(), amountBase);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import '@yield-protocol/utils-v2/contracts/access/AccessControl.sol';
import '@yield-protocol/utils-v2/contracts/cast/CastBytes32Bytes6.sol';
import '@yield-protocol/utils-v2/contracts/token/IERC20Metadata.sol';
import '@yield-protocol/vault-interfaces/IOracle.sol';
import '../../constants/Constants.sol';
import './AggregatorV3Interface.sol';
import './FlagsInterface.sol';

/**
 * @title ChainlinkUSDMultiOracle
 * @notice Chainlink only uses USD or ETH as a quote in the aggregators, and we will use only USD
 */
contract ChainlinkUSDMultiOracle is IOracle, AccessControl, Constants {
    using CastBytes32Bytes6 for bytes32;

    event SourceSet(bytes6 indexed baseId, IERC20Metadata base, address indexed source);

    struct Source {
        address source;
        uint8 baseDecimals;
    }

    mapping(bytes6 => Source) public sources;

    /// @dev Set or reset an oracle source and its inverse
    function setSource(
        bytes6 baseId,
        IERC20Metadata base,
        address source
    ) external auth {
        require(AggregatorV3Interface(source).decimals() == 8, 'Non-8-decimals USD source');

        sources[baseId] = Source({source: source, baseDecimals: base.decimals()});
        emit SourceSet(baseId, base, source);
    }

    /// @dev Convert amountBase base into quote at the latest oracle price.
    function peek(
        bytes32 baseId,
        bytes32 quoteId,
        uint256 amountBase
    ) external view virtual override returns (uint256 amountQuote, uint256 updateTime) {
        if (baseId == quoteId) return (amountBase, block.timestamp);

        (amountQuote, updateTime) = _peekThroughUSD(baseId.b6(), quoteId.b6(), amountBase);
    }

    /// @dev Convert amountBase base into quote at the latest oracle price, updating state if necessary. Same as `peek` for this oracle.
    function get(
        bytes32 baseId,
        bytes32 quoteId,
        uint256 amountBase
    ) external virtual override returns (uint256 amountQuote, uint256 updateTime) {
        if (baseId == quoteId) return (amountBase, block.timestamp);

        (amountQuote, updateTime) = _peekThroughUSD(baseId.b6(), quoteId.b6(), amountBase);
    }

    /// @dev returns price for `baseId` in USD and base (not USD!) decimals
    function _getPriceInUSD(bytes6 baseId)
        private
        view
        returns (
            uint256 uintPrice,
            uint256 updateTime,
            uint8 baseDecimals
        )
    {
        int256 price;
        uint80 roundId;
        uint80 answeredInRound;
        Source memory source = sources[baseId];
        require(source.source != address(0), 'Source not found');
        (roundId, price, , updateTime, answeredInRound) = AggregatorV3Interface(source.source).latestRoundData();
        require(price > 0, 'Chainlink price <= 0');
        require(updateTime != 0, 'Incomplete round');
        require(answeredInRound >= roundId, 'Stale price');

        uintPrice = uint256(price);
        baseDecimals = source.baseDecimals;
    }

    /// @dev Convert amountBase base into quote at the latest oracle price, using USD as an intermediate step.
    function _peekThroughUSD(
        bytes6 baseId,
        bytes6 quoteId,
        uint256 amountBase
    ) internal view returns (uint256 amountQuote, uint256 updateTime) {
        (uint256 basePrice, uint256 updateTime1, uint8 baseDecimals) = _getPriceInUSD(baseId);
        (uint256 quotePrice, uint256 updateTime2, uint8 quoteDecimals) = _getPriceInUSD(quoteId);

        // decimals: baseDecimals * udcDecimals / usdDecimals
        amountQuote = (amountBase * basePrice) / quotePrice;

        // now need to convert baseDecimals to quoteDecimals
        if (baseDecimals <= quoteDecimals) {
            amountQuote *= (10**(quoteDecimals - baseDecimals));
        } else {
            amountQuote /= (10**(baseDecimals - quoteDecimals));
        }

        updateTime = (updateTime1 < updateTime2) ? updateTime1 : updateTime2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant ROOT4146650865 = 0x00000000; // Collision protection for ROOT, test with ROOT12007226833()
    bytes4 public constant LOCK = 0xFFFFFFFF;           // Used to disable further permissioning of a function
    bytes4 public constant LOCK8605463013 = 0xFFFFFFFF; // Collision protection for LOCK, test with LOCK10462387368()

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastBytes32Bytes6 {
    function b6(bytes32 x) internal pure returns (bytes6 y){
        require (bytes32(y = bytes6(x)) == x, "Cast overflow");
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

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
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations:
     * @return value in wei
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @return value in wei
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

contract Constants {
    bytes32 CHI = "CHI";
    bytes32 RATE = "RATE";
    bytes6 ETH = "00";
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/FlagsInterface.sol
interface FlagsInterface {
  function getFlag(address) external view returns (bool);

  function getFlags(address[] calldata) external view returns (bool[] memory);

  function raiseFlag(address) external;

  function raiseFlags(address[] calldata) external;

  function lowerFlags(address[] calldata) external;

  function setRaisingAccessController(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}