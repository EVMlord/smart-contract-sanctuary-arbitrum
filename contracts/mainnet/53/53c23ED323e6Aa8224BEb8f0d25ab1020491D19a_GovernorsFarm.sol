// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity >=0.6.11;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "./Context.sol";
import "./SafeMath.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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
pragma solidity ^0.8.18;

import "communal/SafeERC20.sol";
import "communal/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

// ================================================================
// |██╗   ██╗███╗   ██╗███████╗██╗  ██╗███████╗████████╗██╗  ██╗
// |██║   ██║████╗  ██║██╔════╝██║  ██║██╔════╝╚══██╔══╝██║  ██║
// |██║   ██║██╔██╗ ██║███████╗███████║█████╗     ██║   ███████║
// |██║   ██║██║╚██╗██║╚════██║██╔══██║██╔══╝     ██║   ██╔══██║
// |╚██████╔╝██║ ╚████║███████║██║  ██║███████╗   ██║   ██║  ██║
// | ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝
// ================================================================
// ======================= GovernorsFarm =+++======================
// ================================================================
// Allows vdUSH users to enter the matrix and receive USH rewards
// Users can claim their rewards at any time
// No staking needed, just enter the matrix and claim rewards
// No user deposits held in this contract!
// ================================================================
// Arbitrum Farm also allows claiming of GRAIL / xGRAIL rewards
// ================================================================
// Author: unshETH team (github.com/unsheth)
// Heavily inspired by StakingRewards, MasterChef
//

interface IxGrail is IERC20 {
    function convertTo(uint amount, address to) external;
}

interface IvdUSH {
    function totalSupply() external view returns(uint);
    function balanceOf(address account) external view returns(uint);
    function deposit_for(address _addr, uint _valueA, uint _valueB, uint _valueC) external;
    function balanceOfAtT(address account, uint ts) external view returns(uint);
    function totalSupplyAtT(uint t) external view returns(uint);
    function user_point_epoch(address account) external view returns(uint);
    function user_point_history__ts(address _addr, uint _idx) external view returns (uint);
}

contract GovernorsFarm is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public constant USH = IERC20(0x51A80238B5738725128d3a3e06Ab41c1d4C05C74);
    IvdUSH public constant vdUsh = IvdUSH(0x69E3877a2A81345BAFD730e3E3dbEF74359988cA);
    IERC20 public constant GRAIL = IERC20(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    IxGrail public constant xGRAIL = IxGrail(0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b);
    
    uint public vdUshPercentage = 80e18; //percentage of rewards to lock as vdUSH
    uint public xGrailPercentage = 80e18; //percentage of GRAIL rewards to lock as xGRAIL

    //check if an address has entered the matrix
    mapping(address => bool) public isInMatrix;
    address[] public users; //array of users in the matrix

    uint public totalSupplyMultiplier = 1e18; //total supply multiplier to adjust for vdush total supply calc on bnb chain
    uint public ushPerSec;
    uint public grailPerSec;
    uint public startTime;

    mapping(address => uint) public lastClaimTimestamp;
    mapping(address => uint) public lastClaimVdUshBalance;
    mapping(address => uint) public lastClaimTotalSupply;
    mapping(address => bool) public isBlocked; //if a user is blocked from claiming rewards

    uint internal constant WEEK = 1 weeks;

    event MatrixEntered(address indexed _user);
    event RewardsClaimed(address indexed _user, uint _ushClaimed, uint _vdUSHClaimed, uint _grailClaimed, uint _xGrailClaimed);
    event RewardRateUpdated(uint _ushPerSec, uint _grailPerSec);
    event TotalSupplyMultiplierUpdated(uint _totalSupplyMultiplier);
    event LockPercentageUpdated(uint _vdUshLockPercentage, uint _xGrailLockPercentage);
    event BlockListUpdated(address indexed _user, bool _isBlocked);
    event FarmStarted(uint _ushPerSec, uint _grailPerSec, uint _startTime);

    //Constructor
    constructor() {
        USH.approve(address(vdUsh), type(uint).max); //for locking on behalf of users
        GRAIL.approve(address(xGRAIL), type(uint).max); //for locking on behalf of users
    }
    
    /**
     * @dev Allows a user with non zero vdUSH balance to enter the matrix and start earning farm rewards.
     * The user's address is registered in a mapping.
     * The user's last claim timestamp is set to the current block timestamp (rewards start from the moment they enter).
     * @param user The address of the user entering the matrix.
     */
    function enterMatrix(address user) external nonReentrant {
        _enterMatrix(user);
    }

    function _enterMatrix(address user) internal {
        require(!isInMatrix[user], "Already in matrix");
        require(vdUsh.balanceOf(user) > 0, "Cannot enter the matrix without vdUSH");
        isInMatrix[user] = true;
        users.push(user);
        lastClaimTimestamp[user] = block.timestamp;
        emit MatrixEntered(user);
    }

    /**
     * @dev Calculate user's earned USH and vdUSH rewards since last claim.
     * User earned rewards are proportional to their share of total vdUSH at the time of claim.
     * @param user The address of the user entering the matrix.
     */
    function earned(address user) public view returns (uint, uint, uint, uint) {
        require(isInMatrix[user], "User not in matrix");
        require(startTime!= 0 && block.timestamp > startTime, "Farm not started");
        require(!isBlocked[user], "User is blocked from claiming rewards");

        //calculate time from which to start accum rewards, max of (time user entered matrix, farm start time, last claim time)
        uint lastClaimTimeStamp = lastClaimTimestamp[user] > startTime ? lastClaimTimestamp[user] : startTime;

        uint secsSinceLastClaim = block.timestamp - lastClaimTimeStamp;
        uint lastEpoch = vdUsh.user_point_epoch(user);
        uint lastEpochTimestamp = vdUsh.user_point_history__ts(user, lastEpoch);

        uint userVdUsh;
        uint totalVdUsh;

        userVdUsh = lastClaimVdUshBalance[user];
        totalVdUsh = lastClaimTotalSupply[user];

        //sampling:
        //fyi we start at i=1, bc i=0 is the lastClaim which is already stored
        for(uint i = 1; i < 53;) {
            uint timestamp = lastClaimTimeStamp + i * 1 weeks;
            //if 1 wk after last claim is after current block timestamp, break
            if(timestamp > block.timestamp) {
                userVdUsh += vdUsh.balanceOf(user);
                totalVdUsh += vdUsh.totalSupply();
                break;
            }
            //round down to nearest week if needed
            if(timestamp > lastEpochTimestamp) {
                timestamp = lastEpochTimestamp;
            }

            userVdUsh += vdUsh.balanceOfAtT(user, timestamp);
            totalVdUsh += vdUsh.totalSupplyAtT(timestamp);

            unchecked{ ++i; }
        }

        uint averageVdUshShare = userVdUsh * 1e18 / totalVdUsh;

        uint totalWeight = averageVdUshShare * secsSinceLastClaim * totalSupplyMultiplier / 1e18;

        uint ushEarned = totalWeight * ushPerSec / 1e18;
        uint grailEarned = totalWeight * grailPerSec / 1e18;

        uint lockedUsh = ushEarned * vdUshPercentage / 100e18;
        uint claimableUsh = ushEarned - lockedUsh;

        uint lockedGrail = grailEarned * xGrailPercentage / 100e18;
        uint claimableGrail = grailEarned - lockedGrail;

        return (claimableUsh, lockedUsh, claimableGrail, lockedGrail);
    }

    /*
    ============================================================================
    Claim
    ============================================================================
    */

    function passGoAndCollect(address user) external nonReentrant {
        uint claimableUsh;
        uint lockedUsh;
        uint claimableGrail;
        uint lockedGrail;

        (claimableUsh, lockedUsh, claimableGrail, lockedGrail) = earned(user);

        require(lockedUsh > 0 || claimableUsh > 0 || claimableGrail > 0 || lockedGrail > 0, "Nothing to claim");

        lastClaimTimestamp[user] = block.timestamp;
        lastClaimVdUshBalance[user] = vdUsh.balanceOf(user);
        lastClaimTotalSupply[user] = vdUsh.totalSupply();

        //add to user's vdUSH if if nonzero
        if(lockedUsh > 0) {
            //add to user's vdUSH if their lock hasn't expired
            if(vdUsh.balanceOf(user) != 0) {
                vdUsh.deposit_for(user, 0, 0, lockedUsh);
            } else {
                lockedUsh = 0;
            }
        }

        //transfer claimable USH to user if nonzero
        if(claimableUsh > 0) {
            USH.safeTransfer(user, claimableUsh);
        }

        //add to user's xGrail if nonzero
        if(lockedGrail > 0) {
            xGRAIL.convertTo(lockedGrail, user);
        }

        //transfer claimable Grail to user if nonzero
        if(claimableGrail > 0) {
            GRAIL.safeTransfer(user, claimableGrail);
        }

        emit RewardsClaimed(user, claimableUsh, lockedUsh, claimableGrail, lockedGrail);
    }

    //view funcs
    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    function getVdUshTotalSupplyInFarm() public view returns (uint) {
        uint totalVdUsh;
        address[] memory _users = users;
        for(uint i = 0; i < _users.length;) {
            uint vdUshBalance = isBlocked[_users[i]] ? 0 : vdUsh.balanceOf(_users[i]);
            totalVdUsh += vdUshBalance;
            unchecked{ ++i; }
        }
        return totalVdUsh;
    }

    //owner funcs
    function startFarm(uint _ushPerSec, uint _grailPerSec) external onlyOwner {
        require(startTime == 0, "Farm already started");
        ushPerSec = _ushPerSec;
        grailPerSec = _grailPerSec;
        startTime = block.timestamp;
        emit FarmStarted(_ushPerSec, _grailPerSec, startTime);
    }

    function updateRewardRate(uint _ushPerSec, uint _grailPerSec) external onlyOwner {
        ushPerSec = _ushPerSec;
        grailPerSec = _grailPerSec;
        emit RewardRateUpdated(_ushPerSec, _grailPerSec);
    }

    function setLockPercentage(uint _vdUshPercentage, uint _xGrailPercentage) external onlyOwner {
        require(_vdUshPercentage <= 100e18, "vdUsh percentage too high");
        require(_xGrailPercentage <= 100e18, "xGrail percentage too high");
        vdUshPercentage = _vdUshPercentage;
        xGrailPercentage = _xGrailPercentage;
        emit LockPercentageUpdated(_vdUshPercentage, _xGrailPercentage);
    }

    function setTotalSupplyMultiplier(uint _totalSupplyMultiplier) external onlyOwner {
        totalSupplyMultiplier = _totalSupplyMultiplier; //make sure to set it in 1e18 terms
        emit TotalSupplyMultiplierUpdated(_totalSupplyMultiplier);
    }

    function setTotalSupplyMultiplier_onChain() external onlyOwner {
        totalSupplyMultiplier = vdUsh.totalSupply() * 1e18 / getVdUshTotalSupplyInFarm();
        emit TotalSupplyMultiplierUpdated(totalSupplyMultiplier);
    }

    function updateBlockList(address _user, bool _isBlocked) external onlyOwner {
        isBlocked[_user] = _isBlocked;
        emit BlockListUpdated(_user, _isBlocked);
    }

    //emergency funcs
    function recoverTokens(address token, uint amount, address dst) external onlyOwner {
        require(dst != address(0), "Cannot recover tokens to the zero address");
        IERC20(token).safeTransfer(dst, amount);
    }
}