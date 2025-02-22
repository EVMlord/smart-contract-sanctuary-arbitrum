// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
pragma solidity ^0.8.16;

interface IEnneadLpDepositor {
    function tokenForPool(address pool) external view returns (address);
}

interface IEnneadToken {
    function pool() external view returns (address);
}

/**
 * @title Ennead Whitelist for xRAM
 * @author Ramses Exchange
 * @notice Used as a lens contract to get all the Ennead contracts that's whitelisted to transfer xRAM
 */
contract EnneadWhitelist {
    // Ennead Addresses
    IEnneadLpDepositor public constant lpDepositor =
        IEnneadLpDepositor(0x1863736c768f232189F95428b5ed9A51B0eCcAe5);
    address public constant nfpDepositor =
        0xe99ead648Fb2893d1CFA4e8Fe8B67B35572d2581;
    address public constant neadStake =
        0x7D07A61b8c18cb614B99aF7B90cBBc8cD8C72680;
    address public constant feeHandler =
        0xe99ead4c038207A834A903FE6EdcBEf8CaE37B18;

    mapping(address sender => bool) public isWhitelisted;

    constructor() {
        // whitelist Ennead addresses
        isWhitelisted[address(lpDepositor)] = true;
        isWhitelisted[nfpDepositor] = true;
        isWhitelisted[neadStake] = true;
        isWhitelisted[feeHandler] = true;
    }

    /**
     * @notice Returns whether an address is whitelisted to transfer xRAM
     * @dev Writes Ennead pools to storage if not already stored
     * @param sender The address sending xRAM
     */
    function syncAndCheckIsWhitelisted(address sender) external returns (bool) {
        // return true if already stored
        if (isWhitelisted[sender]) {
            return true;
        }

        // Validate if the sender is an Ennead token if not on whitelist

        (bool sucess, bytes memory data) = sender.staticcall(
            abi.encodeWithSelector(IEnneadToken.pool.selector)
        );

        if (!sucess || data.length != 32) {
            return false;
        }

        address pool = abi.decode(data, (address));

        address token = lpDepositor.tokenForPool(pool);

        bool isValidEnneadToken = (sender == token);

        // Update whitelist if sender is a valid Ennead token
        if (isValidEnneadToken) {
            isWhitelisted[token] = true;
        }

        return isValidEnneadToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./EnneadWhitelist.sol";

interface IVeRam {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenID
    ) external view returns (bool);

    function create_lock_for(
        uint256 _amount,
        uint256 _length,
        address _for
    ) external returns (uint256);

    function increase_amount(uint256 _tokenID, uint256 _amount) external;

    function increase_unlock_time(uint256 _tokenID, uint256 _length) external;

    function locked(
        uint256 _tokenId
    ) external view returns (LockedBalance memory);
}

interface IVoter {
    function isGauge(address _gauge) external view returns (bool);
}

contract XRam is Initializable, ERC20Upgradeable {
    // constants and immutables
    uint256 public constant PRECISION = 100;
    uint256 public constant MAXTIME = 4 * 365 days;
    IERC20Upgradeable public immutable ram;
    IVeRam public immutable veRam;
    IVoter public immutable voter;

    // addresses
    address public timelock;
    address public multisig;
    address public whitelistOperator;

    mapping(address => bool) public isWhitelisted;

    ///@dev ratio of earned ram via exit penalty. 65% means they earn 65% of the RAM value
    uint256 public exitRatio = 65; // 65%
    uint256 public veExitRatio = 80; // 80%
    uint256 public minVest = 7 days; /// @notice the initial minimum vesting period is 7 days (one week)
    uint256 public veMaxVest = 30 days; /// @notice the initial maximum vesting period for vote escrowed exits is 30 days (1 month)
    uint256 public maxVest = 90 days; /// @notice the initial maximum vesting period is 90 days (3 months)

    struct VestPosition {
        uint256 amount; // amount of xRAM
        uint256 start; // start unix timestamp
        uint256 maxEnd; // start + maxVest (end timestamp)
        uint256 vestID; // vest identifier (starting from 0)
    }

    mapping(address user => VestPosition[]) public vestInfo;

    // Partner/Modular whitelists, at the end of the storage slots in case of more partners
    EnneadWhitelist public enneadWhitelist;

    // Events
    event WhitelistStatus(address indexed candidate, bool status);

    event RamConverted(address indexed user, uint256);
    event XRamRedeemed(address indexed user, uint256);

    event NewExitRatios(uint256 exitRatio, uint256 veExitRatio);
    event NewVestingTimes(uint256 min, uint256 max, uint256 veMaxVest);
    event InstantExit(address indexed user, uint256);

    event NewVest(
        address indexed user,
        uint256 indexed vestId,
        uint256 indexed amount
    );
    event ExitVesting(
        address indexed user,
        uint256 indexed vestId,
        uint256 amount
    );
    event CancelVesting(
        address indexed user,
        uint256 indexed vestId,
        uint256 amount
    );

    modifier onlyTimelock() {
        require(msg.sender == timelock, "xRAM: !Auth");
        _;
    }

    modifier onlyWhitelistOperator() {
        require(
            msg.sender == whitelistOperator,
            "xRAM: Only the whitelisting operator can call this function"
        );
        _;
    }

    constructor(
        address _ramToken,
        address _veRam,
        address _voter
    ) initializer() {
        ram = IERC20Upgradeable(_ramToken);
        veRam = IVeRam(_veRam);
        voter = IVoter(_voter);
    }

    function initialize(
        address _timelock,
        address _multisig,
        address _whitelistOperator,
        address _enneadWhitelist
    ) external initializer {
        __ERC20_init_unchained("Extended RAM", "xRAM");
        // set addresses
        timelock = _timelock;
        multisig = _multisig;
        whitelistOperator = _whitelistOperator;
        enneadWhitelist = EnneadWhitelist(_enneadWhitelist);

        // set initial parameters
        exitRatio = 65; // 65%
        veExitRatio = 80; // 80%
        minVest = 7 days; /// @notice the initial minimum vesting period is 7 days (one week)
        veMaxVest = 30 days; /// @notice the initial maximum vesting period for vote escrowed exits is 30 days (1 month)
        maxVest = 90 days; /// @notice the initial maximum vesting period is 90 days (3 months)

        // approve ram to veRam
        ram.approve(address(veRam), type(uint256).max);

        // whitelist address(0), for minting
        _updateWhitelist(address(0), true);

        // whitelist self, voter, and multisig
        _updateWhitelist(address(this), true);
        _updateWhitelist(address(voter), true);
        _updateWhitelist(multisig, true);

        // whitelist ennead
        _updateWhitelist(0x1863736c768f232189F95428b5ed9A51B0eCcAe5, true); // Ennead LP Depositor
        _updateWhitelist(0xe99ead648Fb2893d1CFA4e8Fe8B67B35572d2581, true); // Ennead NFP Depositor
        _updateWhitelist(0x7D07A61b8c18cb614B99aF7B90cBBc8cD8C72680, true); // neadStake
    }

    /*****************************************************************/
    // ERC20 Overrides
    /*****************************************************************/

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 //amount
    ) internal override {
        if (to != address(0)) {
            require(
                syncAndCheckIsWhitelisted(from),
                "xRAM: You are not able to transfer this token"
            );
        }
    }

    /*****************************************************************/
    // General use functions
    /*****************************************************************/

    ///@dev mints xRAM for each RAM.
    function convertRam(uint256 _amount) external {
        // restricted to whitelisted contracts
        // to prevent users from minting xRAM and can't convert back without penalty
        require(syncAndCheckIsWhitelisted(msg.sender), "xRAM: !auth");
        require(_amount > 0, "xRAM: Amount must be greater than 0");
        ram.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        emit RamConverted(msg.sender, _amount);
    }

    ///@dev convert xRAM to veRAM at veExitRatio (new veNFT form)
    function xRamConvertToNft(
        uint256 _amount
    ) external returns (uint256 veRamTokenId) {
        require(_amount > 0, "xRAM: Amount must be greater than 0");
        _burn(msg.sender, _amount);
        uint256 _adjustedAmount = ((veExitRatio * _amount) / PRECISION);
        _mint(multisig, (_amount - _adjustedAmount));
        veRamTokenId = veRam.create_lock_for(
            _adjustedAmount,
            MAXTIME,
            msg.sender
        );
        emit XRamRedeemed(msg.sender, _amount);
        return veRamTokenId;
    }

    ///@dev convert xRAM to veRAM at a 1:1 ratio (increase existing veNFT)
    function xRamIncreaseNft(uint256 _amount, uint256 _tokenID) external {
        require(_amount > 0, "xRAM: Amount must be greater than 0");
        _burn(msg.sender, _amount);

        IVeRam _veRam = veRam;
        // ensure the xRAM contract is approved to increase the amount of this veRAM
        // this is to ensure extending lock time will work
        require(
            _veRam.isApprovedOrOwner(address(this), _tokenID),
            "xRAM: The contract has not been given approval to your veRAM position"
        );

        uint256 _adjustedAmount = ((veExitRatio * _amount) / PRECISION);

        // mint the exit penalty to the multisig
        _mint(multisig, (_amount - _adjustedAmount));

        // ensures that the veRAM is 4 year locked
        try _veRam.increase_unlock_time(_tokenID, MAXTIME) {} catch {
            // check if lock duration is already max if the call fails
            // redundant, but just in case
            IVeRam.LockedBalance memory locked = _veRam.locked(_tokenID);
            require(
                locked.end >= ((block.timestamp + MAXTIME) / 1 weeks) * 1 weeks,
                "xRAM: veRAM isn't max locked"
            );
        }

        veRam.increase_amount(_tokenID, _adjustedAmount);
        emit XRamRedeemed(msg.sender, _amount);
    }

    ///@dev exit instantly with a penalty
    function instantExit(uint256 _amount) external {
        require(_amount > 0, "xRAM: Amount must be greater than 0");
        uint256 exitAmount = ((exitRatio * _amount) / PRECISION);
        uint256 haircut = _amount - exitAmount;

        _burn(msg.sender, _amount);
        // mint the exit penalty to the multisig
        _mint(multisig, haircut);
        ram.transfer(msg.sender, exitAmount);
        emit InstantExit(msg.sender, _amount);
    }

    ///@dev vesting xRAM --> RAM functionality
    function createVest(uint256 _amount) external {
        require(_amount > 0, "xRAM: Amount must be greater than 0");
        _burn(msg.sender, _amount);
        uint256 vestLength = vestInfo[msg.sender].length;
        vestInfo[msg.sender].push(
            VestPosition(
                _amount,
                block.timestamp,
                block.timestamp + maxVest,
                vestLength
            )
        );
        emit NewVest(msg.sender, vestLength, _amount);
    }

    ///@dev handles all situations regarding exiting vests
    function exitVest(uint256 _vestID, bool _ve) external returns (bool) {
        uint256 vestCount = vestInfo[msg.sender].length;
        require(
            vestCount != 0 && _vestID <= vestCount - 1,
            "xRAM: Vest does not exist"
        );
        VestPosition storage _vest = vestInfo[msg.sender][_vestID];
        require(
            _vest.amount != 0 && _vest.vestID == _vestID,
            "xRAM: Vest not active"
        );
        uint256 _amount = _vest.amount;
        uint256 _start = _vest.start;
        _vest.amount = 0;

        // case: vest has not crossed the minimum vesting threshold
        if (block.timestamp < _start + minVest) {
            _mint(msg.sender, _amount);
            emit CancelVesting(msg.sender, _vestID, _amount);
            return true;
        }

        ///@dev if it is not a veRAM exit
        if (!_ve) {
            // case: vest is complete
            if (_vest.maxEnd <= block.timestamp) {
                ram.transfer(msg.sender, _amount);
                emit ExitVesting(msg.sender, _vestID, _amount);
                return true;
            }
            // case: vest is in progress
            else {
                uint256 base = (_amount * exitRatio) / PRECISION;
                uint256 vestEarned = ((_amount *
                    (PRECISION - exitRatio) *
                    (block.timestamp - _start)) / maxVest) / PRECISION;

                uint256 exitedAmount = base + vestEarned;

                _mint(multisig, (_amount - exitedAmount));
                ram.transfer(msg.sender, exitedAmount);
                emit ExitVesting(msg.sender, _vestID, _amount);
                return true;
            }
        }
        // exit to veRam
        else {
            uint256 veMaxEnd = _start + veMaxVest;
            // case: vest is complete for vote escrow threshold
            if (veMaxEnd <= block.timestamp) {
                veRam.create_lock_for(_amount, MAXTIME, msg.sender);
                emit ExitVesting(msg.sender, _vestID, _amount);
                return true;
            }
            // case: vest is in progress for vote escrow exit
            else {
                uint256 base = (_amount * veExitRatio) / PRECISION;
                uint256 vestEarned = ((_amount *
                    (PRECISION - veExitRatio) *
                    (block.timestamp - _start)) / veMaxVest) / PRECISION;

                uint256 exitedAmount = base + vestEarned;

                _mint(multisig, (_amount - exitedAmount));
                veRam.create_lock_for(exitedAmount, MAXTIME, msg.sender);
                emit ExitVesting(msg.sender, _vestID, _amount);
                return true;
            }
        }
    }

    /*****************************************************************/
    // Permissioned functions, timelock/operator gated
    /*****************************************************************/

    ///@dev allows the multisig to redeem collected xRAM
    function multisigRedeem(uint256 _amount) external {
        require(msg.sender == multisig, "xRAM: !Auth");
        _burn(msg.sender, _amount);

        ram.transferFrom(address(this), msg.sender, _amount);
    }

    ///@dev timelock only: alter the parameters for exiting
    function alterExitRatios(
        uint256 _newExitRatio,
        uint256 _newVeExitRatio
    ) external onlyTimelock {
        exitRatio = _newExitRatio;
        veExitRatio = _newVeExitRatio;
        emit NewExitRatios(_newExitRatio, _newVeExitRatio);
    }

    ///@dev allows the timelock to rescue any trapped tokens
    function rescueTrappedTokens(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyTimelock {
        for (uint256 i = 0; i < _tokens.length; ++i) {
            IERC20Upgradeable(_tokens[i]).transfer(multisig, _amounts[i]);
        }
    }

    ///@dev change the minimum and maximum vest durations
    function reinitializeVestingParameters(
        uint256 _min,
        uint256 _max,
        uint256 _veMax
    ) external onlyTimelock {
        (minVest, maxVest, veMaxVest) = (_min, _max, _veMax);

        emit NewVestingTimes(_min, _max, _veMax);
    }

    ///@dev change minimum vesting parameter
    function changeMinimumVestingLength(
        uint256 _minVest
    ) external onlyTimelock {
        minVest = _minVest;

        emit NewVestingTimes(_minVest, maxVest, veMaxVest);
    }

    ///@dev change maximum vesting parameter
    function changeMaximumVestingLength(
        uint256 _maxVest
    ) external onlyTimelock {
        maxVest = _maxVest;

        emit NewVestingTimes(minVest, _maxVest, veMaxVest);
    }

    ///@dev change vote escrow maximum vesting parameter
    function changeVeMaximumVestingLength(
        uint256 _veMax
    ) external onlyTimelock {
        veMaxVest = _veMax;

        emit NewVestingTimes(minVest, maxVest, _veMax);
    }

    ///@dev migrates the timelock to another contract
    function migrateTimelock(address _timelock) external onlyTimelock {
        timelock = _timelock;
    }

    ///@dev migrates the multisig to another contract
    function migrateMultisig(address _multisig) external onlyTimelock {
        multisig = _multisig;
    }

    ///@dev migrates The Ennead whitelist
    function migrateEnneadWhitelist(
        address _enneadWhitelist
    ) external onlyWhitelistOperator {
        enneadWhitelist = EnneadWhitelist(_enneadWhitelist);
    }

    ///@dev only callable by the whitelistOperator contract
    function adjustWhitelist(
        address[] calldata _candidates,
        bool[] calldata _status
    ) external onlyWhitelistOperator {
        for (uint256 i = 0; i < _candidates.length; ++i) {
            _updateWhitelist(_candidates[i], _status[i]);
        }
    }

    ///@notice allows the whitelist operator to add an address to the xRAM whitelist
    function addWhitelist(address _whitelistee) external onlyWhitelistOperator {
        _updateWhitelist(_whitelistee, true);
    }

    ///@notice allows the whitelist operator to remove an address from the xRAM whitelist
    function removeWhitelist(
        address _whitelistee
    ) external onlyWhitelistOperator {
        _updateWhitelist(_whitelistee, false);
    }

    function _updateWhitelist(address _whitelistee, bool _status) internal {
        isWhitelisted[_whitelistee] = _status;

        emit WhitelistStatus(_whitelistee, _status);
    }

    ///@dev timelock can change the operator contract
    function changeWhitelistOperator(
        address _newOperator
    ) external onlyTimelock {
        whitelistOperator = _newOperator;
    }

    /*****************************************************************/
    // Getter functions
    /*****************************************************************/

    ///@dev return the amount of RAM within the contract
    function getBalanceResiding() public view returns (uint256) {
        return ram.balanceOf(address(this));
    }

    /// @notice Potentially writes new whitelsited pools to storage then return if an address is whitelisted to transfer xRAM
    /// @param _address The address of the sender
    function syncAndCheckIsWhitelisted(address _address) public returns (bool) {
        if (isWhitelisted[_address]) {
            return true;
        }

        // automatically whitelist gauges
        if (voter.isGauge(_address)) {
            _updateWhitelist(_address, true);
            return true;
        }

        // automatically whitelist ennead addresses
        if (enneadWhitelist.syncAndCheckIsWhitelisted(_address)) {
            _updateWhitelist(_address, true);
            return true;
        }

        return false;
    }

    ///@dev returns the total number of individual vests the user has
    function usersTotalVests(address _user) public view returns (uint256) {
        return vestInfo[_user].length;
    }
}