// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
 */
library EnumerableSetUpgradeable {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IBadgez is IERC1155Upgradeable {

    function mintIfNeeded(address _to, uint256 _id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBugz is IERC20Upgradeable {

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IItemz is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function mintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;

    function burn(address _from, uint256 _id, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ToadTraitConstants {

    string constant public SVG_HEADER = '<svg id="toad" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string constant public SVG_FOOTER = '<style>#toad{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';

    string constant public RARITY = "Rarity";
    string constant public BACKGROUND = "Background";
    string constant public MUSHROOM = "Mushroom";
    string constant public SKIN = "Skin";
    string constant public CLOTHES = "Clothes";
    string constant public MOUTH = "Mouth";
    string constant public EYES = "Eyes";
    string constant public ITEM = "Item";
    string constant public HEAD = "Head";
    string constant public ACCESSORY = "Accessory";

    string constant public RARITY_COMMON = "Common";
    string constant public RARITY_1_OF_1 = "1 of 1";
}

enum ToadRarity {
    COMMON,
    ONE_OF_ONE
}

enum ToadBackground {
    GREY,
    PURPLE,
    GREEN,
    BROWN,
    YELLOW,
    PINK,
    SKY_BLUE,
    MINT,
    ORANGE,
    RED,
    SKY,
    SUNRISE,
    SPRING,
    WATERMELON,
    SPACE,
    CLOUDS,
    SWAMP,
    GOLDEN,
    DARK_PURPLE
}

enum ToadMushroom {
    COMMON,
    ORANGE,
    BROWN,
    RED_SPOTS,
    GREEN,
    BLUE,
    YELLOW,
    GREY,
    PINK,
    ICE,
    GOLDEN,
    RADIOACTIVE,
    CRYSTAL,
    ROBOT
}

enum ToadSkin {
    OG_GREEN,
    BROWN,
    DARK_GREEN,
    ORANGE,
    GREY,
    BLUE,
    PURPLE,
    PINK,
    RAINBOW,
    GOLDEN,
    RADIOACTIVE,
    CRYSTAL,
    SKELETON,
    ROBOT,
    SKIN
}

enum ToadClothes {
    NONE,
    TURTLENECK_BLUE,
    TURTLENECK_GREY,
    T_SHIRT_ROCKET_GREY,
    T_SHIRT_ROCKET_BLUE,
    T_SHIRT_FLY_GREY,
    T_SHIRT_FLY_BLUE,
    T_SHIRT_FLY_RED,
    T_SHIRT_HEART_BLACK,
    T_SHIRT_HEART_PINK,
    T_SHIRT_RAINBOW,
    T_SHIRT_SKULL,
    HOODIE_GREY,
    HOODIE_PINK,
    HOODIE_LIGHT_BLUE,
    HOODIE_DARK_BLUE,
    HOODIE_WHITE,
    T_SHIRT_CAMO,
    HOODIE_CAMO,
    CONVICT,
    ASTRONAUT,
    FARMER,
    RED_OVERALLS,
    GREEN_OVERALLS,
    ZOMBIE,
    SAMURI,
    SAIAN,
    HAWAIIAN_SHIRT,
    SUIT_BLACK,
    SUIT_RED,
    ROCKSTAR,
    PIRATE,
    ASTRONAUT_SUIT,
    CHICKEN_COSTUME,
    DINOSAUR_COSTUME,
    SMOL,
    STRAW_HAT,
    TRACKSUIT
}

enum ToadMouth {
    SMILE,
    O,
    GASP,
    SMALL_GASP,
    LAUGH,
    LAUGH_TEETH,
    SMILE_BIG,
    TONGUE,
    RAINBOW_VOM,
    PIPE,
    CIGARETTE,
    BLUNT,
    MEH,
    GUM,
    FIRE,
    NONE
}

enum ToadEyes {
    RIGHT_UP,
    RIGHT_DOWN,
    TIRED,
    EYE_ROLL,
    WIDE_UP,
    CONTENTFUL,
    LASERS,
    CROAKED,
    SUSPICIOUS,
    WIDE_DOWN,
    BORED,
    STONED,
    HEARTS,
    WINK,
    GLASSES_HEART,
    GLASSES_3D,
    GLASSES_SUN,
    EYE_PATCH_LEFT,
    EYE_PATCH_RIGHT,
    EYE_PATCH_BORED_LEFT,
    EYE_PATCH_BORED_RIGHT,
    EXCITED,
    NONE
}

enum ToadItem {
    NONE,
    LIGHTSABER_RED,
    LIGHTSABER_GREEN,
    LIGHTSABER_BLUE,
    SWORD,
    WAND_LEFT,
    WAND_RIGHT,
    FIRE_SWORD,
    ICE_SWORD,
    AXE_LEFT,
    AXE_RIGHT
}

enum ToadHead {
    NONE,
    CAP_BROWN,
    CAP_BLACK,
    CAP_RED,
    CAP_PINK,
    CAP_MUSHROOM,
    STRAW_HAT,
    SAILOR_HAT,
    PIRATE_HAT,
    WIZARD_PURPLE_HAT,
    WIZARD_BROWN_HAT,
    CAP_KIDS,
    TOP_HAT,
    PARTY_HAT,
    CROWN,
    BRAIN,
    MOHAWK_PURPLE,
    MOHAWK_GREEN,
    MOHAWK_PINK,
    AFRO,
    BACK_CAP_WHITE,
    BACK_CAP_RED,
    BACK_CAP_BLUE,
    BANDANA_PURPLE,
    BANDANA_RED,
    BANDANA_BLUE,
    BEANIE_GREY,
    BEANIE_BLUE,
    BEANIE_YELLOW,
    HALO,
    COOL_CAT_HEAD,
    FIRE
}

enum ToadAccessory {
    NONE,
    FLIES,
    GOLD_CHAIN,
    NECKTIE_RED,
    NECKTIE_BLUE,
    NECKTIE_PINK
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../toadhousezmetadata/IToadHousezMetadata.sol";

interface IToadHousez is IERC721Upgradeable {

    function mint(address _to, ToadHouseTraits calldata _traits) external;

    function adminSafeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToadHousezMetadata {
    function tokenURI(uint256 _tokenId) external view returns(string memory);

    function setMetadataForHouse(uint256 _tokenId, ToadHouseTraits calldata _traits) external;
}

// Immutable Traits.
// Do not change.
struct ToadHouseTraits {
    HouseRarity rarity;
    HouseVariation variation;
    HouseBackground background;
    HouseSmoke smoke;
    WoodType main;
    WoodType left;
    WoodType right;
    WoodType door;
    WoodType mushroom;
}

// The string represenation of the various traits.
// variation is still a uint as there is no string representation.
//
struct ToadHouseTraitStrings {
    string rarity;
    uint8 variation;
    string background;
    string smoke;
    string main;
    string left;
    string right;
    string door;
    string mushroom;
}

enum HouseRarity {
    COMMON,
    ONE_OF_ONE
}

enum HouseBackground {
    GARDEN,
    BEACH,
    DARK_FOREST,
    SLIME,
    SWAMP,
    TEMPLE
}

enum HouseSmoke {
    BLUE,
    GREEN,
    LAVENDAR,
    ORANGE,
    PINK,
    PURPLE,
    RED,
    YELLOW
}

enum WoodType {
    PINE,
    OAK,
    REDWOOD,
    BUFO_WOOD,
    WITCH_WOOD,
    TOAD_WOOD,
    GOLD_WOOD,
    SAKURA_WOOD
}

enum HouseVariation {
    VARIATION_1,
    VARIATION_2,
    VARIATION_3
}

string constant RARITY = "Rarity";
string constant BACKGROUND = "Background";
string constant SMOKE = "Smoke";
string constant WOOD_TYPE = "Wood Type";
string constant VARIATION = "Variation";
string constant MAIN = "Main";
string constant LEFT = "Left";
string constant RIGHT = "Right";
string constant DOOR = "Door";
string constant MUSHROOM = "Mushroom";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToadHousezMinter {

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ToadHousezMinterContracts.sol";

contract ToadHousezMinter is Initializable, ToadHousezMinterContracts {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize() external initializer {
        ToadHousezMinterContracts.__ToadHousezMinterContracts_init();
    }

    function setHouseBuildingDuration(uint256 _houseBuildingDuration) external onlyAdminOrOwner {
        houseBuildingDuration = _houseBuildingDuration;
        emit HouseBuildingDuration(houseBuildingDuration);
    }

    function setHouseBlueprintBugzCost(uint256 _houseBlueprintBugzCost) external onlyAdminOrOwner {
        houseBlueprintBugzCost = _houseBlueprintBugzCost;
        emit HouseBlueprintBugzCost(_houseBlueprintBugzCost);
    }

    function setIsBlueprintBuyingEnabled(bool _isBlueprintBuyingEnabled) external onlyAdminOrOwner {
        isBlueprintBuyingEnabled = _isBlueprintBuyingEnabled;
        emit BlueprintBuyingEnabledChanged(isBlueprintBuyingEnabled);
    }

    function setIsHouseBuildingEnabled(bool _isHouseBuildingEnabled) external onlyAdminOrOwner {
        isHouseBuildingEnabled = _isHouseBuildingEnabled;
        emit HouseBuildingEnabledChanged(isHouseBuildingEnabled);
    }

    function setTraitRaritiesAndAliases(string calldata _trait, uint8[] calldata _rarities, uint8[] calldata _aliases) external onlyAdminOrOwner {
        traitTypeToRarities[_trait] = _rarities;
        traitTypeToAliases[_trait] = _aliases;
    }

    function rarities(string calldata _traitType) external view returns(uint8[] memory) {
        return traitTypeToRarities[_traitType];
    }

    function aliases(string calldata _traitType) external view returns(uint8[] memory) {
        return traitTypeToAliases[_traitType];
    }

    function buyBlueprints(
        uint256[] calldata _toadIds)
    external
    onlyEOA
    whenNotPaused
    contractsAreSet
    {
        require(_toadIds.length > 0, "ToadHousezMinter: Invalid array length");
        require(wartlocksHallow.isCroakshirePowered(), "ToadHousezMinter: Croakshire is not powered");
        require(isBlueprintBuyingEnabled, "ToadHousezMinter: Blueprint buying not enabled");

        for(uint256 i = 0; i < _toadIds.length; i++) {
            uint256 _toadId = _toadIds[i];

            require(toadz.ownerOf(_toadId) == msg.sender || world.ownerForStakedToad(_toadId) == msg.sender,
                "ToadHousezMinter: Must own toad to buy the blueprints");

            // Update to bought. Will revert if already purchased
            toadzMetadata.setHasPurchasedBlueprint(_toadId);
        }

        itemz.mint(msg.sender, houseBlueprintId, _toadIds.length);

        uint256 _totalBugzCost = houseBlueprintBugzCost * _toadIds.length;
        if(_totalBugzCost > 0) {
            bugz.burn(msg.sender, _totalBugzCost);
        }
    }

    function startBuildingHouses(
        BuildHouseParams[] calldata _buildHouseParams)
    external
    onlyEOA
    whenNotPaused
    contractsAreSet
    {
        require(_buildHouseParams.length > 0, "ToadHousezMinter: Invalid array length");
        require(wartlocksHallow.isCroakshirePowered(), "ToadHousezMinter: Croakshire is not powered");
        require(isHouseBuildingEnabled, "ToadHousezMinter: House building not enabled");

        uint256 _requestId = randomizer.requestRandomNumber();
        addressToRequestIds[msg.sender].add(_requestId);

        requestIdToHouses[_requestId].startTime = block.timestamp;

        uint256[] memory _woodAmountsToBurn = new uint256[](8);

        for(uint256 i = 0; i < _buildHouseParams.length; i++) {
            BuildHouseParams calldata _buildHouseParam = _buildHouseParams[i];

            // Track what wood to burn
            for(uint256 j = 0; j < _buildHouseParam.woods.length; j++) {
                _woodAmountsToBurn[uint256(_buildHouseParam.woods[j])] += 1;
            }

            requestIdToHouses[_requestId].houseParams.push(_buildHouseParam);
        }

        for(uint256 i = 0; i < _woodAmountsToBurn.length; i++) {
            uint256 _amount = _woodAmountsToBurn[i];
            if(_amount == 0) {
                continue;
            }
            uint256 _woodId = woodTypeToItemId[WoodType(i)];
            itemz.burn(msg.sender, _woodId, _amount);
        }

        // Burn the correct number of blueprints
        itemz.burn(msg.sender, houseBlueprintId, _buildHouseParams.length);

        uint256 _totalBugzCost = houseBuildingBugzCost * _buildHouseParams.length;
        if(_totalBugzCost > 0) {
            bugz.burn(msg.sender, _totalBugzCost);
        }

        emit HouseBuildingBatchStarted(msg.sender, _requestId, _buildHouseParams.length, block.timestamp + houseBuildingDuration);
    }

    function finishBuildingHouses()
    external
    onlyEOA
    whenNotPaused
    contractsAreSet
    {
        uint256[] memory _requestIds = addressToRequestIds[msg.sender].values();

        uint256 _requestIdsProcessed;

        for(uint256 i = 0; i < _requestIds.length; i++) {
            uint256 _requestId = _requestIds[i];

            if(!randomizer.isRandomReady(_requestId)) {
                continue;
            }

            RequestIdInfo storage _requestIdInfo = requestIdToHouses[_requestId];
            if(block.timestamp < _requestIdInfo.startTime + houseBuildingDuration) {
                continue;
            }

            _requestIdsProcessed++;
            addressToRequestIds[msg.sender].remove(_requestId);

            uint256 _randomNumber = randomizer.revealRandomNumber(_requestId);

            for(uint256 j = 0; j < _requestIdInfo.houseParams.length; j++) {
                if(j != 0) {
                    _randomNumber = uint256(keccak256(abi.encode(_randomNumber, j)));
                }

                ToadHouseTraits memory _traits = _pickTraits(
                    _requestIdInfo.houseParams[j],
                    _randomNumber
                );

                toadHousez.mint(
                    msg.sender,
                    _traits
                );
            }

            emit HouseBuildingBatchFinished(msg.sender, _requestId);
        }


        require(_requestIdsProcessed > 0, "ToadHousezMinter: Nothing to finish");
    }

    function _pickTraits(
        BuildHouseParams storage _buildHouseParams,
        uint256 _randomNumber)
    private
    view
    returns(ToadHouseTraits memory _toadHouseTraits)
    {
        _toadHouseTraits.rarity = HouseRarity.COMMON;

        // In total, have 12 fields to pick (the last wood position does not require a random).
        // Each takes 16 bits of the 256 bit random number. No worry about using too many bits.
        //
        _toadHouseTraits.variation = HouseVariation(
            _pickTrait(uint16(_randomNumber & 0xFFFF),
            traitTypeToRarities[VARIATION],
            traitTypeToAliases[VARIATION]));
        _randomNumber >>= 16;

        _toadHouseTraits.background = HouseBackground(
            _pickTrait(uint16(_randomNumber & 0xFFFF),
            traitTypeToRarities[BACKGROUND],
            traitTypeToAliases[BACKGROUND]));
        _randomNumber >>= 16;

        _toadHouseTraits.smoke = HouseSmoke(
            _pickTrait(uint16(_randomNumber & 0xFFFF),
            traitTypeToRarities[SMOKE],
            traitTypeToAliases[SMOKE]));
        _randomNumber >>= 16;

        // Used 4 16 bit slots of the random.
        //
        WoodType[5] memory _woodTypeOrder = _randomizeWoodPositions(_buildHouseParams, _randomNumber);
        _randomNumber >>= 64;

        _toadHouseTraits.main = _woodTypeOrder[0];
        _toadHouseTraits.left = _woodTypeOrder[1];
        _toadHouseTraits.right = _woodTypeOrder[2];
        _toadHouseTraits.door = _woodTypeOrder[3];
        _toadHouseTraits.mushroom = _woodTypeOrder[4];
    }

    function _pickTrait(
        uint16 _randomNumber,
        uint8[] storage _rarities,
        uint8[] storage _aliases)
    private
    view
    returns(uint8)
    {
        uint8 _trait = uint8(_randomNumber) % uint8(_rarities.length);

        // If a selected random trait probability is selected, return that trait
        if(_randomNumber >> 8 < _rarities[_trait]) {
            return _trait;
        } else {
            return _aliases[_trait];
        }
    }

    function _randomizeWoodPositions(
        BuildHouseParams memory _buildHouseParams,
        uint256 _randomNumber)
    private
    pure
    returns(WoodType[5] memory _randomizedArray)
    {
        uint8 _elementsRemaining = 5;
        uint256 _returnValueArrayIndex = 0;

        while(_elementsRemaining > 0) {
            uint256 _chosenIndex;
            if(_elementsRemaining == 1) {
                _chosenIndex = 0;
            } else {
                _chosenIndex = _randomNumber % _elementsRemaining;
                _randomNumber >> 16;
            }

            _randomizedArray[_returnValueArrayIndex] = _buildHouseParams.woods[_chosenIndex];
            _returnValueArrayIndex++;
            _elementsRemaining--;

            // Swap the chosen element position with the last element.
            //
            _buildHouseParams.woods[_chosenIndex] = _buildHouseParams.woods[_elementsRemaining];
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ToadHousezMinterState.sol";

abstract contract ToadHousezMinterContracts is Initializable, ToadHousezMinterState {

    function __ToadHousezMinterContracts_init() internal initializer {
        ToadHousezMinterState.__ToadHousezMinterState_init();
    }

    function setContracts(
        address _randomizerAddress,
        address _itemzAddress,
        address _bugzAddress,
        address _toadzAddress,
        address _toadzMetadataAddress,
        address _toadHousezAddress,
        address _badgezAddress,
        address _worldAddress,
        address _wartlocksHallowAddress)
    external onlyAdminOrOwner
    {
        randomizer = IRandomizer(_randomizerAddress);
        itemz = IItemz(_itemzAddress);
        bugz = IBugz(_bugzAddress);
        toadz = IToadz(_toadzAddress);
        toadzMetadata = IToadzMetadata(_toadzMetadataAddress);
        toadHousez = IToadHousez(_toadHousezAddress);
        badgez = IBadgez(_badgezAddress);
        world = IWorld(_worldAddress);
        wartlocksHallow = IWartlocksHallow(_wartlocksHallowAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(randomizer) != address(0)
            && address(itemz) != address(0)
            && address(bugz) != address(0)
            && address(toadz) != address(0)
            && address(toadzMetadata) != address(0)
            && address(toadHousez) != address(0)
            && address(badgez) != address(0)
            && address(world) != address(0)
            && address(wartlocksHallow) != address(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../../shared/randomizer/IRandomizer.sol";
import "../../shared/AdminableUpgradeable.sol";
import "../itemz/IItemz.sol";
import "../bugz/IBugz.sol";
import "../toadz/IToadz.sol";
import "../toadzmetadata/IToadzMetadata.sol";
import "../toadhousez/IToadHousez.sol";
import "../badgez/IBadgez.sol";
import "../world/IWorld.sol";
import "../wartlockshallow/IWartlocksHallow.sol";
import "./IToadHousezMinter.sol";

abstract contract ToadHousezMinterState is Initializable, IToadHousezMinter, AdminableUpgradeable {

    event HouseBlueprintBugzCost(uint256 _bugzCost);
    event HouseBuildingBugzCost(uint256 _bugzCost);
    event HouseBuildingDuration(uint256 _duration);
    event BlueprintBuyingEnabledChanged(bool _isBlueprintBuyingEnabled);
    event HouseBuildingEnabledChanged(bool _isHouseBuildingEnabled);

    event HouseBuildingBatchStarted(address _user, uint256 _requestId, uint256 _numberOfHousesInBatch, uint256 _timeOfCompletion);
    event HouseBuildingBatchFinished(address _user, uint256 _requestId);

    IRandomizer public randomizer;
    IItemz public itemz;
    IBugz public bugz;
    IToadz public toadz;
    IToadzMetadata public toadzMetadata;
    IToadHousez public toadHousez;
    IBadgez public badgez;
    IWorld public world;
    IWartlocksHallow public wartlocksHallow;

    mapping(WoodType => uint256) public woodTypeToItemId;

    uint256 public houseBlueprintId;
    uint256 public houseBlueprintBugzCost;
    uint256 public houseBuildingBugzCost;
    uint256 public houseBuildingDuration;

    mapping(address => EnumerableSetUpgradeable.UintSet) internal addressToRequestIds;
    mapping(uint256 => RequestIdInfo) internal requestIdToHouses;

    // Rarities and aliases are used for the Walker's Alias algorithm.
    mapping(string => uint8[]) public traitTypeToRarities;
    mapping(string => uint8[]) public traitTypeToAliases;

    bool public isBlueprintBuyingEnabled;
    bool public isHouseBuildingEnabled;

    function __ToadHousezMinterState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();

        emit BlueprintBuyingEnabledChanged(false);
        emit HouseBuildingEnabledChanged(false);

        woodTypeToItemId[WoodType.PINE] = 3;
        woodTypeToItemId[WoodType.OAK] = 5;
        woodTypeToItemId[WoodType.REDWOOD] = 4;
        woodTypeToItemId[WoodType.BUFO_WOOD] = 6;
        woodTypeToItemId[WoodType.WITCH_WOOD] = 32;
        woodTypeToItemId[WoodType.TOAD_WOOD] = 7;
        woodTypeToItemId[WoodType.GOLD_WOOD] = 33;
        woodTypeToItemId[WoodType.SAKURA_WOOD] = 34;

        traitTypeToRarities[BACKGROUND] = [227, 155, 155, 155, 255, 155];
        traitTypeToAliases[BACKGROUND] = [4, 0, 0, 0, 0, 4];

        traitTypeToRarities[VARIATION] = [255, 254, 254];
        traitTypeToAliases[VARIATION] = [0, 0, 0];

        traitTypeToRarities[SMOKE] = [255, 255, 255, 255, 255, 255, 255, 255];
        traitTypeToAliases[SMOKE] = [0, 0, 0, 0, 0, 0, 0, 0];

        houseBlueprintId = 37;
        houseBlueprintBugzCost = 100 ether;
        emit HouseBlueprintBugzCost(houseBlueprintBugzCost);

        houseBuildingBugzCost = 0;
        emit HouseBuildingBugzCost(houseBuildingBugzCost);

        houseBuildingDuration = 1 days;
        emit HouseBuildingDuration(houseBuildingDuration);
    }
}

struct RequestIdInfo {
    uint256 startTime;
    BuildHouseParams[] houseParams;
}

struct BuildHouseParams {
    WoodType[5] woods;
}

struct HouseBuildingInfo {
    uint256 startTime;
    WoodType[5] woods;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../libraries/ToadTraitConstants.sol";
import "../toadzmetadata/IToadzMetadata.sol";

interface IToadz is IERC721Upgradeable {

    function mint(address _to, ToadTraits calldata _traits) external returns(uint256);

    function adminSafeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/ToadTraitConstants.sol";

interface IToadzMetadata {
    function tokenURI(uint256 _tokenId) external view returns(string memory);

    function setMetadataForToad(uint256 _tokenId, ToadTraits calldata _traits) external;

    function setHasPurchasedBlueprint(uint256 _tokenId) external;

    function hasPurchasedBlueprint(uint256 _tokenId) external view returns(bool);
}

// Immutable Traits.
// Do not change.
struct ToadTraits {
    ToadRarity rarity;
    ToadBackground background;
    ToadMushroom mushroom;
    ToadSkin skin;
    ToadClothes clothes;
    ToadMouth mouth;
    ToadEyes eyes;
    ToadItem item;
    ToadHead head;
    ToadAccessory accessory;
}

struct ToadTraitStrings {
    string rarity;
    string background;
    string mushroom;
    string skin;
    string clothes;
    string mouth;
    string eyes;
    string item;
    string head;
    string accessory;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWartlocksHallow {
    function isCroakshirePowered() external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWorld {

    function ownerForStakedToad(uint256 _tokenId) external view returns(address);

    function locationForStakedToad(uint256 _tokenId) external view returns(Location);

    function balanceOf(address _owner) external view returns (uint256);
}

enum Location {
    NOT_STAKED,
    WORLD,
    HUNTING_GROUNDS,
    CRAFTING
}