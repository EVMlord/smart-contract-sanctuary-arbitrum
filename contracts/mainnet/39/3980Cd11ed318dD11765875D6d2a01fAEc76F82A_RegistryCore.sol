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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IRegistry.sol";
import "./IFee.sol";
import "../libs/Errors.sol";
import "../libs/math/FixedPoint.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract AbstractRegistry is
  IRegistry,
  AccessControlUpgradeable,
  OwnableUpgradeable
{
  using FixedPoint for uint256;
  using FixedPoint for int256;
  using SafeCast for uint256;
  using SafeCast for int256;

  bytes32 public constant APPROVED_ROLE = keccak256("APPROVED_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
  bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

  uint128 public salt;

  // constant subject to governance update
  uint16 public maxOpenTradesPerPriceId;
  uint16 public maxOpenTradesPerUser;
  uint64 public liquidationPenalty;
  uint64 public feeFactor;
  uint128 public maxMarginPerUser;
  uint128 public minPositionPerTrade;
  uint128 public maxPercentagePnLFactor;
  uint128 public stopFee;
  uint128 public fee;

  // optional constant
  uint128 public maxPercentagePnLCap;
  uint128 public maxPercentagePnLFloor;

  // variable
  uint128 public minCollateral;

  // constant subject to governance update
  mapping(bytes32 => bool) public approvedPriceId;
  mapping(bytes32 => uint128) public maxLeveragePerPriceId;
  mapping(bytes32 => uint128) public minLeveragePerPriceId;
  mapping(bytes32 => uint64) public liquidationThresholdPerPriceId;
  mapping(bytes32 => uint128) public impactRefDepthLongPerPriceId;
  mapping(bytes32 => uint128) public impactRefDepthShortPerPriceId;

  // dynamic variable
  mapping(bytes32 => Trade) internal __openTradeByOrderHash;

  mapping(address => mapping(bytes32 => uint128))
    public openTradesPerPriceIdCount;
  mapping(address => uint128) public openTradesPerUserCount;
  mapping(address => uint128) public totalMarginPerUser;

  mapping(bytes32 => uint128) public totalLongPerPriceId;
  mapping(bytes32 => uint128) public totalShortPerPriceId;

  event ApprovedPriceIdEvent(bytes32 priceId, bool approved);
  event SetMaxOpenTradesPerPriceIdEvent(uint256 maxOpenTradesPerPriceId);
  event SetMaxOpenTradesPerUserEvent(uint256 maxOpenTradesPerUser);
  event SetMaxMarginPerUserEvent(uint256 maxMarginPerUser);
  event SetMinPositionPerTradeEvent(uint256 minPositionPerTrade);
  event SetLiquidationThresholdEvent(
    bytes32 priceId,
    uint256 liquidationThreshold
  );
  event SetLiquidationPenaltyEvent(uint256 liquidationPenalty);
  event SetMaxLeverageEvent(bytes32 priceId, uint256 maxLeverage);
  event SetMinLeverageEvent(bytes32 priceId, uint256 minLeverage);
  event SetMaxPercentagePnLFactorEvent(uint256 maxPercentagePnLFactor);
  event SetMaxPercentagePnLCapEvent(uint256 maxPercentagePnLCap);
  event SetMaxPercentagePnLFloorEvent(uint256 maxPercentagePnLFloor);
  event SetFeeEvent(uint256 fee);
  event SetFeeFactorEvent(uint256 feeFactor);
  event SetImpactRefDepthLongEvent(bytes32 priceId, uint256 impactRefDepthLong);
  event SetImpactRefDepthShortEvent(
    bytes32 priceId,
    uint256 impactRefDepthShort
  );
  event SetStopFeeEvent(uint256 stopFee);

  function __AbstractRegistry_init(
    address owner,
    uint16 _maxOpenTradesPerPriceId,
    uint16 _maxOpenTradesPerUser,
    uint128 _maxMarginPerUser,
    uint128 _minPositionPerTrade,
    uint64 _liquidationPenalty,
    uint128 _maxPercentagePnLFactor,
    uint128 _stopFee,
    uint128 _fee
  ) internal onlyInitializing {
    __AccessControl_init();
    __Ownable_init();
    _transferOwnership(owner);
    _grantRole(DEFAULT_ADMIN_ROLE, owner);
    _grantRole(UPDATER_ROLE, owner);
    maxOpenTradesPerPriceId = _maxOpenTradesPerPriceId;
    maxOpenTradesPerUser = _maxOpenTradesPerUser;
    maxMarginPerUser = _maxMarginPerUser;
    minPositionPerTrade = _minPositionPerTrade;
    liquidationPenalty = _liquidationPenalty;
    maxPercentagePnLFactor = _maxPercentagePnLFactor;
    stopFee = _stopFee;
    fee = _fee;

    maxPercentagePnLCap = type(uint128).max;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  modifier onlyApprovedPriceId(bytes32 priceId) {
    _require(approvedPriceId[priceId], Errors.APPROVED_PRICE_ID_ONLY);
    _;
  }

  // external functions

  function isLiquidator(address user) external view override returns (bool) {
    return hasRole(LIQUIDATOR_ROLE, user);
  }

  function openTradeByOrderHash(
    bytes32 orderHash
  ) external view returns (Trade memory) {
    return _openTradeByOrderHash(orderHash);
  }

  function UncheckedOpenTradeByOrderHash(
    bytes32 orderHash
  ) external view returns (Trade memory) {
    return __openTradeByOrderHash[orderHash];
  }

  function getFee() external view virtual returns (uint256) {
    return fee;
  }

  function getSlippage(
    bytes32 priceId,
    bool isBuy,
    uint128 price,
    uint128 position
  ) external view override returns (uint128) {
    return _getSlippage(priceId, isBuy, price, position);
  }

  // governance functions

  function setMaxOpenTradesPerPriceId(
    uint16 _maxOpenTradesPerPriceId
  ) external onlyOwner {
    maxOpenTradesPerPriceId = _maxOpenTradesPerPriceId;
    emit SetMaxOpenTradesPerPriceIdEvent(maxOpenTradesPerPriceId);
  }

  function setMaxOpenTradesPerUser(
    uint16 _maxOpenTradesPerUser
  ) external onlyOwner {
    maxOpenTradesPerUser = _maxOpenTradesPerUser;
    emit SetMaxOpenTradesPerUserEvent(maxOpenTradesPerUser);
  }

  function setMaxMarginPerUser(uint128 _maxMarginPerUser) external onlyOwner {
    maxMarginPerUser = _maxMarginPerUser;
    emit SetMaxMarginPerUserEvent(maxMarginPerUser);
  }

  function setMinPositionPerTrade(
    uint128 _minPositionPerTrade
  ) external onlyOwner {
    minPositionPerTrade = _minPositionPerTrade;
    emit SetMinPositionPerTradeEvent(minPositionPerTrade);
  }

  function setApprovedPriceId(
    bytes32 priceId,
    bool approved
  ) external onlyOwner {
    approvedPriceId[priceId] = approved;
    emit ApprovedPriceIdEvent(priceId, approved);
  }

  function setLiquidationThresholdPerPriceId(
    bytes32 priceId,
    uint64 liquidationThreshold
  ) external onlyOwner {
    liquidationThresholdPerPriceId[priceId] = liquidationThreshold;
    emit SetLiquidationThresholdEvent(priceId, liquidationThreshold);
  }

  function setLiquidationPenalty(
    uint64 _liquidationPenalty
  ) external onlyOwner {
    liquidationPenalty = _liquidationPenalty;
    emit SetLiquidationPenaltyEvent(liquidationPenalty);
  }

  function setMaxLeveragePerPriceId(
    bytes32 priceId,
    uint128 maxLeverage
  ) external onlyOwner {
    _require(
      maxLeverage >= minLeveragePerPriceId[priceId],
      Errors.MAX_SMALLER_THAN_MIN
    );
    maxLeveragePerPriceId[priceId] = maxLeverage;
    emit SetMaxLeverageEvent(priceId, maxLeverage);
  }

  function setMinLeveragePerPriceId(
    bytes32 priceId,
    uint128 minLeverage
  ) external onlyOwner {
    _require(
      minLeverage <= maxLeveragePerPriceId[priceId],
      Errors.MIN_BIGGER_THAN_MAX
    );
    _require(
      minLeverage >= liquidationThresholdPerPriceId[priceId],
      Errors.MIN_SMALLER_THAN_THRESHOLD
    );
    minLeveragePerPriceId[priceId] = minLeverage;
    emit SetMinLeverageEvent(priceId, minLeverage);
  }

  function setMaxPercentagePnLFloor(
    uint128 _maxPercentagePnLFloor
  ) external onlyOwner {
    _require(
      _maxPercentagePnLFloor <= maxPercentagePnLCap,
      Errors.MIN_BIGGER_THAN_MAX
    );
    maxPercentagePnLFloor = _maxPercentagePnLFloor;
    emit SetMaxPercentagePnLFloorEvent(maxPercentagePnLFloor);
  }

  function setMaxPercentagePnLCap(
    uint128 _maxPercentagePnLCap
  ) external onlyOwner {
    _require(
      _maxPercentagePnLCap >= maxPercentagePnLFloor,
      Errors.MAX_SMALLER_THAN_MIN
    );
    maxPercentagePnLCap = _maxPercentagePnLCap;
    emit SetMaxPercentagePnLCapEvent(maxPercentagePnLCap);
  }

  function setMaxPercentagePnLFactor(
    uint128 _maxPercentagePnLFactor
  ) external onlyOwner {
    maxPercentagePnLFactor = _maxPercentagePnLFactor;
    emit SetMaxPercentagePnLFactorEvent(maxPercentagePnLFactor);
  }

  function setFee(uint128 _fee) external onlyOwner {
    fee = _fee;
    emit SetFeeEvent(fee);
  }

  function setFeeFactor(uint64 _feeFactor) external onlyOwner {
    _require(_feeFactor >= 0 && _feeFactor <= 1e18, Errors.INVALID_FEE_FACTOR);
    feeFactor = _feeFactor;
    emit SetFeeFactorEvent(feeFactor);
  }

  function setStopFee(uint128 _stopFee) external onlyOwner {
    stopFee = _stopFee;
    emit SetStopFeeEvent(stopFee);
  }

  // priviledged functions

  function setImpactRefDepthLongPerPriceId(
    bytes32 priceId,
    uint128 impactRefDepthLong
  ) external onlyRole(UPDATER_ROLE) {
    impactRefDepthLongPerPriceId[priceId] = impactRefDepthLong;
    emit SetImpactRefDepthLongEvent(priceId, impactRefDepthLong);
  }

  function setImpactRefDepthShortPerPriceId(
    bytes32 priceId,
    uint128 impactRefDepthShort
  ) external onlyRole(UPDATER_ROLE) {
    impactRefDepthShortPerPriceId[priceId] = impactRefDepthShort;
    emit SetImpactRefDepthShortEvent(priceId, impactRefDepthShort);
  }

  // internal functions

  function _openTradeByOrderHash(
    bytes32 orderHash
  ) internal view returns (Trade memory t) {
    t = __openTradeByOrderHash[orderHash];
    _require(t.user != address(0x0), Errors.ORDER_NOT_FOUND);
  }

  function _getSlippage(
    bytes32 priceId,
    bool isBuy,
    uint128 price,
    uint128 position
  ) internal view returns (uint128) {
    uint256 impact = (
      uint256(
        isBuy ? totalLongPerPriceId[priceId] : totalShortPerPriceId[priceId]
      ).add(position)
    ).divDown(
        isBuy
          ? impactRefDepthLongPerPriceId[priceId]
          : impactRefDepthShortPerPriceId[priceId]
      );
    return uint256(price).mulDown(impact).divDown(uint256(100e18)).toUint128();
  }

  // abstract functions

  function openMarketOrder(
    Trade memory trade
  ) external virtual returns (bytes32);

  function closeMarketOrder(
    bytes32 orderHash,
    uint64 closePercent
  ) external virtual;

  function updateOpenOrder(
    bytes32 orderHash,
    Trade memory trade
  ) external virtual;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IFee {
  struct Fee {
    uint128 fee;
    uint128 referredFee;
    uint128 referralFee;
    bytes32 referralCode;
    address referrer;
  }

  function getOpenFee(address _user) external view returns (Fee memory);

  function getCloseFee(address _user) external view returns (Fee memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IRegistry {
  struct Trade {
    address user;
    bool isBuy;
    uint32 executionBlock;
    uint32 executionTime;
    bytes32 priceId;
    uint128 margin;
    uint128 leverage;
    uint128 openPrice;
    uint128 slippage;
    uint128 liquidationPrice;
    uint128 profitTarget;
    uint128 stopLoss;
    uint128 maxPercentagePnL;
    uint128 salt;
  }

  function openMarketOrder(Trade memory trade) external returns (bytes32);

  function closeMarketOrder(bytes32 orderHash, uint64 closePercent) external;

  function updateOpenOrder(bytes32 orderHash, Trade memory trade) external;

  function openTradeByOrderHash(
    bytes32 orderHash
  ) external view returns (Trade memory);

  function approvedPriceId(bytes32 priceId) external view returns (bool);

  function getSlippage(
    bytes32 priceId,
    bool isBuy,
    uint128 price,
    uint128 position
  ) external view returns (uint128);

  function liquidationThresholdPerPriceId(
    bytes32 priceId
  ) external view returns (uint64);

  function isLiquidator(address user) external view returns (bool);

  function maxPercentagePnLFactor() external view returns (uint128);

  function maxPercentagePnLCap() external view returns (uint128);

  function maxPercentagePnLFloor() external view returns (uint128);

  function maxLeveragePerPriceId(
    bytes32 priceId
  ) external view returns (uint128);

  function maxOpenTradesPerPriceId() external view returns (uint16);

  function maxOpenTradesPerUser() external view returns (uint16);

  function maxMarginPerUser() external view returns (uint128);

  function minPositionPerTrade() external view returns (uint128);

  function liquidationPenalty() external view returns (uint64);

  function stopFee() external view returns (uint128);

  function feeFactor() external view returns (uint64);

  function totalMarginPerUser(address user) external view returns (uint128);

  function minCollateral() external view returns (uint128);

  function openTradesPerPriceIdCount(
    address user,
    bytes32 priceId
  ) external view returns (uint128);

  function openTradesPerUserCount(address user) external view returns (uint128);

  function totalLongPerPriceId(bytes32 priceId) external view returns (uint128);

  function totalShortPerPriceId(
    bytes32 priceId
  ) external view returns (uint128);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IRegistry.sol";
import "./IFee.sol";

interface IRegistryCore is IRegistry {
  struct SignedBalance {
    int128 balance;
    uint32 lastUpdate;
  }

  struct AccruedFee {
    int128 fundingFee;
    uint128 rolloverFee;
    uint32 lastUpdate;
  }

  struct OnOrderUpdate {
    IRegistryCore.SignedBalance feeBalance;
    int128 feeBase;
    IRegistryCore.AccruedFee accruedFee;
  }

  function getOpenFee(address _user) external view returns (IFee.Fee memory);

  function getCloseFee(address _user) external view returns (IFee.Fee memory);

  function getAccumulatedFee(
    bytes32 orderHash,
    uint64 closePercent
  ) external view returns (int128, uint128);

  function onOrderUpdate(
    bytes32 orderHash
  ) external view returns (OnOrderUpdate memory);

  function updateTrade(
    bytes32 orderHash,
    uint128 oraclePrice,
    uint128 margin,
    bool isAdding,
    uint256 liquidityBalance
  ) external view returns (Trade memory);

  function updateStop(
    bytes32 orderHash,
    uint128 oraclePrice,
    uint128 profitTarget,
    uint128 stopLoss
  ) external view returns (Trade memory);

  function maxTotalLongPerPriceId(
    bytes32 priceId
  ) external view returns (uint128);

  function maxTotalShortPerPriceId(
    bytes32 priceId
  ) external view returns (uint128);

  function netFeeRebateLP() external view returns (uint64);

  function minIncrement() external view returns (uint256);

  function minBlockGap() external view returns (uint256);
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

pragma solidity ^0.8.17;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 * Uses the default 'UNW' prefix for the error code
 */
function _require(bool condition, uint256 errorCode) pure {
  if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode, bytes3 prefix) pure {
  if (!condition) _revert(errorCode, prefix);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 * Uses the default 'UNW' prefix for the error code
 */
function _revert(uint256 errorCode) pure {
  _revert(errorCode, 0x554e57); // This is the raw byte representation of "UNW"
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode, bytes3 prefix) pure {
  uint256 prefixUint = uint256(uint24(prefix));
  // We're going to dynamically create a revert string based on the error code, with the following format:
  // 'UNW#{errorCode}'
  // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
  //
  // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
  // number (8 to 16 bits) than the individual string characters.
  //
  // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
  // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
  // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
  assembly {
    // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
    // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
    // the '0' character.

    let units := add(mod(errorCode, 10), 0x30)

    errorCode := div(errorCode, 10)
    let tenths := add(mod(errorCode, 10), 0x30)

    errorCode := div(errorCode, 10)
    let hundreds := add(mod(errorCode, 10), 0x30)

    // With the individual characters, we can now construct the full string.
    // We first append the '#' character (0x23) to the prefix. In the case of 'UNW', it results in 0x554e57 ('UNW#')
    // Then, we shift this by 24 (to provide space for the 3 bytes of the error code), and add the
    // characters to it, each shifted by a multiple of 8.
    // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
    // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
    // array).
    let formattedPrefix := shl(24, add(0x23, shl(8, prefixUint)))

    let revertReason := shl(
      200,
      add(formattedPrefix, add(add(units, shl(8, tenths)), shl(16, hundreds)))
    )

    // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
    // message will have the following layout:
    // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

    // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
    // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
    mstore(
      0x0,
      0x08c379a000000000000000000000000000000000000000000000000000000000
    )
    // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
    mstore(
      0x04,
      0x0000000000000000000000000000000000000000000000000000000000000020
    )
    // The string length is fixed: 7 characters.
    mstore(0x24, 7)
    // Finally, the string itself is stored.
    mstore(0x44, revertReason)

    // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
    // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
    revert(0, 100)
  }
}

function _verifyCallResult(
  bool success,
  bytes memory returndata
) pure returns (bytes memory) {
  if (success) {
    return returndata;
  }
  if (returndata.length > 0) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let returndata_size := mload(returndata)
      revert(add(32, returndata), returndata_size)
    }
  }
  _revert(Errors.SHOULD_NOT_HAPPEN);
}

library Errors {
  // Math
  uint256 internal constant ADD_OVERFLOW = 0;
  uint256 internal constant SUB_OVERFLOW = 1;
  uint256 internal constant SUB_UNDERFLOW = 2;
  uint256 internal constant MUL_OVERFLOW = 3;
  uint256 internal constant ZERO_DIVISION = 4;
  uint256 internal constant DIV_INTERNAL = 5;
  uint256 internal constant X_OUT_OF_BOUNDS = 6;
  uint256 internal constant Y_OUT_OF_BOUNDS = 7;
  uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
  uint256 internal constant INVALID_EXPONENT = 9;

  // Input
  uint256 internal constant OUT_OF_BOUNDS = 10;
  uint256 internal constant UNSORTED_ARRAY = 11;
  uint256 internal constant UNSORTED_TOKENS = 12;
  uint256 internal constant INPUT_LENGTH_MISMATCH = 13;
  uint256 internal constant INVALID_INPUT = 14;

  // TradingBook related
  uint256 internal constant ZERO_TOKEN = 104;
  uint256 internal constant TOKEN_MISMATCH = 105;
  uint256 internal constant INVALID_STOP_LOSS = 106;
  uint256 internal constant INVALID_PROFIT_TARGET = 107;
  uint256 internal constant FEE_TOO_HIGH = 108;
  uint256 internal constant NEGATIVE_LEVERAGE = 109;
  uint256 internal constant LEVERAGE_TOO_HIGH = 110;
  uint256 internal constant APPROVED_PRICE_ID_ONLY = 111;
  uint256 internal constant POSITION_TOO_SMALL = 112;
  uint256 internal constant SLIPPAGE_TOO_GREAT = 113;
  uint256 internal constant SLIPPAGE_EXCEEDS_LIMIT = 114;
  uint256 internal constant SWAP_MARGIN_MISMATCH = 115;
  uint256 internal constant INVALID_CLOSE_PERCENT = 116;
  uint256 internal constant INVALID_MARGIN = 117;
  uint256 internal constant ORDER_NOT_FOUND = 118;
  uint256 internal constant TRADER_OWNER_MISMATCH = 119;
  uint256 internal constant POSITIVE_EXPO = 120;
  uint256 internal constant NEGATIVE_PRICE = 121;
  uint256 internal constant INVALID_BURN_AMOUNT = 122;
  uint256 internal constant NOTHING_TO_BURN = 123;
  uint256 internal constant INVALID_TOKEN_DECIMALS = 124;
  uint256 internal constant MIN_BIGGER_THAN_MAX = 125;
  uint256 internal constant MAX_SMALLER_THAN_MIN = 126;
  uint256 internal constant MIN_SMALLER_THAN_THRESHOLD = 127;
  uint256 internal constant BURN_EXCEEDS_EXCESS = 128;
  uint256 internal constant PRICE_ID_MISMATCH = 129;
  uint256 internal constant TRADE_DIRECTION_MISMATCH = 130;
  uint256 internal constant CANNOT_LIQUIDATE = 131;
  uint256 internal constant INVALID_TIMESTAMP = 132;
  uint256 internal constant CANNOT_EXECUTE_LIMIT = 133;
  uint256 internal constant INVALID_FEE_FACTOR = 134;
  uint256 internal constant INVALID_MINT_AMOUNT = 135;
  uint256 internal constant TRADE_SALT_MISMATCH = 136;
  uint256 internal constant REQUIRE_BURN_REQUEST = 137;

  // Access
  uint256 internal constant APPROVED_ONLY = 200;
  uint256 internal constant TRADING_PAUSED = 201;
  uint256 internal constant USER_OR_LIQUIDATOR_ONLY = 202;
  uint256 internal constant USER_SENDER_MISMATCH = 203;
  uint256 internal constant LIQUIDATOR_ONLY = 204;
  uint256 internal constant DELEGATE_CALL_ONLY = 205;
  uint256 internal constant TRANSFER_NOT_ALLOWED = 206;
  uint256 internal constant APPROVED_TOKEN_ONLY = 207;
  uint256 internal constant ZERO_ADDRESS = 208;

  // Trading capacity
  uint256 internal constant MAX_OPEN_TRADES_PER_PRICE_ID = 300;
  uint256 internal constant MAX_OPEN_TRADES_PER_USER = 301;
  uint256 internal constant MAX_MARGIN_PER_USER = 302;
  uint256 internal constant MAX_LIQUIDITY_POOL = 303;
  uint256 internal constant MAX_TOTAL_POSITIONS = 304;

  // Pyth related
  uint256 internal constant INVALID_UPDATE_DATA_SOURCE = 400;
  uint256 internal constant INVALID_UPDATE_DATA = 401;
  uint256 internal constant INVALID_WORMHOLE_VAA = 402;
  uint256 internal constant PRICE_FEED_NOT_FOUND = 403;

  // Referral
  uint256 internal constant USER_ALREADY_REGISTERED = 500;
  uint256 internal constant INVALID_REFERRAL_CODE = 501;
  uint256 internal constant USER_NOT_REGISTERED = 502;
  uint256 internal constant INVALID_SHARE = 503;
  uint256 internal constant EXCEED_MAX_REFERRAL_CODES = 504;

  // NFT related
  uint256 internal constant ALREADY_MINTED = 600;
  uint256 internal constant MAX_MINTED = 601;
  uint256 internal constant INVALID_DISCOUNT = 602;

  // Staking related
  uint256 internal constant INVALID_AMOUNT = 700;
  uint256 internal constant INVALID_TOKEN_ID = 701;
  uint256 internal constant NO_STAKING_POSITION = 702;
  uint256 internal constant INVALID_REWARD_TOKEN = 703;
  uint256 internal constant ALREADY_STAKED = 704;

  // Airdrop related
  uint256 internal constant START_BLOCK_NOT_REACHED = 800;

  // Timelock related
  uint256 internal constant INVALID_AGREEMENT_CONTEXT = 900;
  uint256 internal constant BENEFICIARY_SENDER_MISMATCH = 901;
  uint256 internal constant RELEASE_TIME_NOT_REACHED = 902;
  uint256 internal constant AGREEMENT_FROZEN = 903;
  uint256 internal constant AGREEMENT_NOT_FROZEN = 904;

  // Auction related
  uint256 internal constant THRESHOLD_NOT_REACHED = 1000;

  // Misc
  uint256 internal constant CALL_FAILED = 1997;
  uint256 internal constant UNIMPLEMENTED = 1998;
  uint256 internal constant SHOULD_NOT_HAPPEN = 1999;
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

pragma solidity ^0.8.17;

import "../Errors.sol";
import "./LogExpMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
  using SafeCast for uint256;
  using SafeCast for int256;

  uint256 internal constant ONE = 1e18; // 18 decimal places
  uint256 internal constant TWO = 2 * ONE;
  uint256 internal constant FOUR = 4 * ONE;
  uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

  // Minimum base for the power function when the exponent is 'free' (larger than ONE).
  uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

  function abs(int256 a) internal pure returns (uint256 result) {
    // Equivalent to:
    // result = a > 0 ? ua.toInt256() : uint256(-a)
    assembly {
      let s := sar(255, a)
      result := sub(xor(a, s), s)
    }
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    // Fixed Point addition is the same as regular checked addition

    uint256 c = a + b;
    _require(c >= a, Errors.ADD_OVERFLOW);
    return c;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    _require((b >= 0 && c >= a) || (b < 0 && c < a), Errors.ADD_OVERFLOW);
    return c;
  }

  function add(uint256 a, int256 b) internal pure returns (int256) {
    return add(a.toInt256(), b);
  }

  function add(int256 a, uint256 b) internal pure returns (int256) {
    return add(a, b.toInt256());
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    // Fixed Point addition is the same as regular checked addition

    _require(b <= a, Errors.SUB_OVERFLOW);
    uint256 c = a - b;
    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    _require((b >= 0 && c <= a) || (b < 0 && c > a), Errors.SUB_OVERFLOW);
    return c;
  }

  function sub(uint256 a, int256 b) internal pure returns (int256) {
    return sub(a.toInt256(), b);
  }

  function sub(int256 a, uint256 b) internal pure returns (int256) {
    return sub(a, b.toInt256());
  }

  function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 product = a * b;
    _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

    return product / ONE;
  }

  function mulDown(int256 a, int256 b) internal pure returns (int256) {
    int256 product = a * b;
    _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

    return product / int256(ONE);
  }

  function mulDown(uint256 a, int256 b) internal pure returns (int256) {
    return mulDown(a.toInt256(), b);
  }

  function mulDown(int256 a, uint256 b) internal pure returns (int256) {
    return mulDown(a, b.toInt256());
  }

  function mulUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
    uint256 product = a * b;
    _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

    // The traditional divUp formula is:
    // divUp(x, y) := (x + y - 1) / y
    // To avoid intermediate overflow in the addition, we distribute the division and get:
    // divUp(x, y) := (x - 1) / y + 1
    // Note that this requires x != 0, if x == 0 then the result is zero
    //
    // Equivalent to:
    // result = product == 0 ? 0 : ((product - 1) / FixedPoint.ONE) + 1;
    assembly {
      result := mul(iszero(iszero(product)), add(div(sub(product, 1), ONE), 1))
    }
  }

  function mulUp(int256 a, int256 b) internal pure returns (int256 result) {
    int256 product = a * b;
    _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

    // The traditional divUp formula is:
    // divUp(x, y) := (x + y - 1) / y
    // To avoid intermediate overflow in the addition, we distribute the division and get:
    // divUp(x, y) := (x - 1) / y + 1
    // Note that this requires x != 0, if x == 0 then the result is zero
    //
    // Equivalent to:
    // result = product == 0 ? 0 : ((product - 1) / FixedPoint.ONE) + 1;
    assembly {
      result := mul(iszero(iszero(product)), add(div(sub(product, 1), ONE), 1))
    }
  }

  function mulUp(uint256 a, int256 b) internal pure returns (int256) {
    return mulUp(a.toInt256(), b);
  }

  function mulUp(int256 a, uint256 b) internal pure returns (int256) {
    return mulDown(a, b.toInt256());
  }

  function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
    _require(b != 0, Errors.ZERO_DIVISION);

    uint256 aInflated = a * ONE;
    _require(a == 0 || aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

    return aInflated / b;
  }

  function divDown(int256 a, int256 b) internal pure returns (int256) {
    _require(b != 0, Errors.ZERO_DIVISION);

    int256 aInflated = a * int256(ONE);
    _require(a == 0 || aInflated / a == int256(ONE), Errors.DIV_INTERNAL); // mul overflow

    return aInflated / b;
  }

  function divDown(uint256 a, int256 b) internal pure returns (int256) {
    return divDown(a.toInt256(), b);
  }

  function divDown(int256 a, uint256 b) internal pure returns (int256) {
    return divDown(a, b.toInt256());
  }

  function divUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
    _require(b != 0, Errors.ZERO_DIVISION);

    uint256 aInflated = a * ONE;
    _require(a == 0 || aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

    // The traditional divUp formula is:
    // divUp(x, y) := (x + y - 1) / y
    // To avoid intermediate overflow in the addition, we distribute the division and get:
    // divUp(x, y) := (x - 1) / y + 1
    // Note that this requires x != 0, if x == 0 then the result is zero
    //
    // Equivalent to:
    // result = a == 0 ? 0 : (a * FixedPoint.ONE - 1) / b + 1;
    assembly {
      result := mul(
        iszero(iszero(aInflated)),
        add(div(sub(aInflated, 1), b), 1)
      )
    }
  }

  /**
   * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
   * the true value (that is, the error function expected - actual is always positive).
   */
  function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
    // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
    // and 80/20 Weighted Pools
    if (y == ONE) {
      return x;
    } else if (y == TWO) {
      return mulDown(x, x);
    } else if (y == FOUR) {
      uint256 square = mulDown(x, x);
      return mulDown(square, square);
    } else {
      uint256 raw = LogExpMath.pow(x, y);
      uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), uint256(1));

      if (raw < maxError) {
        return 0;
      } else {
        return sub(raw, maxError);
      }
    }
  }

  /**
   * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
   * the true value (that is, the error function expected - actual is always negative).
   */
  function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
    // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
    // and 80/20 Weighted Pools
    if (y == ONE) {
      return x;
    } else if (y == TWO) {
      return mulUp(x, x);
    } else if (y == FOUR) {
      uint256 square = mulUp(x, x);
      return mulUp(square, square);
    } else {
      uint256 raw = LogExpMath.pow(x, y);
      uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), uint256(1));

      return add(raw, maxError);
    }
  }

  /**
   * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
   *
   * Useful when computing the complement for values with some level of relative error, as it strips this error and
   * prevents intermediate negative values.
   */
  function complement(uint256 x) internal pure returns (uint256 result) {
    // Equivalent to:
    // result = (x < ONE) ? (ONE - x) : 0;
    assembly {
      result := mul(lt(x, ONE), sub(ONE, x))
    }
  }

  /**
   * @dev Returns the largest of two numbers of 256 bits.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256 result) {
    // Equivalent to:
    // result = (a < b) ? b : a;
    assembly {
      result := sub(a, mul(sub(a, b), lt(a, b)))
    }
  }

  function max(int256 a, int256 b) internal pure returns (int256 result) {
    // Equivalent to:
    // result = (a < b) ? b : a;
    assembly {
      result := sub(a, mul(sub(a, b), lt(a, b)))
    }
  }

  function max(uint256 a, int256 b) internal pure returns (int256 result) {
    return max(a.toInt256(), b);
  }

  function max(int256 a, uint256 b) internal pure returns (int256 result) {
    return max(a, b.toInt256());
  }

  /**
   * @dev Returns the smallest of two numbers of 256 bits.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256 result) {
    // Equivalent to `result = (a < b) ? a : b`
    assembly {
      result := sub(a, mul(sub(a, b), gt(a, b)))
    }
  }

  function min(int256 a, int256 b) internal pure returns (int256 result) {
    // Equivalent to `result = (a < b) ? a : b`
    assembly {
      result := sub(a, mul(sub(a, b), gt(a, b)))
    }
  }

  function min(uint256 a, int256 b) internal pure returns (int256 result) {
    return min(a.toInt256(), b);
  }

  function min(int256 a, uint256 b) internal pure returns (int256 result) {
    return min(a, b.toInt256());
  }
}

// SPDX-License-Identifier: MIT
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.17;

import "../Errors.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
  // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
  // two numbers, and multiply by ONE when dividing them.

  // All arguments and return values are 18 decimal fixed point numbers.
  int256 constant ONE_18 = 1e18;

  // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
  // case of ln36, 36 decimals.
  int256 constant ONE_20 = 1e20;
  int256 constant ONE_36 = 1e36;

  // The domain of natural exponentiation is bound by the word size and number of decimals used.
  //
  // Because internally the result will be stored using 20 decimals, the largest possible result is
  // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
  // The smallest possible result is 10^(-18), which makes largest negative argument
  // ln(10^(-18)) = -41.446531673892822312.
  // We use 130.0 and -41.0 to have some safety margin.
  int256 constant MAX_NATURAL_EXPONENT = 130e18;
  int256 constant MIN_NATURAL_EXPONENT = -41e18;

  // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
  // 256 bit integer.
  int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
  int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

  uint256 constant MILD_EXPONENT_BOUND = 2 ** 254 / uint256(ONE_20);

  // 18 decimal constants
  int256 constant x0 = 128000000000000000000; // 2ˆ7
  int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
  int256 constant x1 = 64000000000000000000; // 2ˆ6
  int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

  // 20 decimal constants
  int256 constant x2 = 3200000000000000000000; // 2ˆ5
  int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
  int256 constant x3 = 1600000000000000000000; // 2ˆ4
  int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
  int256 constant x4 = 800000000000000000000; // 2ˆ3
  int256 constant a4 = 298095798704172827474000; // eˆ(x4)
  int256 constant x5 = 400000000000000000000; // 2ˆ2
  int256 constant a5 = 5459815003314423907810; // eˆ(x5)
  int256 constant x6 = 200000000000000000000; // 2ˆ1
  int256 constant a6 = 738905609893065022723; // eˆ(x6)
  int256 constant x7 = 100000000000000000000; // 2ˆ0
  int256 constant a7 = 271828182845904523536; // eˆ(x7)
  int256 constant x8 = 50000000000000000000; // 2ˆ-1
  int256 constant a8 = 164872127070012814685; // eˆ(x8)
  int256 constant x9 = 25000000000000000000; // 2ˆ-2
  int256 constant a9 = 128402541668774148407; // eˆ(x9)
  int256 constant x10 = 12500000000000000000; // 2ˆ-3
  int256 constant a10 = 113314845306682631683; // eˆ(x10)
  int256 constant x11 = 6250000000000000000; // 2ˆ-4
  int256 constant a11 = 106449445891785942956; // eˆ(x11)

  /**
   * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
   *
   * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
   */
  function pow(uint256 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) {
      // We solve the 0^0 indetermination by making it equal one.
      return uint256(ONE_18);
    }

    if (x == 0) {
      return 0;
    }

    // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
    // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
    // x^y = exp(y * ln(x)).

    // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
    _require(x >> 255 == 0, Errors.X_OUT_OF_BOUNDS);
    int256 x_int256 = int256(x);

    // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
    // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

    // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
    _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
    int256 y_int256 = int256(y);

    int256 logx_times_y;
    if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
      int256 ln_36_x = _ln_36(x_int256);

      // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
      // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
      // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
      // (downscaled) last 18 decimals.
      logx_times_y = ((ln_36_x / ONE_18) *
        y_int256 +
        ((ln_36_x % ONE_18) * y_int256) /
        ONE_18);
    } else {
      logx_times_y = _ln(x_int256) * y_int256;
    }
    logx_times_y /= ONE_18;

    // Finally, we compute exp(y * ln(x)) to arrive at x^y
    _require(
      MIN_NATURAL_EXPONENT <= logx_times_y &&
        logx_times_y <= MAX_NATURAL_EXPONENT,
      Errors.PRODUCT_OUT_OF_BOUNDS
    );

    return uint256(exp(logx_times_y));
  }

  /**
   * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
   *
   * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
   */
  function exp(int256 x) internal pure returns (int256) {
    _require(
      x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT,
      Errors.INVALID_EXPONENT
    );

    if (x < 0) {
      // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
      // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
      // Fixed point division requires multiplying by ONE_18.
      return ((ONE_18 * ONE_18) / exp(-x));
    }

    // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
    // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
    // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
    // decomposition.
    // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
    // decomposition, which will be lower than the smallest x_n.
    // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
    // We mutate x by subtracting x_n, making it the remainder of the decomposition.

    // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
    // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
    // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
    // decomposition.

    // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
    // it and compute the accumulated product.

    int256 firstAN;
    if (x >= x0) {
      x -= x0;
      firstAN = a0;
    } else if (x >= x1) {
      x -= x1;
      firstAN = a1;
    } else {
      firstAN = 1; // One with no decimal places
    }

    // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
    // smaller terms.
    x *= 100;

    // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
    // one. Recall that fixed point multiplication requires dividing by ONE_20.
    int256 product = ONE_20;

    if (x >= x2) {
      x -= x2;
      product = (product * a2) / ONE_20;
    }
    if (x >= x3) {
      x -= x3;
      product = (product * a3) / ONE_20;
    }
    if (x >= x4) {
      x -= x4;
      product = (product * a4) / ONE_20;
    }
    if (x >= x5) {
      x -= x5;
      product = (product * a5) / ONE_20;
    }
    if (x >= x6) {
      x -= x6;
      product = (product * a6) / ONE_20;
    }
    if (x >= x7) {
      x -= x7;
      product = (product * a7) / ONE_20;
    }
    if (x >= x8) {
      x -= x8;
      product = (product * a8) / ONE_20;
    }
    if (x >= x9) {
      x -= x9;
      product = (product * a9) / ONE_20;
    }

    // x10 and x11 are unnecessary here since we have high enough precision already.

    // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
    // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

    int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
    int256 term; // Each term in the sum, where the nth term is (x^n / n!).

    // The first term is simply x.
    term = x;
    seriesSum += term;

    // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
    // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

    term = ((term * x) / ONE_20) / 2;
    seriesSum += term;

    term = ((term * x) / ONE_20) / 3;
    seriesSum += term;

    term = ((term * x) / ONE_20) / 4;
    seriesSum += term;

    term = ((term * x) / ONE_20) / 5;
    seriesSum += term;

    term = ((term * x) / ONE_20) / 6;
    seriesSum += term;

    term = ((term * x) / ONE_20) / 7;
    seriesSum += term;

    term = ((term * x) / ONE_20) / 8;
    seriesSum += term;

    term = ((term * x) / ONE_20) / 9;
    seriesSum += term;

    term = ((term * x) / ONE_20) / 10;
    seriesSum += term;

    term = ((term * x) / ONE_20) / 11;
    seriesSum += term;

    term = ((term * x) / ONE_20) / 12;
    seriesSum += term;

    // 12 Taylor terms are sufficient for 18 decimal precision.

    // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
    // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
    // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
    // and then drop two digits to return an 18 decimal value.

    return (((product * seriesSum) / ONE_20) * firstAN) / 100;
  }

  /**
   * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
   */
  function log(int256 arg, int256 base) internal pure returns (int256) {
    // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

    // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
    // upscaling.

    int256 logBase;
    if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
      logBase = _ln_36(base);
    } else {
      logBase = _ln(base) * ONE_18;
    }

    int256 logArg;
    if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
      logArg = _ln_36(arg);
    } else {
      logArg = _ln(arg) * ONE_18;
    }

    // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
    return (logArg * ONE_18) / logBase;
  }

  /**
   * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
   */
  function ln(int256 a) internal pure returns (int256) {
    // The real natural logarithm is not defined for negative numbers or zero.
    _require(a > 0, Errors.OUT_OF_BOUNDS);
    if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
      return _ln_36(a) / ONE_18;
    } else {
      return _ln(a);
    }
  }

  /**
   * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
   */
  function _ln(int256 a) private pure returns (int256) {
    if (a < ONE_18) {
      // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
      // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
      // Fixed point division requires multiplying by ONE_18.
      return (-_ln((ONE_18 * ONE_18) / a));
    }

    // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
    // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
    // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
    // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
    // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
    // decomposition, which will be lower than the smallest a_n.
    // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
    // We mutate a by subtracting a_n, making it the remainder of the decomposition.

    // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
    // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
    // ONE_18 to convert them to fixed point.
    // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
    // by it and compute the accumulated sum.

    int256 sum = 0;
    if (a >= a0 * ONE_18) {
      a /= a0; // Integer, not fixed point division
      sum += x0;
    }

    if (a >= a1 * ONE_18) {
      a /= a1; // Integer, not fixed point division
      sum += x1;
    }

    // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
    sum *= 100;
    a *= 100;

    // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

    if (a >= a2) {
      a = (a * ONE_20) / a2;
      sum += x2;
    }

    if (a >= a3) {
      a = (a * ONE_20) / a3;
      sum += x3;
    }

    if (a >= a4) {
      a = (a * ONE_20) / a4;
      sum += x4;
    }

    if (a >= a5) {
      a = (a * ONE_20) / a5;
      sum += x5;
    }

    if (a >= a6) {
      a = (a * ONE_20) / a6;
      sum += x6;
    }

    if (a >= a7) {
      a = (a * ONE_20) / a7;
      sum += x7;
    }

    if (a >= a8) {
      a = (a * ONE_20) / a8;
      sum += x8;
    }

    if (a >= a9) {
      a = (a * ONE_20) / a9;
      sum += x9;
    }

    if (a >= a10) {
      a = (a * ONE_20) / a10;
      sum += x10;
    }

    if (a >= a11) {
      a = (a * ONE_20) / a11;
      sum += x11;
    }

    // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
    // that converges rapidly for values of `a` close to one - the same one used in ln_36.
    // Let z = (a - 1) / (a + 1).
    // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

    // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
    // division by ONE_20.
    int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
    int256 z_squared = (z * z) / ONE_20;

    // num is the numerator of the series: the z^(2 * n + 1) term
    int256 num = z;

    // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
    int256 seriesSum = num;

    // In each step, the numerator is multiplied by z^2
    num = (num * z_squared) / ONE_20;
    seriesSum += num / 3;

    num = (num * z_squared) / ONE_20;
    seriesSum += num / 5;

    num = (num * z_squared) / ONE_20;
    seriesSum += num / 7;

    num = (num * z_squared) / ONE_20;
    seriesSum += num / 9;

    num = (num * z_squared) / ONE_20;
    seriesSum += num / 11;

    // 6 Taylor terms are sufficient for 36 decimal precision.

    // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
    seriesSum *= 2;

    // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
    // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
    // value.

    return (sum + seriesSum) / 100;
  }

  /**
   * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
   * for x close to one.
   *
   * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
   */
  function _ln_36(int256 x) private pure returns (int256) {
    // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
    // worthwhile.

    // First, we transform x to a 36 digit fixed point value.
    x *= ONE_18;

    // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
    // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

    // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
    // division by ONE_36.
    int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
    int256 z_squared = (z * z) / ONE_36;

    // num is the numerator of the series: the z^(2 * n + 1) term
    int256 num = z;

    // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
    int256 seriesSum = num;

    // In each step, the numerator is multiplied by z^2
    num = (num * z_squared) / ONE_36;
    seriesSum += num / 3;

    num = (num * z_squared) / ONE_36;
    seriesSum += num / 5;

    num = (num * z_squared) / ONE_36;
    seriesSum += num / 7;

    num = (num * z_squared) / ONE_36;
    seriesSum += num / 9;

    num = (num * z_squared) / ONE_36;
    seriesSum += num / 11;

    num = (num * z_squared) / ONE_36;
    seriesSum += num / 13;

    num = (num * z_squared) / ONE_36;
    seriesSum += num / 15;

    // 8 Taylor terms are sufficient for 36 decimal precision.

    // All that remains is multiplying by 2 (non fixed point).
    return seriesSum * 2;
  }
}

// SPDX-License-Identifier: BUSL-1.1

import "./interfaces/IRegistryCore.sol";
import "./interfaces/AbstractRegistry.sol";

pragma solidity ^0.8.17;

contract RegistryCore is AbstractRegistry, IRegistryCore {
  using SafeCast for uint256;
  using SafeCast for int256;
  using FixedPoint for uint256;
  using FixedPoint for int256;

  IFee internal fees;

  mapping(bytes32 => uint128) public fundingFeePerPriceId;
  mapping(bytes32 => uint128) public rolloverFeePerPriceId;

  mapping(bytes32 => SignedBalance) internal _longFundingFeePerPriceId;
  mapping(bytes32 => SignedBalance) internal _shortFundingFeePerPriceId;

  mapping(bytes32 => int128) internal _fundingFeeBaseByOrderHash;
  mapping(bytes32 => AccruedFee) internal _accruedFeeByOrderHash;

  mapping(bytes32 => uint128) public maxTotalLongPerPriceId;
  mapping(bytes32 => uint128) public maxTotalShortPerPriceId;

  uint64 public netFeeRebateLP;
  uint256 public minIncrement;
  uint256 public minBlockGap;

  mapping(address => mapping(uint128 => bytes32))
    public openTradeOrderHashesPerUser;

  event SetFeesEvent(address fees);
  event SetFundingFeeEvent(bytes32 priceId, uint256 fundingFee);
  event SetRolloverFeeEvent(bytes32 priceId, uint256 rolloverFee);
  event SetMaxTotalLongPerPriceId(bytes32 priceId, uint256 _maxLong);
  event SetMaxTotalShortPerPriceId(bytes32 priceId, uint256 _maxShort);
  event SetNetFeeRabateLP(uint256 _fee);
  event SetMinIncrementEvent(uint256 _minIncrement);
  event SetMinBlockGapEvent(uint256 _minBlockGap);

  function initialize(
    address _owner,
    uint16 _maxOpenTradesPerPriceId,
    uint16 _maxOpenTradesPerUser,
    uint128 _maxMarginPerUser,
    uint128 _minPositionPerTrade,
    uint64 _liquidationPenalty,
    uint128 _maxPercentagePnLFactor,
    uint128 _stopFee,
    IFee _fees
  ) external initializer {
    __AbstractRegistry_init(
      _owner,
      _maxOpenTradesPerPriceId,
      _maxOpenTradesPerUser,
      _maxMarginPerUser,
      _minPositionPerTrade,
      _liquidationPenalty,
      _maxPercentagePnLFactor,
      _stopFee,
      0
    );
    fees = _fees;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // external functions

  function getFee() external view override returns (uint256) {
    _revert(Errors.UNIMPLEMENTED);
  }

  function getOpenFee(
    address _user
  ) external view override returns (IFee.Fee memory) {
    return fees.getOpenFee(_user);
  }

  function getCloseFee(
    address _user
  ) external view override returns (IFee.Fee memory) {
    return fees.getCloseFee(_user);
  }

  function getAccumulatedFee(
    bytes32 orderHash,
    uint64 closePercent
  ) external view override returns (int128 fundingFee, uint128 rolloverFee) {
    _require(closePercent <= 1e18, Errors.INVALID_CLOSE_PERCENT);
    Trade memory trade = _openTradeByOrderHash(orderHash);
    (, AccruedFee memory accruedFee) = _getAccumulatedFee(
      orderHash,
      trade.priceId,
      trade.isBuy,
      trade.leverage,
      trade.margin
    );
    fundingFee = int256(accruedFee.fundingFee).mulDown(closePercent).toInt128();
    rolloverFee = uint256(accruedFee.rolloverFee)
      .mulDown(closePercent)
      .toUint128();
  }

  function longFundingFeePerPriceId(
    bytes32 priceId
  ) external view returns (SignedBalance memory) {
    return _longFundingFeePerPriceId[priceId];
  }

  function shortFundingFeePerPriceId(
    bytes32 priceId
  ) external view returns (SignedBalance memory) {
    return _shortFundingFeePerPriceId[priceId];
  }

  function fundingFeeBaseByOrderHash(
    bytes32 orderHash
  ) external view returns (int256) {
    return _fundingFeeBaseByOrderHash[orderHash];
  }

  function accruedFeeByOrderHash(
    bytes32 orderHash
  ) external view returns (AccruedFee memory) {
    return _accruedFeeByOrderHash[orderHash];
  }

  function onOrderUpdate(
    bytes32 orderHash
  ) external view override returns (OnOrderUpdate memory _onOrderUpdate) {
    Trade memory trade = _openTradeByOrderHash(orderHash);
    _onOrderUpdate.feeBalance = trade.isBuy
      ? _longFundingFeePerPriceId[trade.priceId]
      : _shortFundingFeePerPriceId[trade.priceId];
    _onOrderUpdate.feeBase = _fundingFeeBaseByOrderHash[orderHash];
    _onOrderUpdate.accruedFee = _accruedFeeByOrderHash[orderHash];
  }

  function updateTrade(
    bytes32 orderHash,
    uint128 closePrice,
    uint128 margin,
    bool isAdd,
    uint256 liquidityBalance
  ) external view override returns (Trade memory trade) {
    return _updateTrade(orderHash, closePrice, margin, isAdd, liquidityBalance);
  }

  function updateStop(
    bytes32 orderHash,
    uint128 closePrice,
    uint128 profitTarget,
    uint128 stopLoss
  ) external view returns (Trade memory trade) {
    return _updateStop(orderHash, closePrice, profitTarget, stopLoss);
  }

  function openTradeOrderHashesByUser(
    address user
  ) external view returns (bytes32[] memory orderHashes) {
    uint128 count = openTradesPerUserCount[user];
    orderHashes = new bytes32[](count);
    for (uint128 i = 0; i < count; ++i) {
      orderHashes[i] = openTradeOrderHashesPerUser[user][i];
    }
  }

  // governance functions

  function setNetFeeRabateLP(uint64 _netFeeRebateLP) external onlyOwner {
    _require(
      _netFeeRebateLP >= 0 && _netFeeRebateLP <= 1e18,
      Errors.INVALID_FEE_FACTOR
    );
    netFeeRebateLP = _netFeeRebateLP;
    emit SetNetFeeRabateLP(netFeeRebateLP);
  }

  function setMaxTotalLongPerPriceId(
    bytes32 priceId,
    uint128 _maxLong
  ) external onlyOwner {
    maxTotalLongPerPriceId[priceId] = _maxLong;
    emit SetMaxTotalLongPerPriceId(priceId, _maxLong);
  }

  function setMaxTotalShortPerPriceId(
    bytes32 priceId,
    uint128 _maxShort
  ) external onlyOwner {
    maxTotalShortPerPriceId[priceId] = _maxShort;
    emit SetMaxTotalShortPerPriceId(priceId, _maxShort);
  }

  function setFees(IFee _fees) external onlyOwner {
    fees = _fees;
    emit SetFeesEvent(address(fees));
  }

  function setFundingFeePerPriceId(
    bytes32 priceId,
    uint128 _fundingFee
  ) external onlyOwner {
    fundingFeePerPriceId[priceId] = _fundingFee;
    emit SetFundingFeeEvent(priceId, _fundingFee);
  }

  function setRolloverFeePerPriceId(
    bytes32 priceId,
    uint128 _rolloverFee
  ) external onlyOwner {
    rolloverFeePerPriceId[priceId] = _rolloverFee;
    emit SetRolloverFeeEvent(priceId, _rolloverFee);
  }

  function setMinIncrement(uint256 _minIncrement) external onlyOwner {
    minIncrement = _minIncrement;
    emit SetMinIncrementEvent(minIncrement);
  }

  function setMinBlockGap(uint256 _minBlockGap) external onlyOwner {
    minBlockGap = _minBlockGap;
    emit SetMinBlockGapEvent(minBlockGap);
  }

  // privilidged functions

  function openMarketOrder(
    Trade memory trade
  )
    external
    override(IRegistry, AbstractRegistry)
    onlyRole(APPROVED_ROLE)
    onlyApprovedPriceId(trade.priceId)
    returns (bytes32)
  {
    salt++;
    trade.salt = salt;
    bytes32 orderHash = keccak256(abi.encode(trade));
    openTradesPerPriceIdCount[trade.user][trade.priceId]++;
    // _addOrderHashToOpenTrades(trade.user, orderHash);
    totalMarginPerUser[trade.user] += trade.margin;

    _accruedFeeByOrderHash[orderHash].lastUpdate = trade.executionBlock;

    _updateFundingFeeBalance(
      orderHash,
      trade.priceId,
      trade.isBuy,
      uint128(0),
      uint128(0),
      trade.leverage,
      trade.margin
    );

    // audit(B): L05
    minCollateral += uint256(trade.margin)
      .mulDown(trade.maxPercentagePnL)
      .toUint128();

    __openTradeByOrderHash[orderHash] = trade;

    return orderHash;
  }

  function closeMarketOrder(
    bytes32 orderHash,
    uint64 closePercent
  ) external override(AbstractRegistry, IRegistry) onlyRole(APPROVED_ROLE) {
    Trade memory t = _openTradeByOrderHash(orderHash);
    uint256 closeMargin = uint256(t.margin).mulDown(closePercent);

    totalMarginPerUser[t.user] = uint256(totalMarginPerUser[t.user])
      .sub(closeMargin)
      .toUint128();
    minCollateral -= uint256(closeMargin)
      .mulDown(uint256(t.maxPercentagePnL))
      .toUint128();

    _updateFundingFeeBalance(
      orderHash,
      t.priceId,
      t.isBuy,
      t.leverage,
      t.margin,
      t.leverage,
      uint256(t.margin).sub(closeMargin).toUint128()
    );

    if (closePercent == 1e18) {
      openTradesPerPriceIdCount[t.user][t.priceId]--;
      _removeOrderHashFromOpenTrades(t.user, orderHash);
      delete __openTradeByOrderHash[orderHash];
      delete _fundingFeeBaseByOrderHash[orderHash];
      delete _accruedFeeByOrderHash[orderHash];
    } else {
      t.margin -= closeMargin.toUint128();
      __openTradeByOrderHash[orderHash] = t;
    }
  }

  function updateOpenOrder(
    bytes32 orderHash,
    Trade memory trade
  ) external override(AbstractRegistry, IRegistry) onlyRole(APPROVED_ROLE) {
    Trade memory t = __openTradeByOrderHash[orderHash];

    _require(t.user == trade.user, Errors.TRADER_OWNER_MISMATCH);
    _require(t.priceId == trade.priceId, Errors.PRICE_ID_MISMATCH);
    _require(t.isBuy == trade.isBuy, Errors.TRADE_DIRECTION_MISMATCH);
    // audit(M): lack of check of salt
    _require(t.salt == trade.salt, Errors.TRADE_SALT_MISMATCH);

    _updateFundingFeeBalance(
      orderHash,
      t.priceId,
      t.isBuy,
      t.leverage,
      t.margin,
      trade.leverage,
      trade.margin
    );

    totalMarginPerUser[trade.user] = uint256(totalMarginPerUser[trade.user])
      .sub(t.margin)
      .add(trade.margin)
      .toUint128();
    minCollateral -= uint256(t.margin).mulDown(t.maxPercentagePnL).toUint128();
    // audit(B): M02, L05
    minCollateral += uint256(trade.margin)
      .mulDown(trade.maxPercentagePnL)
      .toUint128();

    __openTradeByOrderHash[orderHash] = trade;
  }

  // internal functions

  function _addOrderHashToOpenTrades(address user, bytes32 orderHash) internal {
    openTradeOrderHashesPerUser[user][openTradesPerUserCount[user]] = orderHash;
    openTradesPerUserCount[user]++;
  }

  function _removeOrderHashFromOpenTrades(
    address user,
    bytes32 orderHash
  ) internal {
    uint128 tradeCount = openTradesPerUserCount[user];

    uint128 index = tradeCount;
    for (uint128 i = 0; i < tradeCount; ++i) {
      if (openTradeOrderHashesPerUser[user][i] == orderHash) {
        index = i;
        break;
      }
    }

    bool isNotFound = index >= tradeCount;
    if (isNotFound) return;

    if (index != tradeCount - 1) {
      // swap with last element
      openTradeOrderHashesPerUser[user][index] = openTradeOrderHashesPerUser[
        user
      ][tradeCount - 1];
    }
    // delete last element
    delete openTradeOrderHashesPerUser[user][tradeCount - 1];
    openTradesPerUserCount[user]--;
  }

  function _updateFundingFeeBalance(
    bytes32 orderHash,
    bytes32 priceId,
    bool isBuy,
    uint128 oldLeverage,
    uint128 oldMargin,
    uint128 newLeverage,
    uint128 newMargin
  ) internal {
    (, AccruedFee memory _accruedFee) = _getAccumulatedFee(
      orderHash,
      priceId,
      isBuy,
      oldLeverage,
      oldMargin
    );

    // uint256 _totalPosition = isBuy
    //   ? totalLongPerPriceId[priceId]
    //   : totalShortPerPriceId[priceId];

    // // simulate out
    // _fundingFee.balance = int256(_fundingFee.balance)
    //   .sub(_accruedFee.fundingFee)
    //   .add(_accruedFeeByOrderHash[orderHash].fundingFee)
    //   .sub(_fundingFeeBaseByOrderHash[orderHash])
    //   .toInt128();

    // _totalPosition = _totalPosition.sub(
    //   uint256(oldLeverage).mulDown(oldMargin)
    // );

    if (uint256(oldLeverage).mulDown(oldMargin) > 0) {
      uint256 ratio = uint256(newLeverage)
        .mulDown(newMargin)
        .divDown(oldLeverage)
        .divDown(oldMargin);
      // _accruedFee.fundingFee = int256(_accruedFee.fundingFee)
      //   .mulDown(ratio)
      //   .toInt128();
      _accruedFee.rolloverFee = uint256(_accruedFee.rolloverFee)
        .mulDown(ratio)
        .toUint128();
    }

    // // simulate in
    // _fundingFeeBaseByOrderHash[orderHash] = _totalPosition > 0
    //   ? int256(_fundingFee.balance)
    //     .mulDown(newLeverage)
    //     .mulDown(newMargin)
    //     .divDown(_totalPosition)
    //     .toInt128()
    //   : _fundingFee.balance;

    // _fundingFee.balance = int256(_fundingFee.balance)
    //   .add(_fundingFeeBaseByOrderHash[orderHash])
    //   .toInt128();
    // _totalPosition = _totalPosition.add(
    //   uint256(newLeverage).mulDown(newMargin)
    // );

    _accruedFeeByOrderHash[orderHash] = _accruedFee;

    // if (isBuy) {
    //   _longFundingFeePerPriceId[priceId] = _fundingFee;
    //   _shortFundingFeePerPriceId[priceId] = _getLatestFundingFeeBalance(
    //     _shortFundingFeePerPriceId[priceId],
    //     totalShortPerPriceId[priceId],
    //     totalLongPerPriceId[priceId],
    //     fundingFeePerPriceId[priceId]
    //   );
    //   totalLongPerPriceId[priceId] = _totalPosition.toUint128();
    // } else {
    //   _shortFundingFeePerPriceId[priceId] = _fundingFee;
    //   _longFundingFeePerPriceId[priceId] = _getLatestFundingFeeBalance(
    //     _longFundingFeePerPriceId[priceId],
    //     totalLongPerPriceId[priceId],
    //     totalShortPerPriceId[priceId],
    //     fundingFeePerPriceId[priceId]
    //   );
    //   totalShortPerPriceId[priceId] = _totalPosition.toUint128();
    // }
  }

  // function _getLatestFundingFeeBalance(
  //   SignedBalance memory fundingFee,
  //   uint256 totalPositionM,
  //   uint256 totalPositionT,
  //   uint128 fundingFeePerBlock
  // ) internal view returns (SignedBalance memory) {
  //   if (fundingFee.lastUpdate > 0)
  //     fundingFee.balance = int256(fundingFee.balance)
  //       .add(
  //         uint256(fundingFeePerBlock).mulDown(
  //           int256(totalPositionM).sub(totalPositionT)
  //         ) * (block.number.sub(uint256(fundingFee.lastUpdate))).toInt256()
  //       )
  //       .toInt128();
  //   fundingFee.lastUpdate = block.number.toUint32();
  //   return fundingFee;
  // }

  function _getAccumulatedFee(
    bytes32 orderHash,
    bytes32 priceId,
    bool isBuy,
    uint128 leverage,
    uint128 margin
  )
    internal
    view
    returns (SignedBalance memory fundingFee, AccruedFee memory accruedFee)
  {
    // uint256 _totalPosition = isBuy
    //   ? totalLongPerPriceId[priceId]
    //   : totalShortPerPriceId[priceId];
    // fundingFee = isBuy
    //   ? _getLatestFundingFeeBalance(
    //     _longFundingFeePerPriceId[priceId],
    //     _totalPosition,
    //     totalShortPerPriceId[priceId],
    //     fundingFeePerPriceId[priceId]
    //   )
    //   : _getLatestFundingFeeBalance(
    //     _shortFundingFeePerPriceId[priceId],
    //     _totalPosition,
    //     totalLongPerPriceId[priceId],
    //     fundingFeePerPriceId[priceId]
    //   );

    // int256 accruedFundingFee = 0;
    // if (_totalPosition > 0) {
    //   accruedFundingFee = int256(fundingFee.balance)
    //     .mulDown(leverage)
    //     .mulDown(margin)
    //     .divDown(_totalPosition)
    //     .sub(_fundingFeeBaseByOrderHash[orderHash]);
    // }

    accruedFee = _accruedFeeByOrderHash[orderHash];
    // accruedFee.fundingFee = int256(accruedFee.fundingFee)
    //   .add(accruedFundingFee)
    //   .toInt128();

    accruedFee.rolloverFee = uint256(accruedFee.rolloverFee)
      .add(
        uint256(rolloverFeePerPriceId[priceId]).mulDown(margin) *
          (block.number.sub(uint256(accruedFee.lastUpdate)))
      )
      .toUint128();
    accruedFee.lastUpdate = block.number.toUint32();
  }

  function _updateTrade(
    bytes32 orderHash,
    uint128 closePrice,
    uint128 margin,
    bool isAdd,
    uint256 liquidityBalance
  ) internal view returns (Trade memory trade) {
    trade = _openTradeByOrderHash(orderHash);

    uint256 position = uint256(trade.leverage).mulDown(trade.margin);
    (, AccruedFee memory accruedFee) = _getAccumulatedFee(
      orderHash,
      trade.priceId,
      trade.isBuy,
      trade.leverage,
      trade.margin
    );

    {
      if (isAdd) {
        _require(
          uint256(trade.margin).add(margin) <=
            position.divDown(minLeveragePerPriceId[trade.priceId]),
          Errors.INVALID_MARGIN
        );
        _require(
          uint256(totalMarginPerUser[trade.user]).add(margin) <
            maxMarginPerUser,
          Errors.MAX_MARGIN_PER_USER
        );
        _require(
          uint256(minCollateral).add(
            uint256(margin).mulDown(trade.maxPercentagePnL)
          ) <= liquidityBalance,
          Errors.MAX_LIQUIDITY_POOL
        );
        trade.margin = uint256(trade.margin).add(margin).toUint128();
      } else {
        _require(trade.margin > margin, Errors.INVALID_MARGIN);
        _require(
          uint256(trade.margin).sub(margin) >=
            position.divDown(maxLeveragePerPriceId[trade.priceId]),
          Errors.LEVERAGE_TOO_HIGH
        );
        trade.margin = uint256(trade.margin).sub(margin).toUint128();
      }
    }

    trade.leverage = position.divDown(trade.margin).toUint128();

    {
      int256 accumulatedFee = int256(accruedFee.fundingFee).add(
        uint256(accruedFee.rolloverFee)
      );

      if (trade.isBuy) {
        uint256 executionPrice = uint256(trade.openPrice).add(trade.slippage);
        int256 accumulatedFeePerPrice = executionPrice
          .mulDown(accumulatedFee)
          .divDown(position);
        trade.liquidationPrice = executionPrice
          .mulDown(
            uint256(trade.leverage)
              .sub(uint256(liquidationThresholdPerPriceId[trade.priceId]))
              .divDown(uint256(trade.leverage))
          )
          .toUint128();
        _require(
          closePrice >
            int256(uint256(trade.liquidationPrice).add(accumulatedFeePerPrice))
              .toUint256(),
          Errors.INVALID_MARGIN
        );
      } else {
        uint256 executionPrice = uint256(trade.openPrice).sub(trade.slippage);
        int256 accumulatedFeePerPrice = executionPrice
          .mulDown(accumulatedFee)
          .divDown(position);
        trade.liquidationPrice = executionPrice
          .mulDown(
            uint256(trade.leverage)
              .add(uint256(liquidationThresholdPerPriceId[trade.priceId]))
              .divDown(uint256(trade.leverage))
          )
          .toUint128();
        _require(
          closePrice <
            int256(uint256(trade.liquidationPrice).sub(accumulatedFeePerPrice))
              .toUint256(),
          Errors.INVALID_MARGIN
        );
      }
    }
  }

  function _updateStop(
    bytes32 orderHash,
    uint128 closePrice,
    uint128 profitTarget,
    uint128 stopLoss
  ) internal view returns (Trade memory trade) {
    trade = _openTradeByOrderHash(orderHash);

    uint256 closePosition = uint256(trade.leverage).mulDown(trade.margin);

    (, AccruedFee memory accruedFee) = _getAccumulatedFee(
      orderHash,
      trade.priceId,
      trade.isBuy,
      trade.leverage,
      trade.margin
    );

    int256 accumulatedFee = int256(accruedFee.fundingFee).add(
      accruedFee.rolloverFee
    );

    uint256 openNet = trade.isBuy
      ? uint256(trade.openPrice).add(trade.slippage)
      : uint256(trade.openPrice).sub(trade.slippage);

    uint256 closeNet = trade.isBuy
      ? int256(
        uint256(closePrice).sub(
          accumulatedFee.mulDown(openNet).divDown(closePosition)
        )
      ).toUint256()
      : int256(
        uint256(closePrice).add(
          accumulatedFee.mulDown(openNet).divDown(closePosition)
        )
      ).toUint256();

    _require(
      stopLoss == 0 ||
        (
          trade.isBuy
            ? uint256(stopLoss).add(minIncrement) < closeNet
            : uint256(stopLoss).sub(minIncrement) > closeNet
        ),
      Errors.INVALID_STOP_LOSS
    );
    _require(
      profitTarget == 0 ||
        (
          trade.isBuy
            ? uint256(profitTarget).sub(minIncrement) > closeNet
            : uint256(profitTarget).add(minIncrement) < closeNet
        ),
      Errors.INVALID_PROFIT_TARGET
    );

    trade.stopLoss = stopLoss;
    trade.profitTarget = profitTarget;
  }
}