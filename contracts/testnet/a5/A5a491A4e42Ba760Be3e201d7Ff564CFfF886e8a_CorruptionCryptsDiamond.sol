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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

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
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
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
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
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
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
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
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
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
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
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
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
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
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
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
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
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
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
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
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
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
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
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
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
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
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
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
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
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
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
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
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
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
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
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
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
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
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
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
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
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
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
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
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
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
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
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
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
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
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
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
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
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
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "../math/SafeCast.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
 * used in storage, and not in memory.
 * ```
 * DoubleEndedQueue.Bytes32Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library DoubleEndedQueue {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct Bytes32Deque {
        int128 _begin;
        int128 _end;
        mapping(int128 => bytes32) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(Bytes32Deque storage deque, bytes32 value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(Bytes32Deque storage deque, bytes32 value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(Bytes32Deque storage deque, uint256 index) internal view returns (bytes32 value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(Bytes32Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(Bytes32Deque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(Bytes32Deque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import "solmate/src/utils/FixedPointMathLib.sol";
import "./CorruptionCryptsDiamondState.sol";



contract CorruptionCryptsDiamond is CorruptionCryptsDiamondState {
    modifier onlyValidLegionSquadAndLegionSquadOwner(
        address _user,
        uint64 _legionSquadId
    ) {
        require(legionSquadIdToLegionSquadInfo[_legionSquadId].owner == _user && legionSquadIdToLegionSquadInfo[_legionSquadId].exists,"You don't own this legion squad!");
        _;
    }

    function updateConfig(GameConfig memory _gameConfig) public onlyAdminOrOwner {
        gameConfig = _gameConfig;

        emit ConfigUpdated(_gameConfig);
    }

    function generateTempleCoordinate(uint256 _index)
        internal
        view
        returns (Coordinate memory)
    {
        uint256 _globalSeed = randomizer.revealRandomNumber(globalRequestId);

        //Generate a new seed from the global seed and the index of the current temple.
        uint256 localSeed = uint256(
            keccak256(abi.encodePacked(_globalSeed, _index))
        );

        //Decide what border it will sit on
        //For this randomness concat the local seed with 1
        uint256 border = generateRandomNumber(
            0,
            3,
            uint256(keccak256(abi.encodePacked(localSeed, uint256(1))))
        );

        //Now that you have a border, make new randomness with the number 2
        uint256 seed = uint256(
            keccak256(abi.encodePacked(localSeed, uint256(2)))
        );

        Coordinate memory thisCoordinate;

        if (border == 0)
            thisCoordinate = Coordinate(
                uint8(generateRandomNumber(0, 15, seed)),
                0
            );
        if (border == 1)
            thisCoordinate = Coordinate(
                15,
                uint8(generateRandomNumber(0, 9, seed))
            );
        if (border == 2)
            thisCoordinate = Coordinate(
                uint8(generateRandomNumber(0, 15, seed)),
                9
            );
        if (border == 3)
            thisCoordinate = Coordinate(
                0,
                uint8(generateRandomNumber(0, 9, seed))
            );

        return thisCoordinate;
    }

    function generateTemplePositions() public view returns (Temple[] memory) {
        uint256 _quantity = gameConfig.templeCount;

        Temple[] memory _temples = new Temple[](_quantity);

        bool[10][16] memory usedCoordinates;

        for (uint256 i = 0; i < _quantity; i++) {
            bool generated = false;
            while (!generated) {
                Coordinate memory thisCoordinate = generateTempleCoordinate(i);
                if (!usedCoordinates[thisCoordinate.x][thisCoordinate.y]) {
                    usedCoordinates[thisCoordinate.x][thisCoordinate.y] = true;
                    generated = true;
                    _temples[i] = Temple(thisCoordinate, uint8(i), true);
                }
            }
        }

        return _temples;
    }

    function generateBoardTreasure()
        public
        view
        returns (BoardTreasure memory)
    {
        //Generate coordinate
        //Generate affinity
        //Num claimed and maxSupply persist.
        BoardTreasure memory _boardTreasure = boardTreasure;

        uint256 _globalSeed = randomizer.revealRandomNumber(globalRequestId);

        uint8 x = uint8(
            generateRandomNumber(
                0,
                15,
                uint256(keccak256(abi.encodePacked(_globalSeed, "treasuresx")))
            )
        );
        uint8 y = uint8(
            generateRandomNumber(
                0,
                9,
                uint256(keccak256(abi.encodePacked(_globalSeed, "treasuresy")))
            )
        );

        uint8 affinity = uint8(
            generateRandomNumber(
                0,
                2,
                uint256(
                    keccak256(abi.encodePacked(_globalSeed, "treasureaffinity"))
                )
            )
        );

        _boardTreasure.coordinate = Coordinate(x, y);
        _boardTreasure.affinity = affinity;
        _boardTreasure.correspondingId = (_boardTreasure.affinity *
            (_boardTreasure.treasureTier));

        return _boardTreasure;
    }

    function generateMapTiles(uint256 _quantity, address _user)
        internal
        view
        returns (MapTile[] memory)
    {
        //Create in memory static array of length _quantity
        MapTile[] memory mapTilesReturn = new MapTile[](_quantity);

        uint256 localSeed;
        uint256 userRequestId = addressToUserData[_user].requestId;

        if (userRequestId == 0) {
            //Not seeded
            //Generate them Psuedo Random Number based on the very first seed, their address, and an arbitrary string.
            uint256 startingSeed = randomizer.revealRandomNumber(
                globalStartingRequestId
            );

            localSeed = uint256(
                keccak256(abi.encodePacked(startingSeed, _user, "mapTiles"))
            );
        } else {
            //Has been seeded
            //Get the seed
            //Might revert.
            localSeed = randomizer.revealRandomNumber(userRequestId);
        }

        for (uint256 i = 0; i < _quantity; i++) {
            //Generate a seed with the nonce and index of map tile.
            uint256 _seed = uint256(keccak256(abi.encodePacked(localSeed, i)));

            //Generate a random number from 0 - 35 and choose that mapTile.
            mapTilesReturn[i] = mapTiles[
                uint8(generateRandomNumber(0, 35, _seed))
            ];

            //Convert the seed into its uint32 counterpart, however modulo by uint32 ceiling so as to not always get 2^32
            //Overwrite the prevoius mapTileId with this new Id.
            mapTilesReturn[i].mapTileId = uint32(
                uint256(keccak256(abi.encodePacked(_seed, "1"))) % (2**32)
            );
        }

        return mapTilesReturn;
    }

    function generateRandomNumber(
        uint256 _min,
        uint256 _max,
        uint256 _seed
    ) internal pure returns (uint256) {
        return _min + (_seed % (_max + 1 - _min));
    }

    function calculateNumPendingMapTiles(address _user)
        internal
        view
        returns (uint256)
    {
        //Pull the last epoch within the current round that this user claimed.
        uint256 lastEpochClaimed = addressToUserData[_user].roundIdToEpochLastClaimedMapTiles[currentRoundId];
        

        //Calculate epochs passed by subtracting the last epoch claimed from the current epoch.
        uint256 epochsPassed = currentEpoch() - lastEpochClaimed;

        //If the number of epochs passed is greater than the maximum map tiles you can hold.
        //Else return the epochs passed.
        uint256 numMapTilesToClaim = epochsPassed > gameConfig.maxMapTilesInHand
            ? gameConfig.maxMapTilesInHand
            : epochsPassed;

        return numMapTilesToClaim;
    }

    function currentEpoch() internal view returns (uint256) {
        uint256 secondsSinceRoundStart = block.timestamp - roundStartTime;
        uint256 epochsSinceRoundStart = secondsSinceRoundStart / gameConfig.secondsInEpoch;
        return (epochsSinceRoundStart);
    }

    function startGame() public onlyAdminOrOwner {
        require(currentRoundId == 0, "Game already started");

        uint256 _startingRequestId = randomizer.requestRandomNumber();

        //Set the starting seed.
        globalStartingRequestId = _startingRequestId;

        //Set the current global request Id.
        globalRequestId = _startingRequestId;

        //Increment round
        currentRoundId = 1;

        //Set round start time to now.
        roundStartTime = block.timestamp;

        emit GlobalRandomnessRequested(globalRequestId, currentRoundId);
    }

    function advanceRound() internal {

        //Request new global randomness.
        globalRequestId = randomizer.requestRandomNumber();
        emit GlobalRandomnessRequested(globalRequestId, currentRoundId);

        //Increment round
        currentRoundId++;

        //Set num claimed to 0 for the board treasure.
        boardTreasure.numClaimed = 0;

        //Reset how many legions have reached the temple.
        numLegionsReachedTemple = 0;

        //Set round start time to now.
        roundStartTime = block.timestamp;
    }

    function claimMapTiles(address _user) internal {
        //How many are in hand
        uint256 currentMapTilesInHand = addressToUserData[_user].mapTilesInHand.length;

        //Maximum that can fit in current hand
        uint256 maxCanClaim = gameConfig.maxMapTilesInHand - currentMapTilesInHand;

        //How much total are pending
        uint256 numPendingMapTiles = calculateNumPendingMapTiles(_user);

        //How many of the pending to claim (that can fit)
        uint256 numToClaim = numPendingMapTiles > maxCanClaim
            ? maxCanClaim
            : numPendingMapTiles;

        //How many epochs to reimburse (if any)
        uint256 epochsToReimburse = numPendingMapTiles - numToClaim;

        //Set lastClaimed epoch and subtract reimbursements.
        addressToUserData[_user].roundIdToEpochLastClaimedMapTiles[currentRoundId] =
            currentEpoch() -
            epochsToReimburse;

        //Generate an array randomly of map tiles to add.
        MapTile[] memory mapTilesToAdd = generateMapTiles(numToClaim, _user);

        for (uint256 i = 0; i < numToClaim; i++) {
            //Loop through array of map tiles.
            MapTile memory thisMapTile = mapTilesToAdd[i];

            //Push their map tile into their hand.
            addressToUserData[_user].mapTilesInHand.push(thisMapTile);
        }

        //Emit event from subgraph
        emit MapTilesClaimed(_user, mapTilesToAdd, currentRoundId);
    }

    function removeMapTileFromHandByIndexAndUser(uint256 _index, address _user)
        internal
    {
        //Load map tiles into memory
        MapTile[] storage mapTiles = addressToUserData[_user].mapTilesInHand;

        //Get the map tile that's at the end
        MapTile memory MapTileAtEnd = mapTiles[mapTiles.length - 1];

        //Overwrite the target index with the end map tile.
        addressToUserData[_user].mapTilesInHand[_index] = MapTileAtEnd;

        //Remove the final map tile
        addressToUserData[_user].mapTilesInHand.pop();
    }

    function getMapTileByIDAndUser(uint128 _mapTileid, address _user)
        internal
        view
        returns (MapTile memory, uint256)
    {
        //Load hand into memory.
        MapTile[] storage _mapTiles = addressToUserData[_user].mapTilesInHand;
        for (uint256 i = 0; i < _mapTiles.length; i++) {
            //If this is the mapTile.
            if (_mapTiles[i].mapTileId == _mapTileid)
                //Return it, and its index.
                return (_mapTiles[i], i);
        }

        //Revert if you cannot find.
        revert("User doesn't possess this tile.");
    }

    function placeMapTile(
        address _user,
        uint128 _mapTileId,
        Coordinate memory _coordinate
    ) internal {
        //Pull this cell into memory
        Cell memory thisCell = addressToUserData[_user].currentBoard[_coordinate.x][
            _coordinate.y
        ];

        //Require this cell has no map tile
        require(!thisCell.hasMapTile, "Already has map tile!");

        //Get this full map tile struct and index from storage.
        (MapTile memory thisMapTile, uint256 _index) = getMapTileByIDAndUser(
            _mapTileId,
            _user
        );

        //Delete this map tile from their hand.
        removeMapTileFromHandByIndexAndUser(_index, _user);

        //Overwrite the previous maptile on this cell, and record it as having a map tile. (empty)
        thisCell.mapTile = thisMapTile;
        thisCell.hasMapTile = true;

        //Store this cell on the board with adjusted data.
        addressToUserData[_user].currentBoard[_coordinate.x][_coordinate.y] = thisCell;

        //Store the coordinates on this map tile.
        addressToUserData[_user].mapTileIdToCoordinate[thisMapTile.mapTileId] = _coordinate;

        //Push this map tile into the front of the queue
        DoubleEndedQueue.pushFront(
            addressToUserData[_user].mapTilesOnBoard,
            bytes32(uint256(thisMapTile.mapTileId))
        );

        //Remove oldest maptile on board IF there are now 11 maptiles placed
        if (
            DoubleEndedQueue.length(addressToUserData[_user].mapTilesOnBoard) >
            gameConfig.maxMapTilesOnBoard
        ) {
            //Get the ID of the map tile you removed.
            uint32 removedMapTileId = uint32(
                uint256(DoubleEndedQueue.popBack(addressToUserData[_user].mapTilesOnBoard))
            );

            //Get the coordinates of the removed tile
            Coordinate
                memory coordinateOfRemovedMapTile = addressToUserData[_user].mapTileIdToCoordinate[removedMapTileId];

            addressToUserData[_user].currentBoard[coordinateOfRemovedMapTile.x][
                coordinateOfRemovedMapTile.y
            ].hasMapTile = false;
            addressToUserData[_user].currentBoard[coordinateOfRemovedMapTile.x][
                coordinateOfRemovedMapTile.y
            ].mapTile = MapTile(0, 0, 0, false, false, false, false);

            //If a legion squad is currently on this tile, revert.
            require(
                !addressToUserData[_user].currentBoard[coordinateOfRemovedMapTile.x][
                    coordinateOfRemovedMapTile.y
                ].hasLegionSquad,
                "Has legion squad!"
            );
        }

        //Emit event from subgraph
        emit MapTilePlaced(_user, thisMapTile, _coordinate, currentRoundId);
    }

    function decideMovabilityBasedOnTwoCoordinates(
        address _user,
        Coordinate memory _startingCoordinate,
        Coordinate memory _endingCoordinate
    ) internal view returns (bool) {
        Cell memory cell1 = addressToUserData[_user].currentBoard[_startingCoordinate.x][
            _startingCoordinate.y
        ];
        Cell memory cell2 = addressToUserData[_user].currentBoard[_endingCoordinate.x][
            _endingCoordinate.y
        ];

        require(cell2.hasMapTile, "Desired cell has no maptile.");

        MapTile memory startingMapTile = cell1.mapTile;
        MapTile memory endingMapTile = cell2.mapTile;

        if (_endingCoordinate.x < _startingCoordinate.x) {
            //Going left (x decreasing)
            require(
                _startingCoordinate.x - 1 == _endingCoordinate.x &&
                    _startingCoordinate.y == _endingCoordinate.y,
                "E cordinate movement invalid."
            );
            if (startingMapTile.west && endingMapTile.east) return true;
        }

        if (_endingCoordinate.x > _startingCoordinate.x) {
            //Going right (x increasing)
            require(
                _startingCoordinate.x + 1 == _endingCoordinate.x &&
                    _startingCoordinate.y == _endingCoordinate.y,
                "W coordinate movement invalid."
            );
            if (startingMapTile.east && endingMapTile.west) return true;
        }

        if (_endingCoordinate.y < _startingCoordinate.y) {
            //Going up (y decreasing)
            require(
                _startingCoordinate.x == _endingCoordinate.x &&
                    _startingCoordinate.y - 1 == _endingCoordinate.y,
                "N coordinate movement invalid."
            );
            if (startingMapTile.north && endingMapTile.south) return true;
        }

        if (_endingCoordinate.y > _startingCoordinate.y) {
            //Going down (y increasing)
            require(
                _startingCoordinate.x == _endingCoordinate.x &&
                    _startingCoordinate.y + 1 == _endingCoordinate.y,
                "S coordinate movement invalid."
            );
            if (startingMapTile.south && endingMapTile.north) return true;
        }

        revert("MapTiles are not connected");
    }

    function enterTemple(address _user, uint64 _legionSquadId)
        internal
        onlyValidLegionSquadAndLegionSquadOwner(_user, _legionSquadId)
    {
        //Pull this legion squad into memory.
        LegionSquadInfo memory _legionSquadInfo = legionSquadIdToLegionSquadInfo[_legionSquadId];

        uint8 _targetTemple = _legionSquadInfo.targetTemple;

        Temple[] memory _temples = generateTemplePositions();

        //Ensure they are on this temple.
        require(
            _temples[_targetTemple].coordinate.x == _legionSquadInfo.coordinate.x &&
                _temples[_targetTemple].coordinate.y ==
                _legionSquadInfo.coordinate.y,
            "Legion squad not at temple!"
        );

        //Ensure this is the temple they targeted.
        require(
            _legionSquadInfo.targetTemple == _targetTemple,
            "This was not the temple you targeted!"
        );

        require(!_legionSquadInfo.inTemple, "Legion squad already in temple.");

        //Record they entered a temple in this round
        legionSquadIdToLegionSquadInfo[_legionSquadId].lastRoundEnteredTemple = uint32(currentRoundId);

        //Record them as being in a temple.
        legionSquadIdToLegionSquadInfo[_legionSquadId].inTemple = true;

        //add this many legions as finished
        numLegionsReachedTemple += _legionSquadInfo.legionIds.length;

        if (numLegionsReachedTemple >= gameConfig.numLegionsReachedTempleToAdvanceRound)
            advanceRound();

        emit TempleEntered(
            _user,
            _legionSquadId,
            _targetTemple,
            currentRoundId
        );
    }

    function moveLegionSquad(
        address _user,
        uint64 _legionSquadId,
        uint128 _mapTileIdToBurn,
        Coordinate memory _startingCoordinate,
        Coordinate[] memory _coordinates
    ) internal onlyValidLegionSquadAndLegionSquadOwner(_user, _legionSquadId) {
        //This reverts if they do not have the tile.
        //Get this full map tile struct and index from storage.
        (MapTile memory thisMapTile, uint256 _index) = getMapTileByIDAndUser(
            _mapTileIdToBurn,
            _user
        );

        LegionSquadInfo memory _legionSquadInfo = legionSquadIdToLegionSquadInfo[_legionSquadId];

        removeMapTileFromHandByIndexAndUser(_index, _user);

        //If they are in a temple, check if they entered in this round or a previous round
        if (_legionSquadInfo.inTemple) {
            //If they entered this round, revert.
            require(
                currentRoundId ==_legionSquadInfo.lastRoundEnteredTemple,
                "Have already entered a temple this round!"
            );

            //If it was a different round, set them as not being in a temple.
            legionSquadIdToLegionSquadInfo[_legionSquadId].inTemple = false;
        }

        //Require the moves on the maptile eq or gt coordinates length
        require(
            thisMapTile.moves >= _coordinates.length,
            "Not enough moves on this map tile!"
        );

        //Require Legion squad on coordinate
        require(
            addressToUserData[_user].currentBoard[_startingCoordinate.x][_startingCoordinate.y]
                .hasLegionSquad &&
                addressToUserData[_user].currentBoard[_startingCoordinate.x][
                    _startingCoordinate.y
                ].legionSquadId ==
                _legionSquadId,
            "Legion squad not on this coordinate!"
        );

        //Require initial cell and first move are legal.
        require(
            decideMovabilityBasedOnTwoCoordinates(
                _user,
                _startingCoordinate,
                _coordinates[0]
            )
        );

        //If they claimed this round, don't try and find out if they can.
        bool hasClaimedTreasure = (
            _legionSquadInfo.mostRecentRoundTreasureClaimed ==
                currentRoundId
                ? true
                : false
        );

        BoardTreasure memory _boardTreasure = generateBoardTreasure();

        for (uint256 i = 0; i < _coordinates.length - 1; i++) {
            //Require i coordinate and i + 1 coordinate are legal.
            require(
                decideMovabilityBasedOnTwoCoordinates(
                    _user,
                    _coordinates[i],
                    _coordinates[i + 1]
                )
            );

            //If they haven't claimed treasure, and they are on a treasure, claim it with a bypass.
            if (
                !hasClaimedTreasure &&
                (_coordinates[i].x == _boardTreasure.coordinate.x &&
                    _coordinates[i].y == _boardTreasure.coordinate.y)
            ) {
                hasClaimedTreasure = true;
                //Claim this treasure, with bypass true.
                claimTreasure(_user, _legionSquadId, true);
            }
        }
        //Remove legion from starting cell
        addressToUserData[_user].currentBoard[_startingCoordinate.x][_startingCoordinate.y]
            .hasLegionSquad = false;

        //Remove legion from starting cell
        addressToUserData[_user].currentBoard[_startingCoordinate.x][_startingCoordinate.y]
            .legionSquadId = 0;

        //Set this final cell as to having a legion squad
        addressToUserData[_user].currentBoard[_coordinates[_coordinates.length - 1].x][
            _coordinates[_coordinates.length - 1].y
        ].hasLegionSquad = true;

        //Set this final cell's legion id to the legion id
        addressToUserData[_user].currentBoard[_coordinates[_coordinates.length - 1].x][
            _coordinates[_coordinates.length - 1].y
        ].legionSquadId = _legionSquadId;

        //Set this legion squads location data to the final coordinate they submitted.
        legionSquadIdToLegionSquadInfo[_legionSquadId].coordinate = Coordinate(
            _coordinates[_coordinates.length - 1].x,
            _coordinates[_coordinates.length - 1].y
        );

        emit LegionSquadMoved(
            _user,
            _legionSquadId,
            Coordinate(
                _coordinates[_coordinates.length - 1].x,
                _coordinates[_coordinates.length - 1].y
            ),
            currentRoundId
        );
    }

    function claimTreasure(
        address _user,
        uint64 _legionSquadId,
        bool _bypassCoordinateCheck
    ) internal onlyValidLegionSquadAndLegionSquadOwner(_user, _legionSquadId) {
        BoardTreasure memory _boardTreasure = generateBoardTreasure();

        LegionSquadInfo memory _legionSquadInfo = legionSquadIdToLegionSquadInfo[_legionSquadId];

        //If this call is coming from a place that has already ensured they are allowed to claim it, bypass the coordinate check.
        //Not publically callable, so no chance of exploitation thru passing true when not allowed.
        if (!_bypassCoordinateCheck) {
            //Pull coordinate into memory.
            Coordinate memory _currentCoordinate = _legionSquadInfo.coordinate;

            //Require they are on the treasure.
            require(
                _currentCoordinate.x == _boardTreasure.coordinate.x &&
                    _currentCoordinate.y == _boardTreasure.coordinate.y,
                "You aren't on the treasure!"
            );
        }

        //Require max treasures haven't been claimed
        require(
            _boardTreasure.maxSupply > _boardTreasure.numClaimed,
            "Max treasures for this round claimed"
        );

        //Require they haven't claimed a fragment this round
        require(
            _legionSquadInfo.mostRecentRoundTreasureClaimed <
                currentRoundId,
            "You already claimed a treasure fragment in this round!"
        );

        //Record that they claimed this round
        legionSquadIdToLegionSquadInfo[_legionSquadId].mostRecentRoundTreasureClaimed = uint32(currentRoundId);

        //increment num claimed.
        boardTreasure.numClaimed++;

        treasureFragment.mint(_user, boardTreasure.correspondingId, 1);

        //emit event
        emit TreasureClaimed(
            _user,
            _legionSquadId,
            _boardTreasure,
            currentRoundId
        );
    }

    function removeLegionSquad(address _user, uint64 _legionSquadId)
        internal
        onlyValidLegionSquadAndLegionSquadOwner(_user, _legionSquadId)
    {
        
        LegionSquadInfo memory _legionSquadInfo = legionSquadIdToLegionSquadInfo[_legionSquadId];

        legionSquadIdToLegionSquadInfo[_legionSquadId].exists = false;


        //Set their cooldown to now plus cooldown time.
        addressToUserData[_user].cooldownEnd = uint64(block.timestamp) + gameConfig.legionUnstakeCooldown;

        addressToUserData[_user].currentBoard[_legionSquadInfo.coordinate.x][
            _legionSquadInfo.coordinate.y
        ].hasLegionSquad = false;

        //Loop their legions and set as unstaked.
        for (uint256 i = 0; i < _legionSquadInfo.legionIds.length; i++) {

            //Transfer it from the staking contract
            legionContract.adminSafeTransferFrom(
                address(this),
                _user,
                _legionSquadInfo.legionIds[i]
            );
        }

        emit LegionSquadRemoved(_user, _legionSquadId, currentRoundId);
    }

    function addLegionSquad(
        address _user,
        uint16[] memory _legionIds,
        uint256 _targetTemple,
        Coordinate memory _coordinate
    ) internal {
        require(
            _legionIds.length <= gameConfig.maximumLegionsInSquad,
            "Exceeds maximum legions in squad."
        );

        //Ensure they have less than X
        require(
            addressToUserData[_user].numberOfLegionSquadsOnBoard < gameConfig.maximumLegionSquadsOnBoard,
            "Already have maximum squads on field"
        );

        //Increment how many they have.
        addressToUserData[_user].numberOfLegionSquadsOnBoard++;

        //Require they are placing it >x distance from a temple.
        require(
            !withinDistanceOfTemple(_coordinate),
            "Placement is too close to a temple!"
        );

        //Ensure they own all the legions
        //Mark as staked
        for (uint256 i = 0; i < _legionIds.length; i++) {
            //Ensure they're not a recruit
            require(legionMetadataStore.metadataForLegion(_legionIds[i]).legionGeneration != LegionGeneration.RECRUIT, "Legion cannot be a recruit!");

            //Transfer it to the staking contract
            legionContract.adminSafeTransferFrom(
                _user,
                address(this),
                _legionIds[i]
            );
        }

        //Pull this cell into memory
        Cell memory thisCell = addressToUserData[_user].currentBoard[_coordinate.x][
            _coordinate.y
        ];

        //Ensure this cell does not have a legion squad
        require(!thisCell.hasLegionSquad, "Cell already has legion squad!");

        //Ensure map tiles exists here
        require(thisCell.hasMapTile, "This cell has no map tile");

        //Ensure they do not have staking cooldown
        require(
            block.timestamp >= addressToUserData[_user].cooldownEnd,
            "cooldown hasn't ended!"
        );

        //Ensure temple exists and is not being targeted by other squad this user owns
        require(templeIdToTemples[uint8(_targetTemple)].exists, "Temple does not exist!");

        uint64 thisLegionSquadId = legionSquadCurrentId;
        legionSquadCurrentId++;

        legionSquadIdToLegionSquadInfo[thisLegionSquadId] = LegionSquadInfo(
            msg.sender,
            thisLegionSquadId,
            0,
            0,
            _coordinate,
            uint8(_targetTemple),
            false,
            true,
            _legionIds
        );

        //Set cell to containing this legion squad id
        thisCell.legionSquadId = thisLegionSquadId;

        //Set cell to containing a legion squad
        thisCell.hasLegionSquad = true;

        //Store cell.
        addressToUserData[_user].currentBoard[_coordinate.x][_coordinate.y] = thisCell;

        //Increment legion squad current Id
        legionSquadCurrentId++;

        emit LegionSquadAdded(
            _user,
            thisLegionSquadId,
            _legionIds,
            currentRoundId,
            uint8(_targetTemple)
        );
    }

    function getDistance(
        uint256 x1,
        uint256 x2,
        uint256 y1,
        uint256 y2
    ) internal pure returns (uint256) {
        return
            FixedPointMathLib.sqrt(
                uint256((int256(x2) - int256(x1))**2) +
                    uint256((int256(y2) - int256(y1))**2)
            );
    }

    function withinDistanceOfTemple(Coordinate memory _coordinate)
        internal
        view
        returns (bool)
    {
        Temple[] memory _temples = generateTemplePositions();

        for (uint8 i = 0; i < gameConfig.templeCount; i++) {
            uint256 distance = getDistance(
                _coordinate.x,
                _temples[i].coordinate.x,
                _coordinate.y,
                _temples[i].coordinate.y
            );
            if (distance < gameConfig.minimumDistanceFromTempleForLegionSquad)
                return true;
        }

        return false;
    }

    function takeTurn(Move[] calldata _moves) public {
        bool claimedMapTiles;

        for (uint256 moveIndex = 0; moveIndex < _moves.length; moveIndex++) {
            Move calldata move = _moves[moveIndex];
            bytes calldata moveDataBytes = move.moveData;

            if (move.moveTypeId == MoveType.ClaimMapTiles) {
                claimMapTiles(msg.sender);
                claimedMapTiles = true;
                continue;
            }

            if (move.moveTypeId == MoveType.PlaceMapTile) {
                //Place map tile

                (uint32 _mapTileId, Coordinate memory _coordinate) = abi.decode(
                    moveDataBytes,
                    (uint32, Coordinate)
                );

                placeMapTile(msg.sender, _mapTileId, _coordinate);
                continue;
            }

            if (move.moveTypeId == MoveType.EnterTemple) {
                //Enter temple

                uint64 _legionSquadId = abi.decode(moveDataBytes, (uint64));

                enterTemple(msg.sender, _legionSquadId);

                continue;
            }

            if (move.moveTypeId == MoveType.MoveLegionSquad) {
                //Move legion squad

                (
                    uint64 _legionSquadId,
                    uint32 _mapTileId,
                    Coordinate memory _startingCoordinate,
                    Coordinate[] memory _coordinates
                ) = abi.decode(
                        moveDataBytes,
                        (uint64, uint32, Coordinate, Coordinate[])
                    );

                moveLegionSquad(
                    msg.sender,
                    _legionSquadId,
                    _mapTileId,
                    _startingCoordinate,
                    _coordinates
                );

                continue;
            }

            if (move.moveTypeId == MoveType.RemoveLegionSquad) {
                //Remove legion squad

                uint64 _legionSquadId = abi.decode(moveDataBytes, (uint64));

                removeLegionSquad(msg.sender, _legionSquadId);

                continue;
            }

            if (move.moveTypeId == MoveType.AddLegionSquad) {
                //Add legion squad

                (
                    uint16[] memory _legionIds,
                    uint8 _targetTemple,
                    Coordinate memory _coordinate
                ) = abi.decode(moveDataBytes, (uint16[], uint8, Coordinate));

                addLegionSquad(
                    msg.sender,
                    _legionIds,
                    _targetTemple,
                    _coordinate
                );
                continue;
            }

            if (move.moveTypeId == MoveType.ClaimTreasure) {
                //Claim Treasure

                uint64 _legionSquadId = abi.decode(moveDataBytes, (uint64));

                //Claim this treasure, with bypass false.
                claimTreasure(msg.sender, _legionSquadId, false);

                continue;
            }

            revert();
        }

        if (claimedMapTiles) {
            //If they claimed map tiles in this turn request a new random number.
            uint64 _requestId = uint64(randomizer.requestRandomNumber());

            //Store their request Id.
            addressToUserData[msg.sender].requestId = _requestId;
        }
    }


    function getPlayerMapTilesPending(address _user)
        public
        view
        returns (MapTile[] memory)
    {
        //How many are in hand
        uint256 currentMapTilesInHand = addressToUserData[_user].mapTilesInHand.length;

        //Maximum that can fit in current hand
        uint256 maxCanClaim = gameConfig.maxMapTilesInHand - currentMapTilesInHand;

        //How much total are pending
        uint256 numPendingMapTiles = calculateNumPendingMapTiles(_user);

        //How many of the pending to claim (that can fit)
        uint256 numToClaim = numPendingMapTiles > maxCanClaim
            ? maxCanClaim
            : numPendingMapTiles;

        //Generate an array randomly of map tiles to add.
        MapTile[] memory pendingMapTiles = generateMapTiles(numToClaim, _user);

        return pendingMapTiles;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import "../legionmetadatastore/ILegionMetadataStore.sol";
import "../treasurefragment/ITreasureFragment.sol";
import "../../shared/randomizer/IRandomizer.sol";
import "../../shared/AdminableUpgradeable.sol";
import "../legion/ILegion.sol";
import "./MapTiles.sol";
import "./Moves.sol";

struct Cell {
    //56 BITS.
    MapTile mapTile;
    //2 BITS
    bool hasMapTile;
    //64 BITS
    uint64 legionSquadId;
    //2 BITS
    bool hasLegionSquad;
}

struct LegionSquadInfo{
    //160 bites
    address owner;
    //64 bits
    uint64 legionSquadId;
    //32 bits
    uint32 lastRoundEnteredTemple;
    //32 bits
    uint32 mostRecentRoundTreasureClaimed;
    //16 bits
    Coordinate coordinate;
    //8 bits
    uint8 targetTemple;
    //8 bits
    bool inTemple;
    //8 bits
    bool exists;
    //224 bits left over
    //x * 16 bits
    uint16[] legionIds;
}

struct UserData {
    mapping(uint256 => uint256) roundIdToEpochLastClaimedMapTiles;
    mapping(uint32 => Coordinate) mapTileIdToCoordinate;

    DoubleEndedQueue.Bytes32Deque mapTilesOnBoard;
    Cell[10][16] currentBoard;
    MapTile[] mapTilesInHand;
    uint64 cooldownEnd;
    uint64 requestId;
    uint8 numberOfLegionSquadsOnBoard;
}

struct BoardTreasure {
    Coordinate coordinate;
    uint8 treasureTier;
    uint8 affinity;
    uint8 correspondingId;
    uint16 numClaimed;
    uint16 maxSupply;
}

struct Temple {
    Coordinate coordinate;
    uint8 templeId;
    bool exists;
}

struct StakingDetails {
    bool staked;
    address staker;
}

struct GameConfig {
    uint256 secondsInEpoch;
    uint256 numLegionsReachedTempleToAdvanceRound;
    uint256 maxMapTilesInHand;
    uint256 maxMapTilesOnBoard;
    uint256 maximumLegionSquadsOnBoard;
    uint256 maximumLegionsInSquad;
    uint256 templeCount;
    uint64 legionUnstakeCooldown;
    uint256 minimumDistanceFromTempleForLegionSquad;
}

abstract contract CorruptionCryptsDiamondState is Initializable, MapTiles, OwnableUpgradeable, AdminableUpgradeable  {
    //External Contracts
    IRandomizer public randomizer;
    ITreasureFragment public treasureFragment;
    ILegionMetadataStore public legionMetadataStore;
    ILegion public legionContract;

    //Global Structs
    BoardTreasure boardTreasure;
    GameConfig gameConfig;

    //Events
    event MapTilesClaimed(address _user, MapTile[] _maptiles, uint256 _roundId);
    event MapTilePlaced(
        address _user,
        MapTile _maptile,
        Coordinate _coordinate,
        uint256 _roundId
    );

    event TempleEntered(
        address _user,
        uint64 _legionSquadId,
        uint8 _targetTemple,
        uint256 _roundId
    );

    event LegionSquadMoved(
        address _user,
        uint64 _legionSquadId,
        Coordinate _finalCoordinate,
        uint256 _roundId
    );

    event LegionSquadAdded(
        address _user,
        uint64 _legionSquadId,
        uint16[] _legionIds,
        uint256 _roundId,
        uint8 _targetTemple
    );

    event LegionSquadRemoved(
        address _user,
        uint64 _legionSquadId,
        uint256 _roundId
    );

    //Emitted when requestGlobalRandomness() is called.
    event GlobalRandomnessRequested(uint256 _globalRequestId, uint256 _roundId);

    event TreasureClaimed(
        address _user,
        uint64 _legionSquadId,
        BoardTreasure _boardTreasure,
        uint256 _roundId
    );

    event ConfigUpdated(GameConfig _newConfig);

    //State variables

    //What round id this round is.
    uint256 public currentRoundId;

    //The timestamp that this round started at.
    uint256 roundStartTime;

    //How many legions have reached the temple this round.
    uint256 numLegionsReachedTemple;

    //Global seed (effects temples and treasures.).
    uint256 globalRequestId;

    //Record the first ever global seed (for future events like user first claiming map tiles.)
    uint256 globalStartingRequestId;

    //Current legion squad Id, increments up by one.
    uint64 legionSquadCurrentId;

    //Address to user data.
    mapping(address => UserData) addressToUserData;

    //Legion squad id to legion squad info.
    mapping(uint64 => LegionSquadInfo) legionSquadIdToLegionSquadInfo;

    //Record temple details.
    mapping(uint8 => Temple) templeIdToTemples;



}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

struct MapTile {
    //56 TOTAL BITS.
    uint32 mapTileId;
    uint8 mapTileType;
    uint8 moves;
    bool north;
    bool east;
    bool south;
    bool west;
    // directions of roads on each MapTile
}

contract MapTiles is Initializable {


    event MapTilesInitialized(MapTile[] _mapTiles);

    mapping(uint8 => MapTile) mapTiles;

    function initMapTiles() internal {
        // See https://boardgamegeek.com/image/3128699/karuba
        // for the tile road directions

        MapTile[] memory _mapTiles = new MapTile[](36);

        _mapTiles[0] = MapTile({
            mapTileId: 1,
            mapTileType: 1,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[1] = MapTile({
            mapTileId: 2,
            mapTileType: 2,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[2] = MapTile({
            mapTileId: 3,
            mapTileType: 3,
            moves: 2,
            north: false,
            east: true,
            south: true,
            west: false
        });
        _mapTiles[3] = MapTile({
            mapTileId: 4,
            mapTileType: 4,
            moves: 2,
            north: false,
            east: false,
            south: true,
            west: true
        });
        _mapTiles[4] = MapTile({
            mapTileId: 5,
            mapTileType: 5,
            moves: 3,
            north: false,
            east: true,
            south: true,
            west: true
        });
        _mapTiles[5] = MapTile({
            mapTileId: 6,
            mapTileType: 6,
            moves: 3,
            north: false,
            east: true,
            south: true,
            west: true
        });

        _mapTiles[6] = MapTile({
            mapTileId: 7,
            mapTileType: 7,
            moves: 4,
            north: true,
            east: true,
            south: true,
            west: true
        });
        _mapTiles[7] = MapTile({
            mapTileId: 8,
            mapTileType: 8,
            moves: 4,
            north: true,
            east: true,
            south: true,
            west: true
        });
        _mapTiles[8] = MapTile({
            mapTileId: 9,
            mapTileType: 9,
            moves: 2,
            north: true,
            east: true,
            south: false,
            west: false
        });
        _mapTiles[9] = MapTile({
            mapTileId: 10,
            mapTileType: 10,
            moves: 2,
            north: true,
            east: false,
            south: false,
            west: true
        });
        _mapTiles[10] = MapTile({
            mapTileId: 11,
            mapTileType: 11,
            moves: 3,
            north: true,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[11] = MapTile({
            mapTileId: 12,
            mapTileType: 12,
            moves: 3,
            north: true,
            east: true,
            south: false,
            west: true
        });

        _mapTiles[12] = MapTile({
            mapTileId: 13,
            mapTileType: 13,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[13] = MapTile({
            mapTileId: 14,
            mapTileType: 14,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[14] = MapTile({
            mapTileId: 15,
            mapTileType: 15,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[15] = MapTile({
            mapTileId: 16,
            mapTileType: 16,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[16] = MapTile({
            mapTileId: 17,
            mapTileType: 17,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[17] = MapTile({
            mapTileId: 18,
            mapTileType: 18,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });

        _mapTiles[18] = MapTile({
            mapTileId: 19,
            mapTileType: 19,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[19] = MapTile({
            mapTileId: 20,
            mapTileType: 20,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[20] = MapTile({
            mapTileId: 21,
            mapTileType: 21,
            moves: 2,
            north: false,
            east: true,
            south: true,
            west: false
        });
        _mapTiles[21] = MapTile({
            mapTileId: 22,
            mapTileType: 22,
            moves: 2,
            north: false,
            east: false,
            south: true,
            west: true
        });
        _mapTiles[22] = MapTile({
            mapTileId: 23,
            mapTileType: 23,
            moves: 3,
            north: true,
            east: true,
            south: true,
            west: false
        });
        _mapTiles[23] = MapTile({
            mapTileId: 24,
            mapTileType: 24,
            moves: 3,
            north: true,
            east: false,
            south: true,
            west: true
        });

        _mapTiles[24] = MapTile({
            mapTileId: 25,
            mapTileType: 25,
            moves: 4,
            north: true,
            east: true,
            south: true,
            west: true
        });
        _mapTiles[25] = MapTile({
            mapTileId: 26,
            mapTileType: 26,
            moves: 4,
            north: true,
            east: true,
            south: true,
            west: true
        });
        _mapTiles[26] = MapTile({
            mapTileId: 27,
            mapTileType: 27,
            moves: 2,
            north: true,
            east: true,
            south: false,
            west: false
        });
        _mapTiles[27] = MapTile({
            mapTileId: 28,
            mapTileType: 28,
            moves: 2,
            north: true,
            east: false,
            south: false,
            west: true
        });
        _mapTiles[28] = MapTile({
            mapTileId: 29,
            mapTileType: 29,
            moves: 3,
            north: true,
            east: true,
            south: true,
            west: false
        });
        _mapTiles[29] = MapTile({
            mapTileId: 30,
            mapTileType: 30,
            moves: 3,
            north: true,
            east: false,
            south: true,
            west: true
        });

        _mapTiles[30] = MapTile({
            mapTileId: 31,
            mapTileType: 31,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[31] = MapTile({
            mapTileId: 32,
            mapTileType: 32,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[32] = MapTile({
            mapTileId: 33,
            mapTileType: 33,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[33] = MapTile({
            mapTileId: 34,
            mapTileType: 34,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[34] = MapTile({
            mapTileId: 35,
            mapTileType: 35,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[35] = MapTile({
            mapTileId: 36,
            mapTileType: 36,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });

        for(uint8 i =0;i<36;i++){
            mapTiles[i] = _mapTiles[i];
        }

        emit MapTilesInitialized(_mapTiles);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*
Move types


claimMapTiles (address)
placeMapTile (address, tile Id, coordinate)
enterTemple (address, squad Id, temple Id)
moveLegionSquad (address, squad Id, tile Id, starting coordinate, [] coordinates)
removeLegionSquad (address, squad Id)
addLegionSquad (address, [] legionId, templeId, coordinate)
*/

enum MoveType {
    ClaimMapTiles,
    PlaceMapTile,
    EnterTemple,
    MoveLegionSquad,
    RemoveLegionSquad,
    AddLegionSquad,
    ClaimTreasure
}

struct Coordinate {
    uint8 x;
    uint8 y;
}

struct Move{
    MoveType moveTypeId;
    bytes moveData;
}

//0 claimMapTiles

//1
struct PlaceMapTileMove{
    uint32 mapTileId;
    Coordinate coordinate;
}

//2
struct EnterTempleMove{
    uint64 legionSquadId;
}


//3
struct MoveLegionSquadMove{
    uint64 legionSquadId;
    uint32 mapTileId;
    Coordinate startingCoordinate;
    Coordinate[] coordinates;
}

//4
struct RemoveLegionSquadMove {
    uint64 legionSquadId;
}

//5
struct AddLegionSquadMove{
    uint16[] legionIds;
    uint8 targetTemple;
    Coordinate coordinate;
}

//6
struct ClaimTreasureMove{
    uint64 _legionSquadId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface ILegion is IERC721MetadataUpgradeable {

    // Mints a legion to the given address. Returns the token ID.
    // Admin only.
    function safeMint(address _to) external returns(uint256);

    // Sets the URI for the given token id. Token must exist.
    // Admin only.
    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;

    // Transfers the token to the given address. Does not need approval. _from still must be the owner of the token.
    // Admin only.
    function adminSafeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LegionMetadataStoreState.sol";

interface ILegionMetadataStore {
    // Sets the intial metadata for a token id.
    // Admin only.
    function setInitialMetadataForLegion(address _owner, uint256 _tokenId, LegionGeneration _generation, LegionClass _class, LegionRarity _rarity, uint256 _oldId) external;

    // Increases the quest level by one. It is up to the calling contract to regulate the max quest level. No validation.
    // Admin only.
    function increaseQuestLevel(uint256 _tokenId) external;

    // Increases the craft level by one. It is up to the calling contract to regulate the max craft level. No validation.
    // Admin only.
    function increaseCraftLevel(uint256 _tokenId) external;

    // Increases the rank of the given constellation to the given number. It is up to the calling contract to regulate the max constellation rank. No validation.
    // Admin only.
    function increaseConstellationRank(uint256 _tokenId, Constellation _constellation, uint8 _to) external;

    // Returns the metadata for the given legion.
    function metadataForLegion(uint256 _tokenId) external view returns(LegionMetadata memory);

    // Returns the tokenUri for the given token.
    function tokenURI(uint256 _tokenId) external view returns(string memory);
}

// As this will likely change in the future, this should not be used to store state, but rather
// as parameters and return values from functions.
struct LegionMetadata {
    LegionGeneration legionGeneration;
    LegionClass legionClass;
    LegionRarity legionRarity;
    uint8 questLevel;
    uint8 craftLevel;
    uint8[6] constellationRanks;
    uint256 oldId;
}

enum Constellation {
    FIRE,
    EARTH,
    WIND,
    WATER,
    LIGHT,
    DARK
}

enum LegionRarity {
    LEGENDARY,
    RARE,
    SPECIAL,
    UNCOMMON,
    COMMON,
    RECRUIT
}

enum LegionClass {
    RECRUIT,
    SIEGE,
    FIGHTER,
    ASSASSIN,
    RANGED,
    SPELLCASTER,
    RIVERMAN,
    NUMERAIRE,
    ALL_CLASS,
    ORIGIN
}

enum LegionGeneration {
    GENESIS,
    AUXILIARY,
    RECRUIT
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../shared/AdminableUpgradeable.sol";
import "./ILegionMetadataStore.sol";

abstract contract LegionMetadataStoreState is Initializable, AdminableUpgradeable {

    event LegionQuestLevelUp(uint256 indexed _tokenId, uint8 _questLevel);
    event LegionCraftLevelUp(uint256 indexed _tokenId, uint8 _craftLevel);
    event LegionConstellationRankUp(uint256 indexed _tokenId, Constellation indexed _constellation, uint8 _rank);
    event LegionCreated(address indexed _owner, uint256 indexed _tokenId, LegionGeneration _generation, LegionClass _class, LegionRarity _rarity);

    mapping(uint256 => LegionGeneration) internal idToGeneration;
    mapping(uint256 => LegionClass) internal idToClass;
    mapping(uint256 => LegionRarity) internal idToRarity;
    mapping(uint256 => uint256) internal idToOldId;
    mapping(uint256 => uint8) internal idToQuestLevel;
    mapping(uint256 => uint8) internal idToCraftLevel;
    mapping(uint256 => uint8[6]) internal idToConstellationRanks;

    mapping(LegionGeneration => mapping(LegionClass => mapping(LegionRarity => mapping(uint256 => string)))) internal _genToClassToRarityToOldIdToUri;

    function __LegionMetadataStoreState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ITreasureFragment is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    function adminSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external;

    function adminSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomizer {

    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns(uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns(bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}