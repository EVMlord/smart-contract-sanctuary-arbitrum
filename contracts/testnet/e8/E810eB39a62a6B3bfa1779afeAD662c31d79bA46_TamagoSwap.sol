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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

// SPDX-License-Identifier: GPL-3.0
//author: Johnleouf21
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title This is the contract which added erc1155 into the previous swap contract.
*/
contract TamagoSwap is Ownable, ERC721Holder, ERC1155Holder {

  uint64 private _swapsCounter;
  uint64[] private swapIDs;
  uint96 public etherLocked;
  uint96 public fee;

  address private constant _ZEROADDRESS = address(0);

  mapping (uint64 => Swap) private _swaps;

  struct Swap {
    address payable initiator;
    uint96 initiatorEtherValue;
    address[] initiatorNftAddresses;
    uint256[] initiatorNftIds;
    uint128[] initiatorNftAmounts;
    address payable secondUser;
    uint96 secondUserEtherValue;
    address[] secondUserNftAddresses;
    uint256[] secondUserNftIds;
    uint128[] secondUserNftAmounts;
  }

  event SwapExecuted(address indexed from, address indexed to, uint64 indexed swapId);
  event SwapCanceled(address indexed canceledBy, uint64 indexed swapId);
  event SwapCanceledWithSecondUserRevert(uint64 indexed swapId, bytes reason);
  event SwapCanceledBySecondUser(uint64 indexed swapId);
  event SwapProposed(
    address indexed from,
    address indexed to,
    uint64 indexed swapId,
    uint128 etherValue,
    address[] nftAddresses,
    uint256[] nftIds,
    uint128[] nftAmounts
  );
  event SwapInitiated(
    address indexed from,
    address indexed to,
    uint64 indexed swapId,
    uint128 etherValue,
    address[] nftAddresses,
    uint256[] nftIds,
    uint128[] nftAmounts
  );
  event AppFeeChanged(
    uint96 fee
  );
  event TransferEthToSecondUserFailed(uint64 indexed swapId);

  modifier onlyInitiator(uint64 swapId) {
    require(msg.sender == _swaps[swapId].initiator,
      "TamagoSwap: caller is not swap initiator");
    _;
  }

  modifier onlySecondUser(uint64 swapId) {
    require(msg.sender == _swaps[swapId].secondUser,
      "TamagoSwap: caller is not swap secondUser");
    _;
  }

  modifier onlyThisContractItself() {
    require(msg.sender == address(this), "Invalid caller");
    _;
  }

  modifier requireSameLength(address[] memory nftAddresses, uint256[] memory nftIds, uint128[] memory nftAmounts) {
    require(nftAddresses.length == nftIds.length, "TamagoSwap: NFT and ID arrays have to be same length");
    require(nftAddresses.length == nftAmounts.length, "TamagoSwap: NFT and AMOUNT arrays have to be same length");
    _;
  }

  modifier chargeAppFee() {
    require(msg.value >= fee, "TamagoSwap: Sent ETH amount needs to be more or equal application fee");
    _;
  }

  constructor(uint96 initalAppFee, address contractOwnerAddress) {
    fee = initalAppFee;
    super.transferOwnership(contractOwnerAddress);
  }

  function setAppFee(uint96 newFee) external onlyOwner {
    fee = newFee;
    emit AppFeeChanged(newFee);
  }

  function getSwapIDs() public view returns(uint64[] memory){ 
        return swapIDs;
  }

	function getSwap(uint64 swapId) public  view returns (address, address, uint256[] memory, uint256[] memory, uint96, uint96)  {
		require((_swaps[swapId].secondUser == msg.sender) || (_swaps[swapId].initiator) == msg.sender, "TamagoSwap: caller is not swap participator");
      return (
          _swaps[swapId].initiator, 
          _swaps[swapId].secondUser,
          _swaps[swapId].initiatorNftIds,
          _swaps[swapId].secondUserNftIds,
          _swaps[swapId].initiatorEtherValue,
          _swaps[swapId].secondUserEtherValue
      );         
    }

  /**
  * @dev First user proposes a swap to the second user with the NFTs that he deposits and wants to trade.
  *      Proposed NFTs are transfered to the TamagoSwap contract and
  *      kept there until the swap is accepted or canceled/rejected.
  *
  * @param secondUser address of the user that the first user wants to trade NFTs with
  * @param nftAddresses array of NFT addressed that want to be traded
  * @param nftIds array of IDs belonging to NFTs that want to be traded
  * @param nftAmounts array of NFT amounts that want to be traded. If the amount is zero, that means 
  * the token is ERC721 token. Otherwise the token is ERC1155 token.
  */
  function proposeSwap(
    address secondUser,
    address[] memory nftAddresses,
    uint256[] memory nftIds,
    uint128[] memory nftAmounts
  ) external payable chargeAppFee requireSameLength(nftAddresses, nftIds, nftAmounts) {
    uint64 swapsCounter = _swapsCounter + 1;
    _swapsCounter = swapsCounter;
    swapIDs.push(swapsCounter);

    Swap storage swap = _swaps[swapsCounter];
    swap.initiator = payable(msg.sender);

    if(nftAddresses.length > 0) {
      for (uint256 i = 0; i < nftIds.length; i++){
        safeTransferFrom(msg.sender, address(this), nftAddresses[i], nftIds[i], nftAmounts[i], "");
      }

      swap.initiatorNftAddresses = nftAddresses;
      swap.initiatorNftIds = nftIds;
      swap.initiatorNftAmounts = nftAmounts;
    }

    uint96 _fee = fee;
    uint96 initiatorEtherValue;

    if (msg.value > _fee) {
      initiatorEtherValue = uint96(msg.value) - _fee;
      swap.initiatorEtherValue = initiatorEtherValue;
      etherLocked += initiatorEtherValue;
    }
    swap.secondUser = payable(secondUser);

    emit SwapProposed(
      msg.sender,
      secondUser,
      swapsCounter,
      initiatorEtherValue,
      nftAddresses,
      nftIds,
      nftAmounts
    );
  }

  /**
  * @dev Second user accepts the swap (with proposed NFTs) from swap initiator and
  *      deposits his NFTs into the TamagoSwap contract.
  *      Callable only by second user that is invited by swap initiator.
  *      Even if the second user didn't provide any NFT and ether value equals to fee, it is considered valid.
  *
  * @param swapId ID of the swap that the second user is invited to participate in
  * @param nftAddresses array of NFT addressed that want to be traded
  * @param nftIds array of IDs belonging to NFTs that want to be traded
  * @param nftAmounts array of NFT amounts that want to be traded. If the amount is zero, that means 
  * the token is ERC721 token. Otherwise the token is ERC1155 token.
  */
  function initiateSwap(
    uint64 swapId,
    address[] memory nftAddresses,
    uint256[] memory nftIds,
    uint128[] memory nftAmounts
  ) external payable chargeAppFee requireSameLength(nftAddresses, nftIds, nftAmounts) {
    require(_swaps[swapId].secondUser == msg.sender, "TamagoSwap: caller is not swap participator");
    require(
      _swaps[swapId].secondUserEtherValue == 0 &&
      _swaps[swapId].secondUserNftAddresses.length == 0
      , "TamagoSwap: swap already initiated"
    );

    if (nftAddresses.length > 0) {
      for (uint256 i = 0; i < nftIds.length; i++){
        safeTransferFrom(msg.sender, address(this), nftAddresses[i], nftIds[i], nftAmounts[i], "");
      }

      _swaps[swapId].secondUserNftAddresses = nftAddresses;
      _swaps[swapId].secondUserNftIds = nftIds;
      _swaps[swapId].secondUserNftAmounts = nftAmounts;
    }

    uint96 _fee = fee;
    uint96 secondUserEtherValue;

    if (msg.value > _fee) {
      secondUserEtherValue = uint96(msg.value) - _fee;
      _swaps[swapId].secondUserEtherValue = secondUserEtherValue;
      etherLocked += secondUserEtherValue;
    }

    emit SwapInitiated(
      msg.sender,
      _swaps[swapId].initiator,
      swapId,
      secondUserEtherValue,
      nftAddresses,
      nftIds,
      nftAmounts
    );
  }

  /**
  * @dev Swap initiator accepts the swap (NFTs proposed by the second user).
  *      Executeds the swap - transfers NFTs from TamagoSwap to the participating users.
  *      Callable only by swap initiator.
  *
  * @param swapId ID of the swap that the initator wants to execute
  */
  function acceptSwap(uint64 swapId) external onlyInitiator(swapId) {
    Swap memory swap = _swaps[swapId];
    

    require(
      (swap.secondUserNftAddresses.length > 0 || swap.secondUserEtherValue > 0) &&
      (swap.initiatorNftAddresses.length > 0 || swap.initiatorEtherValue > 0),
      "TamagoSwap: Can't accept swap, both participants didn't add NFTs"
    );

    if (swap.secondUserNftAddresses.length > 0) {
      // transfer NFTs from escrow to initiator
      for (uint256 i = 0; i < swap.secondUserNftIds.length; i++) {
        safeTransferFrom(
          address(this),
          swap.initiator,
          swap.secondUserNftAddresses[i],
          swap.secondUserNftIds[i],
          swap.secondUserNftAmounts[i],
          ""
        );
      }
    }

    if (swap.initiatorNftAddresses.length > 0) {
      // transfer NFTs from escrow to second user
      for (uint256 i = 0; i < swap.initiatorNftIds.length; i++) {
        safeTransferFrom(
          address(this),
          swap.secondUser,
          swap.initiatorNftAddresses[i],
          swap.initiatorNftIds[i],
          swap.initiatorNftAmounts[i],
          ""
        );
      }
    }

    if (swap.initiatorEtherValue > 0) {
      etherLocked -= swap.initiatorEtherValue;
      (bool success,) = swap.secondUser.call{value: swap.initiatorEtherValue}("");
      require(success, "Failed to send Ether to the second user");
    }
    if (swap.secondUserEtherValue > 0) {
      etherLocked -= swap.secondUserEtherValue;
      (bool success,) = swap.initiator.call{value: swap.secondUserEtherValue}("");
      require(success, "Failed to send Ether to the initiator user");
    }

    emit SwapExecuted(swap.initiator, swap.secondUser, swapId);
	delete _swaps[swapId];
	deleteArrayEntry(swapId);
  }

  /**
  * @dev Returns NFTs from TamagoSwap to swap initator.
  *      Callable only if second user hasn't yet added NFTs.
  *
  * @param swapId ID of the swap that the swap participants want to cancel
  */
  function cancelSwap(uint64 swapId) external returns (bool) {
    Swap memory swap = _swaps[swapId];
     

    require(
      swap.initiator == msg.sender || swap.secondUser == msg.sender,
      "TamagoSwap: Can't cancel swap, must be swap participant"
    );

    if (swap.initiatorNftAddresses.length > 0) {
      // return initiator NFTs
      for (uint256 i = 0; i < swap.initiatorNftIds.length; i++) {
        safeTransferFrom(
          address(this),
          swap.initiator,
          swap.initiatorNftAddresses[i],
          swap.initiatorNftIds[i],
          swap.initiatorNftAmounts[i],
          ""
        );
      }
    }

    if (swap.initiatorEtherValue != 0) {
      etherLocked -= swap.initiatorEtherValue;
      (bool success,) = swap.initiator.call{value: swap.initiatorEtherValue}("");
      require(success, "Failed to send Ether to the initiator user");
    }

    if(swap.secondUserNftAddresses.length > 0) {
      // return second user NFTs
      try this.safeMultipleTransfersFrom(
        address(this),
        swap.secondUser,
        swap.secondUserNftAddresses,
        swap.secondUserNftIds,
        swap.secondUserNftAmounts
      ) {} catch (bytes memory reason) {
        _swaps[swapId].secondUser = swap.secondUser;
        _swaps[swapId].secondUserNftAddresses = swap.secondUserNftAddresses;
        _swaps[swapId].secondUserNftIds = swap.secondUserNftIds;
        _swaps[swapId].secondUserNftAmounts = swap.secondUserNftAmounts;
        _swaps[swapId].secondUserEtherValue = swap.secondUserEtherValue;
        emit SwapCanceledWithSecondUserRevert(swapId, reason);
        return true;
      }
    }

    if (swap.secondUserEtherValue != 0) {
      etherLocked -= swap.secondUserEtherValue;
      (bool success,) = swap.secondUser.call{value: swap.secondUserEtherValue}("");
      if (!success) {
        etherLocked += swap.secondUserEtherValue;
        _swaps[swapId].secondUser = swap.secondUser;
        _swaps[swapId].secondUserEtherValue = swap.secondUserEtherValue;
        emit TransferEthToSecondUserFailed(swapId);
        return true;
      }
    }

    emit SwapCanceled(msg.sender, swapId);
	delete _swaps[swapId];
	deleteArrayEntry(swapId);
    return true;
	
  }

  function cancelSwapBySecondUser(uint64 swapId) external onlySecondUser(swapId) {
    Swap memory swap = _swaps[swapId];
    

    if(swap.secondUserNftAddresses.length > 0) {
      // return second user NFTs
      for (uint256 i = 0; i < swap.secondUserNftIds.length; i++) {
        safeTransferFrom(
          address(this),
          swap.secondUser,
          swap.secondUserNftAddresses[i],
          swap.secondUserNftIds[i],
          swap.secondUserNftAmounts[i],
          ""
        );
      }
    }

    if (swap.secondUserEtherValue != 0) {
      etherLocked -= swap.secondUserEtherValue;
      (bool success,) = swap.secondUser.call{value: swap.secondUserEtherValue}("");
      require(success, "Failed to send Ether to the second user");
    }

    if (swap.initiator != _ZEROADDRESS) {
      _swaps[swapId].initiator = swap.initiator;
      _swaps[swapId].initiatorEtherValue = swap.initiatorEtherValue;
      _swaps[swapId].initiatorNftAddresses = swap.initiatorNftAddresses;
      _swaps[swapId].initiatorNftIds = swap.initiatorNftIds;
      _swaps[swapId].initiatorNftAmounts = swap.initiatorNftAmounts;
    }

    emit SwapCanceledBySecondUser(swapId);
	delete _swaps[swapId];
	deleteArrayEntry(swapId);
  }

  function deleteArrayEntry(uint64 swapId) public {
        uint index = findSwapIdIndex(swapId);
        if (index != uint64(int64(-1))) {
            uint64[] memory newSwapIDs = new uint64[](swapIDs.length - 1);
            for (uint i = 0; i < index; i++) {
                newSwapIDs[i] = swapIDs[i];
            }
            for (uint i = index + 1; i < swapIDs.length; i++) {
                newSwapIDs[i - 1] = swapIDs[i];
            }
            swapIDs = newSwapIDs;
        }
    }

    function findSwapIdIndex(uint64 swapId) private view returns (uint64) {
    for (uint64 i = 0; i < swapIDs.length; i++) {
        if (swapIDs[i] == swapId) {
            return i;
        }
    }
    return uint64(int64(-1));
}

  function safeMultipleTransfersFrom(
    address from,
    address to,
    address[] memory nftAddresses,
    uint256[] memory nftIds,
    uint128[] memory nftAmounts
  ) external onlyThisContractItself {
    for (uint256 i = 0; i < nftIds.length; i++) {
      safeTransferFrom(from, to, nftAddresses[i], nftIds[i], nftAmounts[i], "");
    }
  }

  function safeTransferFrom(
    address from,
    address to,
    address tokenAddress,
    uint256 tokenId,
    uint256 tokenAmount,
    bytes memory _data
  ) internal virtual {
    if (tokenAmount == 0) {
      IERC721(tokenAddress).transferFrom(from, to, tokenId);
    } else {
      IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, tokenAmount, _data);
    }
  }

  function withdrawEther(address payable recipient) external onlyOwner {
    require(recipient != address(0), "TamagoSwap: transfer to the zero address");
    recipient.transfer((address(this).balance - etherLocked));
  }

  function getBalance() public view onlyOwner returns (uint256) {
    return (address(this).balance - etherLocked);
  }
}