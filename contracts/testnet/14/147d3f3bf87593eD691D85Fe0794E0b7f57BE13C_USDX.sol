/**
 *Submitted for verification at Arbiscan on 2022-07-15
*/

// File: contracts/_external/compound/ExponentialNoError.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
  uint256 constant expScale = 1e18;
  uint256 constant doubleScale = 1e36;
  uint256 constant halfExpScale = expScale / 2;
  uint256 constant mantissaOne = expScale;
  uint256 constant uint192Max = 2**192 - 1;
  uint256 constant uint128Max = 2**128 - 1;

  struct Exp {
    uint256 mantissa;
  }

  struct Double {
    uint256 mantissa;
  }

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
   */
  function truncate(Exp memory exp) internal pure returns (uint256) {
    return exp.mantissa / expScale;
  }

  function truncate(uint256 u) internal pure returns (uint256) {
    return u / expScale;
  }

  function safeu192(uint256 u) internal pure returns (uint192) {
    require(u < uint192Max, "overflow");
    return uint192(u);
  }

  function safeu128(uint256 u) internal pure returns (uint128) {
    require(u < uint128Max, "overflow");
    return uint128(u);
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mul_ScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (uint256) {
    Exp memory product = mul_(a, scalar);
    return truncate(product);
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mul_ScalarTruncateAddUInt(
    Exp memory a,
    uint256 scalar,
    uint256 addend
  ) internal pure returns (uint256) {
    Exp memory product = mul_(a, scalar);
    return add_(truncate(product), addend);
  }

  /**
   * @dev Checks if first Exp is less than second Exp.
   */
  function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa < right.mantissa;
  }

  /**
   * @dev Checks if left Exp <= right Exp.
   */
  function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa <= right.mantissa;
  }

  /**
   * @dev Checks if left Exp > right Exp.
   */
  function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa > right.mantissa;
  }

  /**
   * @dev returns true if Exp is exactly zero
   */
  function isZeroExp(Exp memory value) internal pure returns (bool) {
    return value.mantissa == 0;
  }

  function safe224(uint256 n, string memory errorMessage) internal pure returns (uint224) {
    require(n < 2**224, errorMessage);
    return uint224(n);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(uint256 a, uint256 b) internal pure returns (uint256) {
    return add_(a, b, "addition overflow");
  }

  function add_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub_(a, b, "subtraction underflow");
  }

  function sub_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
  }

  function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / expScale;
  }

  function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
  }

  function mul_(Double memory a, uint256 b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / doubleScale;
  }

  function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
    return mul_(a, b, "multiplication overflow");
  }

  function mul_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, errorMessage);
    return c;
  }

  function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
  }

  function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return div_(mul_(a, expScale), b.mantissa);
  }

  function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
  }

  function div_(Double memory a, uint256 b) internal pure returns (Double memory) {
    return Double({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint256 a, Double memory b) internal pure returns (uint256) {
    return div_(mul_(a, doubleScale), b.mantissa);
  }

  function div_(uint256 a, uint256 b) internal pure returns (uint256) {
    return div_(a, b, "divide by zero");
  }

  function div_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function fraction(uint256 a, uint256 b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a, doubleScale), b)});
  }
}

// File: contracts/_external/openzeppelin/AddressUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity 0.8.9;

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
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
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
    return functionCall(target, data, "Address: low-level call failed");
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
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
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
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
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
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

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

// File: contracts/_external/openzeppelin/IERC20Upgradeable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

// File: contracts/_external/openzeppelin/SafeERC20Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: contracts/_external/Context.sol


pragma solidity 0.8.9;

/*
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
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File: contracts/_external/CompLike.sol


pragma solidity 0.8.9;

interface CompLike {
  function delegate(address delegatee) external;
}

// File: contracts/lending/IVaultController.sol


pragma solidity 0.8.9;

// @title VaultController Events
/// @notice interface which contains any events which the VaultController contract emits
interface VaultControllerEvents {
  event InterestEvent(uint64 epoch, uint192 amount, uint256 curve_val);
  event NewProtocolFee(uint256 protocol_fee);
  event RegisteredErc20(address token_address, uint256 LTVe4, address oracle_address, uint256 liquidationIncentivee4);
  event UpdateRegisteredErc20(
    address token_address,
    uint256 LTVe4,
    address oracle_address,
    uint256 liquidationIncentivee4
  );
  event NewVault(address vault_address, uint256 vaultId, address vaultOwner);
  event RegisterOracleMaster(address oracleMasterAddress);
  event RegisterCurveMaster(address curveMasterAddress);
  event BorrowUSDx(uint256 vaultId, address vaultAddress, uint256 borrowAmount);
  event RepayUSDx(uint256 vaultId, address vaultAddress, uint256 repayAmount);
  event Liquidate(uint256 vaultId, address asset_address, uint256 usdx_to_repurchase, uint256 tokens_to_liquidate);
}

/// @title VaultController Interface
/// @notice extends VaultControllerEvents
interface IVaultController is VaultControllerEvents {
  // initializer
  function initialize() external;

  // view functions

  function tokensRegistered() external view returns (uint256);

  function vaultsMinted() external view returns (uint96);

  function lastInterestTime() external view returns (uint64);

  function totalBaseLiability() external view returns (uint192);

  function interestFactor() external view returns (uint192);

  function protocolFee() external view returns (uint192);

  function vaultAddress(uint96 id) external view returns (address);

  function vaultIDs(address wallet) external view returns (uint96[] memory);

  function amountToSolvency(uint96 id) external view returns (uint256);

  function vaultLiability(uint96 id) external view returns (uint192);

  function vaultBorrowingPower(uint96 id) external view returns (uint192);

  function tokensToLiquidate(uint96 id, address token) external view returns (uint256);

  function checkVault(uint96 id) external view returns (bool);

  struct VaultSummary {
    uint96 id;
    uint192 borrowingPower;
    uint192 vaultLiability;
    address[] tokenAddresses;
    uint256[] tokenBalances;
  }
  function vaultSummaries(uint96 start, uint96 stop) external view returns (VaultSummary[] memory);

  // interest calculations
  function calculateInterest() external returns (uint256);

  // vault management business
  function mintVault() external returns (address);

  function liquidateVault(
    uint96 id,
    address asset_address,
    uint256 tokenAmount
  ) external returns (uint256);

  function borrowUsdx(uint96 id, uint192 amount) external;

  function repayUSDx(uint96 id, uint192 amount) external;

  function repayAllUSDx(uint96 id) external;

  // admin
  function pause() external;

  function unpause() external;

  function getOracleMaster() external view returns (address);

  function registerOracleMaster(address master_oracle_address) external;

  function getCurveMaster() external view returns (address);

  function registerCurveMaster(address master_curve_address) external;

  function changeProtocolFee(uint192 new_protocol_fee) external;

  function registerErc20(
    address token_address,
    uint256 LTV,
    address oracle_address,
    uint256 liquidationIncentive
  ) external;

  function registerUSDx(address usdx_address) external;

  function updateRegisteredErc20(
    address token_address,
    uint256 LTV,
    address oracle_address,
    uint256 liquidationIncentive
  ) external;
}

// File: contracts/lending/IVault.sol


pragma solidity 0.8.9;

// @title Vault Events
/// @notice interface which contains any events which the Vault contract emits
interface VaultEvents {
  event Deposit(address token_address, uint256 amount);
  event Withdraw(address token_address, uint256 amount);
}

/// @title Vault Interface
/// @notice extends VaultEvents
interface IVault is VaultEvents {
  /// @notice value of _baseLiability
  function baseLiability() external view returns (uint256);
  /// @notice value of _vaultInfo.minter
  function minter() external view returns (address);
  /// @notice value of _vaultInfo.id
  function id() external view returns (uint96);
  /// @notice value of _tokenBalance
  function tokenBalance(address) external view returns (uint256);

  // business logic

  function withdrawErc20(address token_address, uint256 amount) external;
  function delegateCompLikeTo(address compLikeDelegatee, address compLikeToken) external;

  // administrative functions
  function controllerTransfer(
    address _token,
    address _to,
    uint256 _amount
  ) external;

  function modifyLiability(bool increase, uint256 base_amount) external returns (uint256);
}

// File: contracts/_external/openzeppelin/Initializable.sol


// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity 0.8.9;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(_initializing || !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }
  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} modifier, directly or indirectly.
   */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }
}

// File: contracts/_external/openzeppelin/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity 0.8.9;


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
  function __Context_init() internal initializer {
    __Context_init_unchained();
  }

  function __Context_init_unchained() internal initializer {}

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

  uint256[50] private __gap;
}

// File: contracts/_external/openzeppelin/PausableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity 0.8.9;



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
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
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
    require(!paused(), "Pausable: paused");
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
    require(paused(), "Pausable: not paused");
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

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// File: contracts/_external/openzeppelin/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity 0.8.9;



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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
    _transferOwnership(_msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

  uint256[49] private __gap;
}

// File: contracts/_external/IERC20.sol



pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

// File: contracts/_external/ERC20Detailed.sol

pragma solidity 0.8.9;



/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
abstract contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
    constructor(string memory name_, string memory symbol_, uint8 decimals_){
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
     */

  function __ERC20Detailed_init(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) public initializer {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  /**
   * @return the name of the token.
   */
  function name() public view virtual returns (string memory) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view virtual returns (uint8) {
    return _decimals;
  }

  uint256[50] private ______gap;
}

// File: contracts/token/UFragments.sol


/* solhint-disable */
pragma solidity 0.8.9;




/**
 * @title uFragments ERC20 token
 * @dev USDX uses the uFragments concept from the Ideal Money project to pay interest
 *      Implementation is shamelessly borrowed from Ampleforth project
 *      uFragments is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *
 *      uFragment balances are internally represented with a hidden denomination, 'gons'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'gons' and the public 'fragments'.
 */
contract UFragments is Initializable, OwnableUpgradeable, ERC20Detailed {
  // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
  // Anytime there is division, there is a risk of numerical instability from rounding errors. In
  // order to minimize this risk, we adhere to the following guidelines:
  // 1) The conversion rate adopted is the number of gons that equals 1 fragment.
  //    The inverse rate must not be used--_totalGons is always the numerator and _totalSupply is
  //    always the denominator. (i.e. If you want to convert gons to fragments instead of
  //    multiplying by the inverse rate, you should divide by the normal rate)
  // 2) Gon balances converted into Fragments are always rounded down (truncated).
  //
  // We make the following guarantees:
  // - If address 'A' transfers x Fragments to address 'B'. A's resulting external balance will
  //   be decreased by precisely x Fragments, and B's external balance will be precisely
  //   increased by x Fragments.
  //
  // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
  // This is because, for any conversion function 'f()' that has non-zero rounding error,
  // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).

  event LogRebase(uint256 indexed epoch, uint256 totalSupply);
  event LogMonetaryPolicyUpdated(address monetaryPolicy);

  // Used for authentication
  address public monetaryPolicy;

  modifier onlyMonetaryPolicy() {
    require(msg.sender == monetaryPolicy);
    _;
  }

  modifier validRecipient(address to) {
    require(to != address(0x0));
    require(to != address(this));
    _;
  }

  uint256 private constant DECIMALS = 18;
  uint256 private constant MAX_UINT256 = 2**256 - 1;
  uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1 * 10**DECIMALS;

  // _totalGons is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
  // Use the highest value that fits in a uint256 for max granularity.
  uint256 public _totalGons; // = INITIAL_FRAGMENTS_SUPPLY * 10**48;

  // MAX_SUPPLY = maximum integer < (sqrt(4*_totalGons + 1) - 1) / 2
  uint256 public MAX_SUPPLY; // = type(uint128).max; // (2^128) - 1

  uint256 public _totalSupply;
  uint256 public _gonsPerFragment;
  mapping(address => uint256) public _gonBalances;

  // This is denominated in Fragments, because the gons-fragments conversion might change before
  // it's fully paid.
  mapping(address => mapping(address => uint256)) private _allowedFragments;

  // EIP-2612: permit – 712-signed approvals
  // https://eips.ethereum.org/EIPS/eip-2612
  string public constant EIP712_REVISION = "1";
  bytes32 public constant EIP712_DOMAIN =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  // EIP-2612: keeps track of number of permits per address
  mapping(address => uint256) private _nonces;

  function __UFragments_init(string memory name, string memory symbol) public initializer {
    __Ownable_init();
    __ERC20Detailed_init(name, symbol, uint8(DECIMALS));

    //set og initial values
    _totalGons = INITIAL_FRAGMENTS_SUPPLY * 10**48;
    MAX_SUPPLY = 2**128 - 1;

    _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
    _gonBalances[address(0x0)] = _totalGons; //send starting supply to a burner address so _totalSupply is never 0
    _gonsPerFragment = _totalGons / _totalSupply;

    emit Transfer(address(this), address(0x0), _totalSupply);
  }

  /**
   * @param monetaryPolicy_ The address of the monetary policy contract to use for authentication.
   */
  function setMonetaryPolicy(address monetaryPolicy_) external onlyOwner {
    monetaryPolicy = monetaryPolicy_;
    emit LogMonetaryPolicyUpdated(monetaryPolicy_);
  }

  /**
   * @dev Notifies Fragments contract about a new rebase cycle.
   * @param supplyAdd The number of new fragment tokens to add into circulation via expansion.
   * @param supplyRemove The number of new fragment tokens to remove into circulation via expansion.
   * @return The total number of fragments after the supply adjustment.
   */
  function rebase(
    uint256 epoch,
    uint256 supplyAdd,
    uint256 supplyRemove
  ) external onlyMonetaryPolicy returns (uint256) {
    if (supplyAdd == 0 && supplyRemove == 0) {
      emit LogRebase(epoch, _totalSupply);
      return _totalSupply;
    }

    if (supplyAdd > 0) {
      _totalSupply = _totalSupply + supplyAdd;
    } else {
      _totalSupply = _totalSupply - supplyRemove;
    }

    if (_totalSupply > MAX_SUPPLY) {
      _totalSupply = MAX_SUPPLY;
    }

    _gonsPerFragment = _totalGons / _totalSupply;

    // From this point forward, _gonsPerFragment is taken as the source of truth.
    // We recalculate a new _totalSupply to be in agreement with the _gonsPerFragment
    // conversion rate.
    // This means our applied Deltas can deviate from the requested Deltas,
    // but this deviation is guaranteed to be < (_totalSupply^2)/(_totalGons - _totalSupply).
    //
    // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
    // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
    // ever increased, it must be re-included.
    // _totalSupply = _totalGons - _gonsPerFragment

    emit LogRebase(epoch, _totalSupply);
    return _totalSupply;
  }

  /**
   * @return The total number of fragments.
   */
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @param who The address to query.
   * @return The balance of the specified address.
   */
  function balanceOf(address who) external view override returns (uint256) {
    return _gonBalances[who] / _gonsPerFragment;
  }

  /**
   * @param who The address to query.
   * @return The gon balance of the specified address.
   */
  function scaledBalanceOf(address who) external view returns (uint256) {
    return _gonBalances[who];
  }

  /**
   * @return the total number of gons.
   */
  function scaledTotalSupply() external view returns (uint256) {
    return _totalGons;
  }

  /**
   * @return The number of successful permits by the specified address.
   */
  function nonces(address who) public view returns (uint256) {
    return _nonces[who];
  }

  /**
   * @return The computed DOMAIN_SEPARATOR to be used off-chain services
   *         which implement EIP-712.
   *         https://eips.ethereum.org/EIPS/eip-2612
   */
  function DOMAIN_SEPARATOR() public view returns (bytes32) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return
      keccak256(
        abi.encode(EIP712_DOMAIN, keccak256(bytes(name())), keccak256(bytes(EIP712_REVISION)), chainId, address(this))
      );
  }

  /**
   * @dev Transfer tokens to a specified address.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   * @return True on success, false otherwise.
   */
  function transfer(address to, uint256 value) external override validRecipient(to) returns (bool) {
    uint256 gonValue = value * _gonsPerFragment;

    _gonBalances[msg.sender] = _gonBalances[msg.sender] - gonValue;
    _gonBalances[to] = _gonBalances[to] + gonValue;

    emit Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Transfer all of the sender's wallet balance to a specified address.
   * @param to The address to transfer to.
   * @return True on success, false otherwise.
   */
  function transferAll(address to) external validRecipient(to) returns (bool) {
    uint256 gonValue = _gonBalances[msg.sender];
    uint256 value = gonValue / _gonsPerFragment;

    delete _gonBalances[msg.sender];
    _gonBalances[to] = _gonBalances[to] + gonValue;

    emit Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner has allowed to a spender.
   * @param owner_ The address which owns the funds.
   * @param spender The address which will spend the funds.
   * @return The number of tokens still available for the spender.
   */
  function allowance(address owner_, address spender) external view override returns (uint256) {
    return _allowedFragments[owner_][spender];
  }

  /**
   * @dev Transfer tokens from one address to another.
   * @param from The address you want to send tokens from.
   * @param to The address you want to transfer to.
   * @param value The amount of tokens to be transferred.
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external override validRecipient(to) returns (bool) {
    _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender] - value;

    uint256 gonValue = value * _gonsPerFragment;
    _gonBalances[from] = _gonBalances[from] - gonValue;
    _gonBalances[to] = _gonBalances[to] + gonValue;

    emit Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Transfer all balance tokens from one address to another.
   * @param from The address you want to send tokens from.
   * @param to The address you want to transfer to.
   */
  function transferAllFrom(address from, address to) external validRecipient(to) returns (bool) {
    uint256 gonValue = _gonBalances[from];
    uint256 value = gonValue / _gonsPerFragment;

    _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender] - value;

    delete _gonBalances[from];
    _gonBalances[to] = _gonBalances[to] + gonValue;

    emit Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of
   * msg.sender. This method is included for ERC20 compatibility.
   * increaseAllowance and decreaseAllowance should be used instead.
   * Changing an allowance with this method brings the risk that someone may transfer both
   * the old and the new allowance - if they are both greater than zero - if a transfer
   * transaction is mined before the later approve() call is mined.
   *
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) external override returns (bool) {
    _allowedFragments[msg.sender][spender] = value;

    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner has allowed to a spender.
   * This method should be used instead of approve() to avoid the double approval vulnerability
   * described above.
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender] + addedValue;

    emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner has allowed to a spender.
   *
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    uint256 oldValue = _allowedFragments[msg.sender][spender];
    _allowedFragments[msg.sender][spender] = (subtractedValue >= oldValue) ? 0 : oldValue - subtractedValue;

    emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Allows for approvals to be made via secp256k1 signatures.
   * @param owner The owner of the funds
   * @param spender The spender
   * @param value The amount
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v Signature param
   * @param s Signature param
   * @param r Signature param
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    require(block.timestamp <= deadline);

    uint256 ownerNonce = _nonces[owner];
    bytes32 permitDataDigest = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, ownerNonce, deadline));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), permitDataDigest));

    require(owner == ecrecover(digest, v, r, s));
    require(owner != address(0x0));

    _nonces[owner] = ownerNonce + 1;

    _allowedFragments[owner][spender] = value;
    emit Approval(owner, spender, value);
  }
}
/* solhint-enable */

// File: contracts/_external/IERC20Metadata.sol



pragma solidity 0.8.9;


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

// File: contracts/IUSDX.sol


pragma solidity 0.8.9;


/// @title USDX Events
/// @notice interface which contains any events which the USDX contract emits
interface USDXEvents {
  event Deposit(address indexed _from, uint256 _value);
  event Withdraw(address indexed _from, uint256 _value);
  event Mint(address to, uint256 _value);
  event Burn(address from, uint256 _value);
  event Donation(address indexed _from, uint256 _value, uint256 _totalSupply);
}

/// @title USDX Interface
/// @notice extends USDXEvents and IERC20Metadata
interface IUSDX is IERC20Metadata, USDXEvents {
  /// @notice initializer specifies the reserveAddress
  function initialize(address reserveAddress) external;

  // getters
  function reserveRatio() external view returns (uint192);

  function reserveAddress() external view returns (address);

  // owner
  function owner() external view returns (address);

  // business
  function deposit(uint256 usdc_amount) external;

  function withdraw(uint256 usdc_amount) external;

  function withdrawAll() external;

  function donate(uint256 usdc_amount) external;

  function donateReserve() external;

  // admin functions

  function setPauser(address pauser_) external;

  function pauser() external view returns (address);

  function pause() external;

  function unpause() external;

  function mint(uint256 usdc_amount) external;

  function burn(uint256 usdc_amount) external;

  function setVaultController(address vault_master_address) external;

  function getVaultController() external view returns (address);

  // functions for the vault controller to call
  function vaultControllerBurn(address target, uint256 amount) external;

  function vaultControllerMint(address target, uint256 amount) external;

  function vaultControllerDonate(uint256 amount) external;
}

// File: contracts/lending/Vault.sol


pragma solidity 0.8.9;

//import "../_external/IWETH.sol";



/// @title Vault
/// @notice our implentation of maker-vault like vault
/// major differences:
/// 1. multi-collateral
/// 2. generate interest in USDx
/// 3. can delegate voting power of contained tokens
contract Vault is IVault, Context {
  using SafeERC20Upgradeable for IERC20;

  /// @title VaultInfo struct
  /// @notice this struct is used to store the vault metadata
  /// this should reduce the cost of minting by ~15,000
  /// by limiting us to max 2**96-1 vaults
  struct VaultInfo {
    uint96 id;
    address minter;
  }
  /// @notice Metadata of vault, aka the id & the minter's address
  VaultInfo public _vaultInfo;
  IVaultController public immutable _controller;

  /// @notice this is the unscaled liability of the vault.
  /// the number is meaningless on its own, and must be combined with the factor taken from
  /// the vaultController in order to find the true liabilitiy
  uint256 public _baseLiability;

  /// @notice checks if _msgSender is the controller of the vault
  modifier onlyVaultController() {
    require(_msgSender() == address(_controller), "sender not VaultController");
    _;
  }

  /// @notice checks if _msgSender is the minter of the vault
  modifier onlyMinter() {
    require(_msgSender() == _vaultInfo.minter, "sender not minter");
    _;
  }

  /// @notice must be called by VaultController, else it will not be registered as a vault in system
  /// @param id_ unique id of the vault, ever increasing and tracked by VaultController
  /// @param minter_ address of the person who created this vault
  /// @param controller_address address of the VaultController
  constructor(
    uint96 id_,
    address minter_,
    address controller_address
  ) {
    _vaultInfo = VaultInfo(id_, minter_);
    _controller = IVaultController(controller_address);
  }

  /// @notice minter of the vault
  /// @return address of minter
  function minter() external view override returns (address) {
    return _vaultInfo.minter;
  }

  /// @notice id of the vault
  /// @return address of minter
  function id() external view override returns (uint96) {
    return _vaultInfo.id;
  }

  /// @notice current vault base liability
  /// @return base liability of vault
  function baseLiability() external view override returns (uint256) {
    return _baseLiability;
  }

  /// @notice get vaults balance of an erc20 token
  /// @param addr address of the erc20 token
  /// @dev scales wBTC up to normal erc20 size
  function tokenBalance(address addr) external view override returns (uint256) {
    return IERC20(addr).balanceOf(address(this));
  }

  /// @notice withdraw an erc20 token from the vault
  /// this can only be called by the minter
  /// the withdraw will be denied if ones vault would become insolvent
  /// @param token_address address of erc20 token
  /// @param amount amount of erc20 token to withdraw
  function withdrawErc20(address token_address, uint256 amount) external override onlyMinter {
    // transfer the token to the owner
    SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token_address), _msgSender(), amount);
    //  check if the account is solvent
    require(_controller.checkVault(_vaultInfo.id), "over-withdrawal");
    emit Withdraw(token_address, amount);
  }

  /// @notice delegate the voting power of a comp-like erc20 token to another address
  /// @param delegatee address that will receive the votes
  /// @param token_address address of comp-like erc20 token
  function delegateCompLikeTo(address delegatee, address token_address) external override onlyMinter {
    CompLike(token_address).delegate(delegatee);
  }

  /// @notice function used by the VaultController to transfer tokens
  /// callable by the VaultController only
  /// @param _token token to transfer
  /// @param _to person to send the coins to
  /// @param _amount amount of coins to move
  function controllerTransfer(
    address _token,
    address _to,
    uint256 _amount
  ) external override onlyVaultController {
    SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), _to, _amount);
  }

  /// @notice function used by the VaultController to reduce a vaults liability
  /// callable by the VaultController only
  /// @param increase true to increase, false to decerase
  /// @param base_amount amount to reduce base liability by
  function modifyLiability(bool increase, uint256 base_amount) external override onlyVaultController returns (uint256) {
    if (increase) {
      _baseLiability = _baseLiability + base_amount;
    } else {
      // require statement only valid for repayment
      require(_baseLiability >= base_amount, "repay too much");
      _baseLiability = _baseLiability - base_amount;
    }
    return _baseLiability;
  }
}

// File: contracts/USDX.sol


pragma solidity 0.8.9;


/// @title USDX token contract
/// @notice handles all minting/burning of usdx
/// @dev extends UFragments
contract USDX is Initializable, PausableUpgradeable, UFragments, IUSDX, ExponentialNoError {
  IERC20 public _reserve;
  IVaultController public _VaultController;

  address public _pauser;

  /// @notice checks if _msgSender() is VaultController
  modifier onlyVaultController() {
    require(_msgSender() == address(_VaultController), "only VaultController");
    _;
  }

  /// @notice checks if _msgSender() is pauser
  modifier onlyPauser() {
    require(_msgSender() == address(_pauser), "only pauser");
    _;
  }

  /// @notice any function with this modifier will call the pay_interest() function before any function logic is called
  modifier paysInterest() {
    _VaultController.calculateInterest();
    _;
  }

  /// @notice initializer for contract
  /// @param reserveAddr the address of USDC
  /// @dev consider adding decimals?
  function initialize(address reserveAddr) public override initializer {
    __UFragments_init("USDX Token", "USDX");
    __Pausable_init();
    _reserve = IERC20(reserveAddr);
  }

  ///@notice sets the pauser for both USDX and VaultController
  ///@notice the pauser is a separate role from the owner
  function setPauser(address pauser_) external override onlyOwner {
    _pauser = pauser_;
  }

  /// @notice pause contract, pauser only
  function pause() external override onlyPauser {
    _pause();
  }

  /// @notice unpause contract, pauser only
  function unpause() external override onlyPauser {
    _unpause();
  }

  ///@notice gets the pauser for both USDX and VaultController
  function pauser() public view returns (address) {
    return _pauser;
  }

  ///@notice gets the owner of the USDX contract
  function owner() public view override(IUSDX, OwnableUpgradeable) returns (address) {
    return super.owner();
  }

  /// @notice getter for name
  /// @return name of token
  function name() public view override(IERC20Metadata, ERC20Detailed) returns (string memory) {
    return super.name();
  }

  /// @notice getter for symbol
  /// @return symbol for token
  function symbol() public view override(IERC20Metadata, ERC20Detailed) returns (string memory) {
    return super.symbol();
  }

  /// @notice getter for decimals
  /// @return decimals for token
  function decimals() public view override(IERC20Metadata, ERC20Detailed) returns (uint8) {
    return super.decimals();
  }

  /// @notice getter for address of the reserve currency, or usdc
  /// @return decimals for of reserve currency
  function reserveAddress() public view override returns (address) {
    return address(_reserve);
  }

  /// @notice get the VaultController addr
  /// @return vaultcontroller addr
  function getVaultController() public view override returns (address) {
    return address(_VaultController);
  }

  /// @notice set the VaultController addr so that vault_master may mint/burn USDx without restriction
  /// @param vault_master_address address of vault master
  function setVaultController(address vault_master_address) external override onlyOwner {
    _VaultController = IVaultController(vault_master_address);
  }

  /// @notice deposit USDC to mint USDx
  /// @dev caller should obtain 1e12 USDx for each USDC
  /// the calculations for deposit mimic the calculations done by mint in the ampleforth contract, simply with the usdc transfer
  /// "fragments" are the units that we see, so 1000 fragments == 1000 USDx
  /// "gons" are the internal accounting unit, used to keep scale.
  /// we use the variable _gonsPerFragment in order to convert between the two
  /// try dimensional analysis when doing the math in order to verify units are correct
  /// @param usdc_amount amount of USDC to deposit
  function deposit(uint256 usdc_amount) external override paysInterest whenNotPaused {
    // scale the usdc_amount to the usdx decimal amount, aka 1e18. since usdc is 6 decimals, we multiply by 1e12
    uint256 amount = usdc_amount * 1e12;
    require(amount > 0, "Cannot deposit 0");
    // check allowance and ensure transfer success
    uint256 allowance = _reserve.allowance(_msgSender(), address(this));
    require(allowance >= usdc_amount, "Insufficient Allowance");
    require(_reserve.transferFrom(_msgSender(), address(this), usdc_amount), "transfer failed");
    // the gonbalances of the sender is in gons, therefore we must multiply the deposit amount, which is in fragments, by gonsperfragment
    _gonBalances[_msgSender()] = _gonBalances[_msgSender()] + amount * _gonsPerFragment;
    // total supply is in fragments, and so we add amount
    _totalSupply = _totalSupply + amount;
    // and totalgons of course is in gons, and so we multiply amount by gonsperfragment to get the amount of gons we must add to totalGons
    _totalGons = _totalGons + amount * _gonsPerFragment;

    emit Transfer(address(0), _msgSender(), amount);
    emit Deposit(_msgSender(), amount);
  }

  /// @notice withdraw USDC by burning USDx
  /// caller should obtain 1 USDC for every 1e12 USDx
  /// @param usdc_amount amount of USDC to withdraw
  function withdraw(uint256 usdc_amount) external override paysInterest whenNotPaused {
    // scale the usdc_amount to the USDx decimal amount, aka 1e18
    uint256 amount = usdc_amount * 1e12;
    // check balances all around
    require(amount <= this.balanceOf(_msgSender()), "insufficient funds");
    require(amount > 0, "Cannot withdraw 0");
    uint256 balance = _reserve.balanceOf(address(this));
    require(balance >= usdc_amount, "Insufficient Reserve in Bank");
    // ensure transfer success
    require(_reserve.transfer(_msgSender(), usdc_amount), "transfer failed");
    // modify the gonbalances of the sender, subtracting the amount of gons, therefore amount*gonsperfragment
    _gonBalances[_msgSender()] = _gonBalances[_msgSender()] - amount * _gonsPerFragment;
    // modify totalSupply and totalGons
    _totalSupply = _totalSupply - amount;
    _totalGons = _totalGons - amount * _gonsPerFragment;
    // emit both a Withdraw and transfer event
    emit Transfer(_msgSender(), address(0), amount);
    emit Withdraw(_msgSender(), amount);
  }

  /// @notice withdraw USDC by burning USDx
  /// caller should obtain 1 USDC for every 1e12 USDx
  /// this function is effectively just withdraw, but we calculate the amount for the sender
  function withdrawAll() external override paysInterest whenNotPaused {
    uint256 reserve = _reserve.balanceOf(address(this));
    require(reserve != 0, "Reserve is empty");
    uint256 usdc_amount = (this.balanceOf(_msgSender())) / 1e12;
    //user's USDX value is more than reserve
    if (usdc_amount > reserve) {
      usdc_amount = reserve;
    }
    uint256 amount = usdc_amount * 1e12;
    require(_reserve.transfer(_msgSender(), usdc_amount), "transfer failed");
    // see comments in the withdraw function for an explaination of this math
    _gonBalances[_msgSender()] = _gonBalances[_msgSender()] - (amount * _gonsPerFragment);
    _totalSupply = _totalSupply - amount;
    _totalGons = _totalGons - (amount * _gonsPerFragment);
    // emit both a Withdraw and transfer event
    emit Transfer(_msgSender(), address(0), amount);
    emit Withdraw(_msgSender(), amount);
  }

  /// @notice admin function to mint USDx
  /// @param usdc_amount the amount of USDx to mint, denominated in USDC
  function mint(uint256 usdc_amount) external override paysInterest onlyOwner {
    require(usdc_amount != 0, "Cannot mint 0");
    uint256 amount = usdc_amount * 1e12;
    // see comments in the deposit function for an explaination of this math
    _gonBalances[_msgSender()] = _gonBalances[_msgSender()] + amount * _gonsPerFragment;
    _totalSupply = _totalSupply + amount;
    _totalGons = _totalGons + amount * _gonsPerFragment;
    // emit both a mint and transfer event
    emit Transfer(address(0), _msgSender(), amount);
    emit Mint(_msgSender(), amount);
  }

  /// @notice admin function to burn USDx
  /// @param usdc_amount the amount of USDx to burn, denominated in USDC
  function burn(uint256 usdc_amount) external override paysInterest onlyOwner {
    require(usdc_amount != 0, "Cannot burn 0");
    uint256 amount = usdc_amount * 1e12;
    // see comments in the deposit function for an explaination of this math
    _gonBalances[_msgSender()] = _gonBalances[_msgSender()] - amount * _gonsPerFragment;
    _totalSupply = _totalSupply - amount;
    _totalGons = _totalGons - amount * _gonsPerFragment;
    // emit both a mint and transfer event
    emit Transfer(_msgSender(), address(0), amount);
    emit Burn(_msgSender(), amount);
  }

  /// @notice donates usdc to the protocol reserve
  /// @param usdc_amount the amount of USDC to donate
  function donate(uint256 usdc_amount) external override paysInterest whenNotPaused {
    uint256 amount = usdc_amount * 1e12;
    require(amount > 0, "Cannot deposit 0");
    uint256 allowance = _reserve.allowance(_msgSender(), address(this));
    require(allowance >= usdc_amount, "Insufficient Allowance");
    require(_reserve.transferFrom(_msgSender(), address(this), usdc_amount), "transfer failed");
    _donation(amount);
  }

  /// @notice donates any USDC held by this contract to the USDx holders
  /// @notice accounts for any USDC that may have been sent here accidently
  /// @notice without this, any USDC sent to the contract could mess up the reserve ratio
  function donateReserve() external override onlyOwner whenNotPaused {
    uint256 totalUSDC = (_reserve.balanceOf(address(this))) * 1e12;
    uint256 totalLiability = truncate(_VaultController.totalBaseLiability() * _VaultController.interestFactor());
    require((totalUSDC + totalLiability) > _totalSupply, "No extra reserve");

    _donation((totalUSDC + totalLiability) - _totalSupply);
  }

  /// @notice function for the vaultController to mint
  /// @param target whom to mint the USDx to
  /// @param amount the amount of USDx to mint
  function vaultControllerMint(address target, uint256 amount) external override onlyVaultController {
    // see comments in the deposit function for an explaination of this math
    _gonBalances[target] = _gonBalances[target] + amount * _gonsPerFragment;
    _totalSupply = _totalSupply + amount;
    _totalGons = _totalGons + amount * _gonsPerFragment;
    emit Transfer(address(0), target, amount);
    emit Mint(target, amount);
  }

  /// @notice function for the vaultController to burn
  /// @param target whom to burn the USDx from
  /// @param amount the amount of USDx to burn
  function vaultControllerBurn(address target, uint256 amount) external override onlyVaultController {
    require(_gonBalances[target] > (amount * _gonsPerFragment), "USDX: not enough balance");
    // see comments in the withdraw function for an explaination of this math
    _gonBalances[target] = _gonBalances[target] - amount * _gonsPerFragment;
    _totalSupply = _totalSupply - amount;
    _totalGons = _totalGons - amount * _gonsPerFragment;
    emit Transfer(target, address(0), amount);
    emit Burn(target, amount);
  }

  /// @notice function for the vaultController to scale all USDx balances
  /// @param amount amount of USDx (e18) to donate
  function vaultControllerDonate(uint256 amount) external override onlyVaultController {
    _donation(amount);
  }

  /// @notice function for distributing the donation to all USDx holders
  /// @param amount amount of USDx to donate
  function _donation(uint256 amount) internal {
    _totalSupply = _totalSupply + amount;
    if (_totalSupply > MAX_SUPPLY) {
      _totalSupply = MAX_SUPPLY;
    }
    _gonsPerFragment = _totalGons / _totalSupply;
    emit Donation(_msgSender(), amount, _totalSupply);
  }

  /// @notice get reserve ratio
  /// @return e18_reserve_ratio USDx reserve ratio
  function reserveRatio() external view override returns (uint192 e18_reserve_ratio) {
    e18_reserve_ratio = safeu192(((_reserve.balanceOf(address(this)) * expScale) / _totalSupply) * 1e12);
  }
}