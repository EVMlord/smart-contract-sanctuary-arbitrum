// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721ContractURI is Ownable {
    /// @notice Current metadata URI for the contract
    string private _contractURI;

    /// @notice Emitted when contractURI has changed
    event ContractURIUpdated(string uri);

    /**
     * Sets the current contractURI for the contract
     *
     * @param _uri New contract URI
     */
    function setContractURI(string calldata _uri) public onlyOwner {
        _contractURI = _uri;
        emit ContractURIUpdated(_uri);
    }

    /**
     * @return Contract metadata URI for the NFT contract, used by NFT marketplaces to display collection inf
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IERC721BeforeTokenTransferHandler.sol";

abstract contract ERC721OperatorFilter is Context, Ownable, ERC721 {
     /// @notice Reference to the handler contract for transfer hooks
    address public beforeTokenTransferHandler;

    /**
     * Sets the before token transfer handler
     *
     * @param handlerAddress  Address to the transfer hook handler contract
     */
    function setBeforeTokenTransferHandler(
        address handlerAddress
    ) external onlyOwner {
        beforeTokenTransferHandler = handlerAddress;
    }

    /**
     * @notice Handles any pre-transfer actions
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        if (beforeTokenTransferHandler != address(0)) {
            IERC721BeforeTokenTransferHandler handlerRef = IERC721BeforeTokenTransferHandler(
                    beforeTokenTransferHandler
                );
            handlerRef.beforeTokenTransfer(
                address(this),
                _msgSender(),
                from,
                to,
                tokenId,
                batchSize
            );
        }

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IERC721BeforeTokenTransferHandler {
    /**
     * Handles before token transfer events from a ERC721 contract
     */
    function beforeTokenTransfer(
        address tokenContract,
        address operator,
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * Handles before token transfer events from a ERC721 contract with newer OpenZepplin ERC721Consecutive implementation
     */
    function beforeTokenTransfer(
        address tokenContract,
        address operator,
        address from,
        address to,
        uint256 firstId,
        uint256 batchSize
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

bytes32 constant TRUSTED_MIRROR_ROLE = keccak256("TRUSTED_MIRROR_ROLE");
bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

/**
 * @title ERC721MirroredL2
 * An extension to ERC721 that allows for ownership to be mirrored from L1 to L2
 * This is meant to be used by contracts using GameRegistryConsumer, but any system can implement _checkRole
 * This is meant to be used with either an Oracle on L1, or an L1 to L2 handler
 */
abstract contract ERC721MirroredL2 is ERC721 {
    bool private _isCheckingRole = true;

    error Soulbound();

    /**
     * @param isCheckingRole Whether to check the TRUSTED_MIRROR_ROLE when transferring tokens
     */
    function setIsCheckingRole(bool isCheckingRole) external {
        _checkRole(MANAGER_ROLE, _msgSender());
        _isCheckingRole = isCheckingRole;
    }

    /**
     * Called by the Oracle or L1 to L2 handler, transfers the ownership.
     * Always checks the role regardless of wether the beforeTransferHook does
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param tokenId The token id to transfer
     */
    function mirrorOwnership(address from, address to, uint256 tokenId) external {
        _checkRole(TRUSTED_MIRROR_ROLE, _msgSender());

        if (from == address(0x0)) {
            _mint(to, tokenId);
        } else {
            _transfer(from, to, tokenId);
        }
    }

    /**
     * This will be included by GameRegistryConsumer which checks the gameRegistry for various roles
     * @param role The role to check
     * @param account The account to check
     */
    function _checkRole(bytes32 role, address account) internal virtual;


    /**
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721)
    {  
        if (_isCheckingRole) {
            _checkRole(TRUSTED_MIRROR_ROLE, _msgSender());
        }

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

// Used for calculating decimal-point percentages (10000 = 100%)
uint256 constant PERCENTAGE_RANGE = 10000;

// Pauser Role - Can pause the game
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

// Minter Role - Can mint items, NFTs, and ERC20 currency
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

// Manager Role - Can manage the shop, loot tables, and other game data
bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

// Game Logic Contract - Contract that executes game logic and accesses other systems
bytes32 constant GAME_LOGIC_CONTRACT_ROLE = keccak256(
    "GAME_LOGIC_CONTRACT_ROLE"
);

// Game Currency Contract - Allowlisted currency ERC20 contract
bytes32 constant GAME_CURRENCY_CONTRACT_ROLE = keccak256(
    "GAME_CURRENCY_CONTRACT_ROLE"
);

// Game NFT Contract - Allowlisted game NFT ERC721 contract
bytes32 constant GAME_NFT_CONTRACT_ROLE = keccak256("GAME_NFT_CONTRACT_ROLE");

// Game Items Contract - Allowlist game items ERC1155 contract
bytes32 constant GAME_ITEMS_CONTRACT_ROLE = keccak256(
    "GAME_ITEMS_CONTRACT_ROLE"
);

// Depositor role - used by Polygon bridge to mint on child chain
bytes32 constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

// Randomizer role - Used by the randomizer contract to callback
bytes32 constant RANDOMIZER_ROLE = keccak256("RANDOMIZER_ROLE");

// Trusted forwarder role - Used by meta transactions to verify trusted forwader(s)
bytes32 constant TRUSTED_FORWARDER_ROLE = keccak256("TRUSTED_FORWARDER_ROLE");

// =====
// All of the possible traits in the system
// =====

/// @dev Trait that points to another token/template id
uint256 constant TEMPLATE_ID_TRAIT_ID = uint256(keccak256("template_id"));

// Generation of a token
uint256 constant GENERATION_TRAIT_ID = uint256(keccak256("generation"));

// XP for a token
uint256 constant XP_TRAIT_ID = uint256(keccak256("xp"));

// Current level of a token
uint256 constant LEVEL_TRAIT_ID = uint256(keccak256("level"));

// Whether or not a token is a pirate
uint256 constant IS_PIRATE_TRAIT_ID = uint256(keccak256("is_pirate"));

// Whether or not a token is a ship
uint256 constant IS_SHIP_TRAIT_ID = uint256(keccak256("is_ship"));

// Whether or not an item is equippable on ships
uint256 constant EQUIPMENT_TYPE_TRAIT_ID = uint256(keccak256("equipment_type"));

// Combat modifiers for items and tokens
uint256 constant COMBAT_MODIFIERS_TRAIT_ID = uint256(
    keccak256("combat_modifiers")
);

// Animation URL for the token
uint256 constant ANIMATION_URL_TRAIT_ID = uint256(keccak256("animation_url"));

// Item slots
uint256 constant ITEM_SLOTS_TRAIT_ID = uint256(keccak256("item_slots"));

// Rank of the ship
uint256 constant SHIP_RANK_TRAIT_ID = uint256(keccak256("ship_rank"));

// Current Health trait
uint256 constant CURRENT_HEALTH_TRAIT_ID = uint256(keccak256("current_health"));

// Health trait
uint256 constant HEALTH_TRAIT_ID = uint256(keccak256("health"));

// Damage trait
uint256 constant DAMAGE_TRAIT_ID = uint256(keccak256("damage"));

// Speed trait
uint256 constant SPEED_TRAIT_ID = uint256(keccak256("speed"));

// Accuracy trait
uint256 constant ACCURACY_TRAIT_ID = uint256(keccak256("accuracy"));

// Evasion trait
uint256 constant EVASION_TRAIT_ID = uint256(keccak256("evasion"));

// Image hash of token's image, used for verifiable / fair drops
uint256 constant IMAGE_HASH_TRAIT_ID = uint256(keccak256("image_hash"));

// Name of a token
uint256 constant NAME_TRAIT_ID = uint256(keccak256("name_trait"));

// Description of a token
uint256 constant DESCRIPTION_TRAIT_ID = uint256(keccak256("description_trait"));

// General rarity for a token (corresponds to IGameRarity)
uint256 constant RARITY_TRAIT_ID = uint256(keccak256("rarity"));

// The character's affinity for a specific element
uint256 constant ELEMENTAL_AFFINITY_TRAIT_ID = uint256(
    keccak256("affinity_id")
);

// The character's expertise value
uint256 constant EXPERTISE_TRAIT_ID = uint256(keccak256("expertise_id"));

// Expertise damage mod ID from SoT
uint256 constant EXPERTISE_DAMAGE_ID = uint256(
    keccak256("expertise.levelmultiplier.damage")
);

// Expertise evasion mod ID from SoT
uint256 constant EXPERTISE_EVASION_ID = uint256(
    keccak256("expertise.levelmultiplier.evasion")
);

// Expertise speed mod ID from SoT
uint256 constant EXPERTISE_SPEED_ID = uint256(
    keccak256("expertise.levelmultiplier.speed")
);

// Expertise accuracy mod ID from SoT
uint256 constant EXPERTISE_ACCURACY_ID = uint256(
    keccak256("expertise.levelmultiplier.accuracy")
);

// Expertise health mod ID from SoT
uint256 constant EXPERTISE_HEALTH_ID = uint256(
    keccak256("expertise.levelmultiplier.health")
);

// Boss start time trait
uint256 constant BOSS_START_TIME_TRAIT_ID = uint256(
    keccak256("boss_start_time")
);

// Boss end time trait
uint256 constant BOSS_END_TIME_TRAIT_ID = uint256(keccak256("boss_end_time"));

// Boss type trait
uint256 constant BOSS_TYPE_TRAIT_ID = uint256(keccak256("boss_type"));

// The character's dice rolls
uint256 constant DICE_ROLL_1_TRAIT_ID = uint256(keccak256("dice_roll_1"));
uint256 constant DICE_ROLL_2_TRAIT_ID = uint256(keccak256("dice_roll_2"));

// The character's star sign (astrology)
uint256 constant STAR_SIGN_TRAIT_ID = uint256(keccak256("star_sign"));

// Image for the token
uint256 constant IMAGE_TRAIT_ID = uint256(keccak256("image_trait"));

// How much energy the token provides if used
uint256 constant ENERGY_PROVIDED_TRAIT_ID = uint256(
    keccak256("energy_provided")
);

// Whether a given token is soulbound, meaning it is unable to be transferred
uint256 constant SOULBOUND_TRAIT_ID = uint256(keccak256("soulbound"));

// ------
// Avatar Profile Picture related traits

// If an avatar is a 1 of 1, this is their only trait
uint256 constant PROFILE_IS_LEGENDARY_TRAIT_ID = uint256(
    keccak256("profile_is_legendary")
);

// Avatar's archetype -- possible values: Human (including Druid, Mage, Berserker, Crusty), Robot, Animal, Zombie, Vampire, Ghost
uint256 constant PROFILE_CHARACTER_TYPE = uint256(
    keccak256("profile_character_type")
);

// Avatar's profile picture's background image
uint256 constant PROFILE_BACKGROUND_TRAIT_ID = uint256(
    keccak256("profile_background")
);

// Avatar's eye style
uint256 constant PROFILE_EYES_TRAIT_ID = uint256(keccak256("profile_eyes"));

// Avatar's facial hair type
uint256 constant PROFILE_FACIAL_HAIR_TRAIT_ID = uint256(
    keccak256("profile_facial_hair")
);

// Avatar's hair style
uint256 constant PROFILE_HAIR_TRAIT_ID = uint256(keccak256("profile_hair"));

// Avatar's skin color
uint256 constant PROFILE_SKIN_TRAIT_ID = uint256(keccak256("profile_skin"));

// Avatar's coat color
uint256 constant PROFILE_COAT_TRAIT_ID = uint256(keccak256("profile_coat"));

// Avatar's earring(s) type
uint256 constant PROFILE_EARRING_TRAIT_ID = uint256(
    keccak256("profile_facial_hair")
);

// Avatar's eye covering
uint256 constant PROFILE_EYE_COVERING_TRAIT_ID = uint256(
    keccak256("profile_eye_covering")
);

// Avatar's headwear
uint256 constant PROFILE_HEADWEAR_TRAIT_ID = uint256(
    keccak256("profile_headwear")
);

// Avatar's (Mages only) gem color
uint256 constant PROFILE_MAGE_GEM_TRAIT_ID = uint256(
    keccak256("profile_mage_gem")
);

// ------
// Dungeon traits

// Whether this token template is a dungeon trigger
uint256 constant IS_DUNGEON_TRIGGER_TRAIT_ID = uint256(
    keccak256("is_dungeon_trigger")
);

// Dungeon start time trait
uint256 constant DUNGEON_START_TIME_TRAIT_ID = uint256(
    keccak256("dungeon.start_time")
);

// Dungeon end time trait
uint256 constant DUNGEON_END_TIME_TRAIT_ID = uint256(
    keccak256("dungeon.end_time")
);

// Dungeon SoT map id trait
uint256 constant DUNGEON_MAP_TRAIT_ID = uint256(keccak256("dungeon.map_id"));

// Whether this token template is a mob
uint256 constant IS_MOB_TRAIT_ID = uint256(keccak256("is_mob"));

// ------
// Island traits

// Whether a game item is placeable on an island
uint256 constant IS_PLACEABLE_TRAIT_ID = uint256(keccak256("is_placeable"));

// ------
// Extra traits for component migration
// NOTE: CURRENTLY NOT USED IN CONTRACTS CODE

uint256 constant MODEL_GLTF_URL_TRAIT_ID = uint256(keccak256("model_gltf_url"));
uint256 constant PLACEABLE_CATEGORY_TRAIT_ID = uint256(
    keccak256("placeable_category")
);
uint256 constant PLACEABLE_IS_BOTTOM_STACKABLE_TRAIT_ID = uint256(
    keccak256("placeable.is_bottom_stackable")
);
uint256 constant PLACEABLE_IS_TOP_STACKABLE_TRAIT_ID = uint256(
    keccak256("placeable.is_top_stackable")
);
uint256 constant PLACEABLE_TERRAIN_TRAIT_ID = uint256(
    keccak256("placeable.terrain")
);
uint256 constant GLTF_SCALING_FACTOR_TRAIT_ID = uint256(
    keccak256("gltf_scaling_factor")
);
uint256 constant SIZE_TRAIT_ID = uint256(keccak256("size"));

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@opengsn/contracts/src/interfaces/IERC2771Recipient.sol";

import {IGameRegistry} from "./core/IGameRegistry.sol";
import {ISystem} from "./core/ISystem.sol";

import {TRUSTED_FORWARDER_ROLE} from "./Constants.sol";

import {ITraitsProvider, ID as TRAITS_PROVIDER_ID} from "./interfaces/ITraitsProvider.sol";
import {ILockingSystem, ID as LOCKING_SYSTEM_ID} from "./locking/ILockingSystem.sol";
import {IRandomizer, IRandomizerCallback, ID as RANDOMIZER_ID} from "./randomizer/IRandomizer.sol";
import {ILootSystem, ID as LOOT_SYSTEM_ID} from "./loot/ILootSystem.sol";

/** @title Contract that lets a child contract access the GameRegistry contract */
abstract contract GameRegistryConsumer is
    ISystem,
    Ownable,
    IERC2771Recipient,
    IRandomizerCallback
{
    /// @notice Whether or not the contract is paused
    bool private _paused;

    /// @notice Id for the system/component
    uint256 private _id;

    /// @notice Read access contract
    IGameRegistry private _gameRegistry;

    /** EVENTS **/

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    /** ERRORS **/

    /// @notice Not authorized to perform action
    error MissingRole(address account, bytes32 expectedRole);

    /** MODIFIERS **/

    // Modifier to verify a user has the appropriate role to call a given function
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
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

    /** ERRORS **/

    /// @notice gameRegistryAddress does not implement IGameRegistry
    error InvalidGameRegistry();

    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(address gameRegistryAddress, uint256 id) {
        _gameRegistry = IGameRegistry(gameRegistryAddress);
        _id = id;

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }

        _paused = true;
    }

    /** EXTERNAL **/

    /** @return ID for this system */
    function getId() public view override returns (uint256) {
        return _id;
    }

    /**
     * Pause/Unpause the contract
     *
     * @param shouldPause Whether or pause or unpause
     */
    function setPaused(bool shouldPause) external onlyOwner {
        if (shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Returns true if the contract OR the GameRegistry is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused || _gameRegistry.paused();
    }

    /**
     * Sets the GameRegistry contract address for this contract
     *
     * @param gameRegistryAddress  Address for the GameRegistry contract
     */
    function setGameRegistry(address gameRegistryAddress) external onlyOwner {
        _gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }
    }

    /** @return GameRegistry contract for this contract */
    function getGameRegistry() external view returns (IGameRegistry) {
        return _gameRegistry;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasAccessRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return _gameRegistry.hasAccessRole(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) virtual internal view {
        if (!_gameRegistry.hasAccessRole(role, account)) {
            revert MissingRole(account, role);
        }
    }

    /** @return Returns the traits provider for this contract */
    function _traitsProvider() internal view returns (ITraitsProvider) {
        return ITraitsProvider(_getSystem(TRAITS_PROVIDER_ID));
    }

    /** @return Interface to the LockingSystem */
    function _lockingSystem() internal view returns (ILockingSystem) {
        return ILockingSystem(_gameRegistry.getSystem(LOCKING_SYSTEM_ID));
    }

    /** @return Interface to the LootSystem */
    function _lootSystem() internal view returns (ILootSystem) {
        return ILootSystem(_gameRegistry.getSystem(LOOT_SYSTEM_ID));
    }

    /** @return Interface to the Randomizer */
    function _randomizer() internal view returns (IRandomizer) {
        return IRandomizer(_gameRegistry.getSystem(RANDOMIZER_ID));
    }

    /** @return Address for a given system */
    function _getSystem(uint256 systemId) internal view returns (address) {
        return _gameRegistry.getSystem(systemId);
    }

    /**
     * Requests randomness from the game's Randomizer contract
     *
     * @param numWords Number of words to request from the VRF
     *
     * @return Id of the randomness request
     */
    function _requestRandomWords(uint32 numWords) internal returns (uint256) {
        return
            _randomizer().requestRandomWords(
                IRandomizerCallback(this),
                numWords
            );
    }

    /**
     * Callback for when a random number request has returned with random words
     *
     * @param requestId     Id of the request
     * @param randomWords   Random words
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external virtual override {
        // Do nothing by default
    }

    /**
     * Returns the Player address for the Operator account
     * @param operatorAccount address of the Operator account to retrieve the player for
     */
    function _getPlayerAccount(
        address operatorAccount
    ) internal view returns (address playerAccount) {
        return _gameRegistry.getPlayerAccount(operatorAccount);
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(
        address forwarder
    ) public view virtual override returns (bool) {
        return
            address(_gameRegistry) != address(0) &&
            _hasAccessRole(TRUSTED_FORWARDER_ROLE, forwarder);
    }

    /** INTERNAL **/

    /// @inheritdoc IERC2771Recipient
    function _msgSender()
        internal
        view
        virtual
        override(Context, IERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData()
        internal
        view
        virtual
        override(Context, IERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /** PAUSABLE **/

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
    function _pause() internal virtual {
        require(_paused == false, "Pausable: not paused");
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
    function _unpause() internal virtual {
        require(_paused == true, "Pausable: not paused");
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@opengsn/contracts/src/interfaces/IERC2771Recipient.sol";

import {PERCENTAGE_RANGE, TRUSTED_FORWARDER_ROLE} from "./Constants.sol";

import {ISystem} from "./core/ISystem.sol";
import {ITraitsProvider, ID as TRAITS_PROVIDER_ID} from "./interfaces/ITraitsProvider.sol";
import {ILockingSystem, ID as LOCKING_SYSTEM_ID} from "./locking/ILockingSystem.sol";
import {IRandomizer, IRandomizerCallback, ID as RANDOMIZER_ID} from "./randomizer/IRandomizer.sol";
import {ILootSystem, ID as LOOT_SYSTEM_ID} from "./loot/ILootSystem.sol";
import {IGameRegistry, IERC165} from "./core/IGameRegistry.sol";

/** @title Contract that lets a child contract access the GameRegistry contract */
abstract contract GameRegistryConsumerUpgradeable is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC2771Recipient,
    IRandomizerCallback,
    ISystem
{
    /// @notice Whether or not the contract is paused
    bool private _paused;

    /// @notice Reference to the game registry that this contract belongs to
    IGameRegistry internal _gameRegistry;

    /// @notice Id for the system/component
    uint256 private _id;

    /** EVENTS **/

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    /** ERRORS **/

    /// @notice Not authorized to perform action
    error MissingRole(address account, bytes32 expectedRole);

    /** MODIFIERS **/

    /// @notice Modifier to verify a user has the appropriate role to call a given function
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
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

    /** ERRORS **/

    /// @notice Error if the game registry specified is invalid
    error InvalidGameRegistry();

    /** SETUP **/

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     * @param id                  Id of the system/component
     */
    function __GameRegistryConsumer_init(
        address gameRegistryAddress,
        uint256 id
    ) internal onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init();

        _gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }

        _paused = true;
        _id = id;
    }

    /** @return ID for this system */
    function getId() public view override returns (uint256) {
        return _id;
    }

    /**
     * Pause/Unpause the contract
     *
     * @param shouldPause Whether or pause or unpause
     */
    function setPaused(bool shouldPause) external onlyOwner {
        if (shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Returns true if the contract OR the GameRegistry is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused || _gameRegistry.paused();
    }

    /**
     * Sets the GameRegistry contract address for this contract
     *
     * @param gameRegistryAddress  Address for the GameRegistry contract
     */
    function setGameRegistry(address gameRegistryAddress) external onlyOwner {
        _gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }
    }

    /** @return GameRegistry contract for this contract */
    function getGameRegistry() external view returns (IGameRegistry) {
        return _gameRegistry;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(
        address forwarder
    ) public view virtual override(IERC2771Recipient) returns (bool) {
        return
            address(_gameRegistry) != address(0) &&
            _hasAccessRole(TRUSTED_FORWARDER_ROLE, forwarder);
    }

    /**
     * Callback for when a random number request has returned with random words
     *
     * @param requestId     Id of the request
     * @param randomWords   Random words
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external virtual override {
        // Do nothing by default
    }

    /** INTERNAL **/

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasAccessRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return _gameRegistry.hasAccessRole(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!_gameRegistry.hasAccessRole(role, account)) {
            revert MissingRole(account, role);
        }
    }

    /** @return Returns the traits provider for this contract */
    function _traitsProvider() internal view returns (ITraitsProvider) {
        return ITraitsProvider(_getSystem(TRAITS_PROVIDER_ID));
    }

    /** @return Interface to the LockingSystem */
    function _lockingSystem() internal view returns (ILockingSystem) {
        return ILockingSystem(_gameRegistry.getSystem(LOCKING_SYSTEM_ID));
    }

    /** @return Interface to the LootSystem */
    function _lootSystem() internal view returns (ILootSystem) {
        return ILootSystem(_gameRegistry.getSystem(LOOT_SYSTEM_ID));
    }

    /** @return Interface to the Randomizer */
    function _randomizer() internal view returns (IRandomizer) {
        return IRandomizer(_gameRegistry.getSystem(RANDOMIZER_ID));
    }

    /** @return Address for a given system */
    function _getSystem(uint256 systemId) internal view returns (address) {
        return _gameRegistry.getSystem(systemId);
    }

    /**
     * Requests randomness from the game's Randomizer contract
     *
     * @param numWords Number of words to request from the VRF
     *
     * @return Id of the randomness request
     */
    function _requestRandomWords(uint32 numWords) internal returns (uint256) {
        return
            _randomizer().requestRandomWords(
                IRandomizerCallback(this),
                numWords
            );
    }

    /**
     * Returns the Player address for the Operator account
     * @param operatorAccount address of the Operator account to retrieve the player for
     */
    function _getPlayerAccount(
        address operatorAccount
    ) internal view returns (address playerAccount) {
        return _gameRegistry.getPlayerAccount(operatorAccount);
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, IERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, IERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /** PAUSABLE **/

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
    function _pause() internal virtual {
        require(_paused == false, "Pausable: not paused");
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
    function _unpause() internal virtual {
        require(_paused == true, "Pausable: not paused");
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../GameRegistryConsumerUpgradeable.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";

import {RANDOMIZER_ROLE, MANAGER_ROLE, IS_PIRATE_TRAIT_ID} from "../Constants.sol";

import {IGameItems} from "../tokens/gameitems/IGameItems.sol";
import {IGameCurrency} from "../tokens/IGameCurrency.sol";
import {ITraitsProvider, ID as TRAITS_PROVIDER_ID} from "../interfaces/ITraitsProvider.sol";
import {ILevelSystem, ID as LEVEL_SYSTEM_ID} from "../level/ILevelSystem.sol";
import {ILootSystem} from "../loot/ILootSystem.sol";
import {ICaptainSystem, ID as CAPTAIN_SYSTEM_ID} from "../captain/ICaptainSystem.sol";
import {IBountySystem, ID} from "./IBountySystem.sol";
import {ICooldownSystem, ID as COOLDOWN_SYSTEM_ID} from "../cooldown/ICooldownSystem.sol";
import {CountingSystem, ID as COUNTING_SYSTEM} from "../counting/CountingSystem.sol";

import {BountyComponent, ID as BOUNTY_COMPONENT_ID} from "../generated/components/BountyComponent.sol";
import {LootSetComponent, ID as LOOT_SET_COMPONENT_ID} from "../generated/components/LootSetComponent.sol";
import {ActiveBountyComponent, ID as ACTIVE_BOUNTY_COMPONENT_ID} from "../generated/components/ActiveBountyComponent.sol";
import {BountyAccountDataComponent, ID as BOUNTY_ACCOUNT_DATA_COMPONENT_ID} from "../generated/components/BountyAccountDataComponent.sol";
import {EnabledComponent, ID as ENABLED_COMPONENT_ID} from "../generated/components/EnabledComponent.sol";

// Cooldown System ID for Bounty System cooldowns
uint256 constant BOUNTY_SYSTEM_NFT_COOLDOWN_ID = uint256(
    keccak256("bounty_system.nft.cooldown_id")
);

// Counting System ID for Bounty System counting as key for ActiveBounty counting
uint256 constant BOUNTY_SYSTEM_ACTIVE_BOUNTY_COUNTER = uint256(
    keccak256("bounty_system.active_bounty.counter")
);

// BountyLootInput : define rules for a Bounty related Loot, primarily its GUID, and loot
struct BountyLootInput {
    // Bounty Loot Component GUID
    uint256 lootEntity;
    uint32[] lootType;
    address[] tokenContract;
    uint256[] lootId;
    uint256[] amount;
}

// SetBountyInputParam : define rules for a Bounty, its Bounty Subs, its enabled status, its input loot, and its timelock
struct SetBountyInputParam {
    // Bounty ID
    uint256 bountyId;
    // Bounty Group ID
    uint256 bountyGroupId;
    // Amount of XP earned on successful completion of this Bounty
    uint32 successXp;
    // Lower bound of staked amount required for reward
    uint32 lowerBound;
    // Upper bound of staked amount required for reward
    uint32 upperBound;
    // Amount of time (in seconds) to complete this Bounty + NFTs are locked for
    uint32 bountyTimeLock;
    // Input Loot to burn to start the bounty
    BountyLootInput inputLoot;
    // Bounty Base loot
    BountyLootInput outputLoot;
}

contract BountySystem is IBountySystem, GameRegistryConsumerUpgradeable {
    /** STRUCTS */

    // VRFRequest: Struct to track and respond to VRF requests
    struct VRFRequest {
        // Account the request is for
        address account;
        // Bounty ID for the request
        uint256 bountyId;
        // Active Bounty ID for the request
        uint256 activeBountyId;
    }

    /** ENUMS */

    // Status of an active bounty
    enum ActiveBountyStatus {
        UNDEFINED,
        IN_PROGRESS,
        COMPLETED
    }

    /** MEMBERS */

    /// @notice Mapping to track VRF requests
    mapping(uint256 => VRFRequest) private _vrfRequests;

    /** EVENTS */

    /// @notice Emitted when a Bounty has been started
    event BountyStarted(
        address account,
        uint256 bountyId,
        uint256 activeBountyId
    );

    /// @notice Emitted when a Bounty has been completed
    event BountyCompleted(
        address account,
        uint256 bountyId,
        uint256 bountyGroupId,
        uint256 activeBountyId,
        bool success
    );

    /** ERRORS */

    /// @notice Error when missing inputs
    error MissingInputs();

    /// @notice Error when invalid inputs
    error InvalidInputs();

    /// @notice Error when caller is not NFT owner
    error NotNFTOwner();

    /// @notice Error when NFT not Pirate
    error NotPirateNFT();

    /// @notice NFT still in Bounty cooldown
    error NFTOnCooldown(uint256 entity);

    /// @notice Error when Bounty not in progress
    error BountyNotInProgress();

    /// @notice Error Bounty still running
    error BountyStillRunning();

    /// @notice Error when Bounty not enabled
    error BountyNotEnabled();

    /// @notice Error caller is not owner of ActiveBounty
    error BountyNotOwnedByCaller();

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /** SETTERS */

    /**
     * Sets the definition for a given Bounty
     * @param definition Definition for the bounty
     */
    function setBountyDefinition(
        SetBountyInputParam calldata definition,
        bool enabled
    ) external onlyRole(MANAGER_ROLE) {
        // Run validation on Bounty definition
        _validateSetBountyInput(definition);
        // Set Bounty component with unique Bounty GUID
        BountyComponent(_gameRegistry.getComponent(BOUNTY_COMPONENT_ID))
            .setValue(
                definition.bountyId,
                definition.successXp,
                definition.lowerBound,
                definition.upperBound,
                definition.bountyTimeLock,
                definition.bountyGroupId,
                definition.inputLoot.lootEntity,
                definition.outputLoot.lootEntity
            );
        // Set Bounty InputLoot component with unique Bounty InputLoot GUID
        LootSetComponent(_gameRegistry.getComponent(LOOT_SET_COMPONENT_ID))
            .setValue(
                definition.inputLoot.lootEntity,
                definition.inputLoot.lootType,
                definition.inputLoot.tokenContract,
                definition.inputLoot.lootId,
                definition.inputLoot.amount
            );
        // Set Bounty Base reward Loot component with unique Bounty Base reward Loot GUID
        LootSetComponent(_gameRegistry.getComponent(LOOT_SET_COMPONENT_ID))
            .setValue(
                definition.outputLoot.lootEntity,
                definition.outputLoot.lootType,
                definition.outputLoot.tokenContract,
                definition.outputLoot.lootId,
                definition.outputLoot.amount
            );
        // Set Bounty enabled status
        EnabledComponent(_gameRegistry.getComponent(ENABLED_COMPONENT_ID))
            .setValue(definition.bountyGroupId, enabled);
    }

    /**
     * @dev Set the Bounty status for a given Bounty Group
     * @param bountyGroupId Bounty Group ID
     * @param enabled Bounty enabled status
     */
    function setBountyStatus(
        uint256 bountyGroupId,
        bool enabled
    ) external override onlyRole(MANAGER_ROLE) {
        // Set Bounty enabled status
        EnabledComponent(_gameRegistry.getComponent(ENABLED_COMPONENT_ID))
            .setValue(bountyGroupId, enabled);
    }

    /** GETTERS */

    /**
     * @dev Get list of active bounty ids for a given account
     * @return All active bounty ids for a given account
     */
    function activeBountyIdsForAccount(
        address account
    ) external view override returns (uint256[] memory) {
        BountyAccountDataComponent accountDataComponent = BountyAccountDataComponent(
                _gameRegistry.getComponent(BOUNTY_ACCOUNT_DATA_COMPONENT_ID)
            );
        uint256 accountEntity = EntityLibrary.addressToEntity(account);
        (, uint256[] memory activeBountyIds) = accountDataComponent.getValue(
            accountEntity
        );

        return activeBountyIds;
    }

    /**
     * @dev Check if a Bounty is available to a user wallet
     * @param account Account to check if Bounty is available for
     * @param bountyId Id of the Bounty to see is available
     * @return Whether or not the Bounty is available to the given account
     */
    function isBountyAvailable(
        address account,
        uint256 bountyId
    ) public view override returns (bool) {
        EnabledComponent enabledComponent = EnabledComponent(
            _gameRegistry.getComponent(ENABLED_COMPONENT_ID)
        );

        (, , , , uint256 groupId, , ) = BountyComponent(
            _gameRegistry.getComponent(BOUNTY_COMPONENT_ID)
        ).getValue(bountyId);

        bool value = enabledComponent.getValue(groupId);
        if (!value) {
            return false;
        }

        // If user has a pending bounty for this Bounty type, return false
        if (hasPendingBounty(account, groupId)) {
            return false;
        }
        return true;
    }

    /**
     * @dev Return boolean if a user has a pending bounty for a given Bounty type
     * @param account Account to check
     * @param bountyGroupId Group Id of the Bounty to check
     * @return Whether or not the user has a pending bounty for the given Bounty type
     */
    function hasPendingBounty(
        address account,
        uint256 bountyGroupId
    ) public view override returns (bool) {
        // Use CountingSystem to return true if user has a pending bounty for this Bounty type
        CountingSystem countingSystem = CountingSystem(
            _gameRegistry.getSystem(COUNTING_SYSTEM)
        );
        // The CountingSystem entity is Bounty ID and key is User Wallet
        if (
            countingSystem.getCount(
                bountyGroupId,
                EntityLibrary.addressToEntity(account)
            ) > 0
        ) {
            return true;
        }
        return false;
    }

    /** CLIENT FUNCTIONS */

    /**
     * Starts a Bounty for a user
     * @param bountyId entity ID of the bounty to start
     * @param entities Inputs to the bounty, these should only be the NFTs in entity format
     */
    function startBounty(
        uint256 bountyId,
        uint256[] calldata entities
    ) public nonReentrant whenNotPaused returns (uint256) {
        // Get user account
        address account = _getPlayerAccount(_msgSender());
        // Get Bounty component for this bounty
        (
            ,
            uint32 lowerBound,
            uint32 upperBound,
            uint32 bountyTimeLock,
            uint256 groupId,
            uint256 inputLootId,

        ) = BountyComponent(_gameRegistry.getComponent(BOUNTY_COMPONENT_ID))
                .getValue(bountyId);

        // Verify startBounty call inputs and conditions on user
        _verifyStartBounty(
            account,
            bountyId,
            groupId,
            bountyTimeLock,
            entities
        );

        // Verify NFT inputs : Verify user is owner, verify NFT IS_PIRATE, AND verify NFT is not on cooldown, and within bounds
        _verifyNftInputs(
            account,
            entities,
            bountyTimeLock,
            lowerBound,
            upperBound
        );

        // Create an ActiveBounty
        uint256 activeBountyId = _createActiveBounty(
            account,
            bountyId,
            groupId,
            entities
        );

        // Handle burning the entry requirements for this bounty
        _handleBurningInputs(account, inputLootId);

        // Add active bounty id to users accountdata, user wallet is the unique GUID
        _addToAccountData(account, activeBountyId);

        emit BountyStarted(account, bountyId, activeBountyId);

        return activeBountyId;
    }

    /**
     * Ends a bounty for a user
     * @param activeBountyId ID of the active bounty to end
     */
    function endBounty(
        uint256 activeBountyId
    ) public nonReentrant whenNotPaused {
        // Get user account
        address account = _getPlayerAccount(_msgSender());

        // Validate endBounty() call : Check that the bounty is active, account is the owner, and timelock has passed
        _validateEndBounty(account, activeBountyId);

        // Check that user still owns the NFTs that were staked for the bounty
        bool failedBounty = _checkStakedNfts(account, activeBountyId);
        if (failedBounty) {
            // User failed the bounty, mark as complete, do not dispense rewards
            _handleFailedBounty(account, activeBountyId);
        } else {
            // Handle loot rewards for a completed Bounty
            _handleLoot(account, activeBountyId);
        }
    }

    /**
     * Finishes Bounty with randomness, VRF callback func
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external override onlyRole(RANDOMIZER_ROLE) {
        VRFRequest storage request = _vrfRequests[requestId];
        if (request.account != address(0)) {
            // Get the BountySub component associated with this request
            (
                uint32 successXp,
                ,
                ,
                ,
                uint256 groupId,
                ,
                uint256 baseLootId
            ) = BountyComponent(_gameRegistry.getComponent(BOUNTY_COMPONENT_ID))
                    .getValue(request.bountyId);

            uint256 randomWord = randomWords[0];
            ILootSystem lootSystem = _lootSystem();

            // Convert baseloot to ILootSystem.Loot
            ILootSystem.Loot[] memory baseRewardLoot = _convertLootSet(
                baseLootId
            );

            // Grant baseloot
            lootSystem.grantLootWithRandomWord(
                request.account,
                baseRewardLoot,
                randomWord
            );

            // Grant successXp
            _handleXp(successXp, request.activeBountyId);

            // Emit BountyCompleted event
            emit BountyCompleted(
                request.account,
                request.bountyId,
                groupId,
                request.activeBountyId,
                true
            );

            // Delete the VRF request
            delete _vrfRequests[requestId];
        }
    }

    /** INTERNAL **/

    /**
     * @dev Add the ActiveBounty GUID to the users account data
     * @param account Account to add the ActiveBounty GUID to
     * @param activeBountyId ActiveBounty GUID to add to the users account data
     */
    function _addToAccountData(
        address account,
        uint256 activeBountyId
    ) internal {
        // Add active bounty id to users accountdata, user wallet is the unique GUID
        BountyAccountDataComponent accountDataComponent = BountyAccountDataComponent(
                _gameRegistry.getComponent(BOUNTY_ACCOUNT_DATA_COMPONENT_ID)
            );
        uint256 localEntity = EntityLibrary.addressToEntity(account);
        (, uint256[] memory activeBountyIds) = accountDataComponent.getValue(
            localEntity
        );
        uint256[] memory newActiveBountyIds = new uint256[](
            activeBountyIds.length + 1
        );
        for (uint256 i = 0; i < activeBountyIds.length; i++) {
            newActiveBountyIds[i] = activeBountyIds[i];
        }
        newActiveBountyIds[activeBountyIds.length] = activeBountyId;
        accountDataComponent.setValue(localEntity, account, newActiveBountyIds);
    }

    /**
     * @dev Remove the ActiveBounty GUID from the users account data
     * @param account Account to remove the ActiveBounty GUID from
     * @param activeBountyId GUID of the ActiveBounty to remove
     */
    function _removeFromAccountData(
        address account,
        uint256 activeBountyId
    ) internal {
        BountyAccountDataComponent accountDataComponent = BountyAccountDataComponent(
                _gameRegistry.getComponent(BOUNTY_ACCOUNT_DATA_COMPONENT_ID)
            );
        uint256 localEntity = EntityLibrary.addressToEntity(account);
        (, uint256[] memory activeBountyIds) = accountDataComponent.getValue(
            localEntity
        );

        uint256[] memory newActiveBountyIds = new uint256[](
            activeBountyIds.length - 1
        );
        uint256 lastIndex = activeBountyIds[activeBountyIds.length - 1];
        for (uint256 i = 0; i < activeBountyIds.length - 1; i++) {
            if (activeBountyIds[i] == activeBountyId) {
                newActiveBountyIds[i] = lastIndex;
            } else {
                newActiveBountyIds[i] = activeBountyIds[i];
            }
        }

        accountDataComponent.setValue(localEntity, account, newActiveBountyIds);
    }

    /**
     * @dev Handle a failed Bounty
     */
    function _handleFailedBounty(
        address account,
        uint256 activeBountyId
    ) internal {
        // Set ActiveBounty status to COMPLETED
        // Get ActiveBounty component for the users active bounty
        (, , , uint256 bountyId, uint256 groupId, ) = ActiveBountyComponent(
            _gameRegistry.getComponent(ACTIVE_BOUNTY_COMPONENT_ID)
        ).getValue(activeBountyId);
        _setActiveBountyCompleted(account, activeBountyId);
        emit BountyCompleted(account, bountyId, groupId, activeBountyId, false);
    }

    /**
     * Handles loot for a bounty ending, checks bonus table and triggers VRF if needed
     */
    function _handleLoot(address account, uint256 activeBountyId) internal {
        // Get user ActiveBounty component
        (, , , uint256 bountyId, , ) = ActiveBountyComponent(
            _gameRegistry.getComponent(ACTIVE_BOUNTY_COMPONENT_ID)
        ).getValue(activeBountyId);
        // Get the Bounty component associated with this bounty
        (
            uint32 successXp,
            ,
            ,
            ,
            uint256 groupId,
            ,
            uint256 baseLootId
        ) = BountyComponent(_gameRegistry.getComponent(BOUNTY_COMPONENT_ID))
                .getValue(bountyId);

        // Convert base loot to ILootSystem.Loot
        ILootSystem.Loot[] memory baseRewardLoot = _convertLootSet(baseLootId);
        ILootSystem lootSystem = _lootSystem();
        // If your base reward loot requires VRF OR bonusloot exists then request VRF, else immediately award base loot
        if (lootSystem.validateLoots(baseRewardLoot)) {
            // Request VRF
            VRFRequest storage vrfRequest = _vrfRequests[
                _requestRandomWords(1)
            ];
            vrfRequest.account = account;
            vrfRequest.bountyId = bountyId;
            vrfRequest.activeBountyId = activeBountyId;
        } else {
            // No VRF needed for baseloot and no bonusloot, just handle base reward loot and successXp
            lootSystem.grantLoot(account, baseRewardLoot);
            _handleXp(successXp, activeBountyId);
            // Emit BountyCompleted event
            emit BountyCompleted(
                account,
                bountyId,
                groupId,
                activeBountyId,
                true
            );
        }
        // Set ActiveBounty status to COMPLETED
        _setActiveBountyCompleted(account, activeBountyId);
    }

    /**
     * @dev Set ActiveBounty component status to COMPLETED and set the pending bounty count to 0
     * @param account UserAccount
     * @param activeBountyId ID of the active bounty to end
     */
    function _setActiveBountyCompleted(
        address account,
        uint256 activeBountyId
    ) internal {
        // Remove this ActiveBounty guid from the users account data
        _removeFromAccountData(account, activeBountyId);
        // Get ActiveBounty component for the users active bounty
        ActiveBountyComponent activeBounty = ActiveBountyComponent(
            _gameRegistry.getComponent(ACTIVE_BOUNTY_COMPONENT_ID)
        );
        // Get ActiveBounty component for the users active bounty
        (
            ,
            ,
            uint32 startTime,
            uint256 bountyId,
            uint256 groupId,
            uint256[] memory entityInputs
        ) = activeBounty.getValue(activeBountyId);
        // Set ActiveBountyComponent with status to COMPLETED
        activeBounty.setValue(
            activeBountyId,
            uint32(ActiveBountyStatus.COMPLETED),
            account,
            startTime,
            bountyId,
            groupId,
            entityInputs
        );
        // Set pending bounty count to 0 for this Bounty type
        CountingSystem(_gameRegistry.getSystem(COUNTING_SYSTEM)).setCount(
            groupId,
            EntityLibrary.addressToEntity(account),
            0
        );
    }

    /**
     * @dev Check that user still owns the NFTs that were staked for the bounty
     * @param account Account to check
     * @param activeBountyId ID of the active bounty to check
     */
    function _checkStakedNfts(
        address account,
        uint256 activeBountyId
    ) internal view returns (bool) {
        bool failedBounty;
        // Get user ActiveBounty component
        (, , , , , uint256[] memory entityInputs) = ActiveBountyComponent(
            _gameRegistry.getComponent(ACTIVE_BOUNTY_COMPONENT_ID)
        ).getValue(activeBountyId);
        // Get the final staked amount for this users ActiveBounty
        // Check that user still owns all the NFTs they staked for the bounty
        uint256 tokenId;
        address tokenContract;
        for (uint256 i = 0; i < entityInputs.length; ++i) {
            (tokenContract, tokenId) = EntityLibrary.entityToToken(
                entityInputs[i]
            );
            // Verify ownership
            if (account != IERC721(tokenContract).ownerOf(tokenId)) {
                failedBounty = true;
                break;
            }
        }
        return failedBounty;
    }

    /**
     * Validate EndBounty call
     * @dev Check caller, check status, check time lock
     * @param userAccount Account to check
     * @param activeBountyId ID of the active bounty to check
     */
    function _validateEndBounty(
        address userAccount,
        uint256 activeBountyId
    ) internal view {
        (
            uint32 status,
            address account,
            uint32 startTime,
            uint256 bountyId,
            ,

        ) = ActiveBountyComponent(
                _gameRegistry.getComponent(ACTIVE_BOUNTY_COMPONENT_ID)
            ).getValue(activeBountyId);
        // Check if user is the account that created the bounty
        if (userAccount != account) {
            revert BountyNotOwnedByCaller();
        }
        // Check if bounty is in progress
        if (status != uint32(ActiveBountyStatus.IN_PROGRESS)) {
            revert BountyNotInProgress();
        }
        // Get Bounty component and check if bounty is valid to end
        (, , , uint32 bountyTimeLock, , , ) = BountyComponent(
            _gameRegistry.getComponent(BOUNTY_COMPONENT_ID)
        ).getValue(bountyId);

        // Check if Bounty valid to end
        if (block.timestamp < startTime + bountyTimeLock) {
            revert BountyStillRunning();
        }
    }

    /**
     * Create an ActiveBounty component using a local entity counter to get a counter
     * and then use that counter to create an ActiveBounty component GUID entity(local address, counter)
     * @param account The account associated with the ActiveBounty
     * @param bountyId The ID of the Bounty component
     * @param entities The entities of the NFTs that were staked for the bounty
     */
    function _createActiveBounty(
        address account,
        uint256 bountyId,
        uint256 groupId,
        uint256[] calldata entities
    ) internal returns (uint256) {
        // Create a local entity counter, Increment counter by 1 and get the latest counter for bounties
        uint256 localEntity = EntityLibrary.addressToEntity(address(this));
        CountingSystem countingSystem = CountingSystem(
            _gameRegistry.getSystem(COUNTING_SYSTEM)
        );
        countingSystem.incrementCount(
            localEntity,
            BOUNTY_SYSTEM_ACTIVE_BOUNTY_COUNTER,
            1
        );
        uint256 latestCounterValue = countingSystem.getCount(
            localEntity,
            BOUNTY_SYSTEM_ACTIVE_BOUNTY_COUNTER
        );

        // The ActiveBounty ID is the local address + latest counter value
        uint256 activeBountyId = EntityLibrary.tokenToEntity(
            address(this),
            latestCounterValue
        );

        // Set ActiveBountyComponent
        ActiveBountyComponent(
            _gameRegistry.getComponent(ACTIVE_BOUNTY_COMPONENT_ID)
        ).setValue(
                activeBountyId,
                uint32(ActiveBountyStatus.IN_PROGRESS),
                account,
                SafeCast.toUint32(block.timestamp),
                bountyId,
                groupId,
                entities
            );
        return activeBountyId;
    }

    /**
     * Handles the burning of input loots for a bounty
     * @param account The account that is burning the input loots
     * @param inputLootSetId The component GUID of the input loots
     */
    function _handleBurningInputs(
        address account,
        uint256 inputLootSetId
    ) internal {
        // Get the input loots
        (
            uint32[] memory lootType,
            address[] memory tokenContract,
            uint256[] memory lootId,
            uint256[] memory amount
        ) = LootSetComponent(_gameRegistry.getComponent(LOOT_SET_COMPONENT_ID))
                .getValue(inputLootSetId);
        // Revert if no entry loots found
        if (lootType.length == 0) {
            revert InvalidInputs();
        }
        for (uint256 i = 0; i < lootType.length; ++i) {
            if (lootType[i] == uint32(ILootSystem.LootType.ERC20)) {
                // Burn amount of ERC20 tokens required to start this bounty
                IGameCurrency(tokenContract[i]).burn(account, amount[i]);
            } else if (lootType[i] == uint32(ILootSystem.LootType.ERC1155)) {
                // Burn amount of ERC1155 tokens required to start this bounty
                IGameItems(tokenContract[i]).burn(
                    account,
                    lootId[i],
                    amount[i]
                );
            }
        }
    }

    /**
     * Verifies inputs and checks related to starting a bounty
     * @param account The account that is starting the bounty
     * @param bountyId The ID of the Bounty
     * @param timeLock The time lock of the bounty
     * @param entities The entities of the NFTs that were staked for the bounty
     */
    function _verifyStartBounty(
        address account,
        uint256 bountyId,
        uint256 groupId,
        uint32 timeLock,
        uint256[] calldata entities
    ) internal {
        // Check if bounty is enabled or available for this user
        if (isBountyAvailable(account, bountyId) == false) {
            revert BountyNotEnabled();
        }
        // Check startBounty inputs
        if (bountyId == 0 || entities.length == 0) {
            revert InvalidInputs();
        }
        // Add a cooldown on this User Wallet + Bounty Component Group ID to ensure user can only run 1 type of this Bounty at a time
        if (
            ICooldownSystem(_getSystem(COOLDOWN_SYSTEM_ID))
                .updateAndCheckCooldown(
                    EntityLibrary.addressToEntity(account),
                    groupId,
                    timeLock
                )
        ) {
            revert BountyStillRunning();
        }
        // Increment the users count for this Bounty type (group id) by 1
        CountingSystem(_gameRegistry.getSystem(COUNTING_SYSTEM)).incrementCount(
                groupId,
                EntityLibrary.addressToEntity(account),
                1
            );
    }

    /**
     * Verify valid NFT inputs for staking : User is owner, token is IS_PIRATE, token is not on cooldown, apply cooldown on token
     * @param account User account
     * @param entityNfts Array of entity NFTs to verify
     * @param timeLock Time lock of the bounty
     * @param lowerBound Lower bound of the bounty
     * @param upperBound Upper bound of the bounty
     */
    function _verifyNftInputs(
        address account,
        uint256[] calldata entityNfts,
        uint32 timeLock,
        uint32 lowerBound,
        uint32 upperBound
    ) internal {
        // Check that amount of NFTs is within bounds
        if (entityNfts.length < lowerBound || entityNfts.length > upperBound) {
            revert InvalidInputs();
        }
        ICooldownSystem cooldownSystem = ICooldownSystem(
            _getSystem(COOLDOWN_SYSTEM_ID)
        );
        uint256 tokenId;
        address tokenContract;
        ITraitsProvider traitsProvider = _traitsProvider();
        for (uint256 i = 0; i < entityNfts.length; ++i) {
            (tokenContract, tokenId) = EntityLibrary.entityToToken(
                entityNfts[i]
            );
            // Verify ownership
            if (account != IERC721(tokenContract).ownerOf(tokenId)) {
                revert NotNFTOwner();
            }
            // Verify token IS_PIRATE
            if (
                traitsProvider.getTraitBool(
                    tokenContract,
                    tokenId,
                    IS_PIRATE_TRAIT_ID
                ) == false
            ) {
                revert NotPirateNFT();
            }
            // Add cooldown and revert if token already in a cooldown
            if (
                cooldownSystem.updateAndCheckCooldown(
                    entityNfts[i],
                    BOUNTY_SYSTEM_NFT_COOLDOWN_ID,
                    timeLock
                )
            ) {
                revert NFTOnCooldown(entityNfts[i]);
            }
        }
    }

    /**
     * Handles the granting of XP, awarded to user staked NFTs
     * @param successXp The amount of XP to grant
     * @param activeBountyId The ID of the active bounty
     */
    function _handleXp(uint256 successXp, uint256 activeBountyId) internal {
        // Grant XP if any
        if (successXp > 0) {
            // Get user ActiveBounty component
            (, , , , , uint256[] memory entityInputs) = ActiveBountyComponent(
                _gameRegistry.getComponent(ACTIVE_BOUNTY_COMPONENT_ID)
            ).getValue(activeBountyId);
            address tokenContract;
            uint256 tokenId;
            for (uint256 i = 0; i < entityInputs.length; ++i) {
                (tokenContract, tokenId) = EntityLibrary.entityToToken(
                    entityInputs[i]
                );
                // Grant XP to NFT
                ILevelSystem(_getSystem(LEVEL_SYSTEM_ID)).grantXP(
                    tokenContract,
                    tokenId,
                    successXp
                );
            }
        }
    }

    /**
     * Converts a LootSetComponent to a ILootSystem.Loot array
     * @param lootSetId The LootSetComponent GUID
     */
    function _convertLootSet(
        uint256 lootSetId
    ) internal view returns (ILootSystem.Loot[] memory) {
        // Get the LootSet component values uisng the lootSetId
        (
            uint32[] memory lootType,
            address[] memory tokenContract,
            uint256[] memory lootId,
            uint256[] memory amount
        ) = LootSetComponent(_gameRegistry.getComponent(LOOT_SET_COMPONENT_ID))
                .getValue(lootSetId);
        // Convert them to an ILootSystem.Loot array
        ILootSystem.Loot[] memory loot = new ILootSystem.Loot[](
            lootType.length
        );
        for (uint256 i = 0; i < lootType.length; i++) {
            loot[i] = ILootSystem.Loot(
                ILootSystem.LootType(lootType[i]),
                tokenContract[i],
                lootId[i],
                amount[i]
            );
        }
        return loot;
    }

    function _convertBountyLootInput(
        BountyLootInput memory input
    ) internal pure returns (ILootSystem.Loot[] memory) {
        ILootSystem.Loot[] memory loot = new ILootSystem.Loot[](
            input.lootType.length
        );
        for (uint256 i = 0; i < input.lootType.length; i++) {
            loot[i] = ILootSystem.Loot(
                ILootSystem.LootType(input.lootType[i]),
                input.tokenContract[i],
                input.lootId[i],
                input.amount[i]
            );
        }
        return loot;
    }

    /**
     * Validates the SetBountyInputParam
     * @param definition The SetBountyInputParam to validate
     */
    function _validateSetBountyInput(
        SetBountyInputParam calldata definition
    ) internal view {
        // Run validation checks on Bounty definition
        // Check Bounty ID and Group ID is present
        if (definition.bountyId == 0 || definition.bountyGroupId == 0) {
            revert MissingInputs();
        }
        // Check Bounty bountyTimeLock, lowerBound, upperBound is present
        if (
            definition.bountyTimeLock == 0 ||
            definition.lowerBound == 0 ||
            definition.upperBound == 0
        ) {
            revert MissingInputs();
        }
        // Check Bounty input loot, base loot is present
        if (
            definition.inputLoot.lootEntity == 0 ||
            definition.outputLoot.lootEntity == 0
        ) {
            revert MissingInputs();
        }
        // Validate Bounty Input loot
        ILootSystem lootSystem = _lootSystem();
        lootSystem.validateLoots(_convertBountyLootInput(definition.inputLoot));
        // Validate Bounty Base loot
        lootSystem.validateLoots(
            _convertBountyLootInput(definition.outputLoot)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.bountysystem"));

/// @title Interface for the BountySystem that lets players go on bounties (time-based quests)
interface IBountySystem {
    /**
     * Whether or not a given bounty is available to the given player
     *
     * @param account Account to check if quest is available for
     * @param bountyComponentId Id of the bounty to see is available
     *
     * @return Whether or not the bounty is available to the given account
     */
    function isBountyAvailable(
        address account,
        uint256 bountyComponentId
    ) external view returns (bool);

    function activeBountyIdsForAccount(
        address account
    ) external view returns (uint256[] memory);

    function setBountyStatus(uint256 bountyGroupId, bool enabled) external;

    function hasPendingBounty(
        address account,
        uint256 bountyGroupId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.captainsystem"));

interface ICaptainSystem {
    /**
     * Sets the current captain NFT for the player
     *
     * @param tokenContract Address of the captain NFT
     * @param tokenId       Id of the captain NFT token
     */
    function setCaptainNFT(address tokenContract, uint256 tokenId) external;

    /**
     * @return tokenContract Token contract for the captain NFT
     * @return tokenId       Token id for the captain NFT
     */
    function getCaptainNFT(address account)
        external
        view
        returns (address tokenContract, uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.cooldownsystem"));

/**
 * @title ICooldownSystem
 *
 * Interface for general CooldownSystem
 */
interface ICooldownSystem {
    /**
     * @dev Map an entity to a system cooldown Id to a timeStamp
     * @param entity can be address, nft, round, ability, etc
     * @param cooldownId keccak to system using cooldown
     * @param cooldownTime cooldown time limit to set for entity, example 12 hours
     * @return true if block.timestamp is past timeStamp + cooldownTime
     */
    function updateAndCheckCooldown(
        uint256 entity,
        uint256 cooldownId,
        uint32 cooldownTime
    ) external returns (bool);

    /**
     * @dev View function to check if entity is in cooldown
     * @param entity can be address, nft, round, ability, etc
     * @param cooldownId keccak to system using cooldown
     * @return true if block.timestamp is before entities cooldown timestamp, meaning entity is still in cooldown
     */
    function isInCooldown(
        uint256 entity,
        uint256 cooldownId
    ) external view returns (bool);

    /**
     * @dev View function return entity cooldown timestamp
     * @param entity can be address, nft, round, ability, etc
     * @param cooldownId keccak to system using cooldown
     * @return uint32 entity cooldown timestamp
     */
    function getCooldown(
        uint256 entity,
        uint256 cooldownId
    ) external view returns (uint32);

    /**
     * @dev Function for cleaning up an entity cooldown timestamp
     * @param entity can be address, nft, round, ability, etc
     * @param cooldownId keccak to system using cooldown
     */
    function deleteCooldown(uint256 entity, uint cooldownId) external;

    /**
     * @dev Function to reduce desired cooldown by cooldownTime
     * @param entity can be address, nft, round, ability, etc
     * @param cooldownId keccak to system using cooldown
     * @param cooldownTime time to reduce cooldown by
     */
    function reduceCooldown(
        uint256 entity,
        uint256 cooldownId,
        uint32 cooldownTime
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant MAX_UINT96 = 2 ** 96 - 1;

/** @title Entity related helpers **/
library EntityLibrary {
    /** ERRORS **/
    error TokenIdExceedsMaxValue(uint256 tokenId);

    /** INTERNAL **/

    /**
     * @dev Note this function will require the tokenId is < uint96.MAX
     * Unpacks a token address from a single uint256 which is the entity ID
     *
     * @return tokenAddress Address of the unpacked token
     */
    function entityToAddress(
        uint256 value
    ) internal pure returns (address tokenAddress) {
        tokenAddress = address(uint160(value));
        uint256 tokenId = uint256(value >> 160);
        uint256 verify = (tokenId << 160) | uint160(tokenAddress);
        require(verify == value);
    }

    /**
     * Packs an address into a single uint256 entity
     *
     * @param addr    Address to convert to entity
     * @return Converted address to entity
     */
    function addressToEntity(address addr) internal pure returns (uint256) {
        return uint160(addr);
    }

    /**
     * @dev Note this function will require the tokenId is < uint96.MAX
     * Unpacks a token address and token id from a single uint256
     *
     * @return tokenAddress Address of the unpacked token
     * @return tokenId      Id of the unpacked token
     */
    function entityToToken(
        uint256 value
    ) internal pure returns (address tokenAddress, uint256 tokenId) {
        tokenAddress = address(uint160(value));
        tokenId = uint256(value >> 160);
        uint256 verify = (tokenId << 160) | uint160(tokenAddress);
        require(verify == value);
    }

    /**
     * @dev Note this function will require the tokenId is < uint96.MAX
     * Packs a token address and token id into a single uint256
     *
     * @param tokenAddress  Address of the unpacked token
     * @param tokenId       Id of the unpacked token
     * @return              Token address and token id packed into single uint256
     */
    function tokenToEntity(
        address tokenAddress,
        uint256 tokenId
    ) internal pure returns (uint256) {
        if (tokenId > MAX_UINT96) {
            revert TokenIdExceedsMaxValue(tokenId);
        }
        return (tokenId << 160) | uint160(tokenAddress);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@opengsn/contracts/src/interfaces/IERC2771Recipient.sol";

import {IGameRegistry} from "./IGameRegistry.sol";
import {ISystem} from "./ISystem.sol";

import {TRUSTED_FORWARDER_ROLE} from "../Constants.sol";

/** @title Contract that lets a child contract access the GameRegistry contract */
contract GameRegistryConsumerV2 is ISystem, Ownable, IERC2771Recipient {
    /// @notice Id for the system/component
    uint256 private _id;

    /// @notice Read access contract
    IGameRegistry public gameRegistry;

    /** ERRORS **/

    /// @notice Not authorized to perform action
    error MissingRole(address account, bytes32 expectedRole);

    /** MODIFIERS **/

    // Modifier to verify a user has the appropriate role to call a given function
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /** ERRORS **/

    /// @notice gameRegistryAddress does not implement IGameRegistry
    error InvalidGameRegistry();

    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(address gameRegistryAddress, uint256 id) {
        gameRegistry = IGameRegistry(gameRegistryAddress);
        _id = id;

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }
    }

    /** EXTERNAL **/

    /** @return ID for this system */
    function getId() public view override returns (uint256) {
        return _id;
    }

    /**
     * Sets the GameRegistry contract address for this contract
     *
     * @param gameRegistryAddress  Address for the GameRegistry contract
     */
    function setGameRegistry(address gameRegistryAddress) external onlyOwner {
        gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }
    }

    /** @return GameRegistry contract for this contract */
    function getGameRegistry() external view returns (IGameRegistry) {
        return gameRegistry;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasAccessRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return gameRegistry.hasAccessRole(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!gameRegistry.hasAccessRole(role, account)) {
            revert MissingRole(account, role);
        }
    }

    /**
     * Returns the Player address for the Operator account
     * @param operatorAccount address of the Operator account to retrieve the player for
     */
    function _getPlayerAccount(
        address operatorAccount
    ) internal view returns (address playerAccount) {
        return gameRegistry.getPlayerAccount(operatorAccount);
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(
        address forwarder
    ) public view virtual override returns (bool) {
        return
            address(gameRegistry) != address(0) &&
            _hasAccessRole(TRUSTED_FORWARDER_ROLE, forwarder);
    }

    /** INTERNAL **/

    /// @inheritdoc IERC2771Recipient
    function _msgSender()
        internal
        view
        virtual
        override(Context, IERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData()
        internal
        view
        virtual
        override(Context, IERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// @title Interface the game's ACL / Management Layer
interface IGameRegistry is IERC165 {
    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasAccessRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /**
     * @return Whether or not the registry is paused
     */
    function paused() external view returns (bool);

    /**
     * Registers a system by id
     *
     * @param systemId          Id of the system
     * @param systemAddress     Address of the system contract
     */
    function registerSystem(uint256 systemId, address systemAddress) external;

    /**
     * @return System based on an id
     */
    function getSystem(uint256 systemId) external view returns (address);

    /**
     * Registers a component using an id and contract address
     * @param componentId Id of the component to register
     * @param componentAddress Address of the component contract
     */
    function registerComponent(
        uint256 componentId,
        address componentAddress
    ) external;

    /**
     * @return A component's contract address given its ID
     */
    function getComponent(uint256 componentId) external view returns (address);

    /**
     * @return A component's id given its contract address
     */
    function getComponentIdFromAddress(
        address componentAddr
    ) external view returns (uint256);

    /**
     * @return Boolean indicating if entity belongs to component
     */
    function getEntityHasComponent(
        uint256 entity,
        uint256 componentId
    ) external view returns (bool);

    /**
     * @return Entire array of components belonging an entity
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function getEntityComponents(
        uint256 componentId
    ) external view returns (uint256[] memory);

    /**
     * @return Number of components belonging to an entity
     */
    function getEntityComponentCount(
        uint256 componentId
    ) external view returns (uint256);

    /**
     * Register a component value update.
     * Emits the `ComponentValueSet` event for clients to reconstruct the state.
     */
    function registerComponentValueSet(
        uint256 entity,
        bytes calldata data
    ) external;

    /**
     * Register a component batch value update.
     * Emits the `ComponentBatchValuesSet` event for clients to reconstruct the state.
     */
    function batchRegisterComponentValueSet(
        uint256[] calldata entities,
        bytes[] calldata data
    ) external;

    /**
     * Register a component value removal.
     * Emits the `ComponentValueRemoved` event for clients to reconstruct the state.
     */
    function registerComponentValueRemoved(uint256 entity) external;

    /**
     * Register a component batch value removal.
     * Emits the `ComponentBatchValuesRemoved` event for clients to reconstruct the state.
     */
    function batchRegisterComponentValueRemoved(
        uint256[] calldata entities
    ) external;

    /**
     * Generate a new general-purpose entity GUID
     */
    function generateGUID() external returns (uint256);

    /** @return Authorized Player account for an address
     * @param operatorAddress   Address of the Operator account
     */
    function getPlayerAccount(
        address operatorAddress
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Defines a system the game engine
 */
interface ISystem {
    /** @return The ID for the system. Ex: a uint256 casted keccak256 hash */
    function getId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

/**
 * Enum of supported schema types
 * Note: This is pulled directly from MUD (mud.dev) to maintain compatibility
 */
library TypesLibrary {
    enum SchemaValue {
        BOOL,
        INT8,
        INT16,
        INT32,
        INT64,
        INT128,
        INT256,
        INT,
        UINT8,
        UINT16,
        UINT32,
        UINT64,
        UINT128,
        UINT256,
        BYTES,
        STRING,
        ADDRESS,
        BYTES4,
        BOOL_ARRAY,
        INT8_ARRAY,
        INT16_ARRAY,
        INT32_ARRAY,
        INT64_ARRAY,
        INT128_ARRAY,
        INT256_ARRAY,
        INT_ARRAY,
        UINT8_ARRAY,
        UINT16_ARRAY,
        UINT32_ARRAY,
        UINT64_ARRAY,
        UINT128_ARRAY,
        UINT256_ARRAY,
        BYTES_ARRAY,
        STRING_ARRAY,
        ADDRESS_ARRAY
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IComponent} from "./IComponent.sol";
import {GAME_LOGIC_CONTRACT_ROLE} from "../../Constants.sol";
import "../GameRegistryConsumerV2.sol";

/**
 * @title BaseComponent
 * @notice Base component class, strongly derived from mud.dev
 */
abstract contract BaseComponent is IComponent, GameRegistryConsumerV2 {
    /// @notice Mapping from entity id to value in this component
    mapping(uint256 => bytes) internal entityToValue;

    /** SETUP **/

    /**
     * Initializer for this upgradeable contract
     *
     * @param _gameRegistryAddress Address of the GameRegistry contract
     * @param id ID of the component being created
     */
    constructor(
        address _gameRegistryAddress,
        uint256 id
    ) GameRegistryConsumerV2(_gameRegistryAddress, id) {
        // Do nothing
    }

    /** EXTERNAL **/

    /**
     * Set the given component value for the given entity.
     *
     * @param entity Entity to set the value for.
     * @param value Value to set for the given entity.
     */
    function setBytes(
        uint256 entity,
        bytes memory value
    ) public override onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _set(entity, value);
    }

    /**
     * Remove the given entity from this component.
     *
     * @param entity Entity to remove from this component.
     */
    function remove(
        uint256 entity
    ) public override onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _remove(entity);
    }

    /**
     * Check whether the given entity has a value in this component.
     *
     * @param entity Entity to check whether it has a value in this component for.
     */
    function has(uint256 entity) public view virtual override returns (bool) {
        return entityToValue[entity].length != 0;
    }

    /**
     * Get the raw (abi-encoded) value of the given entity in this component.
     *
     * @param entity Entity to get the raw value in this component for.
     */
    function getBytes(
        uint256 entity
    ) public view virtual override returns (bytes memory) {
        return entityToValue[entity];
    }

    /** INTERNAL */

    /**
     * Set the given component value for the given entity.
     *
     * @param entity Entity to set the value for.
     * @param value Value to set for the given entity.
     */
    function _set(uint256 entity, bytes memory value) internal virtual {
        // Store the entity's value;
        entityToValue[entity] = value;

        // Emit global event
        gameRegistry.registerComponentValueSet(entity, value);
    }

    /**
     * Remove the given entity from this component.
     *
     * @param entity Entity to remove from this component.
     */
    function _remove(uint256 entity) internal virtual {
        // Remove the entity from the mapping
        delete entityToValue[entity];

        // Emit global event
        gameRegistry.registerComponentValueRemoved(entity);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {TypesLibrary} from "../TypesLibrary.sol";

interface IComponent {
    /**
     * Sets the raw bytes value for this component
     *
     * @param entity Entity to set value for
     * @param value Bytes encoded value for this comoonent
     */
    function setBytes(uint256 entity, bytes memory value) external;

    /**
     * Removes an entity from this component
     * @param entity Entity to remove
     */
    function remove(uint256 entity) external;

    /**
     * Whether or not the entity exists in this component
     * @param entity Entity to check for
     * @return true if the entity exists
     */
    function has(uint256 entity) external view returns (bool);

    /**
     * @param entity Entity to retrieve value for
     * @return The raw bytes value for the given entity in this component
     */
    function getBytes(uint256 entity) external view returns (bytes memory);

    /** Return the keys and value types of the schema of this component. */
    function getSchema()
        external
        pure
        returns (
            string[] memory keys,
            TypesLibrary.SchemaValue[] memory values
        );
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {GAME_LOGIC_CONTRACT_ROLE, MANAGER_ROLE} from "../Constants.sol";
import {GameRegistryConsumerUpgradeable} from "../GameRegistryConsumerUpgradeable.sol";
import {ID, ICountingSystem} from "./ICountingSystem.sol";

/// @notice Be sure to list your counting key in `packages/shared/src/countingIds.ts`.
contract CountingSystem is ICountingSystem, GameRegistryConsumerUpgradeable {
    /** MEMBERS */
    /// @notice This should be an entity ➞ keccak256 hash ➞ count (value).
    // The creation of that keccak256 is left as an exercise for the caller.
    mapping(uint256 => mapping(uint256 => uint256)) public counters;

    /** EVENTS */

    /// @notice Emitted when the count has been forcibly set.
    event CountSet(uint256 entity, uint256 key, uint256 newTotal);

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /**
     * Get the stored counter's value.
     *
     * @param entity    The entity in the mapping.
     * @param key       The key in the mapping.
     * @return value    The value in the mapping.
     */
    function getCount(
        uint256 entity,
        uint256 key
    ) external view returns (uint256) {
        return counters[entity][key];
    }

    /**
     * Set the stored counter's value.
     * (Mostly intended for debug purposes.)
     *
     * @param entity    The entity in the mapping.
     * @param key       The key in the mapping.
     * @param value     The value in the mapping.
     */
    function setCount(
        uint256 entity,
        uint256 key,
        uint256 value
    ) external onlyRole(GAME_LOGIC_CONTRACT_ROLE) whenNotPaused {
        counters[entity][key] = value;
        emit CountSet(entity, key, value);
    }

    /**
     * Increments the stored counter by some amount.
     *
     * @param entity    The entity in the mapping.
     * @param key       The key in the mapping.
     * @param amount    The amount to increment by.
     */
    function incrementCount(
        uint256 entity,
        uint256 key,
        uint256 amount
    ) external onlyRole(GAME_LOGIC_CONTRACT_ROLE) whenNotPaused {
        counters[entity][key] += amount;
        emit CountSet(entity, key, counters[entity][key]);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.countingsystem"));

/**
 * @title Simple Counting System
 */
interface ICountingSystem {
    /**
     * Get the stored counter's value.
     *
     * @param entityId  The entityId in the mapping.
     * @param key       The key in the mapping.
     * @return value    The value in the mapping.
     */
    function getCount(uint256 entityId, uint256 key)
        external
        view
        returns (uint256);

    /**
     * Set the stored counter's value.
     * (Mostly intended for debug purposes.)
     *
     * @param entityId  The entityId in the mapping.
     * @param key       The key in the mapping.
     * @param value     The value in the mapping.
     */
    function setCount(
        uint256 entityId,
        uint256 key,
        uint256 value
    ) external;

    /**
     * Increments the stored counter by some amount.
     *
     * @param entityId  The entityId in the mapping.
     * @param key       The key in the mapping.
     * @param amount    The amount to increment by.
     */
    function incrementCount(
        uint256 entityId,
        uint256 key,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.energysystem"));

/// @title Interface for the EnergySystem that lets tokens have energy associated with them
interface IEnergySystem {
    /**
     * Gives energy to the given token
     *
     * @param tokenContract Contract to give energy to
     * @param tokenId       Token id to give energy to
     * @param amount        Amount of energy to give
     */
    function giveEnergy(
        address tokenContract,
        uint256 tokenId,
        uint256 amount
    ) external;

    /**
     * Spends energy for the given token
     *
     * @param tokenContract Contract to spend energy for
     * @param tokenId       Token id to spend energy for
     * @param amount        Amount of energy to spend
     */
    function spendEnergy(
        address tokenContract,
        uint256 tokenId,
        uint256 amount
    ) external;

    /**
     * @param tokenContract Contract to get milestones for
     * @param tokenId       Token id to get milestones for
     *
     * @return The amount of energy the token currently has
     */
    function getEnergy(
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);
}

/// @title Interface for the EnergySystem that lets tokens have energy associated with them
interface IEnergySystemV3 {
    /**
     * Gives energy to the given entity
     *
     * @param entity        Entity to give energy to
     * @param amount        Amount of energy to give
     */
    function giveEnergy(uint256 entity, uint256 amount) external;

    /**
     * Spends energy for the given entity
     *
     * @param entity        Entity to spend energy for
     * @param amount        Amount of energy to spend
     */
    function spendEnergy(uint256 entity, uint256 amount) external;

    /**
     * @param entity Entity to get energy for
     *
     * @return The amount of energy the token currently has
     */
    function getEnergy(uint256 entity) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TypesLibrary} from "../../core/TypesLibrary.sol";
import {BaseComponent, IComponent} from "../../core/components/BaseComponent.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.activebountycomponent"));

/**
 * @title ActiveBountyComponent
 * @dev This component is used to mark the active bounty for a player.
 */
contract ActiveBountyComponent is BaseComponent {
    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(
        address gameRegistryAddress
    ) BaseComponent(gameRegistryAddress, ID) {
        // Do nothing
    }

    /**
     * @inheritdoc IComponent
     */
    function getSchema()
        public
        pure
        override
        returns (string[] memory keys, TypesLibrary.SchemaValue[] memory values)
    {
        keys = new string[](6);
        values = new TypesLibrary.SchemaValue[](6);
    
        // The status of the bounty (uint256 rep of the enum).
        keys[0] = "status";
        values[0] = TypesLibrary.SchemaValue.UINT32;
    
        // User wallet address
        keys[1] = "account";
        values[1] = TypesLibrary.SchemaValue.ADDRESS;
    
        // Active bounty start time
        keys[2] = "start_time";
        values[2] = TypesLibrary.SchemaValue.UINT32;
    
        // Bounty id
        keys[3] = "bounty_id";
        values[3] = TypesLibrary.SchemaValue.UINT256;
    
        // Group id
        keys[4] = "group_id";
        values[4] = TypesLibrary.SchemaValue.UINT256;
    
        // Entity inputs used for this bounty
        keys[5] = "entity_inputs";
        values[5] = TypesLibrary.SchemaValue.UINT256_ARRAY;
    
    }

    /**
     * Sets the typed value for this component
     *
     * @param entity Entity to get value for 
     * @param status uint32 The status of the bounty (uint256 rep of the enum).    
     * @param account address User wallet address    
     * @param startTime uint32 Active bounty start time    
     * @param bountyId uint256 Bounty id    
     * @param groupId uint256 Group id    
     * @param entityInputs uint256[] Entity inputs used for this bounty    
     */
    function setValue(
        uint256 entity,
        uint32 status,
        address account,
        uint32 startTime,
        uint256 bountyId,
        uint256 groupId,
        uint256[] memory entityInputs
    ) external virtual {
        setBytes(entity, abi.encode(status, account, startTime, bountyId, groupId, entityInputs));
    }

    /**
     * Returns the typed value for this component
     *
     * @param entity Entity to get value for
     */
    function getValue(
        uint256 entity
    )
        external
        view
        virtual
        returns (
            uint32 status,
            address account,
            uint32 startTime,
            uint256 bountyId,
            uint256 groupId,
            uint256[] memory entityInputs
        )
    {
        if (has(entity)) {
            (status, account, startTime, bountyId, groupId, entityInputs) = abi.decode(
                getBytes(entity),
                (uint32, address, uint32, uint256, uint256, uint256[])
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TypesLibrary} from "../../core/TypesLibrary.sol";
import {BaseComponent, IComponent} from "../../core/components/BaseComponent.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.bountyaccountdatacomponent"));

/**
 * @title BountyAccountDataComponent
 * @dev Bounty Account Data
 */
contract BountyAccountDataComponent is BaseComponent {
    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(
        address gameRegistryAddress
    ) BaseComponent(gameRegistryAddress, ID) {
        // Do nothing
    }

    /**
     * @inheritdoc IComponent
     */
    function getSchema()
        public
        pure
        override
        returns (string[] memory keys, TypesLibrary.SchemaValue[] memory values)
    {
        keys = new string[](2);
        values = new TypesLibrary.SchemaValue[](2);
    
        // User wallet address
        keys[0] = "account";
        values[0] = TypesLibrary.SchemaValue.ADDRESS;
    
        // Array of user active bounty IDs
        keys[1] = "active_bounty_ids";
        values[1] = TypesLibrary.SchemaValue.UINT256_ARRAY;
    
    }

    /**
     * Sets the typed value for this component
     *
     * @param entity Entity to get value for 
     * @param account address User wallet address    
     * @param activeBountyIds uint256[] Array of user active bounty IDs    
     */
    function setValue(
        uint256 entity,
        address account,
        uint256[] memory activeBountyIds
    ) external virtual {
        setBytes(entity, abi.encode(account, activeBountyIds));
    }

    /**
     * Returns the typed value for this component
     *
     * @param entity Entity to get value for
     */
    function getValue(
        uint256 entity
    )
        external
        view
        virtual
        returns (
            address account,
            uint256[] memory activeBountyIds
        )
    {
        if (has(entity)) {
            (account, activeBountyIds) = abi.decode(
                getBytes(entity),
                (address, uint256[])
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TypesLibrary} from "../../core/TypesLibrary.sol";
import {BaseComponent, IComponent} from "../../core/components/BaseComponent.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.bountycomponent"));

/**
 * @title BountyComponent
 * @dev This component defines rules for a Bounty. Each entity is a namespace GUID defined in the SoT
 */
contract BountyComponent is BaseComponent {
    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(
        address gameRegistryAddress
    ) BaseComponent(gameRegistryAddress, ID) {
        // Do nothing
    }

    /**
     * @inheritdoc IComponent
     */
    function getSchema()
        public
        pure
        override
        returns (string[] memory keys, TypesLibrary.SchemaValue[] memory values)
    {
        keys = new string[](7);
        values = new TypesLibrary.SchemaValue[](7);
    
        
        keys[0] = "success_xp";
        values[0] = TypesLibrary.SchemaValue.UINT32;
    
        // Lower bound of staked amount required for reward
        keys[1] = "lower_bound";
        values[1] = TypesLibrary.SchemaValue.UINT32;
    
        // Upper bound of staked amount required for reward
        keys[2] = "upper_bound";
        values[2] = TypesLibrary.SchemaValue.UINT32;
    
        // Amount of time (in seconds) to complete this Bounty + NFTs are locked for
        keys[3] = "bounty_time_lock";
        values[3] = TypesLibrary.SchemaValue.UINT32;
    
        // Bounty Group ID defined in the SoT, ex: WOOD_BOUNTY
        keys[4] = "group_id";
        values[4] = TypesLibrary.SchemaValue.UINT256;
    
        // Bounty Input Loot component namespace GUID defined in the SoT
        keys[5] = "input_loot_set_entity";
        values[5] = TypesLibrary.SchemaValue.UINT256;
    
        // Bounty Output Loot component namespace GUID defined in the SoT
        keys[6] = "output_loot_set_entity";
        values[6] = TypesLibrary.SchemaValue.UINT256;
    
    }

    /**
     * Sets the typed value for this component
     *
     * @param entity Entity to get value for 
     * @param successXp uint32     
     * @param lowerBound uint32 Lower bound of staked amount required for reward    
     * @param upperBound uint32 Upper bound of staked amount required for reward    
     * @param bountyTimeLock uint32 Amount of time (in seconds) to complete this Bounty + NFTs are locked for    
     * @param groupId uint256 Bounty Group ID defined in the SoT, ex: WOOD_BOUNTY    
     * @param inputLootEntity uint256 Bounty Input Loot component namespace GUID defined in the SoT    
     * @param outputLootEntity uint256 Bounty Output Loot component namespace GUID defined in the SoT    
     */
    function setValue(
        uint256 entity,
        uint32 successXp,
        uint32 lowerBound,
        uint32 upperBound,
        uint32 bountyTimeLock,
        uint256 groupId,
        uint256 inputLootEntity,
        uint256 outputLootEntity
    ) external virtual {
        setBytes(entity, abi.encode(successXp, lowerBound, upperBound, bountyTimeLock, groupId, inputLootEntity, outputLootEntity));
    }

    /**
     * Returns the typed value for this component
     *
     * @param entity Entity to get value for
     */
    function getValue(
        uint256 entity
    )
        external
        view
        virtual
        returns (
            uint32 successXp,
            uint32 lowerBound,
            uint32 upperBound,
            uint32 bountyTimeLock,
            uint256 groupId,
            uint256 inputLootEntity,
            uint256 outputLootEntity
        )
    {
        if (has(entity)) {
            (successXp, lowerBound, upperBound, bountyTimeLock, groupId, inputLootEntity, outputLootEntity) = abi.decode(
                getBytes(entity),
                (uint32, uint32, uint32, uint32, uint256, uint256, uint256)
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TypesLibrary} from "../../core/TypesLibrary.sol";
import {BaseComponent, IComponent} from "../../core/components/BaseComponent.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.enabledcomponent"));

/**
 * @title EnabledComponent
 * @dev maps entity id → boolean if enabled or not
 */
contract EnabledComponent is BaseComponent {
    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(
        address gameRegistryAddress
    ) BaseComponent(gameRegistryAddress, ID) {
        // Do nothing
    }

    /**
     * @inheritdoc IComponent
     */
    function getSchema()
        public
        pure
        override
        returns (string[] memory keys, TypesLibrary.SchemaValue[] memory values)
    {
        keys = new string[](1);
        values = new TypesLibrary.SchemaValue[](1);
    
        // Whether the entity is enabled or not
        keys[0] = "value";
        values[0] = TypesLibrary.SchemaValue.BOOL;
    
    }

    /**
     * Sets the typed value for this component
     *
     * @param entity Entity to get value for 
     * @param value bool Whether the entity is enabled or not    
     */
    function setValue(
        uint256 entity,
        bool value
    ) external virtual {
        setBytes(entity, abi.encode(value));
    }

    /**
     * Returns the typed value for this component
     *
     * @param entity Entity to get value for
     */
    function getValue(
        uint256 entity
    )
        external
        view
        virtual
        returns (
            bool value
        )
    {
        if (has(entity)) {
            (value) = abi.decode(
                getBytes(entity),
                (bool)
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TypesLibrary} from "../../core/TypesLibrary.sol";
import {BaseComponent, IComponent} from "../../core/components/BaseComponent.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.lootsetcomponent"));

/**
 * @title LootSetComponent
 * @dev Loot Set Component
 */
contract LootSetComponent is BaseComponent {
    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(
        address gameRegistryAddress
    ) BaseComponent(gameRegistryAddress, ID) {
        // Do nothing
    }

    /**
     * @inheritdoc IComponent
     */
    function getSchema()
        public
        pure
        override
        returns (string[] memory keys, TypesLibrary.SchemaValue[] memory values)
    {
        keys = new string[](4);
        values = new TypesLibrary.SchemaValue[](4);
    
        // Type of fulfillment (ERC721, ERC1155, ERC20, LOOT_TABLE)
        keys[0] = "loot_type";
        values[0] = TypesLibrary.SchemaValue.UINT32_ARRAY;
    
        // Contract to grant tokens from
        keys[1] = "token_contract";
        values[1] = TypesLibrary.SchemaValue.ADDRESS_ARRAY;
    
        // Id of the token to grant (ERC1155/LOOT TABLE/CALLBACK types only)
        keys[2] = "loot_id";
        values[2] = TypesLibrary.SchemaValue.UINT256_ARRAY;
    
        // Amount of token to grant (XP, ERC20, ERC1155)
        keys[3] = "amount";
        values[3] = TypesLibrary.SchemaValue.UINT256_ARRAY;
    
    }

    /**
     * Sets the typed value for this component
     *
     * @param entity Entity to get value for 
     * @param lootType uint32[] Type of fulfillment (ERC721, ERC1155, ERC20, LOOT_TABLE)    
     * @param tokenContract address[] Contract to grant tokens from    
     * @param lootId uint256[] Id of the token to grant (ERC1155/LOOT TABLE/CALLBACK types only)    
     * @param amount uint256[] Amount of token to grant (XP, ERC20, ERC1155)    
     */
    function setValue(
        uint256 entity,
        uint32[] memory lootType,
        address[] memory tokenContract,
        uint256[] memory lootId,
        uint256[] memory amount
    ) external virtual {
        setBytes(entity, abi.encode(lootType, tokenContract, lootId, amount));
    }

    /**
     * Returns the typed value for this component
     *
     * @param entity Entity to get value for
     */
    function getValue(
        uint256 entity
    )
        external
        view
        virtual
        returns (
            uint32[] memory lootType,
            address[] memory tokenContract,
            uint256[] memory lootId,
            uint256[] memory amount
        )
    {
        if (has(entity)) {
            (lootType, tokenContract, lootId, amount) = abi.decode(
                getBytes(entity),
                (uint32[], address[], uint256[], uint256[])
            );
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IHoldingConsumer {
    /**
     * @param account Account to check hold time of
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held a token
     */
    function getTimeHeld(
        address account,
        uint256 tokenId
    ) external view returns (uint32);

    /**
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held the token
     */
    function getLastTransfer(uint256 tokenId) external view returns (uint32);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {ITraitsProvider} from "./ITraitsProvider.sol";

/** @title Consumer of traits, exposes functions to get traits for this contract */
interface ITraitsConsumer {
    /** @return Token name for the given tokenId */
    function tokenName(uint256 tokenId) external view returns (string memory);

    /** @return Token name for the given tokenId */
    function tokenDescription(uint256 tokenId)
        external
        view
        returns (string memory);

    /** @return Image URI for the given tokenId */
    function imageURI(uint256 tokenId) external view returns (string memory);

    /** @return External URI for the given tokenId */
    function externalURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.traitsprovider"));

// Enum describing how the trait can be modified
enum TraitBehavior {
    NOT_INITIALIZED, // Trait has not been initialized
    UNRESTRICTED, // Trait can be changed unrestricted
    IMMUTABLE, // Trait can only be set once and then never changed
    INCREMENT_ONLY, // Trait can only be incremented
    DECREMENT_ONLY // Trait can only be decremented
}

// Type of data to allow in the trait
enum TraitDataType {
    NOT_INITIALIZED, // Trait has not been initialized
    INT, // int256 data type
    UINT, // uint256 data type
    BOOL, // bool data type
    STRING, // string data type
    INT_ARRAY, // int256 array data type
    UINT_ARRAY // uint256 array data type
}

// Holds metadata for a given trait type
struct TraitMetadata {
    // Name of the trait, used in tokenURIs
    string name;
    // How the trait can be modified
    TraitBehavior behavior;
    // Trait type
    TraitDataType dataType;
    // Whether or not the trait is a top-level property and should not be in the attribute array
    bool isTopLevelProperty;
    // Whether or not the trait should be hidden from end-users
    bool hidden;
}

// Used to pass traits around for URI generation
struct TokenURITrait {
    string name;
    bytes value;
    TraitDataType dataType;
    bool isTopLevelProperty;
    bool hidden;
}

/** @title Provides a set of traits to a set of ERC721/ERC1155 contracts */
interface ITraitsProvider is IERC165 {
    /**
     * Sets the value for the string trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitString(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        string calldata value
    ) external;

    /**
     * Sets several string traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitString(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        string[] calldata values
    ) external;

    /**
     * Sets the value for the uint256 trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitUint256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 value
    ) external;

    /**
     * Sets several uint256 traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitUint256(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        uint256[] calldata values
    ) external;

    /**
     * Sets the value for the int256 trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        int256 value
    ) external;

    /**
     * Sets several int256 traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitInt256(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        int256[] calldata values
    ) external;

    /**
     * Sets the value for the int256[] trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        int256[] calldata value
    ) external;

    /**
     * Sets the value for the uint256[] trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitUint256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256[] calldata value
    ) external;

    /**
     * Sets the value for the bool trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitBool(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        bool value
    ) external;

    /**
     * Sets several bool traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitBool(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        bool[] calldata values
    ) external;

    /**
     * Increments the trait for a token by the given amount
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to increment trait by
     */
    function incrementTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 amount
    ) external;

    /**
     * Decrements the trait for a token by the given amount
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to decrement trait by
     */
    function decrementTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 amount
    ) external;

    /**
     * Returns the trait data for a given token
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     *
     * @return A struct containing all traits for the token
     */
    function getTraitIds(
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256[] memory);

    /**
     * Retrieves a raw abi-encoded byte data for the given trait
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitBytes(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bytes memory);

    /**
     * Retrieves a int256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (int256);

    /**
     * Retrieves a int256 array trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (int256[] memory);

    /**
     * Retrieves a uint256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitUint256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (uint256);

    /**
     * Retrieves a uint256 array trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitUint256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (uint256[] memory);

    /**
     * Retrieves a bool trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitBool(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * Retrieves a string trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitString(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (string memory);

    /**
     * Returns whether or not the given token has a trait
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function hasTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * @param traitId  Id of the trait to get metadata for
     * @return Metadata for the given trait
     */
    function getTraitMetadata(
        uint256 traitId
    ) external view returns (TraitMetadata memory);

    /**
     * Generate a tokenURI based on a set of global properties and traits
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURI(
        address tokenContract,
        uint256 tokenId,
        TokenURITrait[] memory extraTraits
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.levelsystem"));

interface ILevelSystem {
    /**
     * Grants XP to the given token
     *
     * @param tokenContract Address of the NFT
     * @param tokenId       Id of the NFT token
     * @param amount        Amount of XP to grant
     */
    function grantXP(
        address tokenContract,
        uint256 tokenId,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./GameRegistryLibrary.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ITraitsProvider} from "../interfaces/ITraitsConsumer.sol";
import {IGameItems} from "../tokens/gameitems/IGameItems.sol";
import {IGameCurrency} from "../tokens/IGameCurrency.sol";
import {LEVEL_TRAIT_ID} from "../Constants.sol";

/** @title Common helper functions for the game **/
library GameHelperLibrary {
    /** @return level for the given token */
    function _levelForPirate(
        ITraitsProvider traitsProvider,
        address tokenContract,
        uint256 tokenId
    ) internal view returns (uint256) {
        if (traitsProvider.hasTrait(tokenContract, tokenId, LEVEL_TRAIT_ID)) {
            return
                traitsProvider.getTraitUint256(
                    tokenContract,
                    tokenId,
                    LEVEL_TRAIT_ID
                );
        } else {
            return 0;
        }
    }

    /**
     * verify is an account owns an input
     *
     * @param input the quest input to verify
     * @param account the owner's address
     *
     */
    function _verifyInputOwnership(
        GameRegistryLibrary.TokenPointer memory input,
        address account
    ) internal view {
        if (input.tokenType == GameRegistryLibrary.TokenType.ERC20) {
            require(
                IGameCurrency(input.tokenContract).balanceOf(account) >=
                    input.amount,
                "INSUFFICIENT_FUNDS"
            );
        } else if (input.tokenType == GameRegistryLibrary.TokenType.ERC721) {
            require(
                IERC721(input.tokenContract).ownerOf(input.tokenId) == account,
                "NOT_OWNER"
            );
        } else if (input.tokenType == GameRegistryLibrary.TokenType.ERC1155) {
            require(
                IGameItems(input.tokenContract).balanceOf(
                    account,
                    input.tokenId
                ) >= input.amount,
                "NOT_OWNER"
            );
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

/** @title Global common constants for the game **/
library GameRegistryLibrary {
    /** Reservation constants -- Used to determined how a token was locked */
    uint32 internal constant RESERVATION_UNDEFINED = 0;
    uint32 internal constant RESERVATION_QUEST_SYSTEM = 1;
    uint32 internal constant RESERVATION_CRAFTING_SYSTEM = 2;

    /** Global generic structs that let the game contracts utilize/lock token resources */

    enum TokenType {
        UNDEFINED,
        ERC20,
        ERC721,
        ERC1155
    }

    // Generic Token Pointer
    struct TokenPointer {
        // Type of token
        TokenType tokenType;
        // Address of the token contract
        address tokenContract;
        // Id of the token (if ERC721 or ERC1155)
        uint256 tokenId;
        // Amount of the token (if ERC20 or ERC1155)
        uint256 amount;
    }

    // Reference to a GameItem
    struct GameItemPointer {
        // Address of the game item contract
        address tokenContract;
        // Id of the ERC1155 token
        uint256 tokenId;
        // Amount of ERC1155 that was staked
        uint256 amount;
    }

    // Reference to a GameNFT
    struct GameNFTPointer {
        // Address of the NFT contract
        address tokenContract;
        // Id of the NFT
        uint256 tokenId;
    }

    struct ReservedToken {
        // Type of token
        TokenType tokenType;
        // Address of the token contract
        address tokenContract;
        // Id of the token (if ERC721 or ERC1155)
        uint256 tokenId;
        // Amount of the token (if ERC20 or ERC1155)
        uint256 amount;
        // reservationId for the locking system
        uint32 reservationId;
    }

    // Struct to point and store game items
    struct ReservedGameItem {
        // Address of the game item contract
        address tokenContract;
        // Id of the ERC1155 token
        uint256 tokenId;
        // Amount of ERC1155 that was staked
        uint256 amount;
        // LockingSystem reservation id, puts a hold on the items
        uint32 reservationId;
    }

    // Struct to point and store game NFTs
    struct ReservedGameNFT {
        // Address of the NFT contract
        address tokenContract;
        // Id of the NFT
        uint256 tokenId;
        // LockingSystem reservationId to put a hold on the NFT
        uint32 reservationId;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {PERCENTAGE_RANGE} from "../Constants.sol";

library RandomLibrary {
    // Generates a new random word from a previous random word
    function generateNextRandomWord(uint256 randomWord)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        gasleft(),
                        randomWord
                    )
                )
            );
    }

    /**
     * Perform a weighted coinflip to determine success or failure.
     * @param randomWord    VRF generated random word, will be incremented before used
     * @param successRate   Between 0 - PERCENTAGE_RANGE. Chance of success (0 = 0%, 10000 = 100%)
     * @return success      Whether flip was successful
     * @return nextRandomWord   Random word that was used to flip
     */
    function weightedCoinFlip(uint256 randomWord, uint256 successRate)
        internal
        view
        returns (bool success, uint256 nextRandomWord)
    {
        if (successRate >= PERCENTAGE_RANGE) {
            success = true;
            nextRandomWord = randomWord;
        } else {
            nextRandomWord = generateNextRandomWord(randomWord);
            success = nextRandomWord % PERCENTAGE_RANGE < successRate;
        }
    }

    /**
     * Perform a multiple weighted coinflips to determine success or failure.
     *
     * @param randomWord    VRF generated random word, will be incremented before used
     * @param successRate   Between 0 - PERCENTAGE_RANGE. Chance of success (0 = 0%, 10000 = 100%)
     * @param amount        Number of flips to perform
     * @return numSuccess   How many flips were successful
     * @return nextRandomWord   Last random word that was used to flip
     */
    function weightedCoinFlipBatch(
        uint256 randomWord,
        uint256 successRate,
        uint8 amount
    ) internal view returns (uint8 numSuccess, uint256 nextRandomWord) {
        if (successRate >= PERCENTAGE_RANGE) {
            numSuccess = amount;
            nextRandomWord = randomWord;
        } else {
            numSuccess = 0;
            for (uint8 idx; idx < amount; ++idx) {
                nextRandomWord = generateNextRandomWord(randomWord);
                if (nextRandomWord % PERCENTAGE_RANGE < successRate) {
                    numSuccess++;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ITraitsProvider, TraitDataType} from "../interfaces/ITraitsProvider.sol";

/** Trait checking structs */

// Type of check to perform for a trait
enum TraitCheckType {
    UNDEFINED,
    TRAIT_EQ,
    TRAIT_GT,
    TRAIT_LT,
    TRAIT_LTE,
    TRAIT_GTE,
    EXIST,
    NOT_EXIST
}

// A single trait value check
struct TraitCheck {
    // Type of check to perform
    TraitCheckType checkType;
    // Id of the trait to check a value for
    uint256 traitId;
    // Trait value, value to compare against for trait check
    int256 traitValue;
}

/** @title Common traits types and related functions for the game **/
library TraitsLibrary {
    /** ERRORS **/

    /// @notice Invalid trait check type
    error InvalidTraitCheckType(TraitCheckType checkType);

    /// @notice Trait was not equal
    error TraitCheckFailed(TraitCheckType checkType);

    /// @notice Trait check was not for a int-compatible type
    error ExpectedIntForTraitCheck();

    /**
     * Performs a trait value check against a given token
     *
     * @param traitsProvider Reference to the traits contract
     * @param traitCheck Trait check to perform
     * @param tokenContract Address of the token
     * @param tokenId Id of the token
     */
    function performTraitCheck(
        ITraitsProvider traitsProvider,
        TraitCheck memory traitCheck,
        address tokenContract,
        uint256 tokenId
    ) internal view returns (bool) {
        TraitCheckType checkType = traitCheck.checkType;

        // Existence check
        bool hasTrait = traitsProvider.hasTrait(
            tokenContract,
            tokenId,
            traitCheck.traitId
        );

        if (checkType == TraitCheckType.NOT_EXIST && hasTrait == true) {
            return false;
        }

        // If is missing trait, return false immediately
        if (hasTrait == false) {
            return false;
        }

        // Numeric checks only
        int256 traitValue;

        TraitDataType dataType = traitsProvider
            .getTraitMetadata(traitCheck.traitId)
            .dataType;

        if (dataType == TraitDataType.UINT) {
            traitValue = SafeCast.toInt256(
                traitsProvider.getTraitUint256(
                    tokenContract,
                    tokenId,
                    traitCheck.traitId
                )
            );
        } else if (dataType == TraitDataType.INT) {
            traitValue = traitsProvider.getTraitInt256(
                tokenContract,
                tokenId,
                traitCheck.traitId
            );
        } else if (dataType == TraitDataType.INT) {
            traitValue = traitsProvider.getTraitBool(
                tokenContract,
                tokenId,
                traitCheck.traitId
            )
                ? int256(1)
                : int256(0);
        } else {
            revert ExpectedIntForTraitCheck();
        }

        if (checkType == TraitCheckType.TRAIT_EQ) {
            return traitValue == traitCheck.traitValue;
        } else if (checkType == TraitCheckType.TRAIT_GT) {
            return traitValue > traitCheck.traitValue;
        } else if (checkType == TraitCheckType.TRAIT_GTE) {
            return traitValue >= traitCheck.traitValue;
        } else if (checkType == TraitCheckType.TRAIT_LT) {
            return traitValue < traitCheck.traitValue;
        } else if (checkType == TraitCheckType.TRAIT_LTE) {
            return traitValue <= traitCheck.traitValue;
        } else if (checkType == TraitCheckType.EXIST) {
            return true;
        }

        // Default to not-pass / error
        revert InvalidTraitCheckType(checkType);
    }

    /**
     * Performs a trait value check against a given token
     *
     * @param traitsProvider Reference to the traits contract
     * @param traitCheck Trait check to perform
     * @param tokenContract Address of the token
     * @param tokenId Id of the token
     */
    function requireTraitCheck(
        ITraitsProvider traitsProvider,
        TraitCheck memory traitCheck,
        address tokenContract,
        uint256 tokenId
    ) internal view {
        bool success = performTraitCheck(
            traitsProvider,
            traitCheck,
            tokenContract,
            tokenId
        );
        if (!success) {
            revert TraitCheckFailed(traitCheck.checkType);
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.lockingsystem"));

/// @title Interface for the LockingSystem that allows tokens to be locked by the game to prevent transfer
interface ILockingSystem is IERC165 {
    /**
     * Whether or not an NFT is locked
     *
     * @param tokenContract Token contract address
     * @param tokenId       Id of the token
     */
    function isNFTLocked(address tokenContract, uint256 tokenId)
        external
        view
        returns (bool);

    /**
     * Amount of token locked in the system by a given owner
     *
     * @param account   	  Token owner
     * @param tokenContract	Token contract address
     * @param tokenId       Id of the token
     *
     * @return Number of tokens locked
     */
    function itemAmountLocked(
        address account,
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * Amount of tokens available for unlock
     *
     * @param account       Token owner
     * @param tokenContract Token contract address
     * @param tokenId       Id of the token
     *
     * @return Number of tokens locked
     */
    function itemAmountUnlocked(
        address account,
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * Whether or not the given items can be transferred
     *
     * @param account   	    Token owner
     * @param tokenContract	    Token contract address
     * @param ids               Ids of the tokens
     * @param amounts           Amounts of the tokens
     *
     * @return Whether or not the given items can be transferred
     */
    function canTransferItems(
        address account,
        address tokenContract,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external view returns (bool);

    /**
     * Lets the game add a reservation to a given NFT, this prevents the NFT from being unlocked
     *
     * @param tokenContract   Token contract address
     * @param tokenId         Token id to reserve
     * @param exclusive       Whether or not the reservation is exclusive. Exclusive reservations prevent other reservations from using the tokens by removing them from the pool.
     * @param data            Data determined by the reserver, can be used to identify the source of the reservation for display in UI
     */
    function addNFTReservation(
        address tokenContract,
        uint256 tokenId,
        bool exclusive,
        uint32 data
    ) external returns (uint32);

    /**
     * Lets the game remove a reservation from a given token
     *
     * @param tokenContract Token contract
     * @param tokenId       Id of the token
     * @param reservationId Id of the reservation to remove
     */
    function removeNFTReservation(
        address tokenContract,
        uint256 tokenId,
        uint32 reservationId
    ) external;

    /**
     * Lets the game add a reservation to a given token, this prevents the token from being unlocked
     *
     * @param account  			    Owner of the token to reserver
     * @param tokenContract   Token contract address
     * @param tokenId  				Token id to reserve
     * @param amount 					Number of tokens to reserve (1 for NFTs, >=1 for ERC1155)
     * @param exclusive				Whether or not the reservation is exclusive. Exclusive reservations prevent other reservations from using the tokens by removing them from the pool.
     * @param data            Data determined by the reserver, can be used to identify the source of the reservation for display in UI
     */
    function addItemReservation(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint256 amount,
        bool exclusive,
        uint32 data
    ) external returns (uint32);

    /**
     * Lets the game remove a reservation from a given token
     *
     * @param account   			Owner to remove reservation from
     * @param tokenContract	Token contract
     * @param tokenId  			Id of the token
     * @param reservationId Id of the reservation to remove
     */
    function removeItemReservation(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint32 reservationId
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.lootsystem"));

/// @title Interface for the LootSystem that gives player loot (tokens, XP, etc) for playing the game
interface ILootSystem is IERC165 {
    // Type of loot
    enum LootType {
        UNDEFINED,
        ERC20,
        ERC721,
        ERC1155,
        LOOT_TABLE,
        CALLBACK
    }

    // Individual loot to grant
    struct Loot {
        // Type of fulfillment (ERC721, ERC1155, ERC20, LOOT_TABLE)
        LootType lootType;
        // Contract to grant tokens from
        address tokenContract;
        // Id of the token to grant (ERC1155/LOOT TABLE/CALLBACK types only)
        uint256 lootId;
        // Amount of token to grant (XP, ERC20, ERC1155)
        uint256 amount;
    }

    /**
     * Grants the given user loot(s), calls VRF to ensure it's truly random
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     */
    function grantLoot(address to, Loot[] calldata loots) external;

    /**
     * Grants the given user loot(s), calls VRF to ensure it's truly random
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     * @param randomWord  Optional random word to skip VRF callback if we already have words generated / are in a VRF callback
     */
    function grantLootWithRandomWord(
        address to,
        Loot[] calldata loots,
        uint256 randomWord
    ) external;

    /**
     * Grants the given user loot(s) in batches. Presumes no randomness or loot tables
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     * @param amount      Amount of each loot to grant
     */
    function batchGrantLootWithoutRandomness(
        address to,
        Loot[] calldata loots,
        uint8 amount
    ) external;

    /**
     * Validate that loots are properly formed. Reverts if the loots are not valid
     *
     * @param loots Loots to validate
     * @return needsVRF Whether or not the loots specified require VRF to generate
     */
    function validateLoots(
        Loot[] calldata loots
    ) external view returns (bool needsVRF);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.questsystem"));

/// @title Interface for the QuestSystem that lets players go on quests
interface IQuestSystem {
    /**
     * Whether or not a given quest is available to the given player
     *
     * @param account Account to check if quest is available for
     * @param questId Id of the quest to see is available
     *
     * @return Whether or not the quest is available to the given account
     */
    function isQuestAvailable(address account, uint32 questId)
        external
        view
        returns (bool);

    /**
     * @return completions How many times the quest was completed by the given account
     * @return lastCompletionTime Last completion timestamp for the given quest and account
     */
    function getQuestDataForAccount(address account, uint32 questId)
        external
        view
        returns (uint32 completions, uint32 lastCompletionTime);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {GameRegistryLibrary} from "../libraries/GameRegistryLibrary.sol";
import {GameHelperLibrary} from "../libraries/GameHelperLibrary.sol";
import "../libraries/TraitsLibrary.sol";
import "../libraries/RandomLibrary.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";

import {RANDOMIZER_ROLE, MANAGER_ROLE, GAME_CURRENCY_CONTRACT_ROLE, PERCENTAGE_RANGE, GAME_NFT_CONTRACT_ROLE, IS_PIRATE_TRAIT_ID} from "../Constants.sol";
import {BOUNTY_SYSTEM_NFT_COOLDOWN_ID} from "../bounty/BountySystem.sol";

import {IGameItems} from "../tokens/gameitems/IGameItems.sol";
import {IGameCurrency} from "../tokens/IGameCurrency.sol";
import {ITraitsProvider} from "../interfaces/ITraitsProvider.sol";
import {ILevelSystem, ID as LEVEL_SYSTEM_ID} from "../level/ILevelSystem.sol";
import {ILootSystem} from "../loot/ILootSystem.sol";
import {IRequirementSystem, ID as REQUIREMENT_SYSTEM_ID} from "../requirements/IRequirementSystem.sol";
import {IEnergySystemV3, ID as ENERGY_SYSTEM_ID} from "../energy/IEnergySystem.sol";
import {IQuestSystem, ID} from "./IQuestSystem.sol";
import {ICooldownSystem, ID as COOLDOWN_SYSTEM_ID} from "../cooldown/ICooldownSystem.sol";
import {ID as PIRATE_NFT_ID} from "../tokens/PirateNFTL2.sol";

import "../GameRegistryConsumerUpgradeable.sol";

contract QuestSystem is IQuestSystem, GameRegistryConsumerUpgradeable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    struct QuestInput {
        // Pointer to a token (if ERC20, ERC721, or ERC1155 input type)
        GameRegistryLibrary.TokenPointer tokenPointer;
        // Traits to check against
        TraitCheck[] traitChecks;
        // Amount of energy used by this input
        uint256 energyRequired;
        // Whether or not this input is required
        bool required;
        // Whether or not the input is burned
        bool consumable;
        // Chance of losing the consumable item on a failure, 0 - 10000 (0 = 0%, 10000 = 100%)
        uint32 failureBurnProbability;
        // Chance of burning the consumable item on success, 0 - 10000 (0 = 0%, 10000 = 100%)
        uint32 successBurnProbability;
        // Amount of XP gained by this input (ERC721-types only, 0 - 10000 (0 = 0%, 10000 = 100%))
        uint32 xpEarnedPercent;
    }

    // Full definition for a quest in the game
    struct QuestDefinition {
        // Whether or not the quest is enabled
        bool enabled;
        // Requirements that must be met before quest can be started
        IRequirementSystem.AccountRequirement[] requirements;
        // Quest input tokens
        QuestInput[] inputs;
        // Quest loot rewards
        ILootSystem.Loot[] loots;
        // % chance of completing quest, 0 - 10000 (0 = 0%, 10000 = 100%)
        uint32 baseSuccessProbability;
        // How much time between each completion before it can be repeated
        uint32 cooldownSeconds;
        // 0 = infinite repeatable, 1 = complete only once, 2 = complete twice, etc.
        uint32 maxCompletions;
        // Amount of XP earned on successful completion of this quest
        uint32 successXp;
    }

    struct QuestParams {
        // Id of the quest to start
        uint32 questId;
        // Inputs to the quest
        GameRegistryLibrary.TokenPointer[] inputs;
    }

    // Struct to track and respond to VRF requests
    struct VRFRequest {
        // Account the request is for
        address account;
        // Active Quest ID for the request
        uint64 activeQuestId;
    }

    // Status of an active quest
    enum ActiveQuestStatus {
        UNDEFINED,
        IN_PROGRESS,
        GENERATING_RESULTS,
        COMPLETED
    }

    // Struct to store the data related to a quest undertaken by an account
    struct ActiveQuest {
        // Status of the quest
        ActiveQuestStatus status;
        // Account that undertook the quest
        address account;
        // Id of the quest
        uint32 questId;
        // Time the quest was started
        uint32 startTime;
        // Inputs passed to this quest
        GameRegistryLibrary.ReservedToken[] inputs;
    }

    // Struct to store account-specific data related to quests
    struct AccountData {
        // Currently active quest ids for the account
        EnumerableSet.UintSet activeQuestIds;
        // Number of times this account has completed a given quest
        mapping(uint32 => uint32) completions;
        // Last completion time for a quest
        mapping(uint32 => uint32) lastCompletionTime;
    }

    /** MEMBERS */

    /// @notice Quest definitions
    mapping(uint32 => QuestDefinition) public _questDefinitions;

    /// @notice Currently active quests
    mapping(uint256 => ActiveQuest) public _activeQuests;

    /// @notice Mapping to track VRF requests
    mapping(uint256 => VRFRequest) private _vrfRequests;

    /// @notice Mapping to track which quests require VRF
    mapping(uint32 => bool) private _questNeedsVRF;

    /// @notice Counter to track active quest id
    Counters.Counter private _activeQuestCounter;

    /// @notice Quest data for a given account
    mapping(address => AccountData) private _accountData;

    /// @notice Pending quests for a given account
    mapping(address => mapping(uint32 => uint32)) private _pendingQuests;

    /** ERRORS */

    /// @notice Error thrown when bounty is still running for this NFT
    error BountyStillRunning();

    /** EVENTS */

    /// @notice Emitted when a quest has been updated
    event QuestUpdated(uint32 questId);

    /// @notice Emitted when a quest has been started
    event QuestStarted(address account, uint32 questId, uint256 activeQuestId);

    /// @notice Emitted when a quest has been completed
    event QuestCompleted(
        address account,
        uint32 questId,
        uint256 activeQuestId,
        bool success
    );

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /**
     * Sets the definition for a given quest
     * @param questId       Id of the quest to set
     * @param definition    Definition for the quest
     */
    function setQuestDefinition(
        uint32 questId,
        QuestDefinition calldata definition
    ) public onlyRole(MANAGER_ROLE) {
        require(
            definition.inputs.length > 0 && definition.loots.length > 0,
            "MISSING_INPUTS_OR_OUTPUTS"
        );

        // Validate all inputs
        for (uint256 idx = 0; idx < definition.inputs.length; ++idx) {
            QuestInput memory input = definition.inputs[idx];
            require(
                input.tokenPointer.tokenType !=
                    GameRegistryLibrary.TokenType.UNDEFINED,
                "INVALID_INPUT_TOKEN_TYPE"
            );
            require(
                input.xpEarnedPercent == 0 ||
                    input.tokenPointer.tokenType ==
                    GameRegistryLibrary.TokenType.ERC721,
                "XP_EARNED_MUST_BE_ON_ERC721"
            );
        }

        // Validate all requirements
        IRequirementSystem requirementSystem = IRequirementSystem(
            _getSystem(REQUIREMENT_SYSTEM_ID)
        );
        requirementSystem.validateAccountRequirements(definition.requirements);

        _questNeedsVRF[questId] =
            _lootSystem().validateLoots(definition.loots) ||
            _needsVRF(definition);

        // Store definition
        _questDefinitions[questId] = definition;

        // Emit quest definition updated event
        emit QuestUpdated(questId);
    }

    /** @return QuestDefinition for a given questId */
    function getQuestDefinition(
        uint32 questId
    ) external view returns (QuestDefinition memory) {
        return _questDefinitions[questId];
    }

    /**
     * @return All active quest ids for a given account
     */
    function activeQuestIdsForAccount(
        address account
    ) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage set = _accountData[account]
            .activeQuestIds;
        uint256[] memory result = new uint256[](set.length());

        for (uint16 idx; idx < set.length(); ++idx) {
            result[idx] = set.at(idx);
        }

        return result;
    }

    /** @return ActiveQuest data for a given activeQuestId */
    function getActiveQuest(
        uint256 activeQuestId
    ) external view returns (ActiveQuest memory) {
        return _activeQuests[activeQuestId];
    }

    /**
     * @return completions How many times the quest was completed by the given account
     * @return lastCompletionTime Last completion timestamp for the given quest and account
     */
    function getQuestDataForAccount(
        address account,
        uint32 questId
    )
        external
        view
        override
        returns (uint32 completions, uint32 lastCompletionTime)
    {
        completions = _accountData[account].completions[questId];
        lastCompletionTime = _accountData[account].lastCompletionTime[questId];
    }

    /**
     * Sets whether or not the quest is active
     *
     * @param questId   Id of the quest to change
     * @param enabled    Whether or not the quest should be active
     */
    function setQuestEnabled(
        uint32 questId,
        bool enabled
    ) public onlyRole(MANAGER_ROLE) {
        QuestDefinition storage questDef = _questDefinitions[questId];
        require(questDef.inputs.length > 0, "QUEST_NOT_DEFINED");

        questDef.enabled = enabled;
    }

    /**
     * Whether or not a given quest is available to the given player
     *
     * @param account Account to check if quest is available for
     * @param questId Id of the quest to see is available
     *
     * @return Whether or not the quest is available to the given account
     */
    function isQuestAvailable(
        address account,
        uint32 questId
    ) external view returns (bool) {
        QuestDefinition storage questDef = _questDefinitions[questId];
        return _isQuestAvailable(account, questId, questDef);
    }

    /**
     * How many quests are pending for the given account
     * @param account Account to check
     * @param questId Id of the quest to check
     *
     * @return Number of pending quests
     */
    function getPendingQuests(
        address account,
        uint32 questId
    ) public view returns (uint256) {
        return _pendingQuests[account][questId];
    }

    /**
     * Starts a quest for a user
     *
     * @param params Quest parameters for the quest (See struct definition)
     *
     * @return activeQuestId that was created
     */
    function startQuest(
        QuestParams calldata params
    ) external nonReentrant whenNotPaused returns (uint256) {
        QuestDefinition storage questDef = _questDefinitions[params.questId];
        address account = _getPlayerAccount(_msgSender());

        // Verify user can start this quest and meets requirements
        require(
            _isQuestAvailable(account, params.questId, questDef) == true,
            "QUEST_NOT_AVAILABLE"
        );
        require(
            params.inputs.length == questDef.inputs.length,
            "INPUT_LENGTH_MISMATCH"
        );

        // Create active quest object
        _activeQuestCounter.increment();
        uint256 activeQuestId = _activeQuestCounter.current();

        ActiveQuest storage activeQuest = _activeQuests[activeQuestId];
        activeQuest.account = account;
        activeQuest.questId = params.questId;
        activeQuest.startTime = SafeCast.toUint32(block.timestamp);
        activeQuest.status = ActiveQuestStatus.IN_PROGRESS;

        // Track activeQuestId for this account
        _accountData[account].activeQuestIds.add(activeQuestId);

        // Verify that the params have inputs that meet the quest requirements
        for (uint8 idx; idx < questDef.inputs.length; ++idx) {
            QuestInput storage inputDef = questDef.inputs[idx];
            GameRegistryLibrary.TokenPointer storage tokenPointerDef = inputDef
                .tokenPointer;

            GameRegistryLibrary.TokenPointer memory input = params.inputs[idx];

            // Make sure that token type matches between definition and id
            require(
                input.tokenType == tokenPointerDef.tokenType,
                "TOKEN_TYPE_NOT_MATCHING"
            );

            // If Quest definition TokenPointer is Pirate NFT check that input is either Pirate NFT or Starter Pirate NFT
            if (tokenPointerDef.tokenContract == _getSystem(PIRATE_NFT_ID)) {
                require(
                    isPirateNFT(input.tokenContract, input.tokenId),
                    "TOKEN_CONTRACT_NOT_MATCHING"
                );
            } else {
                // Else perform standard check that definition and input token contracts match
                require(
                    tokenPointerDef.tokenContract == address(0) ||
                        tokenPointerDef.tokenContract == input.tokenContract,
                    "TOKEN_CONTRACT_NOT_MATCHING"
                );
            }

            // Make sure token id match between definition and input
            require(
                tokenPointerDef.tokenId == 0 ||
                    tokenPointerDef.tokenId == input.tokenId,
                "TOKEN_ID_NOT_MATCHING"
            );

            GameHelperLibrary._verifyInputOwnership(input, account);

            GameRegistryLibrary.TokenType tokenType = tokenPointerDef.tokenType;
            uint32 reservationId = 0;

            // Check token type to ensure that the input matches what the quest expects
            if (tokenType == GameRegistryLibrary.TokenType.ERC20) {
                require(
                    _hasAccessRole(
                        GAME_CURRENCY_CONTRACT_ROLE,
                        input.tokenContract
                    ) == true,
                    "NOT_GAME_CURRENCY"
                );

                // Burn ERC20 immediately, will be refunded if not consumable later
                IGameCurrency(input.tokenContract).burn(account, input.amount);
            } else if (tokenType == GameRegistryLibrary.TokenType.ERC721) {
                // Check if NFT is in Bounty cooldown
                if (
                    ICooldownSystem(_getSystem(COOLDOWN_SYSTEM_ID))
                        .isInCooldown(
                            EntityLibrary.tokenToEntity(
                                input.tokenContract,
                                input.tokenId
                            ),
                            BOUNTY_SYSTEM_NFT_COOLDOWN_ID
                        )
                ) {
                    revert BountyStillRunning();
                }
                // Spend Wallet energy if needed
                if (inputDef.energyRequired > 0) {
                    // Subtract energy from user wallet entity
                    IEnergySystemV3(_getSystem(ENERGY_SYSTEM_ID)).spendEnergy(
                        EntityLibrary.addressToEntity(account),
                        inputDef.energyRequired
                    );
                }
            } else if (tokenType == GameRegistryLibrary.TokenType.ERC1155) {
                // Burn ERC1155 inputs immediately, refund if they don't need to be burned
                IGameItems(input.tokenContract).burn(
                    account,
                    input.tokenId,
                    tokenPointerDef.amount
                );
            }

            // Perform all trait checks
            ITraitsProvider traitsProvider = _traitsProvider();

            for (
                uint8 traitIdx;
                traitIdx < inputDef.traitChecks.length;
                traitIdx++
            ) {
                TraitsLibrary.requireTraitCheck(
                    traitsProvider,
                    inputDef.traitChecks[traitIdx],
                    input.tokenContract,
                    input.tokenId
                );
            }

            activeQuest.inputs.push(
                GameRegistryLibrary.ReservedToken({
                    tokenType: input.tokenType,
                    tokenId: input.tokenId,
                    tokenContract: input.tokenContract,
                    amount: tokenPointerDef.amount,
                    reservationId: reservationId
                })
            );
        }

        _pendingQuests[account][params.questId] += 1;

        emit QuestStarted(account, params.questId, activeQuestId);

        if (_questNeedsVRF[params.questId] == false) {
            _completeQuest(account, activeQuest, activeQuestId, true, 0);
        } else {
            // Start the completion process immediately
            uint256 requestId = _requestRandomWords(1);
            _vrfRequests[requestId] = VRFRequest({
                account: account,
                activeQuestId: SafeCast.toUint64(activeQuestId)
            });
        }

        return activeQuestId;
    }

    /**
     * Finishes quest with randomness
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external override onlyRole(RANDOMIZER_ROLE) {
        VRFRequest storage request = _vrfRequests[requestId];
        address account = request.account;

        if (account != address(0)) {
            uint256 activeQuestId = request.activeQuestId;

            ActiveQuest storage activeQuest = _activeQuests[activeQuestId];

            QuestDefinition storage questDef = _questDefinitions[
                activeQuest.questId
            ];

            // Calculate whether or not quest was successful
            (bool success, uint256 nextRandomWord) = RandomLibrary
                .weightedCoinFlip(
                    randomWords[0],
                    questDef.baseSuccessProbability
                );

            _completeQuest(
                account,
                activeQuest,
                activeQuestId,
                success,
                nextRandomWord
            );

            // Delete the VRF request
            delete _vrfRequests[requestId];
        }
    }

    /** INTERNAL **/

    /**
     * Completes a quest for a user
     *
     * @param account Account of the quest to be completed
     * @param activeQuest the active quest beign completed
     * @param activeQuestId Id of the ActiveQuest to be completed
     * @param success was the quest successfully completed
     * @param nextRandomWord random word
     *
     */
    function _completeQuest(
        address account,
        ActiveQuest storage activeQuest,
        uint256 activeQuestId,
        bool success,
        uint256 nextRandomWord
    ) internal {
        if (success) {
            _questSuccess(account, activeQuest, nextRandomWord);
        } else {
            _questFailed(account, activeQuest, nextRandomWord);
        }

        // Emit completed event
        emit QuestCompleted(
            account,
            activeQuest.questId,
            activeQuestId,
            success
        );

        // Subtract pending quests
        _pendingQuests[account][activeQuest.questId] -= 1;

        // Change quest status to completed
        activeQuest.status = ActiveQuestStatus.COMPLETED;

        // Remove from activeQuestId array
        _accountData[account].activeQuestIds.remove(activeQuestId);
    }

    /**
     * checks if a quest is available
     *
     * @param account Account to be checked
     * @param questId questId to be checked
     * @param questDef definition of the quest to be checked
     *
     * @return bool
     *
     */
    function _isQuestAvailable(
        address account,
        uint32 questId,
        QuestDefinition memory questDef
    ) internal view returns (bool) {
        if (!questDef.enabled) {
            return false;
        }

        // Perform all requirement checks
        IRequirementSystem requirementSystem = IRequirementSystem(
            _getSystem(REQUIREMENT_SYSTEM_ID)
        );
        if (
            requirementSystem.performAccountCheckBatch(
                account,
                questDef.requirements
            ) == false
        ) {
            return false;
        }

        // Make sure user hasn't completed already
        AccountData storage accountData = _accountData[account];
        if (
            questDef.maxCompletions > 0 &&
            accountData.completions[questId] >= questDef.maxCompletions
        ) {
            return false;
        }

        // Make sure enough time has passed before completions
        if (questDef.cooldownSeconds > 0) {
            // make sure no quests are currently pending
            if (_pendingQuests[account][questId] > 0) {
                return false;
            }

            // Make sure cooldown has passed
            if (
                accountData.lastCompletionTime[questId] +
                    questDef.cooldownSeconds >
                block.timestamp
            ) {
                return false;
            }
        }
        return true;
    }

    /**
     * Quest fail handler
     *
     * @param account Account to be checked
     * @param activeQuest the active quest to be checked
     * @param randomWord a  random word
     *
     */
    function _questFailed(
        address account,
        ActiveQuest storage activeQuest,
        uint256 randomWord
    ) internal {
        QuestDefinition storage questDef = _questDefinitions[
            activeQuest.questId
        ];

        _unlockQuestInputs(account, questDef, activeQuest, false, randomWord);
    }

    /**
     * Quest success handler
     *
     * @param account Account to be checked
     * @param activeQuest the active quest to be checked
     * @param randomWord a  random word
     *
     */
    function _questSuccess(
        address account,
        ActiveQuest storage activeQuest,
        uint256 randomWord
    ) internal {
        uint32 questId = activeQuest.questId;
        QuestDefinition storage questDef = _questDefinitions[questId];

        // Unlock quest inputs and optionally grant XP
        _unlockQuestInputs(account, questDef, activeQuest, true, randomWord);

        // Grant quest loot
        _lootSystem().grantLootWithRandomWord(
            account,
            questDef.loots,
            randomWord
        );

        // Track account specific completion data
        AccountData storage accountData = _accountData[account];
        accountData.lastCompletionTime[questId] = SafeCast.toUint32(
            block.timestamp
        );
        accountData.completions[questId]++;
    }

    /**
     * Unlock a quest input
     *
     * @param account Account with the quest
     * @param questDef quest definition
     * @param activeQuest tthe active quest
     * @param isSuccess was successful
     * @param randomWord random word
     *
     */
    function _unlockQuestInputs(
        address account,
        QuestDefinition storage questDef,
        ActiveQuest storage activeQuest,
        bool isSuccess,
        uint256 randomWord
    ) internal {
        uint32 successXp = isSuccess ? questDef.successXp : 0;

        // Unlock inputs, grant XP, and potentially burn inputs
        for (uint8 idx; idx < questDef.inputs.length; ++idx) {
            QuestInput storage input = questDef.inputs[idx];
            GameRegistryLibrary.ReservedToken
                storage activeQuestInput = activeQuest.inputs[idx];

            // Grant XP on success
            if (successXp > 0 && input.xpEarnedPercent > 0) {
                uint256 xpAmount = (successXp * input.xpEarnedPercent) /
                    PERCENTAGE_RANGE;

                if (xpAmount > 0) {
                    ILevelSystem levelSystem = ILevelSystem(
                        _getSystem(LEVEL_SYSTEM_ID)
                    );
                    levelSystem.grantXP(
                        activeQuestInput.tokenContract,
                        activeQuestInput.tokenId,
                        xpAmount
                    );
                }
            }

            // Determine if the input should be refunded to the user
            bool shouldBurn;

            if (input.consumable) {
                uint256 burnProbability = isSuccess
                    ? input.successBurnProbability
                    : input.failureBurnProbability;

                if (burnProbability == 0) {
                    shouldBurn = false;
                } else if (burnProbability >= PERCENTAGE_RANGE) {
                    shouldBurn = true;
                } else {
                    randomWord = RandomLibrary.generateNextRandomWord(
                        randomWord
                    );
                    (shouldBurn, randomWord) = RandomLibrary.weightedCoinFlip(
                        randomWord,
                        burnProbability
                    );
                }

                // Unlock/burn based on token type
                if (
                    activeQuestInput.tokenType ==
                    GameRegistryLibrary.TokenType.ERC20
                ) {
                    // If we are not burning, refund the ERC20
                    if (shouldBurn == false) {
                        IGameCurrency(activeQuestInput.tokenContract).mint(
                            account,
                            activeQuestInput.amount
                        );
                    }
                } else if (
                    activeQuestInput.tokenType ==
                    GameRegistryLibrary.TokenType.ERC1155
                ) {
                    if (shouldBurn == false) {
                        // If we are not burning, refund the amount
                        IGameItems(activeQuestInput.tokenContract).mint(
                            account,
                            SafeCast.toUint32(activeQuestInput.tokenId),
                            activeQuestInput.amount
                        );
                    }
                }
            }
        }
    }

    /**
     * checks is a quest requires VRF
     *
     * @param definition the definition of the quest to be verified
     *
     * @return bool
     */
    function _needsVRF(
        QuestDefinition memory definition
    ) internal pure returns (bool) {
        if (
            definition.baseSuccessProbability < PERCENTAGE_RANGE &&
            definition.baseSuccessProbability != 0
        ) {
            return true;
        }

        QuestInput[] memory inputs = definition.inputs;

        for (uint8 i; i < inputs.length; ++i) {
            if (
                inputs[i].successBurnProbability < PERCENTAGE_RANGE &&
                inputs[i].successBurnProbability != 0
            ) {
                return true;
            }
            if (
                inputs[i].failureBurnProbability < PERCENTAGE_RANGE &&
                inputs[i].failureBurnProbability != 0
            ) {
                return true;
            }
        }
        return false;
    }

    function isPirateNFT(
        address tokenContract,
        uint256 tokenId
    ) internal view returns (bool) {
        return (_hasAccessRole(GAME_NFT_CONTRACT_ROLE, tokenContract) &&
            _traitsProvider().hasTrait(
                tokenContract,
                tokenId,
                IS_PIRATE_TRAIT_ID
            ));
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IRandomizerCallback} from "./IRandomizerCallback.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.randomizer"));

interface IRandomizer is IERC165 {
    /**
     * Starts a VRF random number request
     *
     * @param callbackAddress Address to callback with the random numbers
     * @param numWords        Number of words to request from VRF
     *
     * @return requestId for the random number, will be passed to the callback contract
     */
    function requestRandomWords(
        IRandomizerCallback callbackAddress,
        uint32 numWords
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRandomizerCallback {
    /**
     * Callback for when the Chainlink request returns
     *
     * @param requestId     Id of the random word request
     * @param randomWords   Random words that were generated by the VRF
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.requirementsystem"));

/// @title Interface for the RequirementSystem that performs state checks against a user account
interface IRequirementSystem {
    // Requirement that must be met
    struct AccountRequirement {
        // Unique id for the requirement
        uint32 requirementId;
        // ABI encoded parameters to perform the requirement check
        bytes requirementData;
    }

    /**
     * Validates whether or not a given set of requirements are valid
     * Errors if there are any invalid requirements
     * @param requirements Requirements to validate
     */
    function validateAccountRequirements(
        AccountRequirement[] memory requirements
    ) external view;

    /**
     * Performs a account requirement check
     * @param account     Account to check
     * @param requirement Requirement to be checked
     * @return Whether or not the requirement was met
     */
    function performAccountCheck(
        address account,
        AccountRequirement memory requirement
    ) external view returns (bool);

    /**
     * Performs a batch account requirement check
     * @param account     Account to check
     * @param requirements Requirements to be checked
     * @return Whether or not the requirement was met
     */
    function performAccountCheckBatch(
        address account,
        AccountRequirement[] memory requirements
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IERC721BeforeTokenTransferHandler {
    /**
     * Before transfer hook for NFTs. Performs any trait checks needed before transfer
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     * @param from              From address
     * @param to                To address
     * @param operator          Operator address
     */
    function beforeTokenTransfer(
        address tokenContract,
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface for a in-game currency, based off of ERC20
 */
interface IGameCurrency is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface ITokenURIHandler {
    /**
     * Generates the TokenURI for a given token
     *
     * @param operator          Sender requesting the tokenURI
     * @param tokenContract     TokenContract to get URI for
     * @param tokenId           Id of the token to get URI for
     *
     * @return TokenURI for the given token
     */
    function tokenURI(
        address operator,
        address tokenContract,
        uint256 tokenId
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import {ERC721ContractURI} from "@proofofplay/erc721-extensions/src/ERC721ContractURI.sol";

import "./gamenft/GameNFTV2.sol";
import {GENERATION_TRAIT_ID, XP_TRAIT_ID, IS_PIRATE_TRAIT_ID, LEVEL_TRAIT_ID, NAME_TRAIT_ID} from "../Constants.sol";
import {MINTER_ROLE} from "../Constants.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.piratenft"));

/** @title The latest PirateNFT */
contract PirateNFTL2 is GameNFTV2 {
    using Strings for uint256;
    error InvalidInput();

    uint256 constant MAX_SUPPLY = 9999;

    constructor(
        address gameRegistryAddress
    ) GameNFTV2(MAX_SUPPLY, "Pirate", "PIRATE", gameRegistryAddress, ID) {
        _defaultDescription = "Take to the seas with your pirate crew! Explore the world and gather XP, loot, and untold riches in a race to become the world's greatest pirate captain! Play at https://piratenation.game";
        _defaultImageURI = "ipfs://QmUeMG7QPySPiBp4hTc9u1FPcq5MKJzyYLgQh1t7FefECX?";
    }

    /**
     * @notice Returns the total supply of the token
     */
    function totalSupply() public view virtual returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @notice Used for bulk minting for initializing our migration
     * @param tokenIds  Array of tokenIds to mint
     * @param addresses Array of addresses to mint to
     */
    function claim(
        uint256[] calldata tokenIds,
        address[] calldata addresses
    ) external onlyRole(MINTER_ROLE) {
        if (tokenIds.length != addresses.length) {
            revert InvalidInput();
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            //todo: can we do optimizations
            if (tokenIds[i] == 0) {
                revert InvalidInput();
            }
            _safeMint(addresses[i], tokenIds[i]);
        }
    }

    /** Initializes traits for the given tokenId */
    function _initializeTraits(uint256 tokenId) internal override {
        ITraitsProvider traitsProvider = _traitsProvider();

        traitsProvider.setTraitUint256(
            address(this),
            tokenId,
            GENERATION_TRAIT_ID,
            0
        );

        traitsProvider.setTraitUint256(address(this), tokenId, XP_TRAIT_ID, 0);

        traitsProvider.setTraitUint256(
            address(this),
            tokenId,
            LEVEL_TRAIT_ID,
            1
        );

        traitsProvider.setTraitBool(
            address(this),
            tokenId,
            IS_PIRATE_TRAIT_ID,
            true
        );
    }

    /** @return Token name for the given tokenId */
    function tokenName(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (_hasTrait(tokenId, NAME_TRAIT_ID) == true) {
            // If token has a name trait set, use that
            return _getTraitString(tokenId, NAME_TRAIT_ID);
        } else {
            return string(abi.encodePacked("Pirate #", tokenId.toString()));
        }
    }

    function batchSetTimeHeld(
        uint256[] calldata tokenIds,
        address[] calldata addresses,
        uint32[] calldata timeHeldValues
    ) external onlyRole(MINTER_ROLE) {
        if (
            tokenIds.length != addresses.length ||
            tokenIds.length != timeHeldValues.length
        ) {
            revert InvalidInput();
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (tokenIds[i] == 0) {
                revert InvalidInput();
            }
            // Migrate the amount of time a token has been held by a given account
            _setTimeHeld(tokenIds[i], addresses[i], timeHeldValues[i]);
        }
    }

    function batchSetLastTransfer(
        uint256[] calldata tokenIds,
        uint32[] calldata lastTransferValues
    ) external onlyRole(MINTER_ROLE) {
        if (tokenIds.length != lastTransferValues.length) {
            revert InvalidInput();
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (tokenIds[i] == 0) {
                revert InvalidInput();
            }
            // Migrate the last transfer time for the token
            _setLastTransfer(tokenIds[i], lastTransferValues[i]);
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.gameitems"));

interface IGameItems is IERC1155 {
    /**
     * Mints a ERC1155 token
     *
     * @param to        Recipient of the token
     * @param id        Id of token to mint
     * @param amount    Quantity of token to mint
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * Burn a token - any payment / game logic should be handled in the game contract.
     *
     * @param from      Account to burn from
     * @param id        Id of the token to burn
     * @param amount    Quantity to burn
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @param id  Id of the type to get data for
     *
     * @return How many of the given token id have been minted
     */
    function minted(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IGameNFTV2} from "./IGameNFTV2.sol";
import {MANAGER_ROLE} from "../../Constants.sol";

import {ITraitsProvider} from "../../interfaces/ITraitsProvider.sol";

import {ITraitsConsumer, TraitsConsumer, GameRegistryConsumer} from "../../traits/TraitsConsumer.sol";
import {IERC721BeforeTokenTransferHandler} from "../IERC721BeforeTokenTransferHandler.sol";

import {ERC721ContractURI} from "@proofofplay/erc721-extensions/src/ERC721ContractURI.sol";
import {ERC721OperatorFilter} from "@proofofplay/erc721-extensions/src/ERC721OperatorFilter.sol";
import {ERC721MirroredL2} from "@proofofplay/erc721-extensions/src/L2/ERC721MirroredL2.sol";

//todo: can we mix in mirrored on demand?
/** @title NFT base contract for all game NFTs. Exposes traits for the NFT and respects GameRegistry/Soulbound/LockingSystem access control */
contract GameNFTV2 is
    TraitsConsumer,
    ERC721OperatorFilter,
    ERC721MirroredL2,
    ERC721ContractURI,
    IGameNFTV2
{
    /// @notice Whether or not the token has had its traits initialized. Prevents re-initialization when bridging
    mapping(uint256 => bool) private _traitsInitialized;

    /// @notice Max supply for this NFT. If zero, it is unlimited supply.
    uint256 private immutable _maxSupply;

    /// @notice The amount of time a token has been held by a given account
    mapping(uint256 => mapping(address => uint32)) private _timeHeld;

    /// @notice Last transfer time for the token
    mapping(uint256 => uint32) public lastTransfer;

    /** ERRORS **/

    /// @notice Account must be non-null
    error InvalidAccountAddress();

    /// @notice Token id is not valid
    error InvalidTokenId();

    /// @notice tokenId exceeds max supply for this NFT
    error TokenIdExceedsMaxSupply();

    /// @notice Amount to mint exceeds max supply
    error NotEnoughSupply(uint256 needed, uint256 actual);

    /** EVENTS **/

    /// @notice Emitted when time held time is updated
    event TimeHeldSet(uint256 tokenId, address account, uint32 timeHeld);

    /// @notice Emitted when last transfer time is updated
    event LastTransferSet(uint256 tokenId, uint32 lastTransferTime);

    /** SETUP **/

    constructor(
        uint256 tokenMaxSupply,
        string memory name,
        string memory symbol,
        address gameRegistryAddress,
        uint256 id
    ) ERC721(name, symbol) TraitsConsumer(gameRegistryAddress, id) {
        _maxSupply = tokenMaxSupply;
    }

    /** @return Max supply for this token */
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @param tokenId token id to check
     * @return Whether or not the given tokenId has been minted
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @return Generates a dynamic tokenURI based on the traits associated with the given token
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        // Make sure this still errors according to ERC721 spec
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _tokenURI(tokenId);
    }

    /**
     * @dev a method that bulk sets initialized imported NFTs
     * @param tokenIds List of TokenIds to be initialized
     */
    function setTraitsInitialized(
        uint256[] calldata tokenIds
    ) external onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _traitsInitialized[tokenIds[i]] = true;
        }
    }

    /**
     * @param account Account to check hold time of
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held a token
     */
    function getTimeHeld(
        address account,
        uint256 tokenId
    ) external view override returns (uint32) {
        address owner = ownerOf(tokenId);
        if (account == address(0)) {
            revert InvalidAccountAddress();
        }

        uint32 totalTime = _timeHeld[tokenId][account];

        if (owner == account) {
            uint32 lastTransferTime = lastTransfer[tokenId];
            uint32 currentTime = SafeCast.toUint32(block.timestamp);

            totalTime += (currentTime - lastTransferTime);
        }

        return totalTime;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC165, ERC721, TraitsConsumer)
        returns (bool)
    {
        return
            interfaceId == type(IGameNFTV2).interfaceId ||
            TraitsConsumer.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }

    /** INTERNAL **/

    /** Initializes traits for the given tokenId */
    function _initializeTraits(uint256 tokenId) internal virtual {
        // Do nothing by default
    }

    /**
     * Mint token to recipient
     *
     * @param to        The recipient of the token
     * @param tokenId   Id of the token to mint
     */
    function _safeMint(address to, uint256 tokenId) internal override {
        if (_maxSupply != 0 && tokenId > _maxSupply) {
            revert TokenIdExceedsMaxSupply();
        }

        if (tokenId == 0) {
            revert InvalidTokenId();
        }

        super._safeMint(to, tokenId);

        // Conditionally initialize traits
        if (_traitsInitialized[tokenId] == false) {
            _initializeTraits(tokenId);
            _traitsInitialized[tokenId] = true;
        }
    }

    /**
     * @notice Checks for soulbound status before transfer
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721MirroredL2, ERC721OperatorFilter) {
        // Track hold time
        for (uint256 idx = 0; idx < batchSize; idx++) {
            uint256 tokenId = firstTokenId + idx;
            uint32 lastTransferTime = lastTransfer[tokenId];
            uint32 currentTime = SafeCast.toUint32(block.timestamp);
            if (lastTransferTime > 0) {
                _timeHeld[tokenId][from] += (currentTime - lastTransferTime);
            }
            lastTransfer[tokenId] = currentTime;
        }

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * Message sender override to get Context to work with meta transactions
     *
     */
    function _msgSender()
        internal
        view
        override(Context, GameRegistryConsumer)
        returns (address)
    {
        return GameRegistryConsumer._msgSender();
    }

    /**
     * Message data override to get Context to work with meta transactions
     *
     */
    function _msgData()
        internal
        view
        override(Context, GameRegistryConsumer)
        returns (bytes calldata)
    {
        return GameRegistryConsumer._msgData();
    }

    function _checkRole(
        bytes32 role,
        address account
    ) internal view virtual override(GameRegistryConsumer, ERC721MirroredL2) {
        GameRegistryConsumer._checkRole(role, account);
    }

    function getLastTransfer(
        uint256 tokenId
    ) external view override returns (uint32) {
        return lastTransfer[tokenId];
    }

    function _setTimeHeld(
        uint256 tokenId,
        address account,
        uint32 timeHeld
    ) internal {
        _timeHeld[tokenId][account] = timeHeld;

        emit TimeHeldSet(tokenId, account, timeHeld);
    }

    function _setLastTransfer(
        uint256 tokenId,
        uint32 lastTransferTime
    ) internal {
        lastTransfer[tokenId] = lastTransferTime;

        emit LastTransferSet(tokenId, lastTransferTime);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IHoldingConsumer} from "../../interfaces/IHoldingConsumer.sol";

/**
 * @title Interface for game NFTs that have stats and other properties
 */
interface IGameNFTV2 is IHoldingConsumer, IERC721 {
    /**
     * @param account Account to check hold time of
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held a token
     */
    function getTimeHeld(
        address account,
        uint256 tokenId
    ) external view returns (uint32);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {GAME_LOGIC_CONTRACT_ROLE, NAME_TRAIT_ID, DESCRIPTION_TRAIT_ID, IMAGE_TRAIT_ID} from "../Constants.sol";

import {ITraitsConsumer} from "../interfaces/ITraitsConsumer.sol";
import {ITokenURIHandler} from "../tokens/ITokenURIHandler.sol";
import {GameRegistryConsumer} from "../GameRegistryConsumer.sol";

/** @title Contract that lets a child contract access the TraitsProvider contract */
abstract contract TraitsConsumer is
    ITraitsConsumer,
    GameRegistryConsumer,
    IERC165
{
    using Strings for uint256;

    /// @notice Override URI for the NFT contract. If not set, on-chain data is used instead
    string public _overrideURI;

    /// @notice Pointer to the handler for TokenURI calls
    address public tokenURIHandler;

    /// @notice Base URI for images, tokenId is appended to make final uri
    string public _baseImageURI;

    /// @notice Base URI for external link, tokenId is appended to make final uri
    string public _baseExternalURI;

    /// @notice Default image URI for the token
    /// @dev Should be set in the constructor
    string public _defaultImageURI;

    /// @notice Default description for the token
    string public _defaultDescription;

    /** ERRORS */

    /// @notice traitsProviderAddress does not implement ITraitsProvvider
    error InvalidTraitsProvider();

    /** SETUP **/

    /** Set game registry  */
    constructor(
        address _gameRegistryAddress,
        uint256 _id
    ) GameRegistryConsumer(_gameRegistryAddress, _id) {}

    /** Sets the override URI for the tokens */
    function setURI(string calldata newURI) external onlyOwner {
        _overrideURI = newURI;
    }

    /** Sets base image URI for the tokens */
    function setBaseImageURI(string calldata newURI) external onlyOwner {
        _baseImageURI = newURI;
    }

    /** Sets base external URI for the tokens */
    function setBaseExternalURI(string calldata newURI) external onlyOwner {
        _baseExternalURI = newURI;
    }

    /** @return Token name for the given tokenId */
    function tokenName(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (_hasTrait(tokenId, NAME_TRAIT_ID)) {
            // If token has a name trait set, use that
            return _getTraitString(tokenId, NAME_TRAIT_ID);
        } else {
            return string(abi.encodePacked("#", tokenId.toString()));
        }
    }

    /** @return Token name for the given tokenId */
    function tokenDescription(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (_hasTrait(tokenId, DESCRIPTION_TRAIT_ID)) {
            // If token has a description trait set, use that
            return _getTraitString(tokenId, DESCRIPTION_TRAIT_ID);
        }

        return _defaultDescription;
    }

    /** @return Image URI for the given tokenId */
    function imageURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (_hasTrait(tokenId, IMAGE_TRAIT_ID)) {
            // If token has a description trait set, use that
            return _getTraitString(tokenId, IMAGE_TRAIT_ID);
        }

        if (bytes(_baseImageURI).length > 0) {
            return string(abi.encodePacked(_baseImageURI, tokenId.toString()));
        }

        return _defaultImageURI;
    }

    /** @return External URI for the given tokenId */
    function externalURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (bytes(_baseExternalURI).length > 0) {
            return
                string(abi.encodePacked(_baseExternalURI, tokenId.toString()));
        }

        return "";
    }

    /**
     * Sets the tokenURI handler for this token
     *
     * @param handler  Address of the handler contract to use
     */
    function setTokenURIHandler(address handler) external onlyOwner {
        tokenURIHandler = handler;
    }

    /** INTERNAL **/

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     *
     * @return Trait int256 value for the given token and trait
     */
    function _getTraitInt256(
        uint256 tokenId,
        uint256 traitId
    ) internal view returns (int256) {
        return
            _traitsProvider().getTraitInt256(address(this), tokenId, traitId);
    }

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     *
     * @return Trait string value for the given token and trait
     */
    function _getTraitString(
        uint256 tokenId,
        uint256 traitId
    ) internal view returns (string memory) {
        return
            _traitsProvider().getTraitString(address(this), tokenId, traitId);
    }

    /**
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function _hasTrait(
        uint256 tokenId,
        uint256 traitId
    ) internal view returns (bool) {
        return _traitsProvider().hasTrait(address(this), tokenId, traitId);
    }

    /**
     * Sets the int256 trait value for this token
     *
     * @param tokenId Id of the token to set trait for
     * @param traitId Id of the trait to set
     * @param value   New value of the trait
     */
    function _setTraitInt256(
        uint256 tokenId,
        uint256 traitId,
        int256 value
    ) internal {
        _traitsProvider().setTraitInt256(
            address(this),
            tokenId,
            traitId,
            value
        );
    }

    /**
     * Sets the string trait value for this token
     *
     * @param tokenId Id of the token to set trait for
     * @param traitId Id of the trait to set
     * @param value   New value of the trait
     */
    function _setTraitString(
        uint256 tokenId,
        uint256 traitId,
        string memory value
    ) internal {
        _traitsProvider().setTraitString(
            address(this),
            tokenId,
            traitId,
            value
        );
    }

    /**
     * @notice Generates metadata for the given tokenId
     * @param tokenId  Token to generate metadata for
     * @return A base64 encoded JSON metadata string
     */
    function _tokenURI(
        uint256 tokenId
    ) internal view virtual returns (string memory) {
        // If override URI is set, return the URI with tokenId appended instead of on-chain data
        if (bytes(_overrideURI).length > 0) {
            return string(abi.encodePacked(_overrideURI, tokenId.toString()));
        }

        if (tokenURIHandler == address(0)) {
            return "";
        }

        return
            ITokenURIHandler(tokenURIHandler).tokenURI(
                _msgSender(),
                address(this),
                tokenId
            );
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(ITraitsConsumer).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}