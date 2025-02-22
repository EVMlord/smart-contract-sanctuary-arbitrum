// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITellor {
	//Controller
	function addresses(bytes32) external view returns (address);

	function uints(bytes32) external view returns (uint256);

	function burn(uint256 _amount) external;

	function changeDeity(address _newDeity) external;

	function changeOwner(address _newOwner) external;

	function changeUint(bytes32 _target, uint256 _amount) external;

	function migrate() external;

	function mint(address _reciever, uint256 _amount) external;

	function init() external;

	function getAllDisputeVars(
		uint256 _disputeId
	)
		external
		view
		returns (bytes32, bool, bool, bool, address, address, address, uint256[9] memory, int256);

	function getDisputeIdByDisputeHash(bytes32 _hash) external view returns (uint256);

	function getDisputeUintVars(
		uint256 _disputeId,
		bytes32 _data
	) external view returns (uint256);

	function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool);

	function retrieveData(
		uint256 _requestId,
		uint256 _timestamp
	) external view returns (uint256);

	function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256);

	function getAddressVars(bytes32 _data) external view returns (address);

	function getUintVar(bytes32 _data) external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function isMigrated(address _addy) external view returns (bool);

	function allowance(address _user, address _spender) external view returns (uint256);

	function allowedToTrade(address _user, uint256 _amount) external view returns (bool);

	function approve(address _spender, uint256 _amount) external returns (bool);

	function approveAndTransferFrom(
		address _from,
		address _to,
		uint256 _amount
	) external returns (bool);

	function balanceOf(address _user) external view returns (uint256);

	function balanceOfAt(address _user, uint256 _blockNumber) external view returns (uint256);

	function transfer(address _to, uint256 _amount) external returns (bool success);

	function transferFrom(
		address _from,
		address _to,
		uint256 _amount
	) external returns (bool success);

	function depositStake() external;

	function requestStakingWithdraw() external;

	function withdrawStake() external;

	function changeStakingStatus(address _reporter, uint256 _status) external;

	function slashReporter(address _reporter, address _disputer) external;

	function getStakerInfo(address _staker) external view returns (uint256, uint256);

	function getTimestampbyRequestIDandIndex(
		uint256 _requestId,
		uint256 _index
	) external view returns (uint256);

	function getNewCurrentVariables()
		external
		view
		returns (bytes32 _c, uint256[5] memory _r, uint256 _d, uint256 _t);

	function getNewValueCountbyQueryId(bytes32 _queryId) external view returns (uint256);

	function getTimestampbyQueryIdandIndex(
		bytes32 _queryId,
		uint256 _index
	) external view returns (uint256);

	function retrieveData(
		bytes32 _queryId,
		uint256 _timestamp
	) external view returns (bytes memory);

	//Governance
	enum VoteResult {
		FAILED,
		PASSED,
		INVALID
	}

	function setApprovedFunction(bytes4 _func, bool _val) external;

	function beginDispute(bytes32 _queryId, uint256 _timestamp) external;

	function delegate(address _delegate) external;

	function delegateOfAt(address _user, uint256 _blockNumber) external view returns (address);

	function executeVote(uint256 _disputeId) external;

	function proposeVote(
		address _contract,
		bytes4 _function,
		bytes calldata _data,
		uint256 _timestamp
	) external;

	function tallyVotes(uint256 _disputeId) external;

	function governance() external view returns (address);

	function updateMinDisputeFee() external;

	function verify() external pure returns (uint256);

	function vote(uint256 _disputeId, bool _supports, bool _invalidQuery) external;

	function voteFor(
		address[] calldata _addys,
		uint256 _disputeId,
		bool _supports,
		bool _invalidQuery
	) external;

	function getDelegateInfo(address _holder) external view returns (address, uint256);

	function isFunctionApproved(bytes4 _func) external view returns (bool);

	function isApprovedGovernanceContract(address _contract) external returns (bool);

	function getVoteRounds(bytes32 _hash) external view returns (uint256[] memory);

	function getVoteCount() external view returns (uint256);

	function getVoteInfo(
		uint256 _disputeId
	)
		external
		view
		returns (
			bytes32,
			uint256[9] memory,
			bool[2] memory,
			VoteResult,
			bytes memory,
			bytes4,
			address[2] memory
		);

	function getDisputeInfo(
		uint256 _disputeId
	) external view returns (uint256, uint256, bytes memory, address);

	function getOpenDisputesOnId(bytes32 _queryId) external view returns (uint256);

	function didVote(uint256 _disputeId, address _voter) external view returns (bool);

	//Oracle
	function getReportTimestampByIndex(
		bytes32 _queryId,
		uint256 _index
	) external view returns (uint256);

	function getValueByTimestamp(
		bytes32 _queryId,
		uint256 _timestamp
	) external view returns (bytes memory);

	function getBlockNumberByTimestamp(
		bytes32 _queryId,
		uint256 _timestamp
	) external view returns (uint256);

	function getReportingLock() external view returns (uint256);

	function getReporterByTimestamp(
		bytes32 _queryId,
		uint256 _timestamp
	) external view returns (address);

	function reportingLock() external view returns (uint256);

	function removeValue(bytes32 _queryId, uint256 _timestamp) external;

	function getTipsByUser(address _user) external view returns (uint256);

	function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;

	function submitValue(
		bytes32 _queryId,
		bytes calldata _value,
		uint256 _nonce,
		bytes memory _queryData
	) external;

	function burnTips() external;

	function changeReportingLock(uint256 _newReportingLock) external;

	function getReportsSubmittedByAddress(address _reporter) external view returns (uint256);

	function changeTimeBasedReward(uint256 _newTimeBasedReward) external;

	function getReporterLastTimestamp(address _reporter) external view returns (uint256);

	function getTipsById(bytes32 _queryId) external view returns (uint256);

	function getTimeBasedReward() external view returns (uint256);

	function getTimestampCountById(bytes32 _queryId) external view returns (uint256);

	function getTimestampIndexByTimestamp(
		bytes32 _queryId,
		uint256 _timestamp
	) external view returns (uint256);

	function getCurrentReward(bytes32 _queryId) external view returns (uint256, uint256);

	function getCurrentValue(bytes32 _queryId) external view returns (bytes memory);

	function getDataBefore(
		bytes32 _queryId,
		uint256 _timestamp
	) external view returns (bool _ifRetrieve, bytes memory _value, uint256 _timestampRetrieved);

	function getTimeOfLastNewValue() external view returns (uint256);

	function depositStake(uint256 _amount) external;

	function requestStakingWithdraw(uint256 _amount) external;

	//Test functions
	function changeAddressVar(bytes32 _id, address _addy) external;

	//parachute functions
	function killContract() external;

	function migrateFor(address _destination, uint256 _amount) external;

	function rescue51PercentAttack(address _tokenHolder) external;

	function rescueBrokenDataReporting() external;

	function rescueFailedUpdate() external;

	//Tellor 360
	function addStakingRewards(uint256 _amount) external;

	function _sliceUint(bytes memory _b) external pure returns (uint256 _number);

	function claimOneTimeTip(bytes32 _queryId, uint256[] memory _timestamps) external;

	function claimTip(bytes32 _feedId, bytes32 _queryId, uint256[] memory _timestamps) external;

	function fee() external view returns (uint256);

	function feedsWithFunding(uint256) external view returns (bytes32);

	function fundFeed(bytes32 _feedId, bytes32 _queryId, uint256 _amount) external;

	function getCurrentFeeds(bytes32 _queryId) external view returns (bytes32[] memory);

	function getCurrentTip(bytes32 _queryId) external view returns (uint256);

	function getDataAfter(
		bytes32 _queryId,
		uint256 _timestamp
	) external view returns (bytes memory _value, uint256 _timestampRetrieved);

	function getDataFeed(bytes32 _feedId) external view returns (Autopay.FeedDetails memory);

	function getFundedFeeds() external view returns (bytes32[] memory);

	function getFundedQueryIds() external view returns (bytes32[] memory);

	function getIndexForDataAfter(
		bytes32 _queryId,
		uint256 _timestamp
	) external view returns (bool _found, uint256 _index);

	function getIndexForDataBefore(
		bytes32 _queryId,
		uint256 _timestamp
	) external view returns (bool _found, uint256 _index);

	function getMultipleValuesBefore(
		bytes32 _queryId,
		uint256 _timestamp,
		uint256 _maxAge,
		uint256 _maxCount
	) external view returns (uint256[] memory _values, uint256[] memory _timestamps);

	function getPastTipByIndex(
		bytes32 _queryId,
		uint256 _index
	) external view returns (Autopay.Tip memory);

	function getPastTipCount(bytes32 _queryId) external view returns (uint256);

	function getPastTips(bytes32 _queryId) external view returns (Autopay.Tip[] memory);

	function getQueryIdFromFeedId(bytes32 _feedId) external view returns (bytes32);

	function getRewardAmount(
		bytes32 _feedId,
		bytes32 _queryId,
		uint256[] memory _timestamps
	) external view returns (uint256 _cumulativeReward);

	function getRewardClaimedStatus(
		bytes32 _feedId,
		bytes32 _queryId,
		uint256 _timestamp
	) external view returns (bool);

	function getTipsByAddress(address _user) external view returns (uint256);

	function isInDispute(bytes32 _queryId, uint256 _timestamp) external view returns (bool);

	function queryIdFromDataFeedId(bytes32) external view returns (bytes32);

	function queryIdsWithFunding(uint256) external view returns (bytes32);

	function queryIdsWithFundingIndex(bytes32) external view returns (uint256);

	function setupDataFeed(
		bytes32 _queryId,
		uint256 _reward,
		uint256 _startTime,
		uint256 _interval,
		uint256 _window,
		uint256 _priceThreshold,
		uint256 _rewardIncreasePerSecond,
		bytes memory _queryData,
		uint256 _amount
	) external;

	function tellor() external view returns (address);

	function tip(bytes32 _queryId, uint256 _amount, bytes memory _queryData) external;

	function tips(bytes32, uint256) external view returns (uint256 amount, uint256 timestamp);

	function token() external view returns (address);

	function userTipsTotal(address) external view returns (uint256);

	function valueFor(
		bytes32 _id
	) external view returns (int256 _value, uint256 _timestamp, uint256 _statusCode);
}

interface Autopay {
	struct FeedDetails {
		uint256 reward;
		uint256 balance;
		uint256 startTime;
		uint256 interval;
		uint256 window;
		uint256 priceThreshold;
		uint256 rewardIncreasePerSecond;
		uint256 feedsWithFundingIndex;
	}

	struct Tip {
		uint256 amount;
		uint256 timestamp;
	}

	function getStakeAmount() external view returns (uint256);

	function stakeAmount() external view returns (uint256);

	function token() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "../Interfaces/ITellorCaller.sol";
import "./ITellor.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/*
 * This contract has a single external function that calls Tellor: getTellorCurrentValue().
 *
 * The function is called by the Vesta contract PriceFeed.sol. If any of its inner calls to Tellor revert,
 * this function will revert, and PriceFeed will catch the failure and handle it accordingly.
 *
 * The function comes from Tellor's own wrapper contract, 'UsingTellor.sol':
 * https://github.com/tellor-io/usingtellor/blob/master/contracts/UsingTellor.sol
 *
 */
contract TellorCaller is ITellorCaller {
	using SafeMathUpgradeable for uint256;

	ITellor public tellor;

	constructor(address _tellorMasterAddress) {
		tellor = ITellor(_tellorMasterAddress);
	}

	// Internal functions
	/**
	 * @dev Convert bytes to uint256
	 * @param _b bytes value to convert to uint256
	 * @return _number uint256 converted from bytes
	 */
	function _sliceUint(bytes memory _b) internal pure returns (uint256 _number) {
		for (uint256 _i = 0; _i < _b.length; _i++) {
			_number = _number * 256 + uint8(_b[_i]);
		}
	}

	/*
	 * getTellorCurrentValue(): identical to getCurrentValue() in UsingTellor.sol
	 *
	 * @dev Allows the user to get the latest value for the requestId specified
	 * @param _queryId is the requestId to look up the value for
	 * @return ifRetrieve bool true if it is able to retrieve a value, the value, and the value's timestamp
	 * @return value the value retrieved
	 * @return _timestampRetrieved the value's timestamp
	 */
	function getTellorCurrentValue(
		bytes32 _queryId
	)
		external
		view
		override
		returns (bool ifRetrieve, uint256 value, uint256 _timestampRetrieved)
	{
		uint256 _count = tellor.getNewValueCountbyQueryId(_queryId);
		uint256 _time = tellor.getTimestampbyQueryIdandIndex(_queryId, _count.sub(1));
		bytes memory _valuesBytes = tellor.retrieveData(_queryId, _time);
		uint256 _value = _sliceUint(_valuesBytes);
		if (_value > 0) return (true, _value, _time);
		return (false, 0, _time);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ITellorCaller {
	function getTellorCurrentValue(
		bytes32 _queryId
	) external view returns (bool, uint256, uint256);
}