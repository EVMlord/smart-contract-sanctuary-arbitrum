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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

pragma solidity 0.8.11;

import '@openzeppelin/contracts/utils/Context.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "@openzeppelin/contracts/proxy/Clones.sol";

import {IPositionRouter} from "./interfaces/gmx/IPositionRouter.sol";
import {IVault} from "./interfaces/gmx/IVault.sol";
import {IRouter} from "./interfaces/gmx/IRouter.sol";
import {IGeniBot} from "./interfaces/IGeniBot.sol";
import {ILevelHelper} from "./interfaces/ILevelHelper.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract GeniVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct User {
        address account;
        uint256 balance;
        uint256 depositBalance;
    }

    bool public botStatus;
    bool public activeReferral;
    address public tokenPlay;
    address public positionRouter;
    address public vault;
    address public router;
    address public weth;

    uint256 public createBotFee = 10000000; // 100 USDC if > countBotRequireFee

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public botExecutionFee; // USDC

    uint256 public marginFeeBasisPoints = 10; // 0.1%
 
    bytes32 public referralCode; 
    ILevelHelper public levelHelper;

    mapping(uint256 => address) public implementations;
    mapping(address => EnumerableSet.AddressSet) private _userBots;

    mapping(address => bool) public isBotKeeper;
    mapping(address => User) public users;

    mapping(uint256 => uint256) public userLevelFee;
    mapping(uint256 => uint256) public traderLevelFee;
    mapping(uint256 => uint256) public refLevelFee;
    mapping(uint256 => uint256) public ref2LevelFee;

    mapping(uint256 => uint256) public maxBotPackagePerUsers;
    mapping(uint256 => uint256) public countBotPackageRequireFees;

    mapping(address => mapping(address => uint256)) public pendingRevenue;

    mapping(address => address) public refUsers;
    mapping(address => uint256) public refCount;

    // Recover NFT tokens sent by accident
    event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);

    // Recover ERC20 tokens sent by accident
    event TokenRecovery(address indexed token, uint256 amount);

    event SetBotStatus(bool status);
    event SetActiveReferral(bool status);
    event Deposit(address indexed account, address tokenAddress, uint256 amount);
    event Withdraw(address indexed account, uint256 amount); 
    event TransferBalance(address indexed account, uint256 amount); 
    event CreateNewBot(address indexed account, address bot, address refAddress, uint256 fixedMargin, uint256 positionLimit, uint256 takeProfit, uint256 stopLoss);
    event BotRequestToken(address indexed account, uint256 amount, address botAddress, uint256 botExecutionFee);
    event CollectToken(address indexed user, address bot, uint256 amount);
    event SetBotExecutionFee(uint256 botExecutionFee);

    event BotRequestUpdateBalanceAndFees(
        address indexed account, 
        address trader, 
        uint256 amount, 
        uint256 realisedPnl, 
        bool isRealisedPnl, 
        address botAddress,
        uint256 geniFees,
        uint256 botExecutionFee
    );

    event BotRequestUpdateFees(
        address indexed account, 
        address trader,
        uint256 realisedPnl, 
        bool isRealisedPnl, 
        address botAddress,
        uint256 geniFees,
        uint256 botExecutionFee
    );

    event BotRequestUpdateBalance(
        address indexed account, 
        uint256 amount,
        address botAddress
    );

    event HandleRefAndSystemFees(
        address indexed bot,
        uint256 systemFeeAmount, 
        address referrerLv1,
        uint256 referralFeeAmount,
        address referrerLv2,
        uint256 referral2FeeAmount
    );

    event HandleTraderFees(
        address indexed bot,
        address trader, 
        uint256 traderFeeAmount
    );

    // Pending revenue is claimed
    event RevenueClaim(address indexed claimer, uint256 amount);

    event TakeFee(address indexed owner, uint256 amount);

    constructor(
        address _positionRouter,
        address _vault,
        address _router,
        address _implementation,
        address _levelHelper
    ) {
        tokenPlay = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; // USDC, decimals 6
        weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

        positionRouter = _positionRouter;
        vault = _vault;
        router = _router;

        botExecutionFee = 50000; // 0.5 USDC
        isBotKeeper[msg.sender] = true;
        botStatus = true;
        activeReferral = true;

        implementations[0] = _implementation;
        levelHelper = ILevelHelper(_levelHelper);

        // set level fees init for system fee per trade win
        userLevelFee[0] = 500; // 5%
        userLevelFee[1] = 400; // 4%
        userLevelFee[2] = 300;
        userLevelFee[3] = 200;
        userLevelFee[4] = 100;
        userLevelFee[5] = 0;

        traderLevelFee[0] = 300;  // 3%
        traderLevelFee[1] = 400;
        traderLevelFee[2] = 500;
        traderLevelFee[3] = 600;

        refLevelFee[0] = 3000; // 30% of 5% in system fee
        refLevelFee[1] = 4000; // 40% of 5% in system fee
        refLevelFee[2] = 5000; // 50% of 5% in system fee

        ref2LevelFee[0] = 500; // 5% of 5% in system fee
        ref2LevelFee[1] = 800; // 8% of 5% in system fee
        ref2LevelFee[2] = 1000; // 10% of 5% in system fee

        // max bot
        maxBotPackagePerUsers[0] = 5;
        maxBotPackagePerUsers[1] = 100;
        maxBotPackagePerUsers[2] = 100;
        maxBotPackagePerUsers[3] = 100;
        maxBotPackagePerUsers[4] = 100;
        maxBotPackagePerUsers[5] = 100;

        // set max bot require fees
        countBotPackageRequireFees[0] = 3;
        countBotPackageRequireFees[1] = 5;
        countBotPackageRequireFees[2] = 7;
        countBotPackageRequireFees[3] = 9;
        countBotPackageRequireFees[4] = 15;
        countBotPackageRequireFees[5] = 30;
    }

    modifier onlyBotContract(address _account) {
        require(_userBots[_account].contains(msg.sender), "onlyBotContract: Is not bot contract");
        _;
    }

    modifier onlyBotKeeper() {
        require(isBotKeeper[msg.sender], "onlyBotKeeper: Is not keeper");
        _;
    }

    function createNewBot(
        uint256 _implementationNo,
        address _refAddress,
        uint256 _fixedMargin,
        uint256 _positionLimit,
        uint256 _takeProfit,
        uint256 _stopLoss
    ) external nonReentrant returns (address bot) {
        uint256 count = _userBots[msg.sender].length();
        require(implementations[_implementationNo] != address(0), "createNewBot: require implementation");

        uint256 maxBotPerUser = maxBotPackagePerUsers[levelHelper.getUserPackageId(msg.sender)];
        uint256 countBotRequireFee = countBotPackageRequireFees[levelHelper.getUserPackageId(msg.sender)];
        require(count < maxBotPerUser, "createNewBot: need less than max bot user");

        if (count >= countBotRequireFee) {
            User memory user = users[msg.sender];
            require(user.balance >= createBotFee, "createNewBot: not enough fee");
            _takeFee(msg.sender, createBotFee);
        }

        bot = Clones.clone(implementations[_implementationNo]);
        IGeniBot(bot).initialize(
            tokenPlay, 
            positionRouter, 
            vault, 
            router, 
            address(this), 
            msg.sender, 
            _fixedMargin, 
            _positionLimit, 
            _takeProfit, 
            _stopLoss
        );
        
        _userBots[msg.sender].add(address(bot));

        if (refUsers[msg.sender] == address(0) && _refAddress != address(msg.sender) && _refAddress != address(0)) {
            refUsers[msg.sender] = _refAddress;
            refCount[_refAddress] += 1;
        }

        emit CreateNewBot(msg.sender, address(bot), _refAddress, _fixedMargin, _positionLimit, _takeProfit, _stopLoss);
    }

    function _takeFee(address _account, uint256 _fee) internal {
        User storage user = users[_account];
        require(user.balance >= _fee, "Take fee: not enough balance");

        user.balance -= _fee;
        pendingRevenue[owner()][tokenPlay] += _fee;
        emit TakeFee(owner(), _fee);
    }

    function setBotKeeper(address _account, bool _status) external onlyOwner {
        isBotKeeper[_account] = _status;
    }

    function setGmxAddress(address _positionRouter, address _vault, address _router) external onlyOwner {
        positionRouter = _positionRouter;
        vault = _vault;
        router = _router;
    }

    function setMaxBotPerUser(uint256 _packageId, uint256 _maxBot) external onlyOwner {
        maxBotPackagePerUsers[_packageId] = _maxBot;
    }

    function setMarginFeeBasisPoints(uint256 _number) external onlyOwner {
        marginFeeBasisPoints = _number;
    }

    function getMarginFeeBasisPoints() view external returns (uint256) {
        return marginFeeBasisPoints;
    }

    function setCountBotRequireFee(uint256 _packageId, uint256 _count) external onlyOwner {
        countBotPackageRequireFees[_packageId] = _count;
    }

    function setCreateBotFee(uint256 _fee) external onlyOwner {
        createBotFee = _fee;
    }

    function setEmplementations(uint256 _implementationNo, address _implementation) external onlyOwner {
        implementations[_implementationNo] = _implementation;
    }

    function setLevelHelper(address _levelHelper) external onlyOwner {
        levelHelper = ILevelHelper(_levelHelper);
    }

    function getBotKeeper(address _account) external view returns (bool) {
        return isBotKeeper[_account];
    }
    
    // USDC fee
    function setBotExecutionFee(uint256 _botExecutionFee) external onlyOwner {
        botExecutionFee = _botExecutionFee;
        emit SetBotExecutionFee(_botExecutionFee);
    }

    function setUserLevelFee(uint256 _level, uint256 _fee) external onlyOwner {
        userLevelFee[_level] = _fee;
    }

    function setTraderLevelFee(uint256 _level, uint256 _fee) external onlyOwner {
        traderLevelFee[_level] = _fee;
    }

    function setRefLevelFee(uint256 _level, uint256 _fee) external onlyOwner {
        refLevelFee[_level] = _fee;
    }

    function setRef2LevelFee(uint256 _level, uint256 _fee) external onlyOwner {
        ref2LevelFee[_level] = _fee;
    }

    function setReferralCode(bytes32 _referralCode) external onlyOwner {
        referralCode = _referralCode;
    }

    function getReferralCode() external view returns (bytes32) {
        return referralCode;
    }

    function getReferrer(address _user) external view returns (address) {
        return refUsers[_user];
    }

    function getRefLevelFee(address _referrer) external returns (uint256) {
        return refLevelFee[levelHelper.getRefLevel(_referrer)];
    }

    function getRef2LevelFee(address _referrer) external returns (uint256) {
        return ref2LevelFee[levelHelper.getRefLevel(_referrer)];
    }

    function setBotStatus(bool _status) external onlyOwner {
        botStatus = _status;
        emit SetBotStatus(_status);
    }

    function setActiveReferral(bool _status) external onlyOwner {
        activeReferral = _status;
        emit SetActiveReferral(_status);
    }

    function deposit(address _tokenAddress, uint256 _amount) external nonReentrant {
        require(botStatus, "Bot: bot off");
        require(_amount > 0, "BotFactory: Deposit requie amount > 0");

        IERC20(_tokenAddress).safeTransferFrom(address(msg.sender), address(this), _amount);

        uint256 amount;
        if (_tokenAddress == tokenPlay) {
            amount = _amount;
        } else {
            IERC20(_tokenAddress).safeTransfer(vault, _amount);
            amount = IVault(vault).swap(_tokenAddress, tokenPlay, address(this));
        }

        User storage user = users[msg.sender];

        user.account = msg.sender;
        user.balance += amount;
        user.depositBalance += amount;

        emit Deposit(msg.sender, _tokenAddress, amount);
    }

    function depositETH() payable external nonReentrant {
        require(botStatus, "Bot: bot off");
        require(msg.value > 0, "BotFactory: Deposit requie amount > 0");

        _transferETHToVault();
        uint256 usdcAmount = IVault(vault).swap(weth, tokenPlay, address(this));

        User storage user = users[msg.sender];

        user.account = msg.sender;
        user.balance += usdcAmount;
        user.depositBalance += usdcAmount;

        emit Deposit(msg.sender, weth, usdcAmount);
    }

    function _transferETHToVault() private {
        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).safeTransfer(vault, msg.value);
    }

    // revert trade if GMX cancel increase position
    function collectToken(address _user, address _bot) external nonReentrant onlyBotKeeper {
        require(_userBots[_user].contains(_bot), "collectToken: invalid user or bot");
        uint256 amount = IGeniBot(_bot).botFactoryCollectToken();
        
        User storage user = users[_user];
        user.balance += amount;

        emit CollectToken(_user, _bot, amount);
    }

    function botRequestToken(address _account, uint256 _amount) external nonReentrant onlyBotContract(_account) returns(uint256) {
        require(botStatus, "Bot: bot off");
        User storage user = users[_account]; 
        require((_amount + botExecutionFee) <= user.balance, "CreateIncreasePosition: require _amountIn < user.balance");
        
        if (_amount > 0) {
            user.balance -= _amount;
            user.balance -= botExecutionFee;
            pendingRevenue[owner()][tokenPlay] += botExecutionFee;

            IERC20(tokenPlay).safeTransfer(address(msg.sender), _amount);
        }
        emit BotRequestToken(_account, _amount, msg.sender, botExecutionFee);
        return _amount;
    }

    function botRequestUpdateBalanceAndFees(
        address _account, 
        address _trader, 
        uint256 _amount, 
        uint256 _realisedPnl, 
        bool _isRealisedPnl
    ) external nonReentrant onlyBotContract(_account) returns(uint256 geniFees) {
        User storage user = users[_account];
        
        if (_amount > 0) {
            user.balance -= botExecutionFee;
            pendingRevenue[owner()][tokenPlay] += botExecutionFee;

            if (_isRealisedPnl) {
                (uint256 referralFeeAmount, uint256 systemFeeAmount) = _handleRefAndSystemFees(_account, _realisedPnl, msg.sender);
                uint256 traderFeeAmount = _handleTraderFees(_trader, _realisedPnl, msg.sender);
                geniFees = referralFeeAmount + systemFeeAmount + traderFeeAmount;
                
                user.balance += _amount - geniFees;
            } else {
                user.balance += _amount;
            }
        }
        emit BotRequestUpdateBalanceAndFees(_account, _trader, _amount, _realisedPnl, _isRealisedPnl, msg.sender, geniFees, botExecutionFee);
    }

    function botRequestUpdateBalance(
        address _account, 
        uint256 _amount
    ) external nonReentrant onlyBotContract(_account) {
        User storage user = users[_account];

        if (_amount > 0) {
            user.balance += _amount;
            emit BotRequestUpdateBalance(_account, _amount, msg.sender);
        }
    }

    function botRequestUpdateFees(
        address _account, 
        address _trader,
        uint256 _realisedPnl,  // amount USDC
        bool _isRealisedPnl
    ) external nonReentrant onlyBotContract(_account) returns(uint256 geniFees) {
        User storage user = users[_account];
        
        user.balance -= botExecutionFee;
        pendingRevenue[owner()][tokenPlay] += botExecutionFee;

        if (_isRealisedPnl) {
            (uint256 referralFeeAmount, uint256 systemFeeAmount) = _handleRefAndSystemFees(_account, _realisedPnl, msg.sender);
            uint256 traderFeeAmount = _handleTraderFees(_trader, _realisedPnl, msg.sender);
            geniFees = referralFeeAmount + systemFeeAmount + traderFeeAmount;
        
            user.balance -= geniFees;
        }

        emit BotRequestUpdateFees(_account, _trader, _realisedPnl, _isRealisedPnl, msg.sender, geniFees, botExecutionFee);
    }

    function _handleRefAndSystemFees(address _account, uint256 _realisedPnl, address _botAddress) internal returns (uint256 referralFeeAmount, uint256 systemFeeAmount) {
        address refAddress = refUsers[_account]; // ref level 1
        address ref2Address = refUsers[refAddress]; // ref level 2
        bool hasRefAccount = refAddress != address(0) && activeReferral;
        bool hasRef2Account = ref2Address != address(0) && activeReferral;

        uint256 systemFee = userLevelFee[levelHelper.getUserLevel(_account)];
        uint256 referralFee = 0;
        uint256 referral2Fee = 0;
        if (hasRefAccount) {
            referralFee = refLevelFee[levelHelper.getRefLevel(refAddress)];
            if (hasRef2Account) {
                referral2Fee = ref2LevelFee[levelHelper.getRefLevel(ref2Address)];
            }
        }

        systemFeeAmount = systemFee * _realisedPnl / BASIS_POINTS_DIVISOR;
        uint256 referral1FeeAmount = referralFee * systemFeeAmount / BASIS_POINTS_DIVISOR;
        uint256 referral2FeeAmount = referral2Fee * systemFeeAmount / BASIS_POINTS_DIVISOR;

        referral1FeeAmount = hasRefAccount ? referral1FeeAmount : 0;
        referral2FeeAmount = hasRef2Account ? referral2FeeAmount : 0;
        
        referralFeeAmount = referral1FeeAmount + referral2FeeAmount;
        systemFeeAmount = systemFeeAmount - referralFeeAmount;

        pendingRevenue[owner()][tokenPlay] += systemFeeAmount;

        if (hasRefAccount) {
            pendingRevenue[refAddress][tokenPlay] += referral1FeeAmount;
        }
        if (hasRef2Account) {
            pendingRevenue[ref2Address][tokenPlay] += referral2FeeAmount;
        }

        emit HandleRefAndSystemFees(
            _botAddress,
            systemFeeAmount, 
            refAddress,
            referralFeeAmount,
            ref2Address,
            referral2FeeAmount
        );
    }

    function _handleTraderFees(address _trader, uint256 _realisedPnl, address _botAddress) internal returns (uint256 traderFeeAmount) {
        uint256 traderFee = traderLevelFee[levelHelper.getTraderLevel(_trader)];
        traderFeeAmount = traderFee * _realisedPnl / BASIS_POINTS_DIVISOR;
        pendingRevenue[_trader][tokenPlay] += traderFeeAmount;

        emit HandleTraderFees(
            _botAddress,
            _trader, 
            traderFeeAmount
        );
    }

    function withdrawBalance(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Withdraw: requie amount > 0");
        User storage user = users[msg.sender];
        require(_amount <= user.balance, "Withdraw: insufficient balance");

        user.balance -= _amount;
        IERC20(tokenPlay).safeTransfer(address(msg.sender), _amount);

        emit Withdraw(msg.sender, _amount);
    }

    function transferBalance(uint256 _amount, address _to) external nonReentrant {
        require(botStatus, "Bot: bot off");
        require(_amount > 0, "Withdraw: requie amount > 0");
        User storage user = users[msg.sender];
        require(_amount <= user.balance, "Withdraw: insufficient balance");

        user.balance -= _amount;
        IERC20(tokenPlay).safeTransfer(_to, _amount);

        emit TransferBalance(_to, _amount);
    }

    /**
     * @notice Claim pending revenue
     */
    function claimPendingRevenue(address _token) external nonReentrant {
        require(botStatus, "Bot: bot off");
        uint256 revenueToClaim = pendingRevenue[msg.sender][_token];
        require(revenueToClaim != 0, "Claim: Nothing to claim");
        pendingRevenue[msg.sender][_token] = 0;

        IERC20(_token).safeTransfer(address(msg.sender), revenueToClaim);

        emit RevenueClaim(msg.sender, revenueToClaim);
    }

    function getBots(address[] memory bots, address[] memory _users) public view returns (uint256[] memory) {
        uint256 propsLength = 10;

        uint256[] memory rets = new uint256[](bots.length * propsLength);

        for (uint256 i = 0; i < bots.length; i++) {
         (,uint256 fixedMargin,uint256 positionLimit, uint256 takeProfit , uint256 stopLoss, uint256 level)  = IGeniBot(bots[i]).getUser();

            User memory u = users[address(_users[i])];

            rets[i * propsLength + 0] = fixedMargin;
            rets[i * propsLength + 1] = positionLimit;
            rets[i * propsLength + 2] = takeProfit;
            rets[i * propsLength + 3] = stopLoss;
            rets[i * propsLength + 4] = level;
            rets[i * propsLength + 5] = u.balance;
            rets[i * propsLength + 6] = u.depositBalance;
        }
        return rets;
    }

    function viewUserBots(
        address user,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            address[] memory bots
        )
    {
        uint256 length = size;

        if (length > _userBots[user].length() - cursor) {
            length = _userBots[user].length() - cursor;
        }

        bots = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            bots[i] = _userBots[user].at(cursor + i);
        }

        return bots;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IPositionRouter {
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable;

    function increasePositionRequestKeysStart() external view returns (uint256);
    function decreasePositionRequestKeysStart() external view returns (uint256);
    function maxGlobalShortSizes(address _indexToken) external view returns (uint256);
    function minExecutionFee() external view returns (uint256);
    function setPositionKeeper(address keeper, bool isActive) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IRouter {
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function approvePlugin(address _plugin) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IVault {
    function taxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function whitelistedTokens(address) external view returns (bool);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function stableTokens(address) external view returns (bool);

    function poolAmounts(address) external view returns (uint256);

    function globalShortSizes(address) external view returns (uint256);

    function globalShortAveragePrices(address) external view returns (uint256);

    function guaranteedUsd(address) external view returns (uint256);

    function reservedAmounts(address) external view returns (uint256);

    function cumulativeFundingRates(address) external view returns (uint256);

    function getFundingFee(address _token, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function lastFundingTimes(address) external view returns (uint256);

    function updateCumulativeFundingRate(address _token) external;

    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);

    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);

    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;

    function getPositionDelta(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (bool, uint256);

    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IGeniBot {
    function initialize(
        address _tokenPlay,
        address _positionRouter,
        address _vault,
        address _router,
        address _botFactory,
        address _userAddress,
        uint256 _fixedMargin,
        uint256 _positionLimit,
        uint256 _takeProfit,
        uint256 _stopLoss
    ) external;

    function botFactoryCollectToken() external returns (uint256);

    function getIncreasePositionRequests(uint256 _count) external returns (
        address,
        address,
        bytes32,
        address,
        uint256,
        uint256,
        bool,
        bool
    );

    function getUser() external view returns (
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    function getTokenPlay() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface ILevelHelper {
    function getUserLevel(address _account) external returns (uint256);

    function getTraderLevel(address _account) external returns (uint256);

    function getRefLevel(address _account) external returns (uint256);

    function getUserPackageId(address _account) external returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}