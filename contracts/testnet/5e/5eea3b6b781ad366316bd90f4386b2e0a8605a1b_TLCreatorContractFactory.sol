// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";

/*//////////////////////////////////////////////////////////////////////////
                          InitializableInterface
//////////////////////////////////////////////////////////////////////////*/
interface InitializableInterface {
    function initialize(
        string memory name,
        string memory symbol,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) external;
}

/*//////////////////////////////////////////////////////////////////////////
                          TLCreatorContractFactory
//////////////////////////////////////////////////////////////////////////*/

/// @title TLCreatorContractFactory
/// @notice Contract factory for TL creator contracts
/// @dev deploys any contract compatible with the InitializableInterface above
/// @author transientlabs.xyz
/// @custom:version 2.6.2
contract TLCreatorContractFactory is Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                                    Structs
    //////////////////////////////////////////////////////////////////////////*/

    struct ContractType {
        string name;
        address[] implementations;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    ContractType[] private _contractTypes;

    /*//////////////////////////////////////////////////////////////////////////
                                    Events
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev event emitted whenever a contract type is added
    event ContractTypeAdded(uint256 indexed contractTypeId, address indexed firstImplementation, string name);

    /// @dev event emitted whenever an implementation is added for a contract type
    event ImplementationAdded(uint256 indexed contractTypeId, address indexed implementation);

    /// @dev event emitted whenever a contract is deployed
    event ContractDeployed(address indexed contractAddress, address indexed implementationAddress, address indexed sender);

    /*//////////////////////////////////////////////////////////////////////////
                                  Constructor
    //////////////////////////////////////////////////////////////////////////*/

    constructor() Ownable() {}

    /*//////////////////////////////////////////////////////////////////////////
                              Ownership Functions  
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to add a contract type
    /// @dev only callable by the factory owner
    /// @param name The new contract type name
    /// @param implementation The first implementation address to add
    function addContractType(string memory name, address implementation) external onlyOwner {
        address[] memory implementations = new address[](1);
        implementations[0] = implementation;

        _contractTypes.push(ContractType(name, implementations));
        uint256 contractTypeId = _contractTypes.length - 1;

        emit ContractTypeAdded(contractTypeId, implementation, name);
    }

    /// @notice Function to add an implementation contract for a type
    /// @dev only callable by the factory owner
    /// @param contractTypeId The contract type id
    /// @param implementation The new implementation address to add
    function addContractImplementation(uint256 contractTypeId, address implementation) external onlyOwner {
        ContractType storage contractType = _contractTypes[contractTypeId];
        contractType.implementations.push(implementation);

        emit ImplementationAdded(contractTypeId, implementation);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           Contract Creation Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to deploy the latest implementation contract for a contract type
    /// @param contractTypeId The contract type id
    /// @param contractName The deployed contract name
    /// @param contractSymbol The deployed contract symbol
    /// @param defaultRoyaltyRecipient The default royalty recipient
    /// @param defaultRoyaltyPercentage The default royalty percentage
    /// @param initOwner The initial owner of the deployed contract
    /// @param admins The intial admins on the contract
    /// @param enableStory The initial state of story inscriptions on the deployed contract
    /// @param blockListRegistry The blocklist registry
    /// @return contractAddress The deployed contract address
    function deployLatestImplementation(
        uint256 contractTypeId,
        string memory contractName,
        string memory contractSymbol,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) external returns (address contractAddress) {
        ContractType memory contractType = _contractTypes[contractTypeId];
        address implementation = contractType.implementations[contractType.implementations.length - 1];
        return _deployContract(
            implementation,
            contractName,
            contractSymbol,
            defaultRoyaltyRecipient,
            defaultRoyaltyPercentage,
            initOwner,
            admins,
            enableStory,
            blockListRegistry
        );
    }

    /// @notice Function to deploy a specific implementation contract for a contract type
    /// @param contractTypeId The contract type id
    /// @param implementationIndex The index specifying the implementation contract
    /// @param contractName The deployed contract name
    /// @param contractSymbol The deployed contract symbol
    /// @param defaultRoyaltyRecipient The default royalty recipient
    /// @param defaultRoyaltyPercentage The default royalty percentage
    /// @param initOwner The initial owner of the deployed contract
    /// @param admins The intial admins on the contract
    /// @param enableStory The initial state of story inscriptions on the deployed contract
    /// @param blockListRegistry The blocklist registry
    /// @return contractAddress The deployed contract address
    function deployImplementation(
        uint256 contractTypeId,
        uint256 implementationIndex,
        string memory contractName,
        string memory contractSymbol,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) external returns (address contractAddress) {
        ContractType memory contractType = _contractTypes[contractTypeId];
        address implementation = contractType.implementations[implementationIndex];
        return _deployContract(
            implementation,
            contractName,
            contractSymbol,
            defaultRoyaltyRecipient,
            defaultRoyaltyPercentage,
            initOwner,
            admins,
            enableStory,
            blockListRegistry
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to get all contract types
    /// @return contractTypes A list of contract type structs
    function getContractTypes() external view returns (ContractType[] memory contractTypes) {
        return _contractTypes;
    }

    /// @notice Function to get contract type info by id
    /// @param contractTypeId The contract type id
    /// @return contractType A contract type struct
    function getContractType(uint256 contractTypeId) external view returns (ContractType memory contractType) {
        return _contractTypes[contractTypeId];
    }

    /*//////////////////////////////////////////////////////////////////////////
                               Internal Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal function to deploy a contract
    /// @param implementation The implementation address
    /// @param contractName The deployed contract name
    /// @param contractSymbol The deployed contract symbol
    /// @param defaultRoyaltyRecipient The default royalty recipient
    /// @param defaultRoyaltyPercentage The default royalty percentage
    /// @param initOwner The initial owner of the deployed contract
    /// @param admins The intial admins on the contract
    /// @param enableStory The initial state of story inscriptions on the deployed contract
    /// @param blockListRegistry The blocklist registry
    /// @return contractAddress The deployed contract address
    function _deployContract(
        address implementation,
        string memory contractName,
        string memory contractSymbol,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) private returns (address contractAddress) {
        contractAddress = Clones.clone(implementation);
        InitializableInterface(contractAddress).initialize(
            contractName,
            contractSymbol,
            defaultRoyaltyRecipient,
            defaultRoyaltyPercentage,
            initOwner,
            admins,
            enableStory,
            blockListRegistry
        );

        emit ContractDeployed(contractAddress, implementation, msg.sender);

        return contractAddress;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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