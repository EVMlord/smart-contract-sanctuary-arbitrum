/**
 *Submitted for verification at Arbiscan.io on 2023-09-30
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/team.sol


pragma solidity ^0.8.7;


contract PricePredictionGame {
    enum Prediction { NONE, UP, DOWN }

    struct GameRound {
        address player;
        Prediction prediction;
        uint256 betAmount;
        int256 initialPrice;
        int256 finalPrice;
        uint256 startTime;
        bool isWin;
    }

    mapping(address => GameRound) public games;
    mapping(address => GameRound[]) public playerRounds;
    AggregatorV3Interface internal priceFeed;
    uint256 public prizePool = 0; // 獎池
    address public teamVault; // 團隊金庫地址
    address public owner; // 合約所有者地址

    constructor(address _priceFeed, address _teamVault) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        teamVault = _teamVault;
        owner = msg.sender;
    }

    function setTeamVault(address _newTeamVault) external {
        require(msg.sender == owner, "Only the owner can set the team vault address");
        teamVault = _newTeamVault;
    }

    function placeBet(Prediction prediction) external payable {
        require(prediction != Prediction.NONE, "Invalid prediction");
        require(games[msg.sender].player == address(0), "Ongoing game exists for this player");

        // 計算5%的投注金額
        uint256 teamShare = msg.value / 20; // 5%
        // 將5%的投注金額轉移到團隊的金庫
        payable(teamVault).transfer(teamShare);
        // 將剩餘的95%的投注金額添加到獎池
        prizePool += msg.value - teamShare;

        int256 currentPrice = getCurrentPrice();
        games[msg.sender] = GameRound({
            player: msg.sender,
            prediction: prediction,
            betAmount: msg.value,
            initialPrice: currentPrice,
            finalPrice: 0,
            startTime: block.timestamp,
            isWin: false
        });
    }

    function getCurrentPrice() public view returns (int256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return answer;
    }

    function getPriceAtTime(uint256 targetTimestamp) public view returns (int256) {
        (uint80 roundId, , , , ) = priceFeed.latestRoundData();
        while (roundId > 0) {
            (, int256 price, , uint256 timestamp, ) = priceFeed.getRoundData(roundId);
            if (timestamp <= targetTimestamp) {
                return price;
            }
            roundId--;
        }
        revert("Couldn't find the price for the specified time");
    }

    function settleGame() external {
        GameRound storage round = games[msg.sender];
        require(round.player != address(0), "No game found for this player");
        require(block.timestamp >= round.startTime + 180, "Game not yet mature");

        int256 priceAtSettlementTime = getPriceAtTime(round.startTime + 180);
        round.finalPrice = priceAtSettlementTime;

        uint256 payout = 0;
        if ((priceAtSettlementTime > round.initialPrice && round.prediction == Prediction.UP) ||
            (priceAtSettlementTime < round.initialPrice && round.prediction == Prediction.DOWN)) {
            round.isWin = true;
            payout = (round.betAmount * 19) / 20; // 95% of the bet amount
            if (prizePool >= payout) {
                prizePool -= payout;
            } else {
                payout = prizePool;
                prizePool = 0;
            }
        }
        if (payout > 0) {
            payable(msg.sender).transfer(payout);
        }

        playerRounds[msg.sender].push(round);
        delete games[msg.sender];
    }

}