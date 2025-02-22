// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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

pragma solidity ^0.8.12;

import "./IERC20BurnableMinter.sol";
import "./IStakePool.sol";
import "./IMarket.sol";

interface IBank {
  // DSD token address
  function DSD() external view returns (IERC20BurnableMinter);

  // Market contract address
  function market() external view returns (IMarket);

  // StakePool contract address
  function pool() external view returns (IStakePool);

  // helper contract address
  function helper() external view returns (address);

  // user debt
  function debt(address user) external view returns (uint256);

  // developer address
  function dev() external view returns (address);

  // fee for borrowing DSD
  function borrowFee() external view returns (uint32);

  /**
   * @dev Constructor.
   * NOTE This function can only called through delegatecall.
   * @param _DSD - DSD token address.
   * @param _market - Market contract address.
   * @param _pool - StakePool contract address.
   * @param _helper - Helper contract address.
   * @param _owner - Owner address.
   */
  function constructor1(
    IERC20BurnableMinter _DSD,
    IMarket _market,
    IStakePool _pool,
    address _helper,
    address _owner
  ) external;

  /**
   * @dev Set bank options.
   *      The caller must be owner.
   * @param _dev - Developer address
   * @param _borrowFee - Fee for borrowing DSD
   */
  function setOptions(address _dev, uint32 _borrowFee) external;

  /**
   * @dev Calculate the amount of Lab that can be withdrawn.
   * @param user - User address
   */
  function withdrawable(address user) external view returns (uint256);

  /**
   * @dev Calculate the amount of Lab that can be withdrawn.
   * @param user - User address
   * @param amountLab - User staked Lab amount
   */
  function withdrawable(address user, uint256 amountLab)
    external
    view
    returns (uint256);

  /**
   * @dev Calculate the amount of DSD that can be borrowed.
   * @param user - User address
   */
  function available(address user) external view returns (uint256);

  /**
   * @dev Borrow DSD.
   * @param amount - The amount of DSD
   * @return borrowed - Borrowed DSD
   * @return fee - Borrow fee
   */
  function borrow(uint256 amount)
    external
    returns (uint256 borrowed, uint256 fee);

  /**
   * @dev Borrow DSD from user and directly mint to msg.sender.
   *      The caller must be helper contract.
   * @param user - User address
   * @param amount - The amount of DSD
   * @return borrowed - Borrowed DSD
   * @return fee - Borrow fee
   */
  function borrowFrom(address user, uint256 amount)
    external
    returns (uint256 borrowed, uint256 fee);

  /**
   * @dev Repay DSD.
   * @param amount - The amount of DSD
   */
  function repay(uint256 amount) external;

  /**
   * @dev Triggers stopped state.
   *      The caller must be owner.
   */
  function pause() external;

  /**
   * @dev Returns to normal state.
   *      The caller must be owner.
   */
  function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC20BurnableMinter is IERC20Metadata {
  function mint(address to, uint256 amount) external;

  function burn(uint256 amount) external;

  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "./IERC20BurnableMinter.sol";
import "./IStakePool.sol";

interface IMarket is IAccessControlEnumerable {
  function totalVolume() external view returns (uint256);

  function paused() external view returns (bool);

  function Lab() external view returns (IERC20BurnableMinter);

  function prLab() external view returns (IERC20BurnableMinter);

  function pool() external view returns (IStakePool);

  // target funding ratio (target/10000)
  function target() external view returns (uint32);

  // target adjusted funding ratio (targetAdjusted/10000)
  function targetAdjusted() external view returns (uint32);

  // minimum value of target
  function minTarget() external view returns (uint32);

  // maximum value of the targetAdjusted
  function maxTargetAdjusted() external view returns (uint32);

  // step value of each raise
  function raiseStep() external view returns (uint32);

  // step value of each lower
  function lowerStep() external view returns (uint32);

  // interval of each lower
  function lowerInterval() external view returns (uint32);

  // the time when ratio was last modified
  function latestUpdateTimestamp() external view returns (uint256);

  // developer address
  function dev() external view returns (address);

  // fee for buying Lab
  function buyFee() external view returns (uint32);

  // fee for selling Lab
  function sellFee() external view returns (uint32);

  // the slope of the price function (1/(k * 1e18))
  function k() external view returns (uint256);

  // current Lab price
  function c() external view returns (uint256);

  // floor Lab price
  function f() external view returns (uint256);

  // floor supply
  function p() external view returns (uint256);

  // total worth
  function w() external view returns (uint256);

  // stablecoins decimals
  function stablecoinsDecimals(address token) external view returns (uint8);

  /**
   * @dev Startup market.
   *      The caller must be owner.
   * @param _token - Initial stablecoin address
   * @param _w - Initial stablecoin worth
   * @param _t - Initial Lab total supply
   */
  function startup(
    address _token,
    uint256 _w,
    uint256 _t
  ) external;

  /**
   * @dev Get the number of stablecoins that can buy Lab.
   */
  function stablecoinsCanBuyLength() external view returns (uint256);

  /**
   * @dev Get the address of the stablecoin that can buy Lab according to the index.
   * @param index - Stablecoin index
   */
  function stablecoinsCanBuyAt(uint256 index) external view returns (address);

  /**
   * @dev Get whether the token can be used to buy Lab.
   * @param token - Token address
   */
  function stablecoinsCanBuyContains(address token)
    external
    view
    returns (bool);

  /**
   * @dev Get the number of stablecoins that can be exchanged with Lab.
   */
  function stablecoinsCanSellLength() external view returns (uint256);

  /**
   * @dev Get the address of the stablecoin that can be exchanged with Lab,
   *      according to the index.
   * @param index - Stablecoin index
   */
  function stablecoinsCanSellAt(uint256 index) external view returns (address);

  /**
   * @dev Get whether the token can be exchanged with Lab.
   * @param token - Token address
   */
  function stablecoinsCanSellContains(address token)
    external
    view
    returns (bool);

  /**
   * @dev Calculate current funding ratio.
   */
  function currentFundingRatio()
    external
    view
    returns (uint256 numerator, uint256 denominator);

  /**
   * @dev Estimate adjust result.
   * @param _k - Slope
   * @param _tar - Target funding ratio
   * @param _w - Total worth
   * @param _t - Total supply
   * @return success - Whether the calculation was successful
   * @return _c - Current price
   * @return _f - Floor price
   * @return _p - Point of intersection
   */
  function estimateAdjust(
    uint256 _k,
    uint256 _tar,
    uint256 _w,
    uint256 _t
  )
    external
    pure
    returns (
      bool success,
      uint256 _c,
      uint256 _f,
      uint256 _p
    );

  /**
   * @dev Estimate next raise price.
   * @return success - Whether the calculation was successful
   * @return _t - The total supply when the funding ratio reaches targetAdjusted
   * @return _c - The price when the funding ratio reaches targetAdjusted
   * @return _w - The total worth when the funding ratio reaches targetAdjusted
   * @return raisedFloorPrice - The floor price after market adjusted
   */
  function estimateRaisePrice()
    external
    view
    returns (
      bool success,
      uint256 _t,
      uint256 _c,
      uint256 _w,
      uint256 raisedFloorPrice
    );

  /**
   * @dev Estimate raise price by input value.
   * @param _f - Floor price
   * @param _k - Slope
   * @param _p - Floor supply
   * @param _tar - Target funding ratio
   * @param _tarAdjusted - Target adjusted funding ratio
   * @return success - Whether the calculation was successful
   * @return _t - The total supply when the funding ratio reaches _tar
   * @return _c - The price when the funding ratio reaches _tar
   * @return _w - The total worth when the funding ratio reaches _tar
   * @return raisedFloorPrice - The floor price after market adjusted
   */
  function estimateRaisePrice(
    uint256 _f,
    uint256 _k,
    uint256 _p,
    uint256 _tar,
    uint256 _tarAdjusted
  )
    external
    pure
    returns (
      bool success,
      uint256 _t,
      uint256 _c,
      uint256 _w,
      uint256 raisedFloorPrice
    );

  /**
   * @dev Lower target and targetAdjusted with lowerStep.
   */
  function lowerAndAdjust() external;

  /**
   * @dev Set market options.
   *      The caller must has MANAGER_ROLE.
   *      This function can only be called before the market is started.
   * @param _k - Slope
   * @param _target - Target funding ratio
   * @param _targetAdjusted - Target adjusted funding ratio
   */
  function setMarketOptions(
    uint256 _k,
    uint32 _target,
    uint32 _targetAdjusted
  ) external;

  /**
   * @dev Set adjust options.
   *      The caller must be owner.
   * @param _minTarget - Minimum value of target
   * @param _maxTargetAdjusted - Maximum value of the targetAdjusted
   * @param _raiseStep - Step value of each raise
   * @param _lowerStep - Step value of each lower
   * @param _lowerInterval - Interval of each lower
   */
  function setAdjustOptions(
    uint32 _minTarget,
    uint32 _maxTargetAdjusted,
    uint32 _raiseStep,
    uint32 _lowerStep,
    uint32 _lowerInterval
  ) external;

  /**
   * @dev Set fee options.
   *      The caller must be owner.
   * @param _dev - Dev address
   * @param _buyFee - Fee for buying Lab
   * @param _sellFee - Fee for selling Lab
   */
  function setFeeOptions(
    address _dev,
    uint32 _buyFee,
    uint32 _sellFee
  ) external;

  /**
   * @dev Manage stablecoins.
   *      Add/Delete token to/from stablecoinsCanBuy/stablecoinsCanSell.
   *      The caller must be owner.
   * @param token - Token address
   * @param buyOrSell - Buy or sell token
   * @param addOrDelete - Add or delete token
   */
  function manageStablecoins(
    address token,
    bool buyOrSell,
    bool addOrDelete
  ) external;

  /**
   * @dev Estimate how much Lab user can buy.
   * @param token - Stablecoin address
   * @param tokenWorth - Number of stablecoins
   * @return amount - Number of Lab
   * @return fee - Dev fee
   * @return worth1e18 - The amount of stablecoins being exchanged(1e18)
   * @return newPrice - New Lab price
   */
  function estimateBuy(address token, uint256 tokenWorth)
    external
    view
    returns (
      uint256 amount,
      uint256 fee,
      uint256 worth1e18,
      uint256 newPrice
    );

  /**
   * @dev Estimate how many stablecoins will be needed to realize prLab.
   * @param amount - Number of prLab user want to realize
   * @param token - Stablecoin address
   * @return worth1e18 - The amount of stablecoins being exchanged(1e18)
   * @return worth - The amount of stablecoins being exchanged
   */
  function estimateRealize(uint256 amount, address token)
    external
    view
    returns (uint256 worth1e18, uint256 worth);

  /**
   * @dev Estimate how much stablecoins user can sell.
   * @param amount - Number of Lab user want to sell
   * @param token - Stablecoin address
   * @return fee - Dev fee
   * @return worth1e18 - The amount of stablecoins being exchanged(1e18)
   * @return worth - The amount of stablecoins being exchanged
   * @return newPrice - New Lab price
   */
  function estimateSell(uint256 amount, address token)
    external
    view
    returns (
      uint256 fee,
      uint256 worth1e18,
      uint256 worth,
      uint256 newPrice
    );

  /**
   * @dev Buy Lab.
   * @param token - Address of stablecoin used to buy Lab
   * @param tokenWorth - Number of stablecoins
   * @param desired - Minimum amount of Lab user want to buy
   * @return amount - Number of Lab
   * @return fee - Dev fee(Lab)
   */
  function buy(
    address token,
    uint256 tokenWorth,
    uint256 desired
  ) external returns (uint256, uint256);

  /**
   * @dev Buy Lab for user.
   * @param token - Address of stablecoin used to buy Lab
   * @param tokenWorth - Number of stablecoins
   * @param desired - Minimum amount of Lab user want to buy
   * @param user - User address
   * @return amount - Number of Lab
   * @return fee - Dev fee(Lab)
   */
  function buyFor(
    address token,
    uint256 tokenWorth,
    uint256 desired,
    address user
  ) external returns (uint256, uint256);

  /**
   * @dev Realize Lab with floor price and equal amount of prLab.
   * @param amount - Amount of prLab user want to realize
   * @param token - Address of stablecoin used to realize prLab
   * @param desired - Maximum amount of stablecoin users are willing to pay
   * @return worth - The amount of stablecoins being exchanged
   */
  function realize(
    uint256 amount,
    address token,
    uint256 desired
  ) external returns (uint256);

  /**
   * @dev Realize Lab with floor price and equal amount of prLab for user.
   * @param amount - Amount of prLab user want to realize
   * @param token - Address of stablecoin used to realize prLab
   * @param desired - Maximum amount of stablecoin users are willing to pay
   * @param user - User address
   * @return worth - The amount of stablecoins being exchanged
   */
  function realizeFor(
    uint256 amount,
    address token,
    uint256 desired,
    address user
  ) external returns (uint256);

  /**
   * @dev Sell Lab.
   * @param amount - Amount of Lab user want to sell
   * @param token - Address of stablecoin used to buy Lab
   * @param desired - Minimum amount of stablecoins user want to get
   * @return fee - Dev fee(Lab)
   * @return worth - The amount of stablecoins being exchanged
   */
  function sell(
    uint256 amount,
    address token,
    uint256 desired
  ) external returns (uint256, uint256);

  /**
   * @dev Sell Lab for user.
   * @param amount - Amount of Lab user want to sell
   * @param token - Address of stablecoin used to buy Lab
   * @param desired - Minimum amount of stablecoins user want to get
   * @param user - User address
   * @return fee - Dev fee(Lab)
   * @return worth - The amount of stablecoins being exchanged
   */
  function sellFor(
    uint256 amount,
    address token,
    uint256 desired,
    address user
  ) external returns (uint256, uint256);

  /**
   * @dev Burn Lab.
   *      It will preferentially transfer the excess value after burning to PSL.
   * @param amount - The amount of Lab the user wants to burn
   */
  function burn(uint256 amount) external;

  /**
   * @dev Burn Lab for user.
   *      It will preferentially transfer the excess value after burning to PSL.
   * @param amount - The amount of Lab the user wants to burn
   * @param user - User address
   */
  function burnFor(uint256 amount, address user) external;

  /**
   * @dev Triggers stopped state.
   *      The caller must be owner.
   */
  function pause() external;

  /**
   * @dev Returns to normal state.
   *      The caller must be owner.
   */
  function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC20BurnableMinter.sol";
import "./IBank.sol";

// The stakepool will mint prLab according to the total supply of Lab and
// then distribute it to all users according to the amount of Lab deposited by each user.
// Info of each pool.
struct PoolInfo {
  IERC20 lpToken; // Address of LP token contract.
  uint256 allocPoint; // How many allocation points assigned to this pool. prLabs to distribute per block.
  uint256 lastRewardBlock; // Last block number that prLabs distribution occurs.
  uint256 accPerShare; // Accumulated prLabs per share, times 1e12. See below.
}

// Info of each user.
struct UserInfo {
  uint256 amount; // How many LP tokens the user has provided.
  uint256 rewardDebt; // Reward debt. See explanation below.
  //
  // We do some fancy math here. Basically, any point in time, the amount of prLabs
  // entitled to a user but is pending to be distributed is:
  //
  //   pending reward = (user.amount * pool.accPerShare) - user.rewardDebt
  //
  // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
  //   1. The pool's `accPerShare` (and `lastRewardBlock`) gets updated.
  //   2. User receives the pending reward sent to his/her address.
  //   3. User's `amount` gets updated.
  //   4. User's `rewardDebt` gets updated.
}

interface IStakePool {
  // The Lab token
  function Lab() external view returns (IERC20);

  // The prLab token
  function prLab() external view returns (IERC20BurnableMinter);

  // The bank contract address
  function bank() external view returns (IBank);

  // Info of each pool.
  function poolInfo(uint256 index)
    external
    view
    returns (
      IERC20,
      uint256,
      uint256,
      uint256
    );

  // Info of each user that stakes LP tokens.
  function userInfo(uint256 pool, address user)
    external
    view
    returns (uint256, uint256);

  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  function totalAllocPoint() external view returns (uint256);

  // Daily minted Lab as a percentage of total supply, the value is mintPercentPerDay / 1000.
  function mintPercentPerDay() external view returns (uint32);

  // How many blocks are there in a day.
  function blocksPerDay() external view returns (uint256);

  // Developer address.
  function dev() external view returns (address);

  // Withdraw fee(Lab).
  function withdrawFee() external view returns (uint32);

  // Mint fee(prLab).
  function mintFee() external view returns (uint32);

  // Constructor.
  function constructor1(
    IERC20 _Lab,
    IERC20BurnableMinter _prLab,
    IBank _bank,
    address _owner
  ) external;

  function poolLength() external view returns (uint256);

  // Add a new lp to the pool. Can only be called by the owner.
  // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    bool _withUpdate
  ) external;

  // Update the given pool's prLab allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) external;

  // Set options. Can only be called by the owner.
  function setOptions(
    uint32 _mintPercentPerDay,
    uint256 _blocksPerDay,
    address _dev,
    uint32 _withdrawFee,
    uint32 _mintFee,
    bool _withUpdate
  ) external;

  // View function to see pending prLabs on frontend.
  function pendingRewards(uint256 _pid, address _user)
    external
    view
    returns (uint256);

  // Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() external;

  // Deposit LP tokens to StakePool for prLab allocation.
  function deposit(uint256 _pid, uint256 _amount) external;

  // Deposit LP tokens to StakePool for user for prLab allocation.
  function depositFor(
    uint256 _pid,
    uint256 _amount,
    address _user
  ) external;

  // Withdraw LP tokens from StakePool.
  function withdraw(uint256 _pid, uint256 _amount) external;

  // Claim reward.
  function claim(uint256 _pid) external;

  // Claim reward for user.
  function claimFor(uint256 _pid, address _user) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20BurnableMinter.sol";
import "./interfaces/IStakePool.sol";
import "./interfaces/IBank.sol";

// The stakepool will mint prLab according to the total supply of Lab and
// then distribute it to all users according to the amount of Lab deposited by each user.
contract StakePool is Ownable {
  using SafeERC20 for IERC20;

bool bankSet = false;
  // The Lab token
  IERC20 public Lab;
  // The prLab token
  IERC20BurnableMinter public prLab;
  // The bank contract
  IBank public bank;
  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;

  // Daily minted Lab as a percentage of Lab total supply.
  uint32 public mintPercentPerDay = 0;
  // How many blocks are there in a day.
  uint256 public blocksPerDay = 0;

  // Developer address.
  address public dev;
  // Withdraw fee(Lab).
  uint32 public withdrawFee = 0;
  // Mint fee(prLab).
  uint32 public mintFee = 0;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

  event Withdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount,
    uint256 fee
  );

  event OptionsChanged(
    uint32 mintPercentPerDay,
    uint256 blocksPerDay,
    address dev,
    uint32 withdrawFee,
    uint32 mintFee
  );

  // Constructor.
  constructor(IERC20 _Lab, IERC20BurnableMinter _prLab) {
    Lab = _Lab;
    prLab = _prLab;
  }

  function setBank(IBank _bank) external onlyOwner {
    require(!bankSet, "AlreadySet");
    bank = _bank;
    bankSet = true;
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  // Add a new lp to the pool. Can only be called by the owner.
  // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    bool _withUpdate
  ) external onlyOwner {
    // when _pid is 0, it is Lab pool
    if (poolInfo.length == 0) {
      require(address(_lpToken) == address(Lab), "StakePool: invalid lp token");
    }

    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint + _allocPoint;
    poolInfo.push(
      PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: block.number,
        accPerShare: 0
      })
    );
  }

  // Update the given pool's prLab allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) external onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  // Set options. Can only be called by the owner.
  function setOptions(
    uint32 _mintPercentPerDay,
    uint256 _blocksPerDay,
    address _dev,
    uint32 _withdrawFee,
    uint32 _mintFee,
    bool _withUpdate
  ) public onlyOwner {
    require(
      _mintPercentPerDay <= 10000,
      "StakePool: mintPercentPerDay is too large"
    );
    require(_blocksPerDay > 0, "StakePool: blocksPerDay is zero");
    require(_dev != address(0), "StakePool: zero dev address");
    require(_withdrawFee <= 10000, "StakePool: invalid withdrawFee");
    require(_mintFee <= 10000, "StakePool: invalid mintFee");
    if (_withUpdate) {
      massUpdatePools();
    }
    mintPercentPerDay = _mintPercentPerDay;
    blocksPerDay = _blocksPerDay;
    dev = _dev;
    withdrawFee = _withdrawFee;
    mintFee = _mintFee;
    emit OptionsChanged(
      _mintPercentPerDay,
      _blocksPerDay,
      _dev,
      _withdrawFee,
      _mintFee
    );
  }

  // View function to see pending prLabs on frontend.
  function pendingRewards(uint256 _pid, address _user)
    external
    view
    returns (uint256)
  {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accPerShare = pool.accPerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 pendingReward = (Lab.totalSupply() *
        1e12 *
        mintPercentPerDay *
        (block.number - pool.lastRewardBlock) *
        pool.allocPoint) / (10000 * blocksPerDay * totalAllocPoint);
      accPerShare += pendingReward / lpSupply;
    }
    return (user.amount * accPerShare) / 1e12 - user.rewardDebt;
  }

  // Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 totalSupply = Lab.totalSupply();
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid, totalSupply);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid, uint256 _totalSupply) internal {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0 || totalAllocPoint == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 pendingReward = (_totalSupply *
      1e12 *
      mintPercentPerDay *
      (block.number - pool.lastRewardBlock) *
      pool.allocPoint) / (10000 * blocksPerDay * totalAllocPoint);
    uint256 mint = pendingReward / 1e12;
    prLab.mint(dev, (mint * mintFee) / 10000);
    prLab.mint(address(this), mint);
    pool.accPerShare += pendingReward / lpSupply;
    pool.lastRewardBlock = block.number;
  }

  // Deposit LP tokens to StakePool for prLab allocation.
  function deposit(uint256 _pid, uint256 _amount) external {
    depositFor(_pid, _amount, msg.sender);
  }

  // Deposit LP tokens to StakePool for user for prLab allocation.
  function depositFor(
    uint256 _pid,
    uint256 _amount,
    address _user
  ) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    updatePool(_pid, Lab.totalSupply());
    if (user.amount > 0) {
      uint256 pending = (user.amount * pool.accPerShare) /
        1e12 -
        user.rewardDebt;
      if (pending > 0) {
        safeTransfer(_user, pending);
      }
    }
    pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    user.amount = user.amount + _amount;
    user.rewardDebt = (user.amount * pool.accPerShare) / 1e12;
    emit Deposit(_user, _pid, _amount);
  }

  // Withdraw LP tokens from StakePool.
  function withdraw(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "StakePool: withdraw not good");
    updatePool(_pid, Lab.totalSupply());
    uint256 pending = (user.amount * pool.accPerShare) / 1e12 - user.rewardDebt;
    if (pending > 0) {
      safeTransfer(msg.sender, pending);
    }

    // when _pid is 0, it is Lab pool,
    // so we have to check the amount that can be withdrawn,
    // and calculate dev fee
    uint256 fee = 0;
    if (_pid == 0) {
      uint256 withdrawable = bank.withdrawable(msg.sender, user.amount);
      require(
        withdrawable >= _amount,
        "StakePool: amount exceeds withdrawable"
      );
      fee = (_amount * withdrawFee) / 10000;
    }

    user.amount = user.amount - _amount;
    user.rewardDebt = (user.amount * pool.accPerShare) / 1e12;
    pool.lpToken.safeTransfer(msg.sender, _amount - fee);
    pool.lpToken.safeTransfer(dev, fee);
    emit Withdraw(msg.sender, _pid, _amount - fee, fee);
  }

  // Claim reward.
  function claim(uint256 _pid) external {
    claimFor(_pid, msg.sender);
  }

  // Claim reward for user.
  function claimFor(uint256 _pid, address _user) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    require(user.amount > 0, "StakePool: claim not good");
    updatePool(_pid, Lab.totalSupply());
    uint256 pending = (user.amount * pool.accPerShare) / 1e12 - user.rewardDebt;
    if (pending > 0) {
      safeTransfer(_user, pending);
      user.rewardDebt = (user.amount * pool.accPerShare) / 1e12;
    }
  }

  // Safe prLab transfer function, just in case if rounding error causes pool to not have enough prLabs.
  function safeTransfer(address _to, uint256 _amount) internal {
    uint256 prLabBal = prLab.balanceOf(address(this));
    if (_amount > prLabBal) {
      prLab.transfer(_to, prLabBal);
    } else {
      prLab.transfer(_to, _amount);
    }
  }
}