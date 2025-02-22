// SPDX-License-Identifier: UNLICENSED

// Cauldron

//    (                (   (
//    )\      )    (   )\  )\ )  (
//  (((_)  ( /(   ))\ ((_)(()/(  )(    (    (
//  )\___  )(_)) /((_) _   ((_))(()\   )\   )\ )
// ((/ __|((_)_ (_))( | |  _| |  ((_) ((_) _(_/(
//  | (__ / _` || || || |/ _` | | '_|/ _ \| ' \))
//   \___|\__,_| \_,_||_|\__,_| |_|  \___/|_||_|

pragma solidity >=0.8.0;
import "./CauldronV4.sol";
import "libraries/CvxLib.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract CvxCauldron is CauldronV4 {
    address public immutable rewardRouter;
    address public immutable baseContract;
    uint256 public rewardPershare;
    mapping(address => uint256) public userRwardDebt;

    error InsufficientStakeBalance();

    constructor(
        IBentoBoxV1 bentoBox_,
        IERC20 magicInternetMoney_,
        address distributeTo_,
        address _arvinDegenNftAddress,
        address _rewardRouter,
        address _baseContract
    ) CauldronV4(bentoBox_, magicInternetMoney_, distributeTo_, _arvinDegenNftAddress) {
        baseContract = _baseContract;
        rewardRouter = _rewardRouter;
        blacklistedCallees[_rewardRouter] = true;
        blacklistedCallees[address(collateral)] = true;
    }

    function init(bytes memory data) public payable virtual override {
        address(baseContract).delegatecall(abi.encodeWithSelector(IMasterContract.init.selector, data));
        blacklistedCallees[address(rewardRouter)] = true;
        collateral.approve(address(bentoBox), type(uint256).max);
        blacklistedCallees[address(collateral)] = true;
    }

    function _beforeAddCollateral(address user, uint256) internal virtual override {
        _harvest(user);
    }

    function _beforeRemoveCollateral(address from, address, uint256 collateralShare) internal virtual override {
        _harvest(from);
    }

    function _afterAddCollateral(address user, uint256 collateralShare) internal virtual override {
        _stake(user, collateralShare);
        _updateUserDebt(user);
    }

    function _afterRemoveCollateral(address from, address, uint256 collateralShare) internal virtual override {
        _unstake(collateralShare);
        _updateUserDebt(from);
    }

    function _beforeUserLiquidated(address user, uint256, uint256, uint256 collateralShare) internal virtual override {
        _harvest(user);
    }

    function _afterUserLiquidated(address user, uint256 collateralShare) internal virtual override {
        _unstake(collateralShare);
        _updateUserDebt(user);
    }

    function withdrawToken(address token) external {
        if (msg.sender != owner) revert CallerIsNotTheOwner();
        if (token == address(collateral)) return;
        IStrictERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    //the convex contract can not get the pending reward on chain, so the pending reward have to be transmited by the frontend.
    function pendingReward(address user, uint256 pending) external view returns (uint256) {
        uint256 rpc = rewardPershare;
        if (pending > 0) {
            rpc += (pending * 1e20) / totalCollateralShare;
        }
        return (userCollateralShare[user] * rpc) / 1e20 - userRwardDebt[user];
    }

    function claim() external {
        address user = msg.sender;
        uint256 ucs = userCollateralShare[user];
        if (ucs == 0) return;
        _harvest(user);
        _updateUserDebt(user);
    }

    function _updateUserDebt(address user) private {
        userRwardDebt[user] = (userCollateralShare[user] * rewardPershare) / 1e20;
    }

    function _stake(address user, uint256 collateralShare) private {
        CvxLib.stake(bentoBox, collateral, rewardRouter, collateralShare);
    }

    function _unstake(uint256 collateralShare) private {
        CvxLib.unstake(bentoBox, collateral, rewardRouter, collateralShare);
    }

    function _harvest(address user) private {
        rewardPershare = CvxLib.harvest(
            rewardRouter,
            user,
            userCollateralShare[user],
            userRwardDebt[user],
            rewardPershare,
            totalCollateralShare
        );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

// Cauldron

//    (                (   (
//    )\      )    (   )\  )\ )  (
//  (((_)  ( /(   ))\ ((_)(()/(  )(    (    (
//  )\___  )(_)) /((_) _   ((_))(()\   )\   )\ )
// ((/ __|((_)_ (_))( | |  _| |  ((_) ((_) _(_/(
//  | (__ / _` || || || |/ _` | | '_|/ _ \| ' \))
//   \___|\__,_| \_,_||_|\__,_| |_|  \___/|_||_|

pragma solidity >=0.8.0;
import "BoringSolidity/BoringOwnable.sol";
import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/interfaces/IMasterContract.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IOracle.sol";
import "interfaces/ISwapperV2.sol";
import "interfaces/IBentoBoxV1.sol";
import "interfaces/IBentoBoxOwner.sol";
import "interfaces/IArvinDegenNFT.sol";
import "interfaces/IMasterChef.sol";

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract CauldronV4 is BoringOwnable, IMasterContract {
    using RebaseLibrary for Rebase;

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint128 accruedAmount);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogFeeTo(address indexed newFeeTo);
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event LogInterestChange(uint64 oldInterestRate, uint64 newInterestRate);
    event LogChangeBorrowLimit(uint128 newLimit, uint128 perAddressPart);
    event LogChangeBlacklistedCallee(address indexed account, bool blacklisted);
    event LogRepayForAll(uint256 amount, uint128 previousElastic, uint128 newElastic);

    event LogLiquidation(
        address indexed from,
        address indexed user,
        address indexed to,
        uint256 collateralShare,
        uint256 borrowAmount,
        uint256 borrowPart
    );

    error CauldronAlreadyInitialized();
    error CauldronBadPair();
    error CauldronUserInsolvent();
    error CauldronSkimTooMuch();
    error CauldronCantCall();
    error CauldronCallFailed();
    error CauldronRateNotOk();
    error CauldronStrategyAlreadyReleased();
    error CauldronAllAreSolvent();
    error InterestRateIncreaseTooMuch();
    error UpdateOnlyEvery3Days();
    error InvalidCallee();
    error CallerIsNotTheOwner();
    error BorrowLimitReached();
    error TotalElasticTooSmall();

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    CauldronV4 public immutable masterContract;
    IERC20 public immutable magicInternetMoney;

    // MasterContract variables
    address public feeTo;
    address public immutable distributeTo;
    IArvinDegenNFT public immutable arvinDegenNFT;

    // Per clone variables
    // Clone init settings
    IERC20 public collateral;
    IOracle public oracle;
    bytes public oracleData;

    struct BorrowCap {
        uint128 total;
        uint128 borrowPartPerAddress;
    }

    BorrowCap public borrowLimit;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers
    uint256 public interestPerPart;

    // User balances
    mapping(address => uint256) public userCollateralShare;
    mapping(address => uint256) public userBorrowPart;
    mapping(address => uint256) public userBorrowInterestDebt;

    // Callee restrictions
    mapping(address => bool) public blacklistedCallees;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        uint64 INTEREST_PER_SECOND;
    }

    AccrueInfo public accrueInfo;

    uint64 internal constant ONE_PERCENT_RATE = 317097920;

    /// @notice tracking of last interest update
    uint256 internal lastInterestUpdate;

    // Settings
    uint256 public COLLATERIZATION_RATE;
    uint256 internal constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)

    uint256 internal constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 public LIQUIDATION_MULTIPLIER;
    uint256 internal constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    uint256 public BORROW_OPENING_FEE;
    uint256 internal constant BORROW_OPENING_FEE_PRECISION = 1e5;

    uint256 internal constant DISTRIBUTION_PART = 10;
    uint256 internal constant DISTRIBUTION_PRECISION = 100;
    uint256 internal constant FEE_DIV = 1e12;

    function onlyMasterContractOwner() private view {
        if (msg.sender != masterContract.owner()) revert CallerIsNotTheOwner();
    }

    // /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_, IERC20 magicInternetMoney_, address distributeTo_, address _arvinDegenNftAddress) {
        bentoBox = bentoBox_;
        magicInternetMoney = magicInternetMoney_;
        masterContract = this;
        distributeTo = distributeTo_;
        arvinDegenNFT = IArvinDegenNFT(_arvinDegenNftAddress);
        blacklistedCallees[address(bentoBox)] = true;
        blacklistedCallees[address(this)] = true;
        blacklistedCallees[distributeTo_] = true;
        blacklistedCallees[BoringOwnable(address(bentoBox)).owner()] = true;
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (IERC20 collateral, IERC20 asset, IOracle oracle, bytes oracleData)
    function init(bytes memory data) public payable virtual override {
        if (address(collateral) != address(0)) revert CauldronAlreadyInitialized();
        (
            collateral,
            oracle,
            oracleData,
            accrueInfo.INTEREST_PER_SECOND,
            LIQUIDATION_MULTIPLIER,
            COLLATERIZATION_RATE,
            BORROW_OPENING_FEE
        ) = abi.decode(data, (IERC20, IOracle, bytes, uint64, uint256, uint256, uint256));
        borrowLimit = BorrowCap(type(uint128).max, type(uint128).max);
        if (address(collateral) == address(0)) revert CauldronBadPair();

        magicInternetMoney.approve(address(bentoBox), type(uint256).max);

        blacklistedCallees[address(bentoBox)] = true;
        blacklistedCallees[address(this)] = true;
        blacklistedCallees[distributeTo] = true;
        blacklistedCallees[BoringOwnable(address(bentoBox)).owner()] = true;

        (, exchangeRate) = oracle.get(oracleData);

        accrue();
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            accrueInfo = _accrueInfo;
            return;
        }

        // Accrue interest
        uint128 extraAmount = uint128((uint256(_totalBorrow.elastic) * _accrueInfo.INTEREST_PER_SECOND * elapsedTime) / 1e18);
        _totalBorrow.elastic = _totalBorrow.elastic + extraAmount;
        interestPerPart += (extraAmount * FEE_DIV) / _totalBorrow.base;
        _accrueInfo.feesEarned = _accrueInfo.feesEarned + extraAmount;
        totalBorrow = _totalBorrow;
        accrueInfo = _accrueInfo;

        emit LogAccrue(extraAmount);
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a third parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            bentoBox.toAmount(
                collateral,
                ((collateralShare * EXCHANGE_RATE_PRECISION) / COLLATERIZATION_RATE_PRECISION) * COLLATERIZATION_RATE,
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            (borrowPart * _totalBorrow.elastic * _exchangeRate) / _totalBorrow.base;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    function solvent() private {
        (, uint256 _exchangeRate) = updateExchangeRate();
        if (!_isSolvent(msg.sender, _exchangeRate)) revert CauldronUserInsolvent();
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    function _beforeAddCollateral(address user, uint256 collateralShare) internal virtual {}

    function _afterAddCollateral(address user, uint256 collateralShare) internal virtual {}

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.x
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(address to, bool skim, uint256 share) public virtual {
        _beforeAddCollateral(to, share);
        userCollateralShare[to] = userCollateralShare[to] + share;
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare + share;
        if (skim) {
            if (share > bentoBox.balanceOf(collateral, address(this)) - oldTotalCollateralShare) revert CauldronSkimTooMuch();
        } else {
            bentoBox.transfer(collateral, msg.sender, address(this), share);
        }
        _afterAddCollateral(to, share);
        emit LogAddCollateral(skim ? address(bentoBox) : msg.sender, to, share);
    }

    function _beforeRemoveCollateral(address from, address to, uint256 collateralShare) internal virtual {}

    function _afterRemoveCollateral(address from, address to, uint256 collateralShare) internal virtual {}

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address to, uint256 share) internal virtual {
        _beforeRemoveCollateral(msg.sender, to, share);
        userCollateralShare[msg.sender] = userCollateralShare[msg.sender] - share;
        totalCollateralShare = totalCollateralShare - share;
        _afterRemoveCollateral(msg.sender, to, share);
        emit LogRemoveCollateral(msg.sender, to, share);
        bentoBox.transfer(collateral, address(this), to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address to, uint256 share) public {
        // accrue must be called because we check solvency
        accrue();
        _removeCollateral(to, share);
        solvent();
    }

    function _preBorrowAction(address to, uint256 amount, uint256 newBorrowPart, uint256 part) internal virtual {}

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address to, uint256 amount) internal returns (uint256 part, uint256 share) {
        handleRefund(msg.sender);
        uint256 feeAmount = (amount * BORROW_OPENING_FEE) / BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow
        (Rebase memory _totalBorrow, uint256 temp) = totalBorrow.add(amount + feeAmount, true);
        part = temp;
        BorrowCap memory cap = borrowLimit;

        if (_totalBorrow.elastic > cap.total) revert BorrowLimitReached();

        accrueInfo.feesEarned = accrueInfo.feesEarned + (uint128(feeAmount));

        uint256 newBorrowPart = userBorrowPart[msg.sender] + (part);
        if (newBorrowPart > cap.borrowPartPerAddress) revert BorrowLimitReached();
        _preBorrowAction(to, amount, newBorrowPart, part);
        userBorrowPart[msg.sender] = newBorrowPart;
        userBorrowInterestDebt[msg.sender] = (newBorrowPart * interestPerPart) / FEE_DIV;

        // As long as there are tokens on this contract you can 'mint'... this enables limiting borrows
        share = bentoBox.toShare(magicInternetMoney, amount, false);
        bentoBox.transfer(magicInternetMoney, address(this), to, share);
        IMasterChef(distributeTo).deposit(msg.sender);
        totalBorrow = _totalBorrow;
        emit LogBorrow(msg.sender, to, amount + feeAmount, part);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address to, uint256 amount) public returns (uint256 part, uint256 share) {
        accrue();
        (part, share) = _borrow(to, amount);
        solvent();
    }

    function handleRefund(address user) private {
        uint256 _interestRefund = (((userBorrowPart[user] * interestPerPart) / FEE_DIV - userBorrowInterestDebt[user]) *
            arvinDegenNFT.getRefundRatio(user)) / 100;
        if (_interestRefund > 0) {
            // uint256 share = totalBorrow.toBase(_interestRefund, false);
            uint256 share = bentoBox.toShare(magicInternetMoney, _interestRefund, false);
            bentoBox.transfer(magicInternetMoney, (address(this)), user, share);
            accrueInfo.feesEarned -= uint128(_interestRefund);
        }
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(address to, bool skim, uint256 part) internal returns (uint256 amount) {
        handleRefund(to);
        userBorrowPart[to] = userBorrowPart[to] - (part);
        IMasterChef(distributeTo).withdraw(to);
        (totalBorrow, amount) = totalBorrow.sub(part, true);
        userBorrowInterestDebt[to] = (userBorrowPart[to] * interestPerPart) / FEE_DIV;
        uint256 share = bentoBox.toShare(magicInternetMoney, amount, true);
        bentoBox.transfer(magicInternetMoney, skim ? address(bentoBox) : msg.sender, address(this), share);
        emit LogRepay(skim ? address(bentoBox) : msg.sender, to, amount, part);
    }

    /// @notice Repays a loan.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(address to, bool skim, uint256 part) public returns (uint256 amount) {
        accrue();
        amount = _repay(to, skim, part);
    }

    // Functions that need accrue to be called
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;

    // Functions that don't need accrue to be called
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;

    // Function on BentoBox
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;

    // Any external call (except to BentoBox)
    uint8 internal constant ACTION_CALL = 30;
    uint8 internal constant ACTION_LIQUIDATE = 31;
    uint8 internal constant ACTION_RELEASE_COLLATERAL_FROM_STRATEGY = 33;

    // Custom cook actions
    uint8 internal constant ACTION_CUSTOM_START_INDEX = 100;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(int256 inNum, uint256 value1, uint256 value2) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0 ? uint256(inNum) : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(bytes memory data, uint256 value, uint256 value1, uint256 value2) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return bentoBox.deposit{value: value}(token, msg.sender, to, uint256(amount), uint256(share));
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(bytes memory data, uint256 value1, uint256 value2) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        return bentoBox.withdraw(token, msg.sender, to, _num(amount, value1, value2), _num(share, value1, value2));
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` are not allowed for obvious security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(uint256 value, bytes memory data, uint256 value1, uint256 value2) internal returns (bytes memory, uint8) {
        (address callee, bytes memory callData, bool useValue1, bool useValue2, uint8 returnValues) = abi.decode(
            data,
            (address, bytes, bool, bool, uint8)
        );

        if (useValue1 && !useValue2) {
            callData = abi.encodePacked(callData, value1);
        } else if (!useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value2);
        } else if (useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value1, value2);
        }

        if (blacklistedCallees[callee]) revert CauldronCantCall();

        (bool success, bytes memory returnData) = callee.call{value: value}(callData);
        if (!success) revert CauldronCallFailed();
        return (returnData, returnValues);
    }

    function _additionalCookAction(
        uint8 action,
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal virtual returns (bytes memory, uint8) {}

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2) {
        CookStatus memory status;
        uint64 previousStrategyTargetPercentage = type(uint64).max;

        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (!status.hasAccrued && action < 10) {
                accrue();
                status.hasAccrued = true;
            }
            if (action == ACTION_ADD_COLLATERAL) {
                (int256 share, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                addCollateral(to, skim, _num(share, value1, value2));
            } else if (action == ACTION_REPAY) {
                (int256 part, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                _repay(to, skim, _num(part, value1, value2));
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (int256 share, address to) = abi.decode(datas[i], (int256, address));
                _removeCollateral(to, _num(share, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_BORROW) {
                (int256 amount, address to) = abi.decode(datas[i], (int256, address));
                (value1, value2) = _borrow(to, _num(amount, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                (bool must_update, uint256 minRate, uint256 maxRate) = abi.decode(datas[i], (bool, uint256, uint256));
                (bool updated, uint256 rate) = updateExchangeRate();
                if (!((!must_update || updated) && rate > minRate && (maxRate == 0 || rate > maxRate))) revert CauldronRateNotOk();
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (address user, address _masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) = abi.decode(
                    datas[i],
                    (address, address, bool, uint8, bytes32, bytes32)
                );
                bentoBox.setMasterContractApproval(user, _masterContract, approved, v, r, s);
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(datas[i], values[i], value1, value2);
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_BENTO_TRANSFER) {
                (IERC20 token, address to, int256 share) = abi.decode(datas[i], (IERC20, address, int256));
                bentoBox.transfer(token, msg.sender, to, _num(share, value1, value2));
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                (IERC20 token, address[] memory tos, uint256[] memory shares) = abi.decode(datas[i], (IERC20, address[], uint256[]));
                bentoBox.transferMultiple(token, msg.sender, tos, shares);
            } else if (action == ACTION_CALL) {
                (bytes memory returnData, uint8 returnValues) = _call(values[i], datas[i], value1, value2);

                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            } else if (action == ACTION_GET_REPAY_SHARE) {
                int256 part = abi.decode(datas[i], (int256));
                value1 = bentoBox.toShare(magicInternetMoney, totalBorrow.toElastic(_num(part, value1, value2), true), true);
            } else if (action == ACTION_GET_REPAY_PART) {
                int256 amount = abi.decode(datas[i], (int256));
                value1 = totalBorrow.toBase(_num(amount, value1, value2), false);
            } else if (action == ACTION_LIQUIDATE) {
                (address[] memory users, uint256[] memory maxBorrowParts, address to, ISwapperV2 swapper, bytes memory swapperData) = abi
                    .decode(datas[i], (address[], uint256[], address, ISwapperV2, bytes));
                liquidate(users, maxBorrowParts, to, swapper, swapperData);
            } else if (action == ACTION_RELEASE_COLLATERAL_FROM_STRATEGY) {
                if (previousStrategyTargetPercentage != type(uint64).max) revert CauldronStrategyAlreadyReleased();

                (, previousStrategyTargetPercentage, ) = bentoBox.strategyData(collateral);
                IBentoBoxOwner(bentoBox.owner()).setStrategyTargetPercentageAndRebalance(collateral, 0);
            } else {
                (bytes memory returnData, uint8 returnValues) = _additionalCookAction(action, values[i], datas[i], value1, value2);
                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            }
        }

        if (previousStrategyTargetPercentage != type(uint64).max) {
            IBentoBoxOwner(bentoBox.owner()).setStrategyTargetPercentageAndRebalance(collateral, previousStrategyTargetPercentage);
        }

        if (status.needsSolvencyCheck) {
            (, uint256 _exchangeRate) = updateExchangeRate();
            if (!_isSolvent(msg.sender, _exchangeRate)) revert CauldronUserInsolvent();
        }
    }

    function _beforeUsersLiquidated(address[] memory users, uint256[] memory maxBorrowPart) internal virtual {}

    function _beforeUserLiquidated(address user, uint256 borrowPart, uint256 borrowAmount, uint256 collateralShare) internal virtual {}

    function _afterUserLiquidated(address user, uint256 collateralShare) internal virtual {}

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param to Address of the receiver in open liquidations if `swapper` is zero.
    function liquidate(
        address[] memory users,
        uint256[] memory maxBorrowParts,
        address to,
        ISwapperV2 swapper,
        bytes memory swapperData
    ) public virtual {
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);
        _beforeUsersLiquidated(users, maxBorrowParts);

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = maxBorrowParts[i] > availableBorrowPart ? availableBorrowPart : maxBorrowParts[i];
                    userBorrowPart[user] = availableBorrowPart - borrowPart;
                    userBorrowInterestDebt[to] = (userBorrowPart[to] * interestPerPart) / FEE_DIV;
                }
                uint256 borrowAmount = totalBorrow.toElastic(borrowPart, false);
                uint256 collateralShare = bentoBoxTotals.toBase(
                    ((borrowAmount * LIQUIDATION_MULTIPLIER * _exchangeRate) / LIQUIDATION_MULTIPLIER_PRECISION) * EXCHANGE_RATE_PRECISION,
                    false
                );

                _beforeUserLiquidated(user, borrowPart, borrowAmount, collateralShare);
                userCollateralShare[user] = userCollateralShare[user] - (collateralShare);
                _afterUserLiquidated(user, collateralShare);

                emit LogRemoveCollateral(user, to, collateralShare);
                emit LogRepay(msg.sender, user, borrowAmount, borrowPart);
                emit LogLiquidation(msg.sender, user, to, collateralShare, borrowAmount, borrowPart);

                // Keep totals
                allCollateralShare = allCollateralShare + collateralShare;
                allBorrowAmount = allBorrowAmount + borrowAmount;
                allBorrowPart = allBorrowPart + borrowPart;
            }
        }
        if (allBorrowAmount == 0) revert CauldronAllAreSolvent();
        IMasterChef(distributeTo).withdraw(users);
        totalBorrow.elastic = totalBorrow.elastic - uint128(allBorrowAmount);
        totalBorrow.base = totalBorrow.base - uint128(allBorrowPart);
        totalCollateralShare = totalCollateralShare - (allCollateralShare);

        // Apply a percentual fee share to sSpell holders

        {
            uint256 distributionAmount = (((allBorrowAmount * LIQUIDATION_MULTIPLIER) /
                LIQUIDATION_MULTIPLIER_PRECISION -
                allBorrowAmount) * DISTRIBUTION_PART) / DISTRIBUTION_PRECISION; // Distribution Amount
            allBorrowAmount = allBorrowAmount + distributionAmount;
            accrueInfo.feesEarned = accrueInfo.feesEarned + uint128(distributionAmount);
        }

        uint256 allBorrowShare = bentoBox.toShare(magicInternetMoney, allBorrowAmount, true);

        // Swap using a swapper freely chosen by the caller
        // Open (flash) liquidation: get proceeds first and provide the borrow after
        bentoBox.transfer(collateral, address(this), to, allCollateralShare);
        if (swapper != ISwapperV2(address(0))) {
            swapper.swap(address(collateral), address(magicInternetMoney), msg.sender, allBorrowShare, allCollateralShare, swapperData);
        }

        allBorrowShare = bentoBox.toShare(magicInternetMoney, allBorrowAmount, true);
        bentoBox.transfer(magicInternetMoney, msg.sender, address(this), allBorrowShare);
    }

    /// @notice Withdraws the fees accumulated.
    function withdrawFees() public {
        accrue();
        address _feeTo = masterContract.feeTo();
        address _distributeTo = distributeTo;
        uint256 share = bentoBox.toShare(magicInternetMoney, accrueInfo.feesEarned, false);
        uint256 shareNeedWithdraw = IMasterChef(_distributeTo).getShareThatShouldDistribute();
        if (shareNeedWithdraw > 0) {
            (uint256 amountOut, ) = bentoBox.withdraw(
                magicInternetMoney,
                address(this),
                address(this),
                0,
                (share * shareNeedWithdraw) / 100
            );
            magicInternetMoney.approve(_distributeTo, amountOut);
            IMasterChef(_distributeTo).addRewardToPool(amountOut);
        }
        accrueInfo.feesEarned = 0;

        bentoBox.transfer(magicInternetMoney, address(this), _feeTo, (share * (100 - shareNeedWithdraw)) / 100);
        emit LogWithdrawFees(_feeTo, (share * (100 - shareNeedWithdraw)) / 100);
        if (shareNeedWithdraw > 0) {
            emit LogWithdrawFees(_distributeTo, (share * shareNeedWithdraw) / 100);
        }
    }

    /// @notice Sets the beneficiary of interest accrued.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public {
        if (msg.sender != owner) revert CallerIsNotTheOwner();
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    /// @notice reduces the supply of MIM
    /// @param amount amount to reduce supply by
    function reduceSupply(uint256 amount) public {
        onlyMasterContractOwner();
        uint256 maxAmount = bentoBox.toAmount(magicInternetMoney, bentoBox.balanceOf(magicInternetMoney, address(this)), false);
        amount = maxAmount > amount ? amount : maxAmount;
        bentoBox.withdraw(magicInternetMoney, address(this), msg.sender, amount, 0);
    }

    /// @notice allows to change the interest rate
    /// @param newInterestRate new interest rate
    function changeInterestRate(uint64 newInterestRate) public {
        onlyMasterContractOwner();
        uint64 oldInterestRate = accrueInfo.INTEREST_PER_SECOND;

        if (!(newInterestRate < oldInterestRate + (oldInterestRate * 3) / 4 || newInterestRate <= ONE_PERCENT_RATE))
            revert InterestRateIncreaseTooMuch();
        if (lastInterestUpdate + 3 days >= block.timestamp) revert UpdateOnlyEvery3Days();

        lastInterestUpdate = block.timestamp;
        accrueInfo.INTEREST_PER_SECOND = newInterestRate;
        emit LogInterestChange(oldInterestRate, newInterestRate);
    }

    /// @notice allows to change the borrow limit
    /// @param newBorrowLimit new borrow limit
    /// @param perAddressPart new borrow limit per address
    function changeBorrowLimit(uint128 newBorrowLimit, uint128 perAddressPart) public {
        onlyMasterContractOwner();
        borrowLimit = BorrowCap(newBorrowLimit, perAddressPart);
        emit LogChangeBorrowLimit(newBorrowLimit, perAddressPart);
    }

    /// @notice allows to change blacklisted callees
    /// @param callee callee to blacklist or not
    /// @param blacklisted true when the callee cannot be used in call cook action
    function setBlacklistedCallee(address callee, bool blacklisted) public {
        onlyMasterContractOwner();
        if (callee == address(bentoBox) || callee == address(this)) revert InvalidCallee();

        blacklistedCallees[callee] = blacklisted;
        emit LogChangeBlacklistedCallee(callee, blacklisted);
    }

    /// @notice Used to auto repay everyone liabilities'.
    /// Transfer MIM deposit to DegenBox for this Cauldron and increase the totalBorrow base or skim
    /// all mim inside this contract
    function repayForAll(uint128 amount, bool skim) public returns (uint128) {
        accrue();

        if (skim) {
            // ignore amount and take every mim in this contract since it could be taken by anyone, the next block.
            amount = uint128(magicInternetMoney.balanceOf(address(this)));
            bentoBox.deposit(magicInternetMoney, address(this), address(this), amount, 0);
        } else {
            bentoBox.transfer(magicInternetMoney, msg.sender, address(this), bentoBox.toShare(magicInternetMoney, amount, true));
        }

        uint128 previousElastic = totalBorrow.elastic;

        if (previousElastic - amount <= 1000 * 1e18) revert TotalElasticTooSmall();

        totalBorrow.elastic = previousElastic - amount;

        emit LogRepayForAll(amount, previousElastic, totalBorrow.elastic);
        return amount;
    }
}

pragma solidity >=0.8.0;
import "interfaces/IConvexWrapper.sol";
import "interfaces/IBentoBoxV1.sol";
import "BoringSolidity/interfaces/IERC20.sol";

interface ICvx {
    function claimable_reward(address token, address user) external view returns (uint256);
}

library CvxLib {
    IStrictERC20 constant crv = IStrictERC20(0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978);

    function getClaimable(address cvxToken, address user) external view returns (uint256) {
        return ICvx(cvxToken).claimable_reward(address(crv), user);
    }

    function unstake(IBentoBoxV1 bentoBox, IERC20 collateral, address rewardRouter, uint256 collateralShare) external {
        uint256 amount = bentoBox.toAmount(collateral, collateralShare, false);
        bentoBox.deposit(collateral, address(this), address(this), 0, collateralShare);
    }

    function stake(IBentoBoxV1 bentoBox, IERC20 collateral, address rewardRouter, uint256 collateralShare) external {
        (uint256 amount, ) = bentoBox.withdraw(collateral, address(this), address(this), 0, collateralShare);
    }

    function harvest(
        address rewardRouter,
        address user,
        uint256 userCollateralShare,
        uint256 userRwardDebt,
        uint256 rewardPershare,
        uint256 totalCollateralShare
    ) external returns (uint256) {
        uint256 lastBalance = crv.balanceOf(address(this));
        IConvexWrapper(rewardRouter).getReward(address(this));
        uint256 tcs = totalCollateralShare;
        if (tcs > 0) {
            rewardPershare += ((crv.balanceOf(address(this)) - lastBalance) * 1e20) / tcs;
        }
        uint256 last = userRwardDebt;
        uint256 curr = (userCollateralShare * rewardPershare) / 1e20;

        if (curr > last) {
            crv.transfer(user, curr - last);
        }
        return rewardPershare;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISwapperV2 {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain IERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        address fromToken,
        address toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom,
        bytes calldata data
    ) external returns (uint256 extraShare, uint256 shareReturned);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IStrategy.sol";

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

interface IBatchFlashBorrower {
    /// @notice The callback for batched flashloans. Every amount + fee needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param tokens Array of addresses for ERC-20 tokens that is loaned.
    /// @param amounts A one-to-one map to `tokens` that is loaned.
    /// @param fees A one-to-one map to `tokens` that needs to be paid on top for each loan. Needs to be the same token.
    /// @param data Additional data that was passed to the flashloan function.
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

interface IBentoBoxV1 {
    function balanceOf(IERC20, address) external view returns (uint256);

    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);

    function batchFlashLoan(
        IBatchFlashBorrower borrower,
        address[] calldata receivers,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function claimOwnership() external;

    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable returns (address);

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingStrategy(IERC20) external view returns (IStrategy);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerProtocol() external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setStrategy(IERC20 token, IStrategy newStrategy) external;

    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;

    function strategy(IERC20) external view returns (IStrategy);

    function strategyData(IERC20)
        external
        view
        returns (
            uint64 strategyStartDate,
            uint64 targetPercentage,
            uint128 balance
        );

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (Rebase memory totals_);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function whitelistMasterContract(address masterContract, bool approved) external;

    function whitelistedMasterContracts(address) external view returns (bool);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";

interface IBentoBoxOwner {
    function setStrategyTargetPercentageAndRebalance(IERC20 token, uint64 targetPercentage) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import "OpenZeppelin/token/ERC721/IERC721.sol";

interface IArvinDegenNFT is IERC721 {
    function getRefundRatio(address user) external view returns (uint256);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IMasterChef {
    struct LockDetail {
        uint256 lockAmount;
        uint256 unlockAmount;
        uint256 unlockTimestamp;
    }

    // Info of each user.
    struct VestingInfo {
        uint256 vestingReward;
        uint256 claimTime;
        bool isClaimed;
    }

    function addRewardToPool(uint256 amount) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function deposit(address to) external;

    function depositLock(uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function withdraw(address to) external;

    function withdraw(address[] calldata to) external;

    function withdrawLock(uint256 _amount) external;

    function getShareThatShouldDistribute() external view returns (uint256 share);

    function totalStake(uint256 _pid) external returns (uint256 stakeAmount);

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function userPendingReward(address user) external view returns (uint256 pendingReward);

    function userInfo(uint256 _pid, address user) external view returns (uint256 amount, uint256 debt);

    function poolInfo(
        uint256 _pid
    )
        external
        view
        returns (
            address stakeToken,
            address rewardToken,
            uint256 lastRewardTimestamp,
            uint256 rewardPerSecond,
            uint256 rewardPerShare, //multiply 1e20
            bool isDynamicReward
        );

    function getLockAmount(address user) external view returns (uint256 amount);

    function getLockInfo(address user) external view returns (LockDetail[] memory locks);

    function getUnlockableAmount(address user) external view returns (uint256 amount);

    function getUserVestingInfo(address user) external returns (VestingInfo[] memory);

    function vestingPendingReward(bool claim) external;

    function claimVestingReward() external;

    function emergencyWithdraw(uint256 _pid) external;

    function estimateARVCirculatingSupply() external view returns (uint256 circulatingSupply);

    function cauldronPoolInfo(address cauldron) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IConvexWrapper {
    struct EarnedData {
        address token;
        uint256 amount;
    }

    function addRewards() external;

    function addTokenReward(address _token) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function cauldrons(uint256) external view returns (address);

    function cauldronsLength() external view returns (uint256);

    function collateralVault() external view returns (address);

    function convexBooster() external view returns (address);

    function convexPool() external view returns (address);

    function convexPoolId() external view returns (uint256);

    function convexToken() external view returns (address);

    function crv() external view returns (address);

    function curveToken() external view returns (address);

    function cvx() external view returns (address);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 _amount, address _to) external;

    function earmarkRewards() external returns (bool);

    function earned(address _account) external returns (EarnedData[] memory claimable);

    function factory() external view returns (address);

    function getReward(address _account, address _forwardTo) external;

    function getReward(address _account) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function initialize(uint256 _poolId) external;

    function invalidateReward(address _token) external;

    function isInit() external view returns (bool);

    function isShutdown() external view returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function registeredRewards(address) external view returns (uint256);

    function renounceOwnership() external;

    function rewardHook() external view returns (address);

    function rewardLength() external view returns (uint256);

    function rewardRedirect(address) external view returns (address);

    function rewards(
        uint256
    ) external view returns (address reward_token, address reward_pool, uint256 reward_integral, uint256 reward_remaining);

    function setApprovals() external;

    function setCauldron(address _cauldron) external;

    function setHook(address _hook) external;

    function setRewardRedirect(address _to) external;

    function shutdown() external;

    function stake(uint256 _amount, address _to) external;

    function symbol() external view returns (string memory);

    function totalBalanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transferOwnership(address newOwner) external;

    function user_checkpoint(address _account) external returns (bool);

    function withdraw(uint256 _amount) external;

    function withdrawAndUnwrap(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface IStrategy {
    /// @notice Send the assets to the Strategy and call skim to invest them.
    /// @param amount The amount of tokens to invest.
    function skim(uint256 amount) external;

    /// @notice Harvest any profits made converted to the asset and pass them to the caller.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @param sender The address of the initiator of this transaction. Can be used for reimbursements, etc.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    /// @notice Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    /// @dev The `actualAmount` should be very close to the amount.
    /// The difference should NOT be used to report a loss. That's what harvest is for.
    /// @param amount The requested amount the caller wants to withdraw.
    /// @return actualAmount The real amount that is withdrawn.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    /// @notice Withdraw all assets in the safest way possible. This shouldn't fail.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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