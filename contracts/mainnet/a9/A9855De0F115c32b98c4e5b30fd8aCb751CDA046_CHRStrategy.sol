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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
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

pragma solidity ^0.8.0;

interface IEarningsReferral {
    function recordReferral(address _user, address _referrer) external;

    function recordReferralCommission(
        address _referrer,
        uint256 _commission
    ) external;

    function getReferrer(address _user) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PolyMaster} from "./PolyMaster.sol";
import {IMaGauge} from "./interfaces/IMaGauge.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CHRStrategy is Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;

    PolyMaster public polyMaster;
    // max uint256
    uint256 internal constant MAX_UINT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    // scaled up by ACC_EARNING_PRECISION
    uint256 internal constant ACC_EARNING_PRECISION = 1e18;
    // max performance fee
    uint256 internal constant MAX_BIPS = 10000;
    // performance fee
    uint256 public performanceFeeBips = 10000;

    //CHR
    IERC20 public constant rewardToken =
        IERC20(0x15b2fb8f08E4Ac1Ce019EADAe02eE92AeDF06851);

    bool public isInitialized = false;

    address private admin;

    struct StrategyInfo {
        IMaGauge stakingContract;
        IERC20 depositToken;
        uint nftId;
    }
    // pidMonopoly => StrategyInfo
    mapping(uint256 => StrategyInfo) public strategyInfo;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function initialize(PolyMaster _polyMaster) external onlyAdmin {
        require(!isInitialized, "already initialized");

        polyMaster = _polyMaster;
        transferOwnership(address(_polyMaster));

        isInitialized = true;
    }

    function updateStrategy(
        uint256 _pidMonopoly,
        IMaGauge _stakingContract,
        IERC20 _depositToken
    ) external onlyAdmin {
        require(
            address(_stakingContract) != address(0),
            "invalid staking contract"
        );
        require(address(_depositToken) != address(0), "invalid deposit token");

        strategyInfo[_pidMonopoly] = StrategyInfo({
            stakingContract: _stakingContract,
            depositToken: _depositToken,
            nftId: 0
        });
        _depositToken.safeApprove(address(_stakingContract), 0);
        _depositToken.safeApprove(address(_stakingContract), MAX_UINT);
    }

    //
    function restake(
        uint256 _pidMonopoly,
        uint256[] memory nftIds
    ) external onlyAdmin {
        StrategyInfo storage info = strategyInfo[_pidMonopoly];

        for (uint256 i = 0; i < nftIds.length; i++) {
            info.stakingContract.withdrawAndHarvest(nftIds[i]);
        }
        info.nftId = info.stakingContract.depositAll();
    }

    function setPerformanceFeeBips(
        uint256 newPerformanceFeeBips
    ) external virtual onlyAdmin {
        require(newPerformanceFeeBips <= MAX_BIPS, "input too high");
        performanceFeeBips = newPerformanceFeeBips;
    }

    //PUBLIC FUNCTIONS
    /**
     * @notice Reward token balance that can be claimed
     * @dev Staking rewards accrue to contract on each deposit/withdrawal
     * @return Unclaimed rewards
     */
    function checkReward() public view returns (uint256) {
        return 0;
    }

    function checkReward(uint256 pidMonopoly) public view returns (uint256) {
        StrategyInfo memory info = strategyInfo[pidMonopoly];

        uint256 reward = info.stakingContract.earned(address(this));
        return reward;
    }

    function pendingRewards(address user) public view returns (uint256) {
        uint256 unclaimedRewards = checkReward();
        return unclaimedRewards;
    }

    function pendingRewards(uint256 pidMonopoly) public view returns (uint256) {
        StrategyInfo memory info = strategyInfo[pidMonopoly];

        uint256 unclaimedRewards = checkReward(pidMonopoly);
        return unclaimedRewards;
    }

    function pendingTokens(
        uint256 pidMonopoly,
        address user,
        uint256
    ) external view returns (address[] memory, uint256[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(rewardToken);
        uint256[] memory _pendingAmounts = new uint256[](1);
        _pendingAmounts[0] = pendingRewards(pidMonopoly);
        return (_rewardTokens, _pendingAmounts);
    }

    function rewardTokens() external view virtual returns (address[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(rewardToken);
        return (_rewardTokens);
    }

    //EXTERNAL FUNCTIONS
    function harvest(uint256 pidMonopoly) external {
        _claimRewards(pidMonopoly);
        _harvest(msg.sender, msg.sender);
    }

    //OWNER-ONlY FUNCTIONS
    function deposit(
        address caller,
        address to,
        uint256 tokenAmount,
        uint256,
        uint256 pidMonopoly
    ) external onlyOwner {
        StrategyInfo storage info = strategyInfo[pidMonopoly];

        if (tokenAmount > 0) {
            if (info.nftId != 0) {
                info.stakingContract.withdrawAndHarvest(info.nftId);
            }
            info.nftId = info.stakingContract.depositAll();
        }

        _harvest(caller, to);
    }

    function withdraw(
        address caller,
        address to,
        uint256 tokenAmount,
        uint256,
        uint256 withdrawalFeeBP,
        uint256 pidMonopoly
    ) external onlyOwner {
        StrategyInfo storage info = strategyInfo[pidMonopoly];
        IMaGauge stakingContract = info.stakingContract;

        if (tokenAmount > 0) {
            stakingContract.withdrawAndHarvest(info.nftId);
            if (withdrawalFeeBP > 0) {
                uint256 withdrawalFee = (tokenAmount * withdrawalFeeBP) / 10000;
                info.depositToken.safeTransfer(
                    polyMaster.actionFeeAddress(),
                    withdrawalFee
                );
                tokenAmount -= withdrawalFee;
            }
            info.depositToken.safeTransfer(to, tokenAmount);
            if (info.depositToken.balanceOf(address(this)) > 0) {
                info.nftId = stakingContract.depositAll();
            } else {
                info.nftId = 0;
            }
        }

        _harvest(caller, to);
    }

    function emergencyWithdraw(
        address,
        address to,
        uint256 tokenAmount,
        uint256 shareAmount,
        uint256 withdrawalFeeBP,
        uint256 pidMonopoly
    ) external onlyOwner {
        StrategyInfo storage info = strategyInfo[pidMonopoly];
        IMaGauge stakingContract = info.stakingContract;

        if (tokenAmount > 0) {
            stakingContract.withdrawAndHarvest(info.nftId);
            if (withdrawalFeeBP > 0) {
                uint256 withdrawalFee = (tokenAmount * withdrawalFeeBP) / 10000;
                info.depositToken.safeTransfer(
                    polyMaster.actionFeeAddress(),
                    withdrawalFee
                );
                tokenAmount -= withdrawalFee;
            }
            info.depositToken.safeTransfer(to, tokenAmount);
            if (info.depositToken.balanceOf(address(this)) > 0) {
                info.nftId = stakingContract.depositAll();
            } else {
                info.nftId = 0;
            }
        }

        _harvest(msg.sender, to);
    }

    function setAllowances(uint256 pidMonopoly) external onlyOwner {
        StrategyInfo memory info = strategyInfo[pidMonopoly];

        info.depositToken.safeApprove(address(info.stakingContract), 0);
        info.depositToken.safeApprove(address(info.stakingContract), MAX_UINT);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards(uint256 pidMonopoly) internal {
        StrategyInfo storage info = strategyInfo[pidMonopoly];

        info.stakingContract.getAllReward();
    }

    function _harvest(address, address) internal {
        uint256 rewardAmount = rewardToken.balanceOf(address(this));
        _safeRewardTokenTransfer(
            polyMaster.performanceFeeAddress(),
            rewardAmount
        );
    }

    //internal wrapper function to avoid reverts due to rounding
    function _safeRewardTokenTransfer(address user, uint256 amount) internal {
        uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
        if (amount > rewardTokenBal) {
            rewardToken.safeTransfer(user, rewardTokenBal);
        } else {
            rewardToken.safeTransfer(user, amount);
        }
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        _operator;
        _from;
        _tokenId;
        _data;
        return 0x150b7a02;
    }

    function inCaseTokensGetStuck(
        IERC20 token,
        address to,
        uint256 amount,
        uint256 pidMonopoly
    ) external virtual onlyOwner {
        require(amount > 0, "cannot recover 0 tokens");
        require(
            address(token) != address(strategyInfo[pidMonopoly].depositToken),
            "cannot recover deposit token"
        );
        token.safeTransfer(to, amount);
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMaGauge {
    function depositAll() external returns (uint _tokenId);

    function deposit(uint256 amount) external returns (uint _tokenId);

    function withdrawAndHarvest(uint _tokenId) external;

    function withdrawAndHarvestAll() external;

    function getAllReward() external;

    function getReward(uint _tokenId) external;

    // returns balanceOf nft
    function balanceOf(address account) external view returns (uint256);

    function balanceOfToken(uint _tokenId) external view returns (uint256);

    function earned(uint _tokenId) external view returns (uint256);

    function earned(address account) external view returns (uint256);
}

interface ImaNFT {
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPolyStrategy {
    // Deposit amount of tokens for 'caller' to address 'to'
    function deposit(
        address caller,
        address to,
        uint256 tokenAmount,
        uint256 shareAmount,
        uint256 pidMonopoly
    ) external;

    // Transfer tokens from strategy for 'caller' to address 'to'
    function withdraw(
        address caller,
        address to,
        uint256 tokenAmount,
        uint256 shareAmount,
        uint256 withdrawalFeeBP,
        uint256 pidMonopoly
    ) external;

    function inCaseTokensGetStuck(
        IERC20 token,
        address to,
        uint256 amount,
        uint256 pidMonopoly
    ) external;

    function setAllowances(uint256 pid) external;

    function revokeAllowance(
        address token,
        address spender,
        uint256 pid
    ) external;

    function migrate(address newStrategy, uint256 pid) external;

    function onMigration(uint256 pid) external;

    function pendingTokens(
        uint256 pid,
        address user,
        uint256 amount
    ) external view returns (address[] memory, uint256[] memory);

    function transferOwnership(address newOwner) external;

    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external;

    function emergencyWithdraw(
        address caller,
        address to,
        uint256 tokenAmount,
        uint256 shareAmount,
        uint256 withdrawalFeeBP,
        uint256 pidMonopoly
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IPolyStrategy} from "./interfaces/IPolyStrategy.sol";
import {IEarningsReferral} from "../interfaces/IEarningsReferral.sol";
import {PolyToken} from "./PolyToken.sol";
import {sPoly} from "./sPoly.sol";

contract PolyMaster is Ownable {
    using SafeERC20 for IERC20;

    bool public isInitialized;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many shares the user currently has
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastDepositTimestamp; // Timestamp of the last deposit.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 want; // Address of LP token contract.
        IPolyStrategy strategy; // Address of strategy for pool
        uint256 allocPoint; // How many allocation points assigned to this pool. earnings to distribute per block.
        uint256 lastRewardTime; // Last block number that earnings distribution occurs.
        uint256 accEarningPerShare; // Accumulated earnings per share, times ACC_EARNING_PRECISION. See below.
        uint256 totalShares; //total number of shares in the pool
        uint256 lpPerShare; //number of LP tokens per share, times ACC_EARNING_PRECISION
        uint16 depositFeeBP; // Deposit fee in basis points
        uint16 withdrawFeeBP; // Withdraw fee in basis points
        bool isWithdrawFee; // if the pool has withdraw fee
    }

    // The main reward token!
    PolyToken public earningToken;
    // The block when mining starts.
    uint256 public startTime;
    // The block when mining ends.
    uint256 public endTime;
    //development endowment

    address public dev;
    //performance fee address -- receives performance fees from strategies
    address public performanceFeeAddress;
    //actionFee fee address -- receives actionFee fees, deposit,withdraw
    address public actionFeeAddress;
    // amount of reward emitted per second
    uint256 public earningsPerSecond;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    //allocations to dev and nest addresses, expressed in BIPS
    uint256 public devMintBips = 1000;
    //whether the onlyApprovedContractOrEOA is turned on or off
    bool public onlyApprovedContractOrEOAStatus;

    uint256 internal constant ACC_EARNING_PRECISION = 1e18;
    uint256 internal constant MAX_BIPS = 10000;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    //mappping for tracking contracts approved to build on top of this one
    mapping(address => bool) public approvedContracts;
    uint16 public constant MAX_DEPOSIT_FEE_BP = 400;
    uint16 public constant MAX_WITHDRAW_FEE_BP = 400;
    uint256 public MAX_LINEAR_DURATION = 3 days;

    // Earnings referral contract address.
    IEarningsReferral public earningReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 300;
    // Max referral commission rate: 20%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 2000;

    sPoly public sPolyToken;
    uint256 public stakedRewardRatio = 7000;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event DevSet(address indexed oldAddress, address indexed newAddress);
    event PerformanceFeeAddressSet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );

    /**
     * @notice Throws if called by smart contract
     */
    modifier onlyApprovedContractOrEOA() {
        if (onlyApprovedContractOrEOAStatus) {
            require(
                tx.origin == msg.sender || approvedContracts[msg.sender],
                "MonoMaster::onlyApprovedContractOrEOA"
            );
        }
        _;
    }

    function initialize(
        PolyToken _earningToken,
        uint256 _startTime,
        uint256 _endTime,
        address _dev,
        address _performanceFeeAddress,
        address _actionFeeAddress,
        uint256 _earningsPerSecond,
        sPoly _sPolyToken
    ) external onlyOwner {
        require(!isInitialized, "already initialized");
        require(_startTime > block.timestamp, "must start in future");
        require(_dev != address(0), "dev address cannot be 0");
        require(
            _performanceFeeAddress != address(0),
            "performanceFee address cannot be 0"
        );
        require(
            _actionFeeAddress != address(0),
            "actionFee address cannot be 0"
        );

        isInitialized = true;
        earningToken = _earningToken;
        startTime = _startTime;
        endTime = _endTime;
        dev = _dev;
        performanceFeeAddress = _performanceFeeAddress;
        actionFeeAddress = _actionFeeAddress;
        earningsPerSecond = _earningsPerSecond;
        sPolyToken = _sPolyToken;

        earningToken.approve(address(sPolyToken), type(uint256).max);

        emit DevSet(address(0), _dev);
        emit PerformanceFeeAddressSet(address(0), _performanceFeeAddress);
    }

    //VIEW FUNCTIONS
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see total pending reward in = on frontend.
    function pendingEarnings(
        uint256 pid,
        address userAddr
    ) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][userAddr];
        uint256 accEarningPerShare = pool.accEarningPerShare;
        uint256 poolShares = pool.totalShares;
        if (block.timestamp > pool.lastRewardTime && poolShares != 0) {
            uint256 earningsReward = (reward(
                pool.lastRewardTime,
                block.timestamp
            ) * pool.allocPoint) / totalAllocPoint;
            accEarningPerShare =
                accEarningPerShare +
                ((earningsReward * ACC_EARNING_PRECISION) / poolShares);
        }
        return
            ((user.amount * accEarningPerShare) / ACC_EARNING_PRECISION) -
            user.rewardDebt;
    }

    // view function to get all pending rewards, from MonoMaster, Strategy, and Rewarder
    function pendingTokens(
        uint256 pid,
        address user
    ) external view returns (address[] memory, uint256[] memory) {
        uint256 earningAmount = pendingEarnings(pid, user);
        (
            address[] memory strategyTokens,
            uint256[] memory strategyRewards
        ) = poolInfo[pid].strategy.pendingTokens(pid, user, earningAmount);

        uint256 rewardsLength = 1;
        for (uint256 j = 0; j < strategyTokens.length; j++) {
            if (strategyTokens[j] != address(0)) {
                rewardsLength += 1;
            }
        }
        address[] memory _rewardTokens = new address[](rewardsLength);
        uint256[] memory _pendingAmounts = new uint256[](rewardsLength);
        _rewardTokens[0] = address(earningToken);
        _pendingAmounts[0] = earningAmount;
        for (uint256 m = 0; m < strategyTokens.length; m++) {
            if (strategyTokens[m] != address(0)) {
                _rewardTokens[m + 1] = strategyTokens[m];
                _pendingAmounts[m + 1] = strategyRewards[m];
            }
        }
        return (_rewardTokens, _pendingAmounts);
    }

    // Return reward over the period _from to _to.
    function reward(
        uint256 _lastRewardTime,
        uint256 _currentTime
    ) public view returns (uint256) {
        uint256 multiplier;
        if (_currentTime <= endTime) {
            multiplier = _currentTime - _lastRewardTime;
        } else if (_lastRewardTime >= endTime) {
            return 0;
        } else {
            multiplier = endTime - _lastRewardTime;
        }

        return multiplier * earningsPerSecond;
    }

    //convenience function to get the yearly emission of reward at the current emission rate
    function earningPerYear() public view returns (uint256) {
        //31536000 = seconds per year = 365 * 24 * 60 * 60
        return (earningsPerSecond * 31536000);
    }

    //convenience function to get the yearly emission of reward at the current emission rate, to a given monopoly
    function earningPerYearToMonopoly(
        uint256 pid
    ) public view returns (uint256) {
        return ((earningPerYear() * poolInfo[pid].allocPoint) /
            totalAllocPoint);
    }

    //convenience function to get the total number of shares in an monopoly
    function totalShares(uint256 pid) public view returns (uint256) {
        return poolInfo[pid].totalShares;
    }

    //convenience function to get the total amount of LP tokens in an monopoly
    function totalLP(uint256 pid) public view returns (uint256) {
        return ((poolInfo[pid].lpPerShare * totalShares(pid)) /
            ACC_EARNING_PRECISION);
    }

    //convenience function to get the shares of a single user in an monopoly
    function userShares(
        uint256 pid,
        address user
    ) public view returns (uint256) {
        return userInfo[pid][user].amount;
    }

    //WRITE FUNCTIONS
    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            uint256 poolShares = pool.totalShares;
            if (poolShares == 0 || pool.allocPoint == 0) {
                pool.lastRewardTime = block.timestamp;
                return;
            }
            uint256 earningReward = (reward(
                pool.lastRewardTime,
                block.timestamp
            ) * pool.allocPoint) / totalAllocPoint;
            pool.lastRewardTime = block.timestamp;
            if (earningReward > 0) {
                uint256 toDev = (earningReward * devMintBips) / MAX_BIPS;
                pool.accEarningPerShare =
                    pool.accEarningPerShare +
                    ((earningReward * ACC_EARNING_PRECISION) / poolShares);
                // safeEarningsTransfer(dev, toDev);
                earningToken.transfer(dev, toDev);
                // earningToken.transfer(address(this), earningReward);
            }
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @notice Deposit LP tokens to MonoMaster for reward allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(
        uint256 pid,
        uint256 amount,
        address to,
        address _referrer
    ) external onlyApprovedContractOrEOA {
        uint256 totalAmount = amount;
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];
        if (amount > 0) {
            UserInfo storage user = userInfo[pid][to];

            if (
                address(earningReferral) != address(0) &&
                _referrer != address(0) &&
                _referrer != msg.sender
            ) {
                earningReferral.recordReferral(msg.sender, _referrer);
            }

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = (amount * pool.depositFeeBP) / 10000;
                pool.want.safeTransferFrom(
                    address(msg.sender),
                    actionFeeAddress,
                    depositFee
                );
                amount = amount - depositFee;
            }

            //find number of new shares from amount
            uint256 newShares = (amount * ACC_EARNING_PRECISION) /
                pool.lpPerShare;

            //transfer tokens directly to strategy
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(pool.strategy),
                amount
            );
            //tell strategy to deposit newly transferred tokens and process update
            pool.strategy.deposit(msg.sender, to, amount, newShares, pid);

            //track new shares
            pool.totalShares = pool.totalShares + newShares;
            user.amount = user.amount + newShares;
            user.rewardDebt =
                user.rewardDebt +
                ((newShares * pool.accEarningPerShare) / ACC_EARNING_PRECISION);
            user.lastDepositTimestamp = block.timestamp;

            emit Deposit(msg.sender, pid, totalAmount, to);
        }
    }

    /// @notice Withdraw LP tokens from MonoMaster.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amountShares amount of shares to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(
        uint256 pid,
        uint256 amountShares,
        address to
    ) external onlyApprovedContractOrEOA {
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= amountShares, "withdraw: not good");

        if (amountShares > 0) {
            //find amount of LP tokens from shares
            uint256 lpFromShares = (amountShares * pool.lpPerShare) /
                ACC_EARNING_PRECISION;

            uint256 withdrawFeeBP;
            if (pool.isWithdrawFee) {
                withdrawFeeBP = getWithdrawFee(pid, msg.sender);
            }

            //tell strategy to withdraw lpTokens, send to 'to', and process update
            pool.strategy.withdraw(
                msg.sender,
                to,
                lpFromShares,
                amountShares,
                withdrawFeeBP,
                pid
            );

            //track removed shares
            user.amount = user.amount - amountShares;
            uint256 rewardDebtOfShares = ((amountShares *
                pool.accEarningPerShare) / ACC_EARNING_PRECISION);
            uint256 userRewardDebt = user.rewardDebt;
            user.rewardDebt = (userRewardDebt >= rewardDebtOfShares)
                ? (userRewardDebt - rewardDebtOfShares)
                : 0;
            pool.totalShares = pool.totalShares - amountShares;

            emit Withdraw(msg.sender, pid, amountShares, to);
        }
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of rewards.
    function harvest(
        uint256 pid,
        address to
    ) external onlyApprovedContractOrEOA {
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        //find all time rewards for all of user's shares
        uint256 accumulatedEarnings = (user.amount * pool.accEarningPerShare) /
            ACC_EARNING_PRECISION;
        //subtract out the rewards they have already been entitled to
        uint256 pendings = accumulatedEarnings - user.rewardDebt;
        //update user reward debt
        user.rewardDebt = accumulatedEarnings;

        //send remainder as reward
        if (pendings > 0) {
            safeEarningsTransfer(to, pendings);
            payReferralCommission(msg.sender, pendings);
        }

        emit Harvest(msg.sender, pid, pendings);
    }

    /// @notice Withdraw LP tokens from MonoMaster.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amountShares amount of shares to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdrawAndHarvest(
        uint256 pid,
        uint256 amountShares,
        address to
    ) external onlyApprovedContractOrEOA {
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= amountShares, "withdraw: not good");

        //find all time rewards for all of user's shares
        uint256 accumulatedEarnings = (user.amount * pool.accEarningPerShare) /
            ACC_EARNING_PRECISION;
        //subtract out the rewards they have already been entitled to
        uint256 pendings = accumulatedEarnings - user.rewardDebt;
        //find amount of LP tokens from shares
        uint256 lpToSend = (amountShares * pool.lpPerShare) /
            ACC_EARNING_PRECISION;

        uint256 withdrawFeeBP;
        if (pool.isWithdrawFee) {
            withdrawFeeBP = getWithdrawFee(pid, msg.sender);
        }

        //tell strategy to withdraw lpTokens, send to 'to', and process update
        pool.strategy.withdraw(
            msg.sender,
            to,
            lpToSend,
            amountShares,
            withdrawFeeBP,
            pid
        );

        //track removed shares
        user.amount = user.amount - amountShares;
        uint256 rewardDebtOfShares = ((amountShares * pool.accEarningPerShare) /
            ACC_EARNING_PRECISION);
        user.rewardDebt = accumulatedEarnings - rewardDebtOfShares;
        pool.totalShares = pool.totalShares - amountShares;

        //handle rewards
        if (pendings > 0) {
            safeEarningsTransfer(to, pendings);
            payReferralCommission(msg.sender, pendings);
        }

        emit Withdraw(msg.sender, pid, amountShares, to);
        emit Harvest(msg.sender, pid, pendings);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(
        uint256 pid,
        address to
    ) external onlyApprovedContractOrEOA {
        //skip pool update
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amountShares = user.amount;
        //find amount of LP tokens from shares
        uint256 lpFromShares = (amountShares * pool.lpPerShare) /
            ACC_EARNING_PRECISION;

        uint256 withdrawFeeBP;
        if (pool.isWithdrawFee) {
            withdrawFeeBP = getWithdrawFee(pid, msg.sender);
        }

        //tell strategy to withdraw lpTokens, send to 'to', and process update
        pool.strategy.emergencyWithdraw(
            msg.sender,
            to,
            lpFromShares,
            amountShares,
            withdrawFeeBP,
            pid
        );

        //track removed shares
        user.amount = 0;
        user.rewardDebt = 0;
        pool.totalShares = pool.totalShares - amountShares;

        emit EmergencyWithdraw(msg.sender, pid, amountShares, to);
    }

    //OWNER-ONLY FUNCTIONS
    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// @param _allocPoint AP of the new pool.
    /// @param _want Address of the LP ERC-20 token.
    /// @param _withUpdate True if massUpdatePools should be called prior to pool updates.
    function add(
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint16 _withdrawFeeBP,
        IERC20 _want,
        bool _withUpdate,
        bool _isWithdrawFee,
        IPolyStrategy _strategy
    ) external onlyOwner {
        require(
            _depositFeeBP <= MAX_DEPOSIT_FEE_BP,
            "add: invalid deposit fee basis points"
        );
        require(
            _withdrawFeeBP <= MAX_WITHDRAW_FEE_BP,
            "add: invalid withdraw fee basis points"
        );

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime
            ? block.timestamp
            : startTime;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                want: _want,
                strategy: _strategy,
                allocPoint: _allocPoint,
                lastRewardTime: lastRewardTime,
                accEarningPerShare: 0,
                depositFeeBP: _depositFeeBP,
                withdrawFeeBP: _withdrawFeeBP,
                isWithdrawFee: _isWithdrawFee,
                totalShares: 0,
                lpPerShare: ACC_EARNING_PRECISION
            })
        );
    }

    /// @notice Update the given pool's reward allocation point, withdrawal fee, and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _withUpdate True if massUpdatePools should be called prior to pool updates.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint16 _withdrawFeeBP,
        bool _withUpdate,
        bool _isWithdrawFee
    ) external onlyOwner {
        require(
            _depositFeeBP <= MAX_DEPOSIT_FEE_BP,
            "add: invalid deposit fee basis points"
        );
        require(
            _withdrawFeeBP <= MAX_WITHDRAW_FEE_BP,
            "add: invalid withdraw fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            (totalAllocPoint - poolInfo[_pid].allocPoint) +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].withdrawFeeBP = _withdrawFeeBP;
        poolInfo[_pid].isWithdrawFee = _isWithdrawFee;
    }

    function setDev(address _dev) external onlyOwner {
        require(_dev != address(0));
        emit DevSet(dev, _dev);
        dev = _dev;
    }

    function setPerfomanceFeeAddress(
        address _performanceFeeAddress
    ) external onlyOwner {
        require(_performanceFeeAddress != address(0));
        emit PerformanceFeeAddressSet(
            performanceFeeAddress,
            _performanceFeeAddress
        );
        performanceFeeAddress = _performanceFeeAddress;
    }

    function setActionFeeAddress(address _actionFeeAddress) external onlyOwner {
        require(_actionFeeAddress != address(0));

        actionFeeAddress = _actionFeeAddress;
    }

    function setDevMintBips(uint256 _devMintBips) external onlyOwner {
        require(
            _devMintBips <= MAX_BIPS,
            "combined dev & nest splits too high"
        );
        devMintBips = _devMintBips;
    }

    function setEarningsEmission(
        uint256 newEarningsPerSecond,
        bool withUpdate
    ) external onlyOwner {
        if (withUpdate) {
            massUpdatePools();
        }
        earningsPerSecond = newEarningsPerSecond;
    }

    //ACCESS CONTROL FUNCTIONS
    function modifyApprovedContracts(
        address[] calldata contracts,
        bool[] calldata statuses
    ) external onlyOwner {
        require(contracts.length == statuses.length, "input length mismatch");
        for (uint256 i = 0; i < contracts.length; i++) {
            approvedContracts[contracts[i]] = statuses[i];
        }
    }

    function setOnlyApprovedContractOrEOAStatus(
        bool newStatus
    ) external onlyOwner {
        onlyApprovedContractOrEOAStatus = newStatus;
    }

    //STRATEGY MANAGEMENT FUNCTIONS
    function inCaseTokensGetStuck(
        uint256 pid,
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IPolyStrategy strat = poolInfo[pid].strategy;
        strat.inCaseTokensGetStuck(token, to, amount, pid);
    }

    function inCaseTokenGetStuck(
        IERC20 token,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }

    function setAllowances(uint256 pid) external onlyOwner {
        IPolyStrategy strat = poolInfo[pid].strategy;
        strat.setAllowances(pid);
    }

    function revokeAllowance(
        uint256 pid,
        address token,
        address spender
    ) external onlyOwner {
        IPolyStrategy strat = poolInfo[pid].strategy;
        strat.revokeAllowance(token, spender, pid);
    }

    function setPerformanceFeeBips(
        uint256 pid,
        uint256 newPerformanceFeeBips
    ) external onlyOwner {
        IPolyStrategy strat = poolInfo[pid].strategy;
        strat.setPerformanceFeeBips(newPerformanceFeeBips);
    }

    //INTERNAL FUNCTIONS
    // Safe reward transfer function, just in case if rounding error causes pool to not have enough earnings.
    function safeEarningsTransfer(address _to, uint256 _amount) internal {
        uint256 earningsBal = earningToken.balanceOf(address(this));
        bool transferSuccess = false;
        uint256 amountToStake = (_amount * stakedRewardRatio) / 10000;
        uint256 amountToTransfer = _amount - amountToStake;

        sPolyToken.stake(amountToStake, _to);

        if (amountToTransfer > earningsBal) {
            transferSuccess = earningToken.transfer(_to, earningsBal);
        } else {
            transferSuccess = earningToken.transfer(_to, amountToTransfer);
        }

        require(transferSuccess, "safeEarningsTransfer: transfer failed");
    }

    // 선형으로 변경
    function getWithdrawFee(
        uint256 _pid,
        address _user
    ) public view returns (uint16) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        if (!pool.isWithdrawFee) return 0;
        uint256 elapsed = block.timestamp - user.lastDepositTimestamp;

        uint16 deductionFee = uint16(
            ((elapsed * 1e18) * pool.withdrawFeeBP) / MAX_LINEAR_DURATION / 1e18
        );
        if (deductionFee > pool.withdrawFeeBP) return 0; // MAX - DEDUCTABLE
        return pool.withdrawFeeBP - deductionFee;
    }

    function setWithdrawalDuration(
        uint256 _maxLenearDuration
    ) public onlyOwner {
        MAX_LINEAR_DURATION = _maxLenearDuration;
    }

    // Update the earning referral contract address by the owner
    function setEarningsReferral(
        IEarningsReferral _earningReferral
    ) public onlyOwner {
        earningReferral = _earningReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(
        uint16 _referralCommissionRate
    ) public onlyOwner {
        require(
            _referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE,
            "setReferralCommissionRate: invalid referral commission rate basis points"
        );
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (
            address(earningReferral) != address(0) && referralCommissionRate > 0
        ) {
            address referrer = earningReferral.getReferrer(_user);
            uint256 commissionAmount = (_pending * referralCommissionRate) /
                10000;

            if (referrer != address(0) && commissionAmount > 0) {
                safeEarningsTransfer(referrer, commissionAmount);
                earningReferral.recordReferralCommission(
                    referrer,
                    commissionAmount
                );
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    function setSPoly(sPoly _sPolyToken) external onlyOwner {
        sPolyToken = _sPolyToken;
    }

    function setStakedRewardRatio(
        uint256 _stakedRewardRatio
    ) external onlyOwner {
        require(_stakedRewardRatio <= 10000, "invalid stakedRewardRatio");
        stakedRewardRatio = _stakedRewardRatio;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract PolyToken is ERC20Permit {
    constructor()
        ERC20("Monopoly Layer-3 Token", "POLY")
        ERC20Permit("Monopoly Layer-3 Token")
    {
        _mint(msg.sender, 7_137_536 * 10 ** decimals());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract sPoly is ERC20, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public polyToken;

    uint256 public vestingPeriod = 5 days;

    uint256 public withdrawalEnabledTime;

    uint256 public instantWithdrawalEnabledTime;

    bool public instantWithdrawalEnabled = false;

    uint256 public instantWithdrawalFeeRate = 5000; // 50%

    address public instantWithdrawalFeeReceiver;

    mapping(address => uint256) public lastClaimedTime;

    mapping(address => uint256) public claimablePerSecond;

    mapping(address => uint256) public timeToFullClaim;

    constructor(address _polyToken) ERC20("sTestToken", "sTest") {
        // constructor(address _polyToken) ERC20("Staked Poly", "sPOLY") {
        polyToken = IERC20(_polyToken);
    }

    function setVestingPeriod(uint256 _vestingPeriod) public onlyOwner {
        vestingPeriod = _vestingPeriod;
    }

    function setWithdrawalEnabledTime(
        uint256 _withdrawalEnabledTime
    ) public onlyOwner {
        withdrawalEnabledTime = _withdrawalEnabledTime;
    }

    function setWithdrawalFeeRate(
        uint256 _instantWithdrawalFeeRate
    ) public onlyOwner {
        instantWithdrawalFeeRate = _instantWithdrawalFeeRate;
    }

    function setWithdrawalFeeReceiver(
        address _instantWithdrawalFeeReceiver
    ) public onlyOwner {
        instantWithdrawalFeeReceiver = _instantWithdrawalFeeReceiver;
    }

    function setInstantWithdrawalEnabledTime(
        uint256 _instantWithdrawalEnabledTime
    ) public onlyOwner {
        instantWithdrawalEnabledTime = _instantWithdrawalEnabledTime;
    }

    function setInstantWithdrawalEnabled(
        bool _instantWithdrawalEnabled
    ) public onlyOwner {
        instantWithdrawalEnabled = _instantWithdrawalEnabled;
    }

    function stake(uint256 amount, address to) public {
        polyToken.safeTransferFrom(address(msg.sender), address(this), amount);

        _mint(to, amount);
    }

    function unstake(uint256 amount) public {
        require(
            block.timestamp > withdrawalEnabledTime,
            "sPoly: withdrawal is not enabled yet"
        );
        _burn(msg.sender, amount);

        claim();

        uint256 totalAmountToVest = amount;
        if (timeToFullClaim[msg.sender] > block.timestamp) {
            totalAmountToVest +=
                claimablePerSecond[msg.sender] *
                (timeToFullClaim[msg.sender] - block.timestamp);
        }

        claimablePerSecond[msg.sender] = totalAmountToVest / vestingPeriod;
        timeToFullClaim[msg.sender] = block.timestamp + vestingPeriod;
    }

    function instantUnstake(uint256 amount) public {
        require(
            block.timestamp > withdrawalEnabledTime,
            "sPoly: withdrawal is not enabled yet"
        );
        require(
            instantWithdrawalEnabled,
            "sPoly: instant withdrawal is not enabled"
        );
        require(
            block.timestamp > instantWithdrawalEnabledTime,
            "sPoly: instant withdrawal is not enabled yet"
        );

        _burn(msg.sender, amount);

        uint256 amountToBurn = (amount * instantWithdrawalFeeRate) / 10000;
        polyToken.safeTransfer(instantWithdrawalFeeReceiver, amountToBurn);
        polyToken.safeTransfer(msg.sender, amount - amountToBurn);
    }

    function claim() public {
        uint256 amountToClaim = getClaimable(msg.sender);

        if (amountToClaim > 0) {
            polyToken.safeTransfer(address(msg.sender), amountToClaim);
        }

        lastClaimedTime[msg.sender] = block.timestamp;
    }

    function getClaimable(address user) public view returns (uint256 amount) {
        if (timeToFullClaim[user] > lastClaimedTime[user]) {
            return
                block.timestamp > timeToFullClaim[user]
                    ? claimablePerSecond[user] *
                        (timeToFullClaim[user] - lastClaimedTime[user])
                    : claimablePerSecond[user] *
                        (block.timestamp - lastClaimedTime[user]);
        }
    }

    function getVestingAmount(
        address user
    ) public view returns (uint256 amount) {
        if (timeToFullClaim[user] > block.timestamp) {
            return
                claimablePerSecond[user] *
                (timeToFullClaim[user] - block.timestamp);
        }
    }
}