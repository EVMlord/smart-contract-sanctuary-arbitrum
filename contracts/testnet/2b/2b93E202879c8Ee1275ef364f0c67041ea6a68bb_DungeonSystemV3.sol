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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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

import {IBaseStorageComponentV2} from "./IBaseStorageComponentV2.sol";
import "../GameRegistryConsumerV2.sol";

/**
 * @title BaseStorageComponentV2
 * @notice Base storage component class, version 2
 */
abstract contract BaseStorageComponentV2 is
    IBaseStorageComponentV2,
    GameRegistryConsumerV2
{
    /// @notice Invalid data count compared to number of entity count
    error InvalidBatchData(uint256 entityCount, uint256 valueCount);

    /** SETUP **/

    /**
     * @param _gameRegistryAddress Address of the GameRegistry contract
     * @param id ID of the component being created
     */
    constructor(
        address _gameRegistryAddress,
        uint256 id
    ) GameRegistryConsumerV2(_gameRegistryAddress, id) {
        // Do nothing
    }

    /** INTERNAL */

    /**
     * Use GameRegistry to trigger emit when setting
     * @param entity Entity to set the value for.
     * @param value Value to set for the given entity.
     */
    function _emitSetBytes(
        uint256 entity,
        bytes memory value
    ) internal virtual {
        // Emit global event
        gameRegistry.registerComponentValueSet(entity, value);
    }

    /**
     * Use GameRegistry to trigger emit when setting
     * @param entities Array of entities to set values for.
     * @param values Array of values to set for a given entity.
     */
    function _emitBatchSetBytes(
        uint256[] calldata entities,
        bytes[] memory values
    ) internal virtual {
        // Emit global event
        gameRegistry.batchRegisterComponentValueSet(entities, values);
    }

    /**
     * Use GameRegistry to trigger emit when removing
     * @param entity Entity to remove from this component.
     */
    function _emitRemoveBytes(uint256 entity) internal virtual {
        // Emit global event
        gameRegistry.registerComponentValueRemoved(entity);
    }

    /**
     * Use GameRegistry to trigger emit when removing
     * @param entities Array of entities to remove from this component.
     */
    function _emitBatchRemoveBytes(
        uint256[] calldata entities
    ) internal virtual {
        // Emit global event
        gameRegistry.batchRegisterComponentValueRemoved(entities);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {TypesLibrary} from "../TypesLibrary.sol";

interface IBaseStorageComponentV2 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../GameRegistryConsumerUpgradeable.sol";

import {EntityLibrary} from "../core/EntityLibrary.sol";
import {IGameGlobals, ID as GAME_GLOBALS_ID} from "../gameglobals/IGameGlobals.sol";
import {ILootSystem, ID as LOOT_SYSTEM_ID} from "../loot/ILootSystem.sol";
import {ITokenTemplateSystem, ID as TOKEN_TEMPLATE_SYSTEM_ID} from "../tokens/ITokenTemplateSystem.sol";
import {RANDOMIZER_ROLE} from "../Constants.sol";
import {EndBattleParams, IDungeonBattleSystemV2, ID as DUNGEON_BATTLE_SYSTEM_ID} from "./IDungeonBattleSystemV2.sol";
import {IDungeonProgressSystem, ID as DUNGEON_PROGRESS_SYSTEM_ID, DungeonNodeProgressState} from "./IDungeonProgressSystem.sol";
import {StartAndEndDungeonBattleParams, StartDungeonBattleParams, EndDungeonBattleParams, IDungeonSystemV3, DungeonMap, DungeonNode, DungeonTrigger} from "./IDungeonSystemV3.sol";
import {GauntletScheduleComponent, ID as GauntletScheduleComponentId, Layout as GauntletScheduleComponentLayout, ID as GAUNTLET_SCHEDULE_ENTITY} from "../generated/components/GauntletScheduleComponent.sol";
import {CombatMapComponent, ID as CombatMapComponentId, Layout as CombatMapComponentLayout} from "../generated/components/CombatMapComponent.sol";
import {CombatEncounterComponent, ID as CombatEncounterComponentId, Layout as CombatEncounterComponentLayout} from "../generated/components/CombatEncounterComponent.sol";
import {AccountXpGrantedComponent, Layout as AccountXpGrantedComponentStruct, ID as ACCOUNT_XP_GRANTED_COMPONENT_ID} from "../generated/components/AccountXpGrantedComponent.sol";
import {CountingSystem, ID as COUNTING_SYSTEM} from "../counting/CountingSystem.sol";
import {IAccountXpSystem, ID as ACCOUNT_XP_SYSTEM_ID} from "../trade/IAccountXpSystem.sol";
import {LootArrayComponent, ID as LootArrayComponentId, Layout as LootArrayComponentLayout} from "../generated/components/LootArrayComponent.sol";
import {LootArrayComponentLibrary} from "../loot/LootArrayComponentLibrary.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.dungeonsystem.v3"));

// The margin of time (in seconds) the user has to complete a dungeon after
// starting it and after the dungeon's end point as past.
uint256 constant DAILY_DUNGEONS_EXTRA_TIME_TO_COMPLETE = uint256(
    keccak256("daily_dungeons.extra_time_to_complete")
);

// Struct to track and respond to VRF requests
struct LootRequest {
    // Account the request belongs to
    address account;
    // Battle entity the request belongs to
    uint256 battleEntity;
    // Dungeon instance the request belongs to
    uint256 scheduledStartTimestamp;
    // Map entity the request belongs to
    uint256 dungeonMapEntity;
    // Node id the request belongs to
    uint256 node;
}

/**
 * @title DungeonSystemV3
 */
contract DungeonSystemV3 is IDungeonSystemV3, GameRegistryConsumerUpgradeable {
    /** MEMBERS **/

    /// @notice Mapping to track VRF requestId ➞ LootRequest
    mapping(uint256 => LootRequest) private _vrfRequests;

    /** EVENTS **/

    /// @notice Emitted when dungeon loot is granted
    // NOTE: We're leaving this in for the Unity cutover, wil be removed in
    // the next iteration of the contracts.
    event DungeonLootGranted(
        address indexed account,
        uint256 indexed battleEntity,
        uint256 scheduledStartTimestamp,
        uint256 mapEntity,
        uint256 node
    );

    /** ERRORS **/

    error DungeonNotAvailable(uint256 scheduledStartTimestamp);
    error DungeonExpired(uint256 scheduledStartTimestamp);
    error DungeonMapNotFound(uint256 scheduledStartTimestamp);
    error DungeonAlreadyCompleted(uint256 scheduledStartTimestamp);
    error DungeonNodeAlreadyCompleted(
        uint256 scheduledStartTimestamp,
        uint256 encounterEntity
    );
    error DungeonNodeOutOfOrder(
        uint256 scheduledStartTimestamp,
        uint256 encounterEntity
    );
    error DungeonNodePreviousNotCompleted(
        uint256 scheduledStartTimestamp,
        uint256 encounterEntity
    );
    error DungeonNodeNotStarted(
        uint256 scheduledStartTimestamp,
        uint256 encounterEntity
    );
    error DungeonNodeBattleEntityMismatch(
        uint256 scheduledStartTimestamp,
        uint256 encounterEntity,
        uint256 givenBattleEntity
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
     * @inheritdoc IDungeonSystemV3
     */
    function getDungeonTriggerByIndex(
        uint256 scheduleIdx
    ) external view override returns (DungeonTrigger memory) {
        return _getDungeonTrigger(scheduleIdx);
    }

    /**
     * @inheritdoc IDungeonSystemV3
     */
    function getDungeonTriggerByStartTimestamp(
        uint256 scheduledStart
    ) external view override returns (DungeonTrigger memory) {
        return _getDungeonTriggerByStartTimestamp(scheduledStart);
    }

    /**
     * @inheritdoc IDungeonSystemV3
     */
    function getDungeonMapById(
        uint256 mapEntity
    ) external view override returns (DungeonMap memory) {
        return _getDungeonMap(mapEntity);
    }

    /**
     * @inheritdoc IDungeonSystemV3
     */
    function getDungeonMapByScheduleIndex(
        uint256 scheduleIdx
    ) external view override returns (DungeonMap memory) {
        DungeonTrigger memory trigger = _getDungeonTrigger(scheduleIdx);
        return _getDungeonMap(trigger.dungeonMapEntity);
    }

    /**
     * @inheritdoc IDungeonSystemV3
     */
    function getDungeonNode(
        uint256 encounterEntity
    ) external view override returns (DungeonNode memory) {
        return _getDungeonNode(encounterEntity);
    }

    /**
     * @inheritdoc IDungeonSystemV3
     */
    function startDungeonBattle(
        StartDungeonBattleParams calldata params
    ) external nonReentrant whenNotPaused returns (uint256) {
        address account = _getPlayerAccount(_msgSender());
        return _startDungeonBattle(account, params);
    }

    /**
     * @inheritdoc IDungeonSystemV3
     */
    function endDungeonBattle(
        EndDungeonBattleParams calldata params
    ) external nonReentrant whenNotPaused {
        address account = _getPlayerAccount(_msgSender());
        _endDungeonBattle(account, params);
    }

    /**
     * A single call to manage starting and ending the battle for a dungeon node.
     * @param params Data for an started and ended battle.
     */
    function startAndEndDungeonBattle(
        StartAndEndDungeonBattleParams calldata params
    ) external nonReentrant whenNotPaused {
        address account = _getPlayerAccount(_msgSender());
        uint256 battleEntity = _startDungeonBattle(
            account,
            StartDungeonBattleParams({
                battleSeed: params.battleSeed,
                scheduledStart: params.scheduledStart,
                mapEntity: params.mapEntity,
                encounterEntity: params.encounterEntity,
                shipEntity: params.shipEntity,
                shipOverloads: params.shipOverloads
            })
        );
        _endDungeonBattle(
            account,
            EndDungeonBattleParams({
                battleEntity: battleEntity,
                scheduledStart: params.scheduledStart,
                mapEntity: params.mapEntity,
                encounterEntity: params.encounterEntity,
                success: params.success
            })
        );
    }

    /**
     * @inheritdoc GameRegistryConsumerUpgradeable
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external override onlyRole(RANDOMIZER_ROLE) {
        LootRequest storage request = _vrfRequests[requestId];

        if (request.account != address(0)) {
            // Grant the loot.
            _grantLootComplete(
                request,
                randomWords[0],
                _getDungeonNode(request.node).loots,
                _lootSystem()
            );

            // Delete the VRF request
            delete _vrfRequests[requestId];
        }
    }

    /**
     * @inheritdoc IDungeonSystemV3
     */
    function getExtraTimeForDungeonCompletion() public view returns (uint256) {
        return
            IGameGlobals(_getSystem(GAME_GLOBALS_ID)).getUint256(
                DAILY_DUNGEONS_EXTRA_TIME_TO_COMPLETE
            );
    }

    /**
     * @inheritdoc IDungeonSystemV3
     */
    function getCurrentPlayerState(
        address account,
        uint256 dungeonScheduledStart
    ) external view returns (uint256, DungeonNodeProgressState) {
        return _getCurrentPlayerState(account, dungeonScheduledStart);
    }

    /**
     * @inheritdoc IDungeonSystemV3
     */
    function isDungeonMapCompleteForAccount(
        address account,
        uint256 dungeonScheduledStart
    ) external view returns (bool) {
        DungeonTrigger
            memory dungeonTrigger = _getDungeonTriggerByStartTimestamp(
                dungeonScheduledStart
            );
        (
            uint256 currentNode,
            DungeonNodeProgressState currentNodeState
        ) = _getCurrentPlayerState(account, dungeonScheduledStart);
        return
            currentNode ==
            _getDungeonMap(dungeonTrigger.dungeonMapEntity).nodes.length &&
            currentNodeState == DungeonNodeProgressState.VICTORY;
    }

    /** INTERNAL **/

    function _getCurrentPlayerState(
        address account,
        uint256 dungeonScheduledStart
    ) internal view returns (uint256, DungeonNodeProgressState) {
        IDungeonProgressSystem progressSystem = IDungeonProgressSystem(
            _getSystem(DUNGEON_PROGRESS_SYSTEM_ID)
        );

        uint256 currentNode = progressSystem.getCurrentNode(
            account,
            dungeonScheduledStart
        );
        DungeonNodeProgressState state = progressSystem.getStateForNode(
            account,
            dungeonScheduledStart,
            currentNode
        );

        return (currentNode, state);
    }

    function _getDungeonTrigger(
        uint256 triggerIdx
    ) internal view returns (DungeonTrigger memory) {
        GauntletScheduleComponent scheduleComponent = GauntletScheduleComponent(
            _gameRegistry.getComponent(GauntletScheduleComponentId)
        );

        GauntletScheduleComponentLayout memory schedule = scheduleComponent
            .getLayoutValue(GAUNTLET_SCHEDULE_ENTITY);
        return
            DungeonTrigger({
                endAt: schedule.endTimestamps[triggerIdx],
                dungeonMapEntity: schedule.mapEntities[triggerIdx],
                startAt: schedule.startTimestamps[triggerIdx]
            });
    }

    function _getDungeonTriggerByStartTimestamp(
        uint256 scheduledStart
    ) internal view returns (DungeonTrigger memory) {
        GauntletScheduleComponent scheduleComponent = GauntletScheduleComponent(
            _gameRegistry.getComponent(GauntletScheduleComponentId)
        );
        GauntletScheduleComponentLayout memory schedule = scheduleComponent
            .getLayoutValue(GAUNTLET_SCHEDULE_ENTITY);

        for (uint i = 0; i < schedule.mapEntities.length; i++) {
            if (schedule.startTimestamps[i] == scheduledStart) {
                return
                    DungeonTrigger({
                        endAt: schedule.endTimestamps[i],
                        dungeonMapEntity: schedule.mapEntities[i],
                        startAt: schedule.startTimestamps[i]
                    });
            }
        }
    }

    function _getDungeonMap(
        uint256 dungeonMapEntity
    ) internal view returns (DungeonMap memory) {
        CombatMapComponent mapComponent = CombatMapComponent(
            _gameRegistry.getComponent(CombatMapComponentId)
        );
        CombatMapComponentLayout memory map = mapComponent.getLayoutValue(
            dungeonMapEntity
        );

        DungeonMap memory dungeonMap;
        dungeonMap.nodes = new DungeonNode[](map.encounterEntities.length);
        for (uint256 index = 0; index < map.encounterEntities.length; index++) {
            DungeonNode memory node = this.getDungeonNode(
                map.encounterEntities[index]
            );
            dungeonMap.nodes[index] = node;
        }

        return dungeonMap;
    }

    function _getDungeonNode(
        uint256 encounterEntity
    ) internal view returns (DungeonNode memory) {
        CombatEncounterComponent encounterComponent = CombatEncounterComponent(
            _gameRegistry.getComponent(CombatEncounterComponentId)
        );
        CombatEncounterComponentLayout memory encounter = encounterComponent
            .getLayoutValue(encounterEntity);

        address lootArrayComponentAddress = _gameRegistry.getComponent(
            LootArrayComponentId
        );

        return
            DungeonNode({
                nodeId: encounterEntity,
                enemies: encounter.enemyEntities,
                loots: LootArrayComponentLibrary.convertLootArrayToLootSystem(
                    lootArrayComponentAddress,
                    encounter.lootEntity
                )
            });
    }

    /**
     * @dev Starts granting loot for a dungeon node, with or without VRF
     */
    function _grantLootBegin(LootRequest memory request) internal {
        ILootSystem lootSystem = _lootSystem();
        ILootSystem.Loot[] memory loots = _getDungeonNode(request.node).loots;

        // Validate loots; returns true if VRF required.
        if (lootSystem.validateLoots(loots)) {
            // Generate a random number for the VRF request and
            // complete loot grant in fulfillRandomWordsCallback.
            uint256 requestId = _requestRandomWords(1);
            _vrfRequests[requestId] = request;
        } else {
            // Grant loot right away.
            _grantLootComplete(request, 0, loots, lootSystem);
        }
    }

    /**
     * @dev Finalizes loot granting for a dungeon node, after or without VRF
     */
    function _grantLootComplete(
        LootRequest memory request,
        uint256 randomWord,
        ILootSystem.Loot[] memory loots,
        ILootSystem lootSystem
    ) internal {
        // Grant loot right away.
        lootSystem.grantLootWithRandomWord(request.account, loots, randomWord);

        // Emit granted event; used by client to find transfer logs.
        // NOTE: We're leaving this in for the Unity cutover, wil be removed in
        // the next iteration of the contracts.
        emit DungeonLootGranted({
            account: request.account,
            battleEntity: request.battleEntity,
            scheduledStartTimestamp: request.scheduledStartTimestamp,
            mapEntity: request.dungeonMapEntity,
            node: request.node
        });
    }

    // @note In this function, "currentNode" refers to the node that the user
    // was on prior to this call being made, and "nextNode" refers to the node
    // that the user is attempting to move to.
    function _validateStartDungeonBattle(
        address account,
        StartDungeonBattleParams memory params
    ) internal view {
        DungeonTrigger memory trigger = _getDungeonTriggerByStartTimestamp(
            params.scheduledStart
        );

        // Check that the dungeon exists.
        DungeonMap memory map = _getDungeonMap(trigger.dungeonMapEntity);
        if (map.nodes.length == 0) {
            revert DungeonMapNotFound(params.scheduledStart);
        }

        // Check that the dungeon has already started.
        if (trigger.startAt > block.timestamp) {
            revert DungeonNotAvailable(params.scheduledStart);
        }

        // Check that the dungeon has not yet finished.
        // If they have already started the dungeon, they get a margin to finish.
        if (params.encounterEntity == map.nodes[0].nodeId) {
            if (trigger.endAt < block.timestamp) {
                revert DungeonExpired(params.scheduledStart);
            }
        } else {
            if (
                (trigger.endAt + getExtraTimeForDungeonCompletion() <
                    block.timestamp)
            ) {
                revert DungeonExpired(params.scheduledStart);
            }
        }

        IDungeonProgressSystem progressSystem = IDungeonProgressSystem(
            _getSystem(DUNGEON_PROGRESS_SYSTEM_ID)
        );

        // Check previous node if they're not just starting the dungeon.
        uint256 nextNode = params.encounterEntity;
        DungeonNodeProgressState nextNodeState = progressSystem.getStateForNode(
            account,
            params.scheduledStart,
            nextNode
        );

        if (nextNode != map.nodes[0].nodeId) {
            uint256 currentNode = progressSystem.getCurrentNode(
                account,
                params.scheduledStart
            );

            // TODO: When we switch to the graph node based system, we'll need
            // to check the current node's next nodes to see if the node the
            // user requested was in the list.
            if (nextNodeState == DungeonNodeProgressState.UNVISITED) {
                // When starting a new node, check that the next node follows the current node.
                for (uint256 i = 0; i < map.nodes.length; i++) {
                    if (map.nodes[i].nodeId == currentNode) {
                        if (i + 1 < map.nodes.length) {
                            if (map.nodes[i + 1].nodeId != nextNode) {
                                revert DungeonNodeOutOfOrder(
                                    params.scheduledStart,
                                    nextNode
                                );
                            }
                        }
                    }
                }

                // When starting a new node, check that the previous node was victorious.
                if (
                    progressSystem.getStateForNode(
                        account,
                        params.scheduledStart,
                        currentNode
                    ) != DungeonNodeProgressState.VICTORY
                ) {
                    revert DungeonNodePreviousNotCompleted(
                        params.scheduledStart,
                        currentNode
                    );
                }
            }
        }

        // Check that the node hasn't already been completed.
        if (nextNodeState == DungeonNodeProgressState.VICTORY) {
            revert DungeonNodeAlreadyCompleted(params.scheduledStart, nextNode);
        }
    }

    function _markStartDungeonBattle(
        address account,
        StartDungeonBattleParams memory params,
        uint256 battleEntity
    ) internal {
        IDungeonProgressSystem progressSystem = IDungeonProgressSystem(
            _getSystem(DUNGEON_PROGRESS_SYSTEM_ID)
        );

        progressSystem.setCurrentNode(
            account,
            params.scheduledStart,
            params.encounterEntity
        );
        progressSystem.setStateForNode(
            account,
            params.scheduledStart,
            params.encounterEntity,
            DungeonNodeProgressState.STARTED
        );
        progressSystem.setBattleEntityForNode(
            account,
            params.scheduledStart,
            params.encounterEntity,
            battleEntity
        );
    }

    // @note In this function, "currentNode" is always the node being finished.
    function _validateEndDungeonBattle(
        address account,
        DungeonTrigger memory trigger,
        EndDungeonBattleParams memory params
    ) internal {
        DungeonMap memory map = _getDungeonMap(trigger.dungeonMapEntity);

        // Check that the dungeon exists.
        if (map.nodes.length == 0) {
            revert DungeonMapNotFound(params.scheduledStart);
        }

        // Check that the dungeon has already started, but not finished.
        if (
            trigger.startAt > block.timestamp || // Start is in the future
            (trigger.endAt + getExtraTimeForDungeonCompletion() <
                block.timestamp) // End is in the past, with extra time
        ) {
            revert DungeonExpired(params.scheduledStart);
        }

        IDungeonProgressSystem progressSystem = IDungeonProgressSystem(
            _getSystem(DUNGEON_PROGRESS_SYSTEM_ID)
        );

        // Check that this node has been started.
        uint256 currentNode = progressSystem.getCurrentNode(
            account,
            params.scheduledStart
        );
        if (currentNode != params.encounterEntity) {
            revert DungeonNodeOutOfOrder(
                params.scheduledStart,
                params.encounterEntity
            );
        }

        // Check that the node hasn't already been completed.
        if (
            progressSystem.getStateForNode(
                account,
                params.scheduledStart,
                params.encounterEntity
            ) != DungeonNodeProgressState.STARTED
        ) {
            revert DungeonNodeNotStarted(
                params.scheduledStart,
                params.encounterEntity
            );
        }

        // Check that the node's battleEntity matches.
        if (
            progressSystem.getBattleEntityForNode(
                account,
                params.scheduledStart,
                params.encounterEntity
            ) != params.battleEntity
        ) {
            revert DungeonNodeBattleEntityMismatch(
                params.scheduledStart,
                params.encounterEntity,
                params.battleEntity
            );
        }
    }

    function _markEndDungeonBattle(
        address account,
        EndDungeonBattleParams memory params
    ) internal {
        IDungeonProgressSystem progressSystem = IDungeonProgressSystem(
            _getSystem(DUNGEON_PROGRESS_SYSTEM_ID)
        );

        // Identify the winner of the battle and set the state accordingly.
        // NOTE: rely on DungeonBattleSystem to perform validations for victory.
        if (params.success) {
            progressSystem.setStateForNode(
                account,
                params.scheduledStart,
                params.encounterEntity,
                DungeonNodeProgressState.VICTORY
            );
        } else {
            progressSystem.setStateForNode(
                account,
                params.scheduledStart,
                params.encounterEntity,
                DungeonNodeProgressState.DEFEAT
            );
        }
    }

    /**
     * @notice Handles granting of AccountXp for a dungeon success or failure
     * @param account The account to grant AccountXp to
     * @param dungeonScheduledStart The dungeon trigger entity
     * @param success Whether the dungeon was successful or not
     */
    function _handleAccountXpGranting(
        address account,
        uint256 dungeonScheduledStart,
        bool success
    ) internal {
        // Get amount of AccountXp to grant
        AccountXpGrantedComponent accountXpGrantedComponent = AccountXpGrantedComponent(
                _gameRegistry.getComponent(ACCOUNT_XP_GRANTED_COMPONENT_ID)
            );
        // Use DungeonSystemV2 ID as the entity
        AccountXpGrantedComponentStruct
            memory accountXpGranted = accountXpGrantedComponent.getLayoutValue(
                ID
            );
        uint256 amountToGrant;
        if (success) {
            amountToGrant = accountXpGranted.successAmount;
        } else {
            amountToGrant = accountXpGranted.failAmount;
        }
        // Get current accrued AccountXp for this dungeon
        CountingSystem countingSystem = CountingSystem(
            _gameRegistry.getSystem(COUNTING_SYSTEM)
        );
        uint256 accountEntity = EntityLibrary.addressToEntity(account);
        uint256 currentAccruedXp = countingSystem.getCount(
            dungeonScheduledStart,
            accountEntity
        );
        // Max daily amount reached or none available to grant
        if (
            amountToGrant == 0 ||
            currentAccruedXp >= accountXpGranted.maxAmountAllowed
        ) {
            return;
        }
        if (
            currentAccruedXp + amountToGrant >=
            accountXpGranted.maxAmountAllowed
        ) {
            amountToGrant =
                accountXpGranted.maxAmountAllowed -
                currentAccruedXp;
        }
        // Update CountingSystem
        countingSystem.incrementCount(
            dungeonScheduledStart,
            accountEntity,
            amountToGrant
        );
        // Grant AccountXp
        IAccountXpSystem(_getSystem(ACCOUNT_XP_SYSTEM_ID)).grantAccountXp(
            accountEntity,
            amountToGrant
        );
    }

    function _startDungeonBattle(
        address account,
        StartDungeonBattleParams memory params
    ) internal returns (uint256) {
        // Validate
        _validateStartDungeonBattle(account, params);
        DungeonNode memory node = _getDungeonNode(params.encounterEntity);
        // Start battle
        uint256 battleEntity = IDungeonBattleSystemV2(
            _getSystem(DUNGEON_BATTLE_SYSTEM_ID)
        ).startBattle(account, params, node);
        _markStartDungeonBattle(account, params, battleEntity);
        return battleEntity;
    }

    function _endDungeonBattle(
        address account,
        EndDungeonBattleParams memory params
    ) internal {
        DungeonTrigger memory trigger = _getDungeonTriggerByStartTimestamp(
            params.scheduledStart
        );

        // Validate
        _validateEndDungeonBattle(account, trigger, params);

        // End battle
        IDungeonBattleSystemV2(_getSystem(DUNGEON_BATTLE_SYSTEM_ID)).endBattle(
            EndBattleParams({
                account: account,
                battleEntity: params.battleEntity,
                success: params.success
            })
        );

        // Update dungeon progress state.
        _markEndDungeonBattle(account, params);

        // Handle account-xp granting
        _handleAccountXpGranting(
            account,
            params.scheduledStart,
            params.success
        );

        // Grant loot if the battle was successful.
        if (params.success) {
            _grantLootBegin(
                LootRequest({
                    account: account,
                    battleEntity: params.battleEntity,
                    scheduledStartTimestamp: params.scheduledStart,
                    dungeonMapEntity: trigger.dungeonMapEntity,
                    node: params.encounterEntity
                })
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../GameRegistryConsumerUpgradeable.sol";

import {StartDungeonBattleParams, DungeonNode} from "./IDungeonSystemV3.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.dungeonbattlesystem.v2")
);

struct EndBattleParams {
    address account;
    uint256 battleEntity;
    bool success;
}

/**
 * @title IDungeonBattleSystemV2
 */
interface IDungeonBattleSystemV2 {
    /**
     * @dev Start a dungeon battle.
     * @param params StartBattleParams
     * @return battleEntity Entity of the battle
     */
    function startBattle(
        address account,
        StartDungeonBattleParams calldata params,
        DungeonNode calldata node
    ) external returns (uint256);

    /**
     * @dev End a dungeon battle.
     * @param params EndBattleParams
     */
    function endBattle(EndBattleParams calldata params) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../GameRegistryConsumerUpgradeable.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.dungeonprogresssystem")
);

enum DungeonNodeProgressState {
    UNVISITED,
    STARTED,
    VICTORY,
    DEFEAT
}

/**
 * @title IDungeonProgressSystem
 */
interface IDungeonProgressSystem {
    /**
     * @dev Get the account progress for a dungeon.
     * @param account address of the account to get progress for
     * @param dungeon entity of the dungeon to get progress for
     * @return uint256 index of the dungeon node the account last completed
     */
    function getCurrentNode(
        address account,
        uint256 dungeon
    ) external view returns (uint256);

    /**
     * @dev Set the account progress for a dungeon.
     * @param account address of the account to set progress for
     * @param dungeon entity of the dungeon to set progress for
     * @param node index of the dungeon node to set progress to
     */
    function setCurrentNode(
        address account,
        uint256 dungeon,
        uint256 node
    ) external;

    /**
     * @dev Get the account progress for a dungeon.
     * @param account address of the account to get progress for
     * @param dungeon entity of the dungeon to get progress for
     * @param node index of the dungeon node to get progress to
     */
    function getStateForNode(
        address account,
        uint256 dungeon,
        uint256 node
    ) external view returns (DungeonNodeProgressState);

    /**
     * @dev Set the account progress for a dungeon.
     * @param account address of the account to set progress for
     * @param dungeon entity of the dungeon to set progress for
     * @param node index of the dungeon node to set progress to
     */
    function setStateForNode(
        address account,
        uint256 dungeon,
        uint256 node,
        DungeonNodeProgressState state
    ) external;

    /**
     * @dev Get the battleEntity for that account for that dungeon node.
     * @param account address of the account to get the battle for
     * @param dungeon entity of the dungeon to get the battle for
     * @param node index of the dungeon node to get the battle for
     * @return uint256 the battleEntity for that account for that node
     */
    function getBattleEntityForNode(
        address account,
        uint256 dungeon,
        uint256 node
    ) external returns (uint256);

    /**
     * @dev Set the battleEntity for that account for that dungeon node.
     * @param account address of the account to set the battle for
     * @param dungeon entity of the dungeon to set the battle for
     * @param node index of the dungeon node to set the battle for
     * @param battle the battleEntity for that account for that node
     */
    function setBattleEntityForNode(
        address account,
        uint256 dungeon,
        uint256 node,
        uint256 battle
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../GameRegistryConsumerUpgradeable.sol";

import {DungeonNodeProgressState} from "./IDungeonProgressSystem.sol";

struct StartAndEndDungeonBattleParams {
    uint256 battleSeed;
    uint256 scheduledStart;
    uint256 mapEntity;
    uint256 encounterEntity;
    uint256 shipEntity;
    uint256[] shipOverloads;
    bool success;
}

struct StartDungeonBattleParams {
    uint256 battleSeed;
    uint256 scheduledStart;
    uint256 mapEntity;
    uint256 encounterEntity;
    uint256 shipEntity;
    uint256[] shipOverloads;
}

struct EndDungeonBattleParams {
    uint256 battleEntity;
    uint256 scheduledStart;
    uint256 mapEntity;
    uint256 encounterEntity;
    bool success;
}

struct DungeonMap {
    DungeonNode[] nodes;
}

struct DungeonNode {
    uint256 nodeId;
    uint256[] enemies;
    ILootSystem.Loot[] loots;
}

struct DungeonTrigger {
    uint256 dungeonMapEntity;
    uint256 endAt;
    uint256 startAt;
}

/**
 * @title IDungeonSystemV2
 *
 * This is where outside users will interact with the dungeon system. It will
 * proxy all other calls to the map, battle, and progress systems.
 */
interface IDungeonSystemV3 {
    /**
     * @dev Returns the dungeon trigger, for use in Unity display/setup.
     * @param scheduledStartTimestamp Id of the dungeon trigger to preview.
     * @return dungeonMap Dungeon node data.
     */
    function getDungeonTriggerByIndex(
        uint256 scheduledStartTimestamp
    ) external returns (DungeonTrigger memory);

    /**
     * @dev Returns the dungeon trigger, for debugging purposes.
     * @param scheduledStartTimestamp Start timestamp of the dungeon trigger.
     * @return dungeonTrigger Dungeon trigger data.
     */
    function getDungeonTriggerByStartTimestamp(
        uint256 scheduledStartTimestamp
    ) external returns (DungeonTrigger memory);

    /**
     * @dev Returns the dungeon map, for use in Unity display/setup.
     * @param mapEntity Id of the dungeon trigger to preview.
     * @return dungeonMap Dungeon node data.
     */
    function getDungeonMapById(
        uint256 mapEntity
    ) external returns (DungeonMap memory);

    /**
     * @dev Returns the dungeon map, for use in Unity display/setup.
     * @param scheduleIndex Id of the dungeon trigger to preview.
     * @return dungeonMap Dungeon node data.
     */
    function getDungeonMapByScheduleIndex(
        uint256 scheduleIndex
    ) external returns (DungeonMap memory);

    /**
     * @dev Returns the dungeon node, for use in Unity display/setup.
     * @param encounterEntity Id of the node within the dungeon to preview.
     * @return dungeonNode Dungeon node data.
     */
    function getDungeonNode(
        uint256 encounterEntity
    ) external returns (DungeonNode memory);

    /**
     * @dev Start the battle for a dungeon node.
     * @param params Data for an started battle.
     * @return uint256 The corresponding battle entity that has been started.
     */
    function startDungeonBattle(
        StartDungeonBattleParams calldata params
    ) external returns (uint256);

    /**
     * @dev Finish the battle for a dungeon node.
     * @param params Data for an ended battle.
     */
    function endDungeonBattle(EndDungeonBattleParams calldata params) external;

    /**
     * A single call to manage starting and ending the battle for a dungeon node.
     * @param params Data for an started and ended battle.
     */
    function startAndEndDungeonBattle(
        StartAndEndDungeonBattleParams calldata params
    ) external;

    /**
     * @dev Get the extra time for dungeon completion.
     * @return uint256
     */
    function getExtraTimeForDungeonCompletion() external view returns (uint256);

    /**
     * @dev Get the current state of the player through the dungeon.
     * @param account The account to get the state for
     * @param dungeonEntity The dungeon to get the state for
     * @return uint256  The current node
     * @return DungeonNodeProgressState  The player's state in the current node
     */
    function getCurrentPlayerState(
        address account,
        uint256 dungeonEntity
    ) external view returns (uint256, DungeonNodeProgressState);

    /**
     * @dev Return the state of the dungeon overall for the player.
     * @param account The account to get the state for
     * @param dungeonScheduledStart The dungeon to get the state for
     * @return bool  True if the player has completed the dungeon, false otherwise.
     */
    function isDungeonMapCompleteForAccount(
        address account,
        uint256 dungeonScheduledStart
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.gameglobals"));

/** @title Provides a set of globals to a set of ERC721/ERC1155 contracts */
interface IGameGlobals is IERC165 {
    // Type of data to allow in the global
    enum GlobalDataType {
        NOT_INITIALIZED, // Global has not been initialized
        BOOL, // bool data type
        INT256, // uint256 data type
        INT256_ARRAY, // int256[] data type
        UINT256, // uint256 data type
        UINT256_ARRAY, // uint256[] data type
        STRING, // string data type
        STRING_ARRAY // string[] data type
    }

    // Holds metadata for a given global type
    struct GlobalMetadata {
        // Name of the global, used in tokenURIs
        string name;
        // Global type
        GlobalDataType dataType;
    }

    /**
     * Sets the value for the string global, also checks to make sure global can be modified
     *
     * @param globalId        Id of the global to modify
     * @param value          New value for the given global
     */
    function setString(uint256 globalId, string calldata value) external;

    /**
     * Sets the value for the string global, also checks to make sure global can be modified
     *
     * @param globalId        Id of the global to modify
     * @param value          New value for the given global
     */
    function setStringArray(uint256 globalId, string[] calldata value) external;

    /**
     * Sets several string globals
     *
     * @param globalIds       Ids of globals to set
     * @param values         Values of globals to set
     */
    function batchSetString(
        uint256[] calldata globalIds,
        string[] calldata values
    ) external;

    /**
     * Sets the value for the bool global, also checks to make sure global can be modified
     *
     * @param globalId       Id of the global to modify
     * @param value          New value for the given global
     */
    function setBool(uint256 globalId, bool value) external;

    /**
     * Sets the value for the uint256 global, also checks to make sure global can be modified
     *
     * @param globalId       Id of the global to modify
     * @param value          New value for the given global
     */
    function setUint256(uint256 globalId, uint256 value) external;

    /**
     * Sets the value for the int256 global, also checks to make sure global can be modified
     *
     * @param globalId       Id of the global to modify
     * @param value          New value for the given global
     */
    function setInt256(uint256 globalId, int256 value) external;

    /**
     * Sets the value for the uint256 global, also checks to make sure global can be modified
     *
     * @param globalId        Id of the global to modify
     * @param value          New value for the given global
     */
    function setUint256Array(uint256 globalId, uint256[] calldata value)
        external;

    /**
     * Sets the value for the int256 global, also checks to make sure global can be modified
     *
     * @param globalId       Id of the global to modify
     * @param value          New value for the given global
     */
    function setInt256Array(uint256 globalId, int256[] calldata value) external;

    /**
     * Sets several uint256 globals for a given token
     *
     * @param globalIds       Ids of globals to set
     * @param values         Values of globals to set
     */
    function batchSetUint256(
        uint256[] calldata globalIds,
        uint256[] calldata values
    ) external;

    /**
     * Sets several int256 globals for a given token
     *
     * @param globalIds      Ids of globals to set
     * @param values         Values of globals to set
     */
    function batchSetInt256(
        uint256[] calldata globalIds,
        int256[] calldata values
    ) external;

    /**
     * Retrieves a bool global for the given token
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getBool(uint256 globalId) external view returns (bool);

    /**
     * Retrieves a uint256 global for the given token
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getUint256(uint256 globalId) external view returns (uint256);

    /**
     * Retrieves a uint256 array global for the given token
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getUint256Array(uint256 globalId)
        external
        view
        returns (uint256[] memory);

    /**
     * Retrieves a int256 global for the given token
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getInt256(uint256 globalId) external view returns (int256);

    /**
     * Retrieves a int256 array global for the given token
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getInt256Array(uint256 globalId)
        external
        view
        returns (int256[] memory);

    /**
     * Retrieves a string global
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getString(uint256 globalId) external view returns (string memory);

    /**
     * Returns data for a global variable containing an array of strings
     *
     * @param globalId  Id of the global to retrieve
     *
     * @return Global value as a string[]
     */
    function getStringArray(uint256 globalId)
        external
        view
        returns (string[] memory);

    /**
     * @param globalId  Id of the global to get metadata for
     * @return Metadata for the given global
     */
    function getMetadata(uint256 globalId)
        external
        view
        returns (GlobalMetadata memory);
}

// SPDX-License-Identifier: MIT
// Auto-generated using Mage CLI codegen (v1) - DO NOT EDIT

pragma solidity ^0.8.13;

import {TypesLibrary} from "../../core/TypesLibrary.sol";
import {BaseStorageComponentV2, IBaseStorageComponentV2} from "../../core/components/BaseStorageComponentV2.sol";
import {GAME_LOGIC_CONTRACT_ROLE} from "../../Constants.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.accountxpgrantedcomponent.v1")
);

struct Layout {
    uint64 successAmount;
    uint64 failAmount;
    uint64 maxAmountAllowed;
}

library AccountXpGrantedComponentStorage {
    bytes32 internal constant STORAGE_SLOT = bytes32(ID);

    // Declare struct for mapping entity to struct
    struct InternalLayout {
        mapping(uint256 => Layout) entityIdToStruct;
    }

    function layout()
        internal
        pure
        returns (InternalLayout storage dataStruct)
    {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            dataStruct.slot := position
        }
    }
}

/**
 * @title AccountXpGrantedComponent
 * @dev Account Xp Granted Component
 */
contract AccountXpGrantedComponent is BaseStorageComponentV2 {
    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(
        address gameRegistryAddress
    ) BaseStorageComponentV2(gameRegistryAddress, ID) {
        // Do nothing
    }

    /**
     * @inheritdoc IBaseStorageComponentV2
     */
    function getSchema()
        public
        pure
        override
        returns (string[] memory keys, TypesLibrary.SchemaValue[] memory values)
    {
        keys = new string[](3);
        values = new TypesLibrary.SchemaValue[](3);

        // Amount of Xp to reward for success
        keys[0] = "success_amount";
        values[0] = TypesLibrary.SchemaValue.UINT64;

        // Amount of Xp to reward for fail
        keys[1] = "fail_amount";
        values[1] = TypesLibrary.SchemaValue.UINT64;

        // Max amount of Xp allowed to be rewarded
        keys[2] = "max_amount_allowed";
        values[2] = TypesLibrary.SchemaValue.UINT64;
    }

    /**
     * Sets the typed value for this component
     *
     * @param entity Entity to get value for
     * @param value Layout to set for the given entity
     */
    function setLayoutValue(
        uint256 entity,
        Layout calldata value
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _setValue(entity, value);
    }

    /**
     * Sets the native value for this component
     *
     * @param entity Entity to get value for
     * @param successAmount Amount of Xp to reward for success
     * @param failAmount Amount of Xp to reward for fail
     * @param maxAmountAllowed Max amount of Xp allowed to be rewarded
     */
    function setValue(
        uint256 entity,
        uint64 successAmount,
        uint64 failAmount,
        uint64 maxAmountAllowed
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _setValue(entity, Layout(successAmount, failAmount, maxAmountAllowed));
    }

    /**
     * Batch sets the typed value for this component
     *
     * @param entities Entity to batch set values for
     * @param values Layout to set for the given entities
     */
    function batchSetValue(
        uint256[] calldata entities,
        Layout[] calldata values
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        if (entities.length != values.length) {
            revert InvalidBatchData(entities.length, values.length);
        }

        // Set the values in storage
        bytes[] memory encodedValues = new bytes[](entities.length);
        for (uint256 i = 0; i < entities.length; i++) {
            _setValueToStorage(entities[i], values[i]);
            encodedValues[i] = _getEncodedValues(values[i]);
        }

        // ABI Encode all native types of the struct
        _emitBatchSetBytes(entities, encodedValues);
    }

    /**
     * Returns the typed value for this component
     *
     * @param entity Entity to get value for
     * @return value Layout value for the given entity
     */
    function getLayoutValue(
        uint256 entity
    ) external view virtual returns (Layout memory value) {
        // Get the struct from storage
        value = AccountXpGrantedComponentStorage.layout().entityIdToStruct[
            entity
        ];
    }

    /**
     * Returns the native values for this component
     *
     * @param entity Entity to get value for
     * @return successAmount Amount of Xp to reward for success
     * @return failAmount Amount of Xp to reward for fail
     * @return maxAmountAllowed Max amount of Xp allowed to be rewarded
     */
    function getValue(
        uint256 entity
    )
        external
        view
        virtual
        returns (
            uint64 successAmount,
            uint64 failAmount,
            uint64 maxAmountAllowed
        )
    {
        if (has(entity)) {
            Layout memory s = AccountXpGrantedComponentStorage
                .layout()
                .entityIdToStruct[entity];
            (successAmount, failAmount, maxAmountAllowed) = abi.decode(
                _getEncodedValues(s),
                (uint64, uint64, uint64)
            );
        }
    }

    /**
     * Returns an array of byte values for each field of this component.
     *
     * @param entity Entity to build array of byte values for.
     */
    function getByteValues(
        uint256 entity
    ) external view virtual returns (bytes[] memory values) {
        // Get the struct from storage
        Layout storage s = AccountXpGrantedComponentStorage
            .layout()
            .entityIdToStruct[entity];

        // ABI Encode all fields of the struct and add to values array
        values = new bytes[](3);
        values[0] = abi.encode(s.successAmount);
        values[1] = abi.encode(s.failAmount);
        values[2] = abi.encode(s.maxAmountAllowed);
    }

    /**
     * Returns the bytes value for this component
     *
     * @param entity Entity to get value for
     */
    function getBytes(
        uint256 entity
    ) external view returns (bytes memory value) {
        Layout memory s = AccountXpGrantedComponentStorage
            .layout()
            .entityIdToStruct[entity];
        value = _getEncodedValues(s);
    }

    /**
     * Sets the value of this component using a byte array
     *
     * @param entity Entity to set value for
     */
    function setBytes(
        uint256 entity,
        bytes calldata value
    ) external onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout memory s = AccountXpGrantedComponentStorage
            .layout()
            .entityIdToStruct[entity];
        (s.successAmount, s.failAmount, s.maxAmountAllowed) = abi.decode(
            value,
            (uint64, uint64, uint64)
        );
        _setValueToStorage(entity, s);

        // ABI Encode all native types of the struct
        _emitSetBytes(entity, value);
    }

    /**
     * Remove the given entity from this component.
     *
     * @param entity Entity to remove from this component.
     */
    function remove(
        uint256 entity
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        // Remove the entity from the component
        delete AccountXpGrantedComponentStorage.layout().entityIdToStruct[
            entity
        ];
        _emitRemoveBytes(entity);
    }

    /**
     * Batch remove the given entities from this component.
     *
     * @param entities Entities to remove from this component.
     */
    function batchRemove(
        uint256[] calldata entities
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        // Remove the entities from the component
        for (uint256 i = 0; i < entities.length; i++) {
            delete AccountXpGrantedComponentStorage.layout().entityIdToStruct[
                entities[i]
            ];
        }
        _emitBatchRemoveBytes(entities);
    }

    /**
     * Check whether the given entity has a value in this component.
     *
     * @param entity Entity to check whether it has a value in this component for.
     */
    function has(uint256 entity) public view virtual returns (bool) {
        return gameRegistry.getEntityHasComponent(entity, ID);
    }

    /** INTERNAL **/

    function _setValueToStorage(uint256 entity, Layout memory value) internal {
        Layout storage s = AccountXpGrantedComponentStorage
            .layout()
            .entityIdToStruct[entity];

        s.successAmount = value.successAmount;
        s.failAmount = value.failAmount;
        s.maxAmountAllowed = value.maxAmountAllowed;
    }

    function _setValue(uint256 entity, Layout memory value) internal {
        _setValueToStorage(entity, value);

        // ABI Encode all native types of the struct
        _emitSetBytes(
            entity,
            abi.encode(
                value.successAmount,
                value.failAmount,
                value.maxAmountAllowed
            )
        );
    }

    function _getEncodedValues(
        Layout memory value
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                value.successAmount,
                value.failAmount,
                value.maxAmountAllowed
            );
    }
}

// SPDX-License-Identifier: MIT
// Auto-generated using Mage CLI codegen (v1) - DO NOT EDIT

pragma solidity ^0.8.13;

import {TypesLibrary} from "../../core/TypesLibrary.sol";
import {BaseStorageComponentV2, IBaseStorageComponentV2} from "../../core/components/BaseStorageComponentV2.sol";
import {GAME_LOGIC_CONTRACT_ROLE} from "../../Constants.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.combatencountercomponent.dev1")
);

struct Layout {
    uint256[] enemyEntities;
    uint256 lootEntity;
}

library CombatEncounterComponentStorage {
    bytes32 internal constant STORAGE_SLOT = bytes32(ID);

    // Declare struct for mapping entity to struct
    struct InternalLayout {
        mapping(uint256 => Layout) entityIdToStruct;
    }

    function layout()
        internal
        pure
        returns (InternalLayout storage dataStruct)
    {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            dataStruct.slot := position
        }
    }
}

/**
 * @title CombatEncounterComponent
 * @dev The parameters used to stage a gauntlet battle
 */
contract CombatEncounterComponent is BaseStorageComponentV2 {
    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(
        address gameRegistryAddress
    ) BaseStorageComponentV2(gameRegistryAddress, ID) {
        // Do nothing
    }

    /**
     * @inheritdoc IBaseStorageComponentV2
     */
    function getSchema()
        public
        pure
        override
        returns (string[] memory keys, TypesLibrary.SchemaValue[] memory values)
    {
        keys = new string[](2);
        values = new TypesLibrary.SchemaValue[](2);

        // The entity IDs of the enemies being fought in this encounter
        keys[0] = "enemy_entities";
        values[0] = TypesLibrary.SchemaValue.UINT256_ARRAY;

        // The loot granted by this encounter
        keys[1] = "loot_entity";
        values[1] = TypesLibrary.SchemaValue.UINT256;
    }

    /**
     * Sets the typed value for this component
     *
     * @param entity Entity to get value for
     * @param value Layout to set for the given entity
     */
    function setLayoutValue(
        uint256 entity,
        Layout calldata value
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _setValue(entity, value);
    }

    /**
     * Sets the native value for this component
     *
     * @param entity Entity to get value for
     * @param enemyEntities The entity IDs of the enemies being fought in this encounter
     * @param lootEntity The loot granted by this encounter
     */
    function setValue(
        uint256 entity,
        uint256[] memory enemyEntities,
        uint256 lootEntity
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _setValue(entity, Layout(enemyEntities, lootEntity));
    }

    /**
     * Batch sets the typed value for this component
     *
     * @param entities Entity to batch set values for
     * @param values Layout to set for the given entities
     */
    function batchSetValue(
        uint256[] calldata entities,
        Layout[] calldata values
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        if (entities.length != values.length) {
            revert InvalidBatchData(entities.length, values.length);
        }

        // Set the values in storage
        bytes[] memory encodedValues = new bytes[](entities.length);
        for (uint256 i = 0; i < entities.length; i++) {
            _setValueToStorage(entities[i], values[i]);
            encodedValues[i] = _getEncodedValues(values[i]);
        }

        // ABI Encode all native types of the struct
        _emitBatchSetBytes(entities, encodedValues);
    }

    /**
     * Returns the typed value for this component
     *
     * @param entity Entity to get value for
     * @return value Layout value for the given entity
     */
    function getLayoutValue(
        uint256 entity
    ) external view virtual returns (Layout memory value) {
        // Get the struct from storage
        value = CombatEncounterComponentStorage.layout().entityIdToStruct[
            entity
        ];
    }

    /**
     * Returns the native values for this component
     *
     * @param entity Entity to get value for
     * @return enemyEntities The entity IDs of the enemies being fought in this encounter
     * @return lootEntity The loot granted by this encounter
     */
    function getValue(
        uint256 entity
    )
        external
        view
        virtual
        returns (uint256[] memory enemyEntities, uint256 lootEntity)
    {
        if (has(entity)) {
            Layout memory s = CombatEncounterComponentStorage
                .layout()
                .entityIdToStruct[entity];
            (enemyEntities, lootEntity) = abi.decode(
                _getEncodedValues(s),
                (uint256[], uint256)
            );
        }
    }

    /**
     * Returns an array of byte values for each field of this component.
     *
     * @param entity Entity to build array of byte values for.
     */
    function getByteValues(
        uint256 entity
    ) external view virtual returns (bytes[] memory values) {
        // Get the struct from storage
        Layout storage s = CombatEncounterComponentStorage
            .layout()
            .entityIdToStruct[entity];

        // ABI Encode all fields of the struct and add to values array
        values = new bytes[](2);
        values[0] = abi.encode(s.enemyEntities);
        values[1] = abi.encode(s.lootEntity);
    }

    /**
     * Returns the bytes value for this component
     *
     * @param entity Entity to get value for
     */
    function getBytes(
        uint256 entity
    ) external view returns (bytes memory value) {
        Layout memory s = CombatEncounterComponentStorage
            .layout()
            .entityIdToStruct[entity];
        value = _getEncodedValues(s);
    }

    /**
     * Sets the value of this component using a byte array
     *
     * @param entity Entity to set value for
     */
    function setBytes(
        uint256 entity,
        bytes calldata value
    ) external onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout memory s = CombatEncounterComponentStorage
            .layout()
            .entityIdToStruct[entity];
        (s.enemyEntities, s.lootEntity) = abi.decode(
            value,
            (uint256[], uint256)
        );
        _setValueToStorage(entity, s);

        // ABI Encode all native types of the struct
        _emitSetBytes(entity, value);
    }

    /**
     * Remove the given entity from this component.
     *
     * @param entity Entity to remove from this component.
     */
    function remove(
        uint256 entity
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        // Remove the entity from the component
        delete CombatEncounterComponentStorage.layout().entityIdToStruct[
            entity
        ];
        _emitRemoveBytes(entity);
    }

    /**
     * Batch remove the given entities from this component.
     *
     * @param entities Entities to remove from this component.
     */
    function batchRemove(
        uint256[] calldata entities
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        // Remove the entities from the component
        for (uint256 i = 0; i < entities.length; i++) {
            delete CombatEncounterComponentStorage.layout().entityIdToStruct[
                entities[i]
            ];
        }
        _emitBatchRemoveBytes(entities);
    }

    /**
     * Check whether the given entity has a value in this component.
     *
     * @param entity Entity to check whether it has a value in this component for.
     */
    function has(uint256 entity) public view virtual returns (bool) {
        return gameRegistry.getEntityHasComponent(entity, ID);
    }

    /** INTERNAL **/

    function _setValueToStorage(uint256 entity, Layout memory value) internal {
        Layout storage s = CombatEncounterComponentStorage
            .layout()
            .entityIdToStruct[entity];

        s.enemyEntities = value.enemyEntities;
        s.lootEntity = value.lootEntity;
    }

    function _setValue(uint256 entity, Layout memory value) internal {
        _setValueToStorage(entity, value);

        // ABI Encode all native types of the struct
        _emitSetBytes(
            entity,
            abi.encode(value.enemyEntities, value.lootEntity)
        );
    }

    function _getEncodedValues(
        Layout memory value
    ) internal pure returns (bytes memory) {
        return abi.encode(value.enemyEntities, value.lootEntity);
    }
}

// SPDX-License-Identifier: MIT
// Auto-generated using Mage CLI codegen (v1) - DO NOT EDIT

pragma solidity ^0.8.13;

import {TypesLibrary} from "../../core/TypesLibrary.sol";
import {BaseStorageComponentV2, IBaseStorageComponentV2} from "../../core/components/BaseStorageComponentV2.sol";
import {GAME_LOGIC_CONTRACT_ROLE} from "../../Constants.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.combatmapcomponent.dev1")
);

struct Layout {
    uint256[] encounterEntities;
}

library CombatMapComponentStorage {
    bytes32 internal constant STORAGE_SLOT = bytes32(ID);

    // Declare struct for mapping entity to struct
    struct InternalLayout {
        mapping(uint256 => Layout) entityIdToStruct;
    }

    function layout()
        internal
        pure
        returns (InternalLayout storage dataStruct)
    {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            dataStruct.slot := position
        }
    }
}

/**
 * @title CombatMapComponent
 * @dev A collection of encounters that makes up a gauntlet
 */
contract CombatMapComponent is BaseStorageComponentV2 {
    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(
        address gameRegistryAddress
    ) BaseStorageComponentV2(gameRegistryAddress, ID) {
        // Do nothing
    }

    /**
     * @inheritdoc IBaseStorageComponentV2
     */
    function getSchema()
        public
        pure
        override
        returns (string[] memory keys, TypesLibrary.SchemaValue[] memory values)
    {
        keys = new string[](1);
        values = new TypesLibrary.SchemaValue[](1);

        // Entity IDs of the encounters in this map
        keys[0] = "encounter_entities";
        values[0] = TypesLibrary.SchemaValue.UINT256_ARRAY;
    }

    /**
     * Sets the typed value for this component
     *
     * @param entity Entity to get value for
     * @param value Layout to set for the given entity
     */
    function setLayoutValue(
        uint256 entity,
        Layout calldata value
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _setValue(entity, value);
    }

    /**
     * Sets the native value for this component
     *
     * @param entity Entity to get value for
     * @param encounterEntities Entity IDs of the encounters in this map
     */
    function setValue(
        uint256 entity,
        uint256[] memory encounterEntities
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _setValue(entity, Layout(encounterEntities));
    }

    /**
     * Appends to the components.
     *
     * @param entity Entity to get value for
     * @param values Layout to set for the given entity
     */
    function append(
        uint256 entity,
        Layout memory values
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout storage s = CombatMapComponentStorage.layout().entityIdToStruct[
            entity
        ];
        for (uint256 i = 0; i < values.encounterEntities.length; i++) {
            s.encounterEntities.push(values.encounterEntities[i]);
        }

        // ABI Encode all native types of the struct
        _emitSetBytes(entity, abi.encode(s.encounterEntities));
    }

    /**
     * @dev Removes the values at a set of given indexes
     * @param entity Entity to get value for
     * @param indexes Indexes to remove
     */
    function removeValueAtIndexes(
        uint256 entity,
        uint256[] calldata indexes
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout storage s = CombatMapComponentStorage.layout().entityIdToStruct[
            entity
        ];

        for (uint256 i = 0; i < indexes.length; i++) {
            uint256 indexToRemove = indexes[i];
            // Get the last index
            uint256 lastIndexInArray = s.encounterEntities.length - 1;
            // Move the last value to the index to pop
            if (indexToRemove != lastIndexInArray) {
                s.encounterEntities[indexToRemove] = s.encounterEntities[
                    lastIndexInArray
                ];
            }
            // Pop the last value
            s.encounterEntities.pop();
        }

        // ABI Encode all native types of the struct
        _emitSetBytes(entity, abi.encode(s.encounterEntities));
    }

    /**
     * Batch sets the typed value for this component
     *
     * @param entities Entity to batch set values for
     * @param values Layout to set for the given entities
     */
    function batchSetValue(
        uint256[] calldata entities,
        Layout[] calldata values
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        if (entities.length != values.length) {
            revert InvalidBatchData(entities.length, values.length);
        }

        // Set the values in storage
        bytes[] memory encodedValues = new bytes[](entities.length);
        for (uint256 i = 0; i < entities.length; i++) {
            _setValueToStorage(entities[i], values[i]);
            encodedValues[i] = _getEncodedValues(values[i]);
        }

        // ABI Encode all native types of the struct
        _emitBatchSetBytes(entities, encodedValues);
    }

    /**
     * Returns the typed value for this component
     *
     * @param entity Entity to get value for
     * @return value Layout value for the given entity
     */
    function getLayoutValue(
        uint256 entity
    ) external view virtual returns (Layout memory value) {
        // Get the struct from storage
        value = CombatMapComponentStorage.layout().entityIdToStruct[entity];
    }

    /**
     * Returns the native values for this component
     *
     * @param entity Entity to get value for
     * @return encounterEntities Entity IDs of the encounters in this map
     */
    function getValue(
        uint256 entity
    ) external view virtual returns (uint256[] memory encounterEntities) {
        if (has(entity)) {
            Layout memory s = CombatMapComponentStorage
                .layout()
                .entityIdToStruct[entity];
            (encounterEntities) = abi.decode(_getEncodedValues(s), (uint256[]));
        }
    }

    /**
     * Returns an array of byte values for each field of this component.
     *
     * @param entity Entity to build array of byte values for.
     */
    function getByteValues(
        uint256 entity
    ) external view virtual returns (bytes[] memory values) {
        // Get the struct from storage
        Layout storage s = CombatMapComponentStorage.layout().entityIdToStruct[
            entity
        ];

        // ABI Encode all fields of the struct and add to values array
        values = new bytes[](1);
        values[0] = abi.encode(s.encounterEntities);
    }

    /**
     * Returns the bytes value for this component
     *
     * @param entity Entity to get value for
     */
    function getBytes(
        uint256 entity
    ) external view returns (bytes memory value) {
        Layout memory s = CombatMapComponentStorage.layout().entityIdToStruct[
            entity
        ];
        value = _getEncodedValues(s);
    }

    /**
     * Sets the value of this component using a byte array
     *
     * @param entity Entity to set value for
     */
    function setBytes(
        uint256 entity,
        bytes calldata value
    ) external onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout memory s = CombatMapComponentStorage.layout().entityIdToStruct[
            entity
        ];
        (s.encounterEntities) = abi.decode(value, (uint256[]));
        _setValueToStorage(entity, s);

        // ABI Encode all native types of the struct
        _emitSetBytes(entity, value);
    }

    /**
     * Remove the given entity from this component.
     *
     * @param entity Entity to remove from this component.
     */
    function remove(
        uint256 entity
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        // Remove the entity from the component
        delete CombatMapComponentStorage.layout().entityIdToStruct[entity];
        _emitRemoveBytes(entity);
    }

    /**
     * Batch remove the given entities from this component.
     *
     * @param entities Entities to remove from this component.
     */
    function batchRemove(
        uint256[] calldata entities
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        // Remove the entities from the component
        for (uint256 i = 0; i < entities.length; i++) {
            delete CombatMapComponentStorage.layout().entityIdToStruct[
                entities[i]
            ];
        }
        _emitBatchRemoveBytes(entities);
    }

    /**
     * Check whether the given entity has a value in this component.
     *
     * @param entity Entity to check whether it has a value in this component for.
     */
    function has(uint256 entity) public view virtual returns (bool) {
        return gameRegistry.getEntityHasComponent(entity, ID);
    }

    /** INTERNAL **/

    function _setValueToStorage(uint256 entity, Layout memory value) internal {
        Layout storage s = CombatMapComponentStorage.layout().entityIdToStruct[
            entity
        ];

        s.encounterEntities = value.encounterEntities;
    }

    function _setValue(uint256 entity, Layout memory value) internal {
        _setValueToStorage(entity, value);

        // ABI Encode all native types of the struct
        _emitSetBytes(entity, abi.encode(value.encounterEntities));
    }

    function _getEncodedValues(
        Layout memory value
    ) internal pure returns (bytes memory) {
        return abi.encode(value.encounterEntities);
    }
}

// SPDX-License-Identifier: MIT
// Auto-generated using Mage CLI codegen (v1) - DO NOT EDIT

pragma solidity ^0.8.13;

import {TypesLibrary} from "../../core/TypesLibrary.sol";
import {BaseStorageComponentV2, IBaseStorageComponentV2} from "../../core/components/BaseStorageComponentV2.sol";
import {GAME_LOGIC_CONTRACT_ROLE} from "../../Constants.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.gauntletschedulecomponent.dev1")
);

struct Layout {
    uint256[] mapEntities;
    uint32[] startTimestamps;
    uint32[] endTimestamps;
}

library GauntletScheduleComponentStorage {
    bytes32 internal constant STORAGE_SLOT = bytes32(ID);

    // Declare struct for mapping entity to struct
    struct InternalLayout {
        mapping(uint256 => Layout) entityIdToStruct;
    }

    function layout()
        internal
        pure
        returns (InternalLayout storage dataStruct)
    {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            dataStruct.slot := position
        }
    }
}

/**
 * @title GauntletScheduleComponent
 * @dev The schedule for all gauntlet maps
 */
contract GauntletScheduleComponent is BaseStorageComponentV2 {
    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(
        address gameRegistryAddress
    ) BaseStorageComponentV2(gameRegistryAddress, ID) {
        // Do nothing
    }

    /**
     * @inheritdoc IBaseStorageComponentV2
     */
    function getSchema()
        public
        pure
        override
        returns (string[] memory keys, TypesLibrary.SchemaValue[] memory values)
    {
        keys = new string[](3);
        values = new TypesLibrary.SchemaValue[](3);

        // Entity for the gauntlet map to run
        keys[0] = "map_entities";
        values[0] = TypesLibrary.SchemaValue.UINT256_ARRAY;

        // Encounter start timestamps
        keys[1] = "start_timestamps";
        values[1] = TypesLibrary.SchemaValue.UINT32_ARRAY;

        // Encounter end timestamps
        keys[2] = "end_timestamps";
        values[2] = TypesLibrary.SchemaValue.UINT32_ARRAY;
    }

    /**
     * Sets the typed value for this component
     *
     * @param entity Entity to get value for
     * @param value Layout to set for the given entity
     */
    function setLayoutValue(
        uint256 entity,
        Layout calldata value
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _setValue(entity, value);
    }

    /**
     * Sets the native value for this component
     *
     * @param entity Entity to get value for
     * @param mapEntities Entity for the gauntlet map to run
     * @param startTimestamps Encounter start timestamps
     * @param endTimestamps Encounter end timestamps
     */
    function setValue(
        uint256 entity,
        uint256[] memory mapEntities,
        uint32[] memory startTimestamps,
        uint32[] memory endTimestamps
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _setValue(entity, Layout(mapEntities, startTimestamps, endTimestamps));
    }

    /**
     * Appends to the components.
     *
     * @param entity Entity to get value for
     * @param values Layout to set for the given entity
     */
    function append(
        uint256 entity,
        Layout memory values
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout storage s = GauntletScheduleComponentStorage
            .layout()
            .entityIdToStruct[entity];
        for (uint256 i = 0; i < values.mapEntities.length; i++) {
            s.mapEntities.push(values.mapEntities[i]);
            s.startTimestamps.push(values.startTimestamps[i]);
            s.endTimestamps.push(values.endTimestamps[i]);
        }

        // ABI Encode all native types of the struct
        _emitSetBytes(
            entity,
            abi.encode(s.mapEntities, s.startTimestamps, s.endTimestamps)
        );
    }

    /**
     * @dev Removes the values at a set of given indexes
     * @param entity Entity to get value for
     * @param indexes Indexes to remove
     */
    function removeValueAtIndexes(
        uint256 entity,
        uint256[] calldata indexes
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout storage s = GauntletScheduleComponentStorage
            .layout()
            .entityIdToStruct[entity];

        for (uint256 i = 0; i < indexes.length; i++) {
            uint256 indexToRemove = indexes[i];
            // Get the last index
            uint256 lastIndexInArray = s.mapEntities.length - 1;
            // Move the last value to the index to pop
            if (indexToRemove != lastIndexInArray) {
                s.mapEntities[indexToRemove] = s.mapEntities[lastIndexInArray];
                s.startTimestamps[indexToRemove] = s.startTimestamps[
                    lastIndexInArray
                ];
                s.endTimestamps[indexToRemove] = s.endTimestamps[
                    lastIndexInArray
                ];
            }
            // Pop the last value
            s.mapEntities.pop();
            s.startTimestamps.pop();
            s.endTimestamps.pop();
        }

        // ABI Encode all native types of the struct
        _emitSetBytes(
            entity,
            abi.encode(s.mapEntities, s.startTimestamps, s.endTimestamps)
        );
    }

    /**
     * Batch sets the typed value for this component
     *
     * @param entities Entity to batch set values for
     * @param values Layout to set for the given entities
     */
    function batchSetValue(
        uint256[] calldata entities,
        Layout[] calldata values
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        if (entities.length != values.length) {
            revert InvalidBatchData(entities.length, values.length);
        }

        // Set the values in storage
        bytes[] memory encodedValues = new bytes[](entities.length);
        for (uint256 i = 0; i < entities.length; i++) {
            _setValueToStorage(entities[i], values[i]);
            encodedValues[i] = _getEncodedValues(values[i]);
        }

        // ABI Encode all native types of the struct
        _emitBatchSetBytes(entities, encodedValues);
    }

    /**
     * Returns the typed value for this component
     *
     * @param entity Entity to get value for
     * @return value Layout value for the given entity
     */
    function getLayoutValue(
        uint256 entity
    ) external view virtual returns (Layout memory value) {
        // Get the struct from storage
        value = GauntletScheduleComponentStorage.layout().entityIdToStruct[
            entity
        ];
    }

    /**
     * Returns the native values for this component
     *
     * @param entity Entity to get value for
     * @return mapEntities Entity for the gauntlet map to run
     * @return startTimestamps Encounter start timestamps
     * @return endTimestamps Encounter end timestamps
     */
    function getValue(
        uint256 entity
    )
        external
        view
        virtual
        returns (
            uint256[] memory mapEntities,
            uint32[] memory startTimestamps,
            uint32[] memory endTimestamps
        )
    {
        if (has(entity)) {
            Layout memory s = GauntletScheduleComponentStorage
                .layout()
                .entityIdToStruct[entity];
            (mapEntities, startTimestamps, endTimestamps) = abi.decode(
                _getEncodedValues(s),
                (uint256[], uint32[], uint32[])
            );
        }
    }

    /**
     * Returns an array of byte values for each field of this component.
     *
     * @param entity Entity to build array of byte values for.
     */
    function getByteValues(
        uint256 entity
    ) external view virtual returns (bytes[] memory values) {
        // Get the struct from storage
        Layout storage s = GauntletScheduleComponentStorage
            .layout()
            .entityIdToStruct[entity];

        // ABI Encode all fields of the struct and add to values array
        values = new bytes[](3);
        values[0] = abi.encode(s.mapEntities);
        values[1] = abi.encode(s.startTimestamps);
        values[2] = abi.encode(s.endTimestamps);
    }

    /**
     * Returns the bytes value for this component
     *
     * @param entity Entity to get value for
     */
    function getBytes(
        uint256 entity
    ) external view returns (bytes memory value) {
        Layout memory s = GauntletScheduleComponentStorage
            .layout()
            .entityIdToStruct[entity];
        value = _getEncodedValues(s);
    }

    /**
     * Sets the value of this component using a byte array
     *
     * @param entity Entity to set value for
     */
    function setBytes(
        uint256 entity,
        bytes calldata value
    ) external onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout memory s = GauntletScheduleComponentStorage
            .layout()
            .entityIdToStruct[entity];
        (s.mapEntities, s.startTimestamps, s.endTimestamps) = abi.decode(
            value,
            (uint256[], uint32[], uint32[])
        );
        _setValueToStorage(entity, s);

        // ABI Encode all native types of the struct
        _emitSetBytes(entity, value);
    }

    /**
     * Remove the given entity from this component.
     *
     * @param entity Entity to remove from this component.
     */
    function remove(
        uint256 entity
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        // Remove the entity from the component
        delete GauntletScheduleComponentStorage.layout().entityIdToStruct[
            entity
        ];
        _emitRemoveBytes(entity);
    }

    /**
     * Batch remove the given entities from this component.
     *
     * @param entities Entities to remove from this component.
     */
    function batchRemove(
        uint256[] calldata entities
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        // Remove the entities from the component
        for (uint256 i = 0; i < entities.length; i++) {
            delete GauntletScheduleComponentStorage.layout().entityIdToStruct[
                entities[i]
            ];
        }
        _emitBatchRemoveBytes(entities);
    }

    /**
     * Check whether the given entity has a value in this component.
     *
     * @param entity Entity to check whether it has a value in this component for.
     */
    function has(uint256 entity) public view virtual returns (bool) {
        return gameRegistry.getEntityHasComponent(entity, ID);
    }

    /** INTERNAL **/

    function _setValueToStorage(uint256 entity, Layout memory value) internal {
        Layout storage s = GauntletScheduleComponentStorage
            .layout()
            .entityIdToStruct[entity];

        s.mapEntities = value.mapEntities;
        s.startTimestamps = value.startTimestamps;
        s.endTimestamps = value.endTimestamps;
    }

    function _setValue(uint256 entity, Layout memory value) internal {
        _setValueToStorage(entity, value);

        // ABI Encode all native types of the struct
        _emitSetBytes(
            entity,
            abi.encode(
                value.mapEntities,
                value.startTimestamps,
                value.endTimestamps
            )
        );
    }

    function _getEncodedValues(
        Layout memory value
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                value.mapEntities,
                value.startTimestamps,
                value.endTimestamps
            );
    }
}

// SPDX-License-Identifier: MIT
// Auto-generated using Mage CLI codegen (v1) - DO NOT EDIT

pragma solidity ^0.8.13;

import {TypesLibrary} from "../../core/TypesLibrary.sol";
import {BaseStorageComponentV2, IBaseStorageComponentV2} from "../../core/components/BaseStorageComponentV2.sol";
import {GAME_LOGIC_CONTRACT_ROLE} from "../../Constants.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.lootarraycomponent.v1")
);

struct Layout {
    uint32[] lootType;
    address[] tokenContract;
    uint256[] lootId;
    uint256[] amount;
}

library LootArrayComponentStorage {
    bytes32 internal constant STORAGE_SLOT = bytes32(ID);

    // Declare struct for mapping entity to struct
    struct InternalLayout {
        mapping(uint256 => Layout) entityIdToStruct;
    }

    function layout()
        internal
        pure
        returns (InternalLayout storage dataStruct)
    {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            dataStruct.slot := position
        }
    }
}

/**
 * @title LootArrayComponent
 * @dev Loot Array Component
 */
contract LootArrayComponent is BaseStorageComponentV2 {
    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(
        address gameRegistryAddress
    ) BaseStorageComponentV2(gameRegistryAddress, ID) {
        // Do nothing
    }

    /**
     * @inheritdoc IBaseStorageComponentV2
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

        // Id of the token to grant (ERC1155/LOOT TABLE only)
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
     * @param value Layout to set for the given entity
     */
    function setLayoutValue(
        uint256 entity,
        Layout calldata value
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _setValue(entity, value);
    }

    /**
     * Sets the native value for this component
     *
     * @param entity Entity to get value for
     * @param lootType Type of fulfillment (ERC721, ERC1155, ERC20, LOOT_TABLE)
     * @param tokenContract Contract to grant tokens from
     * @param lootId Id of the token to grant (ERC1155/LOOT TABLE only)
     * @param amount Amount of token to grant (XP, ERC20, ERC1155)
     */
    function setValue(
        uint256 entity,
        uint32[] memory lootType,
        address[] memory tokenContract,
        uint256[] memory lootId,
        uint256[] memory amount
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        _setValue(entity, Layout(lootType, tokenContract, lootId, amount));
    }

    /**
     * Appends to the components.
     *
     * @param entity Entity to get value for
     * @param values Layout to set for the given entity
     */
    function append(
        uint256 entity,
        Layout memory values
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout storage s = LootArrayComponentStorage.layout().entityIdToStruct[
            entity
        ];
        for (uint256 i = 0; i < values.lootType.length; i++) {
            s.lootType.push(values.lootType[i]);
            s.tokenContract.push(values.tokenContract[i]);
            s.lootId.push(values.lootId[i]);
            s.amount.push(values.amount[i]);
        }

        // ABI Encode all native types of the struct
        _emitSetBytes(
            entity,
            abi.encode(s.lootType, s.tokenContract, s.lootId, s.amount)
        );
    }

    /**
     * @dev Removes the values at a set of given indexes
     * @param entity Entity to get value for
     * @param indexes Indexes to remove
     */
    function removeValueAtIndexes(
        uint256 entity,
        uint256[] calldata indexes
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout storage s = LootArrayComponentStorage.layout().entityIdToStruct[
            entity
        ];

        for (uint256 i = 0; i < indexes.length; i++) {
            uint256 indexToRemove = indexes[i];
            // Get the last index
            uint256 lastIndexInArray = s.lootType.length - 1;
            // Move the last value to the index to pop
            if (indexToRemove != lastIndexInArray) {
                s.lootType[indexToRemove] = s.lootType[lastIndexInArray];
                s.tokenContract[indexToRemove] = s.tokenContract[
                    lastIndexInArray
                ];
                s.lootId[indexToRemove] = s.lootId[lastIndexInArray];
                s.amount[indexToRemove] = s.amount[lastIndexInArray];
            }
            // Pop the last value
            s.lootType.pop();
            s.tokenContract.pop();
            s.lootId.pop();
            s.amount.pop();
        }

        // ABI Encode all native types of the struct
        _emitSetBytes(
            entity,
            abi.encode(s.lootType, s.tokenContract, s.lootId, s.amount)
        );
    }

    /**
     * Batch sets the typed value for this component
     *
     * @param entities Entity to batch set values for
     * @param values Layout to set for the given entities
     */
    function batchSetValue(
        uint256[] calldata entities,
        Layout[] calldata values
    ) external virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        if (entities.length != values.length) {
            revert InvalidBatchData(entities.length, values.length);
        }

        // Set the values in storage
        bytes[] memory encodedValues = new bytes[](entities.length);
        for (uint256 i = 0; i < entities.length; i++) {
            _setValueToStorage(entities[i], values[i]);
            encodedValues[i] = _getEncodedValues(values[i]);
        }

        // ABI Encode all native types of the struct
        _emitBatchSetBytes(entities, encodedValues);
    }

    /**
     * Returns the typed value for this component
     *
     * @param entity Entity to get value for
     * @return value Layout value for the given entity
     */
    function getLayoutValue(
        uint256 entity
    ) external view virtual returns (Layout memory value) {
        // Get the struct from storage
        value = LootArrayComponentStorage.layout().entityIdToStruct[entity];
    }

    /**
     * Returns the native values for this component
     *
     * @param entity Entity to get value for
     * @return lootType Type of fulfillment (ERC721, ERC1155, ERC20, LOOT_TABLE)
     * @return tokenContract Contract to grant tokens from
     * @return lootId Id of the token to grant (ERC1155/LOOT TABLE only)
     * @return amount Amount of token to grant (XP, ERC20, ERC1155)
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
            Layout memory s = LootArrayComponentStorage
                .layout()
                .entityIdToStruct[entity];
            (lootType, tokenContract, lootId, amount) = abi.decode(
                _getEncodedValues(s),
                (uint32[], address[], uint256[], uint256[])
            );
        }
    }

    /**
     * Returns an array of byte values for each field of this component.
     *
     * @param entity Entity to build array of byte values for.
     */
    function getByteValues(
        uint256 entity
    ) external view virtual returns (bytes[] memory values) {
        // Get the struct from storage
        Layout storage s = LootArrayComponentStorage.layout().entityIdToStruct[
            entity
        ];

        // ABI Encode all fields of the struct and add to values array
        values = new bytes[](4);
        values[0] = abi.encode(s.lootType);
        values[1] = abi.encode(s.tokenContract);
        values[2] = abi.encode(s.lootId);
        values[3] = abi.encode(s.amount);
    }

    /**
     * Returns the bytes value for this component
     *
     * @param entity Entity to get value for
     */
    function getBytes(
        uint256 entity
    ) external view returns (bytes memory value) {
        Layout memory s = LootArrayComponentStorage.layout().entityIdToStruct[
            entity
        ];
        value = _getEncodedValues(s);
    }

    /**
     * Sets the value of this component using a byte array
     *
     * @param entity Entity to set value for
     */
    function setBytes(
        uint256 entity,
        bytes calldata value
    ) external onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        Layout memory s = LootArrayComponentStorage.layout().entityIdToStruct[
            entity
        ];
        (s.lootType, s.tokenContract, s.lootId, s.amount) = abi.decode(
            value,
            (uint32[], address[], uint256[], uint256[])
        );
        _setValueToStorage(entity, s);

        // ABI Encode all native types of the struct
        _emitSetBytes(entity, value);
    }

    /**
     * Remove the given entity from this component.
     *
     * @param entity Entity to remove from this component.
     */
    function remove(
        uint256 entity
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        // Remove the entity from the component
        delete LootArrayComponentStorage.layout().entityIdToStruct[entity];
        _emitRemoveBytes(entity);
    }

    /**
     * Batch remove the given entities from this component.
     *
     * @param entities Entities to remove from this component.
     */
    function batchRemove(
        uint256[] calldata entities
    ) public virtual onlyRole(GAME_LOGIC_CONTRACT_ROLE) {
        // Remove the entities from the component
        for (uint256 i = 0; i < entities.length; i++) {
            delete LootArrayComponentStorage.layout().entityIdToStruct[
                entities[i]
            ];
        }
        _emitBatchRemoveBytes(entities);
    }

    /**
     * Check whether the given entity has a value in this component.
     *
     * @param entity Entity to check whether it has a value in this component for.
     */
    function has(uint256 entity) public view virtual returns (bool) {
        return gameRegistry.getEntityHasComponent(entity, ID);
    }

    /** INTERNAL **/

    function _setValueToStorage(uint256 entity, Layout memory value) internal {
        Layout storage s = LootArrayComponentStorage.layout().entityIdToStruct[
            entity
        ];

        s.lootType = value.lootType;
        s.tokenContract = value.tokenContract;
        s.lootId = value.lootId;
        s.amount = value.amount;
    }

    function _setValue(uint256 entity, Layout memory value) internal {
        _setValueToStorage(entity, value);

        // ABI Encode all native types of the struct
        _emitSetBytes(
            entity,
            abi.encode(
                value.lootType,
                value.tokenContract,
                value.lootId,
                value.amount
            )
        );
    }

    function _getEncodedValues(
        Layout memory value
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                value.lootType,
                value.tokenContract,
                value.lootId,
                value.amount
            );
    }
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

import {IGameItems} from "../tokens/gameitems/IGameItems.sol";
import {IGameCurrency} from "../tokens/IGameCurrency.sol";
import {ILootSystem} from "../loot/ILootSystem.sol";
import "../libraries/GameRegistryLibrary.sol";

import {Layout as LootArray, LootArrayComponent} from "../generated/components/LootArrayComponent.sol";
import {Layout as LootArrayComponentStruct} from "../generated/components/LootArrayComponent.sol";

/**
 * Common helper functions for dealing with LootArrayComponents
 */
library LootArrayComponentLibrary {
    error InvalidInputs();

    /**
     * @dev Handle burning LootSetComponent inputs
     * @param account Account to burn the input fees from
     * @param inputLootSetId ID of the LootSetComponent that holds the input fees
     */
    function handleBurningInputs(
        address lootSetComponent,
        address account,
        uint256 inputLootSetId
    ) internal {
        // Get the input loots
        LootArrayComponent component = LootArrayComponent(lootSetComponent);
        LootArray memory lootArrayStruct = component.getLayoutValue(
            inputLootSetId
        );
        // Revert if no entry loots found
        if (lootArrayStruct.lootType.length == 0) {
            revert InvalidInputs();
        }
        for (uint256 i = 0; i < lootArrayStruct.lootType.length; ++i) {
            if (
                lootArrayStruct.lootType[i] ==
                uint32(ILootSystem.LootType.ERC20)
            ) {
                // Burn amount of ERC20 tokens required to start this bounty
                IGameCurrency(lootArrayStruct.tokenContract[i]).burn(
                    account,
                    lootArrayStruct.amount[i]
                );
            } else if (
                lootArrayStruct.lootType[i] ==
                uint32(ILootSystem.LootType.ERC1155)
            ) {
                // Burn amount of ERC1155 tokens required to start this bounty
                IGameItems(lootArrayStruct.tokenContract[i]).burn(
                    account,
                    lootArrayStruct.lootId[i],
                    lootArrayStruct.amount[i]
                );
            }
        }
    }

    /**
     * @dev Converts an array of LootInput structs to arrays
     */
    function convertLootInputToArrays(
        GameRegistryLibrary.TokenPointer[] calldata items
    )
        internal
        pure
        returns (
            uint32[] memory lootType,
            address[] memory tokenContract,
            uint256[] memory lootId,
            uint256[] memory amount
        )
    {
        lootType = new uint32[](items.length);
        tokenContract = new address[](items.length);
        lootId = new uint256[](items.length);
        amount = new uint256[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            lootType[i] = uint32(items[i].tokenType);
            tokenContract[i] = items[i].tokenContract;
            lootId[i] = items[i].tokenId;
            amount[i] = items[i].amount;
        }
    }

    /**
     * @dev Converts an array of ILootSystem.Loot to arrays
     */
    function convertLootToArrays(
        ILootSystem.Loot[] calldata items
    )
        internal
        pure
        returns (
            uint32[] memory lootType,
            address[] memory tokenContract,
            uint256[] memory lootId,
            uint256[] memory amount
        )
    {
        lootType = new uint32[](items.length);
        tokenContract = new address[](items.length);
        lootId = new uint256[](items.length);
        amount = new uint256[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            lootType[i] = uint32(items[i].lootType);
            tokenContract[i] = items[i].tokenContract;
            lootId[i] = items[i].lootId;
            amount[i] = items[i].amount;
        }
    }

    /**
     * @dev Converts an array of ILootSystem.Loot to arrays
     * Note: Quick hack to unblock.
     */
    function convertMemoryLootToArrays(
        ILootSystem.Loot[] memory items
    )
        internal
        pure
        returns (
            uint32[] memory lootType,
            address[] memory tokenContract,
            uint256[] memory lootId,
            uint256[] memory amount
        )
    {
        lootType = new uint32[](items.length);
        tokenContract = new address[](items.length);
        lootId = new uint256[](items.length);
        amount = new uint256[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            lootType[i] = uint32(items[i].lootType);
            tokenContract[i] = items[i].tokenContract;
            lootId[i] = items[i].lootId;
            amount[i] = items[i].amount;
        }
    }

    /**
     * @dev Converts LootArrayComponent to LootSystem Loot array
     */
    function convertLootArrayToLootSystem(
        address lootArrayComponent,
        uint256 lootArrayComponentId
    ) internal view returns (ILootSystem.Loot[] memory) {
        // Get the LootArray component values using the LootSetComponent Id
        LootArrayComponent component = LootArrayComponent(lootArrayComponent);
        LootArrayComponentStruct memory lootArrayStruct = component
            .getLayoutValue(lootArrayComponentId);
        // Convert them to an ILootSystem.Loot array
        ILootSystem.Loot[] memory loot = new ILootSystem.Loot[](
            lootArrayStruct.lootType.length
        );
        for (uint256 i = 0; i < lootArrayStruct.lootType.length; i++) {
            loot[i] = ILootSystem.Loot(
                ILootSystem.LootType(lootArrayStruct.lootType[i]),
                lootArrayStruct.tokenContract[i],
                lootArrayStruct.lootId[i],
                lootArrayStruct.amount[i]
            );
        }
        return loot;
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

import {TokenURITrait} from "../interfaces/ITraitsProvider.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.tokentemplatesystem")
);

/**
 * @title Interface to access token template system
 */
interface ITokenTemplateSystem {
    /**
     * @return Whether or not a template has been defined yet
     *
     * @param templateId    TemplateId to check
     */
    function exists(uint256 templateId) external view returns (bool);

    /**
     * Sets a template for a given token
     *
     * @param tokenContract Token contract to set template for
     * @param tokenId       Token id to set template for
     * @param templateId    Id of the template to set
     */
    function setTemplate(
        address tokenContract,
        uint256 tokenId,
        uint256 templateId
    ) external;

    /**
     * @return Returns the template token for the given token contract/token id, if it exists
     *
     * @param tokenContract Token to get the template for
     * @param tokenId to get the template for
     */
    function getTemplate(
        address tokenContract,
        uint256 tokenId
    ) external view returns (address, uint256);

    /**
     * Generates a token URI for a given token that inherits traits from its templates
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURI(
        address tokenContract,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * Generates a token URI for a given token that inherits traits from its templates
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     * @param extraTraits       Dyanmically generated traits to add on to the generated url
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURIWithExtra(
        address tokenContract,
        uint256 tokenId,
        TokenURITrait[] memory extraTraits
    ) external view returns (string memory);

    /**
     * Returns whether or not the given token has a trait recursively
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
     * Returns the trait data for a given token and checks the templates
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Trait value as abi-encoded bytes
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.accountxpsystem"));

/// @title Interface for the AccountXpSystem that grants Account Xp for completing actions
interface IAccountXpSystem {
    function grantAccountXp(
        uint256 actionEntityId,
        uint256 entityToGrant
    ) external;

    function getAccountXp(
        uint256 accountEntity
    ) external view returns (uint256);

    function getPlayerAccountLevel(
        uint256 accountEntity
    ) external view returns (uint256);

    function convertAccountXpToLevel(
        uint256 accountXp
    ) external view returns (uint256);
}