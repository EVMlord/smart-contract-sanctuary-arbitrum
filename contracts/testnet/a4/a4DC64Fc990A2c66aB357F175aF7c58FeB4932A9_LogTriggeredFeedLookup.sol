// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;

abstract contract ExecutionPrevention {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum UpkeepFormat {
  V1,
  V2,
  V3
}

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
pragma solidity 0.8.16;

import "../../../interfaces/TypeAndVersionInterface.sol";
import {IAutomationRegistryConsumer} from "./interfaces/IAutomationRegistryConsumer.sol";

uint256 constant PERFORM_GAS_CUSHION = 5_000;

/**
 * @title AutomationForwarder is a relayer that sits between the registry and the customer's target contract
 * @dev The purpose of the forwarder is to give customers a consistent address to authorize against,
 * which stays consistent between migrations. The Forwarder also exposes the registry address, so that users who
 * want to programatically interact with the registry (ie top up funds) can do so.
 */
contract AutomationForwarder is TypeAndVersionInterface {
  IAutomationRegistryConsumer private s_registry;
  address private immutable i_target;
  uint256 private immutable i_upkeepID;
  string public constant override typeAndVersion = "AutomationForwarder 1.0.0";

  error NotAuthorized();

  constructor(uint256 upkeepID, address target, address registry) {
    s_registry = IAutomationRegistryConsumer(registry);
    i_target = target;
    i_upkeepID = upkeepID;
  }

  /**
   * @notice forward is called by the registry and forwards the call to the target
   * @param gasAmount is the amount of gas to use in the call
   * @param data is the 4 bytes function selector + arbitrary function data
   * @return success indicating whether the target call succeeded or failed
   */
  function forward(uint256 gasAmount, bytes memory data) external returns (bool success) {
    if (msg.sender != address(s_registry)) revert NotAuthorized();
    address target = i_target;
    assembly {
      let g := gas()
      // Compute g -= PERFORM_GAS_CUSHION and check for underflow
      if lt(g, PERFORM_GAS_CUSHION) {
        revert(0, 0)
      }
      g := sub(g, PERFORM_GAS_CUSHION)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call with exact gas
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
  }

  /**
   * @notice updateRegistry is called by the registry during migrations
   * @param newRegistry is the registry that this forwarder is being migrated to
   */
  function updateRegistry(address newRegistry) external {
    if (msg.sender != address(s_registry)) revert NotAuthorized();
    s_registry = IAutomationRegistryConsumer(newRegistry);
  }

  /**
   * @notice gets the registry address
   */
  function getRegistry() external view returns (IAutomationRegistryConsumer) {
    return s_registry;
  }

  /**
   * @notice gets the target contract address
   */
  function getTarget() external view returns (address) {
    return i_target;
  }

  /**
   * @notice gets the upkeepID that this forwarder belongs to
   */
  function getUpkeepID() external view returns (uint256) {
    return i_upkeepID;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title Chainable - the contract size limit nullifier
 * @notice Chainable is designed to link together a "chain" of contracts through fallback functions
 * and delegatecalls. All code is executed in the context of the head of the chain, the "master" contract.
 */
contract Chainable {
  /**
   * @dev addresses of the next contract in the chain **have to be immutable/constant** or the system won't work
   */
  address private immutable i_next;

  /**
   * @param next the address of the next contract in the chain
   */
  constructor(address next) {
    i_next = next;
  }

  /**
   * @notice returns the address of the next contract in the chain
   */
  function fallbackTo() external view returns (address) {
    return i_next;
  }

  /**
   * @notice the fallback function routes the call to the next contract in the chain
   * @dev most of the implementation is copied directly from OZ's Proxy contract
   */
  fallback() external {
    // copy to memory for assembly access
    address next = i_next;
    // copied directly from OZ's Proxy contract
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the next contract.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), next, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FeedLookupCompatibleInterface {
  error FeedLookup(string feedParamKey, string[] feeds, string timeParamKey, uint256 time, bytes extraData);

  /**
   * @notice any contract which wants to utilize FeedLookup feature needs to
   * implement this interface as well as the automation compatible interface.
   * @param values an array of bytes returned from Mercury endpoint.
   * @param extraData context data from feed lookup process.
   * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
   */
  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external view returns (bool upkeepNeeded, bytes memory performData);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice IAutomationRegistryConsumer defines the LTS user-facing interface that we intend to maintain for
 * across upgrades. As long as users use functions from within this interface, their upkeeps will retain
 * backwards compatability across migrations.
 * @dev Functions can be added to this interface, but not removed.
 */
interface IAutomationRegistryConsumer {
  function getBalance(uint256 id) external view returns (uint256 balance);

  function getMinBalance(uint256 id) external view returns (uint96 minBalance);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function withdrawFunds(uint256 id, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Log {
  uint256 index;
  uint256 txIndex;
  bytes32 txHash;
  uint256 blockNumber;
  bytes32 blockHash;
  address source;
  bytes32[] topics;
  bytes data;
}

interface ILogAutomation {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param log the raw log data matching the filter that this contract has
   * registered as a trigger
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkLog(Log calldata log) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/proxy/Proxy.sol";
import "./KeeperRegistryBase2_1.sol";
import "./KeeperRegistryLogicA2_1.sol";
import "./Chainable.sol";
import "../../../interfaces/ERC677ReceiverInterface.sol";
import "../../../OCR2Abstract.sol";

/**
 * @notice Registry for adding work for Chainlink Keepers to perform on client
 * contracts. Clients must support the Upkeep interface.
 */
contract KeeperRegistry2_1 is KeeperRegistryBase2_1, OCR2Abstract, Chainable, ERC677ReceiverInterface {
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @notice versions:
   * - KeeperRegistry 2.1.0: introduces support for log, cron, and ready triggers
                           : removes the need for "wrapped perform data"
   * - KeeperRegistry 2.0.2: pass revert bytes as performData when target contract reverts
   *                       : fixes issue with arbitrum block number
   *                       : does an early return in case of stale report instead of revert
   * - KeeperRegistry 2.0.1: implements workaround for buggy migrate function in 1.X
   * - KeeperRegistry 2.0.0: implement OCR interface
   * - KeeperRegistry 1.3.0: split contract into Proxy and Logic
   *                       : account for Arbitrum and Optimism L1 gas fee
   *                       : allow users to configure upkeeps
   * - KeeperRegistry 1.2.0: allow funding within performUpkeep
   *                       : allow configurable registry maxPerformGas
   *                       : add function to let admin change upkeep gas limit
   *                       : add minUpkeepSpend requirement
   *                       : upgrade to solidity v0.8
   * - KeeperRegistry 1.1.0: added flatFeeMicroLink
   * - KeeperRegistry 1.0.0: initial release
   */
  string public constant override typeAndVersion = "KeeperRegistry 2.1.0";

  /**
   * @param logicA the address of the first logic contract
   */
  constructor(
    KeeperRegistryLogicA2_1 logicA
  )
    KeeperRegistryBase2_1(
      logicA.getMode(),
      logicA.getLinkAddress(),
      logicA.getLinkNativeFeedAddress(),
      logicA.getFastGasFeedAddress()
    )
    Chainable(address(logicA))
  {}

  ////////
  // ACTIONS
  ////////

  /**
   * @inheritdoc OCR2Abstract
   */
  function transmit(
    bytes32[3] calldata reportContext,
    bytes calldata rawReport,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs
  ) external override {
    uint256 gasOverhead = gasleft();
    HotVars memory hotVars = s_hotVars;

    if (hotVars.paused) revert RegistryPaused();
    if (!s_transmitters[msg.sender].active) revert OnlyActiveTransmitters();

    // Verify signatures
    if (s_latestConfigDigest != reportContext[0]) revert ConfigDigestMismatch();
    if (rs.length != hotVars.f + 1 || rs.length != ss.length) revert IncorrectNumberOfSignatures();
    _verifyReportSignature(reportContext, rawReport, rs, ss, rawVs);

    Report memory report = _decodeReport(rawReport);
    UpkeepTransmitInfo[] memory upkeepTransmitInfo = new UpkeepTransmitInfo[](report.upkeepIds.length);
    uint16 numUpkeepsPassedChecks;

    for (uint256 i = 0; i < report.upkeepIds.length; i++) {
      upkeepTransmitInfo[i].upkeep = s_upkeep[report.upkeepIds[i]];
      upkeepTransmitInfo[i].triggerType = getTriggerType(report.upkeepIds[i]);
      upkeepTransmitInfo[i].maxLinkPayment = _getMaxLinkPayment(
        hotVars,
        upkeepTransmitInfo[i].triggerType,
        upkeepTransmitInfo[i].upkeep.executeGas,
        uint32(report.performDatas[i].length),
        report.fastGasWei,
        report.linkNative,
        true
      );
      upkeepTransmitInfo[i].earlyChecksPassed = _prePerformChecks(
        report.upkeepIds[i],
        upkeepTransmitInfo[i].triggerType,
        report.triggers[i],
        upkeepTransmitInfo[i].upkeep,
        upkeepTransmitInfo[i].maxLinkPayment
      );

      if (upkeepTransmitInfo[i].earlyChecksPassed) {
        numUpkeepsPassedChecks += 1;
      } else {
        continue;
      }

      // Actually perform the target upkeep
      (upkeepTransmitInfo[i].performSuccess, upkeepTransmitInfo[i].gasUsed) = _performUpkeep(
        upkeepTransmitInfo[i].upkeep.forwarder,
        report.gasLimits[i],
        report.performDatas[i]
      );

      // Deduct that gasUsed by upkeep from our running counter
      gasOverhead -= upkeepTransmitInfo[i].gasUsed;

      // Store last perform block number for upkeep
      _updateLastPerformed(report.upkeepIds[i], upkeepTransmitInfo[i].triggerType);
    }
    // No upkeeps to be performed in this report
    if (numUpkeepsPassedChecks == 0) {
      return;
    }

    // This is the overall gas overhead that will be split across performed upkeeps
    // Take upper bound of 16 gas per callData bytes, which is approximated to be reportLength
    // Rest of msg.data is accounted for in accounting overheads
    gasOverhead =
      (gasOverhead - gasleft() + 16 * rawReport.length) +
      ACCOUNTING_FIXED_GAS_OVERHEAD +
      (ACCOUNTING_PER_SIGNER_GAS_OVERHEAD * (hotVars.f + 1));
    gasOverhead = gasOverhead / numUpkeepsPassedChecks + ACCOUNTING_PER_UPKEEP_GAS_OVERHEAD;

    uint96 totalReimbursement;
    uint96 totalPremium;
    {
      uint96 reimbursement;
      uint96 premium;
      for (uint256 i = 0; i < report.upkeepIds.length; i++) {
        if (upkeepTransmitInfo[i].earlyChecksPassed) {
          upkeepTransmitInfo[i].gasOverhead = _getCappedGasOverhead(
            gasOverhead,
            upkeepTransmitInfo[i].triggerType,
            uint32(report.performDatas[i].length),
            hotVars.f
          );

          (reimbursement, premium) = _postPerformPayment(
            hotVars,
            report.upkeepIds[i],
            upkeepTransmitInfo[i],
            report.fastGasWei,
            report.linkNative,
            numUpkeepsPassedChecks
          );
          totalPremium += premium;
          totalReimbursement += reimbursement;

          emit UpkeepPerformed(
            report.upkeepIds[i],
            upkeepTransmitInfo[i].performSuccess,
            reimbursement + premium,
            upkeepTransmitInfo[i].gasUsed,
            upkeepTransmitInfo[i].gasOverhead,
            report.triggers[i]
          );
        }
      }
    }
    // record payments
    s_transmitters[msg.sender].balance += totalReimbursement;
    s_hotVars.totalPremium += totalPremium;

    uint40 epochAndRound = uint40(uint256(reportContext[1]));
    uint32 epoch = uint32(epochAndRound >> 8);
    if (epoch > hotVars.latestEpoch) {
      s_hotVars.latestEpoch = epoch;
    }
  }

  /**
   * @notice simulates the upkeep with the perform data returned from checkUpkeep
   * @param id identifier of the upkeep to execute the data with.
   * @param performData calldata parameter to be passed to the target upkeep.
   * @return success whether the call reverted or not
   * @return gasUsed the amount of gas the target contract consumed
   */
  function simulatePerformUpkeep(
    uint256 id,
    bytes calldata performData
  ) external cannotExecute returns (bool success, uint256 gasUsed) {
    if (s_hotVars.paused) revert RegistryPaused();

    Upkeep memory upkeep = s_upkeep[id];
    (success, gasUsed) = _performUpkeep(upkeep.forwarder, upkeep.executeGas, performData);
    return (success, gasUsed);
  }

  /**
   * @notice uses LINK's transferAndCall to LINK and add funding to an upkeep
   * @dev safe to cast uint256 to uint96 as total LINK supply is under UINT96MAX
   * @param sender the account which transferred the funds
   * @param amount number of LINK transfer
   */
  function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external override {
    if (msg.sender != address(i_link)) revert OnlyCallableByLINKToken();
    if (data.length != 32) revert InvalidDataLength();
    uint256 id = abi.decode(data, (uint256));
    if (s_upkeep[id].maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();

    s_upkeep[id].balance = s_upkeep[id].balance + uint96(amount);
    s_expectedLinkBalance = s_expectedLinkBalance + amount;

    emit FundsAdded(id, sender, uint96(amount));
  }

  /////////////
  // SETTERS //
  /////////////

  /**
   * @inheritdoc OCR2Abstract
   */
  function setConfig(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfigBytes,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) external override onlyOwner {
    if (signers.length > maxNumOracles) revert TooManyOracles();
    if (f == 0) revert IncorrectNumberOfFaultyOracles();
    if (signers.length != transmitters.length || signers.length <= 3 * f) revert IncorrectNumberOfSigners();

    // move all pooled payments out of the pool to each transmitter's balance
    uint96 totalPremium = s_hotVars.totalPremium;
    uint96 oldLength = uint96(s_transmittersList.length);
    for (uint256 i = 0; i < oldLength; i++) {
      _updateTransmitterBalanceFromPool(s_transmittersList[i], totalPremium, oldLength);
    }

    // remove any old signer/transmitter addresses
    address signerAddress;
    address transmitterAddress;
    for (uint256 i = 0; i < oldLength; i++) {
      signerAddress = s_signersList[i];
      transmitterAddress = s_transmittersList[i];
      delete s_signers[signerAddress];
      // Do not delete the whole transmitter struct as it has balance information stored
      s_transmitters[transmitterAddress].active = false;
    }
    delete s_signersList;
    delete s_transmittersList;

    // add new signer/transmitter addresses
    {
      Transmitter memory transmitter;
      address temp;
      for (uint256 i = 0; i < signers.length; i++) {
        if (s_signers[signers[i]].active) revert RepeatedSigner();
        s_signers[signers[i]] = Signer({active: true, index: uint8(i)});

        temp = transmitters[i];
        transmitter = s_transmitters[temp];
        if (transmitter.active) revert RepeatedTransmitter();
        transmitter.active = true;
        transmitter.index = uint8(i);
        // new transmitters start afresh from current totalPremium
        // some spare change of premium from previous pool will be forfeited
        transmitter.lastCollected = totalPremium;
        s_transmitters[temp] = transmitter;
      }
    }
    s_signersList = signers;
    s_transmittersList = transmitters;

    // Set the onchain config
    OnchainConfig memory onchainConfig = abi.decode(onchainConfigBytes, (OnchainConfig));

    s_hotVars = HotVars({
      f: f,
      paymentPremiumPPB: onchainConfig.paymentPremiumPPB,
      flatFeeMicroLink: onchainConfig.flatFeeMicroLink,
      stalenessSeconds: onchainConfig.stalenessSeconds,
      gasCeilingMultiplier: onchainConfig.gasCeilingMultiplier,
      paused: s_hotVars.paused,
      reentrancyGuard: s_hotVars.reentrancyGuard,
      totalPremium: totalPremium,
      latestEpoch: 0 // DON restarts epoch
    });

    s_storage = Storage({
      checkGasLimit: onchainConfig.checkGasLimit,
      minUpkeepSpend: onchainConfig.minUpkeepSpend,
      maxPerformGas: onchainConfig.maxPerformGas,
      transcoder: onchainConfig.transcoder,
      maxCheckDataSize: onchainConfig.maxCheckDataSize,
      maxPerformDataSize: onchainConfig.maxPerformDataSize,
      maxRevertDataSize: onchainConfig.maxRevertDataSize,
      upkeepPrivilegeManager: onchainConfig.upkeepPrivilegeManager,
      nonce: s_storage.nonce,
      configCount: s_storage.configCount,
      latestConfigBlockNumber: s_storage.latestConfigBlockNumber,
      ownerLinkBalance: s_storage.ownerLinkBalance
    });
    s_fallbackGasPrice = onchainConfig.fallbackGasPrice;
    s_fallbackLinkPrice = onchainConfig.fallbackLinkPrice;

    uint32 previousConfigBlockNumber = s_storage.latestConfigBlockNumber;
    s_storage.latestConfigBlockNumber = uint32(_blockNum());
    s_storage.configCount += 1;

    s_latestConfigDigest = _configDigestFromConfigData(
      block.chainid,
      address(this),
      s_storage.configCount,
      signers,
      transmitters,
      f,
      onchainConfigBytes,
      offchainConfigVersion,
      offchainConfig
    );

    for (uint256 idx = 0; idx < s_registrars.length(); idx++) {
      s_registrars.remove(s_registrars.at(idx));
    }

    for (uint256 idx = 0; idx < onchainConfig.registrars.length; idx++) {
      s_registrars.add(onchainConfig.registrars[idx]);
    }

    emit ConfigSet(
      previousConfigBlockNumber,
      s_latestConfigDigest,
      s_storage.configCount,
      signers,
      transmitters,
      f,
      onchainConfigBytes,
      offchainConfigVersion,
      offchainConfig
    );
  }

  /////////////
  // GETTERS //
  /////////////

  /**
   * @inheritdoc OCR2Abstract
   */
  function latestConfigDetails()
    external
    view
    override
    returns (uint32 configCount, uint32 blockNumber, bytes32 configDigest)
  {
    return (s_storage.configCount, s_storage.latestConfigBlockNumber, s_latestConfigDigest);
  }

  /**
   * @inheritdoc OCR2Abstract
   */
  function latestConfigDigestAndEpoch()
    external
    view
    override
    returns (bool scanLogs, bytes32 configDigest, uint32 epoch)
  {
    return (false, s_latestConfigDigest, s_hotVars.latestEpoch);
  }

  ////////////////////////
  // INTERNAL FUNCTIONS //
  ////////////////////////

  /**
   * @dev _decodeReport decodes a serialized report into a Report struct
   */
  function _decodeReport(bytes memory rawReport) internal pure returns (Report memory) {
    (
      uint256 fastGasWei,
      uint256 linkNative,
      uint256[] memory upkeepIds,
      uint256[] memory gasLimits,
      bytes[] memory triggers,
      bytes[] memory performDatas
    ) = abi.decode(rawReport, (uint256, uint256, uint256[], uint256[], bytes[], bytes[]));
    if (
      upkeepIds.length != gasLimits.length ||
      upkeepIds.length != triggers.length ||
      upkeepIds.length != performDatas.length
    ) {
      revert InvalidReport();
    }
    return
      Report({
        fastGasWei: fastGasWei,
        linkNative: linkNative,
        upkeepIds: upkeepIds,
        gasLimits: gasLimits,
        triggers: triggers,
        performDatas: performDatas
      });
  }

  /**
   * @dev Does some early sanity checks before actually performing an upkeep
   */
  function _prePerformChecks(
    uint256 upkeepId,
    Trigger triggerType,
    bytes memory rawTrigger,
    Upkeep memory upkeep,
    uint96 maxLinkPayment
  ) internal returns (bool) {
    if (triggerType == Trigger.CONDITION) {
      if (!_validateConditionalTrigger(upkeepId, rawTrigger, upkeep)) return false;
    } else if (triggerType == Trigger.LOG) {
      if (!_validateLogTrigger(upkeepId, rawTrigger)) return false;
    } else {
      revert InvalidTriggerType();
    }
    if (upkeep.maxValidBlocknumber <= _blockNum()) {
      // Can happen when an upkeep got cancelled after report was generated.
      // However we have a CANCELLATION_DELAY of 50 blocks so shouldn't happen in practice
      emit CancelledUpkeepReport(upkeepId, rawTrigger);
      return false;
    }

    if (upkeep.balance < maxLinkPayment) {
      // Can happen due to flucutations in gas / link prices
      emit InsufficientFundsUpkeepReport(upkeepId, rawTrigger);
      return false;
    }

    return true;
  }

  /**
   * @dev Does some early sanity checks before actually performing an upkeep
   */
  function _validateConditionalTrigger(
    uint256 upkeepId,
    bytes memory rawTrigger,
    Upkeep memory upkeep
  ) internal returns (bool) {
    ConditionalTrigger memory trigger = abi.decode(rawTrigger, (ConditionalTrigger));
    if (trigger.blockNum < upkeep.lastPerformedBlockNumber) {
      // Can happen when another report performed this upkeep after this report was generated
      emit StaleUpkeepReport(upkeepId, rawTrigger);
      return false;
    }
    if (
      (trigger.blockHash != bytes32("") && _blockHash(trigger.blockNum) != trigger.blockHash) ||
      trigger.blockNum >= block.number
    ) {
      // There are two cases of reorged report
      // 1. trigger block number is in future: this is an edge case during extreme deep reorgs of chain
      // which is always protected against
      // 2. blockHash at trigger block number was same as trigger time. This is an optional check which is
      // applied if DON sends non empty trigger.blockHash. Note: It only works for last 256 blocks on chain
      // when it is sent
      emit ReorgedUpkeepReport(upkeepId, rawTrigger);
      return false;
    }
    return true;
  }

  function _validateLogTrigger(uint256 upkeepId, bytes memory rawTrigger) internal returns (bool) {
    LogTrigger memory trigger = abi.decode(rawTrigger, (LogTrigger));
    if (
      (trigger.blockHash != bytes32("") && _blockHash(trigger.blockNum) != trigger.blockHash) ||
      trigger.blockNum >= block.number
    ) {
      // Reorg protection is same as conditional trigger upkeeps
      emit ReorgedUpkeepReport(upkeepId, rawTrigger);
      return false;
    }
    bytes32 logTriggerID = keccak256(abi.encodePacked(upkeepId, trigger.txHash, trigger.logIndex));
    if (s_observedLogTriggers[logTriggerID]) {
      emit StaleUpkeepReport(upkeepId, rawTrigger);
      return false;
    }
    s_observedLogTriggers[logTriggerID] = true;
    return true;
  }

  /**
   * @dev Verify signatures attached to report
   */
  function _verifyReportSignature(
    bytes32[3] calldata reportContext,
    bytes calldata report,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs
  ) internal view {
    bytes32 h = keccak256(abi.encode(keccak256(report), reportContext));
    // i-th byte counts number of sigs made by i-th signer
    uint256 signedCount = 0;

    Signer memory signer;
    address signerAddress;
    for (uint256 i = 0; i < rs.length; i++) {
      signerAddress = ecrecover(h, uint8(rawVs[i]) + 27, rs[i], ss[i]);
      signer = s_signers[signerAddress];
      if (!signer.active) revert OnlyActiveSigners();
      unchecked {
        signedCount += 1 << (8 * signer.index);
      }
    }

    if (signedCount & ORACLE_MASK != signedCount) revert DuplicateSigners();
  }

  /**
   * @dev we don't update anything for log triggers because log triggered txs can be performed out of order
   */
  function _updateLastPerformed(uint256 upkeepID, Trigger triggerType) private {
    if (triggerType == Trigger.CONDITION) {
      s_upkeep[upkeepID].lastPerformedBlockNumber = uint32(_blockNum());
    }
  }

  /**
   * @dev calls the Upkeep target with the performData param passed in by the
   * transmitter and the exact gas required by the Upkeep
   */
  function _performUpkeep(
    AutomationForwarder forwarder,
    uint256 executeGas,
    bytes memory performData
  ) private nonReentrant returns (bool success, uint256 gasUsed) {
    gasUsed = gasleft();
    performData = abi.encodeWithSelector(PERFORM_SELECTOR, performData);
    success = forwarder.forward(executeGas, performData);
    gasUsed = gasUsed - gasleft();
    return (success, gasUsed);
  }

  /**
   * @dev does postPerform payment processing for an upkeep. Deducts upkeep's balance and increases
   * amount spent.
   */
  function _postPerformPayment(
    HotVars memory hotVars,
    uint256 upkeepId,
    UpkeepTransmitInfo memory upkeepTransmitInfo,
    uint256 fastGasWei,
    uint256 linkNative,
    uint16 numBatchedUpkeeps
  ) internal returns (uint96 gasReimbursement, uint96 premium) {
    (gasReimbursement, premium) = _calculatePaymentAmount(
      hotVars,
      upkeepTransmitInfo.gasUsed,
      upkeepTransmitInfo.gasOverhead,
      fastGasWei,
      linkNative,
      numBatchedUpkeeps,
      true
    );

    uint96 payment = gasReimbursement + premium;
    s_upkeep[upkeepId].balance -= payment;
    s_upkeep[upkeepId].amountSpent += payment;

    return (gasReimbursement, premium);
  }

  /**
   * @dev Caps the gas overhead by the constant overhead used within initial payment checks in order to
   * prevent a revert in payment processing.
   */
  function _getCappedGasOverhead(
    uint256 calculatedGasOverhead,
    Trigger triggerType,
    uint32 performDataLength,
    uint8 f
  ) private pure returns (uint256 cappedGasOverhead) {
    cappedGasOverhead = _getMaxGasOverhead(triggerType, performDataLength, f);
    if (calculatedGasOverhead < cappedGasOverhead) {
      return calculatedGasOverhead;
    }
    return cappedGasOverhead;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/Address.sol";
import "../../../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbGasInfo.sol";
import "../../../vendor/@eth-optimism/contracts/0.8.9/contracts/L2/predeploys/OVM_GasPriceOracle.sol";
import "../../../automation/ExecutionPrevention.sol";
import {ArbSys} from "../../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import "./interfaces/FeedLookupCompatibleInterface.sol";
import "./interfaces/ILogAutomation.sol";
import {AutomationForwarder} from "./AutomationForwarder.sol";
import "../../../ConfirmedOwner.sol";
import "../../../interfaces/AggregatorV3Interface.sol";
import "../../../interfaces/LinkTokenInterface.sol";
import "../../../interfaces/automation/KeeperCompatibleInterface.sol";
import "../../../interfaces/automation/UpkeepTranscoderInterface.sol";

/**
 * @notice Base Keeper Registry contract, contains shared logic between
 * KeeperRegistry and KeeperRegistryLogic
 */
abstract contract KeeperRegistryBase2_1 is ConfirmedOwner, ExecutionPrevention {
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  address internal constant ZERO_ADDRESS = address(0);
  address internal constant IGNORE_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
  bytes4 internal constant CHECK_SELECTOR = KeeperCompatibleInterface.checkUpkeep.selector;
  bytes4 internal constant PERFORM_SELECTOR = KeeperCompatibleInterface.performUpkeep.selector;
  bytes4 internal constant CHECK_CALLBACK_SELECTOR = FeedLookupCompatibleInterface.checkCallback.selector;
  bytes4 internal constant CHECK_LOG_SELECTOR = ILogAutomation.checkLog.selector;
  uint256 internal constant PERFORM_GAS_MIN = 2_300;
  uint256 internal constant CANCELLATION_DELAY = 50;
  uint256 internal constant PERFORM_GAS_CUSHION = 5_000;
  uint256 internal constant PPB_BASE = 1_000_000_000;
  uint32 internal constant UINT32_MAX = type(uint32).max;
  uint96 internal constant LINK_TOTAL_SUPPLY = 1e27;
  // The first byte of the mask can be 0, because we only ever have 31 oracles
  uint256 internal constant ORACLE_MASK = 0x0001010101010101010101010101010101010101010101010101010101010101;
  /**
   * @dev UPKEEP_TRANSCODER_VERSION_BASE is temporary necessity for backwards compatibility with
   * MigratableKeeperRegistryInterfaceV1 - it should be removed in future versions in favor of
   * UPKEEP_VERSION_BASE and MigratableKeeperRegistryInterfaceV2
   */
  UpkeepFormat internal constant UPKEEP_TRANSCODER_VERSION_BASE = UpkeepFormat.V1;
  uint8 internal constant UPKEEP_VERSION_BASE = uint8(UpkeepFormat.V3);
  // L1_FEE_DATA_PADDING includes 35 bytes for L1 data padding for Optimism
  bytes internal constant L1_FEE_DATA_PADDING =
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

  uint256 internal constant REGISTRY_CONDITIONAL_OVERHEAD = 80_000; // Used in maxPayment estimation, and in capping overheads during actual payment
  uint256 internal constant REGISTRY_LOG_OVERHEAD = 100_000; // Used only in maxPayment estimation, and in capping overheads during actual payment.
  uint256 internal constant REGISTRY_PER_PERFORM_BYTE_GAS_OVERHEAD = 20; // Used only in maxPayment estimation, and in capping overheads during actual payment. Value scales with performData length.
  uint256 internal constant REGISTRY_PER_SIGNER_GAS_OVERHEAD = 7_500; // Used only in maxPayment estimation, and in capping overheads during actual payment. Value scales with f.

  uint256 internal constant ACCOUNTING_FIXED_GAS_OVERHEAD = 27_500; // Used in actual payment. Fixed overhead per tx
  uint256 internal constant ACCOUNTING_PER_SIGNER_GAS_OVERHEAD = 1_100; // Used in actual payment. overhead per signer
  uint256 internal constant ACCOUNTING_PER_UPKEEP_GAS_OVERHEAD = 7_000; // Used in actual payment. overhead per upkeep performed

  OVM_GasPriceOracle internal constant OPTIMISM_ORACLE = OVM_GasPriceOracle(0x420000000000000000000000000000000000000F);
  ArbGasInfo internal constant ARB_NITRO_ORACLE = ArbGasInfo(0x000000000000000000000000000000000000006C);
  ArbSys internal constant ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064);

  LinkTokenInterface internal immutable i_link;
  AggregatorV3Interface internal immutable i_linkNativeFeed;
  AggregatorV3Interface internal immutable i_fastGasFeed;
  Mode internal immutable i_mode;

  // @dev - The storage is gas optimised for one and only function - transmit. All the storage accessed in transmit
  // is stored compactly. Rest of the storage layout is not of much concern as transmit is the only hot path
  // Upkeep storage
  EnumerableSet.UintSet internal s_upkeepIDs;
  mapping(uint256 => Upkeep) internal s_upkeep; // accessed during transmit
  mapping(uint256 => address) internal s_upkeepAdmin;
  mapping(uint256 => address) internal s_proposedAdmin;
  mapping(uint256 => bytes) internal s_checkData;
  mapping(bytes32 => bool) internal s_observedLogTriggers;
  // Registry config and state
  EnumerableSet.AddressSet internal s_registrars;
  mapping(address => Transmitter) internal s_transmitters;
  mapping(address => Signer) internal s_signers;
  address[] internal s_signersList; // s_signersList contains the signing address of each oracle
  address[] internal s_transmittersList; // s_transmittersList contains the transmission address of each oracle
  mapping(address => address) internal s_transmitterPayees; // s_payees contains the mapping from transmitter to payee.
  mapping(address => address) internal s_proposedPayee; // proposed payee for a transmitter
  bytes32 internal s_latestConfigDigest; // Read on transmit path in case of signature verification
  HotVars internal s_hotVars; // Mixture of config and state, used in transmit
  Storage internal s_storage; // Mixture of config and state, not used in transmit
  uint256 internal s_fallbackGasPrice;
  uint256 internal s_fallbackLinkPrice;
  uint256 internal s_expectedLinkBalance; // Used in case of erroneous LINK transfers to contract
  mapping(address => MigrationPermission) internal s_peerRegistryMigrationPermission; // Permissions for migration to and fro
  mapping(uint256 => bytes) internal s_upkeepTriggerConfig; // upkeep triggers
  mapping(uint256 => bytes) internal s_upkeepOffchainConfig; // general config set by users for each upkeep
  mapping(uint256 => bytes) internal s_upkeepPrivilegeConfig; // general config set by an administrative role

  error ArrayHasNoEntries();
  error CannotCancel();
  error DuplicateEntry();
  error GasLimitCanOnlyIncrease();
  error GasLimitOutsideRange();
  error IndexOutOfRange();
  error InsufficientFunds();
  error InvalidDataLength();
  error InvalidTrigger();
  error InvalidPayee();
  error InvalidRecipient();
  error InvalidTriggerType();
  error MigrationNotPermitted();
  error NotAContract();
  error OnlyActiveTransmitters();
  error OnlyCallableByAdmin();
  error OnlyCallableByLINKToken();
  error OnlyCallableByOwnerOrAdmin();
  error OnlyCallableByOwnerOrRegistrar();
  error OnlyCallableByPayee();
  error OnlyCallableByProposedAdmin();
  error OnlyCallableByProposedPayee();
  error OnlyCallableByUpkeepPrivilegeManager();
  error OnlyPausedUpkeep();
  error OnlyUnpausedUpkeep();
  error ParameterLengthError();
  error PaymentGreaterThanAllLINK();
  error TargetCheckReverted(bytes reason);
  error TranscoderNotSet();
  error UpkeepCancelled();
  error UpkeepNotCanceled();
  error UpkeepNotNeeded();
  error ValueNotChanged();
  error ConfigDigestMismatch();
  error IncorrectNumberOfSignatures();
  error OnlyActiveSigners();
  error DuplicateSigners();
  error TooManyOracles();
  error IncorrectNumberOfSigners();
  error IncorrectNumberOfFaultyOracles();
  error RepeatedSigner();
  error RepeatedTransmitter();
  error CheckDataExceedsLimit();
  error MaxCheckDataSizeCanOnlyIncrease();
  error MaxPerformDataSizeCanOnlyIncrease();
  error InvalidReport();
  error RegistryPaused();
  error ReentrantCall();
  error UpkeepAlreadyExists();

  enum MigrationPermission {
    NONE,
    OUTGOING,
    INCOMING,
    BIDIRECTIONAL
  }

  enum Mode {
    DEFAULT,
    ARBITRUM,
    OPTIMISM
  }

  enum Trigger {
    CONDITION,
    LOG
  }

  enum UpkeepFailureReason {
    NONE,
    UPKEEP_CANCELLED,
    UPKEEP_PAUSED,
    TARGET_CHECK_REVERTED,
    UPKEEP_NOT_NEEDED,
    PERFORM_DATA_EXCEEDS_LIMIT,
    INSUFFICIENT_BALANCE,
    CALLBACK_REVERTED,
    REVERT_DATA_EXCEEDS_LIMIT,
    REGISTRY_PAUSED
  }

  /**
   * @notice OnchainConfig of the registry
   * @dev only used in params and return values
   * @member paymentPremiumPPB payment premium rate oracles receive on top of
   * being reimbursed for gas, measured in parts per billion
   * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
   * priced in MicroLink; can be used in conjunction with or independently of
   * paymentPremiumPPB
   * @member checkGasLimit gas limit when checking for upkeep
   * @member stalenessSeconds number of seconds that is allowed for feed data to
   * be stale before switching to the fallback pricing
   * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
   * when calculating the payment ceiling for keepers
   * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
   * @member maxPerformGas max executeGas allowed for an upkeep on this registry
   * @member maxCheckDataSize max length of checkData bytes
   * @member maxPerformDataSize max length of performData bytes
   * @member maxRevertDataSize max length of revertData bytes
   * @member fallbackGasPrice gas price used if the gas price feed is stale
   * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
   * @member transcoder address of the transcoder contract
   * @member registrar address of the registrar contract
   * @member address which can set privilege for upkeeps
   */
  struct OnchainConfig {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
    uint96 minUpkeepSpend;
    uint32 maxPerformGas;
    uint32 maxCheckDataSize;
    uint32 maxPerformDataSize;
    uint32 maxRevertDataSize;
    uint256 fallbackGasPrice;
    uint256 fallbackLinkPrice;
    address transcoder;
    address[] registrars;
    address upkeepPrivilegeManager;
  }

  /**
   * @notice state of the registry
   * @dev only used in params and return values
   * @member nonce used for ID generation
   * @member ownerLinkBalance withdrawable balance of LINK by contract owner
   * @member expectedLinkBalance the expected balance of LINK of the registry
   * @member totalPremium the total premium collected on registry so far
   * @member numUpkeeps total number of upkeeps on the registry
   * @member configCount ordinal number of current config, out of all configs applied to this contract so far
   * @member latestConfigBlockNumber last block at which this config was set
   * @member latestConfigDigest domain-separation tag for current config
   * @member latestEpoch for which a report was transmitted
   * @member paused freeze on execution scoped to the entire registry
   */
  struct State {
    uint32 nonce;
    uint96 ownerLinkBalance;
    uint256 expectedLinkBalance;
    uint96 totalPremium;
    uint256 numUpkeeps;
    uint32 configCount;
    uint32 latestConfigBlockNumber;
    bytes32 latestConfigDigest;
    uint32 latestEpoch;
    bool paused;
  }

  /**
   * @notice all information about an upkeep
   * @dev only used in return values
   * @member target the contract which needs to be serviced
   * @member executeGas the gas limit of upkeep execution
   * @member checkData the checkData bytes for this upkeep
   * @member balance the balance of this upkeep
   * @member admin for this upkeep
   * @member maxValidBlocknumber until which block this upkeep is valid
   * @member lastPerformedBlockNumber the last block number when this upkeep was performed
   * @member amountSpent the amount this upkeep has spent
   * @member paused if this upkeep has been paused
   * @member skipSigVerification skip signature verification in transmit for a low security low cost model
   */
  struct UpkeepInfo {
    address target;
    address forwarder;
    uint32 executeGas;
    bytes checkData;
    uint96 balance;
    address admin;
    uint64 maxValidBlocknumber;
    uint32 lastPerformedBlockNumber;
    uint96 amountSpent;
    bool paused;
    bytes offchainConfig;
  }

  /**
   * @notice relevant state of an upkeep which is used in transmit function
   * @member executeGas the gas limit of upkeep execution
   * @member maxValidBlocknumber until which block this upkeep is valid
   * @member forwarder the forwarder contract to use for this upkeep
   * @member paused if this upkeep has been paused
   * @member amountSpent the amount this upkeep has spent
   * @member balance the balance of this upkeep
   * @member lastPerformedBlockNumber the last block number when this upkeep was performed
   * @member target the contract which needs to be serviced
   */
  struct Upkeep {
    bool paused;
    uint32 executeGas;
    uint32 maxValidBlocknumber;
    AutomationForwarder forwarder;
    // 0 bytes left in 1st EVM word - not written to in transmit
    uint96 amountSpent;
    uint96 balance;
    uint32 lastPerformedBlockNumber;
    // 2 bytes left in 2nd EVM word - written in transmit path
    address target;
    // 12 bytes left in 3rd EVM word - neither written to nor read in transmit
  }

  // Config + State storage struct which is on hot transmit path
  struct HotVars {
    uint8 f; // maximum number of faulty oracles
    uint32 paymentPremiumPPB; // premium percentage charged to user over tx cost
    uint32 flatFeeMicroLink; // flat fee charged to user for every perform
    uint24 stalenessSeconds; // Staleness tolerance for feeds
    uint16 gasCeilingMultiplier; // multiplier on top of fast gas feed for upper bound
    bool paused; // pause switch for all upkeeps in the registry
    bool reentrancyGuard; // guard against reentrancy
    uint96 totalPremium; // total historical payment to oracles for premium
    uint32 latestEpoch; // latest epoch for which a report was transmitted
    // 1 EVM word full
  }

  // Config + State storage struct which is not on hot transmit path
  struct Storage {
    uint96 minUpkeepSpend; // Minimum amount an upkeep must spend
    address transcoder; // Address of transcoder contract used in migrations
    // 1 EVM word full
    uint96 ownerLinkBalance; // Balance of owner, accumulates minUpkeepSpend in case it is not spent
    uint32 checkGasLimit; // Gas limit allowed in checkUpkeep
    uint32 maxPerformGas; // Max gas an upkeep can use on this registry
    uint32 nonce; // Nonce for each upkeep created
    uint32 configCount; // incremented each time a new config is posted, The count
    // is incorporated into the config digest to prevent replay attacks.
    uint32 latestConfigBlockNumber; // makes it easier for offchain systems to extract config from logs
    // 2 EVM word full
    uint32 maxCheckDataSize; // max length of checkData bytes
    uint32 maxPerformDataSize; // max length of performData bytes
    uint32 maxRevertDataSize; // max length of revertData bytes
    address upkeepPrivilegeManager; // address which can set privilege for upkeeps
    // 3 EVM word full
  }

  // Report transmitted by OCR to transmit function
  struct Report {
    uint256 fastGasWei;
    uint256 linkNative;
    uint256[] upkeepIds;
    uint256[] gasLimits;
    bytes[] triggers;
    bytes[] performDatas;
  }

  /**
   * @dev This struct is used to maintain run time information about an upkeep in transmit function
   * @member upkeep the upkeep struct
   * @member earlyChecksPassed whether the upkeep passed early checks before perform
   * @member paymentParams the paymentParams for this upkeep
   * @member performSuccess whether the perform was successful
   * @member gasUsed gasUsed by this upkeep in perform
   */
  struct UpkeepTransmitInfo {
    Upkeep upkeep;
    bool earlyChecksPassed;
    uint96 maxLinkPayment;
    bool performSuccess;
    Trigger triggerType;
    uint256 gasUsed;
    uint256 gasOverhead;
  }

  struct Transmitter {
    bool active;
    uint8 index; // Index of oracle in s_signersList/s_transmittersList
    uint96 balance;
    uint96 lastCollected;
  }

  struct Signer {
    bool active;
    // Index of oracle in s_signersList/s_transmittersList
    uint8 index;
  }

  struct ConditionalTriggerConfig {
    uint32 checkCadance; // how often to check in blocks
  }

  /**
   * @notice structure of trigger for log triggers
   */
  struct LogTriggerConfig {
    address contractAddress;
    uint8 filterSelector; // denotes which topics apply to filter ex 000, 101, 111...only last 3 bits apply
    bytes32 topic0;
    bytes32 topic1;
    bytes32 topic2;
    bytes32 topic3;
  }

  /**
   * @notice the trigger structure conditional trigger type
   */
  struct ConditionalTrigger {
    uint32 blockNum;
    bytes32 blockHash;
  }

  /**
   * @notice the trigger structure of log upkeeps
   * @dev NOTE that blockNum / blockHash describe the block used for the callback,
   * not necessarily the block number that the log was emitted in!!!!
   */
  struct LogTrigger {
    bytes32 txHash;
    uint32 logIndex;
    uint32 blockNum;
    bytes32 blockHash;
  }

  event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
  event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
  event OwnerFundsWithdrawn(uint96 amount);
  event PayeesUpdated(address[] transmitters, address[] payees);
  event PayeeshipTransferRequested(address indexed transmitter, address indexed from, address indexed to);
  event PayeeshipTransferred(address indexed transmitter, address indexed from, address indexed to);
  event PaymentWithdrawn(address indexed transmitter, uint256 indexed amount, address indexed to, address payee);
  event UpkeepPrivilegeConfigSet(uint256 indexed id, bytes privilegeConfig);
  event UpkeepAdminTransferRequested(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepAdminTransferred(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
  event UpkeepCheckDataSet(uint256 indexed id, bytes newCheckData);
  event UpkeepGasLimitSet(uint256 indexed id, uint96 gasLimit);
  event UpkeepOffchainConfigSet(uint256 indexed id, bytes offchainConfig);
  event UpkeepTriggerConfigSet(uint256 indexed id, bytes triggerConfig);
  event UpkeepMigrated(uint256 indexed id, uint256 remainingBalance, address destination);
  event UpkeepPaused(uint256 indexed id);
  event UpkeepPerformed(
    uint256 indexed id,
    bool indexed success,
    uint96 totalPayment,
    uint256 gasUsed,
    uint256 gasOverhead,
    bytes trigger
  );
  event UpkeepReceived(uint256 indexed id, uint256 startingBalance, address importedFrom);
  event UpkeepUnpaused(uint256 indexed id);
  event UpkeepRegistered(uint256 indexed id, uint32 executeGas, address admin);
  event StaleUpkeepReport(uint256 indexed id, bytes trigger);
  event ReorgedUpkeepReport(uint256 indexed id, bytes trigger);
  event InsufficientFundsUpkeepReport(uint256 indexed id, bytes trigger);
  event CancelledUpkeepReport(uint256 indexed id, bytes trigger);
  event Paused(address account);
  event Unpaused(address account);

  /**
   * @param mode the contract mode of default, Arbitrum, or Optimism
   * @param link address of the LINK Token
   * @param linkNativeFeed address of the LINK/Native price feed
   * @param fastGasFeed address of the Fast Gas price feed
   */
  constructor(Mode mode, address link, address linkNativeFeed, address fastGasFeed) ConfirmedOwner(msg.sender) {
    i_mode = mode;
    i_link = LinkTokenInterface(link);
    i_linkNativeFeed = AggregatorV3Interface(linkNativeFeed);
    i_fastGasFeed = AggregatorV3Interface(fastGasFeed);
  }

  /////////////
  // GETTERS //
  /////////////

  function getMode() external view returns (Mode) {
    return i_mode;
  }

  function getLinkAddress() external view returns (address) {
    return address(i_link);
  }

  function getLinkNativeFeedAddress() external view returns (address) {
    return address(i_linkNativeFeed);
  }

  function getFastGasFeedAddress() external view returns (address) {
    return address(i_fastGasFeed);
  }

  //////////////
  // INTERNAL //
  //////////////

  /**
   * @notice creates a new upkeep with the given fields
   * @param id the id of the upkeep
   * @param upkeep the upkeep to create
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param checkData data which is passed to user's checkUpkeep
   * @param triggerConfig the trigger config for this upkeep
   * @param offchainConfig the off-chain config of this upkeep
   */
  function _createUpkeep(
    uint256 id,
    Upkeep memory upkeep,
    address admin,
    bytes memory checkData,
    bytes memory triggerConfig,
    bytes memory offchainConfig
  ) internal {
    if (s_hotVars.paused) revert RegistryPaused();
    if (!upkeep.target.isContract()) revert NotAContract();
    if (checkData.length > s_storage.maxCheckDataSize) revert CheckDataExceedsLimit();
    if (upkeep.executeGas < PERFORM_GAS_MIN || upkeep.executeGas > s_storage.maxPerformGas)
      revert GasLimitOutsideRange();
    if (s_upkeep[id].target != ZERO_ADDRESS) revert UpkeepAlreadyExists();
    s_upkeep[id] = upkeep;
    s_upkeepAdmin[id] = admin;
    s_checkData[id] = checkData;
    s_expectedLinkBalance = s_expectedLinkBalance + upkeep.balance;
    s_upkeepTriggerConfig[id] = triggerConfig;
    s_upkeepOffchainConfig[id] = offchainConfig;
    s_upkeepIDs.add(id);
  }

  /**
   * @dev retrieves feed data for fast gas/native and link/native prices. if the feed
   * data is stale it uses the configured fallback price. Once a price is picked
   * for gas it takes the min of gas price in the transaction or the fast gas
   * price in order to reduce costs for the upkeep clients.
   */
  function _getFeedData(HotVars memory hotVars) internal view returns (uint256 gasWei, uint256 linkNative) {
    uint32 stalenessSeconds = hotVars.stalenessSeconds;
    bool staleFallback = stalenessSeconds > 0;
    uint256 timestamp;
    int256 feedValue;
    (, feedValue, , timestamp, ) = i_fastGasFeed.latestRoundData();
    if (
      feedValue <= 0 || block.timestamp < timestamp || (staleFallback && stalenessSeconds < block.timestamp - timestamp)
    ) {
      gasWei = s_fallbackGasPrice;
    } else {
      gasWei = uint256(feedValue);
    }
    (, feedValue, , timestamp, ) = i_linkNativeFeed.latestRoundData();
    if (
      feedValue <= 0 || block.timestamp < timestamp || (staleFallback && stalenessSeconds < block.timestamp - timestamp)
    ) {
      linkNative = s_fallbackLinkPrice;
    } else {
      linkNative = uint256(feedValue);
    }
    return (gasWei, linkNative);
  }

  /**
   * @dev calculates LINK paid for gas spent plus a configure premium percentage
   * @param gasLimit the amount of gas used
   * @param gasOverhead the amount of gas overhead
   * @param fastGasWei the fast gas price
   * @param linkNative the exchange ratio between LINK and Native token
   * @param numBatchedUpkeeps the number of upkeeps in this batch. Used to divide the L1 cost
   * @param isExecution if this is triggered by a perform upkeep function
   */
  function _calculatePaymentAmount(
    HotVars memory hotVars,
    uint256 gasLimit,
    uint256 gasOverhead,
    uint256 fastGasWei,
    uint256 linkNative,
    uint16 numBatchedUpkeeps,
    bool isExecution
  ) internal view returns (uint96, uint96) {
    uint256 gasWei = fastGasWei * hotVars.gasCeilingMultiplier;
    // in case it's actual execution use actual gas price, capped by fastGasWei * gasCeilingMultiplier
    if (isExecution && tx.gasprice < gasWei) {
      gasWei = tx.gasprice;
    }

    uint256 l1CostWei = 0;
    if (i_mode == Mode.OPTIMISM) {
      bytes memory txCallData = new bytes(0);
      if (isExecution) {
        txCallData = bytes.concat(msg.data, L1_FEE_DATA_PADDING);
      } else {
        // @dev fee is 4 per 0 byte, 16 per non-zero byte. Worst case we can have
        // s_storage.maxPerformDataSize non zero-bytes. Instead of setting bytes to non-zero
        // we initialize 'new bytes' of length 4*maxPerformDataSize to cover for zero bytes.
        txCallData = new bytes(4 * s_storage.maxPerformDataSize);
      }
      l1CostWei = OPTIMISM_ORACLE.getL1Fee(txCallData);
    } else if (i_mode == Mode.ARBITRUM) {
      l1CostWei = ARB_NITRO_ORACLE.getCurrentTxL1GasFees();
    }
    // if it's not performing upkeeps, use gas ceiling multiplier to estimate the upper bound
    if (!isExecution) {
      l1CostWei = hotVars.gasCeilingMultiplier * l1CostWei;
    }
    // Divide l1CostWei among all batched upkeeps. Spare change from division is not charged
    l1CostWei = l1CostWei / numBatchedUpkeeps;

    uint256 gasPayment = ((gasWei * (gasLimit + gasOverhead) + l1CostWei) * 1e18) / linkNative;
    uint256 premium = (((gasWei * gasLimit) + l1CostWei) * 1e9 * hotVars.paymentPremiumPPB) /
      linkNative +
      uint256(hotVars.flatFeeMicroLink) *
      1e12;
    // LINK_TOTAL_SUPPLY < UINT96_MAX
    if (gasPayment + premium > LINK_TOTAL_SUPPLY) revert PaymentGreaterThanAllLINK();
    return (uint96(gasPayment), uint96(premium));
  }

  /**
   * @dev generates the max link payment for an upkeep
   */
  function _getMaxLinkPayment(
    HotVars memory hotVars,
    Trigger triggerType,
    uint32 executeGas,
    uint32 performDataLength,
    uint256 fastGasWei,
    uint256 linkNative,
    bool isExecution // Whether this is an actual perform execution or just a simulation
  ) internal view returns (uint96) {
    uint256 gasOverhead = _getMaxGasOverhead(triggerType, performDataLength, hotVars.f);
    (uint96 reimbursement, uint96 premium) = _calculatePaymentAmount(
      hotVars,
      executeGas,
      gasOverhead,
      fastGasWei,
      linkNative,
      1, // Consider only 1 upkeep in batch to get maxPayment
      isExecution
    );

    return reimbursement + premium;
  }

  /**
   * @dev returns the max gas overhead that can be charged for an upkeep
   */
  function _getMaxGasOverhead(Trigger triggerType, uint32 performDataLength, uint8 f) internal pure returns (uint256) {
    // performData causes additional overhead in report length and memory operations
    uint256 baseOverhead;
    if (triggerType == Trigger.CONDITION) {
      baseOverhead = REGISTRY_CONDITIONAL_OVERHEAD;
    } else if (triggerType == Trigger.LOG) {
      baseOverhead = REGISTRY_LOG_OVERHEAD;
    } else {
      revert InvalidTriggerType();
    }
    return
      baseOverhead +
      (REGISTRY_PER_SIGNER_GAS_OVERHEAD * (f + 1)) +
      (REGISTRY_PER_PERFORM_BYTE_GAS_OVERHEAD * performDataLength);
  }

  /**
   * @dev move a transmitter's balance from total pool to withdrawable balance
   */
  function _updateTransmitterBalanceFromPool(
    address transmitterAddress,
    uint96 totalPremium,
    uint96 payeeCount
  ) internal returns (uint96) {
    Transmitter memory transmitter = s_transmitters[transmitterAddress];

    if (transmitter.active) {
      uint96 uncollected = totalPremium - transmitter.lastCollected;
      uint96 due = uncollected / payeeCount;
      transmitter.balance += due;
      transmitter.lastCollected += due * payeeCount;
      s_transmitters[transmitterAddress] = transmitter;
    }

    return transmitter.balance;
  }

  function getTriggerType(uint256 upkeepId) public pure returns (Trigger) {
    bytes32 rawID = bytes32(upkeepId);
    bytes1 empty = bytes1(0);
    for (uint256 idx = 4; idx < 15; idx++) {
      if (rawID[idx] != empty) {
        // old IDs that were created before this standard and migrated to this registry
        return Trigger.CONDITION;
      }
    }
    return Trigger(uint8(rawID[15]));
  }

  /**
   * @dev ensures the upkeep is not cancelled and the caller is the upkeep admin
   */
  function _requireAdminAndNotCancelled(uint256 upkeepId) internal view {
    if (msg.sender != s_upkeepAdmin[upkeepId]) revert OnlyCallableByAdmin();
    if (s_upkeep[upkeepId].maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
  }

  /**
   * @notice returns the current block number in a chain agnostic manner
   */
  function _blockNum() internal view returns (uint256) {
    if (i_mode == Mode.ARBITRUM) {
      return ARB_SYS.arbBlockNumber();
    } else {
      return block.number;
    }
  }

  /**
   * @notice returns the blockhash of the provided block number in a chain agnostic manner
   * @param n the blocknumber to retrieve the blockhash for
   * @return blockhash the blockhash of block number n, or 0 if n is out queryable of range
   */
  function _blockHash(uint256 n) internal view returns (bytes32) {
    if (i_mode == Mode.ARBITRUM) {
      uint256 blockNum = ARB_SYS.arbBlockNumber();
      if (n >= blockNum || blockNum - n > 256) {
        return "";
      }
      return ARB_SYS.arbBlockHash(n);
    } else {
      return blockhash(n);
    }
  }

  /**
   * @notice replicates Open Zeppelin's ReentrancyGuard but optimized to fit our storage
   */
  modifier nonReentrant() {
    if (s_hotVars.reentrancyGuard) revert ReentrantCall();
    s_hotVars.reentrancyGuard = true;
    _;
    s_hotVars.reentrancyGuard = false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./KeeperRegistryBase2_1.sol";
import "./KeeperRegistryLogicB2_1.sol";
import "./Chainable.sol";
import {AutomationForwarder} from "./AutomationForwarder.sol";
import "../../../interfaces/automation/UpkeepTranscoderInterfaceV2.sol";

import "../../../interfaces/automation/MigratableKeeperRegistryInterface.sol";
import "../../../interfaces/automation/MigratableKeeperRegistryInterfaceV2.sol";

/**
 * @notice Logic contract, works in tandem with KeeperRegistry as a proxy
 */
contract KeeperRegistryLogicA2_1 is
  KeeperRegistryBase2_1,
  Chainable,
  MigratableKeeperRegistryInterface,
  MigratableKeeperRegistryInterfaceV2
{
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @param logicB the address of the second logic contract
   */
  constructor(
    KeeperRegistryLogicB2_1 logicB
  )
    KeeperRegistryBase2_1(
      logicB.getMode(),
      logicB.getLinkAddress(),
      logicB.getLinkNativeFeedAddress(),
      logicB.getFastGasFeedAddress()
    )
    Chainable(address(logicB))
  {}

  UpkeepFormat public constant override upkeepTranscoderVersion = UPKEEP_TRANSCODER_VERSION_BASE;

  uint8 public constant override upkeepVersion = UPKEEP_VERSION_BASE;

  /**
   * @dev this function will be deprecated in a future version of chainlink automation
   */
  function checkUpkeep(
    uint256 id
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 gasLimit,
      uint256 fastGasWei,
      uint256 linkNative
    )
  {
    return checkUpkeep(id, s_checkData[id]);
  }

  /**
   * @dev there is an incongruency on what gets returned during failure modes
   * ex sometimes we include price data, some times we omit it depending on the failure
   */
  function checkUpkeep(
    uint256 id,
    bytes memory checkData
  )
    public
    cannotExecute
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 gasLimit,
      uint256 fastGasWei,
      uint256 linkNative
    )
  {
    Trigger triggerType = getTriggerType(id);
    HotVars memory hotVars = s_hotVars;
    Upkeep memory upkeep = s_upkeep[id];

    if (hotVars.paused) return (false, bytes(""), UpkeepFailureReason.REGISTRY_PAUSED, 0, upkeep.executeGas, 0, 0);
    if (upkeep.maxValidBlocknumber != UINT32_MAX)
      return (false, bytes(""), UpkeepFailureReason.UPKEEP_CANCELLED, 0, upkeep.executeGas, 0, 0);
    if (upkeep.paused) return (false, bytes(""), UpkeepFailureReason.UPKEEP_PAUSED, 0, upkeep.executeGas, 0, 0);

    (fastGasWei, linkNative) = _getFeedData(hotVars);
    uint96 maxLinkPayment = _getMaxLinkPayment(
      hotVars,
      triggerType,
      upkeep.executeGas,
      s_storage.maxPerformDataSize,
      fastGasWei,
      linkNative,
      false
    );
    if (upkeep.balance < maxLinkPayment) {
      return (false, bytes(""), UpkeepFailureReason.INSUFFICIENT_BALANCE, 0, upkeep.executeGas, 0, 0);
    }

    bytes memory callData;
    if (triggerType == Trigger.CONDITION) {
      callData = abi.encodeWithSelector(CHECK_SELECTOR, checkData);
    } else {
      callData = bytes.concat(CHECK_LOG_SELECTOR, checkData);
    }
    gasUsed = gasleft();
    (bool success, bytes memory result) = upkeep.target.call{gas: s_storage.checkGasLimit}(callData);
    gasUsed = gasUsed - gasleft();

    if (!success) {
      // User's target check reverted. We capture the revert data here and pass it within performData
      if (result.length > s_storage.maxRevertDataSize) {
        return (
          false,
          bytes(""),
          UpkeepFailureReason.REVERT_DATA_EXCEEDS_LIMIT,
          gasUsed,
          upkeep.executeGas,
          fastGasWei,
          linkNative
        );
      }
      return (
        upkeepNeeded,
        result,
        UpkeepFailureReason.TARGET_CHECK_REVERTED,
        gasUsed,
        upkeep.executeGas,
        fastGasWei,
        linkNative
      );
    }

    (upkeepNeeded, performData) = abi.decode(result, (bool, bytes));
    if (!upkeepNeeded)
      return (
        false,
        bytes(""),
        UpkeepFailureReason.UPKEEP_NOT_NEEDED,
        gasUsed,
        upkeep.executeGas,
        fastGasWei,
        linkNative
      );

    if (performData.length > s_storage.maxPerformDataSize)
      return (
        false,
        bytes(""),
        UpkeepFailureReason.PERFORM_DATA_EXCEEDS_LIMIT,
        gasUsed,
        upkeep.executeGas,
        fastGasWei,
        linkNative
      );

    return (upkeepNeeded, performData, upkeepFailureReason, gasUsed, upkeep.executeGas, fastGasWei, linkNative);
  }

  /**
   * @dev core node calls this function to call user contracts' checkCallback functions with proper gas limit
   */
  function checkCallback(
    uint256 id,
    bytes[] memory values,
    bytes calldata extraData
  )
    external
    cannotExecute
    returns (bool upkeepNeeded, bytes memory performData, UpkeepFailureReason upkeepFailureReason, uint256 gasUsed)
  {
    bytes memory payload = abi.encodeWithSelector(CHECK_CALLBACK_SELECTOR, values, extraData);
    return executeCallback(id, payload);
  }

  /**
   * @dev this is a generic callback executor that forwards a call to a users contract with the configured
   * gas limit
   */
  function executeCallback(
    uint256 id,
    bytes memory payload
  )
    public
    cannotExecute
    returns (bool upkeepNeeded, bytes memory performData, UpkeepFailureReason upkeepFailureReason, uint256 gasUsed)
  {
    Upkeep memory upkeep = s_upkeep[id];

    gasUsed = gasleft();
    (bool success, bytes memory result) = upkeep.target.call{gas: s_storage.checkGasLimit}(payload);
    gasUsed = gasUsed - gasleft();

    if (!success) {
      return (false, bytes(""), UpkeepFailureReason.CALLBACK_REVERTED, gasUsed);
    }
    (upkeepNeeded, performData) = abi.decode(result, (bool, bytes));

    if (!upkeepNeeded) {
      return (false, bytes(""), UpkeepFailureReason.UPKEEP_NOT_NEEDED, gasUsed);
    }
    if (performData.length > s_storage.maxPerformDataSize) {
      return (false, bytes(""), UpkeepFailureReason.PERFORM_DATA_EXCEEDS_LIMIT, gasUsed);
    }

    return (upkeepNeeded, performData, upkeepFailureReason, gasUsed);
  }

  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    Trigger triggerType,
    bytes calldata checkData,
    bytes memory triggerConfig,
    bytes memory offchainConfig
  ) public returns (uint256 id) {
    if (msg.sender != owner() && !s_registrars.contains(msg.sender)) revert OnlyCallableByOwnerOrRegistrar();
    id = _createID(triggerType);
    AutomationForwarder forwarder = new AutomationForwarder(id, target, address(this));
    _createUpkeep(
      id,
      Upkeep({
        target: target,
        executeGas: gasLimit,
        balance: 0,
        maxValidBlocknumber: UINT32_MAX,
        lastPerformedBlockNumber: 0,
        amountSpent: 0,
        paused: false,
        forwarder: forwarder
      }),
      admin,
      checkData,
      triggerConfig,
      offchainConfig
    );
    s_storage.nonce++;
    emit UpkeepRegistered(id, gasLimit, admin);
    emit UpkeepCheckDataSet(id, checkData);
    emit UpkeepTriggerConfigSet(id, triggerConfig);
    emit UpkeepOffchainConfigSet(id, offchainConfig);
    return (id);
  }

  /**
   * this function registers a conditional upkeep, using a backwards compatible function signature
   * @dev this function is deprecated and will be removed in a future version of chainlink automation
   */
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id) {
    return
      registerUpkeep(
        target,
        gasLimit,
        admin,
        Trigger.CONDITION,
        checkData,
        abi.encode(ConditionalTriggerConfig({checkCadance: 1})),
        offchainConfig
      );
  }

  function addFunds(uint256 id, uint96 amount) external {
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();

    s_upkeep[id].balance = upkeep.balance + amount;
    s_expectedLinkBalance = s_expectedLinkBalance + amount;
    i_link.transferFrom(msg.sender, address(this), amount);
    emit FundsAdded(id, msg.sender, amount);
  }

  /**
   * @notice creates an ID for the upkeep based on the upkeep's type
   * @dev the format of the ID looks like this:
   * ****00000000000X****************
   * 4 bytes of entropy
   * 11 bytes of zeros
   * 1 identifying byte for the trigger type
   * 16 bytes of entropy
   * @dev this maintains the same level of entropy as eth addresses, so IDs will still be unique
   * @dev we add the "identifying" part in the middle so that it is mostly hidden from users who usually only
   * see the first 4 and last 4 hex values ex 0x1234...ABCD
   */
  function _createID(Trigger triggerType) private view returns (uint256) {
    bytes1 empty;
    bytes memory idBytes = abi.encodePacked(
      keccak256(abi.encode(_blockHash(_blockNum() - 1), address(this), s_storage.nonce))
    );
    for (uint256 idx = 4; idx < 15; idx++) {
      idBytes[idx] = empty;
    }
    idBytes[15] = bytes1(uint8(triggerType));
    return uint256(bytes32(idBytes));
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function cancelUpkeep(uint256 id) external {
    Upkeep memory upkeep = s_upkeep[id];
    bool canceled = upkeep.maxValidBlocknumber != UINT32_MAX;
    bool isOwner = msg.sender == owner();

    if (canceled && !(isOwner && upkeep.maxValidBlocknumber > _blockNum())) revert CannotCancel();
    if (!isOwner && msg.sender != s_upkeepAdmin[id]) revert OnlyCallableByOwnerOrAdmin();

    uint256 height = _blockNum();
    if (!isOwner) {
      height = height + CANCELLATION_DELAY;
    }
    s_upkeep[id].maxValidBlocknumber = uint32(height);
    s_upkeepIDs.remove(id);

    // charge the cancellation fee if the minUpkeepSpend is not met
    uint96 minUpkeepSpend = s_storage.minUpkeepSpend;
    uint96 cancellationFee = 0;
    // cancellationFee is supposed to be min(max(minUpkeepSpend - amountSpent,0), amountLeft)
    if (upkeep.amountSpent < minUpkeepSpend) {
      cancellationFee = minUpkeepSpend - upkeep.amountSpent;
      if (cancellationFee > upkeep.balance) {
        cancellationFee = upkeep.balance;
      }
    }
    s_upkeep[id].balance = upkeep.balance - cancellationFee;
    s_storage.ownerLinkBalance = s_storage.ownerLinkBalance + cancellationFee;

    emit UpkeepCanceled(id, uint64(height));
  }

  function setUpkeepTriggerConfig(uint256 id, bytes calldata triggerConfig) external {
    _requireAdminAndNotCancelled(id);
    s_upkeepTriggerConfig[id] = triggerConfig;
    emit UpkeepTriggerConfigSet(id, triggerConfig);
  }

  function migrateUpkeeps(
    uint256[] calldata ids,
    address destination
  ) external override(MigratableKeeperRegistryInterface, MigratableKeeperRegistryInterfaceV2) {
    if (
      s_peerRegistryMigrationPermission[destination] != MigrationPermission.OUTGOING &&
      s_peerRegistryMigrationPermission[destination] != MigrationPermission.BIDIRECTIONAL
    ) revert MigrationNotPermitted();
    if (s_storage.transcoder == ZERO_ADDRESS) revert TranscoderNotSet();
    if (ids.length == 0) revert ArrayHasNoEntries();
    uint256 id;
    Upkeep memory upkeep;
    uint256 totalBalanceRemaining;
    address[] memory admins = new address[](ids.length);
    Upkeep[] memory upkeeps = new Upkeep[](ids.length);
    bytes[] memory checkDatas = new bytes[](ids.length);
    bytes[] memory triggerConfigs = new bytes[](ids.length);
    bytes[] memory offchainConfigs = new bytes[](ids.length);
    for (uint256 idx = 0; idx < ids.length; idx++) {
      id = ids[idx];
      upkeep = s_upkeep[id];
      _requireAdminAndNotCancelled(id);
      upkeep.forwarder.updateRegistry(destination);
      upkeeps[idx] = upkeep;
      admins[idx] = s_upkeepAdmin[id];
      checkDatas[idx] = s_checkData[id];
      triggerConfigs[idx] = s_upkeepTriggerConfig[id];
      offchainConfigs[idx] = s_upkeepOffchainConfig[id];
      totalBalanceRemaining = totalBalanceRemaining + upkeep.balance;
      delete s_upkeep[id];
      delete s_checkData[id];
      delete s_upkeepTriggerConfig[id];
      delete s_upkeepOffchainConfig[id];
      // nullify existing proposed admin change if an upkeep is being migrated
      delete s_proposedAdmin[id];
      s_upkeepIDs.remove(id);
      emit UpkeepMigrated(id, upkeep.balance, destination);
    }
    s_expectedLinkBalance = s_expectedLinkBalance - totalBalanceRemaining;
    bytes memory encodedUpkeeps = abi.encode(ids, upkeeps, admins, checkDatas, triggerConfigs, offchainConfigs);
    MigratableKeeperRegistryInterfaceV2(destination).receiveUpkeeps(
      UpkeepTranscoderInterfaceV2(s_storage.transcoder).transcodeUpkeeps(
        UPKEEP_VERSION_BASE,
        MigratableKeeperRegistryInterfaceV2(destination).upkeepVersion(),
        encodedUpkeeps
      )
    );
    i_link.transfer(destination, totalBalanceRemaining);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function receiveUpkeeps(
    bytes calldata encodedUpkeeps
  ) external override(MigratableKeeperRegistryInterface, MigratableKeeperRegistryInterfaceV2) {
    if (
      s_peerRegistryMigrationPermission[msg.sender] != MigrationPermission.INCOMING &&
      s_peerRegistryMigrationPermission[msg.sender] != MigrationPermission.BIDIRECTIONAL
    ) revert MigrationNotPermitted();
    (
      uint256[] memory ids,
      Upkeep[] memory upkeeps,
      address[] memory upkeepAdmins,
      bytes[] memory checkDatas,
      bytes[] memory triggerConfigs,
      bytes[] memory offchainConfigs
    ) = abi.decode(encodedUpkeeps, (uint256[], Upkeep[], address[], bytes[], bytes[], bytes[]));
    for (uint256 idx = 0; idx < ids.length; idx++) {
      _createUpkeep(
        ids[idx],
        upkeeps[idx],
        upkeepAdmins[idx],
        checkDatas[idx],
        triggerConfigs[idx],
        offchainConfigs[idx]
      );
      emit UpkeepReceived(ids[idx], upkeeps[idx].balance, msg.sender);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./KeeperRegistryBase2_1.sol";

contract KeeperRegistryLogicB2_1 is KeeperRegistryBase2_1 {
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @dev see KeeperRegistry master contract for constructor description
   */
  constructor(
    Mode mode,
    address link,
    address linkNativeFeed,
    address fastGasFeed
  ) KeeperRegistryBase2_1(mode, link, linkNativeFeed, fastGasFeed) {}

  function transferPayeeship(address transmitter, address proposed) external {
    if (s_transmitterPayees[transmitter] != msg.sender) revert OnlyCallableByPayee();
    if (proposed == msg.sender) revert ValueNotChanged();

    if (s_proposedPayee[transmitter] != proposed) {
      s_proposedPayee[transmitter] = proposed;
      emit PayeeshipTransferRequested(transmitter, msg.sender, proposed);
    }
  }

  function acceptPayeeship(address transmitter) external {
    if (s_proposedPayee[transmitter] != msg.sender) revert OnlyCallableByProposedPayee();
    address past = s_transmitterPayees[transmitter];
    s_transmitterPayees[transmitter] = msg.sender;
    s_proposedPayee[transmitter] = ZERO_ADDRESS;

    emit PayeeshipTransferred(transmitter, past, msg.sender);
  }

  function transferUpkeepAdmin(uint256 id, address proposed) external {
    _requireAdminAndNotCancelled(id);
    if (proposed == msg.sender) revert ValueNotChanged();

    if (s_proposedAdmin[id] != proposed) {
      s_proposedAdmin[id] = proposed;
      emit UpkeepAdminTransferRequested(id, msg.sender, proposed);
    }
  }

  function acceptUpkeepAdmin(uint256 id) external {
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
    if (s_proposedAdmin[id] != msg.sender) revert OnlyCallableByProposedAdmin();
    address past = s_upkeepAdmin[id];
    s_upkeepAdmin[id] = msg.sender;
    s_proposedAdmin[id] = ZERO_ADDRESS;

    emit UpkeepAdminTransferred(id, past, msg.sender);
  }

  function pauseUpkeep(uint256 id) external {
    _requireAdminAndNotCancelled(id);
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.paused) revert OnlyUnpausedUpkeep();
    s_upkeep[id].paused = true;
    s_upkeepIDs.remove(id);
    emit UpkeepPaused(id);
  }

  function unpauseUpkeep(uint256 id) external {
    _requireAdminAndNotCancelled(id);
    Upkeep memory upkeep = s_upkeep[id];
    if (!upkeep.paused) revert OnlyPausedUpkeep();
    s_upkeep[id].paused = false;
    s_upkeepIDs.add(id);
    emit UpkeepUnpaused(id);
  }

  function setUpkeepCheckData(uint256 id, bytes calldata newCheckData) external {
    _requireAdminAndNotCancelled(id);
    if (newCheckData.length > s_storage.maxCheckDataSize) revert CheckDataExceedsLimit();
    s_checkData[id] = newCheckData;
    emit UpkeepCheckDataSet(id, newCheckData);
  }

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external {
    if (gasLimit < PERFORM_GAS_MIN || gasLimit > s_storage.maxPerformGas) revert GasLimitOutsideRange();
    _requireAdminAndNotCancelled(id);
    s_upkeep[id].executeGas = gasLimit;

    emit UpkeepGasLimitSet(id, gasLimit);
  }

  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external {
    _requireAdminAndNotCancelled(id);
    s_upkeepOffchainConfig[id] = config;
    emit UpkeepOffchainConfigSet(id, config);
  }

  function withdrawFunds(uint256 id, address to) external nonReentrant {
    if (to == ZERO_ADDRESS) revert InvalidRecipient();
    Upkeep memory upkeep = s_upkeep[id];
    if (s_upkeepAdmin[id] != msg.sender) revert OnlyCallableByAdmin();
    if (upkeep.maxValidBlocknumber > _blockNum()) revert UpkeepNotCanceled();

    uint96 amountToWithdraw = s_upkeep[id].balance;
    s_expectedLinkBalance = s_expectedLinkBalance - amountToWithdraw;
    s_upkeep[id].balance = 0;
    i_link.transfer(to, amountToWithdraw);
    emit FundsWithdrawn(id, amountToWithdraw, to);
  }

  function withdrawPayment(address from, address to) external {
    if (to == ZERO_ADDRESS) revert InvalidRecipient();
    if (s_transmitterPayees[from] != msg.sender) revert OnlyCallableByPayee();

    uint96 balance = _updateTransmitterBalanceFromPool(from, s_hotVars.totalPremium, uint96(s_transmittersList.length));
    s_transmitters[from].balance = 0;
    s_expectedLinkBalance = s_expectedLinkBalance - balance;

    i_link.transfer(to, balance);

    emit PaymentWithdrawn(from, balance, to, msg.sender);
  }

  ///////////////////
  // OWNER ACTIONS //
  ///////////////////

  function withdrawOwnerFunds() external onlyOwner {
    uint96 amount = s_storage.ownerLinkBalance;

    s_expectedLinkBalance = s_expectedLinkBalance - amount;
    s_storage.ownerLinkBalance = 0;

    emit OwnerFundsWithdrawn(amount);
    i_link.transfer(msg.sender, amount);
  }

  function recoverFunds() external onlyOwner {
    uint256 total = i_link.balanceOf(address(this));
    i_link.transfer(msg.sender, total - s_expectedLinkBalance);
  }

  function setPayees(address[] calldata payees) external onlyOwner {
    if (s_transmittersList.length != payees.length) revert ParameterLengthError();
    for (uint256 i = 0; i < s_transmittersList.length; i++) {
      address transmitter = s_transmittersList[i];
      address oldPayee = s_transmitterPayees[transmitter];
      address newPayee = payees[i];
      if (
        (newPayee == ZERO_ADDRESS) || (oldPayee != ZERO_ADDRESS && oldPayee != newPayee && newPayee != IGNORE_ADDRESS)
      ) revert InvalidPayee();
      if (newPayee != IGNORE_ADDRESS) {
        s_transmitterPayees[transmitter] = newPayee;
      }
    }
    emit PayeesUpdated(s_transmittersList, payees);
  }

  function pause() external onlyOwner {
    s_hotVars.paused = true;

    emit Paused(msg.sender);
  }

  function unpause() external onlyOwner {
    s_hotVars.paused = false;

    emit Unpaused(msg.sender);
  }

  function setPeerRegistryMigrationPermission(address peer, MigrationPermission permission) external onlyOwner {
    s_peerRegistryMigrationPermission[peer] = permission;
  }

  function setUpkeepPrivilegeConfig(uint256 upkeepId, bytes calldata newPrivilegeConfig) external {
    if (msg.sender != s_storage.upkeepPrivilegeManager) {
      revert OnlyCallableByUpkeepPrivilegeManager();
    }
    s_upkeepPrivilegeConfig[upkeepId] = newPrivilegeConfig;
    emit UpkeepPrivilegeConfigSet(upkeepId, newPrivilegeConfig);
  }

  /////////////
  // GETTERS //
  /////////////

  /**
   * @notice read all of the details about an upkeep
   * @dev this function may be deprecated in a future version of automation in favor of individual
   * getters for each field
   */
  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo) {
    Upkeep memory reg = s_upkeep[id];
    upkeepInfo = UpkeepInfo({
      target: reg.target,
      forwarder: address(reg.forwarder),
      executeGas: reg.executeGas,
      checkData: s_checkData[id],
      balance: reg.balance,
      admin: s_upkeepAdmin[id],
      maxValidBlocknumber: reg.maxValidBlocknumber,
      lastPerformedBlockNumber: reg.lastPerformedBlockNumber,
      amountSpent: reg.amountSpent,
      paused: reg.paused,
      offchainConfig: s_upkeepOffchainConfig[id]
    });
    return upkeepInfo;
  }

  /**
   * @notice retrieve active upkeep IDs. Active upkeep is defined as an upkeep which is not paused and not canceled.
   * @param startIndex starting index in list
   * @param endIndex end index. non-inclusive
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   * @dev this function will not error if an endIndex is provided that is too large, instead, it will resolve gracefully
   * by supplying as many results as it can within the bounds of the upkeep set
   */
  function getActiveUpkeepIDs(uint256 startIndex, uint256 endIndex) external view returns (uint256[] memory) {
    uint256 maxIndex = s_upkeepIDs.length();
    endIndex = endIndex > maxIndex ? maxIndex : endIndex;
    if (startIndex > endIndex) revert IndexOutOfRange();
    uint256 count = endIndex - startIndex;
    uint256[] memory ids = new uint256[](count);
    for (uint256 idx = 0; idx < count; idx++) {
      ids[idx] = s_upkeepIDs.at(idx + startIndex);
    }
    return ids;
  }

  /**
   * @notice retrieve active upkeep IDs within the range, filtered by the provided type
   * @param startIndex starting index in list
   * @param endIndex end index. non-inclusive
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   * @dev this function will not error if an endIndex is provided that is too large, instead, it will resolve gracefully
   * by supplying as many results as it can within the bounds of the upkeep set
   */
  function getActiveUpkeepIDsByType(
    uint256 startIndex,
    uint256 endIndex,
    Trigger trigger
  ) external view returns (uint256[] memory) {
    uint256 maxIndex = s_upkeepIDs.length();
    endIndex = endIndex > maxIndex ? maxIndex : endIndex;
    if (startIndex > endIndex) revert IndexOutOfRange();
    uint256 maxCount = endIndex - startIndex;
    uint256 numFound;
    uint256[] memory ids = new uint256[](maxCount);
    for (uint256 idx = 0; idx < maxCount; idx++) {
      uint256 id = s_upkeepIDs.at(idx + startIndex);
      if (getTriggerType(id) == trigger) {
        ids[numFound] = id;
        numFound++;
      }
    }
    if (numFound != maxCount) {
      assembly {
        mstore(ids, numFound)
      }
    }
    return ids;
  }

  function getUpkeepTriggerConfig(uint256 upkeepId) public view returns (bytes memory) {
    return s_upkeepTriggerConfig[upkeepId];
  }

  function getLogTriggerConfig(uint256 upkeepId) public view returns (LogTriggerConfig memory) {
    require(getTriggerType(upkeepId) == Trigger.LOG);
    return abi.decode(s_upkeepTriggerConfig[upkeepId], (LogTriggerConfig));
  }

  function getConditionalTriggerConfig(uint256 upkeepId) public view returns (ConditionalTriggerConfig memory) {
    require(getTriggerType(upkeepId) == Trigger.LOG);
    return abi.decode(s_upkeepTriggerConfig[upkeepId], (ConditionalTriggerConfig));
  }

  /**
   * @notice read the current info about any transmitter address
   */
  function getTransmitterInfo(
    address query
  ) external view returns (bool active, uint8 index, uint96 balance, uint96 lastCollected, address payee) {
    Transmitter memory transmitter = s_transmitters[query];

    uint96 pooledShare = 0;
    if (transmitter.active) {
      uint96 totalDifference = s_hotVars.totalPremium - transmitter.lastCollected;
      pooledShare = totalDifference / uint96(s_transmittersList.length);
    }

    return (
      transmitter.active,
      transmitter.index,
      (transmitter.balance + pooledShare),
      transmitter.lastCollected,
      s_transmitterPayees[query]
    );
  }

  /**
   * @notice read the current info about any signer address
   */
  function getSignerInfo(address query) external view returns (bool active, uint8 index) {
    Signer memory signer = s_signers[query];
    return (signer.active, signer.index);
  }

  /**
   * @notice read the current state of the registry
   */
  function getState()
    external
    view
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    )
  {
    state = State({
      nonce: s_storage.nonce,
      ownerLinkBalance: s_storage.ownerLinkBalance,
      expectedLinkBalance: s_expectedLinkBalance,
      totalPremium: s_hotVars.totalPremium,
      numUpkeeps: s_upkeepIDs.length(),
      configCount: s_storage.configCount,
      latestConfigBlockNumber: s_storage.latestConfigBlockNumber,
      latestConfigDigest: s_latestConfigDigest,
      latestEpoch: s_hotVars.latestEpoch,
      paused: s_hotVars.paused
    });

    config = OnchainConfig({
      paymentPremiumPPB: s_hotVars.paymentPremiumPPB,
      flatFeeMicroLink: s_hotVars.flatFeeMicroLink,
      checkGasLimit: s_storage.checkGasLimit,
      stalenessSeconds: s_hotVars.stalenessSeconds,
      gasCeilingMultiplier: s_hotVars.gasCeilingMultiplier,
      minUpkeepSpend: s_storage.minUpkeepSpend,
      maxPerformGas: s_storage.maxPerformGas,
      maxCheckDataSize: s_storage.maxCheckDataSize,
      maxPerformDataSize: s_storage.maxPerformDataSize,
      maxRevertDataSize: s_storage.maxRevertDataSize,
      fallbackGasPrice: s_fallbackGasPrice,
      fallbackLinkPrice: s_fallbackLinkPrice,
      transcoder: s_storage.transcoder,
      registrars: s_registrars.values(),
      upkeepPrivilegeManager: s_storage.upkeepPrivilegeManager
    });

    return (state, config, s_signersList, s_transmittersList, s_hotVars.f);
  }

  /**
   * @notice calculates the minimum balance required for an upkeep to remain eligible
   * @param id the upkeep id to calculate minimum balance for
   */
  function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance) {
    return getMaxPaymentForGas(getTriggerType(id), s_upkeep[id].executeGas);
  }

  /**
   * @notice calculates the maximum payment for a given gas limit
   * @param gasLimit the gas to calculate payment for
   */
  function getMaxPaymentForGas(Trigger triggerType, uint32 gasLimit) public view returns (uint96 maxPayment) {
    HotVars memory hotVars = s_hotVars;
    (uint256 fastGasWei, uint256 linkNative) = _getFeedData(hotVars);
    return
      _getMaxLinkPayment(hotVars, triggerType, gasLimit, s_storage.maxPerformDataSize, fastGasWei, linkNative, false);
  }

  /**
   * @notice retrieves the migration permission for a peer registry
   */
  function getPeerRegistryMigrationPermission(address peer) external view returns (MigrationPermission) {
    return s_peerRegistryMigrationPermission[peer];
  }

  /**
   * @notice returns the upkeep privilege config
   */
  function getUpkeepPrivilegeConfig(uint256 upkeepId) external view returns (bytes memory) {
    return s_upkeepPrivilegeConfig[upkeepId];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ILogAutomation, Log} from "../2_1/interfaces/ILogAutomation.sol";
import "../2_1/interfaces/FeedLookupCompatibleInterface.sol";
import {ArbSys} from "../../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";

interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier.
   * @param signedReport The encoded data to be verified.
   * @return verifierResponse The encoded response from the verifier.
   */
  function verify(bytes memory signedReport) external returns (bytes memory verifierResponse);
}

struct LogTriggerConfig {
  address contractAddress;
  uint8 filterSelector; // denotes which topics apply to filter ex 000, 101, 111...only last 3 bits apply
  bytes32 topic0;
  bytes32 topic1;
  bytes32 topic2;
  bytes32 topic3;
}

contract LogTriggeredFeedLookup is ILogAutomation, FeedLookupCompatibleInterface {
  event PerformingLogTriggerUpkeep(
    address indexed from,
    uint256 orderId,
    uint256 amount,
    address exchange,
    uint256 blockNumber,
    bytes blob,
    bytes verified
  );

  ArbSys internal constant ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064);
  IVerifierProxy internal constant VERIFIER = IVerifierProxy(0xa4D813064dc6E2eFfaCe02a060324626d4C5667f);

  // for log trigger
  bytes32 constant sentSig = 0x3e9c37b3143f2eb7e9a2a0f8091b6de097b62efcfe48e1f68847a832e521750a;
  bytes32 constant withdrawnSig = 0x0a71b8ed921ff64d49e4d39449f8a21094f38a0aeae489c3051aedd63f2c229f;
  bytes32 constant executedSig = 0xd1ffe9e45581c11d7d9f2ed5f75217cd4be9f8b7eee6af0f6d03f46de53956cd;

  // for mercury config
  bool public useArbitrumBlockNum;
  string[] public feedsHex = ["0x4554482d5553442d415242495452554d2d544553544e45540000000000000000"];
  string public constant feedParamKey = "feedIdHex";
  string public constant timeParamKey = "blockNumber";

  constructor(bool _useArbitrumBlockNum) {
    useArbitrumBlockNum = _useArbitrumBlockNum;
  }

  function setFeedsHex(string[] memory newFeeds) external {
    feedsHex = newFeeds;
  }

  function checkLog(Log calldata log) external override returns (bool upkeepNeeded, bytes memory performData) {
    uint256 blockNum = getBlockNumber();

    // filter by event signature
    if (log.topics[0] == executedSig) {
      // filter by indexed parameters
      bytes memory t1 = abi.encodePacked(log.topics[1]); // bytes32 to bytes
      uint256 orderId = abi.decode(t1, (uint256));
      bytes memory t2 = abi.encodePacked(log.topics[2]);
      uint256 amount = abi.decode(t2, (uint256));
      bytes memory t3 = abi.encodePacked(log.topics[3]);
      address exchange = abi.decode(t3, (address));

      revert FeedLookup(feedParamKey, feedsHex, timeParamKey, blockNum, abi.encodePacked(orderId, amount, exchange));
    }
    revert("could not find matching event sig");
  }

  function performUpkeep(bytes calldata performData) external override {
    (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
    (uint256 orderId, uint256 amount, address exchange) = abi.decode(extraData, (uint256, uint256, address));

    bytes memory verifiedResponse; // = VERIFIER.verify(values[0]);

    emit PerformingLogTriggerUpkeep(
      tx.origin,
      orderId,
      amount,
      exchange,
      getBlockNumber(),
      values[0],
      verifiedResponse
    );
  }

  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external view override returns (bool upkeepNeeded, bytes memory performData) {
    // do sth about the chainlinkBlob data in values and extraData
    bytes memory performData = abi.encode(values, extraData);
    return (true, performData);
  }

  function getBlockNumber() internal view returns (uint256) {
    if (useArbitrumBlockNum) {
      return ARB_SYS.arbBlockNumber();
    } else {
      return block.number;
    }
  }

  function getBasicLogTriggerConfig(address targetContract) external view returns (bytes memory logTrigger) {
    LogTriggerConfig memory cfg = LogTriggerConfig({
      contractAddress: targetContract,
      filterSelector: 0, // not applying any filter, if 1, it will check topic1, if 3, it will check both topic1 and topic2, if 5, it will check both topic1 and topic3
      topic0: executedSig, // only triggerSig will be available at `checkLog` this will always apply
      topic1: 0x000000000000000000000000000000000000000000000000000000000000000,
      topic2: 0x000000000000000000000000000000000000000000000000000000000000000,
      topic3: 0x000000000000000000000000000000000000000000000000000000000000000
    });
    return abi.encode(cfg);
  }

  function getAdvancedLogTriggerConfig(
    address targetContract,
    uint8 selector,
    bytes32 topic0,
    bytes32 topic1,
    bytes32 topic2
  ) external view returns (bytes memory logTrigger) {
    LogTriggerConfig memory cfg = LogTriggerConfig({
      contractAddress: targetContract,
      filterSelector: selector, // not applying any filter, if 1, it will check topic1, if 3, it will check both topic1 and topic2, if 5, it will check both topic1 and topic3
      topic0: topic0,
      topic1: topic1,
      topic2: topic2,
      topic3: 0x000000000000000000000000000000000000000000000000000000000000000
    });
    return abi.encode(cfg);
  }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../automation/UpkeepFormat.sol";

interface MigratableKeeperRegistryInterface {
  /**
   * @notice Migrates upkeeps from one registry to another, including LINK and upkeep params.
   * Only callable by the upkeep admin. All upkeeps must have the same admin. Can only migrate active upkeeps.
   * @param upkeepIDs ids of upkeeps to migrate
   * @param destination the address of the registry to migrate to
   */
  function migrateUpkeeps(uint256[] calldata upkeepIDs, address destination) external;

  /**
   * @notice Called by other registries when migrating upkeeps. Only callable by other registries.
   * @param encodedUpkeeps abi encoding of upkeeps to import - decoded by the transcoder
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps) external;

  /**
   * @notice Specifies the version of upkeep data that this registry requires in order to import
   */
  function upkeepTranscoderVersion() external returns (UpkeepFormat version);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../automation/UpkeepFormat.sol";

interface MigratableKeeperRegistryInterfaceV2 {
  /**
   * @notice Migrates upkeeps from one registry to another, including LINK and upkeep params.
   * Only callable by the upkeep admin. All upkeeps must have the same admin. Can only migrate active upkeeps.
   * @param upkeepIDs ids of upkeeps to migrate
   * @param destination the address of the registry to migrate to
   */
  function migrateUpkeeps(uint256[] calldata upkeepIDs, address destination) external;

  /**
   * @notice Called by other registries when migrating upkeeps. Only callable by other registries.
   * @param encodedUpkeeps abi encoding of upkeeps to import - decoded by the transcoder
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps) external;

  /**
   * @notice Specifies the version of upkeep data that this registry requires in order to import
   */
  function upkeepVersion() external returns (uint8 version);
}

// SPDX-License-Identifier: MIT

import "../../automation/UpkeepFormat.sol";

pragma solidity ^0.8.0;

interface UpkeepTranscoderInterface {
  function transcodeUpkeeps(
    UpkeepFormat fromVersion,
    UpkeepFormat toVersion,
    bytes calldata encodedUpkeeps
  ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface UpkeepTranscoderInterfaceV2 {
  function transcodeUpkeeps(
    uint8 fromVersion,
    uint8 toVersion,
    bytes calldata encodedUpkeeps
  ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ERC677ReceiverInterface {
  function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
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
pragma solidity ^0.8.0;

import "./interfaces/TypeAndVersionInterface.sol";

abstract contract OCR2Abstract is TypeAndVersionInterface {
  // Maximum number of oracles the offchain reporting protocol is designed for
  uint256 internal constant maxNumOracles = 31;
  uint256 private constant prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
  uint256 private constant prefix = 0x0001 << (256 - 16); // 0x000100..00

  /**
   * @notice triggers a new run of the offchain reporting protocol
   * @param previousConfigBlockNumber block in which the previous config was set, to simplify historic analysis
   * @param configDigest configDigest of this configuration
   * @param configCount ordinal number of this config setting among all config settings over the life of this contract
   * @param signers ith element is address ith oracle uses to sign a report
   * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
   * @param f maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version of the serialization format used for "offchainConfig" parameter
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   */
  event ConfigSet(
    uint32 previousConfigBlockNumber,
    bytes32 configDigest,
    uint64 configCount,
    address[] signers,
    address[] transmitters,
    uint8 f,
    bytes onchainConfig,
    uint64 offchainConfigVersion,
    bytes offchainConfig
  );

  /**
   * @notice sets offchain reporting protocol configuration incl. participating oracles
   * @param signers addresses with which oracles sign the reports
   * @param transmitters addresses oracles use to transmit the reports
   * @param f number of faulty oracles the system can tolerate
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version number for offchainEncoding schema
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   */
  function setConfig(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) external virtual;

  /**
   * @notice information about current offchain reporting protocol configuration
   * @return configCount ordinal number of current config, out of all configs applied to this contract so far
   * @return blockNumber block at which this config was set
   * @return configDigest domain-separation tag for current config (see _configDigestFromConfigData)
   */
  function latestConfigDetails()
    external
    view
    virtual
    returns (uint32 configCount, uint32 blockNumber, bytes32 configDigest);

  function _configDigestFromConfigData(
    uint256 chainId,
    address contractAddress,
    uint64 configCount,
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) internal pure returns (bytes32) {
    uint256 h = uint256(
      keccak256(
        abi.encode(
          chainId,
          contractAddress,
          configCount,
          signers,
          transmitters,
          f,
          onchainConfig,
          offchainConfigVersion,
          offchainConfig
        )
      )
    );
    return bytes32((prefix & prefixMask) | (h & ~prefixMask));
  }

  /**
  * @notice optionally emited to indicate the latest configDigest and epoch for
     which a report was successfully transmited. Alternatively, the contract may
     use latestConfigDigestAndEpoch with scanLogs set to false.
  */
  event Transmitted(bytes32 configDigest, uint32 epoch);

  /**
   * @notice optionally returns the latest configDigest and epoch for which a
     report was successfully transmitted. Alternatively, the contract may return
     scanLogs set to true and use Transmitted events to provide this information
     to offchain watchers.
   * @return scanLogs indicates whether to rely on the configDigest and epoch
     returned or whether to scan logs for the Transmitted event instead.
   * @return configDigest
   * @return epoch
   */
  function latestConfigDigestAndEpoch()
    external
    view
    virtual
    returns (bool scanLogs, bytes32 configDigest, uint32 epoch);

  /**
   * @notice transmit is called to post a new report to the contract
   * @param reportContext [0]: ConfigDigest, [1]: 27 byte padding, 4-byte epoch and 1-byte round, [2]: ExtraHash
   * @param report serialized report, which the signatures are signing.
   * @param rs ith element is the R components of the ith signature on report. Must have at most maxNumOracles entries
   * @param ss ith element is the S components of the ith signature on report. Must have at most maxNumOracles entries
   * @param rawVs ith element is the the V component of the ith signature
   */
  function transmit(
    // NOTE: If these parameters are changed, expectedMsgDataLength and/or
    // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
    bytes32[3] calldata reportContext,
    bytes calldata report,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs // signatures
  ) external virtual;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

interface ArbGasInfo {
    // return gas prices in wei, assuming the specified aggregator is used
    //        (
    //            per L2 tx,
    //            per L1 calldata unit, (zero byte = 4 units, nonzero byte = 16 units)
    //            per storage allocation,
    //            per ArbGas base,
    //            per ArbGas congestion,
    //            per ArbGas total
    //        )
    function getPricesInWeiWithAggregator(address aggregator) external view returns (uint, uint, uint, uint, uint, uint);

    // return gas prices in wei, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInWei() external view returns (uint, uint, uint, uint, uint, uint);

    // return prices in ArbGas (per L2 tx, per L1 calldata unit, per storage allocation),
    //       assuming the specified aggregator is used
    function getPricesInArbGasWithAggregator(address aggregator) external view returns (uint, uint, uint);

    // return gas prices in ArbGas, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInArbGas() external view returns (uint, uint, uint);

    // return gas accounting parameters (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams() external view returns (uint, uint, uint);

    // get ArbOS's estimate of the L1 gas price in wei
    function getL1GasPriceEstimate() external view returns(uint);

    // set ArbOS's estimate of the L1 gas price in wei
    // reverts unless called by chain owner or designated gas oracle (if any)
    function setL1GasPriceEstimate(uint priceInWei) external;

    // get L1 gas fees paid by the current transaction (txBaseFeeWei, calldataFeeWei)
    function getCurrentTxL1GasFees() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* External Imports */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OVM_GasPriceOracle
 * @dev This contract exposes the current l2 gas price, a measure of how congested the network
 * currently is. This measure is used by the Sequencer to determine what fee to charge for
 * transactions. When the system is more congested, the l2 gas price will increase and fees
 * will also increase as a result.
 *
 * All public variables are set while generating the initial L2 state. The
 * constructor doesn't run in practice as the L2 state generation script uses
 * the deployed bytecode instead of running the initcode.
 */
contract OVM_GasPriceOracle is Ownable {
  /*************
   * Variables *
   *************/

  // Current L2 gas price
  uint256 public gasPrice;
  // Current L1 base fee
  uint256 public l1BaseFee;
  // Amortized cost of batch submission per transaction
  uint256 public overhead;
  // Value to scale the fee up by
  uint256 public scalar;
  // Number of decimals of the scalar
  uint256 public decimals;

  /***************
   * Constructor *
   ***************/

  /**
   * @param _owner Address that will initially own this contract.
   */
  constructor(address _owner) Ownable() {
    transferOwnership(_owner);
  }

  /**********
   * Events *
   **********/

  event GasPriceUpdated(uint256);
  event L1BaseFeeUpdated(uint256);
  event OverheadUpdated(uint256);
  event ScalarUpdated(uint256);
  event DecimalsUpdated(uint256);

  /********************
   * Public Functions *
   ********************/

  /**
   * Allows the owner to modify the l2 gas price.
   * @param _gasPrice New l2 gas price.
   */
  // slither-disable-next-line external-function
  function setGasPrice(uint256 _gasPrice) public onlyOwner {
    gasPrice = _gasPrice;
    emit GasPriceUpdated(_gasPrice);
  }

  /**
   * Allows the owner to modify the l1 base fee.
   * @param _baseFee New l1 base fee
   */
  // slither-disable-next-line external-function
  function setL1BaseFee(uint256 _baseFee) public onlyOwner {
    l1BaseFee = _baseFee;
    emit L1BaseFeeUpdated(_baseFee);
  }

  /**
   * Allows the owner to modify the overhead.
   * @param _overhead New overhead
   */
  // slither-disable-next-line external-function
  function setOverhead(uint256 _overhead) public onlyOwner {
    overhead = _overhead;
    emit OverheadUpdated(_overhead);
  }

  /**
   * Allows the owner to modify the scalar.
   * @param _scalar New scalar
   */
  // slither-disable-next-line external-function
  function setScalar(uint256 _scalar) public onlyOwner {
    scalar = _scalar;
    emit ScalarUpdated(_scalar);
  }

  /**
   * Allows the owner to modify the decimals.
   * @param _decimals New decimals
   */
  // slither-disable-next-line external-function
  function setDecimals(uint256 _decimals) public onlyOwner {
    decimals = _decimals;
    emit DecimalsUpdated(_decimals);
  }

  /**
   * Computes the L1 portion of the fee
   * based on the size of the RLP encoded tx
   * and the current l1BaseFee
   * @param _data Unsigned RLP encoded tx, 6 elements
   * @return L1 fee that should be paid for the tx
   */
  // slither-disable-next-line external-function
  function getL1Fee(bytes memory _data) public view returns (uint256) {
    uint256 l1GasUsed = getL1GasUsed(_data);
    uint256 l1Fee = l1GasUsed * l1BaseFee;
    uint256 divisor = 10 ** decimals;
    uint256 unscaled = l1Fee * scalar;
    uint256 scaled = unscaled / divisor;
    return scaled;
  }

  // solhint-disable max-line-length
  /**
   * Computes the amount of L1 gas used for a transaction
   * The overhead represents the per batch gas overhead of
   * posting both transaction and state roots to L1 given larger
   * batch sizes.
   * 4 gas for 0 byte
   * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L33
   * 16 gas for non zero byte
   * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L87
   * This will need to be updated if calldata gas prices change
   * Account for the transaction being unsigned
   * Padding is added to account for lack of signature on transaction
   * 1 byte for RLP V prefix
   * 1 byte for V
   * 1 byte for RLP R prefix
   * 32 bytes for R
   * 1 byte for RLP S prefix
   * 32 bytes for S
   * Total: 68 bytes of padding
   * @param _data Unsigned RLP encoded tx, 6 elements
   * @return Amount of L1 gas used for a transaction
   */
  // solhint-enable max-line-length
  function getL1GasUsed(bytes memory _data) public view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < _data.length; i++) {
      if (_data[i] == 0) {
        total += 4;
      } else {
        total += 16;
      }
    }
    uint256 unsigned = total + overhead;
    return unsigned + (68 * 16);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}