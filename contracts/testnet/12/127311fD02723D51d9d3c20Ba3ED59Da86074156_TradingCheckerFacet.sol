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
pragma solidity ^0.8.19;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import "../interfaces/IVault.sol";
import "../interfaces/ILimitOrder.sol";
import "../interfaces/IPriceFacade.sol";
import "../interfaces/ITradingCore.sol";
import "../interfaces/IPairsManager.sol";
import "../interfaces/ITradingConfig.sol";
import "../interfaces/ITradingChecker.sol";
import "../libraries/LibChain.sol";
import "../libraries/LibTrading.sol";
import {ZERO, ONE, UC, uc, into} from "unchecked-counter/src/UC.sol";

contract TradingCheckerFacet is ITradingChecker {

    function checkTp(
        bool isLong, uint takeProfit, uint entryPrice, uint leverage_10000, uint maxTakeProfitP
    ) public pure returns (bool) {
        if (isLong) {
            // The takeProfit price must be set and the percentage of profit must not exceed the maximum allowed
            return takeProfit > entryPrice && (takeProfit - entryPrice) * leverage_10000 <= maxTakeProfitP * entryPrice;
        } else {
            // The takeProfit price must be set and the percentage of profit must not exceed the maximum allowed
            return takeProfit > 0 && takeProfit < entryPrice && (entryPrice - takeProfit) * leverage_10000 <= maxTakeProfitP * entryPrice;
        }
    }

    function checkSl(bool isLong, uint stopLoss, uint entryPrice) public pure returns (bool) {
        if (isLong) {
            // stopLoss price below the liquidation price is meaningless
            // But no check is done here and is intercepted by the front-end.
            // (entryPrice - stopLoss) * qty < marginUsd * liqLostP / Constants.1e4
            return stopLoss == 0 || stopLoss < entryPrice;
        } else {
            // stopLoss price below the liquidation price is meaningless
            // But no check is done here and is intercepted by the front-end.
            // (stopLoss - entryPrice) * qty * 1e4 < marginUsd * liqLostP
            return stopLoss == 0 || stopLoss > entryPrice;
        }
    }

    function checkLimitOrderTp(ILimitOrder.LimitOrder calldata order) external view override {
        IVault.MarginToken memory token = IVault(address(this)).getTokenForTrading(order.tokenIn);

        // notionalUsd = price * qty
        uint notionalUsd = uint256(order.limitPrice) * order.qty;

        // openFeeUsd = notionalUsd * openFeeP
        uint openFeeUsd = notionalUsd * IPairsManager(address(this)).getPairFeeConfig(order.pairBase).openFeeP / 1e4;

        // marginUsd = amountInUsd - openFeeUsd - executionFeeUsd
        uint marginUsd = order.amountIn * token.price * 1e10 / (10 ** token.decimals) - openFeeUsd - ITradingConfig(address(this)).getTradingConfig().executionFeeUsd;

        // leverage_10000 = notionalUsd * 10000 / marginUsd
        uint leverage_10000 = notionalUsd * 1e4 / marginUsd;

        require(
            checkTp(order.isLong, order.takeProfit, order.limitPrice, leverage_10000, ITradingConfig(address(this)).getTradingConfig().maxTakeProfitP),
            "TradingCheckerFacet: takeProfit is not in the valid range"
        );
    }

    function _checkParameters(IBook.OpenDataInput calldata data) private pure {
        require(
            data.qty > 0 && data.amountIn > 0 && data.price > 0
            && data.pairBase != address(0) && data.tokenIn != address(0),
            "TradingCheckerFacet: Invalid parameters"
        );
    }

    function openLimitOrderCheck(IBook.OpenDataInput calldata data) external view override {
        _checkParameters(data);

        IVault.MarginToken memory token = IVault(address(this)).getTokenForTrading(data.tokenIn);
        require(token.asMargin, "TradingCheckerFacet: This token is not supported as margin");

        IPairsManager.TradingPair memory pair = IPairsManager(address(this)).getPairForTrading(data.pairBase);
        require(pair.status == IPairsManager.PairStatus.AVAILABLE, "TradingCheckerFacet: The pair is temporarily unavailable for trading");

        ITradingConfig.TradingConfig memory tc = ITradingConfig(address(this)).getTradingConfig();
        require(tc.limitOrder, "TradingCheckerFacet: This feature is temporarily disabled");

        (uint marketPrice,) = IPriceFacade(address(this)).getPriceFromCacheOrOracle(data.pairBase);
        require(marketPrice > 0, "TradingCheckerFacet: No access to current market effective prices");

        uint triggerPrice = ITradingCore(address(this)).triggerPrice(data.pairBase, data.price, data.qty, data.isLong);
        require(
            (data.isLong && triggerPrice < marketPrice) || (!data.isLong && triggerPrice > marketPrice),
            "TradingCheckerFacet: This price will open a position immediately"
        );

        // price * qty * 10^18 / 10^(8+10) = price * qty
        uint notionalUsd = uint256(data.price) * data.qty;
        // The notional value must be greater than or equal to the minimum notional value allowed
        require(notionalUsd >= tc.minNotionalUsd, "TradingCheckerFacet: Position is too small");

        IPairsManager.LeverageMargin[] memory lms = pair.leverageMargins;
        // The notional value of the position must be less than or equal to the maximum notional value allowed by pair
        require(notionalUsd <= lms[lms.length - 1].notionalUsd, "TradingCheckerFacet: Position is too large");

        IPairsManager.LeverageMargin memory lm = marginLeverage(lms, notionalUsd);
        uint openFeeUsd = notionalUsd * pair.feeConfig.openFeeP / 1e4;
        uint amountInUsd = data.amountIn * token.price * 1e10 / (10 ** token.decimals);
        require(amountInUsd > openFeeUsd + tc.executionFeeUsd, "TradingCheckerFacet: The amount is too small");

        // marginUsd = amountInUsd - openFeeUsd - executionFeeUsd
        uint marginUsd = amountInUsd - openFeeUsd - tc.executionFeeUsd;
        // leverage = notionalUsd / marginUsd
        uint leverage_10000 = notionalUsd * 1e4 / marginUsd;
        require(
            leverage_10000 <= uint(1e4) * lm.maxLeverage,
            "TradingCheckerFacet: Exceeds the maximum leverage allowed for the position"
        );
        require(
            checkTp(data.isLong, data.takeProfit, data.price, leverage_10000, tc.maxTakeProfitP),
            "TradingCheckerFacet: takeProfit is not in the valid range"
        );
        require(
            checkSl(data.isLong, data.stopLoss, data.price),
            "TradingCheckerFacet: stopLoss is not in the valid range"
        );
    }

    struct ExecuteLimitOrderCheckTuple {
        IPairsManager.TradingPair pair;
        ITradingConfig.TradingConfig tc;
        IVault.MarginToken token;
        ITradingCore.PairQty pairQty;
        uint notionalUsd;
        uint triggerPrice;
    }

    function _buildExecuteLimitOrderCheckTuple(
        ILimitOrder.LimitOrder memory order
    ) private view returns (ExecuteLimitOrderCheckTuple memory) {
        IPairsManager.TradingPair memory pair = IPairsManager(address(this)).getPairForTrading(order.pairBase);
        ITradingCore.PairQty memory pairQty = ITradingCore(address(this)).getPairQty(order.pairBase);
        return ExecuteLimitOrderCheckTuple(
            pair,
            ITradingConfig(address(this)).getTradingConfig(),
            IVault(address(this)).getTokenForTrading(order.tokenIn),
            pairQty,
            uint256(order.limitPrice) * order.qty,
            ITradingCore(address(this)).triggerPrice(pairQty, pair.slippageConfig, order.limitPrice, order.qty, order.isLong)
        );
    }

    function executeLimitOrderCheck(
        ILimitOrder.LimitOrder memory order,
        uint256 marketPrice
    ) external view override returns (bool result, uint96 openFee, uint96 executionFee, Refund refund) {
        ExecuteLimitOrderCheckTuple memory tuple = _buildExecuteLimitOrderCheckTuple(order);
        if (!tuple.tc.executeLimitOrder) {
            return (false, 0, 0, Refund.SWITCH);
        }

        if (tuple.pair.base == address(0) || tuple.pair.status != IPairsManager.PairStatus.AVAILABLE) {
            return (false, 0, 0, Refund.PAIR_STATUS);
        }

        if (tuple.notionalUsd < tuple.tc.minNotionalUsd) {
            return (false, 0, 0, Refund.MIN_NOTIONAL_USD);
        }

        IPairsManager.LeverageMargin[] memory lms = tuple.pair.leverageMargins;
        if (tuple.notionalUsd > lms[lms.length - 1].notionalUsd) {
            return (false, 0, 0, Refund.MAX_NOTIONAL_USD);
        }

        IPairsManager.LeverageMargin memory lm = marginLeverage(lms, tuple.notionalUsd);
        uint openFeeUsd = tuple.notionalUsd * tuple.pair.feeConfig.openFeeP / 1e4;
        uint amountInUsd = order.amountIn * tuple.token.price * 1e10 / (10 ** tuple.token.decimals);
        if (amountInUsd <= openFeeUsd + tuple.tc.executionFeeUsd) {
            return (false, 0, 0, Refund.AMOUNT_IN);
        }

        // marginUsd = amountInUsd - openFeeUsd - executionFeeUsd
        uint marginUsd = amountInUsd - openFeeUsd - tuple.tc.executionFeeUsd;
        // leverage_10000 = notionalUsd * 10000 / marginUsd
        uint leverage_10000 = tuple.notionalUsd * 1e4 / marginUsd;
        if (leverage_10000 > uint(1e4) * lm.maxLeverage) {
            return (false, 0, 0, Refund.MAX_LEVERAGE);
        }

        if (order.isLong) {
            if (marketPrice > tuple.triggerPrice) {
                return (false, 0, 0, Refund.USER_PRICE);
            }
            // Whether the Stop Loss will be triggered immediately at the current price
            if (marketPrice <= order.stopLoss) {
                return (false, 0, 0, Refund.SL);
            }
            // pair OI check
            if (tuple.notionalUsd + tuple.pairQty.longQty * marketPrice > tuple.pair.pairConfig.maxLongOiUsd) {
                return (false, 0, 0, Refund.PAIR_OI);
            }
            // open lost check
            if ((order.limitPrice - marketPrice) * order.qty * 1e4 >= marginUsd * lm.initialLostP) {
                return (false, 0, 0, Refund.OPEN_LOST);
            }
        } else {
            // Comparison of the values of price and limitPrice + slippage
            if (marketPrice < tuple.triggerPrice) {
                return (false, 0, 0, Refund.USER_PRICE);
            }
            // 4. Whether the Stop Loss will be triggered immediately at the current price
            if (order.stopLoss > 0 && marketPrice >= order.stopLoss) {
                return (false, 0, 0, Refund.SL);
            }
            // pair OI check
            if (tuple.notionalUsd + tuple.pairQty.shortQty * marketPrice > tuple.pair.pairConfig.maxShortOiUsd) {
                return (false, 0, 0, Refund.PAIR_OI);
            }
            // open lost check
            if ((marketPrice - order.limitPrice) * order.qty * 1e4 >= marginUsd * lm.initialLostP) {
                return (false, 0, 0, Refund.OPEN_LOST);
            }
        }
        return (true,
        uint96(openFeeUsd * (10 ** tuple.token.decimals) / (1e10 * tuple.token.price)),
        uint96(tuple.tc.executionFeeUsd * (10 ** tuple.token.decimals) / (1e10 * tuple.token.price)),
        Refund.NO
        );
    }

    function checkMarketTradeTp(ITrading.OpenTrade calldata ot) external view {
        IVault.MarginToken memory token = IVault(address(this)).getTokenForTrading(ot.tokenIn);

        // notionalUsd = price * qty
        uint notionalUsd = uint256(ot.entryPrice) * ot.qty;

        // marginUsd = margin * token.price
        uint marginUsd = ot.margin * token.price * 1e10 / (10 ** token.decimals);

        // leverage_10000 = notionalUsd * 10000 / marginUsd
        uint leverage_10000 = notionalUsd * 1e4 / marginUsd;

        require(
            checkTp(ot.isLong, ot.takeProfit, ot.entryPrice, leverage_10000, ITradingConfig(address(this)).getTradingConfig().maxTakeProfitP),
            "TradingCheckerFacet: takeProfit is not in the valid range"
        );
    }

    function openMarketTradeCheck(IBook.OpenDataInput calldata data) external view override {
        _checkParameters(data);

        IVault.MarginToken memory token = IVault(address(this)).getTokenForTrading(data.tokenIn);
        require(token.asMargin, "TradingCheckerFacet: This token is not supported as margin");

        IPairsManager.TradingPair memory pair = IPairsManager(address(this)).getPairForTrading(data.pairBase);
        require(pair.status == IPairsManager.PairStatus.AVAILABLE, "TradingCheckerFacet: The pair is temporarily unavailable for trading");

        ITradingConfig.TradingConfig memory tc = ITradingConfig(address(this)).getTradingConfig();
        require(tc.marketTrading, "TradingCheckerFacet: This feature is temporarily disabled");

        (uint marketPrice,) = IPriceFacade(address(this)).getPriceFromCacheOrOracle(data.pairBase);
        require(marketPrice > 0, "TradingCheckerFacet: No access to current market effective prices");

        ITradingCore.PairQty memory pairQty = ITradingCore(address(this)).getPairQty(data.pairBase);
        uint trialPrice = ITradingCore(address(this)).slippagePrice(pairQty, pair.slippageConfig, marketPrice, data.qty, data.isLong);
        require(
            (data.isLong && trialPrice <= data.price) || (!data.isLong && trialPrice >= data.price),
            "TradingCheckerFacet: Unable to trading at a price acceptable to the user"
        );

        // price * qty * 10^18 / 10^(8+10) = price * qty
        uint notionalUsd = trialPrice * data.qty;
        // The notional value must be greater than or equal to the minimum notional value allowed
        require(notionalUsd >= tc.minNotionalUsd, "TradingCheckerFacet: Position is too small");

        IPairsManager.LeverageMargin[] memory lms = pair.leverageMargins;
        // The notional value of the position must be less than or equal to the maximum notional value allowed by pair
        require(notionalUsd <= lms[lms.length - 1].notionalUsd, "TradingCheckerFacet: Position is too large");

        IPairsManager.LeverageMargin memory lm = marginLeverage(lms, notionalUsd);
        uint openFeeUsd = notionalUsd * pair.feeConfig.openFeeP / 1e4;
        uint amountInUsd = data.amountIn * token.price * 1e10 / (10 ** token.decimals);
        require(amountInUsd > openFeeUsd + tc.executionFeeUsd, "TradingCheckerFacet: The amount is too small");

        // marginUsd = amountInUsd - openFeeUsd - executionFeeUsd
        uint marginUsd = amountInUsd - openFeeUsd - tc.executionFeeUsd;
        // leverage = notionalUsd / marginUsd
        uint leverage_10000 = notionalUsd * 1e4 / marginUsd;
        require(
            leverage_10000 <= uint(1e4) * lm.maxLeverage,
            "TradingCheckerFacet: Exceeds the maximum leverage allowed for the position"
        );
        require(
            checkTp(data.isLong, data.takeProfit, trialPrice, leverage_10000, tc.maxTakeProfitP),
            "TradingCheckerFacet: takeProfit is not in the valid range"
        );
        require(
            checkSl(data.isLong, data.stopLoss, trialPrice),
            "TradingCheckerFacet: stopLoss is not in the valid range"
        );

        if (data.isLong) {
            // It is prohibited to open positions with excessive losses. Avoid opening positions that are liquidated
            require(
                (trialPrice - marketPrice) * data.qty * 1e4 < marginUsd * lm.initialLostP,
                "TradingCheckerFacet: Too much initial loss"
            );
            // The total position must be less than or equal to the maximum position allowed for the trading pair
            require(notionalUsd + pairQty.longQty * trialPrice <= pair.pairConfig.maxLongOiUsd, "TradingCheckerFacet: Long positions have exceeded the maximum allowed");
        } else {
            // It is prohibited to open positions with excessive losses. Avoid opening positions that are liquidated
            require(
                (marketPrice - trialPrice) * data.qty * 1e4 < marginUsd * lm.initialLostP,
                "TradingCheckerFacet: Too much initial loss"
            );
            // The total position must be less than or equal to the maximum position allowed for the trading pair
            require(notionalUsd + pairQty.shortQty * trialPrice <= pair.pairConfig.maxShortOiUsd, "TradingCheckerFacet: Short positions have exceeded the maximum allowed");
        }
    }

    struct MarketTradeCallbackCheckTuple {
        IPairsManager.TradingPair pair;
        ITradingConfig.TradingConfig tc;
        IVault.MarginToken token;
        ITradingCore.PairQty pairQty;
        uint notionalUsd;
        uint entryPrice;
    }

    function _buildMarketTradeCallbackCheckTuple(
        ITrading.PendingTrade memory pt, uint256 marketPrice
    ) private view returns (MarketTradeCallbackCheckTuple memory) {
        IPairsManager.TradingPair memory pair = IPairsManager(address(this)).getPairForTrading(pt.pairBase);
        ITradingCore.PairQty memory pairQty = ITradingCore(address(this)).getPairQty(pt.pairBase);
        uint entryPrice = ITradingCore(address(this)).slippagePrice(pairQty, pair.slippageConfig, marketPrice, pt.qty, pt.isLong);
        return MarketTradeCallbackCheckTuple(
            pair,
            ITradingConfig(address(this)).getTradingConfig(),
            IVault(address(this)).getTokenForTrading(pt.tokenIn),
            pairQty,
            entryPrice * pt.qty,
            entryPrice
        );
    }

    function marginLeverage(
        IPairsManager.LeverageMargin[] memory lms, uint256 notionalUsd
    ) private pure returns (IPairsManager.LeverageMargin memory) {
        for (UC i = ZERO; i < uc(lms.length); i = i + ONE) {
            if (notionalUsd <= lms[i.into()].notionalUsd) {
                return lms[i.into()];
            }
        }
        return lms[lms.length - 1];
    }

    function marketTradeCallbackCheck(
        ITrading.PendingTrade calldata pt, uint256 marketPrice
    ) external view returns (bool result, uint96 openFee, uint96 executionFee, uint256 entryPrice, Refund refund) {
        if (pt.blockNumber + Constants.FEED_DELAY_BLOCK < LibChain.getBlockNumber()) {
            return (false, 0, 0, 0, Refund.FEED_DELAY);
        }

        MarketTradeCallbackCheckTuple memory tuple = _buildMarketTradeCallbackCheckTuple(pt, marketPrice);
        if ((pt.isLong && tuple.entryPrice > pt.price) || (!pt.isLong && tuple.entryPrice < pt.price)) {
            return (false, 0, 0, tuple.entryPrice, Refund.USER_PRICE);
        }

        if (tuple.notionalUsd < tuple.tc.minNotionalUsd) {
            return (false, 0, 0, tuple.entryPrice, Refund.MIN_NOTIONAL_USD);
        }

        IPairsManager.LeverageMargin[] memory lms = tuple.pair.leverageMargins;
        if (tuple.notionalUsd > lms[lms.length - 1].notionalUsd) {
            return (false, 0, 0, tuple.entryPrice, Refund.MAX_NOTIONAL_USD);
        }

        IPairsManager.LeverageMargin memory lm = marginLeverage(lms, tuple.notionalUsd);
        uint openFeeUsd = tuple.notionalUsd * tuple.pair.feeConfig.openFeeP / 1e4;
        uint amountInUsd = pt.amountIn * tuple.token.price * 1e10 / (10 ** tuple.token.decimals);
        if (amountInUsd <= openFeeUsd + tuple.tc.executionFeeUsd) {
            return (false, 0, 0, tuple.entryPrice, Refund.AMOUNT_IN);
        }

        // marginUsd = amountInUsd - openFeeUsd - executionFeeUsd
        uint marginUsd = amountInUsd - openFeeUsd - tuple.tc.executionFeeUsd;
        // leverage_10000 = notionalUsd * 10000 / marginUsd
        uint leverage_10000 = tuple.notionalUsd * 1e4 / marginUsd;
        if (leverage_10000 > uint(1e4) * lm.maxLeverage) {
            return (false, 0, 0, tuple.entryPrice, Refund.MAX_LEVERAGE);
        }

        if (!checkTp(pt.isLong, pt.takeProfit, tuple.entryPrice, leverage_10000, tuple.tc.maxTakeProfitP)) {
            return (false, 0, 0, tuple.entryPrice, Refund.TP);
        }

        if (!checkSl(pt.isLong, pt.stopLoss, tuple.entryPrice)) {
            return (false, 0, 0, tuple.entryPrice, Refund.SL);
        }

        if (pt.isLong) {
            // pair OI check
            if (tuple.notionalUsd + tuple.pairQty.longQty * tuple.entryPrice > tuple.pair.pairConfig.maxLongOiUsd) {
                return (false, 0, 0, tuple.entryPrice, Refund.PAIR_OI);
            }
            // open lost check
            if ((tuple.entryPrice - marketPrice) * pt.qty * 1e4 >= marginUsd * lm.initialLostP) {
                return (false, 0, 0, tuple.entryPrice, Refund.OPEN_LOST);
            }
        } else {
            // pair OI check
            if (tuple.notionalUsd + tuple.pairQty.shortQty * tuple.entryPrice > tuple.pair.pairConfig.maxShortOiUsd) {
                return (false, 0, 0, tuple.entryPrice, Refund.PAIR_OI);
            }
            // open lost check
            if ((marketPrice - tuple.entryPrice) * pt.qty * 1e4 >= marginUsd * lm.initialLostP) {
                return (false, 0, 0, tuple.entryPrice, Refund.OPEN_LOST);
            }
        }
        return (
        true,
        uint96(openFeeUsd * (10 ** tuple.token.decimals) / (1e10 * tuple.token.price)),
        uint96(tuple.tc.executionFeeUsd * (10 ** tuple.token.decimals) / (1e10 * tuple.token.price)),
        tuple.entryPrice, Refund.NO
        );
    }

    function executeLiquidateCheck(
        ITrading.OpenTrade calldata ot, uint256 marketPrice, uint256 closePrice
    ) external view returns (bool needLiq, int256 pnl, int256 fundingFee, uint256 closeFee) {
        IVault.MarginToken memory mt = IVault(address(this)).getTokenForTrading(ot.tokenIn);
        IPairsManager.TradingPair memory pair = IPairsManager(address(this)).getPairForTrading(ot.pairBase);

        fundingFee = LibTrading.calcFundingFee(ot, mt, marketPrice);

        uint256 closeNotionalUsd = closePrice * ot.qty;
        closeFee = closeNotionalUsd * pair.feeConfig.closeFeeP * (10 ** mt.decimals) / (1e4 * 1e10 * mt.price);
        IPairsManager.LeverageMargin memory lm = marginLeverage(pair.leverageMargins, uint256(ot.entryPrice) * ot.qty);

        if (ot.isLong) {
            pnl = (int256(closeNotionalUsd) - int256(uint256(ot.entryPrice) * ot.qty)) * int256(10 ** mt.decimals) / int256(1e10 * mt.price);
        } else {
            pnl = (int256(uint256(ot.entryPrice) * ot.qty) - int256(closeNotionalUsd)) * int256(10 ** mt.decimals) / int256(1e10 * mt.price);
        }
        int256 loss = int256(closeFee) - fundingFee - pnl;
        return (loss > 0 && uint256(loss) * 1e4 >= lm.liqLostP * ot.margin, pnl, fundingFee, closeFee);
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

interface ITradingConfig {
    /*
    |-----------> 8 bit <-----------|
    |---|---|---|---|---|---|---|---|
    |   |   | 5 | 4 | 3 | 2 | 1 | 0 |
    |---|---|---|---|---|---|---|---|
    */
    enum TradingSwitch {
        LIMIT_ORDER,
        EXECUTE_LIMIT_ORDER,
        MARKET_TRADING,
        USER_CLOSE_TRADING,
        TP_SL_CLOSE_TRADING,
        LIQUIDATE_TRADING
    }

    struct TradingConfig {
        uint256 executionFeeUsd;
        uint256 minNotionalUsd;
        uint24 maxTakeProfitP;
        bool limitOrder;
        bool executeLimitOrder;
        bool marketTrading;
        bool userCloseTrading;
        bool tpSlCloseTrading;
        bool liquidateTrading;
    }

    function getTradingConfig() external view returns (TradingConfig memory);

    function setTradingSwitches(
        bool limitOrder, bool executeLimitOrder, bool marketTrade,
        bool userCloseTrade, bool tpSlCloseTrade, bool liquidateTrade
    ) external;

    function setExecutionFeeUsd(uint256 executionFeeUsd) external;

    function setMinNotionalUsd(uint256 minNotionalUsd) external;

    function setMaxTakeProfitP(uint24 maxTakeProfitP) external;
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

import "../interfaces/IVault.sol";
import "../interfaces/ITrading.sol";
import "../interfaces/ITradingCore.sol";
import {ZERO, ONE, UC, uc, into} from "unchecked-counter/src/UC.sol";

library LibTrading {

    bytes32 constant TRADING_POSITION = keccak256("shardex.trading.storage");

    struct TradingStorage {
        uint256 salt;
        //--------------- pending ---------------
        // tradeHash =>
        mapping(bytes32 => ITrading.PendingTrade) pendingTrades;
        // margin.tokenIn => total amount of all pending trades
        mapping(address => uint256) pendingTradeAmountIns;
        //--------------- open ---------------
        // tradeHash =>
        mapping(bytes32 => ITrading.OpenTrade) openTrades;
        // user => tradeHash[]
        mapping(address => bytes32[]) userOpenTradeHashes;
        // tokenIn =>
        mapping(address => uint256) openTradeAmountIns;
        // tokenIn[]
        address[] openTradeTokenIns;
    }

    function tradingStorage() internal pure returns (TradingStorage storage ts) {
        bytes32 position = TRADING_POSITION;
        assembly {
            ts.slot := position
        }
    }

    function calcFundingFee(
        ITrading.OpenTrade memory ot,
        IVault.MarginToken memory mt,
        uint256 marketPrice
    ) internal view returns (int256 fundingFee) {
        int256 longAccFundingFeePerShare = ITradingCore(address(this)).lastLongAccFundingFeePerShare(ot.pairBase);
        return calcFundingFee(ot, mt, marketPrice, longAccFundingFeePerShare);
    }

    function calcFundingFee(
        ITrading.OpenTrade memory ot,
        IVault.MarginToken memory mt,
        uint256 marketPrice,
        int256 longAccFundingFeePerShare
    ) internal pure returns (int256 fundingFee) {
        int256 fundingFeeUsd;
        if (ot.isLong) {
            fundingFeeUsd = int256(ot.qty * marketPrice) * (longAccFundingFeePerShare - ot.longAccFundingFeePerShare) / 1e18;
        } else {
            fundingFeeUsd = int256(ot.qty * marketPrice) * (longAccFundingFeePerShare - ot.longAccFundingFeePerShare) * (- 1) / 1e18;
        }
        fundingFee = fundingFeeUsd * int256(10 ** mt.decimals) / int256(1e10 * mt.price);
        return fundingFee;
    }

    function increaseOpenTradeAmount(TradingStorage storage ts, address token, uint256 amount) internal {
        address[] storage tokenIns = ts.openTradeTokenIns;
        bool exists;
        for (UC i = ZERO; i < uc(tokenIns.length); i = i + ONE) {
            if (tokenIns[i.into()] == token) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            tokenIns.push(token);
        }
        ts.openTradeAmountIns[token] += amount;
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
    uint16 constant public FEED_DELAY_BLOCK = 1000; // todo for @dev
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