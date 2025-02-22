/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;
pragma experimental ABIEncoderV2;

library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex;
                // Replace lastValue's index to valueIndex
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


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
}


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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

library SafeBEP20 {
    using SafeMath for uint256;
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, 'e0');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'e1');
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
}

interface Token is IERC20 {
    function mint(address _to, uint256 _amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function MinerList(address _address) external returns (bool);
}

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

interface pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function factory() external view returns (address);
}


// interface dao {
//     function stakingNftOlderOwnerList(address _nftToken, uint256 _tokenID) external view returns (address);
// }

interface rewardOsPlus {
    function refererAddressList(address _user) external view returns (address);

    function addRewardList(address _user, uint256 _rewardAmount, uint256 _type) external;

    function refererRate() external view returns (uint256);

    function userRate() external view returns (uint256);
}

contract MasterChefForErc20 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardDebt2;
        // uint256 daoTokenId;
    }

    struct poolInfo0 {
        IERC20 rewardToken;
        IERC20 lpToken;
    }

    struct poolInfo1 {
        bool limitWithdrawTime;
        bool pool_status;
        bool onlyRewardMode;
        bool updatePool;
        bool isLP;
    }

    struct poolInfo2 {
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accCakePerShare;
        uint256 staking_stock_length;
        uint256 refererrate;
        uint256 startBlock;
        uint256 bonusEndBlock;
        uint256 accCakePerShare2;
    }

    struct PoolInfoItem {
        uint256 pid;
        poolInfo0 tokensList;
        poolInfo1 statusList;
        poolInfo2 poolConfigList;
    }

    struct pairReservesItem {
        address pair;
        address factory;
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 decimals0;
        uint256 decimals1;
        uint256 lpDecimals;
        uint256 totalLpSupply;
        string symbol0;
        string symbol1;
        string name0;
        string name1;

    }

    Token public cake;
    address public devaddr;
    // dao public daoAddress;
    // address public daoNftToken;
    uint256 public cakePerBlock;
    uint256 public BONUS_MULTIPLIER = 1;
    uint256 public poolLength = 0;
    mapping(uint256 => PoolInfoItem) public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    bool public limitGetRewardTime = false;
    bool public useWhiteList = false;
    bool public useMintMode = true;
    // bool public useDaoReward;
    bool public useRewardOsPlus = false;
    rewardOsPlus public rewardOsPlusAddress;

    // event Deposit(address indexed user, uint256 indexed pid, uint256 tokenId, uint256 unlockTime);
    // event Withdraw(address indexed user, uint256 indexed pid, uint256 tokenId);
    // event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    mapping(uint256 => mapping(address => uint256)) public staking_time;
    mapping(uint256 => mapping(address => uint256)) public unlock_time;
    mapping(uint256 => uint256) public stakingNumForPool;
    mapping(uint256 => mapping(address => uint256)) public pending_list;
    mapping(uint256 => mapping(address => uint256)) public pending_list2;
    mapping(uint256 => mapping(address => uint256)) public allrewardList;
    mapping(uint256 => mapping(address => uint256)) public allrewardList2;
    mapping(address => bool) public white_list;
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private userStakingTokenForPoolIdListSet;
    mapping(address => EnumerableSet.UintSet) private userStakingTokenIdListSet;
    mapping(address => EnumerableSet.UintSet) private userBurnToPoolSet;
    mapping(IERC20 => EnumerableSet.UintSet) private rewardTokenList;
    mapping(IERC20 => uint256) public RewardTokenPerBlockList;
    mapping(address => bool) public depositProxyList;
    EnumerableSet.AddressSet private stakingAddress;
    EnumerableSet.AddressSet private lpTokenSet;

    event updatePoolEvent(uint256 lpSupply, uint256 num, uint256 totalLpSupply, uint256 totalNum, uint256 cakeReward);
    event safeCakeTransferEvent(IERC20 _rewardToken, address _to, uint256 _amount, uint256 cakeBalance);

    constructor()  {
        devaddr = msg.sender;
        totalAllocPoint = 0;
    }

    function setDepositProxyList(address[] memory _addressList, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _addressList.length; i++) {
            depositProxyList[_addressList[i]] = _status;
        }
    }

    function setUseMintMode(bool _useMintMode) external onlyOwner {
        useMintMode = _useMintMode;
    }

    function setRewardOsPlus(bool _useRewardOsPlus, rewardOsPlus _rewardOsPlusAddress) external onlyOwner {
        useRewardOsPlus = _useRewardOsPlus;
        rewardOsPlusAddress = _rewardOsPlusAddress;
    }

    function setLimitGetRewardTime(bool _limitGetRewardTime) external onlyOwner {
        limitGetRewardTime = _limitGetRewardTime;
    }

    function setUseWhiteList(bool _useWhiteList) external onlyOwner {
        useWhiteList = _useWhiteList;
    }

    function setWhiteList(address[] memory _address_list) external onlyOwner {
        for (uint256 i = 0; i < _address_list.length; i++) {
            white_list[_address_list[i]] = true;
        }
    }

    function removeWhiteList(address[] memory _address_list) external onlyOwner {
        for (uint256 i = 0; i < _address_list.length; i++) {
            white_list[_address_list[i]] = false;
        }
    }

    function setCakePerBlockAndCake(Token _cake, uint256 _cakePerBlock) external onlyOwner {
        if (useMintMode) {
            require(_cake.MinerList(address(this)), "e0");
        }
        massUpdatePools();
        cake = _cake;
        cakePerBlock = _cakePerBlock;
        RewardTokenPerBlockList[cake] = _cakePerBlock;
    }

    function updateMultiplier(uint256 multiplierNumber) external onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function addPool(uint256 _allocPoint, IERC20 _lpToken, bool _isLP, bool _limitWithdrawTime, uint256 _staking_stock_length, uint256 _startBlock, uint256 _bonusEndBlock, uint256 _daoRewardRate, IERC20 _rewardToken, bool _updatePool, bool _onlyRewardMode) external onlyOwner {
        if (_isLP && !lpTokenSet.contains(address(_lpToken))) {
            lpTokenSet.add(address(_lpToken));
        }
        if (_onlyRewardMode) {
            require(_rewardToken != cake, "e001");
        }
        if (_updatePool) {
            massUpdatePools();
        }
        require(RewardTokenPerBlockList[cake] > 0 && RewardTokenPerBlockList[_rewardToken] > 0, "e002");
        require(address(rewardOsPlusAddress) != address(0), "e003");
        uint256 lastRewardBlock = block.timestamp > _startBlock ? block.timestamp : _startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        PoolInfoItem memory poolItem = (new PoolInfoItem[](1))[0];
        poolItem.pid = poolLength;
        poolItem.tokensList = poolInfo0({
        rewardToken : _rewardToken,
        lpToken : _lpToken
        });
        poolItem.statusList = poolInfo1({
        isLP : _isLP,
        limitWithdrawTime : _limitWithdrawTime,
        pool_status : true,
        updatePool : _updatePool,
        onlyRewardMode : _onlyRewardMode
        });
        poolItem.poolConfigList = poolInfo2({
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accCakePerShare : 0,
        accCakePerShare2 : 0,
        staking_stock_length : _staking_stock_length,
        refererrate : _daoRewardRate,
        startBlock : _startBlock,
        bonusEndBlock : _bonusEndBlock
        });
        poolInfo[poolLength] = poolItem;
        if (_rewardToken != cake) {
            rewardTokenList[_rewardToken].add(poolLength);
        }
        if (!_onlyRewardMode) {
            rewardTokenList[cake].add(poolLength);
        }
        poolLength = poolLength.add(1);
    }

    function getRewardTokenList(IERC20 _rewardToken) external view returns (uint256[] memory) {
        return rewardTokenList[_rewardToken].values();
    }

    function getRewardTokenListNum(IERC20 _rewardToken) external view returns (uint256) {
        return rewardTokenList[_rewardToken].length();
    }

    function setPool(uint256 _pid, bool _limitWithdrawTime, uint256 _staking_stock_length) external onlyOwner {
        updatePool(_pid);
        PoolInfoItem memory poolItem = poolInfo[_pid];
        poolItem.statusList.limitWithdrawTime = _limitWithdrawTime;
        poolItem.poolConfigList.staking_stock_length = _staking_stock_length;
    }

    function setPool2(uint256 _pid, uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        updatePool(_pid);
        PoolInfoItem memory poolItem = poolInfo[_pid];
        poolItem.poolConfigList.startBlock = _startBlock;
        poolItem.poolConfigList.bonusEndBlock = _bonusEndBlock;
    }

    function setPool3(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        massUpdatePools();
        PoolInfoItem memory poolItem = poolInfo[_pid];
        poolItem.poolConfigList.allocPoint = _allocPoint;
    }

    function updatePoolIsLP(uint256 _pid, bool _isLP) external onlyOwner {
        address _lpToken = address(poolInfo[_pid].tokensList.lpToken);
        if (_isLP && !lpTokenSet.contains(_lpToken)) {
            lpTokenSet.add(_lpToken);
        } else if (!_isLP && lpTokenSet.contains(_lpToken)) {
            lpTokenSet.remove(_lpToken);
        }
        poolInfo[_pid].statusList.isLP = _isLP;
    }

    function enablePool(uint256 _pid) external onlyOwner {
        updatePool(_pid);
        poolInfo[_pid].statusList.pool_status = true;
    }

    function disablePool(uint256 _pid) external onlyOwner {
        updatePool(_pid);
        poolInfo[_pid].statusList.pool_status = false;
    }

    function getMultiplier(uint256 _pid, uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 bonusEndBlock = poolInfo[_pid].poolConfigList.bonusEndBlock;
        uint256 fromBlock = poolInfo[_pid].poolConfigList.startBlock;
        if (!poolInfo[_pid].statusList.pool_status || block.timestamp < fromBlock) {
            return 0;
        }
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    function getTotalAllocPoint2(IERC20 _rewardToken) public view returns (uint256) {
        uint256 totalAllocPoint2 = 0;
        uint256 poolNum = rewardTokenList[_rewardToken].length();
        for (uint256 i = 0; i < poolNum; i++) {
            totalAllocPoint2 = totalAllocPoint2.add((poolInfo[rewardTokenList[_rewardToken].at(i)]).poolConfigList.allocPoint);
        }
        return totalAllocPoint2;
    }

    function pendingCake(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfoItem storage pool = poolInfo[_pid];
        if (pool.statusList.onlyRewardMode) {
            return 0;
        }
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCakePerShare = pool.poolConfigList.accCakePerShare;
        uint256 lpSupply = stakingNumForPool[_pid];
        if (block.timestamp > pool.poolConfigList.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(_pid, pool.poolConfigList.lastRewardBlock, block.timestamp);
            uint256 cakeReward = multiplier.mul(cakePerBlock).mul(pool.poolConfigList.allocPoint).div(getTotalAllocPoint2(cake));
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt);
    }

    function pendingCake2(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfoItem storage pool = poolInfo[_pid];
        if (pool.tokensList.rewardToken == cake) {
            return 0;
        }
        UserInfo storage user = userInfo[_pid][_user];
        IERC20 rewardToken = pool.tokensList.rewardToken;
        uint256 accCakePerShare2 = pool.poolConfigList.accCakePerShare2;
        uint256 lpSupply = stakingNumForPool[_pid];
        uint256 totalAllocPoint2 = getTotalAllocPoint2(rewardToken);
        if (block.timestamp > pool.poolConfigList.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(_pid, pool.poolConfigList.lastRewardBlock, block.timestamp);
            uint256 tokenReward = multiplier.mul(RewardTokenPerBlockList[rewardToken]).mul(pool.poolConfigList.allocPoint).div(totalAllocPoint2);
            accCakePerShare2 = accCakePerShare2.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCakePerShare2).div(1e12).sub(user.rewardDebt2);
    }

    function updatePool(uint256 _pid) public {
        PoolInfoItem storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.poolConfigList.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = stakingNumForPool[_pid];
        if (lpSupply == 0) {
            pool.poolConfigList.lastRewardBlock = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(_pid, pool.poolConfigList.lastRewardBlock, block.timestamp);
        if (!pool.statusList.onlyRewardMode) {
            uint256 cakeReward = multiplier.mul(cakePerBlock).mul(pool.poolConfigList.allocPoint).div(getTotalAllocPoint2(cake));
            pool.poolConfigList.accCakePerShare = pool.poolConfigList.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));

            if (useMintMode && cake.MinerList(address(this))) {
                cake.mint(address(this), cakeReward);
            }
        }
        if (pool.tokensList.rewardToken != cake) {
            IERC20 rewardToken = pool.tokensList.rewardToken;
            uint256 totalAllocPoint2 = getTotalAllocPoint2(rewardToken);
            uint256 tokenReward = multiplier.mul(RewardTokenPerBlockList[rewardToken]).mul(pool.poolConfigList.allocPoint).div(totalAllocPoint2);
            pool.poolConfigList.accCakePerShare2 = pool.poolConfigList.accCakePerShare2.add(tokenReward.mul(1e12).div(lpSupply));
        }
        pool.poolConfigList.lastRewardBlock = block.timestamp;
        // emit updatePoolEvent(lpSupply, num, totalLpSupply, totalNum, cakeReward);
    }

    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolLength; pid++) {
            updatePool(pid);
        }
    }

    function isContract(address _address) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }

    function deposit(uint256 _pid, uint256 _depositAmount) external {
        address _proxy = address(0);
        depositByUser(_proxy, msg.sender, _pid, _depositAmount);
    }

    modifier onlyProxyList() {
        require(depositProxyList[_msgSender()], "e001");
        _;
    }

    function depositByProxy(address _user, uint256 _pid, uint256 _depositAmount) external onlyProxyList {
        address _proxy = msg.sender;
        depositByUser(_proxy, _user, _pid, _depositAmount);
    }

    function massDepositByProxy(address[] memory _userList, uint256 _pid, uint256 _depositAmount) external onlyProxyList {
        address _proxy = msg.sender;
        for (uint256 i = 0; i < _userList.length; i++) {
            depositByUser(_proxy, _userList[i], _pid, _depositAmount);
        }
    }

    function depositByUser(address _proxy, address _user, uint256 _pid, uint256 _depositAmount) internal {
        updatePool(_pid);
        require(poolInfo[_pid].statusList.pool_status, "e4");
        PoolInfoItem storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        address fromAddress;
        if (_proxy == address(0)) {
            fromAddress = _user;
        } else {
            fromAddress = _proxy;
        }

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.poolConfigList.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                pending_list[_pid][_user] = pending_list[_pid][_user].add(pending);
            }
            if (pool.tokensList.rewardToken != cake) {
                uint256 pending2 = user.amount.mul(pool.poolConfigList.accCakePerShare2).div(1e12).sub(user.rewardDebt2);
                if (pending2 > 0) {
                    pending_list2[_pid][_user] = pending_list2[_pid][_user].add(pending2);
                }
            }
        }
        if (_depositAmount > 0) {
            uint256 balanceOld = pool.tokensList.lpToken.balanceOf(address(this));
            pool.tokensList.lpToken.transferFrom(fromAddress, address(this), _depositAmount);
            uint256 balanceNew = pool.tokensList.lpToken.balanceOf(address(this));
            uint256 addAmount = balanceNew.sub(balanceOld);
            stakingNumForPool[_pid] = stakingNumForPool[_pid].add(addAmount);
            uint256 oldStaking = user.amount;
            uint256 newStaking = user.amount.add(addAmount);
            user.amount = user.amount.add(addAmount);
            uint256 oldUnlockTime;
            uint256 newUnlockTime;
            if (unlock_time[_pid][_user] == 0) {
                oldUnlockTime = block.timestamp.add(pool.poolConfigList.staking_stock_length);
            } else {
                oldUnlockTime = unlock_time[_pid][_user];
            }
            if (oldUnlockTime >= block.timestamp) {
                newUnlockTime = oldStaking.mul(oldUnlockTime.sub(block.timestamp)).add(addAmount.mul(pool.poolConfigList.staking_stock_length)).div(newStaking);
            } else {
                newUnlockTime = addAmount.mul(pool.poolConfigList.staking_stock_length).div(newStaking);
            }
            unlock_time[_pid][_user] = block.timestamp.add(newUnlockTime);
            staking_time[_pid][_user] = block.timestamp;
        }
        user.rewardDebt = user.amount.mul(pool.poolConfigList.accCakePerShare).div(1e12);
        if (pool.tokensList.rewardToken != cake) {
            user.rewardDebt2 = user.amount.mul(pool.poolConfigList.accCakePerShare2).div(1e12);
        }
    }

    function withdraw(uint256 _pid, uint256 _withdrawAmount) external nonReentrant {
        address _user = msg.sender;
        updatePool(_pid);
        if (poolInfo[_pid].statusList.limitWithdrawTime) {
            if (!useWhiteList) {
                require(block.timestamp > unlock_time[_pid][msg.sender], "e10");
            } else {
                if (!white_list[msg.sender]) {
                    require(block.timestamp > unlock_time[_pid][msg.sender], "e11");
                }
            }
        }
        PoolInfoItem storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 pending = user.amount.mul(pool.poolConfigList.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            pending_list[_pid][_user] = pending_list[_pid][_user].add(pending);
        }

        if (pool.tokensList.rewardToken != cake) {
            uint256 pending2 = user.amount.mul(pool.poolConfigList.accCakePerShare2).div(1e12).sub(user.rewardDebt2);
            if (pending2 > 0) {
                pending_list2[_pid][_user] = pending_list2[_pid][_user].add(pending2);
            }
        }
        pool.tokensList.lpToken.transfer(_user, _withdrawAmount);
        user.amount = user.amount.sub(_withdrawAmount);
        stakingNumForPool[_pid] = stakingNumForPool[_pid].sub(_withdrawAmount);
        user.rewardDebt = user.amount.mul(pool.poolConfigList.accCakePerShare).div(1e12);
        if (pool.tokensList.rewardToken != cake) {
            user.rewardDebt2 = user.amount.mul(pool.poolConfigList.accCakePerShare2).div(1e12);
        }
    }

    function _getReward(uint256 _pid, address _user) private {
        updatePool(_pid);
        PoolInfoItem storage pool = poolInfo[_pid];
        address referer = rewardOsPlusAddress.refererAddressList(msg.sender);
        uint256 refererrate = pool.poolConfigList.refererrate;
        if (limitGetRewardTime) {
            if (!useWhiteList) {
                require(block.timestamp > unlock_time[_pid][_user], "e7");
            } else {
                if (!white_list[_user]) {
                    require(block.timestamp > unlock_time[_pid][_user], "e8");
                }
            }
        }
        UserInfo storage user = userInfo[_pid][_user];
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.poolConfigList.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0 && !pool.statusList.onlyRewardMode) {
                pending_list[_pid][_user] = pending_list[_pid][_user].add(pending);
            }
            if (pool.tokensList.rewardToken != cake) {
                uint256 pending2 = user.amount.mul(pool.poolConfigList.accCakePerShare2).div(1e12).sub(user.rewardDebt2);
                if (pending2 > 0) {
                    pending_list2[_pid][_user] = pending_list2[_pid][_user].add(pending2);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.poolConfigList.accCakePerShare).div(1e12);
        if (pool.tokensList.rewardToken != cake) {
            user.rewardDebt2 = user.amount.mul(pool.poolConfigList.accCakePerShare2).div(1e12);
        }
        if (pending_list[_pid][_user] > 0 && !pool.statusList.onlyRewardMode) {
            uint256 allAmount = pending_list[_pid][_user];
            uint256 rewardAmount = allAmount.mul(refererrate).div(100);
            uint256 leftAmount = allAmount.sub(rewardAmount);
            allrewardList[_pid][_user] = allrewardList[_pid][_user].add(leftAmount);
            safeTokenTransfer(cake, _user, leftAmount);
            if (useRewardOsPlus) {
                if (referer == address(0)) {
                    safeTokenTransfer(cake, address(1), rewardAmount);
                } else {
                    uint256 rewardAmountForUser = rewardAmount.mul(rewardOsPlusAddress.userRate()).div(100);
                    uint256 rewardAmountForReferer = rewardAmount.sub(rewardAmountForUser);
                    safeTokenTransfer(cake, _user, rewardAmountForUser);
                    safeTokenTransfer(cake, referer, rewardAmountForReferer);
                }
                rewardOsPlusAddress.addRewardList(msg.sender, rewardAmount, 4);
            }
            pending_list[_pid][_user] = 0;
        }
        if (pool.tokensList.rewardToken != cake && pending_list2[_pid][_user] > 0) {
            uint256 allAmount = pending_list2[_pid][_user];
            uint256 rewardAmount = allAmount.mul(refererrate).div(100);
            uint256 leftAmount = allAmount.sub(rewardAmount);
            allrewardList2[_pid][_user] = allrewardList2[_pid][_user].add(leftAmount);
            safeTokenTransfer(pool.tokensList.rewardToken, _user, leftAmount);
            if (useRewardOsPlus) {
                if (referer == address(0)) {
                    safeTokenTransfer(pool.tokensList.rewardToken, address(1), rewardAmount);
                } else {
                    uint256 rewardAmountForUser = rewardAmount.mul(rewardOsPlusAddress.userRate()).div(100);
                    uint256 rewardAmountForReferer = rewardAmount.sub(rewardAmountForUser);
                    safeTokenTransfer(pool.tokensList.rewardToken, _user, rewardAmountForUser);
                    safeTokenTransfer(pool.tokensList.rewardToken, referer, rewardAmountForReferer);
                }
            }
            pending_list2[_pid][_user] = 0;
        }
    }

    function getReward(uint256 _pid) external nonReentrant {
        _getReward(_pid, msg.sender);
    }

    function massGetReward() external nonReentrant {
        address _user = msg.sender;
        for (uint256 _pid = 0; _pid < poolLength; _pid++) {
            if (userInfo[_pid][_user].amount > 0 || pending_list[_pid][_user] > 0) {
                _getReward(_pid, msg.sender);
            }
        }
    }

    function safeTokenTransfer(IERC20 _rewardToekn, address _to, uint256 _amount) internal {
        uint256 cakeBalance = _rewardToekn.balanceOf(address(this));
        if (_amount > cakeBalance) {
            _rewardToekn.transfer(_to, cakeBalance);
        } else {
            _rewardToekn.transfer(_to, _amount);
        }
        emit safeCakeTransferEvent(_rewardToekn, _to, _amount, cakeBalance);
    }

    function setRewardTokenPerBlock(IERC20 _rewardToken, uint256 _rewardAmount) external onlyOwner {
        require(_rewardToken != cake, "e001");
        RewardTokenPerBlockList[_rewardToken] = _rewardAmount;
        uint256 poolNum = rewardTokenList[_rewardToken].length();
        for (uint256 i = 0; i < poolNum; i++) {
            updatePool(rewardTokenList[_rewardToken].at(i));
        }
    }

    function setdev(address _devaddr) external {
        require(msg.sender == devaddr || msg.sender == owner(), "e18");
        devaddr = _devaddr;
    }

    struct getInfoForUserItem {
        PoolInfoItem poolinfo;
        UserInfo userinfo;
        uint256 unlockTime;
        uint256 stakingTime;
        uint256 pendingAmount;
        uint256 pendingAmount2;
        uint256 pendingCake;
        uint256 pendingCake2;
        uint256 allPendingReward;
        uint256 allPendingReward2;
        uint256 stakingNumAll;
        uint256 allreward;
        uint256 allreward2;
        uint256 lpTokenBalance;
        uint256 totalAllocPoint;
        uint256 totalAllocPoint2;
        uint256 cakePerBlock;
        uint256 rewardTokenPerBlock;
        bool limitGetRewardTime;
        bool limitWithdrawTime;
        bool useWhiteList;
    }

    function getInfoForUser(uint256 _pid, address _user) public view returns (getInfoForUserItem memory getInfoForUserInfo) {
        getInfoForUserInfo.poolinfo = poolInfo[_pid];
        getInfoForUserInfo.userinfo = userInfo[_pid][_user];
        getInfoForUserInfo.unlockTime = unlock_time[_pid][_user];
        getInfoForUserInfo.stakingTime = staking_time[_pid][_user];
        getInfoForUserInfo.pendingAmount = pending_list[_pid][_user];
        getInfoForUserInfo.pendingAmount2 = pending_list2[_pid][_user];
        uint256 pending = pendingCake(_pid, _user);
        uint256 pending2 = pendingCake2(_pid, _user);
        getInfoForUserInfo.pendingCake = pending;
        getInfoForUserInfo.pendingCake2 = pending2;
        getInfoForUserInfo.allPendingReward = pending_list[_pid][_user].add(pending);
        getInfoForUserInfo.allPendingReward2 = pending_list2[_pid][_user].add(pending2);
        getInfoForUserInfo.stakingNumAll = stakingNumForPool[_pid];
        getInfoForUserInfo.allreward = allrewardList[_pid][_user];
        getInfoForUserInfo.allreward2 = allrewardList2[_pid][_user];
        getInfoForUserInfo.lpTokenBalance = poolInfo[_pid].tokensList.lpToken.balanceOf(_user);
        getInfoForUserInfo.totalAllocPoint = getTotalAllocPoint2(cake);
        getInfoForUserInfo.totalAllocPoint2 = getTotalAllocPoint2(poolInfo[_pid].tokensList.rewardToken);
        getInfoForUserInfo.limitGetRewardTime = limitGetRewardTime;
        getInfoForUserInfo.limitWithdrawTime = poolInfo[_pid].statusList.limitWithdrawTime;
        getInfoForUserInfo.useWhiteList = useWhiteList;
        getInfoForUserInfo.cakePerBlock = cakePerBlock;
        getInfoForUserInfo.rewardTokenPerBlock = RewardTokenPerBlockList[poolInfo[_pid].tokensList.rewardToken];
    }

    function MassGetInfoForUser(address _user) external view returns (getInfoForUserItem[] memory getInfoForUserInfoList) {
        getInfoForUserInfoList = new getInfoForUserItem[](poolLength);
        for (uint256 i = 0; i < poolLength; i++) {
            getInfoForUserInfoList[i] = getInfoForUser(i, _user);
        }
    }

    function getTokensReserves(address[] memory _pairList) public view returns (pairReservesItem[] memory pairReservesList) {
        pairReservesList = new pairReservesItem[](_pairList.length);
        for (uint256 i = 0; i < _pairList.length; i++)
        {
            address _pair = _pairList[i];
            address token0 = pair(_pair).token0();
            address token1 = pair(_pair).token1();
            (uint256 reserve0, uint256 reserve1,) = pair(_pair).getReserves();
            pairReservesList[i] = pairReservesItem(_pair, pair(_pair).factory(), token0, token1, reserve0, reserve1, IERC20(token0).decimals(), IERC20(token1).decimals(), pair(_pair).decimals(), pair(_pair).totalSupply(), IERC20(token0).symbol(), IERC20(token1).symbol(), IERC20(token0).name(), IERC20(token1).name());
        }
    }

    function getLpTokenSetNum() public view returns (uint256 num) {
        num = lpTokenSet.length();
    }

    function getLpTokenSet() public view returns (address[] memory lpTokenList) {
        lpTokenList = lpTokenSet.values();
    }

    function getAllLp() external view returns (pairReservesItem[] memory pairReservesList) {
        address[] memory _pairList = getLpTokenSet();
        pairReservesList = getTokensReserves(_pairList);
    }
}