// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
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
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/binary/IBinaryMarket.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// solhint-disable-next-line
contract BinaryMarket is
    Pausable,
    IBinaryMarket,
    AccessControl,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    enum Position {
        Bull,
        Bear
    }

    struct TimeFrame {
        uint8 id;
        uint256 interval;
    }

    struct Round {
        uint256 epoch;
        uint256 startBlockTime; // start block time
        uint256 lockBlockTime; // lock block time
        uint256 closeBlockTime; // close block time
        uint256 lockPrice;
        uint256 closePrice;
        uint256 lockOracleTimestamp;
        uint256 closeOracleTimestamp;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        bool oracleCalled;
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    /// @dev Market Data
    string public marketName;
    IOracle public oracle;
    IBinaryVault public vault;

    IERC20 public underlyingToken;

    /// @dev Timeframes supported in this market.
    TimeFrame[] public timeframes;

    /// @dev Rounds per timeframe
    mapping(uint8 => mapping(uint256 => Round)) public rounds; // timeframe id => round id => round

    /// @dev bet info per user and round
    mapping(uint8 => mapping(uint256 => mapping(address => BetInfo)))
        public ledger; // timeframe id => round id => address => bet info

    // @dev user rounds per timeframe
    mapping(uint8 => mapping(address => uint256[])) public userRounds; // timeframe id => user address => round ids

    /// @dev This should be modified
    uint256 public minBetAmount;
    uint256 public oracleLatestTimestamp;
    uint256 public genesisStartBlockTimestamp;
    uint256 public futureBettingTimeUpTo = 6 hours;
    uint256 public bufferTime = 3 seconds;
    uint256 public bufferForRefund = 30 seconds;

    /// @dev default false
    bool public genesisStartOnce;
    /// @dev timeframe id => genesis locked? default false
    mapping(uint8 => bool) public genesisLockedOnce;

    event PositionOpened(
        string indexed marketName,
        address user,
        uint256 amount,
        uint8 timeframeId,
        uint256 roundId,
        Position position
    );

    event Claimed(
        string indexed marketName,
        address indexed user,
        uint8 timeframeId,
        uint256 indexed roundId,
        uint256 amount
    );

    event StartRound(
        uint8 indexed timeframeId,
        uint256 indexed epoch,
        uint256 startTime
    );
    event LockRound(
        uint8 indexed timeframeId,
        uint256 indexed epoch,
        uint256 indexed oracleTimestamp,
        uint256 price
    );
    event EndRound(
        uint8 indexed timeframeId,
        uint256 indexed epoch,
        uint256 indexed oracleTimestamp,
        uint256 price
    );

    event OracleChanged(address indexed oldOracle, address indexed newOracle);
    event MarketNameChanged(string oldName, string newName);
    event AdminChanged(address indexed admin, bool enabled);
    event OperatorChanged(address indexed operator, bool enabled);
    event MinBetAmountChanged(uint256 newAmount, uint256 oldAmount);

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "ONLY_ADMIN");
        _;
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender), "ONLY_OPERATOR");
        _;
    }

    constructor(
        IOracle oracle_,
        IBinaryVault vault_,
        string memory marketName_,
        TimeFrame[] memory timeframes_,
        uint256 minBetAmount_
    ) {
        require(address(oracle_) != address(0), "ZERO_ADDRESS");
        require(address(vault_) != address(0), "ZERO_ADDRESS");

        uint256 length = timeframes_.length;
        require(length > 0, "INVALID_ARRAY_LENGTH");

        oracle = oracle_;
        vault = vault_;

        marketName = marketName_;
        minBetAmount = minBetAmount_;

        for (uint256 i = 0; i < length; i = i + 1) {
            timeframes.push(timeframes_[i]);
        }

        underlyingToken = vault.underlyingToken();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    /**
     * @notice Set oracle of underlying token of this market
     * @dev Only owner can set the oracle
     * @param oracle_ New oracle address to set
     */
    function setOracle(IOracle oracle_) external onlyAdmin {
        require(address(oracle_) != address(0), "ZERO_ADDRESS");
        emit OracleChanged(address(oracle), address(oracle_));
        oracle = oracle_;
        oracleLatestTimestamp = 0;
    }

    /**
     * @notice Set name of this market
     * @dev Only owner can set name
     * @param name_ New name to set
     */
    function setName(string memory name_) external onlyAdmin {
        emit MarketNameChanged(marketName, name_);
        marketName = name_;
    }

    /**
     * @notice Set new admin of this market
     * @dev Only owner can set new admin
     * @param admin_ New admin to set
     */
    function setAdmin(address admin_, bool enable) external onlyAdmin {
        require(admin_ != address(0), "ZERO_ADDRESS");
        emit AdminChanged(admin_, enable);

        if (enable) {
            require(hasRole(DEFAULT_ADMIN_ROLE, admin_), "Already enabled.");
            grantRole(DEFAULT_ADMIN_ROLE, admin_);
        } else {
            require(!hasRole(DEFAULT_ADMIN_ROLE, admin_), "Already disabled.");
            revokeRole(DEFAULT_ADMIN_ROLE, admin_);
        }
    }

    /**
     * @notice Set new operator of this market
     * @dev Only admin can set new operator
     * @param operator_ New operator to set
     */
    function setOperator(address operator_, bool enable) external onlyAdmin {
        require(operator_ != address(0), "ZERO_ADDRESS");
        emit OperatorChanged(operator_, enable);

        if (enable) {
            require(!hasRole(OPERATOR_ROLE, operator_), "Already enabled.");
            grantRole(OPERATOR_ROLE, operator_);
        } else {
            require(hasRole(OPERATOR_ROLE, operator_), "Already disabled.");
            revokeRole(OPERATOR_ROLE, operator_);
        }
    }

    /**
     * @dev Change future betting allowed time
     */
    function setFutureBettingTimeUpTo(uint256 _time) external onlyAdmin {
        require(_time > 0, "INVALID_VALUE");
        futureBettingTimeUpTo = _time;
    }

    /**
     * @dev Get latest recorded price from oracle
     */
    function _getPriceFromOracle() internal returns (uint256, uint256) {
        (uint256 timestamp, uint256 price) = oracle.getLatestRoundData();
        require(timestamp >= oracleLatestTimestamp, "INVALID_ORACLE_TIMESTAMP");
        oracleLatestTimestamp = timestamp;
        return (timestamp, price);
    }

    function _writeOraclePrice(uint256 timestamp, uint256 price) internal {
        if (oracle.isWritable()) {
            uint256 _timestamp  = timestamp - (timestamp % 60); // Standardize
            oracle.writePrice(_timestamp, price);
        }
    }

    /**
     * @dev Start genesis round
     */
    function genesisStartRound() external onlyOperator whenNotPaused {
        require(!genesisStartOnce, "Can only run genesisStartRound once");

        // Gas efficient
        TimeFrame[] memory _timeframes = timeframes;
        uint256 length = _timeframes.length;
        // We have 1m, 5m and 15m timeframes. So we will set genesisStartBlockTime base on 15m timeframes.
        genesisStartBlockTimestamp =
            block.timestamp -
            (block.timestamp % _timeframes[2].interval);
        for (uint256 i = 0; i < length; i = i + 1) {
            _startRound(_timeframes[i].id, 0);
        }
        genesisStartOnce = true;
    }

    /**
     * @dev Lock genesis round
     */
    function genesisLockRound(uint8 timeframeId)
        external
        onlyOperator
        whenNotPaused
    {
        require(
            genesisStartOnce,
            "Can only run after genesisStartRound is triggered"
        );
        require(
            !genesisLockedOnce[timeframeId],
            "Can only run genesisLockRound once"
        );

        _writeOraclePrice(block.timestamp, 1 wei);
        (
            uint256 currentTimestamp,
            uint256 currentPrice
        ) = _getPriceFromOracle();
        uint256 currentEpoch = getCurrentRoundId(timeframeId);

        _safeLockRound(
            timeframeId,
            currentEpoch - 1,
            currentTimestamp,
            currentPrice
        );
        _startRound(timeframeId, currentEpoch);
        genesisLockedOnce[timeframeId] = true;
    }

    function _executeRound(
        uint8[] memory timeframeIds,
        uint256[] memory roundIds,
        uint256 price
    ) internal {
        require(
            genesisStartOnce,
            "Can only run after genesisStartRound is triggered"
        );
        uint256 length = timeframeIds.length;

        require(length <= timeframes.length, "Invalid timeframe ids length");
        // Update oracle price
        _writeOraclePrice(block.timestamp, price);

        (
            uint256 currentTimestamp,
            uint256 currentPrice
        ) = _getPriceFromOracle();

        for (uint8 i = 0; i < length; i = i + 1) {
            uint8 timeframeId = timeframeIds[i];
            if (genesisLockedOnce[timeframeId]) {
                uint256 currentEpoch = roundIds[i];

                // CurrentEpoch refers to previous round (n-1)
                _safeLockRound(
                    timeframeId,
                    currentEpoch - 1,
                    currentTimestamp,
                    currentPrice
                );
                _safeEndRound(
                    timeframeId,
                    currentEpoch - 2,
                    currentTimestamp,
                    currentPrice
                );

                // Increment currentEpoch to current round (n)
                _safeStartRound(timeframeId, currentEpoch);
            }
        }
    }

    /**
     * @dev Execute round
     */
    function executeRound(
        uint8[] memory timeframeIds,
        uint256[] memory roundIds,
        uint256 price
    ) external onlyOperator whenNotPaused {
        _executeRound(timeframeIds, roundIds, price);
    }

    /**
     * @dev Start the next round n, lock price for round n-1, end round n-2
     */
    function executeCurrentRound(uint8[] memory timeframeIds, uint256 price)
        external
        onlyOperator
        whenNotPaused
    {
        uint256 length = timeframeIds.length;
        uint256[] memory roundIds = new uint256[](length);

        for (uint8 i = 0; i < length; i++) {
            roundIds[i] = getCurrentRoundId(timeframeIds[i]);
        }

        _executeRound(timeframeIds, roundIds, price);
    }

    /**
     * @dev Start round
     * Previous locked round must end
     */
    function _safeStartRound(uint8 timeframeId, uint256 epoch) internal {
        // We use block time for all compare action.
        if (rounds[timeframeId][epoch - 2].closeBlockTime > 0) {
            require(
                block.timestamp >=
                    rounds[timeframeId][epoch - 2].closeBlockTime - bufferTime,
                "Can only start new round after locked round's closeBlock"
            );
        }

        if (rounds[timeframeId][epoch].startBlockTime == 0) {
            _startRound(timeframeId, epoch);
        }
    }

    function _startRound(uint8 timeframeId, uint256 epoch) internal {
        Round storage round = rounds[timeframeId][epoch];
        // We use block time instead of block number

        uint256 startTime = getBlockTimeForEpoch(timeframeId, epoch);

        round.startBlockTime = startTime;
        round.lockBlockTime = startTime + timeframes[timeframeId].interval;
        round.closeBlockTime = startTime + timeframes[timeframeId].interval * 2;

        round.epoch = epoch;

        emit StartRound(timeframeId, epoch, round.startBlockTime);
    }

    /**
     * @dev Lock round
     */
    function _safeLockRound(
        uint8 timeframeId,
        uint256 epoch,
        uint256 timestamp,
        uint256 price
    ) internal {
        uint256 lockBlockTime = rounds[timeframeId][epoch].lockBlockTime;

        if (
            lockBlockTime > 0 &&
            timestamp >= lockBlockTime - bufferTime &&
            timestamp <= lockBlockTime + 60
        ) {
            require(
                rounds[timeframeId][epoch].lockOracleTimestamp == 0,
                "Already locked."
            );
            _lockRound(timeframeId, epoch, timestamp, price);
        }
    }

    function _lockRound(
        uint8 timeframeId,
        uint256 epoch,
        uint256 timestamp,
        uint256 price
    ) internal {
        Round storage round = rounds[timeframeId][epoch];
        round.lockPrice = price;
        round.lockOracleTimestamp = timestamp;

        emit LockRound(timeframeId, epoch, timestamp, round.lockPrice);
    }

    /**
     * @dev End round
     */
    function _safeEndRound(
        uint8 timeframeId,
        uint256 epoch,
        uint256 timestamp,
        uint256 price
    ) internal {
        uint256 closeBlockTime = rounds[timeframeId][epoch].closeBlockTime;
        /// @dev We allow to write price between [closeBlockTime, close block time + 1m] only.
        if (
            closeBlockTime > 0 &&
            timestamp >= closeBlockTime - bufferTime &&
            timestamp <= closeBlockTime + 60 &&
            rounds[timeframeId][epoch].lockOracleTimestamp > 0
        ) {
            // Already startd and locked round
            require(!rounds[timeframeId][epoch].oracleCalled, "Already ended.");
            _endRound(timeframeId, epoch, timestamp, price);
        }
    }

    function _endRound(
        uint8 timeframeId,
        uint256 epoch,
        uint256 timestamp,
        uint256 price
    ) internal {
        Round storage round = rounds[timeframeId][epoch];
        round.closePrice = price;
        round.closeOracleTimestamp = timestamp;
        round.oracleCalled = true;

        // Update vault deposited amount based on bet results
        bool isBull = round.closePrice > round.lockPrice;
        bool isBear = round.closePrice < round.lockPrice;

        uint256 willClaimAmount = 0;
        uint256 willDepositAmount = 0;

        if (isBull) {
            willClaimAmount = round.bullAmount;
            willDepositAmount = round.bearAmount;
        }
        if (isBear) {
            willClaimAmount = round.bearAmount;
            willDepositAmount = round.bullAmount;
        }

        if (!isBull && !isBear) {
            willDepositAmount = round.bullAmount + round.bearAmount;
        }

        if (willDepositAmount > willClaimAmount) {
            vault.onTraderLose(willDepositAmount - willClaimAmount);
        }

        if (willDepositAmount < willClaimAmount) {
            vault.onTraderWin(willClaimAmount - willDepositAmount);
        }

        emit EndRound(timeframeId, epoch, timestamp, round.closePrice);
    }

    /**
     * @dev Current bettable amount.
     * This should be calculated based on vault hourly exposure amount, and current existing bets in all timeframes.
     */
    function getCurrentBettableAmount(uint8 timeframeId, uint256 epoch)
        public
        view
        returns (uint256)
    {
        uint256 maxHourlyExposure = vault.getMaxHourlyExposure();
        uint256 maxMinuteExposure = maxHourlyExposure / 60;
        if (maxMinuteExposure == 0) {
            return 0;
        }

        uint256 currentEpoch = getCurrentRoundId(timeframeId);
        // Ahead betting
        if (epoch > currentEpoch) {
            if (!vault.isFutureBettingAvailable()) {
                return 0;
            }
        }

        uint256 bullAmount;
        uint256 bearAmount;

        uint256 startBlockTime = getBlockTimeForEpoch(timeframeId, epoch);

        // Gas efficient
        TimeFrame[] memory _timeframes = timeframes;
        uint256 length = _timeframes.length;

        for (uint256 i; i < length; i++) {
            uint8 _timeframeId = _timeframes[i].id;
            // Get close block time for this round
            uint256 _epoch = getRoundIdAt(_timeframeId, startBlockTime);
            // Get round
            Round memory round = rounds[_timeframeId][_epoch];
            bullAmount += round.bullAmount;
            bearAmount += round.bearAmount;
        }

        uint256 risk = bullAmount > bearAmount
            ? bullAmount - bearAmount
            : bearAmount - bullAmount;

        if (risk >= maxMinuteExposure) {
            return 0;
        } else {
            if (epoch > currentEpoch) {
                // ahead betting
                return (maxMinuteExposure - risk) / 2;
            } else {
                return maxMinuteExposure - risk;
            }
        }
    }

    /**
     * @dev Bet bear position
     * @param amount Bet amount
     * @param timeframeId id of 1m/5m/10m
     * @param position bull/bear
     */
    function openPosition(
        uint256 amount,
        uint8 timeframeId,
        uint256 epoch,
        Position position
    ) external whenNotPaused {
        require(
            genesisStartOnce && genesisLockedOnce[timeframeId],
            "Can only place bet after genesisStartOnce and genesisLockedOnce"
        );

        underlyingToken.safeTransferFrom(msg.sender, address(vault), amount);

        require(
            amount >= minBetAmount,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[timeframeId][epoch][msg.sender].amount == 0,
            "Can only bet once per round"
        );

        if (rounds[timeframeId][epoch].startBlockTime == 0) {
            _startRound(timeframeId, epoch);
        }
        require(_bettable(timeframeId, epoch), "Round not bettable");

        // Get current bettable amount based on binary vault state
        uint256 currentBettableAmount = getCurrentBettableAmount(
            timeframeId,
            epoch
        );
        require(
            amount <= currentBettableAmount,
            "Bet amount exceeds current vault's capacity."
        );

        // Update round data
        Round storage round = rounds[timeframeId][epoch];
        round.totalAmount = round.totalAmount + amount;

        if (position == Position.Bear) {
            round.bearAmount = round.bearAmount + amount;
        } else {
            round.bullAmount = round.bullAmount + amount;
        }

        // Update user data
        BetInfo storage betInfo = ledger[timeframeId][epoch][msg.sender];
        betInfo.position = position;
        betInfo.amount = amount;
        userRounds[timeframeId][msg.sender].push(epoch);

        emit PositionOpened(
            marketName,
            msg.sender,
            amount,
            timeframeId,
            epoch,
            position
        );
    }

    function _claim(uint8 timeframeId, uint256 epoch) internal {
        // We use block time
        require(
            block.timestamp > rounds[timeframeId][epoch].closeBlockTime,
            "Round has not ended"
        );
        require(
            !ledger[timeframeId][epoch][msg.sender].claimed,
            "Rewards claimed"
        );

        uint256 rewardAmount = 0;
        BetInfo storage betInfo = ledger[timeframeId][epoch][msg.sender];

        // Round valid, claim rewards
        if (rounds[timeframeId][epoch].oracleCalled) {
            require(
                isClaimable(timeframeId, epoch, msg.sender),
                "Not eligible for claim"
            );
            rewardAmount = betInfo.amount * 2;
        }
        // Round invalid, refund bet amount
        else {
            require(
                refundable(timeframeId, epoch, msg.sender),
                "Not eligible for refund"
            );

            rewardAmount = betInfo.amount;
        }

        betInfo.claimed = true;
        vault.claimBettingRewards(msg.sender, rewardAmount);

        emit Claimed(marketName, msg.sender, timeframeId, epoch, rewardAmount);
    }

    /**
     * @notice claim winning rewards
     * @param timeframeId Timeframe ID to claim winning rewards
     * @param epoch round id
     */
    function claim(uint8 timeframeId, uint256 epoch) external nonReentrant {
        _claim(timeframeId, epoch);
    }

    /**
     * @notice Batch claim winning rewards
     * @param timeframeIds Timeframe IDs to claim winning rewards
     * @param epochs round ids
     */
    function claimBatch(uint8[] memory timeframeIds, uint256[][] memory epochs)
        external
        nonReentrant
    {
        uint256 tLength = timeframeIds.length;
        require(tLength == epochs.length, "INVALID_ARRAY_LENGTH");

        for (uint256 i = 0; i < tLength; i = i + 1) {
            uint8 timeframeId = timeframeIds[i];
            uint256 eLength = epochs[i].length;

            for (uint256 j = 0; j < eLength; j = j + 1) {
                _claim(timeframeId, epochs[i][j]);
            }
        }
    }

    /**
     * @dev Get the claimable stats of specific epoch and user account
     */
    function isClaimable(
        uint8 timeframeId,
        uint256 epoch,
        address user
    ) public view returns (bool) {
        BetInfo memory betInfo = ledger[timeframeId][epoch][user];
        Round memory round = rounds[timeframeId][epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
            round.oracleCalled &&
            betInfo.amount > 0 &&
            !betInfo.claimed &&
            ((round.closePrice > round.lockPrice &&
                betInfo.position == Position.Bull) ||
                (round.closePrice < round.lockPrice &&
                    betInfo.position == Position.Bear));
    }

    /**
     * @dev Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current block must be within startBlock and closeBlock
     */
    function _bettable(uint8 timeframeId, uint256 epoch)
        internal
        view
        returns (bool)
    {
        // start time for epoch
        uint256 timestamp = getBlockTimeForEpoch(timeframeId, epoch);

        // not bettable if current block time is after lock time
        if (
            block.timestamp >=
            timestamp + timeframes[timeframeId].interval - bufferTime
        ) {
            return false;
        }

        if (timestamp > block.timestamp + futureBettingTimeUpTo) {
            return false;
        }

        return rounds[timeframeId][epoch].lockOracleTimestamp == 0;
    }

    /**
     * @dev Get the refundable stats of specific epoch and user account
     */
    function refundable(
        uint8 timeframeId,
        uint256 epoch,
        address user
    ) public view returns (bool) {
        // fixme now imagine that people will refund their lost bets. We need to do some interval between close timestamp and us writing close price. Let's say you can refund if we don't write price within 30minutes after close timestamp.
        // legendary - Yes, I agree. We can set buffer block for each timeframe.
        BetInfo memory betInfo = ledger[timeframeId][epoch][user];
        Round memory round = rounds[timeframeId][epoch];
        return
            !round.oracleCalled &&
            block.timestamp > round.closeBlockTime + bufferForRefund &&
            betInfo.amount > 0;
    }

    /**
     * @dev Pause/unpause
     */

    function setPause(bool value) external onlyOperator {
        if (value) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev set minBetAmount
     * callable by admin
     */
    function setMinBetAmount(uint256 _minBetAmount) external onlyAdmin {
        emit MinBetAmountChanged(_minBetAmount, minBetAmount);
        minBetAmount = _minBetAmount;
    }

    function isNecessaryToExecute(uint8 timeframeId)
        public
        view
        returns (bool)
    {
        if (!genesisLockedOnce[timeframeId] || !genesisStartOnce) {
            return false;
        }

        uint256 currentEpoch = getCurrentRoundId(timeframeId);

        Round memory round = rounds[timeframeId][currentEpoch];
        Round memory currentRound = rounds[timeframeId][currentEpoch - 1];
        Round memory prevRound = rounds[timeframeId][currentEpoch - 2];

        uint256 lockBlockTimeOfCurrentRound = getBlockTimeForEpoch(timeframeId, currentEpoch - 1) + timeframes[timeframeId].interval;

        // We use block time
        bool lockable = currentRound.lockOracleTimestamp == 0 &&
            block.timestamp >= lockBlockTimeOfCurrentRound &&
            block.timestamp <= lockBlockTimeOfCurrentRound + 60;

        bool closable = !prevRound.oracleCalled &&
            block.timestamp >= lockBlockTimeOfCurrentRound;

        // FIXME if we start backend after some failure, prev round will not have oracleCalled, how we can execute first round?
        // Answer If backend cannot start within a minute, it should be refundable. What do you think?
        return
            lockable &&
            closable &&
            (currentRound.totalAmount > 0 ||
                prevRound.totalAmount > 0 ||
                round.totalAmount > 0);
    }

    /**
        @dev check if bet is active
     */

    function getExecutableTimeframes()
        external
        view
        returns (uint8[] memory result)
    {
        // gas optimized
        TimeFrame[] memory _timeframes = timeframes;
        uint256 length = _timeframes.length;

        result = new uint8[](length);
        uint256 count;

        for (uint256 i = 0; i < length; i = i + 1) {
            uint8 timeframeId = _timeframes[i].id;

            if (isNecessaryToExecute(timeframeId)) {
                result[count] = timeframeId;
                count = count + 1;
            }
        }

        uint256 toDrop = length - count;
        if (toDrop > 0) {
            // solhint-disable-next-line
            assembly {
                mstore(result, sub(mload(result), toDrop))
            }
        }
    }

    /**
     * @dev Return round epochs that a user has participated in specific timeframe
     */
    function getUserRounds(
        uint8 timeframeId,
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > userRounds[timeframeId][user].length - cursor) {
            length = userRounds[timeframeId][user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[timeframeId][user][cursor + i];
        }

        return (values, cursor + length);
    }

    /**
     * @dev Calculate current round based on genesis timestamp and block number
     * @param timeframeId timeframe id what we want to get round number
     */
    function getCurrentRoundId(uint8 timeframeId)
        public
        view
        returns (uint256 roundFromBlockTime)
    {
        return getRoundIdAt(timeframeId, block.timestamp);
    }

    /**
     * @dev Calculate round id for specific timestamp and block
     */
    function getRoundIdAt(uint8 timeframeId, uint256 timestamp)
        public
        view
        returns (uint256 roundFromBlockTime)
    {
        roundFromBlockTime =
            (timestamp - genesisStartBlockTimestamp) /
            timeframes[timeframeId].interval;
    }

    /**
     * @dev Get block from epoch
     */
    function getBlockTimeForEpoch(uint8 timeframeId, uint256 epoch)
        public
        view
        returns (uint256 timestamp)
    {
        timestamp =
            genesisStartBlockTimestamp +
            epoch *
            timeframes[timeframeId].interval;
    }

    /**
     * @dev Check if round is bettable
     */
    function isBettable(uint8 timeframeId, uint256 epoch)
        external
        view
        returns (bool)
    {
        return _bettable(timeframeId, epoch);
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the user role.
    function isOperator(address account) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    /// @dev Set buffer time
    function setBufferTime(uint256 _bufferTime, uint256 _bufferForRefund)
        external
        onlyOperator
    {
        bufferTime = _bufferTime;
        bufferForRefund = _bufferForRefund;
    }
}

// SPDX-License-Identifier: MIT
import "./IOracle.sol";
import "./IBinaryVault.sol";

pragma solidity 0.8.16;

interface IBinaryMarket {
    function oracle() external view returns (IOracle);

    function vault() external view returns (IBinaryVault);

    function marketName() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBinaryVault {
    function underlyingToken() external view returns (IERC20);

    function claimBettingRewards(address to, uint256 amount) external;

    function onTraderLose(uint256 amount) external;

    function onTraderWin(uint256 amount) external;

    function totalDepositedAmount() external view returns (uint256);

    function getMaxHourlyExposure() external view returns (uint256);

    function getCurrentPendingWithdrawalAmount()
        external
        view
        returns (uint256 shareAmount, uint256 underlyingTokenAmount);

    function isFutureBettingAvailable() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IOracle {
    function getLatestRoundData()
        external
        view
        returns (uint256 timestamp, uint256 price);

    function pairName() external view returns (string memory);

    function isWritable() external view returns (bool);

    function writePrice(uint256 timestamp, uint256 price) external;
}