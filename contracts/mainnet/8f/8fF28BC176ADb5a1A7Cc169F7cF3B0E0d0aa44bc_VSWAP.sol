// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

contract VSWAP {
    address public owner;
    address public immutable tokenAddress;
    address public immutable depositToken;

    uint256 public baseTokenUint = 1 ether;
    uint256 public swapPrice = 936400000000;
    uint256 public withdrawDuration = 24 days;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public withdrawAt;
    mapping(address => uint256) public withdrawAmount;

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    constructor(address _xtoken, address _token) {
        owner = msg.sender;
        depositToken = _token;
        tokenAddress = _xtoken;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setWithdrawDuration(uint256 duration) external onlyOwner {
        withdrawDuration = duration;
    }

    function withdrawToken(
        address token_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        TransferHelper.safeTransfer(token_, to_, amount_);
    }

    function depositTo(address to_, uint256 amount_) external returns (bool) {
        TransferHelper.safeTransferFrom(
            depositToken,
            msg.sender,
            address(this),
            amount_
        );

        uint256 tokenAmount = (amount_ * baseTokenUint) / swapPrice;
        balances[msg.sender] += tokenAmount;
        TransferHelper.safeTransfer(tokenAddress, to_, tokenAmount);
        return true;
    }

    function transferTo(address to_, uint256 amount_) external returns (bool) {
        TransferHelper.safeTransferFrom(
            tokenAddress,
            msg.sender,
            address(this),
            amount_
        );
        TransferHelper.safeTransfer(tokenAddress, to_, amount_);
        balances[to_] += amount_;
        return true;
    }

    function deposit(uint256 amount_) external {
        TransferHelper.safeTransferFrom(
            depositToken,
            msg.sender,
            address(this),
            amount_
        );

        uint256 tokenAmount = (amount_ * baseTokenUint) / swapPrice;
        balances[msg.sender] += tokenAmount;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, tokenAmount);
    }

    function withdraw(uint256 amount_) external {
        require(balances[msg.sender] >= amount_, "insufficient balance");
        balances[msg.sender] -= amount_;
        withdrawAt[msg.sender] = block.timestamp;
        TransferHelper.safeTransferFrom(
            tokenAddress,
            msg.sender,
            address(this),
            amount_
        );
        withdrawAmount[msg.sender] += amount_;
    }

    function cancelWithdraw(uint256 amount_) external {
        require(withdrawAmount[msg.sender] >= amount_, "insufficient balance");
        withdrawAmount[msg.sender] -= amount_;
        balances[msg.sender] += amount_;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, amount_);
    }

    function confirmWithdraw() external {
        require(withdrawAmount[msg.sender] > 0, "insufficient balance");
        require(
            withdrawAt[msg.sender] + withdrawDuration < block.timestamp,
            "too early"
        );

        uint256 amount_ = withdrawAmount[msg.sender];
        withdrawAmount[msg.sender] = 0;
        uint256 swapAmount = (amount_ * swapPrice) / baseTokenUint;
        TransferHelper.safeTransfer(depositToken, msg.sender, swapAmount);
    }
}