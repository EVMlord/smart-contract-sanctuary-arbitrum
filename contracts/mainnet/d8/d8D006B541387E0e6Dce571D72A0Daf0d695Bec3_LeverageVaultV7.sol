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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IGainsVault {
    function asset() external view returns (address);

    // Returns the global id of the current spoch.
    function currentEpoch() external view returns (uint256);

    // Returns the start timestamp of the current epoch.
    function currentEpochStart() external view returns (uint256);

    function maxDeposit(address owner) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    // Returns the epochs time(date) of the next withdraw
    // Base value [3, 2, 1]
    function withdrawEpochsTimelock() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    // DAI deposit function to Gains network
    function deposit(uint256 assets, address receiver) external returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function shareToAssetsPrice() external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);

    function makeWithdrawRequest(uint256 shares, address owner) external;

    // TODO: Check this feature is need
    function cancelWithdrawRequest(uint shares, address owner, uint unlockEpoch) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ILendingVault {
  function lend(uint256 leverage) external returns (bool);

  function repayDebt(uint256 loan, uint256 _amountPaid) external returns (bool);

  function rewardSplit() external view returns (uint256);

  function allocateDebt(uint256 amount) external;

  function totalDebt() external view returns (uint256);

  function totalAssets() external view returns (uint256);

  function balanceOfDAI() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function unstakeAndLiquidate(uint256 _pid, address _user, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IOpenTradesPnlFeed{
    function nextEpochValuesRequestCount() external view returns(uint);
    function newOpenPnlRequestOrEpoch() external;
}

pragma solidity 0.8.18;
// SPDX-License-Identifier: MIT

interface ITokenBurnable {
    function burn(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/ITokenBurnable.sol";
import "./interfaces/IOpenTradesPnlFeed.sol";
import "./interfaces/IGainsVault.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/ILendingVault.sol";

//import "hardhat/console.sol";

contract LeverageVaultV7 is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  ERC20BurnableUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using MathUpgradeable for uint256;
  using MathUpgradeable for uint128;

  struct UserInfo {
    address user; // user that created the position
    uint256 deposit; // total amount of deposit
    uint256 leverage; // leverage used
    uint256 position; // position size
    uint256 price; // gToken (gDAI) price when position was created
    bool liquidated; // true if position was liquidated
    bool withdrawalRequested; // true if user requested withdrawal
    uint256 epochUnlock; // epoch when user can withdraw
    uint256 closedPositionValue; // value of position when closed
  }

  struct LiquidationRequests {
    uint256 positionID; // position ID
    address user; // user that created the position
    uint256 leverage; // leverage used
    uint256 epochUnlock; // epoch when liquation can be executed
    address liquidatorRequestForWithdrawal; // address of liquidator that requested withdrawal
    address liquidator; // address of liquidator that executed liquidation
  }

  struct FeeSplitStrategyInfo {
    // slope 1 used to control the change of reward fee split when reward is inbetween  0-40%
    uint128 maxFeeSplitSlope1;
    // slope 2 used to control the change of reward fee split when reward is inbetween  40%-80%
    uint128 maxFeeSplitSlope2;
    // slope 3 used to control the change of reward fee split when reward is inbetween  80%-100%
    uint128 maxFeeSplitSlope3;
    uint128 utilizationThreshold1;
    uint128 utilizationThreshold2;
    uint128 utilizationThreshold3;
  }

  struct FeeConfiguration {
    address feeReceiver;
    uint256 withdrawalFee;
  }

  FeeSplitStrategyInfo public feeStrategy;
  FeeConfiguration public feeConfiguration;
  LiquidationRequests[] public liquidationRequests;
  address[] public allUsers;

  address public dai; // DAI
  address public gainsVault;
  address public lendingVault;
  address public MasterChef;
  address public openPNL;
  uint256 public MCPID;
  uint256 public MAX_BPS;
  

  uint256 public constant DECIMAL = 1e18;
  uint256 public liquidatorsRewardPercentage;
  uint256[50] private __gaps;

  mapping(address => UserInfo[]) public userInfo;
  mapping(uint256 => bool) public isPositionLiquidated;
  mapping(address => bool) public allowedSenders;
  mapping(address => bool) public burner;
  mapping(address => bool) public isUser;
  mapping(address => bool) public allowedClosers;
  
  uint256 public fixedFeeSplit;

  modifier InvalidID(uint256 positionId,address user) {
    require(
      positionId < userInfo[user].length,
      "Whiskey: positionID is not valid"
    );
    _;
  }

  modifier zeroAddress(address addr) {
    require(addr != address(0), "Zero address");
    _;
  }

  modifier onlyBurner() {
    require(burner[msg.sender], "Not allowed to burn");
    _;
  }

  /** --------------------- Event --------------------- */
  event LendingVaultChanged(address newLendingVault);
  event GainsAddressesChanged(address newGainsVault);
  event Deposit(
    address indexed depositer,
    uint256 depositTokenAmount,
    uint256 createdAt,
    uint256 GDAIAmount
  );
  event PendingWithdrawRequested(
    address indexed owner,
    uint256 positionId,
    uint256 position,
    uint256 createdAt,
    uint256 epochUnlock
  );
  event Withdraw(address indexed user, uint256 amount, uint256 time, uint256 GDAIAmount);
  event FeeStrategyUpdated(FeeSplitStrategyInfo newFeeStrategy);
  event ProtocolFeeChanged(
    address newFeeReceiver,
    uint256 newWithdrawalFee
  );
  event LiquidationRequest(
    address indexed liquidator,
    address indexed borrower,
    uint256 positionId,
    uint256 time
  );
  event LiquidatorsRewardPercentageChanged(uint256 newPercentage);
  event Liquidation(
    address indexed liquidator,
    address indexed borrower,
    uint256 positionId,
    uint256 liquidatedAmount,
    uint256 outputAmount,
    uint256 time
  );
  event SetAllowaedClosers(address indexed closer, bool allowed);
  event SetAllowedSenders(address indexed sender, bool allowed);
  event SetBurner(address indexed burner, bool allowed);
  event UpdateMCAndPID(address indexed _newMC, uint256 _mcpPid);


  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _dai,
    address _gDAI,
    address _lendingVault,
    address _openPNL
  ) external initializer {
    require(_dai != address(0) &&
      _gDAI != address(0) &&
      _lendingVault != address(0) &&
      _openPNL != address(0), "Zero address");
    dai = _dai;
    gainsVault = _gDAI;
    lendingVault = _lendingVault;
    openPNL = _openPNL;

    MAX_BPS = 100_000;
    liquidatorsRewardPercentage = 500;

    __Ownable_init();
    __Pausable_init();
    __ERC20_init("WhiskeyPOD", "WPOD");
  }

  /** ----------- Change onlyOwner functions ------------- */

  //MC or any other whitelisted contracts
  function setAllowed(address _sender, bool _allowed) public onlyOwner zeroAddress(_sender) {
    allowedSenders[_sender] = _allowed;
    emit SetAllowedSenders(_sender, _allowed);
  }

  function setFeeSplit(uint256 _feeSplit) public onlyOwner {
    require(_feeSplit <= 90, "Fee split cannot be more than 100%");
    fixedFeeSplit = _feeSplit;
  }

  function setBurner(address _burner,bool _allowed) public onlyOwner zeroAddress(_burner) {
    burner[_burner] = _allowed;
    emit SetBurner(_burner, _allowed);
  }
  
  function setMC(address _mc, uint256 _mcPid) public onlyOwner zeroAddress(_mc) {
    MasterChef = _mc;
    MCPID = _mcPid;
    emit UpdateMCAndPID(_mc, _mcPid);
  }

  function setCloser(address _closer,bool _allowed) public onlyOwner zeroAddress(_closer) {
    allowedClosers[_closer] = _allowed;
    emit SetAllowaedClosers(_closer, _allowed);
  }

  function changeProtocolFee(
    address newFeeReceiver,
    uint256 newWithdrawalFee
  ) external onlyOwner {
    feeConfiguration.withdrawalFee = newWithdrawalFee;
    feeConfiguration.feeReceiver = newFeeReceiver;
    emit ProtocolFeeChanged(newFeeReceiver, newWithdrawalFee);
  }

  function changeGainsContracts(
    address _gainsVault,
    address _openPNL
  ) external onlyOwner zeroAddress(_gainsVault) zeroAddress(_openPNL) {
    gainsVault = _gainsVault;
    openPNL = _openPNL;
    emit GainsAddressesChanged(_gainsVault);
  }

  function changeLendingVault(
    address _lendingVault
  ) external onlyOwner zeroAddress(_lendingVault) {
    lendingVault = _lendingVault;
    emit LendingVaultChanged(_lendingVault);
  }

  function updateFeeStrategyParams(
    FeeSplitStrategyInfo calldata _feeStrategy
  ) external onlyOwner {
    require(
        _feeStrategy.maxFeeSplitSlope1 >= 0 &&
        _feeStrategy.maxFeeSplitSlope1 <= DECIMAL &&
        _feeStrategy.maxFeeSplitSlope2 >= _feeStrategy.maxFeeSplitSlope1 &&
        _feeStrategy.maxFeeSplitSlope2 <= DECIMAL &&
        _feeStrategy.maxFeeSplitSlope3 >= _feeStrategy.maxFeeSplitSlope2 &&
        _feeStrategy.maxFeeSplitSlope3 <= DECIMAL &&
        _feeStrategy.utilizationThreshold1 >= 0 &&
        _feeStrategy.utilizationThreshold1 <=
        _feeStrategy.utilizationThreshold2 &&
        _feeStrategy.utilizationThreshold2 >=
        _feeStrategy.utilizationThreshold1 &&
        _feeStrategy.utilizationThreshold2 <=
        _feeStrategy.utilizationThreshold3 &&
        _feeStrategy.utilizationThreshold3 >=
        _feeStrategy.utilizationThreshold2 &&
        _feeStrategy.utilizationThreshold3 <= DECIMAL,
      "Invalid fee strategy parameters"
    );

    feeStrategy = _feeStrategy;
    emit FeeStrategyUpdated(_feeStrategy);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function updateLiquidatorsRewardPercentage(uint256 newPercentage) external onlyOwner {
    require(newPercentage <= MAX_BPS, "Whiskey: invalid percentage");
    liquidatorsRewardPercentage = newPercentage;
    emit LiquidatorsRewardPercentageChanged(newPercentage);
  }

  function getAllUsers() public view returns (address[] memory) {
    return allUsers;
  }

  function getTotalNumbersOfOpenPositionBy(address user) public view returns (uint256) {
    return userInfo[user].length;
  }

  function getGainsBalance() public view returns (uint256) {
    return IGainsVault(gainsVault).balanceOf(address(this));
  }

  function getPositionUnlockEpoch(uint256 positionID,address user, bool state) public view returns (bool) {
    bool canBeUnlocked;
    uint256 currentGainsEpoch = IGainsVault(gainsVault).currentEpoch();

    if (state) {
      UserInfo memory _userInfo = userInfo[user][positionID];
      if (currentGainsEpoch == _userInfo.epochUnlock && IOpenTradesPnlFeed(openPNL).nextEpochValuesRequestCount() == 0) {
        canBeUnlocked = true;
      } else {
        canBeUnlocked = false;
      }
    } else {
      LiquidationRequests memory liquidationRequest = liquidationRequests[positionID];
      if (currentGainsEpoch == liquidationRequest.epochUnlock) {
        canBeUnlocked = true;
      } else {
        canBeUnlocked = false;
      }
    }
    
    return canBeUnlocked;
  }

  function getUpdatedDebtAndValue(
    uint256 positionID,
    address user
  )
    public
    view
    returns (uint256 currentDTV, uint256 currentPosition, uint256 currentDebt)
  {
    UserInfo memory _userInfo = userInfo[user][positionID];
    if (_userInfo.position == 0 || _userInfo.liquidated) return (0, 0, 0);

    uint256 previousValueInDAI;
    (currentPosition, previousValueInDAI) = getCurrentPosition(
      positionID,
      user
    );

    uint256 profitOrLoss;
    uint256 getFeeSplit;
    uint256 rewardSplitToWater;
    uint256 owedToWater;

    if (currentPosition > previousValueInDAI) {
      profitOrLoss = currentPosition - previousValueInDAI;
      getFeeSplit = fixedFeeSplit;
      rewardSplitToWater = profitOrLoss * getFeeSplit / 100;
      owedToWater = _userInfo.leverage + rewardSplitToWater;
    } 
    else if (previousValueInDAI > currentPosition){
      owedToWater = _userInfo.leverage;
    } else {
      owedToWater = _userInfo.leverage;
    }
    currentDTV = owedToWater.mulDiv(DECIMAL, currentPosition);

    return (currentDTV, currentPosition, owedToWater);
  }

  function getCurrentPosition(
    uint256 positionID,
    address user
  ) public view returns (uint256 currentPosition, uint256 previousValueInDAI) {
    UserInfo memory _userInfo = userInfo[user][positionID];
    uint256 userPosition;
    if (_userInfo.closedPositionValue == 0) {
      userPosition = _userInfo.position;
      currentPosition = userPosition.mulDiv(gTokenPrice(), DECIMAL);
    } else {
      currentPosition = _userInfo.closedPositionValue;
    }
    previousValueInDAI = _userInfo.position.mulDiv(_userInfo.price, DECIMAL);
    
    
    return (currentPosition, previousValueInDAI);
  }

  /**
   * @notice Token Deposit
   * @dev Users can deposit with DAI
   * @param amount Deposit token amount
   * @param user User address
   */
  function openPosition(uint256 amount, address user) external whenNotPaused {
    IERC20Upgradeable(dai).safeTransferFrom(msg.sender, address(this), amount);
    user = msg.sender;
    uint256 leverage = amount * 2;
    
    bool status = ILendingVault(lendingVault).lend(leverage);
    require(status, "LendingVault: Lend failed");

    // Actual deposit amount to Gains network
    uint256 xAmount = amount + leverage;

    IERC20Upgradeable(dai).safeApprove(gainsVault, xAmount);
    uint256 balanceBefore = getGainsBalance();

    IGainsVault(gainsVault).deposit(xAmount, address(this));
    
    uint256 balanceAfter = getGainsBalance();
    uint256 gdaiShares = balanceAfter - balanceBefore;

    UserInfo memory _userInfo = UserInfo({
      user: user,
      deposit: amount,
      leverage: leverage,
      position: gdaiShares,
      price: gTokenPrice(),
      liquidated: false,
      withdrawalRequested: false,
      epochUnlock: 0,
      closedPositionValue: 0
    });

    //frontend helper to fetch all users and then their userInfo
    if (isUser[msg.sender] == false) {
      isUser[msg.sender] = true;
      allUsers.push(msg.sender);
    } 

    userInfo[msg.sender].push(_userInfo);
    _mint(msg.sender, gdaiShares);

    emit Deposit(msg.sender, amount, block.timestamp, gdaiShares);
  }

  function closePosition(
    uint256 positionID,
    address _user
  ) external whenNotPaused InvalidID(positionID,_user) nonReentrant {
    UserInfo storage _userInfo = userInfo[_user][positionID];
    require(!_userInfo.liquidated, "Whiskey: position is liquidated");
    require(_userInfo.position > 0, "Whiskey: position is not enough to close");
    require(_userInfo.withdrawalRequested,"Whiskey: user has not requested a withdrawal");
    require(getPositionUnlockEpoch(positionID, _user, true), "Whiskey: position is not unlocked yet");
    require(allowedClosers[msg.sender] || msg.sender == _userInfo.user, "Whiskey: not allowed to close position");

    uint256 balanceBefore = IERC20Upgradeable(dai).balanceOf(address(this));
    uint256 returnedAssetInDAI = IGainsVault(gainsVault).redeem(
      _userInfo.position,
      address(this),
      address(this)
    );
    uint256 balanceAfter = IERC20Upgradeable(dai).balanceOf(address(this));
    _userInfo.closedPositionValue = balanceAfter - balanceBefore;

    (uint256 currentDTV, , uint256 debtValue) = getUpdatedDebtAndValue(positionID, _user);

    _userInfo.position = 0;

    uint256 afterLoanPayment;
    if (currentDTV >= (9 * DECIMAL) / 10 || returnedAssetInDAI < debtValue) {
      _userInfo.liquidated = true;
      IERC20Upgradeable(dai).safeApprove(lendingVault, returnedAssetInDAI);
      ILendingVault(lendingVault).repayDebt(_userInfo.leverage, returnedAssetInDAI);
      emit LiquidationRequest(_user, _user, positionID, block.timestamp);
      return;
    } else {
      afterLoanPayment = returnedAssetInDAI - debtValue;
    }

    IERC20Upgradeable(dai).safeApprove(lendingVault, debtValue);
    ILendingVault(lendingVault).repayDebt(_userInfo.leverage, debtValue);

    // take protocol fee
    uint256 amountAfterFee;
    if (feeConfiguration.withdrawalFee > 0) {
      uint256 fee = afterLoanPayment.mulDiv(
        feeConfiguration.withdrawalFee,
        MAX_BPS
      );
      IERC20Upgradeable(dai).safeTransfer(feeConfiguration.feeReceiver, fee);
      amountAfterFee = afterLoanPayment - fee;
    } else {
      amountAfterFee = afterLoanPayment;
    }
    IERC20Upgradeable(dai).safeTransfer(_user, amountAfterFee);
    emit Withdraw(_user, amountAfterFee, block.timestamp, _userInfo.closedPositionValue);
  }

  function requestLiquidationPosition(uint256 positionId, address user) external {
    UserInfo storage _userInfo = userInfo[user][positionId];
    uint256 userPosition = _userInfo.position;
    require(!_userInfo.liquidated, "Whiskey: position is liquidated");
    require(userPosition > 0, "Whiskey: position is not enough to close");
    (uint256 currentDTV, ,) = getUpdatedDebtAndValue(positionId, user);
    require(currentDTV >= (9 * DECIMAL) / 10, "Liquidation Threshold Has Not Reached");

    //delete any amounts staked in MC or user wallet. We assume only the MC is whitelisted to stake.
    uint256 userAmountStaked;
    if (MasterChef != address(0)) {
        (userAmountStaked,) = IMasterChef(MasterChef).userInfo(MCPID,user);
        if (userAmountStaked > 0) {
          IMasterChef(MasterChef).unstakeAndLiquidate(MCPID, user, userPosition);
        }
    }
    
    if (userAmountStaked == 0) {
      _burn(user, userPosition);
    }
    
    IGainsVault(gainsVault).makeWithdrawRequest(userPosition, address(this));

    _userInfo.liquidated = true;

    liquidationRequests.push(
      LiquidationRequests({
        positionID: positionId,
        user: user,
        leverage: _userInfo.leverage,
        epochUnlock : getWithdrawableEpochTime(),
        liquidatorRequestForWithdrawal: msg.sender,
        liquidator: address(0)
      })
    );

    emit LiquidationRequest(msg.sender, user, positionId, block.timestamp);
  }

  function liquidatePosition(uint256 liquidationId) external {
    LiquidationRequests storage liquidationRequest = liquidationRequests[liquidationId];
    require(!isPositionLiquidated[liquidationId], "Whiskey: Not Liquidatable");
    require(liquidationRequest.user != address(0), "Whiskey: liquidation request does not exist");
    require(getPositionUnlockEpoch(liquidationId, address(this), false), "Whiskey: position is not unlocked yet");
    uint256 position = userInfo[liquidationRequest.user][liquidationRequest.positionID].position;
    // redeem all asset from gains vault
    uint256 returnedAssetInDAI = IGainsVault(gainsVault).redeem(
      position,
      address(this),
      address(this)
    );
    liquidationRequest.liquidator = msg.sender;
    isPositionLiquidated[liquidationId] = true;

    // liquidaorsRewardPercentage
    // liquidator and liquidatorRequestForWithdrawal can share the reward
    // @dev taking liquidation reward from returnedAssetInDAI instead
    // of checking if returnedAssetInDAI is greater than debtValue
    // if yes then remove the debt value first and then take liquidation reward from  remnant
    // then the remaining should be added to the debt value as water users bonus
    uint256 liquidatorReward = returnedAssetInDAI.mulDiv(
      liquidatorsRewardPercentage,
      MAX_BPS
    );
    // deduct liquidator reward from returnedAssetInDAI
    uint256 amountAfterLiquidatorReward = returnedAssetInDAI - liquidatorReward;
    // repay debt
    IERC20Upgradeable(dai).safeApprove(lendingVault, amountAfterLiquidatorReward);
    ILendingVault(lendingVault).repayDebt(liquidationRequest.leverage, amountAfterLiquidatorReward);

    if (msg.sender != liquidationRequest.liquidatorRequestForWithdrawal) {
      uint256 liquidatorRequestForWithdrawalReward = liquidatorReward / 2;
      IERC20Upgradeable(dai).safeTransfer(
        liquidationRequest.liquidatorRequestForWithdrawal,
        liquidatorRequestForWithdrawalReward
      );
      IERC20Upgradeable(dai).safeTransfer(
        msg.sender,
        liquidatorReward - liquidatorRequestForWithdrawalReward
      );
    } else {
      IERC20Upgradeable(dai).safeTransfer(msg.sender, liquidatorReward);
    }
    // emit event
    emit Liquidation(
      liquidationRequest.liquidator,
      liquidationRequest.user,
      liquidationRequest.positionID,
      position,
      liquidatorReward,
      block.timestamp
    );
  }

  function makeWithdrawRequestWithAssets(
    uint256 positionId
  ) public InvalidID(positionId,msg.sender) {
    UserInfo storage _userInfo = userInfo[msg.sender][positionId];
    require(!_userInfo.liquidated, "Whiskey: position is liquidated");
    require(_userInfo.position > 0, "Whiskey: position is not enough to close");

    //normal unstake from MC/redeem flow, user needs to unstake from MC then redeem if staked
    ITokenBurnable(address(this)).burnFrom(msg.sender,_userInfo.position);
    require(IOpenTradesPnlFeed(openPNL).nextEpochValuesRequestCount() == 0, "Whiskey: gdai next epoch values request count is not 0");
    IGainsVault(gainsVault).makeWithdrawRequest(_userInfo.position, address(this));

    // withdrawal request can be made multiple time cause if user did not withdraw
    // GDAi will be staked in the next epoch
    _userInfo.withdrawalRequested = true;
    _userInfo.epochUnlock = getWithdrawableEpochTime();
    emit PendingWithdrawRequested(
        msg.sender,
        positionId,
        _userInfo.position,
        block.timestamp,
        _userInfo.epochUnlock
    );
  }

  function getWithdrawableEpochTime() public view returns (uint256) {
    return IGainsVault(gainsVault).currentEpoch() + IGainsVault(gainsVault).withdrawEpochsTimelock();
  }

  function totalShares() public view returns (uint256) {
    return IERC20Upgradeable(gainsVault).balanceOf(address(this));
  }

  function gTokenPrice() public view returns (uint256) {
    return IGainsVault(gainsVault).shareToAssetsPrice();
  }

  function calculateFeeSplit() public view returns (uint256 feeSplitRate) {
    uint256 utilizationRate = getUtilizationRate();
    if (utilizationRate <= feeStrategy.utilizationThreshold1) {
      /* Slope 1
            rewardFee_{slope2} =  
                {maxFeeSplitSlope1 *  {(utilization Ratio / URThreshold1)}}
            */
      feeSplitRate = (feeStrategy.maxFeeSplitSlope1).mulDiv(
        utilizationRate,
        feeStrategy.utilizationThreshold1
      );
    } else if (
      utilizationRate > feeStrategy.utilizationThreshold1 &&
      utilizationRate < feeStrategy.utilizationThreshold2
    ) {
      /* Slope 2
            rewardFee_{slope2} =  
                maxFeeSplitSlope1 + 
                {(utilization Ratio - URThreshold1) / 
                (1 - UR Threshold1 - (UR Threshold3 - URThreshold2)}
                * (maxFeeSplitSlope2 -maxFeeSplitSlope1) 
            */
      uint256 subThreshold1FromUtilizationRate = utilizationRate -
        feeStrategy.utilizationThreshold1;
      uint256 maxBpsSubThreshold1 = DECIMAL - feeStrategy.utilizationThreshold1;
      uint256 threshold3SubThreshold2 = feeStrategy.utilizationThreshold3 -
        feeStrategy.utilizationThreshold2;
      uint256 mSlope2SubMSlope1 = feeStrategy.maxFeeSplitSlope2 -
        feeStrategy.maxFeeSplitSlope1;
      uint256 feeSlpope = maxBpsSubThreshold1 - threshold3SubThreshold2;
      uint256 split = subThreshold1FromUtilizationRate.mulDiv(
        DECIMAL,
        feeSlpope
      );
      feeSplitRate = mSlope2SubMSlope1.mulDiv(split, DECIMAL);
      feeSplitRate = feeSplitRate + (feeStrategy.maxFeeSplitSlope1);
    } else if (
      utilizationRate > feeStrategy.utilizationThreshold2 &&
      utilizationRate < feeStrategy.utilizationThreshold3
    ) {
      /* Slope 3
            rewardFee_{slope3} =  
                maxFeeSplitSlope2 + {(utilization Ratio - URThreshold2) / 
                (1 - UR Threshold2}
                * (maxFeeSplitSlope3 -maxFeeSplitSlope2) 
            */
      uint256 subThreshold2FromUtilirationRatio = utilizationRate -
        feeStrategy.utilizationThreshold2;
      uint256 maxBpsSubThreshold2 = DECIMAL - feeStrategy.utilizationThreshold2;
      uint256 mSlope3SubMSlope2 = feeStrategy.maxFeeSplitSlope3 -
        feeStrategy.maxFeeSplitSlope2;
      uint256 split = subThreshold2FromUtilirationRatio.mulDiv(
        DECIMAL,
        maxBpsSubThreshold2
      );

      feeSplitRate =
        (split.mulDiv(mSlope3SubMSlope2, DECIMAL)) +
        (feeStrategy.maxFeeSplitSlope2);
    }
    return feeSplitRate;
  }

  function getUtilizationRate() public view returns (uint256) {
    uint256 totalWaterDebt = ILendingVault(lendingVault).totalDebt();
    uint256 totalWaterAssets = ILendingVault(lendingVault).balanceOfDAI();
    return totalWaterDebt == 0 ? 0 : totalWaterDebt.mulDiv(DECIMAL, totalWaterAssets + totalWaterDebt);
  }

  function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
      address spender = _msgSender();
      require(allowedSenders[from] || allowedSenders[to] || allowedSenders[spender], "ERC20: transfer not allowed");
      _spendAllowance(from, spender, amount);
      _transfer(from, to, amount);
      return true;
  }

  function transfer(address to, uint256 amount) public virtual override returns (bool) {
      address ownerOf = _msgSender();
      require(allowedSenders[ownerOf] || allowedSenders[to], "ERC20: transfer not allowed");
      _transfer(ownerOf, to, amount);
      return true;
  }

  function burn(uint256 amount) public virtual override onlyBurner {
        _burn(_msgSender(), amount);
  }
}