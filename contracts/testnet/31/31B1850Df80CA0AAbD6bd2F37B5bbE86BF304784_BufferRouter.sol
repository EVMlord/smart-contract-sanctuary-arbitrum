// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "ReentrancyGuard.sol";
import "AccessControl.sol";
import "ECDSA.sol";
import "Interfaces.sol";

/**
 * @author Heisenberg
 * @notice Buffer Options Router Contract
 */
contract BufferRouter is AccessControl, IBufferRouter {
    uint16 MAX_WAIT_TIME = 1 minutes;
    uint256 public nextQueueId = 0;
    address public publisher;
    uint256 public nextQueueIdToProcess = 0;
    bool public isInPrivateKeeperMode = true;

    mapping(address => uint256[]) public userQueuedIds;
    mapping(address => uint256[]) public userCancelledQueuedIds;
    mapping(address => uint256) public userNextQueueIndexToProcess;
    mapping(uint256 => QueuedTrade) public queuedTrades;
    mapping(address => bool) public contractRegistry;
    mapping(address => bool) public isKeeper;

    constructor(address _publisher) {
        publisher = _publisher;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /************************************************
     *  ADMIN ONLY FUNCTIONS
     ***********************************************/

    function setContractRegistry(address targetContract, bool register)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        contractRegistry[targetContract] = register;
    }

    function setKeeper(address _keeper, bool _isActive)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isKeeper[_keeper] = _isActive;
    }

    function setInPrivateKeeperMode() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isInPrivateKeeperMode = !isInPrivateKeeperMode;
    }

    /************************************************
     *  USER WRITE FUNCTIONS
     ***********************************************/

    /**
     * @notice Adds an option creation request in the queue
     */
    function initiateTrade(
        uint256 totalFee,
        uint256 period,
        bool isAbove,
        address targetContract,
        uint256 expectedStrike,
        uint256 slippage,
        bool allowPartialFill,
        string memory referralCode,
        uint256 traderNFTId
    ) external returns (uint256 queueId) {
        // Checks if the target contract has been registered
        require(
            contractRegistry[targetContract],
            "Router: Unauthorized contract"
        );
        IBufferBinaryOptions optionsContract = IBufferBinaryOptions(
            targetContract
        );

        optionsContract.runInitialChecks(slippage, period, totalFee);

        // Transfer the fee specified from the user to this contract.
        // User has to approve first inorder to execute this function
        IERC20(optionsContract.tokenX()).transferFrom(
            msg.sender,
            address(this),
            totalFee
        );
        queueId = nextQueueId;
        nextQueueId++;

        QueuedTrade memory queuedTrade = QueuedTrade(
            queueId,
            userQueueCount(msg.sender),
            msg.sender,
            totalFee,
            period,
            isAbove,
            targetContract,
            expectedStrike,
            slippage,
            allowPartialFill,
            block.timestamp,
            true,
            referralCode,
            traderNFTId
        );

        queuedTrades[queueId] = queuedTrade;

        userQueuedIds[msg.sender].push(queueId);

        emit InitiateTrade(msg.sender, queueId, block.timestamp);
    }

    /**
     * @notice Cancels a queued traded. Can only be called by the trade owner
     */
    function cancelQueuedTrade(uint256 queueId) external {
        QueuedTrade memory queuedTrade = queuedTrades[queueId];
        require(msg.sender == queuedTrade.user, "Router: Forbidden");
        require(queuedTrade.isQueued, "Router: Trade has already been opened");
        _cancelQueuedTrade(queueId);
        emit CancelTrade(queuedTrade.user, queueId, "User Cancelled");
    }

    /************************************************
     *  KEEPER ONLY FUNCTIONS
     ***********************************************/

    /**
     * @notice Verifies the trade parameter via the signature and resolves all the valid queued trades
     */
    function resolveQueuedTrades(OpenTradeParams[] calldata params) external {
        _validateKeeper();
        for (uint32 index = 0; index < params.length; index++) {
            OpenTradeParams memory currentParams = params[index];
            QueuedTrade memory queuedTrade = queuedTrades[
                currentParams.queueId
            ];
            IBufferBinaryOptions optionsContract = IBufferBinaryOptions(
                queuedTrade.targetContract
            );
            bool isSignerVerifed = _validateSigner(
                currentParams.timestamp,
                optionsContract.assetPair(),
                currentParams.price,
                currentParams.signature
            );
            // Silently fail if the signature doesn't match
            if (!isSignerVerifed) {
                emit FailResolve(
                    currentParams.queueId,
                    "Router: Signature didn't match"
                );
                continue;
            }
            if (
                !queuedTrade.isQueued ||
                currentParams.timestamp != queuedTrade.queuedTime
            ) {
                // Trade has already been opened or cancelled or the timestamp is wrong.
                // So ignore this trade.
                continue;
            }

            // If the opening time is much greater than the queue time then cancel the trade
            if (block.timestamp - queuedTrade.queuedTime <= MAX_WAIT_TIME) {
                _openQueuedTrade(currentParams.queueId, currentParams.price);
            } else {
                _cancelQueuedTrade(currentParams.queueId);
                emit CancelTrade(
                    queuedTrade.user,
                    currentParams.queueId,
                    "Wait time too high"
                );
            }

            // Track the next queueIndex to be processed for user
            userNextQueueIndexToProcess[queuedTrade.user] =
                queuedTrade.userQueueIndex +
                1;
        }
        // Track the next queueIndex to be processed overall
        nextQueueIdToProcess = params[params.length - 1].queueId + 1;
    }

    /**
     * @notice Verifies the option parameter via the signature and unlocks an array of options
     */
    function unlockOptions(CloseTradeParams[] calldata optionData) external {
        _validateKeeper();

        uint32 arrayLength = uint32(optionData.length);
        for (uint32 i = 0; i < arrayLength; i++) {
            CloseTradeParams memory params = optionData[i];
            IBufferBinaryOptions optionsContract = IBufferBinaryOptions(
                params.targetContract
            );
            (, , , , , uint256 expiration, , , ) = optionsContract.options(
                params.optionId
            );

            bool isSignerVerifed = _validateSigner(
                params.expiryTimestamp,
                optionsContract.assetPair(),
                params.priceAtExpiry,
                params.signature
            );

            // Silently fail if the timestamp of the signature is wrong
            if (expiration != params.expiryTimestamp) {
                emit FailUnlock(params.optionId, "Router: Wrong price");
                continue;
            }

            // Silently fail if the signature doesn't match
            if (!isSignerVerifed) {
                emit FailUnlock(
                    params.optionId,
                    "Router: Signature didn't match"
                );
                continue;
            }

            try
                optionsContract.unlock(params.optionId, params.priceAtExpiry)
            {} catch Error(string memory reason) {
                emit FailUnlock(params.optionId, reason);
                continue;
            }
        }
    }

    /************************************************
     *  READ ONLY FUNCTIONS
     ***********************************************/

    function userQueueCount(address user) public view returns (uint256) {
        return userQueuedIds[user].length;
    }

    function userCancelledQueueCount(address user)
        external
        view
        returns (uint256)
    {
        return userCancelledQueuedIds[user].length;
    }

    /************************************************
     *  INTERNAL FUNCTIONS
     ***********************************************/
    function _validateKeeper() private view {
        require(
            !isInPrivateKeeperMode || isKeeper[msg.sender],
            "Keeper: forbidden"
        );
    }

    function _validateSigner(
        uint256 timestamp,
        string memory assetPair,
        uint256 price,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 digest = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(assetPair, timestamp, price))
        );
        address recoveredSigner = ECDSA.recover(digest, signature);
        return recoveredSigner == publisher;
    }

    function _openQueuedTrade(uint256 queueId, uint256 price) internal {
        QueuedTrade storage queuedTrade = queuedTrades[queueId];
        IBufferBinaryOptions optionsContract = IBufferBinaryOptions(
            queuedTrade.targetContract
        );

        // Check if slippage lies within the bounds
        bool isSlippageWithinRange = optionsContract.isStrikeValid(
            queuedTrade.slippage,
            price,
            queuedTrade.expectedStrike
        );

        if (!isSlippageWithinRange) {
            _cancelQueuedTrade(queueId);
            emit CancelTrade(
                queuedTrade.user,
                queueId,
                "Slippage limit exceeds"
            );

            return;
        }

        // Check all the parameters and compute the amount and revised fee
        uint256 amount;
        uint256 revisedFee;
        bool isReferralValid;
        IBufferBinaryOptions.OptionParams
            memory optionParams = IBufferBinaryOptions.OptionParams(
                queuedTrade.expectedStrike,
                0,
                queuedTrade.period,
                queuedTrade.isAbove,
                queuedTrade.allowPartialFill,
                queuedTrade.totalFee,
                queuedTrade.user,
                queuedTrade.referralCode,
                queuedTrade.traderNFTId
            );
        try optionsContract.checkParams(optionParams) returns (
            uint256 _amount,
            uint256 _revisedFee,
            bool _isReferralValid
        ) {
            (amount, revisedFee, isReferralValid) = (
                _amount,
                _revisedFee,
                _isReferralValid
            );
        } catch Error(string memory reason) {
            _cancelQueuedTrade(queueId);
            emit CancelTrade(queuedTrade.user, queueId, reason);
            return;
        }

        // Transfer the fee to the target options contract
        IERC20 tokenX = IERC20(optionsContract.tokenX());
        tokenX.transfer(queuedTrade.targetContract, revisedFee);

        // Refund the user in case the trade amount was lesser
        if (revisedFee < queuedTrade.totalFee) {
            tokenX.transfer(
                queuedTrade.user,
                queuedTrade.totalFee - revisedFee
            );
        }

        optionParams.totalFee = revisedFee;
        optionParams.strike = price;
        optionParams.amount = amount;

        uint256 optionId = optionsContract.createFromRouter(
            optionParams,
            isReferralValid
        );

        queuedTrade.isQueued = false;

        emit OpenTrade(queuedTrade.user, queueId, optionId);
    }

    function _cancelQueuedTrade(uint256 queueId) internal {
        QueuedTrade storage queuedTrade = queuedTrades[queueId];
        IBufferBinaryOptions optionsContract = IBufferBinaryOptions(
            queuedTrade.targetContract
        );
        queuedTrade.isQueued = false;
        IERC20(optionsContract.tokenX()).transfer(
            queuedTrade.user,
            queuedTrade.totalFee
        );

        userCancelledQueuedIds[queuedTrade.user].push(queueId);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: BUSL-1.1
import "ERC20.sol";

pragma solidity 0.8.4;

interface IKeeperPayment {
    function distributeForOpen(
        uint256 queueId,
        uint256 size,
        address keeper
    ) external;

    function distributeForClose(
        uint256 optionId,
        uint256 size,
        address keeper
    ) external;

    event DistriuteRewardForOpen(uint256 queueId, uint256 size, address keeper);
    event DistriuteRewardForClose(
        uint256 optionId,
        uint256 size,
        address keeper
    );
    event UpdateOpenRewardPercent(uint32 value);
    event UpdateReward(uint32 value);
}

interface IBufferRouter {
    struct QueuedTrade {
        uint256 queueId;
        uint256 userQueueIndex;
        address user;
        uint256 totalFee;
        uint256 period;
        bool isAbove;
        address targetContract;
        uint256 expectedStrike;
        uint256 slippage;
        bool allowPartialFill;
        uint256 queuedTime;
        bool isQueued;
        string referralCode;
        uint256 traderNFTId;
    }
    struct Trade {
        uint256 queueId;
        uint256 price;
    }
    struct OpenTradeParams {
        uint256 queueId;
        uint256 timestamp;
        uint256 price;
        bytes signature;
    }
    struct CloseTradeParams {
        uint256 optionId;
        address targetContract;
        uint256 expiryTimestamp;
        uint256 priceAtExpiry;
        bytes signature;
    }
    event OpenTrade(address indexed account, uint256 queueId, uint256 optionId);
    event CancelTrade(address indexed account, uint256 queueId, string reason);
    event FailUnlock(uint256 optionId, string reason);
    event FailResolve(uint256 queueId, string reason);
    event InitiateTrade(
        address indexed account,
        uint256 queueId,
        uint256 queuedTime
    );
}

interface IBufferBinaryOptions {
    event Create(
        address indexed account,
        uint256 indexed id,
        uint256 settlementFee,
        uint256 totalFee
    );

    event Exercise(
        address indexed account,
        uint256 indexed id,
        uint256 profit,
        uint256 priceAtExpiration
    );
    event Expire(
        uint256 indexed id,
        uint256 premium,
        uint256 priceAtExpiration
    );
    event Pause(bool isPaused);
    event UpdateReferral(
        address referrer,
        bool isReferralValid,
        uint256 totalFee,
        uint256 referrerFee,
        uint256 rebate,
        string referralCode
    );

    function createFromRouter(
        OptionParams calldata optionParams,
        bool isReferralValid
    ) external returns (uint256 optionID);

    function checkParams(OptionParams calldata optionParams)
        external
        returns (
            uint256 amount,
            uint256 revisedFee,
            bool isReferralValid
        );

    function runInitialChecks(
        uint256 slippage,
        uint256 period,
        uint256 totalFee
    ) external view;

    function isStrikeValid(
        uint256 slippage,
        uint256 strike,
        uint256 expectedStrike
    ) external view returns (bool);

    function tokenX() external view returns (ERC20);

    function pool() external view returns (ILiquidityPool);

    function config() external view returns (IOptionsConfig);

    function assetPair() external view returns (string calldata);

    enum State {
        Inactive,
        Active,
        Exercised,
        Expired
    }

    enum AssetCategory {
        Forex,
        Crypto,
        Commodities
    }
    struct OptionExpiryData {
        uint256 optionId;
        uint256 priceAtExpiration;
    }

    struct Option {
        State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        bool isAbove;
        uint256 totalFee;
        uint256 createdAt;
    }
    struct OptionParams {
        uint256 strike;
        uint256 amount;
        uint256 period;
        bool isAbove;
        bool allowPartialFill;
        uint256 totalFee;
        address user;
        string referralCode;
        uint256 traderNFTId;
    }

    function options(uint256 optionId)
        external
        view
        returns (
            State state,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            bool isAbove,
            uint256 totalFee,
            uint256 createdAt
        );

    function unlock(uint256 optionID, uint256 priceAtExpiration) external;
}

interface ILiquidityPool {
    struct LockedAmount {
        uint256 timestamp;
        uint256 amount;
    }
    struct ProvidedLiquidity {
        uint256 unlockedAmount;
        LockedAmount[] lockedAmounts;
        uint256 nextIndexForUnlock;
    }
    struct LockedLiquidity {
        uint256 amount;
        uint256 premium;
        bool locked;
    }
    event Profit(uint256 indexed id, uint256 amount);
    event Loss(uint256 indexed id, uint256 amount);
    event Provide(address indexed account, uint256 amount, uint256 writeAmount);
    event UpdateMaxLiquidity(uint256 indexed maxLiquidity);
    event Withdraw(
        address indexed account,
        uint256 amount,
        uint256 writeAmount
    );

    function unlock(uint256 id) external;

    function totalTokenXBalance() external view returns (uint256 amount);

    function availableBalance() external view returns (uint256 balance);

    function send(
        uint256 id,
        address account,
        uint256 amount
    ) external;

    function lock(
        uint256 id,
        uint256 tokenXAmount,
        uint256 premium
    ) external;
}

interface IOptionsConfig {
    struct Window {
        uint8 startHour;
        uint8 startMinute;
        uint8 endHour;
        uint8 endMinute;
    }

    event UpdateMarketTime();
    event UpdateMaxPeriod(uint32 value);
    event UpdateMinPeriod(uint32 value);

    event UpdateOptionFeePerTxnLimitPercent(uint16 value);
    event UpdateOverallPoolUtilizationLimit(uint16 value);
    event UpdateSettlementFeeDisbursalContract(address value);
    event UpdatetraderNFTContract(address value);
    event UpdateAssetUtilizationLimit(uint16 value);
    event UpdateMinFee(uint256 value);

    function traderNFTContract() external view returns (address);

    function settlementFeeDisbursalContract() external view returns (address);

    function marketTimes(uint8)
        external
        view
        returns (
            uint8,
            uint8,
            uint8,
            uint8
        );

    function assetUtilizationLimit() external view returns (uint16);

    function overallPoolUtilizationLimit() external view returns (uint16);

    function maxPeriod() external view returns (uint32);

    function minPeriod() external view returns (uint32);

    function minFee() external view returns (uint256);

    function optionFeePerTxnLimitPercent() external view returns (uint16);
}

interface ITraderNFT {
    function tokenOwner(uint256 id) external view returns (address user);

    function tokenTierMappings(uint256 id) external view returns (uint8 tier);

    event UpdateNftBasePrice(uint256 nftBasePrice);
    event UpdateMaxNFTMintLimits(uint256 maxNFTMintLimit);
    event UpdateBaseURI(string baseURI);
    event Claim(address indexed account, uint256 claimTokenId);
    event Mint(address indexed account, uint256 tokenId, uint8 tier);
}

interface IReferralStorage {
    function codeOwner(string memory _code) external view returns (address);

    function traderReferralCodes(address) external view returns (string memory);

    function getTraderReferralInfo(address user)
        external
        view
        returns (string memory, address);

    function setTraderReferralCode(address user, string memory _code) external;

    function setReferrerTier(address, uint8) external;

    function referrerTierStep(uint8 referralTier)
        external
        view
        returns (uint8 step);

    function referrerTierDiscount(uint8 referralTier)
        external
        view
        returns (uint32 discount);

    function referrerTier(address referrer) external view returns (uint8 tier);

    struct ReferrerData {
        uint256 tradeVolume;
        uint256 rebate;
        uint256 trades;
    }

    struct ReferreeData {
        uint256 tradeVolume;
        uint256 rebate;
    }

    struct ReferralData {
        ReferrerData referrerData;
        ReferreeData referreeData;
    }

    struct Tier {
        uint256 totalRebate; // e.g. 2400 for 24%
        uint256 discountShare; // 5000 for 50%/50%, 7000 for 30% rebates/70% discount
    }

    event UpdateTraderReferralCode(address indexed account, string code);
    event UpdateReferrerTier(address referrer, uint8 tierId);
    event RegisterCode(address indexed account, string code);
    event SetCodeOwner(
        address indexed account,
        address newAccount,
        string code
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

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