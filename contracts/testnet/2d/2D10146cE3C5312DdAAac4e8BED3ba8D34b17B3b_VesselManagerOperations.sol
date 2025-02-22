// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

pragma solidity 0.8.19;

abstract contract BaseMath {
    uint256 public constant DECIMAL_PRECISION = 1 ether;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./BaseMath.sol";
import "./PreonMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IPreonBase.sol";
import "../Interfaces/IAdminContract.sol";

/*
 * Base contract for VesselManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
abstract contract PreonBase is IPreonBase, BaseMath, OwnableUpgradeable {
    IAdminContract public adminContract;
    IActivePool public activePool;
    IDefaultPool internal defaultPool;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;

    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a vessel, for the purpose of ICR calculation
    function _getCompositeDebt(
        address _asset,
        uint256 _debt
    ) internal view returns (uint256) {
        return _debt + adminContract.getDebtTokenGasCompensation(_asset);
    }

    function _getNetDebt(
        address _asset,
        uint256 _debt
    ) internal view returns (uint256) {
        return _debt - adminContract.getDebtTokenGasCompensation(_asset);
    }

    // Return the amount of ETH to be drawn from a vessel's collateral and sent as gas compensation.
    function _getCollGasCompensation(
        address _asset,
        uint256 _entireColl
    ) internal view returns (uint256) {
        return _entireColl / adminContract.getPercentDivisor(_asset);
    }

    function getEntireSystemColl(
        address _asset
    ) public view returns (uint256 entireSystemColl) {
        uint256 activeColl = adminContract.activePool().getAssetBalance(_asset);
        uint256 liquidatedColl = adminContract.defaultPool().getAssetBalance(
            _asset
        );
        return activeColl + liquidatedColl;
    }

    function getEntireSystemDebt(
        address _asset
    ) public view returns (uint256 entireSystemDebt) {
        uint256 activeDebt = adminContract.activePool().getDebtTokenBalance(
            _asset
        );
        uint256 closedDebt = adminContract.defaultPool().getDebtTokenBalance(
            _asset
        );
        return activeDebt + closedDebt;
    }

    function _getTCR(
        address _asset,
        uint256 _price
    ) internal view returns (uint256 TCR) {
        uint256 entireSystemColl = getEntireSystemColl(_asset);
        uint256 entireSystemDebt = getEntireSystemDebt(_asset);
        TCR = PreonMath._computeCR(entireSystemColl, entireSystemDebt, _price);
    }

    function _checkRecoveryMode(
        address _asset,
        uint256 _price
    ) internal view returns (bool) {
        uint256 TCR = _getTCR(_asset, _price);
        return TCR < adminContract.getCcr(_asset);
    }

    function _requireUserAcceptsFee(
        uint256 _fee,
        uint256 _amount,
        uint256 _maxFeePercentage
    ) internal view {
        uint256 feePercentage = (_fee * adminContract.DECIMAL_PRECISION()) /
            _amount;
        require(
            feePercentage <= _maxFeePercentage,
            "Fee exceeded provided maximum"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library PreonMath {
    uint256 internal constant DECIMAL_PRECISION = 1 ether;

    uint256 internal constant EXPONENT_CAP = 525_600_000;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint256 internal constant NICR_PRECISION = 1e20;

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a : _b;
    }

    /*
     * Multiply two decimal numbers and use normal rounding rules:
     * -round product up if 19'th mantissa digit >= 5
     * -round product down if 19'th mantissa digit < 5
     *
     * Used only inside the exponentiation, _decPow().
     */
    function decMul(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 decProd) {
        uint256 prod_xy = x * y;

        decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) VesselManager._calcDecayedBaseRate
     * 2) CommunityIssuance._getCumulativeIssuanceFraction
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     *
     * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
     * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
     */
    function _decPow(
        uint256 _base,
        uint256 _minutes
    ) internal pure returns (uint256) {
        if (_minutes > EXPONENT_CAP) {
            _minutes = EXPONENT_CAP;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _base;
        uint256 n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n / 2;
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n - 1) / 2;
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(
        uint256 _a,
        uint256 _b
    ) internal pure returns (uint256) {
        return (_a >= _b) ? _a - _b : _b - _a;
    }

    function _computeNominalCR(
        uint256 _coll,
        uint256 _debt
    ) internal pure returns (uint256) {
        if (_debt > 0) {
            return (_coll * NICR_PRECISION) / _debt;
        }
        // Return the maximal value for uint256 if the Vessel has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return type(uint256).max;
        }
    }

    function _computeCR(
        uint256 _coll,
        uint256 _debt,
        uint256 _price
    ) internal pure returns (uint256) {
        if (_debt > 0) {
            uint256 newCollRatio = (_coll * _price) / _debt;

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Vessel has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return type(uint256).max;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---

    event ActivePoolDebtUpdated(address _asset, uint256 _debtTokenAmount);
    event ActivePoolAssetBalanceUpdated(address _asset, uint256 _balance);

    // --- Functions ---

    function sendAsset(
        address _asset,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IPriceFeed.sol";

interface IAdminContract {
    // Structs ----------------------------------------------------------------------------------------------------------

    struct CollateralParams {
        uint256 decimals;
        uint256 index; //Maps to token address in validCollateral[]
        bool active;
        bool isWrapped;
        uint256 mcr;
        uint256 ccr;
        uint256 debtTokenGasCompensation; // Amount of debtToken to be locked in gas pool on opening vessels
        uint256 minNetDebt; // Minimum amount of net debtToken a vessel must have
        uint256 percentDivisor; // dividing by 200 yields 0.5%
        uint256 borrowingFee;
        uint256 redemptionFeeFloor;
        uint256 redemptionBlockTimestamp;
        uint256 mintCap;
    }

    // Custom Errors ----------------------------------------------------------------------------------------------------

    error SafeCheckError(
        string parameter,
        uint256 valueEntered,
        uint256 minValue,
        uint256 maxValue
    );
    error AdminContract__ShortTimelockOnly();
    error AdminContract__LongTimelockOnly();
    error AdminContract__OnlyOwner();
    error AdminContract__CollateralAlreadyInitialized();

    // Events -----------------------------------------------------------------------------------------------------------

    event CollateralAdded(address _collateral);
    event MCRChanged(uint256 oldMCR, uint256 newMCR);
    event CCRChanged(uint256 oldCCR, uint256 newCCR);
    event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
    event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
    event BorrowingFeeChanged(uint256 oldBorrowingFee, uint256 newBorrowingFee);
    event RedemptionFeeFloorChanged(
        uint256 oldRedemptionFeeFloor,
        uint256 newRedemptionFeeFloor
    );
    event MintCapChanged(uint256 oldMintCap, uint256 newMintCap);
    event RedemptionBlockTimestampChanged(
        address _collateral,
        uint256 _blockTimestamp
    );

    // Functions --------------------------------------------------------------------------------------------------------

    function DECIMAL_PRECISION() external view returns (uint256);

    function _100pct() external view returns (uint256);

    function activePool() external view returns (IActivePool);

    function treasury() external view returns (address);

    function defaultPool() external view returns (IDefaultPool);

    function priceFeed() external view returns (IPriceFeed);

    function addNewCollateral(
        address _collateral,
        uint256 _debtTokenGasCompensation,
        uint256 _decimals,
        bool _isWrapped
    ) external;

    function setMCR(address _collateral, uint256 newMCR) external;

    function setCCR(address _collateral, uint256 newCCR) external;

    function setMinNetDebt(address _collateral, uint256 minNetDebt) external;

    function setPercentDivisor(
        address _collateral,
        uint256 precentDivisor
    ) external;

    function setBorrowingFee(
        address _collateral,
        uint256 borrowingFee
    ) external;

    function setRedemptionFeeFloor(
        address _collateral,
        uint256 redemptionFeeFloor
    ) external;

    function setMintCap(address _collateral, uint256 mintCap) external;

    function setRedemptionBlockTimestamp(
        address _collateral,
        uint256 _blockTimestamp
    ) external;

    function getIndex(address _collateral) external view returns (uint256);

    function getIsActive(address _collateral) external view returns (bool);

    function getValidCollateral() external view returns (address[] memory);

    function getMcr(address _collateral) external view returns (uint256);

    function getCcr(address _collateral) external view returns (uint256);

    function getDebtTokenGasCompensation(
        address _collateral
    ) external view returns (uint256);

    function getMinNetDebt(address _collateral) external view returns (uint256);

    function getPercentDivisor(
        address _collateral
    ) external view returns (uint256);

    function getBorrowingFee(
        address _collateral
    ) external view returns (uint256);

    function getRedemptionFeeFloor(
        address _collateral
    ) external view returns (uint256);

    function getRedemptionBlockTimestamp(
        address _collateral
    ) external view returns (uint256);

    function getMintCap(address _collateral) external view returns (uint256);

    function getTotalAssetDebt(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IDeposit.sol";

interface ICollSurplusPool is IDeposit {
    // --- Events ---

    event CollBalanceUpdated(address indexed _account, uint256 _newBalance);
    event AssetSent(address _to, uint256 _amount);

    // --- Functions ---

    function getAssetBalance(address _asset) external view returns (uint256);

    function getCollateral(
        address _asset,
        address _account
    ) external view returns (uint256);

    function accountSurplus(
        address _asset,
        address _account,
        uint256 _amount
    ) external;

    function claimColl(address _asset, address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStabilityPool.sol";

interface IDebtToken is IERC20 {
    // --- Events ---

    event TokenBalanceUpdated(address _user, uint256 _amount);
    event EmergencyStopMintingCollateral(address _asset, bool state);
    event WhitelistChanged(address _whitelisted, bool whitelisted);

    function emergencyStopMinting(address _asset, bool status) external;

    function mint(address _asset, address _account, uint256 _amount) external;

    function mintFromWhitelistedContract(uint256 _amount) external;

    function burnFromWhitelistedContract(uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(
        address _sender,
        address poolAddress,
        uint256 _amount
    ) external;

    function returnFromPool(
        address poolAddress,
        address user,
        uint256 _amount
    ) external;

    function addWhitelist(address _address) external;

    function removeWhitelist(address _address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event DefaultPoolDebtUpdated(address _asset, uint256 _debt);
    event DefaultPoolAssetBalanceUpdated(address _asset, uint256 _balance);

    // --- Functions ---
    function sendAssetToActivePool(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDeposit {
    function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IDeposit.sol";

interface IPool is IDeposit {
    // --- Events ---

    event AssetSent(address _to, address indexed _asset, uint256 _amount);

    // --- Functions ---

    function getAssetBalance(address _asset) external view returns (uint256);

    function getDebtTokenBalance(
        address _asset
    ) external view returns (uint256);

    function increaseDebt(address _asset, uint256 _amount) external;

    function decreaseDebt(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IAdminContract.sol";

interface IPreonBase {
    struct Colls {
        // tokens and amounts should be the same length
        address[] tokens;
        uint256[] amounts;
    }

    function adminContract() external view returns (IAdminContract);
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.17;

interface IPriceFeed {
    // Structs --------------------------------------------------------------------------------------------------------

    struct OracleRecord {
        AggregatorV3Interface chainLinkOracle;
        // Maximum price deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
        uint256 maxDeviationBetweenRounds;
        bool exists;
        bool isFeedWorking;
        bool isEthIndexed;
    }

    struct PriceRecord {
        uint256 scaledPrice;
        uint256 timestamp;
    }

    struct FeedResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    // Custom Errors --------------------------------------------------------------------------------------------------

    error PriceFeed__InvalidFeedResponseError(address token);
    error PriceFeed__InvalidPriceDeviationParamError();
    error PriceFeed__FeedFrozenError(address token);
    error PriceFeed__PriceDeviationError(address token);
    error PriceFeed__UnknownFeedError(address token);
    error PriceFeed__TimelockOnly();

    // Events ---------------------------------------------------------------------------------------------------------

    event NewOracleRegistered(
        address token,
        address chainlinkAggregator,
        bool isEthIndexed
    );
    event PriceFeedStatusUpdated(address token, address oracle, bool isWorking);
    event PriceRecordUpdated(address indexed token, uint256 _price);

    // Functions ------------------------------------------------------------------------------------------------------

    function setOracle(
        address _token,
        address _chainlinkOracle,
        uint256 _maxPriceDeviationFromPreviousRound,
        bool _isEthIndexed
    ) external;

    function fetchPrice(address _token) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ISortedVessels {
    // --- Events ---

    event NodeAdded(address indexed _asset, address _id, uint256 _NICR);
    event NodeRemoved(address indexed _asset, address _id);

    // --- Functions ---

    function insert(
        address _asset,
        address _id,
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external;

    function remove(address _asset, address _id) external;

    function reInsert(
        address _asset,
        address _id,
        uint256 _newICR,
        address _prevId,
        address _nextId
    ) external;

    function contains(address _asset, address _id) external view returns (bool);

    function isEmpty(address _asset) external view returns (bool);

    function getSize(address _asset) external view returns (uint256);

    function getFirst(address _asset) external view returns (address);

    function getLast(address _asset) external view returns (address);

    function getNext(
        address _asset,
        address _id
    ) external view returns (address);

    function getPrev(
        address _asset,
        address _id
    ) external view returns (address);

    function validInsertPosition(
        address _asset,
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (bool);

    function findInsertPosition(
        address _asset,
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IDeposit.sol";

interface IStabilityPool is IDeposit {
    // --- Structs ---

    struct Snapshots {
        mapping(address => uint256) S;
        uint256 P;
        uint256 G;
        uint128 scale;
        uint128 epoch;
    }

    // --- Events ---

    event DepositSnapshotUpdated(
        address indexed _depositor,
        uint256 _P,
        uint256 _G
    );
    event SystemSnapshotUpdated(uint256 _P, uint256 _G);

    event AssetSent(address _asset, address _to, uint256 _amount);
    event GainsWithdrawn(
        address indexed _depositor,
        address[] _collaterals,
        uint256[] _amounts,
        uint256 _debtTokenLoss
    );
    event PREONPaidToDepositor(address indexed _depositor, uint256 _PREON);
    event StabilityPoolAssetBalanceUpdated(address _asset, uint256 _newBalance);
    event StabilityPoolDebtTokenBalanceUpdated(uint256 _newBalance);
    event StakeChanged(uint256 _newSystemStake, address _depositor);
    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);

    event P_Updated(uint256 _P);
    event S_Updated(address _asset, uint256 _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    // --- Functions ---

    function addCollateralType(address _collateral) external;

    /*
     * Initial checks:
     * - _amount is not zero
     * ---
     * - Triggers a PREON issuance, based on time passed since the last issuance. The PREON issuance is shared between *all* depositors.
     * - Sends depositor's accumulated gains (PREON, assets) to depositor
     */
    function provideToSP(uint256 _amount) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized vessels left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a PREON issuance, based on time passed since the last issuance. The PREON issuance is shared between *all* depositors.
     * - Sends all depositor's accumulated gains (PREON, assets) to depositor
     * - Decreases deposit's stake, and takes new snapshots.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint256 _amount) external;

    /*
	Initial checks:
	 * - Caller is VesselManager
	 * ---
	 * Cancels out the specified debt against the debt token contained in the Stability Pool (as far as possible)
	 * and transfers the Vessel's collateral from ActivePool to StabilityPool.
	 * Only called by liquidation functions in the VesselManager.
	 */
    function offset(uint256 _debt, address _asset, uint256 _coll) external;

    /*
     * Returns debt tokens held in the pool. Changes when users deposit/withdraw, and when Vessel debt is offset.
     */
    function getTotalDebtTokenDeposits() external view returns (uint256);

    /*
     * Calculates the asset gains earned by the deposit since its last snapshots were taken.
     */
    function getDepositorGains(
        address _depositor
    ) external view returns (address[] memory, uint256[] memory);

    /*
     * Calculate the PREON gain earned by a deposit since its last snapshots were taken.
     */
    function getDepositorPREONGain(
        address _depositor
    ) external view returns (uint256);

    /*
     * Return the user's compounded deposits.
     */
    function getCompoundedDebtTokenDeposits(
        address _depositor
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IActivePool.sol";
import "./ICollSurplusPool.sol";
import "./IDebtToken.sol";
import "./IDefaultPool.sol";
import "./IPreonBase.sol";
import "./ISortedVessels.sol";
import "./IStabilityPool.sol";

interface IVesselManager is IPreonBase {
    // Enums ------------------------------------------------------------------------------------------------------------

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    enum VesselManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    // Events -----------------------------------------------------------------------------------------------------------

    event BaseRateUpdated(address indexed _asset, uint256 _baseRate);
    event LastFeeOpTimeUpdated(address indexed _asset, uint256 _lastFeeOpTime);
    event TotalStakesUpdated(address indexed _asset, uint256 _newTotalStakes);
    event SystemSnapshotsUpdated(
        address indexed _asset,
        uint256 _totalStakesSnapshot,
        uint256 _totalCollateralSnapshot
    );
    event LTermsUpdated(
        address indexed _asset,
        uint256 _L_Coll,
        uint256 _L_Debt
    );
    event VesselSnapshotsUpdated(
        address indexed _asset,
        uint256 _L_Coll,
        uint256 _L_Debt
    );
    event VesselIndexUpdated(
        address indexed _asset,
        address _borrower,
        uint256 _newIndex
    );

    event VesselUpdated(
        address indexed _asset,
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint256 _stake,
        VesselManagerOperation _operation
    );

    // Custom Errors ----------------------------------------------------------------------------------------------------

    error VesselManager__FeeBiggerThanAssetDraw();
    error VesselManager__OnlyOneVessel();

    error VesselManager__OnlyVesselManagerOperations();
    error VesselManager__OnlyBorrowerOperations();
    error VesselManager__OnlyVesselManagerOperationsOrBorrowerOperations();

    // Structs ----------------------------------------------------------------------------------------------------------

    struct Vessel {
        uint256 debt;
        uint256 coll;
        uint256 stake;
        Status status;
        uint128 arrayIndex;
    }

    // Functions --------------------------------------------------------------------------------------------------------

    function stabilityPool() external returns (IStabilityPool);

    function debtToken() external returns (IDebtToken);

    function executeFullRedemption(
        address _asset,
        address _borrower,
        uint256 _newColl
    ) external;

    function executePartialRedemption(
        address _asset,
        address _borrower,
        uint256 _newDebt,
        uint256 _newColl,
        uint256 _newNICR,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint
    ) external;

    function getVesselOwnersCount(
        address _asset
    ) external view returns (uint256);

    function getVesselFromVesselOwnersArray(
        address _asset,
        uint256 _index
    ) external view returns (address);

    function getNominalICR(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function getCurrentICR(
        address _asset,
        address _borrower,
        uint256 _price
    ) external view returns (uint256);

    function updateStakeAndTotalStakes(
        address _asset,
        address _borrower
    ) external returns (uint256);

    function updateVesselRewardSnapshots(
        address _asset,
        address _borrower
    ) external;

    function addVesselOwnerToArray(
        address _asset,
        address _borrower
    ) external returns (uint256 index);

    function applyPendingRewards(address _asset, address _borrower) external;

    function getPendingAssetReward(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function getPendingDebtTokenReward(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function hasPendingRewards(
        address _asset,
        address _borrower
    ) external view returns (bool);

    function getEntireDebtAndColl(
        address _asset,
        address _borrower
    )
        external
        view
        returns (
            uint256 debt,
            uint256 coll,
            uint256 pendingDebtTokenReward,
            uint256 pendingAssetReward
        );

    function closeVessel(address _asset, address _borrower) external;

    function closeVesselLiquidation(address _asset, address _borrower) external;

    function removeStake(address _asset, address _borrower) external;

    function getRedemptionRate(address _asset) external view returns (uint256);

    function getRedemptionRateWithDecay(
        address _asset
    ) external view returns (uint256);

    function getRedemptionFeeWithDecay(
        address _asset,
        uint256 _assetDraw
    ) external view returns (uint256);

    function getBorrowingRate(address _asset) external view returns (uint256);

    function getBorrowingFee(
        address _asset,
        uint256 _debtTokenAmount
    ) external view returns (uint256);

    function getVesselStatus(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function getVesselStake(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function getVesselDebt(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function getVesselColl(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function setVesselStatus(
        address _asset,
        address _borrower,
        uint256 num
    ) external;

    function increaseVesselColl(
        address _asset,
        address _borrower,
        uint256 _collIncrease
    ) external returns (uint256);

    function decreaseVesselColl(
        address _asset,
        address _borrower,
        uint256 _collDecrease
    ) external returns (uint256);

    function increaseVesselDebt(
        address _asset,
        address _borrower,
        uint256 _debtIncrease
    ) external returns (uint256);

    function decreaseVesselDebt(
        address _asset,
        address _borrower,
        uint256 _collDecrease
    ) external returns (uint256);

    function getTCR(
        address _asset,
        uint256 _price
    ) external view returns (uint256);

    function checkRecoveryMode(
        address _asset,
        uint256 _price
    ) external returns (bool);

    function sortedVessels() external returns (ISortedVessels);

    function isValidFirstRedemptionHint(
        address _asset,
        address _firstRedemptionHint,
        uint256 _price
    ) external returns (bool);

    function updateBaseRateFromRedemption(
        address _asset,
        uint256 _assetDrawn,
        uint256 _price,
        uint256 _totalDebtTokenSupply
    ) external returns (uint256);

    function getRedemptionFee(
        address _asset,
        uint256 _assetDraw
    ) external view returns (uint256);

    function finalizeRedemption(
        address _asset,
        address _receiver,
        uint256 _debtToRedeem,
        uint256 _fee,
        uint256 _totalRedemptionRewards
    ) external;

    function redistributeDebtAndColl(
        address _asset,
        uint256 _debt,
        uint256 _coll,
        uint256 _debtToOffset,
        uint256 _collToSendToStabilityPool
    ) external;

    function updateSystemSnapshots_excludeCollRemainder(
        address _asset,
        uint256 _collRemainder
    ) external;

    function movePendingVesselRewardsToActivePool(
        address _asset,
        uint256 _debtTokenAmount,
        uint256 _assetAmount
    ) external;

    function isVesselActive(
        address _asset,
        address _borrower
    ) external view returns (bool);

    function sendGasCompensation(
        address _asset,
        address _liquidator,
        uint256 _debtTokenAmount,
        uint256 _assetAmount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IPreonBase.sol";
import "./IVesselManager.sol";

interface IVesselManagerOperations is IPreonBase {
    // Events -----------------------------------------------------------------------------------------------------------

    event Redemption(
        address indexed _asset,
        uint256 _attemptedDebtAmount,
        uint256 _actualDebtAmount,
        uint256 _collSent,
        uint256 _collFee
    );

    event Liquidation(
        address indexed _asset,
        uint256 _liquidatedDebt,
        uint256 _liquidatedColl,
        uint256 _collGasCompensation,
        uint256 _debtTokenGasCompensation
    );

    event VesselLiquidated(
        address indexed _asset,
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        IVesselManager.VesselManagerOperation _operation
    );

    // Custom Errors ----------------------------------------------------------------------------------------------------

    error VesselManagerOperations__InvalidArraySize();
    error VesselManagerOperations__EmptyAmount();
    error VesselManagerOperations__FeePercentOutOfBounds(
        uint256 lowerBoundary,
        uint256 upperBoundary
    );
    error VesselManagerOperations__InsufficientDebtTokenBalance(
        uint256 availableBalance
    );
    error VesselManagerOperations__NothingToLiquidate();
    error VesselManagerOperations__OnlyVesselManager();
    error VesselManagerOperations__RedemptionIsBlocked();
    error VesselManagerOperations__TCRMustBeAboveMCR(uint256 tcr, uint256 mcr);
    error VesselManagerOperations__UnableToRedeemAnyAmount();
    error VesselManagerOperations__VesselNotActive();

    // Structs ----------------------------------------------------------------------------------------------------------

    struct RedemptionTotals {
        uint256 remainingDebt;
        uint256 totalDebtToRedeem;
        uint256 totalCollDrawn;
        uint256 collFee;
        uint256 collToSendToRedeemer;
        uint256 decayedBaseRate;
        uint256 price;
        uint256 totalDebtTokenSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint256 debtLot;
        uint256 collLot;
        bool cancelledPartial;
    }

    struct LiquidationTotals {
        uint256 totalCollInSequence;
        uint256 totalDebtInSequence;
        uint256 totalCollGasCompensation;
        uint256 totalDebtTokenGasCompensation;
        uint256 totalDebtToOffset;
        uint256 totalCollToSendToSP;
        uint256 totalDebtToRedistribute;
        uint256 totalCollToRedistribute;
        uint256 totalCollSurplus;
    }

    struct LiquidationValues {
        uint256 entireVesselDebt;
        uint256 entireVesselColl;
        uint256 collGasCompensation;
        uint256 debtTokenGasCompensation;
        uint256 debtToOffset;
        uint256 collToSendToSP;
        uint256 debtToRedistribute;
        uint256 collToRedistribute;
        uint256 collSurplus;
    }

    struct LocalVariables_InnerSingleLiquidateFunction {
        uint256 collToLiquidate;
        uint256 pendingDebtReward;
        uint256 pendingCollReward;
    }

    struct LocalVariables_OuterLiquidationFunction {
        uint256 price;
        uint256 debtTokenInStabPool;
        bool recoveryModeAtStart;
        uint256 liquidatedDebt;
        uint256 liquidatedColl;
    }

    struct LocalVariables_LiquidationSequence {
        uint256 remainingDebtTokenInStabPool;
        uint256 i;
        uint256 ICR;
        address user;
        bool backToNormalMode;
        uint256 entireSystemDebt;
        uint256 entireSystemColl;
    }

    struct LocalVariables_AssetBorrowerPrice {
        address _asset;
        uint256 _price;
    }

    // Functions --------------------------------------------------------------------------------------------------------

    function liquidate(address _asset, address _borrower) external;

    function liquidateVessels(address _asset, uint256 _n) external;

    function batchLiquidateVessels(
        address _asset,
        address[] memory _vesselArray
    ) external;

    function redeemCollateral(
        address _asset,
        uint256 _debtTokenAmount,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        address _firstRedemptionHint,
        uint256 _partialRedemptionHintNICR,
        uint256 _maxIterations,
        uint256 _maxFeePercentage
    ) external;

    function getRedemptionHints(
        address _asset,
        uint256 _debtTokenAmount,
        uint256 _price,
        uint256 _maxIterations
    )
        external
        returns (
            address firstRedemptionHint,
            uint256 partialRedemptionHintNICR,
            uint256 truncatedDebtTokenAmount
        );

    function getApproxHint(
        address _asset,
        uint256 _CR,
        uint256 _numTrials,
        uint256 _inputRandomSeed
    )
        external
        returns (address hintAddress, uint256 diff, uint256 latestRandomSeed);

    function computeNominalCR(
        uint256 _coll,
        uint256 _debt
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Dependencies/PreonBase.sol";
import "./Interfaces/IActivePool.sol";
import "./Interfaces/IDefaultPool.sol";
import "./Interfaces/IVesselManager.sol";
import "./Interfaces/IVesselManagerOperations.sol";

contract VesselManagerOperations is IVesselManagerOperations, PreonBase {
    string public constant NAME = "VesselManagerOperations";
    uint256 public constant REDEMPTION_SOFTENING_PARAM = 970; // 97%
    uint256 public constant PERCENTAGE_PRECISION = 1000;
    uint256 public constant BATCH_SIZE_LIMIT = 25;

    // Structs ----------------------------------------------------------------------------------------------------------

    struct LiquidationContractsCache {
        IActivePool activePool;
        IDefaultPool defaultPool;
        ISortedVessels sortedVessels;
    }

    struct RedemptionContractsCache {
        IAdminContract adminContract;
        IPriceFeed priceFeed;
        ISortedVessels sortedVessels;
        IVesselManager vesselManager;
    }

    struct HintHelperLocalVars {
        address asset;
        uint256 debtTokenAmount;
        uint256 price;
        uint256 maxIterations;
    }

    // State ------------------------------------------------------------------------------------------------------------

    IVesselManager public vesselManager;
    ISortedVessels public sortedVessels;
    IStabilityPool public stabilityPool;
    ICollSurplusPool public collSurplusPool;
    IDebtToken public debtToken;

    // Initializer ------------------------------------------------------------------------------------------------------

    function setAddresses(
        address _vesselManagerAddress,
        address _sortedVesselsAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _debtTokenAddress,
        address _adminContractAddress
    ) external initializer {
        __Ownable_init();
        vesselManager = IVesselManager(_vesselManagerAddress);
        sortedVessels = ISortedVessels(_sortedVesselsAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        debtToken = IDebtToken(_debtTokenAddress);
        adminContract = IAdminContract(_adminContractAddress);
    }

    // Liquidation external functions -----------------------------------------------------------------------------------

    /*
     * Single liquidation function. Closes the vessel if its ICR is lower than the minimum collateral ratio.
     */
    function liquidate(address _asset, address _borrower) external override {
        if (!vesselManager.isVesselActive(_asset, _borrower)) {
            revert VesselManagerOperations__VesselNotActive();
        }
        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        batchLiquidateVessels(_asset, borrowers);
    }

    /*
     * Liquidate a sequence of vessels. Closes a maximum number of n under-collateralized Vessels,
     * starting from the one with the lowest collateral ratio in the system, and moving upwards.
     */
    function liquidateVessels(address _asset, uint256 _n) external override {
        LiquidationContractsCache
            memory contractsCache = LiquidationContractsCache({
                activePool: adminContract.activePool(),
                defaultPool: adminContract.defaultPool(),
                sortedVessels: sortedVessels
            });
        IStabilityPool stabilityPoolCached = stabilityPool;
        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;
        vars.price = adminContract.priceFeed().fetchPrice(_asset);
        vars.debtTokenInStabPool = stabilityPoolCached
            .getTotalDebtTokenDeposits();
        vars.recoveryModeAtStart = _checkRecoveryMode(_asset, vars.price);

        // Perform the appropriate liquidation sequence - tally the values, and obtain their totals
        if (vars.recoveryModeAtStart) {
            totals = _getTotalsFromLiquidateVesselsSequence_RecoveryMode(
                _asset,
                contractsCache,
                vars.price,
                vars.debtTokenInStabPool,
                _n
            );
        } else {
            totals = _getTotalsFromLiquidateVesselsSequence_NormalMode(
                _asset,
                vars.price,
                vars.debtTokenInStabPool,
                _n
            );
        }

        if (totals.totalDebtInSequence == 0) {
            revert VesselManagerOperations__NothingToLiquidate();
        }

        vesselManager.redistributeDebtAndColl(
            _asset,
            totals.totalDebtToRedistribute,
            totals.totalCollToRedistribute,
            totals.totalDebtToOffset,
            totals.totalCollToSendToSP
        );
        if (totals.totalCollSurplus > 0) {
            contractsCache.activePool.sendAsset(
                _asset,
                address(collSurplusPool),
                totals.totalCollSurplus
            );
        }

        vesselManager.updateSystemSnapshots_excludeCollRemainder(
            _asset,
            totals.totalCollGasCompensation
        );

        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl =
            totals.totalCollInSequence -
            totals.totalCollGasCompensation -
            totals.totalCollSurplus;
        emit Liquidation(
            _asset,
            vars.liquidatedDebt,
            vars.liquidatedColl,
            totals.totalCollGasCompensation,
            totals.totalDebtTokenGasCompensation
        );
        vesselManager.sendGasCompensation(
            _asset,
            adminContract.treasury(),
            totals.totalDebtTokenGasCompensation,
            totals.totalCollGasCompensation
        );
    }

    /*
     * Attempt to liquidate a custom list of vessels provided by the caller.
     */
    function batchLiquidateVessels(
        address _asset,
        address[] memory _vesselArray
    ) public override {
        if (
            _vesselArray.length == 0 || _vesselArray.length > BATCH_SIZE_LIMIT
        ) {
            revert VesselManagerOperations__InvalidArraySize();
        }

        IActivePool activePoolCached = adminContract.activePool();
        IStabilityPool stabilityPoolCached = stabilityPool;
        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;

        vars.debtTokenInStabPool = stabilityPoolCached
            .getTotalDebtTokenDeposits();
        vars.price = adminContract.priceFeed().fetchPrice(_asset);
        vars.recoveryModeAtStart = _checkRecoveryMode(_asset, vars.price);

        // Perform the appropriate liquidation sequence - tally values and obtain their totals.
        if (vars.recoveryModeAtStart) {
            totals = _getTotalFromBatchLiquidate_RecoveryMode(
                _asset,
                vars.price,
                vars.debtTokenInStabPool,
                _vesselArray
            );
        } else {
            totals = _getTotalsFromBatchLiquidate_NormalMode(
                _asset,
                vars.price,
                vars.debtTokenInStabPool,
                _vesselArray
            );
        }

        if (totals.totalDebtInSequence == 0) {
            revert VesselManagerOperations__NothingToLiquidate();
        }

        vesselManager.redistributeDebtAndColl(
            _asset,
            totals.totalDebtToRedistribute,
            totals.totalCollToRedistribute,
            totals.totalDebtToOffset,
            totals.totalCollToSendToSP
        );
        if (totals.totalCollSurplus > 0) {
            activePoolCached.sendAsset(
                _asset,
                address(collSurplusPool),
                totals.totalCollSurplus
            );
        }

        // Update system snapshots
        vesselManager.updateSystemSnapshots_excludeCollRemainder(
            _asset,
            totals.totalCollGasCompensation
        );

        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl =
            totals.totalCollInSequence -
            totals.totalCollGasCompensation -
            totals.totalCollSurplus;
        emit Liquidation(
            _asset,
            vars.liquidatedDebt,
            vars.liquidatedColl,
            totals.totalCollGasCompensation,
            totals.totalDebtTokenGasCompensation
        );
        vesselManager.sendGasCompensation(
            _asset,
            adminContract.treasury(),
            totals.totalDebtTokenGasCompensation,
            totals.totalCollGasCompensation
        );
    }

    // Redemption external functions ------------------------------------------------------------------------------------

    function redeemCollateral(
        address _asset,
        uint256 _debtTokenAmount,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        address _firstRedemptionHint,
        uint256 _partialRedemptionHintNICR,
        uint256 _maxIterations,
        uint256 _maxFeePercentage
    ) external override {
        RedemptionTotals memory totals;
        RedemptionContractsCache
            memory contractsCache = RedemptionContractsCache({
                adminContract: adminContract,
                priceFeed: adminContract.priceFeed(),
                sortedVessels: sortedVessels,
                vesselManager: vesselManager
            });
        totals.price = contractsCache.priceFeed.fetchPrice(_asset);
        _validateRedemptionRequirements(
            contractsCache,
            _asset,
            _maxFeePercentage,
            _debtTokenAmount,
            totals.price
        );
        totals.totalDebtTokenSupplyAtStart = getEntireSystemDebt(_asset);
        totals.remainingDebt = _debtTokenAmount;
        address currentBorrower;
        if (
            contractsCache.vesselManager.isValidFirstRedemptionHint(
                _asset,
                _firstRedemptionHint,
                totals.price
            )
        ) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = contractsCache.sortedVessels.getLast(_asset);
            // Find the first vessel with ICR >= MCR
            while (
                currentBorrower != address(0) &&
                contractsCache.vesselManager.getCurrentICR(
                    _asset,
                    currentBorrower,
                    totals.price
                ) <
                contractsCache.adminContract.getMcr(_asset)
            ) {
                currentBorrower = contractsCache.sortedVessels.getPrev(
                    _asset,
                    currentBorrower
                );
            }
        }

        // Loop through the vessels starting from the one with lowest collateral ratio until _debtTokenAmount is exchanged for collateral
        if (_maxIterations == 0) {
            _maxIterations = type(uint256).max;
        }
        while (
            currentBorrower != address(0) &&
            totals.remainingDebt > 0 &&
            _maxIterations > 0
        ) {
            _maxIterations--;
            // Save the address of the vessel preceding the current one, before potentially modifying the list
            address nextUserToCheck = contractsCache.sortedVessels.getPrev(
                _asset,
                currentBorrower
            );

            contractsCache.vesselManager.applyPendingRewards(
                _asset,
                currentBorrower
            );

            SingleRedemptionValues
                memory singleRedemption = _redeemCollateralFromVessel(
                    _asset,
                    currentBorrower,
                    totals.remainingDebt,
                    totals.price,
                    _upperPartialRedemptionHint,
                    _lowerPartialRedemptionHint,
                    _partialRedemptionHintNICR
                );

            if (singleRedemption.cancelledPartial) break;
            // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last vessel

            totals.totalDebtToRedeem =
                totals.totalDebtToRedeem +
                singleRedemption.debtLot;
            totals.totalCollDrawn =
                totals.totalCollDrawn +
                singleRedemption.collLot;

            totals.remainingDebt =
                totals.remainingDebt -
                singleRedemption.debtLot;
            currentBorrower = nextUserToCheck;
        }
        if (totals.totalCollDrawn == 0) {
            revert VesselManagerOperations__UnableToRedeemAnyAmount();
        }

        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total STAR supply value, from before it was reduced by the redemption.
        contractsCache.vesselManager.updateBaseRateFromRedemption(
            _asset,
            totals.totalCollDrawn,
            totals.price,
            totals.totalDebtTokenSupplyAtStart
        );

        // Calculate the collateral fee
        totals.collFee = contractsCache.vesselManager.getRedemptionFee(
            _asset,
            totals.totalCollDrawn
        );

        _requireUserAcceptsFee(
            totals.collFee,
            totals.totalCollDrawn,
            _maxFeePercentage
        );

        contractsCache.vesselManager.finalizeRedemption(
            _asset,
            msg.sender,
            totals.totalDebtToRedeem,
            totals.collFee,
            totals.totalCollDrawn
        );

        emit Redemption(
            _asset,
            _debtTokenAmount,
            totals.totalDebtToRedeem,
            totals.totalCollDrawn,
            totals.collFee
        );
    }

    // Hint helper functions --------------------------------------------------------------------------------------------

    /* getRedemptionHints() - Helper function for finding the right hints to pass to redeemCollateral().
     *
     * It simulates a redemption of `_debtTokenAmount` to figure out where the redemption sequence will start and what state the final Vessel
     * of the sequence will end up in.
     *
     * Returns three hints:
     *  - `firstRedemptionHint` is the address of the first Vessel with ICR >= MCR (i.e. the first Vessel that will be redeemed).
     *  - `partialRedemptionHintNICR` is the final nominal ICR of the last Vessel of the sequence after being hit by partial redemption,
     *     or zero in case of no partial redemption.
     *  - `truncatedDebtTokenAmount` is the maximum amount that can be redeemed out of the the provided `_debtTokenAmount`. This can be lower than
     *    `_debtTokenAmount` when redeeming the full amount would leave the last Vessel of the redemption sequence with less net debt than the
     *    minimum allowed value (i.e. adminContract.MIN_NET_DEBT()).
     *
     * The number of Vessels to consider for redemption can be capped by passing a non-zero value as `_maxIterations`, while passing zero
     * will leave it uncapped.
     */

    function getRedemptionHints(
        address _asset,
        uint256 _debtTokenAmount,
        uint256 _price,
        uint256 _maxIterations
    )
        external
        view
        override
        returns (
            address firstRedemptionHint,
            uint256 partialRedemptionHintNewICR,
            uint256 truncatedDebtTokenAmount
        )
    {
        ISortedVessels sortedVesselsCached = sortedVessels;

        HintHelperLocalVars memory vars = HintHelperLocalVars({
            asset: _asset,
            debtTokenAmount: _debtTokenAmount,
            price: _price,
            maxIterations: _maxIterations
        });

        uint256 remainingDebt = _debtTokenAmount;
        address currentVesselBorrower = sortedVesselsCached.getLast(vars.asset);

        while (
            currentVesselBorrower != address(0) &&
            vesselManager.getCurrentICR(
                vars.asset,
                currentVesselBorrower,
                vars.price
            ) <
            adminContract.getMcr(vars.asset)
        ) {
            currentVesselBorrower = sortedVesselsCached.getPrev(
                vars.asset,
                currentVesselBorrower
            );
        }

        firstRedemptionHint = currentVesselBorrower;

        if (vars.maxIterations == 0) {
            vars.maxIterations = type(uint256).max;
        }

        while (
            currentVesselBorrower != address(0) &&
            remainingDebt > 0 &&
            vars.maxIterations-- > 0
        ) {
            uint256 currentVesselNetDebt = _getNetDebt(
                vars.asset,
                vesselManager.getVesselDebt(vars.asset, currentVesselBorrower) +
                    vesselManager.getPendingDebtTokenReward(
                        vars.asset,
                        currentVesselBorrower
                    )
            );

            if (currentVesselNetDebt <= remainingDebt) {
                remainingDebt = remainingDebt - currentVesselNetDebt;
            } else {
                if (
                    currentVesselNetDebt >
                    adminContract.getMinNetDebt(vars.asset)
                ) {
                    uint256 maxRedeemableDebt = PreonMath._min(
                        remainingDebt,
                        currentVesselNetDebt -
                            adminContract.getMinNetDebt(vars.asset)
                    );

                    uint256 currentVesselColl = vesselManager.getVesselColl(
                        vars.asset,
                        currentVesselBorrower
                    ) +
                        vesselManager.getPendingAssetReward(
                            vars.asset,
                            currentVesselBorrower
                        );

                    uint256 collLot = (maxRedeemableDebt * DECIMAL_PRECISION) /
                        vars.price;
                    // Apply redemption softening
                    collLot =
                        (collLot * REDEMPTION_SOFTENING_PARAM) /
                        PERCENTAGE_PRECISION;

                    uint256 newColl = currentVesselColl - collLot;
                    uint256 newDebt = currentVesselNetDebt - maxRedeemableDebt;
                    uint256 compositeDebt = _getCompositeDebt(
                        vars.asset,
                        newDebt
                    );

                    partialRedemptionHintNewICR = PreonMath._computeNominalCR(
                        newColl,
                        compositeDebt
                    );
                    remainingDebt = remainingDebt - maxRedeemableDebt;
                }

                break;
            }

            currentVesselBorrower = sortedVesselsCached.getPrev(
                vars.asset,
                currentVesselBorrower
            );
        }

        truncatedDebtTokenAmount = _debtTokenAmount - remainingDebt;
    }

    /* getApproxHint() - return address of a Vessel that is, on average, (length / numTrials) positions away in the
    sortedVessels list from the correct insert position of the Vessel to be inserted. 
    
    Note: The output address is worst-case O(n) positions away from the correct insert position, however, the function 
    is probabilistic. Input can be tuned to guarantee results to a high degree of confidence, e.g:

    Submitting numTrials = k * sqrt(length), with k = 15 makes it very, very likely that the ouput address will 
    be <= sqrt(length) positions away from the correct insert position.
    */
    function getApproxHint(
        address _asset,
        uint256 _CR,
        uint256 _numTrials,
        uint256 _inputRandomSeed
    )
        external
        view
        override
        returns (address hintAddress, uint256 diff, uint256 latestRandomSeed)
    {
        uint256 arrayLength = vesselManager.getVesselOwnersCount(_asset);

        if (arrayLength == 0) {
            return (address(0), 0, _inputRandomSeed);
        }

        hintAddress = sortedVessels.getLast(_asset);
        diff = PreonMath._getAbsoluteDifference(
            _CR,
            vesselManager.getNominalICR(_asset, hintAddress)
        );
        latestRandomSeed = _inputRandomSeed;

        uint256 i = 1;

        while (i < _numTrials) {
            latestRandomSeed = uint256(
                keccak256(abi.encodePacked(latestRandomSeed))
            );

            uint256 arrayIndex = latestRandomSeed % arrayLength;
            address currentAddress = vesselManager
                .getVesselFromVesselOwnersArray(_asset, arrayIndex);
            uint256 currentNICR = vesselManager.getNominalICR(
                _asset,
                currentAddress
            );

            // check if abs(current - CR) > abs(closest - CR), and update closest if current is closer
            uint256 currentDiff = PreonMath._getAbsoluteDifference(
                currentNICR,
                _CR
            );

            if (currentDiff < diff) {
                diff = currentDiff;
                hintAddress = currentAddress;
            }
            i++;
        }
    }

    function computeNominalCR(
        uint256 _coll,
        uint256 _debt
    ) external pure override returns (uint256) {
        return PreonMath._computeNominalCR(_coll, _debt);
    }

    // Liquidation internal/helper functions ----------------------------------------------------------------------------

    /*
     * This function is used when the batch liquidation sequence starts during Recovery Mode. However, it
     * handles the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
     */
    function _getTotalFromBatchLiquidate_RecoveryMode(
        address _asset,
        uint256 _price,
        uint256 _debtTokenInStabPool,
        address[] memory _vesselArray
    ) internal returns (LiquidationTotals memory totals) {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;
        vars.remainingDebtTokenInStabPool = _debtTokenInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt(_asset);
        vars.entireSystemColl = getEntireSystemColl(_asset);

        for (vars.i = 0; vars.i < _vesselArray.length; ) {
            vars.user = _vesselArray[vars.i];
            // Skip non-active vessels
            if (
                vesselManager.getVesselStatus(_asset, vars.user) !=
                uint256(IVesselManager.Status.active)
            ) {
                unchecked {
                    vars.i++;
                }
                continue;
            }
            vars.ICR = vesselManager.getCurrentICR(_asset, vars.user, _price);

            if (!vars.backToNormalMode) {
                // Skip this vessel if ICR is greater than MCR and Stability Pool is empty
                if (
                    vars.ICR >= adminContract.getMcr(_asset) &&
                    vars.remainingDebtTokenInStabPool == 0
                ) {
                    unchecked {
                        vars.i++;
                    }
                    continue;
                }
                uint256 TCR = PreonMath._computeCR(
                    vars.entireSystemColl,
                    vars.entireSystemDebt,
                    _price
                );

                singleLiquidation = _liquidateRecoveryMode(
                    _asset,
                    vars.user,
                    vars.ICR,
                    vars.remainingDebtTokenInStabPool,
                    TCR,
                    _price
                );

                // Update aggregate trackers
                vars.remainingDebtTokenInStabPool =
                    vars.remainingDebtTokenInStabPool -
                    singleLiquidation.debtToOffset;
                vars.entireSystemDebt =
                    vars.entireSystemDebt -
                    singleLiquidation.debtToOffset;
                vars.entireSystemColl =
                    vars.entireSystemColl -
                    singleLiquidation.collToSendToSP -
                    singleLiquidation.collGasCompensation -
                    singleLiquidation.collSurplus;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(
                    totals,
                    singleLiquidation
                );

                vars.backToNormalMode = !_checkPotentialRecoveryMode(
                    _asset,
                    vars.entireSystemColl,
                    vars.entireSystemDebt,
                    _price
                );
            } else if (
                vars.backToNormalMode && vars.ICR < adminContract.getMcr(_asset)
            ) {
                singleLiquidation = _liquidateNormalMode(
                    _asset,
                    vars.user,
                    vars.remainingDebtTokenInStabPool
                );
                vars.remainingDebtTokenInStabPool =
                    vars.remainingDebtTokenInStabPool -
                    singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(
                    totals,
                    singleLiquidation
                );
            }
            unchecked {
                vars.i++;
            }
        }
    }

    function _getTotalsFromBatchLiquidate_NormalMode(
        address _asset,
        uint256 _price,
        uint256 _debtTokenInStabPool,
        address[] memory _vesselArray
    ) internal returns (LiquidationTotals memory totals) {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingDebtTokenInStabPool = _debtTokenInStabPool;

        for (vars.i = 0; vars.i < _vesselArray.length; ) {
            vars.user = _vesselArray[vars.i];
            vars.ICR = vesselManager.getCurrentICR(_asset, vars.user, _price);

            if (vars.ICR < adminContract.getMcr(_asset)) {
                singleLiquidation = _liquidateNormalMode(
                    _asset,
                    vars.user,
                    vars.remainingDebtTokenInStabPool
                );
                vars.remainingDebtTokenInStabPool =
                    vars.remainingDebtTokenInStabPool -
                    singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(
                    totals,
                    singleLiquidation
                );
            }
            unchecked {
                vars.i++;
            }
        }
    }

    function _addLiquidationValuesToTotals(
        LiquidationTotals memory oldTotals,
        LiquidationValues memory singleLiquidation
    ) internal pure returns (LiquidationTotals memory newTotals) {
        // Tally all the values with their respective running totals
        newTotals.totalCollGasCompensation =
            oldTotals.totalCollGasCompensation +
            singleLiquidation.collGasCompensation;
        newTotals.totalDebtTokenGasCompensation =
            oldTotals.totalDebtTokenGasCompensation +
            singleLiquidation.debtTokenGasCompensation;
        newTotals.totalDebtInSequence =
            oldTotals.totalDebtInSequence +
            singleLiquidation.entireVesselDebt;
        newTotals.totalCollInSequence =
            oldTotals.totalCollInSequence +
            singleLiquidation.entireVesselColl;
        newTotals.totalDebtToOffset =
            oldTotals.totalDebtToOffset +
            singleLiquidation.debtToOffset;
        newTotals.totalCollToSendToSP =
            oldTotals.totalCollToSendToSP +
            singleLiquidation.collToSendToSP;
        newTotals.totalDebtToRedistribute =
            oldTotals.totalDebtToRedistribute +
            singleLiquidation.debtToRedistribute;
        newTotals.totalCollToRedistribute =
            oldTotals.totalCollToRedistribute +
            singleLiquidation.collToRedistribute;
        newTotals.totalCollSurplus =
            oldTotals.totalCollSurplus +
            singleLiquidation.collSurplus;
        return newTotals;
    }

    function _getTotalsFromLiquidateVesselsSequence_NormalMode(
        address _asset,
        uint256 _price,
        uint256 _debtTokenInStabPool,
        uint256 _n
    ) internal returns (LiquidationTotals memory totals) {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;
        ISortedVessels sortedVesselsCached = sortedVessels;

        vars.remainingDebtTokenInStabPool = _debtTokenInStabPool;

        for (vars.i = 0; vars.i < _n; ) {
            vars.user = sortedVesselsCached.getLast(_asset);
            vars.ICR = vesselManager.getCurrentICR(_asset, vars.user, _price);

            if (vars.ICR < adminContract.getMcr(_asset)) {
                singleLiquidation = _liquidateNormalMode(
                    _asset,
                    vars.user,
                    vars.remainingDebtTokenInStabPool
                );

                vars.remainingDebtTokenInStabPool =
                    vars.remainingDebtTokenInStabPool -
                    singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(
                    totals,
                    singleLiquidation
                );
            } else break;
            // break if the loop reaches a Vessel with ICR >= MCR
            unchecked {
                vars.i++;
            }
        }
    }

    function _liquidateNormalMode(
        address _asset,
        address _borrower,
        uint256 _debtTokenInStabPool
    ) internal returns (LiquidationValues memory singleLiquidation) {
        IVesselManager vesselManagerCached = vesselManager;
        LocalVariables_InnerSingleLiquidateFunction memory vars;
        (
            singleLiquidation.entireVesselDebt,
            singleLiquidation.entireVesselColl,
            vars.pendingDebtReward,
            vars.pendingCollReward
        ) = vesselManagerCached.getEntireDebtAndColl(_asset, _borrower);

        vesselManagerCached.movePendingVesselRewardsToActivePool(
            _asset,
            vars.pendingDebtReward,
            vars.pendingCollReward
        );
        vesselManagerCached.removeStake(_asset, _borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(
            _asset,
            singleLiquidation.entireVesselColl
        );
        singleLiquidation.debtTokenGasCompensation = adminContract
            .getDebtTokenGasCompensation(_asset);
        uint256 collToLiquidate = singleLiquidation.entireVesselColl -
            singleLiquidation.collGasCompensation;

        (
            singleLiquidation.debtToOffset,
            singleLiquidation.collToSendToSP,
            singleLiquidation.debtToRedistribute,
            singleLiquidation.collToRedistribute
        ) = _getOffsetAndRedistributionVals(
            singleLiquidation.entireVesselDebt,
            collToLiquidate,
            _debtTokenInStabPool
        );

        vesselManagerCached.closeVesselLiquidation(_asset, _borrower);
        emit VesselLiquidated(
            _asset,
            _borrower,
            singleLiquidation.entireVesselDebt,
            singleLiquidation.entireVesselColl,
            IVesselManager.VesselManagerOperation.liquidateInNormalMode
        );
        return singleLiquidation;
    }

    function _liquidateRecoveryMode(
        address _asset,
        address _borrower,
        uint256 _ICR,
        uint256 _debtTokenInStabPool,
        uint256 _TCR,
        uint256 _price
    ) internal returns (LiquidationValues memory singleLiquidation) {
        LocalVariables_InnerSingleLiquidateFunction memory vars;
        IVesselManager vesselManagerCached = vesselManager;
        IAdminContract adminContractCached = adminContract;
        if (vesselManager.getVesselOwnersCount(_asset) <= 1) {
            return singleLiquidation;
        }
        // don't liquidate if last vessel
        (
            singleLiquidation.entireVesselDebt,
            singleLiquidation.entireVesselColl,
            vars.pendingDebtReward,
            vars.pendingCollReward
        ) = vesselManagerCached.getEntireDebtAndColl(_asset, _borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(
            _asset,
            singleLiquidation.entireVesselColl
        );
        singleLiquidation.debtTokenGasCompensation = adminContractCached
            .getDebtTokenGasCompensation(_asset);
        vars.collToLiquidate =
            singleLiquidation.entireVesselColl -
            singleLiquidation.collGasCompensation;

        // If ICR <= 100%, purely redistribute the Vessel across all active Vessels
        if (_ICR <= adminContract._100pct()) {
            vesselManagerCached.movePendingVesselRewardsToActivePool(
                _asset,
                vars.pendingDebtReward,
                vars.pendingCollReward
            );
            vesselManagerCached.removeStake(_asset, _borrower);

            singleLiquidation.debtToOffset = 0;
            singleLiquidation.collToSendToSP = 0;
            singleLiquidation.debtToRedistribute = singleLiquidation
                .entireVesselDebt;
            singleLiquidation.collToRedistribute = vars.collToLiquidate;

            vesselManagerCached.closeVesselLiquidation(_asset, _borrower);
            emit VesselLiquidated(
                _asset,
                _borrower,
                singleLiquidation.entireVesselDebt,
                singleLiquidation.entireVesselColl,
                IVesselManager.VesselManagerOperation.liquidateInRecoveryMode
            );

            // If 100% < ICR < MCR, offset as much as possible, and redistribute the remainder
        } else if (
            (_ICR > adminContract._100pct()) &&
            (_ICR < adminContractCached.getMcr(_asset))
        ) {
            vesselManagerCached.movePendingVesselRewardsToActivePool(
                _asset,
                vars.pendingDebtReward,
                vars.pendingCollReward
            );
            vesselManagerCached.removeStake(_asset, _borrower);

            (
                singleLiquidation.debtToOffset,
                singleLiquidation.collToSendToSP,
                singleLiquidation.debtToRedistribute,
                singleLiquidation.collToRedistribute
            ) = _getOffsetAndRedistributionVals(
                singleLiquidation.entireVesselDebt,
                vars.collToLiquidate,
                _debtTokenInStabPool
            );

            vesselManagerCached.closeVesselLiquidation(_asset, _borrower);
            emit VesselLiquidated(
                _asset,
                _borrower,
                singleLiquidation.entireVesselDebt,
                singleLiquidation.entireVesselColl,
                IVesselManager.VesselManagerOperation.liquidateInRecoveryMode
            );

            /*
             * If 110% <= ICR < current TCR (accounting for the preceding liquidations in the current sequence)
             * and there are debt tokens in the Stability Pool, only offset, with no redistribution,
             * but at a capped rate of 1.1 and only if the whole debt can be liquidated.
             * The remainder due to the capped rate will be claimable as collateral surplus.
             */
        } else if (
            (_ICR >= adminContractCached.getMcr(_asset)) &&
            (_ICR < _TCR) &&
            (singleLiquidation.entireVesselDebt <= _debtTokenInStabPool)
        ) {
            vesselManagerCached.movePendingVesselRewardsToActivePool(
                _asset,
                vars.pendingDebtReward,
                vars.pendingCollReward
            );
            assert(_debtTokenInStabPool != 0);

            vesselManagerCached.removeStake(_asset, _borrower);
            singleLiquidation = _getCappedOffsetVals(
                _asset,
                singleLiquidation.entireVesselDebt,
                singleLiquidation.entireVesselColl,
                _price
            );

            vesselManagerCached.closeVesselLiquidation(_asset, _borrower);
            if (singleLiquidation.collSurplus > 0) {
                collSurplusPool.accountSurplus(
                    _asset,
                    _borrower,
                    singleLiquidation.collSurplus
                );
            }
            emit VesselLiquidated(
                _asset,
                _borrower,
                singleLiquidation.entireVesselDebt,
                singleLiquidation.collToSendToSP,
                IVesselManager.VesselManagerOperation.liquidateInRecoveryMode
            );
        } else {
            // if (_ICR >= MCR && ( _ICR >= _TCR || singleLiquidation.entireVesselDebt > _debtTokenInStabPool))
            LiquidationValues memory zeroVals;
            return zeroVals;
        }

        return singleLiquidation;
    }

    /*
     * This function is used when the liquidateVessels sequence starts during Recovery Mode. However, it
     * handles the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
     */
    function _getTotalsFromLiquidateVesselsSequence_RecoveryMode(
        address _asset,
        LiquidationContractsCache memory _contractsCache,
        uint256 _price,
        uint256 _debtTokenInStabPool,
        uint256 _n
    ) internal returns (LiquidationTotals memory totals) {
        LocalVariables_AssetBorrowerPrice
            memory assetVars = LocalVariables_AssetBorrowerPrice({
                _asset: _asset,
                _price: _price
            });

        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingDebtTokenInStabPool = _debtTokenInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt(assetVars._asset);
        vars.entireSystemColl = getEntireSystemColl(assetVars._asset);

        vars.user = _contractsCache.sortedVessels.getLast(assetVars._asset);
        address firstUser = _contractsCache.sortedVessels.getFirst(
            assetVars._asset
        );
        for (vars.i = 0; vars.i < _n && vars.user != firstUser; ) {
            // we need to cache it, because current user is likely going to be deleted
            address nextUser = _contractsCache.sortedVessels.getPrev(
                assetVars._asset,
                vars.user
            );

            vars.ICR = vesselManager.getCurrentICR(
                assetVars._asset,
                vars.user,
                assetVars._price
            );

            if (!vars.backToNormalMode) {
                // Break the loop if ICR is greater than MCR and Stability Pool is empty
                if (
                    vars.ICR >= adminContract.getMcr(_asset) &&
                    vars.remainingDebtTokenInStabPool == 0
                ) {
                    break;
                }

                uint256 TCR = PreonMath._computeCR(
                    vars.entireSystemColl,
                    vars.entireSystemDebt,
                    assetVars._price
                );

                singleLiquidation = _liquidateRecoveryMode(
                    assetVars._asset,
                    vars.user,
                    vars.ICR,
                    vars.remainingDebtTokenInStabPool,
                    TCR,
                    assetVars._price
                );

                // Update aggregate trackers
                vars.remainingDebtTokenInStabPool =
                    vars.remainingDebtTokenInStabPool -
                    singleLiquidation.debtToOffset;
                vars.entireSystemDebt =
                    vars.entireSystemDebt -
                    singleLiquidation.debtToOffset;
                vars.entireSystemColl =
                    vars.entireSystemColl -
                    singleLiquidation.collToSendToSP -
                    singleLiquidation.collGasCompensation -
                    singleLiquidation.collSurplus;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(
                    totals,
                    singleLiquidation
                );

                vars.backToNormalMode = !_checkPotentialRecoveryMode(
                    _asset,
                    vars.entireSystemColl,
                    vars.entireSystemDebt,
                    assetVars._price
                );
            } else if (
                vars.backToNormalMode && vars.ICR < adminContract.getMcr(_asset)
            ) {
                singleLiquidation = _liquidateNormalMode(
                    assetVars._asset,
                    vars.user,
                    vars.remainingDebtTokenInStabPool
                );

                vars.remainingDebtTokenInStabPool =
                    vars.remainingDebtTokenInStabPool -
                    singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(
                    totals,
                    singleLiquidation
                );
            } else break;
            // break if the loop reaches a Vessel with ICR >= MCR

            vars.user = nextUser;
            unchecked {
                vars.i++;
            }
        }
    }

    /* In a full liquidation, returns the values for a vessel's coll and debt to be offset, and coll and debt to be
     * redistributed to active vessels.
     */
    function _getOffsetAndRedistributionVals(
        uint256 _debt,
        uint256 _coll,
        uint256 _debtTokenInStabPool
    )
        internal
        pure
        returns (
            uint256 debtToOffset,
            uint256 collToSendToSP,
            uint256 debtToRedistribute,
            uint256 collToRedistribute
        )
    {
        if (_debtTokenInStabPool > 0) {
            /*
             * Offset as much debt & collateral as possible against the Stability Pool, and redistribute the remainder
             * between all active vessels.
             *
             *  If the vessel's debt is larger than the deposited debt token in the Stability Pool:
             *
             *  - Offset an amount of the vessel's debt equal to the debt token in the Stability Pool
             *  - Send a fraction of the vessel's collateral to the Stability Pool, equal to the fraction of its offset debt
             *
             */
            debtToOffset = PreonMath._min(_debt, _debtTokenInStabPool);
            collToSendToSP = (_coll * debtToOffset) / _debt;
            debtToRedistribute = _debt - debtToOffset;
            collToRedistribute = _coll - collToSendToSP;
        } else {
            debtToOffset = 0;
            collToSendToSP = 0;
            debtToRedistribute = _debt;
            collToRedistribute = _coll;
        }
    }

    /*
     *  Get its offset coll/debt and coll gas comp, and close the vessel.
     */
    function _getCappedOffsetVals(
        address _asset,
        uint256 _entireVesselDebt,
        uint256 _entireVesselColl,
        uint256 _price
    ) internal view returns (LiquidationValues memory singleLiquidation) {
        singleLiquidation.entireVesselDebt = _entireVesselDebt;
        singleLiquidation.entireVesselColl = _entireVesselColl;
        uint256 cappedCollPortion = (_entireVesselDebt *
            adminContract.getMcr(_asset)) / _price;

        singleLiquidation.collGasCompensation = _getCollGasCompensation(
            _asset,
            cappedCollPortion
        );
        singleLiquidation.debtTokenGasCompensation = adminContract
            .getDebtTokenGasCompensation(_asset);

        singleLiquidation.debtToOffset = _entireVesselDebt;
        singleLiquidation.collToSendToSP =
            cappedCollPortion -
            singleLiquidation.collGasCompensation;
        singleLiquidation.collSurplus = _entireVesselColl - cappedCollPortion;
        singleLiquidation.debtToRedistribute = 0;
        singleLiquidation.collToRedistribute = 0;
    }

    function _checkPotentialRecoveryMode(
        address _asset,
        uint256 _entireSystemColl,
        uint256 _entireSystemDebt,
        uint256 _price
    ) internal view returns (bool) {
        uint256 TCR = PreonMath._computeCR(
            _entireSystemColl,
            _entireSystemDebt,
            _price
        );
        return TCR < adminContract.getCcr(_asset);
    }

    // Redemption internal/helper functions -----------------------------------------------------------------------------

    function _validateRedemptionRequirements(
        RedemptionContractsCache memory contractsCache,
        address _asset,
        uint256 _maxFeePercentage,
        uint256 _debtTokenAmount,
        uint256 _price
    ) internal view {
        uint256 redemptionBlockTimestamp = contractsCache
            .adminContract
            .getRedemptionBlockTimestamp(_asset);
        if (redemptionBlockTimestamp > block.timestamp) {
            revert VesselManagerOperations__RedemptionIsBlocked();
        }
        uint256 redemptionFeeFloor = contractsCache
            .adminContract
            .getRedemptionFeeFloor(_asset);
        if (
            _maxFeePercentage < redemptionFeeFloor ||
            _maxFeePercentage > DECIMAL_PRECISION
        ) {
            revert VesselManagerOperations__FeePercentOutOfBounds(
                redemptionFeeFloor,
                DECIMAL_PRECISION
            );
        }
        if (_debtTokenAmount == 0) {
            revert VesselManagerOperations__EmptyAmount();
        }
        uint256 redeemerBalance = debtToken.balanceOf(msg.sender);
        if (redeemerBalance < _debtTokenAmount) {
            revert VesselManagerOperations__InsufficientDebtTokenBalance(
                redeemerBalance
            );
        }
        uint256 tcr = _getTCR(_asset, _price);
        uint256 mcr = contractsCache.adminContract.getMcr(_asset);
        if (tcr < mcr) {
            revert VesselManagerOperations__TCRMustBeAboveMCR(tcr, mcr);
        }
    }

    // Redeem as much collateral as possible from _borrower's vessel in exchange for STAR up to _maxDebtTokenAmount
    function _redeemCollateralFromVessel(
        address _asset,
        address _borrower,
        uint256 _maxDebtTokenAmount,
        uint256 _price,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintNICR
    ) internal returns (SingleRedemptionValues memory singleRedemption) {
        uint256 vesselDebt = vesselManager.getVesselDebt(_asset, _borrower);
        uint256 vesselColl = vesselManager.getVesselColl(_asset, _borrower);

        // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the vessel minus the liquidation reserve
        singleRedemption.debtLot = PreonMath._min(
            _maxDebtTokenAmount,
            vesselDebt - adminContract.getDebtTokenGasCompensation(_asset)
        );

        // Get the debtToken lot of equivalent value in USD
        singleRedemption.collLot =
            (singleRedemption.debtLot * DECIMAL_PRECISION) /
            _price;
        // Apply redemption softening
        singleRedemption.collLot =
            (singleRedemption.collLot * REDEMPTION_SOFTENING_PARAM) /
            PERCENTAGE_PRECISION;

        // Decrease the debt and collateral of the current vessel according to the debt token lot and corresponding coll to send

        uint256 newDebt = vesselDebt - singleRedemption.debtLot;
        uint256 newColl = vesselColl - singleRedemption.collLot;

        if (newDebt == adminContract.getDebtTokenGasCompensation(_asset)) {
            vesselManager.executeFullRedemption(_asset, _borrower, newColl);
        } else {
            uint256 newNICR = PreonMath._computeNominalCR(newColl, newDebt);

            /*
             * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
             * certainly result in running out of gas.
             *
             * If the resultant net debt of the partial is less than the minimum, net debt we bail.
             */
            if (
                newNICR != _partialRedemptionHintNICR ||
                _getNetDebt(_asset, newDebt) <
                adminContract.getMinNetDebt(_asset)
            ) {
                singleRedemption.cancelledPartial = true;
                return singleRedemption;
            }

            vesselManager.executePartialRedemption(
                _asset,
                _borrower,
                newDebt,
                newColl,
                newNICR,
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint
            );
        }

        return singleRedemption;
    }
}