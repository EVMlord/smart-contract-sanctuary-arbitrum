// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IOracleConnector.sol";

/**
 * @title OracleConnector
 * @notice Abstract contract for connecting to an oracle and retrieving price data.
 */
abstract contract OracleConnector is IOracleConnector, Ownable, Pausable {
    string public name;
    uint256 public immutable decimals;

    /**
     * @notice Retrieves the data for a specific round ID.
     * @param roundId_ The ID of the round to retrieve data for.
     * @return roundId The round ID.
     * @return answer The answer for the round.
     * @return startedAt The timestamp when the round started.
     * @return updatedAt The timestamp when the round was last updated.
     * @return answeredInRound The round ID where the answer was computed.
     */
    function getRoundData(
        uint256 roundId_
    )
        external
        view
        virtual
        returns (uint256 roundId, uint256 answer, uint256 startedAt, uint256 updatedAt, uint256 answeredInRound);

    /**
     * @notice Retrieves the ID of the latest round.
     * @return The ID of the latest round.
     */
    function latestRound() external view virtual returns (uint256);

    /**
     * @notice Retrieves the data for the latest round.
     * @return roundId The round ID.
     * @return answer The answer for the round.
     * @return startedAt The timestamp when the round started.
     * @return updatedAt The timestamp when the round was last updated.
     * @return answeredInRound The round ID where the answer was computed.
     */
    function latestRoundData()
        external
        view
        virtual
        returns (uint256 roundId, uint256 answer, uint256 startedAt, uint256 updatedAt, uint256 answeredInRound);

    /**
     * @notice Returns whether or not the contract is currently paused.
     * @return bool Returns true if the contract is paused.
     */
    function paused() public view override(Pausable, IOracleConnector) returns (bool) {
        return super.paused();
    }

    /**
     * @notice Constructor for OracleConnector.
     * @param name_ The name of the oracle.
     * @param decimals_ The number of decimal places in the price data.
     */
    constructor(string memory name_, uint256 decimals_) Ownable() Pausable() {
        name = name_;
        decimals = decimals_;
    }

    /**
     * @notice Toggles the pause state of the contract.
     * @return bool Returns true if the pause state was successfully toggled.
     */
    function togglePause() external onlyOwner returns (bool) {
        if (paused()) _unpause();
        else _pause();
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOracleConnector {
    function name() external view returns (string memory);
    function decimals() external view returns (uint256);
    function paused() external view returns (bool);
    function validateTimestamp(uint256) external view returns (bool);
    function getRoundData(
        uint256 roundId_
    )
        external
        view
        returns (uint256 roundId, uint256 answer, uint256 startedAt, uint256 updatedAt, uint256 answeredInRound);
    function latestRound() external view returns (uint256);
    function latestRoundData()
        external
        view
        returns (uint256 roundId, uint256 answer, uint256 startedAt, uint256 updatedAt, uint256 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import "../../core/connectors/OracleConnector.sol";

contract ChainlinkPriceFeed is OracleConnector {
    AggregatorV2V3Interface public immutable aggregator;

    function getRoundData(
        uint256 roundId
    ) external view override returns (uint256, uint256, uint256, uint256, uint256) {
        require(roundId <= type(uint80).max, "ChainlinkPriceFeed: Round id is invalid");
        (, int256 answer, uint256 startedAt, uint256 updatedAt, uint256 answeredInRound) = aggregator.getRoundData(
            uint80(roundId)
        );
        require(answer >= 0, "ChainlinkPriceFeed: Answer is negative");
        return (roundId, uint256(answer), startedAt, updatedAt, answeredInRound);
    }

    function latestRoundData() external view override returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint256 answeredInRound) = aggregator
            .latestRoundData();
        require(answer >= 0, "ChainlinkPriceFeed: Answer is negative");
        return (roundId, uint256(answer), startedAt, updatedAt, answeredInRound);
    }

    function latestRound() external view override returns (uint256) {
        return aggregator.latestRound();
    }

    function validateTimestamp(uint256) external pure override returns (bool) {
        return true;
    }

    constructor(
        AggregatorV2V3Interface aggregator_
    ) OracleConnector(aggregator_.description(), aggregator_.decimals()) {
        aggregator = aggregator_;
    }
}