// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title ConfigOptions
 * @notice A central place for enumerating the configurable options of our HelixConfig contract
 * @author Helix
 */

library HelixConfigOptions {
  // NEVER EVER CHANGE THE ORDER OF THESE!
  // You can rename or append. But NEVER change the order.
  enum Numbers {
    TransactionLimit, // 0
    MinimumInvestment, //  1
    MaxUnderwriterLimit, // 2
    ReserveDenominator, // 3 
    WithdrawFeeDenominator, // 4
    LatenessGracePeriodInDays, // 5
    LatenessMaxDays, // 6
    TransferRestrictionPeriodInDays, // 7
    LeverageRatio, // 8
    JuniorRatioSlippage // 9
  }
  /// @dev TrustedForwarder is deprecated because we no longer use GSN. CreditDesk
  ///   and Pool are deprecated because they are no longer used in the protocol.
  enum Addresses {
    HelixFactory,
    USDC,
    HELIX,
    TreasuryReserve,
    ProtocolAdmin,
    // OneInch,
    // CUSDCContract,
    HelixConfig,
    CreditLineImplementation,
    TranchedPoolShareImplementation,
    TranchedPoolImplementation,
    TranchedPoolImplementationRepository,
    PoolSharesImplementationRepository,
    BorrowerImplementation,
    Go,
    JuniorRewards,
    UniTranchedPoolImplementationRepository
    // StakingRewards
    // FiduUSDCCurveLP
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/HelixConfigHelper.sol";
import "../upgradeable/BaseUpgradeablePausable.sol";
import "../libraries/BulletAccountantV2.sol";
import "../interfaces/IERC20withDec.sol";
import "../interfaces/IHelixCreditLineV3.sol";
import "../interfaces/IHelixConfig.sol";

import "../interfaces/IHelixInterestModel.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title CreditLine
 * @notice A contract that represents the agreement between Backers and
 *  a Borrower. Includes the terms of the loan, as well as the current accounting state, such as interest owed.
 *  A CreditLine belongs to a TranchedPool, and is fully controlled by that TranchedPool. It does not
 *  operate in any standalone capacity. It should generally be considered internal to the TranchedPool.
 * @author Goldfinch
 */

// solhint-disable-next-line max-states-count
contract HelixBulletCreditLineV3 is BaseUpgradeablePausable, IHelixCreditLineV3 {

  uint256 private constant INTEREST_DECIMALS = 1e18;
  uint256 private constant SECONDS_PER_DAY = 1 days;
  uint256 private constant SECONDS_PER_YEAR = SECONDS_PER_DAY * 365;

  // Credit line terms
  address public override borrower;
  uint256 public currentLimit;
  uint256 public override maxLimit;
  uint256 public override minLimit;
  uint256 public override interestApr;
  uint256 public override paymentPeriodInDays;
  uint256 public override termInDays;
  uint256 public override principalGracePeriodInDays;
  uint256 public override lateFeeApr;
  uint256 public override fundingDate;
  bytes32 public override fileHash;
  
  // Accounting variables
  uint256 public override balance;
  uint256 public override interestOwed;
  uint256 public override principalOwed;
  uint256 public override termEndTime;
  uint256 public override nextDueTime;
  uint256 public override interestAccruedAsOf;
  uint256 public override lastFullPaymentTime;
  uint256 public override totalInterestAccrued;

  IHelixInterestModel public interestModel;
  IHelixConfig public config;
  using HelixConfigHelper for IHelixConfig;

  event SetFileHash(bytes32 newFileHash);
  event TestCreditLine(uint256,uint256,uint256,uint256,uint256);
  event TestCreditLine2(bool);

  function initialize(
    address _interestModel,
    address _config,
    address owner,
    address _borrower,
    uint256 _maxLimit,
    uint256 _minLimit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundingDate
  ) public override initializer {
    require(_config != address(0) && owner != address(0) && _borrower != address(0), "Zero address passed in");
    require(_minLimit <= _maxLimit, "Min limit must be less than or equal max limit");
    __BaseUpgradeablePausable__init(owner);
    interestModel = IHelixInterestModel(_interestModel);
    config = IHelixConfig(_config);
    borrower = _borrower;
    maxLimit = _maxLimit;
    minLimit = _minLimit;
    interestApr = _interestApr;
    paymentPeriodInDays = _paymentPeriodInDays;
    termInDays = _termInDays;
    lateFeeApr = _lateFeeApr;
    principalGracePeriodInDays = _principalGracePeriodInDays;
    interestAccruedAsOf = block.timestamp;
    fundingDate = _fundingDate;

    // Unlock owner, which is a TranchedPool, for infinite amount
    bool success = config.getUSDC().approve(owner, type(uint256).max);
    require(success, "Failed to approve USDC");
  }

  function limit() external view override returns (uint256) {
    return currentLimit;
  }

  /**
   * @notice Updates the internal accounting to track a drawdown as of current block timestamp.
   * Does not move any money
   * @param amount The amount in USDC that has been drawndown
   */
  function drawdown(uint256 amount, uint256 startAccured) external override onlyAdmin {
    // uint256 timestamp = currentTime();
    emit TestCreditLine(termEndTime, startAccured, amount, balance, currentLimit);
    require(termEndTime == 0 || (startAccured < termEndTime), "After termEndTime");
    require(amount + balance <= currentLimit, "Cannot drawdown more than the limit");
    require(amount > 0, "Invalid drawdown amount");
    emit TestCreditLine2(_isLate(startAccured));
    return;
    if (balance == 0) {
      setInterestAccruedAsOf(startAccured);
      setLastFullPaymentTime(startAccured);
      setTotalInterestAccrued(0);
      // Set termEndTime only once to prevent extending
      // the loan's end time on every 0 balance drawdown
      if (termEndTime == 0) {
        setTermEndTime(startAccured + termInDays);
      }
    }

    (uint256 _interestOwed, uint256 _principalOwed) = _updateAndGetInterestAndPrincipalOwedAsOf(startAccured);
    balance = balance + amount;

    updateCreditLineAccounting(balance, _interestOwed, _principalOwed);
    require(!_isLate(startAccured), "Cannot drawdown when payments are past due");
  }

  function setFileHash(bytes32 newFileHash) external override onlyAdmin {
    fileHash = newFileHash;
    emit SetFileHash(newFileHash);
  }

  function setFundingDate(uint256 newFundingDate) external override onlyAdmin {
    fundingDate = newFundingDate;
  }

  function setLateFeeApr(uint256 newLateFeeApr) external override onlyAdmin {
    lateFeeApr = newLateFeeApr;
  }

  function setLimit(uint256 newAmount) external override onlyAdmin {
    require(newAmount <= maxLimit, "Cannot be more than the max limit");
    currentLimit = newAmount;
  }

  function setMaxLimit(uint256 newAmount) external override onlyAdmin {
    maxLimit = newAmount;
  }

  function termStartTime() external override view returns (uint256) {
    return _termStartTime();
  }

  function isLate() external view override returns (bool) {
    return _isLate(block.timestamp);
  }

  function withinPrincipalGracePeriod() external view override returns (bool) {
    if (termEndTime == 0) {
      // Loan hasn't started yet
      return true;
    }
    return block.timestamp < _termStartTime() + principalGracePeriodInDays;
  }

  function setTermEndTime(uint256 newTermEndTime) public override onlyAdmin {
    termEndTime = newTermEndTime;
  }

  function setNextDueTime(uint256 newNextDueTime) public override onlyAdmin {
    nextDueTime = newNextDueTime;
  }

  function setBalance(uint256 newBalance) public override onlyAdmin {
    balance = newBalance;
  }

  function setTotalInterestAccrued(uint256 _totalInterestAccrued) public override onlyAdmin {
    totalInterestAccrued = _totalInterestAccrued;
  }

  function setInterestOwed(uint256 newInterestOwed) public override onlyAdmin {
    interestOwed = newInterestOwed;
  }

  function setPrincipalOwed(uint256 newPrincipalOwed) public override onlyAdmin {
    principalOwed = newPrincipalOwed;
  }

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) public override onlyAdmin {
    interestAccruedAsOf = newInterestAccruedAsOf;
  }

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) public override onlyAdmin {
    lastFullPaymentTime = newLastFullPaymentTime;
  }

  function setInterestModel(address _interestModel) public override onlyAdmin {
    interestModel = IHelixInterestModel(_interestModel);
  }

  /**
   * @notice Triggers an assessment of the creditline. Any USDC balance available in the creditline is applied
   * towards the interest and principal.
   * @return Any amount remaining after applying payments towards the interest and principal
   * @return Amount applied towards interest
   * @return Amount applied towards principal
   */
  function assess()
    public
    override
    onlyAdmin
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // Do not assess until a full period has elapsed or past due
    require(balance > 0, "Must have balance to assess credit line");


    // Don't assess credit lines early!
    if (currentTime() < nextDueTime && !_isLate(currentTime())) {
      return (0, 0, 0);
    }
    uint256 timeToAssess = calculateNextDueTime();
    setNextDueTime(timeToAssess);

    // We always want to assess for the most recently *past* nextDueTime.
    // So if the recalculation above sets the nextDueTime into the future,
    // then ensure we pass in the one just before this.
    if (timeToAssess > currentTime()) {
      uint256 secondsPerPeriod = paymentPeriodInDays;
      timeToAssess = timeToAssess - secondsPerPeriod;
    }
    return handlePayment(_getUSDCBalance(address(this)), timeToAssess);
  }

  function calculateNextDueTime() public view returns (uint256) {
    uint256 newNextDueTime = nextDueTime;
    uint256 secondsPerPeriod = paymentPeriodInDays;
    uint256 curTimestamp = currentTime();
    // You must have just done your first drawdown
    if (newNextDueTime == 0 && balance > 0) {
      return fundingDate + secondsPerPeriod;
    }

    // Active loan that has entered a new period, so return the *next* newNextDueTime.
    // But never return something after the termEndTime
    if (balance > 0 && curTimestamp >= newNextDueTime) {
      uint256 secondsToAdvance = ((curTimestamp - newNextDueTime) / secondsPerPeriod + 1) * secondsPerPeriod;
      newNextDueTime = newNextDueTime + secondsToAdvance;
      return Math.min(newNextDueTime, termEndTime);
    }

    // You're paid off, or have not taken out a loan yet, so no next due time.
    if (balance == 0 && newNextDueTime != 0) {
      return 0;
    }
    // Active loan in current period, where we've already set the newNextDueTime correctly, so should not change.
    if (balance > 0 && curTimestamp < newNextDueTime) {
      return newNextDueTime;
    }
    revert("Error: could not calculate next due time.");
  }

  function currentTime() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function _isLate(uint256 timestamp) internal view returns (bool) {
    uint256 secondsElapsedSinceFullPayment = timestamp - lastFullPaymentTime;
    return balance > 0 && secondsElapsedSinceFullPayment > paymentPeriodInDays;
  }

  function _termStartTime() internal view returns (uint256) {
    return termEndTime - termInDays;
  }

  /**
   * @notice Applies `amount` of payment for a given credit line. This moves already collected money into the Pool.
   *  It also updates all the accounting variables. Note that interest is always paid back first, then principal.
   *  Any extra after paying the minimum will go towards existing principal (reducing the
   *  effective interest rate). Any extra after the full loan has been paid off will remain in the
   *  USDC Balance of the creditLine, where it will be automatically used for the next drawdown.
   * @param paymentAmount The amount, in USDC atomic units, to be applied
   * @param timestamp The timestamp on which accrual calculations should be based. This allows us
   *  to be precise when we assess a Credit Line
   */
  function handlePayment(uint256 paymentAmount, uint256 timestamp)
    internal
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 newInterestOwed, uint256 newPrincipalOwed) = _updateAndGetInterestAndPrincipalOwedAsOf(timestamp);



    BulletAccountantV2.PaymentAllocation memory pa = BulletAccountantV2.allocatePayment(
      paymentAmount,
      balance,
      newInterestOwed,
      newPrincipalOwed
    );

    uint256 newBalance = balance - pa.principalPayment;
    // Apply any additional payment towards the balance
    newBalance = newBalance - pa.additionalBalancePayment;
    uint256 totalPrincipalPayment = balance - newBalance;
    uint256 paymentRemaining = paymentAmount - pa.interestPayment - totalPrincipalPayment;











    updateCreditLineAccounting(
      newBalance,
      newInterestOwed - pa.interestPayment,
      newPrincipalOwed - pa.principalPayment
    );

    assert(paymentRemaining + pa.interestPayment + totalPrincipalPayment == paymentAmount);

    return (paymentRemaining, pa.interestPayment, totalPrincipalPayment);
  }

  function _updateAndGetInterestAndPrincipalOwedAsOf(uint256 timestamp) internal returns (uint256, uint256) {
    (uint256 interestAccrued, uint256 principalAccrued) = BulletAccountantV2.calculateInterestAndPrincipalAccrued(
      this,
      interestModel,
      timestamp,
      config.getLatenessGracePeriodInDays()
    );
    if (interestAccrued > 0) {
      // If we've accrued any interest, update interestAccruedAsOf to the time that we've
      // calculated interest for. If we've not accrued any interest, then we keep the old value so the next
      // time the entire period is taken into account.
      setInterestAccruedAsOf(timestamp);
      totalInterestAccrued = totalInterestAccrued + interestAccrued;
    }
    return (interestOwed + interestAccrued, principalOwed + principalAccrued);
  }

  function updateCreditLineAccounting(
    uint256 newBalance,
    uint256 newInterestOwed,
    uint256 newPrincipalOwed
  ) internal nonReentrant {
    setBalance(newBalance);
    setInterestOwed(newInterestOwed);
    setPrincipalOwed(newPrincipalOwed);

    // This resets lastFullPaymentTime. These conditions assure that they have
    // indeed paid off all their interest and they have a real nextDueTime. (ie. creditline isn't pre-drawdown)
    uint256 _nextDueTime = nextDueTime;
    if (newInterestOwed == 0 && _nextDueTime != 0) {
      // If interest was fully paid off, then set the last full payment as the previous due time
      uint256 mostRecentLastDueTime;
      if (currentTime() < _nextDueTime) {
        uint256 secondsPerPeriod = paymentPeriodInDays;
        mostRecentLastDueTime = _nextDueTime - secondsPerPeriod;
      } else {
        mostRecentLastDueTime = _nextDueTime;
      }
      setLastFullPaymentTime(mostRecentLastDueTime);
    }

    setNextDueTime(calculateNextDueTime());
  }

  function _getUSDCBalance(address _address) internal view returns (uint256) {
    return config.getUSDC().balanceOf(_address);
  }

  function calculatePayAmount() public view returns (uint256, uint256, uint256, uint8) {
    uint256 timeToAssess = calculateNextDueTime();
    if (timeToAssess > currentTime()) {
      uint256 secondsPerPeriod = paymentPeriodInDays;
      timeToAssess = timeToAssess - secondsPerPeriod;
    }
    (uint256 _interestOwed, uint256 _principalOwed, uint256 _lateFeeAccrued, uint8 status) = BulletAccountantV2.calculateInterestAndLateFeeAndPrincipalAccruedAndPaymentStatus(
      this,
      interestModel,
      timeToAssess,
      config.getLatenessGracePeriodInDays()
    );

    if(interestOwed+_interestOwed > 0){
      return(interestOwed+_interestOwed, _principalOwed, _lateFeeAccrued, status);
    }
    // if pay all interestOwed, calculate interestOwed in the next due time
    timeToAssess = calculateNextDueTime();
    (_interestOwed, _principalOwed, _lateFeeAccrued,) = BulletAccountantV2.calculateInterestAndLateFeeAndPrincipalAccruedAndPaymentStatus(
      this,
      interestModel,
      timeToAssess,
      config.getLatenessGracePeriodInDays()
    );
    return (interestOwed + _interestOwed, _principalOwed, _lateFeeAccrued, uint8(BulletAccountantV2.PaymentStatus.Upcoming));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20withDec is IERC20 {
  /**
   * @dev Returns the number of decimals used for the token
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IHelixConfig {
  function goList(address member) external view returns (bool);

  function getNumber(uint256 index) external view returns (uint256);

  function getAddress(uint256 index) external view returns (address);

  function setAddress(uint256 index, address newAddress) external returns (address);

  function setNumber(uint256 index, uint256 newNumber) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IHelixCreditLine {
  function borrower() external view returns (address);

  function limit() external view returns (uint256);

  function minLimit() external view returns (uint256);

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriodInDays() external view returns (uint256);

  function principalGracePeriodInDays() external view returns (uint256);

  function termInDays() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function isLate() external view returns (bool);

  function withinPrincipalGracePeriod() external view returns (bool);

  // Accounting variables
  function balance() external view returns (uint256);

  function interestOwed() external view returns (uint256);

  function principalOwed() external view returns (uint256);

  function termEndTime() external view returns (uint256);

  function nextDueTime() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IHelixCreditLine.sol";

abstract contract IHelixCreditLineV3 is IHelixCreditLine {
  // function principal() external view virtual returns (uint256);

  function fileHash() external view virtual returns (bytes32);

  function fundingDate() external view virtual returns (uint256);

  function setFundingDate(uint256 newFundingDate) external virtual;

  function totalInterestAccrued() external view virtual returns (uint256);

  function termStartTime() external view virtual returns (uint256);

  function setLimit(uint256 newAmount) external virtual;

  function setMaxLimit(uint256 newAmount) external virtual;

  function setBalance(uint256 newBalance) external virtual;

  // function setPrincipal(uint256 _principal) external virtual;

  function setTotalInterestAccrued(uint256 _interestAccrued) external virtual;

  function drawdown(uint256 amount, uint256 startAccured) external virtual;

  function assess()
    external
    virtual
    returns (
      uint256,
      uint256,
      uint256
    );

  function initialize(
    address _interestModel,
    address _config,
    address owner,
    address _borrower,
    uint256 _maxTarget,
    uint256 _minTarget,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundingDate
  ) public virtual;

  function setInterestModel(address _interestModel) external virtual;

  function setTermEndTime(uint256 newTermEndTime) external virtual;

  function setNextDueTime(uint256 newNextDueTime) external virtual;

  function setInterestOwed(uint256 newInterestOwed) external virtual;

  function setPrincipalOwed(uint256 newPrincipalOwed) external virtual;

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) external virtual;

  // function setWritedownAmount(uint256 newWritedownAmount) external virtual;

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) external virtual;

  function setLateFeeApr(uint256 newLateFeeApr) external virtual;
  
  function setFileHash(bytes32 newFileHash) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IHelixFactory {
  function createCreditLine() external returns (address);

  function createPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);

  function updateHelixConfig() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract IHelixGo {
  uint256 public constant ID_TYPE_0 = 0;
  uint256 public constant ID_TYPE_1 = 1;
  uint256 public constant ID_TYPE_2 = 2;
  uint256 public constant ID_TYPE_3 = 3;
  uint256 public constant ID_TYPE_4 = 4;
  uint256 public constant ID_TYPE_5 = 5;
  uint256 public constant ID_TYPE_6 = 6;
  uint256 public constant ID_TYPE_7 = 7;
  uint256 public constant ID_TYPE_8 = 8;
  uint256 public constant ID_TYPE_9 = 9;
  uint256 public constant ID_TYPE_10 = 10;

  /// @notice Returns the address of the UniqueIdentity contract.
  function uniqueIdentity() external virtual returns (address);

  function go(address account) public view virtual returns (bool);

  function goOnlyIdTypes(address account, uint256[] calldata onlyIdTypes) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IHelixInterestModel {
    function calculateInterestAccruedOverTimes(
        uint256 _amount,
        uint256 _interestRate,
        uint256 _secondElapsed
    ) external pure returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
interface IHelixJuniorRewards {
  function allocateRewards(uint256 _interestPaymentAmount) external;

  function onTranchedPoolDrawdown(uint256 sliceIndex) external;

  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(address poolAddress, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IHelixInterestModel.sol";
import "../interfaces/IHelixCreditLineV3.sol";
import "./WadRayMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

/**
 * @title The Accountant`
 * @notice Library for handling key financial calculations, such as interest and principal accrual.
 * @author Goldfinch
 */

library BulletAccountantV2 {
  using WadRayMath for int256;
  using WadRayMath for uint256;

  enum PaymentStatus {
    Upcoming,
    Pending,
    Overdue
  }

  // Scaling factor used by FixedPoint.sol. We need this to convert the fixed point raw values back to unscaled
  uint256 private constant INTEREST_DECIMALS = 1e18;
  uint256 private constant SECONDS_PER_DAY = 1 days;
  uint256 private constant SECONDS_PER_YEAR = (SECONDS_PER_DAY * 365);

  struct PaymentAllocation {
    uint256 interestPayment;
    uint256 principalPayment;
    uint256 additionalBalancePayment;
  }

  function calculateInterestAndPrincipalAccrued(
    IHelixCreditLineV3 cl,
    IHelixInterestModel im,
    uint256 timestamp,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 balance = cl.balance(); // gas optimization
    uint256 interestAccrued = calculateInterestAccrued(cl, im, balance, timestamp, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, timestamp);
    return (interestAccrued, principalAccrued);
  }

  function calculateInterestAndPrincipalAccruedOverPeriod(
    IHelixCreditLineV3 cl,
    IHelixInterestModel im,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 interestAccrued = calculateInterestAccruedOverPeriod(cl,im, balance, startTime, endTime, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, endTime);
    return (interestAccrued, principalAccrued);
  }

  function calculatePrincipalAccrued(
    IHelixCreditLineV3 cl,
    uint256 balance,
    uint256 timestamp
  ) public view returns (uint256) {
    // If we've already accrued principal as of the term end time, then don't accrue more principal
    uint256 termEndTime = cl.termEndTime();
    if (cl.interestAccruedAsOf() >= termEndTime || timestamp >= termEndTime) {
      return balance;
    }
    
    return 0;
  }

  function calculateWritedownFor(
    IHelixCreditLineV3 cl,
    uint256 timestamp,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    return calculateWritedownForPrincipal(cl, cl.balance(), timestamp, gracePeriodInDays, maxDaysLate);
  }

  function calculateWritedownForPrincipal(
    IHelixCreditLineV3 cl,
    uint256 principal,
    uint256 timestamp,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    uint256 amountOwedPerDay = calculateAmountOwedForOneDay(cl);
    if (amountOwedPerDay == 0) {
      return (0, 0);
    }
    uint256 daysLate;

    // Excel math: =min(1,max(0,periods_late_in_days-graceperiod_in_days)/MAX_ALLOWED_DAYS_LATE) grace_period = 30,
    // Before the term end date, we use the interestOwed to calculate the periods late. However, after the loan term
    // has ended, since the interest is a much smaller fraction of the principal, we cannot reliably use interest to
    // calculate the periods later.
    uint256 totalOwed = cl.interestOwed() + cl.principalOwed();
    daysLate = totalOwed.wadDiv(amountOwedPerDay);
    if (timestamp > cl.termEndTime()) {
      uint256 secondsLate = timestamp - cl.termEndTime();
      daysLate = daysLate + secondsLate / SECONDS_PER_DAY;
    }

    uint256 writedownPercent;
    if (daysLate <= gracePeriodInDays) {
      // Within the grace period, we don't have to write down, so assume 0%
      writedownPercent = 0;
    } else {
      writedownPercent = MathUpgradeable.min(WadRayMath.WAD, (daysLate - gracePeriodInDays).wadDiv(maxDaysLate));
    }

    uint256 writedownAmount = writedownPercent.wadMul(principal);
    // This will return a number between 0-100 representing the write down percent with no decimals
    uint256 unscaledWritedownPercent = writedownPercent.wadMul(100);
    return (unscaledWritedownPercent, writedownAmount);
  }

  function calculateAmountOwedForOneDay(IHelixCreditLineV3 cl) public view returns (uint256 interestOwed) {
    // Determine theoretical interestOwed for one full day
    uint256 totalInterestPerYear = cl.balance().wadMul(cl.interestApr());
    interestOwed = totalInterestPerYear.wadDiv(365);
    return interestOwed;
  }

  function calculateInterestAccrued(
    IHelixCreditLineV3 cl,
    IHelixInterestModel im,
    uint256 balance,
    uint256 timestamp,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256) {
    // We use Math.min here to prevent integer overflow (ie. go negative) when calculating
    // numSecondsElapsed. Typically this shouldn't be possible, because
    // the interestAccruedAsOf couldn't be *after* the current timestamp. However, when assessing
    // we allow this function to be called with a past timestamp, which raises the possibility
    // of overflow.
    // This use of min should not generate incorrect interest calculations, since
    // this function's purpose is just to normalize balances, and handing in a past timestamp
    // will necessarily return zero interest accrued (because zero elapsed time), which is correct.
    uint256 startTime = MathUpgradeable.min(timestamp, cl.interestAccruedAsOf());
    return calculateInterestAccruedOverPeriod(cl, im, balance, startTime, timestamp, lateFeeGracePeriodInDays);
  }

  function calculateInterestAccruedOverPeriod(
    IHelixCreditLineV3 cl,
    IHelixInterestModel im,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256 interestOwed) {
    uint256 secondsElapsed = endTime - startTime;
    interestOwed = im.calculateInterestAccruedOverTimes(balance,  cl.interestApr(), secondsElapsed);
    if (lateFeeApplicable(cl, endTime, lateFeeGracePeriodInDays)) {
      uint256 lateFeeInterestPerYear = balance * cl.lateFeeApr() / INTEREST_DECIMALS;
      uint256 additionalLateFeeInterest = lateFeeInterestPerYear * secondsElapsed / SECONDS_PER_YEAR;
      interestOwed = interestOwed + additionalLateFeeInterest;
    }

    return interestOwed;
  }

  function lateFeeApplicable(
    IHelixCreditLineV3 cl,
    uint256 timestamp,
    uint256 gracePeriodInDays
  ) public view returns (bool) {
    uint256 secondsLate = timestamp - cl.lastFullPaymentTime();
    return cl.lateFeeApr() > 0 && secondsLate > gracePeriodInDays;
  }

  function allocatePayment(
    uint256 paymentAmount,
    uint256 balance,
    uint256 interestOwed,
    uint256 principalOwed
  ) public pure returns (PaymentAllocation memory) {
    uint256 paymentRemaining = paymentAmount;
    uint256 interestPayment = MathUpgradeable.min(interestOwed, paymentRemaining);
    paymentRemaining = paymentRemaining - interestPayment;

    uint256 principalPayment = MathUpgradeable.min(principalOwed, paymentRemaining);
    paymentRemaining = paymentRemaining - principalPayment;

    uint256 balanceRemaining = balance - principalPayment;
    uint256 additionalBalancePayment = MathUpgradeable.min(paymentRemaining, balanceRemaining);

    return
      PaymentAllocation({
        interestPayment: interestPayment,
        principalPayment: principalPayment,
        additionalBalancePayment: additionalBalancePayment
      });
  }

  function calculateInterestAndLateFeeAndPrincipalAccruedAndPaymentStatus(
    IHelixCreditLineV3 cl,
    IHelixInterestModel im,
    uint256 timestamp,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256, uint256, uint8) {
    uint256 balance = cl.balance(); // gas optimization
    (uint256 interestAccrued, uint256 lateFeeAccrued, uint8 status) = calculateInterestAccruedAndLateFeeAndPaymentStatus(cl, im, balance, timestamp, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, timestamp);
    return (interestAccrued, lateFeeAccrued, principalAccrued, status);
  }

  function calculateInterestAccruedAndLateFeeAndPaymentStatus(
    IHelixCreditLineV3 cl,
    IHelixInterestModel im,
    uint256 balance,
    uint256 timestamp,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256, uint256, uint8) {
    // We use Math.min here to prevent integer overflow (ie. go negative) when calculating
    // numSecondsElapsed. Typically this shouldn't be possible, because
    // the interestAccruedAsOf couldn't be *after* the current timestamp. However, when assessing
    // we allow this function to be called with a past timestamp, which raises the possibility
    // of overflow.
    // This use of min should not generate incorrect interest calculations, since
    // this function's purpose is just to normalize balances, and handing in a past timestamp
    // will necessarily return zero interest accrued (because zero elapsed time), which is correct.
    uint256 startTime = MathUpgradeable.min(timestamp, cl.interestAccruedAsOf());
    return calculateInterestAccruedAndLateFeeAndPaymentStatusOverPeriod(cl, im, balance, startTime, timestamp, lateFeeGracePeriodInDays);
  }

  function calculateInterestAccruedAndLateFeeAndPaymentStatusOverPeriod(
    IHelixCreditLineV3 cl,
    IHelixInterestModel im,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256 interestOwed, uint256 additionalLateFeeInterest, uint8) {
    uint256 secondsElapsed = endTime - startTime;
    interestOwed = im.calculateInterestAccruedOverTimes(balance,  cl.interestApr(), secondsElapsed);
    if (lateFeeApplicable(cl, endTime, lateFeeGracePeriodInDays)) {
      uint256 lateFeeInterestPerYear = balance * cl.lateFeeApr() / INTEREST_DECIMALS;
      additionalLateFeeInterest = lateFeeInterestPerYear * secondsElapsed / SECONDS_PER_YEAR;
      interestOwed = interestOwed + additionalLateFeeInterest;
      return (interestOwed, additionalLateFeeInterest, uint8(PaymentStatus.Overdue));
    }

    return (interestOwed, additionalLateFeeInterest, uint8(PaymentStatus.Pending));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {ImplementationRepository} from "../proxy/ImplementationRepository.sol";
import {HelixConfigOptions} from "../core/HelixConfigOptions.sol";
import {IHelixConfig} from "../interfaces/IHelixConfig.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
// import {ICUSDCContract} from "../../interfaces/ICUSDCContract.sol";
// import {IHelixJuniorLP} from "./interfaces/IHelixJuniorLP.sol";
import {IHelixJuniorRewards} from "../interfaces/IHelixJuniorRewards.sol";
import {IHelixFactory} from "../interfaces/IHelixFactory.sol";
import {IHelixGo} from "../interfaces/IHelixGo.sol";

// import {IStakingRewards} from "../../interfaces/IStakingRewards.sol";
// import {ICurveLP} from "../../interfaces/ICurveLP.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the HelixConfig contract
 * @author Helix
 */

library HelixConfigHelper {
  function getUSDC(IHelixConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(usdcAddress(config));
  }
//   function getFiduUSDCCurveLP(HelixConfig config) internal view returns (ICurveLP) {
//     return ICurveLP(fiduUSDCCurveLPAddress(config));
//   }

//   function getCUSDCContract(HelixConfig config) internal view returns (ICUSDCContract) {
//     return ICUSDCContract(cusdcContractAddress(config));
//   }

  function getJuniorRewards(IHelixConfig config) internal view returns (IHelixJuniorRewards) {
    return IHelixJuniorRewards(juniorRewardsAddress(config));
  }

  function getHelixFactory(IHelixConfig config) internal view returns (IHelixFactory) {
    return IHelixFactory(HelixFactoryAddress(config));
  }

  function getOVN(IHelixConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(HelixAddress(config));
  }

  function getGo(IHelixConfig config) internal view returns (IHelixGo) {
    return IHelixGo(goAddress(config));
  }

//   function getStakingRewards(HelixConfig config) internal view returns (IStakingRewards) {
//     return IStakingRewards(stakingRewardsAddress(config));
//   }

  function getTranchedPoolImplementationRepository(
    IHelixConfig config
  ) internal view returns (ImplementationRepository) {
    return
      ImplementationRepository(
        config.getAddress(uint256(HelixConfigOptions.Addresses.TranchedPoolImplementationRepository))
      );
  }

  function getUniTranchedPoolImplementationRepository(
    IHelixConfig config
  ) internal view returns (ImplementationRepository) {
    return
      ImplementationRepository(
        config.getAddress(uint256(HelixConfigOptions.Addresses.UniTranchedPoolImplementationRepository))
      );
  }

  function getPoolSharesImplementationRepository(
    IHelixConfig config
  ) internal view returns (ImplementationRepository) {
    return
      ImplementationRepository(
        config.getAddress(uint256(HelixConfigOptions.Addresses.PoolSharesImplementationRepository))
      );
  }

//   function oneInchAddress(HelixConfig config) internal view returns (address) {
//     return config.getAddress(uint256(HelixHelixConfigOptions.Addresses.OneInch));
//   }

  function creditLineImplementationAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.CreditLineImplementation));
  }

//   /// @dev deprecated because we no longer use GSN
//   function trustedForwarderAddress(HelixConfig config) internal view returns (address) {
//     return config.getAddress(uint256(HelixHelixConfigOptions.Addresses.TrustedForwarder));
//   }

  function configAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.HelixConfig));
  }
  function juniorRewardsAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.JuniorRewards));
  }

  function HelixFactoryAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.HelixFactory));
  }

  function HelixAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.HELIX));
  }

//   function fiduUSDCCurveLPAddress(HelixConfig config) internal view returns (address) {
//     return config.getAddress(uint256(HelixConfigOptions.Addresses.FiduUSDCCurveLP));
//   }

//   function cusdcContractAddress(HelixConfig config) internal view returns (address) {
//     return config.getAddress(uint256(HelixConfigOptions.Addresses.CUSDCContract));
//   }

  function usdcAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.USDC));
  }

  function tranchedPoolAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.TranchedPoolImplementation));
  }

  function tranchedPoolShareAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.TranchedPoolShareImplementation));
  }

  function reserveAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.TreasuryReserve));
  }

  function protocolAdminAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.ProtocolAdmin));
  }

  function goAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.Go));
  }

//   function stakingRewardsAddress(HelixConfig config) internal view returns (address) {
//     return config.getAddress(uint256(HelixConfigOptions.Addresses.StakingRewards));
//   }

  function getReserveDenominator(IHelixConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(HelixConfigOptions.Numbers.ReserveDenominator));
  }

  function getWithdrawFeeDenominator(IHelixConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(HelixConfigOptions.Numbers.WithdrawFeeDenominator));
  }

  function getLatenessGracePeriodInDays(IHelixConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(HelixConfigOptions.Numbers.LatenessGracePeriodInDays));
  }

  function getLatenessMaxDays(IHelixConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(HelixConfigOptions.Numbers.LatenessMaxDays));
  }

  function getTransferRestrictionPeriodInDays(IHelixConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(HelixConfigOptions.Numbers.TransferRestrictionPeriodInDays));
  }

  function getLeverageRatio(IHelixConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(HelixConfigOptions.Numbers.LeverageRatio));
  }

  function getJuniorRatioSlippage(IHelixConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(HelixConfigOptions.Numbers.JuniorRatioSlippage));
  }

  function borrowerImplementationAddress(IHelixConfig config) internal view returns (address) {
    return config.getAddress(uint256(HelixConfigOptions.Addresses.BorrowerImplementation));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {BaseUpgradeablePausable} from "../upgradeable/BaseUpgradeablePausable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title User Controlled Upgrades (UCU) Proxy Repository
/// A repository maintaing a collection of "lineages" of implementation contracts
///
/// Lineages are a sequence of implementations each lineage can be thought of as
/// a "major" revision of implementations. Implementations between lineages are
/// considered incompatible.
contract ImplementationRepository is BaseUpgradeablePausable {
  address internal constant INVALID_IMPL = address(0);
  uint256 internal constant INVALID_LINEAGE_ID = 0;

  /// @notice returns data that will be delegatedCalled when the given implementation
  ///           is upgraded to
  mapping(address => bytes) public upgradeDataFor;

  /// @dev mapping from one implementation to the succeeding implementation
  mapping(address => address) internal _nextImplementationOf;

  /// @notice Returns the id of the lineage a given implementation belongs to
  mapping(address => uint256) public lineageIdOf;

  /// @dev internal because we expose this through the `currentImplementation(uint256)` api
  mapping(uint256 => address) internal _currentOfLineage;

  /// @notice Returns the id of the most recently created lineage
  uint256 public currentLineageId;

  // //////// External ////////////////////////////////////////////////////////////

  /// @notice initialize the repository's state
  /// @dev reverts if `_owner` is the null address
  /// @dev reverts if `implementation` is not a contract
  /// @param _owner owner of the repository
  /// @param implementation initial implementation in the repository
  function initialize(address _owner, address implementation) external initializer {
    __BaseUpgradeablePausable__init(_owner);
    _createLineage(implementation);
    require(currentLineageId != INVALID_LINEAGE_ID);
  }

  /// @notice set data that will be delegate called when a proxy upgrades to the given `implementation`
  /// @dev reverts when caller is not an admin
  /// @dev reverts when the contract is paused
  /// @dev reverts if the given implementation isn't registered
  function setUpgradeDataFor(
    address implementation,
    bytes calldata data
  ) external onlyAdmin whenNotPaused {
    _setUpgradeDataFor(implementation, data);
  }

  /// @notice Create a new lineage of implementations.
  ///
  /// This creates a new "root" of a new lineage
  /// @dev reverts if `implementation` is not a contract
  /// @param implementation implementation that will be the first implementation in the lineage
  /// @return newly created lineage's id
  function createLineage(
    address implementation
  ) external onlyAdmin whenNotPaused returns (uint256) {
    return _createLineage(implementation);
  }

  /// @notice add a new implementation and set it as the current implementation
  /// @dev reverts if the sender is not an owner
  /// @dev reverts if the contract is paused
  /// @dev reverts if `implementation` is not a contract
  /// @param implementation implementation to append
  function append(address implementation) external onlyAdmin whenNotPaused {
    _append(implementation, currentLineageId);
  }

  /// @notice Append an implementation to a specified lineage
  /// @dev reverts if the contract is paused
  /// @dev reverts if the sender is not an owner
  /// @dev reverts if `implementation` is not a contract
  /// @param implementation implementation to append
  /// @param lineageId id of lineage to append to
  function append(address implementation, uint256 lineageId) external onlyAdmin whenNotPaused {
    _append(implementation, lineageId);
  }

  /// @notice Remove an implementation from the chain and "stitch" together its neighbors
  /// @dev If you have a chain of `A -> B -> C` and I call `remove(B, C)` it will result in `A -> C`
  /// @dev reverts if `previos` is not the ancestor of `toRemove`
  /// @dev we need to provide the previous implementation here to be able to successfully "stitch"
  ///       the chain back together. Because this is an admin action, we can source what the previous
  ///       version is from events.
  /// @param toRemove Implementation to remove
  /// @param previous Implementation that currently has `toRemove` as its successor
  function remove(address toRemove, address previous) external onlyAdmin whenNotPaused {
    _remove(toRemove, previous);
  }

  // //////// External view ////////////////////////////////////////////////////////////

  /// @notice Returns `true` if an implementation has a next implementation set
  /// @param implementation implementation to check
  /// @return The implementation following the given implementation
  function hasNext(address implementation) external view returns (bool) {
    return _nextImplementationOf[implementation] != INVALID_IMPL;
  }

  /// @notice Returns `true` if an implementation has already been added
  /// @param implementation Implementation to check existence of
  /// @return `true` if the implementation has already been added
  function has(address implementation) external view returns (bool) {
    return _has(implementation);
  }

  /// @notice Get the next implementation for a given implementation or
  ///           `address(0)` if it doesn't exist
  /// @dev reverts when contract is paused
  /// @param implementation implementation to get the upgraded implementation for
  /// @return Next Implementation
  function nextImplementationOf(
    address implementation
  ) external view whenNotPaused returns (address) {
    return _nextImplementationOf[implementation];
  }

  /// @notice Returns `true` if a given lineageId exists
  function lineageExists(uint256 lineageId) external view returns (bool) {
    return _lineageExists(lineageId);
  }

  /// @notice Return the current implementation of a lineage with the given `lineageId`
  function currentImplementation(uint256 lineageId) external view whenNotPaused returns (address) {
    return _currentImplementation(lineageId);
  }

  /// @notice return current implementaton of the current lineage
  function currentImplementation() external view whenNotPaused returns (address) {
    return _currentImplementation(currentLineageId);
  }

  // //////// Internal ////////////////////////////////////////////////////////////

  function _setUpgradeDataFor(address implementation, bytes memory data) internal {
    require(_has(implementation), "unknown impl");
    upgradeDataFor[implementation] = data;
    emit UpgradeDataSet(implementation, data);
  }

  function _createLineage(address implementation) internal virtual returns (uint256) {
    require(Address.isContract(implementation), "not a contract");
    // NOTE: impractical to overflow
    currentLineageId += 1;

    _currentOfLineage[currentLineageId] = implementation;
    lineageIdOf[implementation] = currentLineageId;

    emit Added(currentLineageId, implementation, address(0));
    return currentLineageId;
  }

  function _currentImplementation(uint256 lineageId) internal view returns (address) {
    return _currentOfLineage[lineageId];
  }

  /// @notice Returns `true` if an implementation has already been added
  /// @param implementation implementation to check for
  /// @return `true` if the implementation has already been added
  function _has(address implementation) internal view virtual returns (bool) {
    return lineageIdOf[implementation] != INVALID_LINEAGE_ID;
  }

  /// @notice Set an implementation to the current implementation
  /// @param implementation implementation to set as current implementation
  /// @param lineageId id of lineage to append to
  function _append(address implementation, uint256 lineageId) internal virtual {
    require(Address.isContract(implementation), "not a contract");
    require(!_has(implementation), "exists");
    require(_lineageExists(lineageId), "invalid lineageId");
    require(_currentOfLineage[lineageId] != INVALID_IMPL, "empty lineage");

    address oldImplementation = _currentOfLineage[lineageId];
    _currentOfLineage[lineageId] = implementation;
    lineageIdOf[implementation] = lineageId;
    _nextImplementationOf[oldImplementation] = implementation;

    emit Added(lineageId, implementation, oldImplementation);
  }

  function _remove(address toRemove, address previous) internal virtual {
    require(toRemove != INVALID_IMPL && previous != INVALID_IMPL, "ZERO");
    require(_nextImplementationOf[previous] == toRemove, "Not prev");

    uint256 lineageId = lineageIdOf[toRemove];

    // need to reset the head pointer to the previous version if we remove the head
    if (toRemove == _currentOfLineage[lineageId]) {
      _currentOfLineage[lineageId] = previous;
    }

    _setUpgradeDataFor(toRemove, ""); // reset upgrade data
    _nextImplementationOf[previous] = _nextImplementationOf[toRemove];
    _nextImplementationOf[toRemove] = INVALID_IMPL;
    lineageIdOf[toRemove] = INVALID_LINEAGE_ID;
    emit Removed(lineageId, toRemove);
  }

  function _lineageExists(uint256 lineageId) internal view returns (bool) {
    return lineageId != INVALID_LINEAGE_ID && lineageId <= currentLineageId;
  }

  // //////// Events //////////////////////////////////////////////////////////////
  event Added(
    uint256 indexed lineageId,
    address indexed newImplementation,
    address indexed oldImplementation
  );
  event Removed(uint256 indexed lineageId, address indexed implementation);
  event UpgradeDataSet(address indexed implementation, bytes data);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title BaseUpgradeablePausable contract
 * @notice This is our Base contract that most other contracts inherit from. It includes many standard
 *  useful abilities like upgradeability, pausability, access control, and re-entrancy guards.
 * @author Helix
 */

contract BaseUpgradeablePausable is
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // Pre-reserving a few slots in the base contract in case we need to add things in the future.
    // This does not actually take up gas cost or storage cost, but it does reserve the storage slots.
    // See OpenZeppelin's use of this pattern here:
    // https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/GSN/Context.sol#L37
    uint256[50] private __gap1;
    uint256[50] private __gap2;
    uint256[50] private __gap3;
    uint256[50] private __gap4;

    // solhint-disable-next-line func-name-mixedcase
    function __BaseUpgradeablePausable__init(address owner) public onlyInitializing {
        require(owner != address(0), "Owner cannot be the zero address");
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _setupRole(OWNER_ROLE, owner);
        _setupRole(PAUSER_ROLE, owner);

        _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    }

    function isAdmin() public view returns (bool) {
        return hasRole(OWNER_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        require(isAdmin(), "Must have admin role to perform this action");
        _;
    }
}