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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ICoreConfiguration.sol";
import "./IOracleConnector.sol";
import "./IOptionsFlashCallback.sol";

interface ICore {
    enum PositionStatus {
        PENDING,
        EXECUTED,
        CANCELED
    }

    enum OrderDirectionType {
        UP,
        DOWN
    }

    struct Counters {
        uint256 ordersCount;
        uint256 positionsCount;
        uint256 totalStableAmount;
    }

    struct Order {
        OrderDescription data;
        address creator;
        uint256 amount;
        uint256 reserved;
        uint256 available;
        bool closed;
    }

    struct OrderDescription {
        address oracle;
        uint256 percent;
        OrderDirectionType direction;
        uint256 rate;
        uint256 duration;
        bool reinvest;
    }

    struct Position {
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        uint256 endPrice;
        uint256 deviationPrice;
        uint256 protocolFee;
        uint256 amountCreator;
        uint256 amountAccepter;
        address winner;
        bool isCreatorWinner;
        PositionStatus status;
    }

    struct Accept {
        uint256 orderId;
        uint256 amount;
        bytes[] updateData;
    }

    function configuration() external view returns (ICoreConfiguration);

    function positionIdToOrderId(uint256) external view returns (uint256);

    function creatorToOrders(address, uint256) external view returns (uint256);

    function orderIdToPositions(uint256, uint256) external view returns (uint256);

    function counters() external view returns (Counters memory);

    function creatorOrdersCount(address creator) external view returns (uint256);

    function orderIdPositionsCount(uint256 orderId) external view returns (uint256);

    function positions(uint256 id) external view returns (Position memory);

    function orders(uint256 id) external view returns (Order memory);

    function availableFeeAmount() external view returns (uint256);

    function permitPeriphery() external view returns (address);

    event Accepted(uint256 indexed orderId, uint256 indexed positionId, Order order, Position position, uint256 amount);
    event AutoResolved(
        uint256 indexed orderId,
        uint256 indexed positionId,
        address indexed winner,
        uint256 protocolStableFee,
        uint256 autoResolveFee,
        uint256 referralID,
        ICoreUtilities.AffiliationUserData affiliation
    );
    event OrderCreated(uint256 orderId, Order order);
    event OrderClosed(uint256 orderId, Order order);
    event Flashloan(address indexed caller, address indexed receiver, uint256 amount, uint256 fee);
    event FeeClaimed(uint256 amount);
    event OrderIncreased(uint256 indexed orderId, uint256 amount);
    event OrderWithdrawal(uint256 indexed orderId, uint256 amount);

    function accept(address accepter, Accept[] memory data) external returns (uint256[] memory positionIds);

    function autoResolve(uint256 positionId, bytes[] calldata updateData) external returns (bool);

    function closeOrder(uint256 orderId) external returns (bool);

    function createOrder(
        address creator,
        OrderDescription memory data,
        uint256 amount
    ) external returns (uint256 orderId);

    function flashloan(address recipient, uint256 amount, bytes calldata data) external returns (bool);

    function increaseOrder(uint256 orderId, uint256 amount) external returns (bool);

    function withdrawOrder(uint256 orderId, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20Stable.sol";
import "./IPositionToken.sol";
import "./IFoxifyAffiliation.sol";
import "./IFoxifyReferral.sol";
import "./IFoxifyBlacklist.sol";
import "./ISwapperConnector.sol";
import "./ICoreUtilities.sol";

interface ICoreConfiguration {
    struct FeeConfiguration {
        address feeRecipient;
        uint256 autoResolveFee;
        uint256 protocolFee;
        uint256 flashloanFee;
    }

    struct ImmutableConfiguration {
        IFoxifyBlacklist blacklist;
        IFoxifyReferral referral;
        IFoxifyAffiliation affiliation;
        IPositionToken positionTokenAccepter;
        IERC20Stable stable;
        ICoreUtilities utils;
    }

    struct LimitsConfiguration {
        uint256 minKeeperFee;
        uint256 minOrderRate;
        uint256 maxOrderRate;
        uint256 minDuration;
        uint256 maxDuration;
        uint256 maxAutoResolveDuration;
    }

    struct NFTDiscountLevel {
        uint256 bronze;
        uint256 silver;
        uint256 gold;
    }

    struct Swapper {
        ISwapperConnector swapperConnector;
        bytes path;
    }

    function discount() external view returns (uint256 bronze, uint256 silver, uint256 gold);

    function feeConfiguration()
        external
        view
        returns (address feeRecipient, uint256 autoResolveFee, uint256 protocolFee, uint256 flashloanFee);

    function immutableConfiguration()
        external
        view
        returns (
            IFoxifyBlacklist blacklist,
            IFoxifyReferral referral,
            IFoxifyAffiliation affiliation,
            IPositionToken positionTokenAccepter,
            IERC20Stable stable,
            ICoreUtilities utils
        );

    function keepers(uint256 index) external view returns (address);

    function keepersCount() external view returns (uint256);

    function keepersContains(address keeper) external view returns (bool);

    function limitsConfiguration()
        external
        view
        returns (
            uint256 minKeeperFee,
            uint256 minOrderRate,
            uint256 maxOrderRate,
            uint256 minDuration,
            uint256 maxDuration,
            uint256 maxAutoResolveDuration
        );

    function oracles(uint256 index) external view returns (address);

    function oraclesCount() external view returns (uint256);

    function oraclesContains(address oracle) external view returns (bool);

    function oraclesWhitelist(uint256 index) external view returns (address);

    function oraclesWhitelistCount() external view returns (uint256);

    function oraclesWhitelistContains(address oracle) external view returns (bool);

    function swapper() external view returns (ISwapperConnector swapperConnector, bytes memory path);

    event DiscountUpdated(NFTDiscountLevel discount_);
    event FeeConfigurationUpdated(FeeConfiguration config);
    event KeepersAdded(address[] keepers);
    event KeepersRemoved(address[] keepers);
    event LimitsConfigurationUpdated(LimitsConfiguration config);
    event OraclesAdded(address[] oracles);
    event OraclesRemoved(address[] oracles);
    event OraclesWhitelistRemoved(address[] oracles);
    event SwapperUpdated(Swapper swapper);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20Stable.sol";
import "./IOracleConnector.sol";
import "./IFoxifyAffiliation.sol";
import "./ICoreConfiguration.sol";
import "./ISwapperConnector.sol";

interface ICoreUtilities {
    struct AffiliationUserData {
        uint256 activeId;
        uint256 team;
        uint256 discount;
        IFoxifyAffiliation.NFTData nftData;
    }

    function calculateStableFee(
        address affiliationUser,
        uint256 amount,
        uint256 fee
    ) external view returns (AffiliationUserData memory affiliationUserData_, uint256 fee_);

    function configuration() external view returns (ICoreConfiguration);

    function calculateMinAcceptAmount(uint256 rate) external view returns (uint256 minAmount);

    function getPriceForAutoResolve(
        address oracle,
        uint256 endTime,
        bytes[] calldata updateData
    ) external returns (bool canceled, uint256 price);

    function getPriceForAccept(
        address oracle,
        uint256 endTime,
        bytes[] calldata updateData
    ) external returns (uint256 price);

    function initialize(address configuration_) external returns (bool);

    function swap(address recipient, uint256 winnerTotalAmount) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20Stable is IERC20, IERC20Permit {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFoxifyAffiliation {
    enum Level {
        UNKNOWN,
        BRONZE,
        SILVER,
        GOLD
    }

    struct NFTData {
        Level level;
        bytes32 randomValue;
        uint256 timestamp;
    }

    function data(uint256) external view returns (NFTData memory);

    function usersActiveID(address) external view returns (uint256);

    function usersTeam(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFoxifyBlacklist {
    function blacklist(uint256 index) external view returns (address);

    function blacklistCount() external view returns (uint256);

    function blacklistContains(address wallet) external view returns (bool);

    function blacklistList(uint256 offset, uint256 limit) external view returns (address[] memory output);

    event Blacklisted(address[] wallets);
    event Unblacklisted(address[] wallets);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFoxifyReferral {
    function maxTeamID() external view returns (uint256);

    function teamOwner(uint256) external view returns (address);

    function userTeamID(address) external view returns (uint256);

    event TeamCreated(uint256 teamID, address owner);
    event TeamJoined(uint256 indexed teamID, address indexed user);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOptionsFlashCallback {
    function optionsFlashCallback(address account, uint256 amount, uint256 fee, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOracleConnector {
    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function paused() external view returns (bool);

    function validateTimestamp(uint256) external view returns (bool);

    function getPrice() external view returns (uint256 price, uint256 timestamp);

    function updatePrice(bytes[] calldata updateData) external payable returns (uint256 price, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ICore.sol";

interface IPermitPeriphery {
    struct Permit {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function acceptWithPermit(
        ICore core,
        ICore.Accept[] memory data,
        Permit memory permit
    ) external returns (uint256[] memory positionIds);

    function createOrderWithPermit(
        ICore core,
        ICore.OrderDescription memory data,
        uint256 amount,
        Permit memory permit
    ) external returns (uint256);

    function increaseOrderWithPermit(
        ICore core,
        uint256 orderId,
        uint256 amount,
        Permit memory permit
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IPositionToken is IERC721Metadata {
    function burn(uint256 id) external returns (bool);

    function mint(address account, uint256 id) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISwapperConnector {
    function getAmountIn(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    event Swapped(address indexed recipient, address indexed tokenIn, uint256 amountIn, uint256 amountOut);

    function swap(
        bytes memory path,
        address tokenIn,
        uint256 amountIn,
        address recipient
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPermitPeriphery.sol";

/**
 * @title PermitPeriphery
 * @notice This smart contract implements methods for working with orders and positions using a permit.
 */
contract PermitPeriphery is IPermitPeriphery {
    using SafeERC20 for IERC20Stable;

    /**
     * @notice Allows a user to accept an order using permit signatures.
     * @param core The address of the core contract.
     * @param data The Accept struct containing the amount and orderId.
     * @param permit A struct containing the permit signature data.
     * @return positionIds The IDs of the created positions.
     */
    function acceptWithPermit(
        ICore core,
        ICore.Accept[] memory data,
        Permit memory permit
    ) external returns (uint256[] memory positionIds) {
        uint256 totalAmount = 0;
        (, , , , IERC20Stable stable, ) = core.configuration().immutableConfiguration();
        stable.permit(msg.sender, address(this), permit.value, permit.deadline, permit.v, permit.r, permit.s);
        for (uint256 i = 0; i < data.length; i++) totalAmount += data[i].amount;
        stable.safeTransferFrom(msg.sender, address(this), totalAmount);
        stable.approve(address(core), totalAmount);
        positionIds = core.accept(msg.sender, data);
    }

    /**
     * @notice Allows a user to create an order using permit signatures.
     * @param core The address of the core contract.
     * @param data A struct containing the order details.
     * @param amount The amount of tokens being transferred.
     * @param permit A struct containing the permit signature data.
     * @return The ID of the created order.
     */
    function createOrderWithPermit(
        ICore core,
        ICore.OrderDescription memory data,
        uint256 amount,
        Permit memory permit
    ) external returns (uint256) {
        (, , , , IERC20Stable stable, ) = core.configuration().immutableConfiguration();
        stable.permit(msg.sender, address(this), permit.value, permit.deadline, permit.v, permit.r, permit.s);
        stable.safeTransferFrom(msg.sender, address(this), amount);
        stable.approve(address(core), amount);
        return core.createOrder(msg.sender, data, amount);
    }

    /**
     * @notice Allows a user to increase an order using permit signatures.
     * @param core The address of the core contract.
     * @param orderId The ID of the order being increased.
     * @param amount The amount of tokens being transferred.
     * @param permit A struct containing the permit signature data.
     * @return A boolean indicating whether the order was successfully increased.
     */
    function increaseOrderWithPermit(
        ICore core,
        uint256 orderId,
        uint256 amount,
        Permit memory permit
    ) external returns (bool) {
        (, , , , IERC20Stable stable, ) = core.configuration().immutableConfiguration();
        stable.permit(msg.sender, address(this), permit.value, permit.deadline, permit.v, permit.r, permit.s);
        stable.safeTransferFrom(msg.sender, address(this), amount);
        stable.approve(address(core), amount);
        return core.increaseOrder(orderId, amount);
    }
}