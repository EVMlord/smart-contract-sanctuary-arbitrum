/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

 
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

 
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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


// File @openzeppelin/contracts/utils/introspection/[email protected]

 
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/interfaces/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/access/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
}


// File contracts/Authorizable.sol



pragma solidity >=0.8.0;

contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] ||  owner() == msg.sender, "Not authorized");
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != address(0));
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

 
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}


// File @openzeppelin/contracts/utils/[email protected]

 
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


// File contracts/BRO.sol

  

pragma solidity >=0.8.0;



contract BRO is ERC721Upgradeable {
    // Royalty
    address private _owner;
    address private _royaltiesAddr; // royality receiver
    uint256 public royaltyPercentage; // royalty based on sales price
    mapping(address => bool) public excludedList; // list of people who dont have to pay fee


    // cost to mint
    uint256 public mintFeeAmount;

    // // NFT Meta data
    string public baseURL;

    uint256 public constant maxSupply = 6969;

    bool public openForPublic;

    // define BRORun struct
    struct broRun {
        uint256 tokenId;
        // string tokenURI;
        address mintedBy;
        address currentOwner;
        uint256 previousPrice;
        uint256 price;
        uint256 numberOfTransfers;
        bool forSale;
        uint256 kg;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // map id to BroRun obj
    mapping(uint256 => broRun) public allBroRun;

    //  implement the IERC721Enumerable which no longer come by default in openzeppelin 4.x
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    //================================= Events ================================= //
   

    event SaleToggle(uint256 broNumber, bool isForSale, uint256 price);
    event PurchaseEvent(uint256 broNumber, address from, address to, uint256 price);
    event LevelUp(uint256 broNumber, uint256 newKg);


    function initialize(
        address _contractOwner,
        address _royaltyReceiver,
        uint256 _royaltyPercentage,
        uint256 _mintFeeAmount,
        string memory _baseURL,
        bool _openForPublic
    ) public initializer {
        __ERC721_init("BRO", "BRO");
        royaltyPercentage = _royaltyPercentage;
        _owner = _contractOwner;
        _royaltiesAddr = _royaltyReceiver;
        mintFeeAmount = _mintFeeAmount;
        excludedList[_contractOwner] = true; // add owner to exclude list
        excludedList[_royaltyReceiver] = true; // add artist to exclude list
        baseURL = _baseURL;
        openForPublic = _openForPublic;
    }

    function mint(uint256 numberOfToken) public payable {
        // check if thic fucntion caller is not an zero address account
        require(openForPublic == true, "not open");
        require(msg.sender != address(0));
        require(
            _allTokens.length + numberOfToken <= maxSupply,
            "max supply"
        );
        require(numberOfToken > 0, "Min 1");
        require(numberOfToken <= 10, "Max 10");
        uint256 price = 0;
        // pay for minting cost
        if (excludedList[msg.sender] == false) {
            // send token's worth of ethers to the owner
            price = mintFeeAmount * numberOfToken;
            require(msg.value == price, "Not enough fee");
            payable(_royaltiesAddr).transfer(msg.value);
        } else {
            // return money to sender // since its free
            payable(msg.sender).transfer(msg.value);
        }

        for (uint256 i = 1; i <= numberOfToken; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            broRun memory newBroRun = broRun(
                newItemId,
                msg.sender,
                msg.sender,
                0,
                price,
                0,
                false,
                100
            );
            // add the token id to the allBroRun
            allBroRun[newItemId] = newBroRun;
        }
    }


    function changeUrl(string memory url) external {
        require(msg.sender == _owner, "Only owner");
        baseURL = url;
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }


    function setPriceForSale(
        uint256 _tokenId,
        uint256 _newPrice,
        bool isForSale
    ) external {
        require(_exists(_tokenId), "token not found");
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "not owner");
        broRun memory b = allBroRun[_tokenId];
        b.price = _newPrice;
        b.forSale = isForSale;
        allBroRun[_tokenId] = b;
        emit SaleToggle(_tokenId, isForSale, _newPrice);
    }

    function getAllSaleTokens() public view returns (uint256[] memory) {
        uint256 _totalSupply = totalSupply();
        uint256[] memory _tokenForSales = new uint256[](_totalSupply);
        uint256 counter = 0;
        for (uint256 i = 1; i <= _totalSupply; i++) {
            if (allBroRun[i].forSale == true) {
                _tokenForSales[counter] = allBroRun[i].tokenId;
                counter++;
            }
        }
        return _tokenForSales;
    }

    // by a token by passing in the token's id
    function buyToken(uint256 _tokenId) public payable {
        // check if the token id of the token being bought exists or not
        require(_exists(_tokenId));
        // get the token's owner
        address tokenOwner = ownerOf(_tokenId);
        // token's owner should not be an zero address account
        require(tokenOwner != address(0));
        // the one who wants to buy the token should not be the token's owner
        require(tokenOwner != msg.sender);
        // get that token from all broRun mapping and create a memory of it defined as (struct => broRun)
        broRun memory b = allBroRun[_tokenId];
        // price sent in to buy should be equal to or more than the token's price
        require(msg.value >= b.price);
        // token should be for sale
        require(b.forSale);
        uint256 amount = msg.value;
        uint256 _royaltiesAmount = (amount * royaltyPercentage) / 100;
        uint256 payOwnerAmount = amount - _royaltiesAmount;
        payable(_royaltiesAddr).transfer(_royaltiesAmount);
        payable(b.currentOwner).transfer(payOwnerAmount);
        b.previousPrice = b.price;
        allBroRun[_tokenId] = b;
        _transfer(tokenOwner, msg.sender, _tokenId);
        emit PurchaseEvent(_tokenId, b.currentOwner, msg.sender, b.price);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < balanceOf(owner), "out of bounds");
        return _ownedTokens[owner][index];
    }

    //  URI Storage override functions
    /** Overrides ERC-721's _baseURI function */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return baseURL;
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
        broRun memory b = allBroRun[tokenId];
        b.currentOwner = to;
        b.numberOfTransfers += 1;
        b.forSale = false;
        allBroRun[tokenId] = b;
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    // upgrade contract to support authorized

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] ||  msg.sender == _owner , "Not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public {
        require(msg.sender == _owner, 'Not owner');
        require(_toAdd != address(0));
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public {
        require(msg.sender == _owner, 'Not owner');
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    // upgrade the contract
    function setKg(uint256 _tokenId, uint256 _newKg) external onlyAuthorized {
        broRun memory b = allBroRun[_tokenId];
        b.kg = _newKg;
        // set and update that token in the mapping
        allBroRun[_tokenId] = b;
        emit LevelUp(_tokenId, _newKg);
    }
}


// File contracts/REPS.sol

  

pragma solidity >=0.8.0;





contract REPS is ERC20, Authorizable {
    using SafeMath for uint256;
    string private TOKEN_NAME = "BRO REPS";
    string private TOKEN_SYMBOL = "REPS";

    address public BRO_CONTRACT;

    // the base number of $REPS per bro (i.e. 0.75 $reps)
    uint256 public BASE_HOLDER_REPS = 750000000000000000;

    // the number of $REPS per bro per day per kg (i.e. 0.25 $reps /bro /day /kg)
    uint256 public REPS_PER_DAY_PER_KG = 250000000000000000;

    // how much reps it costs to skip the cooldown
    uint256 public COOLDOWN_BASE = 100000000000000000000; // base 100
    // how much additional reps it costs to skip the cooldown per kg
    uint256 public COOLDOWN_BASE_FACTOR = 100000000000000000000; // additional 100 per kg
    // how long to wait before skip cooldown can be re-invoked
    uint256 public COOLDOWN_CD_IN_SECS = 86400; // additional 100 per kg

    uint256 public LEVELING_BASE = 25;
    uint256 public LEVELING_RATE = 2;
    uint256 public COOLDOWN_RATE = 3600; // 60 mins

    // uint8 (0 - 255)
    // uint16 (0 - 65535)
    // uint24 (0 - 16,777,216)
    // uint32 (0 - 4,294,967,295)
    // uint40 (0 - 1,099,511,627,776)
    // unit48 (0 - 281,474,976,710,656)
    // uint256 (0 - 1.157920892e77)

    /**
     * Stores staked bro fields (=> 152 <= stored in order of size for optimal packing!)
     */
    struct StakedBroObj {
        // the current kg level (0 -> 16,777,216)
        uint24 kg;
        // when to calculate reps from (max 20/02/36812, 11:36:16)
        uint32 sinceTs;
        // for the skipCooldown's cooldown (max 20/02/36812, 11:36:16)
        uint32 lastSkippedTs;
        // how much this bro has been fed (in whole numbers)
        uint48 eatenAmount;
        // cooldown time until level up is allow (per kg)
        uint32 cooldownTs;
    }

    // redundant struct - can't be packed? (max totalKg = 167,772,160,000)
    uint40 public totalKg;
    uint16 public totalStakedBro;

    StakedBroObj[100001] public stakedBro;

    // Events

    event Minted(address owner, uint256 repsAmt);
    event Burned(address owner, uint256 repsAmt);
    event Staked(uint256 tid, uint256 ts);
    event UnStaked(uint256 tid, uint256 ts);

    // Constructor

    constructor(address _broContract) ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        BRO_CONTRACT = _broContract;
    }

    // "READ" Functions
    // How much is required to be fed to level up per kg

    function muscleLevelingRate(uint256 kg) public view returns (uint256) {
        // need to divide the kg by 100, and make sure the muscle level is at 18 decimals
        return LEVELING_BASE * ((kg / 100)**LEVELING_RATE);
    }

    // when using the value, need to add the current block timestamp as well
    function cooldownRate(uint256 kg) public view returns (uint256) {
        // need to divide the kg by 100

        return (kg / 100) * COOLDOWN_RATE;
    }

    // Staking Functions

    // stake bro, check if is already staked, get all detail for bro such as
    function _stake(uint256 tid) internal {
        BRO x = BRO(BRO_CONTRACT);

        // verify user is the owner of the bro...
        require(x.ownerOf(tid) == msg.sender, "NOT OWNER");

        // get calc'd values...
        (, , , , , , , uint256 kg) = x.allBroRun(tid);
        // if lastSkippedTs is 0 its mean it never have a last skip timestamp
        StakedBroObj memory b = stakedBro[tid];
        uint32 ts = uint32(block.timestamp);
        if (stakedBro[tid].kg == 0) {
            // create staked bro...
            stakedBro[tid] = StakedBroObj(
                uint24(kg),
                ts,
                b.lastSkippedTs > 0 ? b.lastSkippedTs :  uint32(ts - COOLDOWN_CD_IN_SECS),
                uint48(0),
                uint32(ts) + uint32(cooldownRate(kg)) 
            );

            // update snapshot values...
            // N.B. could be optimised for multi-stakes - but only saves 0.5c AUD per bro - not worth it, this is a one time operation.
            totalStakedBro += 1;
            totalKg += uint24(kg);

            // let ppl know!
            emit Staked(tid, block.timestamp);
        }
    }


    function stake(uint256[] calldata tids) external {
        for (uint256 i = 0; i < tids.length; i++) {
            _stake(tids[i]);
        }
    }

    /**
     * Calculates the amount of reps that is claimable from a bro.
     */
    function claimableView(uint256 tokenId) public view returns (uint256) {
        StakedBroObj memory b = stakedBro[tokenId];
        if (b.kg > 0) {
            uint256 repsPerDay = ((REPS_PER_DAY_PER_KG * (b.kg / 100)) +
                BASE_HOLDER_REPS);
            uint256 deltaSeconds = block.timestamp - b.sinceTs;
            return deltaSeconds * (repsPerDay / 86400);
        } else {
            return 0;
        }
    }


    /**
     * Get all MY staked bro id
     */

    function myStakedBro() public view returns (uint256[] memory) {
        BRO x = BRO(BRO_CONTRACT);
        uint256 broCount = x.balanceOf(msg.sender);
        uint256[] memory tokenIds = new uint256[](broCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < broCount; i++) {
            uint256 tokenId = x.tokenOfOwnerByIndex(msg.sender, i);
            StakedBroObj memory b = stakedBro[tokenId];
            if (b.kg > 0) {
                tokenIds[counter] = tokenId;
                counter++;
            }
        }
        return tokenIds;
    }

    /**
     * Calculates the TOTAL amount of reps that is claimable from ALL bro.
     */
    function myClaimableView() public view returns (uint256) {
        BRO x = BRO(BRO_CONTRACT);
        uint256 cnt = x.balanceOf(msg.sender);
        require(cnt > 0, "NO BRO");
        uint256 totalClaimable = 0;
        for (uint256 i = 0; i < cnt; i++) {
            uint256 tokenId = x.tokenOfOwnerByIndex(msg.sender, i);
            StakedBroObj memory b = stakedBro[tokenId];
            // make sure that the token is staked
            if (b.kg > 0) {
                uint256 claimable = claimableView(tokenId);
                if (claimable > 0) {
                    totalClaimable = totalClaimable + claimable;
                }
            }
        }
        return totalClaimable;
    }

    /**
     * Claims reps from the provided bro.
     */
    function _claimReps(uint256[] calldata tokenIds) internal {
        BRO x = BRO(BRO_CONTRACT);
        uint256 totalClaimableReps = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(x.ownerOf(tokenIds[i]) == msg.sender, "NOT OWNER");
            StakedBroObj memory b = stakedBro[tokenIds[i]];
            // we only care about bro that have been staked (i.e. kg > 0) ...
            if (b.kg > 0) {
                uint256 claimableReps = claimableView(tokenIds[i]);
                if (claimableReps > 0) {
                    totalClaimableReps = totalClaimableReps + claimableReps;
                    // reset since, for the next calc...
                    b.sinceTs = uint32(block.timestamp);
                    stakedBro[tokenIds[i]] = b;
                }
            }
        }
        if (totalClaimableReps > 0) {
            _mint(msg.sender, totalClaimableReps);
            emit Minted(msg.sender, totalClaimableReps);
        }
    }

    /**
     * Claims reps from the provided bro.
     */
    function claimReps(uint256[] calldata tokenIds) external {
        _claimReps(tokenIds);
    }

    /**
     * Unstakes a bro. Why you'd call this, I have no idea.
     */
    function _unstake(uint256 tokenId) internal {
        BRO x = BRO(BRO_CONTRACT);

        // verify user is the owner of the bro...
        require(x.ownerOf(tokenId) == msg.sender, "NOT OWNER");

        // update bro...
        StakedBroObj memory c = stakedBro[tokenId];
        if (c.kg > 0) {
            // update snapshot values...
            totalKg -= uint24(c.kg);
            totalStakedBro -= 1;

            c.kg = 0;
            stakedBro[tokenId] = c;

            // let ppl know!
            emit UnStaked(tokenId, block.timestamp);
        }
    }

    function _unstakeMultiple(uint256[] calldata tids) internal {
        for (uint256 i = 0; i < tids.length; i++) {
            _unstake(tids[i]);
        }
    }

    /**
     * Unstakes MULTIPLE bro. Why you'd call this, I have no idea.
     */
    function unstake(uint256[] calldata tids) external {
        _unstakeMultiple(tids);
    }

    /**
     * Unstakes MULTIPLE bro AND claims the reps.
     */
    function withdrawAllBroAndClaim(uint256[] calldata tids) external {
        _claimReps(tids);
        _unstakeMultiple(tids);
    }

    /**
     * Public : update the bro's KG level.
     */
     function levelUpBro(uint256 tid) external {
        StakedBroObj memory c = stakedBro[tid];
        require(c.kg > 0, "NOT STAKED");

        BRO x = BRO(BRO_CONTRACT);
        // NOTE Does it matter if sender is not owner?
        // require(x.ownerOf(broId) == msg.sender, "NOT OWNER");

        // check: bro has eaten enough...
        require(c.eatenAmount >= muscleLevelingRate(c.kg), "MORE Muscle REQD");
        // check: cooldown has passed...
        require(block.timestamp >= c.cooldownTs, "COOLDOWN NOT MET");

        // increase kg, reset eaten to 0, update next muscle level and cooldown time
        c.kg = c.kg + 100;
        c.eatenAmount = 0;
        c.cooldownTs = uint32(block.timestamp + cooldownRate(c.kg));
        stakedBro[tid] = c;

        // need to increase overall size
        totalKg += uint24(100);

        // and update the bro contract
        x.setKg(tid, c.kg);
    }

    /**
     * Internal: burns the given amount of reps from the wallet.
     */
    function _burnReps(address sender, uint256 repsAmount) internal {
        // NOTE do we need to check this before burn?
        require(balanceOf(sender) >= repsAmount, "NOT ENOUGH REPS");
        _burn(sender, repsAmount);
        emit Burned(sender, repsAmount);
    }

    /**
     * Burns the given amount of reps from the sender's wallet.
     */
    function burnReps(address sender, uint256 repsAmount) external onlyAuthorized {
        _burnReps(sender, repsAmount);
    }

    /**
     * Skips the "levelUp" cooling down period, in return for burning Reps.
     */
     function skipCoolingOff(uint256 tokenId, uint256 repsAmt) external {
        StakedBroObj memory b = stakedBro[tokenId];
        require(b.kg != 0, "NOT STAKED");

        uint32 ts = uint32(block.timestamp);

        // NOTE Does it matter if sender is not owner?
        // BRO instance = BRO(BRO_CONTRACT);
        // require(instance.ownerOf(broId) == msg.sender, "NOT OWNER");

        // check: enough reps in wallet to pay
        uint256 walletBalance = balanceOf(msg.sender);
        require( walletBalance >= repsAmt, "NOT ENOUGH REPS IN WALLET");

        // check: provided reps amount is enough to skip this level
        require(repsAmt >= checkSkipCoolingOffAmt(b.kg), "NOT ENOUGH REPS TO SKIP");

        // check: user hasn't skipped cooldown in last 24 hrs
        require((b.lastSkippedTs + COOLDOWN_CD_IN_SECS) <= ts, "BLOCKED BY 24HR COOLDOWN");

        // burn reps
        _burnReps(msg.sender, repsAmt);

        // disable cooldown
        b.cooldownTs = ts;
        // track last time cooldown was skipped (i.e. now)
        b.lastSkippedTs = ts;
        stakedBro[tokenId] = b;
    }

    /**
     * Calculates the cost of skipping cooldown.
     */
    function checkSkipCoolingOffAmt(uint256 kg) public view returns (uint256) {
        // NOTE cannot assert KG is < 100... we can have large numbers!
        return ((kg / 100) * COOLDOWN_BASE_FACTOR);
    }

    /**
     * Muscle Muscling the bro
     */
    function muscleBro(uint256 tokenId, uint256 muscleAmount)
        external
        onlyAuthorized
    {
        StakedBroObj memory b = stakedBro[tokenId];
        require(b.kg > 0, "NOT STAKED");
        require(muscleAmount > 0, "NOTHING TO MUSCLE");
        // update the block time as well as claimable
        b.eatenAmount = uint48(muscleAmount / 1e18) + b.eatenAmount;
        stakedBro[tokenId] = b;
    }

    // NOTE What happens if we update the multiplier, and people have been staked for a year...?
    // We need to snapshot somehow... but we're physically unable to update 10k records!!!

    // Removed "updateBaseReps" - to make space

    // Removed "updateRepsPerDayPerKg" - to make space

    // ADMIN: to update the cost of skipping cooldown
    function updateSkipCooldownValues(
        uint256 a, 
        uint256 b, 
        uint256 c,
        uint256 d,
        uint256 e
    ) external onlyOwner {
        COOLDOWN_BASE = a;
        COOLDOWN_BASE_FACTOR = b;
        COOLDOWN_CD_IN_SECS = c;
        BASE_HOLDER_REPS = d;
        REPS_PER_DAY_PER_KG = e;
    }

    // INTRA-CONTRACT: use this function to mint reps to users
    // this also get called by the MUSCLE contract
    function mintReps(address sender, uint256 amount) external onlyAuthorized {
        _mint(sender, amount);
        emit Minted(sender, amount);
    }

    // ADMIN: drop reps to the given bro wallet owners (within the broId range from->to).
    function airdropToExistingHolder(
        uint256 from,
        uint256 to,
        uint256 amountOfBro
    ) external onlyOwner {
        // mint 100 reps to every owners
        BRO instance = BRO(BRO_CONTRACT);
        for (uint256 i = from; i <= to; i++) {
            address currentOwner = instance.ownerOf(i);
            if (currentOwner != address(0)) {
                _mint(currentOwner, amountOfBro * 1e18);
            }
        }
    }

    // ADMIN: Rebalance user wallet by minting reps (within the broId range from->to).
    // NOTE: This is use when we need to update reps production
    function rebalanceRepsClaimableToUserWallet(uint256 from, uint256 to)
        external
        onlyOwner
    {
        BRO instance = BRO(BRO_CONTRACT);
        for (uint256 i = from; i <= to; i++) {
            address currentOwner = instance.ownerOf(i);
            StakedBroObj memory b = stakedBro[i];
            // we only care about Bro that have been staked (i.e. kg > 0) ...
            if (b.kg > 0) {
                _mint(currentOwner, claimableView(i));
                b.sinceTs = uint32(block.timestamp);
                stakedBro[i] = b;
            }
        }
    }
}


// File contracts/MUSCLE.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;






contract MUSCLE is ERC20, Authorizable {
    using SafeMath for uint256;

    uint256 public MAX_MUSCLE_SUPPLY = 32000000000000000000000000000;
    string private TOKEN_NAME = "BRO MUSCLE";
    string private TOKEN_SYMBOL = "MUSCLE";

    address public BRO_CONTRACT;
    address public REPS_CONTRACT;

    uint256 public BOOSTER_MULTIPLIER = 1;
    uint256 public MUSCLE_FARMING_FACTOR = 3; // reps to muscle ratio
    uint256 public MUSCLE_SWAP_FACTOR = 12; // swap reps for muscle ratio


    // muscle mint event
    event Minted(address owner, uint256 numberOfMuscle);
    event Burned(address owner, uint256 numberOfMuscle);
    event RepsSwap(address owner, uint256 numberOfMuscle);
    // reps event
    event MintedReps(address owner, uint256 numberOfMuscle);
    event BurnedReps(address owner, uint256 numberOfReps);
    event StakedReps(address owner, uint256 numberOfReps);
    event UnstakedReps(address owner, uint256 numberOfReps);

    // Reps staking
    struct RepsStake {
        // user wallet - who we have to pay back for the staked reps.
        address user;
        // used to calculate how much muscle since.
        uint32 since;
        // amount of reps that have been staked.
        uint256 amount;
    }

    mapping(address => RepsStake) public repsStakeHolders;
    uint256 public totalRepsStaked;
    address[] public _allRepsStakeHolders;
    mapping(address => uint256) private _allRepsStakeHoldersIndex;

    // reps stake and unstake
    event RepsStaked(address user, uint256 amount);
    event RepsUnStaked(address user, uint256 amount);

    constructor(address _broContract, address _repsContract)
        ERC20(TOKEN_NAME, TOKEN_SYMBOL)
    {
        BRO_CONTRACT = _broContract;
        REPS_CONTRACT = _repsContract;
    }

    /**
     * pdates user's amount of staked repss to the given value. Resets the "since" timestamp.
     */
    function _upsertRepsStaking(
        address user,
        uint256 amount
    ) internal {
        // NOTE does this ever happen?
        require(user != address(0), "EMPTY ADDRESS");
        RepsStake memory r = repsStakeHolders[user];

        // if first time user is staking $reps...
        if (r.user == address(0)) {
            // add tracker for first time staker
            _allRepsStakeHoldersIndex[user] = _allRepsStakeHolders.length;
            _allRepsStakeHolders.push(user);
        }
        // since its an upsert, we took out old reps and add new amount
        uint256 previousReps = r.amount;
        // update stake
        r.user = user;
        r.amount = amount;
        r.since = uint32(block.timestamp);

        repsStakeHolders[user] = r;
        totalRepsStaked = totalRepsStaked - previousReps + amount;
        emit RepsStaked(user, amount);
    }

    function staking(uint256 amount) external {
        require(amount > 0, "NEED REPS");
        REPS repsContract = REPS(REPS_CONTRACT);
        uint256 available = repsContract.balanceOf(msg.sender);
        require(available >= amount, "NOT ENOUGH REPS");
        RepsStake memory existingReps = repsStakeHolders[msg.sender];
        if (existingReps.amount > 0) {
            // already have previous reps staked
            // need to calculate claimable
            uint256 projection = claimableView(msg.sender);
            // mint muscle to wallet
            _mint(msg.sender, projection);
            emit Minted(msg.sender, amount);
            _upsertRepsStaking(msg.sender, existingReps.amount + amount);
        } else {
            // no reps staked just update staking
            _upsertRepsStaking(msg.sender, amount);
        }
        repsContract.burnReps(msg.sender, amount);
        emit StakedReps(msg.sender, amount);
    }

    /**
     * Calculates how much muscle is available to claim.
     */
    function claimableView(address user) public view returns (uint256) {
        RepsStake memory r = repsStakeHolders[user];
        require(r.user != address(0), "NOT STAKED");
        // need to add 10000000000 to factor for decimal
        return
            ((r.amount * MUSCLE_FARMING_FACTOR) *
                (((block.timestamp - r.since) * 10000000000) / 86400) *
                BOOSTER_MULTIPLIER) /
            10000000000;
    }

    // NOTE withdrawing reps without claiming muscle
    function withdrawReps(uint256 amount) external {
        require(amount > 0, "MUST BE MORE THAN 0");
        RepsStake memory r = repsStakeHolders[msg.sender];
        require(r.user != address(0), "NOT STAKED");
        require(amount <= r.amount, "OVERDRAWN");
        REPS repsContract = REPS(REPS_CONTRACT);
        // uint256 projection = claimableView(msg.sender);
        _upsertRepsStaking(msg.sender, r.amount - amount);
        // Need to burn 1/12 when withdrawing (breakage fee)
        uint256 afterBurned = (amount * 11) / 12;
        // mint reps to return to user
        repsContract.mintReps(msg.sender, afterBurned);
        emit UnstakedReps(msg.sender, afterBurned);
    }

    /**
     * Claims muscle from staked Reps
     */
    function claimMuscle() external {
        uint256 projection = claimableView(msg.sender);
        require(projection > 0, "NO MUSCLE TO CLAIM");

        RepsStake memory r = repsStakeHolders[msg.sender];

        // Updates user's amount of staked reps to the given value. Resets the "since" timestamp.
        _upsertRepsStaking(msg.sender, r.amount);

        // check: that the total Muscle supply hasn't been exceeded.
        _mintMuscle(msg.sender, projection);
    }

    /**
     */
    function _removeUserFromRepsEnumeration(address user) private {
        uint256 lastUserIndex = _allRepsStakeHolders.length - 1;
        uint256 currentUserIndex = _allRepsStakeHoldersIndex[user];

        address lastUser = _allRepsStakeHolders[lastUserIndex];

        _allRepsStakeHolders[currentUserIndex] = lastUser; // Move the last token to the slot of the to-delete token
        _allRepsStakeHoldersIndex[lastUser] = currentUserIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allRepsStakeHoldersIndex[user];
        _allRepsStakeHolders.pop();
    }

    /**
     * Unstakes the reps, returns the Reps (mints) to the user.
     */
    function withdrawAllRepsAndClaimMuscle() external {
        RepsStake memory r = repsStakeHolders[msg.sender];

        // NOTE does this ever happen?
        require(r.user != address(0), "NOT STAKED");

        // if there's muscle to claim, supply it to the owner...
        uint256 projection = claimableView(msg.sender);
        if (projection > 0) {
            // supply muscle to the sender...
            _mintMuscle(msg.sender, projection);
        }
        // if there's reps to withdraw, supply it to the owner...
        if (r.amount > 0) {
            // mint reps to return to user
            // Need to burn 1/12 when withdrawing (breakage fee)
            uint256 afterBurned = (r.amount * 11) / 12;
            REPS repsContract = REPS(REPS_CONTRACT);
            repsContract.mintReps(msg.sender, afterBurned);
            emit UnstakedReps(msg.sender, afterBurned);
        }
        // Internal: removes reps from storage.
        _unstakingReps(msg.sender);
    }

    /**
     * Internal: removes reps from storage.
     */
    function _unstakingReps(address user) internal {
        RepsStake memory r = repsStakeHolders[user];
        // NOTE when whould address be zero?
        require(r.user != address(0), "EMPTY ADDRESS");
        totalRepsStaked = totalRepsStaked - r.amount;
        _removeUserFromRepsEnumeration(user);
        delete repsStakeHolders[user];
        emit RepsUnStaked(user, r.amount);
    }

    /**
     * Muscle the bro the amount of Muscle.
     */
    function muscleBro(uint256 broId, uint256 amount) external {
        // check: amount is gt zero...
        require(amount > 0, "MUST BE MORE THAN 0 MUSCLE");

        IERC721 instance = IERC721(BRO_CONTRACT);

        // check: msg.sender is bro owner...
        require(instance.ownerOf(broId) == msg.sender, "NOT OWNER");
        
        // check: user has enough muscle in wallet...
        require(balanceOf(msg.sender) >= amount, "NOT ENOUGH MUSCLE");
        
        // TODO should this be moved to reps contract? or does the order here, matter?
        REPS repsContract = REPS(REPS_CONTRACT);
        (uint24 kg, , , , ) = repsContract.stakedBro(broId);
        require(kg > 0, "NOT STAKED");

        // burn muscle...
        _burn(msg.sender, amount);
        emit Burned(msg.sender, amount);

        // update eatenAmount in REPS contract...
        repsContract.muscleBro(broId, amount);
    }

    function swapRepsForMuscle(uint256 repsAmt) external {
        require(repsAmt > 0, "MUST BE MORE THAN 0 REPS");

        // burn reps...
        REPS repsContract = REPS(REPS_CONTRACT);
        repsContract.burnReps(msg.sender, repsAmt);

        // supply muscle...
        _mint(msg.sender, repsAmt * MUSCLE_SWAP_FACTOR);
        emit RepsSwap(msg.sender, repsAmt * MUSCLE_SWAP_FACTOR);
    }

    /**
     * Internal: mints the muscle to the given wallet.
     */
    function _mintMuscle(address sender, uint256 muscleAmount) internal {
        // check: that the total Muscle supply hasn't been exceeded.
        require(totalSupply() + muscleAmount < MAX_MUSCLE_SUPPLY, "OVER MAX SUPPLY");
        _mint(sender, muscleAmount);
        emit Minted(sender, muscleAmount);
    }

    // ADMIN FUNCTIONS

    /**
     * Admin : mints the muscle to the given wallet.
     */
    function mintMuscle(address sender, uint256 amount) external onlyOwner {
        _mintMuscle(sender, amount);
    }

    /**
     * Admin : used for temporarily multipling how much muscle is distributed per staked reps.
     */
    function updateBoosterMultiplier(uint256 _value) external onlyOwner {
        BOOSTER_MULTIPLIER = _value;
    }

    /**
     * Admin : updates how much muscle you get per staked reps (e.g. 3x).
     */
    function updateFarmingFactor(uint256 _value) external onlyOwner {
        MUSCLE_FARMING_FACTOR = _value;
    }

    /**
     * Admin : updates the multiplier for swapping (burning) reps for muscle (e.g. 12x).
     */
    function updateMuscleSwapFactor(uint256 _value) external onlyOwner {
        MUSCLE_SWAP_FACTOR = _value;
    }

    /**
     * Admin : updates the maximum available muscle supply.
     */
    function updateMaxMuscleSupply(uint256 _value) external onlyOwner {
        MAX_MUSCLE_SUPPLY = _value;
    }

    /**
     * Admin : util for working out how many people are staked.
     */
    function totalRepsHolder() public view returns (uint256) {
        return _allRepsStakeHolders.length;
    }

    /**
     * Admin : gets the wallet for the the given index. Used for rebalancing.
     */
    function getRepsHolderByIndex(uint256 index) internal view returns (address){
        return _allRepsStakeHolders[index];
    }

    /**
     * Admin : Rebalances the pool. Mint to the user's wallet. Only called if changing multiplier.
     */
    function rebalanceStakingPool(uint256 from, uint256 to) external onlyOwner {
        // for each holder of staked reps...
        for (uint256 i = from; i <= to; i++) {
            address holderAddress = getRepsHolderByIndex(i);

            // check how much muscle is claimable...
            uint256 pendingClaim = claimableView(holderAddress);
            RepsStake memory r = repsStakeHolders[holderAddress];

            // supply Muscle to the owner's wallet...
            _mint(holderAddress, pendingClaim);
            emit Minted(holderAddress, pendingClaim);

            // pdates user's amount of staked reps to the given value. Resets the "since" timestamp.
            _upsertRepsStaking(holderAddress, r.amount);
        }
    }
}