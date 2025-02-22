// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ILendingVault {

  /* ========== STRUCTS ========== */

  struct Borrower {
    // Boolean for whether borrower is approved to borrow from this vault
    bool approved;
    // Debt share of the borrower in this vault
    uint256 debt;
    // The last timestamp borrower borrowed from this vault
    uint256 lastUpdatedAt;
  }

  struct InterestRate {
    // Base interest rate which is the y-intercept when utilization rate is 0 in 1e18
    uint256 baseRate;
    // Multiplier of utilization rate that gives the slope of the interest rate in 1e18
    uint256 multiplier;
    // Multiplier after hitting a specified utilization point (kink2) in 1e18
    uint256 jumpMultiplier;
    // Utilization point at which the interest rate is fixed in 1e18
    uint256 kink1;
    // Utilization point at which the jump multiplier is applied in 1e18
    uint256 kink2;
  }

  function totalAsset() external view returns (uint256);
  function totalAvailableAsset() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function lvTokenValue() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address borrower) external view returns (uint256);
  function depositNative(uint256 assetAmt, uint256 minSharesAmt) payable external;
  function deposit(uint256 assetAmt, uint256 minSharesAmt) external;
  function withdraw(uint256 sharesAmt, uint256 minAssetAmt) external;
  function borrow(uint256 assetAmt) external;
  function repay(uint256 repayAmt) external;
  function withdrawReserve(uint256 assetAmt) external;
  function updatePerformanceFee(uint256 newPerformanceFee) external;
  function updateInterestRate(InterestRate memory newInterestRate) external;
  function approveBorrower(address borrower) external;
  function revokeBorrower(address borrower) external;
  function updateKeeper(address keeper, bool approval) external;
  function emergencyRepay(uint256 repayAmt, address defaulter) external;
  function emergencyShutdown() external;
  function emergencyResume() external;
  function updateMaxCapacity(uint256 newMaxCapacity) external;
  function updateTreasury(address newTreasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IChainlinkOracle {
  function consult(address token) external view returns (int256 price, uint8 decimals);
  function consultIn18Decimals(address token) external view returns (uint256 price);
  function addTokenPriceFeed(address token, address feed) external;
  function addTokenMaxDelay(address token, uint256 maxDelay) external;
  function addTokenMaxDeviation(address token, uint256 maxDeviation) external;
  function emergencyPause() external;
  function emergencyResume() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IGMXOracle {
  struct MarketPoolValueInfoProps {
    int256 poolValue;
    int256 longPnl;
    int256 shortPnl;
    int256 netPnl;

    uint256 longTokenAmount;
    uint256 shortTokenAmount;
    uint256 longTokenUsd;
    uint256 shortTokenUsd;

    uint256 totalBorrowingFees;
    uint256 borrowingFeePoolFactor;

    uint256 impactPoolAmount;
  }

  function getAmountsOut(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenIn,
    uint256 amountIn
  ) external view returns (uint256);

  function getAmountsIn(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenOut,
    uint256 amountsOut
  ) external view returns (uint256);

  function getMarketTokenInfo(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bytes32 pnlFactorType,
    bool maximize
  ) external view returns (
    int256,
    MarketPoolValueInfoProps memory
  );

  function getLpTokenReserves(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken
  ) external view returns (uint256, uint256);

  function getLpTokenValue(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) external view returns (uint256);

  function getLpTokenAmount(
    uint256 givenValue,
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDeposit {
  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the account depositing liquidity
  // @param receiver the address to send the liquidity tokens to
  // @param callbackContract the callback contract
  // @param uiFeeReceiver the ui fee receiver
  // @param market the market to deposit to
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialLongToken;
    address initialShortToken;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
  }

  // @param initialLongTokenAmount the amount of long tokens to deposit
  // @param initialShortTokenAmount the amount of short tokens to deposit
  // @param minMarketTokens the minimum acceptable number of liquidity tokens
  // @param updatedAtBlock the block that the deposit was last updated at
  // sending funds back to the user in case the deposit gets cancelled
  // @param executionFee the execution fee for keepers
  // @param callbackGasLimit the gas limit for the callbackContract
  struct Numbers {
    uint256 initialLongTokenAmount;
    uint256 initialShortTokenAmount;
    uint256 minMarketTokens;
    uint256 updatedAtBlock;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  // @param shouldUnwrapNativeToken whether to unwrap the native token when
  struct Flags {
    bool shouldUnwrapNativeToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IDeposit.sol";
import "./IEvent.sol";

// @title IDepositCallbackReceiver
// @dev interface for a deposit callback contract
interface IDepositCallbackReceiver {
  // @dev called after a deposit execution
  // @param key the key of the deposit
  // @param deposit the deposit that was executed
  function afterDepositExecution(
    bytes32 key,
    IDeposit.Props memory deposit,
    IEvent.Props memory eventData
  ) external;

  // @dev called after a deposit cancellation
  // @param key the key of the deposit
  // @param deposit the deposit that was cancelled
  function afterDepositCancellation(
    bytes32 key,
    IDeposit.Props memory deposit,
    IEvent.Props memory eventData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IEvent {
  struct Props {
    AddressItems addressItems;
    UintItems uintItems;
    IntItems intItems;
    BoolItems boolItems;
    Bytes32Items bytes32Items;
    BytesItems bytesItems;
    StringItems stringItems;
  }

  struct AddressItems {
    AddressKeyValue[] items;
    AddressArrayKeyValue[] arrayItems;
  }

  struct UintItems {
    UintKeyValue[] items;
    UintArrayKeyValue[] arrayItems;
  }

  struct IntItems {
    IntKeyValue[] items;
    IntArrayKeyValue[] arrayItems;
  }

  struct BoolItems {
    BoolKeyValue[] items;
    BoolArrayKeyValue[] arrayItems;
  }

  struct Bytes32Items {
    Bytes32KeyValue[] items;
    Bytes32ArrayKeyValue[] arrayItems;
  }

  struct BytesItems {
    BytesKeyValue[] items;
    BytesArrayKeyValue[] arrayItems;
  }

  struct StringItems {
    StringKeyValue[] items;
    StringArrayKeyValue[] arrayItems;
  }

  struct AddressKeyValue {
    string key;
    address value;
  }

  struct AddressArrayKeyValue {
    string key;
    address[] value;
  }

  struct UintKeyValue {
    string key;
    uint256 value;
  }

  struct UintArrayKeyValue {
    string key;
    uint256[] value;
  }

  struct IntKeyValue {
    string key;
    int256 value;
  }

  struct IntArrayKeyValue {
    string key;
    int256[] value;
  }

  struct BoolKeyValue {
    string key;
    bool value;
  }

  struct BoolArrayKeyValue {
    string key;
    bool[] value;
  }

  struct Bytes32KeyValue {
    string key;
    bytes32 value;
  }

  struct Bytes32ArrayKeyValue {
    string key;
    bytes32[] value;
  }

  struct BytesKeyValue {
    string key;
    bytes value;
  }

  struct BytesArrayKeyValue {
    string key;
    bytes[] value;
  }

  struct StringKeyValue {
    string key;
    string value;
  }

  struct StringArrayKeyValue {
    string key;
    string[] value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IExchangeRouter {
  struct CreateDepositParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialLongToken;
    address initialShortToken;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minMarketTokens;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  struct CreateWithdrawalParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  struct CreateOrderParams {
    CreateOrderParamsAddresses addresses;
    CreateOrderParamsNumbers numbers;
    OrderType orderType;
    DecreasePositionSwapType decreasePositionSwapType;
    bool isLong;
    bool shouldUnwrapNativeToken;
    bytes32 referralCode;
  }

  struct CreateOrderParamsAddresses {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialCollateralToken;
    address[] swapPath;
  }

  struct CreateOrderParamsNumbers {
    uint256 sizeDeltaUsd;
    uint256 initialCollateralDeltaAmount;
    uint256 triggerPrice;
    uint256 acceptablePrice;
    uint256 executionFee;
    uint256 callbackGasLimit;
    uint256 minOutputAmount;
  }

  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  function sendWnt(address receiver, uint256 amount) external payable;

  function sendTokens(
    address token,
    address receiver,
    uint256 amount
  ) external payable;

  function createDeposit(
    CreateDepositParams calldata params
  ) external payable returns (bytes32);

  function createWithdrawal(
    CreateWithdrawalParams calldata params
  ) external payable returns (bytes32);

  function createOrder(
    CreateOrderParams calldata params
  ) external payable returns (bytes32);

  // function cancelDeposit(bytes32 key) external payable;

  // function cancelWithdrawal(bytes32 key) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOrder {
  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  // to help further differentiate orders
  enum SecondaryOrderType {
    None,
    Adl
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the account of the order
  // @param receiver the receiver for any token transfers
  // this field is meant to allow the output of an order to be
  // received by an address that is different from the creator of the
  // order whether this is for swaps or whether the account is the owner
  // of a position
  // for funding fees and claimable collateral, the funds are still
  // credited to the owner of the position indicated by order.account
  // @param callbackContract the contract to call for callbacks
  // @param uiFeeReceiver the ui fee receiver
  // @param market the trading market
  // @param initialCollateralToken for increase orders, initialCollateralToken
  // is the token sent in by the user, the token will be swapped through the
  // specified swapPath, before being deposited into the position as collateral
  // for decrease orders, initialCollateralToken is the collateral token of the position
  // withdrawn collateral from the decrease of the position will be swapped
  // through the specified swapPath
  // for swaps, initialCollateralToken is the initial token sent for the swap
  // @param swapPath an array of market addresses to swap through
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialCollateralToken;
    address[] swapPath;
  }

  // @param sizeDeltaUsd the requested change in position size
  // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
  // is the amount of the initialCollateralToken sent in by the user
  // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
  // collateralToken to withdraw
  // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
  // in for the swap
  // @param orderType the order type
  // @param triggerPrice the trigger price for non-market orders
  // @param acceptablePrice the acceptable execution price for increase / decrease orders
  // @param executionFee the execution fee for keepers
  // @param callbackGasLimit the gas limit for the callbackContract
  // @param minOutputAmount the minimum output amount for decrease orders and swaps
  // note that for decrease orders, multiple tokens could be received, for this reason, the
  // minOutputAmount value is treated as a USD value for validation in decrease orders
  // @param updatedAtBlock the block at which the order was last updated
  struct Numbers {
    OrderType orderType;
    DecreasePositionSwapType decreasePositionSwapType;
    uint256 sizeDeltaUsd;
    uint256 initialCollateralDeltaAmount;
    uint256 triggerPrice;
    uint256 acceptablePrice;
    uint256 executionFee;
    uint256 callbackGasLimit;
    uint256 minOutputAmount;
    uint256 updatedAtBlock;
  }

  // @param isLong whether the order is for a long or short
  // @param shouldUnwrapNativeToken whether to unwrap native tokens before
  // transferring to the user
  // @param isFrozen whether the order is frozen
  struct Flags {
    bool isLong;
    bool shouldUnwrapNativeToken;
    bool isFrozen;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IOrder.sol";
import "./IEvent.sol";

// @title IOrderCallbackReceiver
// @dev interface for an order callback contract
interface IOrderCallbackReceiver {
  // @dev called after an order execution
  // @param key the key of the order
  // @param order the order that was executed
  function afterOrderExecution(
    bytes32 key,
    IOrder.Props memory order,
    IEvent.Props memory eventData
  ) external;

  // @dev called after an order cancellation
  // @param key the key of the order
  // @param order the order that was cancelled
  function afterOrderCancellation(
    bytes32 key,
    IOrder.Props memory order,
    IEvent.Props memory eventData
  ) external;

  // @dev called after an order has been frozen, see OrderUtils.freezeOrder in OrderHandler for more info
  // @param key the key of the order
  // @param order the order that was frozen
  function afterOrderFrozen(
    bytes32 key,
    IOrder.Props memory order,
    IEvent.Props memory eventData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IRoleStore {
  function hasRole(address account, bytes32 roleKey) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWithdrawal {
  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account The account to withdraw for.
  // @param receiver The address that will receive the withdrawn tokens.
  // @param callbackContract The contract that will be called back.
  // @param uiFeeReceiver The ui fee receiver.
  // @param market The market on which the withdrawal will be executed.
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
  }

  // @param marketTokenAmount The amount of market tokens that will be withdrawn.
  // @param minLongTokenAmount The minimum amount of long tokens that must be withdrawn.
  // @param minShortTokenAmount The minimum amount of short tokens that must be withdrawn.
  // @param updatedAtBlock The block at which the withdrawal was last updated.
  // @param executionFee The execution fee for the withdrawal.
  // @param callbackGasLimit The gas limit for calling the callback contract.
  struct Numbers {
    uint256 marketTokenAmount;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    uint256 updatedAtBlock;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  // @param shouldUnwrapNativeToken whether to unwrap the native token when
  struct Flags {
    bool shouldUnwrapNativeToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IWithdrawal.sol";
import "./IEvent.sol";

// @title IWithdrawalCallbackReceiver
// @dev interface for a withdrawal callback contract
interface IWithdrawalCallbackReceiver {
  // @dev called after a withdrawal execution
  // @param key the key of the withdrawal
  // @param withdrawal the withdrawal that was executed
  function afterWithdrawalExecution(
    bytes32 key,
    IWithdrawal.Props memory withdrawal,
    IEvent.Props memory eventData
  ) external;

  // @dev called after a withdrawal cancellation
  // @param key the key of the withdrawal
  // @param withdrawal the withdrawal that was cancelled
  function afterWithdrawalCancellation(
    bytes32 key,
    IWithdrawal.Props memory withdrawal,
    IEvent.Props memory eventData
) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { GMXTypes } from  "../../../strategy/gmx/GMXTypes.sol";

interface IGMXVault {
  function store() external view returns (GMXTypes.Store memory);
  function isTokenWhitelisted(address token) external view returns (bool);

  function deposit(GMXTypes.DepositParams memory dp) payable external;
  function depositNative(GMXTypes.DepositParams memory dp) payable external;
  function processMint(bytes32 depositKey) payable external;

  function withdraw(GMXTypes.WithdrawParams memory wp) payable external;
  function processSwapForRepay(bytes32 orderKey) external;
  function processRepay(bytes32 withdrawKey, bytes32 orderKey) external;
  function processSwapForWithdraw(bytes32 orderKey) external;
  function processBurn(bytes32 withdrawKey, bytes32 orderKey) payable external;

  function emergencyWithdraw(GMXTypes.WithdrawParams memory wp) external;
  function mintMgmtFee() external;

  function compound(GMXTypes.CompoundParams memory cp) payable external;
  function processCompoundAdd(bytes32 orderKey) external;
  function processCompoundAdded(bytes32 depositKey) payable external;

  function rebalanceAdd(GMXTypes.RebalanceAddParams memory rebalanceAddParams) payable external;
  function processRebalanceAdd(bytes32 depositKey) payable external;

  function rebalanceRemove(GMXTypes.RebalanceRemoveParams memory rebalanceRemoveParams) payable external;
  function processRebalanceRemoveSwapForRepay(bytes32 withdrawKey) external;
  function processRebalanceRemoveRepay(bytes32 withdrawKey, bytes32 swapKey) external;
  function processRebalanceRemoveAddLiquidity(bytes32 depositKey) payable external;

  function emergencyShutdown() payable external;
  function emergencyResume() payable external;

  function pause() external;
  function unpause() external;

  function updateKeeper(address keeper, bool approval) external;
  function updateTreasury(address treasury) external;
  function updateQueue(address queue) external;
  function updateCallback(address callback) external;
  function updateMgmtFeePerSecond(uint256 mgmtFeePerSecond) external;
  function updatePerformanceFee(uint256 performanceFee) external;
  function updateMaxCapacity(uint256 maxCapacity) external;
  function mint(address to, uint256 amt) external;
  function burn(address to, uint256 amt) external;

  function updateInvariants(
    uint256 debtRatioStepThreshold,
    uint256 deltaStepThreshold,
    uint256 debtRatioUpperLimit,
    uint256 debtRatioLowerLimit,
    int256 deltaUpperLimit,
    int256 deltaLowerLimit
  ) external;

  function updateMinExecutionFee(uint256 minExecutionFee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWNT {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IDeposit } from "../../interfaces/protocols/gmx/IDeposit.sol";
import { IWithdrawal } from "../../interfaces/protocols/gmx/IWithdrawal.sol";
import { IEvent } from "../../interfaces/protocols/gmx/IEvent.sol";
import { IOrder } from "../../interfaces/protocols/gmx/IOrder.sol";
import { IDepositCallbackReceiver } from "../../interfaces/protocols/gmx/IDepositCallbackReceiver.sol";
import { IWithdrawalCallbackReceiver } from "../../interfaces/protocols/gmx/IWithdrawalCallbackReceiver.sol";
import { IOrderCallbackReceiver } from "../../interfaces/protocols/gmx/IOrderCallbackReceiver.sol";
import { IRoleStore } from "../../interfaces/protocols/gmx/IRoleStore.sol";
import { IGMXVault } from "../../interfaces/strategy/gmx/IGMXVault.sol";
import { Errors } from "../../utils/Errors.sol";
import { GMXTypes } from "./GMXTypes.sol";

contract GMXCallback is IDepositCallbackReceiver, IWithdrawalCallbackReceiver, IOrderCallbackReceiver {

  /* ========== STATE VARIABLES ========== */

  // Vault address
  IGMXVault public vault;
  // GMX role store address
  IRoleStore public roleStore;

  // TEMP
  address public handler;
  uint256 public timestamp;
  bytes32 public key;

  /* ========== MODIFIERS ========== */

  modifier onlyController() {
    if (!roleStore.hasRole(msg.sender, keccak256(abi.encode("CONTROLLER")))) {
      revert Errors.InvalidCallbackHandler();
    } else {
      _;
    }
  }

  /* ========== CONSTRUCTOR ========== */

  /**
    * @dev Initialize callback contract with associated vault address
    * @param _vault Address of vault contract
  */
  constructor (address _vault) {
    vault = IGMXVault(_vault);
    roleStore = IRoleStore(vault.store().roleStore);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function viewStatus() external view returns (GMXTypes.Status) {
    return vault.store().status;
  }

  function viewStore() external view returns (GMXTypes.Store memory) {
    return vault.store();
  }

  /**
    * @dev Process vault after successful deposit execution from GMX
    * @notice Callback function for GMX handler to call or approved keepers
    * @param depositKey bytes32 depositKey hash of deposit created
    * @param depositProps IDeposit.Props
    * @param eventData IEvent.Props
  */
  function afterDepositExecution(
    bytes32 depositKey,
    IDeposit.Props memory depositProps,
    IEvent.Props memory eventData
  ) external onlyController {

    GMXTypes.Store memory _store = vault.store();

    key = depositKey;
    handler = msg.sender;
    timestamp = block.timestamp;

    _afterDepositCallbackChecks(
      depositKey,
      depositProps,
      eventData
    );

    if (_store.status == GMXTypes.Status.Mint) {
      vault.processMint(depositKey);
    } else if (_store.status == GMXTypes.Status.Rebalance_Add_Add_Liquidity) {
      vault.processRebalanceAdd(depositKey);
    } else if (_store.status == GMXTypes.Status.Compound_Liquidity_Added) {
      vault.processCompoundAdded(depositKey);
    }
  }

  /**
    * @dev Process vault after deposit cancellation from GMX
    * @notice Callback function for GMX handler to call or approved keepers
    * @param depositKey bytes32 depositKey hash of deposit created
    * @param depositProps IDeposit.Props
    * @param eventData IEvent.Props
  */
  function afterDepositCancellation(
    bytes32 depositKey,
    IDeposit.Props memory depositProps,
    IEvent.Props memory eventData
  ) external onlyController {
    GMXTypes.Store memory _store = vault.store();

    key = depositKey;
    handler = msg.sender;
    timestamp = block.timestamp;

    _afterDepositCallbackChecks(
      depositKey,
      depositProps,
      eventData
    );

    // TODO
    // GMXDeposit.afterDepositCancellation(_store, depositKey);
  }

  /**
    * @dev Process vault after successful withdrawal execution from GMX
    * @notice Callback function for GMX handler to call or approved keepers
    * @param withdrawKey bytes32 depositKey hash of withdrawal created
    * @param withdrawProps IWithdrawal.Props
    * @param eventData IEvent.Props
  */
  function afterWithdrawalExecution(
    bytes32 withdrawKey,
    IWithdrawal.Props memory withdrawProps,
    IEvent.Props memory eventData
  ) external onlyController {
    GMXTypes.Store memory _store = vault.store();

    key = withdrawKey;
    handler = msg.sender;
    timestamp = block.timestamp;

    _afterWithdrawalCallbackChecks(
      withdrawKey,
      withdrawProps,
      eventData
    );

    if (_store.status == GMXTypes.Status.Swap_For_Repay) {
      vault.processSwapForRepay(withdrawKey);
    } else if (_store.status == GMXTypes.Status.Rebalance_Remove_Swap_For_Repay) {
      vault.processRebalanceRemoveSwapForRepay(withdrawKey);
    }
  }

  /**
    * @dev Process vault after withdrawal cancellation from GMX
    * @notice Callback function for GMX handler to call or approved keepers
    * @param withdrawKey bytes32 withdrawalKey hash of withdrawal created
    * @param withdrawProps IWithdrawal.Props
    * @param eventData IEvent.Props
  */
  function afterWithdrawalCancellation(
    bytes32 withdrawKey,
    IWithdrawal.Props memory withdrawProps,
    IEvent.Props memory eventData
  ) external {
    GMXTypes.Store memory _store = vault.store();

    key = withdrawKey;
    handler = msg.sender;
    timestamp = block.timestamp;

    _afterWithdrawalCallbackChecks(
      withdrawKey,
      withdrawProps,
      eventData
    );

    // TODO
    // GMXWithdraw.afterWithdrawalCancellation(_store, withdrawKey);
  }

  /**
    * @dev Process vault after successful order execution from GMX
    * @notice Callback function for GMX handler to call or approved keepers
    * @param orderKey bytes32 orderKey hash of order created
    * @param orderProps IOrder.Props
    * @param eventData IEvent.Props
  */
  function afterOrderExecution(
    bytes32 orderKey,
    IOrder.Props memory orderProps,
    IEvent.Props memory eventData
  ) external {
    GMXTypes.Store memory _store = vault.store();

    key = orderKey;
    handler = msg.sender;
    timestamp = block.timestamp;

    _afterOrderCallbackChecks(
      orderKey,
      orderProps,
      eventData
    );

    if (_store.status == GMXTypes.Status.Repay) {
      vault.processRepay(_store.withdrawCache.withdrawKey, orderKey);
    } else if (_store.status == GMXTypes.Status.Burn) {
      vault.processBurn(_store.withdrawCache.withdrawKey, orderKey);
    } else if (_store.status == GMXTypes.Status.Rebalance_Remove_Repay) {
      vault.processBurn(_store.rebalanceRemoveCache.withdrawKey, orderKey);
    } else if (_store.status == GMXTypes.Status.Compound_Add_Liquidity) {
      vault.processCompoundAdd(orderKey);
    }
  }

  /**
    * @dev Process vault after order cancellation from GMX
    * @notice Callback function for GMX handler to call or approved keepers
    * @param orderKey bytes32 orderKey hash of order created
    * @param orderProps IOrder.Props
    * @param eventData IEvent.Props
  */
  function afterOrderCancellation(
    bytes32 orderKey,
    IOrder.Props memory orderProps,
    IEvent.Props memory eventData
  ) external {
    GMXTypes.Store memory _store = vault.store();

    key = orderKey;
    handler = msg.sender;
    timestamp = block.timestamp;

    _afterOrderCallbackChecks(
      orderKey,
      orderProps,
      eventData
    );

    // TODO
    // GMXWithdraw.afterOrderCancellation(_store, orderKey, order, eventData);
  }

  /**
    * @dev Process vault after order is considered frozen from GMX
    * @notice Callback function for GMX handler to call or approved keepers
    * @param orderKey bytes32 orderKey hash of order created
    * @param orderProps IOrder.Props
    * @param eventData IEvent.Props
  */
  function afterOrderFrozen(
    bytes32 orderKey,
    IOrder.Props memory orderProps,
    IEvent.Props memory eventData
  ) external {
    GMXTypes.Store memory _store = vault.store();

    key = orderKey;
    handler = msg.sender;
    timestamp = block.timestamp;

    _afterOrderCallbackChecks(
      orderKey,
      orderProps,
      eventData
    );

    // TODO
    // GMXWithdraw.afterOrderFrozen(_store, orderKey, order, eventData);
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    * @dev Checks after deposit callbacks from GMX handler
    * @param depositKey bytes32 depositKey hash of deposit created
    * @param depositProps IDeposit.Props
    * @param eventData IEvent.Props
  */
  function _afterDepositCallbackChecks(
    bytes32 depositKey,
    IDeposit.Props memory depositProps,
    IEvent.Props memory eventData
  ) internal {
    GMXTypes.Store memory _store = vault.store();

    if (
      _store.status != GMXTypes.Status.Mint &&
      _store.status != GMXTypes.Status.Rebalance_Add_Add_Liquidity &&
      _store.status != GMXTypes.Status.Compound_Liquidity_Added
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @dev Checks after withdrawal callbacks from GMX handler
    * @param withdrawKey bytes32 withdrawKey hash of withdraw created
    * @param withdrawProps IWithdrawal.Props
    * @param eventData IEvent.Props
  */
  function _afterWithdrawalCallbackChecks(
    bytes32 withdrawKey,
    IWithdrawal.Props memory withdrawProps,
    IEvent.Props memory eventData
  ) internal view {
    GMXTypes.Store memory _store = vault.store();

    if (
      _store.status != GMXTypes.Status.Swap_For_Repay &&
      _store.status != GMXTypes.Status.Rebalance_Remove_Remove_Liquidity
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @dev Checks after order callbacks from GMX handler
    * @param orderKey bytes32 orderKey hash of order created
    * @param orderProps IOrder.Props
    * @param eventData IEvent.Props
  */
  function _afterOrderCallbackChecks(
    bytes32 orderKey,
    IOrder.Props memory orderProps,
    IEvent.Props memory eventData
  ) internal view {
    GMXTypes.Store memory _store = vault.store();

    if (
      _store.status != GMXTypes.Status.Repay &&
      _store.status != GMXTypes.Status.Swap_For_Withdraw &&
      _store.status != GMXTypes.Status.Rebalance_Remove_Swap_For_Repay &&
      _store.status != GMXTypes.Status.Compound_Add_Liquidity
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWNT } from "../../interfaces/tokens/IWNT.sol";
import { ILendingVault } from "../../interfaces/lending/ILendingVault.sol";
import { IGMXVault } from "../../interfaces/strategy/gmx/IGMXVault.sol";
import { IChainlinkOracle } from "../../interfaces/oracles/IChainlinkOracle.sol";
import { IGMXOracle } from "../../interfaces/oracles/IGMXOracle.sol";
import { IExchangeRouter } from "../../interfaces/protocols/gmx/IExchangeRouter.sol";

library GMXTypes {

  /* ========== STRUCTS ========== */

  struct Store {
    // Target leverage of the vault in 1e18
    uint256 leverage;
    // Delta strategy
    Delta delta;
    // Management fee per second in % in 1e18
    uint256 mgmtFeePerSecond;
    // Performance fee in % in 1e18
    uint256 performanceFee;
    // Max capacity of vault in USD value in 1e18
    uint256 maxCapacity;
    // Treasury address
    address treasury;

    // Invariant: threshold for debtRatio change after deposit/withdraw
    uint256 debtRatioStepThreshold; // in 1e4; e.g. 500 = 5%
    // Invariant: threshold for delta change after deposit/withdraw
    uint256 deltaStepThreshold; // in 1e4; e.g. 500 = 5%
    // Invariant: upper limit of debt ratio after rebalance
    uint256 debtRatioUpperLimit; // in 1e4; e.g. 6900 = 0.69
    // Invariant: lower limit of debt ratio after rebalance
    uint256 debtRatioLowerLimit; // in 1e4; e.g. 6100 = 0.61
    // Invariant: upper limit of delta after rebalance
    int256 deltaUpperLimit; // in 1e4; e.g. 10500 = 1.05
    // Invariant: lower limit of delta after rebalance
    int256 deltaLowerLimit; // in 1e4; e.g. 9500 = 0.95
    // Minimum execution fee required
    uint256 minExecutionFee; // in 1e18

    // Token A in this strategy; long token + index token
    IERC20 tokenA;
    // Token B in this strategy; short token
    IERC20 tokenB;
    // LP token of this strategy; market token
    IERC20 lpToken;
    // Native token for this chain (e.g. WETH, WAVAX, WBNB, etc.)
    IWNT WNT;

    // Token A lending vault
    ILendingVault tokenALendingVault;
    // Token B lending vault
    ILendingVault tokenBLendingVault;

    // Vault address
    IGMXVault vault;
    // Queue contract address; if address(0) it means there is no queue enabled
    address queue;
    // Callback contract address; if address(0) it means there is no callback enabled
    address callback;

    // Chainlink Oracle contract address
    IChainlinkOracle chainlinkOracle;
    // GMX Oracle contract address
    IGMXOracle gmxOracle;

    // GMX exchange router contract address
    IExchangeRouter exchangeRouter;
    // GMX router contract address
    address router;
    // GMX deposit vault address
    address depositVault;
    // GMX withdrawal vault address
    address withdrawalVault;
    // GMX order vault address
    address orderVault;
    // GMX role store address
    address roleStore;

    // Status of the vault
    Status status;

    // Timestamp when vault last collected management fee
    uint256 lastFeeCollected;
    // Timestamp when last user deposit happened
    uint256 lastDepositBlock;

    // DepositCache
    DepositCache depositCache;
    // WithdrawCache
    WithdrawCache withdrawCache;
    // RebalanceAddCache
    RebalanceAddCache rebalanceAddCache;
    // RebalanceRemoveCache
    RebalanceRemoveCache rebalanceRemoveCache;
    // CompoundCache
    CompoundCache compoundCache;
  }

  struct DepositCache {
    // Address of user that is depositing
    address payable user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // USD value of deposit in 1e18; filled by vault
    uint256 depositValue;
    // Amount of shares to mint in 1e18; filled by vault
    uint256 sharesToUser;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // DepositParams
    DepositParams depositParams;
    // BorrowParams
    BorrowParams borrowParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct WithdrawCache {
    // Address of user that is withdrawing
    address payable user;
    // Timestamp of withdrawal created, filled by vault
    uint256 timestamp;
    // Ratio of shares out of total supply of shares to burn; filled by vault
    uint256 shareRatio;
    // Actual amount of withdraw token that user receives
    uint256 withdrawTokenAmt;
    // Withdraw key from GMX in bytes32
    bytes32 withdrawKey;
    // WithdrawParams
    WithdrawParams withdrawParams;
    // RepayParams
    RepayParams repayParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct RebalanceAddCache {
    // This should be the approved keeper address; filled by vault
    address payable user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // RebalanceAddParams
    RebalanceAddParams rebalanceAddParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct RebalanceRemoveCache {
    // This should be the approved keeper address; filled by vault
    address payable user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // Withdraw key from GMX in bytes32
    bytes32 withdrawKey;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // RebalanceRemoveParams
    RebalanceRemoveParams rebalanceRemoveParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct CompoundCache {
    // This should be the approved keeper address; filled by vault
    address payable user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // CompoundParams
    CompoundParams compoundParams;
  }

  struct DepositParams {
    // Address of token depositing; can be tokenA, tokenB or lpToken
    address token;
    // Amount of token to deposit in token decimals
    uint256 amt;
    // Minimum amount of shares to receive in 1e18
    uint256 minSharesAmt;
    // Slippage tolerance for adding liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // TODO Timestamp of deadline
    uint256 deadline;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct WithdrawParams {
    // Amount of shares to burn in 1e18
    uint256 shareAmt;
    // Address of token to withdraw to; could be tokenA, tokenB or lpToken
    address token;
    // Minimum amount of token to receive in token decimals
    uint256 minWithdrawTokenAmt;
    // Slippage tolerance for removing liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // TODO Timestamp of deadline
    uint256 deadline;
    // Execution fee sent to GMX for removing liquidity
    uint256 executionFee;
    // Amount of shares to remove in 1e18; filled by vault
    uint256 lpAmtToRemove;
    // SwapParams Swap for repay parameters
    SwapParams swapForRepayParams;
    // SwapParams Swap for withdraw parameters
    SwapParams swapForWithdrawParams;
  }

  struct RebalanceAddParams {
    // DepositParams
    DepositParams depositParams;
    // BorrowParams
    BorrowParams borrowParams;
    // RepayParams
    RepayParams repayParams;
  }

  struct RebalanceRemoveParams {
    // Amount of LP tokens to remove
    uint256 lpAmtToRemove;
    // DepositParams
    DepositParams depositParams;
    // WithdrawParams
    WithdrawParams withdrawParams;
    // BorrowParams
    BorrowParams borrowParams;
    // RepayParams
    RepayParams repayParams;
    // SwapParams Swap for repay parameters
    SwapParams swapForRepayParams;
  }

  struct CompoundParams {
    // SwapParams
    SwapParams swapParams;
    // DepositParams
    DepositParams depositParams;
  }

  struct AddLiquidityParams {
    // Amount of tokenA to add liquidity
    uint256 tokenAAmt;
    // Amount of tokenB to add liquidity
    uint256 tokenBAmt;
    // Slippage tolerance for adding liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct RemoveLiquidityParams {
    // Amount of lpToken to remove liquidity
    uint256 lpTokenAmt;
    // Slippage tolerance for removing liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Execution fee sent to GMX for removing liquidity
    uint256 executionFee;
  }

  struct BorrowParams {
    // Amount of tokenA to borrow in tokenA decimals
    uint256 borrowTokenAAmt;
    // Amount of tokenB to borrow in tokenB decimals
    uint256 borrowTokenBAmt;
  }

  struct RepayParams {
    // Amount of tokenA to repay in tokenA decimals
    uint256 repayTokenAAmt;
    // Amount of tokenB to repay in tokenB decimals
    uint256 repayTokenBAmt;
  }

  struct SwapParams {
    // Address of token swapping from; filled by vault
    address tokenFrom;
    // Address of token swapping to; filled by vault
    address tokenTo;
    // Amount of token swapping from; filled by vault
    uint256 tokenFromAmt;
    // Slippage tolerance swap; e.g. 3 = 0.03%
    uint256 slippage;
    // TODO Timestamp of deadline
    uint256 deadline;
    // Execution fee sent to GMX for swap orders
    uint256 executionFee;
    // Order key from GMX in bytes32
    bytes32 orderKey;
  }

  struct HealthParams {
    // USD value of equity in 1e18
    uint256 equityBefore;
    // Debt ratio in 1e18
    uint256 debtRatioBefore;
    // Delta in 1e18
    int256 deltaBefore;
    // LP token balance in 1e18
    uint256 lpAmtBefore;
    // Debt amount of tokenA in token decimals
    uint256 debtAmtTokenABefore;
    // Debt amount of tokenB in token decimals
    uint256 debtAmtTokenBBefore;
    // USD value of equity in 1e18
    uint256 equityAfter;
    // svToken value before in 1e18
    uint256 svTokenValueBefore;
    // // svToken value after in 1e18
    uint256 svTokenValueAfter;
  }

  /* ========== ENUM ========== */

  enum Status {
    // Vault is not open for any action
    Closed,
    // Vault is open for deposit/withdraw/rebalance
    Open,
    // User is depositing assets
    Deposit,
    // Vault is borrowing assets
    Borrow,
    // Vault is swapping for adding liquidity; note: unused
    Swap_For_Add,
    // Vault is adding liquidity
    Add_Liquidity,
    // Vault is minting shares
    Mint,
    // Vault is staking LP token; note: unused
    Stake,
    // User is withdrawing assets
    Withdraw,
    // Vault is unstaking LP token; note: unused
    Unstake,
    // Vault is removing liquidity
    Remove_Liquidity,
    // Vault is swapping assets for repayments
    Swap_For_Repay,
    // Vault is repaying assets
    Repay,
    // Vault is swapping assets for withdrawal
    Swap_For_Withdraw,
    // Vault is burning shares
    Burn,
    // Vault is rebalancing by adding more debt
    Rebalance_Add,
    // Vault is borrowing during rebalancing add
    Rebalance_Add_Borrow,
    // Vault is repaying during rebalancing add
    Rebalance_Add_Repay,
    // Vault is swapping for adding liquidity during rebalancing add; note: unused
    Rebalance_Add_Swap_For_Add,
    // Vault is adding liquidity during rebalancing add
    Rebalance_Add_Add_Liquidity,
    // Vault is rebalancing by reducing debt
    Rebalance_Remove,
    // Vault is removing liquidity during rebalancing remove
    Rebalance_Remove_Remove_Liquidity,
    // Vault is borrowing during rebalancing remove
    Rebalance_Remove_Borrow,
    // Vault is swapping for repay during rebalancing remove
    Rebalance_Remove_Swap_For_Repay,
    // Vault is repaying during rebalancing remove
    Rebalance_Remove_Repay,
    // Vault is swapping for adding liquidity during rebalancing remove; note: unused
    Rebalance_Remove_Swap_For_Add,
    // Vault is adding liquidity during rebalancing remove
    Rebalance_Remove_Add_Liquidity,
    // Vault is starting to compound
    Compound,
    // Vault is swapping during compound
    Compound_Swap,
    // Vault is adding liquidity during compound
    Compound_Add_Liquidity,
    // Vault is has added liquidity during compound
    Compound_Liquidity_Added,
    // Vault is performing an emergency shutdown
    Emergency_Shutdown,
    // // Vault is performing an emergency resume
    Emergency_Resume
  }

  enum Delta {
    Neutral,
    Long
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Errors {

  /* ========== AUTHORIZATION ========== */

  error OnlyKeeperAllowed();
  error OnlyVaultAllowed();
  error OnlyBorrowerAllowed();
  error OnlyCallbackOrKeeperAllowed();
  error OnlyQueueAllowed();

  /* ========== LENDING ========== */

  error InsufficientBorrowAmount();
  error InsufficientRepayAmount();
  error BorrowerAlreadyApproved();
  error BorrowerAlreadyRevoked();
  error InsufficientLendingLiquidity();
  error InsufficientAssetsBalance();

  /* ========== VAULT DEPOSIT ========== */

  error EmptyDepositAmount();
  error InvalidDepositToken();
  error InsufficientDepositAmount();
  error InvalidNativeDepositAmountValue();
  error InsufficientSharesMinted();
  error InsufficientCapacity();
  error OnlyNonNativeDepositToken();
  error InvalidNativeTokenAddress();
  error DepositAndExecutionFeeDoesNotMatchMsgValue();
  error InvalidExecutionFeeAmount();
  error InsufficientExecutionFeeAmount();
  error InsufficientSecurityDeposit();

  /* ========== VAULT WITHDRAWAL ========== */

  error EmptyWithdrawAmount();
  error InvalidWithdrawToken();
  error InsufficientWithdrawAmount();
  error InsufficientWithdrawBalance();
  error InsufficientAssetsReceived();
  error WithdrawNotAllowedInSameDepositBlock();

  /* ========== VAULT REBALANCE ========== */

  error InvalidDebtRatio();
  error InvalidDelta();
  error InvalidEquity();
  error InsufficientLPTokensMinted();
  error InsufficientLPTokensBurned();
  error InvalidRebalancePreConditions();
  error InvalidRebalanceDebtAmounts();

  /* ========== VAULT CALLBACKS ========== */

  error InvalidDepositKey();
  error InvalidWithdrawKey();
  error InvalidOrderKey();
  error InvalidCallbackHandler();

  /* ========== ORACLE ========== */

  error NoTokenPriceFeedAvailable();
  error FrozenTokenPriceFeed();
  error BrokenTokenPriceFeed();
  error TokenPriceFeedAlreadySet();
  error TokenPriceFeedMaxDelayMustBeGreaterOrEqualToZero();
  error TokenPriceFeedMaxDeviationMustBeGreaterOrEqualToZero();
  error InvalidTokenInLPPool();
  error InvalidReservesInLPPool();
  error OrderAmountOutMustBeGreaterThanZero();
  error SequencerDown();
  error GracePeriodNotOver();

  /* ========== GENERAL ========== */

  error NotAllowedInCurrentVaultStatus();
  error ZeroAddressNotAllowed();
  error TokenDecimalsMustBeLessThan18();
}