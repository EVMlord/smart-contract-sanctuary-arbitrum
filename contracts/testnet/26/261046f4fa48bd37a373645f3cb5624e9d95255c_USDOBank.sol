/**
 *Submitted for verification at Arbiscan on 2023-02-10
*/

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0*/
pragma solidity 0.8.9;



/// @notice USDOBank is a mortgage lending system that supports ERC20 as collateral and issues USDO
/// USDO is a self-issued stable coin used to support multi-collateralization protocols
interface IUSDOBank {
    /// @notice deposit function: user deposit their collateral.
    /// @param from: deposit from which account
    /// @param collateral: deposit collateral type.
    /// @param amount: collateral amount
    /// @param to: account that user want to deposit to
    function deposit(address from, address collateral, uint256 amount, address to) external;

    /// @notice borrow function: get USDO based on the amount of user's collaterals.
    /// @param amount: borrow USDO amount
    /// @param to: is the address receiving USDO
    /// @param isDepositToJOJO: whether deposit to JOJO account
    /// @param from: who want to borrow USDO
    function borrow(uint256 amount, address to, bool isDepositToJOJO, address from) external;

    /// @notice withdraw function: user can withdraw their collateral
    /// @param collateral: withdraw collateral type
    /// @param amount: withdraw amount
    /// @param to: is the address receiving asset
    /// @param from: who want to withdraw asset
    function withdraw(address collateral, uint256 amount, address to, address from) external;

    /// @notice repay function: repay the USDO in order to avoid account liquidation by liquidators
    /// @param amount: repay USDO amount
    /// @param to: repay to whom
    function repay(uint256 amount, address to) external returns (uint256);

    /// @notice liquidate function: The price of user mortgage assets fluctuates.
    /// If the value of the mortgage collaterals cannot handle the value of USDO borrowed, the collaterals may be liquidated
    /// @param liquidatedTrader: is the trader to be liquidated
    /// @param liquidationCollateral: is the liquidated collateral type
    /// @param liquidationAmount: is the collateral amount liqidator want to take
    /// @param depositCollateral: User can deposit collaterals or repay USDO to keep account safe
    /// @param depositAmount: repay or deposit amount
    /// @param expectLiquidateAmount: expect liquidate amount
    function liquidate(
        address liquidatedTrader,
        address liquidationCollateral,
        address liquidator,
        uint256 liquidationAmount,
        address depositCollateral,
        uint256 depositAmount,
        uint256 expectLiquidateAmount
    ) external returns (uint256 adjustedCollateral, uint256 actualLiquidatedAmount, uint256 insuranceFee);

    /// @notice insurance account take bad debts on unsecured accounts
    /// @param liquidatedTraders traders who have bad debts
    function handleDebt(address[] calldata liquidatedTraders) external;

    /// @notice withdraw and deposit collaterals in one transaction
    /// @param receiver address who receiver the collateral
    /// @param collateral collateral type
    /// @param amount withdraw amount
    /// @param to: if repay USDO, repay to whom
    /// @param param user input
    function flashLoan(address receiver, address collateral, uint256 amount, address to, bytes memory param) external;

    /// @notice get the all collateral list
    function getReservesList() external view returns (address[] memory);

    /// @notice return the max borrow USDO amount from the deposit amount
    function getDepositMaxMintAmount(address user) external view returns (uint256);

    /// @notice return the collateral's max borrow USDO amount
    function getCollateralMaxMintAmount(
        address collateral,
        uint256 amoount
    ) external view returns (uint256 maxAmount);

    /// @notice return the collateral's max withdraw amount
    function getMaxWithdrawAmount(address collateral, address user) external view returns (uint256 maxAmount);

    function isAccountSafe(address user) external view returns (bool);

    function getCollateralPrice(address collateral) external view returns (uint256);

    function getIfHasCollateral(address from, address collateral) external view returns (bool);

    function getDepositBalance(address collateral, address from) external view returns (uint256);

    function getBorrowBalance(address from) external view returns (uint256);

    function getUserCollateralList(address from) external view returns (address[] memory);

    function getFee(address trader) external view returns (int256);

    function getTotalBorrow(address trader) external view returns (uint256);

    function getTotalRepay(address trader) external view returns (uint256);
}



interface IFlashLoanReceive {
    function JOJOFlashLoan(address asset, uint256 amount, address to, bytes calldata param) external;
}



// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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



library DataTypes {
    struct ReserveInfo {
        //    the initial mortgage rate of collateral
        //        1e18 based decimal
        uint256 initialMortgageRate;
        //        max total deposit collateral amount
        uint256 maxTotalDepositAmount;
        //        max deposit collateral amount per account
        uint256 maxDepositAmountPerAccount;
        //    the collateral max deposit value, protect from oracle
        uint256 maxBorrowValue;
        //        liquidate params
        LiquidityInfo liquidityInfo;
        //        oracle address
        address oracle;
        //        if allow user deposit collateral
        bool isDepositAllowed;
        //        if allow user borrow USDO
        bool isBorrowAllowed;
        //      total deposit amount
        uint256 totalDepositAmount;
    }

    /// @notice liquidate params
    struct LiquidityInfo {
        //        liquidation mortgage rate
        uint256 liquidationMortgageRate;
        /*
            The discount rate for the liquidation.
            price * (1 - liquidationPriceOff)
            1e18 based decimal.
        */
        uint256 liquidationPriceOff;
        //        insurance fee rate
        uint256 insuranceFeeRate;
        /*       
            if the mortgage collateral delisted.
            if isFinalLiquidation = true which means user can not deposit collateral and borrow USDO
        */
        bool isFinalLiquidation;
    }

    /// @notice user param
    struct UserInfo {
        //        deposit collateral ==> deposit amount
        mapping(address => uint256) depositBalance;
        //        t0 borrow USDO amount
        uint256 t0BorrowBalance;
        //      collateral ==> if deposited
        mapping(address => bool) hasCollateral;
        //        user deposit collateral list
        address[] collateralList;
        //        total borrow
        uint256 totalBorrow;
        //        total repay
        uint256 totalRepay;
    }
}

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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



abstract contract FlashLoanReentrancyGuard {
    uint256 private constant _CAN_FLASHLOAN = 1;
    uint256 private constant _CAN_NOT_FLASHLOAN = 2;

    uint256 private _status;

    constructor() {
        _status = _CAN_FLASHLOAN;
    }

    modifier nonFlashLoanReentrant() {
        require(_status != _CAN_NOT_FLASHLOAN, "ReentrancyGuard: flashLoan reentrant call");

        _status = _CAN_NOT_FLASHLOAN;

        _;

        _status = _CAN_FLASHLOAN;
    }
}



library JOJOConstant {
    uint256 public constant SECONDS_PER_YEAR = 365 days;
}

abstract contract USDOBankStorage is Ownable, ReentrancyGuard, FlashLoanReentrancyGuard {
    // reserve token address ==> reserve info
    mapping(address => DataTypes.ReserveInfo) public reserveInfo;
    // reserve token address ==> user info
    mapping(address => DataTypes.UserInfo) public userInfo;
    //client -> operator -> bool
    mapping(address => mapping(address => bool)) public operatorRegistry;
    // reserves amount
    uint256 public reservesAmount;
    // max reserves amount
    uint256 public maxReservesAmount;

    // max borrow USDO amount per account
    uint256 public maxPerAccountBorrowAmount;
    // max total borrow USDO amount
    uint256 public maxTotalBorrowAmount;
    // t0 total borrow USDO amount
    uint256 public t0TotalBorrowAmount;

    // borrow fee rate
    uint256 public borrowFeeRate;
    // t0Rate
    uint256 public t0Rate;
    // update timestamp
    uint32 public lastUpdateTimestamp;

    // reserves's list
    address[] public reservesList;

    // insurance account
    address public insurance;
    // USDO address
    address public USDO;
    address public JOJODealer;

    function getTRate() public view returns (uint256) {
        uint256 timeDifference = block.timestamp - uint256(lastUpdateTimestamp);
        return t0Rate + (borrowFeeRate * timeDifference) / JOJOConstant.SECONDS_PER_YEAR;
    }
}





library USDOErrors {
    string constant RESERVE_NOT_ALLOW_DEPOSIT = "RESERVE_NOT_ALLOW_DEPOSIT";
    string constant DEPOSIT_AMOUNT_IS_ZERO = "DEPOSIT_AMOUNT_IS_ZERO";
    string constant REPAY_AMOUNT_IS_ZERO = "REPAY_AMOUNT_IS_ZERO";
    string constant WITHDRAW_AMOUNT_IS_ZERO = "WITHDRAW_AMOUNT_IS_ZERO";
    string constant LIQUIDATE_AMOUNT_IS_ZERO = "LIQUIDATE_AMOUNT_IS_ZERO";
    string constant AFTER_BORROW_ACCOUNT_IS_NOT_SAFE = "AFTER_BORROW_ACCOUNT_IS_NOT_SAFE";
    string constant AFTER_WITHDRAW_ACCOUNT_IS_NOT_SAFE = "AFTER_WITHDRAW_ACCOUNT_IS_NOT_SAFE";
    string constant AFTER_FLASHLOAN_ACCOUNT_IS_NOT_SAFE = "AFTER_FLASHLOAN_ACCOUNT_IS_NOT_SAFE";
    string constant EXCEED_THE_MAX_DEPOSIT_AMOUNT_PER_ACCOUNT = "EXCEED_THE_MAX_DEPOSIT_AMOUNT_PER_ACCOUNT";
    string constant EXCEED_THE_MAX_DEPOSIT_AMOUNT_TOTAL = "EXCEED_THE_MAX_DEPOSIT_AMOUNT_TOTAL";
    string constant EXCEED_THE_MAX_BORROW_AMOUNT_PER_ACCOUNT = "EXCEED_THE_MAX_BORROW_AMOUNT_PER_ACCOUNT";
    string constant EXCEED_THE_MAX_BORROW_AMOUNT_TOTAL = "EXCEED_THE_MAX_BORROW_AMOUNT_TOTAL";
    string constant ACCOUNT_IS_SAFE = "ACCOUNT_IS_SAFE";
    string constant NOT_CONTRACT = "NOT_CONTRACT";
    string constant WITHDRAW_AMOUNT_IS_TOO_BIG = "WITHDRAW_AMOUNT_IS_TOO_BIG";
    string constant CAN_NOT_OPERATOR_ACCOUNT = "CAN_NOT_OPERATOR_ACCOUNT";
    string constant LIQUIDATE_AMOUNT_IS_TOO_BIG = "LIQUIDATE_AMOUNT_IS_TOO_BIG";
    string constant TOKEN_IS_NOT_THE_STABLE_COIN = "TOKEN_IS_NOT_THE_STABLE_COIN";
    string constant NOT_SUPPORTED_EXCHANGE = "NOT_SUPPORTED_EXCHANGE";
    string constant LESS_THAN_MIN_EXCHANGE_AMOUNT = "LESS_THAN_MIN_EXCHANGE_AMOUNT";
    string constant BIGGER_THAN_MAX_EXCHANGE_AMOUNT = "BIGGER_THAN_MAX_EXCHANGE_AMOUNT";
    string constant BIGGER_THAN_MAX_EXCHANGE_AMOUNT_PER_ACCOUNT = "BIGGER_THAN_MAX_EXCHANGE_AMOUNT_PER_ACCOUNT";
    string constant USDC_CAN_NOT_TRANSFER = "USDC_CAN_NOT_TRANSFER";
    string constant SELF_LIQUIDATION_NOT_ALLOWED = "SELF_LIQUIDATION_NOT_ALLOWED";
    string constant LIQUIDATION_PRICE_PROTECTION = "LIQUIDATION_PRICE_PROTECTION";
    string constant NOT_ALLOWED_TO_EXCHANGE = "NOT_ALLOWED_TO_EXCHANGE";
    string constant EXCHANGE_AMOUNT_TOO_BIG = "EXCHANGE_AMOUNT_TOO_BIG";
    string constant NO_MORE_RESERVE_ALLOWED = "NO_MORE_RESERVE_ALLOWED";
}

/// @notice Owner-only functions
abstract contract USDOOperation is USDOBankStorage {
    // ========== event ==========
    event UpdateInsurance(address oldInsurance, address newInsurance);
    event UpdateJOJODealer(address oldJOJODealer, address newJOJODealer);
    event SetOperator(address indexed client, address indexed operator, bool isOperator);
    event UpdateOracle(address collateral, address newOracle);
    event UpdateBorrowFeeRate(uint256 newBorrowFeeRate, uint256 newT0Rate, uint32 lastUpdateTimestamp);
    event UpdateMaxReservesAmount(uint256 maxReservesAmount, uint256 newMaxReservesAmount);
    event RemoveReserve(address indexed collateral);
    event ReRegisterReserve(address indexed collateral);
    event UpdateReserveRiskParam(
        address indexed collateral,
        uint256 liquidationMortgageRate,
        uint256 liquidationPriceOff,
        uint256 insuranceFeeRate
    );

    event UpdateReserveParam(
        address indexed collateral,
        uint256 initialMortgageRate,
        uint256 maxTotalDepositAmount,
        uint256 maxDepositAmountPerAccount,
        uint256 maxBorrowValue
    );
    event UpdateMaxBorrowAmount(uint256 maxPerAccountBorrowAmount, uint256 maxTotalBorrowAmount);

    /// @notice initial the param of each reserve
    function initReserve(
        address _collateral,
        uint256 _initialMortgageRate,
        uint256 _maxTotalDepositAmount,
        uint256 _maxDepositAmountPerAccount,
        uint256 _maxBorrowValue,
        uint256 _liquidationMortgageRate,
        uint256 _liquidationPriceOff,
        uint256 _insuranceFeeRate,
        address _oracle
    ) external onlyOwner {
        reserveInfo[_collateral].initialMortgageRate = _initialMortgageRate;
        reserveInfo[_collateral].maxTotalDepositAmount = _maxTotalDepositAmount;
        reserveInfo[_collateral].maxDepositAmountPerAccount = _maxDepositAmountPerAccount;
        reserveInfo[_collateral].maxBorrowValue = _maxBorrowValue;
        reserveInfo[_collateral].liquidityInfo.liquidationMortgageRate = _liquidationMortgageRate;
        reserveInfo[_collateral].liquidityInfo.liquidationPriceOff = _liquidationPriceOff;
        reserveInfo[_collateral].liquidityInfo.insuranceFeeRate = _insuranceFeeRate;
        reserveInfo[_collateral].isDepositAllowed = true;
        reserveInfo[_collateral].isBorrowAllowed = true;
        reserveInfo[_collateral].oracle = _oracle;
        _addReserve(_collateral);
    }

    function _addReserve(address collateral) private {
        require(reservesAmount <= maxReservesAmount, USDOErrors.NO_MORE_RESERVE_ALLOWED);
        reservesList.push(collateral);
        reservesAmount += 1;
    }

    /// @notice update the max borrow amount of total and per account
    function updateMaxBorrowAmount(
        uint256 _maxBorrowAmountPerAccount,
        uint256 _maxTotalBorrowAmount
    ) external onlyOwner {
        maxTotalBorrowAmount = _maxTotalBorrowAmount;
        maxPerAccountBorrowAmount = _maxBorrowAmountPerAccount;
        emit UpdateMaxBorrowAmount(maxPerAccountBorrowAmount, maxTotalBorrowAmount);
    }

    /// @notice update the insurance account
    function updateInsurance(address newInsurance) external onlyOwner {
        emit UpdateInsurance(insurance, newInsurance);
        insurance = newInsurance;
    }

    /// @notice update JOJODealer address
    function updateJOJODealer(address newJOJODealer) external onlyOwner {
        emit UpdateJOJODealer(JOJODealer, newJOJODealer);
        JOJODealer = newJOJODealer;
    }

    /// @notice update collateral oracle
    function updateOracle(address collateral, address newOracle) external onlyOwner {
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        reserve.oracle = newOracle;
        emit UpdateOracle(collateral, newOracle);
    }

    function updateMaxReservesAmount(uint256 newMaxReservesAmount) external onlyOwner {
        emit UpdateMaxReservesAmount(maxReservesAmount, newMaxReservesAmount);
        maxReservesAmount = newMaxReservesAmount;
    }

    /// @notice update the borrow fee rate
    // t0Rate and lastUpdateTimestamp will be updated according to the borrow fee rate
    function updateBorrowFeeRate(uint256 _borrowFeeRate) external onlyOwner {
        t0Rate = getTRate();
        lastUpdateTimestamp = uint32(block.timestamp);
        borrowFeeRate = _borrowFeeRate;
        emit UpdateBorrowFeeRate(_borrowFeeRate, t0Rate, lastUpdateTimestamp);
    }

    /// @notice update the reserve risk params
    function updateRiskParam(
        address collateral,
        uint256 _liquidationMortgageRate,
        uint256 _liquidationPriceOff,
        uint256 _insuranceFeeRate
    ) external onlyOwner {
        reserveInfo[collateral].liquidityInfo.liquidationMortgageRate = _liquidationMortgageRate;
        reserveInfo[collateral].liquidityInfo.liquidationPriceOff = _liquidationPriceOff;
        reserveInfo[collateral].liquidityInfo.insuranceFeeRate = _insuranceFeeRate;
        emit UpdateReserveRiskParam(collateral, _liquidationMortgageRate, _liquidationPriceOff, _insuranceFeeRate);
    }

    /// @notice update the reserve basic params
    function updateReserveParam(
        address collateral,
        uint256 _initialMortgageRate,
        uint256 _maxTotalDepositAmount,
        uint256 _maxDepositAmountPerAccount,
        uint256 _maxBorrowValue
    ) external onlyOwner {
        reserveInfo[collateral].initialMortgageRate = _initialMortgageRate;
        reserveInfo[collateral].maxTotalDepositAmount = _maxTotalDepositAmount;
        reserveInfo[collateral].maxDepositAmountPerAccount = _maxDepositAmountPerAccount;
        reserveInfo[collateral].maxBorrowValue = _maxBorrowValue;
        emit UpdateReserveParam(
            collateral, _initialMortgageRate, _maxTotalDepositAmount, _maxDepositAmountPerAccount, _maxBorrowValue
            );
    }

    /// @notice remove the reserve, need to modify the market status
    /// which means this reserve is delist
    function delistReserve(address collateral) external onlyOwner {
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        reserve.isBorrowAllowed = false;
        reserve.isDepositAllowed = false;
        reserve.liquidityInfo.isFinalLiquidation = true;
        emit RemoveReserve(collateral);
    }

    /// @notice relist the delist reserve
    function relistReserve(address collateral) external onlyOwner {
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        reserve.isBorrowAllowed = true;
        reserve.isDepositAllowed = true;
        reserve.liquidityInfo.isFinalLiquidation = false;
        emit ReRegisterReserve(collateral);
    }

    /// @notice Update the sub account
    function setOperator(address operator, bool isOperator) external {
        operatorRegistry[msg.sender][operator] = isOperator;
        emit SetOperator(msg.sender, operator, isOperator);
    }
}





library DecimalMath {
    uint256 constant ONE = 1e18;

    function decimalMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function decimalDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function decimalRemainder(uint256 a, uint256 b) internal pure returns (bool) {
        if ((a * ONE) % b == 0) {
            return true;
        } else {
            return false;
        }
    }
}



interface IPriceChainLink {
    //    get token address price
    function getAssetPrice() external view returns (uint256);
}

abstract contract USDOView is USDOBankStorage, IUSDOBank {
    using DecimalMath for uint256;

    function getReservesList() external view returns (address[] memory) {
        return reservesList;
    }

    function getDepositMaxMintAmount(address user) external view returns (uint256) {
        DataTypes.UserInfo storage userInfo = userInfo[user];
        return _maxMintAmount(userInfo);
    }

    function getCollateralMaxMintAmount(
        address collateral,
        uint256 amoount
    ) external view returns (uint256 maxAmount) {
        DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
        return _getMintAmount(amoount, reserve.oracle, reserve.initialMortgageRate, reserve.maxBorrowValue);
    }

    //1. 存200，可以全取完；
    function getMaxWithdrawAmount(address collateral, address user) external view returns (uint256 maxAmount) {
        DataTypes.UserInfo storage userInfo = userInfo[user];
        uint256 USDOBorrow = userInfo.t0BorrowBalance.decimalMul(getTRate());
        uint256 maxMintAmount = _maxWithdrawAmount(userInfo);
        if (maxMintAmount <= USDOBorrow) {
            maxAmount = 0;
        } else {
            DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
            uint256 remainAmount = (maxMintAmount - USDOBorrow).decimalDiv(
                reserve.initialMortgageRate.decimalMul(IPriceChainLink(reserve.oracle).getAssetPrice())
            );
            remainAmount >= userInfo.depositBalance[collateral]
                ? maxAmount = userInfo.depositBalance[collateral]
                : maxAmount = remainAmount;
        }
    }

    function isAccountSafe(address user) external view returns (bool) {
        DataTypes.UserInfo storage userInfo = userInfo[user];
        return _isAccountSafe(userInfo, getTRate());
    }

    function getCollateralPrice(address collateral) external view returns (uint256) {
        return IPriceChainLink(reserveInfo[collateral].oracle).getAssetPrice();
    }

    function getIfHasCollateral(address from, address collateral) external view returns (bool) {
        return userInfo[from].hasCollateral[collateral];
    }

    function getDepositBalance(address collateral, address from) external view returns (uint256) {
        return userInfo[from].depositBalance[collateral];
    }

    function getBorrowBalance(address from) external view returns (uint256) {
        return (userInfo[from].t0BorrowBalance * getTRate()) / 1e18;
    }

    function getUserCollateralList(address from) external view returns (address[] memory) {
        return userInfo[from].collateralList;
    }

    function getFee(address trader) external view returns (int256) {
        //    abs(totalBorrow - totalRepay - myloan)
        int256 fee = int256(userInfo[trader].totalBorrow) - int256(userInfo[trader].totalRepay)
            - int256((userInfo[trader].t0BorrowBalance * getTRate()) / 1e18);
        return fee < 0 ? -fee : fee;
    }

    function getTotalBorrow(address trader) external view returns (uint256) {
        return userInfo[trader].totalBorrow;
    }

    function getTotalRepay(address trader) external view returns (uint256) {
        return userInfo[trader].totalRepay;
    }

    /// @notice get the USDO mint amount
    function _getMintAmount(
        uint256 balance,
        address oracle,
        uint256 rate,
        uint256 maxBorrowValue
    ) internal view returns (uint256) {
        uint256 depositValue = IPriceChainLink(oracle).getAssetPrice().decimalMul(balance).decimalMul(rate);
        if (depositValue >= maxBorrowValue) {
            depositValue = maxBorrowValue;
        }
        return depositValue;
    }

    /// @notice according to the initialMortgageRate to judge whether the user's account is safe after borrow, withdraw, flashloan
    /// If the collateral is not allowed to be borrowed. When calculating max mint USDO amount, treat the value of collateral as 0
    /// maxMintAmount = sum(collateral amount * price * initialMortgageRate)
    function _isAccountSafe(DataTypes.UserInfo storage user, uint256 tRate) internal view returns (bool) {
        return user.t0BorrowBalance.decimalMul(tRate) <= _maxMintAmount(user);
    }

    function _maxWithdrawAmount(DataTypes.UserInfo storage user) internal view returns (uint256) {
        address[] memory collaterals = user.collateralList;
        uint256 maxMintAmount;
        for (uint256 i; i < collaterals.length; i = i + 1) {
            address collateral = collaterals[i];
            DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
            if (!reserve.isBorrowAllowed) {
                continue;
            }
            maxMintAmount += IPriceChainLink(reserve.oracle).getAssetPrice().decimalMul(user.depositBalance[collateral])
                .decimalMul(reserve.initialMortgageRate);
        }
        return maxMintAmount;
    }

    function _maxMintAmount(DataTypes.UserInfo storage user) internal view returns (uint256) {
        address[] memory collaterals = user.collateralList;
        uint256 maxMintAmount;
        for (uint256 i; i < collaterals.length; i = i + 1) {
            address collateral = collaterals[i];
            DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
            if (!reserve.isBorrowAllowed) {
                continue;
            }
            maxMintAmount += _getMintAmount(
                user.depositBalance[collateral], reserve.oracle, reserve.initialMortgageRate, reserve.maxBorrowValue
            );
        }
        return maxMintAmount;
    }

    /// @notice Determine whether the account is safe by liquidationMortgageRate
    // If the collateral delisted. When calculating the boundary conditions for collateral to be liquidated, treat the value of collateral as 0
    // liquidationMaxMintAmount = sum(depositAmount * price * liquidationMortgageRate)
    function _isStartLiquidation(
        DataTypes.UserInfo storage liquidatedTraderInfo,
        uint256 tRate
    ) internal view returns (bool) {
        uint256 USDOBorrow = (liquidatedTraderInfo.t0BorrowBalance).decimalMul(tRate);
        uint256 liquidationMaxMintAmount;
        address[] memory collaterals = liquidatedTraderInfo.collateralList;
        for (uint256 i; i < collaterals.length; i = i + 1) {
            address collateral = collaterals[i];
            DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
            if (reserve.liquidityInfo.isFinalLiquidation) {
                continue;
            }
            liquidationMaxMintAmount += _getMintAmount(
                liquidatedTraderInfo.depositBalance[collateral],
                reserve.oracle,
                reserve.liquidityInfo.liquidationMortgageRate,
                reserve.maxBorrowValue
            );
        }
        return liquidationMaxMintAmount < USDOBorrow;
    }
}



/// @notice User's multi-step operation on the USDObank like: deposit and borrow
contract USDOMulticall {
    using DecimalMath for uint256;

    function multiCall(bytes[] memory callData) external returns (bytes[] memory returnData) {
        returnData = new bytes[](callData.length);

        for (uint256 i; i < callData.length; i++) {
            (bool success, bytes memory res) = address(this).delegatecall(callData[i]);
            if (success == false) {
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
            returnData[i] = res;
        }
    }

    // --------------helper-------------------
    function getMulticallData(bytes[] memory callData) external pure returns (bytes memory) {
        return abi.encodeWithSignature("multiCall(bytes[])", callData);
    }

    function getDepositData(
        address from,
        address collateral,
        uint256 amount,
        address to
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature("deposit(address,address,uint256,address)", from, collateral, amount, to);
    }

    function getBorrowData(
        uint256 amount,
        address to,
        bool isDepositToJOJO,
        address from
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature("borrow(uint256,address,bool,address)", amount, to, isDepositToJOJO, from);
    }

    function getRepayData(uint256 amount, address to) external pure returns (bytes memory) {
        return abi.encodeWithSignature("repay(uint256,address)", amount, to);
    }

    function getWithdrawData(
        address collateral,
        uint256 amount,
        address to,
        address from
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature("withdraw(address,uint256,address,address)", collateral, amount, to, from);
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



library Types {
    /// @notice data structure of dealer
    struct State {
        // primary asset, ERC20
        address primaryAsset;
        // secondary asset, ERC20
        address secondaryAsset;
        // credit, gained by deposit assets
        mapping(address => int256) primaryCredit;
        mapping(address => uint256) secondaryCredit;
        // withdrawal request time lock
        uint256 withdrawTimeLock;
        // pending primary asset withdrawal amount
        mapping(address => uint256) pendingPrimaryWithdraw;
        // pending secondary asset withdrawal amount
        mapping(address => uint256) pendingSecondaryWithdraw;
        // withdrawal request executable timestamp
        mapping(address => uint256) withdrawExecutionTimestamp;
        // perpetual contract risk parameters
        mapping(address => Types.RiskParams) perpRiskParams;
        // perpetual contract registry, for view
        address[] registeredPerp;
        // all open positions of a trader
        mapping(address => address[]) openPositions;
        // To quickly search if a trader has open position:
        // trader => perpetual contract address => hasPosition
        mapping(address => mapping(address => bool)) hasPosition;
        // For offchain pnl calculation, serial number +1 whenever 
        // position is fully closed.
        // trader => perpetual contract address => current serial Num
        mapping(address => mapping(address => uint256)) positionSerialNum;
        // filled amount of orders
        mapping(bytes32 => uint256) orderFilledPaperAmount;
        // valid order sender registry
        mapping(address => bool) validOrderSender;
        // operator registry
        // client => operator => isValid
        mapping(address => mapping(address => bool)) operatorRegistry;
        // insurance account
        address insurance;
        // funding rate keeper, normally an EOA account
        address fundingRateKeeper;
    }

    struct Order {
        // address of perpetual market
        address perp;
        /*
            Signer is trader, the identity of trading behavior,
            whose balance will be changed.
            Normally it should be an EOA account and the 
            order is valid only if the signer signed it.
            If the signer is a contract, it must implement
            isValidPerpetualOperator(address) returns(bool).
            The order is valid only if one of the valid operators
            is an EOA account and signed the order.
        */
        address signer;
        // positive(negative) if you want to open long(short) position
        int128 paperAmount;
        // negative(positive) if you want to open short(long) position
        int128 creditAmount;
        /*
            ╔═══════════════════╤═════════╗
            ║ info component    │ type    ║
            ╟───────────────────┼─────────╢
            ║ makerFeeRate      │ int64   ║
            ║ takerFeeRate      │ int64   ║
            ║ expiration        │ uint64  ║
            ║ nonce             │ uint64  ║
            ╚═══════════════════╧═════════╝
        */
        bytes32 info;
    }

    // EIP712 component
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(address perp,address signer,int128 paperAmount,int128 creditAmount,bytes32 info)"
        );

    /// @notice risk params of a perpetual market
    struct RiskParams {
        /*
            Liquidation will happen when
            netValue < exposure * liquidationThreshold
            The lower liquidationThreshold, the higher leverage.
            1E18 based decimal.
        */
        uint256 liquidationThreshold;
        /*
            The discount rate for the liquidation.
            markPrice * (1 - liquidationPriceOff) when liquidate long position
            markPrice * (1 + liquidationPriceOff) when liquidate short position
            1e18 based decimal.
        */
        uint256 liquidationPriceOff;
        // The insurance fee rate charged from liquidation. 
        // 1E18 based decimal.
        uint256 insuranceFeeRate;
        // price source of mark price
        address markPriceSource;
        // perpetual market name
        string name;
        // if the market is activited
        bool isRegistered;
    }

    /// @notice Match result obtained by parsing and validating tradeData.
    /// Contains arrays of balance change.
    struct MatchResult {
        address[] traderList;
        int256[] paperChangeList;
        int256[] creditChangeList;
        int256 orderSenderFee;
    }

    uint256 constant ONE = 10**18;
}

interface IDealer {
    /// @notice Deposit fund to get credit for trading
    /// @param primaryAmount is the amount of primary asset you want to deposit.
    /// @param secondaryAmount is the amount of secondary asset you want to deposit.
    /// @param to is the account you want to deposit to.
    function deposit(
        uint256 primaryAmount,
        uint256 secondaryAmount,
        address to
    ) external;

    /// @notice Submit withdrawal request, which can be executed after
    /// the timelock. The main purpose of this function is to avoid the
    /// failure of counterparty caused by withdrawal.
    /// @param primaryAmount is the amount of primary asset you want to withdraw.
    /// @param secondaryAmount is the amount of secondary asset you want to withdraw.
    function requestWithdraw(uint256 primaryAmount, uint256 secondaryAmount)
        external;

    /// @notice Execute the withdrawal request.
    /// @param to is the address receiving assets.
    /// @param isInternal Only internal credit transfers will be made,
    /// and ERC20 transfers will not happen.
    function executeWithdraw(address to, bool isInternal) external;

    /// @notice Help perpetual contract parse tradeData and return
    /// the balance changes of each trader.
    /// @dev only perpetual contract can call this function
    /// @param orderSender is the one who submit tradeData.
    /// @param tradeData contains orders, signatures and match info.
    function approveTrade(address orderSender, bytes calldata tradeData)
        external
        returns (
            address[] memory traderList,
            int256[] memory paperChangeList,
            int256[] memory creditChangeList
        );

    /// @notice Check if the trader's margin is enough (>= maintenance margin).
    /// If so, the trader is "safe".
    /// The trader's positions under all markets will be liquidated if he is
    /// not safe.
    function isSafe(address trader) external view returns (bool);

    /// @notice Check if a list of traders are safe.
    /// @dev This function is more gas effective than isSafe, by caching
    /// mark prices.
    function isAllSafe(address[] calldata traderList)
        external
        view
        returns (bool);

    /// @notice Get funding rate of a perpetual market.
    /// Funding rate is a 1e18 based decimal.
    function getFundingRate(address perp) external view returns (int256);

    /// @notice Update multiple funding rate at once.
    /// Can only be called by funding rate keeper.
    function updateFundingRate(
        address[] calldata perpList,
        int256[] calldata rateList
    ) external;

    /// @notice Calculate the paper and credit change of liquidator and
    /// liquidated trader.
    /// @dev Only perpetual contract can call this function.
    /// liqtor is short for liquidator, liqed is short for liquidated trader.
    /// @param liquidator is the one who will take over positions.
    /// @param liquidatedTrader is the one who is being liquidated.
    /// @param requestPaperAmount is the size that the liquidator wants to take.
    /// Positive if the position is long, negative if the position is short.
    function requestLiquidation(
        address liquidator,
        address liquidatedTrader,
        int256 requestPaperAmount
    )
        external
        returns (
            int256 liqtorPaperChange,
            int256 liqtorCreditChange,
            int256 liqedPaperChange,
            int256 liqedCreditChange
        );

    /// @notice Transfer all bad debt to insurance account,
    /// including primary and secondary balances.
    function handleBadDebt(address liquidatedTrader) external;

    /// @notice Register the trader's position into dealer.
    /// @dev Only perpetual contract can call this function when
    /// someone's position is opened.
    function openPosition(address trader) external;

    /// @notice Accrual realized pnl and remove the trader's position from dealer.
    /// @dev Only perpetual contract can call this function when
    /// someone's position is closed.
    function realizePnl(address trader, int256 pnl) external;

    /// @notice Register operator.
    /// The operator can sign order on your behalf.
    function setOperator(address operator, bool isValid) external;

    /// @param perp the address of perpetual contract market
    function getRiskParams(address perp)
        external
        view
        returns (Types.RiskParams memory params);

    /// @notice Return all registered perpetual contract market.
    function getAllRegisteredPerps() external view returns (address[] memory);

    /// @notice Return mark price of a perpetual market.
    /// price is a 1e18 based decimal.
    function getMarkPrice(address perp) external view returns (uint256);

    /// @notice Get all open positions of the trader.
    function getPositions(address trader)
        external
        view
        returns (address[] memory);

    /// @notice Return the credit details of the trader.
    /// You cannot use credit as net value or net margin of a trader.
    /// The net value of positions would also be included.
    function getCreditOf(address trader)
        external
        view
        returns (
            int256 primaryCredit,
            uint256 secondaryCredit,
            uint256 pendingPrimaryWithdraw,
            uint256 pendingSecondaryWithdraw,
            uint256 executionTimestamp
        );

    /// @notice Get the risk profile data of a trader.
    /// @return netValue net value of trader including credit amount
    /// @return exposure open position value of the trader across all markets
    function getTraderRisk(address trader)
        external
        view
        returns (
            int256 netValue,
            uint256 exposure,
            uint256 maintenanceMargin
        );

    /// @notice Get liquidation price of a position
    /// @dev This function is for directional use. The margin of error is typically
    /// within 10 wei.
    /// @return liquidationPrice equals 0 if there is no liquidation price.
    function getLiquidationPrice(address trader, address perp)
        external
        view
        returns (uint256 liquidationPrice);

    /// @notice a view version of requestLiquidation, liquidators can use
    /// this function to check how much you have to pay in advance.
    function getLiquidationCost(
        address perp,
        address liquidatedTrader,
        int256 requestPaperAmount
    )
        external
        view
        returns (int256 liqtorPaperChange, int256 liqtorCreditChange);

    /// @notice Get filled paper amount of an order to avoid double matching.
    /// @return filledAmount includes paper amount
    function getOrderFilledAmount(bytes32 orderHash)
        external
        view
        returns (uint256 filledAmount);

    /// @notice check if order sender is valid
    function isOrderSenderValid(address orderSender)
        external
        view
        returns (bool);

    /// @notice check if operator is valid
    function isOperatorValid(address client, address operator)
        external
        view
        returns (bool);
}

contract USDOBank is IUSDOBank, USDOOperation, USDOView, USDOMulticall {
    using DecimalMath for uint256;
    using SafeERC20 for IERC20;

    constructor(
        uint256 _maxReservesAmount,
        address _insurance,
        address _USDO,
        address _JOJODealer,
        uint256 _maxPerAccountBorrowAmount,
        uint256 _maxTotalBorrowAmount,
        uint256 _borrowFeeRate,
        uint256 _t0Rate
    ) {
        maxReservesAmount = _maxReservesAmount;
        USDO = _USDO;
        JOJODealer = _JOJODealer;
        insurance = _insurance;
        maxPerAccountBorrowAmount = _maxPerAccountBorrowAmount;
        maxTotalBorrowAmount = _maxTotalBorrowAmount;
        borrowFeeRate = _borrowFeeRate;
        t0Rate = _t0Rate;
        lastUpdateTimestamp = uint32(block.timestamp);
    }

    // --------------------------event-----------------------

    event HandleBadDebt(address indexed liquidatedTrader, uint256 borrowUSDOT0);
    event Deposit(
        address indexed collateral, address indexed from, address indexed to, address operator, uint256 amount
    );
    event Borrow(
        address indexed from, address indexed to, address indexed operator, uint256 amount, bool isDepositToJOJO
    );
    event Repay(address indexed from, address indexed to, uint256 amount);
    event Withdraw(
        address indexed collateral, address indexed from, address indexed to, address operator, uint256 amount
    );
    event Liquidate(
        address indexed collateral,
        address indexed liquidator,
        address indexed liquidated,
        address operator,
        uint256 collateralAmount,
        uint256 liquidatedAmount,
        uint256 insuranceFee
    );
    event FlashLoan(address indexed collateral, uint256 amount);

    /// @notice to ensure msg.sender is from account or msg.sender is the sub account of from
    /// so that msg.sender can send the transaction
    modifier operatorAccount(address from) {
        require(msg.sender == from || operatorRegistry[from][msg.sender], USDOErrors.CAN_NOT_OPERATOR_ACCOUNT);
        _;
    }

    function deposit(
        address from,
        address collateral,
        uint256 amount,
        address to
    ) external override nonReentrant operatorAccount(from) {
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        DataTypes.UserInfo storage user = userInfo[to];
        //        deposit
        _deposit(reserve, user, amount, collateral, to, from);
    }

    function borrow(
        uint256 amount,
        address to,
        bool isDepositToJOJO,
        address from
    ) external override nonReentrant operatorAccount(from) {
        //     t0BorrowedAmount = borrowedAmount /  getT0Rate
        DataTypes.UserInfo storage user = userInfo[from];
        _borrow(user, isDepositToJOJO, to, amount, from);
        require(_isAccountSafe(user, getTRate()), USDOErrors.AFTER_BORROW_ACCOUNT_IS_NOT_SAFE);
    }

    function repay(uint256 amount, address to) external override nonReentrant returns (uint256) {
        DataTypes.UserInfo storage user = userInfo[to];
        uint256 tRate = getTRate();
        return _repay(user, msg.sender, to, amount, tRate);
    }

    function withdraw(
        address collateral,
        uint256 amount,
        address to,
        address from
    ) external override nonReentrant operatorAccount(from) {
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        DataTypes.UserInfo storage user = userInfo[from];
        _withdraw(reserve, user, amount, collateral, to, from);
        uint256 tRate = getTRate();
        require(_isAccountSafe(user, tRate), USDOErrors.AFTER_WITHDRAW_ACCOUNT_IS_NOT_SAFE);
    }

    function liquidate(
        address liquidated,
        address liquidationCollateral,
        address liquidator,
        uint256 liquidationAmount,
        address depositCollateral,
        uint256 depositAmount,
        uint256 expectLiquidateAmount
    )
        external
        override
        nonReentrant
        operatorAccount(liquidator)
        returns (uint256 actualCollateral, uint256 actualUSDO, uint256 insuranceFee)
    {
        require(liquidator != liquidated, USDOErrors.SELF_LIQUIDATION_NOT_ALLOWED);
        DataTypes.UserInfo storage liquidatorInfo = userInfo[liquidator];
        DataTypes.UserInfo storage liquidatedInfo = userInfo[liquidated];
        require(liquidationAmount != 0, USDOErrors.LIQUIDATE_AMOUNT_IS_ZERO);
        require(
            liquidationAmount <= liquidatedInfo.depositBalance[liquidationCollateral],
            USDOErrors.LIQUIDATE_AMOUNT_IS_TOO_BIG
        );
        uint256 tRate = getTRate();
        // settle the liquidate amount
        (actualCollateral, actualUSDO, insuranceFee) =
            _liquidate(liquidatorInfo, liquidatedInfo, liquidationCollateral, liquidationAmount, tRate);

        require(actualCollateral >= expectLiquidateAmount, USDOErrors.LIQUIDATION_PRICE_PROTECTION);

        _depositOrRepay(depositCollateral, depositAmount, liquidatorInfo, liquidator, tRate);

        // after liquidator take the collateral, need to judge whether liquidator is safe
        require(_isAccountSafe(liquidatorInfo, tRate), "liquidator is not safe");

        emit Liquidate(
            liquidationCollateral, liquidator, liquidated, msg.sender, actualCollateral, actualUSDO, insuranceFee
            );

        // if (liquidatedInfo.collateralList.length == 0) {
        //     _handleBadDebt(liquidated);
        // }
    }

    function handleDebt(address[] calldata liquidatedTraders) external onlyOwner {
        for (uint256 i; i < liquidatedTraders.length; i = i + 1) {
            _handleBadDebt(liquidatedTraders[i]);
        }
    }

    function flashLoan(
        address receiver,
        address collateral,
        uint256 amount,
        address to,
        bytes memory param
    ) external nonFlashLoanReentrant {
        DataTypes.UserInfo storage user = userInfo[msg.sender];
        DataTypes.ReserveInfo storage reserve = reserveInfo[collateral];
        IFlashLoanReceive Ireceiver = IFlashLoanReceive(receiver);
        _withdraw(reserve, user, amount, collateral, receiver, msg.sender);
        // repay
        Ireceiver.JOJOFlashLoan(collateral, amount, to, param);
        require(_isAccountSafe(user, getTRate()), USDOErrors.AFTER_FLASHLOAN_ACCOUNT_IS_NOT_SAFE);
        emit FlashLoan(collateral, amount);
    }

    function _deposit(
        DataTypes.ReserveInfo storage reserve,
        DataTypes.UserInfo storage user,
        uint256 amount,
        address collateral,
        address to,
        address from
    ) internal {
        require(reserve.isDepositAllowed, USDOErrors.RESERVE_NOT_ALLOW_DEPOSIT);
        require(amount != 0, USDOErrors.DEPOSIT_AMOUNT_IS_ZERO);
        IERC20(collateral).safeTransferFrom(from, address(this), amount);
        if (!user.hasCollateral[collateral]) {
            user.hasCollateral[collateral] = true;
            user.collateralList.push(collateral);
        }
        user.depositBalance[collateral] += amount;
        reserve.totalDepositAmount += amount;
        require(
            user.depositBalance[collateral] <= reserve.maxDepositAmountPerAccount,
            USDOErrors.EXCEED_THE_MAX_DEPOSIT_AMOUNT_PER_ACCOUNT
        );
        require(
            reserve.totalDepositAmount <= reserve.maxTotalDepositAmount, USDOErrors.EXCEED_THE_MAX_DEPOSIT_AMOUNT_TOTAL
        );
        emit Deposit(collateral, from, to, msg.sender, amount);
    }

    //    Pass parameter checking, excluding checking legality
    function _borrow(
        DataTypes.UserInfo storage user,
        bool isDepositToJOJO,
        address to,
        uint256 tAmount,
        address from
    ) internal {
        uint256 tRate = getTRate();
        //        tAmount % tRate ？ tAmount / tRate + 1 ： tAmount % tRate
        uint256 t0Amount = tAmount.decimalRemainder(tRate) ? tAmount.decimalDiv(tRate) : tAmount.decimalDiv(tRate) + 1;
        user.t0BorrowBalance += t0Amount;
        user.totalBorrow += tAmount;
        t0TotalBorrowAmount += t0Amount;
        if (isDepositToJOJO) {
            IERC20(USDO).approve(address(JOJODealer), tAmount);
            IDealer(JOJODealer).deposit(0, tAmount, to);
        } else {
            IERC20(USDO).safeTransfer(to, tAmount);
        }
        // Personal account hard cap
        require(
            user.t0BorrowBalance.decimalMul(tRate) <= maxPerAccountBorrowAmount,
            USDOErrors.EXCEED_THE_MAX_BORROW_AMOUNT_PER_ACCOUNT
        );
        // Global account hard cap
        require(
            t0TotalBorrowAmount.decimalMul(tRate) <= maxTotalBorrowAmount, USDOErrors.EXCEED_THE_MAX_BORROW_AMOUNT_TOTAL
        );
        emit Borrow(from, to, msg.sender, tAmount, isDepositToJOJO);
    }

    function _repay(
        DataTypes.UserInfo storage user,
        address payer,
        address to,
        uint256 amount,
        uint256 tRate
    ) internal returns (uint256) {
        require(amount != 0, USDOErrors.REPAY_AMOUNT_IS_ZERO);
        uint256 USDOBorrowed = user.t0BorrowBalance.decimalMul(tRate);
        uint256 tBorrowAmount;
        uint256 t0Amount;
        if (USDOBorrowed <= amount) {
            tBorrowAmount = USDOBorrowed;
            t0Amount = user.t0BorrowBalance;
        } else {
            tBorrowAmount = amount;
            t0Amount = amount.decimalDiv(tRate);
        }
        IERC20(USDO).safeTransferFrom(payer, address(this), tBorrowAmount);
        user.t0BorrowBalance -= t0Amount;
        user.totalRepay += tBorrowAmount;
        t0TotalBorrowAmount -= t0Amount;
        emit Repay(payer, to, tBorrowAmount);
        return tBorrowAmount;
    }

    function _withdraw(
        DataTypes.ReserveInfo storage reserve,
        DataTypes.UserInfo storage user,
        uint256 amount,
        address collateral,
        address to,
        address from
    ) internal {
        require(amount != 0, USDOErrors.WITHDRAW_AMOUNT_IS_ZERO);
        require(amount <= user.depositBalance[collateral], USDOErrors.WITHDRAW_AMOUNT_IS_TOO_BIG);
        reserve.totalDepositAmount -= amount;
        user.depositBalance[collateral] -= amount;
        IERC20(collateral).safeTransfer(to, amount);
        if (user.depositBalance[collateral] == 0) {
            _removeCollateral(user, collateral);
        }
        emit Withdraw(collateral, from, to, msg.sender, amount);
    }

    /// @notice liquidate is divided into three steps,
    // 1. determine whether liquidatedTrader is safe
    // 2. calculate the collateral amount actually liquidated
    // 3. transfer the insurance fee
    function _liquidate(
        DataTypes.UserInfo storage liquidatorInfo,
        DataTypes.UserInfo storage liquidatedInfo,
        address collateral,
        uint256 amount,
        uint256 tRate
    ) internal returns (uint256 actualCollateral, uint256 actualUSDO, uint256 insuranceFee) {
        require(_isStartLiquidation(liquidatedInfo, tRate), USDOErrors.ACCOUNT_IS_SAFE);

        (actualCollateral, actualUSDO, insuranceFee) =
            _settleCollateralAndUSDO(liquidatedInfo, liquidatorInfo, collateral, amount, tRate);

        // transfer the insurance fee to the insurance account
        IERC20(USDO).safeTransfer(insurance, insuranceFee);
    }

    function _removeCollateral(DataTypes.UserInfo storage user, address collateral) internal {
        user.hasCollateral[collateral] = false;
        address[] storage collaterals = user.collateralList;
        for (uint256 i; i < collaterals.length; i = i + 1) {
            if (collaterals[i] == collateral) {
                collaterals[i] = collaterals[collaterals.length - 1];
                collaterals.pop();
                break;
            }
        }
    }

    /// @notice liquidate is trying to pay off all USDO debt instead of selling all collateral
    function _settleCollateralAndUSDO(
        DataTypes.UserInfo storage liquidatedInfo,
        DataTypes.UserInfo storage liquidatorInfo,
        address collateral,
        uint256 amount,
        uint256 tRate
    ) internal returns (uint256 actualCollateral, uint256 actualUSDO, uint256 insuranceFee) {
        DataTypes.ReserveInfo memory reserve = reserveInfo[collateral];
        // discounted price
        uint256 priceOff = IPriceChainLink(reserve.oracle).getAssetPrice().decimalMul(
            DecimalMath.ONE - reserve.liquidityInfo.liquidationPriceOff
        );

        uint256 liquidateAmount = amount.decimalMul(priceOff).decimalMul(1e18 - reserve.liquidityInfo.insuranceFeeRate);
        uint256 USDOBorrowed = liquidatedInfo.t0BorrowBalance.decimalMul(tRate);
        uint256 actualLiquidatorT0;
        uint256 actualLiquidatedT0;
        /*
        liquidateAmount <= USDOBorrowed
        liquidateAmount = amount * priceOff * (1-insuranceFee)
        actualUSDO = actualCollateral * priceOff
        insuranceFee = actualCollateral * priceOff * insuranceFeeRate
        */
        if (liquidateAmount <= USDOBorrowed) {
            actualCollateral = amount;
            actualLiquidatorT0 = amount.decimalMul(priceOff).decimalDiv(tRate);
            actualUSDO = amount.decimalMul(priceOff);
            insuranceFee = amount.decimalMul(priceOff).decimalMul(reserve.liquidityInfo.insuranceFeeRate);
            actualLiquidatedT0 = liquidateAmount.decimalDiv(tRate);
        } else {
            //            collateral amount
            //            actualUSDO = actualCollateral * priceOff
            //            = USDOBorrowed * priceOff / priceOff * (1-insuranceFeeRate)
            //            = USDOBorrowed / (1-insuranceFeeRate)
            //            insuranceFee = actualCollateral * priceOff * insuranceFeeRate
            //            = USDOBorrowed * insuranceFeeRate / (1- insuranceFeeRate)
            actualCollateral =
                USDOBorrowed.decimalDiv(priceOff).decimalDiv(1e18 - reserve.liquidityInfo.insuranceFeeRate);
            insuranceFee = USDOBorrowed.decimalMul(reserve.liquidityInfo.insuranceFeeRate).decimalDiv(
                1e18 - reserve.liquidityInfo.insuranceFeeRate
            );
            actualUSDO = USDOBorrowed.decimalDiv((1e18 - reserve.liquidityInfo.insuranceFeeRate));
            actualLiquidatorT0 = actualUSDO.decimalDiv(tRate);
            actualLiquidatedT0 = liquidatedInfo.t0BorrowBalance;
        }

        if (actualCollateral == liquidatedInfo.depositBalance[collateral]) {
            _removeCollateral(liquidatedInfo, collateral);
        }

        liquidatedInfo.depositBalance[collateral] -= actualCollateral;
        liquidatorInfo.depositBalance[collateral] += actualCollateral;
        liquidatedInfo.t0BorrowBalance -= actualLiquidatedT0;
        liquidatedInfo.totalRepay += actualUSDO - insuranceFee;
        liquidatorInfo.t0BorrowBalance += actualLiquidatorT0;
        liquidatorInfo.totalBorrow += actualUSDO;
        t0TotalBorrowAmount += actualLiquidatorT0 - actualLiquidatedT0;

        if (!liquidatorInfo.hasCollateral[collateral]) {
            liquidatorInfo.collateralList.push(collateral);
            liquidatorInfo.hasCollateral[collateral] = true;
        }
    }

    function _depositOrRepay(
        address depositCollateral,
        uint256 depositAmount,
        DataTypes.UserInfo storage liquidatorInfo,
        address liquidator,
        uint256 tRate
    ) internal {
        if (depositCollateral != address(0)) {
            // if depositCollateral is USDO, which means user ensure account security by repaying USDO
            if (depositCollateral == USDO) {
                //                msg.sender liquidator
                _repay(liquidatorInfo, liquidator, liquidator, depositAmount, tRate);
            } else {
                // or user deposit new collateral type to keep account security
                _deposit(
                    reserveInfo[depositCollateral],
                    liquidatorInfo,
                    depositAmount,
                    depositCollateral,
                    liquidator,
                    liquidator
                );
            }
        }
    }

    /// @notice handle the bad debt
    /// @param liquidatedTrader need to be liquidated
    function _handleBadDebt(address liquidatedTrader) internal {
        DataTypes.UserInfo storage liquidatedTraderInfo = userInfo[liquidatedTrader];
        uint256 tRate = getTRate();
        if (liquidatedTraderInfo.collateralList.length == 0 && _isStartLiquidation(liquidatedTraderInfo, tRate)) {
            DataTypes.UserInfo storage insuranceInfo = userInfo[insurance];
            uint256 borrowUSDOT0 = liquidatedTraderInfo.t0BorrowBalance;
            insuranceInfo.t0BorrowBalance += borrowUSDOT0;
            liquidatedTraderInfo.t0BorrowBalance = 0;
            liquidatedTraderInfo.totalBorrow = 0;
            liquidatedTraderInfo.totalRepay = 0;
            emit HandleBadDebt(liquidatedTrader, borrowUSDOT0);
        }
    }
}