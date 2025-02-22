// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        address owner = _owners[tokenId];
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
            "ERC721: approve caller is not token owner nor approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
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
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// Libraries
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {OwnableRoles} from "solady/src/auth/OwnableRoles.sol";

// Libraries
import {StructuredLinkedList} from "solidity-linked-list/contracts/StructuredLinkedList.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

// Contracts
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ReentrancyGuard} from "../helpers/ReentrancyGuard.sol";
import {Pausable} from "../helpers/Pausable.sol";
import {AtlanticPutsPoolState} from "./AtlanticPutsPoolState.sol";

// Interfaces
import {IERC20} from "../interfaces/IERC20.sol";
import {IOptionPricing} from "../interfaces/IOptionPricing.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IVolatilityOracle} from "../interfaces/IVolatilityOracle.sol";
import {IOptionPricing} from "../interfaces/IOptionPricing.sol";
import {IDopexFeeStrategy} from "../fees/interfaces/IDopexFeeStrategy.sol";

// Enums
import {OptionsState, EpochState, Contracts, VaultConfig} from "./AtlanticPutsPoolEnums.sol";
// Structs
import {EpochData, MaxStrikesRange, Checkpoint, OptionsPurchase, DepositPosition, EpochRewards, MaxStrike} from "./AtlanticPutsPoolStructs.sol";

contract AtlanticPutsPool is
    AtlanticPutsPoolState,
    Pausable,
    ReentrancyGuard,
    OwnableRoles,
    ERC721
{
    using StructuredLinkedList for StructuredLinkedList.List;
    using Counters for Counters.Counter;

    uint256 internal constant ADMIN_ROLE = _ROLE_0;
    uint256 internal constant MANAGED_CONTRACT_ROLE = _ROLE_1;
    uint256 internal constant BOOSTRAPPER_ROLE = _ROLE_2;
    uint256 internal constant WHITELISTED_CONTRACT_ROLE = _ROLE_3;

    Counters.Counter internal _tokenIdCounter;

    /**
     * @notice Structured linked list for max strikes
     * @dev    epoch => strike list
     */
    mapping(uint256 => StructuredLinkedList.List) private epochStrikesList;

    /// @dev Number of deicmals of deposit/premium token
    uint256 private immutable COLLATERAL_TOKEN_DECIMALS;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(
        Contracts[] memory _types,
        address[] memory _addresses,
        string[2] memory _nftDetails,
        address collateralToken
    ) ERC721(_nftDetails[0], _nftDetails[1]) {
        // Invalid array lengths
        _validate(_types.length == _addresses.length, 0);
        for (uint256 i; i < _types.length; ) {
            // Zero address
            _validate(_addresses[i] != address(0), 1);
            addresses[_types[i]] = _addresses[i];
            unchecked {
                ++i;
            }
        }
        COLLATERAL_TOKEN_DECIMALS = IERC20(collateralToken).decimals();
        _setOwner(msg.sender);
        _grantRoles(msg.sender, ADMIN_ROLE);
        _grantRoles(msg.sender, MANAGED_CONTRACT_ROLE);
        _grantRoles(msg.sender, BOOSTRAPPER_ROLE);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       PUBLIC METHODS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice        Burn deposit tokens.
     * @param tokenId ID of the deposit position.
     */
    function burn(uint256 tokenId) public {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert Unauthorized();
        _burn(tokenId);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        PUBLIC VIEWS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice                Get amount amount of underlying to
     *                        be unwinded against options.
     * @param  _optionStrike  Strike price of the option.
     * @param  _optionsAmount Amount of options to unwind.
     * @return unwindAmount
     */
    function getUnwindAmount(
        uint256 _optionStrike,
        uint256 _optionsAmount
    ) public view returns (uint256 unwindAmount) {
        if (_optionStrike < getUsdPrice()) {
            unwindAmount = (_optionsAmount * _optionStrike) / getUsdPrice();
        } else {
            unwindAmount = _optionsAmount;
        }
    }

    /**
     * @notice       Calculate Pnl for exercising options.
     * @param price  price of BaseToken.
     * @param strike strike price of the option.
     * @param amount amount of options.
     */
    function calculatePnl(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) public view returns (uint256) {
        if (price == 0) price = getUsdPrice();
        return strike > price ? (strikeMulAmount((strike - price), amount)) : 0;
    }

    /**
     * @notice                  Calculate funding fees based on days
     *                          left till expiry.
     * @param _collateralAccess Amount of collateral borrowed.
     * @param _entryTimestamp   Timestamp of entry of unlockCollatera().
     *                          which is used to calc. how much funding
     *                          is to be charged.
     * @return fees
     */
    function calculateFundingFees(
        uint256 _collateralAccess,
        uint256 _entryTimestamp
    ) public view returns (uint256 fees) {
        fees =
            ((_epochData[currentEpoch].expiryTime - _entryTimestamp) /
                vaultConfig[VaultConfig.FundingInterval]) *
            vaultConfig[VaultConfig.BaseFundingRate];

        fees =
            ((_collateralAccess * (FEE_BPS_PRECISION + fees)) /
                FEE_BPS_PRECISION) -
            _collateralAccess;
    }

    /**
     * @notice        Calculate Fees for settlement of options.
     * @param  account Account to consider for fee discount.
     * @param  pnl     total pnl.
     * @return fees
     * */
    function calculateSettlementFees(
        address account,
        uint256 pnl
    ) public view returns (uint256 fees) {
        fees = IDopexFeeStrategy(addresses[Contracts.FeeStrategy]).getFeeBps({
            feeType: SETTLEMENT_FEES_KEY,
            user: account,
            useDiscount: vaultConfig[VaultConfig.UseDiscount] == 1
                ? true
                : false
        });

        fees = ((pnl * (FEE_BPS_PRECISION + fees)) / FEE_BPS_PRECISION) - pnl;
    }

    /**
     * @notice          Calculate Fees for purchase.
     * @param  strike   strike price of the BaseToken option.
     * @param  amount   amount of options being bought.
     * @return finalFee purchase fee in QuoteToken.
     */
    function calculatePurchaseFees(
        address account,
        uint256 strike,
        uint256 amount
    ) public view returns (uint256 finalFee) {
        uint256 feeBps = IDopexFeeStrategy(addresses[Contracts.FeeStrategy])
            .getFeeBps({
                feeType: PURCHASE_FEES_KEY,
                user: account,
                useDiscount: vaultConfig[VaultConfig.UseDiscount] == 1
                    ? true
                    : false
            });

        finalFee =
            (((amount * (FEE_BPS_PRECISION + feeBps)) / FEE_BPS_PRECISION) -
                amount) /
            10 ** (OPTION_TOKEN_DECIMALS - COLLATERAL_TOKEN_DECIMALS);

        if (getUsdPrice() < strike) {
            uint256 feeMultiplier = (((strike * 100) / (getUsdPrice())) - 100) +
                100;
            finalFee = (feeMultiplier * finalFee) / 100;
        }
    }

    /**
     * @notice         Calculate premium for an option.
     * @param  _strike Strike price of the option.
     * @param  _amount Amount of options.
     * @return premium in QuoteToken.
     */
    function calculatePremium(
        uint256 _strike,
        uint256 _amount
    ) public view returns (uint256 premium) {
        uint256 currentPrice = getUsdPrice();
        premium = strikeMulAmount({
            strike: IOptionPricing(addresses[Contracts.OptionPricing])
                .getOptionPrice({
                    isPut: true,
                    expiry: _epochData[currentEpoch].expiryTime,
                    strike: _strike,
                    lastPrice: currentPrice,
                    baseIv: getVolatility(_strike)
                }),
            amount: _amount
        });
    }

    /**
     * @notice       Returns the price of the BaseToken in USD.
     * @return price Price of the base token in 1e8 decimals.
     */
    function getUsdPrice() public view returns (uint256) {
        return
            IPriceOracle(addresses[Contracts.PriceOracle]).getPrice({
                token: addresses[Contracts.BaseToken],
                maximise: false,
                includeAmmPrice: false,
                useSwapPricing: false
            }) / 10 ** (PRICE_ORACLE_DECIMALS - STRIKE_DECIMALS);
    }

    /**
     * @notice        Returns the volatility from the volatility oracle
     * @param _strike Strike of the option
     */
    function getVolatility(uint256 _strike) public view returns (uint256) {
        return
            (IVolatilityOracle(addresses[Contracts.VolatilityOracle])
                .getVolatility(_strike) *
                (FEE_BPS_PRECISION + vaultConfig[VaultConfig.IvBoost])) /
            FEE_BPS_PRECISION;
    }

    /**
     * @notice         Multiply strike and amount depending on strike
     *                 and options decimals.
     * @param  strike Option strike.
     * @param  amount Amount of options.
     * @return result  Product of strike and amount in collateral/quote
     *                 token decimals.
     */
    function strikeMulAmount(
        uint256 strike,
        uint256 amount
    ) public view returns (uint256 result) {
        uint256 divisor = (STRIKE_DECIMALS + OPTION_TOKEN_DECIMALS) -
            COLLATERAL_TOKEN_DECIMALS;
        return ((strike * amount) / 10 ** divisor);
    }

    /**
     * @notice         A view fn to check if the current epoch of the
     *                 pool is within the exercise window or not.
     * @return whether Whether the current epoch is within exercise
     *                 window of options.
     */
    function isWithinExerciseWindow() public view returns (bool) {
        uint256 expiry = _epochData[currentEpoch].expiryTime;
        if (expiry == 0) return false;
        return
            block.timestamp >=
            (expiry - vaultConfig[VaultConfig.ExpiryWindow]) &&
            block.timestamp <= expiry;
    }

    /**
     * @notice            A view fn to get the state of the options.
     *                    Although by default it returns the state of
     *                    the option but if the epoch of the options
     *                    are expired it will return the state as
     *                    settled.
     * @param _purchaseId ID of the options purchase.
     * @return state      State of the options.
     */
    function getOptionsState(
        uint256 _purchaseId
    ) public view returns (OptionsState) {
        uint256 epoch = _optionsPositions[_purchaseId].epoch;
        if (block.timestamp >= _epochData[epoch].expiryTime) {
            return OptionsState.Settled;
        } else {
            return _optionsPositions[_purchaseId].state;
        }
    }

    /**
     * @param _depositId Epoch of atlantic pool to inquire
     * @return depositAmount Total deposits of user
     * @return premium       Total premiums earned
     * @return borrowFees    Total borrowFees fees earned
     * @return underlying    Total underlying earned on unwinds
     */
    function getWithdrawable(
        uint256 _depositId
    )
        public
        view
        returns (
            uint256 depositAmount,
            uint256 premium,
            uint256 borrowFees,
            uint256 underlying,
            uint256[] memory rewards
        )
    {
        DepositPosition memory userDeposit = _depositPositions[_depositId];
        rewards = new uint256[](
            epochMaxStrikeCheckpoints[userDeposit.epoch][userDeposit.strike]
                .rewardRates
                .length
        );

        rewards = epochMaxStrikeCheckpoints[userDeposit.epoch][
            userDeposit.strike
        ].rewardRates;

        _validate(userDeposit.depositor == msg.sender, 16);

        Checkpoint memory checkpoint = epochMaxStrikeCheckpoints[
            userDeposit.epoch
        ][userDeposit.strike].checkpoints[userDeposit.checkpoint];

        for (uint256 i; i < rewards.length; ) {
            rewards[i] =
                (((userDeposit.liquidity * checkpoint.activeCollateral) /
                    checkpoint.totalLiquidity) * rewards[i]) /
                10 ** COLLATERAL_TOKEN_DECIMALS;

            unchecked {
                ++i;
            }
        }

        borrowFees +=
            (userDeposit.liquidity * checkpoint.borrowFeesAccrued) /
            checkpoint.totalLiquidity;

        premium +=
            (userDeposit.liquidity * checkpoint.premiumAccrued) /
            checkpoint.totalLiquidity;

        underlying +=
            (userDeposit.liquidity * checkpoint.underlyingAccrued) /
            checkpoint.totalLiquidity;

        depositAmount +=
            (userDeposit.liquidity * checkpoint.liquidityBalance) /
            checkpoint.totalLiquidity;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      EXTERNAL METHODS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice             Gracefully exercises an atlantic
     *                     sends collateral to integrated protocol,
     *                     underlying to writers.
     * @param unwindAmount Amount charged from caller (unwind amount + fees).
     * @param purchaseId   Options purchase id.
     */
    function unwind(
        uint256 purchaseId,
        uint256 unwindAmount
    ) external onlyRoles(MANAGED_CONTRACT_ROLE) {
        _whenNotPaused();

        _validate(_isVaultBootstrapped(currentEpoch), 7);

        OptionsPurchase memory _userOptionsPurchase = _optionsPositions[
            purchaseId
        ];

        _validate(_userOptionsPurchase.delegate == msg.sender, 9);
        _validate(_userOptionsPurchase.state == OptionsState.Unlocked, 10);

        uint256 expectedUnwindAmount = getUnwindAmount(
            _userOptionsPurchase.optionStrike,
            _userOptionsPurchase.optionsAmount
        );

        uint256 collateralAccess = strikeMulAmount(
            _userOptionsPurchase.optionStrike,
            _userOptionsPurchase.optionsAmount
        );

        for (uint256 i; i < _userOptionsPurchase.strikes.length; ) {
            _unwind({
                epoch: _userOptionsPurchase.epoch,
                maxStrike: _userOptionsPurchase.strikes[i],
                underlyingAmount: ((
                    unwindAmount > expectedUnwindAmount
                        ? expectedUnwindAmount
                        : unwindAmount
                ) * _userOptionsPurchase.weights[i]) / WEIGHTS_MUL_DIV,
                collateralAmount: (collateralAccess *
                    _userOptionsPurchase.weights[i]) / WEIGHTS_MUL_DIV,
                checkpoint: _userOptionsPurchase.checkpoints[i]
            });

            unchecked {
                ++i;
            }
        }

        // Transfer excess to user.
        if (unwindAmount > expectedUnwindAmount) {
            _safeTransfer({
                _token: addresses[Contracts.BaseToken],
                _to: _userOptionsPurchase.user,
                _amount: unwindAmount - expectedUnwindAmount
            });
        }

        _safeTransferFrom({
            _token: addresses[Contracts.BaseToken],
            _from: msg.sender,
            _to: address(this),
            _amount: unwindAmount
        });

        delete _optionsPositions[purchaseId];
    }

    /**
     * @notice             Callable by managed contracts that wish
     *                     to relock collateral that was unlocked previously.
     * @param relockAmount Amount of collateral to relock.
     * @param purchaseId   User options purchase id.
     */
    function relockCollateral(
        uint256 purchaseId,
        uint256 relockAmount
    ) external onlyRoles(MANAGED_CONTRACT_ROLE) {
        _whenNotPaused();

        _validate(_isVaultBootstrapped(currentEpoch), 7);

        OptionsPurchase memory _userOptionsPurchase = _optionsPositions[
            purchaseId
        ];

        _validate(_userOptionsPurchase.delegate == msg.sender, 9);
        _validate(_userOptionsPurchase.state == OptionsState.Unlocked, 13);

        uint256 collateralAccess = strikeMulAmount(
            _userOptionsPurchase.optionStrike,
            _userOptionsPurchase.optionsAmount
        );

        uint256 fundingRefund = calculateFundingFees(
            collateralAccess,
            _userOptionsPurchase.unlockEntryTimestamp
        );

        /// @dev refund = funding charged previsouly - funding charged for borrowing
        fundingRefund =
            fundingRefund -
            (fundingRefund -
                calculateFundingFees(collateralAccess, block.timestamp));

        if (collateralAccess > relockAmount) {
            /**
             * Settle the option if fail to relock atleast collateral amount
             * to disallow reuse of options.
             * */
            _optionsPositions[purchaseId].state = OptionsState.Settled;
            delete fundingRefund;
        } else {
            _optionsPositions[purchaseId].state = OptionsState.Active;
        }

        for (uint256 i; i < _userOptionsPurchase.strikes.length; ) {
            _relockCollateral({
                epoch: _userOptionsPurchase.epoch,
                maxStrike: _userOptionsPurchase.strikes[i],
                collateralAmount: (((
                    relockAmount > collateralAccess
                        ? collateralAccess
                        : relockAmount
                ) * _userOptionsPurchase.weights[i]) / WEIGHTS_MUL_DIV),
                borrowFeesRefund: ((fundingRefund *
                    _userOptionsPurchase.weights[i]) / WEIGHTS_MUL_DIV),
                checkpoint: _userOptionsPurchase.checkpoints[i]
            });

            unchecked {
                ++i;
            }
        }

        // Transfer to user any excess.
        if (collateralAccess < relockAmount) {
            _safeTransfer({
                _token: addresses[Contracts.QuoteToken],
                _to: _userOptionsPurchase.user,
                _amount: relockAmount - collateralAccess
            });
        }

        _safeTransferFrom({
            _token: addresses[Contracts.QuoteToken],
            _from: msg.sender,
            _to: address(this),
            _amount: relockAmount
        });

        if (fundingRefund != 0) {
            _safeTransfer({
                _token: addresses[Contracts.QuoteToken],
                _to: _userOptionsPurchase.user,
                _amount: fundingRefund
            });
        }
    }

    /**
     * @notice                    Unlock collateral to borrow against AP option.
     *                            Only Callable by managed contracts.
     * @param  purchaseId         User options purchase ID
     * @param  to                 Collateral to transfer to
     * @return unlockedCollateral Amount of collateral unlocked plus fees
     */
    function unlockCollateral(
        uint256 purchaseId,
        address to
    )
        external
        nonReentrant
        onlyRoles(MANAGED_CONTRACT_ROLE)
        returns (uint256 unlockedCollateral)
    {
        _whenNotPaused();

        _validate(_isVaultBootstrapped(currentEpoch), 7);

        OptionsPurchase memory _userOptionsPurchase = _optionsPositions[
            purchaseId
        ];

        unlockedCollateral = strikeMulAmount(
            _userOptionsPurchase.optionStrike,
            _userOptionsPurchase.optionsAmount
        );

        _validate(_userOptionsPurchase.delegate == msg.sender, 9);
        // Cannot unlock collateral after expiry
        _validate(getOptionsState(purchaseId) == OptionsState.Active, 10);

        _userOptionsPurchase.state = OptionsState.Unlocked;
        _userOptionsPurchase.unlockEntryTimestamp = block.timestamp;

        uint256 borrowFees = calculateFundingFees(
            unlockedCollateral,
            block.timestamp
        );

        for (uint256 i; i < _userOptionsPurchase.strikes.length; ) {
            _unlockCollateral({
                epoch: _userOptionsPurchase.epoch,
                maxStrike: _userOptionsPurchase.strikes[i],
                collateralAmount: (_userOptionsPurchase.weights[i] *
                    unlockedCollateral) / WEIGHTS_MUL_DIV,
                borrowFees: (_userOptionsPurchase.weights[i] * borrowFees) /
                    WEIGHTS_MUL_DIV,
                checkpoint: _userOptionsPurchase.checkpoints[i]
            });

            unchecked {
                ++i;
            }
        }

        _optionsPositions[purchaseId] = _userOptionsPurchase;

        /// @dev Transfer out collateral
        _safeTransfer({
            _token: addresses[Contracts.QuoteToken],
            _to: to,
            _amount: unlockedCollateral
        });

        _safeTransferFrom({
            _token: addresses[Contracts.QuoteToken],
            _from: msg.sender,
            _to: address(this),
            _amount: borrowFees
        });
    }

    /**
     * @notice           Purchases puts for the current epoch
     * @param _strike    Strike index for current epoch
     * @param _amount    Amount of puts to purchase
     * @param _account   Address of the user options were purchased
     *                   on behalf of.
     * @param _delegate  Address of the delegate who will be in charge
     *                   of the options.
     * @return purchaseId
     */
    function purchase(
        uint256 _strike,
        uint256 _amount,
        address _delegate,
        address _account
    )
        external
        nonReentrant
        onlyRoles(MANAGED_CONTRACT_ROLE)
        returns (uint256 purchaseId)
    {
        _whenNotPaused();
        _validate(!isWithinExerciseWindow(), 20);

        uint256 epoch = currentEpoch;

        _validate(_isVaultBootstrapped(epoch), 7);
        _validate(_account != address(0), 1);
        _validateParams(_strike, _amount, epoch, _delegate);

        // Calculate liquidity required
        uint256 collateralRequired = strikeMulAmount(_strike, _amount);

        // Should have adequate cumulative liquidity
        _validate(_epochData[epoch].totalLiquidity >= collateralRequired, 11);

        // Price/premium of option
        uint256 premium = calculatePremium(_strike, _amount);

        // Fees on top of premium for fee distributor
        uint256 fees = calculatePurchaseFees({
            account: _account,
            strike: _strike,
            amount: _amount
        });

        purchaseId = _newPurchasePosition({
            _user: _account,
            _delegate: _delegate,
            _strike: _strike,
            _amount: _amount,
            _epoch: epoch
        });

        _squeezeMaxStrikes({
            epoch: epoch,
            putStrike: _strike,
            collateralRequired: collateralRequired,
            premium: premium,
            purchaseId: purchaseId
        });

        unchecked {
            _epochData[epoch].totalLiquidity -= collateralRequired;
            _epochData[epoch].totalActiveCollateral += collateralRequired;
        }

        _safeTransferFrom({
            _token: addresses[Contracts.QuoteToken],
            _from: msg.sender,
            _to: address(this),
            _amount: premium
        });

        _safeTransferFrom({
            _token: addresses[Contracts.QuoteToken],
            _from: msg.sender,
            _to: addresses[Contracts.FeeDistributor],
            _amount: fees
        });

        emit NewPurchase(
            epoch,
            purchaseId,
            premium,
            fees,
            _account,
            msg.sender
        );
    }

    /**
     * @notice           Deposits USD into the ssov-p to mint puts in the
     *                   current epoch for selected strikes
     * @param _maxStrike Exact price of strike in 1e8 decimals
     * @param _liquidity Amount of liquidity to provide in quote token decimals
     * @param _user      Address of the user to deposit for
     */
    function deposit(
        uint256 _maxStrike,
        uint256 _liquidity,
        address _user
    ) external nonReentrant returns (uint256 depositId) {
        _isEligibleSender();
        _whenNotPaused();
        uint256 epoch = currentEpoch;
        _validate(_isVaultBootstrapped(epoch), 7);
        _validate(_maxStrike <= getUsdPrice(), 6);
        _validateParams(_maxStrike, _liquidity, epoch, _user);

        uint256 checkpoint = _updateCheckpoint(epoch, _maxStrike, _liquidity);

        depositId = _newDepositPosition({
            _epoch: epoch,
            _liquidity: _liquidity,
            _maxStrike: _maxStrike,
            _checkpoint: checkpoint,
            _user: _user
        });

        _epochData[epoch].totalLiquidity += _liquidity;

        _safeTransferFrom(
            addresses[Contracts.QuoteToken],
            msg.sender,
            address(this),
            _liquidity
        );

        // Emit event
        emit NewDeposit(epoch, _maxStrike, _liquidity, _user, msg.sender);
    }

    /**
     * @notice                        Withdraws balances for a strike from epoch
     *                                deposted in a epoch.
     * @param depositIds              Deposit Ids of the deposit positions.
     */
    function withdraw(
        uint256[] calldata depositIds,
        address receiver
    ) external nonReentrant {
        _whenNotPaused();

        uint256 epoch;
        uint256[] memory rewards;
        uint256 premium;
        uint256 userWithdrawableAmount;
        uint256 borrowFees;
        uint256 underlying;
        for (uint256 i; i < depositIds.length; ) {
            epoch = _depositPositions[depositIds[i]].epoch;

            _validate(_epochData[epoch].state == EpochState.Expired, 4);

            (
                userWithdrawableAmount,
                premium,
                borrowFees,
                underlying,
                rewards
            ) = getWithdrawable(depositIds[i]);

            burn(depositIds[i]);
            delete _depositPositions[depositIds[i]];

            if (underlying != 0) {
                _safeTransfer({
                    _token: addresses[Contracts.BaseToken],
                    _to: receiver,
                    _amount: underlying
                });
            }

            if (premium + userWithdrawableAmount + borrowFees != 0) {
                _safeTransfer({
                    _token: addresses[Contracts.QuoteToken],
                    _to: receiver,
                    _amount: premium + userWithdrawableAmount + borrowFees
                });
            }

            for (uint256 j; j < rewards.length; ) {
                if (rewards[j] != 0) {
                    _safeTransfer({
                        _token: _epochRewards[epoch].rewardTokens[j],
                        _to: receiver,
                        _amount: rewards[j]
                    });
                }
                unchecked {
                    ++j;
                }
            }

            emit Withdraw(
                depositIds[i],
                receiver,
                userWithdrawableAmount,
                borrowFees,
                premium,
                underlying,
                rewards
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Sets the current epoch as expired.
    function expireEpoch() external nonReentrant {
        uint256 epoch = currentEpoch;
        _validate(_epochData[epoch].state != EpochState.Expired, 17);
        uint256 epochExpiry = _epochData[epoch].expiryTime;
        if (!paused()) {
            _validate((block.timestamp >= epochExpiry), 18);
            _validate(
                block.timestamp <=
                    epochExpiry + vaultConfig[VaultConfig.ExpireDelayTolerance],
                2
            );
        }
        _allocateRewardsForStrikes(epoch);
        _epochData[epoch].settlementPrice = getUsdPrice();
        _epochData[epoch].state = EpochState.Expired;
        emit EpochExpired(msg.sender, getUsdPrice());
    }

    /// @notice Sets the current epoch as expired. Only can be called by DEFAULT_ADMIN_ROLE.
    /// @param settlementPrice The settlement price
    function expireEpoch(uint256 settlementPrice) external {
        _whenNotPaused();
        uint256 epoch = currentEpoch;
        _validate(_epochData[epoch].state == EpochState.Expired, 17);
        _validate(
            (block.timestamp >
                _epochData[epoch].expiryTime +
                    vaultConfig[VaultConfig.ExpireDelayTolerance]),
            19
        );
        _allocateRewardsForStrikes(epoch);
        _epochData[epoch].settlementPrice = settlementPrice;
        _epochData[epoch].state = EpochState.Expired;

        emit EpochExpired(msg.sender, settlementPrice);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       EXTERNAL VIEWS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice                 Get OptionsPurchase instance for a given tokenId.
     * @param  _tokenId        ID of the options purchase.
     * @return OptionsPurchase Options purchase data.
     */
    function getOptionsPurchase(
        uint256 _tokenId
    ) external view returns (OptionsPurchase memory) {
        return _optionsPositions[_tokenId];
    }

    /**
     * @notice                 Get OptionsPurchase instance for a given tokenId.
     * @param  _tokenId        ID of the options purchase.
     * @return DepositPosition Deposit position data.
     */
    function getDepositPosition(
        uint256 _tokenId
    ) external view returns (DepositPosition memory) {
        return _depositPositions[_tokenId];
    }

    /**
     * @notice              Get checkpoints of a maxstrike in a epoch.
     * @param  _epoch       Epoch of the pool.
     * @param  _maxStrike   Max strike to query for.
     * @return _checkpoints array of checkpoints of a max strike.
     */
    function getEpochCheckpoints(
        uint256 _epoch,
        uint256 _maxStrike
    ) external view returns (Checkpoint[] memory _checkpoints) {
        _checkpoints = new Checkpoint[](
            epochMaxStrikeCheckpointsLength[_epoch][_maxStrike]
        );

        for (
            uint256 i;
            i < epochMaxStrikeCheckpointsLength[_epoch][_maxStrike];

        ) {
            _checkpoints[i] = epochMaxStrikeCheckpoints[_epoch][_maxStrike]
                .checkpoints[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice            Fetches all max strikes written in a epoch.
     * @param  epoch      Epoch of the pool.
     * @return maxStrikes
     */
    function getEpochStrikes(
        uint256 epoch
    ) external view returns (uint256[] memory maxStrikes) {
        maxStrikes = new uint256[](epochStrikesList[epoch].sizeOf());

        uint256 nextNode = _epochData[epoch].maxStrikesRange.highest;
        uint256 iterator;
        while (nextNode != 0) {
            maxStrikes[iterator] = nextNode;
            iterator++;
            (, nextNode) = epochStrikesList[epoch].getNextNode(nextNode);
        }
    }

    /**
     * @notice Fetch the tick size set for the onGoing epoch.
     * @return tickSize
     */
    function getEpochTickSize(uint256 _epoch) external view returns (uint256) {
        return _epochData[_epoch].tickSize;
    }

    /**
     * @notice Fetch epoch data of an epoch.
     * @return DataOfTheEpoch.
     */
    function getEpochData(
        uint256 _epoch
    ) external view returns (EpochData memory) {
        return _epochData[_epoch];
    }

    /**
     * @notice Fetch rewards set for an epoch.
     * @return RewardsAllocated.
     */
    function getEpochRewards(
        uint256 _epoch
    ) external view returns (EpochRewards memory) {
        return _epochRewards[_epoch];
    }

    /**
     * @notice           Get MaxStrike type data.
     * @param _epoch     Epoch of the pool.
     * @param _maxStrike Max strike to query for.
     */
    function getEpochMaxStrikeData(
        uint256 _epoch,
        uint256 _maxStrike
    )
        external
        view
        returns (uint256 activeCollateral, uint256[] memory rewardRates)
    {
        activeCollateral = epochMaxStrikeCheckpoints[_epoch][_maxStrike]
            .activeCollateral;
        rewardRates = new uint256[](
            epochMaxStrikeCheckpoints[_epoch][_maxStrike].rewardRates.length
        );
        rewardRates = epochMaxStrikeCheckpoints[_epoch][_maxStrike].rewardRates;
    }

    /**
     * @notice Fetch checkpoint data of a max strike.
     * @return Checkpoint data.
     */
    function getEpochMaxStrikeCheckpoint(
        uint256 _epoch,
        uint256 _maxStrike,
        uint256 _checkpoint
    ) external view returns (Checkpoint memory) {
        return
            epochMaxStrikeCheckpoints[_epoch][_maxStrike].checkpoints[
                _checkpoint
            ];
    }

    /**
     * @notice Fetch total supply of deposit positions.
     * @return totalSupply
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTERNAL METHODS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice        Add max strike to strikesList (linked list).
     * @param _strike Strike to add to strikesList.
     * @param _epoch  Epoch of the pool.
     */
    function _addMaxStrike(uint256 _strike, uint256 _epoch) internal {
        uint256 highestMaxStrike = _epochData[_epoch].maxStrikesRange.highest;
        uint256 lowestMaxStrike = _epochData[_epoch].maxStrikesRange.lowest;

        if (_strike > highestMaxStrike) {
            _epochData[_epoch].maxStrikesRange.highest = _strike;
        }
        if (_strike < lowestMaxStrike || lowestMaxStrike == 0) {
            _epochData[_epoch].maxStrikesRange.lowest = _strike;
        }

        // Add new max strike after the next largest strike
        uint256 strikeToInsertAfter = _getSortedSpot(_strike, _epoch);

        if (strikeToInsertAfter == 0)
            epochStrikesList[_epoch].pushBack(_strike);
        else
            epochStrikesList[_epoch].insertBefore(strikeToInsertAfter, _strike);
    }

    /**
     * @notice                 Helper function for unlockCollateral().
     * @param epoch            epoch of the vault.
     * @param maxStrike        Max strike to unlock collateral from.
     * @param collateralAmount Amount of collateral to unlock.
     * @param checkpoint      Checkpoint of the max strike.
     */
    function _unlockCollateral(
        uint256 epoch,
        uint256 maxStrike,
        uint256 collateralAmount,
        uint256 borrowFees,
        uint256 checkpoint
    ) internal {
        unchecked {
            epochMaxStrikeCheckpoints[epoch][maxStrike]
                .checkpoints[checkpoint]
                .unlockedCollateral += collateralAmount;

            epochMaxStrikeCheckpoints[epoch][maxStrike]
                .checkpoints[checkpoint]
                .borrowFeesAccrued += borrowFees;

            epochMaxStrikeCheckpoints[epoch][maxStrike]
                .checkpoints[checkpoint]
                .liquidityBalance -= collateralAmount;
        }

        emit UnlockCollateral(epoch, collateralAmount, msg.sender);
    }

    /**
     * @notice                  Update checkpoint states and total unlocked
     *                          collateral for a max strike.
     * @param epoch            Epoch of the pool.
     * @param maxStrike        maxStrike to update states for.
     * @param collateralAmount Collateral token amount relocked.
     * @param borrowFeesRefund Borrow fees to be refunded.
     * @param checkpoint       Checkpoint pointer to update.
     *
     */
    function _relockCollateral(
        uint256 epoch,
        uint256 maxStrike,
        uint256 collateralAmount,
        uint256 borrowFeesRefund,
        uint256 checkpoint
    ) internal {
        unchecked {
            epochMaxStrikeCheckpoints[epoch][maxStrike]
                .checkpoints[checkpoint]
                .liquidityBalance += collateralAmount;

            epochMaxStrikeCheckpoints[epoch][maxStrike]
                .checkpoints[checkpoint]
                .unlockedCollateral -= collateralAmount;

            epochMaxStrikeCheckpoints[epoch][maxStrike]
                .checkpoints[checkpoint]
                .borrowFeesAccrued -= borrowFeesRefund;
        }

        emit RelockCollateral(epoch, maxStrike, collateralAmount, msg.sender);
    }

    /**
     *
     * @notice                  Update unwind related states for corr-
     *                          esponding max strikes.
     * @param epoch            Epoch of the options.
     * @param maxStrike        Max strike to update.
     * @param underlyingAmount Amount of underlying to unwind.
     * @param collateralAmount Equivalent collateral amount com-
     *                          pared to options unwinded.
     * @param checkpoint       Checkpoint to update.
     *
     */
    function _unwind(
        uint256 epoch,
        uint256 maxStrike,
        uint256 underlyingAmount,
        uint256 collateralAmount,
        uint256 checkpoint
    ) internal {
        unchecked {
            epochMaxStrikeCheckpoints[epoch][maxStrike]
                .checkpoints[checkpoint]
                .underlyingAccrued += underlyingAmount;
            epochMaxStrikeCheckpoints[epoch][maxStrike]
                .checkpoints[checkpoint]
                .unlockedCollateral -= collateralAmount;
        }

        emit Unwind(epoch, maxStrike, underlyingAmount, msg.sender);
    }

    /**
     * @notice           Creates a new checkpoint or update existing
     *                   checkpoint.
     * @param  epoch     Epoch of the pool.
     * @param  maxStrike Max strike deposited into.
     * @param  liquidity Amount of deposits / liquidity to add
     *                   to totalLiquidity, totalLiquidityBalance.
     * @return index     Returns the checkpoint number.
     */
    function _updateCheckpoint(
        uint256 epoch,
        uint256 maxStrike,
        uint256 liquidity
    ) internal returns (uint256 index) {
        index = epochMaxStrikeCheckpointsLength[epoch][maxStrike];

        // Add `maxStrike` if it doesn't exist
        if (epochMaxStrikeCheckpoints[epoch][maxStrike].maxStrike == 0) {
            _addMaxStrike(maxStrike, epoch);
            epochMaxStrikeCheckpoints[epoch][maxStrike].maxStrike = maxStrike;
        }

        if (index == 0) {
            epochMaxStrikeCheckpoints[epoch][maxStrike].checkpoints[index] = (
                Checkpoint(block.timestamp, 0, 0, 0, 0, liquidity, liquidity, 0)
            );
            unchecked {
                ++epochMaxStrikeCheckpointsLength[epoch][maxStrike];
            }
        } else {
            Checkpoint memory currentCheckpoint = epochMaxStrikeCheckpoints[
                epoch
            ][maxStrike].checkpoints[index - 1];

            /**
             * @dev Check if checkpoint interval was exceeded
             *      compared to previous checkpoint start time
             *      if yes then create a new checkpoint or
             *      else accumulate to previous checkpoint.
             */

            /** @dev If a checkpoint's options have active collateral,
             *       add liquidity to next checkpoint.
             */
            if (currentCheckpoint.activeCollateral != 0) {
                epochMaxStrikeCheckpoints[epoch][maxStrike]
                    .checkpoints[index]
                    .startTime = block.timestamp;
                epochMaxStrikeCheckpoints[epoch][maxStrike]
                    .checkpoints[index]
                    .totalLiquidity += liquidity;
                epochMaxStrikeCheckpoints[epoch][maxStrike]
                    .checkpoints[index]
                    .liquidityBalance += liquidity;
                epochMaxStrikeCheckpointsLength[epoch][maxStrike]++;
            } else {
                unchecked {
                    --index;
                }

                currentCheckpoint.totalLiquidity += liquidity;
                currentCheckpoint.liquidityBalance += liquidity;

                epochMaxStrikeCheckpoints[epoch][maxStrike].checkpoints[
                        index
                    ] = currentCheckpoint;
            }
        }
    }

    /**
     * @notice            Create a deposit position instance and update ID counter.
     * @param _epoch      Epoch of the pool.
     * @param _liquidity  Amount of collateral token deposited.
     * @param _maxStrike     Max strike deposited into.
     * @param _checkpoint Checkpoint of the max strike deposited into.
     * @param _user       Address of the user to deposit for / is depositing.
     */
    function _newDepositPosition(
        uint256 _epoch,
        uint256 _liquidity,
        uint256 _maxStrike,
        uint256 _checkpoint,
        address _user
    ) internal returns (uint256 depositId) {
        depositId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_user, depositId);

        _depositPositions[depositId].epoch = _epoch;
        _depositPositions[depositId].strike = _maxStrike;
        _depositPositions[depositId].liquidity = _liquidity;
        _depositPositions[depositId].checkpoint = _checkpoint;
        _depositPositions[depositId].depositor = _user;
    }

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        SafeTransferLib.safeTransfer(_token, _to, _amount);
    }

    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        SafeTransferLib.safeTransferFrom(_token, _from, _to, _amount);
    }

    /**
     * @notice             Mint new NFT token anddeposit positon.
     * @param  _user       Address of the user to mint for.
     * @param  _delegate   Address of the delagate who will be
     *                     in charge of the options.
     * @param  _strike     Strike price of the option.
     * @param  _amount     Amount of options.
     * @param  _epoch      Epoch of the pool.
     * @return purchaseId  TokenID and positionID of the purchase position.
     */
    function _newPurchasePosition(
        address _user,
        address _delegate,
        uint256 _strike,
        uint256 _amount,
        uint256 _epoch
    ) internal returns (uint256 purchaseId) {
        purchaseId = purchasePositionsCounter;

        _optionsPositions[purchaseId].user = _user;
        _optionsPositions[purchaseId].delegate = _delegate;
        _optionsPositions[purchaseId].optionStrike = _strike;
        _optionsPositions[purchaseId].optionsAmount = _amount;
        _optionsPositions[purchaseId].epoch = _epoch;
        _optionsPositions[purchaseId].state = OptionsState.Active;

        unchecked {
            ++purchasePositionsCounter;
        }
    }

    /**
     * @notice                    Loop through max strike allocating
     *                            for liquidity for options.
     * @param  epoch              Epoch of the pool.
     * @param  putStrike          Strike to purchase.
     * @param  collateralRequired Amount of collateral to squeeze from
     *                            max strike.
     * @param  premium            Amount of premium to distribute.
     */
    function _squeezeMaxStrikes(
        uint256 epoch,
        uint256 putStrike,
        uint256 collateralRequired,
        uint256 premium,
        uint256 purchaseId
    ) internal {
        uint256 liquidityFromMaxStrikes;
        uint256 liquidityProvided;
        uint256 nextStrike = _epochData[epoch].maxStrikesRange.highest;
        uint256 _liquidityRequired;

        while (liquidityFromMaxStrikes != collateralRequired) {
            // Unchecked because liquidityProvided from _squeeze max strikes
            // will either be equal or less than collateral required
            unchecked {
                _liquidityRequired =
                    collateralRequired -
                    liquidityFromMaxStrikes;
            }

            _validate(putStrike <= nextStrike, 12);

            liquidityProvided = _squeezeMaxStrikeCheckpoints({
                epoch: epoch,
                maxStrike: nextStrike,
                totalCollateralRequired: collateralRequired,
                collateralRequired: _liquidityRequired,
                premium: premium,
                purchaseId: purchaseId
            });

            unchecked {
                epochMaxStrikeCheckpoints[epoch][nextStrike]
                    .activeCollateral += liquidityProvided;

                liquidityFromMaxStrikes += liquidityProvided;
            }

            (, nextStrike) = epochStrikesList[epoch].getNextNode(nextStrike);
        }
    }

    /**
     * @notice                         Squeezes out liquidity from checkpoints within
     *                                 each max strike/
     * @param epoch                    Epoch of the pool
     * @param maxStrike                Max strike to squeeze liquidity from
     * @param totalCollateralRequired  Total amount of liquidity required for the option
     *                                 purchase/
     * @param collateralRequired       As the loop _squeezeMaxStrikes() accumulates
     *                                 liquidity, this value deducts liquidity is
     *                                 accumulated.
     *                                 collateralRequired = totalCollateralRequired - liquidity
     *                                 accumulated till the max strike in the context of the loop
     * @param premium                  Premium to distribute among the checkpoints and maxstrike
     * @param purchaseId               Options purchase ID
     */
    function _squeezeMaxStrikeCheckpoints(
        uint256 epoch,
        uint256 maxStrike,
        uint256 totalCollateralRequired,
        uint256 collateralRequired,
        uint256 premium,
        uint256 purchaseId
    ) internal returns (uint256 liquidityProvided) {
        uint256 startIndex = epochMaxStrikeCheckpointStartIndex[epoch][
            maxStrike
        ];
        //check if previous checkpoint liquidity all consumed
        if (
            startIndex != 0 &&
            epochMaxStrikeCheckpoints[epoch][maxStrike]
                .checkpoints[startIndex - 1]
                .totalLiquidity >
            epochMaxStrikeCheckpoints[epoch][maxStrike]
                .checkpoints[startIndex - 1]
                .activeCollateral
        ) {
            unchecked {
                --startIndex;
            }
        }
        uint256 endIndex;
        // Unchecked since only max strikes with checkpoints != 0 will come to this point
        unchecked {
            endIndex = epochMaxStrikeCheckpointsLength[epoch][maxStrike] - 1;
        }
        uint256 liquidityProvidedFromCurrentMaxStrike;

        while (
            startIndex <= endIndex && liquidityProvided != collateralRequired
        ) {
            uint256 availableLiquidity = epochMaxStrikeCheckpoints[epoch][
                maxStrike
            ].checkpoints[startIndex].totalLiquidity -
                epochMaxStrikeCheckpoints[epoch][maxStrike]
                    .checkpoints[startIndex]
                    .activeCollateral;

            uint256 _requiredLiquidity = collateralRequired - liquidityProvided;

            /// @dev if checkpoint has more than required liquidity
            if (availableLiquidity >= _requiredLiquidity) {
                /// @dev Liquidity provided from current max strike at current index
                unchecked {
                    liquidityProvidedFromCurrentMaxStrike = _requiredLiquidity;
                    liquidityProvided += liquidityProvidedFromCurrentMaxStrike;

                    /// @dev Add to active collateral, later if activeCollateral == totalliquidity, then we stop
                    //  coming back to this checkpoint
                    epochMaxStrikeCheckpoints[epoch][maxStrike]
                        .checkpoints[startIndex]
                        .activeCollateral += _requiredLiquidity;

                    /// @dev Add to premium accured
                    epochMaxStrikeCheckpoints[epoch][maxStrike]
                        .checkpoints[startIndex]
                        .premiumAccrued +=
                        (liquidityProvidedFromCurrentMaxStrike * premium) /
                        totalCollateralRequired;
                }

                _updatePurchasePositionMaxStrikesLiquidity({
                    _purchaseId: purchaseId,
                    _maxStrike: maxStrike,
                    _checkpoint: startIndex,
                    _weight: (liquidityProvidedFromCurrentMaxStrike *
                        WEIGHTS_MUL_DIV) / totalCollateralRequired
                });
            } else if (availableLiquidity != 0) {
                /// @dev if checkpoint has less than required liquidity
                liquidityProvidedFromCurrentMaxStrike = availableLiquidity;
                unchecked {
                    liquidityProvided += liquidityProvidedFromCurrentMaxStrike;

                    epochMaxStrikeCheckpoints[epoch][maxStrike]
                        .checkpoints[startIndex]
                        .activeCollateral += liquidityProvided;

                    /// @dev Add to premium accured
                    epochMaxStrikeCheckpoints[epoch][maxStrike]
                        .checkpoints[startIndex]
                        .premiumAccrued +=
                        (liquidityProvidedFromCurrentMaxStrike * premium) /
                        totalCollateralRequired;
                }

                _updatePurchasePositionMaxStrikesLiquidity({
                    _purchaseId: purchaseId,
                    _maxStrike: maxStrike,
                    _checkpoint: startIndex,
                    _weight: (liquidityProvidedFromCurrentMaxStrike *
                        WEIGHTS_MUL_DIV) / totalCollateralRequired
                });

                unchecked {
                    ++epochMaxStrikeCheckpointStartIndex[epoch][maxStrike];
                }
            }
            unchecked {
                ++startIndex;
            }
        }
    }

    /**
     * @notice      Allocate rewards for strikes based
     *              on active collateral present.
     * @param epoch Epoch of the pool
     */
    function _allocateRewardsForStrikes(uint256 epoch) internal {
        uint256 nextNode = _epochData[epoch].maxStrikesRange.highest;
        uint256 iterator;

        EpochRewards memory epochRewards = _epochRewards[epoch];
        uint256 activeCollateral;
        uint256 totalEpochActiveCollateral = _epochData[epoch]
            .totalActiveCollateral;
        while (nextNode != 0) {
            activeCollateral = epochMaxStrikeCheckpoints[epoch][nextNode]
                .activeCollateral;

            for (uint256 i; i < epochRewards.rewardTokens.length; ) {
                /**
                 * rewards allocated for a strike:
                 *               strike's active collateral
                 *    rewards *  --------------------------
                 *               total active collateral
                 *
                 * Reward rate per active collateral:
                 *
                 *      rewards allocated
                 *      ------------------
                 *   strike's active collateral
                 */
                epochMaxStrikeCheckpoints[epoch][nextNode].rewardRates.push(
                    (((activeCollateral * epochRewards.amounts[i]) /
                        totalEpochActiveCollateral) *
                        (10 ** COLLATERAL_TOKEN_DECIMALS)) / activeCollateral
                );
                unchecked {
                    ++i;
                }
            }

            iterator++;
            (, nextNode) = epochStrikesList[epoch].getNextNode(nextNode);
        }
    }

    /**
     * @notice            Pushes new item into strikes, checkpoints and
     *                    weights in a single-go for a options purchase
     *                    instance.
     * @param _purchaseId Options purchase ID
     * @param _maxStrike  Maxstrike to push into strikes array of the
     *                    options purchase.
     * @param _checkpoint Checkpoint to push into checkpoints array of
     *                    the options purchase.
     * @param _weight     Weight (%) to push into weights array of the
     *                    options purchase in 1e18 decimals.
     */
    function _updatePurchasePositionMaxStrikesLiquidity(
        uint256 _purchaseId,
        uint256 _maxStrike,
        uint256 _checkpoint,
        uint256 _weight
    ) internal {
        _optionsPositions[_purchaseId].strikes.push(_maxStrike);
        _optionsPositions[_purchaseId].checkpoints.push(_checkpoint);
        _optionsPositions[_purchaseId].weights.push(_weight);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       INTERNAL VIEWS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Validate params for purchase and deposit.
     * @param _strike Strike price for the option.
     * @param _amount Amount of options or liquidity added.
     * @param _epoch  Epoch of the pool.
     * @param _user   User address provided.
     */

    function _validateParams(
        uint256 _strike,
        uint256 _amount,
        uint256 _epoch,
        address _user
    ) internal view {
        _validate(_user != address(0), 1);
        _validate(_amount != 0, 3);
        _validate(
            _strike != 0 && _strike % _epochData[_epoch].tickSize == 0,
            5
        );
    }

    /**
     * @notice              Revert-er function to revert with string error message.
     * @param trueCondition Similar to require, a condition that has to be false
     *                      to revert.
     * @param errorCode     Index in the errors[] that was set in error controller.
     */
    function _validate(bool trueCondition, uint256 errorCode) internal pure {
        if (!trueCondition) {
            revert AtlanticPutsPoolError(errorCode);
        }
    }

    /**
     * @notice       Checks if vault is not expired and bootstrapped.
     * @param  epoch Epoch of the pool.
     * @return isVaultBootstrapped
     */
    function _isVaultBootstrapped(uint256 epoch) internal view returns (bool) {
        return
            _epochData[epoch].state == EpochState.BootStrapped &&
            block.timestamp <= _epochData[epoch].expiryTime;
    }

    /**
     * @param  _value Value of max strike / node
     * @param  _epoch Epoch of the pool
     * @return tail   of the linked list
     */
    function _getSortedSpot(
        uint256 _value,
        uint256 _epoch
    ) private view returns (uint256) {
        if (epochStrikesList[_epoch].sizeOf() == 0) {
            return 0;
        }

        uint256 next;
        (, next) = epochStrikesList[_epoch].getAdjacent(0, true);
        // Switch to descending
        while (
            (next != 0) &&
            (
                (_value <
                    (
                        epochMaxStrikeCheckpoints[_epoch][next].maxStrike != 0
                            ? next
                            : 0
                    ))
            )
        ) {
            next = epochStrikesList[_epoch].list[next][true];
        }
        return next;
    }

    /**
     * @dev         checks for contract or eoa addresses
     * @param  addr the address to check
     * @return bool whether the passed address is a contract address
     */
    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size != 0;
    }

    /**
     * @notice Check for whitelisted contracts.
     */
    function _isEligibleSender() private view {
        uint256 size;
        assembly {
            size := extcodesize(caller())
        }
        if (size != 0) {
            _checkRoles(WHITELISTED_CONTRACT_ROLE);
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ADMIN METHODS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice        Set  vault configurations.
     * @param _type   Configuration type.
     * @param _config Configuration parameter.
     */
    function setVaultConfig(
        VaultConfig _type,
        uint256 _config
    ) external onlyRoles(ADMIN_ROLE) {
        vaultConfig[_type] = _config;
        emit VaultConfigSet(_type, _config);
    }

    /**
     * @notice          Sets (adds) a list of addresses to the address list.
     * @dev             an only be called by the owner.
     * @param _type     Contract type to set from Contracs enum
     * @param _address  address of the contract.
     */
    function setAddress(
        Contracts _type,
        address _address
    ) external onlyRoles(ADMIN_ROLE) {
        addresses[_type] = _address;
        emit AddressSet(_type, _address);
    }

    /**
     * @notice Pauses the vault for emergency cases.
     * @dev    Can only be called by the owner.
     */
    function pause() external onlyRoles(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the vault
     * @dev    Can only be called by the owner
     */

    function unpause() external onlyRoles(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Transfers all funds to msg.sender
     * @dev Can only be called by DEFAULT_ADMIN_ROLE
     * @param tokens The list of erc20 tokens to withdraw
     * @param transferNative Whether should transfer the native currency
     */
    function emergencyWithdraw(
        address[] calldata tokens,
        bool transferNative
    ) external onlyRoles(ADMIN_ROLE) returns (bool) {
        _whenPaused();
        if (transferNative) payable(msg.sender).transfer(address(this).balance);

        for (uint256 i; i < tokens.length; ) {
            _safeTransfer(
                tokens[i],
                msg.sender,
                IERC20(tokens[i]).balanceOf(address(this))
            );
            unchecked {
                ++i;
            }
        }

        emit EmergencyWithdraw(msg.sender);

        return true;
    }

    /**
     * @notice              Set rewards for an upcoming epoch.
     * @param _rewardTokens Addresses of the reward tokens.
     * @param _amounts      Amounts of tokens to reward.
     * @param _epoch        Upcoming epoch.
     */
    function setEpochRewards(
        address[] calldata _rewardTokens,
        uint256[] calldata _amounts,
        uint256 _epoch
    ) external onlyRoles(ADMIN_ROLE) {
        _validate(_rewardTokens.length == _amounts.length, 0);
        // Can only set for a future epoch
        _validate(_epoch > currentEpoch, 14);

        // Rewards already set for the epoch.
        _validate(_epochRewards[_epoch].rewardTokens.length == 0, 15);

        for (uint256 i; i < _rewardTokens.length; ) {
            _safeTransferFrom(
                _rewardTokens[i],
                msg.sender,
                address(this),
                _amounts[i]
            );

            _epochRewards[_epoch].rewardTokens.push(_rewardTokens[i]);
            _epochRewards[_epoch].amounts.push(_amounts[i]);
            emit EpochRewardsSet(_epoch, _amounts[i], _rewardTokens[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Reset token counter.
     */
    function resetCounter() external onlyRoles(ADMIN_ROLE) {
        _tokenIdCounter.reset();
    }

    /**
     * @notice Bootstraps a new epoch, sets the strike based on offset% set. To be called after expiry
     *         of every epoch. Ensure strike offset is set before calling this function
     * @param  expiry   Expiry of the epoch to set.
     * @param  tickSize Spacing between max strikes.
     * @return success
     */
    function bootstrap(
        uint256 expiry,
        uint256 tickSize
    ) external nonReentrant onlyRoles(BOOSTRAPPER_ROLE) returns (bool) {
        _validate(expiry > block.timestamp, 2);
        _validate(tickSize != 0, 3);

        uint256 nextEpoch = currentEpoch + 1;

        EpochData memory _vaultState = _epochData[nextEpoch];

        // Prev epoch must be expired
        if (currentEpoch > 0)
            _validate(_epochData[nextEpoch - 1].state == EpochState.Expired, 4);

        _vaultState.startTime = block.timestamp;
        _vaultState.tickSize = tickSize;
        _vaultState.expiryTime = expiry;
        _vaultState.state = EpochState.BootStrapped;

        currentEpoch = nextEpoch;

        _epochData[nextEpoch] = _vaultState;

        emit Bootstrap(nextEpoch);

        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC721 SUPPORT                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

enum OptionsState {
    Settled,
    Active,
    Unlocked
}

enum EpochState {
    InActive,
    BootStrapped,
    Expired,
    Paused
}

enum Contracts {
    QuoteToken,
    BaseToken,
    FeeDistributor,
    FeeStrategy,
    OptionPricing,
    PriceOracle,
    VolatilityOracle,
    Gov
}

enum VaultConfig {
    IvBoost,
    ExpiryWindow,
    FundingInterval,
    BaseFundingRate,
    UseDiscount,
    ExpireDelayTolerance
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// Structs
import {EpochData, MaxStrikesRange, Checkpoint, OptionsPurchase, DepositPosition, EpochRewards, MaxStrike} from "./AtlanticPutsPoolStructs.sol";

// Enums
import {OptionsState, EpochState, Contracts, VaultConfig} from "./AtlanticPutsPoolEnums.sol";

contract AtlanticPutsPoolState {
    uint256 internal constant PURCHASE_FEES_KEY = 0;
    uint256 internal constant SETTLEMENT_FEES_KEY = 1;
    uint256 internal constant FEE_BPS_PRECISION = 10000000;
    uint256 internal constant PRICE_ORACLE_DECIMALS = 30;

    /// @dev Options amounts precision
    uint256 internal constant OPTION_TOKEN_DECIMALS = 18;

    /// @dev Number of decimals for max strikes
    uint256 internal constant STRIKE_DECIMALS = 8;

    /// @dev Max strike weights divisor/multiplier
    uint256 internal constant WEIGHTS_MUL_DIV = 1e18;

    uint256 public currentEpoch;

    uint256 public purchasePositionsCounter = 1;

    mapping(VaultConfig => uint256) public vaultConfig;
    mapping(Contracts => address) public addresses;
    mapping(uint256 => EpochData) internal _epochData;
    mapping(uint256 => EpochRewards) internal _epochRewards;
    mapping(uint256 => DepositPosition) internal _depositPositions;
    mapping(uint256 => OptionsPurchase) internal _optionsPositions;

    /**
     * @notice Checkpoints for a max strike in a epoch
     * @dev    epoch => max strike => Checkpoint[]
     */
    mapping(uint256 => mapping(uint256 => MaxStrike))
        internal epochMaxStrikeCheckpoints;

    mapping(uint256 => mapping(uint256 => uint256))
        internal epochMaxStrikeCheckpointsLength;

    /**
     *  @notice Start index of checkpoint (reference point to
     *           loop from on _squeeze())
     *  @dev    epoch => index
     */
    mapping(uint256 => mapping(uint256 => uint256))
        internal epochMaxStrikeCheckpointStartIndex;

    event EmergencyWithdraw(address sender);

    event Bootstrap(uint256 epoch);

    event NewDeposit(
        uint256 epoch,
        uint256 strike,
        uint256 amount,
        address user,
        address sender
    );

    event NewPurchase(
        uint256 epoch,
        uint256 purchaseId,
        uint256 premium,
        uint256 fee,
        address user,
        address sender
    );

    event Withdraw(
        uint256 depositId,
        address receiver,
        uint256 withdrawableAmount,
        uint256 borrowFees,
        uint256 premium,
        uint256 underlying,
        uint256[] rewards
    );

    event EpochRewardsSet(uint256 epoch, uint256 amount, address rewardToken);

    event Unwind(uint256 epoch, uint256 strike, uint256 amount, address caller);

    event UnlockCollateral(
        uint256 epoch,
        uint256 totalCollateral,
        address caller
    );

    event NewSettle(
        uint256 epoch,
        uint256 strike,
        address user,
        uint256 amount,
        uint256 pnl
    );

    event RelockCollateral(
        uint256 epoch,
        uint256 strike,
        uint256 totalCollateral,
        address caller
    );

    event AddressSet(Contracts _type, address _address);

    event EpochExpired(address sender, uint256 settlementPrice);

    event VaultConfigSet(VaultConfig _type, uint256 _config);

    error AtlanticPutsPoolError(uint256 errorCode);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {OptionsState, EpochState} from "./AtlanticPutsPoolEnums.sol";

struct EpochData {
    uint256 settlementPrice;
    uint256 startTime;
    uint256 expiryTime;
    uint256 totalLiquidity;
    uint256 totalActiveCollateral;
    uint256 fundingRate;
    uint256 tickSize;
    MaxStrikesRange maxStrikesRange;
    EpochState state;
}

struct MaxStrikesRange {
    uint256 highest;
    uint256 lowest;
}

struct Checkpoint {
    uint256 startTime;
    uint256 unlockedCollateral;
    uint256 premiumAccrued;
    uint256 borrowFeesAccrued;
    uint256 underlyingAccrued;
    uint256 totalLiquidity;
    uint256 liquidityBalance;
    uint256 activeCollateral;
}

struct EpochRewards {
    address[] rewardTokens;
    uint256[] amounts;
}

struct OptionsPurchase {
    uint256 epoch;
    uint256 optionStrike;
    uint256 optionsAmount;
    uint256 unlockEntryTimestamp;
    uint256[] strikes;
    uint256[] checkpoints;
    uint256[] weights;
    OptionsState state;
    address user;
    address delegate;
}

struct DepositPosition {
    uint256 epoch;
    uint256 strike;
    uint256 liquidity;
    uint256 checkpoint;
    address depositor;
}

struct MaxStrike {
    uint256 maxStrike;
    uint256 activeCollateral;
    uint256[] rewardRates;
    mapping(uint256 => Checkpoint) checkpoints;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDopexFeeStrategy {
 function getFeeBps(
        uint256 feeType,
        address user,
        bool useDiscount
    ) external view returns (uint256 _feeBps);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/// @title Lighter version of the Openzeppelin Pausable contract
/// @author witherblock
/// @notice Helps pause a contract to block the execution of selected functions
/// @dev Difference from the Openzeppelin version is changing the modifiers to internal fns and requires to reverts
abstract contract Pausable {
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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Internal function to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _whenNotPaused() internal view {
        if (paused()) revert ContractPaused();
    }

    /**
     * @dev Internal function to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _whenPaused() internal view {
        if (!paused()) revert ContractNotPaused();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual {
        _whenNotPaused();
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        _whenPaused();
        _paused = false;
        emit Unpaused(msg.sender);
    }

    error ContractPaused();
    error ContractNotPaused();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.7;

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

    error ReentrancyCall();

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
        if (_status == _ENTERED) revert ReentrancyCall();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOptionPricing {
  function getOptionPrice(
    bool isPut,
    uint256 expiry,
    uint256 strike,
    uint256 lastPrice,
    uint256 baseIv
  ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceOracle {
    function latestAnswer() external view returns (uint256);

    function getUnderlyingPrice() external view returns (uint256);

    function getCollateralPrice() external view returns (uint256);

    function getPrice(
        address token,
        bool maximise,
        bool includeAmmPrice,
        bool useSwapPricing
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVolatilityOracle {
    function getVolatility(uint256 strike) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
/// @dev While the ownable portion follows [EIP-173](https://eips.ethereum.org/EIPS/eip-173)
/// for compatibility, the nomenclature for the 2-step ownership handover
/// may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /// @dev `bytes4(keccak256(bytes("Unauthorized()")))`.
    uint256 private constant _UNAUTHORIZED_ERROR_SELECTOR = 0x82b42900;

    /// @dev `bytes4(keccak256(bytes("NewOwnerIsZeroAddress()")))`.
    uint256 private constant _NEW_OWNER_IS_ZERO_ADDRESS_ERROR_SELECTOR = 0x7448fbae;

    /// @dev `bytes4(keccak256(bytes("NoHandoverRequest()")))`.
    uint256 private constant _NO_HANDOVER_REQUEST_ERROR_SELECTOR = 0x6f5e8818;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by: `not(_OWNER_SLOT_NOT)`.
    /// It is intentionally choosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
            sstore(ownerSlot, newOwner)
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        if (newOwner == address(0)) revert NewOwnerIsZeroAddress();
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will be automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, _NO_HANDOVER_REQUEST_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    function ownershipHandoverValidFor() public view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

/// @notice Simple single owner and multiroles authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
/// @dev While the ownable portion follows [EIP-173](https://eips.ethereum.org/EIPS/eip-173)
/// for compatibility, the nomenclature for the 2-step ownership handover and roles
/// may be unique to this codebase.
abstract contract OwnableRoles is Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `bytes4(keccak256(bytes("Unauthorized()")))`.
    uint256 private constant _UNAUTHORIZED_ERROR_SELECTOR = 0x82b42900;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The `user`'s roles is updated to `roles`.
    /// Each bit of `roles` represents whether the role is set.
    event RolesUpdated(address indexed user, uint256 indexed roles);

    /// @dev `keccak256(bytes("RolesUpdated(address,uint256)"))`.
    uint256 private constant _ROLES_UPDATED_EVENT_SIGNATURE =
        0x715ad5ce61fc9595c7b415289d59cf203f23a94fa06f04af7e489a0a76e1fe26;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The role slot of `user` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _ROLE_SLOT_SEED))
    ///     let roleSlot := keccak256(0x00, 0x20)
    /// ```
    /// This automatically ignores the upper bits of the `user` in case
    /// they are not clean, as well as keep the `keccak256` under 32-bytes.
    ///
    /// Note: This is equal to `_OWNER_SLOT_NOT` in for gas efficiency.
    uint256 private constant _ROLE_SLOT_SEED = 0x8b78c6d8;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Grants the roles directly without authorization guard.
    /// Each bit of `roles` represents the role to turn on.
    function _grantRoles(address user, uint256 roles) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, user)
            let roleSlot := keccak256(0x0c, 0x20)
            // Load the current value and `or` it with `roles`.
            roles := or(sload(roleSlot), roles)
            // Store the new value.
            sstore(roleSlot, roles)
            // Emit the {RolesUpdated} event.
            log3(0, 0, _ROLES_UPDATED_EVENT_SIGNATURE, shr(96, mload(0x0c)), roles)
        }
    }

    /// @dev Removes the roles directly without authorization guard.
    /// Each bit of `roles` represents the role to turn off.
    function _removeRoles(address user, uint256 roles) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, user)
            let roleSlot := keccak256(0x0c, 0x20)
            // Load the current value.
            let currentRoles := sload(roleSlot)
            // Use `and` to compute the intersection of `currentRoles` and `roles`,
            // `xor` it with `currentRoles` to flip the bits in the intersection.
            roles := xor(currentRoles, and(currentRoles, roles))
            // Then, store the new value.
            sstore(roleSlot, roles)
            // Emit the {RolesUpdated} event.
            log3(0, 0, _ROLES_UPDATED_EVENT_SIGNATURE, shr(96, mload(0x0c)), roles)
        }
    }

    /// @dev Throws if the sender does not have any of the `roles`.
    function _checkRoles(uint256 roles) internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, caller())
            // Load the stored value, and if the `and` intersection
            // of the value and `roles` is zero, revert.
            if iszero(and(sload(keccak256(0x0c, 0x20)), roles)) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Throws if the sender is not the owner,
    /// and does not have any of the `roles`.
    /// Checks for ownership first, then lazily checks for roles.
    function _checkOwnerOrRoles(uint256 roles) internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner.
            // Note: `_ROLE_SLOT_SEED` is equal to `_OWNER_SLOT_NOT`.
            if iszero(eq(caller(), sload(not(_ROLE_SLOT_SEED)))) {
                // Compute the role slot.
                mstore(0x0c, _ROLE_SLOT_SEED)
                mstore(0x00, caller())
                // Load the stored value, and if the `and` intersection
                // of the value and `roles` is zero, revert.
                if iszero(and(sload(keccak256(0x0c, 0x20)), roles)) {
                    mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @dev Throws if the sender does not have any of the `roles`,
    /// and is not the owner.
    /// Checks for roles first, then lazily checks for ownership.
    function _checkRolesOrOwner(uint256 roles) internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, caller())
            // Load the stored value, and if the `and` intersection
            // of the value and `roles` is zero, revert.
            if iszero(and(sload(keccak256(0x0c, 0x20)), roles)) {
                // If the caller is not the stored owner.
                // Note: `_ROLE_SLOT_SEED` is equal to `_OWNER_SLOT_NOT`.
                if iszero(eq(caller(), sload(not(_ROLE_SLOT_SEED)))) {
                    mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to grant `user` `roles`.
    /// If the `user` already has a role, then it will be an no-op for the role.
    function grantRoles(address user, uint256 roles) public payable virtual onlyOwner {
        _grantRoles(user, roles);
    }

    /// @dev Allows the owner to remove `user` `roles`.
    /// If the `user` does not have a role, then it will be an no-op for the role.
    function revokeRoles(address user, uint256 roles) public payable virtual onlyOwner {
        _removeRoles(user, roles);
    }

    /// @dev Allow the caller to remove their own roles.
    /// If the caller does not have a role, then it will be an no-op for the role.
    function renounceRoles(uint256 roles) public payable virtual {
        _removeRoles(msg.sender, roles);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `user` has any of `roles`.
    function hasAnyRole(address user, uint256 roles) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, user)
            // Load the stored value, and set the result to whether the
            // `and` intersection of the value and `roles` is not zero.
            result := iszero(iszero(and(sload(keccak256(0x0c, 0x20)), roles)))
        }
    }

    /// @dev Returns whether `user` has all of `roles`.
    function hasAllRoles(address user, uint256 roles) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, user)
            // Whether the stored value is contains all the set bits in `roles`.
            result := eq(and(sload(keccak256(0x0c, 0x20)), roles), roles)
        }
    }

    /// @dev Returns the roles of `user`.
    function rolesOf(address user) public view virtual returns (uint256 roles) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the role slot.
            mstore(0x0c, _ROLE_SLOT_SEED)
            mstore(0x00, user)
            // Load the stored value.
            roles := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Convenience function to return a `roles` bitmap from an array of `ordinals`.
    /// This is meant for frontends like Etherscan, and is therefore not fully optimized.
    /// Not recommended to be called on-chain.
    function rolesFromOrdinals(uint8[] memory ordinals) public pure returns (uint256 roles) {
        /// @solidity memory-safe-assembly
        assembly {
            for { let i := shl(5, mload(ordinals)) } i { i := sub(i, 0x20) } {
                // We don't need to mask the values of `ordinals`, as Solidity
                // cleans dirty upper bits when storing variables into memory.
                roles := or(shl(mload(add(ordinals, i)), 1), roles)
            }
        }
    }

    /// @dev Convenience function to return an array of `ordinals` from the `roles` bitmap.
    /// This is meant for frontends like Etherscan, and is therefore not fully optimized.
    /// Not recommended to be called on-chain.
    function ordinalsFromRoles(uint256 roles) public pure returns (uint8[] memory ordinals) {
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the pointer to the free memory.
            ordinals := mload(0x40)
            let ptr := add(ordinals, 0x20)
            let o := 0
            // The absence of lookup tables, De Bruijn, etc., here is intentional for
            // smaller bytecode, as this function is not meant to be called on-chain.
            for { let t := roles } 1 {} {
                mstore(ptr, o)
                // `shr` 5 is equivalent to multiplying by 0x20.
                // Push back into the ordinals array if the bit is set.
                ptr := add(ptr, shl(5, and(t, 1)))
                o := add(o, 1)
                t := shr(o, roles)
                if iszero(t) { break }
            }
            // Store the length of `ordinals`.
            mstore(ordinals, shr(5, sub(ptr, add(ordinals, 0x20))))
            // Allocate the memory.
            mstore(0x40, ptr)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by an account with `roles`.
    modifier onlyRoles(uint256 roles) virtual {
        _checkRoles(roles);
        _;
    }

    /// @dev Marks a function as only callable by the owner or by an account
    /// with `roles`. Checks for ownership first, then lazily checks for roles.
    modifier onlyOwnerOrRoles(uint256 roles) virtual {
        _checkOwnerOrRoles(roles);
        _;
    }

    /// @dev Marks a function as only callable by an account with `roles`
    /// or the owner. Checks for roles first, then lazily checks for ownership.
    modifier onlyRolesOrOwner(uint256 roles) virtual {
        _checkRolesOrOwner(roles);
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ROLE CONSTANTS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // IYKYK

    uint256 internal constant _ROLE_0 = 1 << 0;
    uint256 internal constant _ROLE_1 = 1 << 1;
    uint256 internal constant _ROLE_2 = 1 << 2;
    uint256 internal constant _ROLE_3 = 1 << 3;
    uint256 internal constant _ROLE_4 = 1 << 4;
    uint256 internal constant _ROLE_5 = 1 << 5;
    uint256 internal constant _ROLE_6 = 1 << 6;
    uint256 internal constant _ROLE_7 = 1 << 7;
    uint256 internal constant _ROLE_8 = 1 << 8;
    uint256 internal constant _ROLE_9 = 1 << 9;
    uint256 internal constant _ROLE_10 = 1 << 10;
    uint256 internal constant _ROLE_11 = 1 << 11;
    uint256 internal constant _ROLE_12 = 1 << 12;
    uint256 internal constant _ROLE_13 = 1 << 13;
    uint256 internal constant _ROLE_14 = 1 << 14;
    uint256 internal constant _ROLE_15 = 1 << 15;
    uint256 internal constant _ROLE_16 = 1 << 16;
    uint256 internal constant _ROLE_17 = 1 << 17;
    uint256 internal constant _ROLE_18 = 1 << 18;
    uint256 internal constant _ROLE_19 = 1 << 19;
    uint256 internal constant _ROLE_20 = 1 << 20;
    uint256 internal constant _ROLE_21 = 1 << 21;
    uint256 internal constant _ROLE_22 = 1 << 22;
    uint256 internal constant _ROLE_23 = 1 << 23;
    uint256 internal constant _ROLE_24 = 1 << 24;
    uint256 internal constant _ROLE_25 = 1 << 25;
    uint256 internal constant _ROLE_26 = 1 << 26;
    uint256 internal constant _ROLE_27 = 1 << 27;
    uint256 internal constant _ROLE_28 = 1 << 28;
    uint256 internal constant _ROLE_29 = 1 << 29;
    uint256 internal constant _ROLE_30 = 1 << 30;
    uint256 internal constant _ROLE_31 = 1 << 31;
    uint256 internal constant _ROLE_32 = 1 << 32;
    uint256 internal constant _ROLE_33 = 1 << 33;
    uint256 internal constant _ROLE_34 = 1 << 34;
    uint256 internal constant _ROLE_35 = 1 << 35;
    uint256 internal constant _ROLE_36 = 1 << 36;
    uint256 internal constant _ROLE_37 = 1 << 37;
    uint256 internal constant _ROLE_38 = 1 << 38;
    uint256 internal constant _ROLE_39 = 1 << 39;
    uint256 internal constant _ROLE_40 = 1 << 40;
    uint256 internal constant _ROLE_41 = 1 << 41;
    uint256 internal constant _ROLE_42 = 1 << 42;
    uint256 internal constant _ROLE_43 = 1 << 43;
    uint256 internal constant _ROLE_44 = 1 << 44;
    uint256 internal constant _ROLE_45 = 1 << 45;
    uint256 internal constant _ROLE_46 = 1 << 46;
    uint256 internal constant _ROLE_47 = 1 << 47;
    uint256 internal constant _ROLE_48 = 1 << 48;
    uint256 internal constant _ROLE_49 = 1 << 49;
    uint256 internal constant _ROLE_50 = 1 << 50;
    uint256 internal constant _ROLE_51 = 1 << 51;
    uint256 internal constant _ROLE_52 = 1 << 52;
    uint256 internal constant _ROLE_53 = 1 << 53;
    uint256 internal constant _ROLE_54 = 1 << 54;
    uint256 internal constant _ROLE_55 = 1 << 55;
    uint256 internal constant _ROLE_56 = 1 << 56;
    uint256 internal constant _ROLE_57 = 1 << 57;
    uint256 internal constant _ROLE_58 = 1 << 58;
    uint256 internal constant _ROLE_59 = 1 << 59;
    uint256 internal constant _ROLE_60 = 1 << 60;
    uint256 internal constant _ROLE_61 = 1 << 61;
    uint256 internal constant _ROLE_62 = 1 << 62;
    uint256 internal constant _ROLE_63 = 1 << 63;
    uint256 internal constant _ROLE_64 = 1 << 64;
    uint256 internal constant _ROLE_65 = 1 << 65;
    uint256 internal constant _ROLE_66 = 1 << 66;
    uint256 internal constant _ROLE_67 = 1 << 67;
    uint256 internal constant _ROLE_68 = 1 << 68;
    uint256 internal constant _ROLE_69 = 1 << 69;
    uint256 internal constant _ROLE_70 = 1 << 70;
    uint256 internal constant _ROLE_71 = 1 << 71;
    uint256 internal constant _ROLE_72 = 1 << 72;
    uint256 internal constant _ROLE_73 = 1 << 73;
    uint256 internal constant _ROLE_74 = 1 << 74;
    uint256 internal constant _ROLE_75 = 1 << 75;
    uint256 internal constant _ROLE_76 = 1 << 76;
    uint256 internal constant _ROLE_77 = 1 << 77;
    uint256 internal constant _ROLE_78 = 1 << 78;
    uint256 internal constant _ROLE_79 = 1 << 79;
    uint256 internal constant _ROLE_80 = 1 << 80;
    uint256 internal constant _ROLE_81 = 1 << 81;
    uint256 internal constant _ROLE_82 = 1 << 82;
    uint256 internal constant _ROLE_83 = 1 << 83;
    uint256 internal constant _ROLE_84 = 1 << 84;
    uint256 internal constant _ROLE_85 = 1 << 85;
    uint256 internal constant _ROLE_86 = 1 << 86;
    uint256 internal constant _ROLE_87 = 1 << 87;
    uint256 internal constant _ROLE_88 = 1 << 88;
    uint256 internal constant _ROLE_89 = 1 << 89;
    uint256 internal constant _ROLE_90 = 1 << 90;
    uint256 internal constant _ROLE_91 = 1 << 91;
    uint256 internal constant _ROLE_92 = 1 << 92;
    uint256 internal constant _ROLE_93 = 1 << 93;
    uint256 internal constant _ROLE_94 = 1 << 94;
    uint256 internal constant _ROLE_95 = 1 << 95;
    uint256 internal constant _ROLE_96 = 1 << 96;
    uint256 internal constant _ROLE_97 = 1 << 97;
    uint256 internal constant _ROLE_98 = 1 << 98;
    uint256 internal constant _ROLE_99 = 1 << 99;
    uint256 internal constant _ROLE_100 = 1 << 100;
    uint256 internal constant _ROLE_101 = 1 << 101;
    uint256 internal constant _ROLE_102 = 1 << 102;
    uint256 internal constant _ROLE_103 = 1 << 103;
    uint256 internal constant _ROLE_104 = 1 << 104;
    uint256 internal constant _ROLE_105 = 1 << 105;
    uint256 internal constant _ROLE_106 = 1 << 106;
    uint256 internal constant _ROLE_107 = 1 << 107;
    uint256 internal constant _ROLE_108 = 1 << 108;
    uint256 internal constant _ROLE_109 = 1 << 109;
    uint256 internal constant _ROLE_110 = 1 << 110;
    uint256 internal constant _ROLE_111 = 1 << 111;
    uint256 internal constant _ROLE_112 = 1 << 112;
    uint256 internal constant _ROLE_113 = 1 << 113;
    uint256 internal constant _ROLE_114 = 1 << 114;
    uint256 internal constant _ROLE_115 = 1 << 115;
    uint256 internal constant _ROLE_116 = 1 << 116;
    uint256 internal constant _ROLE_117 = 1 << 117;
    uint256 internal constant _ROLE_118 = 1 << 118;
    uint256 internal constant _ROLE_119 = 1 << 119;
    uint256 internal constant _ROLE_120 = 1 << 120;
    uint256 internal constant _ROLE_121 = 1 << 121;
    uint256 internal constant _ROLE_122 = 1 << 122;
    uint256 internal constant _ROLE_123 = 1 << 123;
    uint256 internal constant _ROLE_124 = 1 << 124;
    uint256 internal constant _ROLE_125 = 1 << 125;
    uint256 internal constant _ROLE_126 = 1 << 126;
    uint256 internal constant _ROLE_127 = 1 << 127;
    uint256 internal constant _ROLE_128 = 1 << 128;
    uint256 internal constant _ROLE_129 = 1 << 129;
    uint256 internal constant _ROLE_130 = 1 << 130;
    uint256 internal constant _ROLE_131 = 1 << 131;
    uint256 internal constant _ROLE_132 = 1 << 132;
    uint256 internal constant _ROLE_133 = 1 << 133;
    uint256 internal constant _ROLE_134 = 1 << 134;
    uint256 internal constant _ROLE_135 = 1 << 135;
    uint256 internal constant _ROLE_136 = 1 << 136;
    uint256 internal constant _ROLE_137 = 1 << 137;
    uint256 internal constant _ROLE_138 = 1 << 138;
    uint256 internal constant _ROLE_139 = 1 << 139;
    uint256 internal constant _ROLE_140 = 1 << 140;
    uint256 internal constant _ROLE_141 = 1 << 141;
    uint256 internal constant _ROLE_142 = 1 << 142;
    uint256 internal constant _ROLE_143 = 1 << 143;
    uint256 internal constant _ROLE_144 = 1 << 144;
    uint256 internal constant _ROLE_145 = 1 << 145;
    uint256 internal constant _ROLE_146 = 1 << 146;
    uint256 internal constant _ROLE_147 = 1 << 147;
    uint256 internal constant _ROLE_148 = 1 << 148;
    uint256 internal constant _ROLE_149 = 1 << 149;
    uint256 internal constant _ROLE_150 = 1 << 150;
    uint256 internal constant _ROLE_151 = 1 << 151;
    uint256 internal constant _ROLE_152 = 1 << 152;
    uint256 internal constant _ROLE_153 = 1 << 153;
    uint256 internal constant _ROLE_154 = 1 << 154;
    uint256 internal constant _ROLE_155 = 1 << 155;
    uint256 internal constant _ROLE_156 = 1 << 156;
    uint256 internal constant _ROLE_157 = 1 << 157;
    uint256 internal constant _ROLE_158 = 1 << 158;
    uint256 internal constant _ROLE_159 = 1 << 159;
    uint256 internal constant _ROLE_160 = 1 << 160;
    uint256 internal constant _ROLE_161 = 1 << 161;
    uint256 internal constant _ROLE_162 = 1 << 162;
    uint256 internal constant _ROLE_163 = 1 << 163;
    uint256 internal constant _ROLE_164 = 1 << 164;
    uint256 internal constant _ROLE_165 = 1 << 165;
    uint256 internal constant _ROLE_166 = 1 << 166;
    uint256 internal constant _ROLE_167 = 1 << 167;
    uint256 internal constant _ROLE_168 = 1 << 168;
    uint256 internal constant _ROLE_169 = 1 << 169;
    uint256 internal constant _ROLE_170 = 1 << 170;
    uint256 internal constant _ROLE_171 = 1 << 171;
    uint256 internal constant _ROLE_172 = 1 << 172;
    uint256 internal constant _ROLE_173 = 1 << 173;
    uint256 internal constant _ROLE_174 = 1 << 174;
    uint256 internal constant _ROLE_175 = 1 << 175;
    uint256 internal constant _ROLE_176 = 1 << 176;
    uint256 internal constant _ROLE_177 = 1 << 177;
    uint256 internal constant _ROLE_178 = 1 << 178;
    uint256 internal constant _ROLE_179 = 1 << 179;
    uint256 internal constant _ROLE_180 = 1 << 180;
    uint256 internal constant _ROLE_181 = 1 << 181;
    uint256 internal constant _ROLE_182 = 1 << 182;
    uint256 internal constant _ROLE_183 = 1 << 183;
    uint256 internal constant _ROLE_184 = 1 << 184;
    uint256 internal constant _ROLE_185 = 1 << 185;
    uint256 internal constant _ROLE_186 = 1 << 186;
    uint256 internal constant _ROLE_187 = 1 << 187;
    uint256 internal constant _ROLE_188 = 1 << 188;
    uint256 internal constant _ROLE_189 = 1 << 189;
    uint256 internal constant _ROLE_190 = 1 << 190;
    uint256 internal constant _ROLE_191 = 1 << 191;
    uint256 internal constant _ROLE_192 = 1 << 192;
    uint256 internal constant _ROLE_193 = 1 << 193;
    uint256 internal constant _ROLE_194 = 1 << 194;
    uint256 internal constant _ROLE_195 = 1 << 195;
    uint256 internal constant _ROLE_196 = 1 << 196;
    uint256 internal constant _ROLE_197 = 1 << 197;
    uint256 internal constant _ROLE_198 = 1 << 198;
    uint256 internal constant _ROLE_199 = 1 << 199;
    uint256 internal constant _ROLE_200 = 1 << 200;
    uint256 internal constant _ROLE_201 = 1 << 201;
    uint256 internal constant _ROLE_202 = 1 << 202;
    uint256 internal constant _ROLE_203 = 1 << 203;
    uint256 internal constant _ROLE_204 = 1 << 204;
    uint256 internal constant _ROLE_205 = 1 << 205;
    uint256 internal constant _ROLE_206 = 1 << 206;
    uint256 internal constant _ROLE_207 = 1 << 207;
    uint256 internal constant _ROLE_208 = 1 << 208;
    uint256 internal constant _ROLE_209 = 1 << 209;
    uint256 internal constant _ROLE_210 = 1 << 210;
    uint256 internal constant _ROLE_211 = 1 << 211;
    uint256 internal constant _ROLE_212 = 1 << 212;
    uint256 internal constant _ROLE_213 = 1 << 213;
    uint256 internal constant _ROLE_214 = 1 << 214;
    uint256 internal constant _ROLE_215 = 1 << 215;
    uint256 internal constant _ROLE_216 = 1 << 216;
    uint256 internal constant _ROLE_217 = 1 << 217;
    uint256 internal constant _ROLE_218 = 1 << 218;
    uint256 internal constant _ROLE_219 = 1 << 219;
    uint256 internal constant _ROLE_220 = 1 << 220;
    uint256 internal constant _ROLE_221 = 1 << 221;
    uint256 internal constant _ROLE_222 = 1 << 222;
    uint256 internal constant _ROLE_223 = 1 << 223;
    uint256 internal constant _ROLE_224 = 1 << 224;
    uint256 internal constant _ROLE_225 = 1 << 225;
    uint256 internal constant _ROLE_226 = 1 << 226;
    uint256 internal constant _ROLE_227 = 1 << 227;
    uint256 internal constant _ROLE_228 = 1 << 228;
    uint256 internal constant _ROLE_229 = 1 << 229;
    uint256 internal constant _ROLE_230 = 1 << 230;
    uint256 internal constant _ROLE_231 = 1 << 231;
    uint256 internal constant _ROLE_232 = 1 << 232;
    uint256 internal constant _ROLE_233 = 1 << 233;
    uint256 internal constant _ROLE_234 = 1 << 234;
    uint256 internal constant _ROLE_235 = 1 << 235;
    uint256 internal constant _ROLE_236 = 1 << 236;
    uint256 internal constant _ROLE_237 = 1 << 237;
    uint256 internal constant _ROLE_238 = 1 << 238;
    uint256 internal constant _ROLE_239 = 1 << 239;
    uint256 internal constant _ROLE_240 = 1 << 240;
    uint256 internal constant _ROLE_241 = 1 << 241;
    uint256 internal constant _ROLE_242 = 1 << 242;
    uint256 internal constant _ROLE_243 = 1 << 243;
    uint256 internal constant _ROLE_244 = 1 << 244;
    uint256 internal constant _ROLE_245 = 1 << 245;
    uint256 internal constant _ROLE_246 = 1 << 246;
    uint256 internal constant _ROLE_247 = 1 << 247;
    uint256 internal constant _ROLE_248 = 1 << 248;
    uint256 internal constant _ROLE_249 = 1 << 249;
    uint256 internal constant _ROLE_250 = 1 << 250;
    uint256 internal constant _ROLE_251 = 1 << 251;
    uint256 internal constant _ROLE_252 = 1 << 252;
    uint256 internal constant _ROLE_253 = 1 << 253;
    uint256 internal constant _ROLE_254 = 1 << 254;
    uint256 internal constant _ROLE_255 = 1 << 255;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // We don't check and revert upon failure here, just in case
                // `SELFDESTRUCT`'s behavior is changed some day in the future.
                // (If that ever happens, we will riot, and port the code to use WETH).
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // We don't check and revert upon failure here, just in case
                // `SELFDESTRUCT`'s behavior is changed some day in the future.
                // (If that ever happens, we will riot, and port the code to use WETH).
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x095ea7b3)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStructureInterface {
    function getValue(uint256 _id) external view returns (uint256);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {
    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function listExists(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `insertBefore` or `insertAfter` basing on your list order.
     * @dev If you want to order basing on other than `structure.getValue()` override this function
     * @param self stored linked list from contract
     * @param _structure the structure instance
     * @param _value value to seek
     * @return uint256 next node with a value less than _value
     */
    function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256) {
        if (sizeOf(self) == 0) {
            return 0;
        }

        uint256 next;
        (, next) = getAdjacent(self, _HEAD, _NEXT);
        while ((next != 0) && ((_value < IStructureInterface(_structure).getValue(next)) != _NEXT)) {
            next = self.list[next][_NEXT];
        }
        return next;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @return bool true if success, false otherwise
     */
    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    /**
     * @dev Pushes an entry to the tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the tail
     * @return bool true if success, false otherwise
     */
    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    /**
     * @dev Pops the first entry from the head of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popFront(List storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }

    /**
     * @dev Pops the first entry from the tail of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popBack(List storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (_NEXT) or tail (_PREV)
     * @return bool true if success, false otherwise
     */
    function _push(List storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (_NEXT) or the tail (_PREV)
     * @return uint256 the removed node
     */
    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function _insert(List storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _link node to link to in the _direction
     * @param _direction direction to insert node in
     */
    function _createLink(List storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }
}