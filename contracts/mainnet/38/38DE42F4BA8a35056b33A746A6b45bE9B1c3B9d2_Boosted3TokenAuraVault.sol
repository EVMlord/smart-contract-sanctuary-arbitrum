// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
                        StringsUpgradeable.toHexString(uint160(account), 20),
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
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
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/// @title All shared constants for the Notional system should be declared here.
library Constants {
    uint8 internal constant CETH_DECIMAL_PLACES = 8;

    // Token precision used for all internal balances, TokenHandler library ensures that we
    // limit the dust amount caused by precision mismatches
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    uint256 internal constant INCENTIVE_ACCUMULATION_PRECISION = 1e18;

    // ETH will be initialized as the first currency
    address internal constant ETH_ADDRESS = address(0);
    uint256 internal constant ETH_CURRENCY_ID = 1;
    uint8 internal constant ETH_DECIMAL_PLACES = 18;
    int256 internal constant ETH_DECIMALS = 1e18;
    // Used to prevent overflow when converting decimal places to decimal precision values via
    // 10**decimalPlaces. This is a safe value for int256 and uint256 variables. We apply this
    // constraint when storing decimal places in governance.
    uint256 internal constant MAX_DECIMAL_PLACES = 36;

    // Address of the reserve account
    address internal constant RESERVE = address(0);

    // Most significant bit
    bytes32 internal constant MSB = 0x8000000000000000000000000000000000000000000000000000000000000000;

    // Each bit set in this mask marks where an active market should be in the bitmap
    // if the first bit refers to the reference time. Used to detect idiosyncratic
    // fcash in the nToken accounts
    bytes32 internal constant ACTIVE_MARKETS_MASK = (
        MSB >> ( 90 - 1) | // 3 month
        MSB >> (105 - 1) | // 6 month
        MSB >> (135 - 1) | // 1 year
        MSB >> (147 - 1) | // 2 year
        MSB >> (183 - 1) | // 5 year
        MSB >> (211 - 1) | // 10 year
        MSB >> (251 - 1)   // 20 year
    );

    // Basis for percentages
    int256 internal constant PERCENTAGE_DECIMALS = 100;
    // Max number of traded markets, also used as the maximum number of assets in a portfolio array
    uint256 internal constant MAX_TRADED_MARKET_INDEX = 7;
    // Max number of fCash assets in a bitmap, this is based on the gas costs of calculating free collateral
    // for a bitmap portfolio
    uint256 internal constant MAX_BITMAP_ASSETS = 20;
    uint256 internal constant FIVE_MINUTES = 300;

    // Internal date representations, note we use a 6/30/360 week/month/year convention here
    uint256 internal constant DAY = 86400;
    // We use six day weeks to ensure that all time references divide evenly
    uint256 internal constant WEEK = DAY * 6;
    uint256 internal constant MONTH = WEEK * 5;
    uint256 internal constant QUARTER = MONTH * 3;
    uint256 internal constant YEAR = QUARTER * 4;

    // These constants are used in DateTime.sol
    uint256 internal constant DAYS_IN_WEEK = 6;
    uint256 internal constant DAYS_IN_MONTH = 30;
    uint256 internal constant DAYS_IN_QUARTER = 90;

    // Offsets for each time chunk denominated in days
    uint256 internal constant MAX_DAY_OFFSET = 90;
    uint256 internal constant MAX_WEEK_OFFSET = 360;
    uint256 internal constant MAX_MONTH_OFFSET = 2160;
    uint256 internal constant MAX_QUARTER_OFFSET = 7650;

    // Offsets for each time chunk denominated in bits
    uint256 internal constant WEEK_BIT_OFFSET = 90;
    uint256 internal constant MONTH_BIT_OFFSET = 135;
    uint256 internal constant QUARTER_BIT_OFFSET = 195;

    // This is a constant that represents the time period that all rates are normalized by, 360 days
    uint256 internal constant IMPLIED_RATE_TIME = 360 * DAY;
    // Number of decimal places that rates are stored in, equals 100%
    int256 internal constant RATE_PRECISION = 1e9;
    // One basis point in RATE_PRECISION terms
    uint256 internal constant BASIS_POINT = uint256(RATE_PRECISION / 10000);
    // Used to when calculating the amount to deleverage of a market when minting nTokens
    uint256 internal constant DELEVERAGE_BUFFER = 300 * BASIS_POINT;
    // Used for scaling cash group factors
    uint256 internal constant FIVE_BASIS_POINTS = 5 * BASIS_POINT;
    // Used for residual purchase incentive and cash withholding buffer
    uint256 internal constant TEN_BASIS_POINTS = 10 * BASIS_POINT;

    // This is the ABDK64x64 representation of RATE_PRECISION
    // RATE_PRECISION_64x64 = ABDKMath64x64.fromUint(RATE_PRECISION)
    int128 internal constant RATE_PRECISION_64x64 = 0x3b9aca000000000000000000;
    int128 internal constant LOG_RATE_PRECISION_64x64 = 382276781265598821176;
    // Limit the market proportion so that borrowing cannot hit extremely high interest rates
    int256 internal constant MAX_MARKET_PROPORTION = RATE_PRECISION * 99 / 100;

    uint8 internal constant FCASH_ASSET_TYPE = 1;
    // Liquidity token asset types are 1 + marketIndex (where marketIndex is 1-indexed)
    uint8 internal constant MIN_LIQUIDITY_TOKEN_INDEX = 2;
    uint8 internal constant MAX_LIQUIDITY_TOKEN_INDEX = 8;

    // Used for converting bool to bytes1, solidity does not have a native conversion
    // method for this
    bytes1 internal constant BOOL_FALSE = 0x00;
    bytes1 internal constant BOOL_TRUE = 0x01;

    // Account context flags
    bytes1 internal constant HAS_ASSET_DEBT = 0x01;
    bytes1 internal constant HAS_CASH_DEBT = 0x02;
    bytes2 internal constant ACTIVE_IN_PORTFOLIO = 0x8000;
    bytes2 internal constant ACTIVE_IN_BALANCES = 0x4000;
    bytes2 internal constant UNMASK_FLAGS = 0x3FFF;
    uint16 internal constant MAX_CURRENCIES = uint16(UNMASK_FLAGS);

    // Equal to 100% of all deposit amounts for nToken liquidity across fCash markets.
    int256 internal constant DEPOSIT_PERCENT_BASIS = 1e8;
    uint256 internal constant SLIPPAGE_LIMIT_PRECISION = 1e8;

    // Placeholder constant to mark the variable rate prime cash maturity
    uint40 internal constant PRIME_CASH_VAULT_MATURITY = type(uint40).max;

    uint256 internal constant CHAIN_ID_MAINNET = 1;
    uint256 internal constant CHAIN_ID_ARBITRUM = 42161;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

import {Constants} from "./Constants.sol";
import {NotionalProxy} from "../../interfaces/notional/NotionalProxy.sol";
import {IWstETH} from "../../interfaces/IWstETH.sol";
import {IBalancerVault, IAsset} from "../../interfaces/balancer/IBalancerVault.sol";
import {WETH9} from "../../interfaces/WETH9.sol";
import {ISwapRouter as UniV3ISwapRouter} from "../../interfaces/uniswap/v3/ISwapRouter.sol";
import {IUniV2Router2} from "../../interfaces/uniswap/v2/IUniV2Router2.sol";
import {ICurveRouter} from "../../interfaces/curve/ICurveRouter.sol";
import {ICurveRegistry} from "../../interfaces/curve/ICurveRegistry.sol";
import {ICurveMetaRegistry} from "../../interfaces/curve/ICurveMetaRegistry.sol";
import {ICurveRouterV2} from "../../interfaces/curve/ICurveRouterV2.sol";

/// @title Hardcoded Deployment Addresses for Arbitrum
library Deployments {
    uint256 internal constant CHAIN_ID = Constants.CHAIN_ID_ARBITRUM;
    NotionalProxy internal constant NOTIONAL = NotionalProxy(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);
    IWstETH internal constant WRAPPED_STETH = IWstETH(0x5979D7b546E38E414F7E9822514be443A4800529);
    address internal constant ETH_ADDRESS = address(0);
    WETH9 internal constant WETH =
        WETH9(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IBalancerVault internal constant BALANCER_VAULT =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    UniV3ISwapRouter internal constant UNIV3_ROUTER = UniV3ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address internal constant ZERO_EX = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    IUniV2Router2 internal constant UNIV2_ROUTER = IUniV2Router2(address(0));

    address internal constant ALT_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ICurveRouterV2 public constant CURVE_ROUTER_V2 = ICurveRouterV2(0x4c2Af2Df2a7E567B5155879720619EA06C5BB15D);
    // Curve meta registry is not deployed on arbitrum
    ICurveMetaRegistry public constant CURVE_META_REGISTRY = ICurveMetaRegistry(address(0));
    address internal constant CURVE_V1_HANDLER = address(0);
    address internal constant CURVE_V2_HANDLER = address(0);
}

/// @title Hardcoded Deployment Addresses for Mainnet
/*library Deployments {
    uint256 internal constant CHAIN_ID = Constants.CHAIN_ID_MAINNET;
    NotionalProxy internal constant NOTIONAL = NotionalProxy(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);
    IWstETH internal constant WRAPPED_STETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    address internal constant ETH_ADDRESS = address(0);
    WETH9 internal constant WETH =
        WETH9(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IBalancerVault internal constant BALANCER_VAULT =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    UniV3ISwapRouter internal constant UNIV3_ROUTER = UniV3ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address internal constant ZERO_EX = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    IUniV2Router2 internal constant UNIV2_ROUTER = IUniV2Router2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address internal constant ALT_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ICurveRouterV2 public constant CURVE_ROUTER_V2 = ICurveRouterV2(0x99a58482BD75cbab83b27EC03CA68fF489b5788f);
    ICurveMetaRegistry public constant CURVE_META_REGISTRY = ICurveMetaRegistry(0xF98B45FA17DE75FB1aD0e7aFD971b0ca00e379fC);
    address internal constant CURVE_V1_HANDLER = 0x46a8a9CF4Fc8e99EC3A14558ACABC1D93A27de68;
    address internal constant CURVE_V2_HANDLER = 0xC4F389020002396143B863F6325aA6ae481D19CE;
} */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

library Errors {
    error InvalidPrice(uint256 oraclePrice, uint256 poolPrice);
    error InvalidEmergencySettlement();
    error HasNotMatured();
    error PostMaturitySettlement();
    error RedeemingTooMuch(
        int256 underlyingRedeemed,
        int256 underlyingCashRequiredToSettle
    );
    error SlippageTooHigh(uint256 slippage, uint32 limit);
    error InSettlementCoolDown(uint32 lastSettlementTimestamp, uint32 coolDownInMinutes);
    /// @notice settleVault called when there is no debt
    error SettlementNotRequired();
    error InvalidRewardToken(address token);
    error InvalidJoinAmounts(uint256 oraclePrice, uint256 maxPrimary, uint256 maxSecondary);
    error PoolShareTooHigh(uint256 totalPoolClaim, uint256 poolClaimThreshold);
    error StakeFailed();
    error UnstakeFailed();
    error InvalidTokenIndex(uint8 tokenIndex);
    error ZeroPoolClaim();
    error ZeroStrategyTokens();
    error VaultLocked();
    error VaultNotLocked();
    error InvalidDexId(uint256 dexId);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library TypeConvert {

    function toUint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require (x <= uint256(type(int256).max)); // dev: toInt overflow
        return int256(x);
    }

    function toInt80(int256 x) internal pure returns (int80) {
        require (int256(type(int80).min) <= x && x <= int256(type(int80).max)); // dev: toInt overflow
        return int80(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        require (x <= uint256(type(uint80).max));
        return uint80(x);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../interfaces/chainlink/AggregatorV2V3Interface.sol";
import "../../interfaces/notional/IPrimeCashHoldingsOracle.sol";
import "../../interfaces/notional/AssetRateAdapter.sol";

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
///  - aToken: Aave interest bearing tokens
enum TokenType {
    UnderlyingToken,
    cToken,
    cETH,
    Ether,
    NonMintable,
    aToken
}

/// @notice Specifies the different trade action types in the system. Each trade action type is
/// encoded in a tightly packed bytes32 object. Trade action type is the first big endian byte of the
/// 32 byte trade action object. The schemas for each trade action type are defined below.
enum TradeActionType {
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
    Lend,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
    Borrow,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 primeCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    AddLiquidity,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    RemoveLiquidity,
    // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
    PurchaseNTokenResidual,
    // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
    SettleCashDebt
}

/// @notice Specifies different deposit actions that can occur during BalanceAction or BalanceActionWithTrades
enum DepositActionType {
    // No deposit action
    None,
    // Deposit asset cash, depositActionAmount is specified in asset cash external precision
    DepositAsset,
    // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
    // external precision
    DepositUnderlying,
    // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
    // nTokens into the account
    DepositAssetAndMintNToken,
    // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
    DepositUnderlyingAndMintNToken,
    // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
    // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
    RedeemNToken,
    // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
    // Notional internal 8 decimal precision.
    ConvertCashToNToken
}

/// @notice Used internally for PortfolioHandler state
enum AssetStorageState {
    NoChange,
    Update,
    Delete,
    RevertIfStored
}

/****** Calldata objects ******/

/// @notice Defines a batch lending action
struct BatchLend {
    uint16 currencyId;
    // True if the contract should try to transfer underlying tokens instead of asset tokens
    bool depositUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/// @notice Defines a balance action for batchAction
struct BalanceAction {
    // Deposit action to take (if any)
    DepositActionType actionType;
    uint16 currencyId;
    // Deposit action amount must correspond to the depositActionType, see documentation above.
    uint256 depositActionAmount;
    // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
    uint256 withdrawAmountInternalPrecision;
    // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
    // residual left from trading.
    bool withdrawEntireCashBalance;
    // If set to true, will redeem asset cash to the underlying token on withdraw.
    bool redeemToUnderlying;
}

/// @notice Defines a balance action with a set of trades to do as well
struct BalanceActionWithTrades {
    DepositActionType actionType;
    uint16 currencyId;
    uint256 depositActionAmount;
    uint256 withdrawAmountInternalPrecision;
    bool withdrawEntireCashBalance;
    bool redeemToUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/****** In memory objects ******/
/// @notice Internal object that represents settled cash balances
struct SettleAmount {
    uint16 currencyId;
    int256 positiveSettledCash;
    int256 negativeSettledCash;
    PrimeRate presentPrimeRate;
}

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 deprecated_maxCollateralBalance;
}

/// @notice Internal object that represents an nToken portfolio
struct nTokenPortfolio {
    CashGroupParameters cashGroup;
    PortfolioState portfolioState;
    int256 totalSupply;
    int256 cashBalance;
    uint256 lastInitializedTime;
    bytes6 parameters;
    address tokenAddress;
}

/// @notice Internal object used during liquidation
struct LiquidationFactors {
    address account;
    // Aggregate free collateral of the account denominated in ETH underlying, 8 decimal precision
    int256 netETHValue;
    // Amount of net local currency asset cash before haircuts and buffers available
    int256 localPrimeAvailable;
    // Amount of net collateral currency asset cash before haircuts and buffers available
    int256 collateralAssetAvailable;
    // Haircut value of nToken holdings denominated in asset cash, will be local or collateral nTokens based
    // on liquidation type
    int256 nTokenHaircutPrimeValue;
    // nToken parameters for calculating liquidation amount
    bytes6 nTokenParameters;
    // ETH exchange rate from local currency to ETH
    ETHRate localETHRate;
    // ETH exchange rate from collateral currency to ETH
    ETHRate collateralETHRate;
    // Asset rate for the local currency, used in cross currency calculations to calculate local asset cash required
    PrimeRate localPrimeRate;
    // Used during currency liquidations if the account has liquidity tokens
    CashGroupParameters collateralCashGroup;
    // Used during currency liquidations if it is only a calculation, defaults to false
    bool isCalculation;
}

/// @notice Internal asset array portfolio state
struct PortfolioState {
    // Array of currently stored assets
    PortfolioAsset[] storedAssets;
    // Array of new assets to add
    PortfolioAsset[] newAssets;
    uint256 lastNewAssetIndex;
    // Holds the length of stored assets after accounting for deleted assets
    uint256 storedAssetLength;
}

/// @notice In memory ETH exchange rate used during free collateral calculation.
struct ETHRate {
    // The decimals (i.e. 10^rateDecimalPlaces) of the exchange rate, defined by the rate oracle
    int256 rateDecimals;
    // The exchange rate from base to ETH (if rate invert is required it is already done)
    int256 rate;
    // Amount of buffer as a multiple with a basis of 100 applied to negative balances.
    int256 buffer;
    // Amount of haircut as a multiple with a basis of 100 applied to positive balances
    int256 haircut;
    // Liquidation discount as a multiple with a basis of 100 applied to the exchange rate
    // as an incentive given to liquidators.
    int256 liquidationDiscount;
}

/// @notice Internal object used to handle balance state during a transaction
struct BalanceState {
    uint16 currencyId;
    // Cash balance stored in balance state at the beginning of the transaction
    int256 storedCashBalance;
    // nToken balance stored at the beginning of the transaction
    int256 storedNTokenBalance;
    // The net cash change as a result of asset settlement or trading
    int256 netCashChange;
    // Amount of prime cash to redeem and withdraw from the system
    int256 primeCashWithdraw;
    // Net token transfers into or out of the account
    int256 netNTokenTransfer;
    // Net token supply change from minting or redeeming
    int256 netNTokenSupplyChange;
    // The last time incentives were claimed for this currency
    uint256 lastClaimTime;
    // Accumulator for incentives that the account no longer has a claim over
    uint256 accountIncentiveDebt;
    // Prime rate for converting prime cash balances
    PrimeRate primeRate;
}

/// @dev Asset rate used to convert between underlying cash and asset cash
struct Deprecated_AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals;
}

/// @dev Cash group when loaded into memory
struct CashGroupParameters {
    uint16 currencyId;
    uint256 maxMarketIndex;
    PrimeRate primeRate;
    bytes32 data;
}

/// @dev A portfolio asset when loaded in memory
struct PortfolioAsset {
    // Asset currency id
    uint16 currencyId;
    uint256 maturity;
    // Asset type, fCash or liquidity token.
    uint256 assetType;
    // fCash amount or liquidity token amount
    int256 notional;
    // Used for managing portfolio asset state
    uint256 storageSlot;
    // The state of the asset for when it is written to storage
    AssetStorageState storageState;
}

/// @dev Market object as represented in memory
struct MarketParameters {
    bytes32 storageSlot;
    uint256 maturity;
    // Total amount of fCash available for purchase in the market.
    int256 totalfCash;
    // Total amount of cash available for purchase in the market.
    int256 totalPrimeCash;
    // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
    int256 totalLiquidity;
    // This is the previous annualized interest rate in RATE_PRECISION that the market traded
    // at. This is used to calculate the rate anchor to smooth interest rates over time.
    uint256 lastImpliedRate;
    // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
    // remaining resistent to flash loan attacks.
    uint256 oracleRate;
    // This is the timestamp of the previous trade
    uint256 previousTradeTime;
}

/****** Storage objects ******/

/// @dev Token object in storage:
///  20 bytes for token address
///  1 byte for hasTransferFee
///  1 byte for tokenType
///  1 byte for tokenDecimals
///  9 bytes for maxCollateralBalance (may not always be set)
struct TokenStorage {
    // Address of the token
    address tokenAddress;
    // Transfer fees will change token deposit behavior
    bool hasTransferFee;
    TokenType tokenType;
    uint8 decimalPlaces;
    uint72 deprecated_maxCollateralBalance;
}

/// @dev Exchange rate object as it is represented in storage, total storage is 25 bytes.
struct ETHRateStorage {
    // Address of the rate oracle
    AggregatorV2V3Interface rateOracle;
    // The decimal places of precision that the rate oracle uses
    uint8 rateDecimalPlaces;
    // True of the exchange rate must be inverted
    bool mustInvert;
    // NOTE: both of these governance values are set with BUFFER_DECIMALS precision
    // Amount of buffer to apply to the exchange rate for negative balances.
    uint8 buffer;
    // Amount of haircut to apply to the exchange rate for positive balances
    uint8 haircut;
    // Liquidation discount in percentage point terms, 106 means a 6% discount
    uint8 liquidationDiscount;
}

/// @dev Asset rate oracle object as it is represented in storage, total storage is 21 bytes.
struct AssetRateStorage {
    // Address of the rate oracle
    AssetRateAdapter rateOracle;
    // The decimal places of the underlying asset
    uint8 underlyingDecimalPlaces;
}

/// @dev Governance parameters for a cash group, total storage is 9 bytes + 7 bytes for liquidity token haircuts
/// and 7 bytes for rate scalars, total of 23 bytes. Note that this is stored packed in the storage slot so there
/// are no indexes stored for liquidityTokenHaircuts or rateScalars, maxMarketIndex is used instead to determine the
/// length.
struct CashGroupSettings {
    // Index of the AMMs on chain that will be made available. Idiosyncratic fCash
    // that is dated less than the longest AMM will be tradable.
    uint8 maxMarketIndex;
    // Time window in 5 minute increments that the rate oracle will be averaged over
    uint8 rateOracleTimeWindow5Min;
    // Total fees per trade, specified in BPS
    uint8 totalFeeBPS;
    // Share of the fees given to the protocol, denominated in percentage
    uint8 reserveFeeShare;
    // Debt buffer specified in 5 BPS increments
    uint8 debtBuffer5BPS;
    // fCash haircut specified in 5 BPS increments
    uint8 fCashHaircut5BPS;
    // If an account has a negative cash balance, it can be settled by incurring debt at the 3 month market. This
    // is the basis points for the penalty rate that will be added the current 3 month oracle rate.
    uint8 settlementPenaltyRate5BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationfCashHaircut5BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationDebtBuffer5BPS;
    // Liquidity token haircut applied to cash claims, specified as a percentage between 0 and 100
    uint8[] liquidityTokenHaircuts;
    // Rate scalar used to determine the slippage of the market
    uint8[] rateScalars;
}

/// @dev Holds account level context information used to determine settlement and
/// free collateral actions. Total storage is 28 bytes
struct AccountContext {
    // Used to check when settlement must be triggered on an account
    uint40 nextSettleTime;
    // For lenders that never incur debt, we use this flag to skip the free collateral check.
    bytes1 hasDebt;
    // Length of the account's asset array
    uint8 assetArrayLength;
    // If this account has bitmaps set, this is the corresponding currency id
    uint16 bitmapCurrencyId;
    // 9 total active currencies possible (2 bytes each)
    bytes18 activeCurrencies;
    // If this is set to true, the account can borrow variable prime cash and incur
    // negative cash balances inside BatchAction. This does not impact the settlement
    // of negative fCash to prime cash which will happen regardless of this setting. This
    // exists here mainly as a safety setting to ensure that accounts do not accidentally
    // incur negative cash balances.
    bool allowPrimeBorrow;
}

/// @dev Holds nToken context information mapped via the nToken address, total storage is
/// 16 bytes
struct nTokenContext {
    // Currency id that the nToken represents
    uint16 currencyId;
    // Annual incentive emission rate denominated in WHOLE TOKENS (multiply by
    // INTERNAL_TOKEN_PRECISION to get the actual rate)
    uint32 incentiveAnnualEmissionRate;
    // The last block time at utc0 that the nToken was initialized at, zero if it
    // has never been initialized
    uint32 lastInitializedTime;
    // Length of the asset array, refers to the number of liquidity tokens an nToken
    // currently holds
    uint8 assetArrayLength;
    // Each byte is a specific nToken parameter
    bytes5 nTokenParameters;
    // Reserved bytes for future usage
    bytes15 _unused;
    // Set to true if a secondary rewarder is set
    bool hasSecondaryRewarder;
}

/// @dev Holds account balance information, total storage 32 bytes
struct BalanceStorage {
    // Number of nTokens held by the account
    uint80 nTokenBalance;
    // Last time the account claimed their nTokens
    uint32 lastClaimTime;
    // Incentives that the account no longer has a claim over
    uint56 accountIncentiveDebt;
    // Cash balance of the account
    int88 cashBalance;
}

/// @dev Holds information about a settlement rate, total storage 25 bytes
struct SettlementRateStorage {
    uint40 blockTime;
    uint128 settlementRate;
    uint8 underlyingDecimalPlaces;
}

/// @dev Holds information about a market, total storage is 42 bytes so this spans
/// two storage words
struct MarketStorage {
    // Total fCash in the market
    uint80 totalfCash;
    // Total asset cash in the market
    uint80 totalPrimeCash;
    // Last annualized interest rate the market traded at
    uint32 lastImpliedRate;
    // Last recorded oracle rate for the market
    uint32 oracleRate;
    // Last time a trade was made
    uint32 previousTradeTime;
    // This is stored in slot + 1
    uint80 totalLiquidity;
}

struct InterestRateParameters {
    // First kink for the utilization rate in RATE_PRECISION
    uint256 kinkUtilization1;
    // Second kink for the utilization rate in RATE_PRECISION
    uint256 kinkUtilization2;
    // First kink interest rate in RATE_PRECISION
    uint256 kinkRate1;
    // Second kink interest rate in RATE_PRECISION
    uint256 kinkRate2;
    // Max interest rate in RATE_PRECISION
    uint256 maxRate;
    // Minimum fee charged in RATE_PRECISION
    uint256 minFeeRate;
    // Maximum fee charged in RATE_PRECISION
    uint256 maxFeeRate;
    // Percentage of the interest rate that will be applied as a fee
    uint256 feeRatePercent;
}

// Specific interest rate curve settings for each market
struct InterestRateCurveSettings {
    // First kink for the utilization rate, specified as a percentage
    // between 1-100
    uint8 kinkUtilization1;
    // Second kink for the utilization rate, specified as a percentage
    // between 1-100
    uint8 kinkUtilization2;
    // Interest rate at the first kink, set as 1/256 units from the kink
    // rate max
    uint8 kinkRate1;
    // Interest rate at the second kink, set as 1/256 units from the kink
    // rate max
    uint8 kinkRate2;
    // Max interest rate, set in 25 bps increments
    uint8 maxRate25BPS;
    // Minimum fee charged in basis points
    uint8 minFeeRateBPS;
    // Maximum fee charged in basis points
    uint8 maxFeeRateBPS;
    // Percentage of the interest rate that will be applied as a fee
    uint8 feeRatePercent;
}

struct ifCashStorage {
    // Notional amount of fCash at the slot, limited to int128 to allow for
    // future expansion
    int128 notional;
}

/// @dev A single portfolio asset in storage, total storage of 19 bytes
struct PortfolioAssetStorage {
    // Currency Id for the asset
    uint16 currencyId;
    // Maturity of the asset
    uint40 maturity;
    // Asset type (fCash or Liquidity Token marker)
    uint8 assetType;
    // Notional
    int88 notional;
}

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes. This is the deprecated version
struct nTokenTotalSupplyStorage_deprecated {
    // Total supply of the nToken
    uint96 totalSupply;
    // Integral of the total supply used for calculating the average total supply
    uint128 integralTotalSupply;
    // Last timestamp the supply value changed, used for calculating the integralTotalSupply
    uint32 lastSupplyChangeTime;
}

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes.
struct nTokenTotalSupplyStorage {
    // Total supply of the nToken
    uint96 totalSupply;
    // How many NOTE incentives should be issued per nToken in 1e18 precision
    uint128 accumulatedNOTEPerNToken;
    // Last timestamp when the accumulation happened
    uint32 lastAccumulatedTime;
}

/// @dev Used in view methods to return account balances in a developer friendly manner
struct AccountBalance {
    uint16 currencyId;
    int256 cashBalance;
    int256 nTokenBalance;
    uint256 lastClaimTime;
    uint256 accountIncentiveDebt;
}

struct VaultConfigStorage {
    // Vault Flags (documented in VaultConfiguration.sol)
    uint16 flags;
    // Primary currency the vault borrows in
    uint16 borrowCurrencyId;
    // Specified in whole tokens in 1e8 precision, allows a 4.2 billion min borrow size
    uint32 minAccountBorrowSize;
    // Minimum collateral ratio for a vault specified in basis points, valid values are greater than 10_000
    // where the largest minimum collateral ratio is 65_536 which is much higher than anything reasonable.
    uint16 minCollateralRatioBPS;
    // Allows up to a 12.75% annualized fee
    uint8 feeRate5BPS;
    // A percentage that represents the share of the cash raised that will go to the liquidator
    uint8 liquidationRate;
    // A percentage of the fee given to the protocol
    uint8 reserveFeeShare;
    // Maximum market index where a vault can borrow from
    uint8 maxBorrowMarketIndex;
    // Maximum collateral ratio that a liquidator can push a an account to during deleveraging
    uint16 maxDeleverageCollateralRatioBPS;
    // An optional list of secondary borrow currencies
    uint16[2] secondaryBorrowCurrencies;
    // Required collateral ratio for accounts to stay inside a vault, prevents accounts
    // from "free riding" on vaults. Enforced on entry and exit, not on deleverage.
    uint16 maxRequiredAccountCollateralRatioBPS;
    // Specified in whole tokens in 1e8 precision, allows a 4.2 billion min borrow size
    uint32[2] minAccountSecondaryBorrow;
    // Specified as a percent discount off the exchange rate of the excess cash that will be paid to
    // the liquidator during liquidateExcessVaultCash
    uint8 excessCashLiquidationBonus;
    // 8 bytes left
}

struct VaultBorrowCapacityStorage {
    // Total fCash across all maturities that caps the borrow capacity
    uint80 maxBorrowCapacity;
    // Total fCash debt across all maturities
    uint80 totalfCashDebt;
}

struct VaultAccountSecondaryDebtShareStorage {
    // Maturity for the account's secondary borrows. This is stored separately from
    // the vault account maturity to ensure that we have access to the proper state
    // during a roll borrow position. It should never be allowed to deviate from the
    // vaultAccount.maturity value (unless it is cleared to zero).
    uint40 maturity;
    // Account debt for the first secondary currency in either fCash or pCash denomination
    uint80 accountDebtOne;
    // Account debt for the second secondary currency in either fCash or pCash denomination
    uint80 accountDebtTwo;
}

struct VaultConfig {
    address vault;
    uint16 flags;
    uint16 borrowCurrencyId;
    int256 minAccountBorrowSize;
    int256 feeRate;
    int256 minCollateralRatio;
    int256 liquidationRate;
    int256 reserveFeeShare;
    uint256 maxBorrowMarketIndex;
    int256 maxDeleverageCollateralRatio;
    uint16[2] secondaryBorrowCurrencies;
    PrimeRate primeRate;
    int256 maxRequiredAccountCollateralRatio;
    int256[2] minAccountSecondaryBorrow;
}

/// @notice Represents a Vault's current borrow and collateral state
struct VaultStateStorage {
    // This represents the total amount of borrowing in the vault for the current
    // vault term. If the vault state is the prime cash maturity, this is stored in
    // prime cash debt denomination, if fCash then it is stored in internal underlying.
    uint80 totalDebt;
    // The total amount of prime cash in the pool held as a result of emergency settlement
    uint80 deprecated_totalPrimeCash;
    // Total vault shares in this maturity
    uint80 totalVaultShares;
    // Set to true if a vault's debt position has been migrated to the prime cash vault
    bool isSettled;
    // NOTE: 8 bits left
    // ----- This breaks into a new storage slot -------    
    // The total amount of strategy tokens held in the pool
    uint80 deprecated_totalStrategyTokens;
    // Valuation of a strategy token at settlement
    int80 deprecated_settlementStrategyTokenValue;
    // NOTE: 96 bits left
}

/// @notice Represents the remaining assets in a vault post settlement
struct Deprecated_VaultSettledAssetsStorage {
    // Remaining strategy tokens that have not been withdrawn
    uint80 remainingStrategyTokens;
    // Remaining asset cash that has not been withdrawn
    int80 remainingPrimeCash;
}

struct VaultState {
    uint256 maturity;
    // Total debt is always denominated in underlying on the stack
    int256 totalDebtUnderlying;
    uint256 totalVaultShares;
    bool isSettled;
}

/// @notice Represents an account's position within an individual vault
struct VaultAccountStorage {
    // Total amount of debt for the account in the primary borrowed currency.
    // If the account is borrowing prime cash, this is stored in prime cash debt
    // denomination, if fCash then it is stored in internal underlying.
    uint80 accountDebt;
    // Vault shares that the account holds
    uint80 vaultShares;
    // Maturity when the vault shares and fCash will mature
    uint40 maturity;
    // Last time when a vault was entered or exited, used to ensure that vault accounts do not
    // flash enter/exit. While there is no specified attack vector here, we can use it to prevent
    // an entire class of attacks from happening without reducing UX.
    // NOTE: in the original version this value was set to the block.number, however, in this
    // version it is being changed to time based. On ETH mainnet block heights are much smaller
    // than block times, accounts that migrate from lastEntryBlockHeight => lastUpdateBlockTime
    // will not see any issues with entering / exiting the protocol.
    uint32 lastUpdateBlockTime;
    // ----------------  Second Storage Slot ----------------------
    // Cash balances held by the vault account as a result of lending at zero interest or due
    // to deleveraging (liquidation). In the previous version of leveraged vaults, accounts would
    // simply lend at zero interest which was not a problem. However, with vaults being able to
    // discount fCash to present value, lending at zero percent interest may have an adverse effect
    // on the account's collateral position (i.e. lending at zero puts them further into danger).
    // Holding cash against debt will eliminate that risk, making vault liquidation more similar to
    // regular Notional liquidation.
    uint80 primaryCash;
    uint80 secondaryCashOne;
    uint80 secondaryCashTwo;
}

struct VaultAccount {
    // On the stack, account debts are always in underlying
    int256 accountDebtUnderlying;
    uint256 maturity;
    uint256 vaultShares;
    address account;
    // This cash balance is used just within a transaction to track deposits
    // and withdraws for an account. Must be zeroed by the time we store the account
    int256 tempCashBalance;
    uint256 lastUpdateBlockTime;
}

// Used to hold vault account liquidation factors in memory
struct VaultAccountHealthFactors {
    // Account's calculated collateral ratio
    int256 collateralRatio;
    // Total outstanding debt across all borrowed currencies in primary
    int256 totalDebtOutstandingInPrimary;
    // Total value of vault shares in underlying denomination
    int256 vaultShareValueUnderlying;
    // Debt outstanding in local currency denomination after present value and
    // account cash held netting applied
    int256[3] debtOutstanding;
}

// PrimeCashInterestRateParameters take up 16 bytes, this takes up 32 bytes so we
// can expand another 16 bytes to increase the storage slots a bit....
struct PrimeCashFactorsStorage {
    // Storage slot 1 [Prime Supply Factors, 248 bytes]
    uint40 lastAccrueTime;
    uint88 totalPrimeSupply;
    uint88 lastTotalUnderlyingValue;
    // Overflows at 429% interest using RATE_PRECISION
    uint32 oracleSupplyRate;
    bool allowDebt;

    // Storage slot 2 [Prime Debt Factors, 256 bytes]
    uint88 totalPrimeDebt;
    // Each one of these values below is stored as a FloatingPoint32 value which
    // gives us approx 7 digits of precision for each value. Because these are used
    // to maintain supply and borrow caps, they are not required to be exact.
    uint32 maxUnderlyingSupply;
    uint128 _reserved;
    // Reserving the next 128 bytes for future use in case we decide to implement debt
    // caps on a currency. In that case, we will need to track the total fcash overall
    // and subtract the total debt held in vaults.
    // uint32 maxUnderlyingDebt;
    // uint32 totalfCashDebtOverall;
    // uint32 totalfCashDebtInVaults;
    // uint32 totalPrimeDebtInVaults;
    // 8 bytes left
    
    // Storage slot 3 [Prime Scalars, 240 bytes]
    // Scalars are stored in 18 decimal precision (i.e. double rate precision) and uint80
    // maxes out at approx 1,210,000e18
    // ln(1,210,000) = rate * years = 14
    // Approx 46 years at 30% interest
    // Approx 233 years at 6% interest
    uint80 underlyingScalar;
    uint80 supplyScalar;
    uint80 debtScalar;
    // The time window in 5 min increments that the rate oracle will be averaged over
    uint8 rateOracleTimeWindow5Min;
    // 8 bytes left
}

struct PrimeCashFactors {
    uint256 lastAccrueTime;
    uint256 totalPrimeSupply;
    uint256 totalPrimeDebt;
    uint256 oracleSupplyRate;
    uint256 lastTotalUnderlyingValue;
    uint256 underlyingScalar;
    uint256 supplyScalar;
    uint256 debtScalar;
    uint256 rateOracleTimeWindow;
}

struct PrimeRate {
    int256 supplyFactor;
    int256 debtFactor;
    uint256 oracleSupplyRate;
}

struct PrimeSettlementRateStorage {
    uint80 supplyScalar;
    uint80 debtScalar;
    uint80 underlyingScalar;
    bool isSet;
}

struct PrimeCashHoldingsOracle {
   IPrimeCashHoldingsOracle oracle; 
}

// Per currency rebalancing context
struct RebalancingContextStorage {
    // Holds the previous underlying scalar to calculate the oracle money market rate
    uint80 previousUnderlyingScalarAtRebalance;
    // Rebalancing has a cool down period that sets the time averaging of the oracle money market rate
    uint40 rebalancingCooldownInSeconds;
    uint40 lastRebalanceTimestampInSeconds;
    // The annualized underlying money market interest rate calculated based on the underlying scalar
    uint32 oracleMoneyMarketRate;
    // 64 bytes left
}

struct TotalfCashDebtStorage {
    uint80 totalfCashDebt;
    // These two variables are used to track fCash lend at zero
    // edge conditions for leveraged vaults.
    uint80 fCashDebtHeldInSettlementReserve;
    uint80 primeCashHeldInSettlementReserve;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract nProxy is ERC1967Proxy {
    constructor(
        address _logic,
        bytes memory _data
    ) ERC1967Proxy(_logic, _data) {}

    receive() external payable override {
        // Allow ETH transfers to succeed
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ITradingModule, Trade} from "../../interfaces/trading/ITradingModule.sol";
import {nProxy} from "../proxy/nProxy.sol";

/// @notice TradeHandler is an internal library to be compiled into StrategyVaults to interact
/// with the TradeModule and execute trades
library TradeHandler {

    /// @notice Can be used to delegate call to the TradingModule's implementation in order to execute
    /// a trade.
    function _executeTradeWithDynamicSlippage(
        Trade memory trade,
        uint16 dexId,
        ITradingModule tradingModule,
        uint32 dynamicSlippageLimit
    ) internal returns (uint256 amountSold, uint256 amountBought) {
        (bool success, bytes memory result) = nProxy(payable(address(tradingModule))).getImplementation()
            .delegatecall(abi.encodeWithSelector(
                ITradingModule.executeTradeWithDynamicSlippage.selector,
                dexId, trade, dynamicSlippageLimit
            )
        );
        require(success);
        (amountSold, amountBought) = abi.decode(result, (uint256, uint256));
    }

    /// @notice Can be used to delegate call to the TradingModule's implementation in order to execute
    /// a trade.
    function _executeTrade(
        Trade memory trade,
        uint16 dexId,
        ITradingModule tradingModule
    ) internal returns (uint256 amountSold, uint256 amountBought) {
        (bool success, bytes memory result) = nProxy(payable(address(tradingModule))).getImplementation()
            .delegatecall(abi.encodeWithSelector(ITradingModule.executeTrade.selector, dexId, trade));
        require(success);
        (amountSold, amountBought) = abi.decode(result, (uint256, uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {IERC20} from "../../interfaces/IERC20.sol";
import {IEIP20NonStandard} from "../../interfaces/IEIP20NonStandard.sol";
import {Deployments} from "../global/Deployments.sol";

library TokenUtils {
    error ERC20Error();

    function tokenBalance(address token) internal view returns (uint256) {
        return
            token == Deployments.ETH_ADDRESS
                ? address(this).balance
                : IERC20(token).balanceOf(address(this));
    }

    function checkApprove(IERC20 token, address spender, uint256 amount) internal {
        if (address(token) == address(0)) return;

        IEIP20NonStandard(address(token)).approve(spender, 0);
        _checkReturnCode();            
        if (amount > 0) {
            IEIP20NonStandard(address(token)).approve(spender, amount);
            _checkReturnCode();            
        }
    }

    function checkRevoke(IERC20 token, address spender) internal {
        if (address(token) == address(0)) return;

        IEIP20NonStandard(address(token)).approve(spender, 0);
        _checkReturnCode();
    }

    function checkTransfer(IERC20 token, address receiver, uint256 amount) internal {
        IEIP20NonStandard(address(token)).transfer(receiver, amount);
        _checkReturnCode();
    }

    // Supports checking return codes on non-standard ERC20 contracts
    function _checkReturnCode() private pure {
        bool success;
        uint256[1] memory result;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := 1 // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(result, 0, 32)
                    success := mload(result) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }

        if (!success) revert ERC20Error();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    StrategyContext, 
    StrategyVaultSettings, 
    TradeParams,
    TwoTokenPoolContext,
    ThreeTokenPoolContext
} from "../common/VaultTypes.sol";
import {IStrategyVault} from "../../../interfaces/notional/IStrategyVault.sol";
import {VaultConfig} from "../../../interfaces/notional/IVaultController.sol";
import {IAuraBooster} from "../../../interfaces/aura/IAuraBooster.sol";
import {IAuraRewardPool} from "../../../interfaces/aura/IAuraRewardPool.sol";
import {NotionalProxy} from "../../../interfaces/notional/NotionalProxy.sol";
import {ILiquidityGauge} from "../../../interfaces/balancer/ILiquidityGauge.sol";
import {IBalancerVault} from "../../../interfaces/balancer/IBalancerVault.sol";
import {IBalancerMinter} from "../../../interfaces/balancer/IBalancerMinter.sol";
import {ITradingModule, Trade, TradeType} from "../../../interfaces/trading/ITradingModule.sol";
import {IAsset} from "../../../interfaces/balancer/IBalancerVault.sol";
import {IERC20} from "../../../interfaces/IERC20.sol";

struct DeploymentParams {
    uint16 primaryBorrowCurrencyId;
    bytes32 balancerPoolId;
    ILiquidityGauge liquidityGauge;
    ITradingModule tradingModule;
}

struct AuraVaultDeploymentParams {
    IAuraRewardPool rewardPool;
    DeploymentParams baseParams;
}

struct InitParams {
    string name;
    uint16 borrowCurrencyId;
    StrategyVaultSettings settings;
}

/// @notice Parameters for joining/exiting Balancer pools
struct PoolParams {
    IAsset[] assets;
    uint256[] amounts;
    uint256 msgValue;
    bytes customData;
}

struct StableOracleContext {
    /// @notice Amplification parameter
    uint256 ampParam;
}

struct UnderlyingPoolContext {
    uint256 mainScaleFactor;
    uint256 mainBalance;
    uint256 wrappedScaleFactor;
    uint256 wrappedBalance;
    uint256 virtualSupply;
    uint256 fee;
    uint256 lowerTarget;
    uint256 upperTarget;
}

struct BoostedOracleContext {
    /// @notice Amplification parameter
    uint256 ampParam;
    /// @notice BPT balance in the pool
    uint256 bptBalance;
    /// @notice Boosted pool swap fee
    uint256 swapFeePercentage;
    /// @notice Virtual supply
    uint256 virtualSupply;
    /// @notice Underlying linear pool for the primary token
    UnderlyingPoolContext[] underlyingPools;
}

struct AuraStakingContext {
    ILiquidityGauge liquidityGauge;
    address booster;
    IAuraRewardPool rewardPool;
    uint256 poolId;
    IERC20[] rewardTokens;
}

struct Balancer2TokenPoolContext {
    TwoTokenPoolContext basePool;
    uint256 primaryScaleFactor;
    uint256 secondaryScaleFactor;
    bytes32 poolId;
}

struct Balancer3TokenPoolContext {
    ThreeTokenPoolContext basePool;
    uint256 primaryScaleFactor;
    uint256 secondaryScaleFactor;
    uint256 tertiaryScaleFactor;
    bytes32 poolId;
}

struct MetaStable2TokenAuraStrategyContext {
    Balancer2TokenPoolContext poolContext;
    StableOracleContext oracleContext;
    AuraStakingContext stakingContext;
    StrategyContext baseStrategy;
}

struct Boosted3TokenAuraStrategyContext {
    Balancer3TokenPoolContext poolContext;
    BoostedOracleContext oracleContext;
    AuraStakingContext stakingContext;
    StrategyContext baseStrategy;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    Boosted3TokenAuraStrategyContext, 
    Balancer3TokenPoolContext,
    StrategyContext,
    AuraStakingContext,
    BoostedOracleContext
} from "../BalancerVaultTypes.sol";
import {
    StrategyContext,
    StrategyVaultSettings,
    StrategyVaultState,
    ThreeTokenPoolContext,
    DepositParams,
    RedeemParams,
    ReinvestRewardParams
} from "../../common/VaultTypes.sol";
import {Constants} from "../../../global/Constants.sol";
import {TypeConvert} from "../../../global/TypeConvert.sol";
import {VaultConstants} from "../../common/VaultConstants.sol";
import {BalancerConstants} from "../internal/BalancerConstants.sol";
import {VaultEvents} from "../../common/VaultEvents.sol";
import {SettlementUtils} from "../../common/internal/settlement/SettlementUtils.sol";
import {StrategyUtils} from "../../common/internal/strategy/StrategyUtils.sol";
import {Balancer3TokenBoostedPoolUtils} from "../internal/pool/Balancer3TokenBoostedPoolUtils.sol";
import {Boosted3TokenAuraRewardUtils} from "../internal/reward/Boosted3TokenAuraRewardUtils.sol";
import {VaultStorage} from "../../common/VaultStorage.sol";
import {StableMath} from "../internal/math/StableMath.sol";

library Boosted3TokenAuraHelper {
    using Boosted3TokenAuraRewardUtils for Balancer3TokenPoolContext;
    using Boosted3TokenAuraRewardUtils for ThreeTokenPoolContext;
    using Balancer3TokenBoostedPoolUtils for Balancer3TokenPoolContext;
    using Balancer3TokenBoostedPoolUtils for ThreeTokenPoolContext;
    using StrategyUtils for StrategyContext;
    using SettlementUtils for StrategyContext;
    using VaultStorage for StrategyVaultSettings;
    using VaultStorage for StrategyVaultState;
    using TypeConvert for uint256;

    function deposit(
        Boosted3TokenAuraStrategyContext memory context,
        uint256 deposit,
        bytes calldata data
    ) external returns (uint256 vaultSharesMinted) {
        // Entering the vault is not allowed within the settlement window
        DepositParams memory params = abi.decode(data, (DepositParams));

        vaultSharesMinted = context.poolContext._deposit({
            strategyContext: context.baseStrategy,
            stakingContext: context.stakingContext,
            oracleContext: context.oracleContext, 
            deposit: deposit,
            minBPT: params.minPoolClaim
        });
    }

    function redeem(
        Boosted3TokenAuraStrategyContext memory context,
        uint256 vaultShares,
        bytes calldata data
    ) external returns (uint256 finalPrimaryBalance) {
        RedeemParams memory params = abi.decode(data, (RedeemParams));

        finalPrimaryBalance = context.poolContext._redeem({
            strategyContext: context.baseStrategy,
            stakingContext: context.stakingContext,
            strategyTokens: vaultShares,
            minPrimary: params.minPrimary
        });
    }

    function settleVaultEmergency(
        Boosted3TokenAuraStrategyContext memory context, 
        uint256 maturity, 
        bytes calldata data
    ) external {
        RedeemParams memory params = SettlementUtils._decodeParamsAndValidate(
            context.baseStrategy.vaultSettings.emergencySettlementSlippageLimitPercent,
            data
        );

        uint256 bptToSettle = context.baseStrategy._getEmergencySettlementParams({
            maturity: maturity, 
            totalPoolSupply: context.oracleContext.virtualSupply
        });
        
        // Calculate minPrimary using Chainlink oracle data
        uint256 minPrimary = context.poolContext._getTimeWeightedPrimaryBalance(
            context.oracleContext, context.baseStrategy, bptToSettle
        );

        minPrimary = minPrimary * context.baseStrategy.vaultSettings.poolSlippageLimitPercent / 
            uint256(VaultConstants.VAULT_PERCENT_BASIS);

        context.poolContext._unstakeAndExitPool({
            stakingContext: context.stakingContext,
            bptClaim: bptToSettle,
            minPrimary: minPrimary
        });

        context.baseStrategy.vaultState.totalPoolClaim -= bptToSettle;
        context.baseStrategy.vaultState.setStrategyVaultState(); 

        emit VaultEvents.EmergencyVaultSettlement(maturity, bptToSettle, 0);
    }

    function reinvestReward(
        Boosted3TokenAuraStrategyContext calldata context,
        ReinvestRewardParams calldata params
    ) external returns (
        address rewardToken,
        uint256 primaryAmount,
        uint256 secondaryAmount,
        uint256 poolClaimAmount
    ) {
        StrategyContext memory strategyContext = context.baseStrategy;
        BoostedOracleContext calldata oracleContext = context.oracleContext;
        AuraStakingContext calldata stakingContext = context.stakingContext;
        Balancer3TokenPoolContext calldata poolContext = context.poolContext;

        (rewardToken, primaryAmount) = context.poolContext.basePool._executeRewardTrades({
            strategyContext: strategyContext,
            rewardTokens: stakingContext.rewardTokens,
            data: params.tradeData
        });

        /// @notice This function is used to validate the spot price against
        /// the oracle price. The return values are not used.
        poolContext._getValidatedPoolData(oracleContext, strategyContext);

        poolClaimAmount = context.poolContext._joinPoolAndStake({
            strategyContext: strategyContext,
            stakingContext: stakingContext,
            oracleContext: oracleContext,
            deposit: primaryAmount,
            /// @notice Setting minBPT to 0 based on the following assumptions
            /// 1. _getValidatedPoolData already validates the spot price to make sure
            /// the pool isn't being manipulated
            /// 2. We check maxPoolShare before joining to make sure the pool
            /// has adequate liquidity
            /// 3. Manipulating the pool before calling reinvestReward isn't expected
            /// to be very profitable for the attacker because the function gets called
            /// very frequently (relatively small trades)
            minBPT: 0
        });

        strategyContext.vaultState.totalPoolClaim += poolClaimAmount;
        strategyContext.vaultState.setStrategyVaultState(); 

        emit VaultEvents.RewardReinvested(rewardToken, primaryAmount, secondaryAmount, poolClaimAmount); 
    }

    function convertStrategyToUnderlying(
        Boosted3TokenAuraStrategyContext memory context,
        uint256 strategyTokenAmount
    ) external view returns (int256 underlyingValue) {
        underlyingValue = context.poolContext._convertStrategyToUnderlying({
            strategyContext: context.baseStrategy,
            oracleContext: context.oracleContext,
            strategyTokenAmount: strategyTokenAmount
        });
    }

    function getSpotPrice(
        Boosted3TokenAuraStrategyContext memory context,
        uint8 tokenIndex
    ) external view returns (uint256 spotPrice) {
        spotPrice = context.poolContext._getSpotPrice(context.oracleContext, tokenIndex);
    }

    function getExchangeRate(Boosted3TokenAuraStrategyContext calldata context) external view returns (int256) {
        if (context.baseStrategy.vaultState.totalVaultSharesGlobal == 0) {
            return context.poolContext._getTimeWeightedPrimaryBalance({
                oracleContext: context.oracleContext,
                strategyContext: context.baseStrategy,
                bptAmount: context.baseStrategy.poolClaimPrecision // 1 pool token
            }).toInt();
        } else {
            return context.poolContext._convertStrategyToUnderlying({
                strategyContext: context.baseStrategy,
                oracleContext: context.oracleContext,
                strategyTokenAmount: uint256(Constants.INTERNAL_TOKEN_PRECISION) // 1 vault share
            });
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.17;

library BalancerConstants {
    uint256 internal constant BALANCER_PRECISION = 1e18;
    uint256 internal constant BALANCER_PRECISION_SQUARED = 1e36;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        return a - b;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        if (product == 0) {
            return 0;
        } else {
            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((product - 1) / ONE) + 1;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;
            return aInflated / b;
        }
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;

            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((aInflated - 1) / b) + 1;
        }
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {Math} from "./Math.sol";
import {FixedPoint} from "./FixedPoint.sol";

library LinearMath {
    using FixedPoint for uint256;

    struct Params {
        uint256 fee;
        uint256 lowerTarget;
        uint256 upperTarget;
    }

    function _calcMainOutPerBptIn(
        uint256 bptIn,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 invariant = _calcInvariant(previousNominalMain, wrappedBalance);
        uint256 deltaNominalMain = Math.divDown(Math.mul(invariant, bptIn), bptSupply);
        uint256 afterNominalMain = previousNominalMain.sub(deltaNominalMain);
        uint256 newMainBalance = _fromNominal(afterNominalMain, params);
        return mainBalance.sub(newMainBalance);
    }

    function _calcBptOutPerMainIn(
        uint256 mainIn,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        if (bptSupply == 0) {
            // BPT typically grows in the same ratio the invariant does. The first time liquidity is added however, the
            // BPT supply is initialized to equal the invariant (which in this case is just the nominal main balance as
            // there is no wrapped balance).
            return _toNominal(mainIn, params);
        }

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = _toNominal(mainBalance.add(mainIn), params);
        uint256 deltaNominalMain = afterNominalMain.sub(previousNominalMain);
        uint256 invariant = _calcInvariant(previousNominalMain, wrappedBalance);
        return Math.divDown(Math.mul(bptSupply, deltaNominalMain), invariant);
    }

    function _toNominal(uint256 real, Params memory params) private pure returns (uint256) {
        // Fees are always rounded down: either direction would work but we need to be consistent, and rounding down
        // uses less gas.

        if (real < params.lowerTarget) {
            uint256 fees = (params.lowerTarget - real).mulDown(params.fee);
            return real.sub(fees);
        } else if (real <= params.upperTarget) {
            return real;
        } else {
            uint256 fees = (real - params.upperTarget).mulDown(params.fee);
            return real.sub(fees);
        }
    }

    function _fromNominal(uint256 nominal, Params memory params) internal pure returns (uint256) {
        // Since real = nominal + fees, rounding down fees is equivalent to rounding down real.

        if (nominal < params.lowerTarget) {
            return (nominal.add(params.fee.mulDown(params.lowerTarget))).divDown(FixedPoint.ONE.add(params.fee));
        } else if (nominal <= params.upperTarget) {
            return nominal;
        } else {
            return (nominal.sub(params.fee.mulDown(params.upperTarget)).divDown(FixedPoint.ONE.sub(params.fee)));
        }
    }

    function _calcInvariant(uint256 nominalMainBalance, uint256 wrappedBalance) private pure returns (uint256) {
        return nominalMainBalance.add(wrappedBalance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Adapted from OpenZeppelin's SafeMath library
 */
library Math {
    /**
     * @dev Returns the addition of two unsigned integers of 256 bits, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(
        uint256 a,
        uint256 b,
        bool roundUp
    ) internal pure returns (uint256) {
        return roundUp ? divUp(a, b) : divDown(a, b);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            return 1 + (a - 1) / b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {StableOracleContext, Balancer2TokenPoolContext, StrategyContext} from "../../BalancerVaultTypes.sol";
import {TwoTokenPoolContext} from "../../../common/VaultTypes.sol";
import {VaultConstants} from "../../../common/VaultConstants.sol";
import {StrategyUtils} from "../../../common/internal/strategy/StrategyUtils.sol";
import {TwoTokenPoolUtils} from "../../../common/internal/pool/TwoTokenPoolUtils.sol";
import {BalancerConstants} from "../BalancerConstants.sol";
import {Errors} from "../../../../global/Errors.sol";
import {TypeConvert} from "../../../../global/TypeConvert.sol";
import {StableMath} from "./StableMath.sol";
import {ITradingModule} from "../../../../../interfaces/trading/ITradingModule.sol";

library Stable2TokenOracleMath {
    using TypeConvert for int256;
    using Stable2TokenOracleMath for StableOracleContext;
    using TwoTokenPoolUtils for TwoTokenPoolContext;
    using StrategyUtils for StrategyContext;

    function _getSpotPrice(
        StableOracleContext memory oracleContext, 
        Balancer2TokenPoolContext memory poolContext, 
        uint256 primaryBalance,
        uint256 secondaryBalance,
        uint256 tokenIndex
    ) internal view returns (uint256 spotPrice) {
        require(tokenIndex < 2); /// @dev invalid token index

        /// Apply scale factors
        uint256 scaledPrimaryBalance = primaryBalance * poolContext.primaryScaleFactor 
            / BalancerConstants.BALANCER_PRECISION;
        uint256 scaledSecondaryBalance = secondaryBalance * poolContext.secondaryScaleFactor 
            / BalancerConstants.BALANCER_PRECISION;

        /// @notice poolContext balances are always in BALANCER_PRECISION (1e18)
        (uint256 balanceX, uint256 balanceY) = tokenIndex == 0 ?
            (scaledPrimaryBalance, scaledSecondaryBalance) :
            (scaledSecondaryBalance, scaledPrimaryBalance);

        uint256 invariant = StableMath._calculateInvariant(
            oracleContext.ampParam, StableMath._balances(balanceX, balanceY), true // round up
        );

        spotPrice = StableMath._calcSpotPrice({
            amplificationParameter: oracleContext.ampParam,
            invariant: invariant,
            balanceX: balanceX,
            balanceY: balanceY
        });

        /// Apply secondary scale factor in reverse
        uint256 scaleFactor = tokenIndex == 0 ?
            poolContext.secondaryScaleFactor * BalancerConstants.BALANCER_PRECISION / poolContext.primaryScaleFactor :
            poolContext.primaryScaleFactor * BalancerConstants.BALANCER_PRECISION / poolContext.secondaryScaleFactor;
        spotPrice = spotPrice * BalancerConstants.BALANCER_PRECISION / scaleFactor;

        // Convert precision back to 1e18 after downscaling by scaleFactor
        spotPrice = spotPrice * BalancerConstants.BALANCER_PRECISION / _getPrecision(poolContext.basePool, tokenIndex);
    }

    function _getPrecision(
        TwoTokenPoolContext memory poolContext,
        uint256 tokenIndex
    ) private pure returns(uint256 precision) {
        if (tokenIndex == 0) {
            precision = 10**poolContext.primaryDecimals;
        } else if (tokenIndex == 1) {
            precision = 10**poolContext.secondaryDecimals;
        }
    }

    /// @notice calculates the expected min exit amounts for a given BPT amount
    function _getMinExitAmounts(
        StableOracleContext memory oracleContext,
        Balancer2TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        uint256 oraclePrice,
        uint256 bptAmount
    ) internal view returns (uint256 minPrimary, uint256 minSecondary) {
        // Oracle price is always specified in terms of primary, so tokenIndex == 0 for primary
        // Validate the spot price to make sure the pool is not being manipulated
        uint256 spotPrice = _getSpotPrice({
            oracleContext: oracleContext,
            poolContext: poolContext,
            primaryBalance: poolContext.basePool.primaryBalance,
            secondaryBalance: poolContext.basePool.secondaryBalance,
            tokenIndex: 0
        });

        (minPrimary, minSecondary) = poolContext.basePool._getMinExitAmounts({
            strategyContext: strategyContext,
            spotPrice: spotPrice,
            oraclePrice: oraclePrice,
            poolClaim: bptAmount
        });
    }

    function _validateSpotPriceAndPairPrice(
        StableOracleContext calldata oracleContext,
        Balancer2TokenPoolContext calldata poolContext,
        StrategyContext memory strategyContext,
        uint256 oraclePrice,
        uint256 primaryAmount, 
        uint256 secondaryAmount
    ) internal view {
        // Oracle price is always specified in terms of primary, so tokenIndex == 0 for primary
        uint256 spotPrice = _getSpotPrice({
            oracleContext: oracleContext,
            poolContext: poolContext,
            primaryBalance: poolContext.basePool.primaryBalance,
            secondaryBalance: poolContext.basePool.secondaryBalance,
            tokenIndex: 0
        });

        /// @notice Check spotPrice against oracle price to make sure that 
        /// the pool is not being manipulated
        strategyContext._checkPriceLimit(oraclePrice, spotPrice);

        uint256 calculatedPairPrice = _getSpotPrice({
            oracleContext: oracleContext,
            poolContext: poolContext,
            primaryBalance: primaryAmount,
            secondaryBalance: secondaryAmount,
            tokenIndex: 0
        });

        /// @notice Check the calculated primary/secondary price against the oracle price
        /// to make sure that we are joining the pool proportionally
        strategyContext._checkPriceLimit(oraclePrice, calculatedPairPrice);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {Math} from "./Math.sol";
import {FixedPoint} from "./FixedPoint.sol";

library StableMath {
    using FixedPoint for uint256;
    
    uint256 internal constant _AMP_PRECISION = 1e3;

    error CalculationDidNotConverge();

    // Note on unchecked arithmetic:
    // This contract performs a large number of additions, subtractions, multiplications and divisions, often inside
    // loops. Since many of these operations are gas-sensitive (as they happen e.g. during a swap), it is important to
    // not make any unnecessary checks. We rely on a set of invariants to avoid having to use checked arithmetic (the
    // Math library), including:
    //  - the number of tokens is bounded by _MAX_STABLE_TOKENS
    //  - the amplification parameter is bounded by _MAX_AMP * _AMP_PRECISION, which fits in 23 bits
    //  - the token balances are bounded by 2^112 (guaranteed by the Vault) times 1e18 (the maximum scaling factor),
    //    which fits in 172 bits
    //
    // This means e.g. we can safely multiply a balance by the amplification parameter without worrying about overflow.

    // Computes the invariant given the current balances, using the Newton-Raphson approximation.
    // The amplification parameter equals: A n^(n-1)
    function _calculateInvariant(
        uint256 amplificationParameter,
        uint256[] memory balances,
        bool roundUp
    ) internal pure returns (uint256) {
        /**********************************************************************************************
        // invariant                                                                                 //
        // D = invariant                                                  D^(n+1)                    //
        // A = amplification coefficient      A  n^n S + D = A D n^n + -----------                   //
        // S = sum of balances                                             n^n P                     //
        // P = product of balances                                                                   //
        // n = number of tokens                                                                      //
        *********x************************************************************************************/

        unchecked {
            // We support rounding up or down.
            uint256 sum = 0;
            uint256 numTokens = balances.length;
            for (uint256 i = 0; i < numTokens; i++) {
                sum = sum.add(balances[i]);
            }
            if (sum == 0) {
                return 0;
            }

            uint256 prevInvariant = 0;
            uint256 invariant = sum;
            uint256 ampTimesTotal = amplificationParameter * numTokens;

            for (uint256 i = 0; i < 255; i++) {
                uint256 P_D = balances[0] * numTokens;
                for (uint256 j = 1; j < numTokens; j++) {
                    P_D = Math.div(Math.mul(Math.mul(P_D, balances[j]), numTokens), invariant, roundUp);
                }
                prevInvariant = invariant;
                invariant = Math.div(
                    Math.mul(Math.mul(numTokens, invariant), invariant).add(
                        Math.div(Math.mul(Math.mul(ampTimesTotal, sum), P_D), _AMP_PRECISION, roundUp)
                    ),
                    Math.mul(numTokens + 1, invariant).add(
                        // No need to use checked arithmetic for the amp precision, the amp is guaranteed to be at least 1
                        Math.div(Math.mul(ampTimesTotal - _AMP_PRECISION, P_D), _AMP_PRECISION, !roundUp)
                    ),
                    roundUp
                );

                if (invariant > prevInvariant) {
                    if (invariant - prevInvariant <= 1) {
                        return invariant;
                    }
                } else if (prevInvariant - invariant <= 1) {
                    return invariant;
                }
            }
        }

        revert CalculationDidNotConverge();
    }

    /**
     * @dev Calculates the spot price of token Y in token X.
     */
    function _calcSpotPrice(
        uint256 amplificationParameter,
        uint256 invariant, 
        uint256 balanceX,
        uint256 balanceY
    ) internal pure returns (uint256) {
        /**************************************************************************************************************
        //                                                                                                           //
        //                             2.a.x.y + a.y^2 + b.y                                                         //
        // spot price Y/X = - dx/dy = -----------------------                                                        //
        //                             2.a.x.y + a.x^2 + b.x                                                         //
        //                                                                                                           //
        // n = 2                                                                                                     //
        // a = amp param * n                                                                                         //
        // b = D + a.(S - D)                                                                                         //
        // D = invariant                                                                                             //
        // S = sum of balances but x,y = 0 since x  and y are the only tokens                                        //
        **************************************************************************************************************/

        unchecked {
            uint256 a = (amplificationParameter * 2) / _AMP_PRECISION;
            uint256 b = Math.mul(invariant, a).sub(invariant);

            uint256 axy2 = Math.mul(a * 2, balanceX).mulDown(balanceY); // n = 2

            // dx = a.x.y.2 + a.y^2 - b.y
            uint256 derivativeX = axy2.add(Math.mul(a, balanceY).mulDown(balanceY)).sub(b.mulDown(balanceY));

            // dy = a.x.y.2 + a.x^2 - b.x
            uint256 derivativeY = axy2.add(Math.mul(a, balanceX).mulDown(balanceX)).sub(b.mulDown(balanceX));

            // The rounding direction is irrelevant as we're about to introduce a much larger error when converting to log
            // space. We use `divUp` as it prevents the result from being zero, which would make the logarithm revert. A
            // result of zero is therefore only possible with zero balances, which are prevented via other means.
            return derivativeX.divUp(derivativeY);
        }
    }

    function _balances(uint256 balanceX, uint256 balanceY) internal pure returns (uint256[] memory balances) {
        balances = new uint256[](2);
        balances[0] = balanceX;
        balances[1] = balanceY;
    }

    // This function calculates the balance of a given token (tokenIndex)
    // given all the other balances and the invariant
    function _getTokenBalanceGivenInvariantAndAllOtherBalances(
        uint256 amplificationParameter,
        uint256[] memory balances,
        uint256 invariant,
        uint256 tokenIndex
    ) internal pure returns (uint256) {
        // Rounds result up overall
        unchecked {
            uint256 ampTimesTotal = amplificationParameter * balances.length;
            uint256 sum = balances[0];
            uint256 P_D = balances[0] * balances.length;
            for (uint256 j = 1; j < balances.length; j++) {
                P_D = Math.divDown(Math.mul(Math.mul(P_D, balances[j]), balances.length), invariant);
                sum = sum.add(balances[j]);
            }
            // No need to use safe math, based on the loop above `sum` is greater than or equal to `balances[tokenIndex]`
            sum = sum - balances[tokenIndex];

            uint256 inv2 = Math.mul(invariant, invariant);
            // We remove the balance fromm c by multiplying it
            uint256 c = Math.mul(
                Math.mul(Math.divUp(inv2, Math.mul(ampTimesTotal, P_D)), _AMP_PRECISION),
                balances[tokenIndex]
            );
            uint256 b = sum.add(Math.mul(Math.divDown(invariant, ampTimesTotal), _AMP_PRECISION));

            // We iterate to find the balance
            uint256 prevTokenBalance = 0;
            // We multiply the first iteration outside the loop with the invariant to set the value of the
            // initial approximation.
            uint256 tokenBalance = Math.divUp(inv2.add(c), invariant.add(b));

            for (uint256 i = 0; i < 255; i++) {
                prevTokenBalance = tokenBalance;

                tokenBalance = Math.divUp(
                    Math.mul(tokenBalance, tokenBalance).add(c),
                    Math.mul(tokenBalance, 2).add(b).sub(invariant)
                );

                if (tokenBalance > prevTokenBalance) {
                    if (tokenBalance - prevTokenBalance <= 1) {
                        return tokenBalance;
                    }
                } else if (prevTokenBalance - tokenBalance <= 1) {
                    return tokenBalance;
                }
            }
        }

        revert CalculationDidNotConverge();
    }

    function _calcTokenOutGivenExactBptIn(
        uint256 amp,
        uint256[] memory balances,
        uint256 tokenIndex,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage,
        uint256 currentInvariant
    ) internal pure returns (uint256) {
        // Token out, so we round down overall.

        unchecked {
            uint256 newInvariant = bptTotalSupply.sub(bptAmountIn).divUp(bptTotalSupply).mulUp(currentInvariant);

            // Calculate amount out without fee
            uint256 newBalanceTokenIndex = _getTokenBalanceGivenInvariantAndAllOtherBalances(
                amp,
                balances,
                newInvariant,
                tokenIndex
            );
            uint256 amountOutWithoutFee = balances[tokenIndex].sub(newBalanceTokenIndex);

            // First calculate the sum of all token balances, which will be used to calculate
            // the current weight of each token
            uint256 sumBalances = 0;
            for (uint256 i = 0; i < balances.length; i++) {
                sumBalances = sumBalances.add(balances[i]);
            }

            // We can now compute how much excess balance is being withdrawn as a result of the virtual swaps, which result
            // in swap fees.
            uint256 currentWeight = balances[tokenIndex].divDown(sumBalances);
            uint256 taxablePercentage = currentWeight.complement();

            // Swap fees are typically charged on 'token in', but there is no 'token in' here, so we apply it
            // to 'token out'. This results in slightly larger price impact. Fees are rounded up.
            uint256 taxableAmount = amountOutWithoutFee.mulUp(taxablePercentage);
            uint256 nonTaxableAmount = amountOutWithoutFee.sub(taxableAmount);

            // No need to use checked arithmetic for the swap fee, it is guaranteed to be lower than 50%
            return nonTaxableAmount.add(taxableAmount.mulDown(FixedPoint.ONE - swapFeePercentage));
        }
    }

    // Computes how many tokens can be taken out of a pool if `tokenAmountIn` are sent, given the current balances.
    // The amplification parameter equals: A n^(n-1)
    function _calcOutGivenIn(
        uint256 amplificationParameter,
        uint256[] memory balances,
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountIn,
        uint256 invariant
    ) internal pure returns (uint256) {
        /**************************************************************************************************************
        // outGivenIn token x for y - polynomial equation to solve                                                   //
        // ay = amount out to calculate                                                                              //
        // by = balance token out                                                                                    //
        // y = by - ay (finalBalanceOut)                                                                             //
        // D = invariant                                               D                     D^(n+1)                 //
        // A = amplification coefficient               y^2 + ( S - ----------  - D) * y -  ------------- = 0         //
        // n = number of tokens                                    (A * n^n)               A * n^2n * P              //
        // S = sum of final balances but y                                                                           //
        // P = product of final balances but y                                                                       //
        **************************************************************************************************************/

        // Amount out, so we round down overall.
        unchecked {
            balances[tokenIndexIn] = balances[tokenIndexIn].add(tokenAmountIn);

            uint256 finalBalanceOut = _getTokenBalanceGivenInvariantAndAllOtherBalances(
                amplificationParameter,
                balances,
                invariant,
                tokenIndexOut
            );

            // No need to use checked arithmetic since `tokenAmountIn` was actually added to the same balance right before
            // calling `_getTokenBalanceGivenInvariantAndAllOtherBalances` which doesn't alter the balances array.
            balances[tokenIndexIn] = balances[tokenIndexIn] - tokenAmountIn;

            return balances[tokenIndexOut].sub(finalBalanceOut).sub(1);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    Balancer2TokenPoolContext, 
    StableOracleContext, 
    PoolParams,
    AuraStakingContext
} from "../../BalancerVaultTypes.sol";
import {
    TradeParams,
    StrategyContext,
    StrategyVaultSettings,
    StrategyVaultState,
    TwoTokenPoolContext,
    DepositParams,
    RedeemParams
} from "../../../common/VaultTypes.sol";
import {Deployments} from "../../../../global/Deployments.sol";
import {BalancerConstants} from "../BalancerConstants.sol";
import {Errors} from "../../../../global/Errors.sol";
import {Constants} from "../../../../global/Constants.sol";
import {TypeConvert} from "../../../../global/TypeConvert.sol";
import {IAsset} from "../../../../../interfaces/balancer/IBalancerVault.sol";
import {TradeHandler} from "../../../../trading/TradeHandler.sol";
import {BalancerUtils} from "../pool/BalancerUtils.sol";
import {Stable2TokenOracleMath} from "../math/Stable2TokenOracleMath.sol";
import {VaultStorage} from "../../../common/VaultStorage.sol";
import {StrategyUtils} from "../../../common/internal/strategy/StrategyUtils.sol";
import {TwoTokenPoolUtils} from "../../../common/internal/pool/TwoTokenPoolUtils.sol";
import {Balancer2TokenPoolUtils} from "../pool/Balancer2TokenPoolUtils.sol";
import {Trade} from "../../../../../interfaces/trading/ITradingModule.sol";
import {IAuraBoosterBase} from "../../../../../interfaces/aura/IAuraBooster.sol";
import {IBalancerVault} from "../../../../../interfaces/balancer/IBalancerVault.sol";
import {TokenUtils, IERC20} from "../../../../utils/TokenUtils.sol";

library Balancer2TokenPoolUtils {
    using TokenUtils for IERC20;
    using Balancer2TokenPoolUtils for Balancer2TokenPoolContext;
    using TwoTokenPoolUtils for TwoTokenPoolContext;
    using TradeHandler for Trade;
    using TypeConvert for uint256;
    using StrategyUtils for StrategyContext;
    using VaultStorage for StrategyVaultSettings;
    using VaultStorage for StrategyVaultState;
    using Stable2TokenOracleMath for StableOracleContext;

    /// @notice Returns parameters for joining and exiting Balancer pools
    function _getPoolParams(
        Balancer2TokenPoolContext memory context,
        uint256 primaryAmount,
        uint256 secondaryAmount,
        bool isJoin,
        bool isSingleSidedExit,
        uint256 bptExitAmount
    ) internal pure returns (PoolParams memory) {
        IAsset[] memory assets = new IAsset[](2);
        assets[context.basePool.primaryIndex] = IAsset(context.basePool.primaryToken);
        assets[context.basePool.secondaryIndex] = IAsset(context.basePool.secondaryToken);

        uint256[] memory amounts = new uint256[](2);
        amounts[context.basePool.primaryIndex] = primaryAmount;
        amounts[context.basePool.secondaryIndex] = secondaryAmount;

        uint256 msgValue;
        if (isJoin && assets[context.basePool.primaryIndex] == IAsset(Deployments.ETH_ADDRESS)) {
            msgValue = amounts[context.basePool.primaryIndex];
        }

        bytes memory customData;
        if (!isJoin) {
            if (isSingleSidedExit) {
                customData = abi.encode(
                    IBalancerVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
                    bptExitAmount,
                    context.basePool.primaryIndex
                );
            } else {
                customData = abi.encode(
                    IBalancerVault.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT,
                    bptExitAmount
                );
            }
        }

        return PoolParams(assets, amounts, msgValue, customData);
    }

    /// @notice Gets the time-weighted primary token balance for a given bptAmount
    /// @param poolContext pool context variables
    /// @param oracleContext oracle context variables
    /// @param bptAmount amount of balancer pool lp tokens
    /// @return primaryAmount primary token balance
    function _getTimeWeightedPrimaryBalance(
        Balancer2TokenPoolContext memory poolContext,
        StableOracleContext memory oracleContext,
        StrategyContext memory strategyContext,
        uint256 bptAmount
    ) internal view returns (uint256 primaryAmount) {
        uint256 oraclePairPrice = poolContext.basePool._getOraclePairPrice(strategyContext);

        // tokenIndex == 0 because _getOraclePairPrice always returns the price in terms of
        // the primary currency
        uint256 spotPrice = oracleContext._getSpotPrice({
            poolContext: poolContext,
            primaryBalance: poolContext.basePool.primaryBalance,
            secondaryBalance: poolContext.basePool.secondaryBalance,
            tokenIndex: 0
        });

        primaryAmount = poolContext.basePool._getTimeWeightedPrimaryBalance({
            strategyContext: strategyContext,
            poolClaim: bptAmount,
            oraclePrice: oraclePairPrice,
            spotPrice: spotPrice
        });
    }

    function _approveBalancerTokens(TwoTokenPoolContext memory poolContext, address bptSpender) internal {
        IERC20(poolContext.primaryToken).checkApprove(address(Deployments.BALANCER_VAULT), type(uint256).max);
        IERC20(poolContext.secondaryToken).checkApprove(address(Deployments.BALANCER_VAULT), type(uint256).max);
        // Allow BPT spender to pull BALANCER_POOL_TOKEN
        poolContext.poolToken.checkApprove(bptSpender, type(uint256).max);
    }

    function _deposit(
        Balancer2TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        uint256 deposit,
        DepositParams memory params
    ) internal returns (uint256 strategyTokensMinted) {
        uint256 secondaryAmount;
        if (params.tradeData.length != 0) {
            // Allows users to trade on a different DEX instead of Balancer when joining
            (uint256 primarySold, uint256 secondaryBought) = poolContext.basePool._tradePrimaryForSecondary({
                strategyContext: strategyContext,
                data: params.tradeData
            });
            deposit -= primarySold;
            secondaryAmount = secondaryBought;
        }

        uint256 bptMinted = poolContext._joinPoolAndStake({
            strategyContext: strategyContext,
            stakingContext: stakingContext,
            primaryAmount: deposit,
            secondaryAmount: secondaryAmount,
            minBPT: params.minPoolClaim
        });

        strategyTokensMinted = strategyContext._mintStrategyTokens(bptMinted);
    }

    function _redeem(
        Balancer2TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        uint256 strategyTokens,
        RedeemParams memory params
    ) internal returns (uint256 finalPrimaryBalance) {
        uint256 bptClaim = strategyContext._redeemStrategyTokens(strategyTokens);
        bool isSingleSidedExit = params.secondaryTradeParams.length == 0;

        // Underlying token balances from exiting the pool
        (uint256 primaryBalance, uint256 secondaryBalance)
            = _unstakeAndExitPool(
                poolContext, stakingContext, bptClaim, params.minPrimary, params.minSecondary, isSingleSidedExit
            );

        finalPrimaryBalance = primaryBalance;
        if (secondaryBalance > 0) {
            uint256 primaryPurchased = poolContext.basePool._sellSecondaryBalance(
                strategyContext, params, secondaryBalance
            );

            finalPrimaryBalance += primaryPurchased;
        }
    }

    function _joinPoolAndStake(
        Balancer2TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        uint256 primaryAmount,
        uint256 secondaryAmount,
        uint256 minBPT
    ) internal returns (uint256 bptMinted) {
        // prettier-ignore
        PoolParams memory poolParams = poolContext._getPoolParams({
            primaryAmount: primaryAmount,
            secondaryAmount: secondaryAmount,
            isJoin: true,
            isSingleSidedExit: false,
            bptExitAmount: 0
        });

        bptMinted = BalancerUtils._joinPoolExactTokensIn({
            poolId: poolContext.poolId,
            poolToken: poolContext.basePool.poolToken,
            params: poolParams,
            minBPT: minBPT
        });

        // Check BPT threshold to make sure our share of the pool is
        // below maxPoolShare
        uint256 bptThreshold = strategyContext.vaultSettings._poolClaimThreshold(
            poolContext.basePool.poolToken.totalSupply()
        );
        uint256 bptHeldAfterJoin = strategyContext.vaultState.totalPoolClaim + bptMinted;
        if (bptHeldAfterJoin > bptThreshold)
            revert Errors.PoolShareTooHigh(bptHeldAfterJoin, bptThreshold);

        // Transfer token to Aura protocol for boosted staking
        bool success = IAuraBoosterBase(stakingContext.booster).deposit(stakingContext.poolId, bptMinted, true); // stake = true
        if (!success) revert Errors.StakeFailed();
    }

    function _unstakeAndExitPool(
        Balancer2TokenPoolContext memory poolContext,
        AuraStakingContext memory stakingContext,
        uint256 bptClaim,
        uint256 minPrimary,
        uint256 minSecondary,
        bool isSingleSidedExit
    ) internal returns (uint256 primaryBalance, uint256 secondaryBalance) {
        // Withdraw BPT tokens back to the vault for redemption
        bool success = stakingContext.rewardPool.withdrawAndUnwrap(bptClaim, false); // claimRewards = false
        if (!success) revert Errors.UnstakeFailed();

        uint256[] memory exitBalances = _exitPool(poolContext, bptClaim, minPrimary, minSecondary, isSingleSidedExit);

        (primaryBalance, secondaryBalance) 
            = (exitBalances[poolContext.basePool.primaryIndex], exitBalances[poolContext.basePool.secondaryIndex]);
    }

    function _exitPool(
        Balancer2TokenPoolContext memory poolContext,
        uint256 bptClaim,
        uint256 minPrimary,
        uint256 minSecondary,
        bool isSingleSidedExit
    ) private returns (uint256[] memory) {
        return BalancerUtils._exitPoolExactBPTIn({
            poolId: poolContext.poolId,
            poolToken: poolContext.basePool.poolToken,
            params: poolContext._getPoolParams({
                primaryAmount: minPrimary,
                secondaryAmount: minSecondary,
                isJoin: false,
                isSingleSidedExit: isSingleSidedExit,
                bptExitAmount: bptClaim
            }),
            bptExitAmount: bptClaim
        });
    }

    /// @notice We value strategy tokens in terms of the primary balance. The time weighted
    /// primary balance is used in order to prevent pool manipulation.
    /// @param poolContext pool context variables
    /// @param strategyContext strategy context variables
    /// @param oracleContext oracle context variables
    /// @param strategyTokenAmount amount of strategy tokens
    /// @return underlyingValue underlying value of strategy tokens
    function _convertStrategyToUnderlying(
        Balancer2TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        StableOracleContext memory oracleContext,
        uint256 strategyTokenAmount
    ) internal view returns (int256 underlyingValue) {
        
        uint256 bptClaim 
            = strategyContext._convertStrategyTokensToPoolClaim(strategyTokenAmount);

        underlyingValue 
            = poolContext._getTimeWeightedPrimaryBalance(oracleContext, strategyContext, bptClaim).toInt();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    Balancer2TokenPoolContext,
    Balancer3TokenPoolContext,
    BoostedOracleContext,
    AuraStakingContext,
    UnderlyingPoolContext
} from "../../BalancerVaultTypes.sol";
import {
    StrategyContext,
    StrategyVaultSettings,
    StrategyVaultState,
    TwoTokenPoolContext,
    ThreeTokenPoolContext
} from "../../../common/VaultTypes.sol";
import {TypeConvert} from "../../../../global/TypeConvert.sol";
import {VaultConstants} from "../../../common/VaultConstants.sol";
import {BalancerConstants} from "../BalancerConstants.sol";
import {Deployments} from "../../../../global/Deployments.sol";
import {Errors} from "../../../../global/Errors.sol";
import {BalancerUtils} from "../pool/BalancerUtils.sol";
import {StableMath} from "../math/StableMath.sol";
import {LinearMath} from "../math/LinearMath.sol";
import {StrategyUtils} from "../../../common/internal/strategy/StrategyUtils.sol";
import {VaultStorage} from "../../../common/VaultStorage.sol";
import {ITradingModule} from "../../../../../interfaces/trading/ITradingModule.sol";
import {IBoostedPool, ILinearPool} from "../../../../../interfaces/balancer/IBalancerPool.sol";
import {IAuraBoosterBase} from "../../../../../interfaces/aura/IAuraBooster.sol";
import {TokenUtils, IERC20} from "../../../../utils/TokenUtils.sol";
import {Balancer2TokenPoolUtils} from "./Balancer2TokenPoolUtils.sol";
import {FixedPoint} from "../math/FixedPoint.sol";

library Balancer3TokenBoostedPoolUtils {
    using TypeConvert for uint256;
    using FixedPoint for uint256;
    using TypeConvert for int256;
    using TokenUtils for IERC20;
    using Balancer2TokenPoolUtils for Balancer2TokenPoolContext;
    using Balancer2TokenPoolUtils for TwoTokenPoolContext;
    using Balancer3TokenBoostedPoolUtils for Balancer3TokenPoolContext;
    using StrategyUtils for StrategyContext;
    using VaultStorage for StrategyVaultSettings;
    using VaultStorage for StrategyVaultState;

    function _getScaleFactor(
        Balancer3TokenPoolContext memory poolContext,
        uint8 tokenIndex
    ) private pure returns(uint256 scaleFactor) {
        if (tokenIndex == 0) {
            scaleFactor = poolContext.primaryScaleFactor;
        } else if (tokenIndex == 1) {
            scaleFactor = poolContext.secondaryScaleFactor;
        } else if (tokenIndex == 2) {
            scaleFactor = poolContext.tertiaryScaleFactor;
        }
    }

    function _getPrecision(
        ThreeTokenPoolContext memory poolContext,
        uint8 tokenIndex
    ) private pure returns(uint256 precision) {
        if (tokenIndex == 0) {
            precision = 10**poolContext.basePool.primaryDecimals;
        } else if (tokenIndex == 1) {
            precision = 10**poolContext.basePool.secondaryDecimals;
        } else if (tokenIndex == 2) {
            precision = 10**poolContext.tertiaryDecimals;
        }
    }

    /// @notice Spot price is always expressed in terms of the primary currency
    function _getSpotPrice(
        Balancer3TokenPoolContext memory poolContext, 
        BoostedOracleContext memory oracleContext,
        uint8 tokenIndex
    ) internal pure returns (uint256 spotPrice) {
        require(tokenIndex < 3);  /// @dev invalid token index

        // Exchange rate of primary currency = 1
        if (tokenIndex == 0) {
            return BalancerConstants.BALANCER_PRECISION;
        }

        uint256[] memory balances = _getScaledBalances(poolContext);
        uint256 invariant = StableMath._calculateInvariant(
            oracleContext.ampParam, balances, true // roundUp = true
        );
        spotPrice = _getSpotPriceWithInvariant({
            poolContext: poolContext,
            oracleContext: oracleContext,
            balances: balances, 
            invariant: invariant,
            tokenIndex: tokenIndex
        });
    }

    function _getUnderlyingBPTOut(
        UnderlyingPoolContext memory pool,
        uint256 mainIn
    ) private pure returns (uint256) {
        uint256 scaledMainBalance = pool.mainBalance * pool.mainScaleFactor /
            BalancerConstants.BALANCER_PRECISION;
        uint256 scaledWrappedBalance = pool.wrappedBalance * pool.wrappedScaleFactor /
            BalancerConstants.BALANCER_PRECISION;

        // Convert from linear pool BPT to primary Amount
        return LinearMath._calcBptOutPerMainIn({
            mainIn: mainIn,
            mainBalance: scaledMainBalance,
            wrappedBalance: scaledWrappedBalance,
            bptSupply: pool.virtualSupply,
            params: LinearMath.Params({
                fee: pool.fee,
                lowerTarget: pool.lowerTarget,
                upperTarget: pool.upperTarget
            }) 
        });
    }

    function _getUnderlyingMainOut(
        UnderlyingPoolContext memory pool,
        uint256 bptIn
    ) private pure returns (uint256) {
        uint256 scaledMainBalance = pool.mainBalance * pool.mainScaleFactor /
            BalancerConstants.BALANCER_PRECISION;
        uint256 scaledWrappedBalance = pool.wrappedBalance * pool.wrappedScaleFactor /
            BalancerConstants.BALANCER_PRECISION;

        // Convert from linear pool BPT to primary Amount
        return LinearMath._calcMainOutPerBptIn({
            bptIn: bptIn,
            mainBalance: scaledMainBalance,
            wrappedBalance: scaledWrappedBalance,
            bptSupply: pool.virtualSupply,
            params: LinearMath.Params({
                fee: pool.fee,
                lowerTarget: pool.lowerTarget,
                upperTarget: pool.upperTarget
            }) 
        });
    }

    /// @notice Spot price is always expressed in terms of the primary currency
    function _getSpotPriceWithInvariant(
        Balancer3TokenPoolContext memory poolContext, 
        BoostedOracleContext memory oracleContext,
        uint256[] memory balances,
        uint256 invariant,
        uint8 tokenIndex
    ) private pure returns (uint256 spotPrice) {
        // Trade 1 unit of tokenIn for tokenOut to get the spot price
        // AmountIn needs to be in underlying precision because mainScaleFactor
        // will convert it to 1e18
        uint256 amountIn = _getPrecision(poolContext.basePool, tokenIndex);

        UnderlyingPoolContext memory inPool = oracleContext.underlyingPools[tokenIndex];
        amountIn = amountIn * inPool.mainScaleFactor / BalancerConstants.BALANCER_PRECISION;
        uint256 linearBPTIn = _getUnderlyingBPTOut(inPool, amountIn);

        linearBPTIn = linearBPTIn * _getScaleFactor(poolContext, tokenIndex) / BalancerConstants.BALANCER_PRECISION;

        uint256 linearBPTOut = StableMath._calcOutGivenIn({
            amplificationParameter: oracleContext.ampParam,
            balances: balances,
            tokenIndexIn: tokenIndex,
            tokenIndexOut: 0, // Primary index
            tokenAmountIn: linearBPTIn,
            invariant: invariant
        });

        linearBPTOut = linearBPTOut * BalancerConstants.BALANCER_PRECISION / _getScaleFactor(poolContext, 0);

        UnderlyingPoolContext memory outPool = oracleContext.underlyingPools[0];
        spotPrice = _getUnderlyingMainOut(outPool, linearBPTOut);
        spotPrice = spotPrice * BalancerConstants.BALANCER_PRECISION / outPool.mainScaleFactor;

        // Convert precision back to 1e18 after downscaling by mainScaleFactor
        // primary currency = index 0
        spotPrice = spotPrice * BalancerConstants.BALANCER_PRECISION / _getPrecision(poolContext.basePool, 0);
    }

    function _validateSpotPrice(
        Balancer3TokenPoolContext memory poolContext, 
        BoostedOracleContext memory oracleContext,
        StrategyContext memory context,
        address tokenIn,
        address tokenOut,
        uint8 tokenIndex,
        uint256[] memory balances,
        uint256 invariant
    ) private view {
        (int256 answer, int256 decimals) = context.tradingModule.getOraclePrice(tokenOut, tokenIn);
        require(decimals == int256(BalancerConstants.BALANCER_PRECISION));
        
        uint256 spotPrice = _getSpotPriceWithInvariant({
            poolContext: poolContext,
            oracleContext: oracleContext,
            balances: balances, 
            invariant: invariant,
            tokenIndex: tokenIndex
        });

        uint256 oraclePrice = answer.toUint();
        uint256 lowerLimit = (oraclePrice * 
            (VaultConstants.VAULT_PERCENT_BASIS - context.vaultSettings.oraclePriceDeviationLimitPercent)) / 
            VaultConstants.VAULT_PERCENT_BASIS;
        uint256 upperLimit = (oraclePrice * 
            (VaultConstants.VAULT_PERCENT_BASIS + context.vaultSettings.oraclePriceDeviationLimitPercent)) / 
            VaultConstants.VAULT_PERCENT_BASIS;

        // Check spot price against oracle price to make sure it hasn't been manipulated
        if (spotPrice < lowerLimit || upperLimit < spotPrice) {
            revert Errors.InvalidPrice(oraclePrice, spotPrice);
        }
    }

    function _validateTokenPrices(
        Balancer3TokenPoolContext memory poolContext, 
        BoostedOracleContext memory oracleContext,
        StrategyContext memory strategyContext,
        uint256[] memory balances,
        uint256 invariant
    ) private view {
        address primaryUnderlying = ILinearPool(address(poolContext.basePool.basePool.primaryToken)).getMainToken();
        address secondaryUnderlying = ILinearPool(address(poolContext.basePool.basePool.secondaryToken)).getMainToken();
        address tertiaryUnderlying = ILinearPool(address(poolContext.basePool.tertiaryToken)).getMainToken();

        _validateSpotPrice({
            poolContext: poolContext,
            oracleContext: oracleContext,
            context: strategyContext,
            tokenIn: primaryUnderlying,
            tokenOut: secondaryUnderlying,
            tokenIndex: 1, // secondary index
            balances: balances,
            invariant: invariant
        });

        _validateSpotPrice({
            poolContext: poolContext,
            oracleContext: oracleContext,
            context: strategyContext,
            tokenIn: primaryUnderlying,
            tokenOut: tertiaryUnderlying,
            tokenIndex: 2, // tertiary index
            balances: balances,
            invariant: invariant
        });
    }

    function _getScaledBalances(Balancer3TokenPoolContext memory poolContext) 
        private pure returns (uint256[] memory amountsWithoutBpt) {
        amountsWithoutBpt = new uint256[](3);
        amountsWithoutBpt[0] = poolContext.basePool.basePool.primaryBalance * poolContext.primaryScaleFactor 
            / BalancerConstants.BALANCER_PRECISION;
        amountsWithoutBpt[1] = poolContext.basePool.basePool.secondaryBalance * poolContext.secondaryScaleFactor
            / BalancerConstants.BALANCER_PRECISION;
        amountsWithoutBpt[2] = poolContext.basePool.tertiaryBalance * poolContext.tertiaryScaleFactor
            / BalancerConstants.BALANCER_PRECISION;        
    }

    function _getValidatedPoolData(
        Balancer3TokenPoolContext memory poolContext,
        BoostedOracleContext memory oracleContext,
        StrategyContext memory strategyContext
    ) internal view returns (uint256[] memory balances, uint256 invariant) {
        balances = _getScaledBalances(poolContext);

        // Get the current and new invariants. Since we need a bigger new invariant, we round the current one up.
        invariant = StableMath._calculateInvariant(
            oracleContext.ampParam, balances, false // roundUp = false
        );

        // validate spot prices against oracle prices
        _validateTokenPrices({
            poolContext: poolContext,
            oracleContext: oracleContext,
            strategyContext: strategyContext,
            balances: balances,
            invariant: invariant
        });
    }

    /// @notice Gets the time-weighted primary token balance for a given bptAmount
    /// @dev Boosted pool can't use the Balancer oracle, using Chainlink instead
    /// @param poolContext pool context variables
    /// @param oracleContext oracle context variables
    /// @param bptAmount amount of balancer pool lp tokens
    /// @return primaryAmount primary token balance
    function _getTimeWeightedPrimaryBalance(
        Balancer3TokenPoolContext memory poolContext,
        BoostedOracleContext memory oracleContext,
        StrategyContext memory strategyContext,
        uint256 bptAmount
    ) internal view returns (uint256 primaryAmount) {
        (
           uint256[] memory balances, 
           uint256 invariant
        ) = _getValidatedPoolData(poolContext, oracleContext, strategyContext);

        // NOTE: For Boosted 3 token pools, the LP token (BPT) is just another
        // token in the pool. So, we first use _calcTokenOutGivenExactBptIn
        // to calculate the value of 1 BPT. Then, we scale it to the BPT
        // amount to get the value in terms of the primary currency.
        // Use virtual total supply and zero swap fees for joins
        uint256 linearBPTAmount = StableMath._calcTokenOutGivenExactBptIn({
            amp: oracleContext.ampParam, 
            balances: balances, 
            tokenIndex: 0, // Primary index
            bptAmountIn: BalancerConstants.BALANCER_PRECISION, // 1 BPT 
            bptTotalSupply: oracleContext.virtualSupply, 
            swapFeePercentage: oracleContext.swapFeePercentage, 
            currentInvariant: invariant
        });

        // Downscale BPT out
        linearBPTAmount = linearBPTAmount * BalancerConstants.BALANCER_PRECISION / poolContext.primaryScaleFactor;

        // Primary underlying pool = index 0
        primaryAmount = _getUnderlyingMainOut(oracleContext.underlyingPools[0], linearBPTAmount);

        uint256 primaryPrecision = 10 ** poolContext.basePool.basePool.primaryDecimals;
        primaryAmount = (primaryAmount * bptAmount * primaryPrecision) / BalancerConstants.BALANCER_PRECISION_SQUARED;
    }

    function _approveBalancerTokens(ThreeTokenPoolContext memory poolContext, address bptSpender) internal {
        poolContext.basePool._approveBalancerTokens(bptSpender);

        IERC20(poolContext.tertiaryToken).checkApprove(address(Deployments.BALANCER_VAULT), type(uint256).max);

        // For boosted pools, the tokens inside pool context are AaveLinearPool tokens.
        // So, we need to approve the _underlyingToken (primary borrow currency) for trading.
        ILinearPool underlyingPool = ILinearPool(poolContext.basePool.primaryToken);
        address primaryUnderlyingAddress = BalancerUtils.getTokenAddress(underlyingPool.getMainToken());
        IERC20(primaryUnderlyingAddress).checkApprove(address(Deployments.BALANCER_VAULT), type(uint256).max);
    }

    function _joinPoolExactTokensIn(Balancer3TokenPoolContext memory context, uint256 primaryAmount, uint256 minBPT)
        private returns (uint256 bptAmount) {
        ILinearPool underlyingPool = ILinearPool(address(context.basePool.basePool.primaryToken));

        // Swap underlyingToken for LinearPool BPT
        uint256 linearPoolBPT = BalancerUtils._swapGivenIn({
            poolId: underlyingPool.getPoolId(),
            tokenIn: underlyingPool.getMainToken(),
            tokenOut: address(underlyingPool),
            amountIn: primaryAmount,
            limit: 0 // slippage checked on the second swap
        });

        // Swap LinearPool BPT for Boosted BPT
        bptAmount = BalancerUtils._swapGivenIn({
            poolId: context.poolId,
            tokenIn: address(underlyingPool),
            tokenOut: address(context.basePool.basePool.poolToken), // Boosted pool
            amountIn: linearPoolBPT,
            limit: minBPT
        });
    }

    function _exitPoolExactBPTIn(Balancer3TokenPoolContext memory context, uint256 bptExitAmount, uint256 minPrimary)
        private returns (uint256 primaryBalance) {
        ILinearPool underlyingPool = ILinearPool(address(context.basePool.basePool.primaryToken));

        // Swap Boosted BPT for LinearPool BPT
        uint256 linearPoolBPT = BalancerUtils._swapGivenIn({
            poolId: context.poolId,
            tokenIn: address(context.basePool.basePool.poolToken), // Boosted pool
            tokenOut: address(underlyingPool),
            amountIn: bptExitAmount,
            limit: 0 // slippage checked on the second swap
        });

        // Swap LinearPool BPT for underlyingToken
        primaryBalance = BalancerUtils._swapGivenIn({
            poolId: underlyingPool.getPoolId(),
            tokenIn: address(underlyingPool),
            tokenOut: underlyingPool.getMainToken(),
            amountIn: linearPoolBPT,
            limit: minPrimary
        }); 
    }

    function _deposit(
        Balancer3TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        BoostedOracleContext memory oracleContext,
        uint256 deposit,
        uint256 minBPT
    ) internal returns (uint256 strategyTokensMinted) {
        uint256 bptMinted = poolContext._joinPoolAndStake({
            strategyContext: strategyContext,
            stakingContext: stakingContext,
            oracleContext: oracleContext,
            deposit: deposit,
            minBPT: minBPT
        });

        strategyTokensMinted = strategyContext._mintStrategyTokens(bptMinted);
    }

    function _redeem(
        Balancer3TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        uint256 strategyTokens,
        uint256 minPrimary
    ) internal returns (uint256 finalPrimaryBalance) {
        uint256 bptClaim = strategyContext._redeemStrategyTokens(strategyTokens);

        finalPrimaryBalance = _unstakeAndExitPool({
            stakingContext: stakingContext,
            poolContext: poolContext,
            bptClaim: bptClaim,
            minPrimary: minPrimary
        });
    }

    function _joinPoolAndStake(
        Balancer3TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        BoostedOracleContext memory oracleContext,
        uint256 deposit,
        uint256 minBPT
    ) internal returns (uint256 bptMinted) {
        bptMinted = _joinPoolExactTokensIn(poolContext, deposit, minBPT);

        // Check BPT threshold to make sure our share of the pool is
        // below maxPoolShare
        uint256 bptThreshold = strategyContext.vaultSettings._poolClaimThreshold(
            oracleContext.virtualSupply
        );
        uint256 bptHeldAfterJoin = strategyContext.vaultState.totalPoolClaim + bptMinted;
        if (bptHeldAfterJoin > bptThreshold)
            revert Errors.PoolShareTooHigh(bptHeldAfterJoin, bptThreshold);

        // Transfer token to Aura protocol for boosted staking
        bool success = IAuraBoosterBase(stakingContext.booster).deposit(stakingContext.poolId, bptMinted, true); // stake = true
        if (!success) revert Errors.StakeFailed();
    }

    function _unstakeAndExitPool(
        Balancer3TokenPoolContext memory poolContext,
        AuraStakingContext memory stakingContext,
        uint256 bptClaim,
        uint256 minPrimary
    ) internal returns (uint256 primaryBalance) {
        // Withdraw BPT tokens back to the vault for redemption
        bool success = stakingContext.rewardPool.withdrawAndUnwrap(bptClaim, false); // claimRewards = false
        if (!success) revert Errors.UnstakeFailed();

        primaryBalance = _exitPoolExactBPTIn(poolContext, bptClaim, minPrimary); 
    }

    /// @notice We value strategy tokens in terms of the primary balance. The time weighted
    /// primary balance is used in order to prevent pool manipulation.
    /// @param poolContext pool context variables
    /// @param oracleContext oracle context variables
    /// @param strategyTokenAmount amount of strategy tokens
    /// @return underlyingValue underlying value of strategy tokens
    function _convertStrategyToUnderlying(
        Balancer3TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        BoostedOracleContext memory oracleContext,
        uint256 strategyTokenAmount
    ) internal view returns (int256 underlyingValue) {
        uint256 bptClaim = strategyContext._convertStrategyTokensToPoolClaim(strategyTokenAmount);

        underlyingValue = poolContext._getTimeWeightedPrimaryBalance(
            oracleContext, strategyContext, bptClaim
        ).toInt();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IBalancerVault, IAsset} from "../../../../../interfaces/balancer/IBalancerVault.sol";
import {PoolParams} from "../../BalancerVaultTypes.sol";
import {Constants} from "../../../../global/Constants.sol";
import {Deployments} from "../../../../global/Deployments.sol";
import {BalancerConstants} from "../BalancerConstants.sol";
import {TokenUtils, IERC20} from "../../../../utils/TokenUtils.sol";

library BalancerUtils {
    using TokenUtils for IERC20;

    /// @notice Special handling for ETH because UNDERLYING_TOKEN == address(0)
    /// and Balancer uses WETH
    function getTokenAddress(address token) internal pure returns (address) {
        return token == Deployments.ETH_ADDRESS ? address(Deployments.WETH) : address(token);
    }

    /// @notice Normalizes balances to 1e18 (used by Balancer price oracle functions)
    function _normalizeBalances(
        uint256 primaryBalance,
        uint8 primaryDecimals,
        uint256 secondaryBalance,
        uint8 secondaryDecimals
    ) internal pure returns (uint256 normalizedPrimary, uint256 normalizedSecondary) {
        if (primaryDecimals == 18) {
            normalizedPrimary = primaryBalance;
        } else {
            uint256 decimalAdjust;
            unchecked {
                decimalAdjust = 10**(18 - primaryDecimals);
            }
            normalizedPrimary = primaryBalance * decimalAdjust;
        }

        if (secondaryDecimals == 18) {
            normalizedSecondary = secondaryBalance;
        } else {
            uint256 decimalAdjust;
            unchecked {
                decimalAdjust = 10**(18 - secondaryDecimals);
            }
            normalizedSecondary = secondaryBalance * decimalAdjust;
        }
    }

    /// @notice Joins a balancer pool using exact tokens in
    function _joinPoolExactTokensIn(
        bytes32 poolId,
        IERC20 poolToken,
        PoolParams memory params,
        uint256 minBPT
    ) internal returns (uint256 bptAmount) {
        bptAmount = poolToken.balanceOf(address(this));
        Deployments.BALANCER_VAULT.joinPool{value: params.msgValue}(
            poolId,
            address(this),
            address(this),
            IBalancerVault.JoinPoolRequest(
                params.assets,
                params.amounts,
                abi.encode(
                    IBalancerVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                    params.amounts,
                    minBPT // Apply minBPT to prevent front running
                ),
                false // Don't use internal balances
            )
        );
        bptAmount = poolToken.balanceOf(address(this)) - bptAmount;
    }

    /// @notice Exits a balancer pool using exact BPT in
    function _exitPoolExactBPTIn(
        bytes32 poolId,
        IERC20 poolToken,
        PoolParams memory params,
        uint256 bptExitAmount
    ) internal returns (uint256[] memory exitBalances) {
        uint256 numAssets = params.assets.length;
        exitBalances = new uint256[](numAssets);

        for (uint256 i; i < numAssets; i++) {
            exitBalances[i] = TokenUtils.tokenBalance(address(params.assets[i]));
        }

        Deployments.BALANCER_VAULT.exitPool(
            poolId,
            address(this),
            payable(address(this)), // Vault will receive the underlying assets
            IBalancerVault.ExitPoolRequest(
                params.assets,
                params.amounts,
                params.customData,
                false // Don't use internal balances
            )
        );

        for (uint256 i; i < numAssets; i++) {
            exitBalances[i] = TokenUtils.tokenBalance(address(params.assets[i])) - exitBalances[i];
        }
    }

    function _swapGivenIn(
        bytes32 poolId,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 limit
    ) internal returns (uint256 amountOut) {
        amountOut = IERC20(tokenOut).balanceOf(address(this));
        Deployments.BALANCER_VAULT.swap({
            singleSwap: IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(tokenIn),
                assetOut: IAsset(tokenOut),
                amount: amountIn,
                userData: new bytes(0)
            }),
            funds: IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            limit: limit,
            deadline: block.timestamp
        });
        amountOut = IERC20(tokenOut).balanceOf(address(this)) - amountOut;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    ThreeTokenPoolContext, 
    ReinvestRewardParams, 
    SingleSidedRewardTradeParams,
    StrategyContext
} from "../../../common/VaultTypes.sol";
import {VaultEvents} from "../../../common/VaultEvents.sol";
import {Errors} from "../../../../global/Errors.sol";
import {BalancerConstants} from "../BalancerConstants.sol";
import {Balancer3TokenBoostedPoolUtils} from "../pool/Balancer3TokenBoostedPoolUtils.sol";
import {StrategyUtils} from "../../../common/internal/strategy/StrategyUtils.sol";
import {RewardUtils} from "../../../common/internal/reward/RewardUtils.sol";
import {ILinearPool} from "../../../../../interfaces/balancer/IBalancerPool.sol";
import {IERC20} from "../../../../../interfaces/IERC20.sol";

library Boosted3TokenAuraRewardUtils {
    using StrategyUtils for StrategyContext;

    function _validateTrade(
        IERC20[] memory rewardTokens,
        SingleSidedRewardTradeParams memory params,
        address primaryToken
    ) private view {
        // Validate trades
        if (!RewardUtils._isValidRewardToken(rewardTokens, params.sellToken)) {
            revert Errors.InvalidRewardToken(params.sellToken);
        }
        if (params.buyToken != ILinearPool(primaryToken).getMainToken()) {
            revert Errors.InvalidRewardToken(params.buyToken);
        }
    }

    function _executeRewardTrades(
        ThreeTokenPoolContext calldata poolContext,
        StrategyContext memory strategyContext,
        IERC20[] memory rewardTokens,
        bytes calldata data
    ) internal returns (address rewardToken, uint256 primaryAmount) {
        SingleSidedRewardTradeParams memory params = abi.decode(data, (SingleSidedRewardTradeParams));

        _validateTrade(rewardTokens, params, poolContext.basePool.primaryToken);

        (/*uint256 amountSold*/, primaryAmount) = strategyContext._executeTradeExactIn({
            params: params.tradeParams,
            sellToken: params.sellToken,
            buyToken: params.buyToken,
            amount: params.amount,
            useDynamicSlippage: false
        });

        rewardToken = params.sellToken;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {AuraStakingContext, AuraVaultDeploymentParams} from "../BalancerVaultTypes.sol";
import {ILiquidityGauge} from "../../../../interfaces/balancer/ILiquidityGauge.sol";
import {IAuraBooster, IAuraBoosterLite} from "../../../../interfaces/aura/IAuraBooster.sol";
import {IAuraRewardPool, IAuraL2Coordinator} from "../../../../interfaces/aura/IAuraRewardPool.sol";
import {IAuraStakingProxy} from "../../../../interfaces/aura/IAuraStakingProxy.sol";
import {TokenUtils, IERC20} from "../../../utils/TokenUtils.sol";
import {Deployments} from "../../../global/Deployments.sol";
import {Constants} from "../../../global/Constants.sol";
import {NotionalProxy} from "../../../../interfaces/notional/NotionalProxy.sol";
import {BalancerConstants} from "../internal/BalancerConstants.sol";
import {RewardUtils} from "../../common/internal/reward/RewardUtils.sol";
import {VaultEvents} from "../../common/VaultEvents.sol";
import {VaultBase} from "../../common/VaultBase.sol";

abstract contract AuraStakingMixin is VaultBase {
    using TokenUtils for IERC20;

    /// @notice Balancer liquidity gauge used to get a list of reward tokens
    ILiquidityGauge internal immutable LIQUIDITY_GAUGE;
    /// @notice Aura booster contract used for staking BPT
    address internal immutable AURA_BOOSTER;
    /// @notice Aura reward pool contract used for unstaking and claiming reward tokens
    IAuraRewardPool internal immutable AURA_REWARD_POOL;
    uint256 internal immutable AURA_POOL_ID;
    IERC20 internal immutable BAL_TOKEN;
    IERC20 internal immutable AURA_TOKEN;

    constructor(NotionalProxy notional_, AuraVaultDeploymentParams memory params) 
        VaultBase(notional_, params.baseParams.tradingModule) {
        LIQUIDITY_GAUGE = params.baseParams.liquidityGauge;
        AURA_REWARD_POOL = params.rewardPool;

        AURA_BOOSTER = AURA_REWARD_POOL.operator();
        AURA_POOL_ID = AURA_REWARD_POOL.pid();

        IERC20 balToken;
        IERC20 auraToken;

        if (Deployments.CHAIN_ID == Constants.CHAIN_ID_MAINNET) {
            IAuraStakingProxy stakingProxy = IAuraStakingProxy(IAuraBooster(AURA_BOOSTER).stakerRewards());

            balToken = IERC20(stakingProxy.crv());
            auraToken = IERC20(stakingProxy.cvx());
        } else if (Deployments.CHAIN_ID == Constants.CHAIN_ID_ARBITRUM) {
            IAuraBoosterLite booster = IAuraBoosterLite(AURA_BOOSTER);
            IAuraL2Coordinator rewards = IAuraL2Coordinator(booster.rewards());

            balToken = IERC20(booster.crv());
            auraToken = IERC20(rewards.auraOFT());
        } else {
            revert();
        }

        BAL_TOKEN = balToken;
        AURA_TOKEN = auraToken;
    }

    function _rewardTokens() private view returns (IERC20[] memory tokens) {
        uint256 rewardTokenCount = LIQUIDITY_GAUGE.reward_count() + 2;
        tokens = new IERC20[](rewardTokenCount);
        tokens[0] = BAL_TOKEN;
        tokens[1] = AURA_TOKEN;
        for (uint256 i = 2; i < rewardTokenCount; i++) {
            tokens[i] = IERC20(LIQUIDITY_GAUGE.reward_tokens(i - 2));
        }
    }

    function _auraStakingContext() internal view returns (AuraStakingContext memory) {
        return AuraStakingContext({
            liquidityGauge: LIQUIDITY_GAUGE,
            booster: AURA_BOOSTER,
            rewardPool: AURA_REWARD_POOL,
            poolId: AURA_POOL_ID,
            rewardTokens: _rewardTokens()
        });
    }

    function _claimAuraRewardTokens() internal returns (bool) {
        return AURA_REWARD_POOL.getReward(address(this), true); // claimExtraRewards = true
    }

    function claimRewardTokens()
        external onlyRole(REWARD_REINVESTMENT_ROLE) returns (
        IERC20[] memory rewardTokens,
        uint256[] memory claimedBalances
    ) {
        rewardTokens = _rewardTokens();
        claimedBalances = RewardUtils._claimRewardTokens(_claimAuraRewardTokens, rewardTokens);
    }

    uint256[40] private __gap; // Storage gap for future potential upgrades
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {IERC20} from "../../../../interfaces/IERC20.sol";
import {StrategyContext} from "../../common/VaultTypes.sol";
import {AuraVaultDeploymentParams} from "../BalancerVaultTypes.sol";
import {Deployments} from "../../../global/Deployments.sol";
import {NotionalProxy} from "../../../../interfaces/notional/NotionalProxy.sol";
import {IBalancerVault} from "../../../../interfaces/balancer/IBalancerVault.sol";
import {AuraStakingMixin} from "./AuraStakingMixin.sol";
import {VaultStorage} from "../../common/VaultStorage.sol";
import {StrategyUtils} from "../../common/internal/strategy/StrategyUtils.sol";
import {BalancerConstants} from "../internal/BalancerConstants.sol";

abstract contract BalancerPoolMixin is AuraStakingMixin {
    using StrategyUtils for StrategyContext;

    bytes32 internal immutable BALANCER_POOL_ID;
    IERC20 internal immutable BALANCER_POOL_TOKEN;

    constructor(NotionalProxy notional_, AuraVaultDeploymentParams memory params) 
        AuraStakingMixin(notional_, params) {
        BALANCER_POOL_ID = params.baseParams.balancerPoolId;
        (address pool, /* */) = Deployments.BALANCER_VAULT.getPool(params.baseParams.balancerPoolId);
        BALANCER_POOL_TOKEN = IERC20(pool);
    }

    function _checkReentrancyContext() internal override {
        IBalancerVault.UserBalanceOp[] memory noop = new IBalancerVault.UserBalanceOp[](0);
        Deployments.BALANCER_VAULT.manageUserBalance(noop);
    }

    function _baseStrategyContext() internal view returns(StrategyContext memory) {
        return StrategyContext({
            tradingModule: TRADING_MODULE,
            vaultSettings: VaultStorage.getStrategyVaultSettings(),
            vaultState: VaultStorage.getStrategyVaultState(),
            poolClaimPrecision: BalancerConstants.BALANCER_PRECISION,
            canUseStaticSlippage: _canUseStaticSlippage()
        });
    }

    /// @notice Converts pool claim to strategy tokens
    function convertPoolClaimToStrategyTokens(uint256 poolClaim)
        external view returns (uint256 strategyTokenAmount) {
        return _baseStrategyContext()._convertPoolClaimToStrategyTokens(poolClaim);
    }

    /// @notice Converts strategy tokens to pool claim
    function convertStrategyTokensToPoolClaim(uint256 strategyTokenAmount) 
        external view returns (uint256 poolClaim) {
        return _baseStrategyContext()._convertStrategyTokensToPoolClaim(strategyTokenAmount);
    }

    uint256[40] private __gap; // Storage gap for future potential upgrades
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    Balancer3TokenPoolContext, 
    Balancer2TokenPoolContext, 
    BoostedOracleContext,
    UnderlyingPoolContext,
    AuraVaultDeploymentParams,
    Boosted3TokenAuraStrategyContext,
    AuraStakingContext
} from "../BalancerVaultTypes.sol";
import {
    StrategyContext, 
    TwoTokenPoolContext, 
    ThreeTokenPoolContext
} from "../../common/VaultTypes.sol";
import {Constants} from "../../../global/Constants.sol";
import {TypeConvert} from "../../../global/TypeConvert.sol";
import {IERC20} from "../../../../interfaces/IERC20.sol";
import {ISingleSidedLPStrategyVault} from "../../../../interfaces/notional/IStrategyVault.sol";
import {BalancerConstants} from "../internal/BalancerConstants.sol";
import {IBalancerPool, IBoostedPool, ILinearPool} from "../../../../interfaces/balancer/IBalancerPool.sol";
import {BalancerUtils} from "../internal/pool/BalancerUtils.sol";
import {Deployments} from "../../../global/Deployments.sol";
import {BalancerPoolMixin} from "./BalancerPoolMixin.sol";
import {NotionalProxy} from "../../../../interfaces/notional/NotionalProxy.sol";
import {StableMath} from "../internal/math/StableMath.sol";
import {Boosted3TokenAuraHelper} from "../external/Boosted3TokenAuraHelper.sol";

abstract contract Boosted3TokenPoolMixin is BalancerPoolMixin, ISingleSidedLPStrategyVault {
    using TypeConvert for uint256;

    error InvalidPrimaryToken(address token);

    uint8 internal constant NOT_FOUND = type(uint8).max;

    address internal immutable PRIMARY_TOKEN;
    address internal immutable SECONDARY_TOKEN;
    address internal immutable TERTIARY_TOKEN;
    uint8 internal immutable PRIMARY_INDEX;
    uint8 internal immutable SECONDARY_INDEX;
    uint8 internal immutable TERTIARY_INDEX;
    uint8 internal immutable BPT_INDEX;
    uint8 internal immutable PRIMARY_DECIMALS;
    uint8 internal immutable SECONDARY_DECIMALS;
    uint8 internal immutable TERTIARY_DECIMALS;

    constructor(
        NotionalProxy notional_, 
        AuraVaultDeploymentParams memory params
    ) BalancerPoolMixin(notional_, params) {
        address primaryAddress = BalancerUtils.getTokenAddress(
            _getNotionalUnderlyingToken(params.baseParams.primaryBorrowCurrencyId)
        );
        
        // prettier-ignore
        (
            address[] memory tokens,
            /* uint256[] memory balances */,
            /* uint256 lastChangeBlock */
        ) = Deployments.BALANCER_VAULT.getPoolTokens(params.baseParams.balancerPoolId);

        // Boosted pools contain 4 tokens (3 LinearPool LP tokens + 1 BoostedPool LP token)
        require(tokens.length == 4);

        uint8 primaryIndex = NOT_FOUND;
        uint8 secondaryIndex = NOT_FOUND;
        uint8 tertiaryIndex = NOT_FOUND;
        uint8 bptIndex = NOT_FOUND;
        for (uint256 i; i < 4; i++) {
            // Skip pool token
            if (tokens[i] == address(BALANCER_POOL_TOKEN)) {
                bptIndex = uint8(i);
            } else if (ILinearPool(tokens[i]).getMainToken() == primaryAddress) {
                primaryIndex = uint8(i);
            } else {
                if (secondaryIndex == NOT_FOUND) {
                    secondaryIndex = uint8(i);
                } else {
                    tertiaryIndex = uint8(i);
                }
            }
        }

        require(primaryIndex != NOT_FOUND);

        PRIMARY_INDEX = primaryIndex;
        SECONDARY_INDEX = secondaryIndex;
        TERTIARY_INDEX = tertiaryIndex;
        BPT_INDEX = bptIndex;

        PRIMARY_TOKEN = tokens[PRIMARY_INDEX];
        SECONDARY_TOKEN = tokens[SECONDARY_INDEX];
        TERTIARY_TOKEN = tokens[TERTIARY_INDEX];

        uint256 primaryDecimals = IERC20(ILinearPool(PRIMARY_TOKEN).getMainToken()).decimals();

        // Do not allow decimal places greater than 18
        require(primaryDecimals <= 18);
        PRIMARY_DECIMALS = uint8(primaryDecimals);

        // If the SECONDARY_TOKEN is ETH, it will be rewritten as WETH
        uint256 secondaryDecimals = IERC20(ILinearPool(SECONDARY_TOKEN).getMainToken()).decimals();

        // Do not allow decimal places greater than 18
        require(secondaryDecimals <= 18);
        SECONDARY_DECIMALS = uint8(secondaryDecimals);
        
        // If the TERTIARY_TOKEN is ETH, it will be rewritten as WETH
        uint256 tertiaryDecimals = IERC20(ILinearPool(TERTIARY_TOKEN).getMainToken()).decimals();

        // Do not allow decimal places greater than 18
        require(tertiaryDecimals <= 18);
        TERTIARY_DECIMALS = uint8(tertiaryDecimals);
    }

    function _underlyingPoolContext(ILinearPool underlyingPool) private view returns (UnderlyingPoolContext memory) {
        (uint256 lowerTarget, uint256 upperTarget) = underlyingPool.getTargets();
        uint256 mainIndex = underlyingPool.getMainIndex();
        uint256 wrappedIndex = underlyingPool.getWrappedIndex();

        (
            /* address[] memory tokens */,
            uint256[] memory underlyingBalances,
            /* uint256 lastChangeBlock */
        ) = Deployments.BALANCER_VAULT.getPoolTokens(underlyingPool.getPoolId());

        uint256[] memory underlyingScalingFactors = underlyingPool.getScalingFactors();

        return UnderlyingPoolContext({
            mainScaleFactor: underlyingScalingFactors[mainIndex],
            mainBalance: underlyingBalances[mainIndex],
            wrappedScaleFactor: underlyingScalingFactors[wrappedIndex],
            wrappedBalance: underlyingBalances[wrappedIndex],
            virtualSupply: underlyingPool.getVirtualSupply(),
            fee: underlyingPool.getSwapFeePercentage(),
            lowerTarget: lowerTarget,
            upperTarget: upperTarget    
        });
    }

    function _boostedOracleContext(uint256[] memory balances) 
        internal view returns (BoostedOracleContext memory boostedPoolContext) {
        IBoostedPool pool = IBoostedPool(address(BALANCER_POOL_TOKEN));

        (
            uint256 value,
            /* bool isUpdating */,
            uint256 precision
        ) = pool.getAmplificationParameter();
        require(precision == StableMath._AMP_PRECISION);

        boostedPoolContext = BoostedOracleContext({
            ampParam: value,
            bptBalance: balances[BPT_INDEX],
            swapFeePercentage: pool.getSwapFeePercentage(),
            virtualSupply: pool.getActualSupply(),
            underlyingPools: new UnderlyingPoolContext[](3)
        });

        boostedPoolContext.underlyingPools[0] = _underlyingPoolContext(ILinearPool(PRIMARY_TOKEN));
        boostedPoolContext.underlyingPools[1] = _underlyingPoolContext(ILinearPool(SECONDARY_TOKEN));
        boostedPoolContext.underlyingPools[2] = _underlyingPoolContext(ILinearPool(TERTIARY_TOKEN));
    }

    function _threeTokenPoolContext(uint256[] memory balances, uint256[] memory scalingFactors) 
        internal view returns (Balancer3TokenPoolContext memory) {
        return Balancer3TokenPoolContext({
            basePool: ThreeTokenPoolContext({
                basePool: TwoTokenPoolContext({
                    primaryToken: PRIMARY_TOKEN,
                    secondaryToken: SECONDARY_TOKEN,
                    primaryIndex: PRIMARY_INDEX,
                    secondaryIndex: SECONDARY_INDEX,
                    primaryDecimals: PRIMARY_DECIMALS,
                    secondaryDecimals: SECONDARY_DECIMALS,
                    primaryBalance: balances[PRIMARY_INDEX],
                    secondaryBalance: balances[SECONDARY_INDEX],
                    poolToken: BALANCER_POOL_TOKEN
                }),
                tertiaryToken: TERTIARY_TOKEN,
                tertiaryIndex: TERTIARY_INDEX,
                tertiaryDecimals: TERTIARY_DECIMALS,
                tertiaryBalance: balances[TERTIARY_INDEX]
            }),
            primaryScaleFactor: scalingFactors[PRIMARY_INDEX],
            secondaryScaleFactor: scalingFactors[SECONDARY_INDEX],
            tertiaryScaleFactor: scalingFactors[TERTIARY_INDEX],
            poolId: BALANCER_POOL_ID
        });
    }

    function _strategyContext() internal view returns (Boosted3TokenAuraStrategyContext memory) {
        (uint256[] memory balances, uint256[] memory scalingFactors) = _getBalancesAndScaleFactors();

        BoostedOracleContext memory oracleContext = _boostedOracleContext(balances);

        return Boosted3TokenAuraStrategyContext({
            poolContext: _threeTokenPoolContext(balances, scalingFactors),
            oracleContext: oracleContext,
            stakingContext: _auraStakingContext(),
            baseStrategy: _baseStrategyContext()
        });
    }

    function _getBalancesAndScaleFactors() internal view returns (uint256[] memory balances, uint256[] memory scalingFactors) {
        (
            /* address[] memory tokens */,
            balances,
            /* uint256 lastChangeBlock */
        ) = Deployments.BALANCER_VAULT.getPoolTokens(BALANCER_POOL_ID);

        scalingFactors = IBalancerPool(address(BALANCER_POOL_TOKEN)).getScalingFactors();
    }

    function getExchangeRate(uint256 /* maturity */) public view override returns (int256) {
        Boosted3TokenAuraStrategyContext memory context = _strategyContext();
        return Boosted3TokenAuraHelper.getExchangeRate(context);
    }

    function getStrategyVaultInfo() public view override returns (SingleSidedLPStrategyVaultInfo memory) {
        StrategyContext memory context = _baseStrategyContext();
        return SingleSidedLPStrategyVaultInfo({
            pool: address(BALANCER_POOL_TOKEN),
            singleSidedTokenIndex: PRIMARY_INDEX,
            totalLPTokens: context.vaultState.totalPoolClaim,
            totalVaultShares: context.vaultState.totalVaultSharesGlobal
        });
    }

    uint256[40] private __gap; // Storage gap for future potential upgrades
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {Token, TokenType} from "../global/Types.sol";
import {Deployments} from "../global/Deployments.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IStrategyVault} from "../../interfaces/notional/IStrategyVault.sol";
import {NotionalProxy} from "../../interfaces/notional/NotionalProxy.sol";
import {ITradingModule, Trade} from "../../interfaces/trading/ITradingModule.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {TokenUtils} from "../utils/TokenUtils.sol";
import {TradeHandler} from "../trading/TradeHandler.sol";
import {nProxy} from "../proxy/nProxy.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract BaseStrategyVault is Initializable, IStrategyVault, AccessControlUpgradeable {
    using TokenUtils for IERC20;
    using TradeHandler for Trade;

    bytes32 internal constant NORMAL_SETTLEMENT_ROLE = keccak256("NORMAL_SETTLEMENT_ROLE");
    bytes32 internal constant EMERGENCY_SETTLEMENT_ROLE = keccak256("EMERGENCY_SETTLEMENT_ROLE");
    bytes32 internal constant POST_MATURITY_SETTLEMENT_ROLE = keccak256("POST_MATURITY_SETTLEMENT_ROLE");
    bytes32 internal constant REWARD_REINVESTMENT_ROLE = keccak256("REWARD_REINVESTMENT_ROLE");
    bytes32 internal constant STATIC_SLIPPAGE_TRADING_ROLE = keccak256("STATIC_SLIPPAGE_TRADING_ROLE");

    /// @notice Hardcoded on the implementation contract during deployment
    NotionalProxy public immutable NOTIONAL;
    ITradingModule public immutable TRADING_MODULE;
    uint8 constant internal INTERNAL_TOKEN_DECIMALS = 8;

    // Borrowing Currency ID the vault is configured with
    uint16 private _BORROW_CURRENCY_ID;
    // True if the underlying is ETH
    bool private _UNDERLYING_IS_ETH;
    // Address of the underlying token
    IERC20 private _UNDERLYING_TOKEN;
    // NOTE: end of first storage slot here

    // Name of the vault
    string private _NAME;


    /**************************************************************************/
    /* Global Modifiers, Constructor and Initializer                          */
    /**************************************************************************/
    modifier onlyNotional() {
        require(msg.sender == address(NOTIONAL));
        _;
    }

    modifier onlyNotionalOwner() {
        require(msg.sender == address(NOTIONAL.owner()));
        _;
    }
    
    /// @notice Set the NOTIONAL address on deployment
    constructor(NotionalProxy notional_, ITradingModule tradingModule_) initializer {
        // Make sure we are using the correct Deployments lib
        uint256 chainId = 42161;
        //assembly { chainId := chainid() }
        require(Deployments.CHAIN_ID == chainId);

        NOTIONAL = notional_;
        TRADING_MODULE = tradingModule_;
    }

    /// @notice Override this method and revert if the contract should not receive ETH.
    /// Upgradeable proxies must have this implemented on the proxy for transfer calls
    /// succeed (use nProxy for this).
    receive() external virtual payable {
        // Allow ETH transfers to succeed
    }

    /// @notice All strategy vaults MUST implement 8 decimal precision
    function decimals() public override view returns (uint8) {
        return INTERNAL_TOKEN_DECIMALS;
    }

    function name() external override view returns (string memory) {
        return _NAME;
    }

    function strategy() external virtual view returns (bytes4);

    function _borrowCurrencyId() internal view returns (uint16) {
        return _BORROW_CURRENCY_ID;
    }

    function _underlyingToken() internal view returns (IERC20) {
        return _UNDERLYING_TOKEN;
    }

    function _isUnderlyingETH() internal view returns (bool) {
        return _UNDERLYING_IS_ETH;
    }

    /// @notice Can only be called once during initialization
    function __INIT_VAULT(
        string memory name_,
        uint16 borrowCurrencyId_
    ) internal onlyInitializing {
        _NAME = name_;
        _BORROW_CURRENCY_ID = borrowCurrencyId_;

        address underlyingAddress = _getNotionalUnderlyingToken(borrowCurrencyId_);
        _UNDERLYING_TOKEN = IERC20(underlyingAddress);
        _UNDERLYING_IS_ETH = underlyingAddress == address(0);
        _setupRole(DEFAULT_ADMIN_ROLE, NOTIONAL.owner());
    }

    function _getNotionalUnderlyingToken(uint16 currencyId) internal view returns (address) {
        (Token memory assetToken, Token memory underlyingToken) = NOTIONAL.getCurrency(currencyId);

        return assetToken.tokenType == TokenType.NonMintable ?
            assetToken.tokenAddress : underlyingToken.tokenAddress;
    }

    /// @notice Can be used to delegate call to the TradingModule's implementation in order to execute
    /// a trade.
    function _executeTrade(
        uint16 dexId,
        Trade memory trade
    ) internal returns (uint256 amountSold, uint256 amountBought) {
        return trade._executeTrade(dexId, TRADING_MODULE);
    }

    /**************************************************************************/
    /* Virtual Methods Requiring Implementation                               */
    /**************************************************************************/
    function convertStrategyToUnderlying(
        address account,
        uint256 vaultShares,
        uint256 maturity
    ) public view virtual returns (int256 underlyingValue);

    function getExchangeRate(uint256 maturity) external virtual view returns (int256);
    
    // Vaults need to implement these two methods
    function _depositFromNotional(
        address account,
        uint256 deposit,
        uint256 maturity,
        bytes calldata data
    ) internal virtual returns (uint256 vaultSharesMinted);

    function _redeemFromNotional(
        address account,
        uint256 vaultShares,
        uint256 maturity,
        bytes calldata data
    ) internal virtual returns (uint256 tokensFromRedeem);

    function _checkReentrancyContext() internal virtual;

    // This can be overridden if the vault borrows in a secondary currency, but reverts by default.
    function _repaySecondaryBorrowCallback(
        address token,  uint256 underlyingRequired, bytes calldata data
    ) internal virtual returns (bytes memory returnData) {
        revert();
    }

    /**************************************************************************/
    /* Default External Method Implementations                                */
    /**************************************************************************/
    function depositFromNotional(
        address account,
        uint256 deposit,
        uint256 maturity,
        bytes calldata data
    ) external payable onlyNotional returns (uint256 vaultSharesMinted) {
        return _depositFromNotional(account, deposit, maturity, data);
    }

    function redeemFromNotional(
        address account,
        address receiver,
        uint256 vaultShares,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) external onlyNotional returns (uint256 transferToReceiver) {
        uint256 borrowedCurrencyAmount = _redeemFromNotional(account, vaultShares, maturity, data);

        uint256 transferToNotional;
        if (account == address(this) || borrowedCurrencyAmount <= underlyingToRepayDebt) {
            // It may be the case that insufficient tokens were redeemed to repay the debt. If this
            // happens the Notional will attempt to recover the shortfall from the account directly.
            // This can happen if an account wants to reduce their leverage by paying off debt but
            // does not want to sell strategy tokens to do so.
            // The other situation would be that the vault is calling redemption to deleverage or
            // settle. In that case all tokens go back to Notional.
            transferToNotional = borrowedCurrencyAmount;
        } else {
            transferToNotional = underlyingToRepayDebt;
            unchecked { transferToReceiver = borrowedCurrencyAmount - underlyingToRepayDebt; }
        }

        if (_UNDERLYING_IS_ETH) {
            if (transferToReceiver > 0) payable(receiver).transfer(transferToReceiver);
            if (transferToNotional > 0) payable(address(NOTIONAL)).transfer(transferToNotional);
        } else {
            if (transferToReceiver > 0) _UNDERLYING_TOKEN.checkTransfer(receiver, transferToReceiver);
            if (transferToNotional > 0) _UNDERLYING_TOKEN.checkTransfer(address(NOTIONAL), transferToNotional);
        }
    }

    function repaySecondaryBorrowCallback(
        address token, uint256 underlyingRequired, bytes calldata data
    ) external onlyNotional returns (bytes memory returnData) {
        return _repaySecondaryBorrowCallback(token, underlyingRequired, data);
    }

    function deleverageAccount(
        address account,
        address vault,
        address liquidator,
        uint16 currencyIndex,
        int256 depositUnderlyingInternal
    ) external payable returns (uint256 vaultSharesFromLiquidation, int256 depositAmountPrimeCash) {
        require(msg.sender == liquidator);
        _checkReentrancyContext();
        return NOTIONAL.deleverageAccount{value: msg.value}(
            account, vault, liquidator, currencyIndex, depositUnderlyingInternal
        );
    }

    function getRoles() external view returns (StrategyVaultRoles memory) {
        return StrategyVaultRoles({
            normalSettlement: NORMAL_SETTLEMENT_ROLE,
            emergencySettlement: EMERGENCY_SETTLEMENT_ROLE,
            postMaturitySettlement: POST_MATURITY_SETTLEMENT_ROLE,
            rewardReinvestment: REWARD_REINVESTMENT_ROLE,
            staticSlippageTrading: STATIC_SLIPPAGE_TRADING_ROLE
        });
    }

    function _canUseStaticSlippage() internal view returns (bool) {
        return hasRole(STATIC_SLIPPAGE_TRADING_ROLE, msg.sender);
    }

    // Storage gap for future potential upgrades
    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {Errors} from "../global/Errors.sol";
import {Deployments} from "../global/Deployments.sol";
import {TokenUtils} from "../utils/TokenUtils.sol";
import {
    AuraVaultDeploymentParams,
    InitParams,
    Balancer3TokenPoolContext,
    Boosted3TokenAuraStrategyContext
} from "./balancer/BalancerVaultTypes.sol";
import {
    StrategyContext,
    StrategyVaultSettings,
    StrategyVaultState,
    ThreeTokenPoolContext,
    DepositParams,
    RedeemParams,
    ReinvestRewardParams
} from "./common/VaultTypes.sol";
import {StrategyUtils} from "./common/internal/strategy/StrategyUtils.sol";
import {BalancerConstants} from "./balancer/internal/BalancerConstants.sol";
import {Boosted3TokenPoolMixin} from "./balancer/mixins/Boosted3TokenPoolMixin.sol";
import {AuraStakingMixin} from "./balancer/mixins/AuraStakingMixin.sol";
import {NotionalProxy} from "../../interfaces/notional/NotionalProxy.sol";
import {VaultStorage} from "./common/VaultStorage.sol";
import {SettlementUtils} from "./common/internal/settlement/SettlementUtils.sol";
import {Balancer3TokenBoostedPoolUtils} from "./balancer/internal/pool/Balancer3TokenBoostedPoolUtils.sol";
import {Boosted3TokenAuraHelper} from "./balancer/external/Boosted3TokenAuraHelper.sol";
import {IBalancerPool} from "../../interfaces/balancer/IBalancerPool.sol";
import {IERC20} from "../../interfaces/IERC20.sol";

contract Boosted3TokenAuraVault is Boosted3TokenPoolMixin {
    using Balancer3TokenBoostedPoolUtils for Balancer3TokenPoolContext;
    using Balancer3TokenBoostedPoolUtils for ThreeTokenPoolContext;
    using StrategyUtils for StrategyContext;
    using VaultStorage for StrategyVaultState;
    using SettlementUtils for StrategyContext;
    using Boosted3TokenAuraHelper for Boosted3TokenAuraStrategyContext;

    constructor(NotionalProxy notional_, AuraVaultDeploymentParams memory params) 
        Boosted3TokenPoolMixin(notional_, params)
    {}

    function strategy() external override view returns (bytes4) {
        return bytes4(keccak256("Boosted3TokenAuraVault"));
    }

    function initialize(InitParams calldata params)
        external
        initializer
        onlyNotionalOwner
    {
        __INIT_VAULT(params.name, params.borrowCurrencyId);
        VaultStorage.setStrategyVaultSettings(params.settings);
        (uint256[] memory balances, uint256[] memory scalingFactors) = _getBalancesAndScaleFactors();

        _threeTokenPoolContext(balances, scalingFactors).basePool._approveBalancerTokens(
            address(_auraStakingContext().booster)
        );
    }

    function _depositFromNotional(
        address /* account */,
        uint256 deposit,
        uint256 maturity,
        bytes calldata data
    ) internal override whenNotLocked returns (uint256 vaultSharesMinted) {
        vaultSharesMinted = _strategyContext().deposit(deposit, data);
    }

    function _redeemFromNotional(
        address account,
        uint256 vaultShares,
        uint256 maturity,
        bytes calldata data
    ) internal override whenNotLocked returns (uint256 finalPrimaryBalance) {
        finalPrimaryBalance = _strategyContext().redeem(vaultShares, data);
    }

    function settleVaultEmergency(uint256 maturity, bytes calldata data) 
        external whenNotLocked onlyRole(EMERGENCY_SETTLEMENT_ROLE) {
        Boosted3TokenAuraHelper.settleVaultEmergency(
            _strategyContext(), maturity, data
        );
        _lockVault();
    }

    function restoreVault(uint256 minBPT) external whenLocked onlyNotionalOwner {
        Boosted3TokenAuraStrategyContext memory context = _strategyContext();

        uint256 bptAmount = context.poolContext._joinPoolAndStake({
            strategyContext: context.baseStrategy,
            stakingContext: context.stakingContext,
            oracleContext: context.oracleContext,
            deposit: TokenUtils.tokenBalance(PRIMARY_TOKEN),
            minBPT: minBPT
        });

        context.baseStrategy.vaultState.totalPoolClaim += bptAmount;
        context.baseStrategy.vaultState.setStrategyVaultState(); 

        _unlockVault();
    }

    function reinvestReward(ReinvestRewardParams calldata params) 
        external whenNotLocked onlyRole(REWARD_REINVESTMENT_ROLE) returns (
            address rewardToken,
            uint256 primaryAmount,
            uint256 secondaryAmount,
            uint256 poolClaimAmount
    ) {
        return Boosted3TokenAuraHelper.reinvestReward(_strategyContext(), params);
    }

    function convertStrategyToUnderlying(
        address account,
        uint256 vaultShares,
        uint256 maturity
    ) public view virtual override whenNotLocked returns (int256 underlyingValue) {
        Boosted3TokenAuraStrategyContext memory context = _strategyContext();
        underlyingValue = context.convertStrategyToUnderlying(vaultShares);
    }

    /// @notice Updates the vault settings
    /// @param settings vault settings
    function setStrategyVaultSettings(StrategyVaultSettings calldata settings)
        external
        onlyNotionalOwner
    {
        VaultStorage.setStrategyVaultSettings(settings);
    }
    
    function getStrategyContext() external view returns (Boosted3TokenAuraStrategyContext memory) {
        return _strategyContext();
    }

    function getSpotPrice(uint8 tokenIndex) external view returns (uint256 spotPrice) {
        Boosted3TokenAuraStrategyContext memory context = _strategyContext();
        spotPrice = Boosted3TokenAuraHelper.getSpotPrice(context, tokenIndex);
    }

    function getEmergencySettlementPoolClaimAmount(uint256 maturity) external view returns (uint256 poolClaimToSettle) {
        Boosted3TokenAuraStrategyContext memory context = _strategyContext();
        poolClaimToSettle = context.baseStrategy._getEmergencySettlementParams({
            maturity: maturity, 
            totalPoolSupply: context.oracleContext.virtualSupply
        });
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    TwoTokenPoolContext, 
    StrategyContext, 
    DepositTradeParams, 
    TradeParams,
    SingleSidedRewardTradeParams,
    Proportional2TokenRewardTradeParams,
    RedeemParams
} from "../../VaultTypes.sol";
import {VaultConstants} from "../../VaultConstants.sol";
import {StrategyUtils} from "../strategy/StrategyUtils.sol";
import {RewardUtils} from "../reward/RewardUtils.sol";
import {Errors} from "../../../../global/Errors.sol";
import {ITradingModule, DexId} from "../../../../../interfaces/trading/ITradingModule.sol";
import {IERC20} from "../../../../../interfaces/IERC20.sol";

library TwoTokenPoolUtils {
    using StrategyUtils for StrategyContext;

    /// @notice Gets the oracle price pair price between two tokens using a weighted
    /// average between a chainlink oracle and the balancer TWAP oracle.
    /// @param poolContext oracle context variables
    /// @param strategyContext strategy context variables
    /// @return oraclePairPrice oracle price for the pair in 18 decimals
    function _getOraclePairPrice(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext
    ) internal view returns (uint256 oraclePairPrice) {
        (int256 rate, int256 decimals) = strategyContext.tradingModule.getOraclePrice(
            poolContext.primaryToken, poolContext.secondaryToken
        );
        require(rate > 0);
        require(decimals >= 0);

        if (uint256(decimals) != strategyContext.poolClaimPrecision) {
            rate = (rate * int256(strategyContext.poolClaimPrecision)) / decimals;
        }

        // No overflow in rate conversion, checked above
        oraclePairPrice = uint256(rate);
    }

    /// @notice calculates the expected primary and secondary amounts based on
    /// the given spot price and oracle price
    function _getMinExitAmounts(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        uint256 spotPrice,
        uint256 oraclePrice,
        uint256 poolClaim
    ) internal view returns (uint256 minPrimary, uint256 minSecondary) {
        strategyContext._checkPriceLimit(oraclePrice, spotPrice);

        // min amounts are calculated based on the share of the Balancer pool with a small discount applied
        uint256 totalPoolSupply = poolContext.poolToken.totalSupply();
        minPrimary = (poolContext.primaryBalance * poolClaim * 
            strategyContext.vaultSettings.poolSlippageLimitPercent) / 
            (totalPoolSupply * uint256(VaultConstants.VAULT_PERCENT_BASIS));
        minSecondary = (poolContext.secondaryBalance * poolClaim * 
            strategyContext.vaultSettings.poolSlippageLimitPercent) / 
            (totalPoolSupply * uint256(VaultConstants.VAULT_PERCENT_BASIS));
    }

    function _getTimeWeightedPrimaryBalance(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        uint256 poolClaim,
        uint256 oraclePrice,
        uint256 spotPrice
    ) internal view returns (uint256 primaryAmount) {
        // Make sure spot price is within oracleDeviationLimit of pairPrice
        strategyContext._checkPriceLimit(oraclePrice, spotPrice);
        
        // Get shares of primary and secondary balances with the provided poolClaim
        uint256 totalSupply = poolContext.poolToken.totalSupply();
        uint256 primaryBalance = poolContext.primaryBalance * poolClaim / totalSupply;
        uint256 secondaryBalance = poolContext.secondaryBalance * poolClaim / totalSupply;
        
        // Scale secondary balance to primaryPrecision
        uint256 primaryPrecision = 10 ** poolContext.primaryDecimals;
        uint256 secondaryPrecision = 10 ** poolContext.secondaryDecimals;
        secondaryBalance = secondaryBalance * primaryPrecision / secondaryPrecision;

        // Value the secondary balance in terms of the primary token using the oraclePairPrice
        uint256 secondaryAmountInPrimary = secondaryBalance * strategyContext.poolClaimPrecision / oraclePrice;

        primaryAmount = primaryBalance + secondaryAmountInPrimary;
    }

    /// @notice Trade primary currency for secondary if the trade is specified
    function _tradePrimaryForSecondary(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        bytes memory data
    ) internal returns (uint256 primarySold, uint256 secondaryBought) {
        (DepositTradeParams memory params) = abi.decode(data, (DepositTradeParams));

        if (DexId(params.tradeParams.dexId) == DexId.ZERO_EX) {
            revert Errors.InvalidDexId(params.tradeParams.dexId);
        }

        (primarySold, secondaryBought) = strategyContext._executeTradeExactIn({
            params: params.tradeParams, 
            sellToken: poolContext.primaryToken, 
            buyToken: poolContext.secondaryToken, 
            amount: params.tradeAmount,
            useDynamicSlippage: true
        });
    }

    function _sellSecondaryBalance(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        RedeemParams memory params,
        uint256 secondaryBalance
    ) internal returns (uint256 primaryPurchased) {
        (TradeParams memory tradeParams) = abi.decode(
            params.secondaryTradeParams, (TradeParams)
        );

        if (DexId(tradeParams.dexId) == DexId.ZERO_EX) {
            revert Errors.InvalidDexId(tradeParams.dexId);
        }

        ( /*uint256 amountSold */, primaryPurchased) = 
            strategyContext._executeTradeExactIn({
                params: tradeParams,
                sellToken: poolContext.secondaryToken,
                buyToken: poolContext.primaryToken,
                amount: secondaryBalance,
                useDynamicSlippage: true
            });
    }

    function _validateTrades(
        IERC20[] memory rewardTokens,
        SingleSidedRewardTradeParams memory primaryTrade,
        SingleSidedRewardTradeParams memory secondaryTrade,
        address primaryToken,
        address secondaryToken
    ) private pure {
        // Validate trades
        if (!RewardUtils._isValidRewardToken(rewardTokens, primaryTrade.sellToken)) {
            revert Errors.InvalidRewardToken(primaryTrade.sellToken);
        }
        if (secondaryTrade.sellToken != primaryTrade.sellToken) {
            revert Errors.InvalidRewardToken(secondaryTrade.sellToken);
        }
        if (primaryTrade.buyToken != primaryToken) {
            revert Errors.InvalidRewardToken(primaryTrade.buyToken);
        }
        if (secondaryTrade.buyToken != secondaryToken) {
            revert Errors.InvalidRewardToken(secondaryTrade.buyToken);
        }
    }

    function _executeRewardTrades(
        TwoTokenPoolContext calldata poolContext,
        StrategyContext memory strategyContext,
        IERC20[] memory rewardTokens,
        bytes calldata data
    ) internal returns (address rewardToken, uint256 primaryAmount, uint256 secondaryAmount) {
        Proportional2TokenRewardTradeParams memory params = abi.decode(
            data,
            (Proportional2TokenRewardTradeParams)
        );

        _validateTrades(
            rewardTokens,
            params.primaryTrade,
            params.secondaryTrade,
            poolContext.primaryToken,
            poolContext.secondaryToken
        );

        (/*uint256 amountSold*/, primaryAmount) = strategyContext._executeTradeExactIn({
            params: params.primaryTrade.tradeParams,
            sellToken: params.primaryTrade.sellToken,
            buyToken: params.primaryTrade.buyToken,
            amount: params.primaryTrade.amount,
            useDynamicSlippage: false
        });

        (/*uint256 amountSold*/, secondaryAmount) = strategyContext._executeTradeExactIn({
            params: params.secondaryTrade.tradeParams,
            sellToken: params.secondaryTrade.sellToken,
            buyToken: params.secondaryTrade.buyToken,
            amount: params.secondaryTrade.amount,
            useDynamicSlippage: false
        });

        rewardToken = params.primaryTrade.sellToken;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {Deployments} from "../../../../global/Deployments.sol";
import {Constants} from "../../../../global/Constants.sol";
import {IERC20} from "../../../../../interfaces/IERC20.sol";
import {IConvexRewardPool, IConvexRewardPoolArbitrum} from "../../../../../interfaces/convex/IConvexRewardPool.sol";
import {VaultEvents} from "../../VaultEvents.sol";

library RewardUtils {
    function _isValidRewardToken(IERC20[] memory rewardTokens, address token)
        internal pure returns (bool) {
        uint256 len = rewardTokens.length;
        for (uint256 i; i < len; i++) {
            if (address(rewardTokens[i]) == token) return true;
        }
        return false;
    }

    function _claimRewardTokens(function() internal returns(bool) claimFunc, IERC20[] memory rewardTokens) 
        internal returns (uint256[] memory claimedBalances) {
        uint256 numRewardTokens = rewardTokens.length;

        claimedBalances = new uint256[](numRewardTokens);
        for (uint256 i; i < numRewardTokens; i++) {
            claimedBalances[i] = rewardTokens[i].balanceOf(address(this));
        }

        bool success = claimFunc();
        require(success);

        for (uint256 i; i < numRewardTokens; i++) {
            claimedBalances[i] = rewardTokens[i].balanceOf(address(this)) - claimedBalances[i];
        }
        
        emit VaultEvents.ClaimedRewardTokens(rewardTokens, claimedBalances);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {TradeParams, StrategyContext, RedeemParams} from "../../VaultTypes.sol";
import {VaultState} from "../../../../global/Types.sol";
import {Errors} from "../../../../global/Errors.sol";
import {Deployments} from "../../../../global/Deployments.sol";
import {Constants} from "../../../../global/Constants.sol";
import {TypeConvert} from "../../../../global/TypeConvert.sol";
import {VaultConstants} from "../../VaultConstants.sol";
import {StrategyUtils} from "../../internal/strategy/StrategyUtils.sol";
import {VaultStorage, StrategyVaultSettings, StrategyVaultState} from "../../VaultStorage.sol";

library SettlementUtils {
    using TypeConvert for uint256;
    using TypeConvert for int256;
    using StrategyUtils for StrategyContext;
    using VaultStorage for StrategyVaultSettings;

    /// @notice Validates that the slippage passed in by the caller
    /// does not exceed the designated threshold.
    /// @param slippageLimitPercent configured limit on the slippage from the oracle price allowed
    /// @param data trade parameters passed into settlement
    /// @return params abi decoded redemption parameters
    function _decodeParamsAndValidate(
        uint32 slippageLimitPercent,
        bytes memory data
    ) internal view returns (RedeemParams memory params) {
        params = abi.decode(data, (RedeemParams));
        if (params.secondaryTradeParams.length != 0) {
            TradeParams memory callbackData = abi.decode(
                params.secondaryTradeParams, (TradeParams)
            );

            if (slippageLimitPercent < callbackData.oracleSlippagePercentOrLimit) {
                revert Errors.SlippageTooHigh(callbackData.oracleSlippagePercentOrLimit, slippageLimitPercent);
            }
        }
    }

    /// @notice Validates that the settlement is past a specified cool down period.
    /// @param lastSettlementTimestamp the last time the vault was settled
    /// @param coolDownInMinutes configured length of time required between settlements to ensure that
    /// slippage thresholds are respected (gives the market time to arbitrage back into position)
    function _validateCoolDown(uint32 lastSettlementTimestamp, uint32 coolDownInMinutes) internal view {
        // Convert coolDown to seconds
        if (lastSettlementTimestamp + (coolDownInMinutes * 60) > block.timestamp)
            revert Errors.InSettlementCoolDown(lastSettlementTimestamp, coolDownInMinutes);
    }

    /// @notice Calculates the amount of pool claim available for emergency settlement
    function _getEmergencySettlementPoolClaimAmount(
        uint256 totalPoolSupply,
        uint16 maxPoolShare,
        uint256 totalPoolClaim,
        uint256 poolClaimInMaturity
    ) private pure returns (uint256 poolClaimToSettle) {
        // desiredPoolShare = maxPoolShare * bufferPercentage
        uint256 desiredPoolShare = (maxPoolShare *
            VaultConstants.POOL_SHARE_BUFFER) /
            VaultConstants.VAULT_PERCENT_BASIS;
        uint256 desiredPoolClaimAmount = (totalPoolSupply * desiredPoolShare) /
            VaultConstants.VAULT_PERCENT_BASIS;
        
        poolClaimToSettle = totalPoolClaim - desiredPoolClaimAmount;

        // Check to make sure we are not settling more than the amount of pool claim
        // available in the current maturity
        // If more settlement is needed, call settleVaultEmergency
        // again with a different maturity
        if (poolClaimToSettle > poolClaimInMaturity) {
            poolClaimToSettle = poolClaimInMaturity;
        }
    }

    function _totalSupplyInMaturity(uint256 maturity) private view returns (uint256) {
        VaultState memory vaultState = Deployments.NOTIONAL.getVaultState(address(this), maturity);
        return vaultState.totalVaultShares;
    }

    function _getEmergencySettlementParams(
        StrategyContext memory strategyContext,
        uint256 maturity,
        uint256 totalPoolSupply
    )  internal view returns(uint256 poolClaimToSettle) {
        StrategyVaultSettings memory settings = strategyContext.vaultSettings;
        StrategyVaultState memory state = strategyContext.vaultState;

        // Not in settlement window, check if pool claim held is greater than maxPoolShare * total pool supply
        uint256 emergencyPooLClaimWithdrawThreshold = settings._poolClaimThreshold(totalPoolSupply);

        if (strategyContext.vaultState.totalPoolClaim <= emergencyPooLClaimWithdrawThreshold)
            revert Errors.InvalidEmergencySettlement();

        uint256 poolClaimInMaturity = _getPoolClaimHeldInMaturity(
            state,
            _totalSupplyInMaturity(maturity),
            strategyContext.vaultState.totalPoolClaim
        );

        poolClaimToSettle = _getEmergencySettlementPoolClaimAmount({
            totalPoolSupply: totalPoolSupply,
            maxPoolShare: settings.maxPoolShare,
            totalPoolClaim: strategyContext.vaultState.totalPoolClaim,
            poolClaimInMaturity: poolClaimInMaturity
        });
    }

    function _getPoolClaimHeldInMaturity(
        StrategyVaultState memory strategyVaultState, 
        uint256 totalSupplyInMaturity,
        uint256 totalPoolClaimHeld
    ) private pure returns (uint256 poolClaimHeldInMaturity) {
        if (strategyVaultState.totalVaultSharesGlobal == 0) return 0;
        poolClaimHeldInMaturity =
            (totalPoolClaimHeld * totalSupplyInMaturity) /
            strategyVaultState.totalVaultSharesGlobal;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {Errors} from "../../../../global/Errors.sol";
import {VaultConstants} from "../../VaultConstants.sol";
import {StrategyContext, TradeParams, StrategyVaultState} from "../../VaultTypes.sol";
import {TokenUtils, IERC20} from "../../../../utils/TokenUtils.sol";
import {TradeHandler} from "../../../../trading/TradeHandler.sol";
import {Deployments} from "../../../../global/Deployments.sol";
import {Constants} from "../../../../global/Constants.sol";
import {ITradingModule, Trade, TradeType} from "../../../../../interfaces/trading/ITradingModule.sol";
import {TypeConvert} from "../../../../global/TypeConvert.sol";
import {VaultStorage} from "../../VaultStorage.sol";

library StrategyUtils {
    using TradeHandler for Trade;
    using TokenUtils for IERC20;
    using TypeConvert for uint256;
    using VaultStorage for StrategyVaultState;

    function _checkPriceLimit(
        StrategyContext memory strategyContext,
        uint256 oraclePrice,
        uint256 poolPrice
    ) internal pure {
        uint256 lowerLimit = (oraclePrice * 
            (VaultConstants.VAULT_PERCENT_BASIS - strategyContext.vaultSettings.oraclePriceDeviationLimitPercent)) / 
            VaultConstants.VAULT_PERCENT_BASIS;
        uint256 upperLimit = (oraclePrice * 
            (VaultConstants.VAULT_PERCENT_BASIS + strategyContext.vaultSettings.oraclePriceDeviationLimitPercent)) / 
            VaultConstants.VAULT_PERCENT_BASIS;

        if (poolPrice < lowerLimit || upperLimit < poolPrice) {
            revert Errors.InvalidPrice(oraclePrice, poolPrice);
        }
    }

    /// @notice Converts strategy tokens to LP tokens
    function _convertStrategyTokensToPoolClaim(StrategyContext memory context, uint256 strategyTokenAmount)
        internal pure returns (uint256 poolClaim) {
        require(strategyTokenAmount <= context.vaultState.totalVaultSharesGlobal);
        if (context.vaultState.totalVaultSharesGlobal > 0) {
            poolClaim = (strategyTokenAmount * context.vaultState.totalPoolClaim) / context.vaultState.totalVaultSharesGlobal;
        }
    }

    /// @notice Converts LP tokens to strategy tokens
    function _convertPoolClaimToStrategyTokens(StrategyContext memory context, uint256 poolClaim)
        internal pure returns (uint256 strategyTokenAmount) {
        if (context.vaultState.totalPoolClaim == 0) {
            // Strategy tokens are in 8 decimal precision. Scale the minted amount according to pool claim precision.
            return (poolClaim * uint256(Constants.INTERNAL_TOKEN_PRECISION)) / 
                context.poolClaimPrecision;
        }

        // Pool claim in maturity is calculated before the new pool tokens are minted, so this calculation
        // is the tokens minted that will give the account a corresponding share of the new pool balance held.
        // The precision here will be the same as strategy token supply.
        strategyTokenAmount = (poolClaim * context.vaultState.totalVaultSharesGlobal) / context.vaultState.totalPoolClaim;
    }

    function _executeTradeExactIn(
        StrategyContext memory context,
        TradeParams memory params,
        address sellToken,
        address buyToken,
        uint256 amount,
        bool useDynamicSlippage
    ) internal returns (uint256 amountSold, uint256 amountBought) {
        require(
            params.tradeType == TradeType.EXACT_IN_SINGLE || params.tradeType == TradeType.EXACT_IN_BATCH
        );
        if (useDynamicSlippage) {
            require(params.oracleSlippagePercentOrLimit <= Constants.SLIPPAGE_LIMIT_PRECISION);
        } else {
            require(context.canUseStaticSlippage);
        }

        // Sell residual secondary balance
        Trade memory trade = Trade(
            params.tradeType,
            sellToken,
            buyToken,
            amount,
            useDynamicSlippage ? 0 : params.oracleSlippagePercentOrLimit,
            block.timestamp, // deadline
            params.exchangeData
        );

        // stETH generally has deeper liquidity than wstETH, setting tradeUnwrapped
        // to lets the contract trade in stETH instead of wstETH
        if (params.tradeUnwrapped) {
            if (sellToken == address(Deployments.WRAPPED_STETH)) {
                trade.sellToken = Deployments.WRAPPED_STETH.stETH();
                uint256 amountBeforeUnwrap = IERC20(trade.sellToken).balanceOf(address(this));
                // NOTE: the amount returned by unwrap is not always accurate for some reason
                Deployments.WRAPPED_STETH.unwrap(trade.amount);
                trade.amount = IERC20(trade.sellToken).balanceOf(address(this)) - amountBeforeUnwrap;
            }
            if (buyToken == address(Deployments.WRAPPED_STETH)) {
                trade.buyToken = Deployments.WRAPPED_STETH.stETH();
            }
        }

        if (useDynamicSlippage) {
            /// @dev params.oracleSlippagePercentOrLimit checked above
            (amountSold, amountBought) = trade._executeTradeWithDynamicSlippage(
                params.dexId, context.tradingModule, uint32(params.oracleSlippagePercentOrLimit)
            );
        } else {
            (amountSold, amountBought) = trade._executeTrade(
                params.dexId, context.tradingModule
            );
        }

        if (params.tradeUnwrapped) {
            if (sellToken == address(Deployments.WRAPPED_STETH)) {
                // Setting amountSold to the original wstETH amount because _executeTradeWithDynamicSlippage
                // returns the amount of stETH sold in this case
                /// @notice amountSold == amount because this function only supports EXACT_IN trades
                amountSold = amount;
            }
            if (buyToken == address(Deployments.WRAPPED_STETH) && amountBought > 0) {
                // trade.buyToken == stETH here
                IERC20(trade.buyToken).checkApprove(address(Deployments.WRAPPED_STETH), amountBought);
                uint256 amountBeforeWrap = Deployments.WRAPPED_STETH.balanceOf(address(this));
                /// @notice the amount returned by wrap is not always accurate for some reason
                Deployments.WRAPPED_STETH.wrap(amountBought);
                amountBought = Deployments.WRAPPED_STETH.balanceOf(address(this)) - amountBeforeWrap;
            }
        }
    }

    function _mintStrategyTokens(
        StrategyContext memory strategyContext,
        uint256 poolClaimMinted
    ) internal returns (uint256 vaultSharesMinted) {
        vaultSharesMinted = _convertPoolClaimToStrategyTokens(strategyContext, poolClaimMinted);

        if (vaultSharesMinted == 0) {
            revert Errors.ZeroStrategyTokens();
        }

        strategyContext.vaultState.totalPoolClaim += poolClaimMinted;
        strategyContext.vaultState.totalVaultSharesGlobal += vaultSharesMinted.toUint80();
        strategyContext.vaultState.setStrategyVaultState(); 
    }

    function _redeemStrategyTokens(
        StrategyContext memory strategyContext,
        uint256 vaultShares
    ) internal returns (uint256 poolClaim) {
        if (vaultShares == 0) {
            return poolClaim;
        }

        poolClaim = _convertStrategyTokensToPoolClaim(strategyContext, vaultShares);

        if (poolClaim == 0) {
            revert Errors.ZeroPoolClaim();
        }

        strategyContext.vaultState.totalPoolClaim -= poolClaim;
        strategyContext.vaultState.totalVaultSharesGlobal -= vaultShares.toUint80();
        strategyContext.vaultState.setStrategyVaultState(); 
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {BaseStrategyVault} from "../BaseStrategyVault.sol";
import {NotionalProxy} from "../../../interfaces/notional/NotionalProxy.sol";
import {ITradingModule} from "../../../interfaces/trading/ITradingModule.sol";
import {Errors} from "../../global/Errors.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {VaultEvents} from "./VaultEvents.sol";
import {StrategyVaultState} from "./VaultTypes.sol";
import {VaultStorage} from "./VaultStorage.sol";
import {VaultConstants} from "./VaultConstants.sol";

abstract contract VaultBase is BaseStrategyVault, UUPSUpgradeable {

    constructor(NotionalProxy notional_, ITradingModule tradingModule_) 
        BaseStrategyVault(notional_, tradingModule_) { }

    modifier whenNotLocked() {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        if (_hasFlag(state.flags, VaultConstants.FLAG_LOCKED)) {
            revert Errors.VaultLocked();
        }
        _;
    }

    modifier whenLocked() {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        if (!_hasFlag(state.flags, VaultConstants.FLAG_LOCKED)) {
            revert Errors.VaultNotLocked();
        }
        _;
    }

    function _hasFlag(uint32 flags, uint32 flagID) private pure returns (bool) {
        return (flags & flagID) == flagID;
    }

    function _lockVault() internal {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        state.flags = state.flags | VaultConstants.FLAG_LOCKED;
        VaultStorage.setStrategyVaultState(state);
        emit VaultEvents.VaultLocked();
    }

    function _unlockVault() internal {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        state.flags = state.flags & ~VaultConstants.FLAG_LOCKED;
        VaultStorage.setStrategyVaultState(state);
        emit VaultEvents.VaultUnlocked();
    }

    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal override onlyNotionalOwner {}
    
    // Storage gap for future potential upgrades
    uint256[100] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library VaultConstants {
    uint32 internal constant SLIPPAGE_LIMIT_PRECISION = 1e8;

    /// @notice Precision for all percentages used by the vault
    /// 1e4 = 100% (i.e. maxPoolShare)
    uint16 internal constant VAULT_PERCENT_BASIS = 1e4;
    /// @notice Buffer percentage between the desired share of the pool
    /// and the maximum share of the pool allowed by maxPoolShare 1e4 = 100%, 8e3 = 80%
    uint16 internal constant POOL_SHARE_BUFFER = 8e3;
    /// @notice Max settlement cool down period allowed (1 day)
    uint16 internal constant MAX_SETTLEMENT_COOLDOWN_IN_MINUTES = 24 * 60;

    uint32 internal constant FLAG_LOCKED = 1 << 0;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {StrategyVaultSettings} from "./VaultTypes.sol";
import {IERC20} from "../../../interfaces/IERC20.sol";

library VaultEvents {
    event RewardReinvested(address token, uint256 primaryAmount, uint256 secondaryAmount, uint256 poolClaimAmount);
    event StrategyVaultSettingsUpdated(StrategyVaultSettings settings);
    event VaultSettlement(
        uint256 maturity,
        uint256 poolClaimToSettle,
        uint256 strategyTokensRedeemed
    );
    event EmergencyVaultSettlement(
        uint256 maturity,
        uint256 poolClaimToSettle,
        uint256 redeemStrategyTokenAmount
    );
    event ClaimedRewardTokens(IERC20[] rewardTokens, uint256[] claimedBalances);
    event VaultLocked();
    event VaultUnlocked();
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {StrategyVaultSettings, StrategyVaultState} from "./VaultTypes.sol";
import {VaultEvents} from "./VaultEvents.sol";
import {VaultConstants} from "./VaultConstants.sol";

library VaultStorage {
    uint256 private constant STRATEGY_VAULT_SETTINGS_SLOT = 1000001;
    uint256 private constant STRATEGY_VAULT_STATE_SLOT    = 1000002;

    function _settings() private pure returns (mapping(uint256 => StrategyVaultSettings) storage store) {
        assembly { store.slot := STRATEGY_VAULT_SETTINGS_SLOT }
    }

    function _state() private pure returns (mapping(uint256 => StrategyVaultState) storage store) {
        assembly { store.slot := STRATEGY_VAULT_STATE_SLOT }
    }

    function getStrategyVaultSettings() internal view returns (StrategyVaultSettings memory) {
        // Hardcode to the zero slot
        return _settings()[0];
    }

    function setStrategyVaultSettings(StrategyVaultSettings memory settings) internal {
        require(settings.maxPoolShare <= VaultConstants.VAULT_PERCENT_BASIS);
        require(settings.settlementSlippageLimitPercent <= VaultConstants.SLIPPAGE_LIMIT_PRECISION);
        require(settings.postMaturitySettlementSlippageLimitPercent <= VaultConstants.SLIPPAGE_LIMIT_PRECISION);
        require(settings.emergencySettlementSlippageLimitPercent <= VaultConstants.SLIPPAGE_LIMIT_PRECISION);
        require(settings.oraclePriceDeviationLimitPercent <= VaultConstants.VAULT_PERCENT_BASIS);
        require(settings.poolSlippageLimitPercent <= VaultConstants.VAULT_PERCENT_BASIS);

        mapping(uint256 => StrategyVaultSettings) storage store = _settings();
        // Hardcode to the zero slot
        store[0] = settings;

        emit VaultEvents.StrategyVaultSettingsUpdated(settings);
    }

    function getStrategyVaultState() internal view returns (StrategyVaultState memory) {
        // Hardcode to the zero slot
        return _state()[0];
    }

    function setStrategyVaultState(StrategyVaultState memory state) internal {
        mapping(uint256 => StrategyVaultState) storage store = _state();
        // Hardcode to the zero slot
        store[0] = state;
    }

    function _poolClaimThreshold(StrategyVaultSettings memory strategyVaultSettings, uint256 totalPoolSupply) 
        internal pure returns (uint256) {
        return (totalPoolSupply * strategyVaultSettings.maxPoolShare) / VaultConstants.VAULT_PERCENT_BASIS;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {ITradingModule, Trade, TradeType} from "../../../interfaces/trading/ITradingModule.sol";
import {IERC20} from "../../../interfaces/IERC20.sol";

/// @notice Parameters for trades
struct TradeParams {
    uint16 dexId;
    TradeType tradeType;
    uint256 oracleSlippagePercentOrLimit;
    bool tradeUnwrapped;
    bytes exchangeData;
}

struct DepositTradeParams {
    uint256 tradeAmount;
    TradeParams tradeParams;
}

struct DepositParams {
    uint256 minPoolClaim;
    bytes tradeData;
}

struct RedeemParams {
    uint256 minPrimary;
    uint256 minSecondary;
    bytes secondaryTradeParams;
}

struct ReinvestRewardParams {
    bytes tradeData;
    uint256 minPoolClaim;
}

struct Proportional2TokenRewardTradeParams {
    SingleSidedRewardTradeParams primaryTrade;
    SingleSidedRewardTradeParams secondaryTrade;
}

struct SingleSidedRewardTradeParams {
    address sellToken;
    address buyToken;
    uint256 amount;
    TradeParams tradeParams;
}

struct StrategyContext {
    ITradingModule tradingModule;
    StrategyVaultSettings vaultSettings;
    StrategyVaultState vaultState;
    uint256 poolClaimPrecision;
    bool canUseStaticSlippage;
}

struct StrategyVaultSettings {
    uint256 maxUnderlyingSurplus;
    /// @notice Slippage limit for normal settlement
    uint32 settlementSlippageLimitPercent;
    /// @notice Slippage limit for post maturity settlement
    uint32 postMaturitySettlementSlippageLimitPercent;
    /// @notice Slippage limit for emergency settlement (vault owns too much of the pool)
    uint32 emergencySettlementSlippageLimitPercent;
    /// @notice Max share of the pool that the vault is allowed to hold
    uint16 maxPoolShare;
    /// @notice Limits the amount of allowable deviation from the oracle price
    uint16 oraclePriceDeviationLimitPercent;
    /// @notice Slippage limit for joining/exiting pools
    uint16 poolSlippageLimitPercent;
}

struct StrategyVaultState {
    uint256 totalPoolClaim;
    /// @notice Total number of strategy tokens across all maturities
    uint80 totalVaultSharesGlobal;
    uint32 lastSettlementTimestamp;
    uint32 flags;
}

struct TwoTokenPoolContext {
    address primaryToken;
    address secondaryToken;
    uint8 primaryIndex;
    uint8 secondaryIndex;
    uint8 primaryDecimals;
    uint8 secondaryDecimals;
    uint256 primaryBalance;
    uint256 secondaryBalance;
    IERC20 poolToken;
}

struct ThreeTokenPoolContext {
    address tertiaryToken;
    uint8 tertiaryIndex;
    uint8 tertiaryDecimals;
    uint256 tertiaryBalance;
    TwoTokenPoolContext basePool;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

struct LendingPoolStorage {
  ILendingPool lendingPool;
}

interface ILendingPool {

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (ReserveData memory);

  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IAuraBoosterBase {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
}

interface IAuraBooster is IAuraBoosterBase {
    function stakerRewards() external view returns(address);
}

interface IAuraBoosterLite is IAuraBoosterBase {
    function crv() external view returns(address);
    function rewards() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import {IRewardPool} from "../common/IRewardPool.sol";

interface IAuraRewardPool is IRewardPool{
}

interface IAuraL2Coordinator {
    function auraOFT() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IAuraStakingProxy {
    function crv() external view returns(address);
    function cvx() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IBalancerMinter {
    function mint(address gauge) external;
    function getBalancerToken() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import {IERC20} from "../IERC20.sol";

interface IBalancerPool is IERC20 {
    function getScalingFactors() external view returns (uint256[] memory);
    function getPoolId() external view returns (bytes32); 
    function getSwapFeePercentage() external view returns (uint256);
}

interface ILinearPool is IBalancerPool {
    function getMainIndex() external view returns (uint256);
    function getWrappedIndex() external view returns (uint256);
    function getVirtualSupply() external view returns (uint256);
    function getTargets() external view returns (uint256 lowerTarget, uint256 upperTarget);
    function getMainToken() external view returns (address);   
    function getWrappedToken() external view returns (address);
    function getWrappedTokenRate() external view returns (uint256);   
}

interface IBoostedPool is IBalancerPool {
    function getAmplificationParameter() external view returns (
        uint256 value,
        bool isUpdating,
        uint256 precision
    );
    function getActualSupply() external view returns (uint256);
}

interface IMetaStablePool is IBalancerPool {
    function getAmplificationParameter() external view returns (
        uint256 value,
        bool isUpdating,
        uint256 precision
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IBalancerVault {
    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for ManagedPool
    }

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId)
        external
        view
        returns (address, PoolSpecialization);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function flashLoan(
        address recipient, 
        address[] calldata tokens, 
        uint256[] calldata amounts, 
        bytes calldata userData
    ) external;

    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    function manageUserBalance(UserBalanceOp[] memory ops) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityGauge is IERC20 {
    function deposit(uint256 value) external;

    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;

    function withdraw(uint256 value, bool claim_rewards) external;

    function claim_rewards() external;

    // curve & balancer use lp_token()
    function lp_token() external view returns (address);

    // angle use staking_token()
    function staking_token() external view returns (address);

    function reward_tokens(uint256 i) external view returns (address token);

    function reward_count() external view returns (uint256 nTokens);

    function user_checkpoint(address addr) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
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
pragma solidity >=0.7.6;

interface IRewardPool {
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function balanceOf(address _account) external view returns(uint256);
    function pid() external view returns(uint256);
    function operator() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import {IRewardPool} from "../common/IRewardPool.sol";

interface IConvexRewardPool is IRewardPool {
    function extraRewards(uint256 idx) external view returns (address);
    function extraRewardsLength() external view returns (uint256);
}


interface IConvexRewardPoolArbitrum {
    function rewardLength() external view returns (uint256);
    function rewards(uint256 i) external view returns (address, uint256, uint256);
    function getReward(address _account) external;
    function convexBooster() external view returns (address);
    function balanceOf(address _account) external view returns(uint256);
    function withdraw(uint256 amount, bool claim) external returns(bool);
    function convexPoolId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveMetaRegistry {
    function get_registry_handlers_from_pool(address _pool)
        external
        view
        returns (address[10] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveRegistry {
    function find_pool_for_coins(address _from, address _to, uint256 i)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveRouter {
    function exchange(
        uint256 _amount,
        address[6] calldata _route,
        uint256[8] calldata _indices,
        uint256 _min_received
    ) external payable;

    function get_exchange_routing(
        address _initial,
        address _target,
        uint256 _amount
    ) external view returns (
        address[6] memory route,
        uint256[8] memory indexes,
        uint256 expectedOutputAmount
    );

    function can_route(address _initial, address _target) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveRouterV2 {
    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external returns (uint256);

    function exchange_multiple(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] calldata _pools,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `approve` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      */
    function approve(address spender, uint256 amount) external;

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import {IERC20} from "./IERC20.sol";

interface IWstETH is IERC20 {
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function stEthPerToken() external view returns (uint256);
    function stETH() external view returns (address);
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;

/// @notice Used as a wrapper for tokens that are interest bearing for an
/// underlying token. Follows the cToken interface, however, can be adapted
/// for other interest bearing tokens.
interface AssetRateAdapter {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function underlying() external view returns (address);

    function getExchangeRateStateful() external returns (int256);

    function getExchangeRateView() external view returns (int256);

    function getAnnualizedSupplyRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;
pragma abicoder v2;

struct DepositData {
    address[] targets;
    bytes[] callData;
    uint256[] msgValue;
    uint256 underlyingDepositAmount;
    address assetToken;
}

struct RedeemData {
    address[] targets;
    bytes[] callData;
    uint256 expectedUnderlying;
    address assetToken;
}

interface IPrimeCashHoldingsOracle {
    /// @notice Returns a list of the various holdings for the prime cash
    /// currency
    function holdings() external view returns (address[] memory);

    /// @notice Returns the underlying token that all holdings can be redeemed
    /// for.
    function underlying() external view returns (address);
    
    /// @notice Returns the native decimal precision of the underlying token
    function decimals() external view returns (uint8);

    /// @notice Returns the total underlying held by the caller in all the
    /// listed holdings
    function getTotalUnderlyingValueStateful() external returns (
        uint256 nativePrecision,
        uint256 internalPrecision
    );

    function getTotalUnderlyingValueView() external view returns (
        uint256 nativePrecision,
        uint256 internalPrecision
    );

    /// @notice Returns calldata for how to withdraw an amount
    function getRedemptionCalldata(uint256 withdrawAmount) external view returns (
        RedeemData[] memory redeemData
    );

    function holdingValuesInUnderlying() external view returns (uint256[] memory);

    function getRedemptionCalldataForRebalancing(
        address[] calldata _holdings, 
        uint256[] calldata withdrawAmounts
    ) external view returns (
        RedeemData[] memory redeemData
    );

    function getDepositCalldataForRebalancing(
        address[] calldata _holdings, 
        uint256[] calldata depositAmounts
    ) external view returns (
        DepositData[] memory depositData
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

interface IRewarder {
    function claimRewards(
        address account,
        uint16 currencyId,
        uint256 nTokenBalanceBefore,
        uint256 nTokenBalanceAfter,
        int256  netNTokenSupplyChange,
        uint256 NOTETokensClaimed
    ) external;
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.6;

interface IStrategyVault {

    struct StrategyVaultRoles {
        bytes32 normalSettlement;
        bytes32 emergencySettlement;
        bytes32 postMaturitySettlement;
        bytes32 rewardReinvestment;
        bytes32 staticSlippageTrading;
    }

    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function strategy() external view returns (bytes4 strategyId);

    // Tells a vault to deposit some amount of tokens from Notional and mint strategy tokens with it.
    function depositFromNotional(
        address account,
        uint256 depositAmount,
        uint256 maturity,
        bytes calldata data
    ) external payable returns (uint256 strategyTokensMinted);

    // Tells a vault to redeem some amount of strategy tokens from Notional and transfer the resulting asset cash
    function redeemFromNotional(
        address account,
        address receiver,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) external returns (uint256 transferToReceiver);

    function convertStrategyToUnderlying(
        address account,
        uint256 strategyTokens,
        uint256 maturity
    ) external view returns (int256 underlyingValue);

    function getExchangeRate(uint256 maturity) external view returns (int256);

    function repaySecondaryBorrowCallback(
        address token,
        uint256 underlyingRequired,
        bytes calldata data
    ) external returns (bytes memory returnData);

    function deleverageAccount(
        address account,
        address vault,
        address liquidator,
        uint16 currencyIndex,
        int256 depositUnderlyingInternal
    ) external payable returns (uint256 vaultSharesFromLiquidation, int256 depositAmountPrimeCash);
}

interface ISingleSidedLPStrategyVault {
    struct SingleSidedLPStrategyVaultInfo {
        address pool;
        uint8 singleSidedTokenIndex;
        uint256 totalLPTokens;
        uint256 totalVaultShares;
    }

    function getStrategyVaultInfo() external view returns (SingleSidedLPStrategyVaultInfo memory);
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.6;
pragma abicoder v2;

import {
    VaultConfigStorage,
    VaultConfig,
    VaultState,
    VaultAccount,
    VaultAccountHealthFactors,
    PrimeRate
} from "../../contracts/global/Types.sol";

interface IVaultAction {
    /// @notice Emitted when a new vault is listed or updated
    event VaultUpdated(address indexed vault, bool enabled, uint80 maxPrimaryBorrowCapacity);
    /// @notice Emitted when a vault's status is updated
    event VaultPauseStatus(address indexed vault, bool enabled);
    /// @notice Emitted when a vault's deleverage status is updated
    event VaultDeleverageStatus(address indexed vaultAddress, bool disableDeleverage);
    /// @notice Emitted when a secondary currency borrow capacity is updated
    event VaultUpdateSecondaryBorrowCapacity(address indexed vault, uint16 indexed currencyId, uint80 maxSecondaryBorrowCapacity);
    /// @notice Emitted when the borrow capacity on a vault changes
    event VaultBorrowCapacityChange(address indexed vault, uint16 indexed currencyId, uint256 totalUsedBorrowCapacity);

    /// @notice Emitted when a vault executes a secondary borrow
    event VaultSecondaryTransaction(
        address indexed vault,
        address indexed account,
        uint16 indexed currencyId,
        uint256 maturity,
        int256 netUnderlyingDebt,
        int256 netPrimeSupply
    );

    /** Vault Action Methods */

    /// @notice Governance only method to whitelist a particular vault
    function updateVault(
        address vaultAddress,
        VaultConfigStorage calldata vaultConfig,
        uint80 maxPrimaryBorrowCapacity
    ) external;

    /// @notice Governance only method to pause a particular vault
    function setVaultPauseStatus(
        address vaultAddress,
        bool enable
    ) external;

    function setVaultDeleverageStatus(
        address vaultAddress,
        bool disableDeleverage
    ) external;

    /// @notice Governance only method to set the borrow capacity
    function setMaxBorrowCapacity(
        address vaultAddress,
        uint80 maxVaultBorrowCapacity
    ) external;

    /// @notice Governance only method to update a vault's secondary borrow capacity
    function updateSecondaryBorrowCapacity(
        address vaultAddress,
        uint16 secondaryCurrencyId,
        uint80 maxBorrowCapacity
    ) external;

    function borrowSecondaryCurrencyToVault(
        address account,
        uint256 maturity,
        uint256[2] calldata underlyingToBorrow,
        uint32[2] calldata maxBorrowRate,
        uint32[2] calldata minRollLendRate
    ) external returns (int256[2] memory underlyingTokensTransferred);

    function repaySecondaryCurrencyFromVault(
        address account,
        uint256 maturity,
        uint256[2] calldata underlyingToRepay,
        uint32[2] calldata minLendRate
    ) external payable returns (int256[2] memory underlyingDepositExternal);

    function settleSecondaryBorrowForAccount(address vault, address account) external;
}

interface IVaultAccountAction {
    /**
     * @notice Borrows a specified amount of fCash in the vault's borrow currency and deposits it
     * all plus the depositAmountExternal into the vault to mint strategy tokens.
     *
     * @param account the address that will enter the vault
     * @param vault the vault to enter
     * @param depositAmountExternal some amount of additional collateral in the borrowed currency
     * to be transferred to vault
     * @param maturity the maturity to borrow at
     * @param fCash amount to borrow
     * @param maxBorrowRate maximum interest rate to borrow at
     * @param vaultData additional data to pass to the vault contract
     */
    function enterVault(
        address account,
        address vault,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint256 fCash,
        uint32 maxBorrowRate,
        bytes calldata vaultData
    ) external payable returns (uint256 strategyTokensAdded);

    /**
     * @notice Re-enters the vault at a longer dated maturity. The account's existing borrow
     * position will be closed and a new borrow position at the specified maturity will be
     * opened. All strategy token holdings will be rolled forward.
     *
     * @param account the address that will reenter the vault
     * @param vault the vault to reenter
     * @param fCashToBorrow amount of fCash to borrow in the next maturity
     * @param maturity new maturity to borrow at
     */
    function rollVaultPosition(
        address account,
        address vault,
        uint256 fCashToBorrow,
        uint256 maturity,
        uint256 depositAmountExternal,
        uint32 minLendRate,
        uint32 maxBorrowRate,
        bytes calldata enterVaultData
    ) external payable returns (uint256 strategyTokensAdded);

    /**
     * @notice Prior to maturity, allows an account to withdraw their position from the vault. Will
     * redeem some number of vault shares to the borrow currency and close the borrow position by
     * lending `fCashToLend`. Any shortfall in cash from lending will be transferred from the account,
     * any excess profits will be transferred to the account.
     *
     * Post maturity, will net off the account's debt against vault cash balances and redeem all remaining
     * strategy tokens back to the borrowed currency and transfer the profits to the account.
     *
     * @param account the address that will exit the vault
     * @param vault the vault to enter
     * @param vaultSharesToRedeem amount of vault tokens to exit, only relevant when exiting pre-maturity
     * @param fCashToLend amount of fCash to lend
     * @param minLendRate the minimum rate to lend at
     * @param exitVaultData passed to the vault during exit
     * @return underlyingToReceiver amount of underlying tokens returned to the receiver on exit
     */
    function exitVault(
        address account,
        address vault,
        address receiver,
        uint256 vaultSharesToRedeem,
        uint256 fCashToLend,
        uint32 minLendRate,
        bytes calldata exitVaultData
    ) external payable returns (uint256 underlyingToReceiver);

    function settleVaultAccount(address account, address vault) external;
}

interface IVaultLiquidationAction {
    event VaultDeleverageAccount(
        address indexed vault,
        address indexed account,
        uint16 currencyId,
        uint256 vaultSharesToLiquidator,
        int256 depositAmountPrimeCash
    );

    event VaultLiquidatorProfit(
        address indexed vault,
        address indexed account,
        address indexed liquidator,
        uint256 vaultSharesToLiquidator,
        bool transferSharesToLiquidator
    );
    
    event VaultAccountCashLiquidation(
        address indexed vault,
        address indexed account,
        address indexed liquidator,
        uint16 currencyId,
        int256 fCashDeposit,
        int256 cashToLiquidator
    );

    /**
     * @notice If an account is below the minimum collateral ratio, this method wil deleverage (liquidate)
     * that account. `depositAmountExternal` in the borrow currency will be transferred from the liquidator
     * and used to offset the account's debt position. The liquidator will receive either vaultShares or
     * cash depending on the vault's configuration.
     * @param account the address that will exit the vault
     * @param vault the vault to enter
     * @param liquidator the address that will receive profits from liquidation
     * @param depositAmountPrimeCash amount of cash to deposit
     * @return vaultSharesFromLiquidation amount of vaultShares received from liquidation
     */
    function deleverageAccount(
        address account,
        address vault,
        address liquidator,
        uint16 currencyIndex,
        int256 depositUnderlyingInternal
    ) external payable returns (uint256 vaultSharesFromLiquidation, int256 depositAmountPrimeCash);

    function liquidateVaultCashBalance(
        address account,
        address vault,
        address liquidator,
        uint256 currencyIndex,
        int256 fCashDeposit
    ) external returns (int256 cashToLiquidator);

    function liquidateExcessVaultCash(
        address account,
        address vault,
        address liquidator,
        uint256 excessCashIndex,
        uint256 debtIndex,
        uint256 _depositUnderlyingInternal
    ) external payable returns (int256 cashToLiquidator);
}

interface IVaultAccountHealth {
    function getVaultAccountHealthFactors(address account, address vault) external view returns (
        VaultAccountHealthFactors memory h,
        int256[3] memory maxLiquidatorDepositUnderlying,
        uint256[3] memory vaultSharesToLiquidator
    );

    function calculateDepositAmountInDeleverage(
        uint256 currencyIndex,
        VaultAccount memory vaultAccount,
        VaultConfig memory vaultConfig,
        VaultState memory vaultState,
        int256 depositUnderlyingInternal
    ) external returns (int256 depositInternal, uint256 vaultSharesToLiquidator, PrimeRate memory);

    function getfCashRequiredToLiquidateCash(
        uint16 currencyId,
        uint256 maturity,
        int256 vaultAccountCashBalance
    ) external view returns (int256 fCashRequired, int256 discountFactor);

    function checkVaultAccountCollateralRatio(address vault, address account) external;

    function getVaultAccount(address account, address vault) external view returns (VaultAccount memory);
    function getVaultAccountWithFeeAccrual(
        address account, address vault
    ) external view returns (VaultAccount memory, int256 accruedPrimeVaultFeeInUnderlying);

    function getVaultConfig(address vault) external view returns (VaultConfig memory vaultConfig);

    function getBorrowCapacity(address vault, uint16 currencyId) external view returns (
        uint256 currentPrimeDebtUnderlying,
        uint256 totalfCashDebt,
        uint256 maxBorrowCapacity
    );

    function getSecondaryBorrow(address vault, uint16 currencyId, uint256 maturity) 
        external view returns (int256 totalDebt);

    /// @notice View method to get vault state
    function getVaultState(address vault, uint256 maturity) external view returns (VaultState memory vaultState);

    function getVaultAccountSecondaryDebt(address account, address vault) external view returns (
        uint256 maturity,
        int256[2] memory accountSecondaryDebt,
        int256[2] memory accountSecondaryCashHeld
    );

    function signedBalanceOfVaultTokenId(address account, uint256 id) external view returns (int256);
}

interface IVaultController is IVaultAccountAction, IVaultAction, IVaultLiquidationAction, IVaultAccountHealth {}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";

interface nERC1155Interface {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function signedBalanceOf(address account, uint256 id) external view returns (int256);

    function signedBalanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (int256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable;

    function decodeToAssets(uint256[] calldata ids, uint256[] calldata amounts)
        external
        view
        returns (PortfolioAsset[] memory);

    function encodeToId(
        uint16 currencyId,
        uint40 maturity,
        uint8 assetType
    ) external pure returns (uint256 id);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";

interface NotionalCalculations {
    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        returns (uint256);

    function nTokenPresentValueAssetDenominated(uint16 currencyId) external view returns (int256);

    function nTokenPresentValueUnderlyingDenominated(uint16 currencyId)
        external
        view
        returns (int256);

    function convertNTokenToUnderlying(uint16 currencyId, int256 nTokenBalance) external view returns (int256);

    function getfCashAmountGivenCashAmount(
        uint16 currencyId,
        int88 netCashToAccount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256);

    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256, int256);

    function nTokenGetClaimableIncentives(address account, uint256 blockTime)
        external
        view
        returns (uint256);

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view returns (int256 presentValue);

    function getMarketIndex(
        uint256 maturity,
        uint256 blockTime
    ) external pure returns (uint8 marketIndex);

    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (
        uint88 fCashAmount,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (
        uint88 fCashDebt,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    ) external view returns (
        uint256 depositAmountUnderlying,
        uint256 depositAmountAsset,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    ) external view returns (
        uint256 borrowAmountUnderlying,
        uint256 borrowAmountAsset,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function convertCashBalanceToExternal(
        uint16 currencyId,
        int256 cashBalanceInternal,
        bool useUnderlying
    ) external view returns (int256);

    function convertUnderlyingToPrimeCash(
        uint16 currencyId,
        int256 underlyingExternal
    ) external view returns (int256);

    function convertSettledfCash(
        uint16 currencyId,
        uint256 maturity,
        int256 fCashBalance,
        uint256 blockTime
    ) external view returns (int256 signedPrimeSupplyValue);

    function accruePrimeInterest(
        uint16 currencyId
    ) external returns (PrimeRate memory pr, PrimeCashFactors memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";
import "../../interfaces/chainlink/AggregatorV2V3Interface.sol";
import "../../interfaces/notional/NotionalGovernance.sol";
import "../../interfaces/notional/IRewarder.sol";
import "../../interfaces/aave/ILendingPool.sol";

interface NotionalGovernance {
    event ListCurrency(uint16 newCurrencyId);
    event UpdateETHRate(uint16 currencyId);
    event UpdateAssetRate(uint16 currencyId);
    event UpdateCashGroup(uint16 currencyId);
    event DeployNToken(uint16 currencyId, address nTokenAddress);
    event UpdateDepositParameters(uint16 currencyId);
    event UpdateInitializationParameters(uint16 currencyId);
    event UpdateIncentiveEmissionRate(uint16 currencyId, uint32 newEmissionRate);
    event UpdateTokenCollateralParameters(uint16 currencyId);
    event UpdateGlobalTransferOperator(address operator, bool approved);
    event UpdateAuthorizedCallbackContract(address operator, bool approved);
    event UpdateMaxCollateralBalance(uint16 currencyId, uint72 maxCollateralBalance);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseRouterAndGuardianUpdated(address indexed pauseRouter, address indexed pauseGuardian);
    event UpdateSecondaryIncentiveRewarder(uint16 indexed currencyId, address rewarder);
    event UpdateLendingPool(address pool);

    function transferOwnership(address newOwner, bool direct) external;

    function claimOwnership() external;

    function upgradeNTokenBeacon(address newImplementation) external;

    function setPauseRouterAndGuardian(address pauseRouter_, address pauseGuardian_) external;

    function listCurrency(
        TokenStorage calldata assetToken,
        TokenStorage calldata underlyingToken,
        AggregatorV2V3Interface rateOracle,
        bool mustInvert,
        uint8 buffer,
        uint8 haircut,
        uint8 liquidationDiscount
    ) external returns (uint16 currencyId);

    function updateMaxCollateralBalance(
        uint16 currencyId,
        uint72 maxCollateralBalanceInternalPrecision
    ) external;

    function enableCashGroup(
        uint16 currencyId,
        AssetRateAdapter assetRateOracle,
        CashGroupSettings calldata cashGroup,
        string calldata underlyingName,
        string calldata underlyingSymbol
    ) external;

    function updateDepositParameters(
        uint16 currencyId,
        uint32[] calldata depositShares,
        uint32[] calldata leverageThresholds
    ) external;

    function updateInitializationParameters(
        uint16 currencyId,
        uint32[] calldata annualizedAnchorRates,
        uint32[] calldata proportions
    ) external;

    function updateIncentiveEmissionRate(uint16 currencyId, uint32 newEmissionRate) external;

    function updateTokenCollateralParameters(
        uint16 currencyId,
        uint8 residualPurchaseIncentive10BPS,
        uint8 pvHaircutPercentage,
        uint8 residualPurchaseTimeBufferHours,
        uint8 cashWithholdingBuffer10BPS,
        uint8 liquidationHaircutPercentage
    ) external;

    function updateCashGroup(uint16 currencyId, CashGroupSettings calldata cashGroup) external;

    function updateAssetRate(uint16 currencyId, AssetRateAdapter rateOracle) external;

    function updateETHRate(
        uint16 currencyId,
        AggregatorV2V3Interface rateOracle,
        bool mustInvert,
        uint8 buffer,
        uint8 haircut,
        uint8 liquidationDiscount
    ) external;

    function updateGlobalTransferOperator(address operator, bool approved) external;

    function updateAuthorizedCallbackContract(address operator, bool approved) external;

    function setLendingPool(ILendingPool pool) external;

    function setSecondaryIncentiveRewarder(uint16 currencyId, IRewarder rewarder) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";
import "./nTokenERC20.sol";
import "./nERC1155Interface.sol";
import "./NotionalGovernance.sol";
import "./NotionalCalculations.sol";
import "./NotionalViews.sol";
import "./NotionalTreasury.sol";
import {IVaultController} from "./IVaultController.sol";

interface NotionalProxy is
    nTokenERC20,
    nERC1155Interface,
    NotionalGovernance,
    NotionalTreasury,
    NotionalCalculations,
    NotionalViews,
    IVaultController
{
    /** User trading events */
    event CashBalanceChange(
        address indexed account,
        uint16 indexed currencyId,
        int256 netCashChange
    );
    event nTokenSupplyChange(
        address indexed account,
        uint16 indexed currencyId,
        int256 tokenSupplyChange
    );
    event MarketsInitialized(uint16 currencyId);
    event SweepCashIntoMarkets(uint16 currencyId, int256 cashIntoMarkets);
    event SettledCashDebt(
        address indexed settledAccount,
        uint16 indexed currencyId,
        address indexed settler,
        int256 amountToSettleAsset,
        int256 fCashAmount
    );
    event nTokenResidualPurchase(
        uint16 indexed currencyId,
        uint40 indexed maturity,
        address indexed purchaser,
        int256 fCashAmountToPurchase,
        int256 netAssetCashNToken
    );
    event LendBorrowTrade(
        address indexed account,
        uint16 indexed currencyId,
        uint40 maturity,
        int256 netAssetCash,
        int256 netfCash
    );
    event AddRemoveLiquidity(
        address indexed account,
        uint16 indexed currencyId,
        uint40 maturity,
        int256 netAssetCash,
        int256 netfCash,
        int256 netLiquidityTokens
    );

    /// @notice Emitted once when incentives are migrated
    event IncentivesMigrated(
        uint16 currencyId,
        uint256 migrationEmissionRate,
        uint256 finalIntegralTotalSupply,
        uint256 migrationTime
    );

    /// @notice Emitted when reserve fees are accrued
    event ReserveFeeAccrued(uint16 indexed currencyId, int256 fee);
    /// @notice Emitted whenever an account context has updated
    event AccountContextUpdate(address indexed account);
    /// @notice Emitted when an account has assets that are settled
    event AccountSettled(address indexed account);
    /// @notice Emitted when an asset rate is settled
    event SetSettlementRate(uint256 indexed currencyId, uint256 indexed maturity, uint128 rate);

    /* Liquidation Events */
    event LiquidateLocalCurrency(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        int256 netLocalFromLiquidator
    );

    event LiquidateCollateralCurrency(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 collateralCurrencyId,
        int256 netLocalFromLiquidator,
        int256 netCollateralTransfer,
        int256 netNTokenTransfer
    );

    event LiquidatefCashEvent(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 fCashCurrency,
        int256 netLocalFromLiquidator,
        uint256[] fCashMaturities,
        int256[] fCashNotionalTransfer
    );

    /** UUPS Upgradeable contract calls */
    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    function getImplementation() external view returns (address);

    function owner() external view returns (address);

    function pauseRouter() external view returns (address);

    function pauseGuardian() external view returns (address);

    /** Initialize Markets Action */
    function initializeMarkets(uint16 currencyId, bool isFirstInit) external;

    function sweepCashIntoMarkets(uint16 currencyId) external;

    /** Redeem nToken Action */
    function nTokenRedeem(
        address redeemer,
        uint16 currencyId,
        uint96 tokensToRedeem_,
        bool sellTokenAssets,
        bool acceptResidualAssets
    ) external returns (int256);

    /** Account Action */
    function enableBitmapCurrency(uint16 currencyId) external;

    function settleAccount(address account) external;

    function depositUnderlyingToken(
        address account,
        uint16 currencyId,
        uint256 amountExternalPrecision
    ) external payable returns (uint256);

    function depositAssetToken(
        address account,
        uint16 currencyId,
        uint256 amountExternalPrecision
    ) external returns (uint256);

    function withdraw(
        uint16 currencyId,
        uint88 amountInternalPrecision,
        bool redeemToUnderlying
    ) external returns (uint256);

    /** Batch Action */
    function batchBalanceAction(address account, BalanceAction[] calldata actions) external payable;

    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions)
        external
        payable;

    function batchBalanceAndTradeActionWithCallback(
        address account,
        BalanceActionWithTrades[] calldata actions,
        bytes calldata callbackData
    ) external payable;

    function batchLend(address account, BatchLend[] calldata actions) external;

    /** Liquidation Action */
    function calculateLocalCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint96 maxNTokenLiquidation
    ) external returns (int256, int256);

    function liquidateLocalCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint96 maxNTokenLiquidation
    ) external returns (int256, int256);

    function calculateCollateralCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 maxCollateralLiquidation,
        uint96 maxNTokenLiquidation
    )
        external
        returns (
            int256,
            int256,
            int256
        );

    function liquidateCollateralCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 maxCollateralLiquidation,
        uint96 maxNTokenLiquidation,
        bool withdrawCollateral,
        bool redeemToUnderlying
    )
        external
        returns (
            int256,
            int256,
            int256
        );

    function calculatefCashLocalLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function liquidatefCashLocal(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function calculatefCashCrossCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function liquidatefCashCrossCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

interface NotionalTreasury {

    /// @notice Emitted when reserve balance is updated
    event ReserveBalanceUpdated(uint16 indexed currencyId, int256 newBalance);
    /// @notice Emitted when reserve balance is harvested
    event ExcessReserveBalanceHarvested(uint16 indexed currencyId, int256 harvestAmount);
    /// @dev Emitted when treasury manager is updated
    event TreasuryManagerChanged(address indexed previousManager, address indexed newManager);
    /// @dev Emitted when reserve buffer value is updated
    event ReserveBufferUpdated(uint16 currencyId, uint256 bufferAmount);

    function claimCOMPAndTransfer(address[] calldata ctokens) external returns (uint256);

    function transferReserveToTreasury(uint16[] calldata currencies)
        external
        returns (uint256[] memory);

    function setTreasuryManager(address manager) external;

    function setReserveBuffer(uint16 currencyId, uint256 amount) external;

    function setReserveCashBalance(uint16 currencyId, int256 reserveBalance) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";

interface NotionalViews {
    function getMaxCurrencyId() external view returns (uint16);

    function getCurrencyId(address tokenAddress) external view returns (uint16 currencyId);

    function getCurrency(uint16 currencyId)
        external
        view
        returns (Token memory assetToken, Token memory underlyingToken);

    function getRateStorage(uint16 currencyId)
        external
        view
        returns (ETHRateStorage memory ethRate, AssetRateStorage memory assetRate);

    function getCurrencyAndRates(uint16 currencyId)
        external
        view
        returns (
            Token memory assetToken,
            Token memory underlyingToken,
            ETHRate memory ethRate,
            Deprecated_AssetRateParameters memory assetRate
        );

    function getCashGroup(uint16 currencyId) external view returns (CashGroupSettings memory);

    function getCashGroupAndAssetRate(uint16 currencyId)
        external
        view
        returns (CashGroupSettings memory cashGroup, Deprecated_AssetRateParameters memory assetRate);

    function getInterestRateCurve(uint16 currencyId) external view returns (
        InterestRateParameters[] memory nextInterestRateCurve,
        InterestRateParameters[] memory activeInterestRateCurve
    );

    function getInitializationParameters(uint16 currencyId)
        external
        view
        returns (int256[] memory annualizedAnchorRates, int256[] memory proportions);

    function getDepositParameters(uint16 currencyId)
        external
        view
        returns (int256[] memory depositShares, int256[] memory leverageThresholds);

    function nTokenAddress(uint16 currencyId) external view returns (address);

    function pCashAddress(uint16 currencyId) external view returns (address);

    function pDebtAddress(uint16 currencyId) external view returns (address);

    function getNoteToken() external view returns (address);

    function getOwnershipStatus() external view returns (address owner, address pendingOwner);

    function getGlobalTransferOperatorStatus(address operator)
        external
        view
        returns (bool isAuthorized);

    function getAuthorizedCallbackContractStatus(address callback)
        external
        view
        returns (bool isAuthorized);

    function getSecondaryIncentiveRewarder(uint16 currencyId)
        external
        view
        returns (address incentiveRewarder);

    function getPrimeFactors(uint16 currencyId, uint256 blockTime) external view returns (
        PrimeRate memory primeRate,
        PrimeCashFactors memory factors,
        uint256 maxUnderlyingSupply,
        uint256 totalUnderlyingSupply
    );

    function getPrimeFactorsStored(uint16 currencyId) external view returns (PrimeCashFactors memory);

    function getPrimeCashHoldingsOracle(uint16 currencyId) external view returns (address);

    function getTotalfCashDebtOutstanding(uint16 currencyId, uint256 maturity) external view returns (int256);

    function getSettlementRate(uint16 currencyId, uint40 maturity)
        external
        view
        returns (PrimeRate memory);

    function getMarket(
        uint16 currencyId,
        uint256 maturity,
        uint256 settlementDate
    ) external view returns (MarketParameters memory);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    function getActiveMarketsAtBlockTime(uint16 currencyId, uint32 blockTime)
        external
        view
        returns (MarketParameters[] memory);

    function getReserveBalance(uint16 currencyId) external view returns (int256 reserveBalance);

    function getNTokenPortfolio(address tokenAddress)
        external
        view
        returns (PortfolioAsset[] memory liquidityTokens, PortfolioAsset[] memory netfCashAssets);

    function getNTokenAccount(address tokenAddress)
        external
        view
        returns (
            uint16 currencyId,
            uint256 totalSupply,
            uint256 incentiveAnnualEmissionRate,
            uint256 lastInitializedTime,
            bytes5 nTokenParameters,
            int256 cashBalance,
            uint256 accumulatedNOTEPerNToken,
            uint256 lastAccumulatedTime
        );

    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        );

    function getAccountContext(address account) external view returns (AccountContext memory);

    function getAccountPrimeDebtBalance(uint16 currencyId, address account) external view returns (
        int256 debtBalance
    );

    function getAccountBalance(uint16 currencyId, address account)
        external
        view
        returns (
            int256 cashBalance,
            int256 nTokenBalance,
            uint256 lastClaimTime
        );

    function getAccountPortfolio(address account) external view returns (PortfolioAsset[] memory);

    function getfCashNotional(
        address account,
        uint16 currencyId,
        uint256 maturity
    ) external view returns (int256);

    function getAssetsBitmap(address account, uint16 currencyId) external view returns (bytes32);

    function getFreeCollateral(address account) external view returns (int256, int256[] memory);

    function getTreasuryManager() external view returns (address);

    function getReserveBuffer(uint16 currencyId) external view returns (uint256);

    function getRebalancingTarget(uint16 currencyId, address holding) external view returns (uint8);

    function getRebalancingCooldown(uint16 currencyId) external view returns (uint40);

    function getStoredTokenBalances(address[] calldata tokens) external view returns (uint256[] memory balances);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

interface nTokenERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function nTokenTotalSupply(address nTokenAddress) external view returns (uint256);

    function nTokenBalanceOf(uint16 currencyId, address account) external view returns (uint256);

    function nTokenTransferAllowance(
        uint16 currencyId,
        address owner,
        address spender
    ) external view returns (uint256);

    function pCashTransferAllowance(
        uint16 currencyId,
        address owner,
        address spender
    ) external view returns (uint256);

    function nTokenTransferApprove(
        uint16 currencyId,
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function pCashTransferApprove(
        uint16 currencyId,
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function nTokenTransfer(
        uint16 currencyId,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function pCashTransfer(
        uint16 currencyId,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function nTokenTransferFrom(
        uint16 currencyId,
        address spender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function pCashTransferFrom(
        uint16 currencyId,
        address spender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function nTokenTransferApproveAll(address spender, uint256 amount) external returns (bool);

    function nTokenClaimIncentives() external returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "../chainlink/AggregatorV2V3Interface.sol";

enum DexId {
    _UNUSED,
    UNISWAP_V2,
    UNISWAP_V3,
    ZERO_EX,
    BALANCER_V2,
    CURVE,
    NOTIONAL_VAULT,
    CURVE_V2
}

enum TradeType {
    EXACT_IN_SINGLE,
    EXACT_OUT_SINGLE,
    EXACT_IN_BATCH,
    EXACT_OUT_BATCH
}

struct Trade {
    TradeType tradeType;
    address sellToken;
    address buyToken;
    uint256 amount;
    /// minBuyAmount or maxSellAmount
    uint256 limit;
    uint256 deadline;
    bytes exchangeData;
}

error InvalidTrade();

interface ITradingModule {
    struct TokenPermissions {
        bool allowSell;
        /// @notice allowed DEXes
        uint32 dexFlags;
        /// @notice allowed trade types
        uint32 tradeTypeFlags; 
    }

    event TradeExecuted(
        address indexed sellToken,
        address indexed buyToken,
        uint256 sellAmount,
        uint256 buyAmount
    );

    event PriceOracleUpdated(address token, address oracle);
    event MaxOracleFreshnessUpdated(uint32 currentValue, uint32 newValue);
    event TokenPermissionsUpdated(address sender, address token, TokenPermissions permissions);

    function getExecutionData(uint16 dexId, address from, Trade calldata trade)
        external view returns (
            address spender,
            address target,
            uint256 value,
            bytes memory params
        );

    function setPriceOracle(address token, AggregatorV2V3Interface oracle) external;

    function setTokenPermissions(
        address sender, 
        address token, 
        TokenPermissions calldata permissions
    ) external;

    function getOraclePrice(address inToken, address outToken)
        external view returns (int256 answer, int256 decimals);

    function executeTrade(
        uint16 dexId,
        Trade calldata trade
    ) external returns (uint256 amountSold, uint256 amountBought);

    function executeTradeWithDynamicSlippage(
        uint16 dexId,
        Trade memory trade,
        uint32 dynamicSlippageLimit
    ) external returns (uint256 amountSold, uint256 amountBought);

    function getLimitAmount(
        address from,
        TradeType tradeType,
        address sellToken,
        address buyToken,
        uint256 amount,
        uint32 slippageLimit
    ) external view returns (uint256 limitAmount);

    function canExecuteTrade(address from, uint16 dexId, Trade calldata trade) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IUniV2Router2 {
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface WETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}