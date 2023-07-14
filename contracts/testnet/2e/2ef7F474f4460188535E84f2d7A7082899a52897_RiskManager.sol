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

pragma solidity ^0.8.0;

/**
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint256 constant expScale = 1e18;
    uint256 constant doubleScale = 1e36;
    uint256 constant halfExpScale = expScale / 2;
    uint256 constant mantissaOne = expScale;

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
    function truncate(Exp memory _exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return _exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(
        Exp memory _a,
        uint256 _scalar
    ) internal pure returns (uint256) {
        Exp memory product = mul_(_a, _scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(
        Exp memory _a,
        uint256 _scalar,
        uint256 _addend
    ) internal pure returns (uint256) {
        Exp memory product = mul_(_a, _scalar);
        return add_(truncate(product), _addend);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then minus an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateSubUInt(
        Exp memory _a,
        uint256 _scalar,
        uint256 _minus
    ) internal pure returns (uint256) {
        Exp memory product = mul_(_a, _scalar);
        return sub_(truncate(product), _minus);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(
        Exp memory _left,
        Exp memory _right
    ) internal pure returns (bool) {
        return _left.mantissa < _right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(
        Exp memory _left,
        Exp memory _right
    ) internal pure returns (bool) {
        return _left.mantissa <= _right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(
        Exp memory _left,
        Exp memory _right
    ) internal pure returns (bool) {
        return _left.mantissa > _right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory _value) internal pure returns (bool) {
        return _value.mantissa == 0;
    }

    function safe224(
        uint256 _n,
        string memory _errorMessage
    ) internal pure returns (uint224) {
        require(_n < 2 ** 224, _errorMessage);
        return uint224(_n);
    }

    function safe32(
        uint256 _n,
        string memory _errorMessage
    ) internal pure returns (uint32) {
        require(_n < 2 ** 32, _errorMessage);
        return uint32(_n);
    }

    function add_(
        Exp memory _a,
        Exp memory _b
    ) internal pure returns (Exp memory) {
        return Exp({mantissa: add_(_a.mantissa, _b.mantissa)});
    }

    function add_(
        Double memory _a,
        Double memory _b
    ) internal pure returns (Double memory) {
        return Double({mantissa: add_(_a.mantissa, _b.mantissa)});
    }

    function add_(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a + _b;
    }

    function sub_(
        Exp memory _a,
        Exp memory _b
    ) internal pure returns (Exp memory) {
        return Exp({mantissa: sub_(_a.mantissa, _b.mantissa)});
    }

    function sub_(
        Double memory _a,
        Double memory _b
    ) internal pure returns (Double memory) {
        return Double({mantissa: sub_(_a.mantissa, _b.mantissa)});
    }

    function sub_(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a - _b;
    }

    function mul_(
        Exp memory _a,
        Exp memory _b
    ) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(_a.mantissa, _b.mantissa) / expScale});
    }

    function mul_(
        Exp memory _a,
        uint256 _b
    ) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(_a.mantissa, _b)});
    }

    function mul_(uint256 _a, Exp memory _b) internal pure returns (uint256) {
        return mul_(_a, _b.mantissa) / expScale;
    }

    function mul_(
        Double memory _a,
        Double memory _b
    ) internal pure returns (Double memory) {
        return Double({mantissa: mul_(_a.mantissa, _b.mantissa) / doubleScale});
    }

    function mul_(
        Double memory _a,
        uint256 _b
    ) internal pure returns (Double memory) {
        return Double({mantissa: mul_(_a.mantissa, _b)});
    }

    function mul_(
        uint256 _a,
        Double memory _b
    ) internal pure returns (uint256) {
        return mul_(_a, _b.mantissa) / doubleScale;
    }

    function mul_(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a * _b;
    }

    function div_(
        Exp memory _a,
        Exp memory _b
    ) internal pure returns (Exp memory) {
        return Exp({mantissa: div_(mul_(_a.mantissa, expScale), _b.mantissa)});
    }

    function div_(
        Exp memory _a,
        uint256 _b
    ) internal pure returns (Exp memory) {
        return Exp({mantissa: div_(_a.mantissa, _b)});
    }

    function div_(uint256 _a, Exp memory _b) internal pure returns (uint256) {
        return div_(mul_(_a, expScale), _b.mantissa);
    }

    function div_(
        Double memory _a,
        Double memory _b
    ) internal pure returns (Double memory) {
        return
            Double({
                mantissa: div_(mul_(_a.mantissa, doubleScale), _b.mantissa)
            });
    }

    function div_(
        Double memory _a,
        uint256 _b
    ) internal pure returns (Double memory) {
        return Double({mantissa: div_(_a.mantissa, _b)});
    }

    function div_(
        uint256 _a,
        Double memory _b
    ) internal pure returns (uint256) {
        return div_(mul_(_a, doubleScale), _b.mantissa);
    }

    function div_(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function fraction(
        uint256 _a,
        uint256 _b
    ) internal pure returns (Double memory) {
        return Double({mantissa: div_(mul_(_a, doubleScale), _b)});
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceOracle {
    /**
     * @notice Get the underlying price of a fToken asset
     * @param _fToken Address of the fToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address _fToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRiskManager {
    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    /// @notice Emitted when an admin supports a market
    event MarketListed(address fToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(address fToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(address fToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(
        uint256 oldCloseFactorMantissa,
        uint256 newCloseFactorMantissa
    );

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(
        address fToken,
        uint256 oldCollateralFactorMantissa,
        uint256 newCollateralFactorMantissa
    );

    /// @notice Emitted when a liquidation factor is changed by admin
    event NewLiquidationFactor(
        address fToken,
        uint256 oldLiquidationFactorMantissa,
        uint256 newLiquidationFactorMantissa
    );

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(address oldPriceOracle, address newPriceOracle);

    event NewVeToken(address oldVeToken, address newVeToken);

    event NewLiquidationIncentive(uint256 oldIncentiveMantissa, uint256 newIncentiveMantissa);

    event NewBoostIncrease(uint256 oldIncreaseMantissa, uint256 newIncreaseMantissa);

    event NewBoostRequired(uint256 oldRequiredToken, uint256 newRequiredToken);

    /// @notice Emitted when an action is paused globally
    event ActionPausedGlobal(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPausedMarket(address fToken, string action, bool pauseState);

    function isRiskManager() external returns (bool);

    function getMarketsEntered(
        address _account
    ) external view returns (address[] memory);

    function checkListed(address _fToken) external view returns (bool);

    function enterMarkets(address[] memory _fTokens) external;

    function exitMarket(address _fToken) external;

    function supplyAllowed(address _fToken) external view returns (bool);

    function redeemAllowed(
        address _fToken,
        address _redeemer,
        uint256 _redeemTokens
    ) external view returns (bool);

    function borrowAllowed(
        address _fToken,
        address _borrower,
        uint256 _borrowAmount
    ) external returns (bool);

    function repayBorrowAllowed(address _fToken) external returns (bool);

    function liquidateBorrowAllowed(
        address _fTokenBorrowed,
        address _fTokenCollateral,
        address _borrower,
        uint256 _repayAmount
    ) external view returns (bool);

    function delegateLiquidateBorrowAllowed(
        address _fTokenBorrowed,
        address _fTokenCollateral,
        address _borrower,
        uint256 _repayAmount
    ) external view returns (bool);

    function seizeAllowed(
        address _fTokenCollateral,
        address _fTokenBorrowed,
        address _borrower,
        uint256 _seizeTokens
    ) external view returns (bool allowed);

    function transferAllowed(
        address _fToken,
        address _src,
        uint256 _amount
    ) external view returns (bool);

    function liquidateCalculateSeizeTokens(
        address _fTokenBorrowed,
        address _fTokenCollateral,
        uint256 _repayAmount
    ) external view returns (uint256 seizeTokens);

    function getAccountLiquidity(
        address _account
    )
        external
        view
        returns (
            uint256 liquidity,
            uint256 shortfallCollateral,
            uint256 shortfallLiquidation,
            uint256 healthFactor
        );

    function getMarketInfo(
        address _ftoken
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenBase {
    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Supply(address supplier, uint256 supplyAmount, uint256 tokensMinted);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint256 repayAmount, address fTokenCollateral);

    event LiquidationProtected(bytes32 _id, address _borrower, address _liquidator);

    event TokenSeized(address from, address to, uint256 amount);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    event NewReserveFactor(uint256 oldReserveFactor, uint256 newReserveFactor);

    event NewPriceOracle(address oldOracle, address newOracle);

    function isFToken() external view returns (bool);

    function balanceOfUnderlying(address _account) external returns (uint256);

    function getAccountSnapshot(address _account) external view returns (uint256, uint256, uint256);

    function getLastAccrualTime() external view returns (uint256);

    function getRiskManager() external view returns (address);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external view returns (uint256);

    function borrowBalanceCurrent(address _account) external view returns (uint256);

    function exchangeRateCurrent() external view returns (uint256);

    function seize(address _liquidator, address _borrower, uint256 _seizeTokens) external;

    /*** Admin ***/
    function setPendingAdmin(address newPendingAdmin) external;

    function acceptAdmin() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RiskManagerStorage.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ITokenBase.sol";
import "./interfaces/IRiskManager.sol";
import "./interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract RiskManager is Initializable, RiskManagerStorage, IRiskManager {
    function initialize(address _priceOracle) public initializer {
        admin = msg.sender;

        liquidationIncentiveMantissa = 1.1e18;

        boostIncreaseMantissa = 1e15;
        boostRequiredToken = 1000000e18;

        oracle = IPriceOracle(_priceOracle);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "RiskManager: Not authorized to call");
        _;
    }

    modifier onlyListed(address _fToken) {
        require(markets[_fToken].isListed, "RiskManager: Market is not listed");
        _;
    }

    function isRiskManager() public pure returns (bool) {
        return IS_RISK_MANAGER;
    }

    /**
     * @dev Returns the markets an account has entered.
     */
    function getMarketsEntered(
        address _account
    ) external view returns (address[] memory) {
        // getAssetsIn
        address[] memory entered = marketsEntered[_account]; // accountAssets[]

        return entered;
    }

    function getMarketInfo(
        address _ftoken
    ) external view returns (uint256, uint256) {
        return (
            markets[_ftoken].collateralFactorMantissa,
            markets[_ftoken].liquidationFactorMantissa
        );
    }

    /**
     * @dev Check if the given account has entered in the given asset.
     */
    function checkMembership(
        address _account,
        address _fToken
    ) external view returns (bool) {
        return markets[_fToken].isMember[_account];
    }

    function checkListed(address _fToken) external view returns (bool) {
        return markets[_fToken].isListed;
    }

    function setLeverageContract(address _furionLeverage) external onlyAdmin {
        furionLeverage = _furionLeverage;
    }

    /**
     * @dev Add assets to be included in account liquidity calculation
     */
    function enterMarkets(address[] memory _fTokens) public override {
        uint256 len = _fTokens.length;

        for (uint256 i; i < len; ) {
            addToMarketInternal(_fTokens[i], msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Add the asset for liquidity calculations of borrower
     */
    function addToMarketInternal(
        address _fToken,
        address _borrower
    ) internal onlyListed(_fToken) {
        Market storage marketToJoin = markets[_fToken];

        if (marketToJoin.isMember[_borrower] == true) {
            return;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.isMember[_borrower] = true;
        marketsEntered[_borrower].push(_fToken);

        emit MarketEntered(_fToken, _borrower);
    }

    /**
     * @dev Removes asset from sender's account liquidity calculation.
     *
     * Sender must not have an outstanding borrow balance in the asset,
     * or be providing necessary collateral for an outstanding borrow.
     */
    function exitMarket(address _fToken) external override {
        /// Get fToken balance and amount of underlying asset borrowed
        (uint256 tokensHeld, uint256 amountOwed, ) = ITokenBase(_fToken)
            .getAccountSnapshot(msg.sender);
        // Fail if the sender has a borrow balance
        require(amountOwed == 0, "RiskManager: Borrow balance is not zero");

        // Fail if the sender is not permitted to redeem all of their tokens
        require(
            redeemAllowed(_fToken, msg.sender, tokensHeld),
            "RiskManager: Cannot withdraw all tokens"
        );

        Market storage marketToExit = markets[_fToken];

        // Already exited market
        if (!marketToExit.isMember[msg.sender]) {
            return;
        }

        // Set fToken membership to false
        delete marketToExit.isMember[msg.sender];

        // Delete fToken from the account’s list of assets
        // load into memory for faster iteration
        address[] memory assets = marketsEntered[msg.sender];
        uint256 len = assets.length;
        uint256 assetIndex;
        for (uint256 i; i < len; i++) {
            if (assets[i] == _fToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // Copy last item in list to location of item to be removed, reduce length by 1
        address[] storage storedList = marketsEntered[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        emit MarketExited(_fToken, msg.sender);
    }

    /********************************* Admin *********************************/

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin MUST call
     *  `acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin MUST
     *  call `acceptAdmin` to finalize the transfer.
     * @param _newPendingAdmin New pending admin.
     */
    function setPendingAdmin(address _newPendingAdmin) external onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = _newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, _newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function acceptAdmin() external {
        // Check caller is pendingAdmin
        require(msg.sender == pendingAdmin, "TokenBase: Not pending admin");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @notice Sets a new price oracle for the comptroller
     * @dev Admin function to set a new price oracle
     */
    function setPriceOracle(address _newOracle) external onlyAdmin {
        // Track the old oracle for the comptroller
        address oldOracle = address(oracle);

        // Set comptroller's oracle to newOracle
        oracle = IPriceOracle(_newOracle);

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, _newOracle);
    }

    function setVeToken(address _newVeToken) external onlyAdmin {
        emit NewVeToken(address(veToken), _newVeToken);

        veToken = IERC20(_newVeToken);
    }

    function setCloseFactor(
        uint256 _newCloseFactorMantissa
    ) external onlyAdmin {
        require(
            _newCloseFactorMantissa >= CLOSE_FACTOR_MIN_MANTISSA &&
                _newCloseFactorMantissa <= CLOSE_FACTOR_MAX_MANTISSA,
            "RiskManager: Close factor not within limit"
        );

        uint256 oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = _newCloseFactorMantissa;

        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);
    }

    /**
     * @notice Sets the collateralFactor for a market
     * @dev Admin function to set per-market collateralFactor
     * @param _fToken The market to set the factor on
     * @param _newCollateralFactorMantissa The new collateral factor, scaled by 1e18
     */
    function setCollateralFactor(
        address _fToken,
        uint256 _newCollateralFactorMantissa
    ) external onlyAdmin onlyListed(_fToken) {
        // Check collateral factor <= 0.9
        require(
            _newCollateralFactorMantissa <= COLLATERAL_FACTOR_MAX_MANTISSA,
            "RiskManager: Collateral factor larger than limit"
        );

        // Fail if price == 0
        uint256 price = oracle.getUnderlyingPrice(_fToken);
        require(price > 0, "RiskManager: Oracle price is 0");

        Market storage market = markets[_fToken];
        // Set market's collateral factor to new collateral factor, remember old value
        uint256 oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = _newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(
            _fToken,
            oldCollateralFactorMantissa,
            _newCollateralFactorMantissa
        );
    }

    function setLiquidationFactor(
        address _fToken,
        uint256 _newLiquidationFactorMantissa
    ) external onlyAdmin onlyListed(_fToken) {
        require(
            _newLiquidationFactorMantissa <= LIQUIDATION_FACTOR_MAX_MANTISSA,
            "RiskManager: Liquidation factor larger than limit"
        );

        Market storage market = markets[_fToken];
        uint256 oldLiquidationFactorMantissa = market.liquidationFactorMantissa;
        market.liquidationFactorMantissa = _newLiquidationFactorMantissa;

        emit NewLiquidationFactor(
            _fToken,
            oldLiquidationFactorMantissa,
            _newLiquidationFactorMantissa
        );
    }

    function setLiquidationIncentive(uint256 _newIncentiveMantissa) external onlyAdmin {
        emit NewLiquidationIncentive(liquidationIncentiveMantissa, _newIncentiveMantissa);

        liquidationIncentiveMantissa = _newIncentiveMantissa;
    }

    function setBoostIncrease(uint256 _newIncreaseMantissa) external onlyAdmin {
        emit NewBoostIncrease(boostIncreaseMantissa, _newIncreaseMantissa);

        boostIncreaseMantissa = _newIncreaseMantissa;
    }

    function setBoostRequired(uint256 _newRequired) external onlyAdmin {
        emit NewBoostRequired(boostRequiredToken, _newRequired);

        boostRequiredToken = _newRequired;
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Admin function to set isListed and add support for the market
     * @param _fToken The address of the market (token) to list
     */
    function supportMarket(
        address _fToken,
        uint256 _collateralFactorMantissa,
        uint256 _liquidationFactorMantissa
    ) external onlyAdmin {
        require(
            !markets[_fToken].isListed,
            "RiskManager: Market already listed"
        );
        require(
            _collateralFactorMantissa <= COLLATERAL_FACTOR_MAX_MANTISSA,
            "RiskManager: Invalid collateral factor"
        );
        require(
            _liquidationFactorMantissa >= _collateralFactorMantissa &&
                _liquidationFactorMantissa <= LIQUIDATION_FACTOR_MAX_MANTISSA,
            "RiskManager: Invalid liquidation factor"
        );

        ITokenBase(_fToken).isFToken(); // Sanity check to make sure its really a FToken

        Market storage newMarket = markets[_fToken];
        newMarket.isListed = true;
        newMarket.collateralFactorMantissa = _collateralFactorMantissa;
        newMarket.liquidationFactorMantissa = _liquidationFactorMantissa;

        emit MarketListed(_fToken);
    }

    function setSupplyPaused(
        address _fToken,
        bool _state
    ) external onlyListed(_fToken) onlyAdmin returns (bool) {
        supplyGuardianPaused[_fToken] = _state;
        emit ActionPausedMarket(_fToken, "Supply", _state);
        return _state;
    }

    function setBorrowPaused(
        address _fToken,
        bool _state
    ) external onlyListed(_fToken) onlyAdmin returns (bool) {
        borrowGuardianPaused[_fToken] = _state;
        emit ActionPausedMarket(_fToken, "Borrow", _state);
        return _state;
    }

    function setTransferPaused(bool _state) external onlyAdmin returns (bool) {
        transferGuardianPaused = _state;
        emit ActionPausedGlobal("Transfer", _state);
        return _state;
    }

    function setSeizePaused(bool _state) external onlyAdmin returns (bool) {
        seizeGuardianPaused = _state;
        emit ActionPausedGlobal("Seize", _state);
        return _state;
    }

    /********************************* Hooks *********************************/

    /**
     * NOTE: Although the hooks are free to call externally, it is important to
     * note that they may not be accurate when called externally by non-Furion
     * contracts because accrueInterest() is not called and lastAccrualBlock may
     * not be the same as current block number. In other words, market state may
     * not be up-to-date.
     */

    /**
     * @dev Checks if the account should be allowed to supply tokens in the given market.
     */
    function supplyAllowed(
        address _fToken
    ) external view onlyListed(_fToken) returns (bool) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(
            !supplyGuardianPaused[_fToken],
            "RiskManager: Supplying is paused"
        );

        return true;
    }

    /**
     * @dev Checks if the account should be allowed to redeem fTokens for underlying
     *  asset in the given market, i.e. check if it will create shortfall / a shortfall
     *  already exists
     * @param _redeemTokens Amount of fTokens used for redemption.
     */
    function redeemAllowed(
        address _fToken,
        address _redeemer,
        uint256 _redeemTokens
    ) public view onlyListed(_fToken) returns (bool) {
        // Can freely redeem if redeemer never entered market, as liquidity calculation is not affected
        if (!markets[_fToken].isMember[_redeemer]) {
            return true;
        }

        // Otherwise, perform a hypothetical liquidity check to guard against shortfall
        (, uint256 shortfall, , ) = getHypotheticalAccountLiquidity(
            _redeemer,
            _fToken,
            _redeemTokens,
            0
        );
        require(shortfall == 0, "RiskManager: Insufficient liquidity");

        return true;
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying
     *  asset of the given market.
     * @param _fToken The market to verify the borrow against.
     * @param _borrower The account which would borrow the asset.
     * @param _borrowAmount The amount of underlying the account would borrow.
     */
    function borrowAllowed(
        address _fToken,
        address _borrower,
        uint256 _borrowAmount
    ) external override onlyListed(_fToken) returns (bool) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(
            !borrowGuardianPaused[_fToken],
            "RiskManager: Borrow is paused"
        );

        if (!markets[_fToken].isMember[_borrower]) {
            // only fToken contract may call borrowAllowed if borrower not in market
            require(
                msg.sender == _fToken,
                "RiskManager: Sender must be fToken contract"
            );

            // attempt to add borrower to the market
            addToMarketInternal(_fToken, _borrower);

            // it should be impossible to break the important invariant
            assert(markets[_fToken].isMember[_borrower]);
        }

        uint256 price = oracle.getUnderlyingPrice(_fToken);
        require(price > 0, "RiskManager: Oracle price is 0");

        (, uint256 shortfall, , ) = getHypotheticalAccountLiquidity(
            _borrower,
            _fToken,
            0,
            _borrowAmount
        );
        require(
            shortfall == 0,
            "RiskManager: Shortfall created, cannot borrow"
        );

        return true;
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the
     *  given market (if a market is listed)
     * @param _fToken The market to verify the repay against
     */
    function repayBorrowAllowed(
        address _fToken
    ) external view onlyListed(_fToken) returns (bool) {
        return true;
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param _fTokenBorrowed Asset which was borrowed by the borrower
     * @param _fTokenCollateral Asset which was used as collateral and will be seized
     * @param _borrower The address of the borrower
     * @param _repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address _fTokenBorrowed,
        address _fTokenCollateral,
        address _borrower,
        uint256 _repayAmount
    ) external view returns (bool) {
        require(
            markets[_fTokenBorrowed].isListed &&
                markets[_fTokenCollateral].isListed,
            "RiskManager: Market is not listed"
        );

        // Stored version used because accrueInterest() has been called at the
        // beginning of liquidateBorrowInternal()
        uint256 borrowBalance = ITokenBase(_fTokenBorrowed)
            .borrowBalanceCurrent(_borrower);

        (, , uint256 shortfall, ) = getAccountLiquidity(_borrower);
        // The borrower must have shortfall in order to be liquidatable
        require(shortfall > 0, "RiskManager: Insufficient shortfall");

        // The liquidator may not repay more than what is allowed by the closeFactor
        uint256 maxClose = mul_ScalarTruncate(
            Exp({mantissa: closeFactorMantissa}),
            borrowBalance
        );

        require(maxClose >= _repayAmount, "RiskManager: Repay too much");

        return true;
    }

    function delegateLiquidateBorrowAllowed(
        address _fTokenBorrowed,
        address _fTokenCollateral,
        address _borrower,
        uint256 _repayAmount
    ) external view returns (bool) {
        require(
            markets[_fTokenBorrowed].isListed &&
                markets[_fTokenCollateral].isListed,
            "RiskManager: Market is not listed"
        );

        // Stored version used because accrueInterest() has been called at the
        // beginning of liquidateBorrowInternal()
        uint256 borrowBalance = ITokenBase(_fTokenBorrowed)
            .borrowBalanceCurrent(_borrower);

        (, , uint256 shortfall, ) = getAccountLiquidity(_borrower);
        // The borrower must have shortfall in order to be liquidatable
        require(shortfall > 0, "RiskManager: Insufficient shortfall");
        require(borrowBalance >= _repayAmount, "RiskManager: Repay too much");
        return true;
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param _fTokenCollateral Asset which was used as collateral and will be seized
     * @param _fTokenBorrowed Asset which was borrowed by the borrower
     * @param _borrower The address of the borrower
     */
    function seizeAllowed(
        address _fTokenCollateral,
        address _fTokenBorrowed,
        address _borrower,
        uint256 _seizeTokens
    ) external view returns (bool allowed) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "RiskManager: Seize is paused");

        // Revert if borrower collateral token balance < seizeTokens
        require(
            IERC20Upgradeable(_fTokenCollateral).balanceOf(_borrower) >=
                _seizeTokens,
            "RiskManager: Seize token amount exceeds collateral"
        );

        require(
            markets[_fTokenBorrowed].isListed &&
                markets[_fTokenCollateral].isListed,
            "RiskManager: Market is not listed"
        );

        require(
            ITokenBase(_fTokenCollateral).getRiskManager() ==
                ITokenBase(_fTokenBorrowed).getRiskManager(),
            "RiskManager: Risk manager mismatch"
        );

        allowed = true;
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param _fToken The market to verify the transfer against
     * @param _src The account which sources the tokens
     * @param _amount The number of fTokens to transfer
     */
    function transferAllowed(
        address _fToken,
        address _src,
        uint256 _amount
    ) external view returns (bool) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        // the src is allowed to redeem this many tokens
        require(
            redeemAllowed(_fToken, _src, _amount),
            "RiskManager: Source not allowed to redeem that much fTokens"
        );

        return true;
    }

    /****************************** Liquidation *******************************/

    function collateralFactorBoost(
        address _account
    ) public view returns (uint256 boostMantissa) {
        if (address(veToken) == address(0)) return 0;

        uint256 veBalance = veToken.balanceOf(_account);
        // How many 0.1% the collateral factor will be increased by.
        // Result is rounded down by default which is fine
        uint256 multiplier = veBalance / boostRequiredToken;

        boostMantissa = boostIncreaseMantissa * multiplier;

        if (boostMantissa > COLLATERAL_FACTOR_MAX_BOOST_MANTISSA) {
            boostMantissa = COLLATERAL_FACTOR_MAX_BOOST_MANTISSA;
        }
    }

    /**
     * @notice Determine the current account liquidity wrt collateral & liquidation requirements
     * @return liquidity Hypothetical spare liquidity
     * @return shortfallCollateral Hypothetical account shortfall below collateral requirements,
     *         used for determining if borrowing/redeeming is allowed
     * @return shortfallLiquidation Hypothetical account shortfall below liquidation requirements,
     *         used for determining if liquidation is allowed
     * @return healthFactor Health factor of account scaled by 1e18, 0 if the account has no borrowings
     */
    function getAccountLiquidity(
        address _account
    )
        public
        view
        returns (
            uint256 liquidity,
            uint256 shortfallCollateral,
            uint256 shortfallLiquidation,
            uint256 healthFactor
        )
    {
        // address(0) -> no iteractions with market
        (
            liquidity,
            shortfallCollateral,
            shortfallLiquidation,
            healthFactor
        ) = getHypotheticalAccountLiquidity(_account, address(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts
     *  were redeemed/borrowed
     * @param _account The account to determine liquidity for
     * @param _fToken The market to hypothetically redeem/borrow in
     * @param _redeemToken The number of fTokens to hypothetically redeem
     * @param _borrowAmount The amount of underlying to hypothetically borrow
     * @return liquidity Hypothetical spare liquidity
     * @return shortfallCollateral Hypothetical account shortfall below collateral requirements,
     *         used for determining if borrowing/redeeming is allowed
     * @return shortfallLiquidation Hypothetical account shortfall below liquidation requirements,
     *         used for determining if liquidation is allowed
     * @return healthFactor Health factor of account scaled by 1e18, used only for off-chain operations.
     *         Return only if querying without interaction, i.e. getAccountLiquidity(), 0 (invalid) otherwise.
     *         Account without any borrowings will also have a health factor of 0
     */
    function getHypotheticalAccountLiquidity(
        address _account,
        address _fToken,
        uint256 _redeemToken,
        uint256 _borrowAmount
    )
        public
        view
        returns (
            uint256 liquidity,
            uint256 shortfallCollateral,
            uint256 shortfallLiquidation,
            uint256 healthFactor
        )
    {
        // Holds all our calculation results, see { RiskManagerStorage }
        AccountLiquidityLocalVars memory vars;

        // For each asset the account is in
        // Loop through to calculate total collateral and borrowed values
        address[] memory assets = marketsEntered[_account];
        for (uint256 i; i < assets.length; ) {
            vars.asset = assets[i];

            // Read the balances and exchange rate from the asset (market)
            (
                vars.tokenBalance,
                vars.borrowBalance,
                vars.exchangeRateMantissa
            ) = ITokenBase(vars.asset).getAccountSnapshot(_account);

            vars.collateralFactor = Exp({
                mantissa: markets[vars.asset].collateralFactorMantissa +
                    collateralFactorBoost(_account)
            });
            vars.liquidationFactor = Exp({
                mantissa: markets[vars.asset].liquidationFactorMantissa
            });

            // Decimal: underlying + 18 - fToken
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the underlying asset of fToken
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(vars.asset);
            require(
                vars.oraclePriceMantissa > 0,
                "RiskManager: Oracle price is 0"
            );
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.valuePerToken = mul_(vars.oraclePrice, vars.exchangeRate);
            vars.collateralValuePerToken = mul_(
                vars.valuePerToken,
                vars.collateralFactor
            );
            vars.liquidationValuePerToken = mul_(
                vars.valuePerToken,
                vars.liquidationFactor
            );

            /** @dev All these are compared with decimal point of 18
             *       Decimal: underlying + 18 - fToken [exchange rate]
             *                + 36 - underlying [oracle price] - 18 [Exp mul]
             *                + 18 [collateral/liquidation factor] - 18 [Exp mul]
             *                + fToken [token balance] - 18 [Exp mul]
             *                = 18
             */
            vars.sumCollateral = mul_ScalarTruncateAddUInt(
                vars.collateralValuePerToken,
                vars.tokenBalance,
                vars.sumCollateral
            );
            // Decimal: same as sumCollateral
            vars.liquidationThreshold = mul_ScalarTruncateAddUInt(
                vars.liquidationValuePerToken,
                vars.tokenBalance,
                vars.liquidationThreshold
            );
            // Decimal: 36 - underlying [oracle price] + underlying [borrow balance] - 18 [Exp mul] = 18
            vars.sumBorrowPlusEffect = mul_ScalarTruncateAddUInt(
                vars.oraclePrice,
                vars.borrowBalance,
                vars.sumBorrowPlusEffect
            );
            vars.sumBorrowPlusEffectLiquidation = vars.sumBorrowPlusEffect;

            // Calculate effects of interacting with fToken
            if (vars.asset == _fToken) {
                // Redeem effect
                // Collateral reduced same as collateral unchanged but borrow increased
                vars.sumBorrowPlusEffect = mul_ScalarTruncateAddUInt(
                    vars.collateralValuePerToken,
                    _redeemToken,
                    vars.sumBorrowPlusEffect
                );
                vars.sumBorrowPlusEffectLiquidation = mul_ScalarTruncateAddUInt(
                    vars.liquidationValuePerToken,
                    _redeemToken,
                    vars.sumBorrowPlusEffectLiquidation
                );

                // Add amount to hypothetically borrow
                // Borrow increased after borrowing
                vars.sumBorrowPlusEffect = mul_ScalarTruncateAddUInt(
                    vars.oraclePrice,
                    _borrowAmount,
                    vars.sumBorrowPlusEffect
                );
            }

            unchecked {
                ++i;
            }
        }

        // sumBorrowPlusEffectLiquidation is always greater than sumBorrowPlusEffect due to a larger factor
        if (vars.sumCollateral > vars.sumBorrowPlusEffect) {
            liquidity = vars.sumCollateral - vars.sumBorrowPlusEffect;
            shortfallCollateral = 0;
            shortfallLiquidation = 0;
        } else {
            liquidity = 0;
            shortfallCollateral = vars.sumBorrowPlusEffect - vars.sumCollateral;
            shortfallLiquidation = vars.sumBorrowPlusEffectLiquidation >
                vars.liquidationThreshold
                ? (vars.sumBorrowPlusEffectLiquidation -
                    vars.liquidationThreshold)
                : 0;
        }

        // Return health factor only for queries without interaction, i.e. invoked through getAccountLiquidity()
        if (_fToken == address(0) && vars.sumBorrowPlusEffect != 0)
            healthFactor = div_(
                vars.liquidationThreshold,
                Exp({mantissa: vars.sumBorrowPlusEffect})
            );
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in fToken.liquidateBorrowInternal)
     * @param _fTokenBorrowed The address of the borrowed cToken
     * @param _fTokenCollateral The address of the collateral cToken
     * @param _repayAmount The amount of fTokenBorrowed underlying to convert into fTokenCollateral tokens
     * @return seizeTokens Number of fTokenCollateral tokens to be seized in a liquidation
     */
    function liquidateCalculateSeizeTokens(
        address _fTokenBorrowed,
        address _fTokenCollateral,
        uint256 _repayAmount
    ) external view override returns (uint256 seizeTokens) {
        // Read oracle prices for borrowed and collateral markets
        uint256 priceBorrowedMantissa = oracle.getUnderlyingPrice(
            _fTokenBorrowed
        );
        uint256 priceCollateralMantissa = oracle.getUnderlyingPrice(
            _fTokenCollateral
        );
        require(
            priceBorrowedMantissa > 0 && priceCollateralMantissa > 0,
            "RiskManager: Oracle price is 0"
        );

        // Decimal: underlying + 18 - fToken
        uint256 exchangeRateMantissa = ITokenBase(_fTokenCollateral)
            .exchangeRateCurrent();

        /**
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = (actualRepayAmount * liquidationIncentive) * priceBorrowed / (priceCollateral * exchangeRate)
         */

        // Decimal: 18 [incentive] + underlying
        Exp memory amountAfterDiscount = mul_(
            Exp({mantissa: liquidationIncentiveMantissa}),
            _repayAmount
        );

        // Decimal: amountAfterDiscount + 36 - underlying [price oracle] - 18 [Exp mul] - 18 [truncate]
        //          = 18
        uint256 valueAfterDiscount = truncate(
            mul_(amountAfterDiscount, Exp({mantissa: priceBorrowedMantissa}))
        );

        /**   (value / underyling) * exchangeRate
         *  = (value /underlying) * (underlying / token)
         *  = value per token
         */

        // Decimal: 36 - underlying [price oracle] + (underlying + 18 - fToken) [exchange rate] - 18 [Exp mul]
        //          = 36 - fToken
        Exp memory valuePerToken = mul_(
            Exp({mantissa: priceCollateralMantissa}),
            Exp({mantissa: exchangeRateMantissa})
        );

        // Decimal: valueAfterDiscount + 18 [Exp div] - valuePerToken
        //          = 18 + 18 - (36 - fToken)
        //          = fToken
        seizeTokens = div_(valueAfterDiscount, valuePerToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ExponentialNoError.sol";
import "./interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RiskManagerStorage is ExponentialNoError {
    bool public constant IS_RISK_MANAGER = true;

    // closeFactorMantissa must be strictly greater than this value
    uint256 internal constant CLOSE_FACTOR_MIN_MANTISSA = 5e16; // 5%

    // closeFactorMantissa must not exceed this value
    uint256 internal constant CLOSE_FACTOR_MAX_MANTISSA = 9e17; // 90%

    // No collateralFactorMantissa may exceed this value
    uint256 internal constant COLLATERAL_FACTOR_MAX_MANTISSA = 9e17; // 90%

    uint256 internal constant COLLATERAL_FACTOR_MAX_BOOST_MANTISSA = 2.5e16; // 2.5%

    uint256 internal constant LIQUIDATION_FACTOR_MAX_MANTISSA = 9e17; // 90%

    /// @notice Administrator for this contract
    address public admin;

    /// @notice Pending administrator for this contract
    address public pendingAdmin;

    IERC20 public veToken;

    /// @notice Oracle which gives the price of underlying assets
    IPriceOracle public oracle;

    uint256 public closeFactorMantissa;

    uint256 public liquidationIncentiveMantissa;

    uint256 public boostIncreaseMantissa;

    uint256 public boostRequiredToken;

    /// @notice List of assets an account has entered, capped by maxAssets
    mapping(address => address[]) public marketsEntered;

    struct Market {
        // Whether or not this market is listed
        bool isListed;
        //  Must be between 0 and 0.9, and stored as a mantissa
        //  For instance, 0.9 to allow borrowing 90% of collateral value
        uint256 collateralFactorMantissa;
        // Point (total collateral value / total borrow value) where account
        // will be liquidated. Between 0 and 0.9, and stored as mantissa.
        // Larger than or equal collateral factor
        uint256 liquidationFactorMantissa;
        // Whether or not an account is entered in this market
        mapping(address => bool) isMember;
    }

    /**
     * @notice Mapping of fTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *
     * Actions which allow users to remove their own assets cannot be paused.
     * Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _supplyGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public supplyGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *
     * Note: `tokenBalance` is the number of fTokens the account owns in the market,
     * `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        address asset;
        uint256 tokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 oraclePriceMantissa;
        // Maximum amount of borrow allowed, 
        // calculated using collateral factor
        uint256 sumCollateral;
        // Borrow value when account is susceptible to liquidation,
        // calculated using liquidation factor
        uint256 liquidationThreshold; 
        uint256 sumBorrowPlusEffect;
        uint256 sumBorrowPlusEffectLiquidation;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp collateralFactor;
        Exp liquidationFactor;
        // Value of 1 fToken
        Exp valuePerToken;
        Exp collateralValuePerToken;
        Exp liquidationValuePerToken;
    }

     address public furionLeverage;
}