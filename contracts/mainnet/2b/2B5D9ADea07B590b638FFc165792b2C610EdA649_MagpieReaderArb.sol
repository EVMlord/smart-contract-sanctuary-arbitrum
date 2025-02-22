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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterMagpieReader {
    // struct PoolInfo {
    //     address stakingToken; // Address of staking token contract to be staked.
    //     uint256 allocPoint; // How many allocation points assigned to this pool. MGPs to distribute per second.
    //     uint256 lastRewardTimestamp; // Last timestamp that MGPs distribution occurs.
    //     uint256 accMGPPerShare; // Accumulated MGPs per share, times 1e12. See below.
    //     address rewarder;
    //     address helper;
    //     bool    helperNeedsHarvest;
    // }
    function poolLength() external view returns (uint256);
    function registeredToken(uint256) external view returns (address);
    function tokenToPoolInfo(address) external view returns (address, uint256, uint256, uint256, address, address, bool);
    function getPoolInfo(address) external view returns (uint256, uint256, uint256, uint256);
    function mgp() external view returns (address);
    function vlmgp() external view returns (address);
    function MPGRewardPool(address) external view returns (bool);

    function allPendingTokens(address _stakingToken, address _user)
        external view returns (
            uint256 pendingMGP,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );
    function stakingInfo(address _stakingToken, address _user)
        external
        view
        returns (uint256 stakedAmount, uint256 availableAmount);
}

pragma solidity ^0.8.0;

interface IPancakeRouter02Reader {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ILBRouter } from "./ILBRouter.sol";

interface ILBQuoter {

   struct Quote {
        address[] route;
        address[] pairs;
        uint256[] binSteps;
        uint256[] amounts;
        uint256[] virtualAmountsWithoutSlippage;
        uint256[] fees;
    }

    function findBestPathFromAmountIn(address[] calldata route, uint256 amountIn)
        external
        view
    returns (Quote memory quote);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Liquidity Book Router Interface
 * @author Trader Joe
 * @notice Required interface of LBRouter contract
 */
interface ILBRouter {

    enum Version {
        V1,
        V2,
        V2_1
    }

    /**
     * @dev The path parameters, such as:
     * - pairBinSteps: The list of bin steps of the pairs to go through
     * - versions: The list of versions of the pairs to go through
     * - tokenPath: The list of tokens in the path to go through
     */
    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );    
}

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IAssetReader is IERC20 {
    function pool() external view returns (address);
    function underlyingToken() external view returns (address);
    function underlyingTokenDecimals() external view returns (uint8);
    function cash() external view returns (uint256);
    function liability() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev Interface of the MasterWombat
 */
interface IMasterWombatV3Reader {
    function poolLength() external view returns (uint256);
    struct WombatV3Pool {
        address lpToken; // Address of LP token contract.
        ////
        address rewarder;
        uint40 periodFinish;
        ////
        uint128 sumOfFactors; // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
        uint128 rewardRate; // 20.18 fixed point.
        ////
        uint104 accWomPerShare; // 19.12 fixed point. Accumulated WOM per share, times 1e12.
        uint104 accWomPerFactorShare; // 19.12 fixed point. Accumulated WOM per factor share
        uint40 lastRewardTimestamp;
    }
    function poolInfoV3(uint256 poolId) external view returns (WombatV3Pool memory);
    //amount uint128, factor uint128, rewardDebt uint128, pendingWom uint128
    function userInfo(uint256 poolId, address account) external view  returns (uint128,  uint128,  uint128,  uint128);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMultiRewarder {
    function onReward(address _user, uint256 _lpAmount) external returns (uint256[] memory rewards);

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMultiRewarderReader {
    

    function rewardTokens() external view returns (IERC20[] memory tokens);
    function rewardLength() external view returns (uint256);
    //rewardToken address, tokenPerSec uint96, accTokenPerShare uint128, distributedAmount uint128
    function rewardInfo(uint256 id) external view returns ( address,  uint96,  uint128,  uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IMultiRewarder.sol';

interface IWombatBribe is IMultiRewarder {

    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external returns (uint256[] memory rewards);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IWombatVoter.sol';
import './IWombatStakingReader.sol';
interface IWombatBribeManagerReader {

    struct Pool {
        address poolAddress;
        address rewarder;
        uint256 totalVoteInVlmgp;
        string name;
        bool isActive;
    }

    function poolInfos(address lpAddress) external view returns (address, address, uint256, string memory, bool);
    function getPoolsLength() external view returns (uint256);
    function pools(uint256 poolIndex)  external view returns (address);
    function voter() external view returns (IWombatVoter);
    function wombatStaking() external view returns (IWombatStakingReader);
    function getVoteForLp(address lp) external view returns (uint256);
    function totalVlMgpInVote() external view returns (uint256);
    function usedVote() external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWombatBribeReader {

    function rewardInfo(uint256 index) external view returns (IERC20 rewardToken, uint96 tokenPerSec, uint128 accTokenPerShare, uint128 distributedAmount);

    function rewardLength() external view returns (uint256);

    function balances() external view returns (uint256[] memory balances_);
}

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;

interface IWombatPoolHelperV2Reader {
    function isNative() external view returns(bool);
    function depositToken() external view returns(address);
    function lpToken() external view returns(address);
    function pid() external view returns(uint256);
    function stakingToken() external view returns(address);
    function balance(address _address) external  view returns (uint256);
}

pragma solidity ^0.8.0;

/**
 * @dev Interface of the VeWom
 */
interface IWombatRouterReader {

    /**
     * @notice Given an input asset amount and an array of token addresses, calculates the
     * maximum output token amount (accounting for fees and slippage).
     * @param tokenPath The token swap path
     * @param poolPath The token pool path
     * @param amountIn The from amount
     * @return amountOut The potential final amount user would receive
     */
    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);


}

// SPDX-License-Identifier: MIT

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.8.0;

interface IWombatStakingReader {
    function masterWombat() external view returns(address);
    struct WombatStakingPool {
        uint256 pid;                // pid on master wombat
        address depositToken;       // token to be deposited on wombat
        address lpAddress;          // token received after deposit on wombat
        address receiptToken;       // token to receive after
        address rewarder;
        address helper;
        address depositTarget;
        bool isActive;
    }

    function pools(address lpAdress)  external view returns(WombatStakingPool memory);
    function isPoolFeeFree(address lpAdress)  external view returns(bool);
    function bribeCallerFee() external view returns(uint256);
    function bribeProtocolFee() external view returns(uint256);
    function wom() external view returns(address);
    function mWom() external view returns(address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IWombatBribe.sol';

interface IWombatGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IWombatVoter {
    struct GaugeInfo {
        uint104 supplyBaseIndex;
        uint104 supplyVoteIndex;
        uint40 nextEpochStartTime;
        uint128 claimable;
        bool whitelist;
        IWombatGauge gaugeManager;
        IWombatBribe bribe;
    }
    
    struct GaugeWeight {
        uint128 allocPoint;
        uint128 voteWeight; // total amount of votes for an LP-token
    }

    function infos(address) external view returns (GaugeInfo memory);

    function getUserVotes(address _user, address _lpToken) external view returns (uint256);

    function lpTokenLength() external view returns (uint256);

    function weights(address _lpToken) external view returns (GaugeWeight memory);    

    function pendingBribes(address[] calldata _lpTokens, address _user)
        external
        view
        returns (uint256[][] memory bribeRewards);

    function vote(address[] calldata _lpVote, int256[] calldata _deltas)
        external
        returns (uint256[][] memory bribeRewards);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IWombatBribeManagerReader} from "./interfaces/wombat/IWombatBribeManagerReader.sol";
import {IWombatVoter, IWombatGauge} from "./interfaces/wombat/IWombatVoter.sol";
import {IWombatBribeReader} from "./interfaces/wombat/IWombatBribeReader.sol";
import {IAssetReader} from "./interfaces/wombat/IAssetReader.sol";
import {IWombatStakingReader} from "./interfaces/wombat/IWombatStakingReader.sol";
import {IMasterWombatV3Reader} from "./interfaces/wombat/IMasterWombatV3Reader.sol";
import {IMasterMagpieReader} from "./interfaces/IMasterMagpieReader.sol";
import {IMultiRewarderReader} from "./interfaces/wombat/IMultiRewarderReader.sol";
import {IPancakeRouter02Reader} from "./interfaces/pancake/IPancakeRouter02Reader.sol";
import {IWombatRouterReader} from "./interfaces/wombat/IWombatRouterReader.sol";
import {IWombatPoolHelperV2Reader} from "./interfaces/wombat/IWombatPoolHelperV2Reader.sol";
import {AggregatorV3Interface} from "./interfaces/chainlink/AggregatorV3Interface.sol";
import {IUniswapV3Pool} from "./interfaces/uniswapV3/IUniswapV3Pool.sol";
import {ILBQuoter} from "./interfaces/traderjoeV2/ILBQuoter.sol";

/// @title MagpieReader for Arbitrum
/// @author Magpie Team

contract MagpieReaderArb is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint128;
    /* ============ Structs ============ */

    struct BribeInfo {
        uint256 bribeCallerFee;
        uint256 bribeProtocolFee;
        uint256 usedVote;
        uint256 totalVlMgpInVote;
        BribePool[] pools;
    }

    //   const usedVote = await this.wombatBribeManagerContract.usedVote();  
    // const totalVlMgpInVote = await this.wombatBribeManagerContract.totalVlMgpInVote();

    struct BribePoolReward {
        IERC20 rewardToken; // if rewardToken is 0, native token is used as reward token
        string symbol;
        uint96 tokenPerSec; // 10.18 fixed point
        uint128 accTokenPerShare; // 26.12 fixed point. Amount of reward token each LP token is worth.
        uint128 distributedAmount; // 20.18 fixed point, depending on the decimals of the reward token. This value is used to
        // track the amount of distributed tokens. If `distributedAmount` is closed to the amount of total received
        // tokens, we should refill reward or prepare to stop distributing reward.
        uint256 balance;
    }
    
    struct BribePool {
        address lpAddress;
        string lpSymbol;
        address underlyingToken;
        string underlyingTokenSymbol;
        address poolAddress;
        address rewarder;
        uint256 totalVoteInVlmgp;
        string name;
        bool isActive;

        uint104 supplyBaseIndex;
        uint104 supplyVoteIndex;
        uint40 nextEpochStartTime;
        uint128 claimable;
        bool whitelist;

        IWombatGauge gaugeManager;
        IWombatBribeReader bribe;

        uint128 allocPoint;
        uint128 voteWeight; 

        uint256 wombatStakingUserVotes;
        BribePoolReward[] rewardList;
    }

    struct MagpieInfo {
        address wom;
        address mgp;
        address vlmgp;
        address mWom;
        TokenPrice[] tokenPriceList;
        MagpiePool[] pools;
    }

    struct MagpiePool {
        address stakingToken; // Address of staking token contract to be staked.
        uint256 allocPoint; // How many allocation points assigned to this pool. MGPs to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that MGPs distribution occurs.
        uint256 accMGPPerShare; // Accumulated MGPs per share, times 1e12. See below.
        address rewarder;
        address helper;
        bool    helperNeedsHarvest;
        uint256 emission;
        uint256 sizeOfPool;
        uint256 totalPoint;
        string  poolType;
        string  stakingTokenSymbol;
        uint256  stakingTokenDecimals;
        uint256 poolId;
        uint256 poolTokenPrice;
        bool isWombatPool;
        bool isActive;
        bool isMPGRewardPool;
        WombatStakingPool wombatStakingPool;
        WombatV3Pool wombatV3Pool;
        WombatPoolHelperInfo wombatHelperInfo;
        MagpieRewardInfo rewardInfo;
        MagpieAccountInfo accountInfo;
        WombatAccountInfo wombatAccountInfo;
    }

    struct MagpieAccountInfo {
        uint256 balance;
        uint256 stakedAmount;
        uint256 stakingAllowance;
        uint256 availableAmount;
    }

    struct WombatAccountInfo {
        uint256 lpBalance;
        uint256 lpDepositAllowance;
        uint128 amount;
        uint128 factor;
        uint128 rewardDebt;
        uint128 pendingWom;
    }

    struct MagpieRewardInfo {
        uint256 pendingMGP;
        address[]  bonusTokenAddresses;
        string[]  bonusTokenSymbols;
        uint256[]  pendingBonusRewards;
        uint256[]  bonusTokenDecimals;
    }

    struct WombatPoolHelperInfo {
        
        bool isNative;
        address depositToken;
        string depositTokenSymbol;
        uint256 depositTokenDecimals;
        address lpToken;
        address stakingToken;
    }

    struct MagpiePoolApr {
        MagpiePoolAprToken[] items;
    }

    struct MagpiePoolAprToken {
        string symbol;
        uint256 price;
        uint256 rewardAmount;
        uint256 tvlAmount; 
        uint256 aprValue;
    }

    struct MagpiePoolTvl {
        uint256 totalSupply;
        address token;
        uint256 price;
        uint256 totalSupplyAmount;
    }

    struct WombatV3Pool {
        address lpToken; // Address of LP token contract.
        ////
        address rewarder;
        uint40 periodFinish;
        ////
        uint128 sumOfFactors; // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
        uint128 rewardRate; // 20.18 fixed point.
        uint128 rewardRateToMgp; // 20.18 fixed point.
        uint128 boostedEffect; // 20.18 fixed point.
        ////
        uint104 accWomPerShare; // 19.12 fixed point. Accumulated WOM per share, times 1e12.
        uint104 accWomPerFactorShare; // 19.12 fixed point. Accumulated WOM per factor share
        uint40 lastRewardTimestamp;
        uint128 wombatStakingUserAmount;
        uint128 wombatStakingUserFactor;
        // uint128 wombatStakingUserRewardDebt;
        // uint128 wombatStakingUserPendingWom;
        uint256 totalSupply;
        // uint256 normPerSec;
        // uint256 emission;
        // uint256 boostedPerSec;
        WombatV3PoolReward[] rewardList;
        address pool;
        string  poolType;
        // address underlyingToken;
        // string  underlyingTokenSymbol;
        // uint256 underlyingTokenDecimals;
        uint256 assetCash;
        uint256 assetLiability;
        string lpTokenSymbol;
        uint256 pid;
    }

    struct WombatV3PoolReward {
         address rewardToken;
         uint96 tokenPerSec;
         uint128 accTokenPerShare;
         uint128 distributedAmount;
         string rewardTokenSymbol;
         uint256 rewardTokenDecimals;
    }

    struct WombatStakingPool {
        uint256 pid;                // pid on master wombat
        address depositToken;       // token to be deposited on wombat
        address lpAddress;          // token received after deposit on wombat
        address receiptToken;       // token to receive after
        address rewarder;
        address helper;
        address depositTarget;
        bool isActive;
        // string depositTokenSymbol;
        // uint256 depositTokenDecimals; 
        bool isPoolFeeFree;
    }

    struct TokenPrice {
        address token;
        string  symbol;
        uint256 price;
    }

    struct TokenRouter {
        address token;
        string symbol;
        uint256 decimals;
        address[] paths;
        address[] pools;
        address chainlink;
        uint256 routerType;
    }

    /* ============ State Variables ============ */

    IWombatBribeManagerReader public wombatBribeManager; // IWombatBribeManager interface
    IWombatVoter public voter; // Wombat voter interface
    IWombatStakingReader public wombatStaking;
    IMasterMagpieReader public masterMagpie;
    IMasterWombatV3Reader public masterWombatV3;
    IPancakeRouter02Reader public pancakeRouter02;
    IWombatRouterReader public wombatRouter;
    mapping(address => string) public wombatPoolType;
    mapping(address => TokenRouter) public tokenRouterMap;
    address[] public tokenList;
    address public wom;
    address public mWom;
    address public mgp;
    address public vlmgp;

   // IPancakeRouter02Reader constant public PancakeRouter02 = IPancakeRouter02Reader(0x10ED43C718714eb63d5aA57B78B54704E256024E);
   // IWombatRouterReader constant public WombatRouter = IWombatRouterReader(0x19609B03C976CCA288fbDae5c21d4290e9a4aDD7);
    address constant public USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant public USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant public WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    uint256 constant PancakeRouterType = 1;
    uint256 constant WombatRouterType = 2;
    uint256 constant ChainlinkType = 3;
    uint256 constant UniswapV3RouterType = 4; // currently only works for 18 decimal tokens    
    uint256 constant TraderJoeV2Type = 5;
    
    uint256 constant ActiveWombatPool = 1;
    uint256 constant DeactiveWombatPool = 2;
    mapping(uint256 => uint256) public wombatPoolStatus;
    address public mWomSV;

    address constant public TraderJoeV2LBQuoter = 0x7f281f22eDB332807A039073a7F34A4A215bE89e;

    /* ============ Events ============ */

    /* ============ Errors ============ */

    /* ============ Constructor ============ */

    // function __MagpieReader_init( 
    //     IMasterMagpieReader _masterMagpie, 
    //     IWombatBribeManagerReader _wombatBribeManager,
    //     IPancakeRouter02Reader _pancakeRouter02,
    //     IWombatRouterReader _wombatRouter,
    //     address _mWomSV
    //     )
    //     public
    //     initializer
    // {
    //     __Ownable_init();
    //     masterMagpie = _masterMagpie;
    //     wombatBribeManager = _wombatBribeManager;
    //     pancakeRouter02 = _pancakeRouter02;
    //     wombatRouter = _wombatRouter;
    //     mWomSV = _mWomSV;
    //     voter = IWombatVoter(wombatBribeManager.voter());
    //     wombatStaking = IWombatStakingReader(wombatBribeManager.wombatStaking());
    //     masterWombatV3 = IMasterWombatV3Reader(wombatStaking.masterWombat());
    // }

    /* ============ External Getters ============ */

    function getMagpieInfo(address account) external view returns (MagpieInfo memory) {
        MagpieInfo memory magpieInfo;
        uint256 poolCount = masterMagpie.poolLength();
        MagpiePool[] memory pools = new MagpiePool[](poolCount);
        TokenPrice[] memory tokenPriceList = getAllTokenPrice();
        for (uint256 i = 0; i < poolCount; ++i) {
           pools[i] = getMagpiePoolInfo(i, account);
        }
        magpieInfo.tokenPriceList = tokenPriceList;
        magpieInfo.pools = pools;
        magpieInfo.wom = wom;
        magpieInfo.mWom = mWom;
        magpieInfo.mgp = mgp;
        magpieInfo.vlmgp = vlmgp;
        return magpieInfo;
    }

    function getMagpiePoolInfo(uint256 poolId, address account) public view returns (MagpiePool memory) {
        MagpiePool memory magpiePool;
        magpiePool.poolId = poolId;
        address registeredToken = masterMagpie.registeredToken(poolId);
        (magpiePool.stakingToken, magpiePool.allocPoint, magpiePool.lastRewardTimestamp, magpiePool.accMGPPerShare, magpiePool.rewarder, magpiePool.helper, magpiePool.helperNeedsHarvest)  = masterMagpie.tokenToPoolInfo(registeredToken);
        (magpiePool.emission, magpiePool.allocPoint, magpiePool.sizeOfPool, magpiePool.totalPoint)  = masterMagpie.getPoolInfo(registeredToken);
        
        magpiePool.stakingTokenSymbol = ERC20(magpiePool.stakingToken).symbol();
        magpiePool.stakingTokenDecimals = ERC20(magpiePool.stakingToken).decimals();
        if (magpiePool.stakingToken == mWom) {
            magpiePool.poolType = "MAGPIE_WOM_POOL";
            magpiePool.isActive = true;
        }
        else if (magpiePool.stakingToken == vlmgp) {
            magpiePool.poolType = "MAGPIE_VLMGP_POOL";
            magpiePool.isActive = true;
        }    
        else if (magpiePool.stakingToken == mWomSV) {
            magpiePool.poolType = "MAGPIE_MWOMSV_POOL";
            magpiePool.isActive = true;
        }
        else if (wombatPoolStatus[poolId] == ActiveWombatPool) {
            magpiePool.wombatHelperInfo = _getWombatHelperInfo(magpiePool.helper);
            magpiePool.wombatStakingPool = _getWombatStakingPoolInfo(magpiePool.wombatHelperInfo.lpToken);
            magpiePool.wombatV3Pool = _getWombatV3PoolInfo(magpiePool.wombatStakingPool.pid);
            IAssetReader assetReader = IAssetReader(magpiePool.wombatV3Pool.lpToken);
            magpiePool.wombatV3Pool.assetCash = assetReader.cash();
            magpiePool.wombatV3Pool.assetLiability = assetReader.liability();
            magpiePool.wombatV3Pool.pool = assetReader.pool();
            // magpiePool.wombatV3Pool.underlyingToken = assetReader.underlyingToken();
            // magpiePool.wombatV3Pool.underlyingTokenDecimals = assetReader.underlyingTokenDecimals();
            // magpiePool.wombatV3Pool.underlyingTokenSymbol =  ERC20(magpiePool.wombatV3Pool.underlyingToken).symbol();
            magpiePool.wombatV3Pool.poolType = wombatPoolType[magpiePool.wombatV3Pool.pool];
            magpiePool.poolType = "WOMBAT_POOL";
            if (magpiePool.wombatV3Pool.rewarder != address(0)) {
                magpiePool.wombatV3Pool.rewardList = _getWombatV3PoolRewardList(magpiePool.wombatV3Pool.rewarder);
            }
            magpiePool.isWombatPool = true;
            magpiePool.isActive = true;
        }
        else if (wombatPoolStatus[poolId] == DeactiveWombatPool) {
            magpiePool.wombatHelperInfo = _getWombatHelperInfo(magpiePool.helper);
            magpiePool.poolType = "WOMBAT_POOL";
            magpiePool.isWombatPool = true;
            magpiePool.isActive = false;
        }
        magpiePool.isMPGRewardPool = masterMagpie.MPGRewardPool(magpiePool.stakingToken);
        if (account != address(0)) {
            magpiePool.rewardInfo = _getMagpieRewardInfo(magpiePool.stakingToken, account);
            magpiePool.accountInfo = _getMagpieAccountInfo(magpiePool, account);
            if (magpiePool.isWombatPool == true && magpiePool.isActive == true) {
                magpiePool.wombatAccountInfo = _getWombatAccountInfo(magpiePool, account);
            }
            
        }
        return magpiePool;
    }

    function getBribeInfo() external view returns (BribeInfo memory) {
        BribeInfo memory bribeInfo;
        uint256 poolCount = wombatBribeManager.getPoolsLength();
        BribePool[] memory pools = new BribePool[](poolCount);
        for (uint256 i = 0; i < poolCount; ++i) {
            address lpAddress = wombatBribeManager.pools(i);
            BribePool memory bribePool;
            bribePool.lpAddress = lpAddress;
            IAssetReader asset = IAssetReader(lpAddress);
            bribePool.underlyingToken = asset.underlyingToken();
            bribePool.underlyingTokenSymbol = ERC20(bribePool.underlyingToken).symbol();
            bribePool.lpSymbol = ERC20(bribePool.lpAddress).symbol();
            (bribePool.poolAddress, bribePool.rewarder, bribePool.totalVoteInVlmgp, bribePool.name, bribePool.isActive) = wombatBribeManager.poolInfos(lpAddress); 
            IWombatVoter.GaugeInfo memory gaugeInfo = voter.infos(lpAddress);
            bribePool.supplyBaseIndex = gaugeInfo.supplyBaseIndex;
            bribePool.supplyVoteIndex = gaugeInfo.supplyVoteIndex;
            bribePool.nextEpochStartTime = gaugeInfo.nextEpochStartTime;
            bribePool.claimable = gaugeInfo.claimable;
            bribePool.whitelist = gaugeInfo.whitelist;
            bribePool.gaugeManager = gaugeInfo.gaugeManager;
            bribePool.bribe = IWombatBribeReader(address(gaugeInfo.bribe));

            IWombatVoter.GaugeWeight memory gaugeWeight = voter.weights(lpAddress);
            bribePool.allocPoint = gaugeWeight.allocPoint;
            bribePool.voteWeight = gaugeWeight.voteWeight;

            bribePool.wombatStakingUserVotes = wombatBribeManager.getVoteForLp(lpAddress);
            if (address(bribePool.bribe) != address(0)) {
                uint256 rewardLength = bribePool.bribe.rewardLength();
                bribePool.rewardList = new BribePoolReward[](rewardLength);
                uint256[] memory balances = bribePool.bribe.balances();
                for (uint256 m = 0; m < rewardLength; m++) {
                    (
                        bribePool.rewardList[m].rewardToken,
                        bribePool.rewardList[m].tokenPerSec,
                        bribePool.rewardList[m].accTokenPerShare,
                        bribePool.rewardList[m].distributedAmount
                    )
                     = bribePool.bribe.rewardInfo(m);
                    bribePool.rewardList[m].symbol = ERC20(address(bribePool.rewardList[m].rewardToken)).symbol();
                    bribePool.rewardList[m].balance = balances[m];
                }
            }
            pools[i] = bribePool;
        }
        bribeInfo.pools = pools;
        bribeInfo.bribeCallerFee = wombatStaking.bribeCallerFee();
        bribeInfo.bribeProtocolFee = wombatStaking.bribeProtocolFee();
        bribeInfo.usedVote = wombatBribeManager.usedVote();
        bribeInfo.totalVlMgpInVote = wombatBribeManager.totalVlMgpInVote();
        return bribeInfo;
    }

    function getUSDTPrice() public view returns (uint256) {
        return getTokenPrice(USDT, address(0));
    }

    function getUSDCPrice() public view returns (uint256) {
        return getTokenPrice(USDC, address(0));
    }    

    function getWETHPrice() public view returns (uint256) {
        return getTokenPrice(WETH, address(0));
    }

    // just to make frontend happy
    function getBUSDPrice() public view returns (uint256) {
        return 0;
    }

    // just to make frontend happy
    function getBNBPrice() public view returns (uint256) {
        return 0;
    }       

    // just to make frontend happy
    function getETHPrice() public view returns (uint256) {
        return getTokenPrice(WETH, address(0));
    }

    function getTokenPrice(address token, address unitToken) public view returns (uint256) {
        TokenRouter memory tokenRouter = tokenRouterMap[token];
        uint256 amountOut = 0;
        if (tokenRouter.token != address(0)) {
           if (tokenRouter.routerType == PancakeRouterType) {
            uint256[] memory prices = pancakeRouter02.getAmountsOut(10 ** tokenRouter.decimals , tokenRouter.paths);
            amountOut = prices[tokenRouter.paths.length - 1];
           }
           else if (tokenRouter.routerType == WombatRouterType) {
            (amountOut , ) = wombatRouter.getAmountOut(tokenRouter.paths, tokenRouter.pools, int256(10) ** tokenRouter.decimals);
          
           }
           else if (tokenRouter.routerType == ChainlinkType) {
            AggregatorV3Interface aggregatorV3Interface = AggregatorV3Interface(tokenRouter.chainlink);
              (
                /* uint80 roundID */,
                int256 price,
                /*uint startedAt*/,
                /*uint timeStamp*/,
                /*uint80 answeredInRound*/
            ) = aggregatorV3Interface.latestRoundData();
            amountOut = uint256(price * 1e18 / 1e8);
           } else if (tokenRouter.routerType == UniswapV3RouterType) {
            IUniswapV3Pool pool = IUniswapV3Pool(tokenRouter.pools[0]);
            (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
            amountOut = uint(sqrtPriceX96).mul(uint(sqrtPriceX96)).mul(1e18) >> (96 * 2);
           } else if (tokenRouter.routerType == TraderJoeV2Type) {
            uint256[] memory quotes = (ILBQuoter(TraderJoeV2LBQuoter).findBestPathFromAmountIn(tokenRouter.paths, 10 ** tokenRouter.decimals)).amounts;
            amountOut = quotes[tokenRouter.paths.length - 1];
           }
       
        }
        if (unitToken == address(0)) {
            return amountOut;
        } 

        TokenRouter memory router = tokenRouterMap[unitToken];
        uint256 unitPrice;
        if (router.routerType != ChainlinkType) {
            address target = router.paths[router.paths.length - 1];
            unitPrice = getTokenPrice(unitToken, target);
        } else {
            unitPrice = getTokenPrice(unitToken, address(0));
        }
        
        uint256 uintDecimals =  ERC20(unitToken).decimals();
        return amountOut * unitPrice / (10 ** uintDecimals);
    }

    function getAllTokenPrice() public view returns (TokenPrice[] memory) {
        TokenPrice[] memory items = new TokenPrice[](tokenList.length);
        for(uint256 i = 0; i < tokenList.length; i++) {
            TokenPrice memory tokenPrice;
            TokenRouter memory router = tokenRouterMap[tokenList[i]];
            address target;

            if (router.routerType != ChainlinkType) {
                target = router.paths[router.paths.length - 1];

            }

            tokenPrice.price = getTokenPrice(tokenList[i], target);
            
            tokenPrice.symbol = router.symbol;
            tokenPrice.token = tokenList[i];
            items[i] = tokenPrice;
        }
        return items;
    }

    /* ============ Internal Functions ============ */

    function _getMagpieAccountInfo(MagpiePool memory magpiePool, address account) internal view returns (MagpieAccountInfo memory) {
        MagpieAccountInfo memory accountInfo;
        if (magpiePool.isWombatPool) {
            accountInfo.balance = ERC20(magpiePool.wombatHelperInfo.depositToken).balanceOf(account);
            accountInfo.stakingAllowance = ERC20(magpiePool.wombatHelperInfo.depositToken).allowance(account, address(wombatStaking));
            IWombatPoolHelperV2Reader helper = IWombatPoolHelperV2Reader(magpiePool.helper);
            accountInfo.stakedAmount = helper.balance(account);
            if (magpiePool.wombatHelperInfo.isNative == true) {
                accountInfo.balance = account.balance;
                accountInfo.stakingAllowance = type(uint256).max;
            }
        }
        else {
            accountInfo.balance = ERC20(magpiePool.stakingToken).balanceOf(account);
            accountInfo.stakingAllowance = ERC20(magpiePool.stakingToken).allowance(account, address(masterMagpie));
            (accountInfo.stakedAmount, accountInfo.availableAmount) = masterMagpie.stakingInfo(magpiePool.stakingToken, account);
        }
    
        return accountInfo;
    }

    function _getWombatAccountInfo(MagpiePool memory magpiePool, address account) internal view returns (WombatAccountInfo memory) {
        WombatAccountInfo memory accountInfo;
        accountInfo.lpBalance = ERC20(magpiePool.wombatV3Pool.lpToken).balanceOf(account);
        accountInfo.lpDepositAllowance = ERC20(magpiePool.wombatV3Pool.lpToken).allowance(account, address(wombatStaking));
        // uint128 amount;
        // uint128 factor;
        // uint128 rewardDebt;
        // uint128 pendingWom;
        (accountInfo.amount, accountInfo.factor, accountInfo.rewardDebt, accountInfo.pendingWom) = masterWombatV3.userInfo(magpiePool.wombatV3Pool.pid, account);
        return accountInfo;
    }

    function _getMagpieRewardInfo(address stakingToken, address account) internal view returns (MagpieRewardInfo memory) {
        MagpieRewardInfo memory rewardInfo;
        (rewardInfo.pendingMGP, rewardInfo.bonusTokenAddresses, rewardInfo.bonusTokenSymbols, rewardInfo.pendingBonusRewards) = masterMagpie.allPendingTokens(stakingToken, account);

        uint256 rewardCount = rewardInfo.bonusTokenAddresses.length;
        uint256[] memory bonusTokenDecimals = new uint256[](rewardCount);
        for(uint256 n = 0; n < rewardCount; ++n) {
            bonusTokenDecimals[n] = ERC20(rewardInfo.bonusTokenAddresses[n]).decimals();
        }
        rewardInfo.bonusTokenDecimals = bonusTokenDecimals;
        return rewardInfo;
    }

    function _getWombatHelperInfo(address helperAddress) internal view returns (WombatPoolHelperInfo memory) {
        IWombatPoolHelperV2Reader helper = IWombatPoolHelperV2Reader(helperAddress);
        WombatPoolHelperInfo memory wombatHelperInfo;
        wombatHelperInfo.isNative = helper.isNative();
        wombatHelperInfo.depositToken = helper.depositToken();
        wombatHelperInfo.depositTokenSymbol = ERC20(wombatHelperInfo.depositToken).symbol();
        wombatHelperInfo.depositTokenDecimals = ERC20(wombatHelperInfo.depositToken).decimals();
        wombatHelperInfo.lpToken = helper.lpToken();
        wombatHelperInfo.stakingToken = helper.stakingToken();
        return wombatHelperInfo;
    }

    function _getWombatV3PoolRewardList(address rewarderAddress) internal view returns (WombatV3PoolReward[] memory) {
        IMultiRewarderReader rewarder = IMultiRewarderReader(rewarderAddress);
        uint256 rewardCount = rewarder.rewardLength();
        WombatV3PoolReward[] memory rewardList =  new WombatV3PoolReward[](rewardCount);
        for(uint256 n = 0; n < rewardCount; ++n) {
            WombatV3PoolReward memory poolReward;
            (poolReward.rewardToken, poolReward.tokenPerSec, poolReward.accTokenPerShare, poolReward.distributedAmount ) = rewarder.rewardInfo(n);
            poolReward.rewardTokenSymbol = ERC20(poolReward.rewardToken).symbol();
            poolReward.rewardTokenDecimals = ERC20(poolReward.rewardToken).decimals();
            rewardList[n] = poolReward;
        }
        return rewardList;
    }

    function _getWombatV3PoolInfo(uint256 poolId) internal view returns (WombatV3Pool memory) {
        WombatV3Pool memory wombatPool;
        IMasterWombatV3Reader.WombatV3Pool memory v3PoolInfo = masterWombatV3.poolInfoV3(poolId);
        wombatPool.lpToken = v3PoolInfo.lpToken;
        wombatPool.periodFinish = v3PoolInfo.periodFinish;
        wombatPool.rewarder = v3PoolInfo.rewarder;
        wombatPool.rewardRate = v3PoolInfo.rewardRate;
        wombatPool.sumOfFactors = v3PoolInfo.sumOfFactors;
        wombatPool.accWomPerFactorShare = v3PoolInfo.accWomPerFactorShare;
        wombatPool.accWomPerShare = v3PoolInfo.accWomPerShare;
        wombatPool.lastRewardTimestamp = v3PoolInfo.lastRewardTimestamp;
        (wombatPool.wombatStakingUserAmount, wombatPool.wombatStakingUserFactor, , ) = masterWombatV3.userInfo(poolId, address(wombatStaking));
        wombatPool.totalSupply = ERC20(wombatPool.lpToken).balanceOf(address(masterWombatV3));
        wombatPool.lpTokenSymbol = ERC20(wombatPool.lpToken).symbol();
        wombatPool.pid = poolId;
        return wombatPool;
    }

    function _getWombatStakingPoolInfo(address lpToken) internal view returns (WombatStakingPool memory) {
        WombatStakingPool memory wombatStakingPool;
        IWombatStakingReader.WombatStakingPool memory wombatStakingPoolInfo = wombatStaking.pools(lpToken);
        wombatStakingPool.lpAddress = wombatStakingPoolInfo.lpAddress;
        wombatStakingPool.depositTarget = wombatStakingPoolInfo.depositTarget;
        wombatStakingPool.depositToken = wombatStakingPoolInfo.depositToken;
        wombatStakingPool.helper = wombatStakingPoolInfo.helper;
        wombatStakingPool.isActive = wombatStakingPoolInfo.isActive;
        wombatStakingPool.pid = wombatStakingPoolInfo.pid;
        wombatStakingPool.receiptToken = wombatStakingPoolInfo.receiptToken;
        wombatStakingPool.rewarder = wombatStakingPoolInfo.rewarder;
        wombatStakingPool.isPoolFeeFree = wombatStaking.isPoolFeeFree(lpToken);
        return wombatStakingPool;
    }

    function _addTokenRouteInteral(address tokenAddress, address [] memory paths, address[] memory pools) internal returns (TokenRouter memory tokenRouter) {
        if (tokenRouterMap[tokenAddress].token == address(0)) {
            tokenList.push(tokenAddress);
        }
        tokenRouter.token = tokenAddress;
        tokenRouter.symbol = ERC20(tokenAddress).symbol();
        tokenRouter.decimals = ERC20(tokenAddress).decimals();
        tokenRouter.paths = paths;
        tokenRouter.pools = pools;
    }

    /* ============ Admin Functions ============ */

    function addWombatPoolType(address poolAddress, string memory poolType) external onlyOwner  {
        wombatPoolType[poolAddress] = poolType;
    }

    // function addTokenPancakeRouter(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
    //     TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
    //     tokenRouter.routerType = PancakeRouterType;
    //     tokenRouterMap[tokenAddress] = tokenRouter;
    // }
    function addTokenWombatRouter(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = WombatRouterType;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }

    // function addUniswapV3Router(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
    //     TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
    //     tokenRouter.routerType = UniswapV3RouterType;
    //     tokenRouterMap[tokenAddress] = tokenRouter;
    // }

    // function addTradeJoeV2Router(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
    //     TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
    //     tokenRouter.routerType = TraderJoeV2Type;
    //     tokenRouterMap[tokenAddress] = tokenRouter;
    // }        

    function addTokenChainlink(address tokenAddress, address [] memory paths, address[] memory pools, address priceAddress) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = ChainlinkType;
        tokenRouter.chainlink = priceAddress;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }

    // function setMagpieWombatPoolStatus(uint256 magpiePoolId, uint256 status) external onlyOwner  {
    //     wombatPoolStatus[magpiePoolId] = status;
    // }

    // function reInit() external onlyOwner  {
    //     mWom = wombatStaking.mWom();
    //     wom = wombatStaking.wom();
    //     mgp = masterMagpie.mgp();
    //     vlmgp = masterMagpie.vlmgp();
    // }

    // function setCameloptRouter(address _router) external onlyOwner  {
    //     pancakeRouter02 = IPancakeRouter02Reader(_router);
    // }

}