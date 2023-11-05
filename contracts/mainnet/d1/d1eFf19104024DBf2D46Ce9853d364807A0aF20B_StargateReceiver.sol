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
pragma solidity ^0.8.9;

error AlreadyInitialized();
error CannotAuthoriseSelf();
error CannotBridgeToSameNetwork();
error ContractCallNotAllowed();
error CumulativeSlippageTooHigh(uint256 minAmount, uint256 receivedAmount);
error ExternalCallFailed();
error InformationMismatch();
error InsufficientBalance(uint256 required, uint256 balance);
error InvalidAmount();
error InvalidCallData();
error InvalidConfig();
error InvalidContract();
error InvalidDestinationChain();
error InvalidFallbackAddress();
error InvalidReceiver();
error InvalidSendingToken();
error NativeAssetNotSupported();
error NativeAssetTransferFailed();
error NoSwapDataProvided();
error NoSwapFromZeroBalance();
error NotAContract();
error NotInitialized();
error NoTransferToNullAddress();
error NullAddrIsNotAnERC20Token();
error NullAddrIsNotAValidSpender();
error OnlyContractOwner();
error RecoveryAddressCannotBeZero();
error ReentrancyError();
error TokenNotSupported();
error UnAuthorized();
error UnsupportedChainId(uint256 chainId);
error ZeroAmount();
error TokenAddressIsZero();
error ZeroPostSwapBalance();
error NativeValueWithERC();
error InvalidBridgeConfigLength();
error InvalidCaller();
error CannotDepositNativeToken();
error NotEnoughBalance(uint256 requested, uint256 available);
error IsNotOwner();

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title Reentrancy Guard
/// @author LI.FI (https://li.fi)
/// @notice Abstract contract to provide protection against reentrancy
abstract contract ReentrancyGuard {
	/// Storage ///

	bytes32 private constant NAMESPACE = keccak256("com.kana.reentrancyguard");

	/// Types ///

	struct ReentrancyStorage {
		uint256 status;
	}

	/// Errors ///

	error ReentrancyError();

	/// Constants ///

	uint256 private constant _NOT_ENTERED = 0;
	uint256 private constant _ENTERED = 1;

	/// Modifiers ///

	modifier nonReentrant() {
		ReentrancyStorage storage s = reentrancyStorage();
		if (s.status == _ENTERED) revert ReentrancyError();
		s.status = _ENTERED;
		_;
		s.status = _NOT_ENTERED;
	}

	/// Private Methods ///

	/// @dev fetch local storage
	function reentrancyStorage() private pure returns (ReentrancyStorage storage data) {
		bytes32 position = NAMESPACE;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			data.slot := position
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC173} from "../Interfaces/IERC173.sol";
import {LibAsset} from "../Libraries/LibAsset.sol";

contract TransferrableOwnership is IERC173 {
	address public owner;
	address public pendingOwner;

	/// Errors ///
	error UnAuthorized();
	error NoNullOwner();
	error NewOwnerMustNotBeSelf();
	error NoPendingOwnershipTransfer();
	error NotPendingOwner();

	/// Events ///
	event OwnershipTransferRequested(address indexed _from, address indexed _to);

	constructor(address initialOwner) {
		owner = initialOwner;
	}

	modifier onlyOwner() {
		if (msg.sender != owner) revert UnAuthorized();
		_;
	}

	/// @notice Initiates transfer of ownership to a new address
	/// @param _newOwner the address to transfer ownership to
	function transferOwnership(address _newOwner) external onlyOwner {
		if (_newOwner == LibAsset.NULL_ADDRESS) revert NoNullOwner();
		if (_newOwner == msg.sender) revert NewOwnerMustNotBeSelf();
		pendingOwner = _newOwner;
		emit OwnershipTransferRequested(msg.sender, pendingOwner);
	}

	/// @notice Cancel transfer of ownership
	function cancelOwnershipTransfer() external onlyOwner {
		if (pendingOwner == LibAsset.NULL_ADDRESS) revert NoPendingOwnershipTransfer();
		pendingOwner = LibAsset.NULL_ADDRESS;
	}

	/// @notice Confirms transfer of ownership to the calling address (msg.sender)
	function confirmOwnershipTransfer() external {
		address _pendingOwner = pendingOwner;
		if (msg.sender != _pendingOwner) revert NotPendingOwner();
		emit OwnershipTransferred(owner, _pendingOwner);
		owner = _pendingOwner;
		pendingOwner = LibAsset.NULL_ADDRESS;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
	/// @dev This emits when ownership of a contract changes.
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/// @notice Get the address of the owner
	/// @return owner_ The address of the owner.
	function owner() external view returns (address owner_);

	/// @notice Set the address of the new owner of the contract
	/// @dev Set _newOwner to address(0) to renounce any ownership.
	/// @param _newOwner The address of the new owner of the contract
	function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibSwap} from "../Libraries/LibSwap.sol";

/// @title Interface for Executor
/// @author KANA
interface IExecutor {
	/// @notice Performs a swap before completing a cross-chain transaction
	/// @param _transactionId the transaction id associated with the operation
	/// @param _swapData array of data needed for swaps
	/// @param transferredAssetId token received from the other chain
	/// @param receiver address that will receive tokens in the end
	function swapAndCompleteBridgeTokens(
		bytes32 _transactionId,
		LibSwap.SwapData[] calldata _swapData,
		address transferredAssetId,
		address payable receiver
	) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKana {
	/// Structs ///

	struct BridgeData {
		bytes32 transactionId;
		string bridge;
		address integrator;
		address kanaWallet;
		address referrer;
		address sendingAssetId;
		address receiver;
		uint256 minAmount;
		uint256 destinationChainId;
		bool hasSourceSwaps;
		bool hasDestinationCall;
		uint256 integratorFee;
		uint256 kanaFee;
	}

	/// Events ///

	event KanaTransferStarted(IKana.BridgeData bridgeData);

	event KanaTransferCompleted(
		bytes32 indexed transactionId,
		address receivingAssetId,
		address receiver,
		uint256 amount,
		uint256 timestamp
	);

	event KanaTransferRecovered(
		bytes32 indexed transactionId,
		address receivingAssetId,
		address receiver,
		uint256 amount,
		uint256 timestamp
	);
	
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

interface IStargateReceiver {
	function sgReceive(
		uint16 _srcChainId, // the remote chainId sending the tokens
		bytes memory _srcAddress, // the remote Bridge address
		uint256 _nonce,
		address _token, // the token contract on the local chain
		uint256 amountLD, // the qty of local _token contract tokens
		bytes memory payload
	) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import {InsufficientBalance, NullAddrIsNotAnERC20Token, NullAddrIsNotAValidSpender, NoTransferToNullAddress, InvalidAmount, NativeValueWithERC, NativeAssetTransferFailed} from "../Errors/GenericErrors.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibSwap} from "./LibSwap.sol";

/// @title LibAsset
/// @notice This library contains helpers for dealing with onchain transfers
///         of assets, including accounting for the native asset `assetId`
///         conventions and any noncompliant ERC20 transfers
library LibAsset {
	uint256 private constant MAX_UINT = type(uint256).max;

	address internal constant NULL_ADDRESS = address(0);

	/// @dev All native assets use the empty address for their asset id
	///      by convention

	address internal constant NATIVE_ASSETID = NULL_ADDRESS; //address(0)

	/// @notice Gets the balance of the inheriting contract for the given asset
	/// @param assetId The asset identifier to get the balance of
	/// @return Balance held by contracts using this library
	function getOwnBalance(address assetId) internal view returns (uint256) {
		return assetId == NATIVE_ASSETID ? address(this).balance : IERC20(assetId).balanceOf(address(this));
	}

	/// @notice Transfers ether from the inheriting contract to a given
	///         recipient
	/// @param recipient Address to send ether to
	/// @param amount Amount to send to given recipient
	function transferNativeAsset(address payable recipient, uint256 amount) private {
		if (recipient == NULL_ADDRESS) revert NoTransferToNullAddress();
		if (amount > address(this).balance) revert InsufficientBalance(amount, address(this).balance);
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = recipient.call{value: amount}("");
		if (!success) revert NativeAssetTransferFailed();
	}

	/// @notice If the current allowance is insufficient, the allowance for a given spender
	/// is set to MAX_UINT.
	/// @param assetId Token address to transfer
	/// @param spender Address to give spend approval to
	/// @param amount Amount to approve for spending
	function maxApproveERC20(IERC20 assetId, address spender, uint256 amount) internal {
		if (address(assetId) == NATIVE_ASSETID) return;
		if (spender == NULL_ADDRESS) revert NullAddrIsNotAValidSpender();
		uint256 allowance = assetId.allowance(address(this), spender);

		if (allowance < amount) SafeERC20.safeIncreaseAllowance(IERC20(assetId), spender, MAX_UINT - allowance);
	}

	/// @notice Transfers tokens from the inheriting contract to a given
	///         recipient
	/// @param assetId Token address to transfer
	/// @param recipient Address to send token to
	/// @param amount Amount to send to given recipient
	function transferERC20(address assetId, address recipient, uint256 amount) private {
		if (isNativeAsset(assetId)) revert NullAddrIsNotAnERC20Token();
		uint256 assetBalance = IERC20(assetId).balanceOf(address(this));
		if (amount > assetBalance) revert InsufficientBalance(amount, assetBalance);
		SafeERC20.safeTransfer(IERC20(assetId), recipient, amount);
	}

	/// @notice Transfers tokens from a sender to a given recipient
	/// @param assetId Token address to transfer
	/// @param from Address of sender/owner
	/// @param to Address of recipient/spender
	/// @param amount Amount to transfer from owner to spender
	function transferFromERC20(address assetId, address from, address to, uint256 amount) internal {
		if (assetId == NATIVE_ASSETID) revert NullAddrIsNotAnERC20Token();
		if (to == NULL_ADDRESS) revert NoTransferToNullAddress();

		IERC20 asset = IERC20(assetId);
		uint256 prevBalance = asset.balanceOf(to);
		SafeERC20.safeTransferFrom(asset, from, to, amount);
		if (asset.balanceOf(to) - prevBalance != amount) revert InvalidAmount();
	}

	function depositAsset(address assetId, uint256 amount) internal {
		if (isNativeAsset(assetId)) {
			if (msg.value < amount) revert InvalidAmount();
		} else {
			if (amount == 0) revert InvalidAmount();
			uint256 balance = IERC20(assetId).balanceOf(msg.sender);
			if (balance < amount) revert InsufficientBalance(amount, balance);
			transferFromERC20(assetId, msg.sender, address(this), amount);
		}
	}

	function depositAssets(LibSwap.SwapData[] calldata swaps) internal {
		for (uint256 i = 0; i < swaps.length; ) {
			LibSwap.SwapData memory swap = swaps[i];
			if (swap.requiresDeposit) {
				depositAsset(swap.sendingAssetId, swap.fromAmount);
			}
			unchecked {
				i++;
			}
		}
	}

	/// @notice Determines whether the given assetId is the native asset
	/// @param assetId The asset identifier to evaluate
	/// @return Boolean indicating if the asset is the native asset
	function isNativeAsset(address assetId) internal pure returns (bool) {
		return assetId == NATIVE_ASSETID;
	}

	/// @notice Wrapper function to transfer a given asset (native or erc20) to
	///         some recipient. Should handle all non-compliant return value
	///         tokens as well by using the SafeERC20 contract by open zeppelin.
	/// @param assetId Asset id for transfer (address(0) for native asset,
	///                token address for erc20s)
	/// @param recipient Address to send asset to
	/// @param amount Amount to send to given recipient
	function transferAsset(address assetId, address payable recipient, uint256 amount) internal {
		(assetId == NATIVE_ASSETID)
			? transferNativeAsset(recipient, amount)
			: transferERC20(assetId, recipient, amount);
	}

	/// @dev Checks whether the given address is a contract and contains code
	function isContract(address _contractAddr) internal view returns (bool) {
		uint256 size;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			size := extcodesize(_contractAddr)
		}
		return size > 0;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LibBytes {
	// solhint-disable no-inline-assembly

	// LibBytes specific errors
	error SliceOverflow();
	error SliceOutOfBounds();
	error AddressOutOfBounds();
	error UintOutOfBounds();

	// -------------------------

	function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
		bytes memory tempBytes;

		assembly {
			// Get a location of some free memory and store it in tempBytes as
			// Solidity does for memory variables.
			tempBytes := mload(0x40)

			// Store the length of the first bytes array at the beginning of
			// the memory for tempBytes.
			let length := mload(_preBytes)
			mstore(tempBytes, length)

			// Maintain a memory counter for the current write location in the
			// temp bytes array by adding the 32 bytes for the array length to
			// the starting location.
			let mc := add(tempBytes, 0x20)
			// Stop copying when the memory counter reaches the length of the
			// first bytes array.
			let end := add(mc, length)

			for {
				// Initialize a copy counter to the start of the _preBytes data,
				// 32 bytes into its memory.
				let cc := add(_preBytes, 0x20)
			} lt(mc, end) {
				// Increase both counters by 32 bytes each iteration.
				mc := add(mc, 0x20)
				cc := add(cc, 0x20)
			} {
				// Write the _preBytes data into the tempBytes memory 32 bytes
				// at a time.
				mstore(mc, mload(cc))
			}

			// Add the length of _postBytes to the current length of tempBytes
			// and store it as the new length in the first 32 bytes of the
			// tempBytes memory.
			length := mload(_postBytes)
			mstore(tempBytes, add(length, mload(tempBytes)))

			// Move the memory counter back from a multiple of 0x20 to the
			// actual end of the _preBytes data.
			mc := end
			// Stop copying when the memory counter reaches the new combined
			// length of the arrays.
			end := add(mc, length)

			for {
				let cc := add(_postBytes, 0x20)
			} lt(mc, end) {
				mc := add(mc, 0x20)
				cc := add(cc, 0x20)
			} {
				mstore(mc, mload(cc))
			}

			// Update the free-memory pointer by padding our last write location
			// to 32 bytes: add 31 bytes to the end of tempBytes to move to the
			// next 32 byte block, then round down to the nearest multiple of
			// 32. If the sum of the length of the two arrays is zero then add
			// one before rounding down to leave a blank 32 bytes (the length block with 0).
			mstore(
				0x40,
				and(
					add(add(end, iszero(add(length, mload(_preBytes)))), 31),
					not(31) // Round down to the nearest 32 bytes.
				)
			)
		}

		return tempBytes;
	}

	function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
		assembly {
			// Read the first 32 bytes of _preBytes storage, which is the length
			// of the array. (We don't need to use the offset into the slot
			// because arrays use the entire slot.)
			let fslot := sload(_preBytes.slot)
			// Arrays of 31 bytes or less have an even value in their slot,
			// while longer arrays have an odd value. The actual length is
			// the slot divided by two for odd values, and the lowest order
			// byte divided by two for even values.
			// If the slot is even, bitwise and the slot with 255 and divide by
			// two to get the length. If the slot is odd, bitwise and the slot
			// with -1 and divide by two.
			let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
			let mlength := mload(_postBytes)
			let newlength := add(slength, mlength)
			// slength can contain both the length and contents of the array
			// if length < 32 bytes so let's prepare for that
			// v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
			switch add(lt(slength, 32), lt(newlength, 32))
			case 2 {
				// Since the new array still fits in the slot, we just need to
				// update the contents of the slot.
				// uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
				sstore(
					_preBytes.slot,
					// all the modifications to the slot are inside this
					// next block
					add(
						// we can just add to the slot contents because the
						// bytes we want to change are the LSBs
						fslot,
						add(
							mul(
								div(
									// load the bytes from memory
									mload(add(_postBytes, 0x20)),
									// zero all bytes to the right
									exp(0x100, sub(32, mlength))
								),
								// and now shift left the number of bytes to
								// leave space for the length in the slot
								exp(0x100, sub(32, newlength))
							),
							// increase length by the double of the memory
							// bytes length
							mul(mlength, 2)
						)
					)
				)
			}
			case 1 {
				// The stored value fits in the slot, but the combined value
				// will exceed it.
				// get the keccak hash to get the contents of the array
				mstore(0x0, _preBytes.slot)
				let sc := add(keccak256(0x0, 0x20), div(slength, 32))

				// save new length
				sstore(_preBytes.slot, add(mul(newlength, 2), 1))

				// The contents of the _postBytes array start 32 bytes into
				// the structure. Our first read should obtain the `submod`
				// bytes that can fit into the unused space in the last word
				// of the stored array. To get this, we read 32 bytes starting
				// from `submod`, so the data we read overlaps with the array
				// contents by `submod` bytes. Masking the lowest-order
				// `submod` bytes allows us to add that value directly to the
				// stored value.

				let submod := sub(32, slength)
				let mc := add(_postBytes, submod)
				let end := add(_postBytes, mlength)
				let mask := sub(exp(0x100, submod), 1)

				sstore(
					sc,
					add(
						and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
						and(mload(mc), mask)
					)
				)

				for {
					mc := add(mc, 0x20)
					sc := add(sc, 1)
				} lt(mc, end) {
					sc := add(sc, 1)
					mc := add(mc, 0x20)
				} {
					sstore(sc, mload(mc))
				}

				mask := exp(0x100, sub(mc, end))

				sstore(sc, mul(div(mload(mc), mask), mask))
			}
			default {
				// get the keccak hash to get the contents of the array
				mstore(0x0, _preBytes.slot)
				// Start copying to the last used word of the stored array.
				let sc := add(keccak256(0x0, 0x20), div(slength, 32))

				// save new length
				sstore(_preBytes.slot, add(mul(newlength, 2), 1))

				// Copy over the first `submod` bytes of the new data as in
				// case 1 above.
				let slengthmod := mod(slength, 32)
				let submod := sub(32, slengthmod)
				let mc := add(_postBytes, submod)
				let end := add(_postBytes, mlength)
				let mask := sub(exp(0x100, submod), 1)

				sstore(sc, add(sload(sc), and(mload(mc), mask)))

				for {
					sc := add(sc, 1)
					mc := add(mc, 0x20)
				} lt(mc, end) {
					sc := add(sc, 1)
					mc := add(mc, 0x20)
				} {
					sstore(sc, mload(mc))
				}

				mask := exp(0x100, sub(mc, end))

				sstore(sc, mul(div(mload(mc), mask), mask))
			}
		}
	}

	function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
		if (_length + 31 < _length) revert SliceOverflow();
		if (_bytes.length < _start + _length) revert SliceOutOfBounds();

		bytes memory tempBytes;

		assembly {
			switch iszero(_length)
			case 0 {
				// Get a location of some free memory and store it in tempBytes as
				// Solidity does for memory variables.
				tempBytes := mload(0x40)

				// The first word of the slice result is potentially a partial
				// word read from the original array. To read it, we calculate
				// the length of that partial word and start copying that many
				// bytes into the array. The first word we copy will start with
				// data we don't care about, but the last `lengthmod` bytes will
				// land at the beginning of the contents of the new array. When
				// we're done copying, we overwrite the full first word with
				// the actual length of the slice.
				let lengthmod := and(_length, 31)

				// The multiplication in the next line is necessary
				// because when slicing multiples of 32 bytes (lengthmod == 0)
				// the following copy loop was copying the origin's length
				// and then ending prematurely not copying everything it should.
				let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
				let end := add(mc, _length)

				for {
					// The multiplication in the next line has the same exact purpose
					// as the one above.
					let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
				} lt(mc, end) {
					mc := add(mc, 0x20)
					cc := add(cc, 0x20)
				} {
					mstore(mc, mload(cc))
				}

				mstore(tempBytes, _length)

				//update free-memory pointer
				//allocating the array padded to 32 bytes like the compiler does now
				mstore(0x40, and(add(mc, 31), not(31)))
			}
			//if we want a zero-length slice let's just return a zero-length array
			default {
				tempBytes := mload(0x40)
				//zero out the 32 bytes slice we are about to return
				//we need to do it because Solidity does not garbage collect
				mstore(tempBytes, 0)

				mstore(0x40, add(tempBytes, 0x20))
			}
		}

		return tempBytes;
	}

	function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
		if (_bytes.length < _start + 20) {
			revert AddressOutOfBounds();
		}
		address tempAddress;

		assembly {
			tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
		}

		return tempAddress;
	}

	function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
		if (_bytes.length < _start + 1) {
			revert UintOutOfBounds();
		}
		uint8 tempUint;

		assembly {
			tempUint := mload(add(add(_bytes, 0x1), _start))
		}

		return tempUint;
	}

	function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
		if (_bytes.length < _start + 2) {
			revert UintOutOfBounds();
		}
		uint16 tempUint;

		assembly {
			tempUint := mload(add(add(_bytes, 0x2), _start))
		}

		return tempUint;
	}

	function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
		if (_bytes.length < _start + 4) {
			revert UintOutOfBounds();
		}
		uint32 tempUint;

		assembly {
			tempUint := mload(add(add(_bytes, 0x4), _start))
		}

		return tempUint;
	}

	function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
		if (_bytes.length < _start + 8) {
			revert UintOutOfBounds();
		}
		uint64 tempUint;

		assembly {
			tempUint := mload(add(add(_bytes, 0x8), _start))
		}

		return tempUint;
	}

	function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
		if (_bytes.length < _start + 12) {
			revert UintOutOfBounds();
		}
		uint96 tempUint;

		assembly {
			tempUint := mload(add(add(_bytes, 0xc), _start))
		}

		return tempUint;
	}

	function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
		if (_bytes.length < _start + 16) {
			revert UintOutOfBounds();
		}
		uint128 tempUint;

		assembly {
			tempUint := mload(add(add(_bytes, 0x10), _start))
		}

		return tempUint;
	}

	function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
		if (_bytes.length < _start + 32) {
			revert UintOutOfBounds();
		}
		uint256 tempUint;

		assembly {
			tempUint := mload(add(add(_bytes, 0x20), _start))
		}

		return tempUint;
	}

	function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
		if (_bytes.length < _start + 32) {
			revert UintOutOfBounds();
		}
		bytes32 tempBytes32;

		assembly {
			tempBytes32 := mload(add(add(_bytes, 0x20), _start))
		}

		return tempBytes32;
	}

	function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
		bool success = true;

		assembly {
			let length := mload(_preBytes)

			// if lengths don't match the arrays are not equal
			switch eq(length, mload(_postBytes))
			case 1 {
				// cb is a circuit breaker in the for loop since there's
				//  no said feature for inline assembly loops
				// cb = 1 - don't breaker
				// cb = 0 - break
				let cb := 1

				let mc := add(_preBytes, 0x20)
				let end := add(mc, length)

				for {
					let cc := add(_postBytes, 0x20)
					// the next line is the loop condition:
					// while(uint256(mc < end) + cb == 2)
				} eq(add(lt(mc, end), cb), 2) {
					mc := add(mc, 0x20)
					cc := add(cc, 0x20)
				} {
					// if any of these checks fails then arrays are not equal
					if iszero(eq(mload(mc), mload(cc))) {
						// unsuccess:
						success := 0
						cb := 0
					}
				}
			}
			default {
				// unsuccess:
				success := 0
			}
		}

		return success;
	}

	function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
		bool success = true;

		assembly {
			// we know _preBytes_offset is 0
			let fslot := sload(_preBytes.slot)
			// Decode the length of the stored array like in concatStorage().
			let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
			let mlength := mload(_postBytes)

			// if lengths don't match the arrays are not equal
			switch eq(slength, mlength)
			case 1 {
				// slength can contain both the length and contents of the array
				// if length < 32 bytes so let's prepare for that
				// v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
				if iszero(iszero(slength)) {
					switch lt(slength, 32)
					case 1 {
						// blank the last byte which is the length
						fslot := mul(div(fslot, 0x100), 0x100)

						if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
							// unsuccess:
							success := 0
						}
					}
					default {
						// cb is a circuit breaker in the for loop since there's
						//  no said feature for inline assembly loops
						// cb = 1 - don't breaker
						// cb = 0 - break
						let cb := 1

						// get the keccak hash to get the contents of the array
						mstore(0x0, _preBytes.slot)
						let sc := keccak256(0x0, 0x20)

						let mc := add(_postBytes, 0x20)
						let end := add(mc, mlength)

						// the next line is the loop condition:
						// while(uint256(mc < end) + cb == 2)
						// solhint-disable-next-line no-empty-blocks
						for {

						} eq(add(lt(mc, end), cb), 2) {
							sc := add(sc, 1)
							mc := add(mc, 0x20)
						} {
							if iszero(eq(sload(sc), mload(mc))) {
								// unsuccess:
								success := 0
								cb := 0
							}
						}
					}
				}
			}
			default {
				// unsuccess:
				success := 0
			}
		}

		return success;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibAsset} from "./LibAsset.sol";
import {LibUtil} from "./LibUtil.sol";
import {InvalidContract, NoSwapFromZeroBalance, InsufficientBalance} from "../Errors/GenericErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibSwap {
	struct SwapData {
		address callTo;
		address approveTo;
		address sendingAssetId;
		address receivingAssetId;
		uint256 fromAmount;
		bytes callData;
		bool requiresDeposit;
	}

	event AssetSwapped(
		bytes32 transactionId,
		address dex,
		address fromAssetId,
		address toAssetId,
		uint256 fromAmount,
		uint256 toAmount,
		uint256 timestamp
	);

	function swap(bytes32 transactionId, SwapData calldata _swap) internal {
		if (!LibAsset.isContract(_swap.callTo)) revert InvalidContract();
		uint256 fromAmount = _swap.fromAmount;
		if (fromAmount == 0) revert NoSwapFromZeroBalance();
		uint256 nativeValue = LibAsset.isNativeAsset(_swap.sendingAssetId) ? _swap.fromAmount : 0;
		uint256 initialSendingAssetBalance = LibAsset.getOwnBalance(_swap.sendingAssetId);
		uint256 initialReceivingAssetBalance = LibAsset.getOwnBalance(_swap.receivingAssetId);

		if (nativeValue == 0) {
			LibAsset.maxApproveERC20(IERC20(_swap.sendingAssetId), _swap.approveTo, _swap.fromAmount);
		}

		if (initialSendingAssetBalance < _swap.fromAmount) {
			revert InsufficientBalance(_swap.fromAmount, initialSendingAssetBalance);
		}

		//solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory res) = _swap.callTo.call{value: nativeValue}(_swap.callData);
		if (!success) {
			string memory reason = LibUtil.getRevertMsg(res);
			revert(reason);
		}

		uint256 newBalance = LibAsset.getOwnBalance(_swap.receivingAssetId);

		emit AssetSwapped(
			transactionId,
			_swap.callTo,
			_swap.sendingAssetId,
			_swap.receivingAssetId,
			_swap.fromAmount,
			newBalance > initialReceivingAssetBalance ? newBalance - initialReceivingAssetBalance : newBalance,
			block.timestamp
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LibBytes.sol";

library LibUtil {
	using LibBytes for bytes;

	function getRevertMsg(bytes memory _res) internal pure returns (string memory) {
		// If the _res length is less than 68, then the transaction failed silently (without a revert message)
		if (_res.length < 68) return "Transaction reverted silently";
		bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
		return abi.decode(revertData, (string)); // All that remains is the revert string
	}

	/// @notice Determines whether the given address is the zero address
	/// @param addr The address to verify
	/// @return Boolean indicating if the address is the zero address
	function isZeroAddress(address addr) internal pure returns (bool) {
		return addr == address(0);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "../Helpers/ReentrancyGuard.sol";
import {LibSwap} from "../Libraries/LibSwap.sol";
import {LibAsset} from "../Libraries/LibAsset.sol";
import {IKana} from "../Interfaces/IKana.sol";
import {IExecutor} from "../Interfaces/IExecutor.sol";
import {IStargateReceiver} from "../Interfaces/LZ/IStargateReceiver.sol";
import {TransferrableOwnership} from "../Helpers/TransferrableOwnership.sol";
import {ExternalCallFailed, UnAuthorized} from "../Errors/GenericErrors.sol";

/// @title Executor
/// @author KANA
/// @notice Arbitrary execution contract used for cross-chain swaps and message passing
/// @custom:version 2.0.0
contract StargateReceiver is IKana, ReentrancyGuard, TransferrableOwnership {
	using SafeERC20 for IERC20;

	/// Storage ///
	address public sgRouter;
	IExecutor public executor;
	uint256 public recoverGas;

	/// Events ///
	event StargateRouterSet(address indexed router);
	event ExecutorSet(address indexed executor);
	event RecoverGasSet(uint256 indexed recoverGas);

	/// Modifiers ///
	modifier onlySGRouter() {
		if (msg.sender != sgRouter) {
			revert UnAuthorized();
		}
		_;
	}

	/// Constructor
	constructor(
		address _owner,
		address _sgRouter,
		address _executor,
		uint256 _recoverGas
	) TransferrableOwnership(_owner) {
		owner = _owner;
		sgRouter = _sgRouter;
		executor = IExecutor(_executor);
		recoverGas = _recoverGas;
		emit StargateRouterSet(_sgRouter);
		emit RecoverGasSet(_recoverGas);
	}

	/// External Methods ///

	/// @notice Completes a cross-chain transaction on the receiving chain.
	/// @dev This function is called from Stargate Router.
	/// @param * (unused) The remote chainId sending the tokens
	/// @param * (unused) The remote Bridge address
	/// @param * (unused) Nonce
	/// @param _token The token contract on the local chain
	/// @param _amountLD The amount of tokens received through bridging
	/// @param _payload The data to execute
	function sgReceive(
		uint16, // _srcChainId unused
		bytes memory, // _srcAddress unused
		uint256, // _nonce unused
		address _token,
		uint256 _amountLD,
		bytes memory _payload
	) external nonReentrant onlySGRouter {
		(bytes32 transactionId, LibSwap.SwapData[] memory swapData, address receiver) = abi.decode(
			_payload,
			(bytes32, LibSwap.SwapData[], address)
		);

		_swapAndCompleteBridgeTokens(
			transactionId,
			swapData,
			swapData.length > 0 ? swapData[0].sendingAssetId : _token, // If swapping assume sent token is the first token in swapData
			payable(receiver),
			_amountLD,
			true
		);
	}

	/// @notice Performs a swap before completing a cross-chain transaction
	/// @param _transactionId the transaction id associated with the operation
	/// @param _swapData array of data needed for swaps
	/// @param assetId token received from the other chain
	/// @param receiver address that will receive tokens in the end
	function swapAndCompleteBridgeTokens(
		bytes32 _transactionId,
		LibSwap.SwapData[] memory _swapData,
		address assetId,
		address payable receiver
	) external payable nonReentrant {
		if (LibAsset.isNativeAsset(assetId)) {
			_swapAndCompleteBridgeTokens(_transactionId, _swapData, assetId, receiver, msg.value, false);
		} else {
			uint256 allowance = IERC20(assetId).allowance(msg.sender, address(this));
			LibAsset.depositAsset(assetId, allowance);
			_swapAndCompleteBridgeTokens(_transactionId, _swapData, assetId, receiver, allowance, false);
		}
	}

	/// @notice Send remaining token to receiver
	/// @param assetId token received from the other chain
	/// @param receiver address that will receive tokens in the end
	/// @param amount amount of token
	function pullToken(address assetId, address payable receiver, uint256 amount) external onlyOwner {
		if (LibAsset.isNativeAsset(assetId)) {
			// solhint-disable-next-line avoid-low-level-calls
			(bool success, ) = receiver.call{value: amount}("");
			if (!success) revert ExternalCallFailed();
		} else {
			IERC20(assetId).safeTransfer(receiver, amount);
		}
	}

	/// Private Methods ///

	/// @notice Performs a swap before completing a cross-chain transaction
	/// @param _transactionId the transaction id associated with the operation
	/// @param _swapData array of data needed for swaps
	/// @param assetId token received from the other chain
	/// @param receiver address that will receive tokens in the end
	/// @param amount amount of token
	/// @param reserveRecoverGas whether we need a gas buffer to recover
	function _swapAndCompleteBridgeTokens(
		bytes32 _transactionId,
		LibSwap.SwapData[] memory _swapData,
		address assetId,
		address payable receiver,
		uint256 amount,
		bool reserveRecoverGas
	) private {
		uint256 _recoverGas = reserveRecoverGas ? recoverGas : 0;

		if (LibAsset.isNativeAsset(assetId)) {
			// case 1: native asset
			uint256 cacheGasLeft = gasleft();
			if (reserveRecoverGas && cacheGasLeft < _recoverGas) {
				// case 1a: not enough gas left to execute calls
				// solhint-disable-next-line avoid-low-level-calls
				(bool success, ) = receiver.call{value: amount}("");
				if (!success) revert ExternalCallFailed();

				emit KanaTransferRecovered(_transactionId, assetId, receiver, amount, block.timestamp);
				return;
			}

			// case 1b: enough gas left to execute calls
			// solhint-disable no-empty-blocks
			try
				executor.swapAndCompleteBridgeTokens{value: amount, gas: cacheGasLeft - _recoverGas}(
					_transactionId,
					_swapData,
					assetId,
					receiver
				)
			{} catch {
				// solhint-disable-next-line avoid-low-level-calls
				(bool success, ) = receiver.call{value: amount}("");
				if (!success) revert ExternalCallFailed();

				emit KanaTransferRecovered(_transactionId, assetId, receiver, amount, block.timestamp);
			}
		} else {
			// case 2: ERC20 asset
			uint256 cacheGasLeft = gasleft();
			IERC20 token = IERC20(assetId);
			token.safeApprove(address(executor), 0);

			if (reserveRecoverGas && cacheGasLeft < _recoverGas) {
				// case 2a: not enough gas left to execute calls
				token.safeTransfer(receiver, amount);

				emit KanaTransferRecovered(_transactionId, assetId, receiver, amount, block.timestamp);
				return;
			}

			// case 2b: enough gas left to execute calls
			token.safeIncreaseAllowance(address(executor), amount);
			try
				executor.swapAndCompleteBridgeTokens{gas: cacheGasLeft - _recoverGas}(
					_transactionId,
					_swapData,
					assetId,
					receiver
				)
			{} catch {
				token.safeTransfer(receiver, amount);
				emit KanaTransferRecovered(_transactionId, assetId, receiver, amount, block.timestamp);
			}

			token.safeApprove(address(executor), 0);
		}
	}

	/// @notice Receive native asset directly.
	/// @dev Some bridges may send native asset before execute external calls.
	// solhint-disable-next-line no-empty-blocks
	receive() external payable {}
}