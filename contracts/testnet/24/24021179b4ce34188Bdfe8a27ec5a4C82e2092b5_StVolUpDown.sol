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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract StVol is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token; // Prediction token

    IPyth public oracle;

    bool public genesisOpenOnce = false;
    bool public genesisStartOnce = false;

    bytes32 public priceId; // address of the pyth price
    address public adminAddress; // address of the admin
    address public operatorAddress; // address of the operator
    address public operatorVaultAddress; // address of the operator vault

    uint256 public bufferSeconds; // number of seconds for valid execution of a participate round
    uint256 public intervalSeconds; // interval in seconds between two participate rounds

    uint256 public minParticipateAmount; // minimum participate amount (denominated in wei)
    uint256 public commissionfee; // commission rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // treasury amount that was not claimed
    uint256 public operateRate; // operate distribute rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public participantRate; // participant distribute rate (e.g. 200 = 2%, 150 = 1.50%)
    int256 public strategyRate; // strategy rate (e.g. 100 = 1%)
    StrategyType public strategyType; // strategy type

    uint256 public currentEpoch; // current epoch for round

    uint256 public constant BASE = 10000; // 100%
    uint256 public constant MAX_COMMISSION_FEE = 200; // 2%

    uint256 public constant DEFAULT_MIN_PARTICIPATE_AMOUNT = 1000000; // 1 USDC
    uint256 public constant DEFAULT_INTERVAL_SECONDS = 86400; // 24 * 60 * 60 * 1(1day)
    uint256 public constant DEFAULT_BUFFER_SECONDS = 600; // 60 * 10 (10min)
    uint256 public lastCommittedPublishTime; // time when the last committed update was published to Pyth

    struct LimitOrder {
        address user;
        uint256 payout;
        uint256 amount;
        uint256 blockTimestamp;
        LimitOrderStatus status;
    }

    enum LimitOrderStatus {
        Undeclared,
        Approve
    }

    mapping(uint256 => LimitOrder[]) public overLimitOrders;
    mapping(uint256 => LimitOrder[]) public underLimitOrders;
    mapping(uint256 => mapping(Position => mapping(address => ParticipateInfo)))
        public ledger;
    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[]) public userRounds;

    enum Position {
        Over,
        Under
    }

    enum StrategyType {
        None,
        Up,
        Down
    }

    struct Round {
        uint256 epoch;
        uint256 openTimestamp;
        uint256 startTimestamp;
        uint256 closeTimestamp;
        int256 startPrice;
        int256 closePrice;
        uint256 startOracleId;
        uint256 closeOracleId;
        uint256 totalAmount;
        uint256 overAmount;
        uint256 underAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
    }

    struct ParticipateInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    struct RoundAmount {
        uint256 totalAmount;
        uint256 overAmount;
        uint256 underAmount;
    }

    event ParticipateUnder(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount
    );
    event ParticipateOver(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount
    );
    event ParticipateLimitOver(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount,
        uint256 payout
    );
    event ParticipateLimitUnder(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount,
        uint256 payout
    );
    event Claim(
        address indexed sender,
        uint256 indexed epoch,
        Position position,
        uint256 amount
    );
    event EndRound(uint256 indexed epoch, int256 price);
    event StartRound(uint256 indexed epoch, int256 price);
    event NewAdminAddress(address admin);
    event NewBufferAndIntervalSeconds(
        uint256 bufferSeconds,
        uint256 intervalSeconds
    );
    event NewMinParticipateAmount(
        uint256 indexed epoch,
        uint256 minParticipateAmount
    );
    event NewCommissionfee(uint256 indexed epoch, uint256 commissionfee);
    event NewOperatorAddress(address operator);
    event NewOperatorVaultAddress(address operatorVault);
    event NewOracle(address oracle);

    event Pause(uint256 indexed epoch);
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );

    event OpenRound(
        uint256 indexed epoch,
        int256 strategyRate,
        StrategyType strategyType
    );
    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);
    event Unpause(uint256 indexed epoch);

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(
            msg.sender == adminAddress || msg.sender == operatorAddress,
            "Not operator/admin"
        );
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     * @notice Constructor
     * @param _token: prediction token
     * @param _oracleAddress: oracle address
     * @param _adminAddress: admin address
     * @param _operatorAddress: operator address
     * @param _operatorVaultAddress: operator vault address
     * @param _commissionfee: commission fee (1000 = 10%)
     * @param _operateRate: operate rate (10000 = 100%)
     * @param _strategyRate: strategy rate (100 = 1%)
     * @param _strategyType: strategy type
     * @param _priceId: pyth price address
     */
    constructor(
        address _token,
        address _oracleAddress,
        address _adminAddress,
        address _operatorAddress,
        address _operatorVaultAddress,
        uint256 _commissionfee,
        uint256 _operateRate,
        int256 _strategyRate,
        StrategyType _strategyType,
        bytes32 _priceId
    ) {
        require(
            _commissionfee <= MAX_COMMISSION_FEE,
            "Commission fee too high"
        );
        if (_strategyRate > 0) {
            require(
                _strategyType != StrategyType.None,
                "Strategy Type must be Up or Down"
            );
        } else {
            require(
                _strategyType == StrategyType.None,
                "Strategy Type must be None"
            );
        }

        token = IERC20(_token);
        oracle = IPyth(_oracleAddress);
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        operatorVaultAddress = _operatorVaultAddress;
        commissionfee = _commissionfee;
        operateRate = _operateRate;
        strategyRate = _strategyRate;
        strategyType = _strategyType;
        priceId = _priceId;

        intervalSeconds = DEFAULT_INTERVAL_SECONDS;
        bufferSeconds = DEFAULT_BUFFER_SECONDS;
        minParticipateAmount = DEFAULT_MIN_PARTICIPATE_AMOUNT;
    }

    /**
     * @notice Participate under position
     * @param epoch: epoch
     */
    function participateUnder(
        uint256 epoch,
        uint256 _amount
    ) external whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch, "Participate is too early/late");
        require(_participable(epoch), "Round not participable");
        require(
            _amount >= minParticipateAmount,
            "Participate amount must be greater than minParticipateAmount"
        );

        token.safeTransferFrom(msg.sender, address(this), _amount);
        _participate(epoch, Position.Under, msg.sender, _amount);
    }

    /**
     * @notice Participate over position
     * @param epoch: epoch
     */
    function participateOver(
        uint256 epoch,
        uint256 _amount
    ) external whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch, "Participate is too early/late");
        require(_participable(epoch), "Round not participable");
        require(
            _amount >= minParticipateAmount,
            "Participate amount must be greater than minParticipateAmount"
        );

        token.safeTransferFrom(msg.sender, address(this), _amount);
        _participate(epoch, Position.Over, msg.sender, _amount);
    }

    /**
     * @notice Claim reward for an epoch
     * @param epoch: epoch
     */
    function claim(
        uint256 epoch,
        Position position
    ) external nonReentrant notContract {
        uint256 reward; // Initializes reward

        require(rounds[epoch].openTimestamp != 0, "Round has not started");
        require(
            block.timestamp > rounds[epoch].closeTimestamp,
            "Round has not ended"
        );

        uint256 addedReward = 0;

        // Round valid, claim rewards
        if (rounds[epoch].oracleCalled) {
            require(
                claimable(epoch, position, msg.sender),
                "Not eligible for claim"
            );
            Round memory round = rounds[epoch];
            if (
                (round.overAmount > 0 && round.underAmount > 0) &&
                (round.startPrice != round.closePrice)
            ) {
                addedReward +=
                    (ledger[epoch][position][msg.sender].amount *
                        round.rewardAmount) /
                    round.rewardBaseCalAmount;
            } else {
                // no winner
            }
        } else {
            // Round invalid, refund Participate amount
            require(
                refundable(epoch, position, msg.sender),
                "Not eligible for refund"
            );
        }
        ledger[epoch][position][msg.sender].claimed = true;
        reward = ledger[epoch][position][msg.sender].amount + addedReward;

        emit Claim(msg.sender, epoch, position, reward);

        if (reward > 0) {
            token.safeTransfer(msg.sender, reward);
        }
    }

    /**
     * @notice Claim all reward for user
     */
    function claimAll() external nonReentrant notContract {
        _trasferReward(msg.sender);
    }

    /**
     * @notice redeem all assets
     * @dev Callable by admin
     */
    function redeemAll(address _user) external whenPaused onlyAdmin {
        _trasferReward(_user);
    }

    /**
     * @notice Open the next round n, lock price for round n-1, end round n-2
     * @dev Callable by operator
     */
    function executeRound(
        bytes[] calldata priceUpdateData,
        uint64 initDate,
        bool isFixed
    ) external payable whenNotPaused onlyOperator {
        require(
            genesisOpenOnce && genesisStartOnce,
            "Can only run after genesisOpenRound and genesisStartRound is triggered"
        );

        (int64 pythPrice, uint publishTime) = _getPythPrice(
            priceUpdateData,
            initDate,
            isFixed
        );
        require(
            publishTime > lastCommittedPublishTime,
            "Pyth Oracle non increasing publishTimes"
        );
        lastCommittedPublishTime = publishTime;

        // CurrentEpoch refers to previous round (n-1)
        _safeStartRound(currentEpoch, pythPrice);
        _placeLimitOrders(currentEpoch);
        _safeEndRound(currentEpoch - 1, pythPrice);
        _calculateRewards(currentEpoch - 1);

        // Increment currentEpoch to current round (n)
        currentEpoch = currentEpoch + 1;
        _safeOpenRound(currentEpoch, initDate);
    }

    function _getPythPrice(
        bytes[] memory priceUpdateData,
        uint64 fixedTimestamp,
        bool isFixed
    ) internal returns (int64, uint) {
        bytes32[] memory pythPair = new bytes32[](1);
        pythPair[0] = priceId;

        uint fee = oracle.getUpdateFee(priceUpdateData);
        if (isFixed) {
            oracle.parsePriceFeedUpdates{value: fee}(
                priceUpdateData,
                pythPair,
                fixedTimestamp,
                fixedTimestamp + 10
            );
        } else {
            oracle.updatePriceFeeds{value: fee}(priceUpdateData);
        }
        PythStructs.Price memory pythPrice = oracle.getPrice(priceId);
        return (pythPrice.price, pythPrice.publishTime);
    }

    /**
     * @notice Start genesis round
     * @dev Callable by operator
     */
    function genesisStartRound(
        bytes[] calldata priceUpdateData,
        uint64 initDate,
        bool isFixed
    ) external payable whenNotPaused onlyOperator {
        require(
            genesisOpenOnce,
            "Can only run after genesisOpenRound is triggered"
        );
        require(!genesisStartOnce, "Can only run genesisStartRound once");

        (int64 pythPrice, uint publishTime) = _getPythPrice(
            priceUpdateData,
            initDate,
            isFixed
        );
        require(
            publishTime > lastCommittedPublishTime,
            "Pyth Oracle non increasing publishTimes"
        );
        lastCommittedPublishTime = publishTime;

        _safeStartRound(currentEpoch, pythPrice);
        _placeLimitOrders(currentEpoch);

        currentEpoch = currentEpoch + 1;
        _openRound(currentEpoch, initDate);
        genesisStartOnce = true;
    }

    /**
     * @notice Open genesis round
     * @dev Callable by admin or operator
     */
    function genesisOpenRound(
        uint256 initDate
    ) external whenNotPaused onlyOperator {
        require(!genesisOpenOnce, "Can only run genesisOpenRound once");

        currentEpoch = currentEpoch + 1;
        _openRound(currentEpoch, initDate);
        genesisOpenOnce = true;
    }

    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external whenNotPaused onlyAdminOrOperator {
        _pause();
        emit Pause(currentEpoch);
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;

        // operator 100%
        token.safeTransfer(
            operatorVaultAddress,
            (currentTreasuryAmount * operateRate) / BASE
        );

        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     * @dev Callable by admin or operator
     */
    function unpause() external whenPaused onlyAdminOrOperator {
        genesisOpenOnce = false;
        genesisStartOnce = false;
        _unpause();

        emit Unpause(currentEpoch);
    }

    /**
     * @notice Set buffer and interval (in seconds)
     * @dev Callable by admin
     */
    function setBufferAndIntervalSeconds(
        uint256 _bufferSeconds,
        uint256 _intervalSeconds
    ) external whenPaused onlyAdmin {
        require(
            _bufferSeconds < _intervalSeconds,
            "bufferSeconds must be inferior to intervalSeconds"
        );
        bufferSeconds = _bufferSeconds;
        intervalSeconds = _intervalSeconds;

        emit NewBufferAndIntervalSeconds(_bufferSeconds, _intervalSeconds);
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
        emit NewOperatorAddress(_operatorAddress);
    }

    /**
     * @notice Set operator vault address
     * @dev Callable by admin
     */
    function setOperatorVault(
        address _operatorVaultAddress
    ) external onlyAdmin {
        require(_operatorVaultAddress != address(0), "Cannot be zero address");
        operatorVaultAddress = _operatorVaultAddress;
        emit NewOperatorVaultAddress(_operatorVaultAddress);
    }

    /**
     * @notice Set Oracle address
     * @dev Callable by admin
     */
    function setOracle(address _oracle) external whenPaused onlyAdmin {
        require(_oracle != address(0), "Cannot be zero address");
        oracle = IPyth(_oracle);

        emit NewOracle(_oracle);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setCommissionfee(
        uint256 _commissionfee
    ) external whenPaused onlyAdmin {
        require(
            _commissionfee <= MAX_COMMISSION_FEE,
            "Commission fee too high"
        );
        commissionfee = _commissionfee;
        emit NewCommissionfee(currentEpoch, commissionfee);
    }

    function _trasferReward(address _user) internal {
        uint256 reward = 0; // Initializes reward

        for (uint256 epoch = 1; epoch <= currentEpoch; epoch++) {
            if (
                rounds[epoch].startTimestamp == 0 ||
                (block.timestamp < rounds[epoch].closeTimestamp + bufferSeconds)
            ) continue;

            Round memory round = rounds[epoch];
            // 0: Over, 1: Under
            uint pst = 0;
            while (pst <= uint(Position.Under)) {
                Position position = pst == 0 ? Position.Over : Position.Under;
                uint256 addedReward = 0;

                // Round vaild, claim rewards
                if (claimable(epoch, position, _user)) {
                    if (
                        (round.overAmount > 0 && round.underAmount > 0) &&
                        (round.startPrice != round.closePrice)
                    ) {
                        addedReward +=
                            (ledger[epoch][position][_user].amount *
                                round.rewardAmount) /
                            round.rewardBaseCalAmount;
                    }
                    addedReward += ledger[epoch][position][_user].amount;
                } else {
                    // Round invaild, refund bet amount
                    if (refundable(epoch, position, _user)) {
                        addedReward += ledger[epoch][position][_user].amount;
                    }
                }

                if (addedReward != 0) {
                    ledger[epoch][position][_user].claimed = true;
                    reward += addedReward;
                    emit Claim(_user, epoch, position, addedReward);
                }
                pst++;
            }
        }

        if (reward > 0) {
            token.safeTransfer(_user, reward);
        }
    }

    /**
     * @notice Set admin address
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }

    function getUserLimitOrders(
        address user,
        uint256 epoch,
        Position position,
        uint256 size
    ) external view returns (LimitOrder[] memory) {
        LimitOrder[] memory limitOrders = new LimitOrder[](size);
        if (position == Position.Over) {
            for (uint256 i = 0; i < overLimitOrders[epoch].length; i++) {
                if (overLimitOrders[epoch][i].user == user) {
                    LimitOrder memory o = LimitOrder({
                        user: overLimitOrders[epoch][i].user,
                        payout: overLimitOrders[epoch][i].payout,
                        amount: overLimitOrders[epoch][i].amount,
                        blockTimestamp: overLimitOrders[epoch][i]
                            .blockTimestamp,
                        status: overLimitOrders[epoch][i].status
                    });
                    limitOrders[i] = o;
                }
            }
        } else {
            for (uint256 i = 0; i < underLimitOrders[epoch].length; i++) {
                if (underLimitOrders[epoch][i].user == user) {
                    LimitOrder memory u = LimitOrder({
                        user: underLimitOrders[epoch][i].user,
                        payout: underLimitOrders[epoch][i].payout,
                        amount: underLimitOrders[epoch][i].amount,
                        blockTimestamp: underLimitOrders[epoch][i]
                            .blockTimestamp,
                        status: underLimitOrders[epoch][i].status
                    });
                    limitOrders[i] = u;
                }
            }
        }

        return (limitOrders);
    }

    function getUserLimitOrdersLength(
        address user,
        uint256 epoch
    ) external view returns (uint256, uint256) {
        uint256 overOrdersLength = 0;
        uint256 underOrdersLength = 0;

        for (uint i = 0; i < overLimitOrders[epoch].length; i++) {
            if (overLimitOrders[epoch][i].user == user) overOrdersLength++;
        }
        for (uint i = 0; i < underLimitOrders[epoch].length; i++) {
            if (underLimitOrders[epoch][i].user == user) underOrdersLength++;
        }
        return (overOrdersLength, underOrdersLength);
    }

    /**
     * @notice Returns round epochs length
     * @param user: user address
     */
    function getUserRoundsLength(address user) external view returns (uint256) {
        return userRounds[user].length;
    }

    /**
     * @notice Get the claimable stats of specific epoch and user account
     * @param epoch: epoch
     * @param position: Position
     * @param user: user address
     */
    function claimable(
        uint256 epoch,
        Position position,
        address user
    ) public view returns (bool) {
        ParticipateInfo memory participateInfo = ledger[epoch][position][user];
        Round memory round = rounds[epoch];

        bool isPossible = false;
        if (round.overAmount > 0 && round.underAmount > 0) {
            isPossible = ((round.closePrice >
                _getStrategyRatePrice(round.startPrice) &&
                participateInfo.position == Position.Over) ||
                (round.closePrice < _getStrategyRatePrice(round.startPrice) &&
                    participateInfo.position == Position.Under) ||
                (round.closePrice == _getStrategyRatePrice(round.startPrice)));
        } else {
            // refund user's fund if there is no paticipation on the other side
            isPossible = true;
        }

        return
            round.oracleCalled &&
            participateInfo.amount != 0 &&
            !participateInfo.claimed &&
            isPossible;
    }

    /**
     * @notice Get the refundable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function refundable(
        uint256 epoch,
        Position position,
        address user
    ) public view returns (bool) {
        ParticipateInfo memory participateInfo = ledger[epoch][position][user];
        Round memory round = rounds[epoch];
        return
            !round.oracleCalled &&
            !participateInfo.claimed &&
            block.timestamp > round.closeTimestamp + bufferSeconds &&
            participateInfo.amount != 0;
    }

    /**
     * @notice Calculate rewards for round
     * @param epoch: epoch
     */
    function _calculateRewards(uint256 epoch) internal {
        require(
            rounds[epoch].rewardBaseCalAmount == 0 &&
                rounds[epoch].rewardAmount == 0,
            "Rewards calculated"
        );
        Round storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;

        // No participation on the other side refund participant amount to users
        if (round.overAmount == 0 || round.underAmount == 0) {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            treasuryAmt = 0;
        } else {
            // Over wins
            if (round.closePrice > _getStrategyRatePrice(round.startPrice)) {
                rewardBaseCalAmount = round.overAmount;
                treasuryAmt = (round.underAmount * commissionfee) / BASE;
                rewardAmount = round.underAmount - treasuryAmt;
            }
            // Under wins
            else if (
                round.closePrice < _getStrategyRatePrice(round.startPrice)
            ) {
                rewardBaseCalAmount = round.underAmount;
                treasuryAmt = (round.overAmount * commissionfee) / BASE;
                rewardAmount = round.overAmount - treasuryAmt;
            }
            // No one wins refund participant amount to users
            else {
                rewardBaseCalAmount = 0;
                rewardAmount = 0;
                treasuryAmt = 0;
            }
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        // Add to treasury
        treasuryAmount += treasuryAmt;

        emit RewardsCalculated(
            epoch,
            rewardBaseCalAmount,
            rewardAmount,
            treasuryAmt
        );
    }

    /**
     * @notice Calculate start price applied with strategy Rate
     * @param price: start price
     */
    function _getStrategyRatePrice(
        int256 price
    ) internal view returns (int256) {
        if (strategyType == StrategyType.Up) {
            return price + (price * strategyRate) / int256(BASE);
        } else if (strategyType == StrategyType.Down) {
            return price - (price * strategyRate) / int256(BASE);
        } else {
            return price;
        }
    }

    /**
     * @notice End round
     * @param epoch: epoch
     * @param price: price of the round
     */
    function _safeEndRound(uint256 epoch, int256 price) internal {
        require(
            rounds[epoch].startTimestamp != 0,
            "Can only end round after round has locked"
        );
        require(
            block.timestamp >= rounds[epoch].closeTimestamp,
            "Can only end round after closeTimestamp"
        );
        require(
            block.timestamp <= rounds[epoch].closeTimestamp + bufferSeconds,
            "Can only end round within bufferSeconds"
        );
        Round storage round = rounds[epoch];
        round.closePrice = price;
        round.oracleCalled = true;

        emit EndRound(epoch, round.closePrice);
    }

    /**
     * @notice Start round
     * @param epoch: epoch
     * @param price: price of the round
     */
    function _safeStartRound(uint256 epoch, int256 price) internal {
        require(
            rounds[epoch].openTimestamp != 0,
            "Can only lock round after round has started"
        );
        require(
            block.timestamp >= rounds[epoch].startTimestamp,
            "Can only start round after startTimestamp"
        );
        require(
            block.timestamp <= rounds[epoch].startTimestamp + bufferSeconds,
            "Can only start round within bufferSeconds"
        );
        Round storage round = rounds[epoch];
        round.startPrice = price;

        emit StartRound(epoch, round.startPrice);
    }

    /**
     * @notice Open round
     * Previous round n-2 must end
     * @param epoch: epoch
     * @param initDate: initDate
     */
    function _safeOpenRound(uint256 epoch, uint256 initDate) internal {
        require(
            genesisOpenOnce,
            "Can only run after genesisOpenRound is triggered"
        );
        require(
            rounds[epoch - 2].closeTimestamp != 0,
            "Can only open round after round n-2 has ended"
        );
        require(
            block.timestamp >= rounds[epoch - 2].closeTimestamp,
            "Can only open new round after round n-2 closeTimestamp"
        );
        require(
            block.timestamp >= initDate,
            "Can only open new round after init date"
        );
        _openRound(epoch, initDate);
    }

    /**
     * @notice Start round
     * Previous round n-2 must end
     * @param epoch: epoch
     * @param initDate: initDate
     */
    function _openRound(uint256 epoch, uint256 initDate) internal {
        require(
            block.timestamp >= initDate,
            "Can only open new round after init date"
        );

        Round storage round = rounds[epoch];
        round.openTimestamp = initDate;
        round.startTimestamp = initDate + intervalSeconds;
        round.closeTimestamp = initDate + (2 * intervalSeconds);
        round.epoch = epoch;
        round.totalAmount = 0;

        emit OpenRound(epoch, strategyRate, strategyType);
    }

    /**
     * @notice Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current timestamp must be within openTimestamp and closeTimestamp
     */
    function _participable(uint256 epoch) internal view returns (bool) {
        return
            rounds[epoch].openTimestamp != 0 &&
            rounds[epoch].startTimestamp != 0 &&
            block.timestamp > rounds[epoch].openTimestamp &&
            block.timestamp < rounds[epoch].startTimestamp;
    }

    function _participate(
        uint256 epoch,
        Position _position,
        address _user,
        uint256 _amount
    ) internal {
        // Update user data
        ParticipateInfo storage participateInfo = ledger[epoch][_position][
            _user
        ];

        participateInfo.position = _position;
        participateInfo.amount = participateInfo.amount + _amount;
        userRounds[_user].push(epoch);

        // Update user round data
        Round storage round = rounds[epoch];
        round.totalAmount = round.totalAmount + _amount;
        if (_position == Position.Over) {
            round.overAmount = round.overAmount + _amount;
            emit ParticipateOver(msg.sender, epoch, _amount);
        } else {
            round.underAmount = round.underAmount + _amount;
            emit ParticipateUnder(msg.sender, epoch, _amount);
        }
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Participate over limit position
     */
    function participateLimitOver(
        uint256 epoch,
        uint256 _amount,
        uint256 _payout
    ) external whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch, "Participate is too early/late");
        require(_participable(epoch), "Round not participable");
        require(
            _amount >= minParticipateAmount,
            "Participate amount must be greater than minParticipateAmount"
        );
        require(_payout > BASE, "Participate payout must be greater than zero");
        token.safeTransferFrom(msg.sender, address(this), _amount);

        LimitOrder[] storage limitOrders = overLimitOrders[epoch];
        limitOrders.push(
            LimitOrder(
                msg.sender,
                _payout,
                _amount,
                block.timestamp,
                LimitOrderStatus.Undeclared
            )
        );
        emit ParticipateLimitOver(msg.sender, epoch, _amount, _payout);
    }

    /**
     * @notice Participate under limit position
     */
    function participateLimitUnder(
        uint256 epoch,
        uint256 _amount,
        uint256 _payout
    ) external whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch, "Participate is too early/late");
        require(_participable(epoch), "Round not participable");
        require(
            _amount >= minParticipateAmount,
            "Participate amount must be greater than minParticipateAmount"
        );
        require(_payout > BASE, "Participate payout must be greater than zero");
        token.safeTransferFrom(msg.sender, address(this), _amount);

        LimitOrder[] storage limitOrders = underLimitOrders[epoch];
        limitOrders.push(
            LimitOrder(
                msg.sender,
                _payout,
                _amount,
                block.timestamp,
                LimitOrderStatus.Undeclared
            )
        );

        emit ParticipateLimitUnder(msg.sender, epoch, _amount, _payout);
    }

    function _placeLimitOrders(uint256 epoch) internal {
        uint overOffset = 0;
        uint underOffset = 0;

        Round storage round = rounds[epoch];
        RoundAmount memory ra = RoundAmount(
            round.totalAmount,
            round.overAmount,
            round.underAmount
        );

        bool applyPayout = false;
        LimitOrder[] memory sortedOverLimitOrders = _sortByPayout(
            overLimitOrders[epoch]
        );
        LimitOrder[] memory sortedUnderLimitOrders = _sortByPayout(
            underLimitOrders[epoch]
        );

        do {
            // proc over limit orders
            for (; overOffset < sortedOverLimitOrders.length; overOffset++) {
                uint expectedPayout = ((ra.totalAmount +
                    sortedOverLimitOrders[overOffset].amount) * BASE) /
                    (ra.overAmount + sortedOverLimitOrders[overOffset].amount);
                if (
                    sortedOverLimitOrders[overOffset].payout <= expectedPayout
                ) {
                    ra.totalAmount =
                        ra.totalAmount +
                        sortedOverLimitOrders[overOffset].amount;
                    ra.overAmount =
                        ra.overAmount +
                        sortedOverLimitOrders[overOffset].amount;
                    sortedOverLimitOrders[overOffset].status = LimitOrderStatus
                        .Approve;
                } else {
                    break;
                }
            }

            applyPayout = false;
            // proc under limit orders
            for (; underOffset < sortedUnderLimitOrders.length; underOffset++) {
                uint expectedPayout = ((ra.totalAmount +
                    sortedUnderLimitOrders[underOffset].amount) * BASE) /
                    (ra.underAmount +
                        sortedUnderLimitOrders[underOffset].amount);

                if (
                    sortedUnderLimitOrders[underOffset].payout <= expectedPayout
                ) {
                    ra.totalAmount =
                        ra.totalAmount +
                        sortedUnderLimitOrders[underOffset].amount;
                    ra.underAmount =
                        ra.underAmount +
                        sortedUnderLimitOrders[underOffset].amount;
                    sortedUnderLimitOrders[underOffset]
                        .status = LimitOrderStatus.Approve;
                    applyPayout = true;
                } else {
                    break;
                }
            }
        } while (applyPayout);

        for (uint i = 0; i < sortedOverLimitOrders.length; i++) {
            if (
                sortedOverLimitOrders[i].status == LimitOrderStatus.Undeclared
            ) {
                // refund participate amount to user
                token.safeTransfer(
                    sortedOverLimitOrders[i].user,
                    sortedOverLimitOrders[i].amount
                );
                continue;
            }

            for (uint j = 0; j < overLimitOrders[epoch].length; j++) {
                if (
                    sortedOverLimitOrders[i].user ==
                    overLimitOrders[epoch][j].user &&
                    sortedOverLimitOrders[i].blockTimestamp ==
                    overLimitOrders[epoch][j].blockTimestamp
                ) {
                    overLimitOrders[epoch][j].status = LimitOrderStatus.Approve;
                    _participate(
                        epoch,
                        Position.Over,
                        sortedOverLimitOrders[i].user,
                        sortedOverLimitOrders[i].amount
                    );
                    break;
                }
            }
        }
        for (uint i = 0; i < sortedUnderLimitOrders.length; i++) {
            if (
                sortedUnderLimitOrders[i].status == LimitOrderStatus.Undeclared
            ) {
                // refund participate amount to user
                token.safeTransfer(
                    sortedUnderLimitOrders[i].user,
                    sortedUnderLimitOrders[i].amount
                );
                continue;
            }
            for (uint j = 0; j < underLimitOrders[epoch].length; j++) {
                if (
                    sortedUnderLimitOrders[i].user ==
                    underLimitOrders[epoch][j].user &&
                    sortedUnderLimitOrders[i].blockTimestamp ==
                    underLimitOrders[epoch][j].blockTimestamp
                ) {
                    underLimitOrders[epoch][j].status = LimitOrderStatus
                        .Approve;
                    _participate(
                        epoch,
                        Position.Under,
                        sortedUnderLimitOrders[i].user,
                        sortedUnderLimitOrders[i].amount
                    );
                    break;
                }
            }
        }
    }

    function _sortByPayout(
        LimitOrder[] memory items
    ) internal pure returns (LimitOrder[] memory) {
        for (uint i = 1; i < items.length; i++)
            for (uint j = 0; j < i; j++)
                if (items[i].payout < items[j].payout) {
                    LimitOrder memory x = items[i];
                    items[i] = items[j];
                    items[j] = x;
                }

        return items;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./StVol.sol";

/**
 * @title StVolUpDown
 */
contract StVolUpDown is StVol {
    constructor(
        address _token,
        address _oracleAddress,
        address _adminAddress,
        address _operatorAddress,
        address _operatorVaultAddress,
        uint256 _commissionfee,
        uint256 _operateRate,
        bytes32 _priceId
    ) 
    StVol(
        _token,
        _oracleAddress,
        _adminAddress,
        _operatorAddress,
        _operatorVaultAddress,
        _commissionfee,
        _operateRate,
        0, // 0
        StVol.StrategyType.None, // None: Up & Down
        _priceId
    ) {}

}