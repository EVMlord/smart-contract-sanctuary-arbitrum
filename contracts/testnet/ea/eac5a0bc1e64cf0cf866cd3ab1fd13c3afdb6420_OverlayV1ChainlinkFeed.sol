/**
 *Submitted for verification at Arbiscan on 2023-02-14
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

// SPDX-License-Identifier: MIT
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

pragma solidity 0.8.10;

library Oracle {
    struct Data {
        uint256 timestamp;
        uint256 microWindow;
        uint256 macroWindow;
        uint256 priceOverMicroWindow; // p(now) averaged over micro
        uint256 priceOverMacroWindow; // p(now) averaged over macro
        uint256 priceOneMacroWindowAgo; // p(now - macro) avg over macro
        uint256 reserveOverMicroWindow; // r(now) in ovl averaged over micro
        bool hasReserve; // whether oracle has manipulable reserve pool
    }
}

pragma solidity 0.8.10;

interface IOverlayV1Feed {
    // immutables
    function feedFactory() external view returns (address);

    function microWindow() external view returns (uint256);

    function macroWindow() external view returns (uint256);

    // returns freshest possible data from oracle
    function latest() external view returns (Oracle.Data memory);
}

pragma solidity 0.8.10;


abstract contract OverlayV1Feed is IOverlayV1Feed {
    using Oracle for Oracle.Data;

    address public immutable feedFactory;
    uint256 public immutable microWindow;
    uint256 public immutable macroWindow;

    constructor(uint256 _microWindow, uint256 _macroWindow) {
        // set the immutables
        microWindow = _microWindow;
        macroWindow = _macroWindow;
        feedFactory = msg.sender;
    }

    /// @dev returns freshest possible data from oracle
    function latest() external view returns (Oracle.Data memory) {
        return _fetch();
    }

    /// @dev fetches data from oracle. should be implemented differently
    /// @dev for each feed type
    function _fetch() internal view virtual returns (Oracle.Data memory);
}

pragma solidity 0.8.10;


contract OverlayV1ChainlinkFeed is OverlayV1Feed {
    AggregatorV3Interface public immutable aggregator;
    string public description;
    uint8 public decimals;

    constructor(
        address _aggregator,
        uint256 _microWindow,
        uint256 _macroWindow
    ) OverlayV1Feed(_microWindow, _macroWindow) {
        require(_aggregator != address(0), "Invalid feed");

        aggregator = AggregatorV3Interface(_aggregator);
        decimals = aggregator.decimals();
        description = aggregator.description();
    }

    function _fetch() internal view virtual override returns (Oracle.Data memory) {
        (uint80 roundId, , , , ) = aggregator.latestRoundData();

        (
            uint256 priceOverMicroWindow,
            uint256 priceOverMacroWindow,
            uint256 priceOneMacroWindowAgo
        ) = _getAveragePrice(roundId);

        return
            Oracle.Data({
                timestamp: block.timestamp,
                microWindow: microWindow,
                macroWindow: macroWindow,
                priceOverMicroWindow: priceOverMicroWindow,
                priceOverMacroWindow: priceOverMacroWindow,
                priceOneMacroWindowAgo: priceOneMacroWindowAgo,
                reserveOverMicroWindow: 0,
                hasReserve: false
            });
    }

    function _getAveragePrice(uint80 roundId)
        internal
        view
        returns (
            uint256 priceOverMicroWindow,
            uint256 priceOverMacroWindow,
            uint256 priceOneMacroWindowAgo
        )
    {
        // nextTimestamp will be next time stamp recorded from current round id
        uint256 nextTimestamp = block.timestamp;
        // these values will keep decreasing till zero, until all data is used up in respective window
        uint256 _microWindow = microWindow;
        uint256 _macroWindow = macroWindow;

        // timestamp till which value need to be considered for macrowindow ago
        uint256 macroAgoTargetTimestamp = nextTimestamp - 2 * macroWindow;

        uint256 sumOfPriceMicroWindow;
        uint256 sumOfPriceMacroWindow;
        uint256 sumOfPriceMacroWindowAgo;

        while (true) {
            (, int256 answer, , uint256 updatedAt, ) = aggregator.getRoundData(roundId);

            if (_microWindow > 0) {
                uint256 dt = nextTimestamp - updatedAt < _microWindow
                    ? nextTimestamp - updatedAt
                    : _microWindow;
                sumOfPriceMicroWindow += dt * uint256(answer);
                _microWindow -= dt;
            }

            if (_macroWindow > 0) {
                uint256 dt = nextTimestamp - updatedAt < _macroWindow
                    ? nextTimestamp - updatedAt
                    : _macroWindow;
                sumOfPriceMacroWindow += dt * uint256(answer);
                _macroWindow -= dt;
            }

            if (updatedAt <= block.timestamp - macroWindow) {
                uint256 startTime = nextTimestamp > block.timestamp - macroWindow
                    ? block.timestamp - macroWindow
                    : nextTimestamp;
                if (updatedAt >= macroAgoTargetTimestamp) {
                    sumOfPriceMacroWindowAgo += (startTime - updatedAt) * uint256(answer);
                } else {
                    sumOfPriceMacroWindowAgo +=
                        (startTime - macroAgoTargetTimestamp) *
                        uint256(answer);
                    break;
                }
            }

            nextTimestamp = updatedAt;
            roundId--;
        }

        priceOverMicroWindow =
            (sumOfPriceMicroWindow * (10**18)) /
            (microWindow * 10**aggregator.decimals());
        priceOverMacroWindow =
            (sumOfPriceMacroWindow * (10**18)) /
            (macroWindow * 10**aggregator.decimals());
        priceOneMacroWindowAgo =
            (sumOfPriceMacroWindowAgo * (10**18)) /
            (macroWindow * 10**aggregator.decimals());
    }
}