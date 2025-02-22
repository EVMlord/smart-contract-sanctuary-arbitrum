/**
 *Submitted for verification at Arbiscan on 2023-05-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

interface IRandomizer {
	function request(uint256 callbackGasLimit) external returns (uint256);
	// function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);    // we don't use this right now
	function clientWithdrawTo(address _to, uint256 _amount) external;
    // Deposits ETH to Randomizer for the client contract
    function clientDeposit(address client) external payable; 
}

struct Bet {
    address gambler;
    uint256 betAmount;
    uint8 rollUnder;
    uint8 modulo;
}

contract DicetoWin {
    // randomizer.ai on zksync
    IRandomizer public randomizer = IRandomizer(0x923096Da90a3b60eb7E12723fA2E1547BA9236Bc);
    
    address public owner;

    uint8 public houseEdgePercent = 5; // 5%

    // eth that is locked in pending bets
    // stops us from accepting more bets than we should
    uint256 public lockedBets;

    // map of game id to gambler address, bet amount, roll under, modulo
    mapping (uint256 => Bet) public bets;

    uint256 public minBet = 0.001 ether;

    event BetResult(uint256 indexed gameId, address indexed gambler, uint256 betAmount, uint256 rollUnder, uint256 randomNumber, bool won);

    modifier onlyOwner() {
		require(msg.sender == owner, "Sender is not owner");
		_;
	}

    constructor() payable {
        owner = msg.sender;
    }

    // take bet amount as function parameter
    function placeBet(uint8 rollUnder, uint8 modulo) external payable {
        require(msg.value >= minBet, "Bet amount is less than minimum bet");
        require(modulo > 1 && modulo <= 100, "Modulo must be between 2 and 100");
        require(0 < rollUnder && rollUnder <= modulo, "Roll under must be between 1 and modulo");

        uint256 winAmount = (msg.value - (msg.value * houseEdgePercent / 100)) * modulo / rollUnder;
        
        lockedBets += winAmount;
        // check whether we have enough to actually accept this bet
        require(lockedBets < address(this).balance, "Cannot accept this bet");

        uint256 id = randomizer.request(100000);

        bets[id] = Bet(msg.sender, msg.value, rollUnder, modulo);


    }

    // callback function for randomizer.ai
    function randomizerCallback(uint256 _id, bytes32 _randomNumber) external {
        // callback should only be called by randomizer
		require(msg.sender == address(randomizer), "Caller not randomizer");

        // get bet from mapping
        Bet memory bet = bets[_id];

        uint256 dice = uint256(_randomNumber) % bet.modulo;
        uint256 winAmount = (bet.betAmount - (bet.betAmount * houseEdgePercent / 100)) * bet.modulo / bet.rollUnder;

        // unlock the eth
        lockedBets -= winAmount;

        if (bet.rollUnder > dice) {
            // win
            payable(bet.gambler).transfer(winAmount + bet.betAmount);   // send what they deposited + their winnings
            emit BetResult(_id, bet.gambler, bet.betAmount, bet.rollUnder, dice, true);
        }
        else {
            // lose
            emit BetResult(_id, bet.gambler, bet.betAmount, bet.rollUnder, dice, false);
        }
        
    }

    // Allows the owner to withdraw their deposited randomizer funds
	function randomizerWithdraw(uint256 amount) external onlyOwner {
		randomizer.clientWithdrawTo(msg.sender, amount);
	}

    function bye() external onlyOwner {
        require(lockedBets == 0, "Cannot destroy contract while there are locked bets");
        selfdestruct(payable(owner));
    }

    function changeHouseEdgePercent(uint8 newHouseEdgePercent) external onlyOwner {
        houseEdgePercent = newHouseEdgePercent;
    }
    
    function changeMinBet(uint256 newMinBet) external onlyOwner {
        minBet = newMinBet;
    }

    function addEth() external payable {
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    function setNewOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // deposit eth thats in the contract to this contract's balance in randomizer.ai which is used for the callback as well as the actual vrf fee.
    function withdrawToRandomizer(uint256 amount) external onlyOwner {
        randomizer.clientDeposit{value: amount}(address(this));
    }

}