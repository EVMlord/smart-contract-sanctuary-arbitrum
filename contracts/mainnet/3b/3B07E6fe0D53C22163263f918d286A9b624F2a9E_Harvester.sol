/**
 *Submitted for verification at Arbiscan on 2022-11-01
*/

/**
*
*/

// SPDX-License-Identifier: MIT


// File: @openzeppelin\contracts-upgradeable\token\ERC20\IERC20Upgradeable.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts-upgradeable\utils\AddressUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts-upgradeable\token\ERC20\utils\SafeERC20Upgradeable.sol


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

// File: @openzeppelin\contracts-upgradeable\proxy\utils\Initializable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin\contracts-upgradeable\utils\ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin\contracts-upgradeable\utils\structs\EnumerableSetUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// File: contracts\BIFI\keepers\contracts\ManageableUpgradeable.sol



pragma solidity ^0.8.4;
abstract contract ManageableUpgradeable is Initializable, ContextUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _managers;

    event ManagersUpdated(address[] users_, address status_);

    /* solhint-disable func-name-mixedcase */
    /**
     * @dev Initializes the contract setting the deployer as the only manager.
     */
    function __Manageable_init() internal onlyInitializing {
        /* solhint-enable func-name-mixedcase */
        __Context_init_unchained();
        __Manageable_init_unchained();
    }

    /* solhint-disable func-name-mixedcase */
    function __Manageable_init_unchained() internal onlyInitializing {
        /* solhint-enable func-name-mixedcase */
        _setManager(_msgSender(), true);
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(_managers.contains(msg.sender), "!manager");
        _;
    }

    function setManagers(address[] memory managers_, bool status_) external onlyManager {
        for (uint256 managerIndex = 0; managerIndex < managers_.length; managerIndex++) {
            _setManager(managers_[managerIndex], status_);
        }
    }

    function _setManager(address manager_, bool status_) internal {
        if (status_) {
            _managers.add(manager_);
        } else {
            // Must be at least 1 manager.
            require(_managers.length() > 1, "!(managers > 1)");
            _managers.remove(manager_);
        }
    }

    uint256[49] private __gap;
}

// File: contracts\BIFI\interfaces\common\IUniswapRouterETH.sol



pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterETH {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts\BIFI\keepers\interfaces\IPegSwap.sol


pragma solidity >=0.6.0 <0.9.0;

interface IPegSwap {
    event LiquidityUpdated(uint256 amount, address indexed source, address indexed target);
    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event StuckTokensRecovered(uint256 amount, address indexed target);
    event TokensSwapped(uint256 amount, address indexed source, address indexed target, address indexed caller);

    /* solhint-disable payable-fallback */
    fallback() external;

    /* solhint-enable payable-fallback */

    function acceptOwnership() external;

    function addLiquidity(
        uint256 amount,
        address source,
        address target
    ) external;

    function getSwappableAmount(address source, address target) external view returns (uint256 amount);

    function onTokenTransfer(
        address sender,
        uint256 amount,
        bytes memory targetData
    ) external;

    function owner() external view returns (address);

    function recoverStuckTokens(uint256 amount, address target) external;

    function removeLiquidity(
        uint256 amount,
        address source,
        address target
    ) external;

    function swap(
        uint256 amount,
        address source,
        address target
    ) external;

    function transferOwnership(address _to) external;
}

// File: contracts\BIFI\keepers\interfaces\IKeeperRegistry.sol


pragma solidity >=0.6.0 <0.9.0;

interface IKeeperRegistry {
    event ConfigSet(
        uint32 paymentPremiumPPB,
        uint24 blockCountPerTurn,
        uint32 checkGasLimit,
        uint24 stalenessSeconds,
        uint16 gasCeilingMultiplier,
        uint256 fallbackGasPrice,
        uint256 fallbackLinkPrice
    );
    event FlatFeeSet(uint32 flatFeeMicroLink);
    event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
    event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
    event KeepersUpdated(address[] keepers, address[] payees);
    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event Paused(address account);
    event PayeeshipTransferRequested(address indexed keeper, address indexed from, address indexed to);
    event PayeeshipTransferred(address indexed keeper, address indexed from, address indexed to);
    event PaymentWithdrawn(address indexed keeper, uint256 indexed amount, address indexed to, address payee);
    event RegistrarChanged(address indexed from, address indexed to);
    event Unpaused(address account);
    event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
    event UpkeepPerformed(
        uint256 indexed id,
        bool indexed success,
        address indexed from,
        uint96 payment,
        bytes performData
    );
    event UpkeepRegistered(uint256 indexed id, uint32 executeGas, address admin);

    function FAST_GAS_FEED() external view returns (address);

    function LINK() external view returns (address);

    function LINK_ETH_FEED() external view returns (address);

    function acceptOwnership() external;

    function acceptPayeeship(address keeper) external;

    function addFunds(uint256 id, uint96 amount) external;

    function cancelUpkeep(uint256 id) external;

    function checkUpkeep(uint256 id, address from)
        external
        returns (
            bytes memory performData,
            uint256 maxLinkPayment,
            uint256 gasLimit,
            uint256 adjustedGasWei,
            uint256 linkEth
        );

    function getCanceledUpkeepList() external view returns (uint256[] memory);

    function getConfig()
        external
        view
        returns (
            uint32 paymentPremiumPPB,
            uint24 blockCountPerTurn,
            uint32 checkGasLimit,
            uint24 stalenessSeconds,
            uint16 gasCeilingMultiplier,
            uint256 fallbackGasPrice,
            uint256 fallbackLinkPrice
        );

    function getFlatFee() external view returns (uint32);

    function getKeeperInfo(address query)
        external
        view
        returns (
            address payee,
            bool active,
            uint96 balance
        );

    function getKeeperList() external view returns (address[] memory);

    function getMaxPaymentForGas(uint256 gasLimit) external view returns (uint96 maxPayment);

    function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance);

    function getRegistrar() external view returns (address);

    function getUpkeep(uint256 id)
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastKeeper,
            address admin,
            uint64 maxValidBlocknumber
        );

    function getUpkeepCount() external view returns (uint256);

    function onTokenTransfer(
        address sender,
        uint256 amount,
        bytes memory data
    ) external;

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function performUpkeep(uint256 id, bytes memory performData) external returns (bool success);

    function recoverFunds() external;

    function registerUpkeep(
        address target,
        uint32 gasLimit,
        address admin,
        bytes memory checkData
    ) external returns (uint256 id);

    function setConfig(
        uint32 paymentPremiumPPB,
        uint32 flatFeeMicroLink,
        uint24 blockCountPerTurn,
        uint32 checkGasLimit,
        uint24 stalenessSeconds,
        uint16 gasCeilingMultiplier,
        uint256 fallbackGasPrice,
        uint256 fallbackLinkPrice
    ) external;

    function setKeepers(address[] memory keepers, address[] memory payees) external;

    function setRegistrar(address registrar) external;

    function transferOwnership(address to) external;

    function transferPayeeship(address keeper, address proposed) external;

    function typeAndVersion() external view returns (string memory);

    function unpause() external;

    function withdrawFunds(uint256 id, address to) external;

    function withdrawPayment(address from, address to) external;
}

// File: contracts\BIFI\keepers\interfaces\IBeefyStrategy.sol


pragma solidity >=0.6.0 <0.9.0;
interface IBeefyStrategy {
    function vault() external view returns (address);

    function want() external view returns (IERC20Upgradeable);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function harvest(address callFeeRecipient) external;

    function retireStrat() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function unirouter() external view returns (address);

    function lpToken0() external view returns (address);

    function lpToken1() external view returns (address);

    function lastHarvest() external view returns (uint256);

    function callReward() external view returns (uint256);

    function harvestWithCallFeeRecipient(address callFeeRecipient) external; // back compat call
}

// File: contracts\BIFI\keepers\interfaces\IBeefyVault.sol


pragma solidity >=0.6.0 <0.9.0;
interface IBeefyVault is IERC20Upgradeable {
    function name() external view returns (string memory);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;

    function getPricePerFullShare() external view returns (uint256);

    function upgradeStrat() external;

    function balance() external view returns (uint256);

    function want() external view returns (IERC20Upgradeable);

    function strategy() external view returns (IBeefyStrategy);
}

// File: contracts\BIFI\keepers\interfaces\IBeefyRegistry.sol


pragma solidity >=0.6.0 <0.9.0;

interface IBeefyRegistry {
    function allVaultAddresses() external view returns (address[] memory);

    function getVaultCount() external view returns (uint256 count);

    function setHarvestFunctionGasOverhead(address vaultAddress_, uint256 gasOverhead_) external;
}

// File: @chainlink\contracts\src\v0.8\interfaces\KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
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

// File: contracts\BIFI\keepers\interfaces\IBeefyHarvester.sol


pragma solidity >=0.6.0 <0.9.0;
interface IBeefyHarvester is KeeperCompatibleInterface {
    struct HarvestInfo {
        bool willHarvest;
        uint256 estimatedTxCost;
        uint256 callRewardsAmount;
    }
        
    event HarvestSummary(
        uint256 indexed blockNumber,
        uint256 oldStartIndex,
        uint256 newStartIndex,
        uint256 gasPrice,
        uint256 gasUsedByPerformUpkeep,
        uint256 numberOfSuccessfulHarvests,
        uint256 numberOfFailedHarvests
    );
    event HeuristicFailed(
        uint256 indexed blockNumber,
        uint256 heuristicEstimatedTxCost,
        uint256 nonHeuristicEstimatedTxCost,
        uint256 estimatedCallRewards
    );
    event ProfitSummary(
        uint256 estimatedTxCost,
        uint256 estimatedCallRewards,
        uint256 estimatedProfit,
        uint256 calculatedTxCost,
        uint256 calculatedCallRewards,
        uint256 calculatedProfit
    );
    event SuccessfulHarvests(
        uint256 indexed blockNumber,
        address[] successfulVaults
    );
    event FailedHarvests(uint256 indexed blockNumber, address[] failedVaults);

    function inCaseTokensGetStuck(address token_) external;

    function initialize(
        address vaultRegistry_,
        address keeperRegistry_,
        address upkeepRefunder_,
        uint256 performUpkeepGasLimit_,
        uint256 performUpkeepGasLimitBuffer_,
        uint256 harvestGasLimit_,
        uint256 keeperRegistryGasOverhead_
    ) external;

    function setHarvestGasConsumption(uint256 harvestGasConsumption_) external;

    function setPerformUpkeepGasLimit(uint256 performUpkeepGasLimit_) external;

    function setPerformUpkeepGasLimitBuffer(
        uint256 performUpkeepGasLimitBuffer_
    ) external;

    function setUpkeepRefunder(address upkeepRefunder_) external;
}

// File: contracts\BIFI\keepers\interfaces\IUpkeepRefunder.sol


pragma solidity >=0.6.0 <0.9.0;
interface IUpkeepRefunder {
    event SwappedNativeToLink(uint256 indexed blockNumber, uint256 nativeAmount, uint256 linkAmount);

    function notifyRefundUpkeep() external returns (uint256 linkRefunded_);
}

// File: contracts\BIFI\keepers\libraries\UpkeepLibrary.sol


pragma solidity >=0.6.0 <0.9.0;

library UpkeepLibrary {
    uint256 public constant CHAINLINK_UPKEEPTX_PREMIUM_SCALING_FACTOR = 1 gwei;

    /**
     * @dev Rescues random funds stuck.
     */
    function _getCircularIndex(
        uint256 index_,
        uint256 offset_,
        uint256 bufferLength_
    ) internal pure returns (uint256 circularIndex_) {
        circularIndex_ = (index_ + offset_) % bufferLength_;
    }

    function _calculateUpkeepTxCost(
        uint256 gasprice_,
        uint256 gasOverhead_,
        uint256 chainlinkUpkeepTxPremiumFactor_
    ) internal pure returns (uint256 upkeepTxCost_) {
        upkeepTxCost_ =
            (gasprice_ * gasOverhead_ * chainlinkUpkeepTxPremiumFactor_) /
            CHAINLINK_UPKEEPTX_PREMIUM_SCALING_FACTOR;
    }

    function _calculateUpkeepTxCostFromTotalVaultHarvestOverhead(
        uint256 gasprice_,
        uint256 totalVaultHarvestOverhead_,
        uint256 keeperRegistryOverhead_,
        uint256 chainlinkUpkeepTxPremiumFactor_
    ) internal pure returns (uint256 upkeepTxCost_) {
        uint256 totalOverhead = totalVaultHarvestOverhead_ + keeperRegistryOverhead_;

        upkeepTxCost_ = _calculateUpkeepTxCost(gasprice_, totalOverhead, chainlinkUpkeepTxPremiumFactor_);
    }

    function _calculateProfit(uint256 revenue, uint256 expenses) internal pure returns (uint256 profit_) {
        profit_ = revenue >= expenses ? revenue - expenses : 0;
    }
}

// File: contracts\BIFI\keepers\contracts\BeefyHarvester.sol



pragma solidity ^0.8.4;
contract Harvester is ManageableUpgradeable, IBeefyHarvester {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Contracts.
    IBeefyRegistry public _vaultRegistry;
    IKeeperRegistry public _keeperRegistry;
    IUpkeepRefunder public _upkeepRefunder;

    // Configuration state variables.
    uint256 public _performUpkeepGasLimit;
    uint256 public _performUpkeepGasLimitBuffer;
    uint256 public _vaultHarvestFunctionGasOverhead; // Estimated average gas cost of calling harvest(). TODO: this needs to live in BeefyRegistry, and needs to be a `per vault` number.
    uint256 public _keeperRegistryGasOverhead; // Gas cost of upstream contract that calls performUpkeep(). This is a private variable on KeeperRegistry.
    uint256 public _chainlinkUpkeepTxPremiumFactor; // Tx premium factor/multiplier scaled by 1 gwei (10**9).
    address public _callFeeRecipient;

    // State variables that will change across upkeeps.
    uint256 public _startIndex;

    /*             */
    /* Initializer */
    /*             */

    function initialize(
        address vaultRegistry_,
        address keeperRegistry_,
        address upkeepRefunder_,
        uint256 performUpkeepGasLimit_,
        uint256 performUpkeepGasLimitBuffer_,
        uint256 vaultHarvestFunctionGasOverhead_,
        uint256 keeperRegistryGasOverhead_
    ) external override initializer {
        __Manageable_init();

        // Set contract references.
        _vaultRegistry = IBeefyRegistry(vaultRegistry_);
        _keeperRegistry = IKeeperRegistry(keeperRegistry_);
        _upkeepRefunder = IUpkeepRefunder(upkeepRefunder_);

        // Initialize state variables from initialize() arguments.
        _performUpkeepGasLimit = performUpkeepGasLimit_;
        _performUpkeepGasLimitBuffer = performUpkeepGasLimitBuffer_;
        _vaultHarvestFunctionGasOverhead = vaultHarvestFunctionGasOverhead_;
        _keeperRegistryGasOverhead = keeperRegistryGasOverhead_;

        // Initialize state variables derived from initialize() arguments.
        (uint32 paymentPremiumPPB, , , , , , ) = _keeperRegistry.getConfig();
        _chainlinkUpkeepTxPremiumFactor = uint256(paymentPremiumPPB);
        _callFeeRecipient = address(_upkeepRefunder);
    }

    /*             */
    /* checkUpkeep */
    /*             */

    function checkUpkeep(
        bytes calldata checkData_ // unused
    )
        external
        view
        override
        returns (
            bool upkeepNeeded_,
            bytes memory performData_ // array of vaults +
        )
    {
        checkData_; // dummy reference to get rid of unused parameter warning

        // get vaults to iterate over
        address[] memory vaults = _vaultRegistry.allVaultAddresses();

        // count vaults to harvest that will fit within gas limit
        (
            HarvestInfo[] memory harvestInfo,
            uint256 numberOfVaultsToHarvest,
            uint256 newStartIndex
        ) = _countVaultsToHarvest(vaults);
        if (numberOfVaultsToHarvest == 0) return (false, bytes("KintsugiAutoHarvester: No vaults to harvest"));

        (
            address[] memory vaultsToHarvest,
            uint256 heuristicEstimatedTxCost,
            uint256 callRewards
        ) = _buildVaultsToHarvest(vaults, harvestInfo, numberOfVaultsToHarvest);

        uint256 nonHeuristicEstimatedTxCost = _calculateExpectedTotalUpkeepTxCost(numberOfVaultsToHarvest);

        performData_ = abi.encode(
            vaultsToHarvest,
            newStartIndex,
            heuristicEstimatedTxCost,
            nonHeuristicEstimatedTxCost,
            callRewards
        );

        return (true, performData_);
    }

    function _buildVaultsToHarvest(
        address[] memory vaults_,
        HarvestInfo[] memory willHarvestVault_,
        uint256 numberOfVaultsToHarvest_
    )
        internal
        view
        returns (
            address[] memory vaultsToHarvest_,
            uint256 heuristicEstimatedTxCost_,
            uint256 totalCallRewards_
        )
    {
        uint256 vaultPositionInArray;
        vaultsToHarvest_ = new address[](numberOfVaultsToHarvest_);

        // create array of vaults to harvest. Could reduce code duplication from _countVaultsToHarvest via a another function parameter called _loopPostProcess
        for (uint256 offset; offset < vaults_.length; ++offset) {
            uint256 vaultIndexToCheck = UpkeepLibrary._getCircularIndex(_startIndex, offset, vaults_.length);
            address vaultAddress = vaults_[vaultIndexToCheck];

            HarvestInfo memory harvestInfo = willHarvestVault_[offset];

            if (harvestInfo.willHarvest) {
                vaultsToHarvest_[vaultPositionInArray] = vaultAddress;
                heuristicEstimatedTxCost_ += harvestInfo.estimatedTxCost;
                totalCallRewards_ += harvestInfo.callRewardsAmount;
                vaultPositionInArray += 1;
            }

            // no need to keep going if we're past last index
            if (vaultPositionInArray == numberOfVaultsToHarvest_) break;
        }

        return (vaultsToHarvest_, heuristicEstimatedTxCost_, totalCallRewards_);
    }

    function _countVaultsToHarvest(address[] memory vaults_)
        internal
        view
        returns (
            HarvestInfo[] memory harvestInfo_,
            uint256 numberOfVaultsToHarvest_,
            uint256 newStartIndex_
        )
    {
        uint256 gasLeft = _calculateAdjustedGasCap();
        uint256 vaultIndexToCheck; // hoisted up to be able to set newStartIndex
        harvestInfo_ = new HarvestInfo[](vaults_.length);

        // count the number of vaults to harvest.
        for (uint256 offset; offset < vaults_.length; ++offset) {
            // _startIndex is where to start in the _vaultRegistry array, offset is position from start index (in other words, number of vaults we've checked so far),
            // then modulo to wrap around to the start of the array, until we've checked all vaults, or break early due to hitting gas limit
            // this logic is contained in _getCircularIndex()
            vaultIndexToCheck = UpkeepLibrary._getCircularIndex(_startIndex, offset, vaults_.length);
            address vaultAddress = vaults_[vaultIndexToCheck];

            (bool willHarvest, uint256 estimatedTxCost, uint256 callRewardsAmount) = _willHarvestVault(vaultAddress);

            if (willHarvest && gasLeft >= _vaultHarvestFunctionGasOverhead) {
                gasLeft -= _vaultHarvestFunctionGasOverhead;
                numberOfVaultsToHarvest_ += 1;
                harvestInfo_[offset] = HarvestInfo(true, estimatedTxCost, callRewardsAmount);
            }

            if (gasLeft < _vaultHarvestFunctionGasOverhead) {
                break;
            }
        }

        newStartIndex_ = UpkeepLibrary._getCircularIndex(vaultIndexToCheck, 1, vaults_.length);

        return (harvestInfo_, numberOfVaultsToHarvest_, newStartIndex_);
    }

    function _willHarvestVault(address vaultAddress_)
        internal
        view
        returns (
            bool willHarvestVault_,
            uint256 estimatedTxCost_,
            uint256 callRewardAmount_
        )
    {
        (bool shouldHarvestVault, uint256 estimatedTxCost, uint256 callRewardAmount) = _shouldHarvestVault(
            vaultAddress_
        );
        bool canHarvestVault = _canHarvestVault(vaultAddress_);

        willHarvestVault_ = canHarvestVault && shouldHarvestVault;

        return (willHarvestVault_, estimatedTxCost, callRewardAmount);
    }

    function _canHarvestVault(address vaultAddress_) internal view returns (bool canHarvest_) {
        IBeefyVault vault = IBeefyVault(vaultAddress_);
        IBeefyStrategy strategy = IBeefyStrategy(vault.strategy());

        bool isPaused = strategy.paused();

        canHarvest_ = !isPaused;

        return canHarvest_;
    }

    function _shouldHarvestVault(address vaultAddress_)
        internal
        view
        returns (
            bool shouldHarvestVault_,
            uint256 txCostWithPremium_,
            uint256 callRewardAmount_
        )
    {
        IBeefyVault vault = IBeefyVault(vaultAddress_);
        IBeefyStrategy strategy = IBeefyStrategy(vault.strategy());

        /* solhint-disable not-rely-on-time */
        uint256 oneDayAgo = block.timestamp - 1 days;
        bool hasBeenHarvestedToday = strategy.lastHarvest() > oneDayAgo;
        /* solhint-enable not-rely-on-time */

        callRewardAmount_ = strategy.callReward();

        uint256 vaultHarvestGasOverhead = _estimateSingleVaultHarvestGasOverhead(_vaultHarvestFunctionGasOverhead); // TODO: Pull this number from BeefyRegistry.
        txCostWithPremium_ = _calculateTxCostWithPremium(vaultHarvestGasOverhead);
        bool isProfitableHarvest = callRewardAmount_ >= txCostWithPremium_;

        shouldHarvestVault_ = isProfitableHarvest || (!hasBeenHarvestedToday && callRewardAmount_ > 0);

        return (shouldHarvestVault_, txCostWithPremium_, callRewardAmount_);
    }

    /*               */
    /* performUpkeep */
    /*               */

    function performUpkeep(bytes calldata performData) external override {
        (
            address[] memory vaultsToHarvest,
            uint256 newStartIndex,
            uint256 heuristicEstimatedTxCost,
            uint256 nonHeuristicEstimatedTxCost,
            uint256 estimatedCallRewards
        ) = abi.decode(performData, (address[], uint256, uint256, uint256, uint256));

        _runUpkeep(
            vaultsToHarvest,
            newStartIndex,
            heuristicEstimatedTxCost,
            nonHeuristicEstimatedTxCost,
            estimatedCallRewards
        );
    }

    function _runUpkeep(
        address[] memory vaults_,
        uint256 newStartIndex_,
        uint256 heuristicEstimatedTxCost_,
        uint256 nonHeuristicEstimatedTxCost_,
        uint256 estimatedCallRewards_
    ) internal {
        // Make sure estimate looks good.
        if (estimatedCallRewards_ < nonHeuristicEstimatedTxCost_) {
            emit HeuristicFailed(
                block.number,
                heuristicEstimatedTxCost_,
                nonHeuristicEstimatedTxCost_,
                estimatedCallRewards_
            );
        }

        uint256 gasBefore = gasleft();
        // multi harvest
        require(vaults_.length > 0, "No vaults to harvest");
        (
            uint256 numberOfSuccessfulHarvests,
            uint256 numberOfFailedHarvests,
            uint256 calculatedCallRewards
        ) = _multiHarvest(vaults_);

        // ensure newStartIndex_ is valid and set _startIndex
        uint256 vaultCount = _vaultRegistry.getVaultCount();
        require(newStartIndex_ >= 0 && newStartIndex_ < vaultCount, "newStartIndex_ out of range.");
        _startIndex = newStartIndex_;

        uint256 gasAfter = gasleft();
        uint256 gasUsedByPerformUpkeep = gasBefore - gasAfter;

        // split these into their own functions to avoid `Stack too deep`
        _reportProfitSummary(
            gasUsedByPerformUpkeep,
            nonHeuristicEstimatedTxCost_,
            estimatedCallRewards_,
            calculatedCallRewards
        );
        _reportHarvestSummary(
            newStartIndex_,
            gasUsedByPerformUpkeep,
            numberOfSuccessfulHarvests,
            numberOfFailedHarvests
        );

        // Don't consider it as part of upkeep. TODO: make upkeepRefunder its own Upkeep.
        _upkeepRefunder.notifyRefundUpkeep();
    }

    function _reportHarvestSummary(
        uint256 newStartIndex_,
        uint256 gasUsedByPerformUpkeep_,
        uint256 numberOfSuccessfulHarvests_,
        uint256 numberOfFailedHarvests_
    ) internal {
        emit HarvestSummary(
            block.number,
            // state variables
            _startIndex,
            newStartIndex_,
            // gas metrics
            tx.gasprice,
            gasUsedByPerformUpkeep_,
            // summary metrics
            numberOfSuccessfulHarvests_,
            numberOfFailedHarvests_
        );
    }

    function _reportProfitSummary(
        uint256 gasUsedByPerformUpkeep_,
        uint256 nonHeuristicEstimatedTxCost_,
        uint256 estimatedCallRewards_,
        uint256 calculatedCallRewards_
    ) internal {
        uint256 estimatedTxCost = nonHeuristicEstimatedTxCost_; // use nonHeuristic here as its more accurate
        uint256 estimatedProfit = UpkeepLibrary._calculateProfit(estimatedCallRewards_, estimatedTxCost);

        uint256 calculatedTxCost = _calculateTxCostWithOverheadWithPremium(gasUsedByPerformUpkeep_);
        uint256 calculatedProfit = UpkeepLibrary._calculateProfit(calculatedCallRewards_, calculatedTxCost);

        emit ProfitSummary(
            // predicted values
            estimatedTxCost,
            estimatedCallRewards_,
            estimatedProfit,
            // calculated values
            calculatedTxCost,
            calculatedCallRewards_,
            calculatedProfit
        );
    }

    function _multiHarvest(address[] memory vaults_)
        internal
        returns (
            uint256 numberOfSuccessfulHarvests_,
            uint256 numberOfFailedHarvests_,
            uint256 cumulativeCallRewards_
        )
    {
        bool[] memory isSuccessfulHarvest = new bool[](vaults_.length);
        for (uint256 i = 0; i < vaults_.length; ++i) {
            (bool didHarvest, uint256 callRewards) = _harvestVault(vaults_[i]);
            // Add rewards to cumulative tracker.
            if (didHarvest) {
                isSuccessfulHarvest[i] = true;
                cumulativeCallRewards_ += callRewards;
            }
        }

        (address[] memory successfulHarvests, address[] memory failedHarvests) = _getSuccessfulAndFailedVaults(
            vaults_,
            isSuccessfulHarvest
        );

        emit SuccessfulHarvests(block.number, successfulHarvests);
        emit FailedHarvests(block.number, failedHarvests);

        numberOfSuccessfulHarvests_ = successfulHarvests.length;
        numberOfFailedHarvests_ = failedHarvests.length;
        return (numberOfSuccessfulHarvests_, numberOfFailedHarvests_, cumulativeCallRewards_);
    }

    function _harvestVault(address vault_) internal returns (bool didHarvest_, uint256 callRewards_) {
        IBeefyStrategy strategy = IBeefyStrategy(IBeefyVault(vault_).strategy());
        callRewards_ = strategy.callReward();
        try strategy.harvest(_callFeeRecipient) {
            didHarvest_ = true;
        } catch {
            // try old function signature
            try strategy.harvestWithCallFeeRecipient(_callFeeRecipient) {
                didHarvest_ = true;
                /* solhint-disable no-empty-blocks */
            } catch {
                /* solhint-enable no-empty-blocks */
            }
        }

        return (didHarvest_, callRewards_);
    }

    function _getSuccessfulAndFailedVaults(address[] memory vaults_, bool[] memory isSuccessfulHarvest_)
        internal
        pure
        returns (address[] memory successfulHarvests_, address[] memory failedHarvests_)
    {
        uint256 successfulCount;
        for (uint256 i = 0; i < vaults_.length; i++) {
            if (isSuccessfulHarvest_[i]) {
                successfulCount += 1;
            }
        }

        successfulHarvests_ = new address[](successfulCount);
        failedHarvests_ = new address[](vaults_.length - successfulCount);
        uint256 successfulHarvestsIndex;
        uint256 failedHarvestIndex;
        for (uint256 i = 0; i < vaults_.length; i++) {
            if (isSuccessfulHarvest_[i]) {
                successfulHarvests_[successfulHarvestsIndex++] = vaults_[i];
            } else {
                failedHarvests_[failedHarvestIndex++] = vaults_[i];
            }
        }

        return (successfulHarvests_, failedHarvests_);
    }

    /*     */
    /* Set */
    /*     */

    function setPerformUpkeepGasLimit(uint256 performUpkeepGasLimit_) external override onlyManager {
        _performUpkeepGasLimit = performUpkeepGasLimit_;
    }

    function setPerformUpkeepGasLimitBuffer(uint256 performUpkeepGasLimitBuffer_) external override onlyManager {
        _performUpkeepGasLimitBuffer = performUpkeepGasLimitBuffer_;
    }

    function setHarvestGasConsumption(uint256 harvestGasConsumption_) external override onlyManager {
        _vaultHarvestFunctionGasOverhead = harvestGasConsumption_;
    }

    function setUpkeepRefunder(address upkeepRefunder_) external override onlyManager {
        _upkeepRefunder = IUpkeepRefunder(upkeepRefunder_);
        _callFeeRecipient = address(_upkeepRefunder);
    }

    /*      */
    /* View */
    /*      */

    function _calculateAdjustedGasCap() internal view returns (uint256 adjustedPerformUpkeepGasLimit_) {
        return _performUpkeepGasLimit - _performUpkeepGasLimitBuffer;
    }

    function _calculateTxCostWithPremium(uint256 gasOverhead_) internal view returns (uint256 txCost_) {
        return UpkeepLibrary._calculateUpkeepTxCost(tx.gasprice, gasOverhead_, _chainlinkUpkeepTxPremiumFactor);
    }

    function _calculateTxCostWithOverheadWithPremium(uint256 totalVaultHarvestOverhead_) internal view returns (uint256 txCost_) {
        return
            UpkeepLibrary._calculateUpkeepTxCostFromTotalVaultHarvestOverhead(
                tx.gasprice,
                totalVaultHarvestOverhead_,
                _keeperRegistryGasOverhead,
                _chainlinkUpkeepTxPremiumFactor
            );
    }

    function _calculateExpectedTotalUpkeepTxCost(uint256 numberOfVaultsToHarvest_)
        internal
        view
        returns (uint256 txCost_)
    {
        uint256 totalVaultHarvestGasOverhead = _vaultHarvestFunctionGasOverhead * numberOfVaultsToHarvest_;
        return
            UpkeepLibrary._calculateUpkeepTxCostFromTotalVaultHarvestOverhead(
                tx.gasprice,
                totalVaultHarvestGasOverhead,
                _keeperRegistryGasOverhead,
                _chainlinkUpkeepTxPremiumFactor
            );
    }

    function _estimateUpkeepGasOverhead(uint256 numberOfVaultsToHarvest_)
        internal
        view
        returns (uint256 totalGasOverhead_)
    {
        uint256 totalHarvestGasOverhead = _vaultHarvestFunctionGasOverhead * numberOfVaultsToHarvest_;
        totalGasOverhead_ = _keeperRegistryGasOverhead + totalHarvestGasOverhead;
    }

    function _estimateAdditionalGasOverheadPerVaultFromKeeperRegistryGasOverhead()
        internal
        view
        returns (uint256 evenlyDistributedOverheadPerVault_)
    {
        uint256 estimatedVaultCountPerUpkeep = _calculateAdjustedGasCap() / _vaultHarvestFunctionGasOverhead;
        // Evenly distribute the overhead to all vaults, assuming we will harvest max amount of vaults everytime.
        evenlyDistributedOverheadPerVault_ = _keeperRegistryGasOverhead / estimatedVaultCountPerUpkeep;
    }

    function _estimateTxCostWithPremiumBasedOnHarvestCount(uint256 numberOfVaultsToHarvest_)
        internal
        view
        returns (uint256 txCost_)
    {
        uint256 gasOverhead = _estimateUpkeepGasOverhead(numberOfVaultsToHarvest_);
        return _calculateTxCostWithPremium(gasOverhead);
    }

    function _estimateSingleVaultHarvestGasOverhead(uint256 vaultHarvestFunctionGasOverhead_)
        internal
        view
        returns (uint256 totalGasOverhead_)
    {
        totalGasOverhead_ =
            vaultHarvestFunctionGasOverhead_ + _keeperRegistryGasOverhead;
            // _estimateAdditionalGasOverheadPerVaultFromKeeperRegistryGasOverhead();
    }

    /*      */
    /* Misc */
    /*      */

    /**
     * @dev Rescues random funds stuck.
     * @param token_ address of the token to rescue.
     */
    function inCaseTokensGetStuck(address token_) external override onlyManager {
        IERC20Upgradeable token = IERC20Upgradeable(token_);

        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, amount);
    }
}