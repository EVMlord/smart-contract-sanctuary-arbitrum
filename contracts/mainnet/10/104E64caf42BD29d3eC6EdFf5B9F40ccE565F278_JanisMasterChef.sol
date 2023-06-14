// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

// File contracts/JanisMasterChef.sol

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libraries/BoringOwnable.sol";
import "../minting/MintableERC20.sol";
import "../minting/JanisMinter.sol";


library ERC20FactoryLib {
    function createERC20(string memory name_, string memory symbol_, uint8 decimals) external returns(address) 
    {
        ERC20 token = new MintableERC20(name_, symbol_, decimals);
        return address(token);
    }
}

interface IAbilityNFT {
    function getAbility(uint tokenId) external view returns(uint);
}


contract JanisMasterChef is BoringOwnable, IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Info of each user.
    struct UserInfo {
        uint amount;         // How many LP tokens the user has provided.
        uint rewardDebtJanis;     // Reward debt. See explanation below.
        uint rewardDebtYieldToken;     // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        ERC20 lpToken;              // Address of LP token contract.
        bool isNFT;
        uint endTime;
        bool usesPremint;
        uint totalLocked;
        uint allocPointJanis;      // How many allocation points assigned to this pool. Janis to distribute per unix time.
        uint allocPointYieldToken;   // How many allocation points assigned to this pool. YieldToken to distribute per unix time.
        uint lastRewardTime;      // Last unix time number that J & WETH distribution occurs.
        uint accJanisPerShare;     // Accumulated J & WETH per share, times 1e24. See below.
        uint accYieldTokenPerShare;  // Accumulated J & WETH per share, times 1e24. See below.
        uint depositFeeBPOrNFTETHFee;        // Deposit fee in basis points
        address receiptToken;
        bool isExtinctionPool;
    }

    struct NFTSlot {
        address slot1;
        uint tokenId1;
        address slot2;
        uint tokenId2;
        address slot3;
        uint tokenId3;
        address slot4;
        uint tokenId4;
        address slot5;
        uint tokenId5;
    }

    JanisMinter public janisMinter;

    // The Janis TOKEN!
    ERC20 public Janis;
    // Janis tokens created per unix time.
    uint public JanisPerSecond;
    // The YieldToken TOKEN!
    ERC20 public yieldToken;
    // YieldToken tokens created per unix time.
    uint public yieldTokenPerSecond;

    address public reserveFund;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint => mapping(address => UserInfo)) public userInfo;

    // NFTs which can be staked as boosters
    mapping(address => bool) public isWhitelistedBoosterNFT;
    // NFTs which we use the ability stat of for boosting
    mapping(address => bool) public isNFTAbilityEnabled;
    // The base boost of NFTs we read the ability of
    mapping(address => uint) public nftAbilityBaseBoost;
    // The ability boost of NFTs we read the ability of
    mapping(address => uint) public nftAbilityBoostScalar;
    // NFT boost for a set, if not ability enabled
    mapping(address => uint) public nonAbilityBoost;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint public totalAllocPointJanis;
    uint public totalAllocPointYieldToken;
    // The unix time number when J & WETH mining starts.
    uint public immutable globalStartTime;

    mapping(ERC20 => bool) public poolExistence;
    mapping(address => mapping(uint => NFTSlot)) public userDepositedNFTMap; // user => pid => nft slot;

    event Deposit(address indexed user, uint indexed pid, uint amount);
    event Withdraw(address indexed user, uint indexed pid, uint amount);
    event EmergencyWithdraw(address indexed user, uint indexed pid, uint amount);
    event UpdateJanisEmissionRate(address indexed user, uint JanisPerSecond);
    event UpdateYieldTokenEmissionRate(address indexed user, uint yieldTokenPerSecond);

    event UpdateBoosterNFTWhitelist(address indexed user, address indexed _nft, bool enabled, uint _boostRate, bool isAbilityEnabled, uint abilityNFTBaseBoost, uint _nftAbilityBoostScalar);

    event UpdateNewReserveFund(address newReserveFund);

    // max NFTs a single user can stake in a pool. This is to ensure finite gas usage on emergencyWithdraw.
    uint public MAX_NFT_COUNT = 150;

    // Mapping of user address to total nfts staked, per series.
    mapping(address => mapping(uint => uint)) public userStakeCounts;

    function hasUserStakedNFT(address _user, address _series, uint _tokenId) external view returns (bool) {
        return userStakedMap[_user][_series][_tokenId];
    }
    // Mapping of NFT contract address to which NFTs a user has staked.
    mapping(address => mapping(address => mapping(uint => bool))) public userStakedMap;
    // Mapping of NFT contract address to array of NFT IDs a user has staked.
    mapping(address => mapping(address => EnumerableSet.UintSet)) private userNftIdsMapArray;

    function onERC721Received(
        address,
        address,
        uint,
        bytes calldata
    ) external override returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    constructor(
        address _Janis,
        address _JanisMinter,
        uint _JanisPerSecond,
        ERC20 _yieldToken,
        uint _yieldTokenPerSecond,
        uint _globalSartTime
    ) {
        require(_Janis != address(0), "_Janis!=0");
        require(_JanisMinter != address(0), "_JanisMinter!=0");

        Janis = ERC20(_Janis);
        janisMinter = JanisMinter(_JanisMinter);
        JanisPerSecond = _JanisPerSecond;

        yieldToken = _yieldToken;
        yieldTokenPerSecond = _yieldTokenPerSecond;

        totalAllocPointJanis = 0;
        totalAllocPointYieldToken = 0;

        globalStartTime = _globalSartTime;

        reserveFund = msg.sender;
    }

    /* ========== Modifiers ========== */


    modifier nonDuplicated(ERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    /* ========== NFT View Functions ========== */

    function getBoostRateJanis(address _nft, uint _nftId) public view returns (uint) {
        if (isNFTAbilityEnabled[_nft]) {
            // getAbility returns a 1e4 basis point number
            return nftAbilityBaseBoost[_nft] + nftAbilityBoostScalar[_nft] * IAbilityNFT(_nft).getAbility(_nftId) / 1e4;
        } else
            return nonAbilityBoost[_nft];
    }

    function getBoostJanis(address _account, uint _pid) public view returns (uint) {
        NFTSlot memory slot = userDepositedNFTMap[_account][_pid];
        uint boost1 = getBoostRateJanis(slot.slot1, slot.tokenId1);
        uint boost2 = getBoostRateJanis(slot.slot2, slot.tokenId2);
        uint boost3 = getBoostRateJanis(slot.slot3, slot.tokenId3);
        uint boost4 = getBoostRateJanis(slot.slot4, slot.tokenId4);
        uint boost5 = getBoostRateJanis(slot.slot5, slot.tokenId5);
        uint boost = boost1 + boost2 + boost3 + boost4 + boost5;
        return boost;
    }

    function getSlots(address _account, uint _pid) external view returns (address, address, address, address, address) {
        NFTSlot memory slot = userDepositedNFTMap[_account][_pid];
        return (slot.slot1, slot.slot2, slot.slot3, slot.slot4, slot.slot5);
    }

    function getTokenIds(address _account, uint _pid) external view returns (uint, uint, uint, uint, uint) {
        NFTSlot memory slot = userDepositedNFTMap[_account][_pid];
        return (slot.tokenId1, slot.tokenId2, slot.tokenId3, slot.tokenId4, slot.tokenId5);
    }

    /* ========== View Functions ========== */

    function poolLength() external view returns (uint) {
        return poolInfo.length;
    }

    // Return reward multiplier over the given _from to _to unix time.
    function getMultiplier(uint _from, uint _to) internal pure returns (uint) {
        return _to - _from;
    }

    // View function to see pending J & WETH on frontend.
    function pendingJanis(uint _pid, address _user) external view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint accJanisPerShare = pool.accJanisPerShare;
        uint lpSupply = pool.totalLocked;
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint JanisReward = multiplier * JanisPerSecond * pool.allocPointJanis / totalAllocPointJanis;
            accJanisPerShare = accJanisPerShare + (JanisReward * 1e24 / lpSupply);
        }
        return (user.amount * accJanisPerShare / 1e24) - user.rewardDebtJanis;
    }

    // View function to see pending J & WETH on frontend.
    function pendingYieldToken(uint _pid, address _user) external view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint accYieldTokenPerShare = pool.accYieldTokenPerShare;
        uint lpSupply = pool.totalLocked;
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint yieldTokenReward = multiplier * yieldTokenPerSecond * pool.allocPointYieldToken / totalAllocPointYieldToken;
            accYieldTokenPerShare = accYieldTokenPerShare + (yieldTokenReward * 1e24 / lpSupply);
        }
        return (user.amount * accYieldTokenPerShare / 1e24) - user.rewardDebtYieldToken;
    }

    /* ========== Owner Functions ========== */

    // Add a new lp to the pool. Can only be called by the owner.
    function add(bool _isExtinctionPool, bool _isNFT, uint _startTime, uint _endTime, bool _usesPremint, uint _allocPointJanis, uint _allocPointYieldToken, ERC20 _lpToken, uint _depositFeeBPOrNFTETHFee, bool _withMassUpdate) external onlyOwner nonDuplicated(_lpToken) {
        require(_startTime == 0 || _startTime > block.timestamp, "invalid startTime!");
        require(_endTime == 0 || (_startTime == 0 && _endTime > block.timestamp + 20) || (_startTime > block.timestamp && _endTime > _startTime + 20), "invalid endTime!");
        require(_depositFeeBPOrNFTETHFee <= 1000, "too high fee"); // <= 10%

        // If it isn't an NFT or ERC20, it will likely revert here:
        _lpToken.balanceOf(address(this));

        bool isReallyAnfNFT = false;

        try ERC721(address(_lpToken)).supportsInterface(0x80ac58cd) returns (bool supportsNFT) {
            isReallyAnfNFT = supportsNFT;
        } catch {}

        if (isReallyAnfNFT != _isNFT) {
            if (_isNFT) {
                revert("NFT address isn't and NFT Address!");
            } else {
                revert("ERC20 address isn't and ERC20 Address!");
            }
        }

        if (_isNFT) {
            _isExtinctionPool = false;
        }

        if (_withMassUpdate) {
            massUpdatePools();
        }

        uint lastRewardTime = _startTime == 0 ? (block.timestamp > globalStartTime ? block.timestamp : globalStartTime) : _startTime;
        totalAllocPointJanis = totalAllocPointJanis + _allocPointJanis;
        totalAllocPointYieldToken = totalAllocPointYieldToken + _allocPointYieldToken;

        poolExistence[_lpToken] = true;

        poolInfo.push(PoolInfo({
            isNFT: _isNFT,
            endTime: _endTime,
            usesPremint: _usesPremint,
            lpToken : _lpToken,
            allocPointJanis : _allocPointJanis,
            allocPointYieldToken : _allocPointYieldToken,
            lastRewardTime : lastRewardTime,
            accJanisPerShare : 0,
            accYieldTokenPerShare : 0,
            depositFeeBPOrNFTETHFee: _depositFeeBPOrNFTETHFee,
            totalLocked: 0,
            receiptToken: address(0),
            isExtinctionPool: _isExtinctionPool
        }));

        if (!_isExtinctionPool && !_isNFT) {
            string memory receiptName = string.concat("J: ", _lpToken.name());
            string memory receiptSymbol = string.concat("J: ", _lpToken.symbol());
            poolInfo[poolInfo.length - 1].receiptToken = ERC20FactoryLib.createERC20(receiptName, receiptSymbol, _lpToken.decimals());
        }
    }

    // Update the given pool's J & WETH allocation point and deposit fee. Can only be called by the owner.
    function set(uint _pid, uint _startTime, uint _endTime, bool _usesPremint, uint _allocPointJanis, uint _allocPointYieldToken, uint _depositFeeBPOrNFTETHFee, bool _withMassUpdate) external onlyOwner {
        require(_startTime == 0 || _startTime > block.timestamp, "invalid startTime!");
        require(_endTime == 0 || (_startTime == 0 && _endTime > block.timestamp + 20) || (_startTime > block.timestamp && _endTime > _startTime + 20), "invalid endTime!");
        require(_depositFeeBPOrNFTETHFee <= 1000, "too high fee"); // <= 10%

        if (_withMassUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }

        totalAllocPointJanis = (totalAllocPointJanis - poolInfo[_pid].allocPointJanis) + _allocPointJanis;
        totalAllocPointYieldToken = (totalAllocPointYieldToken - poolInfo[_pid].allocPointYieldToken) + _allocPointYieldToken;

        uint lastRewardTime = _startTime == 0 ? (block.timestamp > globalStartTime ? block.timestamp : globalStartTime) : _startTime;

        poolInfo[_pid].lastRewardTime = lastRewardTime;
        poolInfo[_pid].endTime = _endTime;
        poolInfo[_pid].usesPremint = _usesPremint;
        poolInfo[_pid].allocPointJanis = _allocPointJanis;
        poolInfo[_pid].allocPointYieldToken = _allocPointYieldToken;
        poolInfo[_pid].depositFeeBPOrNFTETHFee = _depositFeeBPOrNFTETHFee;
    }

    function setUsePremintOnly(uint _pid, bool _usesPremint) external onlyOwner {
        poolInfo[_pid].usesPremint = _usesPremint;
    }

    function setAllocationPointsOnly(uint _pid, uint _allocPointJanis, uint _allocPointYieldToken, bool _withMassUpdate) external onlyOwner {
        if (_withMassUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }

        totalAllocPointJanis = (totalAllocPointJanis - poolInfo[_pid].allocPointJanis) + _allocPointJanis;
        totalAllocPointYieldToken = (totalAllocPointYieldToken - poolInfo[_pid].allocPointYieldToken) + _allocPointYieldToken;

        poolInfo[_pid].allocPointJanis = _allocPointJanis;
        poolInfo[_pid].allocPointYieldToken = _allocPointYieldToken;
    }

    function setDepositFeeOnly(uint _pid,  uint _depositFeeBPOrNFTETHFee, bool _withMassUpdate) external onlyOwner {
        require(_depositFeeBPOrNFTETHFee <= 1000, "too high fee"); // <= 10%

        if (_withMassUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }

        poolInfo[_pid].depositFeeBPOrNFTETHFee = _depositFeeBPOrNFTETHFee;
    }

    function setPoolScheduleKeepMultipliers(uint _pid, uint _startTime, uint _endTime, bool _withMassUpdate) external onlyOwner {
        require(_startTime == 0 || _startTime > block.timestamp, "invalid startTime!");
        require(_endTime == 0 || (_startTime == 0 && _endTime > block.timestamp + 20) || (_startTime > block.timestamp && _endTime > _startTime + 20), "invalid endTime!");

        if (_withMassUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }

        uint lastRewardTime = _startTime == 0 ? (block.timestamp > globalStartTime ? block.timestamp : globalStartTime) : _startTime;

        poolInfo[_pid].lastRewardTime = lastRewardTime;
        poolInfo[_pid].endTime = _endTime;
    }

    function setPoolScheduleAndMultipliers(uint _pid, uint _startTime, uint _endTime, uint _allocPointJanis, uint _allocPointYieldToken, bool _withMassUpdate) external onlyOwner {
        require(_startTime == 0 || _startTime > block.timestamp, "invalid startTime!");
        require(_endTime == 0 || (_startTime == 0 && _endTime > block.timestamp + 20) || (_startTime > block.timestamp && _endTime > _startTime + 20), "invalid endTime!");

        if (_withMassUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }

        uint lastRewardTime = _startTime == 0 ? (block.timestamp > globalStartTime ? block.timestamp : globalStartTime) : _startTime;

        poolInfo[_pid].lastRewardTime = lastRewardTime;
        poolInfo[_pid].endTime = _endTime;

        totalAllocPointJanis = (totalAllocPointJanis - poolInfo[_pid].allocPointJanis) + _allocPointJanis;
        totalAllocPointYieldToken = (totalAllocPointYieldToken - poolInfo[_pid].allocPointYieldToken) + _allocPointYieldToken;

        poolInfo[_pid].allocPointJanis = _allocPointJanis;
        poolInfo[_pid].allocPointYieldToken = _allocPointYieldToken;
    }

    function disablePoolKeepMultipliers(uint _pid, bool _withMassUpdate) external onlyOwner {
        if (_withMassUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }

        uint lastRewardTime = block.timestamp > globalStartTime ? block.timestamp : globalStartTime;

        poolInfo[_pid].lastRewardTime = lastRewardTime;
        poolInfo[_pid].endTime = lastRewardTime;
    }

    function zeroEndedMultipliersAndDecreaseEmissionVariables(uint startPid, uint endPid, bool _withMassUpdate) external onlyOwner {
        require(startPid < poolInfo.length, "startPid too high!");
        require(endPid < poolInfo.length, "endPid too high!");

        if (_withMassUpdate) {
            massUpdatePools();
        }

        uint janisAllocPointsEliminated = 0;
        uint yieldTokenllocPointsEliminated = 0;

        for (uint i = startPid;i<=endPid;i++) {
            if (poolInfo[i].lastRewardTime >= poolInfo[i].endTime) {
                janisAllocPointsEliminated += poolInfo[i].allocPointJanis;
                yieldTokenllocPointsEliminated += poolInfo[i].allocPointYieldToken;
                poolInfo[i].allocPointJanis = 0;
                poolInfo[i].allocPointYieldToken = 0;
            }
        }

        JanisPerSecond -= JanisPerSecond * janisAllocPointsEliminated / totalAllocPointJanis;
        yieldTokenPerSecond -= yieldTokenPerSecond * yieldTokenllocPointsEliminated / totalAllocPointYieldToken;

        totalAllocPointJanis -= janisAllocPointsEliminated;
        totalAllocPointYieldToken -= yieldTokenllocPointsEliminated;
    }

    /* ========== NFT External Functions ========== */

    // Depositing of NFTs
    function depositNFT(address _nft, uint _tokenId, uint _slot, uint _pid) external nonReentrant {
        require(_slot != 0 && _slot <= 5, "slot out of range 1-5!");
        require(isWhitelistedBoosterNFT[_nft], "only approved NFTs");
        require(ERC721(_nft).balanceOf(msg.sender) > 0, "user does not have specified NFT");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        //require(user.amount == 0, "not allowed to deposit");

        updatePool(_pid);
        transferPendingRewards(_pid);
        
        user.rewardDebtJanis = user.amount * pool.accJanisPerShare / 1e24;
        user.rewardDebtYieldToken = user.amount * pool.accYieldTokenPerShare / 1e24;

        NFTSlot memory slot = userDepositedNFTMap[msg.sender][_pid];

        address existingNFT;

        if (_slot == 1) existingNFT = slot.slot1;
        else if (_slot == 2) existingNFT = slot.slot2;
        else if (_slot == 3) existingNFT = slot.slot3;
        else if (_slot == 4) existingNFT = slot.slot4;
        else if (_slot == 5) existingNFT = slot.slot5;

        require(existingNFT == address(0), "you must empty this slot before depositing a new nft here!");

        if (_slot == 1) slot.slot1 = _nft;
        else if (_slot == 2) slot.slot2 = _nft;
        else if (_slot == 3) slot.slot3 = _nft;
        else if (_slot == 4) slot.slot4 = _nft;
        else if (_slot == 5) slot.slot5 = _nft;
        
        if (_slot == 1) slot.tokenId1 = _tokenId;
        else if (_slot == 2) slot.tokenId2 = _tokenId;
        else if (_slot == 3) slot.tokenId3 = _tokenId;
        else if (_slot == 4) slot.tokenId4 = _tokenId;
        else if (_slot == 5) slot.tokenId5 = _tokenId;

        userDepositedNFTMap[msg.sender][_pid] = slot;

        ERC721(_nft).transferFrom(msg.sender, address(this), _tokenId);
    }

    // Withdrawing of NFTs
    function withdrawNFT(uint _slot, uint _pid) external nonReentrant {
        address _nft;
        uint _tokenId;
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);
        transferPendingRewards(_pid);
        
        user.rewardDebtJanis = user.amount * pool.accJanisPerShare / 1e24;
        user.rewardDebtYieldToken = user.amount * pool.accYieldTokenPerShare / 1e24;

        NFTSlot memory slot = userDepositedNFTMap[msg.sender][_pid];

        if (_slot == 1) _nft = slot.slot1;
        else if (_slot == 2) _nft = slot.slot2;
        else if (_slot == 3) _nft = slot.slot3;
        else if (_slot == 4) _nft = slot.slot4;
        else if (_slot == 5) _nft = slot.slot5;
        
        if (_slot == 1) _tokenId = slot.tokenId1;
        else if (_slot == 2) _tokenId = slot.tokenId2;
        else if (_slot == 3) _tokenId = slot.tokenId3;
        else if (_slot == 4) _tokenId = slot.tokenId4;
        else if (_slot == 5) _tokenId = slot.tokenId5;

        if (_slot == 1) slot.slot1 = address(0);
        else if (_slot == 2) slot.slot2 = address(0);
        else if (_slot == 3) slot.slot3 = address(0);
        else if (_slot == 4) slot.slot4 = address(0);
        else if (_slot == 5) slot.slot5 = address(0);
        
        if (_slot == 1) slot.tokenId1 = uint(0);
        else if (_slot == 2) slot.tokenId2 = uint(0);
        else if (_slot == 3) slot.tokenId3 = uint(0);
        else if (_slot == 4) slot.tokenId4 = uint(0);
        else if (_slot == 5) slot.tokenId5 = uint(0);

        userDepositedNFTMap[msg.sender][_pid] = slot;
        
        ERC721(_nft).transferFrom(address(this), msg.sender, _tokenId);
    }

    /* ========== External Functions ========== */

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        if (pool.endTime != 0 && pool.lastRewardTime >= pool.endTime) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint lpSupply = pool.totalLocked;
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint currentTimeOrEndOfPoolTime = block.timestamp;

        if (pool.endTime != 0 && pool.endTime < currentTimeOrEndOfPoolTime)
            currentTimeOrEndOfPoolTime = pool.endTime;

        uint multiplier = getMultiplier(pool.lastRewardTime, currentTimeOrEndOfPoolTime);

        if (pool.allocPointJanis > 0) {
            uint JanisReward = multiplier * JanisPerSecond * pool.allocPointJanis / totalAllocPointJanis;
            if (JanisReward > 0) {
                if (!pool.usesPremint)
                    janisMinter.operatorMint(address(this), JanisReward);
                else
                    janisMinter.operatorFetchOrMint(address(this), JanisReward);
                pool.accJanisPerShare = pool.accJanisPerShare + (JanisReward * 1e24 / lpSupply);
            }
        }

        if (pool.allocPointYieldToken > 0) {
            uint yieldTokenReward = multiplier * yieldTokenPerSecond * pool.allocPointYieldToken / totalAllocPointYieldToken;
            if (yieldTokenReward > 0) {
                // We can't mint extra of the yield token, meant to be a 3rd party token like WETH, WBTC etc..
                pool.accYieldTokenPerShare = pool.accYieldTokenPerShare + (yieldTokenReward * 1e24 / lpSupply);
            }
        }

        pool.lastRewardTime = block.timestamp;
    }

    function transferPendingRewards(uint _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amount > 0) {
            uint pendingJanisToPay = (user.amount * pool.accJanisPerShare / 1e24)  - user.rewardDebtJanis;
            if (pendingJanisToPay > 0) {
                safeJanisTransfer(msg.sender, pendingJanisToPay, _pid);
            }
            uint pendingYieldTokenToPay = (user.amount * pool.accYieldTokenPerShare / 1e24) - user.rewardDebtYieldToken;
            if (pendingYieldTokenToPay > 0) {
                safeYieldTokenTransfer(msg.sender, pendingYieldTokenToPay);
            }
        }
    }


    // Deposit LP tokens to MasterChef for J & WETH allocation.
    function deposit(uint _pid, uint _amountOrId, bool isNFTHarvest, address _referrer) public payable nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        transferPendingRewards(_pid);

        // We allow changing of referrals
        janisMinter.recordReferral(msg.sender, _referrer);

        if (!isNFTHarvest && pool.isNFT) {
            require(msg.value >= pool.depositFeeBPOrNFTETHFee, "ETH deposit fee too low!");

            if (pool.depositFeeBPOrNFTETHFee > 0) {
                (bool transferSuccess, ) = payable(reserveFund).call{
                    value: payable(address(this)).balance
                }("");
                require(transferSuccess, "Fee Transfer Failed!");
            }

            address series = address(pool.lpToken);

            userStakeCounts[msg.sender][_pid]++;
            require(userStakeCounts[msg.sender][_pid] <= MAX_NFT_COUNT,
                "you have aleady reached the maximum amount of NFTs you can stake in this pool");
            IERC721(series).safeTransferFrom(msg.sender, address(this), _amountOrId);

            userStakedMap[msg.sender][series][_amountOrId] = true;

            userNftIdsMapArray[msg.sender][series].add(_amountOrId);

            user.amount = user.amount + 1;
            pool.totalLocked = pool.totalLocked + 1;
        } else if (!pool.isNFT && _amountOrId > 0) {
            if (_amountOrId > 0) {
                uint lpBalanceBefore = pool.lpToken.balanceOf(address(this));
                pool.lpToken.safeTransferFrom(msg.sender, address(this), _amountOrId);
                _amountOrId = pool.lpToken.balanceOf(address(this)) - lpBalanceBefore;
                require(_amountOrId > 0, "No tokens received, high transfer tax?");
        
                uint userPoolBalanceBefore = user.amount;

                if (pool.isExtinctionPool) {
                    pool.lpToken.safeTransfer(reserveFund, _amountOrId);
                    user.amount += _amountOrId;
                    pool.totalLocked += _amountOrId;  
                } else if (pool.depositFeeBPOrNFTETHFee > 0) {
                    uint _depositFee = _amountOrId * pool.depositFeeBPOrNFTETHFee / 1e4;
                    pool.lpToken.safeTransfer(reserveFund, _depositFee);
                    user.amount = (user.amount + _amountOrId) - _depositFee;
                    pool.totalLocked = (pool.totalLocked + _amountOrId) - _depositFee;
                } else {
                    user.amount += _amountOrId;
                    pool.totalLocked += _amountOrId;
                }

                uint userPoolBalanceGained = user.amount - userPoolBalanceBefore;

                require(userPoolBalanceGained > 0, "Zero deposit gained, depositing small wei?");

                if (!pool.isExtinctionPool)
                    MintableERC20(pool.receiptToken).mint(msg.sender, userPoolBalanceGained);
            }
        }
    
        user.rewardDebtJanis = user.amount * pool.accJanisPerShare / 1e24;
        user.rewardDebtYieldToken = user.amount * pool.accYieldTokenPerShare / 1e24;
        emit Deposit(msg.sender, _pid, _amountOrId);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint _pid, uint _amountOrId) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        require(!pool.isExtinctionPool, "can't withdraw from extinction pools!");

        UserInfo storage user = userInfo[_pid][msg.sender];
        require(pool.isNFT || user.amount >= _amountOrId, "withdraw: not good");
        updatePool(_pid);
        transferPendingRewards(_pid);

        uint256 withdrawQuantity = 0;

        address tokenAddress = address(pool.lpToken);

        if (pool.isNFT) {
            require(userStakedMap[msg.sender][tokenAddress][_amountOrId], "nft not staked");

            userStakeCounts[msg.sender][_pid]--;

            userStakedMap[msg.sender][tokenAddress][_amountOrId] = false;

            userNftIdsMapArray[msg.sender][tokenAddress].remove(_amountOrId);

            withdrawQuantity = 1;
        } else if (_amountOrId > 0) {
            MintableERC20(pool.receiptToken).burn(msg.sender, _amountOrId);

            pool.lpToken.safeTransfer(msg.sender, _amountOrId);

            withdrawQuantity = _amountOrId;
        }

        user.amount -= withdrawQuantity;
        pool.totalLocked -= withdrawQuantity;

        user.rewardDebtJanis = user.amount * pool.accJanisPerShare / 1e24;
        user.rewardDebtYieldToken = user.amount * pool.accYieldTokenPerShare / 1e24;

        if (pool.isNFT)
            IERC721(tokenAddress).safeTransferFrom(address(this), msg.sender, _amountOrId);

        emit Withdraw(msg.sender, _pid, _amountOrId);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        require(!pool.isExtinctionPool, "can't withdraw from extinction pools!");

        UserInfo storage user = userInfo[_pid][msg.sender];
        uint amount = user.amount;

        user.amount = 0;
        user.rewardDebtJanis = 0;
        user.rewardDebtYieldToken = 0;

        userStakeCounts[msg.sender][_pid] = 0;

        // In the case of an accounting error, we choose to let the user emergency withdraw anyway
        if (pool.totalLocked >=  amount)
            pool.totalLocked = pool.totalLocked - amount;
        else
            pool.totalLocked = 0;

        if (pool.isNFT) {
            address series = address(pool.lpToken);
            EnumerableSet.UintSet storage nftStakedCollection = userNftIdsMapArray[msg.sender][series];

            for (uint j = 0;j < nftStakedCollection.length();j++) {
                uint nftId = nftStakedCollection.at(j);

                userStakedMap[msg.sender][series][nftId] = false;
                IERC721(series).safeTransferFrom(address(this), msg.sender, nftId);
            }

            // empty user nft Ids array
            delete userNftIdsMapArray[msg.sender][series];
        } else {
            MintableERC20(pool.receiptToken).burn(msg.sender, amount);

            pool.lpToken.safeTransfer(msg.sender, amount);
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function viewStakerUserNFTs(address _series, address userAddress) external view returns (uint[] memory){
        EnumerableSet.UintSet storage nftStakedCollection = userNftIdsMapArray[userAddress][_series];

        uint[] memory nftStakedArray = new uint[](nftStakedCollection.length());

        for (uint i = 0;i < nftStakedCollection.length();i++)
           nftStakedArray[i] = nftStakedCollection.at(i);

        return nftStakedArray;
    }

    // Safe Janis transfer function, just in case if rounding error causes pool to not have enough Janis.
    function safeJanisTransfer(address _to, uint _amount, uint _pid) internal {
        uint boost = 0;
        Janis.transfer(_to, _amount);

        boost = getBoostJanis(_to, _pid) * _amount / 1e4;
        uint total = _amount + boost;

        if (boost > 0) janisMinter.operatorMint(_to, boost);
        janisMinter.mintReferralsOnly(_to, total);
        janisMinter.mintDaoShare(total);
    }

    // Safe YieldToken transfer function, just in case if rounding error causes pool to not have enough YieldToken.
    function safeYieldTokenTransfer(address _to, uint _amount) internal {
        uint currentYieldTokenBalance = yieldToken.balanceOf(address(this));
        if (currentYieldTokenBalance < _amount)
            yieldToken.safeTransfer(_to, currentYieldTokenBalance);
        else
            yieldToken.safeTransfer(_to, _amount);
    }

    /* ========== Set Variable Functions ========== */

    function giveCredit(uint _pid, uint _amountOrId, address _user) external onlyOwner {
        require(block.timestamp < globalStartTime, "emissions already started!");

        PoolInfo storage pool = poolInfo[_pid];
        require(pool.isExtinctionPool, "can only set extinction pools!");

        UserInfo storage user = userInfo[_pid][_user];

        user.amount += _amountOrId;
        pool.totalLocked += _amountOrId;
    }

    function updateJanisEmissionRate(uint _JanisPerSecond) external onlyOwner {
        require(_JanisPerSecond < 1e22, "emissions too high!");
        massUpdatePools();
        JanisPerSecond = _JanisPerSecond;
        emit UpdateJanisEmissionRate(msg.sender, _JanisPerSecond);
    }

    function updateYieldTokenEmissionRate(uint _yieldTokenPerSecond) external onlyOwner {
        require(_yieldTokenPerSecond < 1e22, "emissions too high!");
        massUpdatePools();
        yieldTokenPerSecond = _yieldTokenPerSecond;
        emit UpdateYieldTokenEmissionRate(msg.sender, _yieldTokenPerSecond);
    }

    /**
     * @dev set the maximum amount of NFTs a user is allowed to stake, useful if
     * too much gas is used by emergencyWithdraw
     * Can only be called by the current operator.
     */
    function set_MAX_NFT_COUNT(uint new_MAX_NFT_COUNT) external onlyOwner {
        require(new_MAX_NFT_COUNT >= 20, "MAX_NFT_COUNT must be greater than 0");
        require(new_MAX_NFT_COUNT <= 150, "MAX_NFT_COUNT must be less than 150");

        MAX_NFT_COUNT = new_MAX_NFT_COUNT;
    }

    function setBoosterNFTWhitelist(address _nft, bool enabled, uint _nonAbilityBoost, bool isAbilityEnabled, uint abilityNFTBaseBoost, uint _nftAbilityBoostScalar) external onlyOwner {
        require(_nft != address(0), "_nft!=0");
        require(enabled || (!enabled && !isAbilityEnabled), "Can't disable and also enable for ability boost!");
        require(_nonAbilityBoost <= 500, "Max non-abilitu boost is 5%!");
        require(abilityNFTBaseBoost<= 500, "Max ability base boost is 5%!");
        require(_nftAbilityBoostScalar<= 500, "Max ability scalar boost is 5%!");

        isWhitelistedBoosterNFT[_nft] = enabled;
        isNFTAbilityEnabled[_nft] = isAbilityEnabled;

        if (enabled && !isAbilityEnabled)
            nonAbilityBoost[_nft] = _nonAbilityBoost;
        else if (!enabled)
            nonAbilityBoost[_nft] = 0;

        if (isNFTAbilityEnabled[_nft]) {
            nftAbilityBaseBoost[_nft] = abilityNFTBaseBoost;
            nftAbilityBoostScalar[_nft] = _nftAbilityBoostScalar;
        } else {
            nftAbilityBaseBoost[_nft] = 0;
            nftAbilityBoostScalar[_nft] = 0;
        }

        emit UpdateBoosterNFTWhitelist(msg.sender, _nft, enabled, nonAbilityBoost[_nft], isAbilityEnabled, nftAbilityBaseBoost[_nft], nftAbilityBoostScalar[_nft]);
    }

    function setReserveFund(address newReserveFund) external onlyOwner {
        reserveFund = newReserveFund;
        emit UpdateNewReserveFund(newReserveFund);
    }

    function harvestAllRewards() external {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) {
            if (userInfo[pid][msg.sender].amount > 0) {
                deposit(pid, 0, true, address(0));
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

// Source Code: https://github.com/boringcrypto/BoringSolidity/blob/78f4817d9c0d95fe9c45cd42e307ccd22cf5f4fc/contracts/BoringOwnable.sol

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/BoringOwnable.sol";
import "./MintableERC20.sol";

contract JanisMinter is BoringOwnable {
    using SafeERC20 for IERC20;
    using SafeERC20 for MintableERC20;

    MintableERC20 public JanisToken;
    address public daoAddress;

    // 5%
    uint public constant MAX_BONUS = 500;
    // 3%
    uint public referralBonusE4 = 300;
    // 2%
    uint public refereeBonusE4 = 200;

    // 25%
    uint public constant MAX_DAO_SHARE = 2500;
    // 12%
    uint public daoShareE4 = 1200;

    mapping(address => bool) public operators;
    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint) public referralsCount; // referrer address => referrals count

    mapping(address => uint) public totalReferralCommission; // referrer address => total referral commission
    mapping(address => mapping(address => uint)) public totalReferralCommissionPerUser; // referrer address => user address => total referral commission

    mapping(address => uint) public totalRefereeReward; // referrer address => total reward for being referred
    mapping(address => mapping(address => uint)) public totalRefereeRewardPerReferrer; // user address => referrer address => total reward for being referred

    event ReferralRecorded(address indexed user, address indexed oldReferrer, address indexed newReferrer);
    event ReferralCommissionRecorded(address indexed referrer, address indexed user, uint commission);
    event HasRefereeRewardRecorded(address indexed user, address indexed referrer, uint reward);
    event JanisMinted(address indexed destination, uint amount);

    event ReferralBonusUpdated(uint oldBonus, uint newBonus);
    event RefereeBonusUpdated(uint oldBonus, uint newBonus);
    event JanisTokenUpdated(address oldJanisToken, address janisToken);
    event DaoAddressUpdated(address oldDaoAddress, address daoAddress);
    event OperatorUpdated(address indexed operator, bool indexed status);

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    constructor(
        address _JanisToken,
        address _DaoAddress
    ) {
        require(_JanisToken != address(0), "_JanisToken!=0");
        require(_DaoAddress != address(0), "_DaoAddress!=0");

        JanisToken = MintableERC20(_JanisToken);
        daoAddress = _DaoAddress;

        operators[msg.sender] = true;
    }

    function recordReferral(address _user, address _referrer) external onlyOperator {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user] != _referrer
        ) {
            address oldReferrer = address(0);
            if (referrers[_user] != address(0)) {
                // Instead of this being a new referral, we are changing the referrer,
                // so we need to subtract from the old referrers count
                oldReferrer = referrers[_user];
                referralsCount[oldReferrer] -= 1;
            }

            referralsCount[_referrer] += 1;
            referrers[_user] = _referrer;
            
            emit ReferralRecorded(_user, oldReferrer, _referrer);
        }
    }

    function operatorMint(address _destination, uint _minting) external onlyOperator {
        mintWithoutReferrals(_destination, _minting);
    }
    
    function operatorMintForReserves(uint _minting) external onlyOperator {
        mintWithoutReferrals(address(this), _minting);
    }

    function operatorFetchOrMint(address _destination, uint _minting) external onlyOperator {
        uint currentJanisBalance = JanisToken.balanceOf(address(this));
        if (currentJanisBalance < _minting) {
            JanisToken.mint(address(this), _minting - currentJanisBalance);
            emit JanisMinted(address(this), _minting);
        }
        JanisToken.safeTransfer(_destination, _minting);
    }

    function mintWithReferrals(address _user, uint _minting) external onlyOperator {
        mintWithoutReferrals(_user, _minting);
        mintReferralsOnly(_user, _minting);
    }

    function mintWithoutReferrals(address _user, uint _minting) public onlyOperator {
        if (_user != address(0) && _minting > 0) {
            JanisToken.mint(_user, _minting);
            emit JanisMinted(_user, _minting);
        }
    }

    function mintReferralsOnly(address _user, uint _minting) public onlyOperator {
        uint commission = _minting * referralBonusE4 / 1e4;
        uint reward =  _minting * refereeBonusE4 / 1e4;

        address referrer = referrers[_user];

        if (referrer != address(0) && _user != address(0) && commission > 0) {
            totalReferralCommission[referrer] += commission;
            totalReferralCommissionPerUser[referrer][_user] += commission;

            JanisToken.mint(referrer, commission);

            emit JanisMinted(referrer, commission);
            emit ReferralCommissionRecorded(referrer, _user, commission);
        }
        if (_user != address(0) && referrer != address(0) && reward > 0) {
            totalRefereeReward[_user] += reward;
            totalRefereeRewardPerReferrer[_user][referrer] += reward;

            JanisToken.mint(_user, reward);

            emit JanisMinted(_user, reward);
            emit ReferralCommissionRecorded(_user, referrer, reward);
        }
    }

    function mintDaoShare(uint _minting) public onlyOperator {
        uint daoShare = _minting * daoShareE4 / 1e4;

        JanisToken.mint(daoAddress, daoShare);

        emit JanisMinted(daoAddress, daoShare);
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) external view returns (address) {
        return referrers[_user];
    }

    // Update the referrer bonus
    function updateReferralBonus(uint _bonus) external onlyOwner {
        require(_bonus <= MAX_BONUS, "Max bonus is 5%");

        uint oldBonus = referralBonusE4;
        referralBonusE4 = _bonus;
        emit ReferralBonusUpdated(oldBonus, referralBonusE4);
    }

    // Update the referee bonus
    function updateRefereeBonus(uint _bonus) external onlyOwner {
        require(_bonus <= MAX_BONUS, "Max bonus is 5%");

        uint oldBonus = refereeBonusE4;
        refereeBonusE4 = _bonus;
        emit ReferralBonusUpdated(oldBonus, refereeBonusE4);
    }

    // Update the dao share percentage
    function updateDaoShare(uint _perc) external onlyOwner {
        require(_perc <= MAX_DAO_SHARE, "Max bonus is 25%");

        uint oldPerc = daoShareE4;
        daoShareE4 = _perc;
        emit ReferralBonusUpdated(oldPerc, daoShareE4);
    }

    // Update the status of the operator
    function setJanisToken(address _JanisToken) external onlyOwner {
        require(_JanisToken != address(0), "_JanisToken!=0");

        address oldJanisToken = address(JanisToken);
        JanisToken = MintableERC20(_JanisToken);
        emit JanisTokenUpdated(oldJanisToken, _JanisToken);
    }


    // Update the status of the operator
    function setDaoAddress(address _DaoAddress) external onlyOwner {
        require(_DaoAddress != address(0), "_DaoAddress!=0");

        address oldDaoAddress = daoAddress;
        daoAddress = _DaoAddress;
        emit DaoAddressUpdated(oldDaoAddress, daoAddress);
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    // Owner can drain tokens that are sent here by mistake
    function drainERC20Token(IERC20 _token, uint _amount, address _to) external onlyOwner {
        _token.safeTransfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/BoringOwnable.sol";

contract MintableERC20 is ERC20, BoringOwnable {

    uint8 public immutable decimalsToUse;

    mapping(address => bool) public operators;

    event OperatorUpdated(address indexed operator, bool indexed status);

    modifier onlyOperatorOrOwner {
        require(owner == msg.sender || operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        decimalsToUse = decimals_;

        operators[msg.sender] = true;
    } 

    function mint(address account, uint256 amount) external onlyOperatorOrOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOperatorOrOwner {
        _burn(account, amount);
    }

    function decimals() public view override returns (uint8){
        return decimalsToUse;
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }
}