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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

import "tapioca-sdk/dist/contracts/interfaces/ILayerZeroEndpoint.sol";
import "../interfaces/ICluster.sol";

contract Cluster is Ownable, ICluster {
    // ************ //
    // *** VARS *** //
    // ************ //

    /// @notice returns the current LayerZero chain id
    uint16 public lzChainId;
    /// @notice returns true if an address is marked as an Editor
    /// @dev editors can update contracts' whitelist status
    mapping(address editor => bool status) public isEditor;
    /// @notice returns the whitelist status for an address
    /// @dev LZ chain id => contract => status
    mapping(uint16 lzChainId => mapping(address _contract => bool status))
        private _whitelisted;

    /// @notice event emitted when LZ chain id is updated
    event LzChainUpdate(uint256 indexed _oldChain, uint256 indexed _newChain);
    /// @notice event emitted when an editor status is updated
    event EditorUpdated(
        address indexed _editor,
        bool indexed _oldStatus,
        bool indexed _newStatus
    );
    /// @notice event emitted when a contract status is updated
    event ContractUpdated(
        address indexed _contract,
        uint16 indexed _lzChainId,
        bool indexed _oldStatus,
        bool _newStatus
    );

    constructor(address lzEndpoint, address _owner) {
        lzChainId = ILayerZeroEndpoint(lzEndpoint).getChainId();
        transferOwnership(_owner);
    }

    // ******************** //
    // *** VIEW METHODS *** //
    // ******************** //
    /// @notice returns the whitelist status of a contract
    /// @param _lzChainId LayerZero chain id
    /// @param _addr the contract's address
    function isWhitelisted(
        uint16 _lzChainId,
        address _addr
    ) external view override returns (bool) {
        if (_lzChainId == 0) {
            _lzChainId = lzChainId;
        }
        return _whitelisted[_lzChainId][_addr];
    }

    // ********************** //
    // *** PUBLIC METHODS *** //
    // ********************** //

    /// @notice updates the whitelist status of contracts
    /// @dev can only be called by Editors or the Owner
    /// @param _lzChainId LayerZero chain id
    /// @param _addresses the contracts addresses
    /// @param _status the new whitelist status
    function batchUpdateContracts(
        uint16 _lzChainId,
        address[] memory _addresses,
        bool _status
    ) external override {
        require(
            isEditor[msg.sender] || msg.sender == owner(),
            "Cluster: not authorized"
        );

        if (_lzChainId == 0) {
            //set lz chain as the current one
            _lzChainId = lzChainId;
        }

        for (uint256 i; i < _addresses.length; i++) {
            emit ContractUpdated(
                _addresses[i],
                _lzChainId,
                _whitelisted[_lzChainId][_addresses[i]],
                _status
            );
            _whitelisted[_lzChainId][_addresses[i]] = _status;
        }
    }

    /// @notice updates the whitelist status of a contract
    /// @dev can only be called by Editors or the Owner
    /// @param _lzChainId LayerZero chain id
    /// @param _addr the contract's address
    /// @param _status the new whitelist status
    function updateContract(
        uint16 _lzChainId,
        address _addr,
        bool _status
    ) external override {
        require(
            isEditor[msg.sender] || msg.sender == owner(),
            "Cluster: not authorized"
        );

        if (_lzChainId == 0) {
            //set lz chain as the current one
            _lzChainId = lzChainId;
        }

        emit ContractUpdated(
            _addr,
            _lzChainId,
            _whitelisted[_lzChainId][_addr],
            _status
        );
        _whitelisted[_lzChainId][_addr] = _status;
    }

    // ********************* //
    // *** OWNER METHODS *** //
    // ********************* //
    /// @notice updates LayerZero chain id
    /// @param _lzChainId the new LayerZero chain id
    function updateLzChain(uint16 _lzChainId) external onlyOwner {
        emit LzChainUpdate(lzChainId, _lzChainId);
        lzChainId = _lzChainId;
    }

    /// @notice updates the editor status
    /// @param _editor the editor's address
    /// @param _status the new editor's status
    function updateEditor(address _editor, bool _status) external onlyOwner {
        emit EditorUpdated(_editor, isEditor[_editor], _status);
        isEditor[_editor] = _status;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ICluster {
    function isWhitelisted(
        uint16 lzChainId,
        address _addr
    ) external view returns (bool);

    function updateContract(
        uint16 lzChainId,
        address _addr,
        bool _status
    ) external;

    function batchUpdateContracts(
        uint16 _lzChainId,
        address[] memory _addresses,
        bool _status
    ) external;

    function lzChainId() external view returns (uint16);
}

// SPDX-License-Identifier: MIT

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

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
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

// SPDX-License-Identifier: MIT

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