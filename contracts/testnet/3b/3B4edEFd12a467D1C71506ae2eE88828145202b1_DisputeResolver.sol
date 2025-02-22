// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IArbitrator.sol";

/// @title IArbitrable
/// Arbitrable interface. Note that this interface follows the ERC-792 standard.
/// When developing arbitrable contracts, we need to:
/// - Define the action taken when a ruling is received by the contract.
/// - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
interface IArbitrable {
    /// @dev To be raised when a ruling is given.
    /// @param _arbitrator The arbitrator giving the ruling.
    /// @param _disputeID ID of the dispute in the Arbitrator contract.
    /// @param _ruling The ruling which was given.
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /// @dev Give a ruling for a dispute. Must be called by the arbitrator.
    /// The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
    /// @param _disputeID ID of the dispute in the Arbitrator contract.
    /// @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IArbitrable.sol";

/// @title Arbitrator
/// Arbitrator interface that implements the new arbitration standard.
/// Unlike the ERC-792 this standard doesn't have anything related to appeals, so each arbitrator can implement an appeal system that suits it the most.
/// When developing arbitrator contracts we need to:
/// - Define the functions for dispute creation (createDispute). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
/// - Define the functions for cost display (arbitrationCost).
/// - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
interface IArbitrator {
    /// @dev To be emitted when a dispute is created.
    /// @param _disputeID ID of the dispute.
    /// @param _arbitrable The contract which created the dispute.
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /// @dev To be raised when a ruling is given.
    /// @param _arbitrable The arbitrable receiving the ruling.
    /// @param _disputeID ID of the dispute in the Arbitrator contract.
    /// @param _ruling The ruling which was given.
    event Ruling(IArbitrable indexed _arbitrable, uint256 indexed _disputeID, uint256 _ruling);

    /// @dev Create a dispute. Must be called by the arbitrable contract.
    /// Must pay at least arbitrationCost(_extraData).
    /// @param _choices Amount of choices the arbitrator can make in this dispute.
    /// @param _extraData Can be used to give additional info on the dispute to be created.
    /// @return disputeID ID of the dispute created.
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /// @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
    /// @param _extraData Can be used to give additional info on the dispute to be created.
    /// @return cost Required cost of arbitration.
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@ferittuncer, @unknownunknown1]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []

import "../IArbitrable.sol";
import "../../evidence/IMetaEvidence.sol";

pragma solidity 0.8.18;

/// @title DisputeResolver
/// DisputeResolver contract adapted for V2 https://github.com/kleros/arbitrable-proxy-contracts/blob/master/contracts/ArbitrableProxy.sol.
contract DisputeResolver is IArbitrable, IMetaEvidence {
    struct DisputeStruct {
        bytes arbitratorExtraData; // Extra data for the dispute.
        bool isRuled; // True if the dispute has been ruled.
        uint256 ruling; // Ruling given to the dispute.
        uint256 numberOfRulingOptions; // The number of choices the arbitrator can give.
    }

    IArbitrator public immutable arbitrator; // Arbitrator is set in constructor and never changed.

    DisputeStruct[] public disputes; // Local disputes.
    mapping(uint256 => uint256) public externalIDtoLocalID; // Maps external (arbitrator side) dispute IDs to local dispute IDs.

    /// @dev Constructor
    /// @param _arbitrator Target global arbitrator for any disputes.
    constructor(IArbitrator _arbitrator) {
        arbitrator = _arbitrator;
    }

    /// @dev TRUSTED. Calls createDispute function of the specified arbitrator to create a dispute.
    /// Note that we don’t need to check that msg.value is enough to pay arbitration fees as it’s the responsibility of the arbitrator contract.
    /// @param _arbitratorExtraData Extra data for the arbitrator of the dispute.
    /// @param _metaevidenceURI Link to metaevidence of the dispute.
    /// @param _numberOfRulingOptions Number of ruling options.
    /// @return disputeID Dispute id (on arbitrator side) of the created dispute.
    function createDispute(
        bytes calldata _arbitratorExtraData,
        string calldata _metaevidenceURI,
        uint256 _numberOfRulingOptions
    ) external payable returns (uint256 disputeID) {
        require(_numberOfRulingOptions > 1, "Should be at least 2 ruling options.");

        disputeID = arbitrator.createDispute{value: msg.value}(_numberOfRulingOptions, _arbitratorExtraData);
        uint256 localDisputeID = disputes.length;
        disputes.push(
            DisputeStruct({
                arbitratorExtraData: _arbitratorExtraData,
                isRuled: false,
                ruling: 0,
                numberOfRulingOptions: _numberOfRulingOptions
            })
        );

        externalIDtoLocalID[disputeID] = localDisputeID;

        emit MetaEvidence(localDisputeID, _metaevidenceURI);
        emit Dispute(arbitrator, disputeID, localDisputeID, localDisputeID);
    }

    /// @dev To be called by the arbitrator of the dispute, to declare the winning ruling.
    /// @param _externalDisputeID ID of the dispute in arbitrator contract.
    /// @param _ruling The ruling choice of the arbitration.
    function rule(uint256 _externalDisputeID, uint256 _ruling) external override {
        uint256 localDisputeID = externalIDtoLocalID[_externalDisputeID];
        DisputeStruct storage dispute = disputes[localDisputeID];
        require(msg.sender == address(arbitrator), "Only the arbitrator can execute this.");
        require(_ruling <= dispute.numberOfRulingOptions, "Invalid ruling.");
        require(!dispute.isRuled, "This dispute has been ruled already.");

        dispute.isRuled = true;
        dispute.ruling = _ruling;

        emit Ruling(IArbitrator(msg.sender), _externalDisputeID, dispute.ruling);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../arbitration/IArbitrator.sol";

/// @title IMetaEvidence
/// ERC-1497: Evidence Standard excluding evidence emission as it will be handled by the arbitrator.
interface IMetaEvidence {
    /// @dev To be emitted when meta-evidence is submitted.
    /// @param _metaEvidenceID Unique identifier of meta-evidence.
    /// @param _evidence IPFS path to metaevidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/metaevidence.json'
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /// @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
    /// @param _arbitrator The arbitrator of the contract.
    /// @param _disputeID ID of the dispute in the Arbitrator contract.
    /// @param _metaEvidenceID Unique identifier of meta-evidence.
    /// @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
    event Dispute(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}