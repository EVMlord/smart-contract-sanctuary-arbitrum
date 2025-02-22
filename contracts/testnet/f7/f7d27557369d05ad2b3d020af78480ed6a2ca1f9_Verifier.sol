// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {ConfirmedOwner} from "chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {IVerifier} from "./interfaces/IVerifier.sol";
import {IVerifierProxy} from "./interfaces/IVerifierProxy.sol";
import {TypeAndVersionInterface} from "chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";
import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";

// OCR2 standard
uint256 constant MAX_NUM_ORACLES = 31;

/*
 * The verifier contract is used to verify offchain reports signed
 * by DONs.  A report consists of a price, block number and feed Id.  It
 * represents the observed price of an asset at a specified block number for
 * a feed.  The verifier contract is used to verify that such reports have
 * been signed by the correct signers.
 **/
contract Verifier is IVerifier, ConfirmedOwner, TypeAndVersionInterface {
    // The first byte of the mask can be 0, because we only ever have 31 oracles
    uint256 internal constant ORACLE_MASK =
        0x0001010101010101010101010101010101010101010101010101010101010101;

    enum Role {
        // Default role for an oracle address.  This means that the oracle address
        // is not a signer
        Unset,
        // Role given to an oracle address that is allowed to sign feed data
        Signer
    }

    struct Signer {
        // Index of oracle in a configuration
        uint8 index;
        // The oracle's role
        Role role;
    }

    struct Config {
        // Fault tolerance
        uint8 f;
        // Map of signer addresses to oracles
        mapping(address => Signer) oracles;
        // Marks whether or not a configuration is active
        bool isActive;
    }

    struct VerifierState {
        // The number of times a new configuration
        /// has been set
        uint32 configCount;
        // The block number of the block the last time
        /// the configuration was updated.
        uint32 latestConfigBlockNumber;
        // The latest epoch a report was verified for
        uint32 latestEpoch;
        /// The latest config digest set
        bytes32 latestConfigDigest;
        // Whether or not the verifier for this feed has been deactivated
        bool isDeactivated;
        /// The historical record of all previously set configs by feedId
        mapping(bytes32 => Config) s_verificationDataConfigs;
    }

    /// @notice This event is emitted when a new report is verified.
    /// It is used to keep a historical record of verified reports.
    event ReportVerified(bytes32 indexed feedId, bytes32 reportHash, address requester);

    /// @notice This event is emitted whenever a new configuration is set for a feed.  It triggers a new run of the offchain reporting protocol.
    event ConfigSet(
        bytes32 indexed feedId,
        uint32 previousConfigBlockNumber,
        bytes32 configDigest,
        uint64 configCount,
        address[] signers,
        bytes32[] offchainTransmitters,
        uint8 f,
        bytes onchainConfig,
        uint64 offchainConfigVersion,
        bytes offchainConfig
    );

    /// @notice This event is emitted whenever a configuration is deactivated
    event ConfigDeactivated(bytes32 indexed feedId, bytes32 configDigest);

    /// @notice This event is emitted whenever a configuration is activated
    event ConfigActivated(bytes32 indexed feedId, bytes32 configDigest);

    /// @notice This event is emitted whenever a feed is activated
    event FeedActivated(bytes32 indexed feedId);

    /// @notice This event is emitted whenever a feed is deactivated
    event FeedDeactivated(bytes32 indexed feedId);

    /// @notice This error is thrown whenever an address tries
    /// to exeecute a transaction that it is not authorized to do so
    error AccessForbidden();

    /// @notice This error is thrown whenever a zero address is passed
    error ZeroAddress();

    /// @notice This error is thrown whenever the feed ID passed in
    /// a signed report is empty
    error FeedIdEmpty();

    /// @notice This error is thrown whenever the config digest
    /// is empty
    error DigestEmpty();

    /// @notice This error is thrown whenever the config digest
    /// passed in has not been set in this verifier
    /// @param feedId The feed ID in the signed report
    /// @param configDigest The config digest that has not been set
    error DigestNotSet(bytes32 feedId, bytes32 configDigest);

    /// @notice This error is thrown whenever the config digest
    /// has been deactivated
    /// @param feedId The feed ID in the signed report
    /// @param configDigest The config digest that is inactive
    error DigestInactive(bytes32 feedId, bytes32 configDigest);

    /// @notice This error is thrown whenever trying to set a config
    /// with a fault tolerance of 0
    error FaultToleranceMustBePositive();

    /// @notice This error is thrown whenever a report is signed
    /// with more than the max number of signers
    /// @param numSigners The number of signers who have signed the report
    /// @param maxSigners The maximum number of signers that can sign a report
    error ExcessSigners(uint256 numSigners, uint256 maxSigners);

    /// @notice This error is thrown whenever a report is signed
    /// with less than the minimum number of signers
    /// @param numSigners The number of signers who have signed the report
    /// @param minSigners The minimum number of signers that need to sign a report
    error InsufficientSigners(uint256 numSigners, uint256 minSigners);

    /// @notice This error is thrown whenever a report is signed
    /// with an incorrect number of signers
    /// @param numSigners The number of signers who have signed the report
    /// @param expectedNumSigners The expected number of signers that need to sign
    /// a report
    error IncorrectSignatureCount(
        uint256 numSigners,
        uint256 expectedNumSigners
    );

    /// @notice This error is thrown whenever the R and S signer components
    /// have different lengths
    /// @param rsLength The number of r signature components
    /// @param ssLength The number of s signature components
    error MismatchedSignatures(uint256 rsLength, uint256 ssLength);

    /// @notice This error is thrown whenever a report has a duplicate
    /// signature
    error NonUniqueSignatures();

    /// @notice This error is thrown whenever the admin tries to deactivate
    /// the latest config digest
    /// @param feedId The feed ID in the signed report
    /// @param configDigest The latest config digest
    error CannotDeactivateLatestConfig(bytes32 feedId, bytes32 configDigest);

    /// @notice This error is thrown whenever the feed ID passed in is deactivated
    /// @param feedId The feed ID
    error InactiveFeed(bytes32 feedId);

    /// @notice This error is thrown whenever the feed ID passed in is not found
    /// @param feedId The feed ID
    error InvalidFeed(bytes32 feedId);

    /// @notice The address of the verifier proxy
    address private immutable i_verifierProxyAddr;

    /// @notice Verifier states keyed on Feed ID
    mapping(bytes32 => VerifierState) s_feedVerifierStates;

    /// @param verifierProxyAddr The address of the VerifierProxy contract
    constructor(address verifierProxyAddr)
        ConfirmedOwner(msg.sender)
    {
        if (verifierProxyAddr == address(0)) revert ZeroAddress();
        i_verifierProxyAddr = verifierProxyAddr;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool isVerifier)
    {
        return interfaceId == this.verify.selector;
    }

    /// @inheritdoc TypeAndVersionInterface
    function typeAndVersion() external pure override returns (string memory) {
        return "Verifier 0.0.2";
    }

    /// @inheritdoc IVerifier
    function verify(bytes calldata signedReport, address sender)
        external
        override
        returns (bytes memory response)
    {
        if (msg.sender != i_verifierProxyAddr) revert AccessForbidden();
        (
            bytes32[3] memory reportContext,
            bytes memory reportData,
            bytes32[] memory rs,
            bytes32[] memory ss,
            bytes32 rawVs
        ) = abi.decode(
                signedReport,
                (bytes32[3], bytes, bytes32[], bytes32[], bytes32)
            );

        // The feed ID is the first 32 bytes of the report data.
        bytes32 feedId = bytes32(reportData);

        VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

        // If the feed has been deactivated, do not verify the report
        if(feedVerifierState.isDeactivated) {
            revert InactiveFeed(feedId);
        }

        // reportContext consists of:
        // reportContext[0]: ConfigDigest
        // reportContext[1]: 27 byte padding, 4-byte epoch and 1-byte round
        // reportContext[2]: ExtraHash
        bytes32 configDigest = reportContext[0];
        Config storage s_config = feedVerifierState.s_verificationDataConfigs[configDigest];

        _validateReport(feedId, configDigest, rs, ss, s_config);
        _updateEpoch(reportContext, feedVerifierState);

        bytes32 hashedReport = keccak256(reportData);

        _verifySignatures(hashedReport, reportContext, rs, ss, rawVs, s_config);
        emit ReportVerified(feedId, hashedReport, sender);
        return reportData;
    }

    /**
     * @notice Validates parameters of the report
     * @param feedId Feed ID from the report
     * @param configDigest Config digest from the report
     * @param rs R components from the report
     * @param ss S components from the report
     * @param config Config for the given feed ID keyed on the config digest
    */
    function _validateReport(
        bytes32 feedId,
        bytes32 configDigest,
        bytes32[] memory rs,
        bytes32[] memory ss,
        Config storage config
    ) private view {
            uint8 expectedNumSignatures = config.f + 1;

            if (config.f == 0) // Is digest configured?
                revert DigestNotSet(feedId, configDigest);
            if (!config.isActive) revert DigestInactive(feedId, configDigest);
            if (rs.length != expectedNumSignatures)
                revert IncorrectSignatureCount(
                    rs.length,
                    expectedNumSignatures
                );
            if (rs.length != ss.length)
                revert MismatchedSignatures(rs.length, ss.length);
        }

    /**
     * @notice Conditionally update the epoch for a feed
     * @param reportContext Report context containing the epoch and round
     * @param feedVerifierState Feed verifier state to conditionally update
     */
    function _updateEpoch(
        bytes32[3] memory reportContext,
        VerifierState storage feedVerifierState
    ) private {
        uint40 epochAndRound = uint40(uint256(reportContext[1]));
        uint32 epoch = uint32(epochAndRound >> 8);
        if (epoch > feedVerifierState.latestEpoch) {
            feedVerifierState.latestEpoch = epoch;
        }
    }

    /**
     * @notice Verifies that a report has been signed by the correct
     * signers and that enough signers have signed the reports.
     * @param hashedReport The keccak256 hash of the raw report's bytes
     * @param reportContext The context the report was signed in
     * @param rs ith element is the R components of the ith signature on report. Must have at most MAX_NUM_ORACLES entries
     * @param ss ith element is the S components of the ith signature on report. Must have at most MAX_NUM_ORACLES entries
     * @param rawVs ith element is the the V component of the ith signature
     * @param s_config The config digest the report was signed for
     **/
    function _verifySignatures(
        bytes32 hashedReport,
        bytes32[3] memory reportContext,
        bytes32[] memory rs,
        bytes32[] memory ss,
        bytes32 rawVs,
        Config storage s_config
    ) private view {
        bytes32 h = keccak256(abi.encodePacked(hashedReport, reportContext));
        // i-th byte counts number of sigs made by i-th signer
        uint256 signedCount;

        Signer memory o;
        address signerAddress;
        uint256 numSigners = rs.length;
        for (uint256 i; i < numSigners; ++i) {
            signerAddress = ecrecover(h, uint8(rawVs[i]) + 27, rs[i], ss[i]);
            o = s_config.oracles[signerAddress];
            if (o.role != Role.Signer) revert AccessForbidden();
            unchecked {
                signedCount += 1 << (8 * o.index);
            }
        }

        if (signedCount & ORACLE_MASK != signedCount)
            revert NonUniqueSignatures();
    }

    /**
     * @notice Generates the config digest from config data
     * @param configCount ordinal number of this config setting among all config settings over the life of this contract
     * @param signers ith element is address ith oracle uses to sign a report
     * @param offchainTransmitters ith element is address ith oracle used to transmit reports (in this case used for flexible additional field, such as CSA pub keys)
     * @param f maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version of the serialization format used for "offchainConfig" parameter
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     * @dev This function is a modified version of the method from OCR2Abstract
     */
    function _configDigestFromConfigData(
        bytes32 feedId,
        uint64 configCount,
        address[] memory signers,
        bytes32[] memory offchainTransmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig
    ) internal view returns (bytes32) {
        uint256 h = uint256(
            keccak256(
                abi.encode(
                    feedId,
                    block.chainid, // chainId
                    address(this), // contractAddress
                    configCount,
                    signers,
                    offchainTransmitters,
                    f,
                    onchainConfig,
                    offchainConfigVersion,
                    offchainConfig
                )
            )
        );
        uint256 prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
        uint256 prefix = 0x0001 << (256 - 16); // 0x000100..00
        return bytes32((prefix & prefixMask) | (h & ~prefixMask));
    }

    /**
     * @notice Deactivates the configuration for a config digest
     * @param feedId Feed ID to deactivate config for
     * @param configDigest The config digest to deactivate
     * @dev This function can be called by the contract admin to deactivate
     * an incorrect configuration.
     */
    function deactivateConfig(bytes32 feedId, bytes32 configDigest) external onlyOwner {
        VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

        if (configDigest == bytes32("")) revert DigestEmpty();
        if (feedVerifierState.s_verificationDataConfigs[configDigest].f == 0)
            revert DigestNotSet(feedId, configDigest);
        if (configDigest == feedVerifierState.latestConfigDigest)
            revert CannotDeactivateLatestConfig(feedId, configDigest);
        feedVerifierState.s_verificationDataConfigs[configDigest].isActive = false;
        emit ConfigDeactivated(feedId, configDigest);
    }

    /**
     * @notice Activates the configuration for a config digest
     * @param feedId Feed ID to activate config for
     * @param configDigest The config digest to activate
     * @dev This function can be called by the contract admin to activate
     * a configuration.
     */
    function activateConfig(bytes32 feedId, bytes32 configDigest) external onlyOwner {
        VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

        if (configDigest == bytes32("")) revert DigestEmpty();
        if (feedVerifierState.s_verificationDataConfigs[configDigest].f == 0)
            revert DigestNotSet(feedId, configDigest);
        feedVerifierState.s_verificationDataConfigs[configDigest].isActive = true;
        emit ConfigActivated(feedId, configDigest);
    }

    /**
     * @notice Activates the given feed
     * @param feedId Feed ID to activated
     * @dev This function can be called by the contract admin to activate a feed
     */
    function activateFeed(bytes32 feedId) external onlyOwner {
        VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

        if (feedVerifierState.configCount == 0) revert InvalidFeed(feedId);
        feedVerifierState.isDeactivated = false;
        emit FeedActivated(feedId);
    }

    /**
     * @notice Deactivates the given feed
     * @param feedId Feed ID to deactivated
     * @dev This function can be called by the contract admin to deactivate a feed
     */
    function deactivateFeed(bytes32 feedId) external onlyOwner {
        VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

        if (feedVerifierState.configCount == 0) revert InvalidFeed(feedId);
        feedVerifierState.isDeactivated = true;
        emit FeedDeactivated(feedId);
    }

    //***************************//
    // Repurposed OCR2 Functions //
    //***************************//

    // Reverts transaction if config args are invalid
    modifier checkConfigValid(uint256 numSigners, uint256 f) {
        if (f == 0) revert FaultToleranceMustBePositive();
        if (numSigners > MAX_NUM_ORACLES)
            revert ExcessSigners(numSigners, MAX_NUM_ORACLES);
        if (numSigners <= 3 * f)
            revert InsufficientSigners(numSigners, 3 * f + 1);
        _;
    }

    function setConfig(
        bytes32 feedId,
        address[] memory signers,
        bytes32[] memory offchainTransmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig
    ) external override checkConfigValid(signers.length, f) onlyOwner {
        VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

        // Increment the number of times a config has been set first
        feedVerifierState.configCount++;

        bytes32 configDigest = _configDigestFromConfigData(
            feedId,
            feedVerifierState.configCount,
            signers,
            offchainTransmitters,
            f,
            onchainConfig,
            offchainConfigVersion,
            offchainConfig
        );

        feedVerifierState.s_verificationDataConfigs[configDigest].f = f;
        feedVerifierState.s_verificationDataConfigs[configDigest].isActive = true;
        for (uint8 i; i < signers.length; i++) {
            address signerAddr = signers[i];
            if (signerAddr == address(0)) revert ZeroAddress();

            // All signer roles are unset by default for a new config digest.
            // Here the contract checks to see if a signer's address has already
            // been set to ensure that the group of signer addresses that will
            // sign reports with the config digest are unique.
            bool isSignerAlreadySet = feedVerifierState.s_verificationDataConfigs[configDigest]
                .oracles[signerAddr]
                .role != Role.Unset;
            if (isSignerAlreadySet) revert NonUniqueSignatures();
            feedVerifierState.s_verificationDataConfigs[configDigest].oracles[
                signerAddr
            ] = Signer({role: Role.Signer, index: i});
        }

        // We need to manually set the verifier in the proxy
        // the first time.
        if (feedVerifierState.configCount > 1)
            IVerifierProxy(i_verifierProxyAddr).setVerifier(
                feedVerifierState.latestConfigDigest,
                configDigest
            );

        emit ConfigSet(
            feedId,
            feedVerifierState.latestConfigBlockNumber,
            configDigest,
            feedVerifierState.configCount,
            signers,
            offchainTransmitters,
            f,
            onchainConfig,
            offchainConfigVersion,
            offchainConfig
        );

        feedVerifierState.latestEpoch = 0;
        feedVerifierState.latestConfigBlockNumber = uint32(block.number);
        feedVerifierState.latestConfigDigest = configDigest;
    }

    function latestConfigDigestAndEpoch(bytes32 feedId)
        external
        view
        override
        returns (
            bool scanLogs,
            bytes32 configDigest,
            uint32 epoch
        )
    {
        VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];
        return (
            false,
            feedVerifierState.latestConfigDigest,
            feedVerifierState.latestEpoch
        );
    }

    function latestConfigDetails(bytes32 feedId)
        external
        view
        override
        returns (
            uint32 configCount,
            uint32 blockNumber,
            bytes32 configDigest
        )
    {
        VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];
        return (
            feedVerifierState.configCount,
            feedVerifierState.latestConfigBlockNumber,
            feedVerifierState.latestConfigDigest
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";

interface IVerifier is IERC165 {
    /**
     * @notice Verifies that the data encoded has been signed
     * correctly by routing to the correct verifier.
     * @param signedReport The encoded data to be verified.
     * @param requester The original address that requested to verify the contract.
     * This is only used for logging purposes.
     * @dev Verification is typically only done through the proxy contract so
     * we can't just use msg.sender to log the requester as the msg.sender
     * contract will always be the proxy.
     * @return response The encoded verified response.
     */
    function verify(bytes memory signedReport, address requester)
        external
        returns (bytes memory response);

    /**
     * @notice sets offchain reporting protocol configuration incl. participating oracles
     * @param feedId Feed ID to set config for
     * @param signers addresses with which oracles sign the reports
     * @param offchainTransmitters CSA key for the ith Oracle
     * @param f number of faulty oracles the system can tolerate
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version number for offchainEncoding schema
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     */
    function setConfig(
        bytes32 feedId,
        address[] memory signers,
        bytes32[] memory offchainTransmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig
    ) external;

    /**
     * @notice returns the latest config digest and epoch for a feed
     * @param feedId Feed ID to fetch data for
     * @return scanLogs indicates whether to rely on the configDigest and epoch
     * returned or whether to scan logs for the Transmitted event instead.
     * @return configDigest
     * @return epoch
     */
    function latestConfigDigestAndEpoch(bytes32 feedId)
        external
        view
        returns (
            bool scanLogs,
            bytes32 configDigest,
            uint32 epoch
        );

    /**
     * @notice information about current offchain reporting protocol configuration
     * @param feedId Feed ID to fetch data for
     * @return configCount ordinal number of current config, out of all configs applied to this contract so far
     * @return blockNumber block at which this config was set
     * @return configDigest domain-separation tag for current config
     */
    function latestConfigDetails(bytes32 feedId)
        external
        view
        returns (
            uint32 configCount,
            uint32 blockNumber,
            bytes32 configDigest
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IVerifierProxy {
    /**
     * @notice Verifies that the data encoded has been signed
     * correctly by routing to the correct verifier.
     * @param signedReport The encoded data to be verified.
     * @return verifierResponse The encoded response from the verifier.
     */
    function verify(bytes memory signedReport)
        external
        returns (bytes memory verifierResponse);

    /**
     * @notice Sets a new verifier for a config digest
     * @param currentConfigDigest The current config digest
     * @param newConfigDigest The config digest to set
     * reports for a given config digest.
     */
    function setVerifier(bytes32 currentConfigDigest, bytes32 newConfigDigest)
        external;

    /**
     * @notice Sets a new verifier for a config digest
     * @param configDigest The config digest to set
     * @param verifierAddr The address of the verifier contract that verifies
     * reports for a given config digest.
     */
    function initializeVerifier(bytes32 configDigest, address verifierAddr)
        external;

    /**
     * @notice Removes a verifier
     * @param configDigest The config digest of the verifier to remove
     */
    function unsetVerifier(bytes32 configDigest) external;

    /**
     * @notice Retrieves the verifier address that verifies reports
     * for a config digest.
     * @param configDigest The config digest to query for
     * @return verifierAddr The address of the verifier contract that verifies
     * reports for a given config digest.
     */
    function getVerifier(bytes32 configDigest)
        external
        view
        returns (address verifierAddr);
}