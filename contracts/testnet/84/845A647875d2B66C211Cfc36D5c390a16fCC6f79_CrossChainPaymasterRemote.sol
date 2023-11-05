// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
pragma solidity ^0.8.13;

import "./lzApp/NonblockingLzApp.sol";
import "./RNS.sol";
import "./CrossChainPaymasterRemote.sol";

/**
 * @title CrossChainPaymaster
 *
 * A Paymaster that coordinates with a paymaster on a remote chain to pay for a user's transaction.
 * The user does not require a balance on the remote chain. The user will pay for the remote chain
 * transaction on the local chain.
 */
contract CrossChainPaymaster is NonblockingLzApp {
    //LayerZero chain ID for ZKSync Era Goerli Testnet
    uint16 LOCAL_CHAIN_ID = 10165;
    bytes32 constant REQUEST = keccak256("\x01\x02\x03\x04");
    bytes32 constant RESPONSE = keccak256("\x05\x06\x07\x08");

    event Gas(string label, uint256 gasUnits);

    struct Balance {
        address lender;
        uint256 amount;
        bool refundFailed;
    }

    mapping(address => mapping(uint16 => Balance)) public balances;
    RNS rns;

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    function setRns(address _rnsContract) public {
        rns = RNS(_rnsContract);
    }

    //REMIX LOGIC STARTS
    CrossChainPaymasterRemote crossChainPaymasterRemote;
    function setCrossChainPaymasterRemote(address payable _crossChainPaymasterRemote) public {
        crossChainPaymasterRemote = CrossChainPaymasterRemote(_crossChainPaymasterRemote);
    }

    function fakeLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public {
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
    //REMIX LOGIC ENDS

    /**
     * Overriding LayerZero app function. Receive message from a remote chain identified by chain ID.
     *
     * @param _srcChainId The LayerZero chain ID of the network the message was sent from.
     * @param _payload The encoded data of the message. This contains the domain name to confirm
     * and the source address.
     */
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        //Decode the message type from the payload.
        bytes memory messageType = abi.decode(_payload, (bytes));

        //Hash the message type for comparison.
        bytes32 messageTypeHash = keccak256(messageType);
        require(messageTypeHash == RESPONSE, "Invalid message type.");

        //Decode response payload from remote chain.
        (
            ,
            address sender,
            address remoteAddress,
            string memory domain,
            uint256 unusedFunds
        ) = abi.decode(_payload, (bytes, address, address, string, uint256));

        require(balances[remoteAddress][_srcChainId].amount >= 0.0001 ether, "Balance is too low to refund.");
        require(balances[remoteAddress][_srcChainId].amount <= unusedFunds, "Unused amount reported is greater than amount locked up.");
        
        //Update lender's balance.
        balances[remoteAddress][_srcChainId].amount = 0;

        //Return unused funds to lender.
        payable(balances[remoteAddress][_srcChainId].lender).transfer(unusedFunds);
        
        //TODO: use try/catch, protect against re-entrancy attack
        //If failed, flag balance record
        // balances[remoteAddress][_srcChainId].refundFailed = true;
    }

    /**
     * Pay for confirmation of ownership of an address on a remote chain with funds on the local chain.
     * 
     * @param _remoteChainId The ID of the remote chain on which to confirm address ownership.
     * @param _remoteAddress The remote address.
     * @param _domain The domain associated with the remote address.
     */
    function confirmRemoteDomain(
        uint16 _remoteChainId,
        address _remoteAddress,
        string memory _domain
    ) public payable {
        //TODO: determine maximimum gas cost; should be able to require much less than 0.01 ETH
        require(msg.value >= 0.02 ether || balances[msg.sender][_remoteChainId].amount >= 0.02 ether, "Lockup amount must be at least 0.02 Ether."); //TODO: ensure same address can't attempt to confirm multiple addresses with only a single lockup amount; separate balances based on unique address/domain being confirmed?
        require(address(rns) != address(0), "RNS contract has not been set.");

        RNS.DomainAddress memory domainAddress;
        (domainAddress.addr, domainAddress.confirmed) = rns.domains(_domain, _remoteChainId);
        require(domainAddress.addr != address(0), "Remote address has not been registered to domain.");
        require(domainAddress.addr == _remoteAddress, "Remote address does not match address registered to domain.");
        require(!domainAddress.confirmed, "Remote address has already been confirmed for domain.");

        //Encode the sender's address, remote address, and the domain into the LZ payload.
        bytes memory payload = abi.encode(
            REQUEST,
            msg.sender,
            _remoteAddress,
            _domain,
            msg.value - 0.01 ether
        );

        //Update the account's balance of locked up funds.
        balances[msg.sender][_remoteChainId].amount += msg.value - 0.01 ether;

        //REMIX LOGIC STARTS
        require(address(crossChainPaymasterRemote) != address(0), "CrossChainPaymasterRemote contract has not been set.");
        crossChainPaymasterRemote.fakeLzReceive(
            LOCAL_CHAIN_ID, 
            "0x", 
            0, 
            payload);
        //REMIX LOGIC ENDS

        //Send message to remote paymaster.
        // _lzSend(
        //     _remoteChainId,
        //     payload,
        //     payable(msg.sender),
        //     address(0x0),
        //     bytes(""),
        //     0.01 ether
        // );

        //TODO:
        //1. destination LZ contract must credit the _remoteAddress the locked up amount.
        //2. User invokes the "confirmDomain" function of the RNSRemote contract on the remote chain. 
        //3. The total funds used for that transaction is reported back to this contract via a RESPONSE message.
        //4. This contract refunds the user any unused funds.
    }

    //This function can be called by a user that has locked up funds in the event the automatic refund has failed.
    function withdraw(uint16 _srcChainId) external {
        require(balances[msg.sender][_srcChainId].amount >= 0.0001 ether, "Balance is too low to refund.");

        uint256 amount = balances[msg.sender][_srcChainId].amount;

        //Update lender's balance.
        balances[msg.sender][_srcChainId].amount = 0;

        //Return unused funds to lender.
        payable(balances[msg.sender][_srcChainId].lender).call{value: amount, gas: gasleft()}("");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./lzApp/NonblockingLzApp.sol";
import "./RNSRemote.sol";
import "./CrossChainPaymaster.sol";

/**
 * @title CrossChainPaymaster
 *
 * A Paymaster that coordinates with a paymaster on a remote chain to pay for a user's transaction.
 * The user does not require a balance on the remote chain. The user will pay for the remote chain
 * transaction on the local chain.
 */
contract CrossChainPaymasterRemote is NonblockingLzApp {
    //LayerZero chain ID for Arbitrum Goerli Testnet
    uint16 LOCAL_CHAIN_ID = 10143;
    bytes32 constant REQUEST = keccak256("\x01\x02\x03\x04");
    bytes32 constant RESPONSE = keccak256("\x05\x06\x07\x08");

    event Gas(string label, uint256 gasUnits);
    event DebugBytes(string label, bytes payload);

    struct Credit {
        address remoteAddress;
        string domain;
        uint256 initialAmount;
        uint256 gasLeft;
    }

    mapping(address => mapping(uint16 => Credit)) public credits;
    RNSRemote rnsRemote;

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    function setRnsRemote(address _rnsRemoteContract) public onlyOwner {
        rnsRemote = RNSRemote(_rnsRemoteContract);
    }

    //REMIX LOGIC STARTS
    CrossChainPaymaster crossChainPaymaster;
    function setCrossChainPaymaster(address _crossChainPaymaster) public {
        crossChainPaymaster = CrossChainPaymaster(_crossChainPaymaster);
    }

    event Debug(string label, bytes payload);

    function fakeLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public {
        // emit Gas("fakeLzReceive called", 1);

        emit DebugBytes("_nonBlockingLzReceive", _payload);
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
    //REMIX LOGIC ENDS

    /**
     * Overriding LayerZero app function. Receive message from a remote chain identified by chain ID.
     *
     * @param _srcChainId The LayerZero chain ID of the network the message was sent from.
     * @param _payload The encoded data of the message. This contains the domain name to confirm
     * and the source address.
     */
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        //Decode the message type from the payload.
        emit DebugBytes("_nonBlockingLzReceive", _payload);
        bytes memory messageType = abi.decode(_payload, (bytes));

        //Hash the message type for comparison.
        bytes32 messageTypeHash = keccak256(messageType);
        require(messageTypeHash == REQUEST, "Invalid message type.");

        //Handle payload from remote chain.
        // (
        //     ,
        //     address senderAddress,
        //     address remoteAddress,
        //     string memory domain,
        //     uint256 lockupAmount
        // ) = abi.decode(_payload, (bytes, address, address, string, uint256));       

        // emit Gas("Decoded amount", lockupAmount);

        // // //1. Credit the remoteAddress the locked up amount.
        // if (credits[remoteAddress][_srcChainId].remoteAddress == address(0)) {
        //     credits[remoteAddress][_srcChainId] = Credit(senderAddress, domain, lockupAmount, lockupAmount);
        // } else {
        //     credits[remoteAddress][_srcChainId].initialAmount += lockupAmount;
        //     credits[remoteAddress][_srcChainId].gasLeft += lockupAmount;
        // }

        //TODO:
        //2. User invokes the "confirmDomain" function of the RNSRemote contract on the remote chain; this TX will be paid for by the CrossChainPaymasterRemote contract. 
        //3. The total funds used for that transaction is reported back to the CrossChainPaymaster contract via a RESPONSE message from this contract
        //4. CrossChainPaymaster contract refunds the user any unused funds.           
    }

    /**
     * To be invoked on behalf of an address with credits from a remote chain.
     */
    function confirmDomain(
        uint16 _dstChainId,
        string memory domain
    ) public {
        //TODO: charge the user's credit even if the transaction fails

        require(credits[msg.sender][_dstChainId].gasLeft >= 0.01 ether, "Insufficient credits available for sender.");
        //TODO: how to pay for transaction using GSN style paymaster

        //Debit the sender's balance.
        credits[msg.sender][_dstChainId].gasLeft -= 0.01 ether;

        //Call "confirmDomain" for provided remoteAddress
        rnsRemote.confirmDomain{value: 0.01 ether}(_dstChainId, domain, msg.sender);             
    }

    function unlockCredits(
        uint16 _dstChainId,
        address localAddress,
        string memory domain
    ) public {
        //Encode the sender's address, remote address, and the domain into the LZ payload.
        bytes memory payload = abi.encode(
            RESPONSE,
            msg.sender,
            localAddress,
            domain,
            credits[localAddress][_dstChainId].gasLeft //TODO: account for cost of _lzsend
        );

        //TODO: calculate initial_lockup_amount - confirm_domain_cost - lz_response_cost
        uint256 toUnlock = credits[localAddress][_dstChainId].gasLeft;

        //TODO: track pending change in case LZ message fails to deliver and must be retried
        //Update the account's balance of locked up funds.
        credits[msg.sender][_dstChainId].gasLeft = 0;

        //REMIX LOGIC STARTS
        require(address(crossChainPaymaster) != address(0), "CrossChainPaymaster contract has not been set.");

        crossChainPaymaster.fakeLzReceive(
            LOCAL_CHAIN_ID, 
            "0x", 
            0, 
            payload);
        //REMIX LOGIC ENDS

        //Send message to remote Paymaster with final TX cost
        // _lzSend(
        //     _dstChainId,
        //     payload,
        //     payable(msg.sender),
        //     address(0x0),
        //     bytes(""),
        //     toUnlock
        // );
    }

    receive() payable external {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    // ua can not send payload larger than this by default, but it can be changed by the ua owner
    uint constant public DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint)) public minDstGasLookup;
    mapping(uint16 => uint) public payloadSizeLimitLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && trustedRemote.length > 0 && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams, uint _nativeFee) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        _checkPayloadSize(_dstChainId, _payload.length);
        lzEndpoint.send{value: _nativeFee}(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _checkGasLimit(uint16 _dstChainId, uint16 _type, bytes memory _adapterParams, uint _extraGas) internal view virtual {
        uint providedGasLimit = _getGasLimit(_adapterParams);
        uint minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function _checkPayloadSize(uint16 _dstChainId, uint _payloadSize) internal view virtual {
        uint payloadSizeLimit = payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) { // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        require(_payloadSize <= payloadSizeLimit, "LzApp: payload size is too large");
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16 _version, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = _path;
        emit SetTrustedRemote(_remoteChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LzApp: no trusted path record");
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint _minGas) external onlyOwner {
        require(_minGas > 0, "LzApp: invalid minGas");
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // if the size is 0, it means default size limit
    function setPayloadSizeLimit(uint16 _dstChainId, uint _size) external onlyOwner {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft(), 150, abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload));
        // try-catch all errors/exceptions
        if (!success) {
            _storeFailedMessage(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function _storeFailedMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload, bytes memory _reason) internal virtual {
        failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./lzApp/NonblockingLzApp.sol";
import "./RNSRemote.sol";

/**
 * @title RNS
 *
 * RBCx Name Service used to register domain names to addresses on multiple EVM chains. This
 * contract is deployed on only the primary chain and holds records of domain name registrations
 * for the local chain and secondary chains.
 */
contract RNS is NonblockingLzApp {
    //LayerZero chain ID for ZKSync Era Goerli Testnet
    uint16 LOCAL_CHAIN_ID = 10165;

    event Registered(
        string domain,
        address addr,
        uint16 chainId,
        bool confirmed
    );
    event SourceAddress(address _srcAddress);
    event Domain(bytes domain);

    struct DomainAddress {
        address addr;
        bool confirmed;
    }

    //Mapping used for storage of domains.
    //domain name => chainId => address
    mapping(string => mapping(uint16 => DomainAddress)) public domains;

    //TODO: enable reverse lookup
    //Mapping used for reverse lookup of domain name.
    //address => domain
    // mapping(address => DomainAddress) public addresses;

    RNSRemote rnsRemote;

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    function setRnsRemote(address _rnsRemoteContract) public {
        rnsRemote = RNSRemote(_rnsRemoteContract);
    }

    //REMIX LOGIC STARTS
    function fakeLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public {
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
    //REMIX LOGIC ENDS

    /**
     * Overriding LayerZero app function. Receive message from a remote chain identified by chain ID.
     *
     * @param _srcChainId The LayerZero chain ID of the network the message was sent from.
     * @param _payload The encoded data of the message. This contains the domain name to confirm
     * and the source address.
     */
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        //Extract the source address from the concatenation of source_address and destination_address.
        (address sourceAddress, string memory domain) = abi.decode(
            _payload,
            (address, string)
        );

        //TODO: remove after development
        emit SourceAddress(sourceAddress);
        emit Domain(bytes(domain));

        require(
            domains[domain][_srcChainId].addr != address(0),
            "No address is registered for provided domain and chain ID."
        );
        require(
            domains[domain][_srcChainId].addr == sourceAddress,
            "Remote chain sender does not match registered address."
        );

        _register(domain, sourceAddress, _srcChainId);
    }

    /**
     * Registers the provided domain name to the sender's address for the local chain ID.
     *
     * @param domain The user's requested domain name.
     */
    function registerLocal(string memory domain) public {
        _register(domain, msg.sender, LOCAL_CHAIN_ID);
    }

    /**
     * Registers the provided domain name to the sender's address for the provided remote chain ID.
     *
     * @param domain The user's requested domain name.
     * @param addr The address to associate with the domain name.
     * @param chainId The chain ID associated with the address.
     */
    function registerRemote(
        string memory domain,
        address addr,
        uint16 chainId
    ) public {
        require(chainId != LOCAL_CHAIN_ID, "Invalid remote chain ID.");
        require(
            domains[domain][LOCAL_CHAIN_ID].addr != address(0),
            "Local chain registration of domain must be performed first."
        );
        require(
            msg.sender == domains[domain][LOCAL_CHAIN_ID].addr,
            "Remote registration must be initiated by owner of domain on local chain."
        );

        _register(domain, addr, chainId);
    }

    /**
     * Registers the provided domain name to the sender's address for the provided chain ID.
     *
     * @param domain The user's requested domain name.
     * @param addr The address to associate with the domain name.
     * @param chainId The chain ID associated with the address.
     */
    function _register(
        string memory domain,
        address addr,
        uint16 chainId
    ) private {
        DomainAddress memory entry;

        if (chainId == LOCAL_CHAIN_ID) {
            //Local chain registration is automatically confirmed.
            entry.confirmed = true;
        } else {
            require(
                domains[domain][LOCAL_CHAIN_ID].confirmed,
                "Domain is not yet registered for local chain."
            );

            //Address can only be confirmed for remote chain if it has been previously registered.
            if (domains[domain][chainId].addr == addr) {
                entry.confirmed = true;
            }
        }

        //Update the storage.
        entry.addr = addr;
        domains[domain][chainId] = entry;

        emit Registered(domain, entry.addr, chainId, entry.confirmed);
    }

    function deregister(string memory domain, uint16 chainId) public {
        //TODO: determine expected user experience for deregistration
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
pragma abicoder v2;

import "./lzApp/NonblockingLzApp.sol";
import "./RNS.sol";
import "./CrossChainPaymasterRemote.sol";

/**
 * @title RNSRemote
 *
 * RBCx Name Service used to register domain names to addresses on multiple EVM chains. This is the
 * contract deployed to non-primary chains for confirming ownership of a claimed address on the
 * primary chain.
 */
contract RNSRemote is NonblockingLzApp {
    event MessageSent(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload
    );
    event SourceAddress(address _srcAddress);
    event Domain(bytes domain);

    event Gas(string label, uint256 gasUnits);

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    //REMIX LOGIC STARTS
    RNS rns;
    function setRns(address _rnsContract) public {
        rns = RNS(_rnsContract);
    }
    //REMIX LOGIC ENDS

    CrossChainPaymasterRemote crossChainPaymasterRemote;
    function setCrossChainPaymasterRemote(address payable _crossChainPaymasterRemote) public onlyOwner {
        crossChainPaymasterRemote = CrossChainPaymasterRemote(_crossChainPaymasterRemote);
    }

    //No action is taken for LZ messages received.
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {}

    function estimateFee(
        uint16 _dstChainId,
        string memory domain,
        bool _useZro,
        bytes calldata _adapterParams
    ) public view returns (uint nativeFee, uint zroFee) {
        //Encode the sender's address and the domain into the LZ payload.
        bytes memory payload = abi.encode(msg.sender, domain);

        return
            lzEndpoint.estimateFees(
                _dstChainId,
                address(this),
                payload,
                _useZro,
                _adapterParams
            );
    }

    function _confirmDomain(uint16 _dstChainId, bytes memory _payload) private {
        //REMIX LOGIC BEGINS
        require(address(rns) != address(0), "RNS contract has not been set.");
        rns.fakeLzReceive(
            10143, //Arbitrum Goerli
            "0x",
            0,
            _payload
        );
        //REMIX LOGIC ENDS

        // _lzSend(
        //     _dstChainId,
        //     _payload,
        //     payable(msg.sender),
        //     address(0x0),
        //     bytes(""),
        //     msg.value
        // );
    }

    function confirmDomain(
        uint16 _dstChainId,
        string memory domain,
        address sender
    ) public payable {
        require(msg.sender == address(crossChainPaymasterRemote), "Only registered CrossChainPaymasterRemote contract may call this function");
        
        // Encode the sender's address and the domain into the LZ payload.
        bytes memory payload = abi.encode(sender, domain);

        _confirmDomain(_dstChainId, payload);
    }

    function confirmDomain(
        uint16 _dstChainId,
        string memory domain
    ) public payable {
        // Encode the sender's address and the domain into the LZ payload.
        bytes memory payload = abi.encode(msg.sender, domain);

        _confirmDomain(_dstChainId, payload);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
    internal
    pure
    returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
            tempBytes := mload(0x40)

        // Store the length of the first bytes array at the beginning of
        // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

        // Maintain a memory counter for the current write location in the
        // temp bytes array by adding the 32 bytes for the array length to
        // the starting location.
            let mc := add(tempBytes, 0x20)
        // Stop copying when the memory counter reaches the length of the
        // first bytes array.
            let end := add(mc, length)

            for {
            // Initialize a copy counter to the start of the _preBytes data,
            // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
            // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
            // Write the _preBytes data into the tempBytes memory 32 bytes
            // at a time.
                mstore(mc, mload(cc))
            }

        // Add the length of _postBytes to the current length of tempBytes
        // and store it as the new length in the first 32 bytes of the
        // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

        // Move the memory counter back from a multiple of 0x20 to the
        // actual end of the _preBytes data.
            mc := end
        // Stop copying when the memory counter reaches the new combined
        // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

        // Update the free-memory pointer by padding our last write location
        // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
        // next 32 byte block, then round down to the nearest multiple of
        // 32. If the sum of the length of the two arrays is zero then add
        // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
        // Read the first 32 bytes of _preBytes storage, which is the length
        // of the array. (We don't need to use the offset into the slot
        // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
        // Arrays of 31 bytes or less have an even value in their slot,
        // while longer arrays have an odd value. The actual length is
        // the slot divided by two for odd values, and the lowest order
        // byte divided by two for even values.
        // If the slot is even, bitwise and the slot with 255 and divide by
        // two to get the length. If the slot is odd, bitwise and the slot
        // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
        // slength can contain both the length and contents of the array
        // if length < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
            // Since the new array still fits in the slot, we just need to
            // update the contents of the slot.
            // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                _preBytes.slot,
                // all the modifications to the slot are inside this
                // next block
                add(
                // we can just add to the slot contents because the
                // bytes we want to change are the LSBs
                fslot,
                add(
                mul(
                div(
                // load the bytes from memory
                mload(add(_postBytes, 0x20)),
                // zero all bytes to the right
                exp(0x100, sub(32, mlength))
                ),
                // and now shift left the number of bytes to
                // leave space for the length in the slot
                exp(0x100, sub(32, newlength))
                ),
                // increase length by the double of the memory
                // bytes length
                mul(mlength, 2)
                )
                )
                )
            }
            case 1 {
            // The stored value fits in the slot, but the combined value
            // will exceed it.
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // The contents of the _postBytes array start 32 bytes into
            // the structure. Our first read should obtain the `submod`
            // bytes that can fit into the unused space in the last word
            // of the stored array. To get this, we read 32 bytes starting
            // from `submod`, so the data we read overlaps with the array
            // contents by `submod` bytes. Masking the lowest-order
            // `submod` bytes allows us to add that value directly to the
            // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                sc,
                add(
                and(
                fslot,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ),
                and(mload(mc), mask)
                )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
            // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // Copy over the first `submod` bytes of the new data as in
            // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
    internal
    pure
    returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

        // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                    // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
    internal
    view
    returns (bool)
    {
        bool success = true;

        assembly {
        // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
        // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

        // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                    // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                        // unsuccess:
                            success := 0
                        }
                    }
                    default {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                        let cb := 1

                    // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                            // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
            _gas, // gas
            _target, // recipient
            0, // ether value
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
            _gas, // gas
            _target, // recipient
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
    internal
    pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
        // load the first word of
            let _word := mload(add(_buf, 0x20))
        // mask out the top 4 bytes
        // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}