// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
        _;
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

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

pragma solidity 0.6.12;

interface IChronosGauge {
    function bribe() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function isReward(address) external view returns (bool);
    function getReward(address account, address[] memory tokens) external;
    function getAllReward() external;
    function earned(address token, address account) external view returns (uint);
    function stake() external view returns (address);
    function deposit(uint amount, uint tokenId) external;
    function depositAll() external;
    function withdraw(uint amount) external;
    function withdrawAndHarvestAll() external;
    function withdrawToken(uint amount, uint tokenId) external;
    function tokenIds(address owner) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IChronosRouter {
    struct Route {
        address from;
        address to;
        bool stable;
    }
    function factory() external pure returns (address);

    function wmatic() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function quoteLiquidity(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountsOut(uint256 amountIn, Route[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./lib/access/Ownable.sol";
import "./lib/token/ERC20/SafeERC20.sol";
import "./lib/token/ERC721/IERC721Receiver.sol";
import "./lib/utils/Pausable.sol";
import "./lib/utils/ReentrancyGuard.sol";

import "./libs/IChronosGauge.sol";
import "./libs/IChronosRouter.sol";
import "./libs/IUniPair.sol";
import "./libs/IWETH.sol";

contract StrategyChronos is Ownable, ReentrancyGuard, Pausable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public gaugeAddress;
    address public wantAddress;
    address public token0Address;
    address public token1Address;
    address public earnedAddress;
    bool public isStable;
    
    address public solidRouterAddress = 0xE708aA9E887980750C040a6A2Cb901c37Aa34f3b;
    address public constant wethAddress = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant vaultAddress = 0xAdFc4a71444B549Db5324737EFF3B58a4Ef42FF8;
    address public constant feeAddress = 0x7Bff90aa7C618298A3B882858e7f0163b2c43381;
    address public vaultChefAddress;
    address public govAddress;

    uint256 public lastEarnBlock = block.number;
    uint256 public sharesTotal = 0;

    uint256 public controllerFee = 50;
    uint256 public constant feeMaxTotal = 1000;
    uint256 public constant feeMax = 10000;

    uint256 public depositFee = 0; // 1 = 1%
    uint256 public withdrawFeeFactor = 10000;
    uint256 public constant withdrawFeeFactorMax = 10000;
    uint256 public constant withdrawFeeFactorLL = 9900;

    uint256 public slippageFactor = 950;
    uint256 public constant slippageFactorUL = 995;

    IChronosRouter.Route[] public earnedToWethPath;
    IChronosRouter.Route[] public earnedToToken0Path;
    IChronosRouter.Route[] public earnedToToken1Path;
    IChronosRouter.Route[] public wethToToken0Path;
    IChronosRouter.Route[] public wethToToken1Path;
    address[] public rewards;

    constructor(
        address _vaultChefAddress,
        address _gaugeAddress,
        bool _isStable,
        address _wantAddress,
        address _earnedAddress,
        IChronosRouter.Route[] memory _earnedTWethPath,
        IChronosRouter.Route[] memory _earnedTToken0Path,
        IChronosRouter.Route[] memory _earnedTToken1Path,
        IChronosRouter.Route[] memory _wethToTken0Path,
        IChronosRouter.Route[] memory _wethToTken1Path
    ) public {
        govAddress = msg.sender;
        vaultChefAddress = _vaultChefAddress;

        gaugeAddress = _gaugeAddress;
        isStable = _isStable;
        wantAddress = _wantAddress;
        rewards.push(_earnedAddress);
        token0Address = IUniPair(wantAddress).token0();
        token1Address = IUniPair(wantAddress).token1();

        earnedAddress = _earnedAddress;

        for(uint i=0; i<_earnedTWethPath.length; i++){
            earnedToWethPath.push();
            earnedToWethPath[i].from = _earnedTWethPath[i].from;
            earnedToWethPath[i].to = _earnedTWethPath[i].to;
            earnedToWethPath[i].stable = _earnedTWethPath[i].stable;
        }

        for(uint i=0; i<_earnedTToken0Path.length; i++){
            earnedToToken0Path.push();
            earnedToToken0Path[i].from = _earnedTToken0Path[i].from;
            earnedToToken0Path[i].to = _earnedTToken0Path[i].to;
            earnedToToken0Path[i].stable = _earnedTToken0Path[i].stable;
        }

        for(uint i=0; i<_earnedTToken1Path.length; i++){
            earnedToToken1Path.push();
            earnedToToken1Path[i].from = _earnedTToken1Path[i].from;
            earnedToToken1Path[i].to = _earnedTToken1Path[i].to;
            earnedToToken1Path[i].stable = _earnedTToken1Path[i].stable;
        }

        for(uint i=0; i<_wethToTken0Path.length; i++){
            wethToToken0Path.push();
            wethToToken0Path[i].from = _wethToTken0Path[i].from;
            wethToToken0Path[i].to = _wethToTken0Path[i].to;
            wethToToken0Path[i].stable = _wethToTken0Path[i].stable;
        }

        for(uint i=0; i<_wethToTken1Path.length; i++){
            wethToToken1Path.push();
            wethToToken1Path[i].from = _wethToTken1Path[i].from;
            wethToToken1Path[i].to = _wethToTken1Path[i].to;
            wethToToken1Path[i].stable = _wethToTken1Path[i].stable;
        }

        transferOwnership(vaultChefAddress);
        _resetAllowances();
    }
    
    modifier onlyGov() {
        require(msg.sender == govAddress);
        _;
    }
    
    function deposit(address _userAddress, uint256 _wantAmt) external onlyOwner nonReentrant whenNotPaused returns (uint256) {
        uint256 wantLockedBefore = wantLockedTotal();

        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        if(depositFee > 0){
            uint256 feesTaken = _wantAmt.mul(depositFee).div(100);

            IERC20(wantAddress).safeTransfer(vaultAddress, feesTaken);
        }

        uint256 sharesAdded = _farm();
        if (sharesTotal > 0) {
            sharesAdded = sharesAdded.mul(sharesTotal).div(wantLockedBefore);
        }
        sharesTotal = sharesTotal.add(sharesAdded);

        return sharesAdded;
    }

    function _farm() internal returns (uint256) {
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (wantAmt == 0) return 0;
        
        uint256 sharesBefore = vaultSharesTotal();
        IChronosGauge(gaugeAddress).depositAll();
        uint256 sharesAfter = vaultSharesTotal();
        
        return sharesAfter.sub(sharesBefore);
    }

    function withdraw(address _userAddress, uint256 _wantAmt) external onlyOwner nonReentrant returns (uint256) {
        require(_wantAmt > 0);
        
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        
        if (_wantAmt > wantAmt) {
            IChronosGauge(gaugeAddress).withdrawAndHarvestAll();
            wantAmt = IERC20(wantAddress).balanceOf(address(this));
        }

        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (_wantAmt > wantLockedTotal()) {
            _wantAmt = wantLockedTotal();
        }

        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal());
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);
        
        uint256 withdrawFee = _wantAmt
            .mul(withdrawFeeFactorMax.sub(withdrawFeeFactor))
            .div(withdrawFeeFactorMax);
        IERC20(wantAddress).safeTransfer(vaultAddress, withdrawFee);
        
        _wantAmt = _wantAmt.sub(withdrawFee);

        IERC20(wantAddress).safeTransfer(vaultChefAddress, _wantAmt);

        _farm();
        return sharesRemoved;
    }

    function earn() external nonReentrant whenNotPaused {
        IChronosGauge(gaugeAddress).getAllReward();

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        uint256 wethAmt = IERC20(wethAddress).balanceOf(address(this));

        if (earnedAmt > 0) {
            earnedAmt = distributeFees(earnedAmt, earnedAddress);
    
            if (earnedAddress != token0Address) {
                _safeSwap(
                    earnedAmt.div(2),
                    earnedToToken0Path,
                    address(this)
                );
            }
    
            if (earnedAddress != token1Address) {
                _safeSwap(
                    earnedAmt.div(2),
                    earnedToToken1Path,
                    address(this)
                );
            }
        }
        
        if (wethAmt > 0) {
            wethAmt = distributeFees(wethAmt, wethAddress);
    
            if (wethAddress != token0Address) {
                _safeSwap(
                    wethAmt.div(2),
                    wethToToken0Path,
                    address(this)
                );
            }
    
            if (wethAddress != token1Address) {
                _safeSwap(
                    wethAmt.div(2),
                    wethToToken1Path,
                    address(this)
                );
            }
        }
        
        if (earnedAmt > 0 || wethAmt > 0) {
            uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
            uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));

            if (token0Amt > 0 && token1Amt > 0) {
                IChronosRouter(solidRouterAddress).addLiquidity(
                    token0Address,
                    token1Address,
                    isStable,
                    token0Amt,
                    token1Amt,
                    0,
                    0,
                    address(this),
                    now.add(600)
                );
            }

            lastEarnBlock = block.number;
    
            _farm();
        }
    }

    function distributeFees(uint256 _earnedAmt, address _earnedAddress) internal returns (uint256) {
        if (controllerFee > 0) {
            uint256 fee = _earnedAmt.mul(controllerFee).div(feeMax);
            
            if (_earnedAddress == wethAddress) {
                IWETH(wethAddress).withdraw(fee);
                safeTransferETH(feeAddress, fee);
            } else {
                _safeSwapWeth(
                    fee,
                    earnedToWethPath,
                    feeAddress
                );
            }
            
            _earnedAmt = _earnedAmt.sub(fee);
        }

        return _earnedAmt;
    }

    function pause() external onlyGov {
        _pause();
    }

    function unpause() external onlyGov {
        _unpause();
        _resetAllowances();
    }
    
    
    function vaultSharesTotal() public view returns (uint256) {
        uint256 balance = IChronosGauge(gaugeAddress).balanceOf(address(this));
        return balance;
    }
    
    function wantLockedTotal() public view returns (uint256) {
        uint256 balance = IChronosGauge(gaugeAddress).balanceOf(address(this));
        return IERC20(wantAddress).balanceOf(address(this)).add(balance);
    }

    function _resetAllowances() internal {
        
        IERC20(wantAddress).safeApprove(gaugeAddress, uint256(0));
        IERC20(wantAddress).safeIncreaseAllowance(
            gaugeAddress,
            uint256(-1)
        );

        IERC20(earnedAddress).safeApprove(solidRouterAddress, uint256(0));
        IERC20(earnedAddress).safeIncreaseAllowance(
            solidRouterAddress,
            uint256(-1)
        );

        IERC20(wethAddress).safeApprove(solidRouterAddress, uint256(0));
        IERC20(wethAddress).safeIncreaseAllowance(
            solidRouterAddress,
            uint256(-1)
        );
        
        IERC20(wantAddress).safeApprove(solidRouterAddress, uint256(0));
        IERC20(wantAddress).safeIncreaseAllowance(
            solidRouterAddress,
            uint256(-1)
        );

        IERC20(token0Address).safeApprove(solidRouterAddress, uint256(0));
        IERC20(token0Address).safeIncreaseAllowance(
            solidRouterAddress,
            uint256(-1)
        );

        IERC20(token1Address).safeApprove(solidRouterAddress, uint256(0));
        IERC20(token1Address).safeIncreaseAllowance(
            solidRouterAddress,
            uint256(-1)
        );
    }

    function resetAllowances() external onlyGov {
        _resetAllowances();
    }

    function panic() external onlyGov {
        _pause();
        IChronosGauge(gaugeAddress).withdrawAndHarvestAll();
    }

    function unpanic() external onlyGov {
        _unpause();
        _farm();
    }
    
    function setSettings(
        uint256 _controllerFee,
        uint256 _withdrawFeeFactor,
        uint256 _slippageFactor,
        address _solidRouterAddress
    ) external onlyGov {
        require(_controllerFee <= feeMaxTotal);
        require(_withdrawFeeFactor >= withdrawFeeFactorLL);
        require(_withdrawFeeFactor <= withdrawFeeFactorMax);
        require(_slippageFactor <= slippageFactorUL);
        controllerFee = _controllerFee;
        withdrawFeeFactor = _withdrawFeeFactor;
        slippageFactor = _slippageFactor;
        solidRouterAddress = _solidRouterAddress;
    }

    function setGov(address _govAddress) external onlyGov {
        govAddress = _govAddress;
    }

    function setDepositFee(uint256 _depositFee) external onlyGov {
        require(_depositFee <= 10, "Max fee of 10%");
        depositFee = _depositFee;
    }
    
    function _safeSwap(
        uint256 _amountIn,
        IChronosRouter.Route[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IChronosRouter(solidRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IChronosRouter(solidRouterAddress).swapExactTokensForTokens(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            now.add(600)
        );
    }
    
    function _safeSwapWeth(
        uint256 _amountIn,
        IChronosRouter.Route[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IChronosRouter(solidRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IChronosRouter(solidRouterAddress).swapExactTokensForETH(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            now.add(600)
        );
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success);
    }

    receive() external payable {}
}