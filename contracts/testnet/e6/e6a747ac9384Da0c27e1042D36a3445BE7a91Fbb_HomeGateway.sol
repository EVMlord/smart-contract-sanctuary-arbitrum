// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface. Note that this interface follows the ERC-792 standard.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator interface that implements the new arbitration standard.
 * Unlike the ERC-792 this standard doesn't have anything related to appeals, so each arbitrator can implement an appeal system that suits it the most.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must pay at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Required cost of arbitration.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shalzz, @hrishibhat, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

interface IFastBridgeReceiver {
    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /**
     * @dev The Fast Bridge participants watch for these events to decide if a challenge should be submitted.
     * @param _epoch The epoch for which the the claim was made.
     * @param _batchMerkleRoot The timestamp of the claim creation.
     */
    event ClaimReceived(uint256 _epoch, bytes32 indexed _batchMerkleRoot);

    /**
     * @dev The Fast Bridge participants watch for these events to call `sendSafeFallback()` on the sending side.
     * @param _epoch The epoch associated with the challenged claim.
     */
    event ClaimChallenged(uint256 _epoch);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * @dev Submit a claim about the `_batchMerkleRoot` for the latests completed Fast bridge epoch and submit a deposit. The `_batchMerkleRoot` should match the one on the sending side otherwise the sender will lose his deposit.
     * @param _epoch The epoch of the claim to claim.
     * @param _batchMerkleRoot The hash claimed for the ticket.
     */
    function claim(uint256 _epoch, bytes32 _batchMerkleRoot) external payable;

    /**
     * @dev Submit a challenge for the claim of the current epoch's Fast Bridge batch merkleroot state and submit a deposit. The `batchMerkleRoot` in the claim already made for the last finalized epoch should be different from the one on the sending side, otherwise the sender will lose his deposit.
     * @param _epoch The epoch of the claim to challenge.
     */
    function challenge(uint256 _epoch) external payable;

    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the most recent possible epoch and relays the message.
     * @param _epoch The epoch in which the message was batched by the bridge.
     * @param _proof The merkle proof to prove the membership of the message and nonce in the merkle tree for the epoch.
     * @param _message The data on the cross-domain chain for the message.
     */
    function verifyAndRelay(
        uint256 _epoch,
        bytes32[] calldata _proof,
        bytes calldata _message
    ) external;

    /**
     * @dev Sends the deposit back to the Bridger if their claim is not successfully challenged. Includes a portion of the Challenger's deposit if unsuccessfully challenged.
     * @param _epoch The epoch associated with the claim deposit to withraw.
     */
    function withdrawClaimDeposit(uint256 _epoch) external;

    /**
     * @dev Sends the deposit back to the Challenger if his challenge is successful. Includes a portion of the Bridger's deposit.
     * @param _epoch The epoch associated with the challenge deposit to withraw.
     */
    function withdrawChallengeDeposit(uint256 _epoch) external;

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /**
     * @dev Returns the `start` and `end` time of challenge period for this `epoch`.
     * @param _epoch The epoch of the claim to request the challenge period.
     * @return start The start time of the challenge period.
     * @return end The end time of the challenge period.
     */
    function claimChallengePeriod(uint256 _epoch) external view returns (uint256 start, uint256 end);

    /**
     * @dev Returns the epoch period.
     */
    function epochPeriod() external view returns (uint256 epochPeriod);

    /**
     * @dev Returns the challenge period.
     */
    function challengePeriod() external view returns (uint256 challengePeriod);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFastBridgeSender {
    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /**
     * @dev The Fast Bridge participants need to watch for these events and relay the messageHash on the FastBridgeReceiverOnEthereum.
     * @param fastMessage The fast message data.
     * @param fastMessage The hash of the fast message data encoded with the nonce.
     */
    event MessageReceived(bytes fastMessage, bytes32 fastMessageHash);

    /**
     * @dev The event is emitted when messages are sent through the canonical bridge.
     * @param epoch The epoch of the batch requested to send.
     * @param canonicalBridgeMessageID The unique identifier of the safe message returned by the canonical bridge.
     */
    event SentSafe(uint256 indexed epoch, bytes32 canonicalBridgeMessageID);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * Note: Access must be restricted by the receiving contract.
     * Message is sent with the message sender address as the first argument.
     * @dev Sends an arbitrary message across domain using the Fast Bridge.
     * @param _receiver The cross-domain contract address which receives the calldata.
     * @param _calldata The receiving domain encoded message data.
     */
    function sendFast(address _receiver, bytes memory _calldata) external;

    /**
     * Sends a batch of arbitrary message from one domain to another
     * via the fast bridge mechanism.
     */
    function sendBatch() external;

    /**
     * @dev Sends a markle root representing an arbitrary batch of messages across domain using the Safe Bridge, which relies on the chain's canonical bridge. It is unnecessary during normal operations but essential only in case of challenge.
     * @param _epoch block number of batch
     */
    function sendSafeFallback(uint256 _epoch) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../arbitration/IArbitrator.sol";

/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {
    /**
     * @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     * @param _arbitrator The arbitrator of the contract.
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     * @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     * @param _evidence IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    event Evidence(
        IArbitrator indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../arbitration/IArbitrator.sol";
import "./IEvidence.sol";

/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IMetaEvidence is IEvidence {
    /**
     * @dev To be emitted when meta-evidence is submitted.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidence IPFS path to metaevidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/metaevidence.json'
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /**
     * @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
     * @param _arbitrator The arbitrator of the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shalzz, @jaybuidl]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "../arbitration/IArbitrator.sol";
import "../bridge/interfaces/IFastBridgeSender.sol";
import "./interfaces/IForeignGateway.sol";
import "./interfaces/IHomeGateway.sol";

/**
 * Home Gateway
 * Counterpart of `ForeignGateway`
 */
contract HomeGateway is IHomeGateway {
    mapping(uint256 => bytes32) public disputeIDtoHash;
    mapping(bytes32 => uint256) public disputeHashtoID;

    address public governor;
    IArbitrator public immutable arbitrator;
    IFastBridgeSender public fastbridge;
    address public override foreignGateway;
    uint256 public immutable override chainID;
    uint256 public immutable override foreignChainID;

    struct RelayedData {
        uint256 arbitrationCost;
        address relayer;
    }
    mapping(bytes32 => RelayedData) public disputeHashtoRelayedData;

    constructor(
        address _governor,
        IArbitrator _arbitrator,
        IFastBridgeSender _fastbridge,
        address _foreignGateway,
        uint256 _foreignChainID
    ) {
        governor = _governor;
        arbitrator = _arbitrator;
        fastbridge = _fastbridge;
        foreignGateway = _foreignGateway;
        foreignChainID = _foreignChainID;
        uint256 id;
        assembly {
            id := chainid()
        }
        chainID = id;

        emit MetaEvidence(0, "BRIDGE");
    }

    /**
     * @dev Provide the same parameters as on the originalChain while creating a
     *      dispute. Providing incorrect parameters will create a different hash
     *      than on the originalChain and will not affect the actual dispute/arbitrable's
     *      ruling.
     *
     * @param _originalChainID originalChainId
     * @param _originalBlockHash originalBlockHash
     * @param _originalDisputeID originalDisputeID
     * @param _choices number of ruling choices
     * @param _extraData extraData
     * @param _arbitrable arbitrable
     */
    function relayCreateDispute(
        uint256 _originalChainID,
        bytes32 _originalBlockHash,
        uint256 _originalDisputeID,
        uint256 _choices,
        bytes calldata _extraData,
        address _arbitrable
    ) external payable override {
        bytes32 disputeHash = keccak256(
            abi.encodePacked(
                _originalChainID,
                _originalBlockHash,
                "createDispute",
                _originalDisputeID,
                _choices,
                _extraData,
                _arbitrable
            )
        );
        RelayedData storage relayedData = disputeHashtoRelayedData[disputeHash];
        require(relayedData.relayer == address(0), "Dispute already relayed");

        // TODO: will mostly be replaced by the actual arbitrationCost paid on the foreignChain.
        relayedData.arbitrationCost = arbitrator.arbitrationCost(_extraData);
        require(msg.value >= relayedData.arbitrationCost, "Not enough arbitration cost paid");

        uint256 disputeID = arbitrator.createDispute{value: msg.value}(_choices, _extraData);
        disputeIDtoHash[disputeID] = disputeHash;
        disputeHashtoID[disputeHash] = disputeID;
        relayedData.relayer = msg.sender;

        emit Dispute(arbitrator, disputeID, 0, 0);
    }

    function rule(uint256 _disputeID, uint256 _ruling) external override {
        require(msg.sender == address(arbitrator), "Only Arbitrator");

        bytes32 disputeHash = disputeIDtoHash[_disputeID];
        RelayedData memory relayedData = disputeHashtoRelayedData[disputeHash];

        bytes4 methodSelector = IForeignGateway.relayRule.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, disputeHash, _ruling, relayedData.relayer);

        fastbridge.sendFast(foreignGateway, data);
    }

    /** @dev Changes the fastBridge, useful to increase the claim deposit.
     *  @param _fastbridge The address of the new fastBridge.
     */
    function changeFastbridge(IFastBridgeSender _fastbridge) external {
        require(governor == msg.sender, "Access not allowed: Governor only.");
        fastbridge = _fastbridge;
    }

    function disputeHashToHomeID(bytes32 _disputeHash) external view override returns (uint256) {
        return disputeHashtoID[_disputeHash];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../arbitration/IArbitrator.sol";
import "./IForeignGatewayBase.sol";

interface IForeignGateway is IArbitrator, IForeignGatewayBase {
    /**
     * Relay the rule call from the home gateway to the arbitrable.
     */
    function relayRule(
        address _messageSender,
        bytes32 _disputeHash,
        uint256 _ruling,
        address _forwarder
    ) external;

    function withdrawFees(bytes32 _disputeHash) external;

    // For cross-chain Evidence standard
    function disputeHashToForeignID(bytes32 _disputeHash) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../bridge/interfaces/IFastBridgeReceiver.sol";

interface IForeignGatewayBase {
    function fastbridge() external view returns (IFastBridgeReceiver);

    function chainID() external view returns (uint256);

    function homeChainID() external view returns (uint256);

    function homeGateway() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../arbitration/IArbitrable.sol";
import "../../evidence/IMetaEvidence.sol";
import "./IHomeGatewayBase.sol";

interface IHomeGateway is IArbitrable, IMetaEvidence, IHomeGatewayBase {
    function relayCreateDispute(
        uint256 _originalChainID,
        bytes32 _originalBlockHash,
        uint256 _originalDisputeID,
        uint256 _choices,
        bytes calldata _extraData,
        address _arbitrable
    ) external payable;

    // For cross-chain Evidence standard
    function disputeHashToHomeID(bytes32 _disputeHash) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../bridge/interfaces/IFastBridgeSender.sol";

interface IHomeGatewayBase {
    function fastbridge() external view returns (IFastBridgeSender);

    function chainID() external view returns (uint256);

    function foreignChainID() external view returns (uint256);

    function foreignGateway() external view returns (address);
}