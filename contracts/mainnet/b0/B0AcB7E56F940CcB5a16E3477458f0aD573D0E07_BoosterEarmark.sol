// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.11;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts-0.8/access/Ownable.sol";

contract BoosterEarmark is Ownable {
    uint256 public constant MAX_DISTRIBUTION = 2500;
    uint256 public constant DENOMINATOR = 10000;

    IBooster public booster;
    address public voterProxy;
    address public depositor;
    address public mainRewardToken;
    address public weth;

    uint256 public earmarkIncentive;

    mapping(address => TokenDistro[]) public distributionByTokens;
    mapping(uint256 => mapping(address => TokenDistro[])) public customDistributionByTokens;

    struct TokenDistro {
        address distro;
        uint256 share;
        bool callQueue;
    }
    address[] distributionTokens;

    uint256 public earmarkPeriod;
    mapping(uint256 => uint256) public lastEarmarkAt;

    struct EarmarkState {
        IERC20 token;
        uint256 balance;
        uint256 dLen;
        uint256 earmarkIncentiveAmount;
        uint256 sentSum;
        uint256 totalDLen;
    }

    event TokenDistributionUpdate(address indexed token, address indexed distro, uint256 share, bool callQueue);
    event DistributionUpdate(address indexed token, uint256 distrosLength, uint256 sharesLength, uint256 callQueueLength, uint256 totalShares);
    event CustomDistributionUpdate(uint256 indexed pid, address indexed token, uint256 distrosLength, uint256 sharesLength, uint256 callQueueLength, uint256 totalShares);
    event ClearDistributionApproval(address indexed distro, address[] tokens);

    event SetPoolManager(address poolManager);

    event SetEarmarkConfig(uint256 earmarkIncentive, uint256 earmarkPeriod);
    event EarmarkRewards(uint256 indexed pid, address indexed lpToken, address indexed rewardToken, uint256 amount);
    event EarmarkRewardsTransfer(uint256 indexed pid, address indexed lpToken, address indexed rewardToken, uint256 amount, address distro, bool queue);
    event EarmarkRewardsDiff(address indexed rewardToken, uint256 diffAmount, uint256 pendingAmount, uint256 currentBal);

    event ReleaseToken(address indexed token, uint256 amount, address indexed recipient);

    constructor(address _booster, address _weth) {
        booster = IBooster(_booster);
        mainRewardToken = booster.crv();
        voterProxy = IBooster(_booster).voterProxy();
        depositor = IStaker(voterProxy).depositor();
        weth = _weth;
    }

    function updateBoosterAndDepositor() external onlyOwner {
        booster = IBooster(IStaker(voterProxy).operator());
        depositor = IStaker(voterProxy).depositor();
    }

    /**
     * @notice Fee manager can set all the relevant fees
     * @param _earmarkIncentive   % for whoever calls the claim where 1% == 100
     */
    function setEarmarkConfig(uint256 _earmarkIncentive, uint256 _earmarkPeriod) external onlyOwner {
        require(_earmarkIncentive <= 100, ">max");
        earmarkIncentive = _earmarkIncentive;
        earmarkPeriod = _earmarkPeriod;
        emit SetEarmarkConfig(_earmarkIncentive, _earmarkPeriod);
    }

    /**
     * @notice Call setPoolManager on booster
     */
    function setBoosterPoolManager(address _poolManager) external onlyOwner {
        require(_poolManager != address(0), "zero");
        booster.setPoolManager(_poolManager);
        emit SetPoolManager(_poolManager);
    }

    /**
     * @notice Call addPool on booster
     */
    function addPool(address _lptoken, address _gauge) external onlyOwner returns (uint256) {
        uint256 pid = booster.addPool(_lptoken, _gauge);
        approvePoolDistributionTokens(pid);
        return pid;
    }

    /**
     * @notice Call addCreatedPool on booster
     */
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) external onlyOwner returns (uint256) {
        require(_lptoken != address(0) && _gauge != address(0) && _token != address(0) && _crvRewards != address(0), "zero");
        uint256 pid = booster.addCreatedPool(_lptoken, _gauge, _token, _crvRewards);
        approvePoolDistributionTokens(pid);
        return pid;
    }

    function shutdownPool(uint256 _pid) external onlyOwner returns (bool) {
        return booster.shutdownPool(_pid);
    }

    function forceShutdownPool(uint256 _pid) external onlyOwner returns (bool) {
        return booster.forceShutdownPool(_pid);
    }

    /**
     * @notice Call approveDistributionTokens on booster
     */
    function approvePoolDistributionTokens(uint256 _pid) public onlyOwner {
        IBooster.PoolInfo memory p = booster.poolInfo(_pid);
        booster.approveDistribution(p.crvRewards, distributionTokens, type(uint256).max);
    }

    /**
     * @notice Allows turning off or on for fee distro
     */
    function clearDistroApprovals(address distro) external onlyOwner {
        booster.approveDistribution(distro, distributionTokens, 0);

        emit ClearDistributionApproval(distro, distributionTokens);
    }

    /**
     * @notice Allows turning off or on for fee distro
     */
    function updateDistributionByTokens(
        address _token,
        address[] memory _distros,
        uint256[] memory _shares,
        bool[] memory _callQueue
    ) public onlyOwner {
        require(_distros.length > 0, "zero");

        if (distributionByTokens[_token].length == 0) {
            distributionTokens.push(_token);
        }

        uint256 totalShares = _updateDistributionByTokens(_token, distributionByTokens[_token], _distros, _shares, _callQueue);

        booster.approvePoolsCrvRewardsDistribution(_token);

        emit DistributionUpdate(_token, _distros.length, _shares.length, _callQueue.length, totalShares);
    }

    function migrateDistribution(BoosterEarmark _oldBoosterEarmark) external {
        address[] memory tokenList = _oldBoosterEarmark.distributionTokenList();
        for (uint256 i = 0; i < tokenList.length; i++) {
            uint256 distroLen = _oldBoosterEarmark.distributionByTokenLength(tokenList[i]);
            address[] memory _distros = new address[](distroLen);
            uint256[] memory _shares = new uint256[](distroLen);
            bool[] memory _callQueue = new bool[](distroLen);

            for (uint256 j = 0; j < distroLen; j++) {
                (_distros[j], _shares[j], _callQueue[j]) = _oldBoosterEarmark.distributionByTokens(tokenList[i], j);
            }
            updateDistributionByTokens(tokenList[i], _distros, _shares, _callQueue);
        }
    }

    /**
     * @notice Allows turning off or on for fee distro
     */
    function updateCustomDistributionByTokens(
        uint256 _pid,
        address _token,
        address[] memory _distros,
        uint256[] memory _shares,
        bool[] memory _callQueue
    ) external onlyOwner {
        uint256 totalShares = _updateDistributionByTokens(_token, customDistributionByTokens[_pid][_token], _distros, _shares, _callQueue);

        IBooster.PoolInfo memory p = booster.poolInfo(_pid);

        address[] memory tokens = new address[](1);
        tokens[0] = _token;

        booster.approveDistribution(p.crvRewards, tokens, type(uint256).max);

        emit CustomDistributionUpdate(_pid, _token, _distros.length, _shares.length, _callQueue.length, totalShares);
    }

    function _updateDistributionByTokens(
        address _token,
        TokenDistro[] storage _tds,
        address[] memory _distros,
        uint256[] memory _shares,
        bool[] memory _callQueue
    ) internal returns(uint256) {
        uint256 curLen = _tds.length;
        for (uint256 i = 0; i < curLen; ) {
            _tds.pop();
            unchecked {
                ++i;
            }
        }

        uint256 totalShares = 0;

        uint256 len = _distros.length;
        require(len > 0 && len == _shares.length && len == _callQueue.length, "!length");

        for (uint256 i = 0; i < len; ) {
            require(_distros[i] != address(0), "!distro");
            totalShares = totalShares + _shares[i];
            _tds.push(TokenDistro(_distros[i], _shares[i], _callQueue[i]));
            emit TokenDistributionUpdate(_token, _distros[i], _shares[i], _callQueue[i]);

            if (_callQueue[i]) {
                address[] memory tokens = new address[](1);
                tokens[0] = _token;
                booster.approveDistribution(_distros[i], tokens, type(uint256).max);
            }
            unchecked {
                ++i;
            }
        }
        require(totalShares <= MAX_DISTRIBUTION, ">max");
        return totalShares;
    }

    function _rewardTokenBalances(uint256 _pid, address[] memory _tokens) internal returns (uint256[] memory balances) {
        uint256 tLen = _tokens.length;

        uint256[] memory balancesBefore = new uint256[](tLen);
        for (uint256 i = 0; i < tLen; ) {
            balancesBefore[i] = IERC20(_tokens[i]).balanceOf(address(booster)) + IERC20(_tokens[i]).balanceOf(voterProxy);
            if (_tokens[i] == weth) {
                balancesBefore[i] = balancesBefore[i] + voterProxy.balance;
            }
            unchecked {
                ++i;
            }
        }

        uint256[] memory pendingRewards = booster.voterProxyClaimRewards(_pid, _tokens);

        balances = new uint256[](tLen);
        for (uint256 i = 0; i < tLen; ) {
            uint256 currentBal = IERC20(_tokens[i]).balanceOf(address(booster));
            balances[i] = currentBal - balancesBefore[i];
            if(balances[i] + pendingRewards[i] > currentBal) {
                emit EarmarkRewardsDiff(_tokens[i], (balances[i] + pendingRewards[i]) - currentBal, pendingRewards[i], currentBal);
                balances[i] = currentBal;
            } else {
                balances[i] += pendingRewards[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function earmarkRewards(uint256 _pid) public {
        IBooster.PoolInfo memory p = booster.poolInfo(_pid);
        require(isEarmarkPoolAvailable(_pid, p), "!available");

        //claim crv/wom and bonus tokens
        address[] memory tokens = IStaker(voterProxy).getGaugeRewardTokens(p.lptoken, p.gauge);
        uint256[] memory balances = _rewardTokenBalances(_pid, tokens);

        for (uint256 i = 0; i < tokens.length; ) {
            if (i != 0 && tokens[i] == mainRewardToken) {
                unchecked {
                    ++i;
                }
                continue;
            }
            EarmarkState memory s;
            s.token = IERC20(tokens[i]);
            s.balance = balances[i];

            emit EarmarkRewards(_pid, p.lptoken, address(s.token), s.balance);

            if (s.balance == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }
            TokenDistro[] storage tDistros = _getDistributionByTokens(_pid, address(s.token));
            s.dLen = tDistros.length;
            require(s.dLen > 0, "!dLen");

            s.earmarkIncentiveAmount = s.balance * earmarkIncentive / DENOMINATOR;
            s.sentSum = s.earmarkIncentiveAmount;

            s.totalDLen = s.dLen + 1 + (s.earmarkIncentiveAmount > 0 ? 1 : 0);
            address[] memory _transferTo = new address[](s.totalDLen);
            uint256[] memory _transferAmount = new uint256[](s.totalDLen);
            bool[] memory _callQueue = new bool[](s.totalDLen);

            for (uint256 j = 0; j < s.dLen; ) {
                TokenDistro memory tDistro = tDistros[j];
                if (tDistro.share == 0) {
                    unchecked {
                        ++j;
                    }
                    continue;
                }
                uint256 amount = s.balance * tDistro.share / DENOMINATOR;
                s.sentSum += amount;

                _transferAmount[j] = amount;
                _transferTo[j] = tDistro.distro;
                _callQueue[j] = tDistro.callQueue;

                emit EarmarkRewardsTransfer(_pid, p.lptoken, address(s.token), amount, tDistro.distro, tDistro.callQueue);
                unchecked {
                    ++j;
                }
            }
            if (s.earmarkIncentiveAmount > 0) {
                _transferAmount[s.totalDLen - 2] = s.earmarkIncentiveAmount;
                _transferTo[s.totalDLen - 2] = msg.sender;
                _callQueue[s.totalDLen - 2] = false;

                emit EarmarkRewardsTransfer(_pid, p.lptoken, address(s.token), s.earmarkIncentiveAmount, msg.sender, false);
            }

            _transferAmount[s.totalDLen - 1] = s.balance - s.sentSum;
            _transferTo[s.totalDLen - 1] = p.crvRewards;
            _callQueue[s.totalDLen - 1] = true;

            booster.distributeRewards(_pid, p.lptoken, tokens[i], _transferTo, _transferAmount, _callQueue);

            emit EarmarkRewardsTransfer(_pid, p.lptoken, address(s.token), _transferAmount[s.totalDLen - 1], p.crvRewards, true);
            unchecked {
                ++i;
            }
        }
        lastEarmarkAt[_pid] = block.timestamp;
    }

    function earmarkRewardsIfAvailable(uint256 _pid) external {
        if (!isEarmarkAvailable(_pid)) {
           return;
        }
        earmarkRewards(_pid);
    }

    function earmarkRewards(uint256[] memory _pids) external {
        uint256 len = _pids.length;
        for (uint256 i = 0; i < len; i++) {
            earmarkRewards(_pids[i]);
        }
    }

    function isEarmarkAvailable(uint256 _pid) public view returns (bool) {
        return isEarmarkPoolAvailable(_pid, booster.poolInfo(_pid));
    }

    function isEarmarkPoolAvailable(uint256 _pid, IBooster.PoolInfo memory _pool) public view returns (bool) {
        if (msg.sender == depositor && !_pool.shutdown) {
            return true;
        }
        return getEarmarkPoolExecuteOn(_pid, _pool) < block.timestamp;
    }

    function getEarmarkPoolExecuteOn(uint256 _pid) public view returns (uint256) {
        return getEarmarkPoolExecuteOn(_pid, booster.poolInfo(_pid));
    }

    function getEarmarkPoolExecuteOn(uint256 _pid, IBooster.PoolInfo memory _pool) public view returns (uint256 executeOn) {
        if (_pool.shutdown) {
            return type(uint256).max;
        }
        executeOn = lastEarmarkAt[_pid] + earmarkPeriod;
        if (block.timestamp > executeOn) {
            return executeOn;
        }
        ( , uint256 periodFinish, , , , , , , bool paused) = IRewards(_pool.crvRewards).tokenRewards(mainRewardToken);
        if (!paused && periodFinish < executeOn) {
            executeOn = periodFinish;
        }
    }

    function _getDistributionByTokens(uint256 _pid, address _rewardToken) internal view returns(TokenDistro[] storage) {
        if (customDistributionByTokens[_pid][_rewardToken].length > 0) {
            return customDistributionByTokens[_pid][_rewardToken];
        }
        return distributionByTokens[_rewardToken];
    }

    function releaseToken(address _token, address _recipient) external onlyOwner {
        uint256 totalPendingRewards;
        uint256 poolLen = booster.poolLength();
        for (uint256 i = 0; i < poolLen; ) {
            IBooster.PoolInfo memory p = booster.poolInfo(i);
            if (p.shutdown) {
                if (_token == p.lptoken) {
                    totalPendingRewards = totalPendingRewards + IERC20(p.token).totalSupply();
                }
            } else {
                totalPendingRewards = totalPendingRewards + booster.lpPendingRewards(p.lptoken, _token);
            }
            unchecked {
                ++i;
            }
        }

        uint256 amountToWithdraw = IERC20(_token).balanceOf(address(booster)) - totalPendingRewards;

        address[] memory transferTo = new address[](1);
        transferTo[0] = _token;

        uint256[] memory transferAmount = new uint256[](1);
        transferAmount[0] = amountToWithdraw;

        bool[] memory callQueue = new bool[](1);
        callQueue[0] = false;

        booster.distributeRewards(type(uint256).max, address(0), _token, transferTo, transferAmount, callQueue);
        emit ReleaseToken(_token, amountToWithdraw, _recipient);
    }

    function distributionByTokenLength(address _token) external view returns (uint256) {
        return distributionByTokens[_token].length;
    }

    function customDistributionByTokenLength(uint256 _pid, address _token) external view returns (uint256) {
        return customDistributionByTokens[_pid][_token].length;
    }

    function distributionTokenList() external view returns (address[] memory) {
        return distributionTokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

interface IWomDepositor {
    function deposit(uint256 _amount, address _stakeAddress) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IAsset is IERC20 {
    function underlyingToken() external view returns (address);

    function pool() external view returns (address);

    function cash() external view returns (uint120);

    function liability() external view returns (uint120);

    function decimals() external view returns (uint8);

    function underlyingTokenDecimals() external view returns (uint8);

    function setPool(address pool_) external;

    function underlyingTokenBalance() external view returns (uint256);

    function transferUnderlyingToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function addCash(uint256 amount) external;

    function removeCash(uint256 amount) external;

    function addLiability(uint256 amount) external;

    function removeLiability(uint256 amount) external;
}

interface IWmxLocker {
    struct EarnedData {
        address token;
        uint256 amount;
    }
    struct LockedBalance {
        uint112 amount;
        uint32 unlockTime;
    }

    function lock(address _account, uint256 _amount) external;

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;

    function balanceOf(address _account) external view returns (uint256 amount);

    function balances(address _account) external view returns (uint112 locked, uint32 nextUnlockIndex);

    function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards);

    function getVotes(address account) external view returns (uint256);

    function getPastVotes(address account, uint256 timestamp) external view returns (uint256 votes);

    function lockedBalances(address _user) external view returns (
        uint256 total,
        uint256 unlockable,
        uint256 locked,
        LockedBalance[] memory lockData
    );
}

interface IBribeVoter {
    function vote(IERC20[] calldata _lpVote, int256[] calldata _deltas) external returns (uint256[][] memory bribeRewards);
    function votes(address _user, address _lpToken) external view returns (uint256);
    function infos(address _lpToken) external view returns (uint104 supplyBaseIndex, uint104 supplyVoteIndex, uint40 nextEpochStartTime, uint128 claimable, bool whitelist, address gaugeManager, address bribe);
    function weights(address _lpToken) external view returns (uint128 allocPoint, uint128 voteWeight);
    function getUserVotes(address _user, address _lpToken) external view returns (uint256);
}

interface IMasterWombatRewarder {
    function rewardTokens() external view returns (address[] memory tokens);
}

interface IExtraRewardsDistributor {
    function addReward(address _token, uint256 _amount) external;
}

interface IWomDepositorWrapper {
    function getMinOut(uint256, uint256) external view returns (uint256);

    function deposit(
        uint256,
        uint256,
        bool,
        address _stakeAddress
    ) external;
}

interface ITokenFactory{
    function CreateDepositToken(address) external returns(address);
    function CreateBribesVotingToken() external returns(address);
}

interface IBribesRewardFactory {
    function CreateBribesRewards(address _stakingToken, address _lptoken, bool _callOperatorOnGetReward) external returns (address);
}

interface IRewards{
    function asset() external returns(address);
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function withdraw(uint256 assets, address receiver, address owner) external;
    function exit(address) external;
    function getReward(address) external;
    function queueNewRewards(address, uint256) external;
    function notifyRewardAmount(uint256) external;
    function addExtraReward(address) external;
    function extraRewardsLength() external view returns (uint256);
    function stakingToken() external view returns (address);
    function rewardToken() external view returns(address);
    function earned(address _token, address _account) external view returns (uint256);
    function updateOperatorData(address operator_, uint256 pid_) external;
    function setRewardTokenPaused(address token_, bool paused_) external;
    function balanceOf(address _account) external view returns (uint256 amount);
    function rewardTokensList() external view returns (address[] memory);
    function tokenRewards(address _token) external view returns (address token, uint256 periodFinish, uint256 rewardRate, uint256 lastUpdateTime, uint256 rewardPerTokenStored, uint256 queuedRewards, uint256 currentRewards, uint256 historicalRewards, bool paused);
}

interface IGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IBribe {
    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external returns (uint256[] memory rewards);

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);

    function rewardInfo(uint256 i) external view returns (IERC20 rewardToken, uint96 tokenPerSec, uint128 accTokenPerShare, uint128 distributedAmount);
}

interface IVe {
    function vote(address user, int256 voteDelta) external;
}

interface INftLocker {
    function voteBoost(address _account) external view returns (uint256);
}

interface IBribeRewardsPool is IRewards {
    function withdrawAndUnwrapFrom(address _from, uint256 _amount, address _claimRecipient) external returns(bool);
    function updateBribesConfig(bool _callOperatorOnGetReward) external;
    function updateRatioConfig(uint256 _duration, uint256 _maxRewardRatio) external;
}

interface ITokenMinter is IERC20 {
    function mint(address,uint256) external;
    function burn(address,uint256) external;
    function setOperator(address) external;
    function updateOperator(address) external;
    function getFactAmounMint(uint256 _amount) external view returns(uint256 amount);
}

interface IStaker{
    function deposit(address, address) external returns (bool);
    function withdraw(address) external returns (uint256);
    function withdrawLp(address, address, uint256) external returns (bool);
    function withdrawAllLp(address, address) external returns (bool);
    function lock(uint256 _lockDays) external;
    function releaseLock(uint256 _slot) external returns(uint256);
    function getGaugeRewardTokens(address _lptoken, address _gauge) external returns (address[] memory tokens);
    function claimCrv(address, uint256) external returns (address[] memory tokens, uint256[] memory balances);
    function balanceOfPool(address, address) external view returns (uint256);
    function lpTokenToPid(address, address) external view returns (uint256);
    function operator() external view returns (address);
    function depositor() external view returns (address);
    function veWom() external view returns (address);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
    function setVote(bytes32 hash, bool valid) external;
    function setDepositor(address _depositor) external;
    function setOwner(address _owner) external;
}

interface IPool {
    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialDeposit(
        address token,
        uint256 amount
    ) external view returns (uint256 liquidity, uint256 reward);

    function quotePotentialWithdraw(
        address token,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function withdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quoteAmountIn(
        address fromToken,
        address toToken,
        int256 toAmount
    ) external view returns (uint256 amountIn, uint256 haircut);

    function addressOfAsset(address token) external view returns (address);
}

interface IWombatRouter {
    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);

    /**
     * @notice Returns the minimum input asset amount required to buy the given output asset amount
     * (accounting for fees and slippage)
     * Note: This function should be used as estimation only. The actual swap amount might
     * be different due to precision error (the error is typically under 1e-6)
     */
    function getAmountIn(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountOut
    ) external view returns (uint256 amountIn, uint256[] memory haircuts);

    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNativeForTokens(
        address[] calldata tokenPath, // the first address should be WBNB
        address[] calldata poolPath,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapExactTokensForNative(
        address[] calldata tokenPath, // the last address should be WBNB
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function addLiquidityNative(
        IPool pool,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external payable returns (uint256 liquidity);

    function removeLiquidityNative(
        IPool pool,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function removeLiquidityFromOtherAssetAsNative(
        IPool pool,
        address fromToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        bool shutdown;
    }

    function crv() external view returns (address);
    function owner() external view returns (address);
    function voterProxy() external view returns (address);
    function earmarkDelegate() external view returns (address);
    function poolLength() external view returns (uint256);
    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
    function depositFor(uint256 _pid, uint256 _amount, bool _stake, address _receiver) external returns (bool);
    function setOwner(address _owner) external;
    function setPoolManager(address _poolManager) external;
    function voterProxyClaimRewards(uint256 _pid, address[] memory pendingTokens) external returns (uint256[] memory pendingRewards);
    function addPool(address _lptoken, address _gauge) external returns (uint256);
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) external returns (uint256);
    function approveDistribution(address _distro, address[] memory _distributionTokens, uint256 _amount) external;
    function approvePoolsCrvRewardsDistribution(address _token) external;
    function distributeRewards(uint256 _pid, address _lpToken, address _rewardToken, address[] memory _transferTo, uint256[] memory _transferAmount, bool[] memory _callQueue) external;
    function lpPendingRewards(address _lptoken, address _token) external view returns (uint256);
    function earmarkRewards(uint256 _pid) external;
    function earmarkRewardsIfAvailable(uint256 _pid) external;
    function shutdownPool(uint256 _pid) external returns (bool);
    function forceShutdownPool(uint256 _pid) external returns (bool);
    function gaugeMigrate(address _newGauge, uint256[] memory migratePids) external;
    function voteExecute(address _voting, uint256 _value, bytes calldata _data) external returns (bytes memory);
    function setVotingValid(address _voting, bool _value) external;
    function mintRatio() external view returns (uint256);
    function customMintRatio(uint256 _pid) external view returns (uint256);
    function crvLockRewards() external view returns (address);
    function cvxLocker() external view returns (address);
}

interface IBoosterEarmark {
    function earmarkIncentive() external view returns (uint256);
    function distributionByTokenLength(address _token) external view returns (uint256);
    function distributionByTokens(address, uint256) external view returns (address, uint256, bool);
    function distributionTokenList() external view returns (address[] memory);
    function addPool(address _lptoken, address _gauge) external returns (uint256);
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) external returns (uint256);
    function isEarmarkAvailable(uint256 _pid) external view returns(bool);
    function isEarmarkPoolAvailable(uint256 _pid, IBooster.PoolInfo memory _pool) external view returns (bool);
    function earmarkRewards(uint256[] memory _pids) external;
    function earmarkPeriod() external view returns (uint256);
    function lastEarmarkAt(uint256 pid) external view returns (uint256);
    function getEarmarkPoolExecuteOn(uint256 pid) external view returns (uint256);
}

interface ISwapRouter {
    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);
}

interface IWomSwapDepositor {
    function pool() external view returns (address);
    function deposit(uint256 _amount, address _stakeAddress, uint256 _minAmountOut, uint256 _deadline) external returns (bool);
}

/**
 * @dev Interface of the MasterWombatV2
 */
interface IMasterWombatV2 {
    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
    external
    view
    returns (
        uint256 pendingRewards,
        IERC20[] memory bonusTokenAddresses,
        string[] memory bonusTokenSymbols,
        uint256[] memory pendingBonusRewards
    );

    function rewarderBonusTokenInfo(uint256 _pid)
    external
    view
    returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function multiClaim(uint256[] memory _pids)
    external
    returns (
        uint256 transfered,
        uint256[] memory rewards,
        uint256[][] memory additionalRewards
    );

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function updateFactor(address _user, uint256 _newVeWomBalance) external;

    function poolInfo(uint256 _pid) external view returns (address lpToken, uint96 allocPoint, IMasterWombatRewarder rewarder, uint256 sumOfFactors, uint104 accWomPerShare, uint104 accWomPerFactorShare, uint40 lastRewardTimestamp);
}

interface IMasterWombatV3 {
    struct PoolInfoV3 {
        address lpToken; // Address of LP token contract.
        ////
        address rewarder;
        uint40 periodFinish;
        ////
        uint128 sumOfFactors; // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
        uint128 rewardRate; // 20.18 fixed point.
        ////
        uint104 accWomPerShare; // 19.12 fixed point. Accumulated WOM per share, times 1e12.
        uint104 accWomPerFactorShare; // 19.12 fixed point. Accumulated WOM per factor share
        uint40 lastRewardTimestamp;
    }

    function poolInfoV3(uint256 _index) external view returns (PoolInfoV3 memory);

    // Info of each user.
    struct UserInfo {
        // storage slot 1
        uint128 amount; // 20.18 fixed point. How many LP tokens the user has provided.
        uint128 factor; // 20.18 fixed point. boosted factor = sqrt (lpAmount * veWom.balanceOf())
        // storage slot 2
        uint128 rewardDebt; // 20.18 fixed point. Reward debt. See explanation below.
        uint128 pendingWom; // 20.18 fixed point. Amount of pending wom
    }
    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);
}