// SPDX-License-Identifier: MIT

/*
 *
 * ░█▀█░█░░░▀█▀░█▀▀░█░█░▀█▀░▀█▀░█▀▀░█░█
 * ░█▀█░█░░░░█░░▀▀█░█▄█░░█░░░█░░█░░░█▀█
 * ░▀░▀░▀▀▀░░▀░░▀▀▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀░▀
 *
 *  AltSwitch v2
 *  https://altswitch.io/
 *
 *  @author raldblox (github.com/raldblox)
 *
 */

pragma solidity ^0.8.10;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(
        address newOwner
    ) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(
            pendingOwner() == sender,
            "Ownable2Step: caller is not the new owner"
        );
        _transferOwnership(sender);
    }
}

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(
        address _owner
    ) external view returns (uint256);

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(
        address _owner
    ) external view returns (uint256);

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(
        address _owner
    ) external view returns (uint256);
}

/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) external view returns (uint256);

    /// @notice Distributes ether to token holders as dividends.
    /// @dev SHOULD distribute the paid ether to token holders as dividends.
    ///  SHOULD NOT directly transfer ether to token holders in this function.
    ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
    function distributeDividends() external payable;

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
    ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
    function withdrawDividend() external;

    /// @dev This event MUST emit when ether is distributed to token holders.
    /// @param from The address which sends ether to this contract.
    /// @param weiAmount The amount of distributed ether in wei.
    event DividendsDistributed(address indexed from, uint256 weiAmount);

    /// @dev This event MUST emit when an address withdraws their dividend.
    /// @param to The address which withdraws ether from this contract.
    /// @param weiAmount The amount of withdrawn ether in wei.
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
        return _decimals;
        // return 18; // @note Update to 18 decimals (disabled)
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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
}

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface,
    Ownable2Step
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 internal constant magnitude = 2 ** 128;

    uint256 internal magnifiedDividendPerShare;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    mapping(address => uint256) internal rawBNBWithdrawnDividends;
    mapping(address => address) public userCurrentRewardToken;
    mapping(address => bool) public userHasCustomRewardToken;
    mapping(address => address) public userCurrentRewardAMM;
    mapping(address => bool) public userHasCustomRewardAMM;
    mapping(address => uint256) public rewardTokenSelectionCount; // Keep track of how many people have each reward token selected
    mapping(address => bool) public ammIsWhiteListed; // Only allow whitelisted AMMs
    mapping(address => bool) public blackListRewardTokens;

    // @note Router address for PancakeSwap v2 (LIVE) @note enabled
    // IUniswapV2Router02 public uniswapV2Router =
    //     IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    // @note Router address for PancakeSwap (TESTNET) @note disabled
    // IUniswapV2Router02 public uniswapV2Router =
    //     IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

    // @note Router address for Arbitrum (TESTNET) @note disabled
    IUniswapV2Router02 public uniswapV2Router =
        IUniswapV2Router02(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    function updateDividendUniswapV2Router(
        address newAddress
    ) external onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "ALTSWITCH: The router already has that address"
        );
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    uint256 public totalDividendsDistributed; // dividends distributed per reward token

    // @note Whitelisted AMMs
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        // ammIsWhiteListed[
        //     address(0x10ED43C718714eb63d5aA57B78B54704E256024E)
        // ] = true; // PCS V2 router @note disabled
        // ammIsWhiteListed[address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F)] = true; // PCS V1 router @note disabled
        // ammIsWhiteListed[address(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7)] = true; // ApeSwap router @note disabled
        //ammIsWhiteListed[address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1)] = true; // PCS Testnet router @note enabled
        ammIsWhiteListed[
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f) // Arbitrum Goerli Testnet router @note enabled
        ] = true;
    }

    /// @dev Distributes dividends whenever ether is paid to this contract.
    receive() external payable {
        distributeDividends();
    }

    // Customized function to send tokens to dividend recipients
    function swapETHForTokens(
        address recipient,
        uint256 ethAmount
    ) private returns (uint256) {
        bool swapSuccess;
        IERC20 token = IERC20(userCurrentRewardToken[recipient]);
        IUniswapV2Router02 swapRouter = uniswapV2Router;

        if (
            userHasCustomRewardAMM[recipient] &&
            ammIsWhiteListed[userCurrentRewardAMM[recipient]]
        ) {
            swapRouter = IUniswapV2Router02(userCurrentRewardAMM[recipient]);
        }

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(token);

        // make the swap
        try
            swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: ethAmount
            }( //try to swap for tokens, if it fails (bad contract, or whatever other reason, send BNB)
                1, // accept any amount of Tokens above 1 wei (so it will fail if nothing returns)
                path,
                address(recipient),
                block.timestamp + 360
            )
        {
            swapSuccess = true;
        } catch {
            swapSuccess = false;
        }

        // if the swap failed, send them their BNB instead
        if (!swapSuccess) {
            rawBNBWithdrawnDividends[recipient] = rawBNBWithdrawnDividends[
                recipient
            ].add(ethAmount);
            (bool success, ) = recipient.call{value: ethAmount, gas: 3000}("");

            if (!success) {
                withdrawnDividends[recipient] = withdrawnDividends[recipient]
                    .sub(ethAmount);
                rawBNBWithdrawnDividends[recipient] = rawBNBWithdrawnDividends[
                    recipient
                ].sub(ethAmount);
                return 0;
            }
        }
        return ethAmount;
    }

    function excludeRewardToken(
        address tokenAddress,
        bool isExcluded
    ) external onlyOwner {
        blackListRewardTokens[tokenAddress] = isExcluded;
    }

    function isExcludedRewardToken(
        address tokenAddress
    ) public view returns (bool) {
        return blackListRewardTokens[tokenAddress];
    }

    function getRawBNBDividends(
        address holder
    ) external view returns (uint256) {
        return rawBNBWithdrawnDividends[holder];
    }

    function setWhiteListAMM(
        address ammAddress,
        bool whitelisted
    ) external onlyOwner {
        ammIsWhiteListed[ammAddress] = whitelisted;
    }

    // call this to set a custom reward token (call from token contract only)
    function setRewardToken(
        address holder,
        address rewardTokenAddress,
        address ammContractAddress
    ) external onlyOwner {
        if (userHasCustomRewardToken[holder] == true) {
            if (rewardTokenSelectionCount[userCurrentRewardToken[holder]] > 0) {
                rewardTokenSelectionCount[userCurrentRewardToken[holder]] -= 1; // remove count from old token
            }
        }

        userHasCustomRewardToken[holder] = true;
        userCurrentRewardToken[holder] = rewardTokenAddress;
        // only set custom AMM if the AMM is whitelisted.
        if (
            ammContractAddress != address(uniswapV2Router) &&
            ammIsWhiteListed[ammContractAddress]
        ) {
            userHasCustomRewardAMM[holder] = true;
            userCurrentRewardAMM[holder] = ammContractAddress;
        } else {
            userHasCustomRewardAMM[holder] = false;
            userCurrentRewardAMM[holder] = address(uniswapV2Router);
        }
        rewardTokenSelectionCount[rewardTokenAddress] += 1; // add count to new token
    }

    // call this to go back to receiving BNB after setting another token. (call from token contract only)
    function unsetRewardToken(address holder) external onlyOwner {
        userHasCustomRewardToken[holder] = false;
        if (rewardTokenSelectionCount[userCurrentRewardToken[holder]] > 0) {
            rewardTokenSelectionCount[userCurrentRewardToken[holder]] -= 1; // remove count from old token
        }
        userCurrentRewardToken[holder] = address(0);
        userCurrentRewardAMM[holder] = address(uniswapV2Router);
        userHasCustomRewardAMM[holder] = false;
    }

    /// @notice Distributes ether to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.

    function distributeDividends() public payable override {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(
                msg.value
            );
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(
        address payable user
    ) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            // if no custom reward token or reward token is blacklisted, send BNB.
            if (
                !userHasCustomRewardToken[user] &&
                !isExcludedRewardToken(userCurrentRewardToken[user])
            ) {
                withdrawnDividends[user] = withdrawnDividends[user].add(
                    _withdrawableDividend
                );
                rawBNBWithdrawnDividends[user] = rawBNBWithdrawnDividends[user]
                    .add(_withdrawableDividend);
                emit DividendWithdrawn(user, _withdrawableDividend);
                (bool success, ) = user.call{
                    value: _withdrawableDividend,
                    gas: 3000
                }("");

                if (!success) {
                    withdrawnDividends[user] = withdrawnDividends[user].sub(
                        _withdrawableDividend
                    );
                    rawBNBWithdrawnDividends[user] = rawBNBWithdrawnDividends[
                        user
                    ].sub(_withdrawableDividend);
                    return 0;
                }
                return _withdrawableDividend;

                // the reward is a token, not BNB, use an IERC20 buyback instead!
            } else {
                withdrawnDividends[user] = withdrawnDividends[user].add(
                    _withdrawableDividend
                );
                emit DividendWithdrawn(user, _withdrawableDividend);
                return swapETHForTokens(user, _withdrawableDividend);
            }
        }
        return 0;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256Safe() / magnitude;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare
            .mul(value)
            .toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
            .add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
            _magCorrection
        );
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

contract AltSwitch is ERC20, Ownable2Step {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    AltSwitchDividendTracker public dividendTracker;

    mapping(address => uint256) public holderBNBUsedForBuyBacks;

    address public liquidityWallet;
    address public operationsWallet;

    uint256 public swapTokensAtAmount = 100000 * (10 ** 9); // @note Equals 1e+14 | 100,000

    // Anti-bot and anti-whale mappings and variables for launch
    mapping(address => uint256) private _holderLastTransferTimestamp; // Hold the last Transfer temporarily during launch

    // @note For the launch, enable transfer delays
    bool public transferDelayEnabled = true;
    bool private swapping;
    bool private tradingIsEnabled;
    bool private noTaxOnBuy;

    // Stores partnered enterprise
    mapping(address => bool) private isEnterprises;
    uint16 _minimumRebate;

    // Store transfer fees and rebates of each addresses during wallet-to-wallet transfer
    mapping(address => uint16) private _percentEnterpriseRebate;
    mapping(address => bool) private _isWithCustomRebate;
    mapping(address => uint256) public userRebatesEarned;
    mapping(address => uint256) public rebatesIssued;

    //Anti-dump mechanism
    uint256 public sellFeeIncreaseFactor = 2;
    struct UserSellPerCycle {
        uint256 currentSellFee;
        uint256 firstSellTime;
    }

    mapping(address => UserSellPerCycle) public userSellPerCycle;

    // Fees @note Updated fees
    uint256 public BNBRewardsFee = 5;
    uint256 public liquidityFee = 5;
    uint256 public totalFees = BNBRewardsFee.add(liquidityFee);
    uint256 public operationsFee = 2; // This is a subset of the liquidity fee, not in addition to.

    // Use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // Exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private canTransferBeforeTradingIsEnabled;

    // Store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event RegisterEnterprise(address indexed account, bool isRegistered);
    event RegisterMultipleEnterprises(address[] accounts, bool included);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BuyBackWithNoFees(address indexed holder, uint256 indexed bnbSpent);
    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );
    event OperationsWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );
    event FeesUpdated(
        uint256 indexed newBNBRewardsFee,
        uint256 indexed newLiquidityFee,
        uint256 newOperationsFee
    );
    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("AltSwitch", "ALTZ", 9) {
        dividendTracker = new AltSwitchDividendTracker();

        liquidityWallet = owner();
        operationsWallet = owner();

        // @note Router address for PancakeSwap v2 (LIVE) @note enabled
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
        //     0x10ED43C718714eb63d5aA57B78B54704E256024E
        // );

        // @note Router address for PancakeSwap v2 (TESTNET) @note enabled
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
        //     0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        // );

        // @note Router address for Arbitrum Goerli v3 (TESTNET) @note enabled
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        );

        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // Exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(liquidityWallet);
        dividendTracker.excludeFromDividends(
            address(0x000000000000000000000000000000000000dEaD)
        );
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // Exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);
        excludeFromFees(address(operationsWallet), true);

        // @note tradingIsEnabled
        canTransferBeforeTradingIsEnabled[owner()] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000000 * (10 ** 9)); // @note Equals 1e+18 | Set supply to 1,000,000,000 (without override)
    }

    receive() external payable {}

    modifier onlyEnterprise() {
        require(isEnterprises[msg.sender] == true || owner() == msg.sender);
        _;
    }

    // Register wallet/contracts as enterprise.
    function registerEnterprise(
        address account,
        bool included
    ) external onlyOwner {
        isEnterprises[account] = included;
        emit RegisterEnterprise(account, included);
    }

    // Register wallets/contracts as enterprise.
    function registerMultipleEnterprise(
        address[] calldata accounts,
        bool included
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isEnterprises[accounts[i]] = included;
        }
        emit RegisterMultipleEnterprises(accounts, included);
    }

    /**
     * Set the default rebate on wallet to wallet transfer.
     * @param percentRebate the default rebates(%) of all users w/o custom tax. Note maximum rebate input = 10%
     */
    function updateMinimumRebate(uint16 percentRebate) external onlyOwner {
        require(percentRebate <= 10000, "ALTSWITCH: Maximum rebate is 100%");
        _minimumRebate = percentRebate;
    }

    /**
     * Set the custom rebates on each wallet address.
     * @param addr Address of holder. NOTE: Cannot be zero address.
     * @param percentRebate Tax on transfer by the holder.
     * Inputs: minimum: 1 for 0.01% | maximum: 1000 for 10%
     */
    function setEnterpriseRebate(
        address addr,
        uint16 percentRebate
    ) external onlyEnterprise {
        require(addr != address(0), "Zero address not allowed");
        require(isEnterprises[addr], "Address is not an enterprise");
        require(percentRebate <= 10000, "Maximum rebates on transfer is 100%"); // 1 means 0.01%; 10000 means 100%
        if (owner() == msg.sender) {
            if (percentRebate == 0) {
                _isWithCustomRebate[addr] = false;
            } else {
                _isWithCustomRebate[addr] = true;
            }
            _percentEnterpriseRebate[addr] = percentRebate;
        } else {
            if (percentRebate == 0) {
                _isWithCustomRebate[addr] = false;
            } else {
                _isWithCustomRebate[addr] = true;
            }
            _percentEnterpriseRebate[msg.sender] = percentRebate;
        }
    }

    /**
     * Get the rebate on transfer.
     * @param addr Wallet address
     */
    function getPercentRebateByEnterprise(
        address addr
    ) public view virtual returns (uint16) {
        require(isEnterprises[addr], "Address is not an enterprise");
        if (
            _isWithCustomRebate[addr] &&
            _percentEnterpriseRebate[addr] >= _minimumRebate
        ) {
            return _percentEnterpriseRebate[addr]; // returns custom tax when it is not equal to default value
        } else {
            return _minimumRebate; // returns defa ult tax value when it is not equal to zero and default value
        }
    }

    /**
     * Check if address has tax on transfer.
     * @param addr The value to compute
     * @return Rebate Status; if true, address is rewarded on token transfer.
     */
    function isEnterpriseWithRebate(
        address addr
    ) public view virtual returns (bool) {
        return getPercentRebateByEnterprise(addr) == 0 ? false : true;
    }

    /**
     * Get the rebate earned of addr.
     * @param addr Wallet address
     */
    function getTotalRebatesEarned(
        address addr
    ) external view virtual returns (uint256) {
        return userRebatesEarned[addr]; // returns user rebates
    }

    /**
     * Get the rebate issued of `addr`.
     * @param addr Wallet address
     */
    function getTotalRebatesIssued(
        address addr
    ) external view virtual returns (uint256) {
        return rebatesIssued[addr]; // returns user rebates
    }

    // Enable / disable custom AMMs
    function setWhiteListAMM(
        address ammAddress,
        bool isWhiteListed
    ) external onlyOwner {
        require(
            isContract(ammAddress),
            "ALTSWITCH: setWhiteListAMM:: AMM is a wallet, not a contract"
        );
        dividendTracker.setWhiteListAMM(ammAddress, isWhiteListed);
    }

    // Change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(
            newAmount < totalSupply(),
            "Swap amount cannot be higher than total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    // Remove transfer delay after launch
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    // Update dividend tracker
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(
            newAddress != address(dividendTracker),
            "ALTSWITCH: The dividend tracker already has that address"
        );

        AltSwitchDividendTracker newDividendTracker = AltSwitchDividendTracker(
            payable(newAddress)
        );

        require(
            newDividendTracker.owner() == address(this),
            "ALTSWITCH: The new dividend tracker must be owned by the ALTSWITCH token contract"
        );

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    // Updates the minimum amount of tokens people must hold in order to get dividends
    function updateDividendTokensMinimum(
        uint256 minimumToEarnDivs
    ) external onlyOwner {
        dividendTracker.updateDividendMinimum(minimumToEarnDivs);
    }

    // Updates the default router for selling tokens
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "ALTSWITCH: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    // Updates the default router for buying tokens from dividend tracker
    function updateDividendUniswapV2Router(
        address newAddress
    ) external onlyOwner {
        dividendTracker.updateDividendUniswapV2Router(newAddress);
    }

    // Excludes wallets from max txn and fees.
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // Allows multiple exclusions at once
    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    // Excludes wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    // Removes exclusion on wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function includeInDividends(address account) external onlyOwner {
        dividendTracker.includeInDividends(account);
    }

    // Allow adding additional AMM pairs to the list
    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) external onlyOwner {
        require(
            pair != uniswapV2Pair,
            "ALTSWITCH: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    // For one-time airdrop feature after contract launch
    function airdropToWallets(
        address[] memory airdropWallets,
        uint256[] memory amount
    ) external onlyOwner {
        require(
            airdropWallets.length == amount.length,
            "ALTSWITCH: airdropToWallets:: Arrays must be the same length"
        );
        for (uint256 i = 0; i < airdropWallets.length; i++) {
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i];
            if (!isContract(wallet)) {
                // prevent double sending and don't airdrop contracts, only wallets.
                _transfer(msg.sender, wallet, airdropAmount);
            }
        }
    }

    // Sets the wallet that receives LP tokens to lock
    function updateLiquidityWallet(
        address newLiquidityWallet
    ) external onlyOwner {
        require(
            newLiquidityWallet != liquidityWallet,
            "ALTSWITCH: The liquidity wallet is already this address"
        );
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    // Updates the operations wallet (marketing, charity, etc.)
    function updateOperationsWallet(
        address newOperationsWallet
    ) external onlyOwner {
        require(
            newOperationsWallet != operationsWallet,
            "ALTSWITCH: The operations wallet is already this address"
        );
        excludeFromFees(newOperationsWallet, true);
        emit OperationsWalletUpdated(newOperationsWallet, operationsWallet);
        operationsWallet = newOperationsWallet;
    }

    // Rebalance fees as needed
    function updateFees(
        uint256 bnbRewardPerc,
        uint256 liquidityPerc,
        uint256 operationsPerc
    ) external onlyOwner {
        require(
            operationsPerc <= liquidityPerc,
            "ALTSWITCH: updateFees:: Liquidity Perc must be equal to or higher than operations and buyback combined."
        );
        require(bnbRewardPerc + liquidityPerc <= 10, "Max Fee is 10%");

        BNBRewardsFee = bnbRewardPerc;
        liquidityFee = liquidityPerc;
        operationsFee = operationsPerc;
        totalFees = BNBRewardsFee.add(liquidityFee);
        emit FeesUpdated(bnbRewardPerc, liquidityPerc, operationsPerc);
    }

    // Changes the gas reserve for processing dividend distribution
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "ALTSWITCH: gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "ALTSWITCH: Cannot update gasForProcessing to same value"
        );
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    // Changes the amount of time to wait for claims (1-24 hours, expressed in seconds)
    function updateClaimWait(
        uint256 claimWait
    ) external onlyOwner returns (bool) {
        dividendTracker.updateClaimWait(claimWait);
        return true;
    }

    function excludeRewardToken(
        address tokenAddress,
        bool isExcluded
    ) external onlyOwner returns (bool) {
        dividendTracker.excludeRewardToken(tokenAddress, isExcluded);
        return true;
    }

    // Determines if an AMM can be used for rewards
    function isAMMWhitelisted(address ammAddress) public view returns (bool) {
        return dividendTracker.ammIsWhiteListed(ammAddress);
    }

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function getUserCurrentRewardToken(
        address holder
    ) public view returns (address) {
        return dividendTracker.userCurrentRewardToken(holder);
    }

    function getUserHasCustomRewardToken(
        address holder
    ) public view returns (bool) {
        return dividendTracker.userHasCustomRewardToken(holder);
    }

    function getRewardTokenSelectionCount(
        address token
    ) public view returns (uint256) {
        return dividendTracker.rewardTokenSelectionCount(token);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getDividendTokensMinimum() external view returns (uint256) {
        return dividendTracker.minimumTokenBalanceForDividends();
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(
        address account
    )
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(
        uint256 index
    )
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function getRawBNBDividends(address holder) public view returns (uint256) {
        return dividendTracker.getRawBNBDividends(holder);
    }

    function getBNBAvailableForHolderBuyBack(
        address holder
    ) public view returns (uint256) {
        return
            getRawBNBDividends(holder).sub(
                holderBNBUsedForBuyBacks[msg.sender]
            );
    }

    function isExcludedRewardToken(
        address tokenAddress
    ) public view returns (bool) {
        return dividendTracker.isExcludedRewardToken(tokenAddress);
    }

    // Set the reward token for the user
    function setRewardToken(address rewardTokenAddress) public returns (bool) {
        require(
            isContract(rewardTokenAddress),
            "ALTSWITCH: setRewardToken:: Address is a wallet, not a contract."
        );
        require(
            rewardTokenAddress != address(this),
            "ALTSWITCH: setRewardToken:: Cannot set reward token as this token due to Router limitations."
        );
        require(
            !isExcludedRewardToken(rewardTokenAddress),
            "ALTSWITCH: setRewardToken:: Reward Token is blacklisted from being used as rewards."
        );
        dividendTracker.setRewardToken(
            msg.sender,
            rewardTokenAddress,
            address(uniswapV2Router)
        );
        return true;
    }

    // Set the reward token for the user with a custom AMM (AMM must be whitelisted)
    function setRewardTokenWithCustomAMM(
        address rewardTokenAddress,
        address ammContractAddress
    ) public returns (bool) {
        require(
            isContract(rewardTokenAddress),
            "ALTSWITCH: setRewardToken:: Address is a wallet, not a contract."
        );
        require(
            ammContractAddress != address(uniswapV2Router),
            "ALTSWITCH: setRewardToken:: Use setRewardToken to use default Router"
        );
        require(
            rewardTokenAddress != address(this),
            "ALTSWITCH: setRewardToken:: Cannot set reward token as this token due to Router limitations."
        );
        require(
            !isExcludedRewardToken(rewardTokenAddress),
            "ALTSWITCH: setRewardToken:: Reward Token is blacklisted from being used as rewards."
        );
        require(
            isAMMWhitelisted(ammContractAddress) == true,
            "ALTSWITCH: setRewardToken:: AMM is not whitelisted!"
        );
        dividendTracker.setRewardToken(
            msg.sender,
            rewardTokenAddress,
            ammContractAddress
        );
        return true;
    }

    // Unset the reward token back to BNB
    function unsetRewardToken() public returns (bool) {
        dividendTracker.unsetRewardToken(msg.sender);
        return true;
    }

    // Holders can buyback with no fees up to their claimed raw BNB amount
    function buyBackTokensWithNoFees() external payable returns (bool) {
        uint256 userRawBNBDividends = getRawBNBDividends(msg.sender);
        require(
            userRawBNBDividends >=
                holderBNBUsedForBuyBacks[msg.sender].add(msg.value),
            "ALTSWITCH: buyBackTokensWithNoFees:: Cannot Spend more than earned."
        );

        uint256 ethAmount = msg.value;

        // Generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // Update amount to prevent user from buying with more BNB than they've received as raw rewards (also update before transfer to prevent reentrancy)
        holderBNBUsedForBuyBacks[msg.sender] = holderBNBUsedForBuyBacks[
            msg.sender
        ].add(msg.value);

        bool prevExclusion = _isExcludedFromFees[msg.sender]; // ensure we don't remove exclusions if the current wallet is already excluded

        // Make the swap to the contract first to bypass fees
        _isExcludedFromFees[msg.sender] = true;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }( // try to swap for tokens, if it fails (bad contract, or whatever other reason, send BNB)
            0, // accept any amount of Tokens
            path,
            address(msg.sender),
            block.timestamp + 360
        );

        _isExcludedFromFees[msg.sender] = prevExclusion; // set value to match original value

        emit BuyBackWithNoFees(msg.sender, ethAmount);

        return true;
    }

    // Allows a user to manually claim their tokens
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    // Allow a user to manually process dividends
    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    // @dev Token functions
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "ALTSWITCH: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // Activate trading on the contract and enable swapAndLiquify for tax redemption against LP
    function activateContract() external onlyOwner {
        tradingIsEnabled = true;
    }

    function disableTaxOnBuy(bool state) external onlyOwner {
        noTaxOnBuy = state;
    }

    // @note Transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Require a valid address for transfers
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // @note tradingIsEnabled
        if (!tradingIsEnabled) {
            require(
                canTransferBeforeTradingIsEnabled[from],
                "_transfer:: cannot send until trading is enabled"
            );
        }

        // Early exit with no other logic if transfering 0 (to prevent 0 transfers from triggering other logic)
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // @note Transfer delay enabled
        // Prevent buying more than 1 txn per block at launch, bot killer
        if (transferDelayEnabled) {
            if (
                to != owner() &&
                to != address(uniswapV2Router) &&
                to != address(uniswapV2Pair) &&
                !_isExcludedFromFees[to] &&
                !_isExcludedFromFees[from]
            ) {
                require(
                    _holderLastTransferTimestamp[to] < block.timestamp,
                    "_transfer:: Transfer Delay enabled.  Please try again later."
                );
                _holderLastTransferTimestamp[to] = block.timestamp;
            }
        }

        // AntiDump Mechanism
        // Holder sell factor penalty
        if (
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to] &&
            automatedMarketMakerPairs[to]
        ) {
            bool newCycle = block.timestamp -
                userSellPerCycle[from].firstSellTime >=
                24 hours;
            if (!newCycle) {
                userSellPerCycle[from].currentSellFee += sellFeeIncreaseFactor;
            } else {
                userSellPerCycle[from].currentSellFee = 0;
                userSellPerCycle[from].firstSellTime = block.timestamp;
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            tradingIsEnabled && // @note tradingIsEnabled
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet &&
            from != operationsWallet &&
            to != operationsWallet &&
            !_isExcludedFromFees[to] &&
            !_isExcludedFromFees[from] &&
            from != address(this) &&
            from != address(dividendTracker)
        ) {
            swapping = true;

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(
                totalFees
            );
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }

        // @note tradingIsEnabled & takeFee
        bool takeFee = tradingIsEnabled && !swapping;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (
            _isExcludedFromFees[from] ||
            _isExcludedFromFees[to] ||
            from == address(this)
        ) {
            takeFee = false;
        }

        // @note Remove fees for buys (only enabled on sells)
        if (automatedMarketMakerPairs[from] && noTaxOnBuy) {
            takeFee = false;
        }

        // Wallet to wallet transfer, disable fees
        if (
            !automatedMarketMakerPairs[from] &&
            !automatedMarketMakerPairs[to] &&
            !isContract(from) &&
            !isContract(to)
        ) {
            takeFee = false;
            // @note Enterprise Rebates for wallet to wallet transfer

            if (isEnterprises[to]) {
                uint256 rebate = amount
                    .mul(getPercentRebateByEnterprise(to))
                    .div(10000);

                // Records rebates earned by `from`
                userRebatesEarned[from] = userRebatesEarned[from] + rebate;

                // Records rebates issued by `to`
                rebatesIssued[to] = rebatesIssued[to] + rebate;

                // Substract the rebate to current `amount` and become rebates of `from` address
                amount = amount.sub(rebate); // @note new amount to send this amount to recipient(enterprise)
            }
        }

        if (takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);

            if (automatedMarketMakerPairs[to]) {
                fees += (amount.mul(userSellPerCycle[from].currentSellFee)).div(
                    100
                );
            }

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try
            dividendTracker.setBalance(payable(from), balanceOf(from))
        {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    // Split the contract balance into proper pieces
    // figure out how many tokens should be sold for liquidity vs operations / buybacks
    function swapAndLiquify(uint256 tokens) private {
        if (liquidityFee > 0) {
            uint256 tokensForLiquidity;

            if (liquidityFee > 0) {
                tokensForLiquidity = tokens
                    .mul(liquidityFee.sub(operationsFee))
                    .div(liquidityFee);
            } else {
                tokensForLiquidity = 0;
            }

            uint256 tokensForBuyBackAndOperations = tokens.sub(
                tokensForLiquidity
            );

            uint256 half = tokensForLiquidity.div(2);
            uint256 otherHalf = tokensForLiquidity.sub(half);

            // Capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // Swap tokens for ETH
            swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

            // How much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);

            // Add liquidity to uniswap
            addLiquidity(otherHalf, newBalance);

            swapTokensForEth(tokensForBuyBackAndOperations);

            uint256 balanceForOperationsAndBuyBack = address(this).balance.sub(
                initialBalance
            );

            bool success;

            if (operationsFee > 0) {
                // Send to Operations Wallet
                uint256 operationsBalance = balanceForOperationsAndBuyBack;
                (success, ) = payable(operationsWallet).call{
                    value: operationsBalance
                }("");
                require(
                    success,
                    "ALTSWITCH: SwapAndLiquify:: Unable to send BNB to Operations Wallet"
                );
            }

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success, ) = address(dividendTracker).call{value: dividends}("");

        if (success) {
            emit SendDividends(tokens, dividends);
        }
    }

    function recoverContractBNB() external onlyOwner {
        payable(operationsWallet).transfer(address(this).balance);
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(
        Map storage map,
        address key
    ) public view returns (int256) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(
        Map storage map,
        uint256 index
    ) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint256 val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract AltSwitchDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor()
        DividendPayingToken(
            "AltSwitch_Dividend_Tracker",
            "AltSwitch_Dividend_Tracker",
            9
        )
    {
        claimWait = 3600;

        minimumTokenBalanceForDividends = 10000 * (10 ** 9); // @note Equals 1e+13 | Must hold a minimum of 10K+ for dividends
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "AltSwitch_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(
            false,
            "AltSwitch_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main ALTSWITCH contract."
        );
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function includeInDividends(address account) external onlyOwner {
        require(excludedFromDividends[account]);
        excludedFromDividends[account] = false;

        emit IncludeInDividends(account);
    }

    function updateDividendMinimum(
        uint256 minimumToEarnDivs
    ) external onlyOwner {
        minimumTokenBalanceForDividends = minimumToEarnDivs;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "AltSwitch_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "AltSwitch_Dividend_Tracker: Cannot update claimWait to same value"
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(
        address _account
    )
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed = index.add(
                    int256(processesUntilEndOfArray)
                );
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);

        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function getAccountAtIndex(
        uint256 index
    )
        public
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                -1,
                0,
                0,
                0,
                0,
                0
            );
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(
        address payable account,
        uint256 newBalance
    ) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(
        address payable account,
        bool automatic
    ) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}