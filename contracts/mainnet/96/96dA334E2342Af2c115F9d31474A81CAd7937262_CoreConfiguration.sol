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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICoreConfiguration.sol";

/**
 * @title CoreConfiguration
 * @notice This contract stores the core configuration of the Foxify protocol.
 */
contract CoreConfiguration is ICoreConfiguration, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant DIVIDER = 1 ether;
    uint256 public constant MAX_PROTOCOL_FEE = 0.2 ether; // TODO: need set production value
    uint256 public constant MAX_FLASHLOAN_FEE = 0.2 ether; // TODO: need set production value

    NFTDiscountLevel private _discount;
    FeeConfiguration private _feeConfiguration;
    ImmutableConfiguration private _immutableConfiguration;
    LimitsConfiguration private _limitsConfiguration;
    Swapper private _swapper;

    EnumerableSet.AddressSet private _keepers;
    EnumerableSet.AddressSet private _oracles;
    EnumerableSet.AddressSet private _oraclesWhitelist;

    /**
     * @notice Returns the discount for NFTs of different tiers.
     * @return bronze The discount for bronze NFTs.
     * @return silver The discount for silver NFTs.
     * @return gold The discount for gold NFTs.
     */
    function discount() external view returns (uint256 bronze, uint256 silver, uint256 gold) {
        return (_discount.bronze, _discount.silver, _discount.gold);
    }

    /**
     * @notice Returns the fee configuration.
     * @return feeRecipient The address that receives the protocol fee.
     * @return autoResolveFee The fee for automatically resolving disputes.
     * @return protocolFee The fee for using the protocol.
     * @return flashloanFee The fee for taking out a flash loan.
     */
    function feeConfiguration()
        external
        view
        returns (address feeRecipient, uint256 autoResolveFee, uint256 protocolFee, uint256 flashloanFee)
    {
        return (
            _feeConfiguration.feeRecipient,
            _feeConfiguration.autoResolveFee,
            _feeConfiguration.protocolFee,
            _feeConfiguration.flashloanFee
        );
    }

    /**
     * @notice Returns the immutable configuration.
     * @return blacklist The address of the blacklist contract.
     * @return affiliation The address of the affiliation contract.
     * @return positionTokenAccepter The address of the position token accepter contract.
     * @return stable The address of the stablecoin contract.
     */
    function immutableConfiguration()
        external
        view
        returns (
            IFoxifyBlacklist blacklist,
            IFoxifyAffiliation affiliation,
            IPositionToken positionTokenAccepter,
            IERC20Stable stable,
            ICoreUtilities utils
        )
    {
        return (
            _immutableConfiguration.blacklist,
            _immutableConfiguration.affiliation,
            _immutableConfiguration.positionTokenAccepter,
            _immutableConfiguration.stable,
            _immutableConfiguration.utils
        );
    }

    /**
     * @notice Returns the list of keepers.
     * @param index The index of the keeper to return.
     * @return The address of the keeper at the specified index.
     */
    function keepers(uint256 index) external view returns (address) {
        return _keepers.at(index);
    }

    /**
     * @notice Returns the number of keepers.
     * @return The number of keepers.
     */
    function keepersCount() external view returns (uint256) {
        return _keepers.length();
    }

    /**
     * @notice Returns true if the specified address is a keeper.
     * @param keeper The address to check.
     * @return True if the specified address is a keeper. False otherwise.
     */
    function keepersContains(address keeper) external view returns (bool) {
        return _keepers.contains(keeper);
    }

    /**
     * @notice Get the limits configuration values.
     * @return minStableAmount The minimum stable amount allowed.
     * @return minOrderRate The minimum order rate allowed.
     * @return maxOrderRate The maximum order rate allowed.
     * @return minDuration The minimum duration allowed for an order.
     * @return maxDuration The maximum duration allowed for an order.
     */
    function limitsConfiguration()
        external
        view
        returns (
            uint256 minStableAmount,
            uint256 minOrderRate,
            uint256 maxOrderRate,
            uint256 minDuration,
            uint256 maxDuration
        )
    {
        return (
            _limitsConfiguration.minStableAmount,
            _limitsConfiguration.minOrderRate,
            _limitsConfiguration.maxOrderRate,
            _limitsConfiguration.minDuration,
            _limitsConfiguration.maxDuration
        );
    }

    /**
     * @notice Get the oracle at the specified index.
     * @param index The index of the oracle.
     * @return The address of the oracle.
     */
    function oracles(uint256 index) external view returns (address) {
        return _oracles.at(index);
    }

    /**
     * @notice Get the number of oracles.
     * @return The number of oracles.
     */
    function oraclesCount() external view returns (uint256) {
        return _oracles.length();
    }

    /**
     * @notice Check if the oracle exists in the oracles set.
     * @param oracle The address of the oracle.
     * @return A boolean indicating if the oracle exists.
     */
    function oraclesContains(address oracle) external view returns (bool) {
        return _oracles.contains(oracle);
    }

    /**
     * @notice Get the oracle in the whitelist at the specified index.
     * @param index The index of the oracle in the whitelist.
     * @return The address of the oracle.
     */
    function oraclesWhitelist(uint256 index) external view returns (address) {
        return _oraclesWhitelist.at(index);
    }

    /**
     * @notice Get the number of oracles in the whitelist.
     * @return The number of oracles in the whitelist.
     */
    function oraclesWhitelistCount() external view returns (uint256) {
        return _oraclesWhitelist.length();
    }

    /**
     * @notice Check if the oracle exists in the oracles whitelist.
     * @param oracle The address of the oracle.
     * @return A boolean indicating if the oracle exists in the whitelist.
     */
    function oraclesWhitelistContains(address oracle) external view returns (bool) {
        return _oraclesWhitelist.contains(oracle);
    }

    /**
     * @notice Get the swapper configuration values.
     * @return connector The swapper connector used.
     * @return path The path used for swapping.
     */
    function swapper() external view returns (ISwapperConnector connector, bytes memory path) {
        return (_swapper.swapperConnector, _swapper.path);
    }

    /**
     * @notice Constructor for the CoreConfiguration contract.
     * @param immutableConfiguration_ The initial configuration settings for immutable components.
     * @param discount_ The initial NFT discount levels.
     * @param feeConfiguration_ The initial fee configuration settings.
     * @param limitsConfiguration_ The initial limits configuration settings.
     * @param swapper_ The initial swapper configuration settings.
     */
    constructor(
        ImmutableConfiguration memory immutableConfiguration_,
        NFTDiscountLevel memory discount_,
        FeeConfiguration memory feeConfiguration_,
        LimitsConfiguration memory limitsConfiguration_,
        Swapper memory swapper_
    ) {
        require(address(immutableConfiguration_.stable) != address(0), "CoreConfiguration: Stable is zero address");
        require(
            address(immutableConfiguration_.positionTokenAccepter) != address(0),
            "CoreConfiguration: Position token Accepter is zero address"
        );
        require(
            address(immutableConfiguration_.affiliation) != address(0),
            "CoreConfiguration: Affiliation is zero address"
        );
        require(
            address(immutableConfiguration_.blacklist) != address(0),
            "CoreConfiguration: Blacklist is zero address"
        );
        require(
            address(immutableConfiguration_.utils) != address(0),
            "CoreConfiguration: Utils is zero address"
        );
        _immutableConfiguration = immutableConfiguration_;
        _updateDiscount(discount_);
        _updateFeeConfiguration(feeConfiguration_);
        _updateLimitsConfiguration(limitsConfiguration_);
        _updateSwapper(swapper_);
    }

    /**
     * @notice Add keepers to the keepers set.
     * @param keepers_ An array of keeper addresses to add.
     * @return A boolean indicating if the keepers were added successfully.
     */
    function addKeepers(address[] memory keepers_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < keepers_.length; i++) {
            address keeper_ = keepers_[i];
            require(keeper_ != address(0), "CoreConfiguration: Keeper is zero address");
            _keepers.add(keeper_);
        }
        emit KeepersAdded(keepers_);
        return true;
    }

    /**
     * @notice Add oracles to the oracles set and whitelist.
     * @param oracles_ An array of oracle addresses to add.
     * @return A boolean indicating if the oracles were added successfully.
     */
    function addOracles(address[] memory oracles_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < oracles_.length; i++) {
            _oracles.add(oracles_[i]);
            _oraclesWhitelist.add(oracles_[i]);
        }
        emit OraclesAdded(oracles_);
        return true;
    }

    /**
     * @notice Remove keepers from the keepers set.
     * @param keepers_ An array of keeper addresses to remove.
     * @return A boolean indicating if the keepers were removed successfully.
     */
    function removeKeepers(address[] memory keepers_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < keepers_.length; i++) {
            address keeper_ = keepers_[i];
            _keepers.remove(keeper_);
        }
        emit KeepersRemoved(keepers_);
        return true;
    }

    /**
     * @notice Remove oracles from the oracles set.
     * @param oracles_ An array of oracle addresses to remove.
     * @return A boolean indicating if the oracles were removed successfully.
     */
    function removeOracles(address[] memory oracles_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < oracles_.length; i++) {
            _oracles.remove(oracles_[i]);
        }
        emit OraclesRemoved(oracles_);
        return true;
    }

    /**
     * @notice Remove oracles from the oracles whitelist.
     * @param oracles_ An array of oracle addresses to remove from the whitelist.
     * @return A boolean indicating if the oracles were removed from the whitelist successfully.
     */
    function removeOraclesWhitelist(address[] memory oracles_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < oracles_.length; i++) {
            _oraclesWhitelist.remove(oracles_[i]);
        }
        emit OraclesWhitelistRemoved(oracles_);
        return true;
    }

    /**
     * @notice Update the NFT discount levels.
     * @param discount_ The new NFTDiscountLevel values.
     * @return A boolean indicating if the discount levels were updated successfully.
     */
    function updateDiscount(NFTDiscountLevel memory discount_) external onlyOwner returns (bool) {
        _updateDiscount(discount_);
        return true;
    }

    /**
     * @notice Update the fee configuration values.
     * @param config The new FeeConfiguration values.
     * @return A boolean indicating if the fee configuration was updated successfully.
     */
    function updateFeeConfiguration(FeeConfiguration memory config) external onlyOwner returns (bool) {
        _updateFeeConfiguration(config);
        return true;
    }

    /**
     * @notice Update the limits configuration values.
     * @param config The new LimitsConfiguration values.
     * @return A boolean indicating if the limits configuration was updated successfully.
     */
    function updateLimitsConfiguration(LimitsConfiguration memory config) external onlyOwner returns (bool) {
        _updateLimitsConfiguration(config);
        return true;
    }

    /**
     * @notice Update the swapper configuration values.
     * @param swapper_ The new Swapper values.
     * @return A boolean indicating if the swapper configuration was updated successfully.
     */
    function updateSwapper(Swapper memory swapper_) external onlyOwner returns (bool) {
        _updateSwapper(swapper_);
        return true;
    }

    /**
     * @notice Updates the NFT discount levels.
     * @param discount_ The new NFT discount levels.
     */
    function _updateDiscount(NFTDiscountLevel memory discount_) private {
        require(
            discount_.bronze <= DIVIDER && discount_.silver <= DIVIDER && discount_.gold <= DIVIDER,
            "CoreConfiguration: Invalid discount value"
        );
        _discount = discount_;
        emit DiscountUpdated(discount_);
    }

    /**
     * @notice Updates the fee configuration.
     * @param config The new fee configuration.
     */
    function _updateFeeConfiguration(FeeConfiguration memory config) private {
        require(config.feeRecipient != address(0), "CoreConfiguration: Recipient is zero address");
        require(config.protocolFee <= MAX_PROTOCOL_FEE, "CoreConfiguration: Protocol fee gt max");
        require(config.flashloanFee <= MAX_FLASHLOAN_FEE, "CoreConfiguration: Flashloan fee gt max");
        _feeConfiguration = config;
        emit FeeConfigurationUpdated(config);
    }

    /**
     * @notice Updates the limits configuration.
     * @param config The new limits configuration.
     */
    function _updateLimitsConfiguration(LimitsConfiguration memory config) private {
        require(config.minStableAmount > 0, "CoreConfiguration: Min stable is not positive");
        require(config.minOrderRate > 0, "CoreConfiguration: Min rate is not positive");
        require(config.maxOrderRate >= config.minOrderRate, "CoreConfiguration: Max order rate lt min");
        require(config.maxDuration >= config.minDuration, "CoreConfiguration: Max duration lt min");
        _limitsConfiguration = config;
        emit LimitsConfigurationUpdated(config);
    }

    /**
     * @notice Updates the swapper configuration.
     * @param swapper_ The new swapper configuration.
     */
    function _updateSwapper(Swapper memory swapper_) private {
        require(address(swapper_.swapperConnector) != address(0), "CoreConfiguration: Connector is zero address");
        require(swapper_.path.length > 0, "CoreConfiguration: Path is zero address");
        _swapper = swapper_;
        emit SwapperUpdated(swapper_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20Stable.sol";
import "./IPositionToken.sol";
import "./IFoxifyAffiliation.sol";
import "./IFoxifyBlacklist.sol";
import "./ISwapperConnector.sol";
import "./ICoreUtilities.sol";

interface ICoreConfiguration {
    struct FeeConfiguration {
        address feeRecipient;
        uint256 autoResolveFee;
        uint256 protocolFee;
        uint256 flashloanFee;
    }

    struct ImmutableConfiguration {
        IFoxifyBlacklist blacklist;
        IFoxifyAffiliation affiliation;
        IPositionToken positionTokenAccepter;
        IERC20Stable stable;
        ICoreUtilities utils;
    }

    struct LimitsConfiguration {
        uint256 minStableAmount;
        uint256 minOrderRate;
        uint256 maxOrderRate;
        uint256 minDuration;
        uint256 maxDuration;
    }

    struct NFTDiscountLevel {
        uint256 bronze;
        uint256 silver;
        uint256 gold;
    }

    struct Swapper {
        ISwapperConnector swapperConnector;
        bytes path;
    }

    function discount() external view returns (uint256 bronze, uint256 silver, uint256 gold);
    function feeConfiguration() external view returns (
        address feeRecipient,
        uint256 autoResolveFee,
        uint256 protocolFee,
        uint256 flashloanFee
    );
    function immutableConfiguration() external view returns (
        IFoxifyBlacklist blacklist,
        IFoxifyAffiliation affiliation,
        IPositionToken positionTokenAccepter,
        IERC20Stable stable,
        ICoreUtilities utils
    );
    function keepers(uint256 index) external view returns (address);
    function keepersCount() external view returns (uint256);
    function keepersContains(address keeper) external view returns (bool);
    function limitsConfiguration() external view returns (
        uint256 minStableAmount,
        uint256 minOrderRate,
        uint256 maxOrderRate,
        uint256 minDuration,
        uint256 maxDuration
    );
    function oracles(uint256 index) external view returns (address);
    function oraclesCount() external view returns (uint256);
    function oraclesContains(address oracle) external view returns (bool);
    function oraclesWhitelist(uint256 index) external view returns (address);
    function oraclesWhitelistCount() external view returns (uint256);
    function oraclesWhitelistContains(address oracle) external view returns (bool);
    function swapper() external view returns (ISwapperConnector swapperConnector, bytes memory path);

    event DiscountUpdated(NFTDiscountLevel discount_);
    event FeeConfigurationUpdated(FeeConfiguration config);
    event KeepersAdded(address[] keepers);
    event KeepersRemoved(address[] keepers);
    event LimitsConfigurationUpdated(LimitsConfiguration config);
    event OraclesAdded(address[] oracles);
    event OraclesRemoved(address[] oracles);
    event OraclesWhitelistRemoved(address[] oracles);
    event SwapperUpdated(Swapper swapper);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20Stable.sol";
import "./IOracleConnector.sol";
import "./IFoxifyAffiliation.sol";
import "./ICoreConfiguration.sol";
import "./ISwapperConnector.sol";

interface ICoreUtilities {
    struct AffiliationUserData {
        uint256 activeId;
        uint256 team;
        uint256 discount;
        IFoxifyAffiliation.NFTData nftData;
    }

    function calculateStableFee(
        address affiliationUser,
        uint256 amount,
        uint256 fee
    ) external view returns (AffiliationUserData memory affiliationUserData_, uint256 fee_);
    function configuration() external view returns (ICoreConfiguration);
    function getAndValidateRoundForAutoResolve(
        uint256 roundId,
        uint256 endTime,
        address oracle
    ) external view returns (bool invalidRound, uint256 price);
    function getAndValidateRoundForAccept(address oracle, uint256 endTime) external view returns (uint256 price);

    function initialize(address configuration_) external returns (bool);
    function swap(address recipient, uint256 winnerTotalAmount) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20Stable is IERC20, IERC20Permit {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFoxifyAffiliation {
    enum Level {
        UNKNOWN,
        BRONZE,
        SILVER,
        GOLD
    }

    struct NFTData {
        Level level;
        bytes32 randomValue;
        uint256 timestamp;
    }

    function data(uint256) external view returns (NFTData memory);
    function usersActiveID(address) external view returns (uint256);
    function usersTeam(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFoxifyBlacklist {
    function blacklist(uint256 index) external view returns (address);
    function blacklistCount() external view returns (uint256);
    function blacklistContains(address wallet) external view returns (bool);
    function blacklistList(uint256 offset, uint256 limit) external view returns (address[] memory output);

    event Blacklisted(address[] wallets);
    event Unblacklisted(address[] wallets);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOracleConnector {
    function name() external view returns (string memory);
    function decimals() external view returns (uint256);
    function paused() external view returns (bool);
    function validateTimestamp(uint256) external view returns (bool);
    function getRoundData(
        uint256 roundId_
    )
        external
        view
        returns (uint256 roundId, uint256 answer, uint256 startedAt, uint256 updatedAt, uint256 answeredInRound);
    function latestRound() external view returns (uint256);
    function latestRoundData()
        external
        view
        returns (uint256 roundId, uint256 answer, uint256 startedAt, uint256 updatedAt, uint256 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IPositionToken is IERC721Metadata {
    function burn(uint256 id) external returns (bool);
    function mint(address account, uint256 id) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISwapperConnector {
    function getAmountIn(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    event Swapped(address indexed recipient, address indexed tokenIn, uint256 amountIn, uint256 amountOut);

    function swap(
        bytes memory path,
        address tokenIn,
        uint256 amountIn,
        address recipient
    ) external returns (uint256 amountOut);
}