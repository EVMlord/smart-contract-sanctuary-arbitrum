// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./erc20/IERC20.sol";
import "./erc20/SafeERC20.sol";
import "./erc20/Ownable.sol";
import "./erc20/SafeMath.sol";
import "./erc20/ReentrancyGuard.sol";
import "./erc20/IWETH.sol";

import "./erc20/IStrategy.sol";
import "./erc20/WETHelper.sol";
import "./erc20/AntiFlashload.sol";

interface IMint {
    function mint(address _to, uint256 _amount) external;
}

contract AETFarm is Ownable, ReentrancyGuard, AntiFlashload {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 shares;
        uint256 update;
        uint256 rewardDebt; // Reward debt. See explanation below.

        // We do some fancy math here. Basically, any point in time, the amount of Sushi
        // entitled to a user but is pending to be distributed is:
        //
        //   amount = user.shares / sharesTotal * wantLockedTotal
        //   pending reward = (amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws want tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    uint256 public constant depositFeeFactorMax = 100; //10%
    uint256 public constant withdrawFeeFactorMax = 100; //10%

    uint256 public constant STRAT_MODE_NONE = 0;
    uint256 public constant STRAT_MODE_MORE_LP = 1;
    uint256 public constant STRAT_MODE_MORE_EARN = 2;

    uint256 public totalTokenPerBlock = 0;

    struct PoolInfo {
        IERC20 lpToken; // Address of the want token.
        uint256 tokenPerBlock;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 accInterestPerShare;
        uint256 depositFee; // default is 0%.
        uint256 withdrawFee; // default is 0%.
        address strat0; // Strategy mode0 STRAT_MODE_MORE_TOKEN
    }

    address public farmToken;
    // Bonus muliplier for early impulse makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    uint256 public startBlock;
    address public devaddr;
    address public WETH;
    // ETH Helper for the transfer, stateless.
    WETHelper public wethelper;

    PoolInfo[] public poolInfo; // Info of each pool.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens.
    uint256 public totalAllocPoint = 0; // Total allocation points. Must be the sum of all allocation points in all pools.
    address[] public accounts;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 shares
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 shares
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event DepositRewards(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Mint(address indexed to, uint256 amount);

    function initialize(
        address _farmToken,
        address _devaddr,
        address _weth
    ) public initializer {
        Ownable.__Ownable_init();
        AntiFlashload.__Flashload_init(1);
        farmToken = _farmToken;
        devaddr = _devaddr;
        WETH = _weth;
        wethelper = new WETHelper();
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function changeWeth(address _weth) public onlyOwner {
        WETH = _weth;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _tokenPerBlock,
        address _want,
        bool _withUpdate,
        uint256 _depositFee,
        uint256 _withdrawFee,
        address _strat0
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.timestamp > startBlock
            ? block.timestamp
            : startBlock;
        totalTokenPerBlock = totalTokenPerBlock.add(_tokenPerBlock);

        require(
            _depositFee < depositFeeFactorMax &&
                _withdrawFee < withdrawFeeFactorMax,
            "!deposit/withdraw fee"
        );
        poolInfo.push(
            PoolInfo({
                lpToken: IERC20(_want),
                tokenPerBlock: _tokenPerBlock,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0,
                accInterestPerShare: 0,
                depositFee: _depositFee,
                withdrawFee: _withdrawFee,
                strat0: _strat0
            })
        );
    }

    function doCompound() public onlyOwner {
        uint256 length = poolLength();
        for (uint256 _pid = 0; _pid < length; ++_pid) {
            PoolInfo storage pool = poolInfo[_pid];
            IStrategy strat = _UserStrategy(pool);
            strat.earn();
        }
    }

    function doCompound1(uint _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        IStrategy strat = _UserStrategy(pool);
        strat.earn();
    }

    function setAccounts(address _user) internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == _user) {
                return;
            }
        }
        accounts.push(_user);
    }

    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // Update the given pool's Impulse allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _tokenPerBlock,
        bool _withUpdate,
        uint256 _depositFee,
        uint256 _withdrawFee
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalTokenPerBlock = totalTokenPerBlock
            .sub(poolInfo[_pid].tokenPerBlock)
            .add(_tokenPerBlock);
        require(
            _depositFee < depositFeeFactorMax &&
                _withdrawFee < withdrawFeeFactorMax,
            "!deposit/withdraw fee"
        );
        poolInfo[_pid].tokenPerBlock = _tokenPerBlock;
        poolInfo[_pid].depositFee = _depositFee;
        poolInfo[_pid].withdrawFee = _withdrawFee;
    }

    function setToken(uint256 _pid, address _token) public onlyOwner {
        poolInfo[_pid].lpToken = IERC20(_token);
    }

    function setVault(uint256 _pid, address _strat0) public onlyOwner {
        poolInfo[_pid].strat0 = _strat0;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function pendingToken(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 sharesTotal = _sharesTotal(pool);
        if (block.timestamp > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.timestamp
            );
            uint256 tokenReward = multiplier.mul(pool.tokenPerBlock);
            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e12).div(sharesTotal)
            );
        }
        uint256 pending = user.shares.mul(accTokenPerShare).div(1e12).sub(
            user.rewardDebt
        );

        return (pending);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardBlock) {
            return;
        }
        uint256 sharesTotal = _sharesTotal(pool);
        if (sharesTotal == 0) {
            pool.lastRewardBlock = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            pool.lastRewardBlock,
            block.timestamp
        );
        if (multiplier <= 0) {
            return;
        }
        uint256 tokenReward = multiplier.mul(pool.tokenPerBlock);

        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(1e12).div(sharesTotal)
        );
        pool.lastRewardBlock = block.timestamp;
    }

    function harvest(
        PoolInfo storage pool,
        UserInfo storage user
    ) internal returns (uint256) {
        uint256 pending;
        if (user.shares > 0) {
            pending = user.shares.mul(pool.accTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                safeFTokenTransfer(msg.sender, pending);
            }
        }
        return pending;
    }

    function harvestCToken(address _user, uint _pid) public {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        if (user.shares > 0) {
            IStrategy(pool.strat0).harvest(_user);
        }
    }

    // View function to see staked Want tokens on frontend.
    function stakedWantTokens(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        IStrategy strat = _UserStrategy(pool);

        (uint256 wantLockedTotal, uint256 sharesTotal) = strat.sharesInfo();
        if (sharesTotal == 0) {
            return 0;
        }
        return user.shares.mul(wantLockedTotal).div(sharesTotal);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function _sharesTotal(
        PoolInfo storage pool
    ) internal view returns (uint256 sharesTotal) {
        if (pool.strat0 != address(0)) {
            sharesTotal += IStrategy(pool.strat0).sharesTotal();
        }
    }

    function _UserStrategy(
        PoolInfo storage pool
    ) internal view returns (IStrategy) {
        return IStrategy(pool.strat0);
    }

    function UserStrategy(uint256 _pid) external view returns (IStrategy) {
        PoolInfo storage pool = poolInfo[_pid];
        return _UserStrategy(pool);
    }

    function deposit(
        uint256 _pid,
        uint256 _wantAmt
    ) public payable enterFlashload(_pid) nonReentrant {
        require(!isContract(msg.sender));
        setAccounts(msg.sender);
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        harvest(pool, user);

        if (msg.value > 0) {
            IWETH(WETH).deposit{value: msg.value}();
        }
        if (address(pool.lpToken) == WETH) {
            if (_wantAmt > 0) {
                pool.lpToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    _wantAmt
                );
            }
            if (msg.value > 0) {
                _wantAmt = _wantAmt.add(msg.value);
            }
        } else if (_wantAmt > 0) {
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _wantAmt);
        }
        IStrategy strat = _UserStrategy(pool);
        uint256 sharesAdded;
        uint256 buybackAmount;
        if (_wantAmt > 0) {
            buybackAmount = _wantAmt.mul(pool.depositFee).div(1000);
            if (buybackAmount > 0) {
                pool.lpToken.safeTransfer(devaddr, buybackAmount);
                _wantAmt = _wantAmt.sub(buybackAmount);
            }
            user.update = block.timestamp;
        }
        pool.lpToken.safeApprove(address(strat), _wantAmt);
        sharesAdded = strat.deposit(msg.sender, _wantAmt);
        // sharesAdded = _wantAmt;
        user.shares = user.shares.add(sharesAdded);
        user.amount = user.amount.add(_wantAmt);

        user.rewardDebt = user.shares.mul(pool.accTokenPerShare).div(1e12);

        // transfer the earn token if have
        // strat.onRewardEarn(msg.sender, user.shares);

        emit Deposit(msg.sender, _pid, _wantAmt, sharesAdded);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(
        uint256 _pid,
        uint256 _wantAmt
    ) public leaveFlashload(_pid) nonReentrant {
        require(!isContract(msg.sender));
        setAccounts(msg.sender);
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        IStrategy strat = _UserStrategy(pool);

        (uint256 wantLockedTotal, uint256 sharesTotal) = strat.sharesInfo();

        require(user.shares > 0, "user.shares is 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        // Withdraw pending Sushi
        harvest(pool, user);

        // Withdraw want tokens
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);
        if (_wantAmt > amount) {
            _wantAmt = amount;
        }
        uint256 buybackAmount;
        uint256 sharesRemoved;
        if (_wantAmt > 0) {
            sharesRemoved = strat.withdraw(msg.sender, _wantAmt);

            // set shares to zero once _wantAmt == amount (means withdraw all of token)
            if (sharesRemoved > user.shares || _wantAmt == amount) {
                user.shares = 0;
            } else {
                user.shares = user.shares.sub(sharesRemoved);
            }

            uint256 wantBal = IERC20(pool.lpToken).balanceOf(address(this));
            if (wantBal < _wantAmt) {
                _wantAmt = wantBal;
            }
            if (user.amount > _wantAmt) {
                user.amount = user.amount.sub(_wantAmt);
            } else {
                user.amount = 0;
            }

            buybackAmount = _wantAmt.mul(pool.withdrawFee).div(1000);
            if (buybackAmount > 0) {
                pool.lpToken.safeTransfer(devaddr, buybackAmount);
                _wantAmt = _wantAmt.sub(buybackAmount);
            }

            if (address(pool.lpToken) == WETH) {
                withdrawEth(address(msg.sender), _wantAmt, false);
            } else {
                pool.lpToken.safeTransfer(address(msg.sender), _wantAmt);
            }
        }

        user.rewardDebt = user.shares.mul(pool.accTokenPerShare).div(1e12);

        emit Withdraw(msg.sender, _pid, _wantAmt, sharesRemoved);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        IStrategy strat = _UserStrategy(pool);

        (uint256 wantLockedTotal, uint256 sharesTotal) = strat.sharesInfo();
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);

        strat.withdraw(msg.sender, amount);

        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
        user.shares = 0;
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe Sushi transfer function, just in case if rounding error causes pool to not have enough
    function safeFTokenTransfer(address _to, uint256 _amt) internal {
        uint256 bal = IERC20(farmToken).balanceOf(address(this));
        if (_amt > bal) {
            IERC20(farmToken).transfer(_to, bal);
        } else {
            IERC20(farmToken).transfer(_to, _amt);
        }
    }

    function withdrawEth(address _to, uint256 _amount, bool _isWeth) internal {
        bool isInProxy = true;
        if (_isWeth) {
            IERC20(WETH).safeTransfer(_to, _amount);
        } else if (isInProxy) {
            IERC20(WETH).safeTransfer(address(wethelper), _amount);
            wethelper.withdraw(WETH, _to, _amount);
        } else {
            IWETH(WETH).withdraw(_amount);
            (bool success, ) = _to.call{value: _amount}(new bytes(0));
            require(success, "!WETHelper: ETH_TRANSFER_FAILED");
        }
    }

    function setFlashloadBlk(uint256 _flashloadBlk) public onlyOwner {
        flashloadBlk = _flashloadBlk;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETHelper {
    function withdraw(uint256) external;
}

contract WETHelper {
    receive() external payable {}

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!WETHelper: ETH_TRANSFER_FAILED");
    }

    function withdraw(
        address _eth,
        address _to,
        uint256 _amount
    ) public {
        IWETHelper(_eth).withdraw(_amount);
        safeTransferETH(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "./IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library SafeERC20 {
    function _safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "!APPROVE_FAILED"
        );
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (value > 0 && token.allowance(msg.sender, to) > 0)
            _safeApprove(token, to, 0);
        return _safeApprove(token, to, value);
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "!TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "!TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";
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
pragma solidity >=0.6.0 <0.9.0;

import "../erc20/Initializable.sol";
import "./Context.sol";

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
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(initializing, "Initializable: contract is not initializing");
        _;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// For interacting with our own strategy
interface IStrategy {
    // Total want tokens managed by stratfegy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    // amount: Total want tokens managed by stratfegy
    // shares: Sum of all shares of users to wantLockedTotal
    function sharesInfo() external view returns (uint256, uint256);

    // Main want token compounding function
    function earn() external;

    function harvest(address _userAddress) external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(
        address _userAddress,
        uint256 _wantAmt
    ) external returns (uint256);

    // Transfer want tokens strategy -> autoFarm
    function withdraw(
        address _userAddress,
        uint256 _wantAmt
    ) external returns (uint256);

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function accInterestPerShare() external view returns (uint256);

    function updatePool() external returns (uint256);

    function distributeRewards(
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function onRewardEarn(address _user, uint256 _amount) external;

    struct EarnInfo {
        address token;
        uint256 amount;
    }

    function pendingEarn(
        address _user
    ) external view returns (EarnInfo[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "../erc20/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

abstract contract AntiFlashload {
    // Info of each user that stakes block no.
    mapping(uint256 => mapping(address => uint256)) public _blockMap;
    uint256 public flashloadBlk; // at least 1 block.

    constructor() {
        __Flashload_init(1);
    }

    function __Flashload_init(uint256 _initBlk) internal {
        flashloadBlk = _initBlk;
    }

    modifier enterFlashload(uint256 id) {
        _blockMap[id][msg.sender] = block.number;
        _;
    }

    modifier leaveFlashload(uint256 id) {
        require(
            block.number >= _blockMap[id][msg.sender] + flashloadBlk,
            "!anti flashload"
        );
        _;
    }
}