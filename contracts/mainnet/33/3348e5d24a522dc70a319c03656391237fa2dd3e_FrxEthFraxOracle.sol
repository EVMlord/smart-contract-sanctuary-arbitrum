// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= FrxEthFraxOracle =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Jon Walch: https://github.com/jonwalch

// Reviewers
// Drake Evans: https://github.com/DrakeEvans
// Dennis: https://github.com/denett

// ====================================================================
import { FraxOracle, ConstructorParams as FraxOracleParams } from "src/frax-oracle/abstracts/FraxOracle.sol";

/// @title FrxEthFraxOracle
/// @author Jon Walch (Frax Finance) https://github.com/jonwalch
/// @notice Drop in replacement for a chainlink oracle for price of frxEth in ETH
contract FrxEthFraxOracle is FraxOracle {
    constructor(FraxOracleParams memory _params) FraxOracle(_params) {}

    // ====================================================================
    // View Helpers
    // ====================================================================

    /// @notice The ```description``` function returns the description of the contract
    /// @return _description The description of the contract
    function description() external pure override returns (string memory _description) {
        _description = "frxEth/ETH";
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================ FraxOracle ============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Jon Walch: https://github.com/jonwalch

// Contributors
// Dennis: https://github.com/denett

// Reviewers
// Drake Evans: https://github.com/DrakeEvans

// ====================================================================
import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import { ITimelock2Step } from "frax-std/access-control/v1/interfaces/ITimelock2Step.sol";
import { IPriceSourceReceiver } from "../interfaces/IPriceSourceReceiver.sol";

/// @notice maximumDeviation Percentage of acceptable deviation i.e. 0.03e18 = 3%
/// @notice maximumOracleDelay Seconds until data is considered stale
struct ConstructorParams {
    // = Timelock2Step
    address timelockAddress;
    // = FraxOracle
    address baseErc20;
    address quoteErc20;
    address priceSource;
    uint256 maximumDeviation;
    uint256 maximumOracleDelay;
}

/// @title FraxOracle
/// @author Jon Walch (Frax Finance) https://github.com/jonwalch
/// @notice Drop in replacement for a chainlink oracle, also supports Fraxlend style high and low prices
abstract contract FraxOracle is AggregatorV3Interface, IPriceSourceReceiver, ERC165Storage, Timelock2Step {
    /// @notice Maximum deviation of price source data between low and high, beyond which it is considered bad data
    uint256 public maximumDeviation;

    /// @notice Maximum delay of price source data, after which it is considered stale
    uint256 public maximumOracleDelay;

    /// @notice The address of the Erc20 base token contract
    address public immutable BASE_TOKEN;

    /// @notice The address of the Erc20 quote token contract
    address public immutable QUOTE_TOKEN;

    /// @notice Contract that posts price updates through addRoundData()
    address public priceSource;

    /// @notice Last round ID where isBadData is false and price is within maximum deviation
    uint80 public lastCorrectRoundId;

    /// @notice Array of round data
    Round[] public rounds;

    /// @notice Packed Round data struct
    /// @notice priceLow Lower of the two prices
    /// @notice priceHigh Higher of the two prices
    /// @notice timestamp Time of price
    /// @notice isBadData If data is bad / should be used
    struct Round {
        uint104 priceLow;
        uint104 priceHigh;
        uint40 timestamp;
        bool isBadData;
    }

    constructor(ConstructorParams memory _params) Timelock2Step() {
        _setTimelock({ _newTimelock: _params.timelockAddress });
        _registerInterface({ interfaceId: type(ITimelock2Step).interfaceId });
        _registerInterface({ interfaceId: type(AggregatorV3Interface).interfaceId });
        _registerInterface({ interfaceId: type(IPriceSourceReceiver).interfaceId });

        BASE_TOKEN = _params.baseErc20;
        QUOTE_TOKEN = _params.quoteErc20;

        _setMaximumDeviation(_params.maximumDeviation);
        _setMaximumOracleDelay(_params.maximumOracleDelay);
        _setPriceSource(_params.priceSource);
    }

    // ====================================================================
    // Events
    // ====================================================================

    /// @notice The ```SetMaximumOracleDelay``` event is emitted when the max oracle delay is set
    /// @param oldMaxOracleDelay The old max oracle delay
    /// @param newMaxOracleDelay The new max oracle delay
    event SetMaximumOracleDelay(uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    /// @notice The ```SetPriceSource``` event is emitted when the price source is set
    /// @param oldPriceSource The old price source address
    /// @param newPriceSource The new price source address
    event SetPriceSource(address oldPriceSource, address newPriceSource);

    /// @notice The ```SetMaximumDeviation``` event is emitted when the max oracle delay is set
    /// @param oldMaxDeviation The old max oracle delay
    /// @param newMaxDeviation The new max oracle delay
    event SetMaximumDeviation(uint256 oldMaxDeviation, uint256 newMaxDeviation);

    // ====================================================================
    // Internal Configuration Setters
    // ====================================================================

    /// @notice The ```_setMaximumOracleDelay``` function sets the max oracle delay to determine if data is stale
    /// @param _newMaxOracleDelay The new max oracle delay
    function _setMaximumOracleDelay(uint256 _newMaxOracleDelay) internal {
        uint256 _maxOracleDelay = maximumOracleDelay;
        if (_maxOracleDelay == _newMaxOracleDelay) revert SameMaximumOracleDelay();
        emit SetMaximumOracleDelay({ oldMaxOracleDelay: _maxOracleDelay, newMaxOracleDelay: _newMaxOracleDelay });
        maximumOracleDelay = _newMaxOracleDelay;
    }

    /// @notice The ```_setPriceSource``` function sets the price source
    /// @param _newPriceSource The new price source
    function _setPriceSource(address _newPriceSource) internal {
        address _priceSource = priceSource;
        if (_priceSource == _newPriceSource) revert SamePriceSource();
        emit SetPriceSource({ oldPriceSource: _priceSource, newPriceSource: _newPriceSource });
        priceSource = _newPriceSource;
    }

    /// @notice The ```_setMaximumDeviation``` function sets the maximum deviation between low and high
    /// @param _newMaximumDeviation The new maximum deviation
    function _setMaximumDeviation(uint256 _newMaximumDeviation) internal {
        uint256 _maxDeviation = maximumDeviation;
        if (_newMaximumDeviation == _maxDeviation) revert SameMaximumDeviation();
        emit SetMaximumDeviation({ oldMaxDeviation: _maxDeviation, newMaxDeviation: _newMaximumDeviation });
        maximumDeviation = _newMaximumDeviation;
    }

    // ====================================================================
    // Configuration Setters
    // ====================================================================

    /// @notice The ```setMaximumOracleDelay``` function sets the max oracle delay to determine if data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external {
        _requireTimelock();
        _setMaximumOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    /// @notice The ```setPriceSource``` function sets the price source
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newPriceSource The new price source address
    function setPriceSource(address _newPriceSource) external {
        _requireTimelock();
        _setPriceSource({ _newPriceSource: _newPriceSource });
    }

    /// @notice The ```setMaximumDeviation``` function sets the max oracle delay to determine if data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newMaxDeviation The new max oracle delay
    function setMaximumDeviation(uint256 _newMaxDeviation) external {
        _requireTimelock();
        _setMaximumDeviation({ _newMaximumDeviation: _newMaxDeviation });
    }

    // ====================================================================
    // Metadata
    // ====================================================================

    /// @notice The ```decimals``` function returns the number of decimals in the response.
    function decimals() external pure virtual override returns (uint8 _decimals) {
        _decimals = 18;
    }

    /// @notice The ```version``` function returns the version number for the AggregatorV3Interface.
    /// @dev Adheres to AggregatorV3Interface, which is different than typical semver
    function version() external view virtual returns (uint256 _version) {
        _version = 1;
    }

    // ====================================================================
    // Price Source Receiver
    // ====================================================================

    /// @notice The ```addRoundData``` adds new price data to be served later
    /// @dev Can only be called by the preconfigured price source
    /// @param _isBadData Boolean representing if the data is bad from underlying chainlink oracles from FraxDualOracle's getPrices()
    /// @param _priceLow The low price returned from a FraxDualOracle's getPrices()
    /// @param _priceHigh The high price returned from a FraxDualOracle's getPrices()
    /// @param _timestamp The timestamp that FraxDualOracle's getPrices() was called
    function addRoundData(bool _isBadData, uint104 _priceLow, uint104 _priceHigh, uint40 _timestamp) external {
        if (msg.sender != priceSource) revert OnlyPriceSource();
        if (_timestamp > block.timestamp) revert CalledWithFutureTimestamp();

        uint256 _roundsLength = rounds.length;
        if (_roundsLength > 0 && _timestamp <= rounds[_roundsLength - 1].timestamp) {
            revert CalledWithTimestampBeforePreviousRound();
        }

        if (!_isBadData && (((uint256(_priceHigh) - _priceLow) * 1e18) / _priceHigh <= maximumDeviation)) {
            lastCorrectRoundId = uint80(_roundsLength);
        }

        rounds.push(
            Round({ isBadData: _isBadData, priceLow: _priceLow, priceHigh: _priceHigh, timestamp: _timestamp })
        );
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    function _getPrices() internal view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 _roundsLength = rounds.length;
        if (_roundsLength == 0) revert NoPriceData();
        Round memory _round = rounds[_roundsLength - 1];

        _isBadData = _round.isBadData || _round.timestamp + maximumOracleDelay < block.timestamp;
        _priceLow = _round.priceLow;
        _priceHigh = _round.priceHigh;
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @return _isBadData is true when data is stale or otherwise bad
    /// @return _priceLow is the lower of the two prices
    /// @return _priceHigh is the higher of the two prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        (_isBadData, _priceLow, _priceHigh) = _getPrices();
    }

    function _getRoundData(
        uint80 _roundId
    )
        internal
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        if (rounds.length <= _roundId) revert NoPriceData();

        Round memory _round = rounds[_roundId];
        answer = int256((uint256(_round.priceHigh) + _round.priceLow) / 2);

        roundId = answeredInRound = _roundId;
        startedAt = updatedAt = _round.timestamp;
    }

    /// @notice The ```getRoundData``` function returns price data
    /// @param _roundId The round ID
    /// @return roundId The round ID
    /// @return answer The data that this specific feed provides
    /// @return startedAt Timestamp of when the round started
    /// @return updatedAt Timestamp of when the round was updated
    /// @return answeredInRound The round ID in which the answer was computed
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = _getRoundData(_roundId);
    }

    /// @notice The ```latestRoundData``` function returns price data
    /// @dev Will only return the latest data that is not bad and within the maximum price deviation
    /// @return roundId The round ID
    /// @return answer The data that this specific feed provides
    /// @return startedAt Timestamp of when the round started
    /// @return updatedAt Timestamp of when the round was updated
    /// @return answeredInRound The round ID in which the answer was computed
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = _getRoundData(lastCorrectRoundId);
    }

    // ====================================================================
    // Errors
    // ====================================================================

    error CalledWithFutureTimestamp();
    error CalledWithTimestampBeforePreviousRound();
    error NoPriceData();
    error OnlyPriceSource();
    error SameMaximumDeviation();
    error SameMaximumOracleDelay();
    error SamePriceSource();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

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

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== Timelock2Step ===========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

/// @title Timelock2Step
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @dev Inspired by the OpenZeppelin's Ownable2Step contract
/// @notice  An abstract contract which contains 2-step transfer and renounce logic for a timelock address
abstract contract Timelock2Step {
    /// @notice The pending timelock address
    address public pendingTimelockAddress;

    /// @notice The current timelock address
    address public timelockAddress;

    constructor() {
        timelockAddress = msg.sender;
    }

    /// @notice Emitted when timelock is transferred
    error OnlyTimelock();

    /// @notice Emitted when pending timelock is transferred
    error OnlyPendingTimelock();

    /// @notice The ```TimelockTransferStarted``` event is emitted when the timelock transfer is initiated
    /// @param previousTimelock The address of the previous timelock
    /// @param newTimelock The address of the new timelock
    event TimelockTransferStarted(address indexed previousTimelock, address indexed newTimelock);

    /// @notice The ```TimelockTransferred``` event is emitted when the timelock transfer is completed
    /// @param previousTimelock The address of the previous timelock
    /// @param newTimelock The address of the new timelock
    event TimelockTransferred(address indexed previousTimelock, address indexed newTimelock);

    /// @notice The ```_isSenderTimelock``` function checks if msg.sender is current timelock address
    /// @return Whether or not msg.sender is current timelock address
    function _isSenderTimelock() internal view returns (bool) {
        return msg.sender == timelockAddress;
    }

    /// @notice The ```_requireTimelock``` function reverts if msg.sender is not current timelock address
    function _requireTimelock() internal view {
        if (msg.sender != timelockAddress) revert OnlyTimelock();
    }

    /// @notice The ```_isSenderPendingTimelock``` function checks if msg.sender is pending timelock address
    /// @return Whether or not msg.sender is pending timelock address
    function _isSenderPendingTimelock() internal view returns (bool) {
        return msg.sender == pendingTimelockAddress;
    }

    /// @notice The ```_requirePendingTimelock``` function reverts if msg.sender is not pending timelock address
    function _requirePendingTimelock() internal view {
        if (msg.sender != pendingTimelockAddress) revert OnlyPendingTimelock();
    }

    /// @notice The ```_transferTimelock``` function initiates the timelock transfer
    /// @dev This function is to be implemented by a public function
    /// @param _newTimelock The address of the nominated (pending) timelock
    function _transferTimelock(address _newTimelock) internal {
        pendingTimelockAddress = _newTimelock;
        emit TimelockTransferStarted(timelockAddress, _newTimelock);
    }

    /// @notice The ```_acceptTransferTimelock``` function completes the timelock transfer
    /// @dev This function is to be implemented by a public function
    function _acceptTransferTimelock() internal {
        pendingTimelockAddress = address(0);
        _setTimelock(msg.sender);
    }

    /// @notice The ```_setTimelock``` function sets the timelock address
    /// @dev This function is to be implemented by a public function
    /// @param _newTimelock The address of the new timelock
    function _setTimelock(address _newTimelock) internal {
        emit TimelockTransferred(timelockAddress, _newTimelock);
        timelockAddress = _newTimelock;
    }

    /// @notice The ```transferTimelock``` function initiates the timelock transfer
    /// @dev Must be called by the current timelock
    /// @param _newTimelock The address of the nominated (pending) timelock
    function transferTimelock(address _newTimelock) external virtual {
        _requireTimelock();
        _transferTimelock(_newTimelock);
    }

    /// @notice The ```acceptTransferTimelock``` function completes the timelock transfer
    /// @dev Must be called by the pending timelock
    function acceptTransferTimelock() external virtual {
        _requirePendingTimelock();
        _acceptTransferTimelock();
    }

    /// @notice The ```renounceTimelock``` function renounces the timelock after setting pending timelock to current timelock
    /// @dev Pending timelock must be set to current timelock before renouncing, creating a 2-step renounce process
    function renounceTimelock() external virtual {
        _requireTimelock();
        _requirePendingTimelock();
        _transferTimelock(address(0));
        _setTimelock(address(0));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ITimelock2Step {
    event TimelockTransferStarted(address indexed previousTimelock, address indexed newTimelock);
    event TimelockTransferred(address indexed previousTimelock, address indexed newTimelock);

    function acceptTransferTimelock() external;

    function pendingTimelockAddress() external view returns (address);

    function renounceTimelock() external;

    function timelockAddress() external view returns (address);

    function transferTimelock(address _newTimelock) external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

interface IPriceSourceReceiver {
    function addRoundData(bool isBadData, uint104 priceLow, uint104 priceHigh, uint40 timestamp) external;

    function getPrices() external view returns (bool isBadData, uint256 priceLow, uint256 priceHigh);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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