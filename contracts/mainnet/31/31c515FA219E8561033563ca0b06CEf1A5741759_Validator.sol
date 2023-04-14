// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface ICore {
    /* ========== Event ========== */
    event MarketSupply(address user, address gToken, uint256 uAmount);
    event MarketRedeem(address user, address gToken, uint256 uAmount);

    event MarketListed(address gToken);
    event MarketEntered(address gToken, address account);
    event MarketExited(address gToken, address account);

    event CloseFactorUpdated(uint256 newCloseFactor);
    event CollateralFactorUpdated(address gToken, uint256 newCollateralFactor);
    event LiquidationIncentiveUpdated(uint256 newLiquidationIncentive);
    event SupplyCapUpdated(address indexed gToken, uint256 newSupplyCap);
    event BorrowCapUpdated(address indexed gToken, uint256 newBorrowCap);
    event KeeperUpdated(address newKeeper);
    event NftCoreUpdated(address newNftCore);
    event ValidatorUpdated(address newValidator);
    event GRVDistributorUpdated(address newGRVDistributor);
    event RebateDistributorUpdated(address newRebateDistributor);
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );

    function nftCore() external view returns (address);

    function validator() external view returns (address);

    function rebateDistributor() external view returns (address);

    function allMarkets() external view returns (address[] memory);

    function marketListOf(address account) external view returns (address[] memory);

    function marketInfoOf(address gToken) external view returns (Constant.MarketInfo memory);

    function checkMembership(address account, address gToken) external view returns (bool);

    function accountLiquidityOf(
        address account
    ) external view returns (uint256 collateralInUSD, uint256 supplyInUSD, uint256 borrowInUSD);

    function closeFactor() external view returns (uint256);

    function liquidationIncentive() external view returns (uint256);

    function enterMarkets(address[] memory gTokens) external;

    function exitMarket(address gToken) external;

    function supply(address gToken, uint256 underlyingAmount) external payable returns (uint256);

    function redeemToken(address gToken, uint256 gTokenAmount) external returns (uint256 redeemed);

    function redeemUnderlying(address gToken, uint256 underlyingAmount) external returns (uint256 redeemed);

    function borrow(address gToken, uint256 amount) external;

    function nftBorrow(address gToken, address user, uint256 amount) external;

    function repayBorrow(address gToken, uint256 amount) external payable;

    function nftRepayBorrow(address gToken, address user, uint256 amount) external payable;

    function repayBorrowBehalf(address gToken, address borrower, uint256 amount) external payable;

    function liquidateBorrow(
        address gTokenBorrowed,
        address gTokenCollateral,
        address borrower,
        uint256 amount
    ) external payable;

    function claimGRV() external;

    function claimGRV(address market) external;

    function compoundGRV() external;

    function firstDepositGRV(uint256 expiry) external;

    function transferTokens(address spender, address src, address dst, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IEcoScore {
    event SetGRVDistributor(address newGRVDistributor);
    event SetPriceProtectionTaxCalculator(address newPriceProtectionTaxCalculator);
    event SetPriceCalculator(address priceCalculator);
    event SetLendPoolLoan(address lendPoolLoan);
    event SetEcoPolicyInfo(
        Constant.EcoZone _zone,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] _pptTax
    );
    event SetAccountCustomEcoPolicy(
        address indexed account,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] _pptTax
    );
    event RemoveAccountCustomEcoPolicy(address indexed account);
    event ExcludeAccount(address indexed account);
    event IncludeAccount(address indexed account);
    event SetEcoZoneStandard(
        uint256 _minExpiryOfGreenZone,
        uint256 _minExpiryOfLightGreenZone,
        uint256 _minDrOfGreenZone,
        uint256 _minDrOfLightGreenZone,
        uint256 _minDrOfYellowZone,
        uint256 _minDrOfOrangeZone
    );
    event SetPPTPhaseInfo(uint256 _phase1, uint256 _phase2, uint256 _phase3, uint256 _phase4);

    function setGRVDistributor(address _grvDistributor) external;

    function setPriceProtectionTaxCalculator(address _priceProtectionTaxCalculator) external;

    function setPriceCalculator(address _priceCalculator) external;

    function setLendPoolLoan(address _lendPoolLoan) external;

    function setEcoPolicyInfo(
        Constant.EcoZone _zone,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] calldata _pptTax
    ) external;

    function setAccountCustomEcoPolicy(
        address account,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] calldata _pptTax
    ) external;

    function setEcoZoneStandard(
        uint256 _minExpiryOfGreenZone,
        uint256 _minExpiryOfLightGreenZone,
        uint256 _minDrOfGreenZone,
        uint256 _minDrOfLightGreenZone,
        uint256 _minDrOfYellowZone,
        uint256 _minDrOfOrangeZone
    ) external;

    function setPPTPhaseInfo(uint256 _phase1, uint256 _phase2, uint256 _phase3, uint256 _phase4) external;

    function removeAccountCustomEcoPolicy(address account) external;

    function excludeAccount(address account) external;

    function includeAccount(address account) external;

    function calculateEcoBoostedSupply(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) external view returns (uint256);

    function calculateEcoBoostedBorrow(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) external view returns (uint256);

    function calculatePreEcoBoostedSupply(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore,
        Constant.EcoZone ecoZone
    ) external view returns (uint256);

    function calculatePreEcoBoostedBorrow(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore,
        Constant.EcoZone ecoZone
    ) external view returns (uint256);

    function calculateCompoundTaxes(
        address account,
        uint256 value,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (uint256 adjustedValue, uint256 taxAmount);

    function calculateClaimTaxes(
        address account,
        uint256 value
    ) external view returns (uint256 adjustedValue, uint256 taxAmount);

    function getClaimTaxRate(
        address account,
        uint256 value,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (uint256);

    function getDiscountTaxRate(address account) external view returns (uint256);

    function getPptTaxRate(Constant.EcoZone ecoZone) external view returns (uint256 pptTaxRate, uint256 gapPercent);

    function getEcoZone(uint256 ecoDRpercent, uint256 remainExpiry) external view returns (Constant.EcoZone ecoZone);

    function updateUserClaimInfo(address account, uint256 amount) external;

    function updateUserCompoundInfo(address account, uint256 amount) external;

    function updateUserEcoScoreInfo(address account) external;

    function accountEcoScoreInfoOf(address account) external view returns (Constant.EcoScoreInfo memory);

    function ecoPolicyInfoOf(Constant.EcoZone zone) external view returns (Constant.EcoPolicyInfo memory);

    function calculatePreUserEcoScoreInfo(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (Constant.EcoZone ecoZone, uint256 ecoDR, uint256 userScore);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IGToken {
    function underlying() external view returns (address);

    function totalSupply() external view returns (uint256);

    function accountSnapshot(address account) external view returns (Constant.AccountSnapshot memory);

    function underlyingBalanceOf(address account) external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function _totalBorrow() external view returns (uint256);

    function totalReserve() external view returns (uint256);

    function reserveFactor() external view returns (uint256);

    function lastAccruedTime() external view returns (uint256);

    function accInterestIndex() external view returns (uint256);

    function exchangeRate() external view returns (uint256);

    function getCash() external view returns (uint256);

    function getRateModel() external view returns (address);

    function getAccInterestIndex() external view returns (uint256);

    function accruedAccountSnapshot(address account) external returns (Constant.AccountSnapshot memory);

    function accruedBorrowBalanceOf(address account) external returns (uint256);

    function accruedTotalBorrow() external returns (uint256);

    function accruedExchangeRate() external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    function supply(address account, uint256 underlyingAmount) external payable returns (uint256);

    function redeemToken(address account, uint256 gTokenAmount) external returns (uint256);

    function redeemUnderlying(address account, uint256 underlyingAmount) external returns (uint256);

    function borrow(address account, uint256 amount) external returns (uint256);

    function repayBorrow(address account, uint256 amount) external payable returns (uint256);

    function repayBorrowBehalf(address payer, address borrower, uint256 amount) external payable returns (uint256);

    function liquidateBorrow(
        address gTokenCollateral,
        address liquidator,
        address borrower,
        uint256 amount
    ) external payable returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount);

    function seize(address liquidator, address borrower, uint256 gTokenAmount) external;

    function withdrawReserves() external;

    function transferTokensInternal(address spender, address src, address dst, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IPriceCalculator {
    struct ReferenceData {
        uint256 lastData;
        uint256 lastUpdated;
    }

    function priceOf(address asset) external view returns (uint256);

    function pricesOf(address[] memory assets) external view returns (uint256[] memory);

    function priceOfETH() external view returns (uint256);

    function getUnderlyingPrice(address gToken) external view returns (uint256);

    function getUnderlyingPrices(address[] memory gTokens) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IValidator {
    function redeemAllowed(address gToken, address redeemer, uint256 redeemAmount) external returns (bool);

    function borrowAllowed(address gToken, address borrower, uint256 borrowAmount) external returns (bool);

    function liquidateAllowed(
        address gTokenBorrowed,
        address borrower,
        uint256 repayAmount,
        uint256 closeFactor
    ) external returns (bool);

    function gTokenAmountToSeize(
        address gTokenBorrowed,
        address gTokenCollateral,
        uint256 actualRepayAmount
    ) external returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount);

    function getAccountLiquidity(
        address account
    ) external view returns (uint256 collateralInUSD, uint256 supplyInUSD, uint256 borrowInUSD);

    function getAccountRedeemFeeRate(address account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

library Constant {
    uint256 public constant CLOSE_FACTOR_MIN = 5e16;
    uint256 public constant CLOSE_FACTOR_MAX = 9e17;
    uint256 public constant COLLATERAL_FACTOR_MAX = 9e17;
    uint256 public constant LIQUIDATION_THRESHOLD_MAX = 9e17;
    uint256 public constant LIQUIDATION_BONUS_MAX = 5e17;
    uint256 public constant AUCTION_DURATION_MAX = 7 days;
    uint256 public constant MIN_BID_FINE_MAX = 100 ether;
    uint256 public constant REDEEM_FINE_RATE_MAX = 5e17;
    uint256 public constant REDEEM_THRESHOLD_MAX = 9e17;
    uint256 public constant BORROW_RATE_MULTIPLIER_MAX = 1e19;
    uint256 public constant AUCTION_FEE_RATE_MAX = 5e17;

    enum EcoZone {
        RED,
        ORANGE,
        YELLOW,
        LIGHTGREEN,
        GREEN
    }

    enum EcoScorePreviewOption {
        LOCK,
        CLAIM,
        EXTEND,
        LOCK_MORE
    }

    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        None,
        // The loan data is stored, but not initiated yet.
        Active,
        // The loan is in auction, higest price liquidator will got chance to claim it.
        Auction,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
        Defaulted
    }

    struct LoanData {
        uint256 loanId;
        LoanState state;
        address borrower;
        address gNft;
        address nftAsset;
        uint256 nftTokenId;
        uint256 borrowAmount;
        uint256 interestIndex;

        uint256 bidStartTimestamp;
        address bidderAddress;
        uint256 bidPrice;
        uint256 bidBorrowAmount;
        uint256 floorPrice;
        uint256 bidCount;
        address firstBidderAddress;
    }

    struct MarketInfo {
        bool isListed;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 collateralFactor;
    }

    struct NftMarketInfo {
        bool isListed;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    struct BorrowInfo {
        uint256 borrow;
        uint256 interestIndex;
    }

    struct AccountSnapshot {
        uint256 gTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRate;
    }

    struct AccrueSnapshot {
        uint256 totalBorrow;
        uint256 totalReserve;
        uint256 accInterestIndex;
    }

    struct AccrueLoanSnapshot {
        uint256 totalBorrow;
        uint256 accInterestIndex;
    }

    struct DistributionInfo {
        uint256 supplySpeed;
        uint256 borrowSpeed;
        uint256 totalBoostedSupply;
        uint256 totalBoostedBorrow;
        uint256 accPerShareSupply;
        uint256 accPerShareBorrow;
        uint256 accruedAt;
    }

    struct DistributionAccountInfo {
        uint256 accruedGRV; // Unclaimed GRV rewards amount
        uint256 boostedSupply; // effective(boosted) supply balance of user  (since last_action)
        uint256 boostedBorrow; // effective(boosted) borrow balance of user  (since last_action)
        uint256 accPerShareSupply; // Last integral value of GRV rewards per share. ∫(GRVRate(t) / totalShare(t) dt) from 0 till (last_action)
        uint256 accPerShareBorrow; // Last integral value of GRV rewards per share. ∫(GRVRate(t) / totalShare(t) dt) from 0 till (last_action)
    }

    struct DistributionAPY {
        uint256 apySupplyGRV;
        uint256 apyBorrowGRV;
        uint256 apyAccountSupplyGRV;
        uint256 apyAccountBorrowGRV;
    }

    struct EcoScoreInfo {
        uint256 claimedGrv;
        uint256 ecoDR;
        EcoZone ecoZone;
        uint256 compoundGrv;
        uint256 changedEcoZoneAt;
    }

    struct BoostConstant {
        uint256 boost_max;
        uint256 boost_portion;
        uint256 ecoBoost_portion;
    }

    struct RebateCheckpoint {
        uint256 timestamp;
        uint256 totalScore;
        uint256 adminFeeRate;
        mapping(address => uint256) amount;
    }

    struct RebateClaimInfo {
        uint256 timestamp;
        address[] markets;
        uint256[] amount;
        uint256[] prices;
        uint256 value;
    }

    struct LockInfo {
        uint256 timestamp;
        uint256 amount;
        uint256 expiry;
    }

    struct EcoPolicyInfo {
        uint256 boostMultiple;
        uint256 maxBoostCap;
        uint256 boostBase;
        uint256 redeemFee;
        uint256 claimTax;
        uint256[] pptTax;
    }

    struct EcoZoneStandard {
        uint256 minExpiryOfGreenZone;
        uint256 minExpiryOfLightGreenZone;
        uint256 minDrOfGreenZone;
        uint256 minDrOfLightGreenZone;
        uint256 minDrOfYellowZone;
        uint256 minDrOfOrangeZone;
    }

    struct PPTPhaseInfo {
        uint256 phase1;
        uint256 phase2;
        uint256 phase3;
        uint256 phase4;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IValidator.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IEcoScore.sol";
import "../interfaces/IBEP20.sol";
import "../library/Constant.sol";

contract Validator is IValidator, OwnableUpgradeable {
    using SafeMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    IPriceCalculator public oracle;
    IEcoScore public ecoScore;
    uint256 private constant grvPriceCollateralCap = 75e15;

    /* ========== STATE VARIABLES ========== */

    ICore public core;
    address private GRV;

    /* ========== INITIALIZER ========== */

    function initialize(address _grv) external initializer {
        __Ownable_init();
        GRV = _grv;
    }

    /// @notice priceCalculator address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    /// @param _priceCalculator priceCalculator contract address
    function setPriceCalculator(address _priceCalculator) public onlyOwner {
        require(_priceCalculator != address(0), "Validator: invalid priceCalculator address");
        oracle = IPriceCalculator(_priceCalculator);
    }

    function setEcoScore(address _ecoScore) public onlyOwner {
        require(_ecoScore != address(0), "Validator: invalid ecoScore address");
        ecoScore = IEcoScore(_ecoScore);
    }

    /* ========== VIEWS ========== */

    /// @notice View collateral, supply, borrow value in USD of account
    /// @param account account address
    /// @return collateralInUSD Total collateral value in USD
    /// @return supplyInUSD Total supply value in USD
    /// @return borrowInUSD Total borrow value in USD
    function getAccountLiquidity(
        address account
    ) external view override returns (uint256 collateralInUSD, uint256 supplyInUSD, uint256 borrowInUSD) {
        collateralInUSD = 0;
        supplyInUSD = 0;
        borrowInUSD = 0;

        address[] memory assets = core.marketListOf(account);
        uint256[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint256 i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "Validator: price error");
            uint256 decimals = _getDecimals(assets[i]);
            Constant.AccountSnapshot memory snapshot = IGToken(payable(assets[i])).accountSnapshot(account);

            uint256 priceCollateral;
            if (assets[i] == GRV && prices[i] > grvPriceCollateralCap) {
                priceCollateral = grvPriceCollateralCap;
            } else {
                priceCollateral = prices[i];
            }

            uint256 collateralFactor = core.marketInfoOf(payable(assets[i])).collateralFactor;
            uint256 collateralValuePerShareInUSD = snapshot.exchangeRate.mul(priceCollateral).mul(collateralFactor).div(
                1e36
            );

            collateralInUSD = collateralInUSD.add(
                snapshot.gTokenBalance.mul(10 ** (18 - decimals)).mul(collateralValuePerShareInUSD).div(1e18)
            );
            supplyInUSD = supplyInUSD.add(
                snapshot.gTokenBalance.mul(snapshot.exchangeRate).mul(10 ** (18 - decimals)).mul(prices[i]).div(1e36)
            );
            borrowInUSD = borrowInUSD.add(snapshot.borrowBalance.mul(10 ** (18 - decimals)).mul(prices[i]).div(1e18));
        }
    }

    function getAccountRedeemFeeRate(address account) external view override returns (uint256 redeemFee) {
        Constant.EcoScoreInfo memory scoreInfo = ecoScore.accountEcoScoreInfoOf(account);
        Constant.EcoPolicyInfo memory scorePolicy = ecoScore.ecoPolicyInfoOf(scoreInfo.ecoZone);
        redeemFee = scorePolicy.redeemFee;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice core address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    ///      설정 이후에는 다른 주소로 변경할 수 없음
    /// @param _core core contract address
    function setCore(address _core) external onlyOwner {
        require(_core != address(0), "Validator: invalid core address");
        require(address(core) == address(0), "Validator: core already set");
        core = ICore(_core);
    }

    /* ========== ALLOWED FUNCTIONS ========== */

    /// @notice View if redeem is allowed
    /// @param gToken gToken address
    /// @param redeemer Redeemer account
    /// @param redeemAmount Redeem amount of underlying token
    function redeemAllowed(address gToken, address redeemer, uint256 redeemAmount) external override returns (bool) {
        (, uint256 shortfall) = _getAccountLiquidityInternal(redeemer, gToken, redeemAmount, 0);
        return shortfall == 0;
    }

    /// @notice View if borrow is allowed
    /// @param gToken gToken address
    /// @param borrower Borrower address
    /// @param borrowAmount Borrow amount of underlying token
    function borrowAllowed(address gToken, address borrower, uint256 borrowAmount) external override returns (bool) {
        require(core.checkMembership(borrower, address(gToken)), "Validator: enterMarket required");
        require(oracle.getUnderlyingPrice(address(gToken)) > 0, "Validator: Underlying price error");

        // Borrow cap of 0 corresponds to unlimited borrowing
        uint256 borrowCap = core.marketInfoOf(gToken).borrowCap;
        if (borrowCap != 0) {
            uint256 totalBorrows = IGToken(payable(gToken)).accruedTotalBorrow();
            uint256 nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "Validator: market borrow cap reached");
        }

        (, uint256 shortfall) = _getAccountLiquidityInternal(borrower, gToken, 0, borrowAmount);
        return shortfall == 0;
    }

    /// @notice View if liquidate is allowed
    /// @param gToken gToken address
    /// @param borrower Borrower address
    /// @param liquidateAmount Underlying token amount to liquidate
    /// @param closeFactor Close factor
    function liquidateAllowed(
        address gToken,
        address borrower,
        uint256 liquidateAmount,
        uint256 closeFactor
    ) external override returns (bool) {
        // The borrower must have shortfall in order to be liquidate
        (, uint256 shortfall) = _getAccountLiquidityInternal(borrower, address(0), 0, 0);
        require(shortfall != 0, "Validator: Insufficient shortfall");

        // The liquidator may not repay more than what is allowed by the closeFactor
        uint256 borrowBalance = IGToken(payable(gToken)).accruedBorrowBalanceOf(borrower);
        uint256 maxClose = closeFactor.mul(borrowBalance).div(1e18);
        return liquidateAmount <= maxClose;
    }

    function gTokenAmountToSeize(
        address gTokenBorrowed,
        address gTokenCollateral,
        uint256 amount
    ) external override returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount) {
        require(
            oracle.getUnderlyingPrice(gTokenBorrowed) != 0 && oracle.getUnderlyingPrice(gTokenCollateral) != 0,
            "Validator: price error"
        );

        uint256 exchangeRate = IGToken(payable(gTokenCollateral)).accruedExchangeRate();
        require(exchangeRate != 0, "Validator: exchangeRate of gTokenCollateral is zero");

        uint256 borrowedDecimals = _getDecimals(gTokenBorrowed);
        uint256 collateralDecimals = _getDecimals(gTokenCollateral);

        // seizeGTokenAmountBase18 =  ( repayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate) )
        // seizeGTokenAmount = seizeGTokenAmountBase18 / (10 ** (18 - decimals))
        uint256 seizeGTokenAmountBase = amount
            .mul(10 ** (18 - borrowedDecimals))
            .mul(core.liquidationIncentive())
            .mul(oracle.getUnderlyingPrice(gTokenBorrowed))
            .div(oracle.getUnderlyingPrice(gTokenCollateral).mul(exchangeRate));

        seizeGAmount = seizeGTokenAmountBase.div(10 ** (18 - collateralDecimals));
        liquidatorGAmount = seizeGAmount;
        rebateGAmount = 0;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getAccountLiquidityInternal(
        address account,
        address gToken,
        uint256 redeemAmount,
        uint256 borrowAmount
    ) private returns (uint256 liquidity, uint256 shortfall) {
        uint256 accCollateralValueInUSD;
        uint256 accBorrowValueInUSD;

        address[] memory assets = core.marketListOf(account);
        uint256[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 decimals = _getDecimals(assets[i]);
            require(prices[i] != 0, "Validator: price error");
            Constant.AccountSnapshot memory snapshot = IGToken(payable(assets[i])).accruedAccountSnapshot(account);

            uint256 collateralValuePerShareInUSD;
            if (assets[i] == GRV && prices[i] > grvPriceCollateralCap) {
                collateralValuePerShareInUSD = snapshot
                    .exchangeRate
                    .mul(grvPriceCollateralCap)
                    .mul(core.marketInfoOf(payable(assets[i])).collateralFactor)
                    .div(1e36);
            } else {
                collateralValuePerShareInUSD = snapshot
                    .exchangeRate
                    .mul(prices[i])
                    .mul(core.marketInfoOf(payable(assets[i])).collateralFactor)
                    .div(1e36);
            }

            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.gTokenBalance.mul(10 ** (18 - decimals)).mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(
                snapshot.borrowBalance.mul(10 ** (18 - decimals)).mul(prices[i]).div(1e18)
            );

            if (assets[i] == gToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(
                    _getAmountForAdditionalBorrowValue(
                        redeemAmount,
                        borrowAmount,
                        collateralValuePerShareInUSD,
                        prices[i],
                        decimals
                    )
                );
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }

    function _getAmountForAdditionalBorrowValue(
        uint256 redeemAmount,
        uint256 borrowAmount,
        uint256 collateralValuePerShareInUSD,
        uint256 price,
        uint256 decimals
    ) internal pure returns (uint256 additionalBorrowValueInUSD) {
        additionalBorrowValueInUSD = redeemAmount.mul(10 ** (18 - decimals)).mul(collateralValuePerShareInUSD).div(
            1e18
        );
        additionalBorrowValueInUSD = additionalBorrowValueInUSD.add(
            borrowAmount.mul(10 ** (18 - decimals)).mul(price).div(1e18)
        );
    }

    /// @notice View underlying token decimals by gToken address
    /// @param gToken gToken address
    function _getDecimals(address gToken) internal view returns (uint256 decimals) {
        address underlying = IGToken(gToken).underlying();
        if (underlying == address(0)) {
            decimals = 18; // ETH
        } else {
            decimals = IBEP20(underlying).decimals();
        }
    }
}