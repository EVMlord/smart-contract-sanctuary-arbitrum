// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IToken.sol";
import "./interfaces/IVaultDelegator.sol";

/// @title Base Delegator
/// @author Christopher Enytc <[email protected]>
/// @notice You can use this contract for deploying new delegators
/// @dev All function calls are currently implemented
/// @custom:security-contact [email protected]
abstract contract BaseDelegator is Ownable, ReentrancyGuard, IVaultDelegator {
  IERC20 private immutable _asset;
  address private immutable _integrationContract;

  address private _linkedVault;

  uint256 private _claimableThreshold;

  bool private _linkedVaultLocked;

  /**
   * @dev Set the underlying asset contract. This must be an ERC20 contract.
   */
  constructor(IERC20 asset_, address integrationContractAddress_) {
    require(
      integrationContractAddress_ != address(0),
      "BaseDelegator: integrationContract_ cannot be address 0"
    );

    _asset = asset_;
    _integrationContract = integrationContractAddress_;

    _claimableThreshold = 1;

    _linkedVaultLocked = false;

    emit ClaimableThresholdUpdated(_claimableThreshold);
  }

  /// @notice Checks if sender is the linked vault
  modifier onlyLinkedVault() {
    require(msg.sender == _linkedVault, "BaseDelegator: Not linked vault");
    _;
  }

  /// @notice Get the underlying asset
  /// @dev Used to get the address of the asset that was configured on deploy
  /// @return Address of the underlying asset
  function asset() public view returns (address) {
    return address(_asset);
  }

  /// @notice Get the underlying contract
  /// @dev Used to get address of the integration contract that was configured on deploy
  /// @return Address of the underlying integration contract
  function underlyingContract() public view returns (address) {
    return _integrationContract;
  }

  /// @notice Get linked vault
  /// @dev Used to get address of the vault that is linked with the delegator
  /// @return Address of the vault contract
  function linkedVault() public view returns (address) {
    return _linkedVault;
  }

  /// @notice Set linked vault
  /// @dev Used to permanently set the vault of this delegator
  /// @param vault Address of the vault to be linked
  function setLinkedVault(address vault) external onlyOwner {
    require(vault != address(0), "BaseDelegator: vault cannot be address 0");

    require(
      !_linkedVaultLocked,
      "BaseDelegator: Cannot set another linked vault after the first time"
    );

    _linkedVault = vault;
    _linkedVaultLocked = true;

    emit LinkedVaultUpdated(vault);
  }

  /// @notice Get claimable threshold
  /// @dev Used to get the threshold to used for calling claim on accumulated rewards
  /// @return Threshold in notation of the underlying asset
  function claimableThreshold() public view returns (uint256) {
    return _claimableThreshold;
  }

  /// @notice Set claimable threshold
  /// @dev Used to set the threshold of claims in this delegator
  /// @param threshold Quantity of assets to accumulate before claim
  function setClaimableThreshold(uint256 threshold) external onlyOwner {
    _claimableThreshold = threshold;

    emit ClaimableThresholdUpdated(threshold);
  }

  /// @notice Get delegator name
  /// @dev Used to get the name of the integration used in this delegator
  /// @return Name of the integration
  function delegatorName() external pure virtual returns (string memory) {
    return "base";
  }

  /// @notice Get delegator type
  /// @dev Used to get the type of the integration used in this delegator
  /// @return Type of the integration
  function delegatorType() external pure virtual returns (string memory) {
    return "Delegator";
  }

  /// @notice Get the estimated total assets
  /// @dev Used to get the estimated total of assets deposited in the integration contract
  /// @return Estimated total of assets on the integration contract
  function estimatedTotalAssets() public view virtual returns (uint256) {
    return 0;
  }

  /// @notice Get rewards
  /// @dev Used to get total of rewards accumulated in the integration contract
  /// @return Total amount of assets accumulated
  function rewards() public view virtual returns (uint256) {
    return 0;
  }

  /// @notice Get integration fee for deposits
  /// @dev Used to get the fee charged by the integration contract for deposits
  /// @param amount Amount of assets to apply fee
  /// @return Fee amount charged
  function integrationFeeForDeposits(
    uint256 amount
  ) public view virtual returns (uint256) {
    return amount;
  }

  /// @notice Get integration fee for withdraws
  /// @dev Used to get the fee charged by the integration contract for withdraws
  /// @param amount Amount of assets to apply fee
  /// @return Fee amount charged
  function integrationFeeForWithdraws(
    uint256 amount
  ) public view virtual returns (uint256) {
    return amount;
  }

  /// @notice Check deposit availability
  /// @dev Used to check if deposits can be made to the integration contract
  /// @param amount Amount of assets to check deposit availability
  /// @return Status of the deposit availability
  function depositsAvailable(
    uint256 amount
  ) public view virtual returns (bool) {
    if (amount > 0) {
      return true;
    }

    return false;
  }

  /// @notice Check withdraw availability
  /// @dev Used to check if withdraws can be made from the integration contract
  /// @param amount Amount of assets to check withdraw availability
  /// @return Status of the withdraw availability
  function withdrawsAvailable(
    uint256 amount
  ) public view virtual returns (bool) {
    if (amount > 0) {
      return true;
    }

    return false;
  }

  /// @notice Recover funds
  /// @dev Used to deposit funds to the integration contract
  /// @param amount Quantity of assets to deposit
  function deposit(
    uint256 amount
  ) external virtual onlyLinkedVault nonReentrant returns (uint256) {
    require(
      depositsAvailable(amount),
      "BaseDelegator: Deposits in the delegator are not available right now"
    );

    claim();

    emit Fee(integrationFeeForDeposits(amount));

    emit RequestedDeposit(amount);

    emit Deposited(amount);

    return amount;
  }

  /// @notice Recover funds
  /// @dev Used to withdraw funds from the integration contract
  /// @param amount Quantity of assets to withdraw
  function withdraw(
    uint256 amount
  ) public virtual onlyLinkedVault nonReentrant returns (uint256) {
    require(
      withdrawsAvailable(amount),
      "BaseDelegator: Withdraws from the delegator are not available right now"
    );

    claim();

    SafeERC20.safeTransfer(_asset, _linkedVault, amount);

    emit Fee(integrationFeeForWithdraws(amount));

    emit RequestedWithdraw(amount);

    emit Withdrawn(amount);

    return amount;
  }

  /// @notice Claim rewards
  /// @dev Used to claim rewards accumulated on the integration contract if the claimable threshold has been reached
  function claim() public virtual {
    if (rewards() < claimableThreshold()) {
      return;
    }
  }

  /// @notice Recover funds
  /// @dev Used to withdraw all funds on the integration contract and send back to the vault
  function recoverFunds() external virtual onlyLinkedVault {
    withdraw(estimatedTotalAssets());
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../BaseDelegator.sol";

import "../interfaces/IGlpPriceFeed.sol";

import "../interfaces/integrations/IGlpVault.sol";
import "../interfaces/integrations/IGlpManager.sol";
import "../interfaces/integrations/IGlpRewardRouter.sol";
import "../interfaces/integrations/IGlpRewardReader.sol";

/// @title Gmx Index Delegator
/// @author Christopher Enytc <[email protected]>
/// @dev All functions are derived from the base delegator
/// @custom:security-contact [email protected]
contract GmxIndex is BaseDelegator {
  using Math for uint256;

  address public immutable weth;

  address public immutable rewardReader;

  IGlpPriceFeed public glpPriceFeed;

  /**
   * @dev Set the underlying asset contract. This must be an ERC20 contract.
   */
  constructor(
    IERC20 asset_,
    address indexContract_,
    address rewardReader_,
    address glpPriceFeed_,
    address weth_
  ) BaseDelegator(asset_, indexContract_) {
    require(
      rewardReader_ != address(0),
      "GmxIndex: rewardReader_ cannot be address 0"
    );

    require(
      glpPriceFeed_ != address(0),
      "GmxIndex: glpPriceFeed_ cannot be address 0"
    );

    require(weth_ != address(0), "GmxIndex: weth_ cannot be address 0");

    rewardReader = rewardReader_;

    glpPriceFeed = IGlpPriceFeed(glpPriceFeed_);

    weth = weth_;
  }

  /// @inheritdoc BaseDelegator
  function delegatorName()
    external
    pure
    virtual
    override
    returns (string memory)
  {
    return "gmx";
  }

  /// @inheritdoc BaseDelegator
  function delegatorType()
    external
    pure
    virtual
    override
    returns (string memory)
  {
    return "Index";
  }

  /// @inheritdoc BaseDelegator
  function estimatedTotalAssets()
    public
    view
    virtual
    override
    returns (uint256)
  {
    address[] memory depositTokens = new address[](1);

    depositTokens[0] = IGlpRewardRouter(underlyingContract()).glp();

    address[] memory rewardTrackers = new address[](1);

    rewardTrackers[0] = IGlpRewardRouter(underlyingContract()).feeGlpTracker();

    uint256[] memory amounts = IGlpRewardReader(rewardReader)
      .getDepositBalances(address(this), depositTokens, rewardTrackers);

    uint256 convertedAmount = glpPriceFeed.convertToUSD(amounts[0], false);

    uint8 assetDecimals = IERC20Metadata(asset()).decimals();

    uint256 amountInAsset = convertedAmount / (10 ** (30 - assetDecimals));

    return amountInAsset;
  }

  /// @inheritdoc BaseDelegator
  function rewards() public view virtual override returns (uint256) {
    address[] memory rewardTrackers = new address[](2);

    rewardTrackers[0] = IGlpRewardRouter(underlyingContract())
      .stakedGlpTracker();
    rewardTrackers[1] = IGlpRewardRouter(underlyingContract()).feeGlpTracker();

    uint256[] memory stakingInfo = IGlpRewardReader(rewardReader)
      .getStakingInfo(address(this), rewardTrackers);

    return stakingInfo[0];
  }

  /// @inheritdoc BaseDelegator
  function integrationFeeForDeposits(
    uint256 amount
  ) public view virtual override returns (uint256) {
    return _integrationFee(amount, true);
  }

  /// @inheritdoc BaseDelegator
  function integrationFeeForWithdraws(
    uint256 amount
  ) public view virtual override returns (uint256) {
    return _integrationFee(amount, false);
  }

  /// @dev Get integration fee from protocol integration
  function _integrationFee(
    uint256 amount,
    bool increment
  ) internal view returns (uint256) {
    address vault = IGlpManager(
      IGlpRewardRouter(underlyingContract()).glpManager()
    ).vault();

    uint256 price = IGlpVault(vault).getMinPrice(asset());

    uint256 usdgAmount = amount.mulDiv(
      price,
      IGlpVault(vault).PRICE_PRECISION()
    );

    usdgAmount = IGlpVault(vault).adjustForDecimals(
      usdgAmount,
      asset(),
      IGlpVault(vault).usdg()
    );

    uint256 feeBasisPoints = IGlpVault(vault).getFeeBasisPoints(
      asset(),
      usdgAmount,
      IGlpVault(vault).mintBurnFeeBasisPoints(),
      IGlpVault(vault).taxBasisPoints(),
      increment
    );

    return feeBasisPoints;
  }

  /// @inheritdoc BaseDelegator
  function depositsAvailable(
    uint256
  ) public view virtual override returns (bool) {
    return true;
  }

  /// @inheritdoc BaseDelegator
  function withdrawsAvailable(
    uint256
  ) public view virtual override returns (bool) {
    return true;
  }

  /// @inheritdoc BaseDelegator
  function deposit(
    uint256 amount
  ) external virtual override onlyLinkedVault nonReentrant returns (uint256) {
    require(
      depositsAvailable(amount),
      "GmxIndex: Deposits in the delegator are not available right now"
    );

    uint256 fee = integrationFeeForDeposits(amount);

    claim();

    SafeERC20.safeTransferFrom(
      IERC20(asset()),
      msg.sender,
      address(this),
      amount
    );

    address glpManager = IGlpRewardRouter(underlyingContract()).glpManager();

    // Approve integration to spend balance from delegator
    SafeERC20.safeIncreaseAllowance(IERC20(asset()), glpManager, amount);

    uint256 glpAmount = glpPriceFeed.convertToGLP(asset(), amount, true);

    uint256 minGlpAmount = glpPriceFeed.getMinPrice(glpAmount);

    uint256 receivedAmount = IGlpRewardRouter(underlyingContract())
      .mintAndStakeGlp(asset(), amount, 0, minGlpAmount);

    emit Fee(fee);

    emit RequestedDeposit(amount);

    emit Deposited(receivedAmount);

    return receivedAmount;
  }

  /// @inheritdoc BaseDelegator
  function withdraw(
    uint256 amount
  ) public virtual override onlyLinkedVault nonReentrant returns (uint256) {
    require(
      withdrawsAvailable(amount),
      "GmxIndex: Withdraws in the delegator are not available right now"
    );

    uint256 fee = integrationFeeForWithdraws(amount);

    claim();

    uint256 glpAmount = glpPriceFeed.convertToGLP(asset(), amount, false);

    uint256 minTokenOut = glpPriceFeed.getMinPrice(amount);

    uint256 receivedAmount = IGlpRewardRouter(underlyingContract())
      .unstakeAndRedeemGlp(asset(), glpAmount, minTokenOut, linkedVault());

    emit Fee(fee);

    emit RequestedWithdraw(amount);

    emit Withdrawn(receivedAmount);

    return receivedAmount;
  }

  /// @inheritdoc BaseDelegator
  function claim() public virtual override {
    if (rewards() < claimableThreshold()) {
      return;
    }

    IGlpRewardRouter(underlyingContract()).compound();

    uint256 claimedRewards = address(this).balance;

    uint256 glpAmount = glpPriceFeed.convertToGLP(
      address(0),
      claimedRewards,
      true
    );

    uint256 minGlpAmount = glpPriceFeed.getMinPrice(glpAmount);

    // slither-disable-start unused-return
    IGlpRewardRouter(underlyingContract()).mintAndStakeGlpETH{
      value: claimedRewards
    }(0, minGlpAmount);
    // slither-disable-end unused-return
  }

  /// @notice Set glp price feed
  /// @dev Used to set the glp price feed of this delegator
  /// @param priceFeed Address of the glp price feed
  function setPriceFeed(address priceFeed) external onlyOwner {
    require(priceFeed != address(0), "GmxIndex: priceFeed cannot be address 0");

    glpPriceFeed = IGlpPriceFeed(priceFeed);
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

interface IGlpPriceFeed {
  function getPrice(bool maximise) external view returns (uint256 price);

  function convertToUSD(
    uint256 amount,
    bool maximise
  ) external view returns (uint256);

  function convertToGLP(
    address asset,
    uint256 amount,
    bool maximise
  ) external view returns (uint256);

  function getMinPrice(uint256 amount) external pure returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

interface IGlpManager {
  function getPrice(bool _maximise) external view returns (uint256);

  function vault() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

interface IGlpRewardReader {
  function getDepositBalances(
    address _account,
    address[] memory _depositTokens,
    address[] memory _rewardTrackers
  ) external view returns (uint256[] memory);

  function getStakingInfo(
    address _account,
    address[] memory _rewardTrackers
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

interface IGlpRewardRouter {
  function feeGlpTracker() external view returns (address);

  function stakedGlpTracker() external view returns (address);

  function glpManager() external view returns (address);

  function glp() external view returns (address);

  function mintAndStakeGlp(
    address _token,
    uint256 _amount,
    uint256 _minUsdg,
    uint256 _minGlp
  ) external returns (uint256);

  function unstakeAndRedeemGlp(
    address _tokenOut,
    uint256 _glpAmount,
    uint256 _minOut,
    address _receiver
  ) external returns (uint256);

  function mintAndStakeGlpETH(
    uint256 _minUsdg,
    uint256 _minGlp
  ) external payable returns (uint256);

  function compound() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

interface IGlpVault {
  function BASIS_POINTS_DIVISOR() external view returns (uint256);

  function PRICE_PRECISION() external view returns (uint256);

  function usdg() external view returns (address);

  function taxBasisPoints() external view returns (uint256);

  function mintBurnFeeBasisPoints() external view returns (uint256);

  function getMinPrice(address _token) external view returns (uint256);

  function adjustForDecimals(
    uint256 _amount,
    address _tokenDiv,
    address _tokenMul
  ) external view returns (uint256);

  function getFeeBasisPoints(
    address _token,
    uint256 _usdgDelta,
    uint256 _feeBasisPoints,
    uint256 _taxBasisPoints,
    bool _increment
  ) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

interface IToken {
  function decimals() external view returns (uint8);

  function pause() external;

  function unpause() external;

  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

interface IVaultDelegator {
  event Fee(uint256 amount);
  event RequestedDeposit(uint256 amount);
  event Deposited(uint256 amount);
  event RequestedWithdraw(uint256 amount);
  event Withdrawn(uint256 amount);
  event LinkedVaultUpdated(address indexed vault);
  event ClaimableThresholdUpdated(uint256 threshold);

  function asset() external view returns (address);

  function underlyingContract() external view returns (address);

  function linkedVault() external view returns (address);

  function setLinkedVault(address vault) external;

  function claimableThreshold() external view returns (uint256);

  function setClaimableThreshold(uint256 threshold) external;

  function delegatorName() external pure returns (string memory);

  function delegatorType() external pure returns (string memory);

  function estimatedTotalAssets() external view returns (uint256);

  function rewards() external view returns (uint256);

  function integrationFeeForDeposits(
    uint256 amount
  ) external view returns (uint256);

  function integrationFeeForWithdraws(
    uint256 amount
  ) external view returns (uint256);

  function depositsAvailable(uint256 amount) external view returns (bool);

  function withdrawsAvailable(uint256 amount) external view returns (bool);

  function deposit(uint256 amount) external returns (uint256);

  function withdraw(uint256 amount) external returns (uint256);

  function claim() external;

  function recoverFunds() external;
}