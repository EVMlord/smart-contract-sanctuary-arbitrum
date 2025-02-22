//SPDX-License-Identifier: MIT
//@author asimaranov

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Tier.sol";

enum StakingTime {
    Month,
    ThreeMonths,
    SixMonths,
    Year
}


contract Staking is Ownable, Pausable {
    using SafeERC20 for IERC20;

    struct StakerInfo {
        uint8 allocationBonusPercent;
        bool isRegistered;
    }

    struct PoolStakerInfo {
        uint256 stake;
        uint256 deadline;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 token;
        uint256 allocPoints;
        uint256 lastRewardBlock;
        uint256 accRaisePerShare;
        uint256 balance;
    }

    struct RequiredTierStakeInfo {  // Will use only one EVM slot
        uint32 fan;
        uint32 merchant;
        uint32 dealer;
        uint32 broker;
        uint32 tycoon;
    }

    struct StakerTicketInfo {
        address user;
        uint256 tickets;
    }

    IERC20 public raiseToken;
    PoolInfo[] public pools;
    mapping(address => StakerInfo) public stakers;
    mapping(Tier => address[]) public tierStakers;  // Tier => stakers of this rank
    mapping(address => uint256) public tierStakerPositions;  // Staker => his index in tierStakers for his rank
    mapping(Tier => uint256[]) public tierStakerGaps; // Empty placed in the tierStakers addresses. Appers when user tier change, when old rank gets removed
    mapping(uint256 => mapping(address => PoolStakerInfo)) public poolStakerInfos;  // Staking id => staker id => staker info
    mapping(address => bool) public registeredTokens;
    RequiredTierStakeInfo public requiredTierStakeInfo;
    uint256 public totalAllocPoints;
    uint256 public raisePerBlock;
    uint256 public totalPenalties;
    uint256 public serviceBalance;
    uint8 public penaltyPercent;
    address[] public stakerAddresses;

    uint256 constant public RAISE_DECIMAL = 1e18;
    uint256 constant public TICKETS_PER_100_RAISE = 10;

    event Staked(address indexed user, uint256 indexed poolId, uint256 amount, uint256 reward, StakingTime time);
    event Unstaked(address indexed user, uint256 indexed poolId, uint256 amount, uint256 reward, bool withPenalty);
    event EmergencyUnstaked(address indexed user, uint256 indexed poolId, uint256 amount, bool withPenalty);
    event Claimed(address indexed user, uint256 indexed poolId, uint256 reward);
    event TierObtained(address indexed user, Tier tier);
    event Funded(address indexed user, uint256 amount);
    event Withdrawed(address indexed user, uint256 amount);

    constructor(address raiseTokenAddr, uint256 raisePerBlock_) {
        raiseToken = IERC20(raiseTokenAddr);
        raisePerBlock = raisePerBlock_;

        pools.push(PoolInfo({
            token: raiseToken,
            allocPoints: 1000,
            lastRewardBlock: block.number,
            accRaisePerShare: 0,
            balance: 0
        }));

        registeredTokens[raiseTokenAddr] = true;
        totalAllocPoints += 1000;
        penaltyPercent = 30;

        requiredTierStakeInfo = RequiredTierStakeInfo({
            fan: 333,
            merchant: 500,
            dealer: 5_000,
            broker: 50_000,
            tycoon: 1_000_000
        });
    }

    function createPool(uint256 allocPoints_, address tokenAddr) public onlyOwner {
        require(!registeredTokens[tokenAddr], "Such pool already created");
        
        registeredTokens[tokenAddr] = true;
        totalAllocPoints += allocPoints_;

        pools.push(PoolInfo({
            token: IERC20(tokenAddr),
            allocPoints: allocPoints_,
            lastRewardBlock: block.number,
            accRaisePerShare: 0,
            balance: 0
        }));
    }

    function updatePool(uint256 poolId) public whenNotPaused {
        PoolInfo storage poolInfo = pools[poolId];
        if (block.number <= poolInfo.lastRewardBlock) 
            return;
        
        uint256 poolBalance = poolInfo.balance;
        uint256 raiseReward;

        if (poolBalance > 0) {
            raiseReward = raisePerBlock * (block.number - poolInfo.lastRewardBlock) * poolInfo.allocPoints / totalAllocPoints;
            poolInfo.accRaisePerShare += raiseReward * 1e12 / poolBalance;
        }

        poolInfo.lastRewardBlock = block.number;
    }

    function stake(uint256 poolId, uint256 amount, StakingTime time) public whenNotPaused {
        require(amount > 0, "Unable to stake 0 tokens");

        StakerInfo storage stakerInfo = stakers[msg.sender];
        PoolStakerInfo storage poolStakerInfo = poolStakerInfos[poolId][msg.sender];
        PoolInfo storage poolInfo = pools[poolId];

        updatePool(poolId);

        uint256 totalUserReward = poolStakerInfo.stake * poolInfo.accRaisePerShare / 1e12;
        uint256 pending;

        if (poolStakerInfo.stake > 0) {
            pending = totalUserReward - poolStakerInfo.rewardDebt;

            if (pending > 0) {
                require(serviceBalance >= pending, "Service balance is empty");

                serviceBalance -= pending;
                raiseToken.safeTransfer(msg.sender, pending);

                emit Claimed(msg.sender, poolId, pending);
            }
        }

        Tier currentTier = getTierByStakingAmount(poolStakerInfo.stake);

        poolStakerInfo.stake += amount;
        poolStakerInfo.rewardDebt = poolStakerInfo.stake * poolInfo.accRaisePerShare / 1e12;

        if (!stakerInfo.isRegistered) {
            stakerAddresses.push(msg.sender);
            stakerInfo.isRegistered = true;
            tierStakerPositions[msg.sender] = tierStakers[Tier.None].length;  // Setting info about current user tier
            tierStakers[Tier.None].push(msg.sender);
        }

        uint256 newDeadline = block.timestamp + getPeriodDuration(time);

        if (newDeadline > poolStakerInfo.deadline)
            poolStakerInfo.deadline = newDeadline;

        poolInfo.balance += amount;

        if (poolId == 0) {
            Tier tierToAcquire = getTierByStakingAmount(poolStakerInfo.stake);

            if (tierToAcquire > currentTier) {
                stakerInfo.allocationBonusPercent = getAllocationBonusPercentByTime(time);
                _updateTier(currentTier, tierToAcquire);
            }
        }
        
        poolInfo.token.safeTransferFrom(msg.sender, address(this), amount);
        
        emit Staked(msg.sender, poolId, amount, pending, time);
    }

    function unstake(uint256 poolId, uint256 amount) public whenNotPaused {
        PoolStakerInfo storage poolStakerInfo = poolStakerInfos[poolId][msg.sender];

        require(poolStakerInfo.stake >= amount, "Not enough balance");

        updatePool(poolId);
        
        PoolInfo storage poolInfo = pools[poolId];
        poolInfo.balance -= amount;

        uint256 totalUserReward = poolStakerInfo.stake * poolInfo.accRaisePerShare / 1e12;
        uint256 pending = totalUserReward - poolStakerInfo.rewardDebt;
        bool withPenalty;
        uint256 amountToUnstake = amount;

        Tier currentTier = getTierByStakingAmount(poolStakerInfo.stake);

        if (block.timestamp < poolStakerInfo.deadline && poolId == 0 && currentTier >= Tier.Merchant) {
            uint256 penalty = amount * penaltyPercent / 100;
            amountToUnstake -= penalty;
            serviceBalance += penalty;
            totalPenalties += penalty;
            withPenalty = true;
        }
        
        if (pending > 0) {
            require(serviceBalance >= pending, "Service balance is empty");
            
            serviceBalance -= pending;
            raiseToken.safeTransfer(msg.sender, pending);

            emit Claimed(msg.sender, poolId, pending);
        }

        poolStakerInfo.stake -= amount;
        poolStakerInfo.rewardDebt = poolStakerInfo.stake * poolInfo.accRaisePerShare / 1e12;

        if (poolId == 0) {
            Tier tierToAcquire = getTierByStakingAmount(poolStakerInfo.stake);

            if (tierToAcquire < currentTier) {
                _updateTier(currentTier, tierToAcquire);
            }
        }

        poolInfo.token.safeTransfer(msg.sender, amountToUnstake);

        emit Unstaked(msg.sender, poolId, amountToUnstake, pending, withPenalty);
    }

    function emergencyUnstake(uint256 poolId) public whenNotPaused {
        PoolStakerInfo storage poolStakerInfo = poolStakerInfos[poolId][msg.sender];
        uint256 amount = poolStakerInfo.stake;
        
        require(amount > 0, "Not enough balance");

        PoolInfo storage poolInfo = pools[poolId]; 
        poolInfo.balance -= amount;
        
        bool withPenalty;
        uint256 amountToUnstake = amount;
        Tier currentTier = getTierByStakingAmount(poolStakerInfo.stake);

        if (block.timestamp < poolStakerInfo.deadline && poolId == 0 && currentTier >= Tier.Merchant) {
            uint256 penalty = amount * penaltyPercent / 100;
            amountToUnstake -= penalty;
            serviceBalance += penalty; 
            totalPenalties += penalty;
            withPenalty = true;
        }
        
        poolStakerInfo.stake = 0;
        poolStakerInfo.rewardDebt = 0;
        poolInfo.token.safeTransfer(msg.sender, amountToUnstake);

        emit EmergencyUnstaked(msg.sender, poolId, amountToUnstake, withPenalty);
    }

    function claim(uint256 poolId) public whenNotPaused {
        updatePool(poolId);

        PoolStakerInfo storage poolStakerInfo = poolStakerInfos[poolId][msg.sender];
        PoolInfo memory poolInfo = pools[poolId];
        uint256 totalUserReward = poolStakerInfo.stake * poolInfo.accRaisePerShare / 1e12;
        uint256 pending = totalUserReward - poolStakerInfo.rewardDebt;

        require(pending > 0, "No reward to claim");
        require(serviceBalance >= pending, "Service balance is empty");
        
        serviceBalance -= pending;
        poolStakerInfo.rewardDebt = totalUserReward;
        raiseToken.safeTransfer(msg.sender, pending);

        emit Claimed(msg.sender, poolId, pending);
    }

    function fund(uint256 amount) public {
        serviceBalance += amount;
        raiseToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Funded(msg.sender, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(serviceBalance >= amount, "Not enough service balance");

        serviceBalance -= amount;
        raiseToken.safeTransfer(msg.sender, amount);

        emit Withdrawed(msg.sender, amount);
    }

    function setAllocPoints(uint256 poolId, uint256 allocPoints) public onlyOwner {
        pools[poolId].allocPoints = allocPoints;
    }

    function setPenaltyPercent(uint8 penaltyPercent_) public onlyOwner {
        penaltyPercent = penaltyPercent_;
    }

    function setRaisePerBlock(uint256 newRaisePerBlock) public onlyOwner {
        raisePerBlock = newRaisePerBlock;
    }

    function setRequiredStakeForTier(Tier tier, uint32 requiredStake) public onlyOwner {
        if (tier == Tier.Fan) requiredTierStakeInfo.fan = requiredStake;
        else if (tier == Tier.Merchant) requiredTierStakeInfo.merchant = requiredStake;
        else if (tier == Tier.Dealer) requiredTierStakeInfo.dealer = requiredStake;
        else if (tier == Tier.Broker) requiredTierStakeInfo.broker = requiredStake;
        else if (tier == Tier.Tycoon) requiredTierStakeInfo.tycoon = requiredStake;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getUserStakeInfo(uint256 poolId, address user) public view returns (uint256 amount, uint256 deadline) {
        PoolStakerInfo memory stakerInfo = poolStakerInfos[poolId][user];
        amount = stakerInfo.stake;
        deadline = stakerInfo.deadline;
    }

    function getPendingReward(uint256 poolId, address user) public view returns (uint256 pendingReward) {
        PoolStakerInfo memory poolStakerInfo = poolStakerInfos[poolId][user];
        PoolInfo memory poolInfo = pools[poolId];

        uint256 accRaisePerShare = poolInfo.accRaisePerShare;
        uint256 poolBalance = poolInfo.balance;

        if (block.number > poolInfo.lastRewardBlock && poolBalance > 0) {
            uint256 raiseReward = raisePerBlock * (block.number - poolInfo.lastRewardBlock) * poolInfo.allocPoints / totalAllocPoints;
            accRaisePerShare += raiseReward * 1e12 / poolBalance;
        }

        pendingReward = poolStakerInfo.stake * accRaisePerShare / 1e12 - poolStakerInfo.rewardDebt;
    }

    function getUserInfo(address user) 
        public view 
        returns (
            uint256 userTickets, 
            Tier tier, 
            uint256 stake_, 
            uint256 deadline, 
            uint8 allocationBonusPercent
        ) 
    {
        PoolStakerInfo memory poolStakerInfo = poolStakerInfos[0][user];
        StakerInfo memory staker = stakers[user];
        Tier userTier = getTierByStakingAmount(poolStakerInfo.stake);

        if (userTier == Tier.Merchant || userTier == Tier.Dealer)
            userTickets = poolStakerInfo.stake * TICKETS_PER_100_RAISE / (100 * RAISE_DECIMAL);
        
        tier = userTier;
        stake_ = poolStakerInfo.stake;
        deadline = poolStakerInfo.deadline;
        allocationBonusPercent = staker.allocationBonusPercent;
    }

    function getStakersByTier(Tier tier) public view returns (address[] memory) {  // Can return null addresses, please just skip them
        return tierStakers[tier];
    }

    function getStakerTicketInfos(Tier tier) public view returns (StakerTicketInfo[] memory userInfos) {
        address[] memory users = getStakersByTier(tier);
        userInfos = new StakerTicketInfo[](users.length);

        for (uint i = 0; i < users.length; i++) {
            (uint256 userTickets, , , , ) = getUserInfo(users[i]);
            userInfos[i] = StakerTicketInfo(users[i], userTickets);
        }
    }

    function getStakedTokenAmount(uint256 poolId) public view returns (uint256) {
        return pools[poolId].balance;
    }

    function getTierByStakingAmount(uint256 amount) public view returns (Tier tier) {
        return _getTierByStakingAmount(requiredTierStakeInfo, amount);
    }

    function getPeriodDuration(StakingTime time) public pure returns (uint256 period) {
        if (StakingTime.Month == time) return 30 days;
        if (StakingTime.ThreeMonths == time) return 30 days * 3;
        if (StakingTime.SixMonths == time) return 30 days * 6;

        return 30 days * 12;
    }

    function getAllocationBonusPercentByTime(StakingTime time) public pure returns (uint8) {
        if (StakingTime.Month == time) return 0;
        if (StakingTime.ThreeMonths == time) return 10;
        if (StakingTime.SixMonths == time) return 20;

        return 30;
    }

    function _getTierByStakingAmount(RequiredTierStakeInfo memory requiredTierStakeInfo_, uint256 amount) internal pure returns (Tier tier) {
        if (amount < requiredTierStakeInfo_.fan * RAISE_DECIMAL) return Tier.None;
        if (amount < requiredTierStakeInfo_.merchant * RAISE_DECIMAL) return Tier.Fan;
        if (amount < requiredTierStakeInfo_.dealer * RAISE_DECIMAL) return Tier.Merchant;
        if (amount < requiredTierStakeInfo_.broker * RAISE_DECIMAL) return Tier.Dealer;
        if (amount < requiredTierStakeInfo_.tycoon * RAISE_DECIMAL) return Tier.Broker;

        return Tier.Tycoon;
    }

    function _updateTier(Tier oldTier, Tier newTier) internal {
        uint256 previousTierStakerPosition = tierStakerPositions[msg.sender];

        tierStakers[oldTier][previousTierStakerPosition] = address(0);  // Remove info about user's previous tier
        tierStakerGaps[oldTier].push(previousTierStakerPosition);  // Will set the free slot to reuse later

        uint256[] storage gapsArray = tierStakerGaps[newTier];

        if (gapsArray.length > 0) {
            uint256 freeGap = gapsArray[gapsArray.length-1];
            gapsArray.pop();
            tierStakerPositions[msg.sender] = freeGap; // Setting info about actual user index in tier list
            tierStakers[newTier][freeGap] = msg.sender;  // Adding user to the tier list
        } else {
            tierStakerPositions[msg.sender] = tierStakers[newTier].length; // Setting info about actual user index in tier list
            tierStakers[newTier].push(msg.sender);  // Adding user to the tier list on a gap's place
        }

        emit TierObtained(msg.sender, newTier);
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT
//@author asimaranov

pragma solidity ^0.8.0;

enum Tier {
    None,
    Fan,
    Merchant,
    Dealer,
    Broker,
    Tycoon
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}