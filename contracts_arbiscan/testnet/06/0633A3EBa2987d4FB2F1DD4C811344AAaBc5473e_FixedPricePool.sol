// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./Base.sol";

contract FixedPricePool is Base {
    using SafeMath for uint;

    event ReserveTokens(address indexed user, uint reserveAmount, uint pricePaid);

    uint public price; // price in wei for PRICE_DENOMINATOR token units

    constructor(IERC20 _token, 
                uint _tokenAmountToSell, 
                uint _startTime, 
                uint _endTime, 
                uint _minimumFillPercentage, 
                uint _minimumOrderSize, 
                uint[] memory _maximumAllocation,
                uint[] memory _minimumStakeTiers,
                uint _claimLockDuration,
                uint _price, 
                address payable _assetManager, 
                address _projectAdmin, 
                address _platformAdmin,
                IStaking _stakingContract,
                IWhitelist _whitelistContract) 
        Base(_token, 
                  _tokenAmountToSell, 
                  _startTime, 
                  _endTime, 
                  _minimumFillPercentage, 
                  _minimumOrderSize, 
                  _maximumAllocation,
                  _minimumStakeTiers,
                  _claimLockDuration,
                  _assetManager, 
                  _projectAdmin, 
                  _platformAdmin,
                  _stakingContract,
                  _whitelistContract)
    {
        price = _price;
    }

    function changePrice(uint newPrice) public onlyProjectAdmin onlyDuringInitialized {
        price = newPrice;
    }

    function setPoolReady() public override onlyProjectAdmin onlyDuringInitialized {
        maximumFunding = tokenAmountToSell.mul(price).div(PRICE_DENOMINATOR);
        super.setPoolReady();
    }

    function _reserveTokens(address user, uint reserveAmount, uint pricePaid) internal {
        userToReserve[user] += reserveAmount;
        amountPaid[user] += pricePaid;

        tokenAmountSold += reserveAmount;
        tokenAmountLeft -= reserveAmount;

        fundRaised += pricePaid;

        if (tokenAmountLeft == 0) {
            _setPoolSuccess();
        }
        
        emit ReserveTokens(user, reserveAmount, pricePaid);
    }

    function reserve() public virtual payable onlyDuringOngoing {
        require(msg.value >= minimumOrderSize, "FP: ORDER_TOO_SMALL");
        uint maxAllocation;
        if (address(whitelistContract) != address(0)){
            uint tier = _getUserTier();
            maxAllocation = _getStakeTierMaxAllocation(tier);
        } else {
            maxAllocation = maximumAllocation[0];
        }
        

        require(amountPaid[msg.sender] < maxAllocation, "FP: MAX_ALLOCATION_REACHED");

        uint payValue = Math.min(msg.value, maxAllocation - amountPaid[msg.sender]);

        uint reserveAmount = Math.min(payValue.mul(PRICE_DENOMINATOR).div(price), tokenAmountLeft);

        uint totalPrice = reserveAmount.mul(price).div(PRICE_DENOMINATOR);

        require(totalPrice > 0 && reserveAmount > 0, "FP: MAX_ALLOCATION_REACHED");

        _reserveTokens(msg.sender, reserveAmount, totalPrice);

        if (msg.value.sub(totalPrice) >= SENDBACK_THRESHOLD) msg.sender.transfer(msg.value.sub(totalPrice));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./State.sol";
import "./Administration.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./../interfaces/IStaking.sol";
import "./../interfaces/IWhitelist.sol";

abstract contract Base is State, Administration {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint constant public PRICE_DENOMINATOR = 10 ** 18;
    uint constant public MINIMUM_DURATION = 3600; // 1 hour in seconds
    uint constant public GLOBAL_MINIMUM_FILL_PERCENTAGE = 10; // 10%
    uint constant public SENDBACK_THRESHOLD = 10 ** 14; // 0.0001 ETH

    IERC20 public token; 
    uint public tokenAmountToSell;
    uint public startTime;
    uint public endTime;
    uint public minimumFillPercentage;
    uint public minimumFill;
    uint public fundRaised;
    uint public tokenAmountSold;
    uint public tokenAmountLeft;
    uint public minimumOrderSize;   // in wei
    uint[] public maximumAllocation;
    uint public totalWithdrawnAmount;

    uint public maximumFunding;
    uint public stakingTokenReward;
    IERC20 public stakingToken;
    bool public RemainingStakingTokenWithdrawnByPlatformAdmin;

    // currently ClaimLockDuration is not used, claiming is availible only after endTime
    uint public claimLockDuration;  // in seconds

    uint public claimAvailableTimestamp;

    uint[] public minimumStakeTiers;
    IStaking public stakingContract;

    IWhitelist public whitelistContract;

    uint[] public unlockCheckpoints;
    uint[] public unlockPercentages;
    uint currentPeriodIndex;

    mapping (address => uint) public userToReserve;
    mapping (address => uint) public amountPaid;
    mapping (address => uint) public withdrawnAmount;

    event Refund(address user, uint refundAmount);
    event Claim(address user, uint claimAmount, uint stakingTokenRewardAmount);

    event ChangeClaimAvailableTimestamp(uint newClaimAvailableTimestamp);

    constructor(IERC20 _token, 
                uint _tokenAmountToSell, 
                uint _startTime, 
                uint _endTime, 
                uint _minimumFillPercentage, 
                uint _minimumOrderSize, 
                uint[] memory _maximumAllocation, 
                uint[] memory _minimumStakeTiers,
                uint _claimLockDuration,
                address payable _assetManager, 
                address _projectAdmin, 
                address _platformAdmin,
                IStaking _stakingContract,
                IWhitelist _whitelistContract) 
    {
        _checkTime(_startTime, _endTime);
        _checkMinimumFillPercentage(_minimumFillPercentage);
        
        token = _token;
        tokenAmountToSell = _tokenAmountToSell;
        startTime = _startTime;
        endTime = _endTime;
        minimumFillPercentage = _minimumFillPercentage;
        minimumOrderSize = _minimumOrderSize;
        maximumAllocation = _maximumAllocation;
        minimumStakeTiers = _minimumStakeTiers;
        claimLockDuration = _claimLockDuration;
        assetManager = _assetManager;
        projectAdmin = _projectAdmin;
        platformAdmin = _platformAdmin;

        fundRaised = 0;
        tokenAmountSold = 0;
        tokenAmountLeft = tokenAmountToSell;

        stakingTokenReward = 0;
        RemainingStakingTokenWithdrawnByPlatformAdmin = false;

        stakingContract = IStaking(_stakingContract);
        whitelistContract = IWhitelist(_whitelistContract);
        
        claimAvailableTimestamp = _endTime;
        unlockCheckpoints.push(claimAvailableTimestamp);
        unlockPercentages.push(100);
        emit ChangeClaimAvailableTimestamp(claimAvailableTimestamp);
    }

    function changeToken(address newToken) public onlyProjectAdmin onlyDuringInitialized{
        token = IERC20(newToken);
    }

    function _checkTime(uint _startTime, uint _endTime) internal view {
        require(_endTime.sub(_startTime) >= MINIMUM_DURATION, "Base: DURATION_SHORT");
        require(_startTime > block.timestamp, "Base: START_TIME_PASSED");
    }

    function changeTime(uint newStartTime, uint newEndTime) public onlyProjectAdmin onlyDuringInitialized {
        _checkTime(newStartTime, newEndTime);
        startTime = newStartTime;
        endTime = newEndTime;
        claimAvailableTimestamp = endTime;
        emit ChangeClaimAvailableTimestamp(claimAvailableTimestamp);
    }

    function changeTokenAmountToSell(uint newTokenAmountToSell) public onlyProjectAdmin onlyDuringInitialized {
        tokenAmountToSell = newTokenAmountToSell;
        tokenAmountLeft = newTokenAmountToSell;
    }

    function _checkMinimumFillPercentage(uint _minimumFillPercentage) internal pure {
        require(_minimumFillPercentage >= GLOBAL_MINIMUM_FILL_PERCENTAGE, "Base: MIN_FILL_PERCENTAGE_LOW");
        require(_minimumFillPercentage <= 100, "Base: MIN_FILL_PERCENTAGE_HIGH");
    }

    function _checkStakeTiers() internal view {
        require(minimumStakeTiers.length == maximumAllocation.length, "Base: STAKE_TIERS_AND_MAX_ALLOCATIONS_NOT_SAME_LENGTH");
        for (uint index = 1; index < minimumStakeTiers.length; index++) {
            require(minimumStakeTiers[index - 1] > minimumStakeTiers[index], "Base: STAKE_TIERS_NOT_SORTED");
            require(maximumAllocation[index - 1] >= maximumAllocation[index], "Base: MAX_ALLOCATIONS_NOT_SORTED");
        }
        require(minimumStakeTiers[minimumStakeTiers.length - 1] == 0, "Base: NO_ZERO_STAKE_TIER");
    }

    function _checkUnlockParameters() internal view {
        require(unlockCheckpoints.length == unlockPercentages.length, "Base: UNLOCK_PARAMS_NOT_SAME_LENGTH");
        for (uint index = 1; index < unlockCheckpoints.length; index++) {
            require(unlockCheckpoints[index - 1] < unlockCheckpoints[index], "Base: UNLOCK_PARAMS_NOT_SORTED");
            require(unlockPercentages[index - 1] < unlockPercentages[index], "Base: UNLOCK_PARAMS_NOT_SORTED");
        }
        require(unlockPercentages[minimumStakeTiers.length - 1] == 100, "Base: PERCENTAGES_NOT_FULL");
    }

    function changeMinimumFillPercentage(uint newMinimumFillPercentage) public onlyProjectAdmin onlyDuringInitialized {
        _checkMinimumFillPercentage(newMinimumFillPercentage);
        minimumFillPercentage = newMinimumFillPercentage;
    }

    function changeMinimumOrderSize(uint newMinimumOrderSize) public onlyProjectAdmin onlyDuringInitialized {
        minimumOrderSize = newMinimumOrderSize;
    }

    function changeClaimLockDuration(uint newClaimLockDuration) public onlyProjectAdmin onlyDuringInitialized {
        claimLockDuration = newClaimLockDuration;
    }

    function changeTiersAndMaximumAllocation(uint[] memory newMinimumStakeTiers, uint[] memory newMaximumAllocation) public onlyPlatformAdmin onlyDuringInitialized {
        maximumAllocation = newMaximumAllocation;
        minimumStakeTiers = newMinimumStakeTiers;
    }

    function changeStakingContract(IStaking newStakingContract) public onlyPlatformAdmin onlyDuringInitialized {
        stakingContract = newStakingContract;
    } 

    function changeWhitelistContract(IWhitelist newWhitelistContract) public onlyPlatformAdmin onlyDuringInitialized {
        whitelistContract = newWhitelistContract;
    }

    function setStakingTokenReward(uint _stakingTokenReward, IERC20 _stakingToken) public onlyPlatformAdmin {
        require(state == StateType.INITIALIZED || state == StateType.READY, "ONLY_DURING_INITIALIZED_OR_READY");
        stakingTokenReward = _stakingTokenReward;
        stakingToken = _stakingToken;
    }

    function setUnlockCheckpointsAndPercentages(uint[] calldata _checkpoints, uint[] calldata _percentages) public onlyProjectAdmin{
        unlockCheckpoints = _checkpoints;
        unlockPercentages = _percentages;
    }

    function setPoolReady() public virtual onlyProjectAdmin onlyDuringInitialized {
        _checkTime(startTime, endTime);
        _checkMinimumFillPercentage(minimumFillPercentage);
        _checkStakeTiers();
        require(token.balanceOf(address(this)) >= tokenAmountToSell, "Base: NOT_ENOUGH_PROJECT_TOKENS");
        minimumFill = tokenAmountToSell.mul(minimumFillPercentage).div(100);

        claimAvailableTimestamp = endTime;
        emit ChangeClaimAvailableTimestamp(claimAvailableTimestamp);
        
        state = StateType.READY;
    }

    function setPoolOngoing() public onlyPlatformAdmin onlyDuringReady {
        require(block.timestamp >= startTime, "Base: TOO_EARLY");
        if (stakingTokenReward > 0) {
            require(stakingToken.balanceOf(address(this)) >= stakingTokenReward, "Base: NOT_ENOUGH_STAKING_TOKEN");
        }
        state = StateType.ONGOING;
    }

    function _setPoolSuccess() internal {
        state = StateType.SUCCESS;
    }

    function _setPoolFail() internal {
        state = StateType.FAIL;
    }

    function setPoolFinish() public onlyDuringOngoing {
        if (block.timestamp > endTime) {
            if (tokenAmountSold >= minimumFill) {
                _setPoolSuccess();
            } else {
                _setPoolFail();
            }
        }
        else {
            if (tokenAmountSold == tokenAmountToSell) {
                _setPoolSuccess();
            }
        }
    }

    function _getUserTier() internal view returns (uint) {
        uint tier = whitelistContract.getTier(msg.sender);
        require(tier > 0, "Base: NOT_WHITELISTED");
        return tier;
    }

    function _getStakeTierMaxAllocation(uint tier) internal view returns (uint){
            uint tierStakeAlloc = maximumAllocation[tier - 1];

            /* uint stake = stakingContract.getStake(msg.sender);
            uint stakingAlloc;
            for (uint index = 0; index < minimumStakeTiers.length; index++) {
                if(stake >= minimumStakeTiers[index]){
                    stakingAlloc = maximumAllocation[index];
                    break;
                }
            } */

           /*  return Math.min(stakingAlloc, tierStakeAlloc); */
           return tierStakeAlloc;
    }

    function withdrawFund() public virtual onlyDuringSuccess onlyAssetManager {
        assetManager.transfer(address(this).balance);
    }

    function withdrawTokenAfterFail() public onlyDuringFail onlyAssetManager {
        token.transfer(assetManager, token.balanceOf(address(this)));
    }

    function withdrawRemainingTokens() public virtual onlyDuringSuccess onlyAssetManager {
        uint tokenRemainingToDistribute = tokenAmountSold.sub(totalWithdrawnAmount);
        uint remaining = token.balanceOf(address(this)).sub(tokenRemainingToDistribute);
        token.transfer(assetManager, remaining);
    }

    function withdrawRemainingStakingToken(address stakingTokenWallet) public onlyPlatformAdmin onlyDuringSuccess {
        if (!RemainingStakingTokenWithdrawnByPlatformAdmin) {
            uint totalReward = stakingTokenReward.mul(fundRaised).div(maximumFunding);
            uint remaining = stakingTokenReward.sub(totalReward);
            RemainingStakingTokenWithdrawnByPlatformAdmin = true;
            stakingToken.safeTransfer(stakingTokenWallet, remaining);
        }
    }

    function withdrawStakingTokenAfterFail(address stakingTokenWallet) public onlyPlatformAdmin onlyDuringFail {
        stakingToken.safeTransfer(stakingTokenWallet, stakingToken.balanceOf(address(this)));
    }

    function refund() public virtual onlyDuringFail {
        uint returnAmount = amountPaid[msg.sender];
        require(returnAmount > 0, "Base: ALREADY_REFUNDED");
        amountPaid[msg.sender] = 0;
        userToReserve[msg.sender] = 0;
        msg.sender.transfer(returnAmount);
        emit Refund(msg.sender, returnAmount);
    }

    function withdrawReservedTokens() public virtual onlyDuringSuccess {
        require(block.timestamp >= claimAvailableTimestamp, "Base: CLAIMING_NOT_STARTED");
        for(; currentPeriodIndex < unlockCheckpoints.length; currentPeriodIndex++){
            if(block.timestamp < unlockCheckpoints[currentPeriodIndex]){
                break;
            }
        }

        uint reservedAmount = userToReserve[msg.sender];
        uint availableAmount = reservedAmount.mul(unlockPercentages[currentPeriodIndex]).div(100);
        uint relesedAmount = availableAmount.sub(withdrawnAmount[msg.sender]);
        withdrawnAmount[msg.sender] = availableAmount;
        uint userAmountPaid = amountPaid[msg.sender];
        require(reservedAmount > 0, "Base: RESERVE_BALANCE_ZERO");
        // userToReserve[msg.sender] = 0;
        amountPaid[msg.sender] = 0;
        token.safeTransfer(msg.sender, relesedAmount);
        totalWithdrawnAmount = totalWithdrawnAmount.add(relesedAmount);
 
        uint rewardForUser = 0;
        if (stakingTokenReward > 0) {
            rewardForUser = stakingTokenReward.mul(userAmountPaid).div(maximumFunding);
            stakingToken.safeTransfer(msg.sender, rewardForUser);
        } 

        emit Claim(msg.sender, reservedAmount, rewardForUser);
    }

    function emergencyChangeClaimAvailable(uint newClaimAvailableTimestamp) public onlyPlatformAdmin {
        claimAvailableTimestamp = newClaimAvailableTimestamp;
        emit ChangeClaimAvailableTimestamp(claimAvailableTimestamp);
    }

    function emergencyPause() public onlyPlatformAdmin {
        require(state != StateType.SUCCESS && state != StateType.FAIL && state != StateType.PAUSED, "Base: STATE_IS_FINAL");
        stateBeforePause = state;
        state = StateType.PAUSED;
    }

    function emergencyUnpause() public onlyPlatformAdmin onlyDuringPaused {
        state = stateBeforePause;
    }

    function emergencyCancel() public onlyPlatformAdmin onlyDuringPaused {
        state = StateType.FAIL;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract State {
    enum StateType {INITIALIZED, READY, ONGOING, SUCCESS, FAIL, PAUSED}

    StateType public state;
    StateType public stateBeforePause;

    modifier onlyDuringInitialized() {
        _isInitializedState();
        _;
    }

    function _isInitializedState() internal view {
        require(state == StateType.INITIALIZED, "ONLY_DURING_INITIALIZED");
    }

    modifier onlyDuringReady() {
        _isReadyState();
        _;
    }

    function _isReadyState() internal view {
        require(state == StateType.READY, "ONLY_DURING_READY");
    }    

    modifier onlyDuringOngoing() {
        _isOngoingState();
        _;
    }

    function _isOngoingState() internal view {
        require(state == StateType.ONGOING, "ONLY_DURING_ONGOING");
    }

    modifier onlyDuringSuccess() {
        _isSuccessState();
        _;
    }

    function _isSuccessState() internal view {
        require(state == StateType.SUCCESS, "ONLY_DURING_SUCCESS");
    }

    modifier onlyDuringFail() {
        _isFailState();
        _;
    }

    function _isFailState() internal view {
        require(state == StateType.FAIL, "ONLY_DURING_FAIL");
    }

    modifier onlyDuringPaused() {
        _isPausedState();
        _;
    }

    function _isPausedState() internal view {
        require(state == StateType.PAUSED, "ONLY_DURING_PAUSED");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./State.sol";

contract Administration is State {
    address public projectAdmin;
    address public newProjectAdmin;
    address public platformAdmin;
    address public newPlatformAdmin;
    address payable public assetManager;
    
    modifier onlyProjectAdmin() {
        _isProjectAdmin();
        _;
    }

    function _isProjectAdmin() internal view {
        require(msg.sender == projectAdmin, "ONLY_PROJECT_ADMIN");
    }

    modifier onlyPlatformAdmin() {
        _isPlatformAdmin();
        _;
    }

    function _isPlatformAdmin() internal view {
        require(msg.sender == platformAdmin, "ONLY_PLATFORM_ADMIN");
    }

    modifier onlyAssetManager() {
        _isAssetManager();
        _;
    }

    function _isAssetManager() internal view {
        require(msg.sender == assetManager, "ONLY_ASSET_MANAGER");
    }

    function changeAssetManager(address payable newAssetManager) public onlyProjectAdmin onlyDuringInitialized{
        assetManager = newAssetManager;
    }

    function setNewProjectAdmin(address _newProjectAdmin) public onlyProjectAdmin {
        newProjectAdmin = _newProjectAdmin;
    }

    function changeProjectAdmin() public {
        require(msg.sender == newProjectAdmin, "ONLY_PROJECT_ADMIN");
        projectAdmin = newProjectAdmin;
    }

    function setNewPlatformAdmin(address _newPlatformAdmin) public onlyPlatformAdmin {
        newPlatformAdmin = _newPlatformAdmin;
    }

    function changePlatformAdmin() public {
        require(msg.sender == newPlatformAdmin, "ONLY_Platform_ADMIN");
        platformAdmin = newPlatformAdmin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface IStaking {
    event CreateStake(address indexed caller, uint amount);
    event RemoveStake(address indexed caller, uint amount);


    /**
     * A method for a stakeholder to create a stake.
     *
     * @param stake - The size of the stake to be created.
     */
    function createStake(uint stake) external;

    /**
     * A method for a stakeholder to create a stake for someone else.
     *
     * @param stake - The size of the stake to be created.
     * @param to - The address the new stake belongs to.
     */
    function createStakeFor(uint stake, address to) external;

    /**
     * A method for a stakeholder to remove a stake.
     *
     * @param stake - The size of the stake to be removed.
     */
    function removeStake(uint stake) external;

    /**
     * A method which returns how much tokens stakeholder staked.
     *
     * @param user - address of stakeholder.
     */
    function getStake(address user) external view returns (uint);



     /**
     * A method to change unstaking fee ratio.
     * @notice Only callable by owner.
     *
     * @param newUnstakingFeeRatio - new unstaking fee ratio.
     */
    function changeUnstakingFeeRatio(uint newUnstakingFeeRatio) external;

    /**
     * A method to change staking token Distributor smart contract.
     * @notice Only callable by owner.
     *
     * @param newStakingTokenDistributor - address of new staking token Distributor smart contract.
     */
    function changeStakingTokenDistributor(address newStakingTokenDistributor) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface IWhitelist {

    function changeTier(address _address, uint256 _tier) external;

    function changeTierBatch(address[] calldata _addresses, uint256[] calldata _tierList) external;

    function getTier(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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