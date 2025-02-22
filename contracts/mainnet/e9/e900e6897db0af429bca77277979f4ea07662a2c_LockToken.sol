/**
 *Submitted for verification at Arbiscan.io on 2023-09-01
*/

// Sources flattened with hardhat v2.17.1 https://hardhat.org

pragma experimental ABIEncoderV2;

// File @openzeppelin/contracts-ethereum-package/contracts/[email protected]

pragma solidity 0.6.2;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


// File @openzeppelin/contracts-ethereum-package/contracts/GSN/[email protected]

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}


// File @openzeppelin/contracts-ethereum-package/contracts/access/[email protected]

pragma solidity ^0.6.0;


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}


// File @openzeppelin/contracts-ethereum-package/contracts/math/[email protected]

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts-ethereum-package/contracts/utils/[email protected]

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
}


// File @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/[email protected]

pragma solidity ^0.6.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
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
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts-ethereum-package/contracts/introspection/[email protected]

pragma solidity ^0.6.0;

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


// File @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/[email protected]

pragma solidity ^0.6.2;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/[email protected]

pragma solidity ^0.6.2;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts-ethereum-package/contracts/utils/[email protected]

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
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

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {


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
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}


// File contracts/IERC721Extended.sol

pragma solidity 0.6.2;

interface IERC721Extended is IERC721 {
    function mintLiquidityLockNFT(address _to, uint256 _tokenId) external;
    function burn (uint256 _tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function transferOwnership (address _newOwner) external;
}


// File @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/[email protected]

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}


// File contracts/IERC20Extended.sol

pragma solidity 0.6.2;

interface IERC20Extended {
    function decimals() external view returns (uint8);
}


// File contracts/IPriceEstimator.sol

pragma solidity 0.6.2;

interface IPriceEstimator {
    function getEstimatedETHforERC20(
        uint256 erc20Amount,
        address token
    ) external view returns (uint256[] memory);

    function getEstimatedERC20forETH(
        uint256 etherAmountInWei,
        address tokenAddress
    ) external view returns (uint256[] memory);
}


// File contracts/IV3Migrator.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity 0.6.2;
// Original pragma directive: pragma experimental ABIEncoderV2

/// @title V3 Migrator
/// @notice Enables migration of liqudity from Uniswap v2-compatible pairs into Uniswap v3 pools
interface IV3Migrator {
    struct MigrateParams {
        address pair; // the Uniswap v2-compatible pair
        uint256 liquidityToMigrate; // expected to be balanceOf(msg.sender)
        uint8 percentageToMigrate; // represented as a numerator over 100
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Min; // must be discounted by percentageToMigrate
        uint256 amount1Min; // must be discounted by percentageToMigrate
        address recipient;
        uint256 deadline;
        bool refundAsETH;
    }

    /// @notice Migrates liquidity to v3 by burning v2 liquidity and minting a new position for v3
    /// @dev Slippage protection is enforced via `amount{0,1}Min`, which should be a discount of the expected values of
    /// the maximum amount of v3 liquidity that the v2 liquidity can get. For the special case of migrating to an
    /// out-of-range position, `amount{0,1}Min` may be set to 0, enforcing that the position remains out of range
    /// @param params The params necessary to migrate v2 liquidity, encoded as `MigrateParams` in calldata
    function migrate(MigrateParams calldata params) external;

    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}


// File contracts/LockToken.sol

//Team Token Locking Contract
pragma solidity 0.6.2;
// Original pragma directive: pragma experimental ABIEncoderV2









contract LockToken is Initializable, OwnableUpgradeSafe, PausableUpgradeSafe, IERC721Receiver{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;
    /*
     * deposit vars
    */
    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }

    struct NFTItems {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
        uint256 tokenId;
    }

    uint256 public depositId;
    uint256[] public allDepositIds;
    mapping(address => uint256[]) public depositsByWithdrawalAddress;
    mapping(uint256 => Items) public lockedToken;
    mapping(address => mapping(address => uint256)) public walletTokenBalance;
    /*
     * Fee vars
    */
    address public usdTokenAddress;
    IPriceEstimator public priceEstimator;
    //feeInUSD is in Wei, i.e 25USD = 25000000 USDT
    uint256 public feesInUSD;
    address payable public companyWallet;
    //list of free tokens
    mapping(address => bool) private listFreeTokens;

    mapping (uint256 => NFTItems) public lockedNFTs;
    
    //migrating liquidity
    IERC721Enumerable public nonfungiblePositionManager;
    IV3Migrator public v3Migrator;
    //new deposit id to old deposit id
    mapping(uint256 => uint256) public listMigratedDepositIds;

    //NFT Liquidity
    mapping(uint256 => bool) public nftMinted;
    address public NFT;
    bool private _notEntered;

    uint256 private constant MAX_PERCENTAGE = 10000;

    uint256 public referralDiscount;
    uint256 public referrerCut;

    // mapping of whitelisted wallet addresses
    mapping(address => bool) public whitelistedWallets;
    // mapping of admins that can whitelist
    mapping (address => bool) public whitelistAdmins;

    event LogTokenWithdrawal(uint256 id, address indexed tokenAddress, address indexed withdrawalAddress, uint256 amount);
    event LogNFTWithdrawal(uint256 id, address indexed tokenAddress, uint256 tokenId, address indexed withdrawalAddress, uint256 amount);
    event FeesChanged(uint256 indexed fees);
    event ReferralParamsChanged(uint256 referralDiscount, uint256 referrerCut);
    event ReferrerRewarded(address indexed addr, uint256 referrerCut);
    // event LiquidityMigrated(address indexed migrator, uint256 oldDepositId, uint256 newDepositId, uint256 v3TokenId);
    // event EthReceived(address, uint256);
    event Deposit(uint256 id, address indexed tokenAddress, address indexed withdrawalAddress, uint256 amount, uint256 unlockTime);
    event DepositNFT(uint256 id, address indexed tokenAddress, uint256 tokenId, address indexed withdrawalAddress, uint256 amount, uint256 unlockTime);
    event LockDurationExtended(uint256 id, uint256 unlockTime);
    event LockSplit(uint256 id, uint256 remainingAmount, uint256 splitLockId, uint256 newSplitLockAmount);
    event CompanyWalletUpdated(address companyWallet);
    event NftContractUpdated(address nftContract);
    event FreeTokenListUpdated(address token, bool isFree);
    event WhiteListUpdated(address wallet, bool noFee);
    event WhiteListAdminUpdated(address wallet, bool status);

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    modifier onlyContract(address account)
    {
        require(account.isContract(), "The address does not contain a contract");
        _;
    }

    /**
    * @dev initialize
    */
    function initialize()
    external
    {
        __LockToken_init();
    }

    function __LockToken_init()
    internal
    initializer
    {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        _notEntered = true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     *lock tokens
    */
    function lockToken(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _amount,
        uint256 _unlockTime,
        bool _mintNFT,
        address referrer
    )
    external 
    payable
    whenNotPaused
    nonReentrant
    returns (uint256 _id)
    {
        require(_amount > 0, "Amount is zero");
        require(_unlockTime > block.timestamp, "Invalid unlock time");
        uint256 amountIn = _amount;

        referrer == address(0) ? _chargeFees(_tokenAddress) : _chargeFeesReferral(_tokenAddress, referrer);
            
        uint256 balanceBefore = IERC20(_tokenAddress).balanceOf(address(this));
        // transfer tokens into contract
        IERC20(_tokenAddress).safeTransferFrom(_msgSender(), address(this), _amount);
        amountIn = IERC20(_tokenAddress).balanceOf(address(this)).sub(balanceBefore);

        //update balance in address
        walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(amountIn);
        _id = _addERC20Deposit(_tokenAddress, _withdrawalAddress, amountIn, _unlockTime);

        if(_mintNFT) {
            _mintNFTforLock(_id, _withdrawalAddress);
        }

        emit Deposit(_id, _tokenAddress, _withdrawalAddress, amountIn, _unlockTime);
    }

    /**
     *lock nft
    */
    function lockNFT(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _amount,
        uint256 _unlockTime,
        uint256 _tokenId,
        bool _mintNFT,
        address referrer
    )
    external 
    payable
    whenNotPaused
    nonReentrant
    returns (uint256 _id)
    {
        require(_amount == 1, "Invalid amount");
        require(_unlockTime > block.timestamp, "Invalid unlock time");

        referrer == address(0) ? _chargeFees(_tokenAddress) : _chargeFeesReferral(_tokenAddress, referrer);

        //update balance in address
        walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amount);
        _id = ++depositId;
        lockedNFTs[_id] = NFTItems({
            tokenAddress: _tokenAddress, 
            withdrawalAddress: _withdrawalAddress,
            tokenAmount: _amount,
            unlockTime: _unlockTime,
            withdrawn: false,
            tokenId: _tokenId
        });

        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);

        if(_mintNFT) {
            _mintNFTforLock(_id, _withdrawalAddress);
        }
        IERC721(_tokenAddress).safeTransferFrom(_msgSender(), address(this), _tokenId);

        emit DepositNFT(_id, _tokenAddress, _tokenId, _withdrawalAddress, _amount, _unlockTime);
    }

    /**
     *Extend lock Duration
    */
    function extendLockDuration(
        uint256 _id,
        uint256 _unlockTime
    )
    external
    {
        require(_unlockTime > block.timestamp, "Invalid unlock time");
        NFTItems storage lockedNFT = lockedNFTs[_id];
        Items storage lockedERC20 = lockedToken[_id];

        if(nftMinted[_id]) {
            require(IERC721Extended(NFT).ownerOf(_id) == _msgSender(), "Unauthorised to extend");
        } else {
            require((_msgSender() == lockedNFT.withdrawalAddress || 
                _msgSender() == lockedERC20.withdrawalAddress),
                "Unauthorised to extend"
            );
        }

        if(lockedNFT.tokenAddress != address(0x0))
        {
            require(_unlockTime > lockedNFT.unlockTime, "NFT: smaller unlockTime than existing");
            require(!lockedNFT.withdrawn, "NFT: already withdrawn");

            //set new unlock time
            lockedNFT.unlockTime = _unlockTime;
        }
        else
        {
            require(
                _unlockTime > lockedERC20.unlockTime,
                "ERC20: smaller unlockTime than existing"
            );
            require(
                !lockedERC20.withdrawn,
                "ERC20: already withdrawn"
            );

            //set new unlock time
            lockedERC20.unlockTime = _unlockTime;
        }
        emit LockDurationExtended(_id, _unlockTime);
    }

    /**
     *transfer locked tokens
    */
    function transferLocks(
        uint256 _id,
        address _receiverAddress
    )
    external
    {
        address msg_sender;
        NFTItems storage lockedNFT = lockedNFTs[_id];
        Items storage lockedERC20 = lockedToken[_id];

        if( lockedNFT.tokenAddress != address(0x0) )
        {
            if (_msgSender() == NFT && nftMinted[_id])
            {
                msg_sender = lockedNFT.withdrawalAddress;
            }
            else
            {
                require((!nftMinted[_id]), "NFT: Transfer Lock NFT");
                require(_msgSender() == lockedNFT.withdrawalAddress, "Unauthorised to transfer");
                msg_sender = _msgSender();
            }

            require(!lockedNFT.withdrawn, "NFT: already withdrawn");
            
            //decrease sender's token balance
            walletTokenBalance[lockedNFT.tokenAddress][msg_sender] = 
                walletTokenBalance[lockedNFT.tokenAddress][msg_sender].sub(lockedNFT.tokenAmount);
            
            //increase receiver's token balance
            walletTokenBalance[lockedNFT.tokenAddress][_receiverAddress] = 
                walletTokenBalance[lockedNFT.tokenAddress][_receiverAddress].add(lockedNFT.tokenAmount);
            
            _removeDepositsForWithdrawalAddress(_id, msg_sender);
            
            //Assign this id to receiver address
            lockedNFT.withdrawalAddress = _receiverAddress;
        }
        else
        {
            if (_msgSender() == NFT && nftMinted[_id])
            {
                msg_sender = lockedERC20.withdrawalAddress;
            }
            else {
                require((!nftMinted[_id]), "ERC20: Transfer Lock NFT");
                require(_msgSender() == lockedERC20.withdrawalAddress, "Unauthorised to transfer");
                msg_sender = _msgSender();
            }
            
            require(!lockedERC20.withdrawn, "ERC20: already withdrawn");
            
            //decrease sender's token balance
            walletTokenBalance[lockedERC20.tokenAddress][msg_sender] = 
            walletTokenBalance[lockedERC20.tokenAddress][msg_sender].sub(lockedERC20.tokenAmount);
            
            //increase receiver's token balance
            walletTokenBalance[lockedERC20.tokenAddress][_receiverAddress] = 
            walletTokenBalance[lockedERC20.tokenAddress][_receiverAddress].add(lockedERC20.tokenAmount);
            
            _removeDepositsForWithdrawalAddress(_id, msg_sender);
            
            //Assign this id to receiver address
            lockedERC20.withdrawalAddress = _receiverAddress;
        }
        
        depositsByWithdrawalAddress[_receiverAddress].push(_id);
    }

    /**
     *withdraw tokens
    */
    function withdrawTokens(
        uint256 _id,
        uint256 _amount
    )
    external
    nonReentrant
    {
        if(nftMinted[_id]) {
            require(IERC721Extended(NFT).ownerOf(_id) == _msgSender(), "Unauthorised to unlock");
        }
        NFTItems memory lockedNFT = lockedNFTs[_id];
        Items storage lockedERC20 = lockedToken[_id];

        require(
            (_msgSender() == lockedNFT.withdrawalAddress || _msgSender() == lockedERC20.withdrawalAddress),
            "Unauthorised to unlock"
        );

        //amount is ignored for erc-721 locks, in the future if 1155 locks are supported, we need to cater to amount var
        if(lockedNFT.tokenAddress != address(0x0)) {
            require(block.timestamp >= lockedNFT.unlockTime, "Unlock time not reached");
            require(!lockedNFT.withdrawn, "NFT: already withdrawn");

            _removeNFTDeposit(_id);

            if(nftMinted[_id])
            {
                nftMinted[_id] = false;
                IERC721Extended(NFT).burn(_id);
            }

            // transfer tokens to wallet address
            IERC721(lockedNFT.tokenAddress).safeTransferFrom(address(this), _msgSender(), lockedNFT.tokenId);

            emit LogNFTWithdrawal(_id, lockedNFT.tokenAddress, lockedNFT.tokenId, _msgSender(), lockedNFT.tokenAmount);
        }
        else
        {
            require(block.timestamp >= lockedERC20.unlockTime, "Unlock time not reached");
            require(!lockedERC20.withdrawn, "ERC20: already withdrawn");
            require(_amount > 0, "ERC20: Cannot Withdraw 0 Tokens");
            require(lockedERC20.tokenAmount >= _amount, "Insufficent Balance to withdraw");

            //full withdrawl
            if(lockedERC20.tokenAmount == _amount){
                _removeERC20Deposit(_id);
                if (nftMinted[_id]){
                    nftMinted[_id] = false;
                    IERC721Extended(NFT).burn(_id);
                }
            }
            else {
                //partial withdrawl
                lockedERC20.tokenAmount = lockedERC20.tokenAmount.sub(_amount);
                walletTokenBalance[lockedERC20.tokenAddress][lockedERC20.withdrawalAddress] = 
                    walletTokenBalance[lockedERC20.tokenAddress][lockedERC20.withdrawalAddress].sub(_amount);
            }
            // transfer tokens to wallet address
            IERC20(lockedERC20.tokenAddress).safeTransfer(_msgSender(), _amount);

            emit LogTokenWithdrawal(_id, lockedERC20.tokenAddress, _msgSender(), _amount);
        }
    }

    /**
    Split existing ERC20 Lock into 2
    @dev This function will split a single lock into two induviual locks
    @param _id represents the lockId of the token lock you are to split
    @param _splitAmount is the amount of tokens in wei that will be 
    shifted from the old lock to the new split lock
    @param _splitUnlockTime the unlock time for the newly created split lock
    must always be >= to unlockTime of lock it is being split from
    @param _mintNFT is a boolean check on weather the new split lock will have an NFT minted
     */
     
    function splitLock(
        uint256 _id, 
        uint256 _splitAmount,
        uint256 _splitUnlockTime,
        bool _mintNFT
    ) 
    external 
    payable
    whenNotPaused
    nonReentrant
    returns (uint256 _splitLockId)
    {
        Items storage lockedERC20 = lockedToken[_id];
        // NFTItems memory lockedNFT = lockedNFTs[_id];
        address lockedNFTAddress = lockedNFTs[_id].tokenAddress;
        //Check to ensure an NFT lock is not being split
        require(lockedNFTAddress == address(0x0), "Can't split locked NFT");
        uint256 lockedERC20Amount = lockedToken[_id].tokenAmount;
        address lockedERC20Address = lockedToken[_id].tokenAddress;
        address lockedERC20WithdrawlAddress = lockedToken[_id].withdrawalAddress;
        require(lockedERC20Address != address(0x0), "Can't split empty lock");
        if(nftMinted[_id]){
            require(
                IERC721(NFT).ownerOf(_id) == _msgSender(),
                "Unauthorised to Split"
            );
        }
        require(
            _msgSender() == lockedERC20WithdrawlAddress,
             "Unauthorised to Split"
        );
        require(!lockedERC20.withdrawn, "Cannot split withdrawn lock");
        //Current locked tokenAmount must always be > _splitAmount as (lockedERC20.tokenAmount - _splitAmount) 
        //will be the number of tokens retained in the original lock, while splitAmount will be the amount of tokens
        //transferred to the new lock
        require(lockedERC20Amount > _splitAmount, "Insufficient balance to split");
        require(_splitUnlockTime >= lockedERC20.unlockTime, "Smaller unlock time than existing");
        //charge Tier 2 fee for tokenSplit
        _chargeFees(lockedERC20Address);
        lockedERC20.tokenAmount = lockedERC20Amount.sub(_splitAmount);
        //new token lock created with id stored in var _splitLockId
        _splitLockId = _addERC20Deposit(lockedERC20Address, lockedERC20WithdrawlAddress, _splitAmount, _splitUnlockTime);
        if(_mintNFT) {
            _mintNFTforLock(_splitLockId, lockedERC20WithdrawlAddress);
        }
        emit LockSplit(_id, lockedERC20.tokenAmount, _splitLockId, _splitAmount);
        emit Deposit(_splitLockId, lockedERC20Address, lockedERC20WithdrawlAddress, _splitAmount, _splitUnlockTime);

    }

    /**
    * @dev Called by an admin to pause, triggers stopped state.
    */
    function pause()
    external
    onlyOwner 
    {
        _pause();
    }

    /**
    * @dev Called by an admin to unpause, returns to normal state.
    */
    function unpause()
    external
    onlyOwner
    {
        _unpause();
    }

    function setFeeParams(address _priceEstimator, address _usdTokenAddress, uint256 _feesInUSD, address payable _companyWallet)
    external
    onlyOwner
    onlyContract(_priceEstimator)
    onlyContract(_usdTokenAddress)
    {
        require(_feesInUSD > 0, "fees should be greater than 0");
        require(_companyWallet != address(0), "Invalid wallet address");
        priceEstimator = IPriceEstimator(_priceEstimator);
        usdTokenAddress = _usdTokenAddress;
        feesInUSD = _feesInUSD;
        companyWallet = _companyWallet;
        emit FeesChanged(_feesInUSD);
    }

    function setFeesInUSD(uint256 _feesInUSD)
    external
    onlyOwner
    {
        require(_feesInUSD > 0,"fees should be greater than 0");
        feesInUSD = _feesInUSD;
        emit FeesChanged(_feesInUSD);
    }

    function setReferralParams(uint256 _referralDiscount, uint256 _referrerCut)
    external
    onlyOwner
    {
        require(_referralDiscount <= MAX_PERCENTAGE, "Referral discount invalid");
        require(_referrerCut <= MAX_PERCENTAGE, "Referrer cut invalid");

        referralDiscount = _referralDiscount;
        referrerCut = _referrerCut;

        emit ReferralParamsChanged(_referralDiscount, _referrerCut);
    }

    function setCompanyWallet(address payable _companyWallet)
    external
    onlyOwner
    {
        require(_companyWallet != address(0), "Invalid wallet address");
        companyWallet = _companyWallet;

        emit CompanyWalletUpdated(_companyWallet);
    }

    /**
     * @dev Update the address of the NFT SC
     * @param _nftContractAddress The address of the new NFT SC
     */
    function setNFTContract(address _nftContractAddress)
    external
    onlyOwner
    onlyContract(_nftContractAddress)
    {
        NFT = _nftContractAddress;

        emit NftContractUpdated(_nftContractAddress);
    }

    /**
    * @dev called by admin to add given token to free tokens list
    */
    function addTokenToFreeList(address token)
    external
    onlyOwner
    onlyContract(token)
    {
        listFreeTokens[token] = true;

        emit FreeTokenListUpdated(token, true);
    }

    /**
    * @dev called by admin to remove given token from free tokens list
    */
    function removeTokenFromFreeList(address token)
    external
    onlyOwner
    onlyContract(token)
    {
        listFreeTokens[token] = false;

        emit FreeTokenListUpdated(token, false);
    }

     /**
    * @dev called by admin/owner to add add or remove wallet from whitelist
    * @param wallet address to add/remove from whitelist
    * @param noFee if to add or remove from whitelist
    */
    function updateWhitelist(address wallet, bool noFee)
    external
    {
        require(
            (whitelistAdmins[_msgSender()] || owner() == _msgSender()),
            "Caller is not authorized to whitelist"
        );
        whitelistedWallets[wallet] = noFee;
        emit WhiteListUpdated(wallet, noFee);
    }


    /*get total token balance in contract*/
    function getTotalTokenBalance(address _tokenAddress) view external returns (uint256)
    {
       return IERC20(_tokenAddress).balanceOf(address(this));
    }
    
    /*get allDepositIds*/
    function getAllDepositIds() view external returns (uint256[] memory)
    {
        return allDepositIds;
    }
    
    /*get getDepositDetails*/
    function getDepositDetails(uint256 _id)
    view
    external
    returns (
        address _tokenAddress, 
        address _withdrawalAddress, 
        uint256 _tokenAmount, 
        uint256 _unlockTime, 
        bool _withdrawn, 
        uint256 _tokenId,
        bool _isNFT,
        uint256 _migratedLockDepositId,
        bool _isNFTMinted)
    {
        bool isNftMinted = nftMinted[_id];
        NFTItems memory lockedNFT = lockedNFTs[_id];
        Items memory lockedERC20 = lockedToken[_id];

        if( lockedNFT.tokenAddress != address(0x0) )
        {
            // //old lock id
            // uint256 migratedLockId = listMigratedDepositIds[_id];

            return (
                lockedNFT.tokenAddress,
                lockedNFT.withdrawalAddress,
                lockedNFT.tokenAmount,
                lockedNFT.unlockTime,
                lockedNFT.withdrawn, 
                lockedNFT.tokenId,
                true,
                0,
                isNftMinted
            );
        }
        else
        {
            return (
                lockedERC20.tokenAddress,
                lockedERC20.withdrawalAddress,
                lockedERC20.tokenAmount,
                lockedERC20.unlockTime,
                lockedERC20.withdrawn,
                0,
                false,
                0,
                isNftMinted
            );
        }
    }
    
    /*get DepositsByWithdrawalAddress*/
    function getDepositsByWithdrawalAddress(address _withdrawalAddress) view external returns (uint256[] memory)
    {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }
    
    function getFeesInETH(address _tokenAddress)
    public
    view
    returns (uint256)
    {
        //token listed free or fee params not set
        if (whitelistedWallets[_msgSender()] || 
            isFreeToken(_tokenAddress) ||
            feesInUSD == 0 ||
            address(priceEstimator) == address(0) ||
            usdTokenAddress == address(0) 
            )
        {
            return 0;
        }
        else 
        {
            //price should be estimated by 1 token because Uniswap algo changes price based on large amount
            uint256 tokenBits = 10 ** uint256(IERC20Extended(usdTokenAddress).decimals());

            uint256 estFeesInEthPerUnit = priceEstimator.getEstimatedETHforERC20(tokenBits, usdTokenAddress)[0];
            //subtract uniswap 0.30% fees
            //_uniswapFeePercentage is a percentage expressed in 1/10 (a tenth) of a percent hence we divide by 1000
            estFeesInEthPerUnit = estFeesInEthPerUnit.sub(estFeesInEthPerUnit.mul(3).div(1000));

            uint256 feesInEth = feesInUSD.mul(estFeesInEthPerUnit).div(tokenBits);
            return feesInEth;
        }
    }

    /**
     * @dev Checks if token is in free list
     * @param token The address to check
    */
    function isFreeToken(address token)
    public
    view
    returns(bool)
    {
        return listFreeTokens[token];
    }

    function _addERC20Deposit (
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 amountIn,
        uint256 _unlockTime
    ) 
    private 
    returns (uint256 _id){
        _id = ++depositId;
        lockedToken[_id] = Items({
            tokenAddress: _tokenAddress, 
            withdrawalAddress: _withdrawalAddress,
            tokenAmount: amountIn, 
            unlockTime: _unlockTime, 
            withdrawn: false
        });

        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
    }

    function _removeERC20Deposit(
        uint256 _id
    )
    private
    {
        Items storage lockedERC20 = lockedToken[_id];
        //remove entry from lockedToken struct
        lockedERC20.withdrawn = true;
                
        //update balance in address
        walletTokenBalance[lockedERC20.tokenAddress][lockedERC20.withdrawalAddress] = 
        walletTokenBalance[lockedERC20.tokenAddress][lockedERC20.withdrawalAddress].sub(lockedERC20.tokenAmount);
        
        _removeDepositsForWithdrawalAddress(_id, lockedERC20.withdrawalAddress);
    }

    function _removeNFTDeposit(
        uint256 _id
    )
    private
    {
        NFTItems storage lockedNFT = lockedNFTs[_id];
        //remove entry from lockedNFTs struct
        lockedNFT.withdrawn = true;
                
        //update balance in address
        walletTokenBalance[lockedNFT.tokenAddress][lockedNFT.withdrawalAddress] = 
        walletTokenBalance[lockedNFT.tokenAddress][lockedNFT.withdrawalAddress].sub(lockedNFT.tokenAmount);
        
        _removeDepositsForWithdrawalAddress(_id, lockedNFTs[_id].withdrawalAddress);
    }

    function _removeDepositsForWithdrawalAddress(
        uint256 _id,
        address _withdrawalAddress
    )
    private
    {
        //remove this id from this address
        uint256 j;
        uint256 arrLength = depositsByWithdrawalAddress[_withdrawalAddress].length;
        for (j=0; j<arrLength; j++) {
            if (depositsByWithdrawalAddress[_withdrawalAddress][j] == _id) {
                depositsByWithdrawalAddress[_withdrawalAddress][j] = 
                    depositsByWithdrawalAddress[_withdrawalAddress][arrLength - 1];
                depositsByWithdrawalAddress[_withdrawalAddress].pop();
                break;
            }
        }
    }

    function _chargeFees(
        address _tokenAddress
    )
    private
    {
        uint256 minRequiredFeeInEth = getFeesInETH(_tokenAddress);
        if (minRequiredFeeInEth == 0) {
            if (msg.value > 0) {
                (bool refundSuccess,) = _msgSender().call.value(msg.value)("");
                require(refundSuccess, "Refund failed.");
            }
            return;
        }

        bool feesBelowMinRequired = msg.value < minRequiredFeeInEth;
        uint256 feeDiff = feesBelowMinRequired ? 
            SafeMath.sub(minRequiredFeeInEth, msg.value) : 
            SafeMath.sub(msg.value, minRequiredFeeInEth);
            
        if( feesBelowMinRequired ) {
            uint256 feeSlippagePercentage = feeDiff.mul(100).div(minRequiredFeeInEth);
            //will allow if diff is less than 5%
            require(feeSlippagePercentage <= 5, "Fee Not Met");
        }
        (bool success,) = companyWallet.call.value(feesBelowMinRequired ? msg.value : minRequiredFeeInEth)("");
        require(success, "Fee transfer failed");
        /* refund difference. */
        if (!feesBelowMinRequired && feeDiff > 0) {
            (bool refundSuccess,) = _msgSender().call.value(feeDiff)("");
            require(refundSuccess, "Refund failed");
        }
    }

    function _chargeFeesReferral(
        address _tokenAddress,
        address referrer
    )
    private
    {
        require(_msgSender() != referrer, "Refferer cant be msg sender");

        uint256 feeInEth = getFeesInETH(_tokenAddress);
        if (feeInEth == 0) {
            if (msg.value > 0) {
                (bool refundSuccess,) = _msgSender().call.value(msg.value)("");
                require(refundSuccess, "Refund failed.");
            }
            return;
        }

        uint256 _referralDiscount = referralDiscount;
        require(_referralDiscount > 0, "Refferal discount not set");

        feeInEth = feeInEth.mul(referralDiscount).div(MAX_PERCENTAGE);

        // will allow if diff is less than 5%
        require(msg.value >= feeInEth.mul(95).div(100), "Fee Not Met");

        uint256 takenFee = msg.value < feeInEth ? msg.value : feeInEth;

        uint256 referrerFee = takenFee.mul(referrerCut).div(MAX_PERCENTAGE);
        (bool referrerTransferSuccess,) = payable(referrer).call.value(referrerFee)("");
        require(referrerTransferSuccess, "Referrer transfer failed.");

        // cant overflow because referrerCut must be < MAX_PERCENTAGE -> referrerFee < takenFee
        uint256 trustswapPart = takenFee - referrerFee;
        (bool success,) = companyWallet.call.value(trustswapPart)("");
        require(success, "Fee transfer failed");

        /* refund difference. */
        if (msg.value > takenFee) {
            // cant overflow because takenFee < msg.value
            (bool refundSuccess,) = _msgSender().call.value(msg.value - takenFee)("");
            require(refundSuccess, "Refund failed");
        }

        emit ReferrerRewarded(referrer, referrerFee);
    }

    /**
     */
    function mintNFTforLock(uint256 _id)
        external
        whenNotPaused
    {
        require(NFT != address(0), 'NFT: Unintalized');
        require(
            !nftMinted[_id], 
            "NFT already minted"
        );
        NFTItems memory lockedNFT = lockedNFTs[_id];
        Items memory lockedERC20 = lockedToken[_id];

        require(
            (lockedNFT.withdrawalAddress == _msgSender() || lockedERC20.withdrawalAddress == _msgSender()), 
            "Unauthorised"
        );
        require((!lockedNFT.withdrawn && !lockedERC20.withdrawn), 
            "Token/NFT already withdrawn"
        );

        _mintNFTforLock(_id, _msgSender());
    }

    function _mintNFTforLock(
        uint256 _id, 
        address _withdrawalAddress
    ) 
    private{
        require(NFT != address(0), 'NFT: Unintalized');
        nftMinted[_id] = true;
        IERC721Extended(NFT).mintLiquidityLockNFT(_withdrawalAddress, _id);
    }

    /**
     * @dev This function is used to setup a whitelistAdmin with the onlyOwner modifier
     * @param account the account to assign the role to
     * @param access to grank or revoke access
    */

    function updateWhitelistAdminAccess (
        address account,
        bool access
    ) 
    external  
    onlyOwner {
        whitelistAdmins[account] = access;
        emit WhiteListAdminUpdated(account, access);
    }

}