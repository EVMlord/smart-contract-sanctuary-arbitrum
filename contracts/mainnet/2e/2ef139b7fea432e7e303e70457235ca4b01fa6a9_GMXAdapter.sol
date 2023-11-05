// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/structs/EnumerableSetUpgradeable.sol";
import "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol";
import "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../../../lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import "../../interfaces/IGmxRouter.sol";

import "../../interfaces/IWETH.sol";
import "../../components/ImplementationGuard.sol";
import "./Storage.sol";
import "./Config.sol";
import "./Position.sol";

contract GMXAdapter is Position, Config, ImplementationGuard, ReentrancyGuardUpgradeable{
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.Bytes32ToBytes32Map;

    address internal immutable _WETH;

    event Withdraw(
        address collateralAddress,
        address account,
        uint256 balance
    );

    constructor(address weth) ImplementationGuard() {
        _WETH = weth;
    }

    receive() external payable {}

    modifier onlyTraderOrFactory() {
        require(msg.sender == _account.account || msg.sender == _factory, "OnlyTraderOrFactory");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == _factory, "onlyFactory");
        _;
    }

    function initialize(
        uint256 exchangeId,
        address account,
        address collateralToken,
        address assetToken,
        bool isLong
    ) external initializer onlyDelegateCall {
        require(exchangeId == EXCHANGE_ID, "Invalidexchange");

        _factory = msg.sender;
        _gmxPositionKey = keccak256(abi.encodePacked(address(this), collateralToken, assetToken, isLong));

        _account.account = account;
        _account.collateralToken = collateralToken;
        _account.indexToken = assetToken;
        _account.isLong = isLong;
        _account.collateralDecimals = IERC20MetadataUpgradeable(collateralToken).decimals();
        _updateConfigs();
    }

    function accountState() external view returns (AccountState memory) {
        return _account;
    }

    function getPendingOrderKeys() external view returns (bytes32[] memory) {
        return _getPendingOrders();
    }

    function getPositionKey() external view returns(bytes32){
        return _gmxPositionKey;
    }

    function getOrder(bytes32 orderKey) external view returns(bool isFilled, LibGmx.OrderHistory memory history){
        (isFilled, history) = LibGmx.getOrder(_exchangeConfigs, orderKey);
    }

    function _tryApprovePlugins() internal {
        IGmxRouter(_exchangeConfigs.router).approvePlugin(_exchangeConfigs.orderBook);
        IGmxRouter(_exchangeConfigs.router).approvePlugin(_exchangeConfigs.positionRouter);
    }

    function _isMarketOrder(uint8 flags) internal pure returns (bool) {
        return (flags & POSITION_MARKET_ORDER) != 0;
    }

    function openPosition(
        address swapInToken,
        uint256 swapInAmount, // tokenIn.decimals
        uint256 minSwapOut, // collateral.decimals
        uint256 sizeUsd, // 1e18
        uint96 priceUsd, // 1e18
        uint96 tpPriceUsd,
        uint96 slPriceUsd,
        uint8 flags // MARKET, TRIGGER
    ) external payable onlyTraderOrFactory nonReentrant {

        _updateConfigs();
        _tryApprovePlugins();
        _cleanOrders();

        bytes32 orderKey;
        orderKey = _openPosition(
            swapInToken,
            swapInAmount, // tokenIn.decimals
            minSwapOut, // collateral.decimals
            sizeUsd, // 1e18
            priceUsd, // 1e18
            flags // MARKET, TRIGGER
        );

        if (flags & POSITION_TPSL_ORDER > 0) {
            bytes32 tpOrderKey;
            bytes32 slOrderKey;
            if (tpPriceUsd > 0) {
                tpOrderKey = _closePosition(0, sizeUsd, tpPriceUsd, 0);
            }
            if (slPriceUsd > 0) {
                slOrderKey = _closePosition(0, sizeUsd, slPriceUsd, 0);
            }
            _openTpslOrderIndexes.set(orderKey, LibGmx.encodeTpslIndex(tpOrderKey, slOrderKey));
        }
    }

    function _openPosition(
        address swapInToken,
        uint256 swapInAmount, // tokenIn.decimals
        uint256 minSwapOut, // collateral.decimals
        uint256 sizeUsd, // 1e18
        uint96 priceUsd, // 1e18
        uint8 flags // MARKET, TRIGGER
    ) internal returns(bytes32 orderKey){

        _updateConfigs();
        _tryApprovePlugins();
        _cleanOrders();

        OpenPositionContext memory context = OpenPositionContext({
            sizeUsd: sizeUsd * GMX_DECIMAL_MULTIPLIER,
            priceUsd: priceUsd * GMX_DECIMAL_MULTIPLIER,
            isMarket: _isMarketOrder(flags),
            fee: 0,
            amountIn: 0,
            amountOut: 0,
            gmxOrderIndex: 0,
            executionFee: msg.value
        });
        if (swapInToken == _WETH) {
            IWETH(_WETH).deposit{ value: swapInAmount }();
            context.executionFee = msg.value - swapInAmount;
        }
        if (swapInToken != _account.collateralToken) {
            context.amountOut = LibGmx.swap(
                _exchangeConfigs,
                swapInToken,
                _account.collateralToken,
                swapInAmount,
                minSwapOut
            );
        } else {
            context.amountOut = swapInAmount;
        }
        context.amountIn = context.amountOut;
        IERC20Upgradeable(_account.collateralToken).approve(_exchangeConfigs.router, context.amountIn);

        return _openPosition(context);
    }

    /// @notice Place a closing request on GMX.
    function closePosition(
        uint256 collateralUsd, // collateral.decimals
        uint256 sizeUsd, // 1e18
        uint96 priceUsd, // 1e18
        uint96 tpPriceUsd, // 1e18
        uint96 slPriceUsd, // 1e18
        uint8 flags // MARKET, TRIGGER
    ) external payable onlyTraderOrFactory nonReentrant {

        _updateConfigs();
        _cleanOrders();

        if (flags & POSITION_TPSL_ORDER > 0) {
            if (_account.isLong) {
                require(tpPriceUsd >= slPriceUsd, "WrongPrice");
            } else {
                require(tpPriceUsd <= slPriceUsd, "WrongPrice");
            }
            bytes32 tpOrderKey = _closePosition(
                collateralUsd, // collateral.decimals
                sizeUsd, // 1e18
                tpPriceUsd, // 1e18
                0 // MARKET, TRIGGER
            );
            _closeTpslOrderIndexes.add(tpOrderKey);
            bytes32 slOrderKey = _closePosition(
                collateralUsd, // collateral.decimals
                sizeUsd, // 1e18
                slPriceUsd, // 1e18
                0 // MARKET, TRIGGER
            );
            _closeTpslOrderIndexes.add(slOrderKey);
        } else {
            _closePosition(
                collateralUsd, // collateral.decimals
                sizeUsd, // 1e18
                priceUsd, // 1e18
                flags // MARKET, TRIGGER
            );
        }
    }

    /// @notice Place a closing request on GMX.
    function _closePosition(
        uint256 collateralUsd, // collateral.decimals
        uint256 sizeUsd, // 1e18
        uint96 priceUsd, // 1e18
        uint8 flags // MARKET, TRIGGER
    ) internal returns (bytes32 orderKey)  {

        _updateConfigs();
        _cleanOrders();

        ClosePositionContext memory context = ClosePositionContext({
            collateralUsd: collateralUsd * GMX_DECIMAL_MULTIPLIER,
            sizeUsd: sizeUsd * GMX_DECIMAL_MULTIPLIER,
            priceUsd: priceUsd * GMX_DECIMAL_MULTIPLIER,
            isMarket: _isMarketOrder(flags),
            gmxOrderIndex: 0,
            executionFee: 0
        });
        return _closePosition(context);
    }

    function updateOrder(
        bytes32 orderKey,
        uint256 collateralDelta,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    ) external onlyTraderOrFactory nonReentrant {
        _updateConfigs();
        _cleanOrders();

        LibGmx.OrderHistory memory history = LibGmx.decodeOrderHistoryKey(orderKey);
        if (history.receiver == LibGmx.OrderReceiver.OB_INC) {
            IGmxOrderBook(_exchangeConfigs.orderBook).updateIncreaseOrder(
                history.index,
                sizeDelta * GMX_DECIMAL_MULTIPLIER,
                triggerPrice * GMX_DECIMAL_MULTIPLIER,
                triggerAboveThreshold
            );
        } else if (history.receiver == LibGmx.OrderReceiver.OB_DEC) {
            IGmxOrderBook(_exchangeConfigs.orderBook).updateDecreaseOrder(
                history.index,
                collateralDelta * GMX_DECIMAL_MULTIPLIER,
                sizeDelta * GMX_DECIMAL_MULTIPLIER,
                triggerPrice * GMX_DECIMAL_MULTIPLIER,
                triggerAboveThreshold
            );
        } else {
            revert("InvalidOrderType");
        }
    }

    function withdraw() external nonReentrant {
        _updateConfigs();
        _cleanOrders();

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            if (_account.collateralToken == _WETH) {
                IWETH(_WETH).deposit{ value: ethBalance }();
            } else {
                AddressUpgradeable.sendValue(payable(_account.account), ethBalance);
                emit Withdraw(
                    _account.collateralToken,
                    _account.account,
                    ethBalance
                );
            }
        }

        uint256 balance = IERC20Upgradeable(_account.collateralToken).balanceOf(address(this));
        //ToDo - should we check if margin is safe?
        if (balance > 0) {
            _transferToUser(balance);
                emit Withdraw(
                _account.collateralToken,
                _account.account,
                balance
            );
        }
        // clean tpsl orders
        _cleanTpslOrders();
    }

    function _transferToUser(uint256 amount) internal {
        if (_account.collateralToken == _WETH) {
            IWETH(_WETH).withdraw(amount);
            Address.sendValue(payable(_account.account), amount);
        } else {
            IERC20Upgradeable(_account.collateralToken).safeTransfer(_account.account, amount);
        }
    }

    function cancelOrders(bytes32[] memory keys) external onlyTraderOrFactory nonReentrant {
        _cleanOrders();
        _cancelOrders(keys);
    }

    function _cancelOrders(bytes32[] memory keys) internal {
        for (uint256 i = 0; i < keys.length; i++) {
            bool success = _cancelOrder(keys[i]);
            require(success, "CancelFailed");
        }
    }

    function cancelTimeoutOrders(bytes32[] memory keys) external nonReentrant {
        _cleanOrders();
        _cancelTimeoutOrders(keys);
    }

    function _cancelTimeoutOrders(bytes32[] memory keys) internal {
        uint256 _now = block.timestamp;
        uint256 marketTimeout = _exchangeConfigs.marketOrderTimeoutSeconds;
        uint256 limitTimeout = _exchangeConfigs.limitOrderTimeoutSeconds;
        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 orderKey = keys[i];
            LibGmx.OrderHistory memory history = LibGmx.decodeOrderHistoryKey(orderKey);
            uint256 elapsed = _now - history.timestamp;
            if (
                ((history.receiver == LibGmx.OrderReceiver.PR_INC || history.receiver == LibGmx.OrderReceiver.PR_DEC) &&
                    elapsed >= marketTimeout) ||
                ((history.receiver == LibGmx.OrderReceiver.OB_INC || history.receiver == LibGmx.OrderReceiver.OB_DEC) &&
                    elapsed >= limitTimeout)
            ) {
                if (_cancelOrder(orderKey)) {
                    _cancelTpslOrders(orderKey);
                }
            }
        }
    }

    function _cleanOrders() internal {
        bytes32[] memory pendingKeys = _pendingOrders.values();
        for (uint256 i = 0; i < pendingKeys.length; i++) {
            bytes32 key = pendingKeys[i];
            (bool notExist, ) = LibGmx.getOrder(_exchangeConfigs, key);
            if (notExist) {
                _removePendingOrder(key);
            }
        }
    }

    function _cleanTpslOrders() internal {
        // open tpsl orders
        uint256 openLength = _openTpslOrderIndexes.length();
        bytes32[] memory openKeys = new bytes32[](openLength);
        for (uint256 i = 0; i < openLength; i++) {
            (openKeys[i], ) = _openTpslOrderIndexes.at(i);
        }
        for (uint256 i = 0; i < openLength; i++) {
            // clean all tpsl orders paired with orders that already filled
            if (!_pendingOrders.contains(openKeys[i])) {
                _cancelTpslOrders(openKeys[i]);
            }
        }
        // close tpsl orders
        uint256 closeLength = _closeTpslOrderIndexes.length();
        bytes32[] memory closeKeys = new bytes32[](closeLength);
        for (uint256 i = 0; i < closeLength; i++) {
            closeKeys[i] = _closeTpslOrderIndexes.at(i);
        }
        for (uint256 i = 0; i < closeLength; i++) {
            // clean all tpsl orders paired with orders that already filled
            if (_pendingOrders.contains(closeKeys[i])) {
                _cancelOrder(closeKeys[i]);
            }
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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

    function safePermit(
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IGmxRouter {
    function approvedPlugins(address, address) external view returns (bool);

    function approvePlugin(address _plugin) external;

    function denyPlugin(address _plugin) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

contract ImplementationGuard {
    address private immutable _this;

    constructor() {
        _this = address(this);
    }

    modifier onlyDelegateCall() {
        require(address(this) != _this);
        _;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/structs/EnumerableSetUpgradeable.sol";
import "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/structs/EnumerableMapUpgradeable.sol";

import "./Types.sol";

contract Storage is Initializable {
    uint256 internal constant EXCHANGE_ID = 1;

    uint32 internal _localexchangeVersion;
    mapping(address => uint32) _localAssetVersions;

    address internal _factory;
    bytes32 internal _gmxPositionKey;

    ExchangeConfigs internal _exchangeConfigs;

    AccountState internal _account;
    EnumerableSetUpgradeable.Bytes32Set internal _pendingOrders;
    EnumerableMapUpgradeable.Bytes32ToBytes32Map internal _openTpslOrderIndexes;
    EnumerableSetUpgradeable.Bytes32Set internal _closeTpslOrderIndexes;


    //ToDo - Do we need these gaps?
    //bytes32[50] private __gaps;

    //Position Market order constant flag
    uint8 constant POSITION_MARKET_ORDER = 0x40;
    uint8 constant POSITION_TPSL_ORDER = 0x08;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/structs/EnumerableSetUpgradeable.sol";

import "../../interfaces/IGmxProxyFactory.sol";

import "../lib/LibUtils.sol";
import "./Storage.sol";
import "./Position.sol";

contract Config is Storage, Position{
    using LibUtils for bytes32;
    using LibUtils for address;
    using LibUtils for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    function _updateConfigs() internal virtual{
        (uint32 latestexchangeVersion) = IGmxProxyFactory(_factory).getConfigVersions(
            EXCHANGE_ID
        );
        if (_localexchangeVersion < latestexchangeVersion) {
            _updateExchangeConfigs();
            _localexchangeVersion = latestexchangeVersion;
        }
    }

    function _updateExchangeConfigs() internal {
        uint256[] memory values = IGmxProxyFactory(_factory).getExchangeConfig(EXCHANGE_ID);
        require(values.length >= uint256(ExchangeConfigIds.END), "MissingConfigs");

        address newPositionRouter = values[uint256(ExchangeConfigIds.POSITION_ROUTER)].toAddress();
        address newOrderBook = values[uint256(ExchangeConfigIds.ORDER_BOOK)].toAddress();
        //ToDo - is cancelling orders when we change positionRouter and orderBook really necessary?
        _onGmxAddressUpdated(
            _exchangeConfigs.positionRouter,
            _exchangeConfigs.orderBook,
            newPositionRouter,
            newOrderBook
        );
        _exchangeConfigs.vault = values[uint256(ExchangeConfigIds.VAULT)].toAddress();
        _exchangeConfigs.positionRouter = newPositionRouter;
        _exchangeConfigs.orderBook = newOrderBook;
        _exchangeConfigs.router = values[uint256(ExchangeConfigIds.ROUTER)].toAddress();
        _exchangeConfigs.referralCode = bytes32(values[uint256(ExchangeConfigIds.REFERRAL_CODE)]);
        _exchangeConfigs.marketOrderTimeoutSeconds = values[uint256(ExchangeConfigIds.MARKET_ORDER_TIMEOUT_SECONDS)]
            .toU32();
        _exchangeConfigs.limitOrderTimeoutSeconds = values[uint256(ExchangeConfigIds.LIMIT_ORDER_TIMEOUT_SECONDS)]
            .toU32();
        _exchangeConfigs.initialMarginRate = values[uint256(ExchangeConfigIds.INITIAL_MARGIN_RATE)]
            .toU32();
        _exchangeConfigs.maintenanceMarginRate = values[uint256(ExchangeConfigIds.MAINTENANCE_MARGIN_RATE)]
            .toU32();
    }

    function _onGmxAddressUpdated(
        address previousPositionRouter,
        address previousOrderBook,
        address newPostitionRouter,
        address newOrderBook
    ) internal virtual {
        bool cancelPositionRouter = previousPositionRouter != newPostitionRouter;
        bool cancelOrderBook = previousOrderBook != newOrderBook;
        bytes32[] memory pendingKeys = _pendingOrders.values();
        for (uint256 i = 0; i < pendingKeys.length; i++) {
            bytes32 key = pendingKeys[i];
            if (cancelPositionRouter) {
                LibGmx.cancelOrderFromPositionRouter(previousPositionRouter, key);
                _removePendingOrder(key);
            }
            if (cancelOrderBook) {
                LibGmx.cancelOrderFromOrderBook(previousOrderBook, key);
                _removePendingOrder(key);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/structs/EnumerableSetUpgradeable.sol";
import "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol";

import "../lib/LibUtils.sol";
import "./lib/LibGmx.sol";
import "./Storage.sol";

contract Position  is Storage{
    using LibUtils for uint256;
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.Bytes32ToBytes32Map;

    uint256 internal constant GMX_DECIMAL_MULTIPLIER = 1e12; // 30 - 18
    uint256 internal constant MAX_PENDING_ORDERS = 64;

    event AddPendingOrder(
        LibGmx.OrderCategory category,
        LibGmx.OrderReceiver receiver,
        uint256 index,
        uint256 timestamp
    );
    event RemovePendingOrder(bytes32 key);
    event CancelOrder(bytes32 key, bool success);

    event OpenPosition(address collateralToken, address indexToken, bool isLong, OpenPositionContext context);
    event ClosePosition(address collateralToken, address indexToken, bool isLong, ClosePositionContext context);

    function _hasPendingOrder(bytes32 key) internal view returns (bool) {
        return _pendingOrders.contains(key);
    }

    function _getPendingOrders() internal view returns (bytes32[] memory) {
        return _pendingOrders.values();
    }

    function _removePendingOrder(bytes32 key) internal {
        _pendingOrders.remove(key);
        emit RemovePendingOrder(key);
    }

    function _getGmxPosition() internal view returns (IGmxVault.Position memory) {
        return IGmxVault(_exchangeConfigs.vault).positions(_gmxPositionKey);
    }

    function _addPendingOrder(
        LibGmx.OrderCategory category,
        LibGmx.OrderReceiver receiver
    ) internal returns (uint256 index, bytes32 orderKey) {
        index = LibGmx.getOrderIndex(_exchangeConfigs, receiver);
        orderKey = LibGmx.encodeOrderHistoryKey(category, receiver, index, block.timestamp);
        require(_pendingOrders.add(orderKey), "AddFailed");
        emit AddPendingOrder(category, receiver, index, block.timestamp);
    }

    function _getMarginValue(
        IGmxVault.Position memory position,
        uint256 deltaCollateral,
        uint256 priceUsd
    ) internal view returns (uint256 accountValue, bool isNegative) {
        bool hasProfit = false;
        uint256 gmxPnlUsd = 0;
        uint256 gmxFundingFeeUsd = 0;
        // 1. gmx pnl and funding, 1e30
        if (position.sizeUsd != 0) {
            (hasProfit, gmxPnlUsd) = LibGmx.getPnl(
                _exchangeConfigs,
                _account.indexToken,
                position.sizeUsd,
                position.averagePrice,
                _account.isLong,
                priceUsd,
                position.lastIncreasedTime
            );
            gmxFundingFeeUsd = IGmxVault(_exchangeConfigs.vault).getFundingFee(
                _account.collateralToken,
                position.sizeUsd,
                position.entryFundingRate
            );
        }
        //ToDo - need to double check the below formulae to make sure they are solid
        int256 value = int256(position.collateralUsd) +
            (hasProfit ? int256(gmxPnlUsd) : -int256(gmxPnlUsd)) -
            int256(gmxFundingFeeUsd);
        if (_account.isLong) {
            value += (int256(deltaCollateral) * int256(position.averagePrice)) / int256(10**_account.collateralDecimals); // 1e30
        } else {
            uint256 tokenPrice = LibGmx.getOraclePrice(_exchangeConfigs, _account.collateralToken, false); // 1e30
            value += (int256(deltaCollateral) * int256(tokenPrice)) / int256(10**_account.collateralDecimals); // 1e30
        }
        if (value > 0) {
            accountValue = uint256(value);
            isNegative = false;
        } else {
            accountValue = uint256(-value);
            isNegative = true;
        }
    }

    function _isMarginSafe(
        IGmxVault.Position memory position,
        uint256 deltaCollateralUsd,
        uint256 deltaSizeUsd,
        uint256 priceUsd,
        uint32 threshold
    ) internal view returns (bool) {
        if (position.sizeUsd == 0) {
            return true;
        }
        (uint256 accountValue, bool isNegative) = _getMarginValue(position, deltaCollateralUsd, priceUsd); // 1e30
        if (isNegative) {
            return false;
        }
        uint256 liquidationFeeUsd = IGmxVault(_exchangeConfigs.vault).liquidationFeeUsd();
        return accountValue >= (position.sizeUsd + deltaSizeUsd).rate(threshold).max(liquidationFeeUsd);
    }

    function _openPosition(OpenPositionContext memory context) internal returns(bytes32 orderKey){
        require(_pendingOrders.length() <= MAX_PENDING_ORDERS, "TooManyPendingOrders");
        IGmxVault.Position memory position = _getGmxPosition();
        require(
            _isMarginSafe(
                position,
                context.amountIn,
                context.sizeUsd,
                LibGmx.getOraclePrice(_exchangeConfigs, _account.indexToken, !_account.isLong),
                _exchangeConfigs.initialMarginRate
            ),
            "ImMarginUnsafe"
        );
        address[] memory path = new address[](1);
        path[0] = _account.collateralToken;
        if (context.isMarket) {
            context.executionFee = LibGmx.getPrExecutionFee(_exchangeConfigs);
            IGmxPositionRouter(_exchangeConfigs.positionRouter).createIncreasePosition{ value: context.executionFee }(
                path,
                _account.indexToken,
                context.amountIn,
                0,
                context.sizeUsd,
                _account.isLong,
                _account.isLong ? type(uint256).max : 0,
                context.executionFee,
                _exchangeConfigs.referralCode,
                address(0)
            );
            (context.gmxOrderIndex, orderKey) = _addPendingOrder(
                LibGmx.OrderCategory.OPEN,
                LibGmx.OrderReceiver.PR_INC
            );
        } else {
            context.executionFee = LibGmx.getObExecutionFee(_exchangeConfigs);
            IGmxOrderBook(_exchangeConfigs.orderBook).createIncreaseOrder{ value: context.executionFee }(
                path,
                context.amountIn,
                _account.indexToken,
                0,
                context.sizeUsd,
                _account.collateralToken,
                _account.isLong,
                context.priceUsd,
                !_account.isLong,
                context.executionFee,
                false
            );
            (context.gmxOrderIndex, orderKey) = _addPendingOrder(
                LibGmx.OrderCategory.OPEN,
                LibGmx.OrderReceiver.OB_INC
            );
        }
        emit OpenPosition(_account.collateralToken, _account.indexToken, _account.isLong, context);
    }

    function _closePosition(ClosePositionContext memory context) internal returns(bytes32 orderKey){
        require(_pendingOrders.length() <= MAX_PENDING_ORDERS * 2, "TooManyPendingOrders");

        IGmxVault.Position memory position = _getGmxPosition();
        require(
            _isMarginSafe(
                position,
                0,
                0,
                LibGmx.getOraclePrice(_exchangeConfigs, _account.indexToken, !_account.isLong),
                _exchangeConfigs.maintenanceMarginRate
            ),
            "MmMarginUnsafe"
        );

        address[] memory path = new address[](1);
        path[0] = _account.collateralToken;
        if (context.isMarket) {
            context.executionFee = LibGmx.getPrExecutionFee(_exchangeConfigs);
            context.priceUsd = _account.isLong ? 0 : type(uint256).max;
            IGmxPositionRouter(_exchangeConfigs.positionRouter).createDecreasePosition{ value: context.executionFee }(
                path, // no swap for collateral
                _account.indexToken,
                context.collateralUsd,
                context.sizeUsd,
                _account.isLong, // no swap for collateral
                address(this),
                context.priceUsd,
                0,
                context.executionFee,
                false,
                address(0)
            );
            (context.gmxOrderIndex, orderKey) = _addPendingOrder(LibGmx.OrderCategory.CLOSE, LibGmx.OrderReceiver.PR_DEC);
        } else {
            context.executionFee = LibGmx.getObExecutionFee(_exchangeConfigs);
            uint256 oralcePrice = LibGmx.getOraclePrice(_exchangeConfigs, _account.indexToken, !_account.isLong);
            uint256 priceUsd = context.priceUsd;
            IGmxOrderBook(_exchangeConfigs.orderBook).createDecreaseOrder{ value: context.executionFee }(
                _account.indexToken,
                context.sizeUsd,
                _account.collateralToken,
                context.collateralUsd,
                _account.isLong,
                priceUsd,
                priceUsd >= oralcePrice
            );
            (context.gmxOrderIndex, orderKey) = _addPendingOrder(LibGmx.OrderCategory.CLOSE, LibGmx.OrderReceiver.OB_DEC);
        }
        emit ClosePosition(_account.collateralToken, _account.indexToken, _account.isLong, context);
    }

    function _cancelOrder(bytes32 key) internal returns (bool success) {
        require(_hasPendingOrder(key), "KeyNotExists");
        success = LibGmx.cancelOrder(_exchangeConfigs, key);
        require(success, 'Cancel Order Failed');
        _removePendingOrder(key);
        emit CancelOrder(key, success);
    }

    function _cancelTpslOrders(bytes32 orderKey) internal returns (bool success) {
        (bool exists, bytes32 tpslIndex) = _openTpslOrderIndexes.tryGet(orderKey);
        if (!exists) {
            success = true;
        } else {
            (bytes32 tpOrderKey, bytes32 slOrderKey) = LibGmx.decodeTpslIndex(orderKey, tpslIndex);
            if (_cancelOrder(tpOrderKey) && _cancelOrder(slOrderKey)) {
                _openTpslOrderIndexes.remove(orderKey);
                success = true;
            }
        }
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSetUpgradeable.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMapUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSetUpgradeable.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

enum ExchangeConfigIds {
    VAULT,
    POSITION_ROUTER,
    ORDER_BOOK,
    ROUTER,
    REFERRAL_CODE,
    MARKET_ORDER_TIMEOUT_SECONDS,
    LIMIT_ORDER_TIMEOUT_SECONDS,
    INITIAL_MARGIN_RATE,
    MAINTENANCE_MARGIN_RATE,
    END
}

struct ExchangeConfigs {
    address vault;
    address positionRouter;
    address orderBook;
    address router;
    bytes32 referralCode;
    // ========================
    uint32 marketOrderTimeoutSeconds;
    uint32 limitOrderTimeoutSeconds;
    uint32 initialMarginRate;
    uint32 maintenanceMarginRate;
    bytes32[20] reserved;
}

struct AccountState {
    address account;
    address collateralToken;
    address indexToken; // 160
    bool isLong; // 8
    uint8 collateralDecimals;
    bytes32[20] reserved;
}

struct OpenPositionContext {
    // parameters
    uint256 amountIn;
    uint256 sizeUsd;
    uint256 priceUsd;
    bool isMarket;
    // calculated
    uint256 fee;
    uint256 amountOut;
    uint256 gmxOrderIndex;
    uint256 executionFee;
}

struct ClosePositionContext {
    uint256 collateralUsd;
    uint256 sizeUsd;
    uint256 priceUsd;
    bool isMarket;
    uint256 gmxOrderIndex;
    uint256 executionFee;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface IGmxProxyFactory {
    
    struct OpenPositionArgs {
        uint256 exchangeId;
        address collateralToken;
        address assetToken;
        bool isLong;
        address tokenIn;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeUsd;
        uint96 priceUsd;
        uint8 flags;
        bytes32 referralCode;
    }

    struct ClosePositionArgs {
        uint256 exchangeId;
        address collateralToken;
        address assetToken;
        bool isLong;
        uint256 collateralUsd;
        uint256 sizeUsd;
        uint96 priceUsd;
        uint8 flags;
        bytes32 referralCode;
    }


    event SetReferralCode(bytes32 referralCode);
    event SetMaintainer(address maintainer, bool enable);

    function initialize(address weth_) external;
    function weth() external view returns (address);
    function implementation() external view returns(address);
    function getImplementationAddress(uint256 exchangeId) external view returns(address);
    function getProxyExchangeId(address proxy) external view returns(uint256);
    function getTradingProxy(bytes32 proxyId) external view returns(address);
    function getExchangeConfig(uint256 ExchangeId) external view returns (uint256[] memory);
    function upgradeTo(uint256 exchangeId, address newImplementation_) external;
    function setExchangeConfig(uint256 ExchangeId, uint256[] memory values) external;
    function getConfigVersions(uint256 ExchangeId) external view returns (uint32 exchangeConfigVersion);
    function setMaintainer(address maintainer, bool enable) external;
    function createProxy(uint256 exchangeId, address collateralToken, address assetToken, bool isLong) external returns (address);
    function openPosition(OpenPositionArgs calldata args) external payable;
    function closePosition(ClosePositionArgs calldata args) external payable;
    function cancelOrders(uint256 exchangeId, address collateralToken, address assetToken, bool isLong, bytes32[] calldata keys) external;
    function getPendingOrderKeys(uint256 exchangeId, address collateralToken, address assetToken, bool isLong) external view  returns(bytes32[] memory);
    function withdraw(uint256 exchangeId, address account, address collateralToken, address assetToken, bool isLong) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

library LibUtils {
    uint256 internal constant RATE_DENOMINATOR = 1e5;

    function toAddress(bytes32 value) internal pure returns (address) {
        return address(bytes20(value));
    }

    function toAddress(uint256 value) internal pure returns (address) {
        return address(bytes20(bytes32(value)));
    }

    function toU256(address value) internal pure returns (uint256) {
        return uint256(uint160(value));
    }

    function toU32(bytes32 value) internal pure returns (uint32) {
        require(uint256(value) <= type(uint32).max, "OU32");
        return uint32(uint256(value));
    }

    function toU32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "OU32");
        return uint32(value);
    }

    function toU8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "OU8");
        return uint8(value);
    }

    function toU96(uint256 n) internal pure returns (uint96) {
        require(n <= type(uint96).max, "OU96"); // uint96 Overflow
        return uint96(n);
    }

    function rate(uint256 value, uint32 rate_) internal pure returns (uint256) {
        return (value * rate_) / RATE_DENOMINATOR;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../interfaces/IGmxOrderBook.sol";
import "../../../interfaces/IGmxPositionRouter.sol";
import "../../../interfaces/IGmxVault.sol";

import "../Types.sol";

library LibGmx {
    using SafeERC20 for IERC20;

    enum OrderCategory {
        NONE,
        OPEN,
        CLOSE
    }

    enum OrderReceiver {
        PR_INC,
        PR_DEC,
        OB_INC,
        OB_DEC
    }

    struct OrderHistory {
        OrderCategory category; // 4
        OrderReceiver receiver; // 4
        uint64 index; // 64
        uint96 zero; // 96
        uint88 timestamp; // 80
    }

    function getOraclePrice(
        ExchangeConfigs storage exchangeConfigs,
        address token,
        bool useMaxPrice
    ) internal view returns (uint256 price) {
        // open long = max
        // open short = min
        // close long = min
        // close short = max
        price = useMaxPrice //isOpen == isLong
            ? IGmxVault(exchangeConfigs.vault).getMaxPrice(token)
            : IGmxVault(exchangeConfigs.vault).getMinPrice(token);
        require(price != 0, "ZeroOraclePrice");
    }

    function swap(
        ExchangeConfigs memory exchangeConfigs,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minOut
    ) internal returns (uint256 amountOut) {
        IERC20(tokenIn).safeTransfer(exchangeConfigs.vault, amountIn);
        amountOut = IGmxVault(exchangeConfigs.vault).swap(tokenIn, tokenOut, address(this));
        require(amountOut >= minOut, "AmountOutNotReached");
    }

    function getOrderIndex(ExchangeConfigs memory exchangeConfigs, OrderReceiver receiver)
        internal
        view
        returns (uint256 index)
    {
        if (receiver == OrderReceiver.PR_INC) {
            index = IGmxPositionRouter(exchangeConfigs.positionRouter).increasePositionsIndex(address(this));
        } else if (receiver == OrderReceiver.PR_DEC) {
            index = IGmxPositionRouter(exchangeConfigs.positionRouter).decreasePositionsIndex(address(this));
        } else if (receiver == OrderReceiver.OB_INC) {
            index = IGmxOrderBook(exchangeConfigs.orderBook).increaseOrdersIndex(address(this)) - 1;
        } else if (receiver == OrderReceiver.OB_DEC) {
            index = IGmxOrderBook(exchangeConfigs.orderBook).decreaseOrdersIndex(address(this)) - 1;
        }
    }

    function getOrder(ExchangeConfigs memory exchangeConfigs, bytes32 key)
        internal
        view
        returns (bool isFilled, OrderHistory memory history)
    {
        history = decodeOrderHistoryKey(key);
        if (history.receiver == OrderReceiver.PR_INC) {
            IGmxPositionRouter.IncreasePositionRequest memory request = IGmxPositionRouter(
                exchangeConfigs.positionRouter
            ).increasePositionRequests(encodeOrderKey(address(this), history.index));
            isFilled = request.account == address(0);
        } else if (history.receiver == OrderReceiver.PR_DEC) {
            IGmxPositionRouter.DecreasePositionRequest memory request = IGmxPositionRouter(
                exchangeConfigs.positionRouter
            ).decreasePositionRequests(encodeOrderKey(address(this), history.index));
            isFilled = request.account == address(0);
        } else if (history.receiver == OrderReceiver.OB_INC) {
            (address collateralToken, , , , , , , , ) = IGmxOrderBook(exchangeConfigs.orderBook).getIncreaseOrder(
                address(this),
                history.index
            );
            isFilled = collateralToken == address(0);
        } else if (history.receiver == OrderReceiver.OB_DEC) {
            (address collateralToken, , , , , , , ) = IGmxOrderBook(exchangeConfigs.orderBook).getDecreaseOrder(
                address(this),
                history.index
            );
            isFilled = collateralToken == address(0);
        } else {
            revert();
        }
    }

    function cancelOrderFromPositionRouter(address positionRouter, bytes32 key) internal returns (bool success) {
        OrderHistory memory history = decodeOrderHistoryKey(key);
        success = false;
        if (history.receiver == OrderReceiver.PR_INC) {
            try
                IGmxPositionRouter(positionRouter).cancelIncreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        } else if (history.receiver == OrderReceiver.PR_DEC) {
            try
                IGmxPositionRouter(positionRouter).cancelDecreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        }
    }

    function cancelOrderFromOrderBook(address orderBook, bytes32 key) internal returns (bool success) {
        OrderHistory memory history = decodeOrderHistoryKey(key);
        success = false;
        if (history.receiver == OrderReceiver.OB_INC) {
            try IGmxOrderBook(orderBook).cancelIncreaseOrder(history.index) {
                success = true;
            } catch {}
        } else if (history.receiver == OrderReceiver.OB_DEC) {
            try IGmxOrderBook(orderBook).cancelDecreaseOrder(history.index) {
                success = true;
            } catch {}
        }
    }

    function cancelOrder(ExchangeConfigs memory exchangeConfigs, bytes32 key) internal returns (bool success) {
        OrderHistory memory history = decodeOrderHistoryKey(key);
        success = false;
        if (history.receiver == OrderReceiver.PR_INC) {
            try
                IGmxPositionRouter(exchangeConfigs.positionRouter).cancelIncreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        } else if (history.receiver == OrderReceiver.PR_DEC) {
            try
                IGmxPositionRouter(exchangeConfigs.positionRouter).cancelDecreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        } else if (history.receiver == OrderReceiver.OB_INC) {
            try IGmxOrderBook(exchangeConfigs.orderBook).cancelIncreaseOrder(history.index) {
                success = true;
            } catch {}
        } else if (history.receiver == OrderReceiver.OB_DEC) {
            try IGmxOrderBook(exchangeConfigs.orderBook).cancelDecreaseOrder(history.index) {
                success = true;
            } catch {}
        } else {
            revert();
        }
    }

    function getPnl(
        ExchangeConfigs memory exchangeConfigs,
        address indexToken,
        uint256 size,
        uint256 averagePriceUsd,
        bool isLong,
        uint256 priceUsd,
        uint256 lastIncreasedTime
    ) internal view returns (bool, uint256) {
        require(priceUsd > 0, "");
        uint256 priceDelta = averagePriceUsd > priceUsd ? averagePriceUsd - priceUsd : priceUsd - averagePriceUsd;
        uint256 delta = (size * priceDelta) / averagePriceUsd;
        bool hasProfit;
        if (isLong) {
            hasProfit = priceUsd > averagePriceUsd;
        } else {
            hasProfit = averagePriceUsd > priceUsd;
        }
        uint256 minProfitTime = IGmxVault(exchangeConfigs.vault).minProfitTime();
        uint256 minProfitBasisPoints = IGmxVault(exchangeConfigs.vault).minProfitBasisPoints(indexToken);
        uint256 minBps = block.timestamp > lastIncreasedTime + minProfitTime ? 0 : minProfitBasisPoints;
        if (hasProfit && delta * 10000 <= size * minBps) {
            delta = 0;
        }
        return (hasProfit, delta);
    }

    function encodeOrderKey(address account, uint256 index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, index));
    }

    function decodeOrderHistoryKey(bytes32 key) internal pure returns (OrderHistory memory history) {
        //            252          248                184          88           0
        // +------------+------------+------------------+-----------+-----------+
        // | category 4 | receiver 4 | gmxOrderIndex 64 |    0   96 |  time 88  |
        // +------------+------------+------------------+-----------+-----------+
        history.category = OrderCategory(uint8(bytes1(key)) >> 4);
        history.receiver = OrderReceiver(uint8(bytes1(key)) & 0x0f);
        history.index = uint64(bytes8(key << 8));
        history.zero = uint96(uint256(key >> 88));
        history.timestamp = uint88(uint256(key));
    }

    function encodeOrderHistoryKey(
        OrderCategory category,
        OrderReceiver receiver,
        uint256 index,
        uint256 timestamp
    ) internal pure returns (bytes32 data) {
        //            252          248                184          88           0
        // +------------+------------+------------------+-----------+-----------+
        // | category 4 | receiver 4 | gmxOrderIndex 64 |    0   96 |  time 88  |
        // +------------+------------+------------------+-----------+-----------+
        require(index < type(uint64).max, "GmxOrderIndexOverflow");
        require(timestamp < type(uint88).max, "FeeOverflow");
        data =
            bytes32(uint256(category) << 252) | // 256 - 4
            bytes32(uint256(receiver) << 248) | // 256 - 4 - 4
            bytes32(uint256(index) << 184) | // 256 - 4 - 4 - 64
            bytes32(uint256(0) << 88) | // 256 - 4 - 4 - 64 - 96
            bytes32(uint256(timestamp));
    }

    function encodeTpslIndex(bytes32 tpOrderKey, bytes32 slOrderKey) internal pure returns (bytes32) {
        //            252          248                184
        // +------------+------------+------------------+
        // | category 4 | receiver 4 | gmxOrderIndex 64 |
        // +------------+------------+------------------+
        // store head of orderkey without timestamp, since tpsl orders should have the same timestamp as the open order.
        return bytes32(bytes9(tpOrderKey)) | (bytes32(bytes9(slOrderKey)) >> 128);
    }

    function decodeTpslIndex(
        bytes32 orderKey,
        bytes32 tpslIndex
    ) internal pure returns (bytes32 tpOrderKey, bytes32 slOrderKey) {
        bytes32 timestamp = bytes32(uint256(uint88(uint256(orderKey))));
        // timestamp of all tpsl orders (main +tp +sl) are same
        tpOrderKey = bytes32(bytes16(tpslIndex));
        tpOrderKey = tpOrderKey != bytes32(0) ? tpOrderKey | timestamp : tpOrderKey;
        slOrderKey = (tpslIndex << 128);
        slOrderKey = slOrderKey != bytes32(0) ? slOrderKey | timestamp : slOrderKey;
    }

    function getPrExecutionFee(ExchangeConfigs memory exchangeConfigs) internal view returns (uint256) {
        return IGmxPositionRouter(exchangeConfigs.positionRouter).minExecutionFee();
    }

    function getObExecutionFee(ExchangeConfigs memory exchangeConfigs) internal view returns (uint256) {
        return IGmxOrderBook(exchangeConfigs.orderBook).minExecutionFee() + 1;
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
pragma solidity 0.8.19;

interface IGmxOrderBook {
    event CreateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );

    function minExecutionFee() external view returns (uint256);

    function getIncreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function increaseOrdersIndex(address account) external view returns (uint256);

    function decreaseOrdersIndex(address account) external view returns (uint256);

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function executeDecreaseOrder(address, uint256, address payable) external;

    function executeIncreaseOrder(address, uint256, address payable) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
    }

    struct DecreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
    }

    function setPositionKeeper(address _account, bool _isActive) external;

    function increasePositionRequests(bytes32) external view returns (IncreasePositionRequest memory);

    function decreasePositionRequests(bytes32) external view returns (DecreasePositionRequest memory);

    function minExecutionFee() external view returns (uint256);

    function increasePositionsIndex(address account) external view returns (uint256);

    function decreasePositionsIndex(address account) external view returns (uint256);

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
    ) external payable returns (bytes32);

    function cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool); // callback

    function cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool); // callback

    function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGmxVault {
    struct Position {
        uint256 sizeUsd;
        uint256 collateralUsd;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnlUsd;
        uint256 lastIncreasedTime;
    }

    event BuyUSDG(address account, address token, uint256 tokenAmount, uint256 usdgAmount, uint256 feeBasisPoints);
    event SellUSDG(address account, address token, uint256 usdgAmount, uint256 tokenAmount, uint256 feeBasisPoints);
    event Swap(
        address account,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutAfterFees,
        uint256 feeBasisPoints
    );

    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );

    event UpdateFundingRate(address token, uint256 fundingRate);
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);

    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);

    event DirectPoolDeposit(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseUsdgAmount(address token, uint256 amount);
    event DecreaseUsdgAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        uint256 _lastIncreasedTime
    ) external view returns (uint256);

    function positions(bytes32 key) external view returns (Position memory);

    /**
     * [0] size,
     * [1] collateral,
     * [2] averagePrice,
     * [3] entryFundingRate,
     * [4] reserveAmount,
     * [5] realisedPnl,
     * [6] realisedPnl >= 0,
     * [7] lastIncreasedTime
     */
    function getPosition(
        address account,
        address collateralToken,
        address indexToken,
        bool isLong
    )
        external
        view
        returns (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            uint256 reserveAmount,
            uint256 realisedPnl,
            bool hasRealisedPnl,
            uint256 lastIncreasedTime
        );

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function usdgAmounts(address) external view returns (uint256);

    function tokenWeights(address) external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function priceFeed() external view returns (address);

    function poolAmounts(address token) external view returns (uint256);

    function bufferAmounts(address token) external view returns (uint256);

    function reservedAmounts(address token) external view returns (uint256);

    function getRedemptionAmount(address token, uint256 usdgAmount) external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function minProfitBasisPoints(address token) external view returns (uint256);

    function maxUsdgAmounts(address token) external view returns (uint256);

    function globalShortSizes(address token) external view returns (uint256);

    function maxGlobalShortSizes(address token) external view returns (uint256);

    function guaranteedUsd(address token) external view returns (uint256);

    function stableTokens(address token) external view returns (bool);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address token) external view returns (uint256);

    function getNextFundingRate(address token) external view returns (uint256);

    function getEntryFundingRate(
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function gov() external view returns (address);

    function setLiquidator(address, bool) external;
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