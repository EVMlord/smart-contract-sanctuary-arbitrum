// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../utils/Ownable.sol";
import "../utils/Reentrant.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IOrderBook.sol";
import "../interfaces/IRouterForKeeper.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OrderBook is IOrderBook, Ownable, Reentrant {
    using ECDSA for bytes32;

    address public routerForKeeper;
    mapping(bytes => bool) public usedNonce;

    constructor(address _routerForKeeper) {
        require(_routerForKeeper != address(0), "OrderBook: ZERO_ADDRESS");
        owner = msg.sender;
        routerForKeeper = _routerForKeeper;
    }

    function batchExecuteOpen(
        OpenPositionOrder[] memory orders,
        bytes[] memory signatures,
        bool requireSuccess
    ) external override nonReentrant returns (RespData[] memory respData) {
        require(orders.length == signatures.length, "OrderBook.batchExecuteOpen: LENGTH_NOT_MATCH");
        respData = new RespData[](orders.length);
        for (uint256 i = 0; i < orders.length; i++) {
            respData[i] = _executeOpen(orders[i], signatures[i], requireSuccess);
        }
        emit BatchExecuteOpen(orders, signatures, requireSuccess);
    }

    function batchExecuteClose(
        ClosePositionOrder[] memory orders,
        bytes[] memory signatures,
        bool requireSuccess
    ) external override nonReentrant returns (RespData[] memory respData) {
        require(orders.length == signatures.length, "OrderBook.batchExecuteClose: LENGTH_NOT_MATCH");
        respData = new RespData[](orders.length);
        for (uint256 i = 0; i < orders.length; i++) {
            respData[i] = _executeClose(orders[i], signatures[i], requireSuccess);
        }

        emit BatchExecuteClose(orders, signatures, requireSuccess);
    }

    function executeOpen(OpenPositionOrder memory order, bytes memory signature) external override nonReentrant {
        _executeOpen(order, signature, true);

        emit ExecuteOpen(order, signature);
    }

    function executeClose(ClosePositionOrder memory order, bytes memory signature) external override nonReentrant {
        _executeClose(order, signature, true);

        emit ExecuteClose(order, signature);
    }

    function verifyOpen(OpenPositionOrder memory order, bytes memory signature) public view override returns (bool) {
        address recover = keccak256(abi.encode(order)).toEthSignedMessageHash().recover(signature);
        require(order.trader == recover, "OrderBook.verifyOpen: NOT_SIGNER");
        require(!usedNonce[order.nonce], "OrderBook.verifyOpen: NONCE_USED");
        require(block.timestamp < order.deadline, "OrderBook.verifyOpen: EXPIRED");
        return true;
    }

    function verifyClose(ClosePositionOrder memory order, bytes memory signature) public view override returns (bool) {
        address recover = keccak256(abi.encode(order)).toEthSignedMessageHash().recover(signature);
        require(order.trader == recover, "OrderBook.verifyClose: NOT_SIGNER");
        require(!usedNonce[order.nonce], "OrderBook.verifyClose: NONCE_USED");
        require(block.timestamp < order.deadline, "OrderBook.verifyClose: EXPIRED");
        return true;
    }

    function setRouterForKeeper(address _routerForKeeper) external override onlyOwner {
        require(_routerForKeeper != address(0), "OrderBook.setRouterKeeper: ZERO_ADDRESS");

        routerForKeeper = _routerForKeeper;
        emit SetRouterForKeeper(_routerForKeeper);
    }

    function _executeOpen(
        OpenPositionOrder memory order,
        bytes memory signature,
        bool requireSuccess
    ) internal returns (RespData memory) {
        require(verifyOpen(order, signature));
        require(order.routerToExecute == routerForKeeper, "OrderBook.executeOpen: WRONG_ROUTER");
        require(order.baseToken != address(0), "OrderBook.executeOpen: ORDER_NOT_FOUND");
        require(order.side == 0 || order.side == 1, "OrderBook.executeOpen: INVALID_SIDE");

        (uint256 currentPrice, uint256 baseDecimals, uint256 quoteDecimals) = IRouterForKeeper(routerForKeeper)
            .getSpotPriceWithMultiplier(order.baseToken, order.quoteToken);
        if (order.side == 0) {
            require(currentPrice <= order.limitPrice, "OrderBook.executeOpen: WRONG_PRICE");
        } else {
            require(currentPrice >= order.limitPrice, "OrderBook.executeOpen: WRONG_PRICE");
        }

        bool success;
        bytes memory ret;
        uint256 slippageRatio = (order.side == 0)
            ? (order.limitPrice * (10**(quoteDecimals - baseDecimals)) * (10000 - order.slippage)) / 10000
            : (order.limitPrice * (10**(quoteDecimals - baseDecimals)) * (10000 + order.slippage)) / 10000;
        if (order.withWallet) {
            (success, ret) = routerForKeeper.call(
                abi.encodeWithSelector(
                    IRouterForKeeper(address(0)).openPositionWithWallet.selector,
                    order,
                    slippageRatio
                )
            );
        } else {
            (success, ret) = routerForKeeper.call(
                abi.encodeWithSelector(
                    IRouterForKeeper(address(0)).openPositionWithMargin.selector,
                    order,
                    slippageRatio
                )
            );
        }
        emit ExecuteLog(order.nonce, success);
        if (requireSuccess) {
            require(success, "_executeOpen: call failed");
        }

        usedNonce[order.nonce] = true;
        return RespData({success: success, result: ret});
    }

    function _executeClose(
        ClosePositionOrder memory order,
        bytes memory signature,
        bool requireSuccess
    ) internal returns (RespData memory) {
        require(verifyClose(order, signature));
        require(order.routerToExecute == routerForKeeper, "OrderBook.executeClose: WRONG_ROUTER");
        require(order.baseToken != address(0), "OrderBook.executeClose: ORDER_NOT_FOUND");
        require(order.side == 0 || order.side == 1, "OrderBook.executeClose: INVALID_SIDE");

        (uint256 currentPrice, , ) = IRouterForKeeper(routerForKeeper).getSpotPriceWithMultiplier(
            order.baseToken,
            order.quoteToken
        );

        require(
            order.side == 0 ? currentPrice >= order.limitPrice : currentPrice <= order.limitPrice,
            "OrderBook.executeClose: WRONG_PRICE"
        );

        (bool success, bytes memory ret) = routerForKeeper.call(
            abi.encodeWithSelector(IRouterForKeeper(address(0)).closePosition.selector, order)
        );
        emit ExecuteLog(order.nonce, success);

        if (requireSuccess) {
            require(success, "_executeClose: call failed");
        }

        usedNonce[order.nonce] = true;
        return RespData({success: success, result: ret});
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Reentrant {
    bool private entered;

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IOrderBook {
    struct RespData {
        bool success;
        bytes result;
    }

    struct OpenPositionOrder {
        address routerToExecute;
        address trader;
        address baseToken;
        address quoteToken;
        uint8 side;
        uint256 baseAmount;
        uint256 quoteAmount;
        uint256 slippage;
        uint256 limitPrice;
        uint256 deadline;
        bool withWallet;
        bytes nonce;
    }

    struct ClosePositionOrder {
        address routerToExecute;
        address trader;
        address baseToken;
        address quoteToken;
        uint8 side;
        uint256 quoteAmount;
        uint256 limitPrice;
        uint256 deadline;
        bool autoWithdraw;
        bytes nonce;
    }

    event BatchExecuteOpen(OpenPositionOrder[] orders, bytes[] signatures, bool requireSuccess);

    event BatchExecuteClose(ClosePositionOrder[] orders, bytes[] signatures, bool requireSuccess);

    event SetRouterForKeeper(address newRouterForKeeper);

    event ExecuteOpen(OpenPositionOrder order, bytes signature);

    event ExecuteClose(ClosePositionOrder order, bytes signature);

    event ExecuteLog(bytes orderId, bool success);

    function batchExecuteOpen(
        OpenPositionOrder[] memory orders,
        bytes[] memory signatures,
        bool requireSuccess
    ) external returns (RespData[] memory respData);

    function batchExecuteClose(
        ClosePositionOrder[] memory orders,
        bytes[] memory signatures,
        bool requireSuccess
    ) external returns (RespData[] memory respData);

    function executeOpen(OpenPositionOrder memory order, bytes memory signature) external;

    function executeClose(ClosePositionOrder memory order, bytes memory signature) external;

    function verifyOpen(OpenPositionOrder memory order, bytes memory signature) external view returns (bool);

    function verifyClose(ClosePositionOrder memory order, bytes memory signature) external view returns (bool);

    function setRouterForKeeper(address routerForKeeper) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "./IOrderBook.sol";

interface IRouterForKeeper {
    event Deposit(address, address, address, uint256);
    event DepositETH(address, address, uint256);
    event Withdraw(address, address, address, uint256);
    event WithdrawETH(address, address, uint256);

    function pairFactory() external view returns (address);

    function WETH() external view returns (address);

    function deposit(
        address baseToken,
        address to,
        uint256 amount
    ) external;

    function depositETH(address to) external payable;

    function withdraw(
        address baseToken,
        address to,
        uint256 amount
    ) external;

    function withdrawETH(address to, uint256 amount) external;

    function openPositionWithWallet(IOrderBook.OpenPositionOrder memory order, uint256 deadline)
        external
        returns (uint256 baseAmount);

    function openPositionWithMargin(IOrderBook.OpenPositionOrder memory order, uint256 deadline)
        external
        returns (uint256 baseAmount);

    function closePosition(IOrderBook.ClosePositionOrder memory order)
        external
        returns (uint256 baseAmount, uint256 withdrawAmount);

    function getSpotPriceWithMultiplier(address baseToken, address quoteToken)
        external
        view
        returns (
            uint256 spotPriceWithMultiplier,
            uint256 baseDecimal,
            uint256 quoteDecimal
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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