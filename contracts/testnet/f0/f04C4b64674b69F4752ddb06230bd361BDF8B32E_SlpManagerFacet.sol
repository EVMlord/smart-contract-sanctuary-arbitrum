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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * ```solidity
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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../security/Pausable.sol";
import "../libraries/LibVault.sol";
import "../interfaces/ISlpManager.sol";
import "../libraries/LibSlpManager.sol";
import "../libraries/LibStakeReward.sol";
import "../security/ReentrancyGuard.sol";
import "../libraries/LibAccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ISlp {
    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract SlpManagerFacet is ReentrancyGuard, Pausable, ISlpManager {

    using Address for address;

    function initSlpManagerFacet(address slpToken) external {
        LibAccessControlEnumerable.checkRole(Constants.DEPLOYER_ROLE);
        require(slpToken != address(0), "SlpManagerFacet: Invalid slpToken");
        LibSlpManager.initialize(slpToken);
    }

    function SLP() public view override returns (address) {
        return LibSlpManager.slpManagerStorage().slp;
    }

    function coolingDuration() external view override returns (uint256) {
        return LibSlpManager.slpManagerStorage().coolingDuration;
    }

    function setCoolingDuration(uint256 coolingDuration_) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        LibSlpManager.SlpManagerStorage storage ams = LibSlpManager.slpManagerStorage();
        ams.coolingDuration = coolingDuration_;
    }

    function mintSlp(address tokenIn, uint256 amount, uint256 minSlp, bool stake) external whenNotPaused nonReentrant override {
        require(amount > 0, "SlpManagerFacet: invalid amount");
        address account = msg.sender;
        uint256 slpAmount = LibSlpManager.mintSlp(account, tokenIn, amount);
        require(slpAmount >= minSlp, "SlpManagerFacet: insufficient SLP output");
        _mint(account, tokenIn, amount, slpAmount, stake);
    }

    function mintSlpETH(uint256 minSlp, bool stake) external payable whenNotPaused nonReentrant override {
        uint amount = msg.value;
        require(amount > 0, "SlpManagerFacet: invalid msg.value");
        address account = msg.sender;
        uint256 slpAmount = LibSlpManager.mintSlpETH(account, amount);
        require(slpAmount >= minSlp, "SlpManagerFacet: insufficient SLP output");
        _mint(account, LibVault.WETH(), amount, slpAmount, stake);
    }

    function _mint(address account, address tokenIn, uint256 amount, uint256 slpAmount, bool stake) private {
        ISlp(SLP()).mint(account, slpAmount);
        emit MintSlp(account, tokenIn, amount, slpAmount);
        if (stake) {
            LibStakeReward.stake(slpAmount);
        }
    }

    function burnSlp(address tokenOut, uint256 slpAmount, uint256 minOut, address receiver) external whenNotPaused nonReentrant override {
        require(slpAmount > 0, "SlpManagerFacet: invalid slpAmount");
        address account = msg.sender;
        uint256 amountOut = LibSlpManager.burnSlp(account, tokenOut, slpAmount, receiver);
        require(amountOut >= minOut, "SlpManagerFacet: insufficient token output");
        ISlp(SLP()).burnFrom(account, slpAmount);
        emit BurnSlp(account, receiver, tokenOut, slpAmount, amountOut);
    }

    function burnSlpETH(uint256 slpAmount, uint256 minOut, address payable receiver) external whenNotPaused nonReentrant override {
        require(slpAmount > 0, "SlpManagerFacet: invalid slpAmount");
        address account = msg.sender;
        uint256 amountOut = LibSlpManager.burnSlpETH(account, slpAmount, receiver);
        require(amountOut >= minOut, "SlpManagerFacet: insufficient ETH output");
        ISlp(SLP()).burnFrom(account, slpAmount);
        emit BurnSlp(account, receiver, LibVault.WETH(), slpAmount, amountOut);
    }

    function slpPrice() external view override returns (uint256){
        return LibSlpManager.slpPrice();
    }

    function lastMintedTimestamp(address account) external view override returns (uint256) {
        return LibSlpManager.slpManagerStorage().lastMintedAt[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IArbSys
 * @dev Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as uint256
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 blockNumber) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBook {

    struct OpenDataInput {
        // Pair.base
        address pairBase;
        bool isLong;
        // USDC/USDT address
        address tokenIn;
        uint96 amountIn;   // tokenIn decimals
        uint80 qty;        // 1e10
        // Limit Order: limit price
        // Market Trade: worst price acceptable
        uint64 price;      // 1e8
        uint64 stopLoss;   // 1e8
        uint64 takeProfit; // 1e8
        uint24 broker;
    }

    struct KeeperExecution {
        bytes32 hash;
        uint64 price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDiamondCut {

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibFeeManager.sol";
import "./IPairsManager.sol";

interface IFeeManager {

    struct FeeDetail {
        // total accumulated fees, include DAO/referral fee
        uint256 total;
        // accumulated DAO repurchase funds
        uint256 daoAmount;
        uint256 brokerAmount;
    }

    function addFeeConfig(uint16 index, string calldata name, uint16 openFeeP, uint16 closeFeeP) external;

    function removeFeeConfig(uint16 index) external;

    function updateFeeConfig(uint16 index, uint16 openFeeP, uint16 closeFeeP) external;

    function setDaoRepurchase(address daoRepurchase) external;

    function setDaoShareP(uint16 daoShareP) external;

    function getFeeConfigByIndex(uint16 index) external view returns (LibFeeManager.FeeConfig memory, IPairsManager.PairSimple[] memory);

    function getFeeDetails(address[] calldata tokens) external view returns (FeeDetail[] memory);

    function daoConfig() external view returns (address, uint16);

    function chargeOpenFee(address token, uint256 openFee, uint24 broker) external returns (uint24);

    function chargeCloseFee(address token, uint256 closeFee, uint24 broker) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IBook.sol";
import "./ITradingChecker.sol";

interface ILimitOrder is IBook {

    event OpenLimitOrder(address indexed user, bytes32 indexed orderHash, OpenDataInput data);
    event UpdateOrderTp(address indexed user, bytes32 indexed orderHash, uint256 oldTp, uint256 tp);
    event UpdateOrderSl(address indexed user, bytes32 indexed orderHash, uint256 oldSl, uint256 sl);
    event ExecuteLimitOrderRejected(address indexed user, bytes32 indexed orderHash, ITradingChecker.Refund refund);
    event LimitOrderRefund(address indexed user, bytes32 indexed orderHash, ITradingChecker.Refund refund);
    event CancelLimitOrder(address indexed user, bytes32 indexed orderHash);
    event ExecuteLimitOrderSuccessful(address indexed user, bytes32 indexed orderHash);

    struct LimitOrderView {
        bytes32 orderHash;
        string pair;
        address pairBase;
        bool isLong;
        address tokenIn;
        uint96 amountIn;    // tokenIn decimals
        uint80 qty;         // 1e10
        uint64 limitPrice;  // 1e8
        uint64 stopLoss;    // 1e8
        uint64 takeProfit;  // 1e8
        uint24 broker;
        uint40 timestamp;
    }

    struct LimitOrder {
        address user;
        uint32 userOpenOrderIndex;
        uint64 limitPrice;   // 1e8
        // pair.base
        address pairBase;
        uint96 amountIn;     // tokenIn decimals
        address tokenIn;
        bool isLong;
        uint24 broker;
        uint64 stopLoss;     // 1e8
        uint80 qty;          // 1e10
        uint64 takeProfit;   // 1e8
        uint40 timestamp;
    }

    function openLimitOrder(OpenDataInput calldata openData) external;

    function updateOrderTp(bytes32 orderHash, uint64 takeProfit) external;

    function updateOrderSl(bytes32 orderHash, uint64 stopLoss) external;

    // stopLoss is allowed to be equal to 0, which means the sl setting is removed.
    // takeProfit must be greater than 0
    function updateOrderTpAndSl(bytes32 orderHash, uint64 takeProfit, uint64 stopLoss) external;

    function executeLimitOrder(KeeperExecution[] memory) external;

    function cancelLimitOrder(bytes32 orderHash) external;

    function getLimitOrderByHash(bytes32 orderHash) external view returns (LimitOrderView memory);

    function getLimitOrders(address user, address pairBase) external view returns (LimitOrderView[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOrderAndTradeHistory {

    enum ActionType {LIMIT, CANCEL_LIMIT, SYSTEM_CANCEL, OPEN, CLOSE, TP, SL, LIQUIDATED}

    struct OrderInfo {
        address user;
        uint96 amountIn;
        address tokenIn;
        uint80 qty;
        bool isLong;
        address pairBase;
        uint64 entryPrice;
    }

    struct TradeInfo {
        uint96 margin;
        uint96 openFee;
        uint96 executionFee;
    }

    struct CloseInfo {
        uint64 closePrice;  // 1e8
        int96 fundingFee;   // tokenIn decimals
        uint96 closeFee;    // tokenIn decimals
        int96 pnl;          // tokenIn decimals
    }

    struct ActionInfo {
        bytes32 hash;
        uint40 timestamp;
        ActionType actionType;
    }

    struct OrderAndTradeHistory {
        bytes32 hash;
        uint40 timestamp;
        string pair;
        ActionType actionType;
        address tokenIn;
        bool isLong;
        uint96 amountIn;           // tokenIn decimals
        uint80 qty;                // 1e10
        uint64 entryPrice;         // 1e8

        uint96 margin;             // tokenIn decimals
        uint96 openFee;            // tokenIn decimals
        uint96 executionFee;       // tokenIn decimals

        uint64 closePrice;         // 1e8
        int96 fundingFee;          // tokenIn decimals
        uint96 closeFee;           // tokenIn decimals
        int96 pnl;                 // tokenIn decimals
    }

    function createLimitOrder(bytes32 orderHash, OrderInfo calldata) external;

    function cancelLimitOrder(bytes32 orderHash, ActionType aType) external;

    function limitTrade(bytes32 tradeHash, TradeInfo calldata) external;

    function marketTrade(bytes32 tradeHash, OrderInfo calldata, TradeInfo calldata) external;

    function closeTrade(bytes32 tradeHash, CloseInfo calldata, ActionType aType) external;

    function updateMargin(bytes32 tradeHash, uint96 newMargin) external;

    function getOrderAndTradeHistory(
        address user, uint start, uint8 size
    ) external view returns (OrderAndTradeHistory[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IFeeManager.sol";
import "../libraries/LibPairsManager.sol";

interface IPairsManager {
    enum PairType{CRYPTO, STOCKS, FOREX, INDICES, COMMODITIES}
    enum PairStatus{AVAILABLE, REDUCE_ONLY, CLOSE}
    enum SlippageType{FIXED, ONE_PERCENT_DEPTH}

    struct PairSimple {
        // BTC/USD
        string name;
        // BTC address
        address base;
        PairType pairType;
        PairStatus status;
    }

    struct PairView {
        // BTC/USD
        string name;
        // BTC address
        address base;
        uint16 basePosition;
        PairType pairType;
        PairStatus status;
        uint256 maxLongOiUsd;
        uint256 maxShortOiUsd;
        uint256 fundingFeePerBlockP;  // 1e18
        uint256 minFundingFeeR;       // 1e18
        uint256 maxFundingFeeR;       // 1e18

        LibPairsManager.LeverageMargin[] leverageMargins;

        uint16 slippageConfigIndex;
        uint16 slippagePosition;
        LibPairsManager.SlippageConfig slippageConfig;

        uint16 feeConfigIndex;
        uint16 feePosition;
        LibFeeManager.FeeConfig feeConfig;
    }

    struct PairMaxOiAndFundingFeeConfig {
        uint256 maxLongOiUsd;
        uint256 maxShortOiUsd;
        uint256 fundingFeePerBlockP;
        uint256 minFundingFeeR;
        uint256 maxFundingFeeR;
    }

    struct LeverageMargin {
        uint256 notionalUsd;
        uint16 maxLeverage;
        uint16 initialLostP; // 1e4
        uint16 liqLostP;     // 1e4
    }

    struct SlippageConfig {
        uint256 onePercentDepthAboveUsd;
        uint256 onePercentDepthBelowUsd;
        uint16 slippageLongP;       // 1e4
        uint16 slippageShortP;      // 1e4
        SlippageType slippageType;
    }

    struct FeeConfig {
        uint16 openFeeP;     // 1e4
        uint16 closeFeeP;    // 1e4
    }

    struct TradingPair {
        // BTC address
        address base;
        string name;
        PairType pairType;
        PairStatus status;
        PairMaxOiAndFundingFeeConfig pairConfig;
        LeverageMargin[] leverageMargins;
        SlippageConfig slippageConfig;
        FeeConfig feeConfig;
    }

    function addSlippageConfig(
        string calldata name, uint16 index, SlippageType slippageType,
        uint256 onePercentDepthAboveUsd, uint256 onePercentDepthBelowUsd,
        uint16 slippageLongP, uint16 slippageShortP
    ) external;

    function removeSlippageConfig(uint16 index) external;

    function updateSlippageConfig(
        uint16 index, SlippageType slippageType,
        uint256 onePercentDepthAboveUsd, uint256 onePercentDepthBelowUsd,
        uint16 slippageLongP, uint16 slippageShortP
    ) external;

    function getSlippageConfigByIndex(uint16 index) external view returns (LibPairsManager.SlippageConfig memory, PairSimple[] memory);

    function addPair(
        address base, string calldata name,
        PairType pairType, PairStatus status,
        PairMaxOiAndFundingFeeConfig calldata pairConfig,
        uint16 slippageConfigIndex, uint16 feeConfigIndex,
        LibPairsManager.LeverageMargin[] calldata leverageMargins
    ) external;

    function updatePairMaxOi(address base, uint256 maxLongOiUsd, uint256 maxShortOiUsd) external;

    function updatePairFundingFeeConfig(
        address base, uint256 fundingFeePerBlockP, uint256 minFundingFeeR, uint256 maxFundingFeeR
    ) external;

    function removePair(address base) external;

    function updatePairStatus(address base, PairStatus status) external;

    function batchUpdatePairStatus(PairType pairType, PairStatus status) external;

    function updatePairSlippage(address base, uint16 slippageConfigIndex) external;

    function updatePairFee(address base, uint16 feeConfigIndex) external;

    function updatePairLeverageMargin(address base, LibPairsManager.LeverageMargin[] calldata leverageMargins) external;

    function pairs() external view returns (PairView[] memory);

    function getPairByBase(address base) external view returns (PairView memory);

    function getPairForTrading(address base) external view returns (TradingPair memory);

    function getPairConfig(address base) external view returns (PairMaxOiAndFundingFeeConfig memory);

    function getPairFeeConfig(address base) external view returns (FeeConfig memory);

    function getPairSlippageConfig(address base) external view returns (SlippageConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPriceFacade {

    struct Config {
        uint16 lowPriceGapP;
        uint16 highPriceGapP;
        uint16 maxDelay;
    }

    function setLowAndHighPriceGapP(uint16 lowPriceGapP, uint16 highPriceGapP) external;

    function setMaxDelay(uint16 maxDelay) external;

    function getPriceFacadeConfig() external view returns (Config memory);

    function getPrice(address token) external view returns (uint256);

    function getPriceFromCacheOrOracle(address token) external view returns (uint64 price, uint40 updatedAt);

    function requestPrice(bytes32 tradeHash, address token, bool isOpen) external;

    function requestPriceCallback(bytes32 requestId, uint64 price) external;

    function confirmTriggerPrice(address token, uint64 price) external returns (bool, uint64, uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISdtReward {

    struct SdtPoolInfo {
        uint256 totalStaked;
        uint256 sdtPerBlock;        //award per block
        uint256 lastRewardBlock;   // Last block number that SDTs distribution occurs.
        uint256 accSDTPerShare;    // Accumulated SDTs per share, times 1e12. See below.
        uint256 totalReward;
        uint256 reserves;
    }

    struct SdtUserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 pendingReward; // User pending reward
        //
        // We do some fancy math here. Basically, any point in time, the amount of SDTs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSDTPerShare) - user.rewardDebt + user.rewardPending
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSDTPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User's `pendingReward` gets updated.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    function updateSdtPerBlock(uint256 sdtPerBlock) external;

    function addReserves(uint256 amount) external;

    function sdtPoolInfo() external view returns (SdtPoolInfo memory) ;

    function pendingSdt(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISlpManager {

    event MintSlp(address indexed account, address indexed tokenIn, uint256 amountIn, uint256 slpOut);
    event BurnSlp(address indexed account, address indexed receiver, address indexed tokenOut, uint256 slpAmount, uint256 amountOut);
    event MintFee(
        address indexed account, address indexed tokenIn, uint256 amountIn,
        uint256 tokenInPrice, uint256 mintFeeUsd, uint256 slpAmount
    );
    event BurnFee(
        address indexed account, address indexed tokenOut, uint256 amountOut,
        uint256 tokenOutPrice, uint256 burnFeeUsd, uint256 slpAmount
    );

    function SLP() external view returns (address);

    function coolingDuration() external view returns (uint256);

    function setCoolingDuration(uint256 coolingDuration_) external;

    function mintSlp(address tokenIn, uint256 amount, uint256 minSlp, bool stake) external;

    function mintSlpETH(uint256 minSlp, bool stake) external payable;

    function burnSlp(address tokenOut, uint256 slpAmount, uint256 minOut, address receiver) external;

    function burnSlpETH(uint256 slpAmount, uint256 minOut, address payable receiver) external;

    function slpPrice() external view returns (uint256);

    function lastMintedTimestamp(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITrading {

    struct PendingTrade {
        address user;
        uint24 broker;
        bool isLong;
        uint64 price;      // 1e8
        address pairBase;
        uint96 amountIn;   // tokenIn decimals
        address tokenIn;
        uint80 qty;        // 1e10
        uint64 stopLoss;   // 1e8
        uint64 takeProfit; // 1e8
        uint128 blockNumber;
    }

    struct OpenTrade {
        address user;
        uint32 userOpenTradeIndex;
        uint64 entryPrice;     // 1e8
        address pairBase;
        address tokenIn;
        uint96 margin;         // tokenIn decimals
        uint64 stopLoss;       // 1e8
        uint64 takeProfit;     // 1e8
        uint24 broker;
        bool isLong;
        uint96 openFee;        // tokenIn decimals
        int256 longAccFundingFeePerShare; // 1e18
        uint96 executionFee;   // tokenIn decimals
        uint40 timestamp;
        uint80 qty;            // 1e10
    }

    struct MarginBalance {
        address token;
        uint256 price;
        uint8 decimals;
        uint256 balanceUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IBook.sol";
import "./IPairsManager.sol";
import "./ILimitOrder.sol";
import "./ITrading.sol";

interface ITradingChecker {

    enum Refund {
        NO, SWITCH, PAIR_STATUS, AMOUNT_IN, USER_PRICE, MIN_NOTIONAL_USD, MAX_NOTIONAL_USD,
        MAX_LEVERAGE, TP, SL, PAIR_OI, OPEN_LOST, SYSTEM, FEED_DELAY
    }

    function checkTp(
        bool isLong, uint takeProfit, uint entryPrice, uint leverage_10000, uint maxTakeProfitP
    ) external pure returns (bool);

    function checkSl(bool isLong, uint stopLoss, uint entryPrice) external pure returns (bool);

    function checkLimitOrderTp(ILimitOrder.LimitOrder calldata order) external view;

    function openLimitOrderCheck(IBook.OpenDataInput calldata data) external view;

    function executeLimitOrderCheck(
        ILimitOrder.LimitOrder calldata order, uint256 marketPrice
    ) external view returns (bool result, uint96 openFee, uint96 executionFee, Refund refund);

    function checkMarketTradeTp(ITrading.OpenTrade calldata) external view;

    function openMarketTradeCheck(IBook.OpenDataInput calldata data) external view;

    function marketTradeCallbackCheck(
        ITrading.PendingTrade calldata pt, uint256 marketPrice
    ) external view returns (bool result, uint96 openFee, uint96 executionFee, uint256 entryPrice, Refund refund);

    function executeLiquidateCheck(
        ITrading.OpenTrade calldata ot, uint256 marketPrice, uint256 closePrice
    ) external view returns (bool needLiq, int256 pnl, int256 fundingFee, uint256 closeFee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ITrading.sol";
import "./IOrderAndTradeHistory.sol";

interface ITradingClose is ITrading {

    event CloseTradeSuccessful(address indexed user, bytes32 indexed tradeHash, IOrderAndTradeHistory.CloseInfo closeInfo);
    event ExecuteCloseSuccessful(address indexed user, bytes32 indexed tradeHash, ExecutionType executionType, IOrderAndTradeHistory.CloseInfo closeInfo);
    event CloseTradeReceived(address indexed user, bytes32 indexed tradeHash, address indexed token, uint256 amount);
    event CloseTradeAddLiquidity(address indexed token, uint256 amount);
    event ExecuteCloseRejected(address indexed user, bytes32 indexed tradeHash, ExecutionType executionType, uint64 execPrice, uint64 marketPrice);

    enum ExecutionType {TP, SL, LIQ}
    struct TpSlOrLiq {
        bytes32 tradeHash;
        uint64 price;
        ExecutionType executionType;
    }

    struct SettleToken {
        address token;
        uint256 amount;
        uint8 decimals;
    }

    function closeTradeCallback(bytes32 tradeHash, uint upperPrice, uint lowerPrice) external;

    function executeTpSlOrLiq(TpSlOrLiq[] memory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IPairsManager.sol";

interface ITradingCore {

    event UpdatePairPositionInfo(
        address indexed pairBase, uint256 lastBlock, uint256 longQty, uint256 shortQty,
        int256 longAccFundingFeePerShare, uint64 lpLongAvgPrice, uint64 lpShortAvgPrice
    );

    struct PairQty {
        uint256 longQty;
        uint256 shortQty;
    }

    struct PairPositionInfo {
        uint256 lastFundingFeeBlock;
        uint256 longQty;                   // 1e10
        uint256 shortQty;                  // 1e10
        // shortAcc = longAcc * -1
        int256 longAccFundingFeePerShare;  // 1e18
        uint64 lpLongAvgPrice;             // 1e8
        address pairBase;
        uint16 pairIndex;
        uint64 lpShortAvgPrice;
    }

    struct LpMarginTokenUnPnl {
        address token;
        int256 unPnlUsd;
    }

    struct MarginPct {
        address token;
        uint256 pct;   // 1e4
    }

    function getPairQty(address pairBase) external view returns (PairQty memory);

    function slippagePrice(address pairBase, uint256 marketPrice, uint256 qty, bool isLong) external view returns (uint256);

    function slippagePrice(
        PairQty memory pairQty,
        IPairsManager.SlippageConfig memory sc,
        uint256 marketPrice, uint256 qty, bool isLong
    ) external pure returns (uint256);

    function triggerPrice(address pairBase, uint256 limitPrice, uint256 qty, bool isLong) external view returns (uint256);

    function triggerPrice(
        PairQty memory pairQty,
        IPairsManager.SlippageConfig memory sc,
        uint256 limitPrice, uint256 qty, bool isLong
    ) external pure returns (uint256);

    function lastLongAccFundingFeePerShare(address pairBase) external view returns (int256);

    function updatePairPositionInfo(
        address pairBase, uint userPrice, uint marketPrice, uint qty, bool isLong, bool isOpen
    ) external returns (int256 longAccFundingFeePerShare);

    function lpUnrealizedPnlUsd() external view returns (int256 totalUsd, LpMarginTokenUnPnl[] memory);

    function lpUnrealizedPnlUsd(address targetToken) external view returns (int256 totalUsd, int256 tokenUsd);

    function lpNotionalUsd() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ITrading.sol";
import "./ITradingChecker.sol";

interface ITradingOpen is ITrading {

    event PendingTradeRefund(address indexed user, bytes32 indexed tradeHash, ITradingChecker.Refund refund);
    event OpenMarketTrade(address indexed user, bytes32 indexed tradeHash, OpenTrade ot);

    struct LimitOrder {
        bytes32 orderHash;
        address user;
        uint64 entryPrice;
        address pairBase;
        address tokenIn;
        uint96 margin;
        uint64 stopLoss;
        uint64 takeProfit;
        uint24 broker;
        bool isLong;
        uint96 openFee;
        uint96 executionFee;
        uint80 qty;
    }

    function limitOrderDeal(LimitOrder memory, uint256 marketPrice) external;

    function marketTradeCallback(bytes32 tradeHash, uint upperPrice, uint lowerPrice) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IBook.sol";
import "./ITrading.sol";

interface ITradingPortal is ITrading, IBook {

    event FundingFeeAddLiquidity(address indexed token, uint256 amount);
    event MarketPendingTrade(address indexed user, bytes32 indexed tradeHash, OpenDataInput trade);
    event UpdateTradeTp(address indexed user, bytes32 indexed tradeHash, uint256 oldTp, uint256 tp);
    event UpdateTradeSl(address indexed user, bytes32 indexed tradeHash, uint256 oldSl, uint256 sl);
    event UpdateMargin(address indexed user, bytes32 indexed tradeHash, uint256 beforeMargin, uint256 margin);

    function openMarketTrade(OpenDataInput calldata openData) external;

    function updateTradeTp(bytes32 tradeHash, uint64 takeProfit) external;

    function updateTradeSl(bytes32 tradeHash, uint64 stopLoss) external;

    // stopLoss is allowed to be equal to 0, which means the sl setting is removed.
    // takeProfit must be greater than 0
    function updateTradeTpAndSl(bytes32 tradeHash, uint64 takeProfit, uint64 stopLoss) external;

    function settleLpFundingFee(uint256 lpReceiveFundingFeeUsd) external;

    function closeTrade(bytes32 tradeHash) external;

    function addMargin(bytes32 tradeHash, uint96 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ITradingPortal.sol";
import "./ITradingClose.sol";

interface IVault {

    event CloseTradeRemoveLiquidity(address indexed token, uint256 amount);

    struct Token {
        address tokenAddress;
        uint16 weight;
        uint16 feeBasisPoints;
        uint16 taxBasisPoints;
        bool stable;
        bool dynamicFee;
        bool asMargin;
    }

    struct LpItem {
        address tokenAddress;
        int256 value;
        uint8 decimals;
        int256 valueUsd; // decimals = 18
        uint16 targetWeight;
        uint16 feeBasisPoints;
        uint16 taxBasisPoints;
        bool dynamicFee;
    }

    struct MarginToken {
        address token;
        bool asMargin;
        uint8 decimals;
        uint256 price;
    }

    function addToken(
        address tokenAddress, uint16 feeBasisPoints, uint16 taxBasisPoints,
        bool stable, bool dynamicFee, bool asMargin, uint16[] calldata weights
    ) external;

    function removeToken(address tokenAddress, uint16[] calldata weights) external;

    function updateToken(address tokenAddress, uint16 feeBasisPoints, uint16 taxBasisPoints, bool dynamicFee) external;

    function updateAsMargin(address tokenAddress, bool asMargin) external;

    function changeWeight(uint16[] calldata weights) external;

    function setSecurityMarginP(uint16 _securityMarginP) external;

    function securityMarginP() external view returns (uint16);

    function tokensV2() external view returns (Token[] memory);

    function getTokenByAddress(address tokenAddress) external view returns (Token memory);

    function getTokenForTrading(address tokenAddress) external view returns (MarginToken memory);

    function itemValue(address token) external view returns (LpItem memory lpItem);

    function totalValue() external view returns (LpItem[] memory lpItems);

    function increaseByCloseTrade(address tokens, uint256 amounts) external;

    function decreaseByCloseTrade(address token, uint256 amount) external returns (ITradingClose.SettleToken[] memory);

    function maxWithdrawAbleUsd() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibAccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 constant ACCESS_CONTROL_STORAGE_POSITION = keccak256("shardex.access.control.storage");

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct AccessControlStorage {
        mapping(bytes32 => RoleData) roles;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
        mapping(bytes4 => bool) supportedInterfaces;
    }

    function accessControlStorage() internal pure returns (AccessControlStorage storage acs) {
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
        assembly {
            acs.slot := position
        }
    }

    function checkRole(bytes32 role) internal view {
        checkRole(role, msg.sender);
    }

    function checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(account),
                    " is missing role ",
                    Strings.toHexString(uint256(role), 32)
                )
            )
            );
        }
    }

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        AccessControlStorage storage acs = accessControlStorage();
        return acs.roles[role].members[account];
    }

    function grantRole(bytes32 role, address account) internal {
        AccessControlStorage storage acs = accessControlStorage();
        if (!hasRole(role, account)) {
            acs.roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
            acs.roleMembers[role].add(account);
        }
    }

    function revokeRole(bytes32 role, address account) internal {
        AccessControlStorage storage acs = accessControlStorage();
        if (hasRole(role, account)) {
            acs.roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
            acs.roleMembers[role].remove(account);
        }
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        AccessControlStorage storage acs = accessControlStorage();
        bytes32 previousAdminRole = acs.roles[role].adminRole;
        acs.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ZERO, ONE, UC, uc, into} from "unchecked-counter/src/UC.sol";

library LibBrokerManager {

    using SafeERC20 for IERC20;

    bytes32 constant BROKER_MANAGER_STORAGE_POSITION = keccak256("shardex.broker.manager.storage");

    struct Broker {
        string name;
        string url;
        address receiver;
        uint24 id;
        uint24 brokerIndex;
        uint16 commissionP;
    }

    struct Commission {
        uint total;
        uint pending;
    }

    struct BrokerManagerStorage {
        // id =>
        mapping(uint24 => Broker) brokers;
        uint24[] brokerIds;
        // id => token =>
        mapping(uint24 => mapping(address => Commission)) brokerCommissions;
        // id => tokens
        mapping(uint24 => address[]) brokerCommissionTokens;
        // token => total amount
        mapping(address => uint256) allPendingCommissions;
        uint24 defaultBroker;
    }

    function brokerManagerStorage() internal pure returns (BrokerManagerStorage storage bms) {
        bytes32 position = BROKER_MANAGER_STORAGE_POSITION;
        assembly {
            bms.slot := position
        }
    }

    event AddBroker(uint24 indexed id, Broker broker);
    event RemoveBroker(uint24 indexed id);
    event UpdateBrokerCommissionP(uint24 indexed id, uint16 oldCommissionP, uint16 commissionP);
    event UpdateBrokerReceiver(uint24 indexed id, address oldReceiver, address receiver);
    event UpdateBrokerName(uint24 indexed id, string oldName, string name);
    event UpdateBrokerUrl(uint24 indexed id, string oldUrl, string url);
    event WithdrawBrokerCommission(
        uint24 indexed id, address indexed token,
        address indexed operator, uint256 amount
    );

    function initialize(
        uint24 id, uint16 commissionP, address receiver,
        string calldata name, string calldata url
    ) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        require(bms.defaultBroker == 0, "LibBrokerManager: Already initialized");
        bms.defaultBroker = id;
        addBroker(id, commissionP, receiver, name, url);
    }

    function addBroker(
        uint24 id, uint16 commissionP, address receiver,
        string calldata name, string calldata url
    ) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        require(bms.brokers[id].receiver == address(0), "LibBrokerManager: Broker already exists");
        Broker memory b = Broker(name, url, receiver, id, uint24(bms.brokerIds.length), commissionP);
        bms.brokers[id] = b;
        bms.brokerIds.push(id);
        emit AddBroker(id, b);
    }

    function _checkBrokerExist(BrokerManagerStorage storage bms, uint24 id) private view returns (Broker storage) {
        Broker storage b = bms.brokers[id];
        require(b.receiver != address(0), "LibBrokerManager: broker does not exist");
        return b;
    }

    function removeBroker(uint24 id) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        require(id != bms.defaultBroker, "LibBrokerManager: Default broker cannot be removed.");
        withdrawCommission(id);

        uint24[] storage brokerIds = bms.brokerIds;
        uint last = brokerIds.length - 1;
        uint removeBrokerIndex = bms.brokers[id].brokerIndex;
        if (removeBrokerIndex != last) {
            uint24 lastBrokerId = brokerIds[last];
            brokerIds[removeBrokerIndex] = lastBrokerId;
            bms.brokers[lastBrokerId].brokerIndex = uint24(removeBrokerIndex);
        }
        brokerIds.pop();
        delete bms.brokers[id];
        emit RemoveBroker(id);
    }

    function updateBrokerCommissionP(uint24 id, uint16 commissionP) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        Broker storage b = _checkBrokerExist(bms, id);
        uint16 oldCommissionP = b.commissionP;
        b.commissionP = commissionP;
        emit UpdateBrokerCommissionP(id, oldCommissionP, commissionP);
    }

    function updateBrokerReceiver(uint24 id, address receiver) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        Broker storage b = _checkBrokerExist(bms, id);
        address oldReceiver = b.receiver;
        b.receiver = receiver;
        emit UpdateBrokerReceiver(id, oldReceiver, receiver);
    }

    function updateBrokerName(uint24 id, string calldata name) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        Broker storage b = _checkBrokerExist(bms, id);
        string memory oldName = b.name;
        b.name = name;
        emit UpdateBrokerName(id, oldName, name);
    }

    function updateBrokerUrl(uint24 id, string calldata url) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        Broker storage b = _checkBrokerExist(bms, id);
        string memory oldUrl = b.url;
        b.url = url;
        emit UpdateBrokerUrl(id, oldUrl, url);
    }

    function withdrawCommission(uint24 id) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        Broker storage b = _checkBrokerExist(bms, id);
        address operator = msg.sender;
        address[] memory tokens = bms.brokerCommissionTokens[id];
        for (UC i = ZERO; i < uc(tokens.length); i = i + ONE) {
            Commission storage c = bms.brokerCommissions[id][tokens[i.into()]];
            if (c.pending > 0) {
                uint256 pending = c.pending;
                c.pending = 0;
                bms.allPendingCommissions[tokens[i.into()]] -= pending;
                IERC20(tokens[i.into()]).safeTransfer(b.receiver, pending);
                emit WithdrawBrokerCommission(id, tokens[i.into()], operator, pending);
            }
        }
    }

    function _getBrokerOrDefault(BrokerManagerStorage storage bms, uint24 id) private view returns (Broker memory) {
        Broker memory b = bms.brokers[id];
        if (b.receiver != address(0)) {
            return b;
        } else {
            return bms.brokers[bms.defaultBroker];
        }
    }

    function updateBrokerCommission(
        address token, uint256 feeAmount, uint24 id
    ) internal returns (uint256, uint24){
        BrokerManagerStorage storage bms = brokerManagerStorage();

        Broker memory b = _getBrokerOrDefault(bms, id);
        uint commission = feeAmount * b.commissionP / 1e4;
        if (commission > 0) {
            Commission storage c = bms.brokerCommissions[b.id][token];
            if (c.total == 0) {
                bms.brokerCommissionTokens[b.id].push(token);
            }
            c.total += commission;
            c.pending += commission;
            bms.allPendingCommissions[token] += commission;
        }
        return (commission, b.id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IArbSys.sol";

library LibChain {
    uint256 public constant ARBITRUM_MAINNET = 42161;
    uint256 public constant ARBITRUM_TESTNET = 421613;
    IArbSys public constant ARBITRUM_SYS = IArbSys(address(100));

    function getBlockHash(uint256 blockNumber) internal view returns (bytes32) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_TESTNET) {
            return ARBITRUM_SYS.arbBlockHash(blockNumber);
        }

        return blockhash(blockNumber);
    }

    function getBlockNumber() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_TESTNET) {
            return ARBITRUM_SYS.arbBlockNumber();
        }

        return block.number;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library LibChainlinkPrice {

    bytes32 constant CHAINLINK_PRICE_POSITION = keccak256("shardex.chainlink.price.storage");

    struct PriceFeed {
        address tokenAddress;
        address feedAddress;
        uint32 tokenAddressPosition;
    }

    struct ChainlinkPriceStorage {
        mapping(address => PriceFeed) priceFeeds;
        address[] tokenAddresses;
    }

    function chainlinkPriceStorage() internal pure returns (ChainlinkPriceStorage storage cps) {
        bytes32 position = CHAINLINK_PRICE_POSITION;
        assembly {
            cps.slot := position
        }
    }

    event SupportChainlinkPriceFeed(address indexed token, address indexed priceFeed, bool supported);

    function addChainlinkPriceFeed(address tokenAddress, address priceFeed) internal {
        ChainlinkPriceStorage storage cps = chainlinkPriceStorage();
        PriceFeed storage pf = cps.priceFeeds[tokenAddress];
        require(pf.feedAddress == address(0), "LibChainlinkPrice: Can't add price feed that already exists");
        AggregatorV3Interface oracle = AggregatorV3Interface(priceFeed);
        (, int256 price, ,,) = oracle.latestRoundData();
        require(price > 0, "LibChainlinkPrice: Invalid priceFeed address");
        pf.tokenAddress = tokenAddress;
        pf.feedAddress = priceFeed;
        pf.tokenAddressPosition = uint32(cps.tokenAddresses.length);

        cps.tokenAddresses.push(tokenAddress);
        emit SupportChainlinkPriceFeed(tokenAddress, priceFeed, true);
    }

    function removeChainlinkPriceFeed(address tokenAddress) internal {
        ChainlinkPriceStorage storage cps = chainlinkPriceStorage();
        PriceFeed storage pf = cps.priceFeeds[tokenAddress];
        address priceFeed = pf.feedAddress;
        require(priceFeed != address(0), "LibChainlinkPrice: Price feed does not exist");

        uint256 lastPosition = cps.tokenAddresses.length - 1;
        uint256 tokenAddressPosition = pf.tokenAddressPosition;
        if (tokenAddressPosition != lastPosition) {
            address lastTokenAddress = cps.tokenAddresses[lastPosition];
            cps.tokenAddresses[tokenAddressPosition] = lastTokenAddress;
            cps.priceFeeds[lastTokenAddress].tokenAddressPosition = uint32(tokenAddressPosition);
        }
        cps.tokenAddresses.pop();
        delete cps.priceFeeds[tokenAddress];
        emit SupportChainlinkPriceFeed(tokenAddress, priceFeed, false);
    }

    function getPriceFromChainlink(address token) internal view returns (uint256 price, uint8 decimals, uint256 updateTime) {
        ChainlinkPriceStorage storage cps = chainlinkPriceStorage();
        address priceFeed = cps.priceFeeds[token].feedAddress;
        require(priceFeed != address(0), "LibChainlinkPrice: Price feed does not exist");
        AggregatorV3Interface oracle = AggregatorV3Interface(priceFeed);
        (, int256 price_, ,uint256 updatedAt,) = oracle.latestRoundData();
        require(price_ > 0, "LibChainlinkPrice: price cannot be negative");
        price = uint256(price_);
        decimals = oracle.decimals();
        return (price, decimals, updatedAt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import  "../interfaces/IDiamondCut.sol";

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Used in ReentrancyGuard
        uint256 status;
        bool paused;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length;) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            bytes4[] memory _functionSelectors = _diamondCut[facetIndex].functionSelectors;
            require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
            unchecked {
                facetIndex++;
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
            unchecked {
                selectorIndex++;
            }
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
            unchecked {
                selectorIndex++;
            }
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
            unchecked {
                selectorIndex++;
            }
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import "../interfaces/IFeeManager.sol";
import "./LibVault.sol";
import "./LibBrokerManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibFeeManager {

    using SafeERC20 for IERC20;

    bytes32 constant FEE_MANAGER_STORAGE_POSITION = keccak256("shardex.fee.manager.storage");

    struct FeeConfig {
        string name;
        uint16 index;
        uint16 openFeeP;     // 1e4
        uint16 closeFeeP;    // 1e4
        bool enable;
    }

    struct FeeManagerStorage {
        // 0/1/2/3/.../ => FeeConfig
        mapping(uint16 => FeeConfig) feeConfigs;
        // feeConfig index => pair.base[]
        mapping(uint16 => address[]) feeConfigPairs;
        // USDT/USDC/.../ => FeeDetail
        mapping(address => IFeeManager.FeeDetail) feeDetails;
        address daoRepurchase;
        uint16 daoShareP;       // 1e4
    }

    function feeManagerStorage() internal pure returns (FeeManagerStorage storage fms) {
        bytes32 position = FEE_MANAGER_STORAGE_POSITION;
        assembly {
            fms.slot := position
        }
    }

    event AddFeeConfig(uint16 indexed index, uint16 openFeeP, uint16 closeFeeP, string name);
    event RemoveFeeConfig(uint16 indexed index);
    event UpdateFeeConfig(uint16 indexed index,
        uint16 oldOpenFeeP, uint16 oldCloseFeeP,
        uint16 openFeeP, uint16 closeFeeP
    );
    event SetDaoRepurchase(address indexed oldDaoRepurchase, address daoRepurchase);
    event SetDaoShareP(uint16 oldDaoShareP, uint16 daoShareP);
    event OpenFee(address indexed token, uint256 totalFee, uint256 daoAmount, uint24 brokerId, uint256 brokerAmount);
    event CloseFee(address indexed token, uint256 totalFee, uint256 daoAmount, uint24 brokerId, uint256 brokerAmount);

    function initialize(address daoRepurchase, uint16 daoShareP) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        require(fms.daoRepurchase == address(0), "LibFeeManager: Already initialized");
        setDaoRepurchase(daoRepurchase);
        setDaoShareP(daoShareP);
        // default fee config
        fms.feeConfigs[0] = FeeConfig("Default Fee Rate", 0, 8, 8, true);
        emit AddFeeConfig(0, 8, 8, "Default Fee Rate");
    }

    function addFeeConfig(uint16 index, string calldata name, uint16 openFeeP, uint16 closeFeeP) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        FeeConfig storage config = fms.feeConfigs[index];
        require(!config.enable, "LibFeeManager: Configuration already exists");
        config.index = index;
        config.name = name;
        config.openFeeP = openFeeP;
        config.closeFeeP = closeFeeP;
        config.enable = true;
        emit AddFeeConfig(index, openFeeP, closeFeeP, name);
    }

    function removeFeeConfig(uint16 index) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        FeeConfig storage config = fms.feeConfigs[index];
        require(config.enable, "LibFeeManager: Configuration not enabled");
        require(fms.feeConfigPairs[index].length == 0, "LibFeeManager: Cannot remove a configuration that is still in use");
        delete fms.feeConfigs[index];
        emit RemoveFeeConfig(index);
    }

    function updateFeeConfig(uint16 index, uint16 openFeeP, uint16 closeFeeP) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        FeeConfig storage config = fms.feeConfigs[index];
        require(config.enable, "LibFeeManager: Configuration not enabled");
        (uint16 oldOpenFeeP, uint16 oldCloseFeeP) = (config.openFeeP, config.closeFeeP);
        config.openFeeP = openFeeP;
        config.closeFeeP = closeFeeP;
        emit UpdateFeeConfig(index, oldOpenFeeP, oldCloseFeeP, openFeeP, closeFeeP);
    }

    function setDaoRepurchase(address daoRepurchase) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        address oldDaoRepurchase = fms.daoRepurchase;
        fms.daoRepurchase = daoRepurchase;
        emit SetDaoRepurchase(oldDaoRepurchase, daoRepurchase);
    }

    function setDaoShareP(uint16 daoShareP) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        require(daoShareP <= Constants.MAX_DAO_SHARE_P, "LibFeeManager: Invalid allocation ratio");
        uint16 oldDaoShareP = fms.daoShareP;
        fms.daoShareP = daoShareP;
        emit SetDaoShareP(oldDaoShareP, daoShareP);
    }

    function getFeeConfigByIndex(uint16 index) internal view returns (FeeConfig memory, address[] storage) {
        FeeManagerStorage storage fms = feeManagerStorage();
        return (fms.feeConfigs[index], fms.feeConfigPairs[index]);
    }

    function chargeOpenFee(address token, uint256 feeAmount, uint24 broker) internal returns (uint24){
        FeeManagerStorage storage fms = feeManagerStorage();
        IFeeManager.FeeDetail storage detail = fms.feeDetails[token];

        uint256 daoShare = feeAmount * fms.daoShareP / 1e4;
        if (daoShare > 0) {
            IERC20(token).safeTransfer(fms.daoRepurchase, daoShare);
            detail.daoAmount += daoShare;
        }
        detail.total += feeAmount;
        (uint256 commission, uint24 brokerId) = LibBrokerManager.updateBrokerCommission(token, feeAmount, broker);
        detail.brokerAmount += commission;

        uint256 lpAmount = feeAmount - daoShare - commission;
        LibVault.deposit(token, lpAmount);
        emit OpenFee(token, feeAmount, daoShare, brokerId, commission);
        return brokerId;
    }

    function chargeCloseFee(address token, uint256 feeAmount, uint24 broker) internal {
        FeeManagerStorage storage fms = feeManagerStorage();
        IFeeManager.FeeDetail storage detail = fms.feeDetails[token];

        uint256 daoShare = feeAmount * fms.daoShareP / 1e4;
        if (daoShare > 0) {
            IERC20(token).safeTransfer(fms.daoRepurchase, daoShare);
            detail.daoAmount += daoShare;
        }
        detail.total += feeAmount;
        (uint256 commission, uint24 brokerId) = LibBrokerManager.updateBrokerCommission(token, feeAmount, broker);
        detail.brokerAmount += commission;

        uint256 lpAmount = feeAmount - daoShare - commission;
        LibVault.deposit(token, lpAmount);
        emit CloseFee(token, feeAmount, daoShare, brokerId, commission);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./LibFeeManager.sol";
import "../interfaces/IPriceFacade.sol";
import "../interfaces/ITradingCore.sol";
import "../interfaces/IPairsManager.sol";
import {ZERO, ONE, UC, uc, into} from "unchecked-counter/src/UC.sol";

library LibPairsManager {

    bytes32 constant PAIRS_MANAGER_STORAGE_POSITION = keccak256("shardex.pairs.manager.storage");

    /*
       tier    notionalUsd     maxLeverage      initialLostP        liqLostP
        1      (0 ~ 10,000]        20              95%                97.5%
        2    (10,000 ~ 50,000]     10              90%                 95%
        3    (50,000 ~ 100,000]     5              80%                 90%
        4    (100,000 ~ 200,000]    3              75%                 85%
        5    (200,000 ~ 500,000]    2              60%                 75%
        6    (500,000 ~ 800,000]    1              40%                 50%
    */
    struct LeverageMargin {
        uint256 notionalUsd;
        uint16 tier;
        uint16 maxLeverage;
        uint16 initialLostP; // 1e4
        uint16 liqLostP;     // 1e4
    }

    struct SlippageConfig {
        string name;
        uint256 onePercentDepthAboveUsd;
        uint256 onePercentDepthBelowUsd;
        uint16 slippageLongP;       // 1e4
        uint16 slippageShortP;      // 1e4
        uint16 index;
        IPairsManager.SlippageType slippageType;
        bool enable;
    }

    struct Pair {
        // BTC/USD
        string name;
        // BTC address
        address base;
        uint16 basePosition;
        IPairsManager.PairType pairType;
        IPairsManager.PairStatus status;

        uint16 slippageConfigIndex;
        uint16 slippagePosition;

        uint16 feeConfigIndex;
        uint16 feePosition;

        uint256 maxLongOiUsd;
        uint256 maxShortOiUsd;
        uint256 fundingFeePerBlockP;  // 1e18
        uint256 minFundingFeeR;       // 1e18
        uint256 maxFundingFeeR;       // 1e18
        // tier => LeverageMargin
        mapping(uint16 => LeverageMargin) leverageMargins;
        uint16 maxTier;
    }

    struct PairsManagerStorage {
        // 0/1/2/3/.../ => SlippageConfig
        mapping(uint16 => SlippageConfig) slippageConfigs;
        // SlippageConfig index => pairs.base[]
        mapping(uint16 => address[]) slippageConfigPairs;
        mapping(address => Pair) pairs;
        address[] pairBases;
    }

    function pairsManagerStorage() internal pure returns (PairsManagerStorage storage pms) {
        bytes32 position = PAIRS_MANAGER_STORAGE_POSITION;
        assembly {
            pms.slot := position
        }
    }

    event AddSlippageConfig(
        uint16 indexed index, IPairsManager.SlippageType indexed slippageType,
        uint256 onePercentDepthAboveUsd, uint256 onePercentDepthBelowUsd,
        uint16 slippageLongP, uint16 slippageShortP, string name
    );
    event RemoveSlippageConfig(uint16 indexed index);
    event UpdateSlippageConfig(
        uint16 indexed index, IPairsManager.SlippageType indexed slippageType,
        uint256 onePercentDepthAboveUsd, uint256 onePercentDepthBelowUsd,
        uint16 slippageLongP, uint16 slippageShortP
    );
    event AddPair(
        address indexed base,
        IPairsManager.PairType indexed pairType, IPairsManager.PairStatus indexed status,
        uint16 slippageConfigIndex, uint16 feeConfigIndex,
        string name, LeverageMargin[] leverageMargins
    );
    event UpdatePairMaxOi(
        address indexed base,
        uint256 OldMaxLongOiUsd, uint256 oldMaxShortOiUsd,
        uint256 maxLongOiUsd, uint256 maxShortOiUsd
    );
    event UpdatePairFundingFeeConfig(
        address indexed base,
        uint256 oldFundingFeePerBlockP, uint256 oldMinFundingFeeR, uint256 oldMaxFundingFeeR,
        uint256 fundingFeePerBlockP, uint256 minFundingFeeR, uint256 maxFundingFeeR
    );
    event RemovePair(address indexed base);
    event UpdatePairStatus(
        address indexed base,
        IPairsManager.PairStatus indexed oldStatus,
        IPairsManager.PairStatus indexed status
    );
    event UpdatePairSlippage(address indexed base, uint16 indexed oldSlippageConfigIndexed, uint16 indexed slippageConfigIndex);
    event UpdatePairFee(address indexed base, uint16 indexed oldFeeConfigIndex, uint16 indexed feeConfigIndex);
    event UpdatePairLeverageMargin(address indexed base, LeverageMargin[] leverageMargins);

    function addSlippageConfig(
        uint16 index, string calldata name, IPairsManager.SlippageType slippageType,
        uint256 onePercentDepthAboveUsd, uint256 onePercentDepthBelowUsd,
        uint16 slippageLongP, uint16 slippageShortP
    ) internal {
        PairsManagerStorage storage pms = pairsManagerStorage();
        SlippageConfig storage config = pms.slippageConfigs[index];
        require(!config.enable, "LibPairsManager: Configuration already exists");
        if (slippageType == IPairsManager.SlippageType.ONE_PERCENT_DEPTH) {
            require(onePercentDepthAboveUsd > 0 && onePercentDepthBelowUsd > 0, "LibPairsManager: Invalid dynamic slippage parameter configuration");
        }
        config.index = index;
        config.name = name;
        config.enable = true;
        config.slippageType = slippageType;
        config.onePercentDepthAboveUsd = onePercentDepthAboveUsd;
        config.onePercentDepthBelowUsd = onePercentDepthBelowUsd;
        config.slippageLongP = slippageLongP;
        config.slippageShortP = slippageShortP;
        emit AddSlippageConfig(index, slippageType, onePercentDepthAboveUsd,
            onePercentDepthBelowUsd, slippageLongP, slippageShortP, name);
    }

    function removeSlippageConfig(uint16 index) internal {
        PairsManagerStorage storage pms = pairsManagerStorage();
        SlippageConfig storage config = pms.slippageConfigs[index];
        require(config.enable, "LibPairsManager: Configuration not enabled");
        require(pms.slippageConfigPairs[index].length == 0, "LibPairsManager: Cannot remove a configuration that is still in use");
        delete pms.slippageConfigs[index];
        emit RemoveSlippageConfig(index);
    }

    function updateSlippageConfig(SlippageConfig memory sc) internal {
        PairsManagerStorage storage pms = pairsManagerStorage();
        SlippageConfig storage config = pms.slippageConfigs[sc.index];
        require(config.enable, "LibPairsManager: Configuration not enabled");
        if (sc.slippageType == IPairsManager.SlippageType.ONE_PERCENT_DEPTH) {
            require(sc.onePercentDepthAboveUsd > 0 && sc.onePercentDepthBelowUsd > 0, "LibPairsManager: Invalid dynamic slippage parameter configuration");
        }

        config.slippageType = sc.slippageType;
        config.onePercentDepthAboveUsd = sc.onePercentDepthAboveUsd;
        config.onePercentDepthBelowUsd = sc.onePercentDepthBelowUsd;
        config.slippageLongP = sc.slippageLongP;
        config.slippageShortP = sc.slippageShortP;
        emit UpdateSlippageConfig(
            sc.index, sc.slippageType, sc.onePercentDepthAboveUsd, sc.onePercentDepthBelowUsd,
            sc.slippageLongP, sc.slippageShortP
        );
    }

    function addPair(
        IPairsManager.PairSimple memory ps,
        uint16 slippageConfigIndex, uint16 feeConfigIndex,
        LeverageMargin[] calldata leverageMargins
    ) internal {
        PairsManagerStorage storage pms = pairsManagerStorage();
        require(pms.pairBases.length < 70, "LibPairsManager: Exceed the maximum number");
        Pair storage pair = pms.pairs[ps.base];
        require(pair.base == address(0), "LibPairsManager: Pair already exists");
        require(IPriceFacade(address(this)).getPrice(ps.base) > 0, "LibPairsManager: No price feed has been configured for the pair");
        {
            SlippageConfig memory slippageConfig = pms.slippageConfigs[slippageConfigIndex];
            require(slippageConfig.enable, "LibPairsManager: Slippage configuration is not available");
            (LibFeeManager.FeeConfig memory feeConfig, address[] storage feePairs) = LibFeeManager.getFeeConfigByIndex(feeConfigIndex);
            require(feeConfig.enable, "LibPairsManager: Fee configuration is not available");

            pair.slippageConfigIndex = slippageConfigIndex;
            address[] storage slippagePairs = pms.slippageConfigPairs[slippageConfigIndex];
            pair.slippagePosition = uint16(slippagePairs.length);
            slippagePairs.push(ps.base);

            pair.feeConfigIndex = feeConfigIndex;
            pair.feePosition = uint16(feePairs.length);
            feePairs.push(ps.base);
        }
        pair.name = ps.name;
        pair.base = ps.base;
        pair.basePosition = uint16(pms.pairBases.length);
        pms.pairBases.push(ps.base);
        pair.pairType = ps.pairType;
        pair.status = ps.status;
        pair.maxTier = uint16(leverageMargins.length);
        for (UC i = ONE; i <= uc(leverageMargins.length); i = i + ONE) {
            pair.leverageMargins[uint16(i.into())] = leverageMargins[uint16(i.into() - 1)];
        }
        emit AddPair(ps.base, ps.pairType, ps.status, slippageConfigIndex, feeConfigIndex, ps.name, leverageMargins);
    }

    function updatePairMaxOi(address base, uint256 maxLongOiUsd, uint256 maxShortOiUsd) internal {
        PairsManagerStorage storage pms = pairsManagerStorage();
        Pair storage pair = pms.pairs[base];
        require(pair.base != address(0), "LibPairsManager: Pair does not exist");

        uint256 oldMaxLongOiUsd = pair.maxLongOiUsd;
        uint256 oldMaxShortOiUsd = pair.maxShortOiUsd;
        pair.maxLongOiUsd = maxLongOiUsd;
        pair.maxShortOiUsd = maxShortOiUsd;
        emit UpdatePairMaxOi(base, oldMaxLongOiUsd, oldMaxShortOiUsd, maxLongOiUsd, maxShortOiUsd);
    }

    function updatePairFundingFeeConfig(address base, uint256 fundingFeePerBlockP, uint256 minFundingFeeR, uint256 maxFundingFeeR) internal {
        require(maxFundingFeeR > minFundingFeeR, "LibPairsManager: fundingFee parameter is invalid");
        PairsManagerStorage storage pms = pairsManagerStorage();
        Pair storage pair = pms.pairs[base];
        require(pair.base != address(0), "LibPairsManager: Pair does not exist");

        uint256 oldFundingFeePerBlockP = pair.fundingFeePerBlockP;
        uint256 oldMinFundingFeeR = pair.minFundingFeeR;
        uint256 oldMaxFundingFeeR = pair.maxFundingFeeR;
        pair.fundingFeePerBlockP = fundingFeePerBlockP;
        pair.minFundingFeeR = minFundingFeeR;
        pair.maxFundingFeeR = maxFundingFeeR;
        emit UpdatePairFundingFeeConfig(
            base, oldFundingFeePerBlockP, oldMinFundingFeeR, oldMaxFundingFeeR,
            fundingFeePerBlockP, minFundingFeeR, maxFundingFeeR
        );
    }

    function removePair(address base) internal {
        PairsManagerStorage storage pms = pairsManagerStorage();
        Pair storage pair = pms.pairs[base];
        require(pair.base != address(0), "LibPairsManager: Pair does not exist");

        ITradingCore.PairQty memory pairQty = ITradingCore(address(this)).getPairQty(base);
        require(pairQty.longQty == 0 && pairQty.shortQty == 0, "LibPairsManager: Position is not 0");

        address[] storage slippagePairs = pms.slippageConfigPairs[pair.slippageConfigIndex];
        uint lastPositionSlippage = slippagePairs.length - 1;
        uint slippagePosition = pair.slippagePosition;
        if (slippagePosition != lastPositionSlippage) {
            address lastBase = slippagePairs[lastPositionSlippage];
            slippagePairs[slippagePosition] = lastBase;
            pms.pairs[lastBase].slippagePosition = uint16(slippagePosition);
        }
        slippagePairs.pop();

        (, address[] storage feePairs) = LibFeeManager.getFeeConfigByIndex(pair.feeConfigIndex);
        uint lastPositionFee = feePairs.length - 1;
        uint feePosition = pair.feePosition;
        if (feePosition != lastPositionFee) {
            address lastBase = feePairs[lastPositionFee];
            feePairs[feePosition] = lastBase;
            pms.pairs[lastBase].feePosition = uint16(feePosition);
        }
        feePairs.pop();

        address[] storage pairBases = pms.pairBases;
        uint lastPositionBase = pairBases.length - 1;
        uint basePosition = pair.basePosition;
        if (basePosition != lastPositionBase) {
            address lastBase = pairBases[lastPositionBase];
            pairBases[basePosition] = lastBase;
            pms.pairs[lastBase].basePosition = uint16(basePosition);
        }
        pairBases.pop();
        // Removing a pair does not delete the leverageMargins mapping data from the Pair struct.
        // If the pair is added again, a new leverageMargins value will be set during the addition,
        // which will overwrite the previous old value.
        delete pms.pairs[base];
        emit RemovePair(base);
    }

    function updatePairStatus(address base, IPairsManager.PairStatus status) internal {
        Pair storage pair = pairsManagerStorage().pairs[base];
        require(pair.base != address(0), "LibPairsManager: Pair does not exist");
        require(pair.status != status, "LibPairsManager: No change in status, no modification required");
        IPairsManager.PairStatus oldStatus = pair.status;
        pair.status = status;
        emit UpdatePairStatus(base, oldStatus, status);
    }

    function batchUpdatePairStatus(IPairsManager.PairType pairType, IPairsManager.PairStatus status) internal {
        PairsManagerStorage storage pms = pairsManagerStorage();
        address[] memory pairBases = pms.pairBases;
        for (UC i = ZERO; i < uc(pairBases.length); i = i + ONE) {
            Pair storage pair = pms.pairs[pairBases[i.into()]];
            if (pair.pairType == pairType) {
                IPairsManager.PairStatus oldStatus = pair.status;
                pair.status = status;
                emit UpdatePairStatus(pair.base, oldStatus, status);
            }
        }
    }

    function updatePairSlippage(address base, uint16 slippageConfigIndex) internal {
        PairsManagerStorage storage pms = pairsManagerStorage();
        Pair storage pair = pms.pairs[base];
        require(pair.base != address(0), "LibPairsManager: Pair does not exist");
        SlippageConfig memory config = pms.slippageConfigs[slippageConfigIndex];
        require(config.enable, "LibPairsManager: Slippage configuration is not available");

        uint16 oldSlippageConfigIndex = pair.slippageConfigIndex;
        address[] storage oldSlippagePairs = pms.slippageConfigPairs[oldSlippageConfigIndex];
        uint lastPositionSlippage = oldSlippagePairs.length - 1;
        uint oldSlippagePosition = pair.slippagePosition;
        if (oldSlippagePosition != lastPositionSlippage) {
            pms.pairs[oldSlippagePairs[lastPositionSlippage]].slippagePosition = uint16(oldSlippagePosition);
            oldSlippagePairs[oldSlippagePosition] = oldSlippagePairs[lastPositionSlippage];
        }
        oldSlippagePairs.pop();

        pair.slippageConfigIndex = slippageConfigIndex;
        address[] storage slippagePairs = pms.slippageConfigPairs[slippageConfigIndex];
        pair.slippagePosition = uint16(slippagePairs.length);
        slippagePairs.push(base);
        emit UpdatePairSlippage(base, oldSlippageConfigIndex, slippageConfigIndex);
    }

    function updatePairFee(address base, uint16 feeConfigIndex) internal {
        PairsManagerStorage storage pms = pairsManagerStorage();
        Pair storage pair = pms.pairs[base];
        require(pair.base != address(0), "LibPairsManager: Pair does not exist");
        (LibFeeManager.FeeConfig memory feeConfig, address[] storage feePairs) = LibFeeManager.getFeeConfigByIndex(feeConfigIndex);
        require(feeConfig.enable, "LibPairsManager: Fee configuration is not available");

        uint16 oldFeeConfigIndex = pair.feeConfigIndex;
        (, address[] storage oldFeePairs) = LibFeeManager.getFeeConfigByIndex(oldFeeConfigIndex);
        uint lastPositionFee = oldFeePairs.length - 1;
        uint oldFeePosition = pair.feePosition;
        if (oldFeePosition != lastPositionFee) {
            pms.pairs[oldFeePairs[lastPositionFee]].feePosition = uint16(oldFeePosition);
            oldFeePairs[oldFeePosition] = oldFeePairs[lastPositionFee];
        }
        oldFeePairs.pop();

        pair.feeConfigIndex = feeConfigIndex;
        pair.feePosition = uint16(feePairs.length);
        feePairs.push(base);
        emit UpdatePairFee(base, oldFeeConfigIndex, feeConfigIndex);
    }

    function updatePairLeverageMargin(address base, LeverageMargin[] calldata leverageMargins) internal {
        PairsManagerStorage storage pms = pairsManagerStorage();
        Pair storage pair = pms.pairs[base];
        require(pair.base != address(0), "LibPairsManager: Pair does not exist");

        uint maxTier = pair.maxTier > leverageMargins.length ? pair.maxTier : leverageMargins.length;
        for (UC i = ONE; i <= uc(maxTier); i = i + ONE) {
            if (i <= uc(leverageMargins.length)) {
                pair.leverageMargins[uint16(i.into())] = leverageMargins[uint16(i.into() - 1)];
            } else {
                delete pair.leverageMargins[uint16(i.into())];
            }
        }
        pair.maxTier = uint16(leverageMargins.length);
        emit UpdatePairLeverageMargin(base, leverageMargins);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import "../interfaces/ITradingOpen.sol";
import "../interfaces/ITradingClose.sol";
import "./LibChain.sol";
import "./LibChainlinkPrice.sol";
import {ZERO, ONE, UC, uc, into} from "unchecked-counter/src/UC.sol";

library LibPriceFacade {

    bytes32 constant PRICE_FACADE_POSITION = keccak256("shardex.price.facade.storage");

    struct LatestCallbackPrice {
        uint64 price;
        uint40 timestamp;
    }

    struct OpenOrClose {
        bytes32 id;
        bool isOpen;
    }

    struct PendingPrice {
        uint256 blockNumber;
        address token;
        OpenOrClose[] ids;
    }

    struct PriceFacadeStorage {
        // BTC/ETH/ARB/.../ =>
        mapping(address => LatestCallbackPrice) callbackPrices;
        // keccak256(token, block.number) =>
        mapping(bytes32 => PendingPrice) pendingPrices;
        uint16 lowPriceGapP;   // 1e4
        uint16 highPriceGapP;  // 1e4
        uint16 maxDelay;
    }

    function priceFacadeStorage() internal pure returns (PriceFacadeStorage storage pfs) {
        bytes32 position = PRICE_FACADE_POSITION;
        assembly {
            pfs.slot := position
        }
    }

    event SetLowPriceGapP(uint16 indexed oldLowPriceGapP, uint16 indexed lowPriceGapP);
    event SetHighPriceGapP(uint16 indexed oldHighPriceGapP, uint16 indexed highPriceGapP);
    event SetMaxDelay(uint16 indexed oldMaxDelay, uint16 indexed maxDelay);
    event RequestPrice(bytes32 indexed requestId, address indexed token);
    event PriceRejected(
        address indexed feeder, bytes32 indexed requestId, address indexed token,
        uint64 price, uint64 beforePrice, uint40 updatedAt
    );
    event PriceUpdated(
        address indexed feeder, bytes32 indexed requestId,
        address indexed token, uint64 price
    );

    function initialize(uint16 lowPriceGapP, uint16 highPriceGapP, uint16 maxDelay) internal {
        PriceFacadeStorage storage pfs = priceFacadeStorage();
        require(pfs.lowPriceGapP == 0 && pfs.highPriceGapP == 0 && pfs.maxDelay == 0, "LibPriceFacade: Already initialized");
        _setLowPriceGapP(pfs, lowPriceGapP);
        _setHighPriceGapP(pfs, highPriceGapP);
        setMaxDelay(maxDelay);
    }

    function _setLowPriceGapP(PriceFacadeStorage storage pfs, uint16 lowPriceGapP) private {
        uint16 old = pfs.lowPriceGapP;
        pfs.lowPriceGapP = lowPriceGapP;
        emit SetLowPriceGapP(old, lowPriceGapP);
    }

    function _setHighPriceGapP(PriceFacadeStorage storage pfs, uint16 highPriceGapP) private {
        uint16 old = pfs.highPriceGapP;
        pfs.highPriceGapP = highPriceGapP;
        emit SetHighPriceGapP(old, highPriceGapP);
    }

    function setLowAndHighPriceGapP(uint16 lowPriceGapP, uint16 highPriceGapP) internal {
        PriceFacadeStorage storage pfs = priceFacadeStorage();
        if (lowPriceGapP > 0 && highPriceGapP > 0) {
            require(highPriceGapP > lowPriceGapP, "LibPriceFacade: highPriceGapP must be greater than lowPriceGapP");
            _setLowPriceGapP(pfs, lowPriceGapP);
            _setHighPriceGapP(pfs, highPriceGapP);
        } else if (lowPriceGapP > 0) {
            require(pfs.highPriceGapP > lowPriceGapP, "LibPriceFacade: highPriceGapP must be greater than lowPriceGapP");
            _setLowPriceGapP(pfs, lowPriceGapP);
        } else {
            require(highPriceGapP > pfs.lowPriceGapP, "LibPriceFacade: highPriceGapP must be greater than lowPriceGapP");
            _setHighPriceGapP(pfs, highPriceGapP);
        }
    }

    function setMaxDelay(uint16 maxDelay) internal {
        PriceFacadeStorage storage pfs = priceFacadeStorage();
        uint16 old = pfs.maxDelay;
        pfs.maxDelay = maxDelay;
        emit SetMaxDelay(old, maxDelay);
    }

    function getPrice(address token) internal view returns (uint256) {
        (uint256 price, uint8 decimals,) = LibChainlinkPrice.getPriceFromChainlink(token);
        return decimals == 8 ? price : price * 1e8 / (10 ** decimals);
    }

    function requestPrice(bytes32 id, address token, bool isOpen) internal {
        PriceFacadeStorage storage pfs = priceFacadeStorage();
        bytes32 requestId = keccak256(abi.encode(token, LibChain.getBlockNumber()));
        PendingPrice storage pendingPrice = pfs.pendingPrices[requestId];
        require(pendingPrice.ids.length < Constants.MAX_REQUESTS_PER_PAIR_IN_BLOCK, "LibPriceFacade: The requests for price retrieval are too frequent.");
        pendingPrice.ids.push(OpenOrClose(id, isOpen));
        if (pendingPrice.blockNumber != LibChain.getBlockNumber()) {
            pendingPrice.token = token;
            pendingPrice.blockNumber = LibChain.getBlockNumber();
            emit RequestPrice(requestId, token);
        }
    }

    function requestPriceCallback(bytes32 requestId, uint64 price) internal {
        PriceFacadeStorage storage pfs = priceFacadeStorage();
        PendingPrice memory pendingPrice = pfs.pendingPrices[requestId];
        OpenOrClose[] memory ids = pendingPrice.ids;
        require(pendingPrice.blockNumber > 0 && ids.length > 0, "LibPriceFacade: requestId does not exist");

        (uint64 beforePrice, uint40 updatedAt) = getPriceFromCacheOrOracle(pfs, pendingPrice.token);
        uint64 priceGap = price > beforePrice ? price - beforePrice : beforePrice - price;
        uint gapPercentage = priceGap * 1e4 / beforePrice;
        // Excessive price difference. Reject this price
        if (gapPercentage > pfs.highPriceGapP) {
            emit PriceRejected(msg.sender, requestId, pendingPrice.token, price, beforePrice, updatedAt);
            return;
        }
        LatestCallbackPrice storage cachePrice = pfs.callbackPrices[pendingPrice.token];
        cachePrice.timestamp = uint40(block.timestamp);
        cachePrice.price = price;
        // The time interval is too long.
        // receive the current price but not use it
        // and wait for the next price to be fed.
        if (block.timestamp > updatedAt + pfs.maxDelay) {
            emit PriceRejected(msg.sender, requestId, pendingPrice.token, price, beforePrice, updatedAt);
            return;
        }
        uint64 upperPrice = price;
        uint64 lowerPrice = price;
        if (gapPercentage > pfs.lowPriceGapP) {
            (upperPrice, lowerPrice) = price > beforePrice ? (price, beforePrice) : (beforePrice, price);
        }
        for (UC i = ZERO; i < uc(ids.length); i = i + ONE) {
            OpenOrClose memory openOrClose = ids[i.into()];
            if (openOrClose.isOpen) {
                ITradingOpen(address(this)).marketTradeCallback(openOrClose.id, upperPrice, lowerPrice);
            } else {
                ITradingClose(address(this)).closeTradeCallback(openOrClose.id, upperPrice, lowerPrice);
            }
        }
        // Deleting data can save a little gas
        emit PriceUpdated(msg.sender, requestId, pendingPrice.token, price);
        delete pfs.pendingPrices[requestId];
    }

    function getPriceFromCacheOrOracle(address token) internal view returns (uint64, uint40) {
        return getPriceFromCacheOrOracle(priceFacadeStorage(), token);
    }

    function getPriceFromCacheOrOracle(PriceFacadeStorage storage pfs, address token) internal view returns (uint64, uint40) {
        LatestCallbackPrice memory cachePrice = pfs.callbackPrices[token];
        (uint256 price, uint8 decimals, uint256 oracleUpdatedAt) = LibChainlinkPrice.getPriceFromChainlink(token);
        require(price <= type(uint64).max, "LibPriceFacade: Invalid price");
        uint40 updatedAt = cachePrice.timestamp >= oracleUpdatedAt ? cachePrice.timestamp : uint40(oracleUpdatedAt);
        // Take the newer price
        uint64 tokenPrice = cachePrice.timestamp >= oracleUpdatedAt ? cachePrice.price :
        (decimals == 8 ? uint64(price) : uint64(price * 1e8 / (10 ** decimals)));
        return (tokenPrice, updatedAt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ISdtReward.sol";
import "./LibChain.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibSdtReward {

    using SafeERC20 for IERC20;

    bytes32 constant SDT_REWARD_POSITION = keccak256("shardex.sdt.reward.storage");

    /* ========== STATE VARIABLES ========== */
    struct SdtRewardStorage {
        IERC20 rewardToken;
        // Mining start block
        uint256 startBlock;
        // Info of each pool.
        ISdtReward.SdtPoolInfo poolInfo;
        // Info of each user that stakes LP tokens.
        mapping(address => ISdtReward.SdtUserInfo) userInfo;
    }

    event ClaimSdtReward(address indexed user, uint256 reward);
    event AddReserves(address indexed contributor, uint256 amount);

    function sdtRewardStorage() internal pure returns (SdtRewardStorage storage ars) {
        bytes32 position = SDT_REWARD_POSITION;
        assembly {
            ars.slot := position
        }
    }

    function initialize(address _rewardsToken, uint256 _sdtPerBlock, uint256 _startBlock) internal {
        SdtRewardStorage storage st = sdtRewardStorage();
        require(address(st.rewardToken) == address(0), "Already initialized!");
        st.rewardToken = IERC20(_rewardsToken);
        st.startBlock = _startBlock;
        // staking pool
        st.poolInfo = ISdtReward.SdtPoolInfo({
            totalStaked: 0,
            sdtPerBlock: _sdtPerBlock,
            lastRewardBlock: _startBlock,
            accSDTPerShare: 0,
            totalReward: 0,
            reserves: 0
        });
    }

    /* ========== VIEWS ========== */

    function sdtPoolInfo() internal view returns (ISdtReward.SdtPoolInfo memory poolInfo) {
        SdtRewardStorage storage ars = sdtRewardStorage();
        ISdtReward.SdtPoolInfo storage pool = ars.poolInfo;

        poolInfo.totalStaked = pool.totalStaked;
        poolInfo.sdtPerBlock = pool.sdtPerBlock;
        poolInfo.lastRewardBlock = pool.lastRewardBlock;
        poolInfo.accSDTPerShare = pool.accSDTPerShare;

        uint256 sdtReward;
        if (LibChain.getBlockNumber() > pool.lastRewardBlock && pool.totalStaked != 0) {
            uint256 blockGap = LibChain.getBlockNumber() - pool.lastRewardBlock;
            sdtReward = blockGap * pool.sdtPerBlock;
        }
        poolInfo.totalReward = pool.totalReward + sdtReward;
        poolInfo.reserves = pool.reserves;
    }

    // View function to see pending SDTs on frontend.
    function pendingSdt(address _user) internal view returns (uint256) {
        SdtRewardStorage storage st = sdtRewardStorage();
        ISdtReward.SdtPoolInfo storage pool = st.poolInfo;
        ISdtReward.SdtUserInfo storage user = st.userInfo[_user];
        uint256 accSdtPerShare = pool.accSDTPerShare;
        uint256 lpSupply = pool.totalStaked;

        if (LibChain.getBlockNumber() > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blockGap = LibChain.getBlockNumber() - pool.lastRewardBlock;
            uint256 sdtReward = blockGap * pool.sdtPerBlock;
            accSdtPerShare = accSdtPerShare + (sdtReward * 1e12 / lpSupply);
        }
        return user.amount * accSdtPerShare / 1e12 - user.rewardDebt + user.pendingReward;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 _amount) internal {
        SdtRewardStorage storage st = sdtRewardStorage();
        require(_amount > 0, 'Invalid amount');
        require(LibChain.getBlockNumber() >= st.startBlock, "Mining not started yet");
        ISdtReward.SdtPoolInfo storage pool = st.poolInfo;
        ISdtReward.SdtUserInfo storage user = st.userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accSDTPerShare / 1e12 - user.rewardDebt;
            if (pending > 0) {
                user.pendingReward = user.pendingReward + pending;
            }
        }

        pool.totalStaked += _amount;
        user.amount += _amount;
        user.rewardDebt = user.amount * pool.accSDTPerShare / 1e12;
    }

    function unStake(uint256 _amount) internal {
        SdtRewardStorage storage st = sdtRewardStorage();

        ISdtReward.SdtPoolInfo storage pool = st.poolInfo;
        ISdtReward.SdtUserInfo storage user = st.userInfo[msg.sender];

        require(_amount > 0, "Invalid withdraw amount");
        require(user.amount >= _amount, "Insufficient balance");
        updatePool();
        uint256 pending = user.amount * pool.accSDTPerShare / 1e12 - user.rewardDebt;
        if (pending > 0) {
            user.pendingReward = user.pendingReward + pending;
        }

        user.amount -= _amount;
        pool.totalStaked -= _amount;
        user.rewardDebt = user.amount * pool.accSDTPerShare / 1e12;
    }

    function claimSdtReward(address account) internal {
        SdtRewardStorage storage st = sdtRewardStorage();
        ISdtReward.SdtPoolInfo storage pool = st.poolInfo;
        ISdtReward.SdtUserInfo storage user = st.userInfo[account];

        updatePool();
        uint256 pending = user.amount * pool.accSDTPerShare / 1e12 - user.rewardDebt + user.pendingReward;
        if (pending > 0) {
            user.pendingReward = 0;
            user.rewardDebt = user.amount * pool.accSDTPerShare / 1e12;
            require(pool.reserves >= pending, "LibSdtReward: SDT reserves shortage");
            pool.reserves -= pending;
            st.rewardToken.safeTransfer(account, pending);
            emit ClaimSdtReward(account, pending);
        }
    }

    function addReserves(uint256 amount) internal {
        SdtRewardStorage storage ars = sdtRewardStorage();
        ISdtReward.SdtPoolInfo storage pool = ars.poolInfo;
        ars.rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        pool.reserves += amount;
        emit AddReserves(msg.sender, amount);
    }

    function updateSdtPerBlock(uint256 _sdtPerBlock) internal {
        SdtRewardStorage storage st = sdtRewardStorage();
        require(_sdtPerBlock > 0, "sdtPerBlock greater than 0");
        updatePool();
        st.poolInfo.sdtPerBlock = _sdtPerBlock;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() internal {
        SdtRewardStorage storage st = sdtRewardStorage();
        ISdtReward.SdtPoolInfo storage pool = st.poolInfo;
        if (LibChain.getBlockNumber() <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalStaked;
        if (lpSupply == 0) {
            pool.lastRewardBlock = LibChain.getBlockNumber();
            return;
        }
        uint256 blockGap = LibChain.getBlockNumber() - pool.lastRewardBlock;
        uint256 sdtReward = blockGap * pool.sdtPerBlock;
        pool.totalReward = pool.totalReward + sdtReward;
        pool.accSDTPerShare = pool.accSDTPerShare + (sdtReward * 1e12 / lpSupply);
        pool.lastRewardBlock = LibChain.getBlockNumber();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import "../libraries/LibVault.sol";
import "../interfaces/IPriceFacade.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibSlpManager {

    bytes32 constant SLP_MANAGER_STORAGE_POSITION = keccak256("shardex.slp.manager.storage.v2");
    uint8 constant  SLP_DECIMALS = 18;

    struct SlpManagerStorage {
        mapping(address => uint256) lastMintedAt;
        uint256 coolingDuration;
        address slp;
        // blockNumber => SLP Increase in quantity, possibly negative
        mapping(uint256 => int256) slpIncrement;  // obsolete
        uint256 safeguard;  // obsolete
    }

    function slpManagerStorage() internal pure returns (SlpManagerStorage storage ams) {
        bytes32 position = SLP_MANAGER_STORAGE_POSITION;
        assembly {
            ams.slot := position
        }
    }

    function initialize(address slpToken) internal {
        SlpManagerStorage storage ams = slpManagerStorage();
        require(ams.slp == address(0), "LibSlpManager: Already initialized");
        ams.slp = slpToken;
        ams.coolingDuration = 30 minutes;
    }

    event MintAddLiquidity(address indexed account, address indexed token, uint256 amount);
    event BurnRemoveLiquidity(address indexed account, address indexed token, uint256 amount);
    event MintFee(
        address indexed account, address indexed tokenIn, uint256 amountIn,
        uint256 tokenInPrice, uint256 mintFeeUsd, uint256 slpAmount
    );
    event BurnFee(
        address indexed account, address indexed tokenOut, uint256 amountOut,
        uint256 tokenOutPrice, uint256 burnFeeUsd, uint256 slpAmount
    );

    function slpPrice() internal view returns (uint256) {
        int256 totalValueUsd = LibVault.getTotalValueUsd();
        (int256 lpUnPnlUsd,) = ITradingCore(address(this)).lpUnrealizedPnlUsd();
        return _slpPrice(totalValueUsd + lpUnPnlUsd);
    }

    function _slpPrice(int256 totalValueUsd) private view returns (uint256) {
        uint256 totalSupply = IERC20(slpManagerStorage().slp).totalSupply();
        if (totalValueUsd <= 0 && totalSupply > 0) {
            return 0;
        }
        if (totalSupply == 0) {
            return 1e8;
        } else {
            return uint256(totalValueUsd) * 1e8 / totalSupply;
        }
    }

    function mintSlp(address account, address tokenIn, uint256 amount) internal returns (uint256 slpAmount){
        LibVault.AvailableToken memory at = LibVault.vaultStorage().tokens[tokenIn];
        slpAmount = _calculateSlpAmount(at, amount);
        LibVault.deposit(tokenIn, amount, account, false);
        _addMinted(account);
        emit MintAddLiquidity(account, tokenIn, amount);
    }

    function mintSlpETH(address account, uint256 amount) internal returns (uint256 slpAmount){
        address tokenIn = LibVault.WETH();
        LibVault.AvailableToken memory at = LibVault.vaultStorage().tokens[tokenIn];
        slpAmount = _calculateSlpAmount(at, amount);
        LibVault.depositETH(amount);
        _addMinted(account);
        emit MintAddLiquidity(account, tokenIn, amount);
    }

    function _calculateSlpAmount(LibVault.AvailableToken memory at, uint256 amount) private returns (uint256 slpAmount) {
        require(at.tokenAddress != address(0), "LibSlpManager: Token does not exist");
        (int256 lpUnPnlUsd, int256 lpTokenUnPnlUsd) = ITradingCore(address(this)).lpUnrealizedPnlUsd(at.tokenAddress);
        int256 totalValueUsd = LibVault.getTotalValueUsd() + lpUnPnlUsd;
        require(totalValueUsd > 0, "LibSlpManager: LP balance is insufficient");

        (uint256 tokenInPrice,) = IPriceFacade(address(this)).getPriceFromCacheOrOracle(at.tokenAddress);
        uint256 amountUsd = tokenInPrice * amount * 1e10 / (10 ** at.decimals);
        int256 poolTokenInUsd = int256(LibVault.vaultStorage().treasury[at.tokenAddress] * tokenInPrice * 1e10 / (10 ** at.decimals)) + lpTokenUnPnlUsd;
        uint256 afterTaxAmountUsd = amountUsd * (1e4 - _getFeePoint(at, uint256(totalValueUsd), poolTokenInUsd, amountUsd, true)) / 1e4;
        slpAmount = afterTaxAmountUsd * 1e8 / _slpPrice(totalValueUsd);
        emit MintFee(msg.sender, at.tokenAddress, amount, tokenInPrice, amountUsd - afterTaxAmountUsd, slpAmount);
    }

    function _addMinted(address account) private {
        slpManagerStorage().lastMintedAt[account] = block.timestamp;
    }

    function burnSlp(address account, address tokenOut, uint256 slpAmount, address receiver) internal returns (uint256 amountOut) {
        SlpManagerStorage storage ams = slpManagerStorage();
        require(ams.lastMintedAt[account] + ams.coolingDuration <= block.timestamp, "LibSlpManager: Cooling duration not yet passed");
        LibVault.AvailableToken memory at = LibVault.vaultStorage().tokens[tokenOut];
        amountOut = _calculateTokenAmount(at, slpAmount);
        LibVault.withdraw(receiver, tokenOut, amountOut);
        emit BurnRemoveLiquidity(account, tokenOut, amountOut);
    }

    function burnSlpETH(address account, uint256 slpAmount, address payable receiver) internal returns (uint256 amountOut) {
        SlpManagerStorage storage ams = slpManagerStorage();
        require(ams.lastMintedAt[account] + ams.coolingDuration <= block.timestamp, "LibSlpManager: Cooling duration not yet passed");
        address tokenOut = LibVault.WETH();
        LibVault.AvailableToken memory at = LibVault.vaultStorage().tokens[tokenOut];
        amountOut = _calculateTokenAmount(at, slpAmount);
        LibVault.withdrawETH(receiver, amountOut);
        emit BurnRemoveLiquidity(account, tokenOut, amountOut);
    }

    function _calculateTokenAmount(LibVault.AvailableToken memory at, uint256 slpAmount) private returns (uint256 amountOut) {
        require(at.tokenAddress != address(0), "LibSlpManager: Token does not exist");
        (int256 lpUnPnlUsd, int256 lpTokenUnPnlUsd) = ITradingCore(address(this)).lpUnrealizedPnlUsd(at.tokenAddress);
        int256 totalValueUsd = LibVault.getTotalValueUsd() + lpUnPnlUsd;
        require(totalValueUsd > 0, "LibSlpManager: LP balance is insufficient");

        (uint256 tokenOutPrice,) = IPriceFacade(address(this)).getPriceFromCacheOrOracle(at.tokenAddress);
        int256 poolTokenOutUsd = int256(LibVault.vaultStorage().treasury[at.tokenAddress] * tokenOutPrice * 1e10 / (10 ** at.decimals)) + lpTokenUnPnlUsd;
        uint256 amountOutUsd = _slpPrice(totalValueUsd) * slpAmount / 1e8;
        // It is not allowed for the value of any token in the LP to become negative after burning.
        require(poolTokenOutUsd >= int256(amountOutUsd), "LibSlpManager: tokenOut balance is insufficient");
        uint256 afterTaxAmountOutUsd = amountOutUsd * (1e4 - _getFeePoint(at, uint256(totalValueUsd), poolTokenOutUsd, amountOutUsd, false)) / 1e4;
        require(int256(afterTaxAmountOutUsd) <= LibVault.maxWithdrawAbleUsd(totalValueUsd), "LibSlpManager: tokenOut balance is insufficient");
        amountOut = afterTaxAmountOutUsd * (10 ** at.decimals) / (tokenOutPrice * 1e10);
        emit BurnFee(msg.sender, at.tokenAddress, amountOut, tokenOutPrice, amountOutUsd - afterTaxAmountOutUsd, slpAmount);
        return amountOut;
    }

    function _getFeePoint(
        LibVault.AvailableToken memory at, uint256 totalValueUsd,
        int256 poolTokenUsd, uint256 amountUsd, bool increase
    ) private pure returns (uint256) {
        if (!at.dynamicFee) {
            return increase ? at.feeBasisPoints : at.taxBasisPoints;
        }
        uint256 targetValueUsd = totalValueUsd * at.weight / 1e4;
        int256 nextValueUsd = poolTokenUsd + int256(amountUsd);
        if (!increase) {
            // ∵ poolTokenUsd >= amountUsd && amountUsd > 0
            // ∴ poolTokenUsd > 0
            nextValueUsd = poolTokenUsd - int256(amountUsd);
        }

        uint256 initDiff = poolTokenUsd > int256(targetValueUsd)
            ? uint256(poolTokenUsd) - targetValueUsd  // ∵ (poolTokenUsd > targetValueUsd && targetValueUsd > 0) ∴ (poolTokenUsd > 0)
            : uint256(int256(targetValueUsd) - poolTokenUsd);

        uint256 nextDiff = nextValueUsd > int256(targetValueUsd)
            ? uint256(nextValueUsd) - targetValueUsd
            : uint256(int256(targetValueUsd) - nextValueUsd);

        if (nextDiff < initDiff) {
            uint256 feeAdjust = at.taxBasisPoints * initDiff / targetValueUsd;
            return at.feeBasisPoints > feeAdjust ? at.feeBasisPoints - feeAdjust : 0;
        }

        uint256 avgDiff = (initDiff + nextDiff) / 2;
        return at.feeBasisPoints + (avgDiff > targetValueUsd ? at.taxBasisPoints : (at.taxBasisPoints * avgDiff) / targetValueUsd);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./LibChain.sol";
import "../libraries/LibSdtReward.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibStakeReward {

    using SafeERC20 for IERC20;

    bytes32 constant STAKE_REWARD_POSITION = keccak256("shardex.stake.reward.storage.v2");

    /* ========== STATE VARIABLES ========== */
    struct StakeRewardStorage {
        IERC20 stakingToken;
        uint256 totalStaked;
        mapping(address => uint256) userStaked;
        mapping(address => uint256) lastBlockNumberCalled;
    }

    /* ========== EVENTS ========== */
    event Stake(address indexed account, uint256 amount);
    event UnStake(address indexed account, uint256 amount);

    function stakeRewardStorage() internal pure returns (StakeRewardStorage storage st) {
        bytes32 position = STAKE_REWARD_POSITION;
        assembly {
            st.slot := position
        }
    }

    function initialize(address _stakingToken) internal {
        StakeRewardStorage storage st = stakeRewardStorage();
        require(address(st.stakingToken) == address(0), "Already initialized!");
        st.stakingToken = IERC20(_stakingToken);
    }

    /* ========== VIEWS ========== */
    function totalStaked() internal view returns (uint256) {
        StakeRewardStorage storage st = stakeRewardStorage();
        return st.totalStaked;
    }

    function stakeOf(address _user) internal view returns (uint256) {
        StakeRewardStorage storage st = stakeRewardStorage();
        return st.userStaked[_user];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function checkOncePerBlock(address user) internal {
        StakeRewardStorage storage st = stakeRewardStorage();
        require(st.lastBlockNumberCalled[user] < LibChain.getBlockNumber(), "once per block");
        st.lastBlockNumberCalled[user] = LibChain.getBlockNumber();
    }

    function stake(uint256 _amount) internal {
        require(_amount > 0, 'Invalid amount');

        StakeRewardStorage storage st = stakeRewardStorage();
        st.stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        st.userStaked[msg.sender] += _amount;
        st.totalStaked += _amount;
        LibSdtReward.stake(_amount);
        emit Stake(msg.sender, _amount);
    }

    function unStake(uint256 _amount) internal {
        require(_amount > 0, "Invalid withdraw amount");

        StakeRewardStorage storage st = stakeRewardStorage();
        require(st.userStaked[msg.sender] >= _amount, "Insufficient balance");
        st.userStaked[msg.sender] -= _amount;
        st.totalStaked -= _amount;
        LibSdtReward.unStake(_amount);
        st.stakingToken.safeTransfer(address(msg.sender), _amount);

        emit UnStake(msg.sender, _amount);
    }

    function claimAllReward() internal {
        LibSdtReward.claimSdtReward(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import "../../dependencies/IWETH.sol";
import "../interfaces/IVault.sol";
import "../interfaces/ITradingCore.sol";
import "../interfaces/ITrading.sol";
import "./LibPriceFacade.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ZERO, ONE, UC, uc, into} from "unchecked-counter/src/UC.sol";

library LibVault {

    using Address for address payable;
    using SafeERC20 for IERC20;

    bytes32 constant VAULT_POSITION = keccak256("shardex.vault.storage");

    struct AvailableToken {
        address tokenAddress;
        uint32 tokenAddressPosition;
        uint16 weight;
        uint16 feeBasisPoints;
        uint16 taxBasisPoints;
        uint8 decimals;
        bool stable;
        bool dynamicFee;
        bool asMargin;
    }

    struct VaultStorage {
        mapping(address => AvailableToken) tokens;
        address[] tokenAddresses;
        // tokenAddress => amount
        mapping(address => uint256) treasury;
        address weth;
        address exchangeTreasury; // obsolete
        uint16 securityMarginP;   // 1e4
    }

    function vaultStorage() internal pure returns (VaultStorage storage vs) {
        bytes32 position = VAULT_POSITION;
        assembly {
            vs.slot := position
        }
    }

    event AddToken(
        address indexed token, uint16 weight, uint16 feeBasisPoints,
        uint16 taxBasisPoints, bool stable, bool dynamicFee, bool asMargin
    );
    event RemoveToken(address indexed token);
    event UpdateToken(
        address indexed token,
        uint16 oldFeeBasisPoints, uint16 oldTaxBasisPoints, bool oldDynamicFee,
        uint16 feeBasisPoints, uint16 taxBasisPoints, bool dynamicFee
    );
    event SupportTokenAsMargin(address indexed tokenAddress, bool supported);
    event ChangeWeight(address[] tokenAddress, uint16[] oldWeights, uint16[] newWeights);
    event SetSecurityMarginP(uint16 oldSecurityMarginP, uint16 securityMarginP);
    event CloseTradeRemoveLiquidity(address indexed token, uint256 amount);

    function initialize(address weth) internal {
        VaultStorage storage vs = vaultStorage();
        require(vs.weth == address(0), "LibVault: Already initialized");
        vs.weth = weth;
    }

    function WETH() internal view returns (address) {
        return vaultStorage().weth;
    }

    function addToken(
        address tokenAddress, uint16 feeBasisPoints, uint16 taxBasisPoints, bool stable,
        bool dynamicFee, bool asMargin, uint16[] calldata weights
    ) internal {
        VaultStorage storage vs = vaultStorage();
        AvailableToken storage at = vs.tokens[tokenAddress];
        require(at.tokenAddress == address(0), "LibVault: Can't add token that already exists");
        at.tokenAddress = tokenAddress;
        at.tokenAddressPosition = uint32(vs.tokenAddresses.length);
        at.feeBasisPoints = feeBasisPoints;
        at.taxBasisPoints = taxBasisPoints;
        at.decimals = IERC20Metadata(tokenAddress).decimals();
        at.stable = stable;
        at.dynamicFee = dynamicFee;
        at.asMargin = asMargin;

        vs.tokenAddresses.push(tokenAddress);
        emit AddToken(at.tokenAddress, weights[weights.length - 1], at.feeBasisPoints, at.taxBasisPoints, at.stable, at.dynamicFee, at.asMargin);
        changeWeight(weights);
    }

    function removeToken(address tokenAddress, uint16[] calldata weights) internal {
        VaultStorage storage vs = vaultStorage();
        AvailableToken storage at = vs.tokens[tokenAddress];
        require(at.tokenAddress != address(0), "LibVault: Token does not exist");

        changeWeight(weights);
        uint256 lastPosition = vs.tokenAddresses.length - 1;
        uint256 tokenAddressPosition = at.tokenAddressPosition;
        if (tokenAddressPosition != lastPosition) {
            address lastTokenAddress = vs.tokenAddresses[lastPosition];
            vs.tokenAddresses[tokenAddressPosition] = lastTokenAddress;
            vs.tokens[lastTokenAddress].tokenAddressPosition = uint32(tokenAddressPosition);
        }
        require(at.weight == 0, "LibVault: The weight of the removed Token must be 0.");
        vs.tokenAddresses.pop();
        delete vs.tokens[tokenAddress];
        emit RemoveToken(tokenAddress);
    }

    function updateToken(address tokenAddress, uint16 feeBasisPoints, uint16 taxBasisPoints, bool dynamicFee) internal {
        VaultStorage storage vs = vaultStorage();
        AvailableToken storage at = vs.tokens[tokenAddress];
        require(at.tokenAddress != address(0), "LibVault: Token does not exist");
        (uint16 oldFeePoints, uint16 oldTaxPoints, bool oldDynamicFee) = (at.feeBasisPoints, at.taxBasisPoints, at.dynamicFee);
        at.feeBasisPoints = feeBasisPoints;
        at.taxBasisPoints = taxBasisPoints;
        at.dynamicFee = dynamicFee;
        emit UpdateToken(tokenAddress, oldFeePoints, oldTaxPoints, oldDynamicFee, feeBasisPoints, taxBasisPoints, dynamicFee);
    }

    function updateAsMargin(address tokenAddress, bool asMargin) internal {
        AvailableToken storage at = vaultStorage().tokens[tokenAddress];
        require(at.tokenAddress != address(0), "LibVault: Token does not exist");
        require(at.asMargin != asMargin, "LibVault: No modification required");
        at.asMargin = asMargin;
        emit SupportTokenAsMargin(tokenAddress, asMargin);
    }

    function changeWeight(uint16[] calldata weights) internal {
        VaultStorage storage vs = vaultStorage();
        require(weights.length == vs.tokenAddresses.length, "LibVault: Invalid weights");
        uint16 totalWeight;
        uint16[] memory oldWeights = new uint16[](weights.length);
        for (UC i = ZERO; i < uc(weights.length); i = i + ONE) {
            totalWeight += weights[i.into()];
            address tokenAddress = vs.tokenAddresses[i.into()];
            uint16 oldWeight = vs.tokens[tokenAddress].weight;
            oldWeights[i.into()] = oldWeight;
            vs.tokens[tokenAddress].weight = weights[i.into()];
        }
        require(totalWeight == 1e4, "LibVault: The sum of the weights is not equal to 10000");
        emit ChangeWeight(vs.tokenAddresses, oldWeights, weights);
    }

    function setSecurityMarginP(uint16 securityMarginP) internal {
        VaultStorage storage vs = vaultStorage();
        uint16 old = vs.securityMarginP;
        vs.securityMarginP = securityMarginP;
        emit SetSecurityMarginP(old, securityMarginP);
    }

    function deposit(address token, uint256 amount) internal {
        deposit(token, amount, address(0), true);
    }

    // The caller checks whether the token exists and the amount>0
    // in order to return quickly in case of an error
    function deposit(address token, uint256 amount, address from, bool transferred) internal {
        if (!transferred) {
            IERC20(token).safeTransferFrom(from, address(this), amount);
        }
        LibVault.VaultStorage storage vs = vaultStorage();
        vs.treasury[token] += amount;
    }

    function depositETH(uint256 amount) internal {
        IWETH(WETH()).deposit{value: amount}();
        deposit(WETH(), amount);
    }

    function decreaseByCloseTrade(address token, uint256 amount) internal returns (ITradingClose.SettleToken[] memory settleTokens) {
        VaultStorage storage vs = vaultStorage();
        uint8 token_0_decimals = vs.tokens[token].decimals;
        ITradingClose.SettleToken memory st = ITradingClose.SettleToken(
            token,
            vs.treasury[token] >= amount ? amount : vs.treasury[token],
            token_0_decimals
        );
        if (vs.treasury[token] >= amount) {
            vs.treasury[token] -= amount;
            settleTokens = new ITradingClose.SettleToken[](1);
            settleTokens[0] = st;
            emit CloseTradeRemoveLiquidity(token, amount);
            return settleTokens;
        } else {
            uint256 otherTokenAmountUsd = (amount - vs.treasury[token]) * LibPriceFacade.getPrice(token) * 1e10 / (10 ** token_0_decimals);
            address[] memory allTokens = vs.tokenAddresses;
            ITrading.MarginBalance[] memory balances = new ITrading.MarginBalance[](allTokens.length - 1);
            uint256 totalBalanceUsd;
            UC index = ZERO;
            for (UC i = ZERO; i < uc(allTokens.length); i = i + ONE) {
                address tokenAddress = allTokens[i.into()];
                AvailableToken memory at = vs.tokens[tokenAddress];
                if (at.asMargin && tokenAddress != token && vs.treasury[tokenAddress] > 0) {
                    uint256 balanceUsd = vs.treasury[tokenAddress] * LibPriceFacade.getPrice(tokenAddress) * 1e10 / (10 ** at.decimals);
                    balances[index.into()] = ITrading.MarginBalance(tokenAddress, LibPriceFacade.getPrice(tokenAddress), at.decimals, balanceUsd);
                    totalBalanceUsd += balanceUsd;
                    index = index + ONE;
                }
            }
            require(otherTokenAmountUsd <= totalBalanceUsd, "LibVault: Insufficient funds in the treasury");
            settleTokens = new ITradingClose.SettleToken[]((index + ONE).into());
            settleTokens[0] = st;
            vs.treasury[token] = 0;
            emit CloseTradeRemoveLiquidity(token, settleTokens[0].amount);

            uint points = 1e4;
            for (UC i = ONE; i < index; i = i + ONE) {
                ITrading.MarginBalance memory mb = balances[i.into()];
                uint256 share = mb.balanceUsd * 1e4 / totalBalanceUsd;
                settleTokens[i.into()] = ITradingClose.SettleToken(mb.token, otherTokenAmountUsd * share * (10 ** mb.decimals) / (1e4 * 1e10 * mb.price), mb.decimals);
                vs.treasury[mb.token] -= settleTokens[i.into()].amount;
                emit CloseTradeRemoveLiquidity(mb.token, settleTokens[i.into()].amount);
                points -= share;
            }
            ITrading.MarginBalance memory b = balances[0];
            settleTokens[index.into()] = ITradingClose.SettleToken(b.token, otherTokenAmountUsd * points * (10 ** b.decimals) / (1e4 * 1e10 * b.price), b.decimals);
            vs.treasury[b.token] -= settleTokens[index.into()].amount;
            emit CloseTradeRemoveLiquidity(b.token, settleTokens[index.into()].amount);
            return settleTokens;
        }
    }

    // The caller checks whether the token exists and the amount>0
    // in order to return quickly in case of an error
    function withdraw(address receiver, address token, uint256 amount) internal {
        LibVault.VaultStorage storage vs = vaultStorage();
        require(vs.treasury[token] >= amount, "LibVault: Treasury insufficient balance");
        vs.treasury[token] -= amount;
        IERC20(token).safeTransfer(receiver, amount);
    }

    // The entry for calling this method needs to prevent reentry
    // use "../security/RentalGuard.sol"
    function withdrawETH(address payable receiver, uint256 amount) internal {
        LibVault.VaultStorage storage vs = vaultStorage();
        require(vs.treasury[WETH()] >= amount, "LibVault: Treasury insufficient balance");
        IWETH(WETH()).withdraw(amount);
        vs.treasury[WETH()] -= amount;
        receiver.sendValue(amount);
    }

    function getTotalValueUsd() internal view returns (int256) {
        LibVault.VaultStorage storage vs = vaultStorage();
        uint256 numTokens = vs.tokenAddresses.length;
        uint256 totalValueUsd;
        for (UC i = ZERO; i < uc(numTokens); i = i + ONE) {
            address tokenAddress = vs.tokenAddresses[i.into()];
            LibVault.AvailableToken storage at = vs.tokens[tokenAddress];
            uint256 price = LibPriceFacade.getPrice(tokenAddress);
            uint256 balance = vs.treasury[tokenAddress];
            uint256 valueUsd = price * balance * 1e10 / (10 ** at.decimals);
            totalValueUsd += valueUsd;
        }
        return int256(totalValueUsd);
    }

    function getTokenByAddress(address tokenAddress) internal view returns (AvailableToken memory) {
        return LibVault.vaultStorage().tokens[tokenAddress];
    }

    function maxWithdrawAbleUsd(int256 totalValueUsd) internal view returns (int256) {
        LibVault.VaultStorage storage vs = vaultStorage();
        return totalValueUsd - int256(ITradingCore(address(this)).lpNotionalUsd() * vs.securityMarginP / 1e4);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import "../libraries/LibDiamond.sol";

abstract contract Pausable {

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function _paused() internal view virtual returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!_paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(_paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    modifier nonReentrant() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.status != _ENTERED, "ReentrancyGuard: reentrant call");
        ds.status = _ENTERED;
        _;
        ds.status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

type Price8 is uint64;
type Qty10 is uint80;
type Usd18 is uint96;

library Constants {

    /*-------------------------------- Role --------------------------------*/
    // 0x0000000000000000000000000000000000000000000000000000000000000000
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    // 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // 0xfc425f2263d0df187444b70e47283d622c70181c5baebb1306a01edba1ce184c
    bytes32 constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    // 0x62150a51582c26f4255242a3c4ca35fb04250e7315069523d650676aed01a56a
    bytes32 constant TOKEN_OPERATOR_ROLE = keccak256("TOKEN_OPERATOR_ROLE");
    // 0xa6fbd0d4ef0ac50b4de984ab8f303863596293cce6d67dd6111979bcf56abe74
    bytes32 constant STAKE_OPERATOR_ROLE = keccak256("STAKE_OPERATOR_ROLE");
    // 0xc24d2c87036c9189cc45e221d5dff8eaffb4966ee49ea36b4ffc88a2d85bf890
    bytes32 constant PRICE_FEED_OPERATOR_ROLE = keccak256("PRICE_FEED_OPERATOR_ROLE");
    // 0x04fcf77d802b9769438bfcbfc6eae4865484c9853501897657f1d28c3f3c603e
    bytes32 constant PAIR_OPERATOR_ROLE = keccak256("PAIR_OPERATOR_ROLE");
    // 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab
    bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    // 0x7d867aa9d791a9a4be418f90a2f248aa2c5f1348317792a6f6412f94df9819f7
    bytes32 constant PRICE_FEEDER_ROLE = keccak256("PRICE_FEEDER_ROLE");
    // 0x8227712ef8ad39d0f26f06731ef0df8665eb7ada7f41b1ee089adf3c238862a2
    bytes32 constant MONITOR_ROLE = keccak256("MONITOR_ROLE");

    /*-------------------------------- Decimals --------------------------------*/
    uint8 constant public PRICE_DECIMALS = 8;
    uint8 constant public QTY_DECIMALS = 10;
    uint8 constant public USD_DECIMALS = 18;

    uint16 constant public BASIS_POINTS_DIVISOR = 1e4;
    uint16 constant public MAX_LEVERAGE = 1e3;
    int256 constant public FUNDING_FEE_RATE_DIVISOR = 1e18;
    uint16 constant public MAX_DAO_SHARE_P = 2000;
    uint16 constant public MAX_COMMISSION_P = 8000;
    uint8 constant public FEED_DELAY_BLOCK = 10;
    uint8 constant public MAX_REQUESTS_PER_PAIR_IN_BLOCK = 100;
    uint256 constant public TIME_LOCK_DELAY = 2 hours;
    uint256 constant public TIME_LOCK_GRACE_PERIOD = 12 hours;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/*//////////////////////////////////////////////////////////////////////////
                                TYPE DEFINITION
//////////////////////////////////////////////////////////////////////////*/

/// @notice Counter type that bypasses checked arithmetic, designed to be used in for loops.
/// @dev Here's an example:
///
/// ```
/// for (UC i = ZERO; i < uc(100); i = i + ONE) {
///   i.into(); // or `i.unwrap()`
/// }
/// ```
type UC is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

// Exports 1 as a typed constant.
UC constant ONE = UC.wrap(1);

// Exports 0 as a typed constant.
UC constant ZERO = UC.wrap(0);

/*//////////////////////////////////////////////////////////////////////////
                                LOGIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { add as +, lt as <, lte as <= } for UC global;

/// @notice Sums up `x` and `y` without checked arithmetic.
function add(UC x, UC y) pure returns (UC) {
    unchecked {
        return UC.wrap(UC.unwrap(x) + UC.unwrap(y));
    }
}

/// @notice Checks if `x` is lower than `y`.
function lt(UC x, UC y) pure returns (bool) {
    return UC.unwrap(x) < UC.unwrap(y);
}

/// @notice Checks if `x` is lower than or equal to `y`.
function lte(UC x, UC y) pure returns (bool) {
    return UC.unwrap(x) <= UC.unwrap(y);
}

/*//////////////////////////////////////////////////////////////////////////
                                CASTING FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { into, unwrap } for UC global;

/// @notice Alias for the `UC.unwrap` function.
function into(UC x) pure returns (uint256 result) {
    result = UC.unwrap(x);
}

/// @notice Alias for the `UC.wrap` function.
function uc(uint256 x) pure returns (UC result) {
    result = UC.wrap(x);
}

/// @notice Alias for the `UC.unwrap` function.
function unwrap(UC x) pure returns (uint256 result) {
    result = UC.unwrap(x);
}

/// @notice Alias for the `UC.wrap` function.
function wrap(uint256 x) pure returns (UC result) {
    result = UC.wrap(x);
}