// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;
import "@openzeppelin/contracts/access/Ownable.sol";
import {StringUtils} from "../libraries/StringUtils.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";  //防止重入
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TimeContent is Ownable,ReentrancyGuard{
    uint256 private pointId; //监察者Id
    uint256 private _contentId; //事务Id
    uint256 private passVote=3; //审核通过票数
    uint256 private punishPassVote=3; //惩戒通过票数
    uint256 contractLock=1;  //1不锁定其余锁定
    address private whaleNft;  //平台专属nft

    //引入SafeERC20
    using SafeERC20 for IERC20;
    //测试token：0x09943Fa8DD32C76f7b880627a0F6af73e8f5A595

    //审查者
    mapping(address=>bool)public addressToBool;
  
    //事务
    mapping(string=>uint256)public contentNameToId; //事务name返回id
    mapping(uint256=>address)public contentIdToAddress; //事务id返回地址
    mapping(string=>bool)public contentNameToBool;  //事务name是否已经存在
    //发起者对某个事务的转入合约token数量
    mapping(address=>mapping(uint256=>uint256))private userTradeBalance;
    //name到惩戒事件id
    mapping(string=>uint256)public nameToPunishId;
    

    //事务者对一事件已投票的证明
    mapping(address=>mapping(uint256=>bool))public supervisorVoteProof;
    //事务者对惩戒事件已投票的证明
    mapping(address=>mapping(uint256=>bool))public supervisorVotePunish;

    //监察者
    struct supervisor{
        uint256 supervisorId;   //监察者Id
        string supervisorName;  //监察者名字
        address supervisorAddress;  //监察者地址
    }
    supervisor[] public _supervisor;

    //事务
    struct contentThing{
        uint256 contentId;        //事务Id
        string contentName;       //事务名称  
        string contentWillThing;  //将要执行的委托内容
        uint256 tradeMoney;       //交易金额
        uint256 startTime;        //开始时间
        uint256 endTime;          //结束时间
        address sourceAddress;    //发起者
        address pointAddress;     //指定者
        bool sendContentWhether;      //发起者确认事务是否开始
        bool receiverContentWhether;   //接收者确认事务是否进行
        uint256 votedSum; //审查者已经投的总数
        address choosedToken;  //选择交易的token
    }
    contentThing[] public _waitContentThing;

    //违约事务
    struct punishment{
        uint256 punishId;
        uint256 allPunishVotes;
        string senderProof;  //发送者证据
        string receiverProof; //接收者证据
        bool punishState; //是否为违约事件
    }
    punishment[] public _punishment;

    constructor() payable{}

    //modifier
    //锁
    modifier lockState() {
        require(contractLock==1,"Contract locked");
        _;
    }

    //改变锁定状态
    function changeLock(uint256 contractState)public onlyOwner{
        contractLock=contractState;
    }

    //用户创建事务
    function createThing(string calldata _contentName,string memory _willThing,uint256 _tradeMoney,uint256 _endTime,address _pointAddress,address token)public{   
        //事务名字长度
        uint256 _thisContentName=StringUtils.strlen(_contentName);
        //转账金额
        uint256 transferMoney=_tradeMoney*1 ether;
        //结束时间
        uint256 getEndTime=_endTime+block.timestamp;
        //结束时间需要>=发起时间5min
        require(getEndTime>=block.timestamp+60,"End time need >= 5min");
        require(_pointAddress!=msg.sender && _pointAddress!=address(0));
        require(_thisContentName>=1 && _thisContentName<=100);  //事务名称需要在1~100间
        require(_tradeMoney>=100 && _tradeMoney<=10000000000);  //交易金额是否在100~10000000000;
        require(contentNameToBool[_contentName]!=true,"This contentName already existed!"); //事务名字是否已经存在
        contentNameToBool[_contentName]=true;       //确定事务名字是否注册
        contentNameToId[_contentName]=_contentId;   //根据事务名字，得到Id
        contentIdToAddress[_contentId]=msg.sender;
        nameToPunishId[_contentName]=_contentId;  //根据事务name到惩罚事件id
       
        //将事务信息推送
        _waitContentThing.push(
            contentThing({
            contentId:_contentId,
            contentName:_contentName,
            contentWillThing:_willThing,
            tradeMoney:transferMoney,
            startTime:block.timestamp,
            endTime:getEndTime,
            sourceAddress:msg.sender,
            pointAddress:_pointAddress,
            sendContentWhether:false,
            receiverContentWhether:false,
            votedSum:0,
            choosedToken:token}));

        //违约事件
        _punishment.push(punishment(_contentId,0,"","",false));
        _contentId++;
    }

    //官方设置whale的nft合约地址是多少
    function setWhale(address whaleContract)public onlyOwner{
        whaleNft=whaleContract;
    }

    //添加审查者
    function addSupervisors(address waitAddress,string calldata _supervisorName)external onlyOwner{
        require(addressToBool[waitAddress]!=true);
        addressToBool[waitAddress]=true;//是否已经为审查者
        _supervisor.push(supervisor(pointId,_supervisorName,waitAddress));
        pointId++;   
    }

    //移除审查者
    function deleteSupervisors(uint256 _supervisorId)external onlyOwner{
        require(addressToBool[_supervisor[_supervisorId].supervisorAddress]==true);
        addressToBool[_supervisor[_supervisorId].supervisorAddress]=false;
        delete _supervisor[_supervisorId];
    }

    //审核者对事务投票
    function voteContent(string calldata contentName,bool judge)external nonReentrant{
        //根据输入的name查找相应id
        uint256 getVotedId=contentNameToContentId(contentName);
        //是否是审查者
        require(addressToBool[msg.sender]==true,"This address not a Supervisor!");
        //判断地址是否投票
        require(supervisorVoteProof[msg.sender][getVotedId]!=true,"You already voted!");
        supervisorVoteProof[msg.sender][getVotedId]=judge;
        if(judge==true){
            //票数增加
            _waitContentThing[contentNameToContentId(contentName)].votedSum++; 
        }
    }
    //部署者根据情况修改通过票数
    function changePassVote(uint256 inputPassVote,uint256 inputPunishVote)external onlyOwner{
        require(passVote>=3&&punishPassVote>=3,"Change < 3");  //至少>=3票
        passVote=inputPassVote;
        punishPassVote=inputPunishVote;
    }

    //审查者和部署者对违约事件投票
    function votePunish(string calldata contentName,bool _punishJudge)external nonReentrant{
        uint256 thisPunishId=nameToPunishId[contentName];
        //是否是审查者
        require(addressToBool[msg.sender]==true,"This address not a Supervisor!");
        require(supervisorVotePunish[msg.sender][thisPunishId]!=true,"You were already vote!");
        supervisorVotePunish[msg.sender][thisPunishId]=true;
        if(_punishJudge==true){
            _punishment[thisPunishId].allPunishVotes++;
        }else{
            _punishment[thisPunishId].allPunishVotes-=0;
        }
    }

    //发起者是否确定要发起该事务
    function judgeSendContent(bool _thisContent,string calldata contentName)external nonReentrant{
        require(getThisSourceAddress(contentName)==msg.sender);  //判断是否是发起者
        require(getRemainTime(contentName)>0,"time error");  //当前时间是否<结束时间
        _waitContentThing[contentNameToContentId(contentName)].sendContentWhether=_thisContent;  
    }

    //接收者是否确定进行该事务
    function judgeReceiverContent(bool _thisContent,string calldata contentName)external nonReentrant{
        require(getThisPointAddress(contentName)==msg.sender);  //判断是否是事务交易指定者
        require(getRemainTime(contentName)>0,"time error");  //当前时间是否<结束时间
        _waitContentThing[contentNameToContentId(contentName)].receiverContentWhether=_thisContent; 
    }

    //发起者复议证据提交
    function senderProof(string calldata contentName,string calldata sendProofThing)external{
        uint256 thisPunishId=nameToPunishId[contentName];
        require(getThisSourceAddress(contentName)==msg.sender);
        _punishment[thisPunishId].senderProof=sendProofThing;
        _punishment[thisPunishId].punishState=true;
    }

    //指定者复议证据提交
    function pointProof(string calldata contentName,string calldata pointProofThing)external{
        uint256 thisPunishId=nameToPunishId[contentName];
        require(getThisPointAddress(contentName)==msg.sender);
        _punishment[thisPunishId].receiverProof=pointProofThing;
        _punishment[thisPunishId].punishState=true;
    }

    //惩戒事件状态
    function punishState(string calldata contentName)external view returns(bool){
        uint256 thisPunishId=nameToPunishId[contentName];
        return _punishment[thisPunishId].allPunishVotes>=punishPassVote?true:false;
    }

    //当票数大于等于passVote，审核才通过
    function doTimeLock(string calldata contentName)external view returns(bool){
        uint256 totalVotes = _waitContentThing[contentNameToContentId(contentName)].votedSum;  //相应事务的总票数
        return totalVotes>=passVote?true:false;
    }

    //查找某地址是否持有whale
    function checkIfHold(address userAddress)external view returns(uint256){
        return IERC721(whaleNft).balanceOf(userAddress);
    }
    
    //得到锁定状态
    function getLockState()public view returns(uint256){
        return contractLock;
    }

    //事务名字返回Id
    function contentNameToContentId(string calldata name)public view returns(uint256){
        return contentNameToId[name];
    }

    //得到发起者地址
    function getThisSourceAddress(string calldata contentName)public view returns(address){
        uint256 getThisContentId=contentNameToContentId(contentName);
        return _waitContentThing[getThisContentId].sourceAddress;
    }
    //得到接收者地址
    function getThisPointAddress(string calldata contentName)public view returns(address){
        uint256 getThisContentId=contentNameToContentId(contentName);
        return _waitContentThing[getThisContentId].pointAddress;
    }

    //得到事务Token
    function getTradeToken(string calldata contentName)public view returns(address){
        uint256 getThisContentId=contentNameToContentId(contentName);
        return _waitContentThing[getThisContentId].choosedToken;
    }

    //得到交易money
    function getThisTradeMoney(string calldata contentName)public view returns(uint256){
        uint256 getThisContentId=contentNameToContentId(contentName);
        return _waitContentThing[getThisContentId].tradeMoney;
    }

    //得到交易发起者事务确认状态
    function getSenderState(string calldata contentName)public view returns(bool){
        uint256 getThisContentId=contentNameToContentId(contentName);
        return _waitContentThing[getThisContentId].sendContentWhether;
    }

    //得到交易接收者事务确认状态
    function getPointState(string calldata contentName)public view returns(bool){
        uint256 getThisContentId=contentNameToContentId(contentName);
        return _waitContentThing[getThisContentId].receiverContentWhether;
    }

    //得到剩余交易时间
    function getRemainTime(string calldata contentName)public view returns(uint256){
        uint256 getThisContentId=contentNameToContentId(contentName);
        if(block.timestamp<_waitContentThing[getThisContentId].endTime){
            return _waitContentThing[getThisContentId].endTime-block.timestamp;
        }else{
            return 0;
        }
    }

    //得到最近的未完成的惩戒事务
    function getAllNoPunishs()public view returns(punishment[] memory){
        uint256 newFinishId;
        for(uint256 i;i<_punishment.length;i++){
            if(_punishment[i].punishState){
                newFinishId++;
            }
        }
        punishment[] memory newFinishPunishs=new punishment[](newFinishId);
        for(uint256 j;j<_punishment.length;j++){
            for(uint256 a;a<newFinishId;a++){
                if(_punishment[j].punishState&&_punishment[j].allPunishVotes<punishPassVote){
                    newFinishPunishs[a]=_punishment[j];
                }
            }
        }
        return newFinishPunishs;
    }

    //得到最新的500个事务
     function fetchAllContents()public view returns(contentThing[] memory){
        uint256 lastFiveHun;
        uint256 contentsLength;
        if(_waitContentThing.length>500){
            lastFiveHun=_waitContentThing.length-(_waitContentThing.length-500);
            contentsLength=_waitContentThing.length-(_waitContentThing.length-500);
        }else{
            lastFiveHun=0;
            contentsLength=_waitContentThing.length;
        }
        contentThing[] memory allContents = new contentThing[](contentsLength);  //最新的500个
        for(uint256 i=lastFiveHun;i<_waitContentThing.length;i++){
            allContents[i]=_waitContentThing[i];
        }
        return allContents;
    }

    //得到用户个人的最近的50个事务
    function getUserAllContent(address userAddress)public view returns(contentThing[] memory){
        uint256 a;
        for(uint256 i=0;i<_waitContentThing.length;i++){
            if(userAddress==_waitContentThing[i].sourceAddress||userAddress==_waitContentThing[i].pointAddress){
                   a++;
            }
        }
        contentThing[] memory allContents = new contentThing[](a);
        if(a>=1){
            for(uint256 i=0;i<_waitContentThing.length;i++){
                for(uint256 x=0;x<a;x++){
                    if(userAddress==_waitContentThing[i].sourceAddress||userAddress==_waitContentThing[i].pointAddress){
                        allContents[x]=_waitContentThing[i];
                    }
                }
            }
        }
        return allContents;
    }

}

// SPDX-License-Identifier: MIT
// Source:
// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
pragma solidity >=0.6.8;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}