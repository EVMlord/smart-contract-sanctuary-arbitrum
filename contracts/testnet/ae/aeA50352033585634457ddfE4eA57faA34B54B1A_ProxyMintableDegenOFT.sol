// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IAirdropVault} from "src/interfaces/IAirdropVault.sol";

contract AirdropVault is IAirdropVault, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable rebornToken;

    /**
     * @dev receive native token
     */
    receive() external payable {}

    constructor(address owner_, address rebornToken_) {
        if (rebornToken_ == address(0)) revert ZeroAddressSet();
        _transferOwnership(owner_);
        rebornToken = rebornToken_;
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function rewardDegen(
        address to,
        uint256 amount
    ) external virtual override onlyOwner {
        IERC20(rebornToken).safeTransfer(to, amount);
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function rewardNative(
        address to,
        uint256 amount
    ) external virtual override nonReentrant onlyOwner {
        payable(to).transfer(amount);
    }

    /**
     * @notice withdraw token Emergency
     */
    function withdrawEmergency(address to) external virtual override onlyOwner {
        if (to == address(0)) revert ZeroAddressSet();
        uint256 degenBalance = IERC20(rebornToken).balanceOf(address(this));
        uint256 nativeBalance = address(this).balance;
        IERC20(rebornToken).safeTransfer(to, degenBalance);

        payable(to).transfer(nativeBalance);

        emit WithdrawEmergency(to, rebornToken, degenBalance, nativeBalance);
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IAirdropVaultDef {
    error ZeroAddressSet();

    event WithdrawEmergency(
        address indexed to,
        address degenToken,
        uint256 degenAmount,
        uint256 nativeAmount
    );
}

interface IAirdropVault is IAirdropVaultDef {
    function rewardDegen(address to, uint256 amount) external; // send degen reward

    function rewardNative(address to, uint256 amount) external; // send native reward

    function withdrawEmergency(address to) external;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {RBT} from "src/RBT.sol";
import {RewardVault} from "src/RewardVault.sol";
import {BitMapsUpgradeable} from "./oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {PortalLib} from "src/PortalLib.sol";
import {FastArray} from "src/lib/FastArray.sol";
import {IPiggyBank} from "./interfaces/IPiggyBank.sol";
import {AirdropVault} from "src/AirdropVault.sol";
import {Registry} from "src/Registry.sol";

abstract contract RebornPortalStorage is IRebornDefination {
    //########### Link Contract Address ########## //
    RBT private rebornToken;
    RewardVault public vault;
    address public burnPool;
    IPiggyBank private piggyBank;

    uint256 internal _season;

    //#### Access #####//
    mapping(address => bool) private signers;

    //#### Incarnation ######//
    uint256 internal idx;
    mapping(address => uint256) internal rounds;
    mapping(uint256 => LifeDetail) internal details;
    BitMapsUpgradeable.BitMap internal _seeds;
    // season => user address => count
    mapping(uint256 => mapping(address => uint256)) internal _incarnateCounts;
    // max incarnation count
    uint256 internal _incarnateCountLimit;

    //##### Tribute ###### //
    mapping(uint256 => SeasonData) internal _seasonData;

    //#### Refer #######//
    mapping(address => address) internal referrals;
    PortalLib.ReferrerRewardFees internal rewardFees;

    //#### airdrop config #####//
    AirdropConf internal _dropConf;
    VrfConf private _vrfConf;
    // requestId => request status
    mapping(uint256 => RequestStatus) internal _vrfRequests;
    uint256[3] private _placeholder2;

    //########### NFT ############//
    // tokenId => character property
    mapping(uint256 => PortalLib.CharacterProperty)
        internal _characterProperties;
    // tokenId => token amount required
    mapping(uint256 => uint256) internal _forgeRequiredMaterials;

    //######### Piggy Bank #########//
    // X% to piggyBank piggyBankFee / 10000
    uint256 internal piggyBankFee;

    // airdrop vault
    AirdropVault public airdropVault;

    mapping(address => AirDropDebt) internal _airdropDebt;

    bytes32 internal _dropNativeRoot;
    bytes32 internal _dropDegenRoot;

    Registry public _registry;
    uint96 internal _placeholder;

    // tokenId => exhumed count
    mapping(uint256 => uint256) internal _exhumeCount;

    mapping(address => mapping(RewardToClaimType => RewardStore))
        internal _rewardToClaim;

    /// @dev gap for potential variable
    uint256[20] private _gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {PortalLib} from "src/PortalLib.sol";
import {BitMapsUpgradeable} from "../oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

interface IRebornDefination {
    struct InnateParams {
        uint256 talentNativePrice;
        uint256 talentDegenPrice;
        uint256 propertyNativePrice;
        uint256 propertyDegenPrice;
    }

    struct SoupParams {
        uint256 soupPrice;
        uint256 charTokenId;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct ExhumeParams {
        address exhumee;
        uint256 tokenId;
        uint256 nativeCost;
        uint256 degenCost;
        uint256 shovelTokenId; // if no shovel, tokenId is 0
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct PermitParams {
        uint256 amount;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct LifeDetail {
        bytes32 seed;
        address creator; // ---
        // uint96 max 7*10^28  7*10^10 eth  //   |
        uint96 reward; // ---
        uint96 rebornCost; // ---
        uint16 age; //   |
        uint32 round; //   |
        // uint64 max 1.8*10^19             //   |
        uint64 score; //   |
        uint48 nativeCost; // only with dicimal of 10^6 // ---
        string creatorName;
    }

    struct SeasonData {
        mapping(uint256 => PortalLib.Pool) pools;
        /// @dev user address => pool tokenId => Portfolio
        mapping(address => mapping(uint256 => PortalLib.Portfolio)) portfolios;
        uint256 _placeholder;
        uint256 _placeholder2;
        uint256 _placeholder3;
        uint256 _placeholder4;
        uint256 _placeholder5;
        uint256 _jackpot;
    }

    struct AirDropDebt {
        uint128 nativeDebt;
        uint128 degenDebt;
    }

    event AirdropNative();
    event AirdropDegen();

    event Exhume(
        address indexed exhumer,
        address exhumee,
        uint256 indexed tokenId,
        uint256 indexed shovelTokenId,
        uint256 nonce,
        uint256 nativeCost,
        uint256 degenCost,
        uint256 nativeToJackpot
    );

    enum AirdropVrfType {
        Invalid,
        DropReborn,
        DropNative
    }

    enum TributeDirection {
        Reverse,
        Forward
    }

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        bool executed; // whether the airdrop is executed
        AirdropVrfType t;
        uint256 randomWords; // we only need one random word. keccak256 to generate more
    }

    struct VrfConf {
        bytes32 keyHash;
        uint64 s_subscriptionId;
        uint32 callbackGasLimit;
        uint32 numWords;
        uint16 requestConfirmations;
    }

    struct AirdropConf {
        bool _dropOn; //                  ---
        bool _lockRequestDropReborn;
        bool _lockRequestDropNative;
        uint24 _rebornDropInterval; //        |
        uint24 _nativeDropInterval; //        |
        uint32 _rebornDropLastUpdate; //      |
        uint32 _nativeDropLastUpdate; //      |
        uint120 _placeholder;
    }

    struct EngraveParams {
        uint256 tokenId;
        bytes32 seed;
        uint256 reward;
        uint256 score;
        uint256 age;
        uint256 nativeCost;
        uint256 rebornCost;
        uint256 shovelAmount;
        uint256 charTokenId;
        uint256 recoveredAP;
        string creatorName;
    }

    // define degen reward is odd, native reward is even
    enum RewardToClaimType {
        Invalid,
        EngraveDegen, // 1
        ReferNative, // 2
        ReferDegen // 3
    }

    struct RewardStore {
        uint256 totalReward;
        uint256 rewardDebt;
    }

    event ClaimReward(
        address indexed user,
        RewardToClaimType indexed t,
        uint256 amount
    );

    event NewDropConf(AirdropConf conf);

    event NewVrfConf(VrfConf conf);

    event Refer(address referee, address referrer);

    event Incarnate(
        address indexed user,
        uint256 indexed tokenId,
        uint256 indexed charTokenId,
        uint256 talentNativePrice,
        uint256 talentRebornPrice,
        uint256 propertyNativePrice,
        uint256 propertyRebornPrice,
        uint256 soupPrice
    );

    event Engrave(
        bytes32 indexed seed,
        address indexed user,
        uint256 indexed tokenId,
        uint256 score,
        uint256 reward,
        uint256 shovelAmount,
        uint256 startTokenId,
        uint256 charTokenId,
        uint256 recoveredAP
    );

    event Infuse(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    );

    event Dry(address indexed user, uint256 indexed tokenId, uint256 amount);

    event Baptise(
        address indexed user,
        uint256 amount,
        uint256 indexed baptiseType
    );

    event NewSoupPrice(uint256 price);

    event SwitchPool(
        address indexed user,
        uint256 indexed fromTokenId,
        uint256 indexed toTokenId,
        uint256 fromAmount,
        uint256 restakeAmount,
        TributeDirection fromDirection,
        TributeDirection toDirection
    );

    event DecreaseFromPool(
        address indexed account,
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    );

    event IncreaseToPool(
        address indexed account,
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    );

    event Drop(uint256[] tokenIds);

    /// @dev event about the vault address is set
    event VaultSet(address rewardVault);

    event AirdropVaultSet(address airdropVault);

    event NewSeason(uint256);

    event NewIncarnationLimit(uint256 limit);

    event ForgedTo(
        uint256 indexed tokenId,
        uint256 newLevel,
        uint256 burnTokenAmount
    );

    event SetNewPiggyBank(address piggyBank);

    event SetNewPiggyBankFee(uint256 piggyBankFee);

    event ClaimNativeAirdrop(uint256 amount);
    event ClaimDegenAirdrop(uint256 amount);

    event NativeDropRootSet(bytes32, uint256);
    event DegenDropRootSet(bytes32, uint256);

    event CurseMultiplierSet(uint256);

    /// @dev revert when msg.value is insufficient
    error InsufficientAmount();

    /// @dev revert when some address var are set to zero
    error ZeroAddressSet();

    /// @dev revert when the random seed is duplicated
    error SameSeed();

    /// @dev revert if burnPool address not set when infuse
    error NotSetBurnPoolAddress();

    /// @dev revert when the drop is not on
    error DropOff();

    /// @dev revert when incarnation count exceed limit
    error IncarnationExceedLimit();

    error DirectionError();

    error DropLocked();

    error InvalidProof();

    error NoRemainingReward();

    error SeasonAlreadyStoped();
}

interface IRebornPortal is IRebornDefination {
    /**
     * @dev user buy the innate for the life
     * @param innate talent and property choice
     * @param referrer the referrer address
     */
    function incarnate(
        InnateParams calldata innate,
        address referrer,
        SoupParams calldata charParams
    ) external payable;

    function incarnate(
        InnateParams calldata innate,
        address referrer,
        SoupParams calldata charParams,
        PermitParams calldata permitParams
    ) external payable;

    function engrave(EngraveParams calldata engraveParams) external;

    /**
     * @dev reward for share the game
     * @param user user address
     * @param amount amount for reward
     */
    function baptise(
        address user,
        uint256 amount,
        uint256 baptiseType
    ) external;

    /**
     * @dev stake $REBORN on this tombstone
     * @param tokenId tokenId of the life to stake
     * @param amount stake amount, decimal 10^18
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) external;

    /**
     * @dev stake $REBORN with permit
     * @param tokenId tokenId of the life to stake
     * @param amount amount of $REBORN to stake
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection,
        PermitParams calldata permitParams
    ) external;

    function switchPool(
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount,
        TributeDirection fromDirection,
        TributeDirection toDirection
    ) external;

    function claimNativeDrops(
        uint256 totalAmount,
        bytes32[] calldata proof
    ) external;

    function claimDegenDrops(
        uint256 totalAmount,
        bytes32[] calldata proof
    ) external;

    /**
     * @dev switch to next season, call by owner
     */
    function toNextSeason() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ERC20CappedUpgradeable, ERC20Upgradeable} from "./oz/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import {SafeOwnableUpgradeable} from "./utils/SafeOwnableUpgradeable.sol";
import {UUPSUpgradeable} from "./oz/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC20PermitUpgradeable} from "./oz/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import {ERC20BurnableUpgradeable} from "./oz/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import {IRebornToken} from "src/interfaces/IRebornToken.sol";
import {RBTStorage} from "src/RBTStorage.sol";

contract RBT is
    ERC20PermitUpgradeable,
    ERC20CappedUpgradeable,
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    IRebornToken,
    RBTStorage,
    ERC20BurnableUpgradeable
{
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        address owner_
    ) public initializer {
        __ERC20_init_unchained(name_, symbol_);
        __ERC20Capped_init(cap_);
        __ERC20Permit_init(name_);
        __Ownable_init(owner_);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev allow minter to mint it
     */
    function mint(address to, uint256 amount) external override onlyMinter {
        _mint(to, amount);
    }

    /**
     * @dev update minters
     */
    function updateMinter(
        address[] calldata toAdd,
        address[] calldata toRemove
    ) external onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            minters[toAdd[i]] = true;
            emit MinterUpdate(toAdd[i], true);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete minters[toRemove[i]];
            emit MinterUpdate(toRemove[i], false);
        }
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20CappedUpgradeable, ERC20Upgradeable) {
        require(
            ERC20Upgradeable.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        ERC20Upgradeable._mint(account, amount);
    }

    modifier onlyMinter() {
        if (!minters[msg.sender]) {
            revert NotMinter();
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IRewardVault} from "src/interfaces/IRewardVault.sol";

contract RewardVault is IRewardVault, Ownable {
    using SafeERC20 for IERC20;

    address public immutable rebornToken;

    constructor(address owner_, address rebornToken_) {
        if (rebornToken_ == address(0)) revert ZeroAddressSet();
        _transferOwnership(owner_);
        rebornToken = rebornToken_;
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function reward(
        address to,
        uint256 amount
    ) external virtual override onlyOwner {
        IERC20(rebornToken).safeTransfer(to, amount);
    }

    /**
     * @notice withdraw token Emergency
     */
    function withdrawEmergency(address to) external virtual override onlyOwner {
        if (to == address(0)) revert ZeroAddressSet();
        IERC20(rebornToken).safeTransfer(
            to,
            IERC20(rebornToken).balanceOf(address(this))
        );
        emit WithdrawEmergency(
            rebornToken,
            IERC20(rebornToken).balanceOf(address(this))
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(
        BitMap storage bitmap,
        uint256 index
    ) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(BitMap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {RewardVault} from "src/RewardVault.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {ECDSAUpgradeable} from "src/oz/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {AirdropVault} from "src/AirdropVault.sol";
import {Registry} from "src/Registry.sol";

library PortalLib {
    uint256 public constant PERSHARE_BASE = 10e18;
    // percentage base of refer reward fees
    uint256 public constant PERCENTAGE_BASE = 10000;

    bytes32 public constant _SOUPPARAMS_TYPEHASH =
        keccak256(
            "AuthenticateSoupArg(address user,uint256 soupPrice,uint256 incarnateCounter,uint256 tokenId,uint256 deadline)"
        );

    bytes32 public constant _EXHUME_TYPEHASH =
        keccak256(
            "ExhumeArg(address exhumer,address exhumee,uint256 tokenId,uint256 nonce,uint256 nativeCost,uint256 degenCost,uint256 shovelTokenId,uint256 deadline)"
        );

    bytes32 public constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    uint256 public constant ONE_HUNDRED = 100;

    struct CharacterParams {
        uint256 maxAP;
        uint256 restoreTimePerAP;
        uint256 level;
    }

    // TODO: use more compact storage
    struct CharacterProperty {
        uint8 currentAP;
        uint8 maxAP;
        uint24 restoreTimePerAP; // Time Needed to Restore One Action Point
        uint32 lastTimeAPUpdate;
        uint8 level;
    }

    struct CurrentAPReturn {
        uint256 currentAP;
        uint256 lastAPUpdateTime;
    }

    enum RewardType {
        NativeToken,
        RebornToken
    }

    struct ReferrerRewardFees {
        uint16 incarnateRef1Fee;
        uint16 incarnateRef2Fee;
        uint16 vaultRef1Fee;
        uint16 vaultRef2Fee;
        uint192 _slotPlaceholder;
    }

    struct Pool {
        uint256 totalAmount;
        uint256 accRebornPerShare;
        uint256 accNativePerShare;
        uint128 droppedRebornTotal;
        uint128 droppedNativeTotal;
        uint256 coindayCumulant;
        uint32 coindayUpdateLastTime;
        uint112 totalForwardTribute;
        uint112 totalReverseTribute;
        uint32 lastDropNativeTime;
        uint32 lastDropRebornTime;
        uint128 validTVL;
        uint64 placeholder;
    }

    //
    // We do some fancy math here. Basically, any point in time, the amount
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (Amount * pool.accPerShare) - user.rewardDebt
    //
    // Whenever a user infuse or switchPool. Here's what happens:
    //   1. The pool's `accPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
    struct Portfolio {
        uint256 accumulativeAmount;
        uint128 rebornRewardDebt;
        uint128 nativeRewardDebt;
        /// @dev reward for holding the NFT when the NFT is selected
        uint128 pendingOwnerRebornReward;
        uint128 pendingOwnerNativeReward;
        uint256 coindayCumulant;
        uint32 coindayUpdateLastTime;
        uint112 totalForwardTribute;
        uint112 totalReverseTribute;
    }

    event SignerUpdate(address signer, bool valid);
    event ReferReward(
        address indexed user,
        address indexed ref1,
        uint256 amount1,
        address indexed ref2,
        uint256 amount2,
        RewardType rewardType
    );

    function _toLastHour(uint256 timestamp) public pure returns (uint256) {
        return timestamp - (timestamp % (1 hours));
    }

    /**
     * @dev returns referrer and referer reward
     * @return ref1  level1 of referrer. direct referrer
     * @return ref1Reward  level 1 referrer reward
     * @return ref2  level2 of referrer. referrer's referrer
     * @return ref2Reward  level 2 referrer reward
     */
    function _calculateReferReward(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        address account,
        uint256 amount,
        RewardType rewardType
    )
        public
        view
        returns (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        )
    {
        ref1 = referrals[account];
        ref2 = referrals[ref1];

        if (rewardType == RewardType.NativeToken) {
            ref1Reward = ref1 == address(0)
                ? 0
                : (amount * rewardFees.incarnateRef1Fee) / PERCENTAGE_BASE;
            ref2Reward = ref2 == address(0)
                ? 0
                : (amount * rewardFees.incarnateRef2Fee) / PERCENTAGE_BASE;
        }

        if (rewardType == RewardType.RebornToken) {
            ref1Reward = ref1 == address(0)
                ? 0
                : (amount * rewardFees.vaultRef1Fee) / PERCENTAGE_BASE;
            ref2Reward = ref2 == address(0)
                ? 0
                : (amount * rewardFees.vaultRef2Fee) / PERCENTAGE_BASE;
        }
    }

    /**
     * @dev send NativeToken to referrers
     */
    function _sendNativeRewardToRefs(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        mapping(address => mapping(IRebornDefination.RewardToClaimType => IRebornDefination.RewardStore))
            storage _rewardToClaim,
        address account,
        uint256 amount
    ) public returns (uint256 total) {
        (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        ) = _calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                RewardType.NativeToken
            );

        unchecked {
            _rewardToClaim[ref1][
                IRebornDefination.RewardToClaimType.ReferNative
            ].totalReward += ref1Reward;
            _rewardToClaim[ref2][
                IRebornDefination.RewardToClaimType.ReferNative
            ].totalReward += ref2Reward;
        }

        unchecked {
            total = ref1Reward + ref2Reward;
        }

        emit ReferReward(
            account,
            ref1,
            ref1Reward,
            ref2,
            ref2Reward,
            RewardType.NativeToken
        );
    }

    /**
     * @dev vault $REBORN token to referrers
     */
    function _rewardDegenRewardToRefs(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        mapping(address => mapping(IRebornDefination.RewardToClaimType => IRebornDefination.RewardStore))
            storage _rewardToClaim,
        address account,
        uint256 amount
    ) public {
        (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        ) = _calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                RewardType.RebornToken
            );

        unchecked {
            _rewardToClaim[ref1][IRebornDefination.RewardToClaimType.ReferDegen]
                .totalReward += ref1Reward;
            _rewardToClaim[ref2][IRebornDefination.RewardToClaimType.ReferDegen]
                .totalReward += ref2Reward;
        }

        emit ReferReward(
            account,
            ref1,
            ref1Reward,
            ref2,
            ref2Reward,
            RewardType.RebornToken
        );
    }

    function _calculateCurrentAP(
        CharacterProperty memory charProperty
    ) public view returns (CurrentAPReturn memory) {
        // if restoreTimePerAP is not set, no process
        if (charProperty.restoreTimePerAP == 0) {
            return
                CurrentAPReturn(
                    charProperty.currentAP,
                    charProperty.lastTimeAPUpdate
                );
        }

        uint256 calculatedRestoreAp = (block.timestamp -
            charProperty.lastTimeAPUpdate) / charProperty.restoreTimePerAP;

        uint256 calculatedCurrentAP = calculatedRestoreAp +
            charProperty.currentAP;

        uint256 lastAPUpdateTime = charProperty.lastTimeAPUpdate +
            calculatedRestoreAp *
            charProperty.restoreTimePerAP;

        uint256 currentAP;

        // min(calculatedCurrentAP, maxAp)
        if (calculatedCurrentAP <= charProperty.maxAP) {
            currentAP = calculatedCurrentAP;
        } else {
            currentAP = charProperty.maxAP;
        }

        return CurrentAPReturn(currentAP, lastAPUpdateTime);
    }

    function _comsumeAP(
        uint256 tokenId,
        mapping(uint256 => CharacterProperty) storage _characterProperties
    ) public {
        CharacterProperty storage charProperty = _characterProperties[tokenId];

        CurrentAPReturn memory car = _calculateCurrentAP(charProperty);

        // if current ap is max, recover starts from now
        if (car.currentAP == charProperty.maxAP) {
            charProperty.lastTimeAPUpdate = uint32(block.timestamp);
        } else {
            charProperty.lastTimeAPUpdate = uint32(car.lastAPUpdateTime);
        }

        // Reduce AP
        charProperty.currentAP = uint8(car.currentAP - 1);
    }

    function _useSoupParam(
        IRebornDefination.SoupParams calldata soupParams,
        uint256 nonce,
        mapping(uint256 => PortalLib.CharacterProperty)
            storage _characterProperties,
        address registry
    ) public {
        _checkSoupSig(soupParams, nonce, registry);

        if (soupParams.charTokenId != 0) {
            // use degen2009 nft character
            _comsumeAP(soupParams.charTokenId, _characterProperties);
        }
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _altarDomainSeparatorV4() public view returns (bytes32) {
        return
            _buildDomainSeparator(
                PortalLib._TYPE_HASH,
                keccak256("Altar"),
                keccak256("1")
            );
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _exhumeDomainSeparatorV4() public view returns (bytes32) {
        return
            _buildDomainSeparator(
                PortalLib._TYPE_HASH,
                keccak256("DegenPortal"),
                keccak256("1")
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _checkExhumeSig(
        IRebornDefination.ExhumeParams calldata exhumeParams,
        uint256 nonce,
        address registry
    ) public view {
        if (block.timestamp >= exhumeParams.deadline) {
            revert CommonError.SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PortalLib._EXHUME_TYPEHASH,
                msg.sender,
                exhumeParams.exhumee,
                exhumeParams.tokenId,
                nonce,
                exhumeParams.nativeCost,
                exhumeParams.degenCost,
                exhumeParams.shovelTokenId,
                exhumeParams.deadline
            )
        );

        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(
            _exhumeDomainSeparatorV4(),
            structHash
        );

        address signer = ECDSAUpgradeable.recover(
            hash,
            exhumeParams.v,
            exhumeParams.r,
            exhumeParams.s
        );

        if (!Registry(registry).checkIsSigner(signer)) {
            revert CommonError.NotSigner();
        }
    }

    function _checkSoupSig(
        IRebornDefination.SoupParams calldata soupParams,
        uint256 nonce,
        address registry
    ) public view {
        if (block.timestamp >= soupParams.deadline) {
            revert CommonError.SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PortalLib._SOUPPARAMS_TYPEHASH,
                msg.sender,
                soupParams.soupPrice,
                nonce,
                soupParams.charTokenId,
                soupParams.deadline
            )
        );

        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(
            _altarDomainSeparatorV4(),
            structHash
        );

        address signer = ECDSAUpgradeable.recover(
            hash,
            soupParams.v,
            soupParams.r,
            soupParams.s
        );

        if (!Registry(registry).checkIsSigner(signer)) {
            revert CommonError.NotSigner();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// A simple array that supports insert and removal.
// The values are assumed to be unique and the library is meant to be lightweight.
// So when calling insert or remove, the caller is responsible to know whether a value already exists in the array or not.
library FastArray {
    struct Data {
        mapping(uint256 => uint256) array;
        mapping(uint256 => uint256) indexMap;
        uint256 length;
    }

    /**
     * @notice please confirm no eq item exist before insert
     */
    function insert(Data storage _fastArray, uint256 _value) public {
        _fastArray.array[_fastArray.length] = _value;
        _fastArray.indexMap[_value] = _fastArray.length;
        _fastArray.length += 1;
    }

    /**
     * @dev remove item from array,but not keep rest item sort
     * @notice Please confirm array is not empty && item is exist && index not out of bounds
     */
    function remove(Data storage _fastArray, uint256 _value) public {
        uint256 index = _fastArray.indexMap[_value];

        uint256 oldIndex = _fastArray.length - 1;

        _fastArray.array[index] = _fastArray.array[oldIndex];
        delete _fastArray.indexMap[_value];
        delete _fastArray.array[oldIndex];

        _fastArray.length = oldIndex;
    }

    /**
     * @dev remove item and keep rest item in sort
     * @notice Please confirm array is not empty && item is exist && index not out of bounds
     */
    function removeKeepSort(Data storage _fastArray, uint256 _value) public {
        uint256 index = _fastArray.indexMap[_value];

        uint256 tempLastItem = _fastArray.array[_fastArray.length - 1];

        for (uint256 i = index; i < _fastArray.length - 1; i++) {
            _fastArray.indexMap[_fastArray.array[i + 1]] = i;
            _fastArray.array[i] = _fastArray.array[i + 1];
        }

        delete _fastArray.indexMap[tempLastItem];
        delete _fastArray.array[_fastArray.length - 1];
        _fastArray.length -= 1;
    }

    /**
     * @notice PLease confirm index is not out of bounds
     */
    function get(
        Data storage _fastArray,
        uint256 _index
    ) public view returns (uint256) {
        return _fastArray.array[_index];
    }

    function length(Data storage _fastArray) public view returns (uint256) {
        return _fastArray.length;
    }

    function contains(
        Data storage _fastArray,
        uint256 _value
    ) public view returns (bool) {
        return _fastArray.indexMap[_value] != 0;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IPiggyBankDefination {
    struct SeasonInfo {
        uint256 totalAmount;
        bytes32 stopedHash;
        address verifySigner; // Used for verification the next time stop is called
        uint32 startTime;
        bool stoped;
    }

    struct RoundInfo {
        uint256 totalAmount;
        uint256 target;
        uint32 currentIndex;
        uint32 startTime;
    }

    struct UserInfo {
        uint256 amount;
        uint256 claimedAmount;
    }

    event InitializeSeason(
        uint256 season,
        uint32 seasonStartTime,
        RoundInfo roundInfo
    );
    event SetNewMultiple(uint8 multiple);
    event SetMinTimeLong(uint64 minTimeLong);
    event Deposit(
        uint256 season,
        address account,
        uint256 roundIndex,
        uint256 amount,
        uint256 roundTotalAmount
    );
    event SeasonStoped(uint256 season, uint256 stopTime);
    event SignerUpdate(address indexed signer, bool valid);
    event SetStopedHash(
        uint256 season,
        bytes32 stopedHash,
        address verifySigner
    );
    event ClaimedReward(uint256 season, address account, uint256 amount);
    event SetNewCountDownTimeLong(uint32 countDownTimeLong);
    event SetIsClaimOpened(bool isClaimOpened);
    event SetNewRoundRewardPercentage(uint16 percentage);
    event RewardUserWhoChangeRound(
        address account,
        uint256 season,
        uint256 roundIndex,
        uint256 amount
    );

    error CallerNotPortal();
    error InvalidRoundInfo();
    error SeasonOver();
    error InvalidSeason();
    error AlreadyClaimed();
    error SeasonNotOver();
    error CountDownTimeLongNotSet();
    error CanNotClaim();
}

interface IPiggyBank is IPiggyBankDefination {
    function deposit(
        uint256 season,
        address account,
        uint256 income
    ) external payable;

    function setMultiple(uint8 multiple_) external;

    function setMinTimeLong(uint64 minTimeLong_) external;

    function checkIsSeasonEnd(uint256 season) external view returns (bool);

    function setSeasonStopedHash(
        uint256 season,
        bytes32 stopedHash,
        address verifySigner
    ) external;

    function stop(uint256 season) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {IRegistry} from "src/interfaces/IRegistry.sol";
import {DegenShovel} from "src/DegenShovel.sol";
import {RBT} from "src/RBT.sol";
import {RebornPortal} from "src/RebornPortal.sol";
import {PiggyBank} from "src/PiggyBank.sol";
import {CommonError} from "src/lib/CommonError.sol";

contract Registry is IRegistry, UUPSUpgradeable, SafeOwnableUpgradeable {
    event DegenSet(address degen);
    event PortalSet(address portal);
    event ShovelSet(address shovel);
    event PiggyBankSet(address piggyBank);

    mapping(address => bool) private _signers;
    RBT private _degen;
    RebornPortal private _portal;
    DegenShovel private _shovel;
    PiggyBank private _piggyBank;

    uint256[45] private __gap;

    function initialize(address owner_) public initializer {
        if (owner_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }
        __Ownable_init_unchained(owner_);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev update signers
     * @param toAdd list of to be added signer
     * @param toRemove list of to be removed signer
     */
    function updateSigners(
        address[] calldata toAdd,
        address[] calldata toRemove
    ) public onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            _signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], true);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete _signers[toRemove[i]];
            emit SignerUpdate(toRemove[i], false);
        }
    }

    function setDegen(RBT addr) public onlyOwner {
        _degen = addr;
        emit DegenSet(address(addr));
    }

    function setPortal(RebornPortal addr) public onlyOwner {
        _portal = addr;
        emit PortalSet(address(addr));
    }

    function setShovel(DegenShovel addr) public onlyOwner {
        _shovel = addr;
        emit ShovelSet(address(addr));
    }

    function setPiggyBank(PiggyBank addr) public onlyOwner {
        _piggyBank = addr;
        emit PiggyBankSet(address(addr));
    }

    function checkIsSigner(address addr) public view returns (bool) {
        return _signers[addr];
    }

    function getDegen() public view returns (RBT) {
        return _degen;
    }

    function getPortal() public view returns (RebornPortal) {
        return _portal;
    }

    function getShovel() public view returns (DegenShovel) {
        return _shovel;
    }

    function getPiggyBank() public view returns (PiggyBank) {
        return _piggyBank;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

library CommonError {
    error ZeroAddressSet();
    error InvalidParams();
    /// @dev revert when to caller is not signer
    error NotSigner();
    error NotPortal();
    error ExhumeeNotTombStoneOwner();
    error NotShovelOwner();
    error TombstoneNotEngraved();
    error SignatureExpired();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }
    error InvalidSignature();
    error InvalidSignatureLength();
    error InvalidSignatureSValue();

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert InvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert InvalidSignatureLength();
        } else if (error == RecoverError.InvalidSignatureS) {
            revert InvalidSignatureSValue();
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(
        bytes memory s
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    StringsUpgradeable.toString(s.length),
                    s
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IRewardVault {
    error ZeroAddressSet();
    
    function reward(address to, uint256 amount) external; // send reward

    function withdrawEmergency(address to) external;

    event WithdrawEmergency(address p12Token, uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// Thanks Yos Riady
// Refer to https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/OwnableUpgradeable.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract SafeOwnableUpgradeable is Initializable, ContextUpgradeable {
    error CallerNotOwner();
    error ZeroAddressOwnerSet();
    error CallerNotPendingOwner();
    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address owner_) internal onlyInitializing {
        __Ownable_init_unchained(owner_);
    }

    function __Ownable_init_unchained(
        address owner_
    ) internal onlyInitializing {
        _transferOwnership(owner_);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Return the address of the pending owner
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner() != _msgSender()) {
            revert CallerNotOwner();
        }
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * Note If direct is false, it will set an pending owner and the OwnerShipTransferring
     * only happens when the pending owner claim the ownership
     */
    function transferOwnership(
        address newOwner,
        bool direct
    ) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressOwnerSet();
        }
        if (direct) {
            _transferOwnership(newOwner);
        } else {
            _transferPendingOwnership(newOwner);
        }
    }

    /**
     * @dev pending owner call this function to claim ownership
     */
    function claimOwnership() public {
        if (msg.sender != _pendingOwner) {
            revert CallerNotPendingOwner();
        }

        _claimOwnership();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        // compatible with hardhat-deploy, maybe removed later
        assembly {
            sstore(_ADMIN_SLOT, newOwner)
        }

        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev set the pending owner address
     * Internal function without access restriction.
     */
    function _transferPendingOwnership(address newOwner) internal virtual {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _claimOwnership() internal virtual {
        address oldOwner = _owner;
        emit OwnershipTransferred(oldOwner, _pendingOwner);

        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IRegistry {
    event SignerUpdate(address signer, bool valid);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {Registry} from "src/Registry.sol";
import {CommonError} from "src/lib/CommonError.sol";

contract DegenShovel is
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    ERC721AUpgradeable
{
    event BaseURISet(string);

    Registry public registry;
    string private _baseURI_;

    uint256[48] private _gap;

    function initialize(
        string calldata name_,
        string calldata symbol_,
        address owner_, // upgrade owner
        address registry_
    ) public initializerERC721A initializer {
        if (owner_ == address(0) || registry_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }

        __ERC721A_init(name_, symbol_);
        __Ownable_init_unchained(owner_);

        registry = Registry(registry_);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function mint(
        address to,
        uint256 quantity
    ) external onlyPortal returns (uint256 startTokenId) {
        startTokenId = _nextTokenId();
        _mint(to, quantity);
    }

    function burn(uint256 tokenId) external onlyPortal {
        // burn directly and dismiss approve check as it's only called by portal
        _burn(tokenId);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseURI_ = uri;
        emit BaseURISet(uri);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(_baseURI_, _toString(tokenId), ".json"));
    }

    // tokenId start from 1
    function _startTokenId() internal view override returns (uint256) {
        return 1 + (block.chainid * 1e18);
    }

    function _checkSigner() internal view {
        if (!registry.checkIsSigner(msg.sender)) {
            revert CommonError.NotSigner();
        }
    }

    modifier onlySigner() {
        _checkSigner();
        _;
    }

    modifier onlyPortal() {
        if (msg.sender != address(registry.getPortal())) {
            revert CommonError.NotPortal();
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ERC721Upgradeable} from "./oz/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "./oz/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "./oz/contracts-upgradeable/security/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "./oz/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BitMapsUpgradeable} from "./oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {SafeOwnableUpgradeable} from "./utils/SafeOwnableUpgradeable.sol";
import {IRebornPortal} from "src/interfaces/IRebornPortal.sol";
import {IBurnPool} from "src/interfaces/IBurnPool.sol";
import {RebornPortalStorage} from "src/RebornPortalStorage.sol";
import {RBT} from "src/RBT.sol";
import {RewardVault} from "src/RewardVault.sol";
import {Renderer} from "src/lib/Renderer.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {PortalLib} from "src/PortalLib.sol";
import {IPiggyBank} from "./interfaces/IPiggyBank.sol";
import {PiggyBank} from "src/PiggyBank.sol";
import {AirdropVault} from "src/AirdropVault.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Registry} from "src/Registry.sol";
import {DegenShovel} from "src/DegenShovel.sol";

// for storage compatible
abstract contract StorageCompat is RebornPortalStorage {

}

contract RebornPortal is
    IRebornPortal,
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    RebornPortalStorage,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    StorageCompat,
    AutomationCompatible
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    /**
     * @dev initialize function
     * @param owner_ owner address
     * @param name_ ERC712 name
     * @param symbol_ ERC721 symbol
     */
    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        Registry registry_
    ) public initializer {
        if (owner_ == address(0) || address(registry_) == address(0)) {
            revert ZeroAddressSet();
        }
        _registry = registry_;
        __Ownable_init(owner_);
        __ERC721_init(name_, symbol_);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @inheritdoc IRebornPortal
     */
    function incarnate(
        InnateParams calldata innate,
        address referrer,
        SoupParams calldata soupParams
    )
        external
        payable
        override
        whenNotStoped
        nonReentrant
        checkIncarnationCount
    {
        _refer(referrer);
        _incarnate(innate, soupParams);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function incarnate(
        InnateParams calldata innate,
        address referrer,
        SoupParams calldata soupParams,
        PermitParams calldata permitParams
    )
        external
        payable
        override
        whenNotStoped
        nonReentrant
        checkIncarnationCount
    {
        _refer(referrer);
        _permit(permitParams);
        _incarnate(innate, soupParams);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function engrave(
        EngraveParams calldata engraveParams
    ) external override onlySigner {
        if (_seeds.get(uint256(engraveParams.seed))) {
            revert SameSeed();
        }
        _seeds.set(uint256(engraveParams.seed));

        address creator = details[engraveParams.tokenId].creator;

        details[engraveParams.tokenId] = LifeDetail(
            engraveParams.seed,
            creator,
            uint96(engraveParams.reward),
            uint96(engraveParams.rebornCost),
            uint16(engraveParams.age),
            uint16(++rounds[creator]),
            uint64(engraveParams.score),
            uint48(engraveParams.nativeCost / 10 ** 12),
            engraveParams.creatorName
        );

        uint256 startTokenId;
        // mint shovel
        if (engraveParams.shovelAmount > 0) {
            startTokenId = _registry.getShovel().mint(
                creator,
                engraveParams.shovelAmount
            );
        }

        // record reward for incarnation owner
        _rewardToClaim[creator][RewardToClaimType.EngraveDegen]
            .totalReward += engraveParams.reward;

        // record reward for referer
        _rewardDegenRewardToRefs(creator, engraveParams.reward);

        // recover AP
        _recoverAP(engraveParams.charTokenId, engraveParams.recoveredAP);

        emit Engrave(
            engraveParams.seed,
            creator,
            engraveParams.tokenId,
            engraveParams.score,
            engraveParams.reward,
            engraveParams.shovelAmount,
            startTokenId,
            engraveParams.charTokenId,
            engraveParams.recoveredAP
        );
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function baptise(
        address user,
        uint256 amount,
        uint256 baptiseType
    ) external override onlySigner {
        vault.reward(user, amount);

        emit Baptise(user, amount, baptiseType);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) external override whenNotStoped {
        _infuse(tokenId, amount, tributeDirection);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection,
        PermitParams calldata permitParams
    ) external override whenNotStoped {
        _permit(permitParams);
        _infuse(tokenId, amount, tributeDirection);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function switchPool(
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount,
        TributeDirection fromDirection,
        TributeDirection toDirection
    ) external override whenNotStoped {
        uint256 restakeAmount = (amount * 95) / 100;

        emit SwitchPool(
            msg.sender,
            fromTokenId,
            toTokenId,
            amount,
            restakeAmount,
            fromDirection,
            toDirection
        );
    }

    function exhume(
        ExhumeParams calldata exhumParams
    ) external payable whenNotPaused {
        _exhume(exhumParams);
    }

    function exhume(
        ExhumeParams calldata exhumParams,
        PermitParams calldata permitParams
    ) external payable whenNotPaused {
        _permit(permitParams);
        _exhume(exhumParams);
    }

    function claimReward(
        RewardToClaimType t
    ) external whenNotPaused nonReentrant {
        uint256 remainingAmount = _rewardToClaim[msg.sender][t].totalReward -
            _rewardToClaim[msg.sender][t].rewardDebt;

        if (remainingAmount == 0) {
            revert NoRemainingReward();
        }

        _rewardToClaim[msg.sender][t].rewardDebt = _rewardToClaim[msg.sender][t]
            .totalReward;

        // if t is even, native reward
        if (uint8(t) % 2 == 0) {
            payable(msg.sender).transfer(remainingAmount);
        } else {
            // t is odd, degen reward
            vault.reward(msg.sender, remainingAmount);
        }

        emit ClaimReward(msg.sender, t, remainingAmount);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function claimNativeDrops(
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) external override nonReentrant whenNotPaused {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, totalAmount)))
        );

        bool valid = MerkleProof.verify(merkleProof, _dropNativeRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }

        uint256 remainingNativeAmount = totalAmount -
            _airdropDebt[msg.sender].nativeDebt;

        if (remainingNativeAmount == 0) {
            revert NoRemainingReward();
        }

        _airdropDebt[msg.sender].nativeDebt = uint128(totalAmount);

        // transfer from portal directly, so the remaining native in airdrop vault will become a part of jackpot
        payable(msg.sender).transfer(remainingNativeAmount);

        emit ClaimNativeAirdrop(remainingNativeAmount);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function claimDegenDrops(
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) external override whenNotPaused {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, totalAmount)))
        );

        bool valid = MerkleProof.verify(merkleProof, _dropDegenRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }

        uint256 remainingDegenAmount = totalAmount -
            _airdropDebt[msg.sender].degenDebt;

        if (remainingDegenAmount == 0) {
            revert NoRemainingReward();
        }

        _airdropDebt[msg.sender].degenDebt = uint128(totalAmount);

        airdropVault.rewardDegen(msg.sender, remainingDegenAmount);

        emit ClaimDegenAirdrop(remainingDegenAmount);
    }

    /**
     * @dev Upkeep perform of chainlink automation
     */
    function performUpkeep(
        bytes calldata performData
    ) external override whenNotStoped {
        uint256 t = abi.decode(performData, (uint256));
        if (t == 1) {
            _fulfillDropDegen();
        } else if (t == 2) {
            _fulfillDropNative();
        }
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function toNextSeason() external onlyOwner {
        _getPiggyBank().stop(_season);

        unchecked {
            _season++;
        }

        // update piggyBank
        _getPiggyBank().initializeSeason(
            _season,
            uint32(block.timestamp),
            0.1 ether
        );

        // pause the contract
        _pause();

        emit NewSeason(_season);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function setCharProperty(
        uint256[] calldata tokenIds,
        PortalLib.CharacterParams[] calldata charParams
    ) external onlySigner {
        uint256 tokenIdLength = tokenIds.length;
        uint256 charParamsLength = charParams.length;
        if (tokenIdLength != charParamsLength) {
            revert CommonError.InvalidParams();
        }
        for (uint256 i = 0; i < tokenIdLength; ) {
            uint256 tokenId = tokenIds[i];
            PortalLib.CharacterParams memory charParam = charParams[i];
            PortalLib.CharacterProperty
                storage charProperty = _characterProperties[tokenId];

            charProperty.maxAP = uint8(charParam.maxAP);
            charProperty.restoreTimePerAP = uint24(charParam.restoreTimePerAP);

            // restore all AP immediately when upgrade
            charProperty.currentAP = uint8(charParam.maxAP);

            charProperty.level = uint8(charParam.level);

            unchecked {
                i++;
            }
        }
    }

    function setNativeDropRoot(
        bytes32 nativeDropRoot,
        uint256 timestamp
    ) external onlySigner {
        _dropNativeRoot = nativeDropRoot;

        // update last drop timestamp, no back to specfic hour, for frontend show
        _dropConf._nativeDropLastUpdate = uint32(block.timestamp);

        emit NativeDropRootSet(nativeDropRoot, timestamp);
    }

    function setDegenDropRoot(
        bytes32 degenDropRoot,
        uint256 timestamp
    ) external onlySigner {
        _dropDegenRoot = degenDropRoot;

        // update last drop timestamp, no back to specfic hour, for frontend show
        _dropConf._rebornDropLastUpdate = uint32(block.timestamp);
        emit DegenDropRootSet(degenDropRoot, timestamp);
    }

    function setDropConf(AirdropConf memory conf) external onlyOwner {
        _dropConf = conf;
        emit NewDropConf(conf);
    }

    /**
     * @notice mul 100 when set. eg: 8% -> 800 18%-> 1800
     * @dev set percentage of referrer reward
     * @param rewardType 0: incarnate reward 1: engrave reward
     */
    function setReferrerRewardFee(
        uint16 refL1Fee,
        uint16 refL2Fee,
        PortalLib.RewardType rewardType
    ) external onlyOwner {
        if (rewardType == PortalLib.RewardType.NativeToken) {
            rewardFees.incarnateRef1Fee = refL1Fee;
            rewardFees.incarnateRef2Fee = refL2Fee;
        } else if (rewardType == PortalLib.RewardType.RebornToken) {
            rewardFees.vaultRef1Fee = refL1Fee;
            rewardFees.vaultRef2Fee = refL2Fee;
        }
    }

    /**
     * @dev set vault
     * @param vault_ new vault address
     */
    function setVault(RewardVault vault_) external onlyOwner {
        vault = vault_;
        emit VaultSet(address(vault_));
    }

    function setRegistry(address r) external onlyOwner {
        _registry = Registry(r);
    }

    /**
     * @dev set airdrop vault
     * @param vault_ new airdrop vault address
     */
    function setAirdropVault(AirdropVault vault_) external onlyOwner {
        airdropVault = vault_;
        emit AirdropVaultSet(address(vault_));
    }

    /**
     * @dev set incarnation limit
     */
    function setIncarnationLimit(uint256 limit) external onlyOwner {
        _incarnateCountLimit = limit;
        emit NewIncarnationLimit(limit);
    }

    /**
     * @dev withdraw token from vault
     * @param to the address which owner withdraw token to
     */
    function withdrawVault(address to) external onlyOwner {
        vault.withdrawEmergency(to);
    }

    /**
     * @dev withdraw token from airdrop vault
     * @param to the address which owner withdraw token to
     */
    function withdrawAirdropVault(address to) external onlyOwner {
        airdropVault.withdrawEmergency(to);
    }

    /**
     * @dev burn $REBORN from burn pool
     * @param amount burn from burn pool
     */
    function burnFromBurnPool(uint256 amount) external onlyOwner {
        IBurnPool(burnPool).burn(amount);
    }

    /**
     * @dev forging with permit
     */
    function forging(
        uint256 tokenId,
        uint256 toLevel,
        PermitParams calldata permitParams
    ) external {
        _permit(permitParams);
        _forging(tokenId, toLevel);
    }

    function forging(uint256 tokenId, uint256 toLevel) external {
        _forging(tokenId, toLevel);
    }

    function _forging(uint256 tokenId, uint256 toLevel) internal {
        uint256 currentLevel = _characterProperties[tokenId].level;
        if (currentLevel >= toLevel) {
            revert CommonError.InvalidParams();
        }
        uint256 requiredAmount;
        for (uint256 i = currentLevel; i < toLevel; ) {
            uint256 thisLevelAmount = _forgeRequiredMaterials[i];

            if (thisLevelAmount == 0) {
                revert CommonError.InvalidParams();
            }

            unchecked {
                requiredAmount += thisLevelAmount;
                i++;
            }
        }

        _getDegen().transferFrom(msg.sender, burnPool, requiredAmount);

        emit ForgedTo(tokenId, toLevel, requiredAmount);
    }

    function initializeSeason(uint256 target) external payable onlyOwner {
        _getPiggyBank().initializeSeason{value: msg.value}(
            0,
            uint32(block.timestamp),
            target
        );
    }

    function setForgingRequiredAmount(
        uint256[] memory levels,
        uint256[] memory amounts
    ) external onlyOwner {
        uint256 levelsLength = levels.length;
        uint256 amountsLength = amounts.length;

        if (levelsLength != amountsLength) {
            revert CommonError.InvalidParams();
        }

        for (uint256 i = 0; i < levelsLength; ) {
            _forgeRequiredMaterials[levels[i]] = amounts[i];
            unchecked {
                i++;
            }
        }
    }

    // set burnPool address for pre burn $REBORN
    function setBurnPool(address burnPool_) external onlyOwner {
        if (burnPool_ == address(0)) {
            revert ZeroAddressSet();
        }
        burnPool = burnPool_;
    }

    function setPiggyBankFee(uint256 piggyBankFee_) external onlyOwner {
        piggyBankFee = piggyBankFee_;

        emit SetNewPiggyBankFee(piggyBankFee_);
    }

    /**
     * @dev withdraw native token for reward distribution
     * @dev amount how much to withdraw
     */
    function withdrawNativeToken(
        address to,
        uint256 amount
    ) external whenPaused onlyOwner {
        payable(to).transfer(amount);
    }

    /**
     * @dev checkUpkeep for chainlink automation
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (_dropConf._dropOn) {
            // first, check whether airdrop is ready and send vrf request
            if (_checkCanDropDegen()) {
                upkeepNeeded = true;
                performData = abi.encode(1);
                return (upkeepNeeded, performData);
            } else if (_checkCanDropNative()) {
                upkeepNeeded = true;
                performData = abi.encode(2);
                return (upkeepNeeded, performData);
            }
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return Renderer.renderByTokenId(details, tokenId);
    }

    /**
     * @dev run erc20 permit to approve
     */
    function _permit(PermitParams calldata permitParams) internal {
        _getDegen().permit(
            msg.sender,
            address(this),
            permitParams.amount,
            permitParams.deadline,
            permitParams.v,
            permitParams.r,
            permitParams.s
        );
    }

    function _infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) internal {
        // it's not necessary to check the whether the address of burnPool is zero
        // as function tranferFrom does not allow transfer to zero address by default
        _getDegen().transferFrom(msg.sender, burnPool, amount);

        emit Infuse(msg.sender, tokenId, amount, tributeDirection);
    }

    /**
     * @dev record referrer relationship
     */
    function _refer(address referrer) internal {
        if (
            referrals[msg.sender] == address(0) &&
            referrer != address(0) &&
            referrer != msg.sender
        ) {
            referrals[msg.sender] = referrer;
            emit Refer(msg.sender, referrer);
        }
    }

    /**
     * @dev implementation of incarnate
     */
    function _incarnate(
        InnateParams calldata innate,
        SoupParams calldata soupParams
    ) internal {
        // use soup
        PortalLib._useSoupParam(
            soupParams,
            getIncarnateCount(_season, msg.sender),
            _characterProperties,
            address(_registry)
        );

        uint256 nativeFee = soupParams.soupPrice +
            innate.talentNativePrice +
            innate.propertyNativePrice;

        uint256 degenFee = innate.talentDegenPrice + innate.propertyDegenPrice;

        if (msg.value < nativeFee) {
            revert InsufficientAmount();
        }

        unchecked {
            // transfer redundant native token back
            payable(msg.sender).transfer(msg.value - nativeFee);
        }

        // reward referrers
        uint256 referNativeAmount = PortalLib._sendNativeRewardToRefs(
            referrals,
            rewardFees,
            _rewardToClaim,
            msg.sender,
            nativeFee
        );

        uint256 netNativeAmount;
        unchecked {
            netNativeAmount = nativeFee - referNativeAmount;
        }

        uint256 piggyBankAmount = (netNativeAmount * piggyBankFee) /
            PortalLib.PERCENTAGE_BASE;

        // more check
        // piggy bank amount should be less than net native amount
        if (piggyBankAmount > netNativeAmount) {
            revert CommonError.InvalidParams();
        }

        // x% to piggyBank
        _getPiggyBank().deposit{value: piggyBankAmount}(
            _season,
            msg.sender,
            nativeFee
        );

        _getDegen().transferFrom(msg.sender, burnPool, degenFee);

        // mint erc721
        uint256 tokenId;
        unchecked {
            // tokenId auto increment
            tokenId = ++idx + (block.chainid * 1e18);
        }
        _safeMint(msg.sender, tokenId);
        // set creator
        details[tokenId].creator = msg.sender;

        emit Incarnate(
            msg.sender,
            tokenId,
            soupParams.charTokenId,
            innate.talentNativePrice,
            innate.talentDegenPrice,
            innate.propertyNativePrice,
            innate.propertyDegenPrice,
            soupParams.soupPrice
        );
    }

    function _exhume(ExhumeParams calldata exhumParams) internal nonReentrant {
        uint256 nativeCost = exhumParams.nativeCost;
        uint256 degenCost = exhumParams.degenCost;
        address exhumee = exhumParams.exhumee;
        uint256 tombstoneTokenId = exhumParams.tokenId;
        address creator = details[tombstoneTokenId].creator;

        if (details[tombstoneTokenId].score == 0) {
            revert CommonError.TombstoneNotEngraved();
        }

        uint256 currentCount;
        unchecked {
            currentCount = ++_exhumeCount[tombstoneTokenId];
        }

        // check signature and param
        PortalLib._checkExhumeSig(
            exhumParams,
            currentCount,
            address(_registry)
        );

        // check tombstone tokenId owner
        if (ownerOf(tombstoneTokenId) != exhumee) {
            revert CommonError.ExhumeeNotTombStoneOwner();
        }

        // check shovel and burn
        if (exhumParams.shovelTokenId != 0) {
            if (_getShovel().ownerOf(exhumParams.shovelTokenId) != msg.sender) {
                revert CommonError.NotShovelOwner();
            }
            _getShovel().burn(exhumParams.shovelTokenId);
        }

        // check native token
        // minus directly as if msg.value is not enough, it will overflow
        uint256 extraAmount = msg.value - nativeCost;
        payable(msg.sender).transfer(extraAmount);

        // distribute native and degen token
        if (currentCount == 1) {
            // 80% native to last owner
            payable(exhumee).transfer((nativeCost * 80) / 100);
            // 10%  to creator
            payable(exhumee).transfer((nativeCost * 10) / 100);
        } else {
            // 85% native to last owner
            payable(exhumee).transfer((nativeCost * 85) / 100);
            // 5% native to creator
            payable(creator).transfer((nativeCost * 5) / 100);
        }

        // 70% degen burn
        _getDegen().transferFrom(msg.sender, burnPool, (degenCost * 70) / 100);

        // 25% degen to last owner
        _getDegen().transferFrom(msg.sender, exhumee, (degenCost * 25) / 100);

        // 5% degen to creator
        _getDegen().transferFrom(msg.sender, creator, (degenCost * 5) / 100);

        // transfer nft ownership
        // it will check old ownership again
        _transfer(exhumee, msg.sender, tombstoneTokenId);

        // emit event
        emit Exhume(
            msg.sender,
            exhumee,
            tombstoneTokenId,
            exhumParams.shovelTokenId,
            currentCount,
            nativeCost,
            degenCost,
            (nativeCost * 1) / 10
        );
    }

    function _recoverAP(uint256 charTokenId, uint256 recoveredAP) internal {
        // recover char AP
        if (charTokenId != 0) {
            uint256 increasedAP = _characterProperties[charTokenId].currentAP +
                recoveredAP;
            if (increasedAP > _characterProperties[charTokenId].maxAP) {
                _characterProperties[charTokenId]
                    .currentAP = _characterProperties[charTokenId].maxAP;
            } else {
                _characterProperties[charTokenId].currentAP = uint8(
                    increasedAP
                );
            }
        }
    }

    function _rewardDegenRewardToRefs(
        address creator,
        uint256 reward
    ) internal {
        // record reward for referer
        PortalLib._rewardDegenRewardToRefs(
            referrals,
            rewardFees,
            _rewardToClaim,
            creator,
            reward
        );
    }

    /**
     * @dev airdrop to top 50 tvl pool
     * @dev directly drop to top 10
     * @dev raffle 10 from top 11 - top 50
     */
    function _fulfillDropDegen() internal onlyDropOn {
        if (!_checkCanDropDegen()) {
            revert CommonError.InvalidParams();
        }

        emit AirdropDegen();
    }

    /**
     * @dev airdrop to top 100 tvl pool
     * @dev directly drop to top 10
     * @dev raffle 10 from top 11 - top 50
     */
    function _fulfillDropNative() internal onlyDropOn {
        if (!_checkCanDropNative()) {
            revert CommonError.InvalidParams();
        }

        emit AirdropNative();
    }

    /**
     * @dev returns referrer and referer reward
     * @return ref1 level1 of referrer. direct referrer
     * @return ref1Reward level 1 referrer reward
     * @return ref2 level2 of referrer. referrer's referrer
     * @return ref2Reward level 2 referrer reward
     */
    function calculateReferReward(
        address account,
        uint256 amount,
        PortalLib.RewardType rewardType
    )
        public
        view
        returns (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        )
    {
        return
            PortalLib._calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                rewardType
            );
    }

    function getIncarnateCount(
        uint256 season,
        address user
    ) public view returns (uint256) {
        return _incarnateCounts[season][user];
    }

    function getIncarnateLimit() public view returns (uint256) {
        return _incarnateCountLimit;
    }

    function getDropConf() public view returns (AirdropConf memory) {
        return _dropConf;
    }

    /**
     * A -> B -> C: B: level1 A: level2
     * @dev referrer1: level1 of referrers referrer2: level2 of referrers
     */
    function getReferrers(
        address account
    ) public view returns (address referrer1, address referrer2) {
        referrer1 = referrals[account];
        referrer2 = referrals[referrer1];
    }

    function getAirdropDebt(
        address user
    ) public view returns (AirDropDebt memory) {
        return _airdropDebt[user];
    }

    function getRewardToClaim(
        address user,
        RewardToClaimType t
    ) public view returns (RewardStore memory) {
        return _rewardToClaim[user][t];
    }

    function readCharProperty(
        uint256 tokenId
    ) public view returns (PortalLib.CharacterProperty memory) {
        PortalLib.CharacterProperty memory charProperty = _characterProperties[
            tokenId
        ];

        PortalLib.CurrentAPReturn memory car = PortalLib._calculateCurrentAP(
            charProperty
        );

        charProperty.currentAP = uint8(car.currentAP);

        charProperty.lastTimeAPUpdate = uint32(car.lastAPUpdateTime);

        return charProperty;
    }

    function _checkDropOn() internal view {
        if (!_dropConf._dropOn) {
            revert DropOff();
        }
    }

    function _checkIncarnationCount() internal {
        uint256 currentIncarnateCount = getIncarnateCount(_season, msg.sender);
        if (currentIncarnateCount >= _incarnateCountLimit) {
            revert IncarnationExceedLimit();
        }

        unchecked {
            _incarnateCounts[_season][msg.sender] = ++currentIncarnateCount;
        }
    }

    /**
     * @dev check signer implementation
     */
    function _checkSigner() internal view {
        if (!_registry.checkIsSigner(msg.sender)) {
            revert CommonError.NotSigner();
        }
    }

    function _checkStoped() internal view {
        if (_getPiggyBank().checkIsSeasonEnd(_season)) {
            revert SeasonAlreadyStoped();
        }

        if (paused()) {
            revert PausablePaused();
        }
    }

    function _getPiggyBank() internal view returns (PiggyBank) {
        return _registry.getPiggyBank();
    }

    function _getDegen() internal view returns (RBT) {
        return _registry.getDegen();
    }

    function _getShovel() internal view returns (DegenShovel) {
        return _registry.getShovel();
    }

    function _checkCanDropDegen() internal view returns (bool) {
        unchecked {
            return
                block.timestamp >
                PortalLib._toLastHour(_dropConf._rebornDropLastUpdate) +
                    _dropConf._rebornDropInterval &&
                !_dropConf._lockRequestDropReborn;
        }
    }

    function _checkCanDropNative() internal view returns (bool) {
        unchecked {
            return
                block.timestamp >
                PortalLib._toLastHour(_dropConf._nativeDropLastUpdate) +
                    _dropConf._nativeDropInterval &&
                !_dropConf._lockRequestDropNative;
        }
    }

    modifier onlySigner() {
        _checkSigner();
        _;
    }

    /**
     * @dev check incarnation Count and auto increment if it meets
     */
    modifier checkIncarnationCount() {
        _checkIncarnationCount();
        _;
    }

    /**
     * @dev only allowed when drop is on
     */
    modifier onlyDropOn() {
        _checkDropOn();
        _;
    }

    modifier whenNotStoped() {
        _checkStoped();
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "./oz/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ECDSAUpgradeable} from "./oz/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {SafeOwnableUpgradeable} from "./utils/SafeOwnableUpgradeable.sol";
import {CommonError} from "./lib/CommonError.sol";
import {IPiggyBank} from "./interfaces/IPiggyBank.sol";
import {PiggyBankStorage} from "./PiggyBankStorage.sol";
import {ReentrancyGuardUpgradeable} from "./oz/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract PiggyBank is
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    IPiggyBank,
    PiggyBankStorage,
    ReentrancyGuardUpgradeable
{
    function initialize(address owner_, address portal_) public initializer {
        if (portal_ == address(0) || owner_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }

        __Ownable_init(owner_);

        portal = portal_;
    }

    function initializeSeason(
        uint256 season,
        uint32 seasonStartTime,
        uint256 initRoundTarget
    ) external payable onlyPortal {
        RoundInfo memory roundInfo = RoundInfo({
            totalAmount: 0,
            target: initRoundTarget,
            currentIndex: 0,
            startTime: seasonStartTime
        });

        seasons[season].totalAmount = msg.value;
        seasons[season].startTime = seasonStartTime;
        rounds[season] = roundInfo;

        emit InitializeSeason(season, seasonStartTime, roundInfo);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function deposit(
        uint256 season,
        address account,
        uint256 income
    ) external payable override onlyPortal {
        if (countDownTimeLong == 0) {
            revert CountDownTimeLongNotSet();
        }

        bool isEnd = checkIsSeasonEnd(season);
        if (isEnd) {
            if (!seasons[season].stoped) {
                seasons[season].stoped = true;
            }
            revert SeasonOver();
        }

        seasons[season].totalAmount += msg.value;

        // update round info
        RoundInfo storage roundInfo = rounds[season];
        if (roundInfo.totalAmount + income > roundInfo.target) {
            uint256 newRoundInitAmount = income -
                (roundInfo.target - roundInfo.totalAmount);

            uint256 remainingAmount = roundInfo.target - roundInfo.totalAmount;
            roundInfo.totalAmount = roundInfo.target;
            users[account][season][roundInfo.currentIndex]
                .amount += remainingAmount;

            emit Deposit(
                season,
                account,
                roundInfo.currentIndex,
                remainingAmount,
                roundInfo.totalAmount
            );

            // reward 8% to
            _rewardUserWhoChangeRound(account, season, roundInfo);

            _toNextRound(account, season, newRoundInitAmount);
        } else {
            roundInfo.totalAmount += income;
            users[account][season][roundInfo.currentIndex].amount += income;

            emit Deposit(
                season,
                account,
                roundInfo.currentIndex,
                income,
                roundInfo.totalAmount
            );
        }
    }

    function stop(uint256 season) external override onlyPortal {
        if (seasons[season].startTime == 0) {
            revert InvalidSeason();
        }
        seasons[season].stoped = true;

        emit SeasonStoped(season, block.timestamp);
    }

    function claimReward(uint256 season) external {
        if (!checkIsSeasonEnd(season)) {
            revert SeasonNotOver();
        }

        if (!isClaimOpened) {
            revert CanNotClaim();
        }

        SeasonInfo memory seasonInfo = seasons[season];
        RoundInfo memory roundInfo = rounds[season];
        UserInfo storage userInfo = users[msg.sender][season][
            roundInfo.currentIndex
        ];

        if (userInfo.claimedAmount > 0) {
            revert AlreadyClaimed();
        }

        uint256 userReward = (seasonInfo.totalAmount * userInfo.amount) /
            roundInfo.totalAmount;

        userInfo.claimedAmount = userReward;

        payable(msg.sender).transfer(userReward);

        emit ClaimedReward(season, msg.sender, userReward);
    }

    function _rewardUserWhoChangeRound(
        address account,
        uint256 season,
        RoundInfo memory roundInfo
    ) internal nonReentrant {
        uint256 reward = (roundInfo.target * newRoundRewardPercentage) /
            PERCENTAGE_BASE;
        seasons[season].totalAmount -= reward;
        payable(account).transfer(reward);

        emit RewardUserWhoChangeRound(
            account,
            season,
            roundInfo.currentIndex,
            reward
        );
    }

    function setMultiple(uint8 multiple_) external override onlyOwner {
        multiple = multiple_;

        emit SetNewMultiple(multiple_);
    }

    function setMinTimeLong(uint64 minTimeLong_) external override onlyOwner {
        minTimeLong = minTimeLong_;

        emit SetMinTimeLong(minTimeLong_);
    }

    function setCoundDownTimeLong(
        uint32 countDownTimeLong_
    ) external onlyOwner {
        countDownTimeLong = countDownTimeLong_;

        emit SetNewCountDownTimeLong(countDownTimeLong_);
    }

    function setSeasonStopedHash(
        uint256 season,
        bytes32 stopedHash,
        address verifySigner
    ) external override onlyOwner {
        if (seasons[season].startTime == 0) {
            revert InvalidSeason();
        }
        if (verifySigner == address(0)) {
            revert CommonError.ZeroAddressSet();
        }

        seasons[season].stopedHash = stopedHash;
        seasons[season].verifySigner = verifySigner;

        emit SetStopedHash(season, stopedHash, verifySigner);
    }

    function setIsClaimOpened(bool isClaimOpened_) external onlyOwner {
        isClaimOpened = isClaimOpened_;

        emit SetIsClaimOpened(isClaimOpened);
    }

    function setNewRoundPercentage(uint16 percentage) external onlyOwner {
        newRoundRewardPercentage = percentage;

        emit SetNewRoundRewardPercentage(percentage);
    }

    function _toNextRound(
        address account,
        uint256 season,
        uint256 nextRoundInitAmount
    ) internal {
        // update rounds
        RoundInfo storage roundInfo = rounds[season];
        roundInfo.currentIndex++;
        roundInfo.startTime = uint32(block.timestamp);
        roundInfo.target += (roundInfo.target * multiple) / PERCENTAGE_BASE;

        if (nextRoundInitAmount > roundInfo.target) {
            roundInfo.totalAmount = roundInfo.target;
            // update userInfo
            users[account][season][roundInfo.currentIndex].amount = roundInfo
                .target;

            emit Deposit(
                season,
                account,
                roundInfo.currentIndex,
                roundInfo.target,
                roundInfo.totalAmount
            );

            // reward the user who change round to next round
            _rewardUserWhoChangeRound(account, season, roundInfo);

            _toNextRound(
                account,
                season,
                nextRoundInitAmount - roundInfo.target
            );
        } else {
            roundInfo.totalAmount = nextRoundInitAmount;

            users[account][season][roundInfo.currentIndex]
                .amount = nextRoundInitAmount;

            emit Deposit(
                season,
                account,
                roundInfo.currentIndex,
                nextRoundInitAmount,
                nextRoundInitAmount
            );
        }
    }

    function checkIsSeasonEnd(uint256 season) public view returns (bool) {
        bool isEnd = false;

        bool isAutoEnd = ((block.timestamp >
            seasons[season].startTime + minTimeLong) &&
            (rounds[season].totalAmount < rounds[season].target) &&
            (block.timestamp - rounds[season].startTime) >= countDownTimeLong);

        if (isAutoEnd || seasons[season].stoped) {
            isEnd = true;
        }
        return isEnd;
    }

    function getSeasonInfo(
        uint256 season
    ) external view returns (SeasonInfo memory seasonInfo, bool isSeasonEnd) {
        seasonInfo = seasons[season];
        isSeasonEnd = checkIsSeasonEnd(season);
    }

    function getRoundInfo(
        uint256 season
    ) external view returns (RoundInfo memory) {
        return rounds[season];
    }

    function getUserInfo(
        address account,
        uint256 season,
        uint256 roundIndex
    ) external view returns (UserInfo memory) {
        return users[account][season][roundIndex];
    }

    function verifyStopHash(
        uint256 season,
        bytes calldata signature
    ) public view returns (bool) {
        bytes32 messageHash = ECDSAUpgradeable.toEthSignedMessageHash(
            seasons[season].stopedHash
        );
        address signer = ECDSAUpgradeable.recover(messageHash, signature);
        return signer == seasons[season].verifySigner;
    }

    modifier onlyPortal() {
        if (msg.sender != portal) {
            revert CallerNotPortal();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
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
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AUpgradeable.sol';
import {ERC721AStorage} from './ERC721AStorage.sol';
import './ERC721A__Initializable.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721ReceiverUpgradeable {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AUpgradeable is ERC721A__Initializable, IERC721AUpgradeable {
    using ERC721AStorage for ERC721AStorage.Layout;

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        ERC721AStorage.layout()._name = name_;
        ERC721AStorage.layout()._symbol = symbol_;
        ERC721AStorage.layout()._currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return ERC721AStorage.layout()._currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - ERC721AStorage.layout()._burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return ERC721AStorage.layout()._burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return ERC721AStorage.layout()._packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = ERC721AStorage.layout()._packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        ERC721AStorage.layout()._packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(ERC721AStorage.layout()._packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (ERC721AStorage.layout()._packedOwnerships[index] == 0) {
            ERC721AStorage.layout()._packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256 packed) {
        if (_startTokenId() <= tokenId) {
            packed = ERC721AStorage.layout()._packedOwnerships[tokenId];
            // If not burned.
            if (packed & _BITMASK_BURNED == 0) {
                // If the data at the starting slot does not exist, start the scan.
                if (packed == 0) {
                    if (tokenId >= ERC721AStorage.layout()._currentIndex) revert OwnerQueryForNonexistentToken();
                    // Invariant:
                    // There will always be an initialized ownership slot
                    // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                    // before an unintialized ownership slot
                    // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                    // Hence, `tokenId` will not underflow.
                    //
                    // We can directly compare the packed value.
                    // If the address is zero, packed will be zero.
                    for (;;) {
                        unchecked {
                            packed = ERC721AStorage.layout()._packedOwnerships[--tokenId];
                        }
                        if (packed == 0) continue;
                        return packed;
                    }
                }
                // Otherwise, the data exists and is not burned. We can skip the scan.
                // This is possible because we have already achieved the target condition.
                // This saves 2143 gas on transfers of initialized tokens.
                return packed;
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        _approve(to, tokenId, true);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return ERC721AStorage.layout()._tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        ERC721AStorage.layout()._operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return ERC721AStorage.layout()._operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < ERC721AStorage.layout()._currentIndex && // If within bounds,
            ERC721AStorage.layout()._packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        ERC721AStorage.TokenApprovalRef storage tokenApproval = ERC721AStorage.layout()._tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --ERC721AStorage.layout()._packedAddressData[from]; // Updates: `balance -= 1`.
            ++ERC721AStorage.layout()._packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data)
        returns (bytes4 retval) {
            return retval == ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            ERC721AStorage.layout()._currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            ERC721AStorage.layout()._currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = ERC721AStorage.layout()._currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (ERC721AStorage.layout()._currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                       APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_approve(to, tokenId, false)`.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _approve(to, tokenId, false);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        bool approvalCheck
    ) internal virtual {
        address owner = ownerOf(tokenId);

        if (approvalCheck)
            if (_msgSenderERC721A() != owner)
                if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                    revert ApprovalCallerNotOwnerNorApproved();
                }

        ERC721AStorage.layout()._tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            ERC721AStorage.layout()._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            ERC721AStorage.layout()._burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = ERC721AStorage.layout()._packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        ERC721AStorage.layout()._packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC721AStorage {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // The next token ID to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned.
        // See {_packedOwnershipOf} implementation for details.
        //
        // Bits Layout:
        // - [0..159]   `addr`
        // - [160..223] `startTimestamp`
        // - [224]      `burned`
        // - [225]      `nextInitialized`
        // - [232..255] `extraData`
        mapping(uint256 => uint256) _packedOwnerships;
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    `balance`
        // - [64..127]  `numberMinted`
        // - [128..191] `numberBurned`
        // - [192..255] `aux`
        mapping(address => uint256) _packedAddressData;
        // Mapping from token ID to approved address.
        mapping(uint256 => ERC721AStorage.TokenApprovalRef) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.ERC721A');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable diamond facet contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */

import {ERC721A__InitializableStorage} from './ERC721A__InitializableStorage.sol';

abstract contract ERC721A__Initializable {
    using ERC721A__InitializableStorage for ERC721A__InitializableStorage.Layout;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializerERC721A() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            ERC721A__InitializableStorage.layout()._initializing
                ? _isConstructor()
                : !ERC721A__InitializableStorage.layout()._initialized,
            'ERC721A__Initializable: contract is already initialized'
        );

        bool isTopLevelCall = !ERC721A__InitializableStorage.layout()._initializing;
        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = true;
            ERC721A__InitializableStorage.layout()._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializingERC721A() {
        require(
            ERC721A__InitializableStorage.layout()._initializing,
            'ERC721A__Initializable: contract is not initializing'
        );
        _;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base storage for the  initialization function for upgradeable diamond facet contracts
 **/

library ERC721A__InitializableStorage {
    struct Layout {
        /*
         * Indicates that the contract has been initialized.
         */
        bool _initialized;
        /*
         * Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.initializable.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 *
 * @custom:storage-size 51
 */
abstract contract ERC20CappedUpgradeable is Initializable, ERC20Upgradeable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    function __ERC20Capped_init(uint256 cap_) internal onlyInitializing {
        __ERC20Capped_init_unchained(cap_);
    }

    function __ERC20Capped_init_unchained(
        uint256 cap_
    ) internal onlyInitializing {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(
            ERC20Upgradeable.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// Thanks Yos Riady
// Refer to https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/OwnableUpgradeable.sol

pragma solidity ^0.8.0;

import "../oz/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../oz/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract SafeOwnableUpgradeable is Initializable, ContextUpgradeable {
    error CallerNotOwner();
    error ZeroAddressOwnerSet();
    error CallerNotPendingOwner();
    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address owner_) internal onlyInitializing {
        __Ownable_init_unchained(owner_);
    }

    function __Ownable_init_unchained(
        address owner_
    ) internal onlyInitializing {
        _transferOwnership(owner_);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Return the address of the pending owner
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function _checkOwner() internal view {
        if (owner() != _msgSender()) {
            revert CallerNotOwner();
        }
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * Note If direct is false, it will set an pending owner and the OwnerShipTransferring
     * only happens when the pending owner claim the ownership
     */
    function transferOwnership(
        address newOwner,
        bool direct
    ) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressOwnerSet();
        }
        if (direct) {
            _transferOwnership(newOwner);
        } else {
            _transferPendingOwnership(newOwner);
        }
    }

    /**
     * @dev pending owner call this function to claim ownership
     */
    function claimOwnership() public {
        if (msg.sender != _pendingOwner) {
            revert CallerNotPendingOwner();
        }

        _claimOwnership();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        // compatible with hardhat-deploy, maybe removed later
        assembly {
            sstore(_ADMIN_SLOT, newOwner)
        }

        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev set the pending owner address
     * Internal function without access restriction.
     */
    function _transferPendingOwnership(address newOwner) internal virtual {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _claimOwnership() internal virtual {
        address oldOwner = _owner;
        emit OwnershipTransferred(oldOwner, _pendingOwner);

        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is
    Initializable,
    IERC1822ProxiableUpgradeable,
    ERC1967UpgradeUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        if (address(this) == __self) {
            revert MustBeCalledThroughDelegatecall();
        }
        if (_getImplementation() != __self) {
            revert MustBeCalledThroughActiveProxy();
        }
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        if (address(this) != __self) {
            revert MustBeCalledThroughDelegatecall();
        }
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/cryptography/EIP712Upgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is
    Initializable,
    ERC20Upgradeable,
    IERC20PermitUpgradeable,
    EIP712Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(
        string memory
    ) internal onlyInitializing {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(
        address owner
    ) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(
        address owner
    ) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
abstract contract ERC20BurnableUpgradeable is
    Initializable,
    ContextUpgradeable,
    ERC20Upgradeable
{
    function __ERC20Burnable_init() internal onlyInitializing {}

    function __ERC20Burnable_init_unchained() internal onlyInitializing {}

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IERC20Upgradeable} from "../oz/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20PermitUpgradeable} from "../oz/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

interface IRebornTokenDef {
    /// @dev revert when the caller is not minter
    error NotMinter();
    /// @dev emit when minter is updated
    event MinterUpdate(address minter, bool valid);
}

interface IRebornToken is
    IERC20Upgradeable,
    IERC20PermitUpgradeable,
    IRebornTokenDef
{
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

contract RBTStorage {
    mapping(address => bool) public minters;

    /// @dev gap for potential vairable
    uint256[49] private _gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
contract ERC20Upgradeable is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable
{
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
    function __ERC20_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
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
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
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
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < subtractedValue) {
            revert DecreasedAllowanceBelowZero();
        }
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
        if (from == address(0)) {
            revert TransferFromZeroAddress();
        }
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert TransferAmountExceedsBalance();
        }
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
        if (account == address(0)) {
            revert MintToZeroAddress();
        }

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
        if (account == address(0)) {
            revert BurnFromZeroAddress();
        }

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        if (accountBalance < amount) {
            revert BurnAmountExceedsBalance();
        }
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0)) {
            revert ApproveFromZeroAddress();
        }

        if (spender == address(0)) {
            revert ApproveToZeroAddress();
        }

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
            if (currentAllowance < amount) {
                revert InsufficientAllowance();
            }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";
import "../../ICustomError.sol";

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
abstract contract Initializable is ICustomError {
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
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
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
        if (_initializing || _initialized >= version) {
            revert ContractAlreadyInitialized();
        }
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
        if (!_initializing) {
            revert ContractIsNotInitializing();
        }
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
        if (_initializing) {
            revert ContractIsInitializing();
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    error InsufficientBalance();
    error UnableToSendValue();
    error CallToNoContract();

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
        if (address(this).balance < amount) {
            revert InsufficientBalance();
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert UnableToSendValue();
        }
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        if (address(this).balance < value) {
            revert InsufficientBalance();
        }
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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
                if (!isContract(target)) {
                    revert CallToNoContract();
                }
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

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
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

pragma solidity ^0.8.0;

interface ICustomError {
    /**********************************
     * Generic errors
     **********************************/
    error ZeroOwnerSet();

    /**********************************
     * Initializable
     **********************************/
    error ContractAlreadyInitialized();
    error ContractIsNotInitializing();
    error ContractIsInitializing();

    /**********************************
     * ReentrancyGuardUpgradeable
     **********************************/
    error ReentrantCall();

    /**********************************
     * PausableUpgradeable
     **********************************/
    error PausablePaused();
    error PausableNotPaused();

    /**********************************
     * UUPSUpgradeable
     **********************************/
    error MustBeCalledThroughDelegatecall();
    error MustBeCalledThroughActiveProxy();

    /**********************************
     * ERC1967UpgradeUpgradeable
     **********************************/
    error NewImplementationIsNotContract();
    error UnsupportedProxiableUUID();
    error NewImplementationIsNotUUPS();
    error NewAdminIsZeroAddress();
    error NewBeaconIsNotContract();
    error BeaconImplementationIsNotContract();
    error DelegateCallToNonContract();

    /**********************************
     * ERC721
     **********************************/
    error InvalidTokenID();
    error ApproveToCurrentOwner();
    error CallerNotTokenOwnerOrApproved();
    error TransferToNonERC721ReceiverImplementer();
    error MintToZeroAddress();
    error TokenAlreadyMinted();
    error TransferFromIncorrectOwner();
    error TransferToZeroAddress();
    error ApproveToCaller();

    /**********************************
     * ERC20Upgradeable
     **********************************/
    error DecreasedAllowanceBelowZero();
    error TransferFromZeroAddress();
    error TransferAmountExceedsBalance();
    error BurnFromZeroAddress();
    error BurnAmountExceedsBalance();
    error ApproveFromZeroAddress();
    error ApproveToZeroAddress();
    error InsufficientAllowance();

    /**********************************
     * SafeERC20Upgradeable
     **********************************/
    error ApproveFromNonZeroToNonZeroAllowance();
    error PermitDidNotSucceed();
    error ERC20OperationDidNotSucceed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (!AddressUpgradeable.isContract(newImplementation)) {
            revert NewImplementationIsNotContract();
        }
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                // require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
                if (slot != _IMPLEMENTATION_SLOT) {
                    revert UnsupportedProxiableUUID();
                }
            } catch {
                revert NewImplementationIsNotUUPS();
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert NewAdminIsZeroAddress();
        }
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (!AddressUpgradeable.isContract(newBeacon)) {
            revert NewBeaconIsNotContract();
        }

        if (
            !AddressUpgradeable.isContract(
                IBeaconUpgradeable(newBeacon).implementation()
            )
        ) {
            revert BeaconImplementationIsNotContract();
        }
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(
        address target,
        bytes memory data
    ) private returns (bytes memory) {
        if (!AddressUpgradeable.isContract(target)) {
            revert DelegateCallToNonContract();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(
        string memory name,
        string memory version
    ) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(
        string memory name,
        string memory version
    ) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            _buildDomainSeparator(
                _TYPE_HASH,
                _EIP712NameHash(),
                _EIP712VersionHash()
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return
            ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        // require(
        //     owner != address(0),
        //     "ERC721: address zero is not a valid owner"
        // );
        if (owner == address(0)) {
            revert ZeroOwnerSet();
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert InvalidTokenID();
        }
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {}

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {}

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        if (to == owner) {
            revert ApproveToCurrentOwner();
        }

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert CallerNotTokenOwnerOrApproved();
        }

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // //solhint-disable-next-line max-line-length
        // if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
        //     revert CallerNotTokenOwnerOrApproved();
        // }
        // _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        // if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
        //     revert CallerNotTokenOwnerOrApproved();
        // }
        // _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) {
            revert MintToZeroAddress();
        }

        if (_exists(tokenId)) {
            revert TokenAlreadyMinted();
        }

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        if (_exists(tokenId)) {
            revert TokenAlreadyMinted();
        }

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (ERC721Upgradeable.ownerOf(tokenId) != from) {
            revert TransferFromIncorrectOwner();
        }

        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        if (ERC721Upgradeable.ownerOf(tokenId) != from) {
            revert TransferFromIncorrectOwner();
        }

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (owner == operator) {
            revert ApproveToCaller();
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) {
            revert InvalidTokenID();
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* firstTokenId */,
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        if (_status == _ENTERED) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
        // require(!paused(), "Pausable: paused");
        if (paused()) {
            revert PausablePaused();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert PausableNotPaused();
        }
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
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IBurnPool {
    error ZeroRebornTokenSet();
    error ZeroOwnerSet();

    event Burn(uint256 amount);

    // burn expect amount of $REBORN
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import {RenderConstant} from "src/lib/RenderConstant.sol";
import {RenderConstant2} from "src/lib/RenderConstant2.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {strings} from "src/lib/strings.sol";

library Renderer {
    using strings for *;

    function renderByTokenId(
        mapping(uint256 => IRebornDefination.LifeDetail) storage details,
        uint256 tokenId
    ) public view returns (string memory) {
        string memory metadata = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    "Degen Tombstone",
                    '","description":"',
                    "",
                    '","image":"',
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            renderSvg(
                                details[tokenId].seed,
                                details[tokenId].score,
                                details[tokenId].round,
                                details[tokenId].age,
                                details[tokenId].creatorName,
                                details[tokenId].nativeCost,
                                details[tokenId].rebornCost
                            )
                        )
                    ),
                    '","attributes": ',
                    renderTrait(
                        details[tokenId].seed,
                        details[tokenId].score,
                        details[tokenId].round,
                        details[tokenId].age,
                        details[tokenId].creator,
                        details[tokenId].creatorName,
                        details[tokenId].reward,
                        details[tokenId].nativeCost
                    ),
                    "}"
                )
            )
        );

        return string.concat("data:application/json;base64,", metadata);
    }

    function renderSvg(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        string memory creatorName,
        uint256 nativeCost,
        uint256 rebornCost
    ) public pure returns (string memory) {
        string memory Part1 = _renderSvgPart1(seed, lifeScore, round, age);
        string memory Part2 = _renderSvgPart2(
            creatorName,
            nativeCost,
            rebornCost
        );

        return string(abi.encodePacked(Part1, Part2));
    }

    function renderTrait(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        address creator,
        string memory creatorName,
        uint256 reward,
        uint256 cost
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _renderTraitPart1(seed, lifeScore, round, age),
                    _renderTraitPart2(creator, creatorName, reward, cost)
                )
            );
    }

    function _renderTraitPart1(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "Seed", "value": "',
                    Strings.toHexString(uint256(seed), 32),
                    '"},{"trait_type": "Life Score", "value": ',
                    Strings.toString(lifeScore),
                    '},{"trait_type": "Round", "value": ',
                    Strings.toString(round),
                    '},{"trait_type": "Age", "value": ',
                    Strings.toString(age)
                )
            );
    }

    function _renderTraitPart2(
        address creator,
        string memory creatorName,
        uint256 reward,
        uint256 cost
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '},{"trait_type": "Creator", "value": "',
                    Strings.toHexString(uint160(creator), 20),
                    '"},{"trait_type": "CreatorName", "value": "',
                    creatorName,
                    '"},{"trait_type": "Reward", "value": ',
                    Strings.toString(reward),
                    '},{"trait_type": "Cost", "value": ',
                    Strings.toString(cost),
                    "}]"
                )
            );
    }

    function _renderSvgPart1(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RenderConstant.P1(),
                    _transformBytes32Seed(seed),
                    RenderConstant.P2(),
                    _transformUint256(lifeScore),
                    RenderConstant.P3(),
                    Strings.toString(round),
                    RenderConstant.P4(),
                    Strings.toString(age)
                )
            );
    }

    function _renderSvgPart2(
        string memory creator,
        uint256 nativeCost,
        uint256 degenCost
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RenderConstant.P5(),
                    _compressUtf8(creator),
                    RenderConstant.P6(),
                    // Complete accuracy
                    _tranformWeiToDecimal2(nativeCost * 10 ** 12),
                    RenderConstant.P7(),
                    _transformUint256(degenCost / 1 ether),
                    RenderConstant.P8(),
                    RenderConstant.P9(),
                    RenderConstant2.P10()
                )
            );
    }

    function _tranformWeiToDecimal2(
        uint256 value
    ) public pure returns (string memory str) {
        if (value > 100 ether) {
            return Strings.toString(value / 1 ether);
        } else {
            uint256 secondFractional = value % (1 ether / 10);
            uint256 firstFractional = (value - secondFractional) % (1 ether);
            uint256 integer;
            if (firstFractional != 0 || secondFractional != 0) {
                integer = value - firstFractional - secondFractional;
            } else {
                integer = value;
            }

            return
                string.concat(
                    Strings.toString(integer / 1 ether),
                    ".",
                    Strings.toString(firstFractional / 10 ** 17),
                    Strings.toString(secondFractional / 10 ** 16)
                );
        }
    }

    function _transformUint256(
        uint256 value
    ) public pure returns (string memory str) {
        if (value < 10 ** 7) {
            return _recursiveAddComma(value);
        } else if (value < 10 ** 11) {
            return
                string(
                    abi.encodePacked(_recursiveAddComma(value / 10 ** 6), "M")
                );
        } else if (value < 10 ** 15) {
            return
                string(
                    abi.encodePacked(_recursiveAddComma(value / 10 ** 9), "B")
                );
        } else {
            revert ValueOutOfRange();
        }
    }

    function _recursiveAddComma(
        uint256 value
    ) internal pure returns (string memory str) {
        if (value / 1000 == 0) {
            str = string(abi.encodePacked(Strings.toString(value), str));
        } else {
            str = string(
                abi.encodePacked(
                    _recursiveAddComma(value / 1000),
                    ",",
                    _numberStringToLengthThree(Strings.toString(value % 1000)),
                    str
                )
            );
        }
    }

    function _transformBytes32Seed(
        bytes32 b
    ) public pure returns (string memory) {
        string memory str = Strings.toHexString(uint256(b), 32);
        return
            string(
                abi.encodePacked(
                    _substring(str, 0, 14),
                    unicode"…",
                    _substring(str, 45, 66)
                )
            );
    }

    function _numberStringToLengthThree(
        string memory number
    ) internal pure returns (string memory) {
        if (bytes(number).length == 1) {
            return string(abi.encodePacked("00", number));
        } else if (bytes(number).length == 2) {
            return string(abi.encodePacked("0", number));
        } else {
            return number;
        }
    }

    error ValueOutOfRange();

    function _shortenAddr(address addr) private pure returns (string memory) {
        uint256 value = uint160(addr);
        bytes memory allBytes = bytes(Strings.toHexString(value, 20));

        string memory newString = string(allBytes);

        return
            string(
                abi.encodePacked(
                    _substring(newString, 0, 6),
                    unicode"…",
                    _substring(newString, 38, 42)
                )
            );
    }

    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _compressUtf8(
        string memory str
    ) public pure returns (string memory res) {
        strings.slice memory sl = str.toSlice();
        strings.slice memory resl = res.toSlice();

        uint256 length = sl.len();
        if (length > 12) {
            for (uint256 i = 0; i < 5; i++) {
                resl = resl.concat(sl.nextRune()).toSlice();
            }
            for (uint256 i = 5; i < length - 7; i++) {
                sl.nextRune().toString();
            }

            resl = resl.concat(unicode"…".toSlice()).toSlice();
            for (uint256 i = length - 7; i < length; i++) {
                resl = resl.concat(sl.nextRune()).toSlice();
            }
            return resl.toString();
        }
        return str;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";

library RenderConstant {
    string internal constant _P1 =
        '<svg width="1244" height="704" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><path d="M2.5 701.5V95.051L97.02 2.5H1241.5v699H2.5z" fill="url(#prefix__p0)" stroke="url(#prefix__p1)" stroke-width="5"/><path d="M1240 10H86.11v2.346H1240V10zM76.727 19.384H1240v2.346H76.727v-2.346zM4 169.529h1236v2.346H4v-2.346zM1240 56.92H39.19v2.346H1240V56.92zM4 207.066h1236v2.346H4v-2.346zM1240 94.457H4v2.346h1236v-2.346zM4 329.059h1236v2.346H4v-2.346zM1240 244.602H4v2.346h1236v-2.346zM4 131.993h1236v2.346H4v-2.346zM1240 282.138H4v2.346h1236v-2.346zM57.959 38.152H1240v2.346H57.959v-2.346zM1240 188.298H4v2.346h1236v-2.346zM20.422 75.689H1240v2.346H20.422v-2.346zM1240 310.291H4v2.346h1236v-2.346zM4 225.834h1236v2.346H4v-2.346zM1240 113.225H4v2.346h1236v-2.346zM4 263.37h1236v2.346H4v-2.346zM1240 150.761H4v2.346h1236v-2.346zM4 300.907h1236v2.346H4v-2.346zM4 160.145h1236v2.346H4v-2.346zM1240 47.536H48.574v2.346H1240v-2.346zM4 197.682h1236v2.346H4v-2.346zM1240 85.073H11.038v2.346H1240v-2.346zM4 319.675h1236v2.346H4v-2.346zM1240 235.218H4v2.346h1236v-2.346zM4 122.609h1236v2.346H4v-2.346zM1240 272.754H4v2.346h1236v-2.346zM67.343 28.768H1240v2.346H67.343v-2.346zM1240 178.913H4v2.347h1236v-2.347zM29.806 66.305H1240v2.345H29.806v-2.346zM1240 216.45H4v2.346h1236v-2.346zM4 103.841h1236v2.346H4v-2.346zM1240 338.443H4v2.346h1236v-2.346zM4 253.986h1236v2.346H4v-2.346zM1240 141.377H4v2.346h1236v-2.346zM4 291.522h1236v2.346H4v-2.346zM4 347.827h1236v2.346H4v-2.346zM1240 357.211H4v2.346h1236v-2.346zM1240 507.356H4v2.346h1236v-2.346zM4 394.747h1236v2.346H4v-2.346zM1240 544.893H4v2.346h1236v-2.346zM4 432.284h1236v2.346H4v-2.346zM1240 666.886H4v2.346h1236v-2.346zM4 582.429h1236v2.346H4v-2.346zM1240 469.82H4v2.346h1236v-2.346zM4 619.965h1236v2.346H4v-2.346zM1240 375.979H4v2.346h1236v-2.346zM4 526.125h1236v2.346H4v-2.346zM1240 413.516H4v2.346h1236v-2.346zM4 648.118h1236v2.346H4v-2.346zM1240 563.661H4v2.346h1236v-2.346zM4 451.052h1236v2.346H4v-2.346zM1240 601.197H4v2.346h1236v-2.346zM4 488.588h1236v2.346H4v-2.346zM1240 638.734H4v2.346h1236v-2.346zM1240 497.972H4v2.346h1236v-2.346zM4 385.363h1236v2.346H4v-2.346zM1240 535.509H4v2.346h1236v-2.346zM4 422.9h1236v2.346H4V422.9zM1240 657.502H4v2.346h1236v-2.346zM4 573.045h1236v2.346H4v-2.346zM1240 460.436H4v2.346h1236v-2.346zM4 610.581h1236v2.346H4v-2.346zM1240 366.595H4v2.346h1236v-2.346zM4 516.74h1236v2.346H4v-2.346zM1240 404.131H4v2.347h1236v-2.347zM4 554.277h1236v2.346H4v-2.346zM1240 441.668H4v2.346h1236v-2.346zM4 676.27h1236v2.346H4v-2.346zM1240 685.654H4V688h1236v-2.346zM4 591.813h1236v2.346H4v-2.346zM1240 479.204H4v2.346h1236v-2.346zM4 629.349h1236v2.346H4v-2.346z" fill="url(#prefix__p2)"/><path d="M1244 12V0H96L0 94v18L102 12h1142z" fill="#F98701"/><text dx="76" dy="605" dominant-baseline="central" style="height:100px" font-family="VT323" textLength="1075" font-size="60" fill="#FF8A01">Seed: ';
    string internal constant _P2 =
        '</text><text dx="76" dy="100" dominant-baseline="central" font-family="Black Ops One" textLength="300" font-weight="400" font-size="60" fill="#FF8A01">LifeScore</text><text dx="76" dy="230" dominant-baseline="central" font-family="Black Ops One" font-weight="400" font-size="120" fill="#FF8A01">';
    string internal constant _P3 =
        '</text><text dx="697" dy="425" dominant-baseline="central" font-family="VT323" font-weight="100" font-size="79" fill="#FFF">Re:';
    string internal constant _P4 =
        '</text><text dx="955" dy="425" dominant-baseline="central" font-family="VT323" font-weight="400" font-size="78" fill="#FFF">Age:';
    string internal constant _P5 =
        '</text><text dx="200" dy="425" dominant-baseline="central" text-anchor="left" font-family="VT323" font-weight="400" font-size="60" fill="#FFF">';
    string internal constant _P6 =
        '</text><text dx="975" dy="100" dominant-baseline="central" text-anchor="middle" style="height:100px" font-family="Black Ops One" font-size="56" fill="#FF8A01">DegenReborn</text><text dx="1070" dy="190" dominant-baseline="central" text-anchor="end" font-family="VT323" font-weight="400" font-size="80" fill="url(#prefix__p75)">';
    string internal constant _P7 =
        '</text><text dx="1070" dy="275" dominant-baseline="central" text-anchor="end" font-family="VT323" font-weight="400" font-size="80" fill="url(#prefix__p75)">';
    string internal constant _P8 =
        '</text><svg version="1.1" id="prefix__Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="830" y="150" viewBox="0 0 23000 23000" xml:space="preserve"><path d="M1248 0c689.3 0 1248 558.7 1248 1248s-558.7 1248-1248 1248S0 1937.3 0 1248 558.7 0 1248 0z" fill-rule="evenodd" clip-rule="evenodd" fill="#f0b90b"/><path d="M685.9 1248l.9 330 280.4 165v193.2l-444.5-260.7v-524l163.2 96.5zm0-330v192.3l-163.3-96.6V821.4l163.3-96.6L850 821.4 685.9 918zm398.4-96.6l163.3-96.6 164.1 96.6-164.1 96.6-163.3-96.6z" fill="#fff"/><path d="M803.9 1509.6v-193.2l163.3 96.6v192.3l-163.3-95.7zm280.4 302.6l163.3 96.6 164.1-96.6v192.3l-164.1 96.6-163.3-96.6v-192.3zm561.6-990.8l163.3-96.6 164.1 96.6v192.3l-164.1 96.6V918l-163.3-96.6zm163.3 756.6l.9-330 163.3-96.6v524l-444.5 260.7v-193.2l280.3-164.9z" fill="#fff"/><path fill="#fff" d="M1692.1 1509.6l-163.3 95.7V1413l163.3-96.6v193.2z"/><path d="M1692.1 986.4l.9 193.2-281.2 165v330.8l-163.3 95.7-163.3-95.7v-330.8l-281.2-165V986.4l164-96.6 279.5 165.8 281.2-165.8 164.1 96.6h-.7zM803.9 656.5l443.7-261.6 444.5 261.6-163.3 96.6-281.2-165.8-280.4 165.8-163.3-96.6z" fill="#fff"/></svg>';

    string internal constant _P9 =
        '<path fill="#FFD058" d="M1125 256v5h-5v-5z"/><path fill="#E86609" d="M1145 256v5h-5v-5z"/><path fill="#F8C156" d="M1165 256v5h-5v-5z"/><path fill="#fff" d="M1115 256v5h-5v-5z"/><path fill="#E86609" d="M1135 256v5h-5v-5z"/><path fill="#F8C156" d="M1155 256v5h-5v-5z"/><path fill="#000" d="M1175 256v5h-5v-5zM1110 256v5h-5v-5z"/><path fill="#FFD058" d="M1130 256v5h-5v-5z"/><path fill="#C04A07" d="M1150 256v5h-5v-5z"/><path fill="#F29914" d="M1170 256v5h-5v-5z"/><path fill="#FFD058" d="M1120 256v5h-5v-5z"/><path fill="#E86609" d="M1140 256v5h-5v-5z"/><path fill="#F8C156" d="M1160 256v5h-5v-5z"/><path fill="#fff" d="M1125 246v5h-5v-5z"/><path fill="#F8C156" d="M1145 246v5h-5v-5z"/><path fill="#000" d="M1165 246v5h-5v-5z"/><path fill="#FFD058" d="M1135 246v5h-5v-5z"/><path fill="#F29914" d="M1155 246v5h-5v-5z"/><path fill="#fff" d="M1130 246v5h-5v-5z"/><path fill="#F8C156" d="M1150 246v5h-5v-5z"/><path fill="#000" d="M1120 246v5h-5v-5z"/><path fill="#FFD058" d="M1140 246v5h-5v-5z"/><path fill="#F29914" d="M1160 246v5h-5v-5z"/><path fill="#000" d="M1130 236h5v5h-5zM1105 266v5h-5v-5z"/><path fill="#FFD058" d="M1125 266v5h-5v-5z"/><path fill="#F8C156" d="M1145 266v5h-5v-5zM1165 266v5h-5v-5z"/><path fill="#FFD058" d="M1115 266v5h-5v-5z"/><path fill="#C04A07" d="M1135 266v5h-5v-5zM1155 266v5h-5v-5z"/><path fill="#F29914" d="M1175 266v5h-5v-5z"/><path fill="#fff" d="M1110 266v5h-5v-5z"/><path fill="#E86609" d="M1130 266v5h-5v-5zM1150 266v5h-5v-5z"/><path fill="#F8C156" d="M1170 266v5h-5v-5z"/><path fill="#FFD058" d="M1120 266v5h-5v-5zM1140 266v5h-5v-5z"/><path fill="#F8C156" d="M1160 266v5h-5v-5z"/><path fill="#000" d="M1180 266v5h-5v-5zM1125 241v5h-5v-5z"/><path fill="#F29914" d="M1145 241v5h-5v-5z"/><path fill="#fff" d="M1135 241v5h-5v-5z"/><path fill="#000" d="M1155 241v5h-5v-5zM1130 241v5h-5v-5z"/><path fill="#F29914" d="M1150 241v5h-5v-5z"/><path fill="#fff" d="M1140 241v5h-5v-5z"/><path fill="#000" d="M1160 241v5h-5v-5z"/><path fill="#FFD058" d="M1125 261v5h-5v-5z"/><path fill="#F8C056" d="M1145 261v5h-5v-5z"/><path fill="#F8C156" d="M1165 261v5h-5v-5z"/><path fill="#fff" d="M1115 261v5h-5v-5z"/><path fill="#C04A07" d="M1135 261v5h-5v-5zM1155 261v5h-5v-5z"/><path fill="#000" d="M1175 261v5h-5v-5zM1110 261v5h-5v-5z"/><path fill="#E86609" d="M1130 261v5h-5v-5zM1150 261v5h-5v-5z"/><path fill="#F29914" d="M1170 261v5h-5v-5z"/><path fill="#FFD058" d="M1120 261v5h-5v-5zM1140 261v5h-5v-5z"/><path fill="#F8C156" d="M1160 261v5h-5v-5z"/><path fill="#FFD058" d="M1125 251v5h-5v-5z"/><path fill="#F8C156" d="M1145 251v5h-5v-5z"/><path fill="#F29914" d="M1165 251v5h-5v-5z"/><path fill="#000" d="M1115 251v5h-5v-5z"/><path fill="#FFD058" d="M1135 251v5h-5v-5z"/><path fill="#F8C156" d="M1155 251v5h-5v-5z"/><path fill="#FFD058" d="M1130 251v5h-5v-5z"/><path fill="#F8C156" d="M1150 251v5h-5v-5z"/><path fill="#000" d="M1170 251v5h-5v-5z"/><path fill="#fff" d="M1120 251v5h-5v-5z"/><path fill="#FFD058" d="M1140 251v5h-5v-5z"/><path fill="#F8C156" d="M1160 251v5h-5v-5z"/><path fill="#000" d="M1135 236h5v5h-5zM1105 271v5h-5v-5z"/><path fill="#FFD058" d="M1125 271v5h-5v-5z"/><path fill="#E86609" d="M1145 271v5h-5v-5z"/><path fill="#F8C156" d="M1165 271v5h-5v-5z"/><path fill="#FFD058" d="M1115 271v5h-5v-5z"/><path fill="#E86609" d="M1135 271v5h-5v-5z"/><path fill="#F8C156" d="M1155 271v5h-5v-5z"/><path fill="#F29914" d="M1175 271v5h-5v-5z"/><path fill="#fff" d="M1110 271v5h-5v-5z"/><path fill="#E86609" d="M1130 271v5h-5v-5z"/><path fill="#C04A07" d="M1150 271v5h-5v-5z"/><path fill="#F8C156" d="M1170 271v5h-5v-5z"/><path fill="#FFD058" d="M1120 271v5h-5v-5z"/><path fill="#E86609" d="M1140 271v5h-5v-5z"/><path fill="#F8C156" d="M1160 271v5h-5v-5z"/><path fill="#000" d="M1180 271v5h-5v-5zM1140 236h5v5h-5zM1105 276v5h-5v-5z"/><path fill="#FFD058" d="M1125 276v5h-5v-5z"/><path fill="#F8C056" d="M1145 276v5h-5v-5z"/><path fill="#F8C156" d="M1165 276v5h-5v-5z"/><path fill="#FFD058" d="M1115 276v5h-5v-5z"/><path fill="#C04A07" d="M1135 276v5h-5v-5zM1155 276v5h-5v-5z"/><path fill="#F29914" d="M1175 276v5h-5v-5z"/><path fill="#fff" d="M1110 276v5h-5v-5z"/><path fill="#E86609" d="M1130 276v5h-5v-5zM1150 276v5h-5v-5z"/><path fill="#F8C156" d="M1170 276v5h-5v-5z"/><path fill="#FFD058" d="M1120 276v5h-5v-5zM1140 276v5h-5v-5z"/><path fill="#F8C156" d="M1160 276v5h-5v-5z"/><path fill="#000" d="M1180 276v5h-5v-5z"/><path fill="#FFD058" d="M1125 296v5h-5v-5z"/><path fill="#F8C156" d="M1145 296v5h-5v-5z"/><path fill="#F29914" d="M1165 296v5h-5v-5z"/><path fill="#000" d="M1115 296v5h-5v-5z"/><path fill="#FFD058" d="M1135 296v5h-5v-5z"/><path fill="#F8C156" d="M1155 296v5h-5v-5z"/><path fill="#FFD058" d="M1130 296v5h-5v-5z"/><path fill="#F8C156" d="M1150 296v5h-5v-5z"/><path fill="#000" d="M1170 296v5h-5v-5z"/><path fill="#fff" d="M1120 296v5h-5v-5z"/><path fill="#FFD058" d="M1140 296v5h-5v-5z"/><path fill="#F8C156" d="M1160 296v5h-5v-5z"/><path fill="#FFD058" d="M1125 286v5h-5v-5z"/><path fill="#F8C156" d="M1145 286v5h-5v-5zM1165 286v5h-5v-5z"/><path fill="#fff" d="M1115 286v5h-5v-5z"/><path fill="#C04A07" d="M1135 286v5h-5v-5z"/><path fill="#E86609" d="M1155 286v5h-5v-5z"/><path fill="#000" d="M1175 286v5h-5v-5zM1110 286v5h-5v-5z"/><path fill="#E86609" d="M1130 286v5h-5v-5z"/><path fill="#F8C056" d="M1150 286v5h-5v-5z"/><path fill="#F29914" d="M1170 286v5h-5v-5z"/><path fill="#FFD058" d="M1120 286v5h-5v-5zM1140 286v5h-5v-5z"/><path fill="#C04A07" d="M1160 286v5h-5v-5z"/><path fill="#000" d="M1125 306v5h-5v-5z"/><path fill="#F29914" d="M1145 306v5h-5v-5z"/><path fill="#FFE6A6" d="M1135 306v5h-5v-5z"/><path fill="#000" d="M1155 306v5h-5v-5zM1130 306v5h-5v-5z"/><path fill="#F29914" d="M1150 306v5h-5v-5z"/><path fill="#FFE6A6" d="M1140 306v5h-5v-5z"/><path fill="#000" d="M1160 306v5h-5v-5zM1145 236h5v5h-5zM1105 281v5h-5v-5z"/><path fill="#FFD058" d="M1125 281v5h-5v-5z"/><path fill="#F8C056" d="M1145 281v5h-5v-5z"/><path fill="#F8C156" d="M1165 281v5h-5v-5z"/><path fill="#FFD058" d="M1115 281v5h-5v-5z"/><path fill="#C04A07" d="M1135 281v5h-5v-5zM1155 281v5h-5v-5z"/><path fill="#F29914" d="M1175 281v5h-5v-5z"/><path fill="#fff" d="M1110 281v5h-5v-5z"/><path fill="#E86609" d="M1130 281v5h-5v-5zM1150 281v5h-5v-5z"/><path fill="#F8C156" d="M1170 281v5h-5v-5z"/><path fill="#FFD058" d="M1120 281v5h-5v-5zM1140 281v5h-5v-5z"/><path fill="#F8C156" d="M1160 281v5h-5v-5z"/><path fill="#000" d="M1180 281v5h-5v-5z"/><path fill="#fff" d="M1125 301v5h-5v-5z"/><path fill="#F8C156" d="M1145 301v5h-5v-5z"/><path fill="#000" d="M1165 301v5h-5v-5z"/><path fill="#FFD058" d="M1135 301v5h-5v-5z"/><path fill="#F29914" d="M1155 301v5h-5v-5z"/><path fill="#fff" d="M1130 301v5h-5v-5z"/><path fill="#F8C156" d="M1150 301v5h-5v-5z"/><path fill="#000" d="M1120 301v5h-5v-5z"/><path fill="#FFD058" d="M1140 301v5h-5v-5z"/><path fill="#F29914" d="M1160 301v5h-5v-5z"/><path fill="#FFD058" d="M1125 291v5h-5v-5z"/><path fill="#F8C156" d="M1145 291v5h-5v-5zM1165 291v5h-5v-5z"/><path fill="#fff" d="M1115 291v5h-5v-5z"/><path fill="#FFD058" d="M1135 291v5h-5v-5z"/><path fill="#F8C056" d="M1155 291v5h-5v-5z"/><path fill="#000" d="M1175 291v5h-5v-5zM1110 291v5h-5v-5z"/><path fill="#FFD058" d="M1130 291v5h-5v-5z"/><path fill="#F8C156" d="M1150 291v5h-5v-5z"/><path fill="#F29914" d="M1170 291v5h-5v-5z"/><path fill="#FFD058" d="M1120 291v5h-5v-5zM1140 291v5h-5v-5z"/><path fill="#F8C056" d="M1160 291v5h-5v-5z"/><path fill="#000" d="M1145 311v5h-5v-5zM1135 311v5h-5v-5zM1150 311v5h-5v-5zM1140 311v5h-5v-5z"/>';

    function P1() public pure returns (string memory) {
        return _P1;
    }

    function P2() public pure returns (string memory) {
        return _P2;
    }

    function P3() public pure returns (string memory) {
        return _P3;
    }

    function P4() public pure returns (string memory) {
        return _P4;
    }

    function P5() public pure returns (string memory) {
        return _P5;
    }

    function P6() public pure returns (string memory) {
        return _P6;
    }

    function P7() public pure returns (string memory) {
        return _P7;
    }

    function P8() public pure returns (string memory) {
        return _P8;
    }

    function P9() public pure returns (string memory) {
        return _P9;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";

library RenderConstant2 {

    string internal constant _P10 =
        '<svg xmlns="http://www.w3.org/2000/svg" x="72" y="380"><svg width="120" height="120"><clipPath id="prefix__clipCircle"><circle cx="48" cy="48" r="48"/></clipPath><circle cx="48" cy="48" r="48" fill="#C8145C"/><g clip-path="url(#prefix__clipCircle)"><path fill="#FA6000" d="M29.633 48.617l-86.61-83.057 83.056-86.611 86.611 83.057z"/><path fill="#F5AF00" d="M63.4 142.048l-119.678 8.788-8.788-119.677L54.61 22.37z"/><path fill="#03585E" d="M21.906-1.682l9.833 119.597-119.596 9.832L-97.69 8.151z"/></g></svg></svg><defs><linearGradient id="prefix__p0" x1="622.044" y1="-2.347" x2="622.044" y2="678.332" gradientUnits="userSpaceOnUse"><stop stop-color="#452F16"/><stop offset="1" stop-color="#1B2023"/></linearGradient><linearGradient id="prefix__p1" x1="622.044" y1="-2.347" x2="622.044" y2="668.943" gradientUnits="userSpaceOnUse"><stop stop-color="#FF8A00"/><stop offset="1" stop-color="#52391B"/></linearGradient><linearGradient id="prefix__p2" x1="622.171" y1="-1.73" x2="622.171" y2="347.827" gradientUnits="userSpaceOnUse"><stop stop-color="#F78602" stop-opacity=".35"/><stop offset="1" stop-color="#F78602" stop-opacity="0"/></linearGradient><linearGradient id="prefix__p75" x1="919" y1="180" x2="919" y2="276" gradientUnits="userSpaceOnUse"><stop stop-color="#FFFFDA"/><stop offset=".503" stop-color="#FFE7B6"/><stop offset="1" stop-color="#A87945"/></linearGradient><pattern id="prefix__pattern0" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#prefix__image0_539_2800" transform="matrix(.00255 0 0 .00255 -.639 -1.77)"/></pattern></defs><style>@font-face{font-family:&apos;Black Ops One&apos;;font-style:normal;font-weight:400;src:url(data:application/font;base64,d09GMgABAAAAAAe0AAoAAAAAEBwAAAdnAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmAAhAoKj2CKLws4AAE2AiQDbAQgBYcrB1gbgQxRlG1Si+zngW1MPbihDBOihmC7LZoLmHL+w+L7alc4tb07Sb6TLCvArudVcokgSMYCOeyWnQJyUmK7gOyU2cnT1dpu6AyhbsQlvku/F5GQMzxf3Ojttr80wCYIJIkgMEjkUC//+6v/b63VE2+INR28VC+BkInr7/7NCWLLYOaVTqZEc6lEoqdISZn/938VOLtupE7d8MC/NdYBXGLQbDzgb+4KgKXnNfHPoSp2HgbAWFBlhyuLfAmEjkPNM0jT598+EP161wHmAQDu4usAgIoAMlY5CACgAbLSlOP9LQA0pt5IiJqaaY8kMbhCsVLTjw5RDVZD1FBVr/6lqmp5taJaSa1cIbBC0P8kghh5Xe8incP3Z3Fcbyc3XXTBSUfttMN2xTZf2fvb+8H73vvO+8r7zFvixSM98T72Pnry6clHQDwQINSQALAIAgBMOF7QUCZKxE4Lsk6nhODn/48lIBCCgkMgFAAgLBwgAgjWY2ljSWu/6CkA3gdyLg8DAkylRJjJMS/b2nhai9NqKNVwEvciazRUI4CIUzl/f3E2gj8ncpwgcJwMoIVeEK9aYLzESYzjKCeKHI12OvMLrOZYizXGZIkym+ITRSLjOIXITDILJp1FY5Wxllp5EcUqwjDijyViVXjJjE06XICsMmghHyngz2uRfCw8KlozQoJ3lmdBMshYccqChEUoiHFycRJO5QOxH7ZDDUoCzo3lMkCE1HYikchmyCOYdkrSh3eS2ECsgzynnCdbNpExxEvEEhhKSEiEiHA0kUtN9yeSZitTMI2weFEUTOnrgoQVIhMtwtFEgTkHOOV8JUqjhYLfjkGiIxIJydi/QLZbueSz/AJmx44wNn1avDZh2JFR/InOQqwSVswNddQiJVqWgCE8EkldVVoycybZwvtE04HtEbOQdM4fQuIWW+X8YUiBKJYgocxubuFMlLA5BiltoIG5ggRRTlYe5zGZ+mvyitFCwIa+YBpIOAnKiyAyA8kWMZC4R5Kj8ZpNIPRIGQuzYdo/a9y0eZPmG4uay9RG6zc1Zk4t1hc1XTbMpQXU2cjdaCeFAayHcRelBkq/MiIy+vfuCmFAp5InrgmuwHcLO7EsBoMeRzCpGwC66jd1R79uzCZG734xnuAyx3wp+QI76zZ80zBsF6P8ctfyiTLTtJkXeYvS0oiuJ6XASEqvuD1d9VCGr1PkWEgWHmp//ZDtV3WHUf4qfSMwoN+Trcxwe1W//gk+ibImlN5ldIFnQW0GObW5jVi2ybCJ6SacSV/LIilNr3zqDNvTJMmHyPeWlALpkNR7vKsqK7tI9yTpbz3fHB74POoYglaOXzmOY3QQOy4e9x3XH2ed2RX9Fd8V8QqzUYpXuK7GCqAaUNhGw0YW2/ydffnCWE1Go9mGmj3Esi+MxrvjNzDIZl31Xd+YMgwxqnOpOjyjCPg6bsw49AYrLq2npfQITzfSmT3aPGcXTKnXqM7dzF6h3uVtK9FZTCWwd/ne/6GbgXou6hk7wcwrV8ou3PfMWDZD/VFQ9K01YzUYXXgvA1gnSqWKnsKML4GvXs9oSzxPaaF7ZdevYAPe4wbe09l3tvLZiePGf2c0iFGwURpE6S4jG7XqNMumdNWoUb7The4sevyMOxUdeud+x3IpdYwp8vV3THDBLIOd2VeIf76ytru5BgZMyxhMd7gKM/RFGQonUnGgI/TgtU9nTxgPwvziCE+Efm+x0WOEmoajWfPm//78uckY41FjGWNXY47KDl9n35DKQ1jVg7pgM7qNOAIf9nxM7d0/gQIAAABAAFAJLSP/rVNXLX9RiQIAwNMfu6cCAO/F9yUg/6cLp3IaAIUjuJvicM3j0EDt32DtXr/VgrVdYl4eGTSzzMxBg3KPLcNgmYcG2rwlEBquPH5kj8/OVaOZ0uit6WaHOSM9nSBKDUhNA0hdpjGmJaT2DPb0pBJrxnxkK9lNrwIyAHbpx89ZQJLiIYoQWTzCNCyIMBiMOMGmIl51q5Ag0AXQEenjpmgYAOz2ByMkoooQpqtTiGheNxCnekuIF9WNkMDYU4boNO4dd6KYZxva/sOUSmpczGVxH1K4o87/M4Y+6z+8HG6N96J6546j3jiqT+HM/UV8el92+EFx4s1KCpSJKfyvkxzjcqxbt2GLSJP4OWhGM9MBt/U2Aeefa+Ki0tWsLrivWjqKiw7WOUfeq2nthrWb1GpkejibbEI1+X8uS9o4u8e9E4UWEaFUmTVioUgH1FfXUEJURR1Ifdz33hjMMFzcq2POSKWzQmOxSvjMrthOf2YVKaHFuGo+6IBjtb7qqMMqdpbtOY4yCeQWHAnGaRlgSrHi07LtZTBXkoM+8b03hwpgF1BAQTck1Lt+t3FRW111NdRCJBPhF8cKXvRzwJ3N3h9IYvPbiONe6QvlYbXNJIB7g5SiduHuDOeAoKmRNvTeRC2NmAYhw6Z+7fdob8eIkNaxPiRzJBC6Pr4PmmgBAAD+b+bQvTpG1lEEChLsHiilNMJpy27LqayKOupqpLFOaCwOT6TRWQAAAA==) format(&apos;woff2&apos;);unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}@font-face{font-family:&apos;VT323&apos;;font-style:normal;font-weight:400;src:url(data:application/font;base64,d09GMgABAAAAABpUAA4AAAAAwJAAABn7AAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGigbHhyEWAZgAIRkEQgKgt9ogpQEC4NUAAE2AiQDhxQEIAWDMAeFORvkl7OierTQkYFg44D8Br48ijKxSrP/QwI9xDJPsV1kGEewHZHdaEZDW0vovnTgTesJ6y6hT6byUn9rJv+1GZUb+4yM74yReC7Pf7/f69rnBskCaRQKFaHQMS6l8dW+HZ+4/vrYd3/+nfPPTVJV8AXzVHAvYsGkYkA7CBNzeWafbzz8/2Xet71wE1yqtjq8JTyU4sHWuCPGPOdDgLo2c3ia6aWYpXkTR8yXmWUiwC+3cmc6HhS4Is+RbX+VTfWXCEcU5z6FA0kVOeHCDOPvVCsrn1fWBSGTmdp7fntXe6g32TkbxObEBrF3YgXfOYEmTfhi0CK+g3pR7SCmvzThS1SKyZq1VlUnu3ekPaFOAj6xMSA8W51MlvN/lIfGuAAI+H9rv68zb3CNtgkN9ZFoiQznLu++ZVDPIraDb0S8ERohikhy/RqKhvjPD7H85H7f0pLu9qUEqTPgRuzetqT/FEZ1Ue0oOekd2mdAp7pq5kbVo7hZckwEGWC0a7Rid8wWTjP6rVAUCvugRCzPqFYzu76sJPtbIYzYjxI/1y/zhm39uxA6JYTMmhzufo2l/7OJbd+RtDMT5k/SyyZeHKIiIiIQIYn/vYUCzAFQCIThkBFGwYw2BnLcEwgCZvjyhbYFhlrgIgC9gwAz1gUNmGHr0/JOphfE3NirpnwSTJvsWhIaNtVBA8Muu4mErGzioc+6pTzcRfWGQ0LVSWxiSolFRCERhOQSTkDmg+GTlhaEJ4zWyCnq+0MYIthXhKncbu2EHT4uYzdsYmvYMraAzfI7BQicYQwxggFjMU5tNp4zdiTFvTIo+ZW5MHLsnVN5tBpjbPydixAsXbV2C10qXLDA741TEuMaBdNsJEy1ETAVEKTi/TDRMGp8CGEe3HoTYcTY5g74nIqPX4nccSYIAv9eLAjaCxsowfhwiBISqzhQFkJqqXeMkgzgC39304yI35mHBequGgBc0fzZg9YfAIzXxaEn/VRedvXlcA7sjHGyX4Oxnj9I6B2Ql6KALThQQAPW4BCwhijcAzhGIsiBeXGSjfEjmtRgp+pKvahXW0rSm/QnA8lQMoXMW2aWdwUEBsoDVT8OYB6JkmJdaFLN91GQnqRvSMnvQdIXcAfoO2AIHtaH+aEAHx8AH+ejIl3JO+nbPW6POwcB7AOXHoA8QXJuvtrD/7hmmTVWOOm6m9baZrv5zlpil5XWW2ydyy66ZJUbCEIiEjJqHjx58TcIKUCgYNFixaFoaCVKkixFmi0W2OqRDT5Ll69AkRIVKlWp1qhJsxat2lnZOTj16NWPMWCI4TZ5YLOrjlnuuNNOOOOh2z65Y7Q9rtntri/uu2KGmd574paFPphujL3mmmOe1bhY2Pg4eATEVOQUlPx48+FLKki4EKEihTkvQgIdvXipYnTLliFTriw58hQqV8qgTINadWjF2hh16GTW5QKTPi5ugw1lM0wUi512OOiQAxCUukWAESB/IFcAJ//gfAqQHCA9AICCp24siPggZQ0RLAV2qeMoaWdIEdpawZF0qJ1A0IA389YDdwNQ+0cxUei9TY/AVQtSvQsTwwAaLaHtiQzgD+zMWQThCmGFvzLQWiVT3Ahx4Aet5I2CkziWU866tKKHNjYeBm3FlbM1Za3k88/Sf0vV2DLkcjoZnaMzlBl8fp6bbn1+zyv6Td0ySeugzNGw3VLtZmiOSpfnOGjdImhO/Fk+Qz7l6//MQ3mYz8s85IsVILFNMekd4fAg35NgO132Lq6wLGkByk9dJvZUXNlrSq8Jm8WLJjkb123HVc77k7aUDJIAbrv9u/8oH+FRYnxffLhA20Apks3h0XocvVnICrGpUV6v24irSxV3G/tuQwPsC6VsBMquMjYDEuXR72S/Yrdbr5NmkwXeZ7ON07veN++F2K/Lc825QECxqGnaiyYmv+LT+deUJJOanKSM62jMpqiursb30ywrSGmayOO0BmfrxSN8/qkD2MEXniJuY2ivQAya207GAkIereBJKYft6NiiOE4XbQPcFwJGAZlaZlqGlDA1//TH2cDROjQogZ/GFyrySodq+msKvmXKl70NXeB0MEQg7GgntcRhRfGCJXgFkv6y7n8gXdEWh637CJmgy9kXPyNsEuzL7HNAixqY6Gjdbk6MjsFkDJGk6cjabsDfg0hFlkbv7k9FQcDS0OoZ2QAk7bOdi0GKg91RpecKtN0RsXt3sRiOAcm3AqlQBVqQvyR2TB1QVcedXQygRXs1pSQsesup7bT9gvQQMDCJDWrnyfErsM1AfK9z2ETLUebytexXx1TB5wLddHDv6+lV7KuvRwZQOhQ0Va8Hymcpe4Mv8UJaGaQWxVIN9JBmjniNXkHY4mbvc7/wHGV3s0SlnoNb7fKbcIs645Gv+oo9dtGOh06kTeBCk/jPa1FOb+eu6pzu2Nx8h4TiDPst6j4RM2uwxdIL00nzSSlzuzsuYHcggM4xxIGz090CzgobulOaO4snMNbzWS45aGagRtQiAIj5i/QUMXXr5ptRBF72dp1wvdsrK2I3UGyomH9ro3T53NmqxxnaKtg0hmd35ajtgmTd7F0ANQ2Lw1e3qngrN8mUYakyPq1kkR4SnkhMp7RRdC/Vmset3HEAq6TOa5bXpMasK5qr8+IKZnAtoH5pA93ltnyJyjPkHqG/lvACx6A56ysuPmKWBK4nC0G5qeSJeQxhQlcXIlyutMf8PN82OcLDF0NanI27zsqsDTBvY6KJ2HH1CmXEFepnDV4qUxVagjk61q0AhCixdlH9ij1JoFi8Z5ytA97rQedJLivPaT4wilNHv9pHk7y0jk67Qhe2fMrlKr0z8nbY7w6oZuwKjNhFb4BOuUHb8hnrdvlBGDzizoYYrHaU2XfboMh4ZwEpl1sUzMAyig/XaDq9uF1LQiIuO0zlM7UdQO0a8Ruu+h1FKoIAVwFg70mwwlxGlmpmnan72xPm6NoydOJ6rCUlK7/9Ap3K9gmjEWEJDxxsEREU3gx1gDX/jF9QEc2T7oqowqHYvR1GmmUp84XMsd6qi4eC0+i/1+mFwE9CWIaHlblV8WZKNlux4/NBL355BoWLDZajXDxlS88ftCmyf6FkzYvoqqAyF5YlVhrJz5R/rcWxPDicmCpqIy45cEb9OxhhxJTIuh1MKGSu992N8RMc2t56d0SA3YvLf72sWYPTXFVmJxJDyOtDzscwIO7YhPlKIOw2cHo82CcxU9TwG7kyDp3MiWCvOomyBky624y37k23MMkVoO7N1ZNcBrZXV1PzaKTVistym4RMLxTa03xzGJoQC6SIIrTz4ngJZGbRxtrlvRntEInvu2ZpLET1JU3JDShqgE6+wv2ofvd9dCPgd0PS1BLGyqRIdv681pjMix1OByezC+w01fgjLMBJgo/Oys27KMoypjnPKTGKPBvVIevOCsXY6968lWm11zXO8J17n+XK51re93pvD/4bxkCT1W4aHiw8SYNpNgUT+Gxmnq1u9+Iix8XpteEcFX/6gfDGYPT/POdSDXaXfy1cuV2lZdtXJs/F2ZtVceErqUo5PZSQeXUqN7Buc2NyanHR1LiavOICACtqXoQbwjhad0t+2kbvtE7nmWsNd5tH9QJa8UicHz8tN5Fpg5GLELSsQ2oYWgk/q3F7t8/LTivg7oQwdsNW8KGAYy1fPr1iz9Wuiisg3Gsh8Jk5hOMW+PavSGQ+pI0/Ubr0mpWdprHqKMrpPGdiHxLfjI1xIjNtWH+CPufij5SGSB392dJqND6tAsWtVBtcaS8T/onOWKIOIa1rjYX+tp/HkoWKXaSlU+aWVJnVZmgxfBOulRJigPIqc8ksAvkfiuaPdjOchrXKncOwALVUg0+wSCb+/Ty/yxhYeQZmWr2JGLFGy3xPpg3XHU6TuBOzYAz2LodySJv7DZUb+h/g/JlgQ1TYF6Auo3xVo+ZO1sJeTmcS1baThqTx1goMmmlRDGISLd7UNQZ/rOfJM19UeoH5sKF8gtrrQhlODausHG3Bvv0Tj1SikmfvOLxTpXt9lL7Xu0woYn7mhfGXqfbHnqVGo2147bw2UGxWOwz/+qANgzkklCEwRHIOHf2Fp/r06AyiTx1VoGMgopvml8G4xxw38AsJXpPqMNQR0GHwekw6Zu3CDbokTluSvHkQ+SVG/PW4MoOxAxkqR+PY10QnBUWwwhaIKlZrbgbbJznAqHX4GhyFrKE4Esktbavkz0or6Y6hPuo+o+4jGGiLk69axDDylOGLndQr586pITgsDVQ7qPeVALBU2jEHI5YgqceAWGXhSzFq10RMAj2xD54XYQntmtRFFZp8gmGDUR6fwbMAVBZ+hc7N8UktlwpYGgTLKJ+T9blTW1/K4Q9dcH4zdXUtqRFOIImfHUGybEgSqxLuHLKDUqFOsFM6xrB9pUjBS4fVISKXdwZISTGkTnBRU88DrPAjiBtaLLXFnxEMlNlEf5yD2ctklia6J9oA4sjh0cCZ4p0QD1P6g5WDrwG3fBC4bWSX026SbXN1fHupTsudLMIj8YJdhsqmDbjC5O7LmRCi4jc0awgAP5HOZ1ObYVDWEzmEu/KixoPbKsmDxpO7WKDx6LbKAhuMcbo5IwCkYR8Z2x/S94c3o6n/R02zwceTjfocdNAj/3lSsBK8z6mCDnEBK764u9z7PIo/jp8Gp7eu4ujTe6B9iw2z2lXoVKdIAUuQNLKZXEPppH0TNj/OFsczMVQROM/zUOJzB/KX2X0YCAYuU553hW3fxfQjF5xxnnuL4Lqu7fvAJNoMWX/FwAmCL8cCQLDrcololMBdudatvi6sMazbs66B5vUCgeZ1iw6AV6IoZYxEZ1yjMkM+mwsFJWbYIiGkk8I0SBVrM9HiumV7bqzqxMKNg8SVQTNiDbaZI8kbI21TzCPaG9n4BKQY2wYD4erYFOc1I/HSdvQWrd6pvoHku9Mw7YTIUef3COEAThKbfwzNjf/s3MSJa8mN4I1Nn7vF68Jx4/Ly4cAIMxlz9/Cxs0HrV5Fzfu4E5CSJubKRzi9P6LSOhLB93wyTjJuvH83E0NK3eDABeJTAw/hXS2qni5oVjzjkWl3kOugK1U5366Z0uNhx0g2v8Cr4vHE4kdiJKi/RfcdENLO7U9Sk31punPmpeZODMbNIb2Z7u/DcuYZq72MN4Q2shMzGmXBcq05soMOX7KdN8wtBcpEWndjpHEKO0ToMEKZ6OrNJugrkLo0B0n4bLyvLMLO3ipq7YASTVO6SQyaH/tyWMGb65wvgyW5Qan2ZGwLRvLh+fWdQQHkFg142PXnqntkyHhRTtNte0p83XF5VociQJilbDDCc6en58oY7O5Q09gbOL9g3UFLKSdlIobFZX1UslvwNzyHDkmI2FmmFRPVq6rizr7Bno9Sx4Jj47Uwif8bAIZ1NuERe1vJr6agN8XuFC3OpchYaf+Z8gca5uVw18H4gd08MYpgNt05EaSCTBBDH9WmAqGsFXCshpiLvDnW+vJ4JuMjT8kMsbzFK0HPB2Z9KeVqlspDNSkUT84Lkjef1EObFItckkjtnikZxVAmsL4l7CdPQuyYG+sFuzVcULP3qHtAJxxtsbuc8mDjRevFuMp/YccQXOewjKJTS6/WwBnLklYKCEgnMcQ/nL2C9RqmX6ijBEa4+u9G8isK4vaK9a2ryNHdZd4Js7l7RSj9wjI4K99QX4Z2uUNuXGM6pKcI39TBc45lapUGaFG8KQ1zIKb4ljgQR4SSNzOLd5o+KPJp5fFs6+hoLf3HgeTpEuVmQPYRLXjoRb2uSqEzH76XpuNtY38zUq0jSVBss0tX4Uuoed/GFIIJiZd0wlixeybRdcBo6NKUql/oILi0N9+Qb/dlfMgc+zPuHZ73KAxxE2Qp3cwxNgN8lbh04wXE0oMwM/aoxHCcZHw6rT5sbaPUybrY9P31oy0NSL2oIUU3xd8dyPAduTZcwkwBirYHWOm25CYavoKQ6ESi3bJNJwpvDZZ+I/nBkNE+nlnjeu9lZ6qg5vAO7tRWskW/x/pMJNk4sV62ZpsIPQuby70PrgC7r1Yuq+7PSZJSTdSV28ZxyEse+24BgheIykmOC8Sj2EvQcDtKVjbDjVzh8/eB16WT+s4efWKhQLv0hIaeaeR9fvYLUAiQRkY2jB3IJfmN4m12HG0x+ayBEJogosmQUCzCCkPmgmYXIRGKp09BcuRtOGgay5M2gpcg0OO2rdYzBpOvnd4q+pd8GpjNBsMOh3vlOmV1vliiSasdvifU5xk5hihyd+B7X+Qed8fRn0XsAXPbU2g2qsARvEbFwoS7QMZ5V+OQuTWg4z+UKcS0zR+BEelgYQTuLwhCiMEHAgDyDuHRVr5tcD9G+yDpGQptliM5DVxAIYlyAiKue8k/fEr79OjgIx6LCKs/ESYtjWAMDfaiG8CQZXeL4CTcR472yNO7pn0GI6g6+bfUoKdOruDViFnph4LTBb1i0OKkOTZisznJNW8GstbB93kHrxMC//SUR+CbSeqXQK8G3B0cMz1nnDPxGnNvlvsiFz758gNxZXRvgEKLbAMGX3gQFcDmlsMkULQWeVQDSM4UO5LoqKvimUCXLAJXa+ET4tA+NBHLHb5AZcp5rxDhXFOMhJmNYjmIyw+73EPbM3wMf+ngjyuUYsCSWIP94iyT+ewQOUwL+EZJJTwKc9qKBJIXl1vEoh9NMAdcaOO6/Fa14bI95UY8WIN6wxuZqhymxovk5NIqCG1iOOIrBDv3WcNCM8aMPxXwQDq5qH7MorIWH9doMtP//AgdfuDp6NGN3DNE5oenpb2XgMLFth6KGvXC3bRejjr1mEJY9Erlv9DeaOSVXN+LcEk9LMfyUeLwzthKSbEqGXSbFW8xbm8JWGrz14aK0hFjLa7rU1HyliBw5zxlGSyAY1i5EHIiJNYFRA+wMjZWk7IFenOYZhvxI3ViiEIpr0YmgrsAVgWuM+bmoGlfKT8ACPMAVSSCxJrshFLB4yTgAsu2JO+JIM9nq8mAjBD7Wwsaeg5EYil+rb9cezhC6q1DXQvBf6B8Dh4xT3wxI9q4A3wt0lNU4fDPoRB2cCvXH4PQhqpSR1eH8xieP3tQxFiuGDJCRoWLmyMiLy7tVzas0xyiVJKVKM5X6mTBnrsyKi3YNvtF0rX2XCNTRFS/pZ6Npqack3JZG/PRGw0OQfODZ0hnDt7on/oFNiNwyW2YuiTx/ZIIzuBBCB4DTBI3UpBgy1EThRP4WRmw+CEurhkY0p2dOxyRS8gE01DA7rGwYTYlHoJ+DtebPvfI7pwxTakD0KoDoheJMNlEc1LWS8j7ECdQyW+mlcWQcpKBnFNbSbyw1sxxS7xscZ+RRnq5O1KmQ1eF9vOCV9ED+j+B/0eZmhiugkBL/RxhZ+RYKZdOCx3Q8TgDjfXAzYlmvOp2N5rKoTtVb4czhqIjmv7XQIdy5kO9arC4oo7CHgm/LrpIfkgAZqQpiHk7q8+CxhrhfVlPc+QI6v1fsg/WmnMSPNgwNZuGmLgv62goLd/9u7ITPrOjZnkE4SXVmPNiYiSwFxkyX4o/jQe8skoRT9YQcegtFEpUo7pcCjXgj7F2uVcFoQdpM9eNEyYUh/CRtBJROfBc+dQQKdElaMoyM3Yiy3QhgBwFMehnzrJMd6L8yfU1Fjs1bClqZjdYL2kDEBeuREPpams4bzEH/lelrbYGMmBIbtimuxoFKmT7TtiKunYWEevNeH1B26V4YfGKQ0zytTJ+TNygb3V1anUmlcpKLjqZYdQHjAIwBeL8G9kBynKQe7qFF0p4YxUC3pTTIgtMZssXGxd0jcJWG5gFcYhVH6TqEqTv8gQ6TBaviXXxRf0HS4QKvQ5piNABcGBkK7R/Z5HBPMNDDIaDA//GpgPb5tK+p1v4B/vzOdgL+zme++f+xS7NtTApMwgACbmAmIS8G8g1IiPnnBneEIaN4r4PfgQEq60BG66wOu20JpsuS5MYwdFqC+VzLBoe8lWCT0chy5GRJaNlluirL6XbHZIzadew2O1VM0u6CjFHZAnRXKZj4pqJVU/BAu9Myxm/CdRiBMld2I8croDZsImkXZVWk3czypsQq5pFpir4FwynQ5yrTTzFXsphFel6XFa9VFqAfkGFAC4aAkefYruDClGg2E/hsq+EQMMUCh0rTwDc3dBLCd07CiB2QcJQJEsGbjbJMyynbVP/2iumBNwyGW4o4cfoZ9bFzY/SL1c+uWyyXPlZxKhQwoNXS0dKJUc3MakC3Tn1oZn0W3+rSi6QVi0Kh3kMg1eZPNVWdUvXKpboXB2pO5VwubsOlR1lXCXwHp2hoRCMjptQsiFAqqbKLg5mR2zjbAIaNawUak8K5mTErlBXL5rFxtywuds7iB4xl5NIjAgag/6IFIn7uEUgBBhfsuqu67Ga0xzwhQpmE+S6c2TU33BQhUpRot9x2x10xt1N0PxZa99xn9dB8e+2j8yu9eAkSJXnkMZsnkqVIleZn6fKkKt0B7V1pnXwFXAr9pIh7NT+ewYqVKGXwFGOIoYEbUKZchUpVhqk23EijjLDeaPvV+E2tOrTp6jUYY5zxxt7E0cF+cUJrEM45b7U1FJRUt4oEt1n0KxOsTGQyU075B/6F/0Ak00VT+ZHYibARm0ygDVj4/MnlBE+bDhmyCAgddIA0+Lbb4YyzLjvksCOOuhQCk5zGiTmTLSH2uz/gGFKAQRbqtAlXEJ5ppphphlkmavdNdoiykMUsRRZ5FFFGFXU84mm2N56ZI9cLrz0vldcZDDx7bPeLsbu2uhS3tFs4A712isqJVKZena9ISyXq1bfuFWO8ZjP4X3Zudu1fUrLzlOgmbisf+DlaTby9TK46Kql3Iu8pymjNL/SlkNdpHGCaSH2MlibJnmLs3aZfE32iNhHhnMScHAA=) format(&apos;woff2&apos;)}</style></svg>';

 
    function P10() public pure returns (string memory) {
        return _P10;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0) return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(
        slice memory self,
        slice memory other
    ) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len) shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if (shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0) return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(
        slice memory self,
        slice memory other
    ) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(
        slice memory self,
        slice memory rune
    ) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(
        slice memory self
    ) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint selflen,
        uint selfptr,
        uint needlelen,
        uint needleptr
    ) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(
        uint selflen,
        uint selfptr,
        uint needlelen,
        uint needleptr
    ) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr) return selfptr;
                    ptr--;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(
        slice memory self,
        slice memory needle
    ) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
            needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr =
                findPtr(
                    self._len - (ptr - self._ptr),
                    ptr,
                    needle._len,
                    needle._ptr
                ) +
                needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        return
            rfindPtr(self._len, self._ptr, needle._len, needle._ptr) !=
            self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(
        slice memory self,
        slice memory other
    ) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(
        slice memory self,
        slice[] memory parts
    ) internal pure returns (string memory) {
        if (parts.length == 0) return "";

        uint length = self._len * (parts.length - 1);
        for (uint i = 0; i < parts.length; i++) length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { IPiggyBankDefination } from "src/interfaces/IPiggyBank.sol";

contract PiggyBankStorage is IPiggyBankDefination {
    uint256 public constant PERCENTAGE_BASE = 10000;
    address public portal;

    // nextRoundTarget = preRoundTarget * multiple / 100
    uint8 public multiple;

    // min time long from season start to end
    uint64 public minTimeLong;

    // Mapping from season to seasonInfo
    mapping(uint256 => SeasonInfo) internal seasons;

    // Mapping from round index to RoundInfo
    mapping(uint256 => RoundInfo) internal rounds;

    // mapping(account => mappiing(season=> mapping(roundIndex => userInfo)))
    mapping(address => mapping(uint256 => mapping(uint256 => UserInfo)))
        internal users;

    uint32 public countDownTimeLong;

    // 800 = 8%
    uint16 public newRoundRewardPercentage;

    bool public isClaimOpened;
    
    uint200 internal _placeholder;

    uint256[43] internal _gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "src/PiggyBank.sol";

contract PiggyBankMock is PiggyBank {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "./oz/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "./oz/contracts-upgradeable/security/PausableUpgradeable.sol";
import {SafeOwnableUpgradeable} from "./utils/SafeOwnableUpgradeable.sol";
import {RBT} from "src/RBT.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {ISacellum} from "src/interfaces/ISacellum.sol";
import {SafeERC20Upgradeable} from "./oz/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Sacellum is
    ISacellum,
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable
{
    RBT public CZToken;
    RBT public DEGENToken;
    uint256 public rate;

    uint256[47] private _gap;

    using SafeERC20Upgradeable for RBT;

    /**
     * @dev initialize function
     * @param CZToken_ $CZ token address
     * @param DEGENToken_ $DEGEN token address
     * @param owner_ contract owner
     */
    function initialize(
        RBT CZToken_,
        RBT DEGENToken_,
        address owner_
    ) public initializer {
        if (
            address(CZToken_) == address(0) ||
            address(DEGENToken_) == address(0)
        ) {
            revert CommonError.ZeroAddressSet();
        }
        CZToken = CZToken_;
        DEGENToken = DEGENToken_;
        __Ownable_init(owner_);
        __Pausable_init();
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev set invoke reate
     * @param rate_ $DEGEN amount per $CZ
     */
    function setRate(uint256 rate_) external override onlyOwner {
        rate = rate_;
        emit RateSet(rate);
    }

    /**
     * @dev withdraw remaining $DEGEN
     * @param to address receive remaining $DEGEN
     */
    function withdrawRemaining(address to) external onlyOwner {
        uint256 b = DEGENToken.balanceOf(address(this));
        DEGENToken.safeTransfer(to, b);

        emit Withdraw(to, b);
    }

    function invoke(uint256 amount) external override {
        _invoke(amount);
    }

    function invoke(
        uint256 amount,
        uint256 permitAmount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external override {
        _permit(permitAmount, deadline, r, s, v);
        _invoke(amount);
    }

    /**
     * @dev burn $CZ to invoke for $DEGEN
     * @param amount amount of $CZ to be burned
     */
    function _invoke(uint256 amount) internal {
        if (rate == 0) {
            revert RateNotSet();
        }
        CZToken.burnFrom(msg.sender, amount);
        uint256 degenAmount = amount * rate;
        DEGENToken.safeTransfer(msg.sender, degenAmount);

        emit Invoke(amount, degenAmount);
    }

    /**
     * @dev run erc20 permit to approve
     */
    function _permit(
        uint256 amount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal {
        CZToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface ISacellumDef {
    event RateSet(uint256 rate);
    event Invoke(uint256 amountBurn, uint256 amountGet);
    event Withdraw(address to, uint256 amount);
    error RateNotSet();
}

interface ISacellum is ISacellumDef {
    function setRate(uint256 rate_) external;

    function invoke(uint256 amount) external;

    function invoke(
        uint256 amount,
        uint256 permitAmount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";
import "../../../ICustomError.sol";

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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'

        if ((value != 0) && (token.allowance(address(this), spender) != 0)) {
            revert ICustomError.ApproveFromNonZeroToNonZeroAllowance();
        }
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            if (oldAllowance < value) {
                revert ICustomError.DecreasedAllowanceBelowZero();
            }
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

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
        if (nonceAfter != nonceBefore + 1) {
            revert ICustomError.PermitDidNotSucceed();
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(
        IERC20Upgradeable token,
        bytes memory data
    ) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            if (!abi.decode(returndata, (bool))) {
                revert ICustomError.ERC20OperationDidNotSucceed();
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {RBT} from "src/RBT.sol";

contract RBTDup is RBT {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "src/RBT.sol";

contract DeprecatedRBT is RBT {
    error InvalidShortString();

    function updateERC20MetaData(
        string memory name,
        string memory symbol
    ) external onlyOwner {
        if (bytes(name).length < 32 && bytes(symbol).length < 32) {
            bytes32 nameBytes32 = _completeShortStringToBytes32(bytes(name));
            bytes32 symbolBytes32 = _completeShortStringToBytes32(
                bytes(symbol)
            );
            assembly {
                sstore(0x36, nameBytes32)
                sstore(0x37, symbolBytes32)
            }
        } else {
            revert InvalidShortString();
        }
    }

    function _completeShortStringToBytes32(
        bytes memory stringBytes
    ) internal pure returns (bytes32) {
        if (stringBytes.length < 32) {
            bytes memory re = new bytes(32);
            for (uint256 i = 0; i < stringBytes.length; i++) {
                re[i] = stringBytes[i];
            }
            re[31] = bytes1(uint8(stringBytes.length * 2));

            return bytes32(abi.encodePacked(re));
        } else {
            revert InvalidShortString();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "src/RebornPortal.sol";
import {BitMapsUpgradeable} from "src/oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

contract PortalMock is RebornPortal {
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    /**
     * @dev read pool attribute
     */
    function getPool(
        uint256 tokenId
    ) public view returns (PortalLib.Pool memory) {
        return _seasonData[_season].pools[tokenId];
    }

    /**
     * @dev read pool attribute
     */
    function getPortfolio(
        address user,
        uint256 tokenId
    ) public view returns (PortalLib.Portfolio memory) {
        return _seasonData[_season].portfolios[user][tokenId];
    }

    /**
     * @dev check whether the seed is used on-chain
     * @param seed random seed in bytes32
     */
    function seedExists(bytes32 seed) external view returns (bool) {
        return _seeds.get(uint256(seed));
    }

    function getSeason() public view returns (uint256) {
        return _season;
    }

    function mockIncarnet(
        uint256 season,
        address account,
        uint256 amount
    ) external payable {
        uint256 value = (msg.value * piggyBankFee) / PortalLib.PERCENTAGE_BASE;
        _registry.getPiggyBank().deposit{value: value}(season, account, amount);
    }

    function mockStop(uint256 season) external {
        _registry.getPiggyBank().stop(season);
    }

    function setNativeDropLock(bool lock) public {
        _dropConf._lockRequestDropNative = lock;
    }

    function setDegenDropLock(bool lock) public {
        _dropConf._lockRequestDropReborn = lock;
    }

    function getNativeDropLock() public view returns (bool) {
        return _dropConf._lockRequestDropNative;
    }

    function getDegenDropLock() public view returns (bool) {
        return _dropConf._lockRequestDropReborn;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "src/lib/Renderer.sol";

contract RenderMock {
    function render(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        string memory creatorName,
        uint256 nativeCost,
        uint256 rebornCost
    ) public pure returns (string memory) {
        return
            Renderer.renderSvg(
                seed,
                lifeScore,
                round,
                age,
                creatorName,
                nativeCost,
                rebornCost
            );
    }
}

// SPDX-License-Identifier: GPL-3.0
// inspired by https://github.com/ngmachado/Waterfall
pragma solidity 0.8.19;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {Vault} from "src/waterfall/Vault.sol";
import {IWaterFall} from "src/interfaces/IWaterFall.sol";

contract WaterFall is SafeOwnableUpgradeable, UUPSUpgradeable, IWaterFall {
    using BitMaps for BitMaps.BitMap;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // @dev Config for the merkleRoot.
    mapping(bytes32 => Config) internal config;
    address public vaultImplementation;

    uint256[48] private _gap;

    function initialize(
        address owner_,
        address vaultImplementation_
    ) public initializer {
        if (owner_ == address(0) || vaultImplementation_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }
        vaultImplementation = vaultImplementation_;
        __Ownable_init(owner_);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function setVaultImplementation(
        address vaultImplementation_
    ) external onlyOwner {
        vaultImplementation = vaultImplementation_;
    }

    // @dev IWaterfall.newDistribuition implementation.
    function newDistribuition(
        bytes32 merkleRoot,
        uint256 amount,
        address token,
        uint256 startTime,
        uint256 endTime
    ) external payable onlyOwner {
        require(
            config[merkleRoot].configured == false,
            "merkleRoot already register"
        );
        require(merkleRoot != bytes32(0), "empty root");
        require(startTime < endTime, "wrong dates");

        // intialize vault
        Vault vault = Vault(
            payable(ClonesUpgradeable.clone(vaultImplementation))
        );

        if (token == address(0)) {
            vault.initialize{value: amount}(address(this), token);
        } else {
            vault.initialize(address(this), token);
            IERC20Upgradeable(token).safeTransferFrom(
                msg.sender,
                address(vault),
                amount
            );
        }

        Config storage _config = config[merkleRoot];
        _config.token = IERC20Upgradeable(token);
        _config.tokensProvider = vault;
        _config.configured = true;
        _config.startTime = uint88(startTime);
        _config.endTime = uint96(endTime);
        emit NewDistribuition(
            address(vault),
            token,
            merkleRoot,
            uint88(startTime),
            uint96(endTime)
        );
    }

    // @dev IWaterfall.isClaimed implementation.
    function isClaimed(
        bytes32 merkleRoot,
        address account
    ) public view returns (bool) {
        return config[merkleRoot].claimed.get(uint160(account));
    }

    // @dev Set index as claimed on specific merkleRoot
    function _setClaimed(bytes32 merkleRoot, address account) private {
        config[merkleRoot].claimed.set(uint160(account));
    }

    // @dev IWaterfall.claim implementation.
    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        );

        bytes32 merkleRoot = MerkleProof.processProof(merkleProof, leaf);

        if (!config[merkleRoot].configured) {
            revert InvalidProof();
        }

        if (
            config[merkleRoot].startTime > block.timestamp ||
            config[merkleRoot].endTime < block.timestamp
        ) {
            revert InvalidClaimTime();
        }

        if (isClaimed(merkleRoot, account)) {
            revert AlreadyClaimed();
        }

        _setClaimed(merkleRoot, account);

        IERC20Upgradeable token = config[merkleRoot].token;
        Vault vault = config[merkleRoot].tokensProvider;

        if (address(token) == address(0)) {
            vault.rewardNative(account, amount);
        } else {
            vault.rewardERC20(account, amount);
        }

        emit Claimed(account, address(config[merkleRoot].token), amount);
    }

    /**
     * @dev withdraw remaining native tokens.
     */
    function withdraw(bytes32 root, address to) external onlyOwner {
        Vault vault = config[root].tokensProvider;
        vault.withdrawEmergency(to);
        emit Withdrawn(to);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {IVault} from "src/interfaces/IVault.sol";

contract Vault is IVault, SafeOwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    address public erc20Token;

    function initialize(
        address owner_,
        address erc20Token_
    ) public payable initializer {
        __Ownable_init(owner_);
        erc20Token = erc20Token_;
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function rewardERC20(
        address to,
        uint256 amount
    ) external virtual onlyOwner {
        IERC20(erc20Token).safeTransfer(to, amount);
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function rewardNative(
        address to,
        uint256 amount
    ) external virtual nonReentrant onlyOwner {
        payable(to).transfer(amount);
    }

    /**
     * @notice withdraw token Emergency
     */
    function withdrawEmergency(address to) external virtual onlyOwner {
        if (to == address(0)) revert CommonError.ZeroAddressSet();
        uint256 nativeBalance;
        uint256 erc20Balance;
        if (address(erc20Token) == address(0)) {
            nativeBalance = address(this).balance;
            payable(to).transfer(nativeBalance);
        } else {
            erc20Balance = IERC20(erc20Token).balanceOf(address(this));
            IERC20(erc20Token).safeTransfer(to, erc20Balance);
        }

        emit WithdrawEmergency(to, erc20Token, erc20Balance, nativeBalance);
    }

    /**
     * @dev receive native token
     */
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {Vault} from "src/waterfall/Vault.sol";

interface IWaterFallDef {
    /**
     * @dev New Distribution Event.
     * @param sender Address that register a new distribution.
     * @param token ERC20 compatible token address that will be distribuited.
     * @param merkleRoot Top node of a merkle tree structure.
     * @param startTime timestamp to accept claims in the distribuition.
     * @param endTime timestamp to stop accepting claims in the distribuition.
     */
    event NewDistribuition(
        address indexed sender,
        address indexed token,
        bytes32 indexed merkleRoot,
        uint96 startTime,
        uint96 endTime
    );

    /**
     * @dev Claimed Event.
     * @param account Address that received tokens from claim function.
     * @param token ERC20 compatible token address that has be distribuited.
     * @param amount Number of tokens transfered.
     */
    event Claimed(address account, address token, uint256 amount);

    event Withdrawn(address to);

    struct Config {
        IERC20Upgradeable token;
        bool configured;
        uint88 startTime;
        Vault tokensProvider;
        uint96 endTime;
        BitMaps.BitMap claimed;
    }

    error AlreadyClaimed();
    error InvalidClaimTime();
    error InvalidProof();
}

interface IWaterFall is IWaterFallDef {}

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IVaultDef {
    event WithdrawEmergency(
        address indexed to,
        address erc20Token,
        uint256 erc20Amount,
        uint256 nativeAmount
    );
}

interface IVault is IVaultDef {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {INFTManager} from "src/interfaces/nft/INFTManager.sol";
import {IDegenNFTDefination} from "src/interfaces/nft/IDegenNFT.sol";
import {NFTManagerStorage} from "src/nft/NFTManagerStorage.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {DegenNFT} from "src/nft/DegenNFT.sol";
import {CommonError} from "src/lib/CommonError.sol";

contract NFTManager is
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    INFTManager,
    NFTManagerStorage,
    PausableUpgradeable
{
    uint256 public constant SUPPORT_MAX_MINT_COUNT = 2009;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    /**
     * @dev recieve native token
     */
    receive() external payable {}

    /**********************************************
     * write functions
     **********************************************/
    function initialize(address owner_) public initializer {
        if (owner_ == address(0)) {
            revert ZeroOwnerSet();
        }

        __Ownable_init(owner_);
        __Pausable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function whitelistMint(
        bytes32[] calldata merkleProof
    )
        public
        payable
        override
        whenNotPaused
        onlyStageTime(StageType.WhitelistMint)
    {
        if (hasMinted.get(uint160(msg.sender))) {
            revert AlreadyMinted();
        }

        if (degenNFT.totalMinted() >= SUPPORT_MAX_MINT_COUNT) {
            revert OutOfMaxMintCount();
        }

        if (msg.value < mintFee) {
            revert MintFeeNotEnough();
        }

        bool valid = checkWhiteList(merkleProof, msg.sender);

        if (!valid) {
            revert InvalidProof();
        }

        hasMinted.set(uint160(msg.sender));
        _mintTo(msg.sender, 1);
    }

    function publicMint(
        uint256 quantity
    )
        public
        payable
        override
        whenNotPaused
        onlyStageTime(StageType.PublicMint)
    {
        if (degenNFT.totalMinted() + quantity > SUPPORT_MAX_MINT_COUNT) {
            revert OutOfMaxMintCount();
        }

        if (quantity == 0) {
            revert InvalidParams();
        }

        if (msg.value < mintFee * quantity) {
            revert MintFeeNotEnough();
        }

        _mintTo(msg.sender, quantity);
    }

    function merge(
        uint256 tokenId1,
        uint256 tokenId2
    ) external override onlyStageTime(StageType.Merge) whenNotPaused {
        _checkOwner(msg.sender, tokenId1);
        _checkOwner(msg.sender, tokenId2);

        bool propertiEq = checkPropertiesEq(tokenId1, tokenId2);
        if (!propertiEq) {
            revert InvalidTokens();
        }

        // only shards can merge
        IDegenNFTDefination.Property memory property = degenNFT.getProperty(
            tokenId1
        );
        if (property.tokenType != uint16(1)) {
            revert OnlyShardsCanMerge();
        }

        degenNFT.burn(tokenId1);
        degenNFT.burn(tokenId2);

        uint256 tokenId = degenNFT.nextTokenId();

        _mintTo(msg.sender, 1);

        emit MergeTokens(msg.sender, tokenId1, tokenId2, tokenId);
        degenNFT.emitMetadataUpdate(tokenId);
    }

    function openMysteryBox(
        uint256[] calldata tokenIds,
        IDegenNFTDefination.Property[] calldata metadataList
    ) external onlySigner {
        if (tokenIds.length != metadataList.length) {
            revert InvalidParams();
        }
        for (uint256 i = 0; i < metadataList.length; i++) {
            degenNFT.setProperties(tokenIds[i], metadataList[i]);
        }
    }

    /**
     * @dev set only when nft is upgraded
     * @param tokenId nft tokenId
     * @param level new level
     */
    function setLevel(uint256 tokenId, uint256 level) external onlySigner {
        degenNFT.setLevel(tokenId, level);
    }

    function burn(
        uint256 tokenId
    ) external override onlyStageTime(StageType.Burn) whenNotPaused {
        if (!degenNFT.exists(tokenId)) {
            revert TokenIdNotExsis();
        }

        uint256 level = degenNFT.getLevel(tokenId);
        // level == 0 && not openMystoryBox
        if (level == 0) {
            if (tokenId <= SUPPORT_MAX_MINT_COUNT) {
                IDegenNFTDefination.Property memory token1Property = degenNFT
                    .getProperty(tokenId);
                if (token1Property.nameId == uint16(0)) {
                    revert MysteryBoxCannotBurn();
                }
            }
            level = 1;
        }

        _checkOwner(msg.sender, tokenId);

        degenNFT.burn(tokenId);

        // refund fees
        BurnRefundConfig memory refundConfig = burnRefundConfigs[level];

        // if no native token configuration
        // revert
        if (refundConfig.nativeToken == 0 && refundConfig.degenToken == 0) {
            revert NoBurnConfSet();
        }

        // refund NativeToken
        payable(msg.sender).transfer(refundConfig.nativeToken);

        emit BurnToken(
            msg.sender,
            tokenId,
            refundConfig.nativeToken,
            refundConfig.degenToken
        );
    }

    function updateSigners(
        address[] calldata toAdd,
        address[] calldata toRemove
    ) external onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], true);
        }

        for (uint256 i = 0; i < toRemove.length; i++) {
            signers[toRemove[i]] = false;
            emit SignerUpdate(toRemove[i], false);
        }
    }

    // set white list merkler tree root
    function setMerkleRoot(bytes32 root) external override onlyOwner {
        if (root == bytes32(0)) {
            revert ZeroRootSet();
        }

        merkleRoot = root;

        emit MerkleTreeRootSet(root);
    }

    function setMintFee(uint256 mintFee_) external onlyOwner {
        mintFee = mintFee_;

        emit MintFeeSet(mintFee);
    }

    function setDegenNFT(address degenNFT_) external onlyOwner {
        if (degenNFT_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }
        degenNFT = DegenNFT(degenNFT_);
        emit SetDegenNFT(degenNFT_);
    }

    function setMintTime(
        StageType mintType_,
        StageTime calldata mintTime_
    ) external onlyOwner {
        if (mintTime_.startTime >= mintTime_.endTime) {
            revert InvalidParams();
        }

        stageTime[mintType_] = mintTime_;

        emit SetMintTime(mintType_, mintTime_);
    }

    function setBurnRefundConfig(
        uint256[] calldata levels,
        BurnRefundConfig[] calldata configs
    ) external override onlyOwner {
        // burnRefundConfigs = configs;
        for (uint256 i = 0; i < configs.length; i++) {
            uint256 level = levels[i];
            BurnRefundConfig memory config = configs[i];
            burnRefundConfigs[level] = config;
            emit SetBurnRefundConfig(level, config);
        }
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    /**********************************************
     * read functions
     **********************************************/

    function checkWhiteList(
        bytes32[] calldata merkleProof,
        address account
    ) public view returns (bool valid) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account))));
        valid = MerkleProofUpgradeable.verify(merkleProof, merkleRoot, leaf);
    }

    function getBurnRefundConfigs(
        uint256 level
    ) public view returns (BurnRefundConfig memory) {
        return burnRefundConfigs[level];
    }

    function minted(address account) external view returns (bool) {
        return hasMinted.get(uint160(account));
    }

    /**********************************************
     * internal functions
     **********************************************/
    function _mintTo(address to, uint256 quantity) internal {
        uint256 startTokenId = degenNFT.nextTokenId();
        degenNFT.mint(to, quantity);

        emit Minted(msg.sender, quantity, startTokenId);
    }

    function _checkOwner(address owner_, uint256 tokenId) internal view {
        if (degenNFT.ownerOf(tokenId) != owner_) {
            revert NotTokenOwner();
        }
    }

    function _checkStageTime(StageType stageType) internal view {
        if (
            block.timestamp < stageTime[stageType].startTime ||
            block.timestamp > stageTime[stageType].endTime
        ) {
            revert InvalidTime();
        }
    }

    // only name && tokenType equal means token1 and token2 can merge
    function checkPropertiesEq(
        uint256 tokenId1,
        uint256 tokenId2
    ) public view returns (bool) {
        IDegenNFTDefination.Property memory token1Property = degenNFT
            .getProperty(tokenId1);
        IDegenNFTDefination.Property memory token2Property = degenNFT
            .getProperty(tokenId2);

        return
            token1Property.nameId == token2Property.nameId &&
            token1Property.tokenType == token2Property.tokenType;
    }

    /**********************************************
     * modiriers
     **********************************************/
    modifier onlySigner() {
        if (!signers[msg.sender]) {
            revert NotSigner();
        }
        _;
    }

    modifier onlyStageTime(StageType stageType) {
        _checkStageTime(stageType);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface INFTManagerDefination {
    enum StageType {
        Invalid,
        WhitelistMint,
        PublicMint,
        Merge,
        Burn
    }
    struct StageTime {
        uint256 startTime;
        uint256 endTime; // mint end time,if no need set 4294967295(2106-02-07 14:28:15)
    }

    struct BurnRefundConfig {
        uint256 nativeToken;
        uint256 degenToken;
    }

    /**********************************************
     * errors
     **********************************************/
    error ZeroOwnerSet();
    error NotSigner();
    error OutOfMaxMintCount();
    error AlreadyMinted();
    error ZeroRootSet();
    error InvalidProof();
    error NotTokenOwner();
    error InvalidTokens();
    error MintFeeNotEnough();
    error InvalidParams();
    error InvalidTime();
    error TokenIdNotExsis();
    error MysteryBoxCannotBurn();
    error OnlyShardsCanMerge();
    error CanNotOpenMysteryBoxTwice();
    error NoBurnConfSet();


    /**********************************************
     * events
     **********************************************/
    event Minted(
        address indexed receiver,
        uint256 quantity,
        uint256 startTokenId
    );
    event SignerUpdate(address indexed signer, bool valid);
    event MerkleTreeRootSet(bytes32 root);
    // burn the tokenId of from account
    event MergeTokens(
        address indexed from,
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 newTokenId
    );
    event BurnToken(
        address account,
        uint256 tokenId,
        uint256 refundNativeToken,
        uint256 refundDegenToken
    );
    event SetDegenNFT(address degenNFT);
    event MintFeeSet(uint256 mintFee);
    event SetMintTime(StageType stageType, StageTime stageTime);
    event SetBurnRefundConfig(
        uint256 level,
        BurnRefundConfig burnRefundConfigs
    );
    event SetBucket(uint256 bucket, uint256 bucketValue);
}

interface INFTManager is INFTManagerDefination {
    /**
     * @dev users in whitelist can mint mystery box
     */
    function whitelistMint(bytes32[] calldata merkleProof) external payable;

    /**
     * public mint
     * @param quantity quantities want to mint
     */
    function publicMint(uint256 quantity) external payable;

    function merge(uint256 tokenId1, uint256 tokenId2) external;

    function burn(uint256 tokenId) external;

    function setMerkleRoot(bytes32 root) external;

    function setBurnRefundConfig(
        uint256[] calldata levels,
        BurnRefundConfig[] calldata configs
    ) external;

    function withdraw(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {IERC4906} from "src/interfaces/nft/IERC4906.sol";
import {IERC2981} from "src/interfaces/nft/IERC2981.sol";

interface IDegenNFTDefination is IERC4906 {
    struct Property {
        uint16 nameId;
        uint16 rarity;
        uint16 tokenType;
    }

    error OnlyManager();

    event SetManager(address manager);
    event SetBaseURI(string baseURI);
    event RoyaltyInfoSet(address receiver, uint256 percent);
    event SetProperties(uint256 tokenId, Property properties);
    event LevelSet(uint256 indexed tokenId, uint256 level);
}

interface IDegenNFT is IDegenNFTDefination, IERC2981 {
    function mint(address to, uint256 quantity) external;

    function burn(uint256 tokenId) external;

    function setBaseURI(string calldata baseURI_) external;

    function setLevel(uint256 tokenId, uint256 level) external;

    function setProperties(
        uint256 tokenId,
        Property memory _properties
    ) external;

    function totalMinted() external view returns (uint256);

    function getProperty(
        uint256 tokenId
    ) external view returns (Property memory);

    function exists(uint256 tokenId) external view returns (bool);

    function nextTokenId() external view returns (uint256);

    function getLevel(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {INFTManagerDefination} from "src/interfaces/nft/INFTManager.sol";
import {IDegenNFTDefination} from "src/interfaces/nft/IDegenNFT.sol";

import {DegenNFT} from "src/nft/DegenNFT.sol";

contract NFTManagerStorage is INFTManagerDefination {
    // degen nft address
    DegenNFT public degenNFT;

    // white list merkle tree root
    bytes32 public merkleRoot;

    mapping(address => bool) public signers;

    // record minted users to avoid whitelist users mint more than once
    // mapping(address => bool) public minted;
    BitMapsUpgradeable.BitMap internal hasMinted;

    // Mapping from mint type to mint start and end time
    mapping(StageType => StageTime) stageTime;

    // different config with different level, index as level
    mapping(uint256 => BurnRefundConfig) internal burnRefundConfigs;

    // public mint pay mint fee
    uint256 public mintFee;

    uint256[43] private _gap;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IDegenNFT} from "src/interfaces/nft/IDegenNFT.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";

import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import {CommonError} from "src/lib/CommonError.sol";

contract DegenNFT is
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    ERC721AUpgradeable,
    IDegenNFT
{
    uint256 public constant PERCENTAGE_BASE = 10000;

    // Mapping from tokenId to Property
    mapping(uint256 => uint256) internal properties;

    // NFTManager
    address public manager;

    string public baseURI;

    // Mapping tokenId to level
    // bucket => value
    mapping(uint256 => uint256) internal levelBucket;

    address _royaltyReceiver; //   ---|
    uint96 _royaltyPercentage; //  ---|

    uint256[45] private _gap;

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function initialize(
        string calldata name_,
        string calldata symbol_,
        address owner_ // upgrade owner
    ) public initializerERC721A initializer {
        __ERC721A_init(name_, symbol_);
        __Ownable_init_unchained(owner_);
    }

    function mint(address to, uint256 quantity) external onlyManager {
        _mint(to, quantity);
    }

    function burn(uint256 tokenId) external onlyManager {
        _burn(tokenId);
    }

    function setManager(address manager_) external onlyOwner {
        if (manager_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }
        manager = manager_;

        emit SetManager(manager_);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;

        emit SetBaseURI(baseURI_);
    }

    function setProperties(
        uint256 tokenId,
        Property memory property_
    ) external onlyManager {
        // encode property
        uint16 property = encodeProperty(property_);
        // storage property
        uint256 bucket = (tokenId - 1) >> 4;
        uint256 pos = (tokenId - 1) % 16;
        uint256 mask = uint256(property) << (pos * 16);
        uint256 data = properties[bucket];
        // clear the data on the tokenId pos
        data &= ~(uint256(type(uint16).max) << (pos * 16));
        properties[bucket] = data | mask;

        emit SetProperties(tokenId, property_);
        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev emit ERC4906 event to trigger all metadata update
     */
    function emitMetadataUpdate() external {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function emitMetadataUpdate(uint256 tokenId) external {
        emit MetadataUpdate(tokenId);
    }

    function setBucket(
        uint256 bucket,
        uint256 compactData
    ) external onlyManager {
        properties[bucket] = compactData;
    }

    function setLevel(uint256 tokenId, uint256 level) external onlyManager {
        uint256 bucket = (tokenId - 1) >> 5;
        uint256 pos = (tokenId - 1) % 32;
        uint256 mask = level << (pos * 8);
        uint256 data = levelBucket[bucket];
        // clear the data on the tokenId pos
        data &= ~(uint256(type(uint8).max) << (pos * 8));
        levelBucket[bucket] = data | mask;

        emit LevelSet(tokenId, level);
    }

    /**
     * @dev set royaly info manually
     * @param receiver receiver address
     * @param percent  percent with 10000 percentBase
     */
    function setRoyaltyInfo(
        address receiver,
        uint96 percent
    ) external onlyOwner {
        _royaltyReceiver = receiver;
        _royaltyPercentage = percent;

        emit RoyaltyInfoSet(receiver, percent);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function encodeProperty(
        Property memory property_
    ) public pure returns (uint16 property) {
        property = (property << 12) | property_.nameId;
        property = (property << 3) | property_.rarity;
        property = (property << 1) | property_.tokenType;
    }

    function decodeProperty(
        uint16 property
    ) public pure returns (uint16 nameId, uint16 rarity, uint16 tokenType) {
        nameId = (property >> 4) & 0x0fff;
        rarity = (property >> 1) & 0x07;
        tokenType = property & 0x01;
    }

    function getProperty(
        uint256 tokenId
    ) external view returns (Property memory) {
        uint256 bucket = (tokenId - 1) >> 4;
        uint256 compactData = properties[bucket];
        uint16 property = uint16(
            (compactData >> (((tokenId - 1) % 16) * 16)) & 0xffff
        );

        (uint16 nameId, uint16 rarity, uint16 tokenType) = decodeProperty(
            property
        );

        return Property({nameId: nameId, rarity: rarity, tokenType: tokenType});
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return string.concat(super.tokenURI(tokenId), ".json");
    }

    /**
     * @dev royalty info
     * @param tokenId NFT tokenId but it's not related with tokenId
     * @param salePrice sale price
     * @return receiver
     * @return royaltyAmount
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = _royaltyReceiver;
        royaltyAmount =
            (salePrice * uint256(_royaltyPercentage)) /
            PERCENTAGE_BASE;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == 0x2a55205a; // ERC165 interface ID ERC2981  Royalty
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function nextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    function getLevel(uint256 tokenId) external view returns (uint256) {
        uint256 bucket = (tokenId - 1) >> 5;
        uint256 compactData = levelBucket[bucket];
        uint256 level = uint8(
            (compactData >> (((tokenId - 1) % 32) * 8)) & 0xff
        );
        return level;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // tokenId start from 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _checkManager() internal view {
        if (msg.sender != manager) {
            revert OnlyManager();
        }
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/// @title EIP-721 Metadata Update Extension
interface IERC4906 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRewardDistributor} from "src/interfaces/IRewardDistributor.sol";

contract RewardDistributor is IRewardDistributor, Ownable {
    using BitMaps for BitMaps.BitMap;

    bytes32 public merkleRoot;
    uint256 public claimPeriodEnds;
    BitMaps.BitMap private claimed;

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    /**
     * @dev Claims airdropped tokens.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (block.timestamp >= claimPeriodEnds) {
            revert ClaimPeriodNotStartOrEnd();
        }

        if (amount > (address(this)).balance) {
            revert AmountExceedBalance();
        }

        // bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, amount)))
        );
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }
        if (isClaimed(uint160(_msgSender()))) {
            revert AlreadyClaimed();
        }

        claimed.set(uint160(_msgSender()));
        payable(msg.sender).transfer(amount);
        emit Claim(msg.sender, amount);
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param index The index into the merkle tree.
     */
    function isClaimed(uint256 index) public view returns (bool) {
        return claimed.get(index);
    }

    /**
     * @dev Sets the merkle root.
     * @param newMerkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        if (merkleRoot != bytes32(0)) {
            revert RootSetTwice();
        }
        if (newMerkleRoot == bytes32(0)) {
            revert ZeroRootSet();
        }
        merkleRoot = newMerkleRoot;
        emit MerkleRootChanged(merkleRoot);
    }

    /**
     * @dev Sets the claim period ends.
     * @param claimPeriodEnds_ The merkle root to set.
     */
    function setClaimPeriodEnds(uint256 claimPeriodEnds_) external onlyOwner {
        if (claimPeriodEnds_ <= block.timestamp) {
            revert InvalidTimestap();
        }
        claimPeriodEnds = claimPeriodEnds_;
        emit ClaimPeriodEndsChanged(claimPeriodEnds);
    }

    /**
     * @dev withdraw remaining native tokens.
     */
    function withdraw(address to) external onlyOwner {
        uint256 balance = (address(this)).balance;
        payable(to).transfer(balance);
        emit WithDrawn(to, balance);
    }

    /**
     * @dev receive native token as reward
     */
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

interface IRewardDistributorDef {
    error ZeroAddressSet();
    error ClaimPeriodNotStartOrEnd();
    error AmountExceedBalance();
    error InvalidProof();
    error AlreadyClaimed();
    error RootSetTwice();
    error ZeroRootSet();
    error InvalidTimestap();

    event Claim(address indexed claimant, uint256 amount);
    event ClaimNativeAndERC20(
        address indexed claimant,
        uint256 nativeAmount,
        uint256 Erc20Amount
    );

    event MerkleRootChanged(bytes32 merkleRoot);
    event ClaimPeriodEndsChanged(uint256 claimPeriodEnds);
    event WithDrawn(address dest, uint256 amount);
    event WithDrawnNativeAndERC20(
        address dest,
        uint256 nativeAmount,
        uint256 Erc20Amount
    );
}

interface IRewardDistributor is IRewardDistributorDef {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRewardDistributor} from "src/interfaces/IRewardDistributor.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeOwnable} from "@p12/contracts-lib/contracts/access/SafeOwnable.sol";

contract RewardNativeAndERC20Distributor is IRewardDistributor, SafeOwnable {
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;
    uint256 public claimPeriodEnds;
    BitMaps.BitMap private claimed;
    IERC20 public immutable rewardToken;

    constructor(address owner_, IERC20 rewardToken_) SafeOwnable(owner_) {
        if (owner_ == address(0) || address(rewardToken_) == address(0)) {
            revert ZeroAddressSet();
        }
        rewardToken = rewardToken_;
    }

    /**
     * @dev Claims airdropped tokens.
     * @param nativeAmount The native amount of the claim being made.
     * @param erc20Amount The erc20 amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(
        uint256 nativeAmount,
        uint256 erc20Amount,
        bytes32[] calldata merkleProof
    ) external {
        if (block.timestamp >= claimPeriodEnds) {
            revert ClaimPeriodNotStartOrEnd();
        }

        if (nativeAmount > (address(this)).balance) {
            revert AmountExceedBalance();
        }

        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(abi.encode(msg.sender, erc20Amount, nativeAmount))
            )
        );

        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }

        if (isClaimed(_msgSender())) {
            revert AlreadyClaimed();
        }

        claimed.set(uint160(_msgSender()));
        payable(msg.sender).transfer(nativeAmount);
        rewardToken.safeTransfer(msg.sender, erc20Amount);
        emit ClaimNativeAndERC20(msg.sender, nativeAmount, erc20Amount);
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param account whether the account is claimed
     */
    function isClaimed(address account) public view returns (bool) {
        return claimed.get(uint256(uint160(account)));
    }

    /**
     * @dev Sets the merkle root.
     * @param newMerkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        if (merkleRoot != bytes32(0)) {
            revert RootSetTwice();
        }
        if (newMerkleRoot == bytes32(0)) {
            revert ZeroRootSet();
        }
        merkleRoot = newMerkleRoot;
        emit MerkleRootChanged(merkleRoot);
    }

    /**
     * @dev Sets the claim period ends.
     * @param claimPeriodEnds_ The merkle root to set.
     */
    function setClaimPeriodEnds(uint256 claimPeriodEnds_) external onlyOwner {
        if (claimPeriodEnds_ <= block.timestamp) {
            revert InvalidTimestap();
        }
        claimPeriodEnds = claimPeriodEnds_;
        emit ClaimPeriodEndsChanged(claimPeriodEnds);
    }

    /**
     * @dev withdraw remaining native tokens.
     */
    function withdraw(address to) external onlyOwner {
        uint256 nativeBalance = (address(this)).balance;
        uint256 erc20Balance = rewardToken.balanceOf(address(this));
        payable(to).transfer(nativeBalance);
        rewardToken.safeTransfer(to, erc20Balance);
        emit WithDrawnNativeAndERC20(to, nativeBalance, erc20Balance);
    }

    /**
     * @dev receive native token as reward
     */
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// Thanks Yos Riady
// Refer to https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

contract SafeOwnable is Context {
    error CallerNotOwner();
    error ZeroAddressOwnerSet();
    error CallerNotPendingOwner();
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Return the address of the pending owner
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner() != _msgSender()) {
            revert CallerNotOwner();
        }
        _;
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
     * Note If direct is false, it will set an pending owner and the OwnerShipTransferring
     * only happens when the pending owner claim the ownership
     */
    function transferOwnership(
        address newOwner,
        bool direct
    ) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressOwnerSet();
        }
        if (direct) {
            _transferOwnership(newOwner);
        } else {
            _transferPendingOwnership(newOwner);
        }
    }

    /**
     * @dev pending owner call this function to claim ownership
     */
    function claimOwnership() public {
        if (msg.sender != _pendingOwner) {
            revert CallerNotPendingOwner();
        }
        _claimOwnership();
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
     * @dev set the pending owner address
     * Internal function without access restriction.
     */
    function _transferPendingOwnership(address newOwner) internal virtual {
        _pendingOwner = newOwner;
    }

    /**
     * @dev claim ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _claimOwnership() internal virtual {
        address oldOwner = _owner;
        emit OwnershipTransferred(oldOwner, _pendingOwner);

        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@p12/contracts-lib/contracts/access/SafeOwnable.sol";

import "src/interfaces/IRewardDistributor.sol";

contract RewardERC20Distributor is IRewardDistributor, SafeOwnable {
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;
    IERC20 public immutable rewardToken;
    uint256 public claimPeriodEnds;
    BitMaps.BitMap private claimed;

    constructor(address owner_, IERC20 rewardToken_) SafeOwnable(owner_) {
        if (owner_ == address(0) || address(rewardToken_) == address(0)) {
            revert ZeroAddressSet();
        }
        rewardToken = rewardToken_;
    }

    /**
     * @dev Claims airdropped tokens.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (block.timestamp >= claimPeriodEnds) {
            revert ClaimPeriodNotStartOrEnd();
        }

        if (amount > rewardToken.balanceOf(address(this))) {
            revert AmountExceedBalance();
        }

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, amount)))
        );
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }
        if (isClaimed(_msgSender())) {
            revert AlreadyClaimed();
        }

        claimed.set(uint160(_msgSender()));
        rewardToken.safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param account address of account
     */
    function isClaimed(address account) public view returns (bool) {
        return claimed.get(uint160(account));
    }

    /**
     * @dev Sets the merkle root.
     * @param newMerkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        if (merkleRoot != bytes32(0)) {
            revert RootSetTwice();
        }
        if (newMerkleRoot == bytes32(0)) {
            revert ZeroRootSet();
        }
        merkleRoot = newMerkleRoot;
        emit MerkleRootChanged(merkleRoot);
    }

    /**
     * @dev Sets the claim period ends.
     * @param claimPeriodEnds_ The merkle root to set.
     */
    function setClaimPeriodEnds(uint256 claimPeriodEnds_) external onlyOwner {
        if (claimPeriodEnds_ <= block.timestamp) {
            revert InvalidTimestap();
        }
        claimPeriodEnds = claimPeriodEnds_;
        emit ClaimPeriodEndsChanged(claimPeriodEnds);
    }

    /**
     * @dev withdraw remaining native tokens.
     */
    function withdraw(address to) external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(to, balance);
        emit WithDrawn(to, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../OFTCore.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ProxyOFT is OFTCore {
    using SafeERC20 for IERC20;

    IERC20 internal immutable innerToken;

    constructor(address _lzEndpoint, address _token) OFTCore(_lzEndpoint) {
        innerToken = IERC20(_token);
    }

    function circulatingSupply() public view virtual override returns (uint) {
        unchecked {
            return innerToken.totalSupply() - innerToken.balanceOf(address(this));
        }
    }

    function token() public view virtual override returns (address) {
        return address(innerToken);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _amount) internal virtual override returns(uint) {
        require(_from == _msgSender(), "ProxyOFT: owner is not send caller");
        uint before = innerToken.balanceOf(address(this));
        innerToken.safeTransferFrom(_from, address(this), _amount);
        return innerToken.balanceOf(address(this)) - before;
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override returns(uint) {
        uint before = innerToken.balanceOf(_toAddress);
        innerToken.safeTransfer(_toAddress, _amount);
        return innerToken.balanceOf(_toAddress) - before;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../lzApp/NonblockingLzApp.sol";
import "./IOFTCore.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract OFTCore is NonblockingLzApp, ERC165, IOFTCore {
    using BytesLib for bytes;

    uint public constant NO_EXTRA_GAS = 0;

    // packet type
    uint16 public constant PT_SEND = 0;

    bool public useCustomAdapterParams;

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOFTCore).interfaceId || super.supportsInterface(interfaceId);
    }

    function estimateSendFee(uint16 _dstChainId, bytes calldata _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        // mock the payload for sendFrom()
        bytes memory payload = abi.encode(PT_SEND, _toAddress, _amount);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function sendFrom(address _from, uint16 _dstChainId, bytes calldata _toAddress, uint _amount, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _amount, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) public virtual onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        uint16 packetType;
        assembly {
            packetType := mload(add(_payload, 32))
        }

        if (packetType == PT_SEND) {
            _sendAck(_srcChainId, _srcAddress, _nonce, _payload);
        } else {
            revert("OFTCore: unknown packet type");
        }
    }

    function _send(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _amount, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual {
        _checkAdapterParams(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        uint amount = _debitFrom(_from, _dstChainId, _toAddress, _amount);

        bytes memory lzPayload = abi.encode(PT_SEND, _toAddress, amount);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _sendAck(uint16 _srcChainId, bytes memory, uint64, bytes memory _payload) internal virtual {
        (, bytes memory toAddressBytes, uint amount) = abi.decode(_payload, (uint16, bytes, uint));

        address to = toAddressBytes.toAddress(0);

        amount = _creditTo(_srcChainId, to, amount);
        emit ReceiveFromChain(_srcChainId, to, amount);
    }

    function _checkAdapterParams(uint16 _dstChainId, uint16 _pkType, bytes memory _adapterParams, uint _extraGas) internal virtual {
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, _pkType, _adapterParams, _extraGas);
        } else {
            require(_adapterParams.length == 0, "OFTCore: _adapterParams must be empty.");
        }
    }

    function _debitFrom(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _amount) internal virtual returns(uint);

    function _creditTo(uint16 _srcChainId, address _toAddress, uint _amount) internal virtual returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft(), 150, abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload));
        // try-catch all errors/exceptions
        if (!success) {
            _storeFailedMessage(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function _storeFailedMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload, bytes memory _reason) internal virtual {
        failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTCore is IERC165 {
    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(uint16 _dstChainId, bytes calldata _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address _from, uint16 _dstChainId, bytes calldata _toAddress, uint _amount, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint);

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view returns (address);

    /**
     * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce
     */
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes _toAddress, uint _amount);

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     * `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, address indexed _to, uint _amount);

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    // ua can not send payload larger than this by default, but it can be changed by the ua owner
    uint constant public DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint)) public minDstGasLookup;
    mapping(uint16 => uint) public payloadSizeLimitLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && trustedRemote.length > 0 && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams, uint _nativeFee) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        _checkPayloadSize(_dstChainId, _payload.length);
        lzEndpoint.send{value: _nativeFee}(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _checkGasLimit(uint16 _dstChainId, uint16 _type, bytes memory _adapterParams, uint _extraGas) internal view virtual {
        uint providedGasLimit = _getGasLimit(_adapterParams);
        uint minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function _checkPayloadSize(uint16 _dstChainId, uint _payloadSize) internal view virtual {
        uint payloadSizeLimit = payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) { // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        require(_payloadSize <= payloadSizeLimit, "LzApp: payload size is too large");
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16 _version, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _path;
        emit SetTrustedRemote(_srcChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LzApp: no trusted path record");
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint _minGas) external onlyOwner {
        require(_minGas > 0, "LzApp: invalid minGas");
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // if the size is 0, it means default size limit
    function setPayloadSizeLimit(uint16 _dstChainId, uint _size) external onlyOwner {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
            _gas, // gas
            _target, // recipient
            0, // ether value
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
            _gas, // gas
            _target, // recipient
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
    internal
    pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
        // load the first word of
            let _word := mload(add(_buf, 0x20))
        // mask out the top 4 bytes
        // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
    internal
    pure
    returns (bytes memory)
    {
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
            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31) // Round down to the nearest 32 bytes.
            ))
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
                and(
                fslot,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ),
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
                let mlengthmod := mod(mlength, 32)
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

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
    internal
    pure
    returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

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
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
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

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
    internal
    view
    returns (bool)
    {
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
                        for {} eq(add(lt(mc, end), cb), 2) {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ProxyOFT} from "lib/solidity-examples/contracts/token/oft/extension/ProxyOFT.sol";
import {RBT} from "src/RBT.sol";

contract ProxyMintableDegenOFT is ProxyOFT {
    constructor(
        address _lzEndpoint,
        address _token
    ) ProxyOFT(_lzEndpoint, _token) {}

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint _amount
    ) internal virtual override returns (uint) {
        RBT(address(innerToken)).burnFrom(_from, _amount);
        return _amount;
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint _amount
    ) internal virtual override returns (uint) {
        RBT(address(innerToken)).mint(_toAddress, _amount);
        return _amount;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "lib/solidity-examples/contracts/token/oft/extension/ProxyOFT.sol";

contract ProxyDegenOFT is ProxyOFT {
    constructor(
        address _lzEndpoint,
        address _token
    ) ProxyOFT(_lzEndpoint, _token) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IBurnPool} from "src/interfaces/IBurnPool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RBT} from "./RBT.sol";

contract BurnPool is IBurnPool, Ownable {
    RBT rebornToken;

    constructor(address owner_, address rebornToken_) {
        if (owner_ == address(0)) {
            revert ZeroOwnerSet();
        }

        if (rebornToken_ == address(0)) {
            revert ZeroRebornTokenSet();
        }

        _transferOwnership(owner_);
        rebornToken = RBT(rebornToken_);
    }

    function burn(uint256 amount) external override onlyOwner {
        rebornToken.burn(amount);

        emit Burn(amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "./FastArray.sol";
import "./RankingRedBlackTree.sol";

library SingleRanking {
    using FastArray for FastArray.Data;
    using RankingRedBlackTree for RankingRedBlackTree.Tree;

    struct Data {
        RankingRedBlackTree.Tree tree;
        mapping(uint => FastArray.Data) keys;
        uint length;
    }

    function add(Data storage _singleRanking, uint _key, uint _value) public {
        FastArray.Data storage keys = _singleRanking.keys[_value];

        if (FastArray.length(keys) == 0) {
            _singleRanking.tree.insert(_value);
        } else {
            _singleRanking.tree.addToCount(_value, 1);
        }

        _singleRanking.keys[_value].insert(_key);

        _singleRanking.length += 1;
    }

    function remove(
        Data storage _singleRanking,
        uint _key,
        uint _value
    ) public {
        FastArray.Data storage keys = _singleRanking.keys[_value];

        if (FastArray.length(keys) > 0) {
            keys.remove(_key);

            if (FastArray.length(keys) == 0) {
                _singleRanking.tree.remove(_value);
            } else {
                _singleRanking.tree.minusFromCount(_value, 1);
            }
        }
        // if FastArray.length(keys) is zero, it means logic error and should revert
        // but no revert here to reduce gas. use remove with caution

        _singleRanking.length -= 1;
    }

    function length(Data storage _singleRanking) public view returns (uint) {
        return _singleRanking.length;
    }

    function get(
        Data storage _singleRanking,
        uint _offset,
        uint _count
    ) public view returns (uint[] memory) {
        require(_count > 0 && _count <= 100, "Count must be between 0 and 100");

        uint[] memory result = new uint[](_count);
        uint size = 0;
        uint id;
        (id, _offset) = _singleRanking.tree.lastByOffset(_offset);

        while (id != 0) {
            uint value = _singleRanking.tree.value(id);
            FastArray.Data storage keys = _singleRanking.keys[value];

            if (_offset >= FastArray.length(keys)) {
                unchecked {
                    _offset -= FastArray.length(keys);
                }
            } else if (FastArray.length(keys) < _offset + _count) {
                uint index;
                unchecked {
                    index = FastArray.length(keys) - 1;
                }
                while (index >= _offset) {
                    uint key = keys.get(index);

                    unchecked {
                        result[size] = key;
                        size += 1;
                    }
                    if (index == 0) {
                        break;
                    }

                    unchecked {
                        index -= 1;
                    }
                }

                unchecked {
                    _count -= FastArray.length(keys) - _offset;
                    _offset = 0;
                }
            } else {
                uint index;
                unchecked {
                    index = _offset + _count - 1;
                }
                while (index >= _offset) {
                    uint key = keys.get(index);

                    result[size] = key;
                    unchecked {
                        size += 1;
                    }

                    if (index == 0) {
                        break;
                    }

                    unchecked {
                        index -= 1;
                    }
                }

                break;
            }

            id = _singleRanking.tree.prev(id);
        }

        return result;
    }

    function getNthValue(
        Data storage _singleRanking,
        uint n
    ) public view returns (uint) {
        (uint256 id, ) = _singleRanking.tree.lastByOffset(n);
        uint value = _singleRanking.tree.value(id);
        return value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// A red-black tree that holds a "count" variable next to the value in the tree.
// This library is used to resolve which values should be skipped to respect the _offset when querying from the rank library.
// The focal function is "lastByOffset" which starts from the largest value in the tree and traverses backwards to find the
// first value that is included in the offset specified and returns it.
// The nodes are accessed by a key and other properties can be queried using the key.
// This library is a modification of BokkyPooBah's Red-Black Tree Library which has a MIT licence.
// Following is the original description and the license:
// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------
// Here is the license attached to this library:
// ----------------------------------------------------------------------------
// MIT License
//
// Copyright (c) 2018 The Officious BokkyPooBah
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ----------------------------------------------------------------------------
library RankingRedBlackTree {
    struct Node {
        uint id;
        uint value;
        uint count;
        uint parent;
        uint left;
        uint right;
        bool red;
    }

    struct Tree {
        uint root;
        mapping(uint => Node) nodes;
        uint counter;
    }

    uint private constant EMPTY = 0;

    function first(Tree storage self) public view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }

    function last(Tree storage self) public view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }

    function lastByOffset(
        Tree storage self,
        uint _offset
    ) public view returns (uint, uint) {
        uint key = last(self);

        while (key != EMPTY && _offset > self.nodes[key].count) {
            unchecked {
                _offset -= self.nodes[key].count;
            }
            key = prev(self, key);
        }

        return (key, _offset);
    }

    function next(
        Tree storage self,
        uint target
    ) public view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function prev(
        Tree storage self,
        uint target
    ) public view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function find(Tree storage self, uint _value) public view returns (uint) {
        uint probe = self.root;
        while (probe != EMPTY) {
            if (_value == self.nodes[probe].value) {
                return probe;
            }
            if (_value < self.nodes[probe].value) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        return EMPTY;
    }

    function value(Tree storage self, uint _key) public view returns (uint) {
        return self.nodes[_key].value;
    }

    function addToCount(Tree storage self, uint _value, uint amount) public {
        self.nodes[find(self, _value)].count += amount;
    }

    function minusFromCount(
        Tree storage self,
        uint _value,
        uint amount
    ) public {
        self.nodes[find(self, _value)].count -= amount;
    }

    function insert(Tree storage self, uint _value) public returns (uint) {
        uint cursor = EMPTY;
        uint probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (_value < self.nodes[probe].value) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.counter += 1;
        self.nodes[self.counter] = Node({
            id: self.counter,
            value: _value,
            count: 1,
            parent: cursor,
            left: EMPTY,
            right: EMPTY,
            red: true
        });
        if (cursor == EMPTY) {
            self.root = self.counter;
        } else if (_value < self.nodes[cursor].value) {
            self.nodes[cursor].left = self.counter;
        } else {
            self.nodes[cursor].right = self.counter;
        }
        insertFixup(self, self.counter);
        return self.counter;
    }

    function remove(Tree storage self, uint _value) public {
        uint key = find(self, _value);
        uint probe;
        uint cursor; // TODO
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];
    }

    function removeWithKey(Tree storage self, uint key) public {
        uint probe;
        uint cursor; // TODO
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];
    }

    function treeMinimum(
        Tree storage self,
        uint key
    ) private view returns (uint) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }

    function treeMaximum(
        Tree storage self,
        uint key
    ) private view returns (uint) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].right;
        uint keyParent = self.nodes[key].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }

    function rotateRight(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].left;
        uint keyParent = self.nodes[key].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                        key = keyParent;
                        rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                        key = keyParent;
                        rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(Tree storage self, uint a, uint b) private {
        uint bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }

    function removeFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (
                    !self.nodes[self.nodes[cursor].left].red &&
                    !self.nodes[self.nodes[cursor].right].red
                ) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (
                    !self.nodes[self.nodes[cursor].right].red &&
                    !self.nodes[self.nodes[cursor].left].red
                ) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}