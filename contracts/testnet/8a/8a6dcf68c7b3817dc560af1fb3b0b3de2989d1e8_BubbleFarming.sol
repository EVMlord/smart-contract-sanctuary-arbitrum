/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

interface IPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function getCollectedFees()
        external
        view
        returns (uint256 _token0, uint256 _token1);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address payable owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BubbleFarming is Ownable {
    address payable public distributor;
    IPair public pair = IPair(0x1FE7EF8C3aB19741aF1c31Ea6b1FC143606C9699);
    IERC20 public token = IERC20(0x0883688e524586C9E3d66078F4d71d81e51B69E3);

    uint256 public totalStaked;
    uint256 public totalDistributedReward;
    uint256 public totalWithdrawan;
    uint256 public uniqueStakers;

    uint256 public minDeposit = 100_000_000;
    uint256 public percentDivider = 100_00;

    struct PoolData {
        uint256 poolDuration;
        uint256 rewardMultiplier;
        uint256 totalStakers;
        uint256 totalStaked;
        uint256 totalDistributedReward;
        uint256 totalWithdrawan;
    }

    struct StakeData {
        uint256 planIndex;
        uint256 lpAmount;
        uint256 reward;
        uint256 startTime;
        uint256 Capturefee;
        uint256 endTime;
        bool isWithdrawn;
    }

    struct UserData {
        bool isExists;
        uint256 stakeCount;
        uint256 totalStaked;
        uint256 totalWithdrawan;
        uint256 totalDistributedReward;
        mapping(uint256 => StakeData) stakeRecord;
    }

    mapping(address => UserData) internal users;
    mapping(uint256 => PoolData) public pools;

    event STAKE(address Staker, uint256 amount);
    event WITHDRAW(address Staker, uint256 amount);

    constructor(address payable _owner, address payable _distributor)
        Ownable(_owner)
    {
        distributor = _distributor;
    }

    function stake(uint256 _amount, uint256 _planIndex) public {
        require(_planIndex < 4, "Invalid index");
        require(_amount >= minDeposit, "stake more than min amount");
        UserData storage user = users[msg.sender];
        StakeData storage userStake = user.stakeRecord[user.stakeCount];
        PoolData storage poolInfo = pools[_planIndex];
        if (!users[msg.sender].isExists) {
            users[msg.sender].isExists = true;
            uniqueStakers++;
        }

        pair.transferFrom(msg.sender, address(this), _amount);
        userStake.lpAmount = _amount;
        userStake.planIndex = _planIndex;
        userStake.startTime = block.timestamp;
        userStake.Capturefee = getTotalFee();
        userStake.endTime = block.timestamp + poolInfo.poolDuration;
        user.stakeCount++;
        user.totalStaked += _amount;
        poolInfo.totalStaked += _amount;
        totalStaked += _amount;
        poolInfo.totalStakers++;

        emit STAKE(msg.sender, _amount);
    }

    function withdraw(uint256 _index) public {
        UserData storage user = users[msg.sender];
        StakeData storage userStake = user.stakeRecord[_index];
        PoolData storage poolInfo = pools[userStake.planIndex];
        require(_index < user.stakeCount, "Invalid index");
        require(!userStake.isWithdrawn, "Already withdrawn");
        require(block.timestamp > userStake.endTime, "Wait for end time");
        pair.transfer(msg.sender, userStake.lpAmount);
        userStake.reward = calculateReward(
            msg.sender,
            _index,
            userStake.planIndex
        );
        token.transferFrom(distributor, msg.sender, userStake.reward);
        userStake.isWithdrawn = true;
        user.totalDistributedReward += userStake.reward;
        poolInfo.totalDistributedReward += userStake.reward;
        totalDistributedReward += userStake.reward;
        user.totalWithdrawan += userStake.lpAmount;
        poolInfo.totalWithdrawan += userStake.lpAmount;
        totalWithdrawan += userStake.lpAmount;

        emit WITHDRAW(msg.sender, userStake.lpAmount);
        emit WITHDRAW(msg.sender, userStake.reward);
    }

    function calculateReward(
        address _userAdress,
        uint256 _index,
        uint256 _planIndex
    ) public view returns (uint256 _reward) {
        PoolData storage poolInfo = pools[_planIndex];
        UserData storage user = users[_userAdress];
        StakeData storage userStake = user.stakeRecord[_index];
        uint256 share = (userStake.lpAmount * percentDivider) /
            pair.totalSupply();
        uint256 feeDifference = getTotalFee() - userStake.Capturefee;
        uint256 feeShare = (feeDifference * share) / percentDivider;
        _reward = feeShare * poolInfo.rewardMultiplier;
    }

    function getTotalFee() public view returns (uint256) {
        (uint256 token0Fee, uint256 token1Fee) = pair.getCollectedFees();
        uint256 totalFee;
        if (pair.token0() == address(token)) {
            token1Fee = (token1Fee * getTokenPrice()) / 1 ether;
        } else {
            token0Fee = (token0Fee * getTokenPrice()) / 1 ether;
        }
        totalFee = token0Fee + token1Fee;
        return totalFee;
    }

    function getTokenPrice() public view returns (uint256) {
        (uint256 token0Reserve, uint256 token1Reserve, ) = pair.getReserves();
        uint256 toknPrice;
        if (pair.token0() == address(token)) {
            toknPrice = (token0Reserve * 10**token.decimals()) / token1Reserve;
        } else {
            toknPrice = (token1Reserve * 10**token.decimals()) / token0Reserve;
        }
        return toknPrice;
    }

    function getUserInfo(address _user)
        public
        view
        returns (
            bool _isExists,
            uint256 _stakeCount,
            uint256 _totalStaked,
            uint256 _totalDistributedReward,
            uint256 _totalWithdrawan
        )
    {
        UserData storage user = users[_user];
        _isExists = user.isExists;
        _stakeCount = user.stakeCount;
        _totalStaked = user.totalStaked;
        _totalDistributedReward = user.totalDistributedReward;
        _totalWithdrawan = user.totalWithdrawan;
    }

    function getUserStakeInfo(address _user, uint256 _index)
        public
        view
        returns (
            uint256 _planIndex,
            uint256 _lpAmount,
            uint256 _capturedFee,
            uint256 _startTime,
            uint256 _endTime,
            uint256 _reward,
            bool _isWithdrawn
        )
    {
        StakeData storage userStake = users[_user].stakeRecord[_index];
        _planIndex = userStake.planIndex;
        _lpAmount = userStake.lpAmount;
        _capturedFee = userStake.Capturefee;
        _startTime = userStake.startTime;
        _endTime = userStake.endTime;
        _reward = userStake.reward;
        _isWithdrawn = userStake.isWithdrawn;
    }

    function SetPoolsDuration(
        uint256 _1,
        uint256 _2,
        uint256 _3,
        uint256 _4
    ) external onlyOwner {
        pools[0].poolDuration = _1;
        pools[1].poolDuration = _2;
        pools[2].poolDuration = _3;
        pools[3].poolDuration = _4;
    }

    function SetPoolsRewardMultiplier(
        uint256 _1,
        uint256 _2,
        uint256 _3,
        uint256 _4
    ) external onlyOwner {
        pools[0].rewardMultiplier = _1;
        pools[1].rewardMultiplier = _2;
        pools[2].rewardMultiplier = _3;
        pools[3].rewardMultiplier = _4;
    }

    function SetMinAmount(uint256 _amount) external onlyOwner {
        minDeposit = _amount;
    }

    function ChangeDistributor(address payable _distributor)
        external
        onlyOwner
    {
        distributor = _distributor;
    }
}