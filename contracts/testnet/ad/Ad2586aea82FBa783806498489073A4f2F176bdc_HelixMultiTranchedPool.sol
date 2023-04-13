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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

import {SafeERC20} from  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {IHelixInterestModel} from "../interfaces/IHelixInterestModel.sol";
import {IHelixPoolShares} from "../interfaces/IHelixPoolShares.sol";
import {IHelixMultiTranchedPool} from "../interfaces/IHelixMultiTranchedPool.sol";
import {IRequiresUID} from "../interfaces/IRequiresUID.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
import {IHelixCreditLineV3} from "../interfaces/IHelixCreditLineV3.sol";
// import {IBackerRewards} from "../../interfaces/IBackerRewards.sol";
// import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {IVersioned} from "../interfaces/IVersioned.sol";
import {IHelixConfig} from "../interfaces/IHelixConfig.sol";
import "../libraries/HelixConfigHelper.sol";
import "../libraries/HelixTranchingLogic.sol";
import "../upgradeable/BaseUpgradeablePausable.sol";
import "../proxy/UcuProxy.sol";
import "../libraries/WadRayMath.sol";

contract HelixMultiTranchedPool is BaseUpgradeablePausable, IHelixMultiTranchedPool, IRequiresUID, IVersioned {
  using HelixConfigHelper for IHelixConfig;
  using HelixTranchingLogic for PoolSlice;
  using HelixTranchingLogic for IHelixPoolShares;
  using WadRayMath for uint16;
  using WadRayMath for uint256;
  using SafeERC20 for IERC20withDec;

  error NotAuthorized();
  error DrawdownSliceHasBeenMade();
  error FundingDateNotReached();
  error NotOpenYet();
  error FundingDatePassed();
  error TrancheMaximumInvestmentExceeds(uint256 current, uint256 amount);
  error InvalidInvestmentRatio();
  error InvalidAmount();
  error ExceededAmount();
  error AlreadyCancelled();
  error AlreadyClosed();
  error AddressZero();
  error MustBeZero();
  error DrawdownHasPaused();
  error InvalidTranche();

  IHelixConfig public config;

  bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");

  uint8 internal constant MAJOR_VERSION = 0;
  uint8 internal constant MINOR_VERSION = 5;
  uint8 internal constant PATCH_VERSION = 11;

  /// @dev PRECISION_POINT: Use for floating calculation. Solidity doesn't support floating
  uint16 public constant PRECISION_POINT = 10000;
  /// @dev use for calculating floating interest rate - Fixed point scaling factor
  uint256 internal constant FP_SCALING_FACTOR = 1e18;

  /// @dev juniorRatioSlippage: Junior ratio slippage to prevent absolute condition (easier to close the pool)
  uint16 public juniorRatioSlippage;
  /// @dev juniorRatio: Expected junior / senior ratio after funding date
  uint16 public juniorRatio;
  /// @dev drawdownsPaused: This will be used to prevent drawdown if we see any suspectible things 
  bool public drawdownsPaused;
  /// @dev cancelled: This will be used to cancel all investment actions, allows investor to withdraw USDC
  bool public cancelled;
  /// @dev closed: This will be used to close all investment actions, allows borrower to drawdown USDC
  bool public closed;

  uint256 public juniorFeePercent;
  uint256 public totalDeployed;
  uint256 public fundableAt;
  uint256 public minTicketSize;
  uint256[] public allowedUIDTypes;

  mapping(uint256 => PoolSlice) internal _poolSlices;
  uint256 public override numSlices;

  function initialize(
    // name - symbol
    string[2] calldata _loanFacade,
    // config - borrower - _interestModel
    address[3] calldata _addresses,
    // junior fee percent - _interestApr - _lateFeeApr - _minTicketSize
    uint256[4] calldata _uints,
    // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt - _fundingDate
    uint256[5] calldata _days,
    // _maxTarget - _minTarget - ratio
    uint256[3] calldata _targets,
    uint256[] calldata _allowedUIDTypes
  ) public override initializer {
    for (uint i; i < 3;) {
      if (address(_addresses[i]) == address(0)) {
        revert AddressZero();
      }
      // require(address(_addresses[i]) != address(0), "ZERO");
      unchecked {
        i++;
      }
    }

    // require(_targets[2] <= PRECISION_POINT, "Junior ratio cannot greater than 100%!");
    if (_targets[2] > PRECISION_POINT) {
      revert InvalidInvestmentRatio();
    }


    config = IHelixConfig(_addresses[0]);
    address owner = config.protocolAdminAddress();
    __BaseUpgradeablePausable__init(owner);

    _initializeNextSlice(_days[3], _loanFacade);
    _createAndSetCreditLine(
      _addresses[2],
      _addresses[1],
      _targets[0],
      _targets[1],
      _uints[1], // interest APR
      _days[0], // _paymentPeriodInDays
      _days[1], // _termInDays
      _uints[2], // late Fee APR
      _days[2], // _principalGracePeriodInDays
      _days[4] // fundingDate
    );

    juniorRatio = uint16(_targets[2]); // Ratio
    juniorRatioSlippage = uint16(config.getJuniorRatioSlippage());
    
    createdAt = block.timestamp;
    juniorFeePercent = _uints[0];
    minTicketSize = _uints[3];
    if (_allowedUIDTypes.length == 0) {
      uint256[1] memory defaultAllowedUIDTypes = [config.getGo().ID_TYPE_0()];
      allowedUIDTypes = defaultAllowedUIDTypes;
    } else {
      allowedUIDTypes = _allowedUIDTypes;
    }

    _setupRole(LOCKER_ROLE, _addresses[1]);
    _setupRole(LOCKER_ROLE, owner);
    _setRoleAdmin(LOCKER_ROLE, OWNER_ROLE);

    // Unlock self for infinite amount
    require(config.getUSDC().approve(address(this), type(uint256).max));
  }

  function setAllowedUIDTypes(uint256[] calldata ids) external onlyLocker {
    require(
      _poolSlices[0].juniorTranche.totalSupply() == 0 &&
        _poolSlices[0].seniorTranche.totalSupply() == 0,
      "has balance"
    );
    allowedUIDTypes = ids;
  }

  function getAllowedUIDTypes() external view override returns (uint256[] memory) {
    return allowedUIDTypes;
  }

  /**
   * @notice Deposit a USDC amount into the pool for a tranche. Mints an NFT to the caller representing the position
   * @param tranche The number representing the tranche to deposit into
   * @param amount The USDC amount to tranfer from the caller to the pool
   * @return tokenId The tokenId of the NFT
   */
  function deposit(
    uint256 tranche,
    uint256 amount
  ) public override nonReentrant whenNotPaused notCancelled returns (uint256) {
    TrancheInfo memory trancheInfo = _getTrancheInfo(tranche); 
    /// @dev IA: invalid amount
    if (amount < minTicketSize) {
      revert InvalidAmount();
    }   

    /// @dev NA: not authorized. Must have correct UID or be go listed
    if (!hasAllowedUID(msg.sender)) {
      revert NotAuthorized();
    }

    if (block.timestamp < fundableAt) {
      revert NotOpenYet();
    }

    if (block.timestamp > creditLine.fundingDate()) {
      revert FundingDatePassed();
    }

    if (trancheInfo.principalDeposited  + amount > trancheInfo.maximumInvestment) {
      revert TrancheMaximumInvestmentExceeds(trancheInfo.principalDeposited, amount);
    }

    IHelixPoolShares(trancheInfo.tranche).mint(msg.sender, amount);
    config.getUSDC().safeTransferFrom(msg.sender, address(this), amount);
    emit DepositMade(msg.sender, trancheInfo.tranche, tranche, amount);
    return amount;
  }

  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public override returns (uint256 tokenId) {
    IERC20PermitUpgradeable(config.usdcAddress()).permit(msg.sender, address(this), amount, deadline, v, r, s);
    return deposit(tranche, amount);
  }

  /**
   * @notice Redeem principal + interest repayment
   * @param tranche The tranche token id
   * @return interestWithdrawn The interest amount that was redeemed
   * @return principalWithdrawn The principal amount that was redeemed
   */
  function redeem(
    uint256 tranche
  ) public override nonReentrant whenNotPaused returns (uint256, uint256) {
    TrancheInfo memory trancheInfo = _getTrancheInfo(tranche);
    return _withdraw(trancheInfo, 0);
  }

   /**
   * @notice Redeem from many tokens (that the sender owns) in a single transaction
   * @param tranches An array of tranche ids representing the position
   */
  function redeemMultiple(
    uint256[] calldata tranches
  ) public override {
    for (uint256 i = 0; i < tranches.length; i++) {
      redeem(tranches[i]);
    }
  }

  /**
   * @notice Withdraw an already deposited amount if the funds are available
   * @param tranche The tranche token id
   * @return interestWithdrawn The interest amount that was withdrawn
   * @return principalWithdrawn The principal amount that was withdrawn
   */
  function withdraw(
    uint256 tranche
  ) public override nonReentrant whenNotPaused returns (uint256, uint256) {
    TrancheInfo memory trancheInfo = _getTrancheInfo(tranche);

    IHelixPoolShares poolShares = IHelixPoolShares(trancheInfo.tranche);
    uint256 shareBalance = poolShares.balanceOf(msg.sender);

    return _withdraw(trancheInfo, shareBalance);
  }

  /**
   * @notice Withdraw from many tokens (that the sender owns) in a single transaction
   * @param tranches An array of tranche ids representing the position
   */
  function withdrawMultiple(
    uint256[] calldata tranches
    ) public override {
    for (uint256 i = 0; i < tranches.length; i++) {
      withdraw(tranches[i]);
    }
  }

  // /**
  //  * @notice Similar to withdraw but will withdraw all available funds
  //  * @param tranche The trancheID that you'd like to withdraw
  //  * @return interestWithdrawn The interest amount that was withdrawn
  //  * @return principalWithdrawn The principal amount that was withdrawn
  //  */
  // function withdrawMax(
  //   uint256 tranche
  // )
  //   external
  //   override
  //   nonReentrant
  //   whenNotPaused
  //   returns (uint256 interestWithdrawn, uint256 principalWithdrawn)
  // {
  //   TrancheInfo memory trancheInfo = _getTrancheInfo(tranche);

  //   uint256 amount = IHelixPoolShares(trancheInfo.tranche).balanceOf(msg.sender);
  //   return _withdraw(trancheInfo, amount);
  // }

  // /**
  //  * @notice Similar to withdraw but will withdraw all available funds
  //  * @param tranche The trancheID that you'd like to withdraw
  //  * @return interestWithdrawn The interest amount that was withdrawn
  //  * @return principalWithdrawn The principal amount that was withdrawn
  //  */
  // function withdrawMaxWithPermit(
  //   uint256 tranche,
  //   uint256 deadline,
  //   uint8 v,
  //   bytes32 r,
  //   bytes32 s
  // )
  //   external
  //   override
  //   nonReentrant
  //   whenNotPaused
  //   returns (uint256 interestWithdrawn, uint256 principalWithdrawn)
  // {
  //   TrancheInfo memory trancheInfo = _getTrancheInfo(tranche);

  //   uint256 amount = IHelixPoolShares(trancheInfo.tranche).balanceOf(msg.sender);
  //   IERC20PermitUpgradeable(trancheInfo.tranche).permit(msg.sender, address(this), amount, deadline, v, r, s);

  //   return _withdraw(trancheInfo, amount);
  // }

  /**
   * @notice Draws down the funds (and locks the pool) to the borrower address. Can only be called by the borrower
   */
  function drawdown() external view override onlyLocker notCancelled whenNotPaused returns(uint256) {
    /// @dev DP: drawdowns paused
    // if (drawdownsPaused) {
    //   revert DrawdownHasPaused();
    // }
   
    // Drawdown only draws down from the current slice for simplicity. It's harder to account for how much
    // money is available from previous slices since depositors can redeem after unlock.
    PoolSlice storage currentSlice = _poolSlices[numSlices - 1];

    // if (currentSlice.drawdownMade) {
    //   revert DrawdownSliceHasBeenMade();
    // }

    // Mark this slice as has been drawdown made
    // currentSlice.drawdownMade = true;

    TrancheInfo memory juniorTrancheInfo = _getTrancheInfoByAddress(currentSlice.juniorTranche);    
    TrancheInfo memory seniorTrancheInfo = _getTrancheInfoByAddress(currentSlice.seniorTranche);    

    uint256 amountAvailable = HelixTranchingLogic.sharePriceToUsdc(
      juniorTrancheInfo.principalSharePrice,
      juniorTrancheInfo.principalDeposited
    );

    amountAvailable = amountAvailable + (
      HelixTranchingLogic.sharePriceToUsdc(
        seniorTrancheInfo.principalSharePrice,
        seniorTrancheInfo.principalDeposited
      )
    );

    // if (!_locked()) {
    //   // Assumes the senior pool has invested already (saves the borrower a separate transaction to lock the pool)
    //   _lockPool();
    // }

    // creditLine.drawdown(amountAvailable, creditLine.fundingDate());

    // // Update the share price to reflect the amount remaining in the pool
    // uint256 amountRemaining = 0;
    // uint256 oldJuniorPrincipalSharePrice = juniorTrancheInfo.principalSharePrice;
    // uint256 oldSeniorPrincipalSharePrice = seniorTrancheInfo.principalSharePrice;
    // juniorTrancheInfo.principalSharePrice = currentSlice
    //   .juniorTranche
    //   .calculateExpectedSharePrice(amountRemaining, currentSlice);
    // seniorTrancheInfo.principalSharePrice = currentSlice
    //   .seniorTranche
    //   .calculateExpectedSharePrice(amountRemaining, currentSlice);
    // currentSlice.principalDeployed = currentSlice.principalDeployed + amountAvailable;
    // totalDeployed = totalDeployed + amountAvailable;

    // address borrower = creditLine.borrower();
    // // // IBackerRewards backerRewards = IBackerRewards(config.backerRewardsAddress());
    // // // backerRewards.onTranchedPoolDrawdown(numSlices - 1);
    // config.getUSDC().safeTransferFrom(address(this), borrower, amountAvailable);
    // emit DrawdownMade(borrower, amountAvailable);
    // emit SharePriceUpdated(
    //   address(this),
    //   juniorTrancheInfo.id,
    //   juniorTrancheInfo.principalSharePrice,
    //   int256(oldJuniorPrincipalSharePrice - juniorTrancheInfo.principalSharePrice) * -1,
    //  juniorTrancheInfo.interestSharePrice,
    //   0
    // );
    // emit SharePriceUpdated(
    //   address(this),
    //   seniorTrancheInfo.id,
    //   seniorTrancheInfo.principalSharePrice,
    //   int256(oldSeniorPrincipalSharePrice - seniorTrancheInfo.principalSharePrice) * -1,
    //   seniorTrancheInfo.interestSharePrice,
    //   0
    // );

    return amountAvailable;
    // return 0;
  }

  function NUM_TRANCHES_PER_SLICE() external pure returns (uint256) {
    return HelixTranchingLogic.NUM_TRANCHES_PER_SLICE;
  }

  function cancel() external override notCancelled onlyLocker {
    /// @dev FS: Funding date passed
    if (block.timestamp > creditLine.fundingDate()) {
      revert FundingDatePassed();
    }

    cancelled = true;
    emit PoolCancelled();
  }

  function close() external override notClosed onlyLocker {
    require(poolRequirementsFulfilled(),"PE");
    closed = true;
    emit PoolClosed();
  }

  /**
   * @notice Locks the pool (locks both senior and junior tranches and starts the drawdown period). Beyond the drawdown
   * period, any unused capital is available to withdraw by all depositors
   */
  function lockPool() external override onlyLocker notCancelled whenNotPaused {
    _lockPool();
  }

  function setFundableAt(uint256 newFundableAt) external override onlyLocker {
    fundableAt = newFundableAt;
  }

//   function initializeNextSlice(uint256 _fundableAt) external override onlyLocker whenNotPaused {
//     /// @dev NL: not locked
//     require(_locked(), "NL");
//     /// @dev LP: late payment
//     require(!creditLine.isLate(), "LP");
//     /// @dev GP: beyond principal grace period
//     require(creditLine.withinPrincipalGracePeriod(), "GP");
//     _initializeNextSlice(_fundableAt);
//     emit SliceCreated(address(this), numSlices.sub(1));
//   }

  /**
   * @notice Triggers an assessment of the creditline and the applies the payments according the tranche waterfall
   */
  function assess() external override notCancelled whenNotPaused {
    _assess();
  }

  /**
   * @notice Allows repaying the creditline. Collects the USDC amount from the sender and triggers an assess
   * @param amount The amount to repay
   */
  function pay(uint256 amount) external override notCancelled whenNotPaused {
    /// @dev  IA: cannot pay 0
    if(amount == 0) {
      revert InvalidAmount();
    }
    config.getUSDC().safeTransferFrom(msg.sender, address(creditLine), amount);
    // _assess();
  }

  /**
   * @notice Pauses the pool and sweeps any remaining funds to the treasury reserve.
   */
  function emergencyShutdown() public onlyAdmin {
    if (!paused()) {
      _pause();
    }

    IERC20withDec usdc = config.getUSDC();
    address reserveAddress = config.reserveAddress();
    // Sweep any funds to community reserve
    uint256 poolBalance = usdc.balanceOf(address(this));
    if (poolBalance > 0) {
      config.getUSDC().safeTransfer(reserveAddress, poolBalance);
    }

    uint256 clBalance = usdc.balanceOf(address(creditLine));
    if (clBalance > 0) {
      usdc.safeTransferFrom(address(creditLine), reserveAddress, clBalance);
    }
    emit EmergencyShutdown(address(this));
  }

  /**
   * @notice Pauses all drawdowns (but not deposits/withdraws)
   */
  function pauseDrawdowns() public onlyAdmin {
    drawdownsPaused = true;
    emit DrawdownsPaused(address(this));
  }

  /**
   * @notice Unpause drawdowns
   */
  function unpauseDrawdowns() public onlyAdmin {
    drawdownsPaused = false;
    emit DrawdownsUnpaused(address(this));
  }

//   /**
//    * @notice Migrates the accounting variables from the current creditline to a brand new one
//    * @param _borrower The borrower address
//    * @param _maxLimit The new max limit
//    * @param _interestApr The new interest APR
//    * @param _paymentPeriodInDays The new payment period in days
//    * @param _termInDays The new term in days
//    * @param _lateFeeApr The new late fee APR
//    */
//   function migrateCreditLine(
//     address _borrower,
//     uint256 _maxLimit,
//     uint256 _interestApr,
//     uint256 _paymentPeriodInDays,
//     uint256 _termInDays,
//     uint256 _lateFeeApr,
//     uint256 _principalGracePeriodInDays
//   ) public onlyAdmin {
//     require(_borrower != address(0) && _paymentPeriodInDays != 0 && _termInDays != 0, "ZERO");

//     IHelixCreditLineV3 originalCl = creditLine;

//     _createAndSetCreditLine(
//       _borrower,
//       _maxLimit,
//       _interestApr,
//       _paymentPeriodInDays,
//       _termInDays,
//       _lateFeeApr,
//       _principalGracePeriodInDays
//     );

//     TranchingLogic.migrateAccountingVariables(originalCl, creditLine);
//     TranchingLogic.closeCreditLine(originalCl);
//     address originalBorrower = originalCl.borrower();
//     address newBorrower = creditLine.borrower();

//     // Ensure Roles
//     if (originalBorrower != newBorrower) {
//       revokeRole(LOCKER_ROLE, originalBorrower);
//       grantRole(LOCKER_ROLE, newBorrower);
//     }
//     // Transfer any funds to new CL
//     uint256 clBalance = config.getUSDC().balanceOf(address(originalCl));
//     if (clBalance > 0) {
//       config.getUSDC().safeERC20TransferFrom(address(originalCl), address(creditLine), clBalance);
//     }
//     emit CreditLineMigrated(originalCl, creditLine);
//   }

  // CreditLine proxy method

  function setFileHash(bytes32 fileHash) external override onlyLocker{
    return creditLine.setFileHash(fileHash);
  }

  function setInterestModel(address _interestModel) external onlyAdmin {
    return creditLine.setInterestModel(_interestModel);
  }
  function setLimit(uint256 newAmount) external onlyAdmin {
    return creditLine.setLimit(newAmount);
  }

  function setMaxLimit(uint256 newAmount) external onlyAdmin {
    return creditLine.setMaxLimit(newAmount);
  }

  function getTranche(uint256 tranche) public view override returns (TrancheInfo memory) {
    return _getTrancheInfo(tranche);
  }

  function poolSlices(uint256 index) external view override returns (PoolSlice memory) {
    return _poolSlices[index];
  }

  /**
   * @notice Returns the total junior capital deposited
   * @return The total USDC amount deposited into all junior tranches
   */
  function totalJuniorDeposits() external view override returns (uint256) {
    uint256 total;
    for (uint256 i = 0; i < numSlices; i++) {
      total = total + (_poolSlices[i].juniorTranche.totalSupply());
    }
    return total;
  }

  /**
   * @notice Determines the amount of interest and principal redeemable by a particular tokenId
   * @param tranche The trancheID
   * @return interestRedeemable The interest available to redeem
   * @return principalRedeemable The principal available to redeem
   */
  function availableToWithdraw(uint256 tranche) public view override returns (uint256, uint256) {
    TrancheInfo memory trancheInfo = _getTrancheInfo(tranche);
    uint256 sliceId = HelixTranchingLogic.trancheIdToSliceIndex(tranche);
    PoolSlice storage slice = _poolSlices[sliceId];
    
    if (poolFundingEvaluate() && !slice.poolLocked) {
      return (0, 0);
    }

    uint256 interestToRedeem;
    uint256 principalToRedeem;
    (interestToRedeem, principalToRedeem) = IHelixPoolShares(trancheInfo.tranche).withdrawableFundsOf(msg.sender);
    
    return (interestToRedeem, principalToRedeem);
  }

  function hasAllowedUID(address sender) public view override returns (bool) {
    return config.getGo().goOnlyIdTypes(sender, allowedUIDTypes);
  }

  function poolFundingEvaluate() public view returns(bool) {
    /// @dev: Pool will automatically marked as fail after pool has cancelled
    if (cancelled) {
      return false;
    }

    /// @dev: Evaluate after pool is finalized
    if (block.timestamp > creditLine.fundingDate() && !poolRequirementsFulfilled()) {
      return false;
    }

    return true;
  }

  function poolRequirementsFulfilled() public view returns(bool) {
    /// @dev: Check currenti investment ratio
    PoolSlice storage currentSlice = _poolSlices[numSlices - 1];
    TrancheInfo memory seniorTrancheInfo = _getTrancheInfoByAddress(currentSlice.seniorTranche);    
    TrancheInfo memory juniorTrancheInfo = _getTrancheInfoByAddress(currentSlice.juniorTranche);    

    uint256 totalPrincipalDeposited = juniorTrancheInfo.principalDeposited + seniorTrancheInfo.principalDeposited;

    if (totalPrincipalDeposited < creditLine.minLimit()) {
      return false;
    }

    /// @dev: ratio - juniorRatioSlippage% < current < ratio + juniorRatioSlippage%
    uint256 maximumRatio = juniorRatio + uint256(juniorRatio) * uint256(juniorRatioSlippage) / PRECISION_POINT;
    uint256 minimumRatio = juniorRatio - uint256(juniorRatio) * uint256(juniorRatioSlippage) / PRECISION_POINT;

    uint256 currentInvestmentRatio = getCurrentInvestmentRatio();

    if (currentInvestmentRatio > maximumRatio || currentInvestmentRatio < minimumRatio) {
      return false;
    }

    // TODO: needs to add extra conditions in here
    return true;
  }

  function getCurrentInvestmentRatio() public view returns(uint256) {
    PoolSlice storage currentSlice = _poolSlices[numSlices - 1];

    TrancheInfo memory juniorTrancheInfo = _getTrancheInfoByAddress(currentSlice.juniorTranche);    
    TrancheInfo memory seniorTrancheInfo = _getTrancheInfoByAddress(currentSlice.seniorTranche);    

     if (seniorTrancheInfo.principalDeposited > 0) {
      return juniorTrancheInfo.principalDeposited * PRECISION_POINT / seniorTrancheInfo.principalDeposited;
    }

    return 0; 
  }

  /* Internal functions  */

  function _collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) internal returns (uint256) {
    config.getUSDC().safeTransferFrom(from, address(this), principal + interest);

    uint256 totalReserveAmount = HelixTranchingLogic.applyToAllSlices(
      _poolSlices,
      numSlices,
      interest,
      principal,
      uint256(100) / (config.getReserveDenominator()), // Convert the denonminator to percent
      totalDeployed,
      creditLine,
      config,
      juniorFeePercent
    );

    config.getUSDC().safeTransferFrom(
      address(this),
      config.reserveAddress(),
      totalReserveAmount
    );

    emit ReserveFundsCollected(address(this), totalReserveAmount);

    return totalReserveAmount;
  }

  function _createAndSetCreditLine(
    address _interestModel,
    address _borrower,
    uint256 _maxTarget,
    uint256 _minTarget,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundingDate
  ) internal {
    creditLine = IHelixCreditLineV3(config.getHelixFactory().createCreditLine());
    creditLine.initialize(
      _interestModel,
      address(config),
      address(this), // Set self as the owner
      _borrower,
      _maxTarget,
      _minTarget,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays,
      _fundingDate
    );
  }

  // Internal //////////////////////////////////////////////////////////////////
  function _withdraw(
    TrancheInfo memory trancheInfo,
    uint256 amount
  ) internal returns (uint256, uint256) {
    IHelixPoolShares poolShares = IHelixPoolShares(trancheInfo.tranche);

    uint256 interestToRedeem = 0;
    uint256 principalToRedeem = 0;

    // If the funding date is not reached, ensure the deposited amount is correct
    if (!poolFundingEvaluate()) {
      /// @dev NA: not authorized
      if(!(poolShares.approve(address(this), amount) && hasAllowedUID(msg.sender))) {
        revert NotAuthorized();
      }

      if (amount == 0) {
        revert InvalidAmount();
      }

      poolShares.burn(msg.sender, amount);
      principalToRedeem = amount;

    } else {
      if (amount > 0) {
        revert MustBeZero();
      }

      (interestToRedeem, principalToRedeem) = poolShares.withdrawableFundsOf(msg.sender);
      poolShares.withdrawFunds(msg.sender);
    }

    config.getUSDC().safeTransferFrom(
      address(this),
      msg.sender,
      interestToRedeem + principalToRedeem
    );

    emit WithdrawalMade(
      msg.sender,
      trancheInfo.tranche,
      trancheInfo.id,
      interestToRedeem,
      principalToRedeem
    );

    return (interestToRedeem, principalToRedeem);
  }
  function _lockPool() internal {
    PoolSlice storage slice = _poolSlices[numSlices - 1];
    /// @dev NL: Not locked
    require(!slice.poolLocked, "NL");
    /// @dev PE: Pool funding evaluation
    require(poolRequirementsFulfilled(), "PE");

    TrancheInfo memory juniorTrancheInfo = _getTrancheInfoByAddress(slice.juniorTranche);    
    TrancheInfo memory seniorTrancheInfo = _getTrancheInfoByAddress(slice.seniorTranche);    

    uint256 currentTotal = juniorTrancheInfo.principalDeposited + (
      seniorTrancheInfo.principalDeposited
    );
    creditLine.setLimit(Math.min(creditLine.limit() + currentTotal, creditLine.maxLimit()));

    IHelixPoolShares(juniorTrancheInfo.tranche).lockPool();
    IHelixPoolShares(seniorTrancheInfo.tranche).lockPool();

    // set pool locked to prevent further locking
    slice.poolLocked = true;  
    // set funding date is the day that we closed the pool
    /// @dev: If we close before initial funding date, funding date now becomes current timestamp 
    if (block.timestamp < creditLine.fundingDate()) {
      creditLine.setFundingDate(block.timestamp);
    }
    emit PoolLocked();
  }

  function _initializeNextSlice(uint256 _newFundableAt, string[2] memory _loanFacade) internal returns(address juniorTranche, address seniorTranche) {
    /// @dev SL: slice limit
    require(numSlices < 5, "SL");
    (juniorTranche, seniorTranche) = HelixTranchingLogic.initializeNextSlice(_poolSlices, numSlices, _loanFacade, config);
    numSlices = numSlices + 1;
    fundableAt = _newFundableAt;

    emit TranchesCreated(juniorTranche, seniorTranche);
  }

  // If the senior tranche of the current slice is locked, then the pool is not open to any more deposits
  // (could throw off leverage ratio)
  function _locked() internal view returns (bool) {
    return numSlices == 0 || _poolSlices[numSlices - 1].poolLocked;
  }

  function _getTrancheInfo(uint256 trancheId) internal view returns (TrancheInfo memory trancheInfo) {
    if (!(trancheId > 0 && trancheId <= numSlices * HelixTranchingLogic.NUM_TRANCHES_PER_SLICE)) {
      revert InvalidTranche();
    }
    
    trancheInfo = _getTrancheInfoById(trancheId);
  }

  function _getTrancheInfoByAddress(IHelixPoolShares _tranche) internal view returns(IHelixMultiTranchedPool.TrancheInfo memory){
      bool isSeniorTranche = HelixTranchingLogic.isSeniorTrancheId(_tranche.id());

      uint multiplyFactor = PRECISION_POINT.wadDiv(juniorRatio) + FP_SCALING_FACTOR;
      uint maximumInvestment = isSeniorTranche ? creditLine.maxLimit() * (multiplyFactor - FP_SCALING_FACTOR) / multiplyFactor : creditLine.maxLimit() * FP_SCALING_FACTOR / multiplyFactor;
      uint minimumInvestment = isSeniorTranche ? creditLine.minLimit() * (multiplyFactor - FP_SCALING_FACTOR) / multiplyFactor : creditLine.maxLimit() * FP_SCALING_FACTOR / multiplyFactor;

      return IHelixMultiTranchedPool.TrancheInfo({
          tranche: address(_tranche),
          id: _tranche.id(),
          principalDeposited: _tranche.principalDeposited(),
          principalSharePrice: _tranche.principalSharePrice(),
          interestSharePrice: _tranche.interestSharePrice(),
          maximumInvestment: maximumInvestment,
          minimumInvestment: minimumInvestment
      });
  }

  function _getTrancheInfoById(uint256 _trancheId) internal view returns(IHelixMultiTranchedPool.TrancheInfo memory){
      uint256 sliceId = HelixTranchingLogic.trancheIdToSliceIndex(_trancheId);
      PoolSlice storage slice = _poolSlices[sliceId];

      bool isSeniorTranche = HelixTranchingLogic.isSeniorTrancheId(_trancheId);
      IHelixPoolShares tranche = isSeniorTranche ? slice.seniorTranche: slice.juniorTranche;

      uint multiplyFactor = PRECISION_POINT.wadDiv(juniorRatio) + FP_SCALING_FACTOR;
      uint maximumInvestment = isSeniorTranche ? creditLine.maxLimit() * (multiplyFactor - FP_SCALING_FACTOR) / multiplyFactor : creditLine.maxLimit() * FP_SCALING_FACTOR / multiplyFactor;
      uint minimumInvestment = isSeniorTranche ? creditLine.minLimit() * (multiplyFactor - FP_SCALING_FACTOR) / multiplyFactor : creditLine.maxLimit() * FP_SCALING_FACTOR / multiplyFactor;

      return IHelixMultiTranchedPool.TrancheInfo({
          tranche: address(tranche),
          id: tranche.id(),
          principalDeposited: tranche.principalDeposited(),
          principalSharePrice: tranche.principalSharePrice(),
          interestSharePrice: tranche.interestSharePrice(),
          maximumInvestment: maximumInvestment,
          minimumInvestment: minimumInvestment
      });
  }

  function _assess() internal {
    // We need to make sure the pool is locked before we allocate rewards to ensure it's not
    // possible to game rewards by sandwiching an interest payment to an unlocked pool
    // It also causes issues trying to allocate payments to an empty slice (divide by zero)
    /// @dev NL: not locked
    require(_locked(), "NL");

    uint256 interestAccrued = creditLine.totalInterestAccrued();
    (uint256 paymentRemaining, uint256 interestPayment, uint256 principalPayment) = creditLine
      .assess();
    interestAccrued = creditLine.totalInterestAccrued() - interestAccrued;

    // Split the interest accrued proportionally across slices so we know how much interest goes to each slice
    // We need this because the slice start at different times, so we cannot retroactively allocate the interest
    // linearly
    uint256[] memory principalPaymentsPerSlice = new uint256[](numSlices);
    for (uint256 i = 0; i < numSlices; i++) {
      uint256 interestForSlice = HelixTranchingLogic.scaleByFraction(
        interestAccrued,
        _poolSlices[i].principalDeployed,
        totalDeployed
      );
      principalPaymentsPerSlice[i] = HelixTranchingLogic.scaleByFraction(
        principalPayment,
        _poolSlices[i].principalDeployed,
        totalDeployed
      );
      _poolSlices[i].totalInterestAccrued = _poolSlices[i].totalInterestAccrued + (
        interestForSlice
      );
    }

    if (interestPayment > 0 || principalPayment > 0) {
      uint256 reserveAmount = _collectInterestAndPrincipal(
        address(creditLine),
        interestPayment,
        principalPayment + paymentRemaining
      );

      for (uint256 i = 0; i < numSlices; i++) {
        _poolSlices[i].principalDeployed = _poolSlices[i].principalDeployed - (
          principalPaymentsPerSlice[i]
        );
        totalDeployed = totalDeployed - principalPaymentsPerSlice[i];
      }

      // config.getBackerRewards().allocateRewards(interestPayment);

      emit PaymentApplied(
        creditLine.borrower(),
        address(this),
        interestPayment,
        principalPayment,
        paymentRemaining,
        reserveAmount
      );
    }
    emit TranchedPoolAssessed(address(this));
  }

  // // Events ////////////////////////////////////////////////////////////////////
  event PoolCancelled();
  event PoolClosed();
  event PoolLocked();
  event DepositMade(
    address indexed owner,
    address indexed tranche,
    uint256 indexed trancheId,
    uint256 amount
  );
  event WithdrawalMade(
    address indexed owner,
    address indexed tranche,
    uint256 indexed trancheId,
    uint256 interestWithdrawn,
    uint256 principalWithdrawn
  );

  event TranchedPoolAssessed(address indexed pool);
  event PaymentApplied(
    address indexed payer,
    address indexed pool,
    uint256 interestAmount,
    uint256 principalAmount,
    uint256 remainingAmount,
    uint256 reserveAmount
  );
  // Note: This has to exactly match the even in the TranchingLogic library for events to be emitted
  // correctly
  event SharePriceUpdated(
    address indexed pool,
    uint256 indexed tranche,
    uint256 principalSharePrice,
    int256 principalDelta,
    uint256 interestSharePrice,
    int256 interestDelta
  );
  event ReserveFundsCollected(address indexed from, uint256 amount);
  event CreditLineMigrated(
    IHelixCreditLineV3 indexed oldCreditLine,
    IHelixCreditLineV3 indexed newCreditLine
  );
  event DrawdownMade(address indexed borrower, uint256 amount);
  event DrawdownsPaused(address indexed pool);
  event DrawdownsUnpaused(address indexed pool);
  event EmergencyShutdown(address indexed pool);
  event TrancheLocked(address indexed pool, uint256 trancheId, uint256 lockedUntil);
  event SliceCreated(address indexed pool, uint256 sliceId);
  event TranchesCreated(address indexed junior, address indexed senior);
  // // Modifiers /////////////////////////////////////////////////////////////////

  /// @inheritdoc IVersioned
  function getVersion() external pure override returns (uint8[3] memory version) {
    (version[0], version[1], version[2]) = (MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION);
  }

  modifier onlyLocker() {
    /// @dev NA: not authorized. not locker
    if (!hasRole(LOCKER_ROLE, msg.sender)) {
      revert NotAuthorized();
    }
    // require(hasRole(LOCKER_ROLE, msg.sender), "NA");
    _;
  }

  modifier notCancelled() {
    if (cancelled) {
      revert AlreadyCancelled();
    }
    _;
  }

  modifier notClosed() {
    if (closed) {
      revert AlreadyClosed();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

// Copied from: https://eips.ethereum.org/EIPS/eip-173

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 {
  /// @dev This emits when ownership of a contract changes.
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /// @notice Get the address of the owner
  /// @return The address of the owner.
  function owner() external view returns (address);

  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract
  function transferOwnership(address _newOwner) external;
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

import { IHelixTranchedPool} from "./IHelixTranchedPool.sol";
import {IHelixPoolShares} from "./IHelixPoolShares.sol";

abstract contract IHelixMultiTranchedPool is IHelixTranchedPool {
    struct TrancheInfo {
        address tranche;
        uint256 id;
        uint256 principalDeposited;
        uint256 principalSharePrice;
        uint256 interestSharePrice;
        uint256 maximumInvestment;
        uint256 minimumInvestment;
    }

    struct PoolSlice {
        IHelixPoolShares seniorTranche;
        IHelixPoolShares juniorTranche;
        uint256 totalInterestAccrued;
        uint256 principalDeployed;
        bool poolLocked;
        bool drawdownMade;
    }

    function poolSlices(uint256 index)
        external
        view
        virtual
        returns (PoolSlice memory);
        
    function numSlices() external view virtual returns (uint256);

     function initialize(
        string[2] calldata _loanFacade,
        // config - borrower - interest model
        address[3] calldata _addresses,
        // junior fee percent - _interestApr - _lateFeeApr
        uint256[4] calldata _uints,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt - _fundingDate
        uint256[5] calldata _days,
        // _maxTarget - _minTarget - ratio
        uint256[3] calldata _targets,
        uint256[] calldata _allowedUIDTypes
    ) public virtual;


    function getTranche(uint256 tranche)
        external
        view
        virtual
        returns (TrancheInfo memory);

    function pay(uint256 amount) external virtual;

    // function initializeNextSlice(uint256 _fundableAt) external virtual;

    function totalJuniorDeposits() external view virtual returns (uint256);

    function drawdown() external virtual returns(uint256);

    function setFundableAt(uint256 timestamp) external virtual;

    function deposit(uint256 tranche, uint256 amount)
        external
        virtual
        returns (uint256 tokenId);

    function assess() external virtual;

    function depositWithPermit(
        uint256 tranche,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 tokenId);

    function availableToWithdraw(uint256 tranche)
        external
        view
        virtual
        returns (uint256 interestRedeemable, uint256 principalRedeemable);

    function withdraw(
        uint256 tranche
    )
        external
        virtual
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    function redeem(
        uint256 tranche
    )
        external
        virtual
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn);
    
    function redeemMultiple(
        uint256[] calldata tranches
    ) external virtual;

    // function withdrawMax(uint256 tranche)
    //     external
    //     virtual
    //     returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    // function withdrawMaxWithPermit(
    //     uint256 tranche,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external virtual returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    function withdrawMultiple(
        uint256[] calldata tranches
    ) external virtual;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

interface IHelixPoolShares is IERC20MetadataUpgradeable {
    function mint(address account, uint256 value) external;
    function burn(address account, uint256 value) external;
    function lockPool() external;
    function withdrawFunds(address _receiver) external;
    function withdrawableFundsOfByShares(address _owner, uint256 _amount) external view returns(uint256, uint256);
    function withdrawableFundsOf(address _owner) external view returns(uint256, uint256);
    function withdrawnInterestOf(address _owner) external view returns(uint256);
    function withdrawnPrincipalOf(address _owner) external view returns(uint256);
    function updateFundsReceived(uint256 _interest, uint256 _principal) external;
    function emergencyTokenTransfer(address _token, address _to, uint256 _amount) external;
    function principalSharePrice() external view returns(uint256);
    function interestSharePrice() external view returns(uint256);
    function principalDeposited() external view returns(uint256);
    function id() external view returns(uint256);
    function initialize(uint256 _id, address _config, address _pool, string memory _name, string memory _symbol) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import {IHelixCreditLineV3} from "./IHelixCreditLineV3.sol";

abstract contract IHelixTranchedPool {
    IHelixCreditLineV3 public creditLine;
    uint256 public createdAt;

    function getAllowedUIDTypes() external view virtual returns (uint256[] memory);

    function cancel() external virtual;

    function close() external virtual;

    function lockPool() external virtual;

    function setFileHash(bytes32 fileHash) external virtual;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { IHelixTranchedPool} from "./IHelixTranchedPool.sol";
import {IHelixPoolShares} from "./IHelixPoolShares.sol";

abstract contract IHelixUniTranchedPool is IHelixTranchedPool {
    struct TrancheInfo {
        address tranche;
        uint256 id;
        uint256 principalDeposited;
        uint256 principalSharePrice;
        uint256 interestSharePrice;
        uint256 maximumInvestment;
        uint256 minimumInvestment;
    }

    struct PoolSlice {
        IHelixPoolShares uniTranche;
        uint256 totalInterestAccrued;
        uint256 principalDeployed;
        bool poolLocked;
        bool drawdownMade;
    }

    function poolSlices(uint256 index)
        external
        view
        virtual
        returns (PoolSlice memory);
    function numSlices() external view virtual returns (uint256);


     function initialize(
        string[2] calldata _loanFacade,
        // config - borrower - interest model
        address[3] calldata _addresses,
        // _interestApr - _lateFeeApr - _minTicketSize
        uint256[3] calldata _uints,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt - _fundingDate
        uint256[5] calldata _days,
        // _maxTarget - _minTarget
        uint256[2] calldata _targets,
        uint256[] calldata _allowedUIDTypes
    ) public virtual;


    function getTranche(uint256 tranche)
        external
        view
        virtual
        returns (TrancheInfo memory);

    // function pay(uint256 amount) external virtual;


    // function initializeNextSlice(uint256 _fundableAt) external virtual;

    // function totalJuniorDeposits() external view virtual returns (uint256);

    function drawdown() external virtual returns(uint256);

    function setFundableAt(uint256 timestamp) external virtual;

    function deposit(uint256 tranche, uint256 amount)
        external
        virtual
        returns (uint256 tokenId);

    function assess(uint256 interestPayment, uint256 principalPayment) external virtual;

    function depositWithPermit(
        uint256 tranche,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 tokenId);

    function availableToWithdraw(uint256 tranche)
        external
        view
        virtual
        returns (uint256 interestRedeemable, uint256 principalRedeemable);

    function withdraw(
        uint256 tranche
    )
        external
        virtual
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    function redeem(
        uint256 tranche
    )
        external
        virtual
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn);
    
    function redeemMultiple(
        uint256[] calldata tranches
    ) external virtual;

    // function withdrawMax(uint256 tranche)
    //     external
    //     virtual
    //     returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    // function withdrawMaxWithPermit(
    //     uint256 tranche,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external virtual returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    function withdrawMultiple(
        uint256[] calldata tranches
    ) external virtual;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IRequiresUID {
  function hasAllowedUID(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title interface for implementers that have an arbitrary associated tag
interface IVersioned {
  /// @notice Returns the version triplet `[major, minor, patch]`
  function getVersion() external pure returns (uint8[3] memory);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Math.sol";
import "./WadRayMath.sol";
import "../proxy/ImplementationRepository.sol";
import "../proxy/UcuProxy.sol";
import { IHelixPoolShares } from "../interfaces/IHelixPoolShares.sol";
import {IHelixCreditLineV3} from "../interfaces/IHelixCreditLineV3.sol";
import "../interfaces/IHelixMultiTranchedPool.sol";
import "../interfaces/IHelixUniTranchedPool.sol";
import { IERC20withDec } from "../interfaces/IERC20withDec.sol";
import {IHelixConfig} from "../interfaces/IHelixConfig.sol";
import {HelixConfigHelper} from "./HelixConfigHelper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title helixTranchingLogic
 * @notice Library for handling the payments waterfall
 * @author Helix
 */

library HelixTranchingLogic {
    // event TranchedPoolAssessed(address indexed pool);
    event PaymentApplied(
        address indexed payer,
        address indexed pool,
        uint256 interestAmount,
        uint256 principalAmount,
        uint256 remainingAmount,
        uint256 reserveAmount
    );

    using WadRayMath for uint256;

    using HelixConfigHelper for IHelixConfig;
    using SafeERC20 for IERC20withDec;

    struct SliceInfo {
        uint256 reserveFeePercent;
        uint256 interestAccrued;
        uint256 principalAccrued;
    }

    struct ApplyResult {
        uint256 actualPaidInterest;
        uint256 actualPaidPrincipal;
        uint256 interestRemaining;
        uint256 principalRemaining;
        uint256 reserveDeduction;
        uint256 oldInterestSharePrice;
        uint256 oldPrincipalSharePrice;
    }

    struct TranchePayout {
        uint256 actualPaidInterest;
        uint256 actualPaidPrincipal;
        uint256 interestRemaining;
        uint256 principalRemaining;
    }

    uint256 internal constant FP_SCALING_FACTOR = 1e18;
    uint256 public constant NUM_TRANCHES_PER_SLICE = 2;
    uint256 public constant NUM_TRANCHES_PER_SLICE_IN_UNI_POOL = 1;

    function usdcToSharePrice(uint256 amount, uint256 totalShares)
        public
        pure
        returns (uint256)
    {
        return
            totalShares == 0
                ? 0
                : amount.wadDiv(totalShares);
    }

    function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares)
        public
        pure
        returns (uint256)
    {
        return sharePrice.wadMul(totalShares);
    }

    // function lockTranche(
    //     IHelixPoolShares tranche,
    //     IHelixConfig config
    // ) external {
    //     // tranche.lockedUntil = block.timestamp + (
    //     //     config.getDrawdownPeriodInSeconds()
    //     // );
    //     // emit TrancheLocked(address(this), tranche.id, tranche.lockedUntil);
    // }

    // function redeemableInterestAndPrincipal(
    //     IHelixMultiTranchedPool.TrancheInfo memory trancheInfo,
    //     uint256 amount
    // ) public view returns (uint256) {
    //     // This supports withdrawing before or after locking because principal share price starts at 1
    //     // and is set to 0 on lock. Interest share price is always 0 until interest payments come back, when it increases


    //     uint256 maxPrincipalRedeemable = trancheInfo.withdrawableFundsOf(
    //         trancheInfo.principalSharePrice,
    //         amount
    //     );
    //     // The principalAmount is used as the totalShares because we want the interestSharePrice to be expressed as a
    //     // percent of total loan value e.g. if the interest is 10% APR, the interestSharePrice should approach a max of 0.1.
    //     uint256 maxInterestRedeemable = sharePriceToUsdc(
    //         trancheInfo.interestSharePrice,
    //         amount
    //     );

    //     uint256 interestRedeemable = maxInterestRedeemable - (
    //         tokenInfo.interestRedeemed
    //     );
    //     uint256 principalRedeemable = maxPrincipalRedeemable - (
    //         tokenInfo.principalRedeemed
    //     );

    //     return (interestRedeemable, principalRedeemable);
    // }

    function calculateExpectedSharePrice(
        IHelixPoolShares tranche,
        uint256 amount,
        IHelixMultiTranchedPool.PoolSlice memory slice
    ) public view returns (uint256) {
        uint256 sharePrice = usdcToSharePrice(
            amount,
            tranche.totalSupply()
        );
        return _scaleByPercentOwnership(tranche, sharePrice, slice);
    }

    function scaleForSlice(
        IHelixMultiTranchedPool.PoolSlice memory slice,
        uint256 amount,
        uint256 totalDeployed
    ) public pure returns (uint256) {
        return scaleByFraction(amount, slice.principalDeployed, totalDeployed);
    }

    function scaleForSlice(
        IHelixUniTranchedPool.PoolSlice memory slice,
        uint256 amount,
        uint256 totalDeployed
    ) public pure returns (uint256) {
        return scaleByFraction(amount, slice.principalDeployed, totalDeployed);
    }

    // We need to create this struct so we don't run into a stack too deep error due to too many variables
    function getSliceInfo(
        IHelixMultiTranchedPool.PoolSlice memory slice,
        IHelixCreditLineV3 creditLine,
        uint256 totalDeployed,
        uint256 reserveFeePercent
    ) public view returns (SliceInfo memory) {
        (
            uint256 interestAccrued,
            uint256 principalAccrued
        ) = getTotalInterestAndPrincipal(slice, creditLine, totalDeployed);
        return
            SliceInfo({
                reserveFeePercent: reserveFeePercent,
                interestAccrued: interestAccrued,
                principalAccrued: principalAccrued
            });
    }

    function getTotalInterestAndPrincipal(
        IHelixMultiTranchedPool.PoolSlice memory slice,
        IHelixCreditLineV3 creditLine,
        uint256 totalDeployed
    ) public view returns (uint256, uint256) {
        uint256 principalAccrued = creditLine.principalOwed();
        // In addition to principal actually owed, we need to account for early principal payments
        // If the borrower pays back 5K early on a 10K loan, the actual principal accrued should be
        // 5K (balance- deployed) + 0 (principal owed)
        principalAccrued = totalDeployed - creditLine.balance() + principalAccrued;
        // Now we need to scale that correctly for the slice we're interested in
        principalAccrued = scaleForSlice(
            slice,
            principalAccrued,
            totalDeployed
        );
        // Finally, we need to account for partial drawdowns. e.g. If 20K was deposited, and only 10K was drawn down,
        // Then principal accrued should start at 10K (total deposited - principal deployed), not 0. This is because
        // share price starts at 1, and is decremented by what was drawn down.
        uint256 totalDeposited = slice.seniorTranche.principalDeposited() + (
            slice.juniorTranche.principalDeposited()
        );
        principalAccrued = totalDeposited - slice.principalDeployed + principalAccrued;
        return (slice.totalInterestAccrued, principalAccrued);
    }

    function scaleByFraction(
        uint256 amount,
        uint256 fraction,
        uint256 total
    ) public pure returns (uint256) {
        // uint256 totalAsFixedPoint = FixedPoint
        //     .fromUnscaledUint(total);
        // uint256 memory fractionAsFixedPoint = FixedPoint
        //     .fromUnscaledUint(fraction);
        // return
        //     fractionAsFixedPoint
        //         .div(totalAsFixedPoint)
        //         .mul(amount)
        //         .div(FP_SCALING_FACTOR)
        //         .rawValue;

        return fraction.wadDiv(total).wadMul(amount);
    }

    /// @notice apply a payment to all slices
    /// @param poolSlices slices to apply to
    /// @param numSlices number of slices
    /// @param interest amount of interest to apply
    /// @param principal amount of principal to apply
    /// @param reserveFeePercent percentage that protocol will take for reserves
    /// @param totalDeployed total amount of principal deployed
    /// @param creditLine creditline to account for
    /// @param juniorFeePercent percentage the junior tranche will take
    /// @return total amount that will be sent to reserves
    function applyToAllSlices(
        mapping(uint256 => IHelixMultiTranchedPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IHelixCreditLineV3 creditLine,
        IHelixConfig config,
        uint256 juniorFeePercent
    ) external returns (uint256) {
        ApplyResult memory result = HelixTranchingLogic.applyToAllSeniorTranches(
            poolSlices,
            numSlices,
            interest,
            principal,
            reserveFeePercent,
            totalDeployed,
            [address(creditLine), address(config)],
            juniorFeePercent
        );

        return
            result.reserveDeduction + (
                HelixTranchingLogic.applyToAllJuniorTranches(
                    poolSlices,
                    numSlices,
                    result.interestRemaining,
                    result.principalRemaining,
                    reserveFeePercent,
                    totalDeployed,
                    [address(creditLine), address(config)]
                )
            );
    }

    function applyToAllSlices(
        mapping(uint256 => IHelixUniTranchedPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IHelixCreditLineV3 creditLine,
        IHelixConfig config
    ) external returns (uint256) {
        ApplyResult memory result = HelixTranchingLogic.applyToAllUniTranches(
            poolSlices,
            numSlices,
            interest,
            principal,
            reserveFeePercent,
            totalDeployed,
            [address(creditLine), address(config)]
        );

        return result.reserveDeduction;
    }

    function applyToAllSeniorTranches(
        mapping(uint256 => IHelixMultiTranchedPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        // Creditline - config
        address[2] memory addresses,
        // IHelixCreditLineV3 creditLine,
        // IHelixConfig config,
        uint256 juniorFeePercent
    ) internal returns (ApplyResult memory) {
        ApplyResult memory seniorApplyResult;
        for (uint256 i = 0; i < numSlices; i++) {
            IHelixMultiTranchedPool.PoolSlice storage slice = poolSlices[i];

            SliceInfo memory sliceInfo = getSliceInfo(
                slice,
                IHelixCreditLineV3(addresses[0]),
                totalDeployed,
                reserveFeePercent
            );

            // Since slices cannot be created when the loan is late, all interest collected can be assumed to split
            // pro-rata across the slices. So we scale the interest and principal to the slice
            ApplyResult memory applyResult = applyToSeniorTranche(
                slice,
                scaleForSlice(slice, interest, totalDeployed),
                scaleForSlice(slice, principal, totalDeployed),
                juniorFeePercent,
                sliceInfo
            );

            uint256 totalPaid = applyResult.actualPaidInterest + applyResult.actualPaidPrincipal;
            IHelixConfig(addresses[1]).getUSDC().safeTransferFrom(address(this), address(slice.seniorTranche), totalPaid);
            slice.seniorTranche.updateFundsReceived(applyResult.actualPaidInterest,applyResult.actualPaidPrincipal);

            emitSharePriceUpdatedEvent(slice.seniorTranche, applyResult);
            seniorApplyResult.interestRemaining = seniorApplyResult
                .interestRemaining
                 + (applyResult.interestRemaining);
            seniorApplyResult.principalRemaining = seniorApplyResult
                .principalRemaining 
                 + (applyResult.principalRemaining);
            seniorApplyResult.reserveDeduction = seniorApplyResult
                .reserveDeduction
                 + (applyResult.reserveDeduction);
        }
        return seniorApplyResult;
    }

    function applyToAllJuniorTranches(
        mapping(uint256 => IHelixMultiTranchedPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        // Creditline - config
        address[2] memory addresses
        // IHelixCreditLineV3 creditLine,
        // IHelixConfig config
    ) internal returns (uint256 totalReserveAmount) {
        for (uint256 i = 0; i < numSlices; i++) {
            IHelixMultiTranchedPool.PoolSlice storage slice = poolSlices[i];

            SliceInfo memory sliceInfo = getSliceInfo(
                slice,
                IHelixCreditLineV3(addresses[0]),
                totalDeployed,
                reserveFeePercent
            );
            // Any remaining interest and principal is then shared pro-rata with the junior slices
            ApplyResult memory applyResult = applyToJuniorTranche(
                poolSlices[i],
                scaleForSlice(poolSlices[i], interest, totalDeployed),
                scaleForSlice(poolSlices[i], principal, totalDeployed),
                sliceInfo
            );

            uint256 totalPaid = applyResult.actualPaidInterest + applyResult.actualPaidPrincipal;
            IHelixConfig(addresses[1]).getUSDC().safeTransferFrom(address(this), address(slice.juniorTranche), totalPaid);
            slice.juniorTranche.updateFundsReceived(applyResult.actualPaidInterest,applyResult.actualPaidPrincipal);

            emitSharePriceUpdatedEvent(
                poolSlices[i].juniorTranche,
                applyResult
            );
            totalReserveAmount = totalReserveAmount + applyResult.reserveDeduction;
        }
        return totalReserveAmount;
    }

    function applyToAllUniTranches(
        mapping(uint256 => IHelixUniTranchedPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        // Creditline - config
        address[2] memory addresses
        // IHelixCreditLineV3 creditLine,
        // IHelixConfig config
    ) internal returns (ApplyResult memory) {
        ApplyResult memory uniApplyResult;
        for (uint256 i = 0; i < numSlices; i++) {
            IHelixUniTranchedPool.PoolSlice storage slice = poolSlices[i];

            // SliceInfo memory sliceInfo = getSliceInfo(
            //     slice,
            //     IHelixCreditLineV3(addresses[0]),
            //     totalDeployed,
            //     reserveFeePercent
            // );

            uint256 reserveDeduction = calculateReserveDeduction(interest, reserveFeePercent);

            // Since slices cannot be created when the loan is late, all interest collected can be assumed to split
            // pro-rata across the slices. So we scale the interest and principal to the slice
            // ApplyResult memory applyResult = applyToSeniorTranche(
            //     slice,
            //     scaleForSlice(slice, interest, totalDeployed),
            //     scaleForSlice(slice, principal, totalDeployed),
            //     juniorFeePercent,
            //     sliceInfo
            // );

            // uint256 totalPaid = applyResult.actualPaidInterest + applyResult.actualPaidPrincipal;
            uint256 actualPaidInterest = interest - reserveDeduction;
            uint256 totalPaid = actualPaidInterest + principal;
            IHelixConfig(addresses[1]).getUSDC().safeTransferFrom(address(this), address(slice.uniTranche), totalPaid);
            slice.uniTranche.updateFundsReceived(actualPaidInterest, principal);

            emitSharePriceUpdatedEventOfUniTranche(slice.uniTranche);
            // uniApplyResult.interestRemaining = uniApplyResult
            //     .interestRemaining
            //      + (applyResult.interestRemaining);
            // uniApplyResult.principalRemaining = uniApplyResult
            //     .principalRemaining 
            //      + (applyResult.principalRemaining);
            uniApplyResult.reserveDeduction = uniApplyResult
                .reserveDeduction
                 + (reserveDeduction);
        }
        return uniApplyResult;
    }

    function calculateReserveDeduction(
        uint256 interestRemaining,
        uint256 reserveFeePercent
    ) internal pure returns (uint256) {
        uint256 reserveDeduction = scaleByFraction(
            interestRemaining,
            reserveFeePercent,
            uint256(100)
        );
        return reserveDeduction;
    }

    function emitSharePriceUpdatedEvent(
        IHelixPoolShares tranche,
        ApplyResult memory applyResult
    ) internal {
        emit SharePriceUpdated(
            address(this),
            tranche.id(),
            tranche.principalSharePrice(),
            int256(
                tranche.principalSharePrice() - applyResult.oldPrincipalSharePrice
            ),
            tranche.interestSharePrice(),
            int256(
                tranche.interestSharePrice() - applyResult.oldInterestSharePrice
            )
        );
    }

    function emitSharePriceUpdatedEventOfUniTranche(
        IHelixPoolShares tranche
    ) internal {
        emit SharePriceUpdatedOfUniTranche(
            address(this),
            tranche.id(),
            tranche.principalSharePrice(),
            tranche.interestSharePrice()
        );
    }

    function applyToSeniorTranche(
        IHelixMultiTranchedPool.PoolSlice storage slice,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 juniorFeePercent,
        SliceInfo memory sliceInfo
    ) internal view returns (ApplyResult memory) {
        // First determine the expected share price for the senior tranche. This is the gross amount the senior
        // tranche should receive.
        uint256 expectedInterestSharePrice = calculateExpectedSharePrice(
            slice.seniorTranche,
            sliceInfo.interestAccrued,
            slice
        );
        uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
            slice.seniorTranche,
            sliceInfo.principalAccrued,
            slice
        );

        // Deduct the junior fee and the protocol reserve
        uint256 desiredNetInterestSharePrice = scaleByFraction(
            expectedInterestSharePrice,
            uint256(100) - (juniorFeePercent + (sliceInfo.reserveFeePercent)),
            uint256(100)
        );
        // Collect protocol fee interest received (we've subtracted this from the senior portion above)
        uint256 reserveDeduction = scaleByFraction(
            interestRemaining,
            sliceInfo.reserveFeePercent,
            uint256(100)
        );
        interestRemaining = interestRemaining - reserveDeduction;
        uint256 oldInterestSharePrice = slice.seniorTranche.interestSharePrice();
        uint256 oldPrincipalSharePrice = slice
            .seniorTranche
            .principalSharePrice();
            
        // Apply the interest remaining so we get up to the netInterestSharePrice
        TranchePayout memory tranchePayout = _applyBySharePrice(
            slice.seniorTranche,
            interestRemaining,
            principalRemaining,
            desiredNetInterestSharePrice,
            expectedPrincipalSharePrice
        );

        interestRemaining = tranchePayout.interestRemaining;
        principalRemaining = tranchePayout.principalRemaining;

        return
            ApplyResult({
                interestRemaining: interestRemaining,
                principalRemaining: principalRemaining,
                actualPaidInterest: tranchePayout.actualPaidInterest,
                actualPaidPrincipal: tranchePayout.actualPaidPrincipal,
                reserveDeduction: reserveDeduction,
                oldInterestSharePrice: oldInterestSharePrice,
                oldPrincipalSharePrice: oldPrincipalSharePrice
            });
    }

    function applyToJuniorTranche(
        IHelixMultiTranchedPool.PoolSlice storage slice,
        uint256 interestRemaining,
        uint256 principalRemaining,
        SliceInfo memory sliceInfo
    ) public view returns (ApplyResult memory) {
        // Then fill up the junior tranche with all the interest remaining, upto the principal share price
        // console.log("Interest share price junior: ", interestRemaining, usdcToSharePrice(
        //             interestRemaining,
        //             slice.juniorTranche.totalSupply
                // ));
        uint256 expectedInterestSharePrice = slice
            .juniorTranche
            .interestSharePrice()
            + (
                usdcToSharePrice(
                    interestRemaining,
                    slice.juniorTranche.totalSupply()
                )
            );
        uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
            slice.juniorTranche,
            sliceInfo.principalAccrued,
            slice
        );
        uint256 oldInterestSharePrice = slice.juniorTranche.interestSharePrice();
        uint256 oldPrincipalSharePrice = slice
            .juniorTranche
            .principalSharePrice();
        // TODO:  get actual paid interest + principal

        TranchePayout memory tranchePayout = _applyBySharePrice(
            slice.juniorTranche,
            interestRemaining,
            principalRemaining,
            expectedInterestSharePrice,
            expectedPrincipalSharePrice
        );

        interestRemaining = tranchePayout.interestRemaining;
        principalRemaining = tranchePayout.principalRemaining;



        // All remaining interest and principal is applied towards the junior tranche as interest
        interestRemaining = interestRemaining + principalRemaining;
        // Since any principal remaining is treated as interest (there is "extra" interest to be distributed)
        // we need to make sure to collect the protocol fee on the additional interest (we only deducted the
        // fee on the original interest portion)
        uint256 reserveDeduction = scaleByFraction(
            principalRemaining,
            sliceInfo.reserveFeePercent,
            uint256(100)
        );
        interestRemaining = interestRemaining - reserveDeduction;
        principalRemaining = 0;

        // TODO: Get bonus actual paid interest + principal 
        // NOTE: Actually it will consider the rest as interest only
        TranchePayout memory bonusTranchePayout = _applyByAmount(
            interestRemaining + principalRemaining,
            0,
            interestRemaining + principalRemaining,
            0
        );

        interestRemaining = tranchePayout.interestRemaining;
        // NOTE:  Store all the bonus interest to actual paid interest
        tranchePayout.actualPaidInterest += bonusTranchePayout.actualPaidInterest;

        return
            ApplyResult({
                interestRemaining: interestRemaining,
                principalRemaining: principalRemaining,
                actualPaidInterest: tranchePayout.actualPaidInterest,
                actualPaidPrincipal: tranchePayout.actualPaidPrincipal,
                reserveDeduction: reserveDeduction,
                oldInterestSharePrice: oldInterestSharePrice,
                oldPrincipalSharePrice: oldPrincipalSharePrice
            });
    }

    function migrateAccountingVariables(
        IHelixCreditLineV3 originalCl,
        IHelixCreditLineV3 newCl
    ) external {
        // Copy over all accounting variables
        newCl.setBalance(originalCl.balance());
        newCl.setLimit(originalCl.limit());
        newCl.setInterestOwed(originalCl.interestOwed());
        newCl.setPrincipalOwed(originalCl.principalOwed());
        newCl.setTermEndTime(originalCl.termEndTime());
        newCl.setNextDueTime(originalCl.nextDueTime());
        newCl.setInterestAccruedAsOf(originalCl.interestAccruedAsOf());
        newCl.setLastFullPaymentTime(originalCl.lastFullPaymentTime());
        newCl.setTotalInterestAccrued(originalCl.totalInterestAccrued());
    }

    function closeCreditLine(IHelixCreditLineV3 cl) external {
        // Close out old CL
        cl.setBalance(0);
        cl.setLimit(0);
        cl.setMaxLimit(0);
    }

    function trancheIdToSliceIndex(uint256 trancheId)
        external
        pure
        returns (uint256)
    {
        return (trancheId - 1) / NUM_TRANCHES_PER_SLICE;
    }

    function initializeNextSlice(
        mapping(uint256 => IHelixMultiTranchedPool.PoolSlice) storage poolSlices,
        uint256 sliceIndex,
        string[2] memory loanFacade,
        IHelixConfig config
    ) external returns (address, address) {
        IHelixPoolShares juniorTranche;
        IHelixPoolShares seniorTranche;

        address admin = config.protocolAdminAddress();

        ImplementationRepository repo = config.getPoolSharesImplementationRepository();
        UcuProxy poolProxy = new UcuProxy(repo, admin);

        juniorTranche = IHelixPoolShares(address(poolProxy));
        juniorTranche.initialize(
            sliceIndexToJuniorTrancheId(sliceIndex),
            address(config),
            address(this),
            string(abi.encodePacked(loanFacade[0],"-JuniorTranche")),
            string(abi.encodePacked(loanFacade[1],"-JR"))
        );

        poolProxy = new UcuProxy(repo, admin);
        seniorTranche = IHelixPoolShares(address(poolProxy));
        seniorTranche.initialize(
            sliceIndexToSeniorTrancheId(sliceIndex),
            address(config),
            address(this),
            string(abi.encodePacked(loanFacade[0],"-SeniorTranche")),
            string(abi.encodePacked(loanFacade[1],"-SR"))
        );

        poolSlices[sliceIndex] = IHelixMultiTranchedPool.PoolSlice({
            seniorTranche: seniorTranche,
            juniorTranche: juniorTranche,
            totalInterestAccrued: 0,
            principalDeployed: 0,
            poolLocked: false,
            drawdownMade: false
        });

        return (address(juniorTranche), address(seniorTranche));
    }

    function initializeNextSlice(
        mapping(uint256 => IHelixUniTranchedPool.PoolSlice) storage poolSlices,
        uint256 sliceIndex,
        string[2] memory loanFacade,
        IHelixConfig config
    ) external returns (address) {
        IHelixPoolShares uniTranche;

        address admin = config.protocolAdminAddress();

        ImplementationRepository repo = config.getPoolSharesImplementationRepository();
        UcuProxy poolProxy = new UcuProxy(repo, admin);

        uniTranche = IHelixPoolShares(address(poolProxy));
        uniTranche.initialize(
            sliceIndexToUniTrancheId(sliceIndex),
            address(config),
            address(this),
            string(abi.encodePacked(loanFacade[0],"-UniTranche")),
            string(abi.encodePacked(loanFacade[1],"-UT"))
        );

        poolSlices[sliceIndex] = IHelixUniTranchedPool.PoolSlice({
            uniTranche: uniTranche,
            totalInterestAccrued: 0,
            principalDeployed: 0,
            poolLocked: false,
            drawdownMade: false
        });

        return address(uniTranche);
    }

    function sliceIndexToJuniorTrancheId(uint256 sliceIndex)
        public
        pure
        returns (uint256)
    {
        // 0 -> 2
        // 1 -> 4
        return sliceIndex* NUM_TRANCHES_PER_SLICE + 2;
    }

    function sliceIndexToSeniorTrancheId(uint256 sliceIndex)
        public
        pure
        returns (uint256)
    {
        // 0 -> 1
        // 1 -> 3
        return sliceIndex * NUM_TRANCHES_PER_SLICE + 1;
    }

    function sliceIndexToUniTrancheId(uint256 sliceIndex)
        public
        pure
        returns (uint256)
    {
        return sliceIndex * NUM_TRANCHES_PER_SLICE_IN_UNI_POOL + 1;
    }

    function isSeniorTrancheId(uint256 trancheId) external pure returns (bool) {
        uint seniorTrancheId;
        uint numberOfTranchesPerSlice = HelixTranchingLogic.NUM_TRANCHES_PER_SLICE;

        assembly {
            seniorTrancheId := mod(trancheId, numberOfTranchesPerSlice)
        }

        return seniorTrancheId == 1;
    }

    function isJuniorTrancheId(uint256 trancheId) external pure returns (bool) {
        uint juniorTrancheId;
        uint numberOfTranchesPerSlice = HelixTranchingLogic.NUM_TRANCHES_PER_SLICE;

        assembly {
            juniorTrancheId := mod(trancheId, numberOfTranchesPerSlice)
        }

        return trancheId != 0 && juniorTrancheId == 0;
    }

    // // INTERNAL //////////////////////////////////////////////////////////////////

    function _applyToSharePrice(
        uint256 amountRemaining,
        // uint256 currentSharePrice,
        uint256 desiredAmount
        // uint256 totalShares
    ) internal pure returns (uint256, uint256) {
        // If no money left to apply, or don't need any changes, return the original amounts
        if (amountRemaining == 0 || desiredAmount == 0) {
            // return (amountRemaining, currentSharePrice);
            return (amountRemaining, 0);
        }
        if (amountRemaining < desiredAmount) {
            // We don't have enough money to adjust share price to the desired level. So just use whatever amount is left
            desiredAmount = amountRemaining;
        }
        // uint256 sharePriceDifference = usdcToSharePrice(
        //     desiredAmount,
        //     totalShares
        // );
        return (
            amountRemaining - desiredAmount, // Interest remaining
            desiredAmount // Desired Amount to pay
        );
    }

    function _scaleByPercentOwnership(
        IHelixPoolShares tranche,
        uint256 amount,
        IHelixMultiTranchedPool.PoolSlice memory slice
    ) internal view returns (uint256) {
        uint256 totalDeposited = slice.juniorTranche.totalSupply() + (
            slice.seniorTranche.totalSupply()
        );
        return
            scaleByFraction(amount, tranche.totalSupply(), totalDeposited);
    }

    function _desiredAmountFromSharePrice(
        uint256 desiredSharePrice,
        uint256 actualSharePrice,
        uint256 totalShares
    ) internal pure returns (uint256) {
        // If the desired share price is lower, then ignore it, and leave it unchanged
        if (desiredSharePrice < actualSharePrice) {
            desiredSharePrice = actualSharePrice;
        }
        uint256 sharePriceDifference = desiredSharePrice - actualSharePrice;
        return sharePriceToUsdc(sharePriceDifference, totalShares);
    }

    function _applyByAmount(
        // IHelixPoolShares tranche,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 desiredInterestAmount,
        uint256 desiredPrincipalAmount
    ) internal pure returns (TranchePayout memory) {
        // uint256 totalShares = tranche.totalSupply();
        uint256 actualPaidInterest;
        uint256 actualPaidPrincipal;

        (interestRemaining, actualPaidInterest) = _applyToSharePrice(
            interestRemaining,
            // tranche.interestSharePrice(),
            desiredInterestAmount
            // totalShares
        );

        (principalRemaining, actualPaidPrincipal) = _applyToSharePrice(
            principalRemaining,
            // tranche.principalSharePrice(),
            desiredPrincipalAmount
            // totalShares
        );
        
        // TODO: Call to update tranche interest + principal share price
        return TranchePayout({
            interestRemaining: interestRemaining,
            principalRemaining: principalRemaining,
            actualPaidInterest: actualPaidInterest,
            actualPaidPrincipal: actualPaidPrincipal
        });
        // return (interestRemaining, principalRemaining, actualPaidInterest, actualPaidPrincipal);
    }

    function _applyBySharePrice(
        IHelixPoolShares tranche,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 desiredInterestSharePrice,
        uint256 desiredPrincipalSharePrice
    ) internal view returns (TranchePayout memory) {
        uint256 desiredInterestAmount = _desiredAmountFromSharePrice(
            desiredInterestSharePrice,
            tranche.interestSharePrice(),
            tranche.totalSupply()
        );
        uint256 desiredPrincipalAmount = _desiredAmountFromSharePrice(
            desiredPrincipalSharePrice,
            tranche.principalSharePrice(),
            tranche.totalSupply()
        );
        return
            _applyByAmount(
                interestRemaining,
                principalRemaining,
                desiredInterestAmount,
                desiredPrincipalAmount
            );
    }

    // // Events /////////////////////////////////////////////////////////////////////

    // NOTE: this needs to match the event in TranchedPool
    event TrancheLocked(
        address indexed pool,
        uint256 trancheId,
        uint256 lockedUntil
    );

    event SharePriceUpdated(
        address indexed pool,
        uint256 indexed tranche,
        uint256 principalSharePrice,
        int256 principalDelta,
        uint256 interestSharePrice,
        int256 interestDelta
    );

    event SharePriceUpdatedOfUniTranche(
        address indexed pool,
        uint256 indexed tranche,
        uint256 principalSharePrice,
        uint256 interestSharePrice
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)
pragma solidity ^0.8.4;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
   
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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

import {ImplementationRepository as Repo} from "./ImplementationRepository.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC173} from "../interfaces/IERC173.sol";

/// @title User Controlled Upgrade (UCU) Proxy
///
/// The UCU Proxy contract allows the owner of the proxy to control _when_ they
/// upgrade their proxy, but not to what implementation.  The implementation is
/// determined by an externally controlled {ImplementationRepository} contract that
/// specifices the upgrade path. A user is able to upgrade their proxy as many
/// times as is available until they're reached the most up to date version
contract UcuProxy is IERC173, Proxy {
  /// @dev Storage slot with the address of the current implementation.
  /// This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
  bytes32 private constant _IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  // defined here: https://eips.ethereum.org/EIPS/eip-1967
  // result of `bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)`
  bytes32 private constant _ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  // result of `bytes32(uint256(keccak256('eipxxxx.proxy.repository')) - 1)`
  bytes32 private constant _REPOSITORY_SLOT =
    0x007037545499569801a5c0bd8dbf5fccb13988c7610367d129f45ee69b1624f8;

  // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

  /// @param _repository repository used for sourcing upgrades
  /// @param _owner owner of proxy
  /// @dev reverts if either `_repository` or `_owner` is null
  constructor(Repo _repository, address _owner) {
    require(_owner != address(0), "bad owner");
    _setOwner(_owner);
    _setRepository(_repository);
    // this will validate that the passed in repo is a contract
    _upgradeToAndCall(_repository.currentImplementation(), "");
  }

  /// @notice upgrade the proxy implementation
  /// @dev reverts if the repository has not been initialized or if there is no following version
  function upgradeImplementation() external onlyOwner {
    _upgradeImplementation();
  }

  /// @inheritdoc IERC173
  function transferOwnership(address newOwner) external override onlyOwner {
    _setOwner(newOwner);
  }

  /// @inheritdoc IERC173
  function owner() external view override returns (address) {
    return _getOwner();
  }

  /// @notice Returns the associated {Repo}
  ///   contract used for fetching implementations to upgrade to
  function getRepository() external view returns (Repo) {
    return _getRepository();
  }

  // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

  function _upgradeImplementation() internal {
    Repo repo = _getRepository();
    address nextImpl = repo.nextImplementationOf(_implementation());
    bytes memory data = repo.upgradeDataFor(nextImpl);
    _upgradeToAndCall(nextImpl, data);
  }

  /// @dev Returns the current implementation address.
  function _implementation() internal view override returns (address impl) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(_IMPLEMENTATION_SLOT)
    }
  }

  /// @dev Upgrades the proxy to a new implementation.
  //
  /// Emits an {Upgraded} event.
  function _upgradeToAndCall(address newImplementation, bytes memory data) internal virtual {
    _setImplementationAndCall(newImplementation, data);
    emit Upgraded(newImplementation);
  }

  /// @dev Stores a new address in the EIP1967 implementation slot.
  function _setImplementationAndCall(address newImplementation, bytes memory data) internal {
    require(Address.isContract(newImplementation), "no upgrade");

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(_IMPLEMENTATION_SLOT, newImplementation)
    }

    if (data.length > 0) {
      (bool success, ) = newImplementation.delegatecall(data);
      if (!success) {
        assembly {
          // This assembly ensure the revert contains the exact string data
          let returnDataSize := returndatasize()
          returndatacopy(0, 0, returnDataSize)
          revert(0, returnDataSize)
        }
      }
    }
  }

  function _setRepository(Repo newRepository) internal {
    require(Address.isContract(address(newRepository)), "bad repo");
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      sstore(_REPOSITORY_SLOT, newRepository)
    }
  }

  function _getRepository() internal view returns (Repo repo) {
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      repo := sload(_REPOSITORY_SLOT)
    }
  }

  function _getOwner() internal view returns (address adminAddress) {
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      adminAddress := sload(_ADMIN_SLOT)
    }
  }

  function _setOwner(address newOwner) internal {
    address previousOwner = _getOwner();
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      sstore(_ADMIN_SLOT, newOwner)
    }
    emit OwnershipTransferred(previousOwner, newOwner);
  }

  // /////////////////////// MODIFIERS ////////////////////////////////////////////////////////////////////////
  modifier onlyOwner() {
    /// @dev NA: not authorized. not owner
    require(msg.sender == _getOwner(), "NA");
    _;
  }

  // /////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////////

  /// @dev Emitted when the implementation is upgraded.
  event Upgraded(address indexed implementation);
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