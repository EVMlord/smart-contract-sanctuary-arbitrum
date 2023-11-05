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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IController.sol";
import "../interfaces/IControllable.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {

  address internal _controller;
  uint256 internal createdTimestamp;
  /// @notice Controller address changed
  event UpdateController(address oldValue, address newValue);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param __controller Controller address
  function initializeControllable(address __controller) public initializer {
    _controller = __controller;
    createdTimestamp = block.timestamp;
  }

  function isController(address _adr) public override view returns (bool) {
    return _adr == controller();
  }

  /// @notice Return true is given address is setup as governance in Controller
  /// @param _adr Address for check
  /// @return true if given address is governance
  function isGovernance(address _adr) public override view returns (bool) {
    return IController(controller()).governance() == _adr;
  }

  // ************ MODIFIERS **********************

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(controller() == msg.sender, "not controller");
    _;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(isController(msg.sender) || isGovernance(msg.sender), "not controller or gov");
    _;
  }

  /// @dev Only smart contracts will be affected by this modifier
  ///      If it is a contract it should be whitelisted
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  /// @dev Only Reward Distributor allowed. Governance is Reward Distributor by default.
  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  /// @return adr Controller address
  function controller() public view returns (address adr) {
    adr = _controller;
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view returns (uint256 ts) {
    ts = createdTimestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IControllable {
  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity ^0.8.9;

interface IController {


  function VERSION() external view returns (string memory);

  function addHardWorker(address _worker) external;

  function addStrategiesToSplitter(
    address _splitter,
    address[] memory _strategies
  ) external;

  function addStrategy(address _strategy) external;

  function addVaultsAndStrategies(
    address[] memory _vaults,
    address[] memory _strategies
  ) external;

  function announcer() external view returns (address);

  function changeWhiteListStatus(address[] memory _targets, bool status)
  external;

  function controllerTokenMove(
    address _recipient,
    address _token,
    uint256 _amount
  ) external;

  function dao() external view returns (address);

  function distributor() external view returns (address);

  function doHardWork(address _vault) external;

  function feeRewardForwarder() external view returns (address);

  function fund() external view returns (address);

  function fundDenominator() external view returns (uint256);

  function fundKeeperTokenMove(
    address _fund,
    address _token,
    uint256 _amount
  ) external;

  function fundNumerator() external view returns (uint256);

  function fundToken() external view returns (address);

  function governance() external view returns (address);

  function hardWorkers(address) external view returns (bool);

  function initialize() external;

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function mintAndDistribute(uint256 totalAmount, bool mintAllAvailable)
  external;

  function mintHelper() external view returns (address);

  function psDenominator() external view returns (uint256);

  function psNumerator() external view returns (uint256);

  function psVault() external view returns (address);

  function pureRewardConsumers(address) external view returns (bool);

  function rebalance(address _strategy) external;

  function removeHardWorker(address _worker) external;

  function rewardDistribution(address) external view returns (bool);

  function rewardToken() external view returns (address);

  function setDao(address newValue) external;

  function setDistributor(address _distributor) external;

  function setFeeRewardForwarder(address _feeRewardForwarder) external;

  function setFund(address _newValue) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator)
  external;

  function setFundToken(address _newValue) external;

  function setGovernance(address newValue) external;

  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator)
  external;

  function setPsVault(address _newValue) external;

  function setPureRewardConsumers(address[] memory _targets, bool _flag)
  external;

  function setRewardDistribution(
    address[] memory _newRewardDistribution,
    bool _flag
  ) external;

  function setRewardToken(address _newValue) external;

  function setVaultController(address _newValue) external;

  function setVaultStrategyBatch(
    address[] memory _vaults,
    address[] memory _strategies
  ) external;

  function strategies(address) external view returns (bool);

  function strategyTokenMove(
    address _strategy,
    address _token,
    uint256 _amount
  ) external;

  function vaultController() external view returns (address);

  function vaults(address) external view returns (bool);

  function whiteList(address) external view returns (bool);
}

// SPDX-License-Identifier: ISC
/**
 * By using this software, you understand, acknowledge and accept that Tetu
 * and/or the underlying software are provided “as is” and “as available”
 * basis and without warranties or representations of any kind either expressed
 * or implied. Any use of this open source software released under the ISC
 * Internet Systems Consortium license is done at your own risk to the fullest
 * extent permissible pursuant to applicable law any and all liability as well
 * as all warranties, including any fitness for a particular purpose with respect
 * to Tetu and/or the underlying software and the use thereof are disclaimed.
 */

pragma solidity ^0.8.9;

interface IStrategy {
  enum Platform {
    UNKNOWN, // 0
    TETU, // 1
    QUICK, // 2
    SUSHI, // 3
    WAULT, // 4
    IRON, // 5
    COSMIC, // 6
    CURVE, // 7
    DINO, // 8
    IRON_LEND, // 9
    HERMES, // 10
    CAFE, // 11
    TETU_SWAP, // 12
    SPOOKY, // 13
    AAVE_LEND, //14
    AAVE_MAI_BAL, // 15
    GEIST, //16
    HARVEST, //17
    SCREAM_LEND, //18
    KLIMA, //19
    VESQ, //20
    QIDAO, //21
    SUNFLOWER, //22
    NACHO, //23
    STRATEGY_SPLITTER, //24
    TOMB, //25
    TAROT, //26
    BEETHOVEN, //27
    IMPERMAX, //28
    TETU_SF, //29
    ALPACA, //30
    MARKET, //31
    UNIVERSE, //32
    MAI_BAL, //33
    UMA, //34
    SPHERE, //35
    BALANCER, //36
    OTTERCLAM, //37
    MESH, //38
    D_FORCE, //39
    DYSTOPIA, //40
    SLOT_41, //41
    SLOT_42, //42
    SLOT_43, //43
    SLOT_44, //44
    SLOT_45, //45
    SLOT_46, //46
    SLOT_47, //47
    SLOT_48, //48
    SLOT_49, //49
    SLOT_50 //50
  }

  // *************** GOVERNANCE ACTIONS **************
  function STRATEGY_NAME() external view returns (string memory);

  function withdrawAllToVault() external;

  function withdrawAll(address to) external;

  function withdrawToVault(uint256 amount) external;

  function withdraw(address to, uint256 amount) external;

  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function earn() external;

  function investAllUnderlying() external;

  function deposit(uint256, uint256) external;

  function emergencyExit() external;

  function pauseInvesting() external;

  function continueInvesting() external;

  // **************** VIEWS ***************
  function rewardTokens() external view returns (address[] memory);

  function underlying() external view returns (address);

  function underlyingBalance() external view returns (uint256);

  function rewardPoolBalance() external view returns (uint256);

  function buyBackRatio() external view returns (uint256);

  function unsalvageableTokens(address token) external view returns (bool);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);

  function platform() external view returns (Platform);

  function assets() external view returns (address[] memory);

  function pausedInvesting() external view returns (bool);

  function readyToClaim() external view returns (uint256[] memory);

  function poolTotalAmount() external view returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
 * By using this software, you understand, acknowledge and accept that Tetu
 * and/or the underlying software are provided “as is” and “as available”
 * basis and without warranties or representations of any kind either expressed
 * or implied. Any use of this open source software released under the ISC
 * Internet Systems Consortium license is done at your own risk to the fullest
 * extent permissible pursuant to applicable law any and all liability as well
 * as all warranties, including any fitness for a particular purpose with respect
 * to Tetu and/or the underlying software and the use thereof are disclaimed.
 */

pragma solidity ^0.8.9;

interface IStrategySplitter {
  enum Platform {
    UNKNOWN, // 0
    TETU, // 1
    QUICK, // 2
    SUSHI, // 3
    WAULT, // 4
    IRON, // 5
    COSMIC, // 6
    CURVE, // 7
    DINO, // 8
    IRON_LEND, // 9
    HERMES, // 10
    CAFE, // 11
    TETU_SWAP, // 12
    SPOOKY, // 13
    AAVE_LEND, //14
    AAVE_MAI_BAL, // 15
    GEIST, //16
    HARVEST, //17
    SCREAM_LEND, //18
    KLIMA, //19
    VESQ, //20
    QIDAO, //21
    SUNFLOWER, //22
    NACHO, //23
    STRATEGY_SPLITTER, //24
    TOMB, //25
    TAROT, //26
    BEETHOVEN, //27
    IMPERMAX, //28
    TETU_SF, //29
    ALPACA, //30
    MARKET, //31
    UNIVERSE, //32
    MAI_BAL, //33
    UMA, //34
    SPHERE, //35
    BALANCER, //36
    OTTERCLAM, //37
    MESH, //38
    D_FORCE, //39
    DYSTOPIA, //40
    SLOT_41, //41
    SLOT_42, //42
    SLOT_43, //43
    SLOT_44, //44
    SLOT_45, //45
    SLOT_46, //46
    SLOT_47, //47
    SLOT_48, //48
    SLOT_49, //49
    SLOT_50 //50
  }

  // *************** GOVERNANCE ACTIONS **************

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function doHardWork() external;

  function emergencyExit() external;

  function pauseInvesting() external;

  function continueInvesting() external;

  // **************** VIEWS ***************

  function underlyingBalance() external view returns (uint256);

  function rewardPoolBalance() external view returns (uint256);

  function buyBackRatio() external view returns (uint256);

  function unsalvageableTokens(address token) external view returns (bool);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);

  function platform() external pure returns (Platform);

  function assets() external view returns (address[] memory);

  function readyToClaim() external view returns (uint256[] memory);

  function poolTotalAmount() external view returns (uint256);

  function strategies(uint idx) external view returns (address);

  function strategiesRatios(address strategy) external view returns (uint);

  function withdrawRequestsCalls(address user) external view returns (uint);

  function addStrategy(address _strategy) external;

  function removeStrategy(address _strategy) external;

  function setStrategyRatios(address[] memory _strategies, uint[] memory _ratios) external;

  function strategiesInited() external view returns (bool);

  function wantToWithdraw() external view returns (uint);

  function maxCheapWithdraw() external view returns (uint);

  function strategiesLength() external view returns (uint);

  function allStrategies() external view returns (address[] memory);

  function strategyRewardTokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity ^0.8.9;

/// @title Library for useful functions for address and uin256 arrays
/// @author bogdoslav, belbix
library ArrayLib {

  string constant INDEX_OUT_OF_BOUND = "ArrayLib: Index out of bounds";
  string constant NOT_UNIQUE_ITEM = "ArrayLib: Not unique item";
  string constant ITEM_NOT_FOUND = "ArrayLib: Item not found";

  /// @dev Return true if given item found in address array
  function contains(address[] storage array, address _item) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) return true;
    }
    return false;
  }

  /// @dev Return true if given item found in uin256 array
  function contains(uint256[] storage array, uint256 _item) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) return true;
    }
    return false;
  }

  // -----------------------------------

  /// @dev If token not exist in the array push it, otherwise throw an error
  function addUnique(address[] storage array, address _item) internal {
    require(!contains(array, _item), NOT_UNIQUE_ITEM);
    array.push(_item);
  }

  /// @dev If token not exist in the array push it, otherwise throw an error
  function addUnique(uint256[] storage array, uint256 _item) internal {
    require(!contains(array, _item), NOT_UNIQUE_ITEM);
    array.push(_item);
  }

  // -----------------------------------

  /// @dev Call addUnique for the given items array
  function addUniqueArray(address[] storage array, address[] memory _items) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      addUnique(array, _items[i]);
    }
  }

  /// @dev Call addUnique for the given items array
  function addUniqueArray(uint256[] storage array, uint256[] memory _items) internal {
    for (uint i = 0; i < _items.length; i++) {
      addUnique(array, _items[i]);
    }
  }

  // -----------------------------------

  /// @dev Remove an item by given index.
  /// @param keepSorting If true the function will shift elements to the place of removed item
  ///                    If false will move the last element on the place of removed item
  function removeByIndex(address[] storage array, uint256 index, bool keepSorting) internal {
    require(index < array.length, INDEX_OUT_OF_BOUND);

    if (keepSorting) {
      // shift all elements to the place of removed item
      // the loop must not include the last element
      for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
      }
    } else {
      // copy the last address in the array
      array[index] = array[array.length - 1];
    }
    array.pop();
  }

  /// @dev Remove an item by given index.
  /// @param keepSorting If true the function will shift elements to the place of removed item
  ///                    If false will move the last element on the place of removed item
  function removeByIndex(uint256[] storage array, uint256 index, bool keepSorting) internal {
    require(index < array.length, INDEX_OUT_OF_BOUND);

    if (keepSorting) {
      // shift all elements to the place of removed item
      // the loop must not include the last element
      for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
      }
    } else {
      // copy the last address in the array
      array[index] = array[array.length - 1];
    }
    array.pop();
  }

  // -----------------------------------

  /// @dev Find given item in the array and call removeByIndex function if exist. If not throw an error
  function findAndRemove(address[] storage array, address _item, bool keepSorting) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        removeByIndex(array, i, keepSorting);
        return;
      }
    }
    revert(ITEM_NOT_FOUND);
  }

  /// @dev Find given item in the array and call removeByIndex function if exist. If not throw an error
  function findAndRemove(uint256[] storage array, uint256 _item, bool keepSorting) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        removeByIndex(array, i, keepSorting);
        return;
      }
    }
    revert(ITEM_NOT_FOUND);
  }

  // -----------------------------------

  /// @dev Call findAndRemove function for given item array
  function findAndRemoveArray(address[] storage array, address[] memory _items, bool keepSorting) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      findAndRemove(array, _items[i], keepSorting);
    }
  }

  /// @dev Call findAndRemove function for given item array
  function findAndRemoveArray(uint256[] storage array, uint256[] memory _items, bool keepSorting) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      findAndRemove(array, _items[i], keepSorting);
    }
  }

  // -----------------------------------

  /// @dev Remove from array the item with given id and move the last item on it place
  ///      Use with mapping for keeping indexes in correct ordering
  function removeIndexed(
    uint256[] storage array,
    mapping(uint256 => uint256) storage indexes,
    uint256 id
  ) internal {
    uint256 lastId = array[array.length - 1];
    uint256 index = indexes[id];
    indexes[lastId] = index;
    indexes[id] = type(uint256).max;
    array[index] = lastId;
    array.pop();
  }

  // ************* SORTING *******************

  /// @dev Insertion sorting algorithm for using with arrays fewer than 10 elements
  ///      Based on https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
  function sortAddressesByUint(address[] storage addressArray, mapping(address => uint) storage uintMap) internal {
    for (uint i = 1; i < addressArray.length; i++) {
      address key = addressArray[i];
      uint j = i - 1;
      while ((int(j) >= 0) && uintMap[addressArray[j]] > uintMap[key]) {
        addressArray[j + 1] = addressArray[j];
      unchecked {j--;}
      }
    unchecked {
      addressArray[j + 1] = key;
    }
    }
  }

  /// @dev Insertion sorting algorithm for using with arrays fewer than 10 elements
  ///      Based on https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
  function sortAddressesByUintReverted(address[] storage addressArray, mapping(address => uint) storage uintMap) internal {
    for (uint i = 1; i < addressArray.length; i++) {
      address key = addressArray[i];
      uint j = i - 1;
      while ((int(j) >= 0) && uintMap[addressArray[j]] < uintMap[key]) {
        addressArray[j + 1] = addressArray[j];
      unchecked {j--;}
      }
    unchecked {
      addressArray[j + 1] = key;
    }
    }
  }

}

// SPDX-License-Identifier: ISC
/**
 * By using this software, you understand, acknowledge and accept that Tetu
 * and/or the underlying software are provided “as is” and “as available”
 * basis and without warranties or representations of any kind either expressed
 * or implied. Any use of this open source software released under the ISC
 * Internet Systems Consortium license is done at your own risk to the fullest
 * extent permissible pursuant to applicable law any and all liability as well
 * as all warranties, including any fitness for a particular purpose with respect
 * to Tetu and/or the underlying software and the use thereof are disclaimed.
 */
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../governance/Controllable.sol";
import "../interfaces/IStrategySplitter.sol";
import "../interfaces/IStrategy.sol";
import "../lib/ArrayLib.sol";
/// @title Proxy solution for connection a vault with multiple strategies
/// @dev Should be used with TetuProxyControlled.sol
/// @author belbix
contract StrategySplitter is IStrategySplitter, Initializable, OwnableUpgradeable {
  using SafeERC20 for IERC20;
  using ArrayLib for address[];

  // ************ VARIABLES **********************
  uint internal constant _PRECISION = 1e18;
  uint public constant STRATEGY_RATIO_DENOMINATOR = 100;
  uint public constant WITHDRAW_REQUEST_TIMEOUT = 1 hours;
  uint internal constant _MIN_OP = 1;

  // user accounts
  address public controller;

  address[] public strategies;
  address public underlying;
  address public vault;
  uint public needRebalance;
  uint public wantToWithdraw;
  bool public onPause;
  mapping(address => uint) public override strategiesRatios;
  mapping(address => uint) public override withdrawRequestsCalls;

  // ***************** EVENTS ********************
  event StrategyAdded(address strategy);
  event StrategyRemoved(address strategy);
  event StrategyRatioChanged(address strategy, uint ratio);
  event RequestWithdraw(address user, uint amount, uint time);
  event Salvage(address recipient, address token, uint256 amount);
  event RebalanceAll(uint underlyingBalance, uint strategiesBalancesSum);
  event Rebalance(address strategy);

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  ///      Initialize Controllable with sender address
  function initialize(address _controller, address _underlying, address __vault) external initializer {
    controller = _controller;
    underlying = _underlying;
    vault = __vault;

    __Ownable_init();
  }

  modifier restricted() {
    require(msg.sender == vault, "!vault");
    _;
  }

  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  modifier onlyControllerAndVault() {
    require(msg.sender == controller || msg.sender == vault, "!controller");
    _;
  }

  function addStrategy(address _strategy) external override onlyController {
    require(IStrategy(_strategy).underlying() == underlying, "Wrong underlying");
    strategies.addUnique(_strategy);
    emit StrategyAdded(_strategy);
  }

  /// @dev Remove given strategy, reset the ratio and withdraw all underlying to this contract
  function removeStrategy(address _strategy) external override onlyController {
    require(strategies.length > 1, "Can't remove last strategy");
    strategies.findAndRemove(_strategy, true);
    uint ratio = strategiesRatios[_strategy];
    strategiesRatios[_strategy] = 0;
    if (ratio != 0) {
      address strategyWithHighestRatio = strategies[0];
      strategiesRatios[strategyWithHighestRatio] = ratio + strategiesRatios[strategyWithHighestRatio];
      strategies.sortAddressesByUintReverted(strategiesRatios);
    }
    IERC20(underlying).safeApprove(_strategy, 0);
    // for expensive strategies should be called before removing
    IStrategy(_strategy).withdrawAll(address(this));
    transferAllUnderlyingToVault();
    emit StrategyRemoved(_strategy);
  }

  function setStrategyRatios(address[] memory _strategies, uint[] memory _ratios) external override onlyOwner {
    require(_strategies.length == strategies.length, "Wrong input strategies");
    require(_strategies.length == _ratios.length, "Wrong input arrays");
    uint sum;
    for (uint i; i < _strategies.length; i++) {
      bool exist = false;
      for (uint j; j < strategies.length; j++) {
        if (strategies[j] == _strategies[i]) {
          exist = true;
          break;
        }
      }
      require(exist, "Strategy not exist");
      sum += _ratios[i];
      strategiesRatios[_strategies[i]] = _ratios[i];
      emit StrategyRatioChanged(_strategies[i], _ratios[i]);
    }
    require(sum == STRATEGY_RATIO_DENOMINATOR, "Wrong sum");

    // sorting strategies by ratios
    strategies.sortAddressesByUintReverted(strategiesRatios);
  }

  function strategiesInited() external view override returns (bool) {
    uint sum;
    for (uint i; i < strategies.length; i++) {
      sum += strategiesRatios[strategies[i]];
    }
    return sum == STRATEGY_RATIO_DENOMINATOR;
  }

  /// @dev Try to withdraw all from all strategies. May be too expensive to handle in one tx
  function withdrawAllToVault() external override onlyController {
    for (uint i = 0; i < strategies.length; i++) {
      IStrategy(strategies[i]).withdrawAll(address(this));
    }
    transferAllUnderlyingToVault();
  }

  function emergencyExit() external override restricted {
    transferAllUnderlyingToVault();
    onPause = true;
  }

  /// @dev Cascade withdraw from strategies start from with higher ratio until reach the target amount.
  ///      For large amounts with multiple strategies may not be possible to process this function.
  function withdrawToVault(uint256 amount) external override onlyControllerAndVault {
    uint uBalance = IERC20(underlying).balanceOf(address(this));
    if (uBalance < amount) {
      for (uint i; i < strategies.length; i++) {
        IStrategy strategy = IStrategy(strategies[i]);
        uint strategyBalance = strategy.investedUnderlyingBalance();
        if (strategyBalance <= amount) {
          strategy.withdrawAll(address(this));
        } else {
          if (amount > _MIN_OP) {
            strategy.withdraw(address(this), amount);
          }
        }
        uBalance = IERC20(underlying).balanceOf(address(this));
        if (uBalance >= amount) {
          break;
        }
      }
    }
    transferAllUnderlyingToVault();
  }

  function doHardWork() external override {
    for (uint i = 0; i < strategies.length; i++) {
      IStrategy(strategies[i]).earn();
    }
  }

  function investAllUnderlying() external {
    rebalanceAll();
  }

  function rebalanceAll() public {
    require(msg.sender == controller || msg.sender == vault, "Forbidden");
    require(!onPause, "SS: Paused");
    needRebalance = 0;
    // collect balances sum
    uint _underlyingBalance = IERC20(underlying).balanceOf(address(this));
    uint _strategiesBalancesSum = _underlyingBalance;
    for (uint i = 0; i < strategies.length; i++) {
      _strategiesBalancesSum += IStrategy(strategies[i]).investedUnderlyingBalance();
    }
    if (_strategiesBalancesSum == 0) {
      return;
    }
    // rebalance only strategies requires withdraw
    // it will move necessary amount to this contract
    for (uint i = 0; i < strategies.length; i++) {
      uint _ratio = strategiesRatios[strategies[i]] * _PRECISION;
      if (_ratio == 0) {
        continue;
      }
      uint _strategyBalance = IStrategy(strategies[i]).investedUnderlyingBalance();
      uint _currentRatio = (_strategyBalance * _PRECISION * STRATEGY_RATIO_DENOMINATOR) / _strategiesBalancesSum;
      if (_currentRatio > _ratio) {
        // not necessary update underlying balance for withdraw
        _rebalanceCall(strategies[i], _strategiesBalancesSum, _strategyBalance, _ratio);
      }
    }

    // rebalance only strategies requires deposit
    for (uint i = 0; i < strategies.length; i++) {
      uint _ratio = strategiesRatios[strategies[i]] * _PRECISION;
      if (_ratio == 0) {
        continue;
      }
      uint _strategyBalance = IStrategy(strategies[i]).investedUnderlyingBalance();
      uint _currentRatio = (_strategyBalance * _PRECISION * STRATEGY_RATIO_DENOMINATOR) / _strategiesBalancesSum;
      if (_currentRatio < _ratio) {
        _rebalanceCall(strategies[i], _strategiesBalancesSum, _strategyBalance, _ratio);
      }
    }
    emit RebalanceAll(_underlyingBalance, _strategiesBalancesSum);
  }

  /// @dev External function for calling rebalance for exact strategy
  ///      Strategies that need withdraw action should be called first
  function rebalance(address _strategy) external onlyController {
    require(!onPause, "SS: Paused");
    needRebalance = 0;
    _rebalance(_strategy);
    emit Rebalance(_strategy);
  }

  /// @dev Deposit or withdraw from given strategy according the strategy ratio
  ///      Should be called from EAO with multiple off-chain steps
  function _rebalance(address _strategy) internal {
    // normalize ratio to 18 decimals
    uint _ratio = strategiesRatios[_strategy] * _PRECISION;
    // in case of unknown strategy will be reverted here
    require(_ratio != 0, "SS: Zero ratio strategy");
    uint _strategyBalance;
    uint _strategiesBalancesSum = IERC20(underlying).balanceOf(address(this));
    // collect strategies balances sum with some tricks for gas optimisation
    for (uint i = 0; i < strategies.length; i++) {
      uint balance = IStrategy(strategies[i]).investedUnderlyingBalance();
      if (strategies[i] == _strategy) {
        _strategyBalance = balance;
      }
      _strategiesBalancesSum += balance;
    }

    _rebalanceCall(_strategy, _strategiesBalancesSum, _strategyBalance, _ratio);
  }

  ///@dev Deposit or withdraw from strategy
  function _rebalanceCall(address _strategy, uint _strategiesBalancesSum, uint _strategyBalance, uint _ratio) internal {
    uint _currentRatio = (_strategyBalance * _PRECISION * STRATEGY_RATIO_DENOMINATOR) / _strategiesBalancesSum;
    if (_currentRatio < _ratio) {
      // Need to deposit to the strategy.
      // We are calling investAllUnderlying() because we anyway will spend similar gas
      // in case of withdraw, and we can't predict what will need.
      uint needToDeposit = (_strategiesBalancesSum * (_ratio - _currentRatio)) /
        (STRATEGY_RATIO_DENOMINATOR * _PRECISION);
      uint _underlyingBalance = IERC20(underlying).balanceOf(address(this));
      needToDeposit = Math.min(needToDeposit, _underlyingBalance);
      //      require(_underlyingBalance >= needToDeposit, "SS: Not enough splitter balance");
      if (needToDeposit > _MIN_OP) {
        IERC20(underlying).safeTransfer(_strategy, needToDeposit);
        IStrategy(_strategy).investAllUnderlying();
      }
    } else if (_currentRatio > _ratio) {
      // withdraw from strategy excess value
      uint needToWithdraw = (_strategiesBalancesSum * (_currentRatio - _ratio)) /
        (STRATEGY_RATIO_DENOMINATOR * _PRECISION);
      needToWithdraw = Math.min(needToWithdraw, _strategyBalance);
      //      require(_strategyBalance >= needToWithdraw, "SS: Not enough strat balance");
      if (needToWithdraw > _MIN_OP) {
        IStrategy(_strategy).withdrawToVault(needToWithdraw);
      }
    }
  }

  /// @dev Change rebalance marker
  function setNeedRebalance(uint _value) external onlyController {
    require(_value < 2, "SS: Wrong value");
    needRebalance = _value;
  }

  /// @dev Stop deposit to strategies
  function pauseInvesting() external override restricted {
    onPause = true;
  }

  /// @dev Continue deposit to strategies
  function continueInvesting() external override restricted {
    onPause = false;
  }

  function transferAllUnderlyingToVault() internal {
    uint balance = IERC20(underlying).balanceOf(address(this));
    if (balance > 0) {
      IERC20(underlying).safeTransfer(vault, balance);
    }
  }

  // **************** VIEWS ***************

  /// @dev Return array of reward tokens collected across all strategies.
  ///      Has random sorting
  function strategyRewardTokens() external view override returns (address[] memory) {
    return _strategyRewardTokens();
  }

  function _strategyRewardTokens() internal view returns (address[] memory) {
    address[] memory rts = new address[](20);
    uint size = 0;
    for (uint i = 0; i < strategies.length; i++) {
      address[] memory strategyRts;
      if (IStrategy(strategies[i]).platform() == IStrategy.Platform.STRATEGY_SPLITTER) {
        strategyRts = IStrategySplitter(strategies[i]).strategyRewardTokens();
      } else {
        strategyRts = IStrategy(strategies[i]).rewardTokens();
      }
      for (uint j = 0; j < strategyRts.length; j++) {
        address rt = strategyRts[j];
        bool exist = false;
        for (uint k = 0; k < rts.length; k++) {
          if (rts[k] == rt) {
            exist = true;
            break;
          }
        }
        if (!exist) {
          rts[size] = rt;
          size++;
        }
      }
    }
    address[] memory result = new address[](size);
    for (uint i = 0; i < size; i++) {
      result[i] = rts[i];
    }
    return result;
  }

  /// @dev Splitter underlying balance
  function underlyingBalance() external view override returns (uint256) {
    return IERC20(underlying).balanceOf(address(this));
  }

  /// @dev Return strategies balances. Doesn't include splitter underlying balance
  function rewardPoolBalance() external view override returns (uint256) {
    uint balance;
    for (uint i = 0; i < strategies.length; i++) {
      balance += IStrategy(strategies[i]).investedUnderlyingBalance();
    }
    return balance;
  }

  /// @dev Return average buyback ratio
  function buyBackRatio() external view override returns (uint256) {
    uint bbRatio = 0;
    for (uint i = 0; i < strategies.length; i++) {
      bbRatio += IStrategy(strategies[i]).buyBackRatio();
    }
    bbRatio = bbRatio / strategies.length;
    return bbRatio;
  }

  /// @dev Check unsalvageable tokens across all strategies
  function unsalvageableTokens(address token) external view override returns (bool) {
    for (uint i = 0; i < strategies.length; i++) {
      if (IStrategy(strategies[i]).unsalvageableTokens(token)) {
        return true;
      }
    }
    return false;
  }

  /// @dev Return a sum of all balances under control. Should be accurate - it will be used in the vault
  function investedUnderlyingBalance() external view override returns (uint256) {
    return _investedUnderlyingBalance();
  }

  function _investedUnderlyingBalance() internal view returns (uint256) {
    uint balance = IERC20(underlying).balanceOf(address(this));
    for (uint i = 0; i < strategies.length; i++) {
      balance += IStrategy(strategies[i]).investedUnderlyingBalance();
    }
    return balance;
  }

  /// @dev Splitter has specific hardcoded platform
  function platform() external pure returns (Platform) {
    return Platform.STRATEGY_SPLITTER;
  }

  /// @dev Assume that we will use this contract only for single token vaults
  function assets() external view override returns (address[] memory) {
    address[] memory result = new address[](1);
    result[0] = underlying;
    return result;
  }

  /// @dev Return ready to claim rewards array
  function readyToClaim() external view override returns (uint256[] memory) {
    uint[] memory rewards = new uint[](20);
    address[] memory rts = new address[](20);
    uint size = 0;
    for (uint i = 0; i < strategies.length; i++) {
      address[] memory strategyRts;
      if (IStrategy(strategies[i]).platform() == IStrategy.Platform.STRATEGY_SPLITTER) {
        strategyRts = IStrategySplitter(strategies[i]).strategyRewardTokens();
      } else {
        strategyRts = IStrategy(strategies[i]).rewardTokens();
      }

      uint[] memory strategyReadyToClaim = IStrategy(strategies[i]).readyToClaim();
      // don't count, better to skip than ruin
      if (strategyRts.length != strategyReadyToClaim.length) {
        continue;
      }
      for (uint j = 0; j < strategyRts.length; j++) {
        address rt = strategyRts[j];
        bool exist = false;
        for (uint k = 0; k < rts.length; k++) {
          if (rts[k] == rt) {
            exist = true;
            rewards[k] += strategyReadyToClaim[j];
            break;
          }
        }
        if (!exist) {
          rts[size] = rt;
          rewards[size] = strategyReadyToClaim[j];
          size++;
        }
      }
    }
    uint[] memory result = new uint[](size);
    for (uint i = 0; i < size; i++) {
      result[i] = rewards[i];
    }
    return result;
  }

  /// @dev Return sum of strategies poolTotalAmount values
  function poolTotalAmount() external view override returns (uint256) {
    uint balance = 0;
    for (uint i = 0; i < strategies.length; i++) {
      balance += IStrategy(strategies[i]).poolTotalAmount();
    }
    return balance;
  }

  /// @dev Return maximum available balance to withdraw without calling more than 1 strategy
  function maxCheapWithdraw() external view override returns (uint) {
    uint strategyBalance;
    if (strategies.length != 0) {
      if (IStrategy(strategies[0]).platform() == IStrategy.Platform.STRATEGY_SPLITTER) {
        strategyBalance = IStrategySplitter(strategies[0]).maxCheapWithdraw();
      } else {
        strategyBalance = IStrategy(strategies[0]).investedUnderlyingBalance();
      }
    }
    return strategyBalance + IERC20(underlying).balanceOf(address(this)) + IERC20(underlying).balanceOf(vault);
  }

  /// @dev Length of strategy array
  function strategiesLength() external view override returns (uint) {
    return strategies.length;
  }

  /// @dev Returns strategy array
  function allStrategies() external view override returns (address[] memory) {
    return strategies;
  }

  /// @dev Simulate vault behaviour - returns vault total supply
  function totalSupply() external view returns (uint256) {
    return IERC20(vault).totalSupply();
  }

  function createdBlock() external view returns (uint256) {}
}