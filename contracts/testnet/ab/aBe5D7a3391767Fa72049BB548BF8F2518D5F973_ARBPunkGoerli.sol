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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Author: Jason Hoi https://github.com/jasonhoi
 *
 */
pragma solidity ^0.8.7;

/**
 * @dev Contract module which provides basic multi-admin access control mechanism,
 * admins are granted exclusive access to specific functions with the provided 
 * modifier.
 *
 * By default, the contract owner is the first admin.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict access.
 * 
 */
contract Adminable {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);

    // mapping for admin address
    mapping(address => uint256) _admins;

    // add the first admin with contract creator
    constructor() {
        _admins[_msgSenderAdminable()] = 1;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSenderAdminable()), "Adminable: caller is not admin");
        _;
    }

    function isAdmin(address addr) public view virtual returns (bool) {
        return _admins[addr] == 1;
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        require(to != address(0), "Adminable: cannot set admin for the zero address");

        if (approved) {
            require(!isAdmin(to), "Adminable: add existing admin");
            _admins[to] = 1;
            emit AdminCreated(to);
        } else {
            require(isAdmin(to), "Adminable: remove non-existent admin");
            delete _admins[to];
            emit AdminRemoved(to);
        }
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderAdminable() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * ARBPunk NFT (ERC721 with random token)
 *******************************************************************************
 * Creator: ARBPunk
 * Author: Jason Hoi https://github.com/jasonhoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRandomizer.sol";
import "./EIP712WhitelistTyped.sol";
import "./ERC721Extended.sol";
import "./MintSetupTest.sol";

contract ARBPunkGoerli is EIP712WhitelistTyped, ERC721Extended, MintSetupTest {
    IRandomizer public randomizer;
    uint256 private vrfRequestId;

    uint256 randomSeed;
    string public PROVENANCE;
    // @@@@@@@@@@TESTONLY
    uint256 public constant MAX_SUPPLY = 40;
    string public baseTokenURI;
    string public unrevealURI;
    uint256 public totalBurned;
    uint256 public totalMinted;

    // random temporary token ids
    mapping(uint256 => uint256) private _reservedTokens;

    constructor() 
        ERC721Extended("ARBPunk", "PUNK")
        EIP712WhitelistTyped() 
        MintSetupTest() 
    {
        // @@@@@@@@@@TESTONLY
        // VRF provider - Randomizer.ai (Arbitrum Goerli)
        randomizer = IRandomizer(0x923096Da90a3b60eb7E12723fA2E1547BA9236Bc);
        // VRF provider - Randomizer.ai (Arbitrum One)
        // randomizer = IRandomizer(0x5b8bB80f2d72D0C85caB8fB169e8170A05C94bAF);
    }

    // @@@@@@@@@@TESTONLY MUST remove on final deployment
    function setRandomSeed(uint256 _seed) external onlyAdmin {
        require(randomSeed == 0, "Random seed already created");
        randomSeed = _seed;
    }

    // Set provenance hash
    function setProvenance(string memory _hash) external onlyAdmin {
        PROVENANCE = _hash;
    }

    function isRandomSeedReady() external view returns (bool) {
        return randomSeed != 0;
    }

    // Set Randomizer VRF provider
    function setRandomizer(address addr) external onlyAdmin {
        randomizer = IRandomizer(addr);
    }

    // Request random seed
    function requestRandomSeed() external onlyAdmin {
        // Random seed can only be setup once
        require(randomSeed == 0, "Random seed already created");
			  // Request a random number from the randomizer contract (50k callback limit, 20 confirmations)
			  vrfRequestId = randomizer.request(50000, 20);
    }

    // Callback function called by the randomizer contract when the random value is generated
		function randomizerCallback(uint256 _reqId, bytes32 _value) external {
        // Callback can only be called by randomizer
        require(msg.sender == address(randomizer), "Invalid randomizer caller");
        require(_reqId == vrfRequestId && vrfRequestId != 0, "Invalid VRF request id");
        require(randomSeed == 0, "Random seed already created");

        randomSeed = uint256(_value);
		}
    
    // Allows the owner to withdraw their deposited randomizer funds
		function randomizerWithdraw(address _to, uint256 amount) external onlyAdmin {
			  randomizer.clientWithdrawTo(_to, amount);
		}

    // do not allow contract to call
    modifier callerIsWallet() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function getMintSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    modifier checkMintQuantity(uint256 _qty) {
        require(totalMinted + _qty <= MAX_SUPPLY, "Reached max supply of the collection");
        _;
    }

    function numberMinted(address _owner) external view returns (uint256) {
        return _numberMinted(_owner);
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted - totalBurned;
    }

    // ======== Minting methods ========
    function ownerMint(address _to, uint256 _qty) 
        external 
        onlyAdmin 
        checkMintQuantity(_qty)
    {
        _randomMint(_to, _qty);
    }
    
    function freeMint(uint256 _qty, bytes calldata _signature) 
        external 
        payable 
        callerIsWallet 
        checkMintQuantity(_qty) 
        isFreeMintActive
        checkWhitelist(_signature,"freemint")
    {
        require(_numberFreeMinted(msg.sender) + _qty <= mintConfig.freeMintPerWallet, "Reached minting limit per wallet");
        _increaseFreeMinted(_qty);
        _randomMint(msg.sender, _qty);
    }
    
    function freeMintGroupA(uint256 _qty) 
        external 
        payable 
        callerIsWallet 
        checkMintQuantity(_qty) 
        isFreeMintActive
    {
        require(checkGroupAOwner(msg.sender), "You are not eligible for free in this group");
        require(_numberFreeMintedGroupA(msg.sender) + _qty <= freeMintConfig.freeMintGroupAPerWallet, "Reached minting limit per wallet");
        require(freeMintConfig.freeMintGroupAMinted + _qty <= freeMintConfig.freeMintGroupATotal, "Reached minting limit for the group");
        freeMintConfig.freeMintGroupAMinted += uint16(_qty);
        _increaseFreeMintedGroupA(_qty);
        _randomMint(msg.sender, _qty);
    }

    function freeMintGroupB(uint256 _qty) 
        external 
        payable 
        callerIsWallet 
        checkMintQuantity(_qty) 
        isFreeMintActive
    {
        require(checkGroupBOwner(msg.sender), "You are not eligible for free in this group");
        require(_numberFreeMintedGroupB(msg.sender) + _qty <= freeMintConfig.freeMintGroupBPerWallet, "Reached minting limit per wallet");
        require(freeMintConfig.freeMintGroupBMinted + _qty <= freeMintConfig.freeMintGroupBTotal, "Reached minting limit for the group");
        freeMintConfig.freeMintGroupBMinted += uint16(_qty);
        _increaseFreeMintedGroupB(_qty);
        _randomMint(msg.sender, _qty);
    }

    function freeMintGroupC(uint256 _qty) 
        external 
        payable 
        callerIsWallet 
        checkMintQuantity(_qty) 
        isFreeMintActive
    {
        require(checkGroupCOwner(msg.sender), "You are not eligible for free in this group");
        require(_numberFreeMintedGroupC(msg.sender) + _qty <= freeMintConfig.freeMintGroupCPerWallet, "Reached minting limit per wallet");
        require(freeMintConfig.freeMintGroupCMinted + _qty <= freeMintConfig.freeMintGroupCTotal, "Reached minting limit for the group");
        freeMintConfig.freeMintGroupCMinted += uint16(_qty);
        _increaseFreeMintedGroupC(_qty);
        _randomMint(msg.sender, _qty);
    }

    function publicMint(uint256 _qty) 
        external 
        payable 
        callerIsWallet 
        isPublicMintActive
        checkMintQuantity(_qty) 
        checkPublicMintValue(_qty)
    {
        require(_numberPublicMinted(msg.sender) + _qty <= mintConfig.publicMintPerWallet, "Reached minting limit per wallet");
        _increasePublicMinted(_qty);
        _randomMint(msg.sender, _qty);
    }

    function publicMintTokenAllowance(address _wallet) external view returns (uint256) {
        return IERC20(mintConfig.token).allowance(_wallet, address(this));
    }

    // before calling this function, user need to first approve ERC20 token to be spendable by this contract
    function publicMintByToken(uint256 _qty) 
        external 
        callerIsWallet 
        isPublicMintActive
        checkMintQuantity(_qty)
        checkPublicMintTokenValue(_qty)
    {
        uint256 amount = _qty * mintConfig.tokenMintPrice;
        // transfer user ERC20 token to our contract
        IERC20(mintConfig.token).transferFrom(msg.sender, address(this), amount);
        require(_numberPublicMinted(msg.sender) + _qty <= mintConfig.publicMintPerWallet, "Reached minting limit per wallet");
        _increasePublicMinted(_qty);
        _randomMint(msg.sender, _qty);
    }

    // Token ID start from #1 - #MAX_SUPPLY
    function _randomMint(address _to, uint256 _qty) private {
        uint256 seed = randomSeed;
        uint256 max = MAX_SUPPLY;
        
        require(_qty > 0, "No mint quantity");
        require(seed != 0, "Random seed is missing");
        require(totalMinted + _qty <= max, "Max supply reached");
        
        for (uint256 i = 0; i < _qty; i++) {
            uint256 tokenId = _getRandomToken(seed, totalMinted, max);
            totalMinted++;

            _safeMint(_to, tokenId);
        }
    }

    // Token ID start from #1 - #MAX_SUPPLY
    function _getRandomToken(uint256 _randomSeed, uint256 _totalMinted, uint256 _maxSupply) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(_randomSeed, _totalMinted)));
        uint256 remaining = _maxSupply - _totalMinted;

        // value of (1 ~ remaining)
        // start from token #1 to MAX_SUPPLY
        uint256 randomIndex = 1 + (random % remaining);

        // use the previously reserved token id instead of randomIndex value
        uint256 tokenId = _reservedTokens[randomIndex];
        if (tokenId == 0) {
            // random id is safe to use
            tokenId = randomIndex;
        }
        
        // no need to store any value if randomIndex is at max token id slot
        if (randomIndex != remaining) {
            uint256 lastToken = _reservedTokens[remaining];

            if (lastToken == 0) {
                // replace current token slot with current max token id
                _reservedTokens[randomIndex] = remaining;
            } else {
                // replace current token slot with last token slot value (previously saved)
                _reservedTokens[randomIndex] = lastToken;
                delete _reservedTokens[remaining];
            }
        }

        return tokenId;
    }

    function burn(uint256 _tokenId) public virtual override {
        super.burn(_tokenId);
        totalBurned++;
    }

    // ======== Unreveal/Reveal token URI functions =========
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string calldata _uri) external onlyAdmin {
        baseTokenURI = _uri;
    }
    
    function setUnrevealURI(string calldata _uri) external onlyAdmin {
        unrevealURI = _uri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token URI for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? 
            string(abi.encodePacked(baseURI, _toString(_tokenId))) : 
            string(abi.encodePacked(unrevealURI, _toString(_tokenId)));
    }
    
    // ======== Extra functions =========
    // Token ownership data {address addr, uint64 startTimestamp}
    function ownershipOf(uint256 _tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(_tokenId);
    }

    // Address data for owner
    function addressDataOf(address _owner) external view returns (AddressData memory) {
        return _addressDataOf(_owner);
    }

    // ======== Withdraw =========
    function withdraw(address payable _to) public onlyAdmin {
        // Call returns a boolean value indicating success or failure.
        uint256 balance = address(this).balance;
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Withdraw failed");
    }

    // withdraw stored ERC20 token from contract
    function withdrawToken(address _token, uint256 _amount, address _to) external onlyAdmin {
        IERC20(_token).transfer(_to, _amount);
    }

    // token balance of received minting token
    function tokenBalance() external view returns (uint256) {
        return IERC20(mintConfig.token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

/**                                                                 
 *******************************************************************************
 * EIP 712 whitelist
 *******************************************************************************
 * Author: Jason Hoi https://github.com/jasonhoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Adminable.sol";

contract EIP712WhitelistTyped is Adminable, Context {
    event SetSigner(address indexed sender, address indexed signer);
    
    using ECDSA for bytes32;

    // Verify signature with this signer address
    address public eip712Signer;

    // Domain separator is EIP-712 defined struct to make sure 
    // signature is coming from the this contract in same ETH newtork.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    // @MATCHING cliend-side code
    bytes32 public DOMAIN_SEPARATOR;

    // HASH_STRUCT should not contain unnecessary whitespace between each parameters
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-encodetype
    // @MATCHING cliend-side code
    bytes32 public constant HASH_STRUCT = keccak256("Minter(address wallet,bytes32 type)");

    constructor() {
        // @MATCHING cliend-side code
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // @MATCHING cliend-side code
                keccak256(bytes("WhitelistToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        // initial signer is contract creator
        setSigner(_msgSender());
    }

    function setSigner(address _addr) public onlyAdmin {
        eip712Signer = _addr;

        emit SetSigner(_msgSender(), _addr);
    }

    modifier checkWhitelist(bytes calldata _signature, string memory _type) {
        require(eip712Signer == _recoverSigner(_signature, _type), "EIP712: Invalid Signature");
        _;
    }

    function verifySignature(bytes calldata _signature, string memory _type) public view returns (bool) {
        return eip712Signer == _recoverSigner(_signature, _type);
    }

    // Recover the signer address
    function _recoverSigner(bytes calldata _signature, string memory _type) internal view returns (address) {
        require(eip712Signer != address(0), "EIP712: Whitelist not enabled");

        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(HASH_STRUCT, _msgSender(), bytes32(bytes(_type))))
            )
        );
        return digest.recover(_signature);
    }
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * NFT ERC721 base contract
 *******************************************************************************
 * Author: Jason Hoi https://github.com/jasonhoi
 *
 * Based on OpenZeppelin v4.5.0 (token/ERC721/ERC721.sol)
 * OpenZeppelin ERC721 extended version:
 * - changing _balances to _addressData, to include address minting stats
 * - adding _isExternalTokenOwner() helper function
 * - implement IERC4907 NFT renting
 *
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./interfaces/IERC4907.sol";

interface IBalanceOf {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract ERC721Extended is Context, IERC721, IERC721Metadata, IERC4907 {
    using Address for address;

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // 2**64-1 is more than enough
        // Keep track of final token balance
        uint64 balance;
        // Keep track of minted amount
        uint64 numberMinted;
        // Keeps track of burn count
        uint64 numberBurned;
        // Mint quota
        uint16 numberPublicMinted;
        // Mint quota
        uint8 numberFreeMinted;
        // Mint quota
        uint8 numberFreeMintedGroupA;
        // Mint quota
        uint8 numberFreeMintedGroupB;
        // Mint quota
        uint8 numberFreeMintedGroupC;
    }

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Keeps track of transfer counter
        uint32 transferCount;
    }

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership data
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to token count
    mapping(address => AddressData) internal _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Struct for ERC4907 user info
    struct UserInfo {
        address user; // address of user role
        uint64 expires; // unix timestamp, user expires
    }

    // ERC4907 user info for each `tokenId`
    mapping (uint256 => UserInfo) internal _users;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // See: https://eips.ethereum.org/EIPS/eip-165
        // return true to show proof of supporting following interface, we use bytes4 
        // interface id to avoid importing the whole interface codes.
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == 0xad092b5c;   // ERC165 interface ID for ERC4907
    }

    /**
     * @dev Set the user and expires of `tokenId`. See {IERC4907-setUser}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function setUser(uint256 tokenId, address user, uint64 expires) external virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC4907: caller is not owner nor approved");

        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;

        emit UpdateUser(tokenId, user, expires);
    }

    /**
     * @dev Returns the user address for `tokenId`.
     * The zero address indicates that there is no user or if the user is expired.
     */
    function userOf(uint256 tokenId) external view virtual override returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp){
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    /**
     * @dev Returns the user's expires timestamp of `tokenId`. 
     * The zero value indicates that there is no user.
     */
    function userExpires(uint256 tokenId) external view virtual override returns (uint256) {
        return _users[tokenId].expires;
    }

    /**
     * Returns the (after minting) transfer counter for a token.
     */
    function transferCount(uint256 tokenId) public view virtual returns (uint256) {
        return _ownershipOf(tokenId).transferCount;
    }

    /**
     * Returns ownership data for a token
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _ownerships[tokenId];
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `addr`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens public minted by `addr`.
     */
    function _numberPublicMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberPublicMinted);
    }

    /**
     * Returns the number of tokens free minted by `addr`.
     */
    function _numberFreeMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberFreeMinted);
    }

    /**
     * Returns the number of tokens free minted by `addr`.
     */
    function _numberFreeMintedGroupA(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberFreeMintedGroupA);
    }

    /**
     * Returns the number of tokens free minted by `addr`.
     */
    function _numberFreeMintedGroupB(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberFreeMintedGroupB);
    }

    /**
     * Returns the number of tokens free minted by `addr`.
     */
    function _numberFreeMintedGroupC(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberFreeMintedGroupC);
    }

    /**
     * Increase the public mint counter for msg sender
     */
    function _increasePublicMinted(uint256 qty) internal {
        _addressData[msg.sender].numberPublicMinted += uint16(qty);
    }

    /**
     * Increase the free mint counter for msg sender
     */
    function _increaseFreeMinted(uint256 qty) internal {
        _addressData[msg.sender].numberFreeMinted += uint8(qty);
    }

    /**
     * Increase the free mint counter for msg sender
     */
    function _increaseFreeMintedGroupA(uint256 qty) internal {
        _addressData[msg.sender].numberFreeMintedGroupA += uint8(qty);
    }

    /**
     * Increase the free mint counter for msg sender
     */
    function _increaseFreeMintedGroupB(uint256 qty) internal {
        _addressData[msg.sender].numberFreeMintedGroupB += uint8(qty);
    }

    /**
     * Increase the free mint counter for msg sender
     */
    function _increaseFreeMintedGroupC(uint256 qty) internal {
        _addressData[msg.sender].numberFreeMintedGroupC += uint8(qty);
    }

    /**
     * Returns the number of tokens burned by `addr`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns address data of a token owner
     */
    function _addressDataOf(address owner) internal view returns (AddressData memory) {
        return _addressData[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerships[tokenId].addr;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerships[tokenId].addr != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += 1;
            _addressData[to].numberMinted += 1;
            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
        }

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _addressData[owner].balance -= 1;
        _addressData[owner].numberBurned += 1;
        delete _ownerships[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
        _ownerships[tokenId].addr = to;
        _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
        _ownerships[tokenId].transferCount += 1;

        // ERC4907 user info reset
        if (from != to && _users[tokenId].user != address(0)) {
            // clear user info
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Returns whether an address is external NFT owner
     */
    function _isExternalTokenOwner(address _contract, address _ownerAddress) internal view returns (bool) {
        try IBalanceOf(_contract).balanceOf(_ownerAddress) returns (uint256 balance) {
            return balance > 0;
        } catch (bytes memory) {
          // when reverted, just returns...
          return false;
        }
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     * credit: https://github.com/chiru-labs/ERC721A
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) external ;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns(address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
// Randomizer VRF - randomizer.ai
pragma solidity ^0.8.0;

// Randomizer protocol interface
interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);
    function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
    function clientWithdrawTo(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * NFT minting setup
 *******************************************************************************
 * Author: Jason Hoi https://github.com/jasonhoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Adminable.sol";

contract MintSetupTest is Adminable {
    struct MintConfig {
        // Public Mint
        uint32 publicMintStartTime;
        uint32 publicMintEndTime;
        uint16 publicMintPerWallet;
        uint256 publicMintPrice;

        // Public Mint by ERC20
        address token;
        uint256 tokenMintPrice;

        // Free Mint by WL
        uint32 freeMintStartTime;
        uint32 freeMintEndTime;
        uint16 freeMintPerWallet;
    }
    MintConfig public mintConfig;
    
    struct FreeMintConfig {
        // Free Mint by contract groups
        uint16 freeMintGroupAPerWallet;
        uint16 freeMintGroupBPerWallet;
        uint16 freeMintGroupCPerWallet;

        uint16 freeMintGroupAMinted;
        uint16 freeMintGroupATotal;

        uint16 freeMintGroupBMinted;
        uint16 freeMintGroupBTotal;

        uint16 freeMintGroupCMinted;
        uint16 freeMintGroupCTotal;
    }
    FreeMintConfig public freeMintConfig;

    constructor () {
        // Free Mint minting per wallet, and total group minted quota
        freeMintConfig.freeMintGroupAPerWallet = 1;
        freeMintConfig.freeMintGroupBPerWallet = 1;
        freeMintConfig.freeMintGroupCPerWallet = 1;
        freeMintConfig.freeMintGroupATotal = 800;
        freeMintConfig.freeMintGroupBTotal = 500;
        freeMintConfig.freeMintGroupCTotal = 300;

        // Free Mint by WL, limit minting per wallet, but no total limit
        mintConfig.freeMintStartTime = 1680368400;
        mintConfig.freeMintEndTime = 200000000;
        mintConfig.freeMintPerWallet = 1;

        // Public Mint
        mintConfig.publicMintPrice = 0.00666 ether;
        mintConfig.publicMintStartTime = 1680368400;
        mintConfig.publicMintEndTime = 200000000;
        mintConfig.publicMintPerWallet = 3;

        // Public Mint by ERC20
        mintConfig.token = 0x9593083626AF50A99462B6389CFBb407b73b849B;
        mintConfig.tokenMintPrice = 8.88 ether; // (default assumed as 18 decimals)
    }

    //////// Free Mint by contract group
    function setFreeMintByContract(uint16 _perWalletA, uint16 _perWalletB, uint16 _perWalletC, uint16 _totalA, uint16 _totalB, uint16 _totalC) 
      external 
      onlyAdmin 
    {
        freeMintConfig.freeMintGroupAPerWallet = _perWalletA;
        freeMintConfig.freeMintGroupBPerWallet = _perWalletB;
        freeMintConfig.freeMintGroupCPerWallet = _perWalletC;
        freeMintConfig.freeMintGroupATotal = _totalA;
        freeMintConfig.freeMintGroupBTotal = _totalB;
        freeMintConfig.freeMintGroupCTotal = _totalC;
    }

    // Helper function for Free Mint by groups
    function checkGroupAOwner(address _owner) public view returns (bool) {
        // Group A - Smol Brain
        // uint256 bal1 = IERC721(0x6325439389E0797Ab35752B4F43a14C004f22A9c).balanceOf(_owner);
        // uint256 bal2 = IERC721(0xA7f1462e0EcdeEbDeE4FaF6681148Ca96Db78777).balanceOf(_owner);
        uint256 bal = IERC721(address(this)).balanceOf(_owner);
        // uint256 sum = bal1 + bal2 + bal3;
        uint256 sum = bal;
        return sum > 0;
    }

    function checkGroupBOwner(address _owner) public view returns (bool) {
        // Group B - Blueberry Club
        uint256 bal = IERC721(address(this)).balanceOf(_owner);
        return bal > 1;
    }

    function checkGroupCOwner(address _owner) public view returns (bool) {
        // Group C - Diamond Pepes
        uint256 bal = IERC721(address(this)).balanceOf(_owner);
        return bal > 2;
    }

    //////// Free Mint WL
    function setFreeMint(uint32 _startTime, uint32 _endTime, uint16 _maxPerWallet) external onlyAdmin 
    {
        mintConfig.freeMintStartTime = _startTime;
        mintConfig.freeMintEndTime = _endTime;
        mintConfig.freeMintPerWallet = _maxPerWallet;
    }

    function checkFreeMintTime() public view returns (bool) {
        uint256 _currentTime = block.timestamp;
        return 
            mintConfig.freeMintStartTime > 0 
            && _currentTime >= mintConfig.freeMintStartTime 
            && _currentTime <= mintConfig.freeMintEndTime;
    }

    modifier isFreeMintActive() {
        require(checkFreeMintTime(), "Free mint is not active");
        _;
    }
    
    //////// Public minting by base coin
    function setPublicMint(uint256 _price, uint32 _startTime, uint32 _endTime, uint16 _maxPerWallet) external onlyAdmin {
        mintConfig.publicMintPrice = _price;
        mintConfig.publicMintStartTime = _startTime;
        mintConfig.publicMintEndTime = _endTime;
        mintConfig.publicMintPerWallet = _maxPerWallet;
    }

    modifier checkPublicMintValue(uint256 _qty) {
        require(msg.value >= mintConfig.publicMintPrice * _qty, "Need to send more ether");
        _;
    }

    //////// Public minting by ERC20
    function setPublicMintToken(address _token, uint256 _price) external onlyAdmin {
        mintConfig.token = _token;
        mintConfig.tokenMintPrice = _price;
    }

    modifier checkPublicMintTokenValue(uint256 _qty) {
        require(mintConfig.tokenMintPrice > 0 && mintConfig.token != address(0), 'Invalid ERC20 minting token');
        require(IERC20(mintConfig.token).allowance(msg.sender, address(this)) >= mintConfig.tokenMintPrice * _qty, "Insufficient ERC20 approved allowance");
        require(IERC20(mintConfig.token).balanceOf(msg.sender) >= mintConfig.tokenMintPrice * _qty, "Insufficient ERC20 token balance");
        _;
    }

    //////// Public minting time control
    function checkPublicMintTime() public view returns (bool) {
        uint256 _currentTime = block.timestamp;
        return 
            mintConfig.publicMintStartTime > 0 
            && _currentTime >= mintConfig.publicMintStartTime 
            && _currentTime <= mintConfig.publicMintEndTime;
    }

    modifier isPublicMintActive() {
        require(checkPublicMintTime(), "Public mint is not active");
        _;
    }
}