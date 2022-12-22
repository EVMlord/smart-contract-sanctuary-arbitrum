//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUXDRouter} from "./IUXDRouter.sol";
import {ErrZeroAddress} from "../common/Constants.sol";
import {IDepository} from "../integrations/IDepository.sol";

/// @title UXDRouter
/// @notice Routes transactions to implementation contracts to interact with various DEXes.
contract UXDRouter is Ownable, IUXDRouter {
    ///////////////////////////////////////////////////////////////
    ///                        Errors
    //////////////////////////////////////////////////////////////
    error NoDepositoryForMarket(address market);
    error RouterNotController(address caller);
    error Exists(
        address assetToken,
        address depository
    );
    error NotExists(address assetToken);

    ///////////////////////////////////////////////////////////////
    ///                     Events
    ///////////////////////////////////////////////////////////////
    event DepositoryRegistered(
        address indexed assetToken,
        address indexed depository
    );
    event DepositoryUnregistered(
        address indexed assetToken,
        address indexed depository
    );

    /// @dev Mapping assetToken address => depository addresses[].
    mapping(address => address[]) private _depositoriesForAsset;

    /// @notice Sets the depository for a given token.
    /// @dev reverts if this depository address is already registered for the same asset.
    /// A depository can be registered multiple times for different assets.
    /// @param depository the depository contract address.
    /// @param assetToken the asset to register the depository for
    function registerDepository(address depository, address assetToken)
        external
        onlyOwner
    {
        address found = _checkDepositoriesForAsset(assetToken, depository);
        if (found != address(0)) {
            revert Exists(assetToken, depository);
        }
        _depositoriesForAsset[assetToken].push(depository);

        emit DepositoryRegistered(assetToken, depository);
    }

    /// @notice Unregisters a previously registered depository
    /// @param depository the depository address.
    /// @param assetToken the asset to unregister depository for
    function unregisterDepository(address depository, address assetToken)
        external
        onlyOwner
    {
        bool foundByAsset = false;
        address[] storage byAsset = _depositoriesForAsset[assetToken];
        if (byAsset.length == 0) {
            revert NotExists(assetToken);
        }
        for (uint256 i = 0; i < byAsset.length; i++) {
            if (byAsset[i] == depository) {
                foundByAsset = true;
                byAsset[i] = byAsset[byAsset.length - 1];
                byAsset.pop();
                break;
            }
        }
        if (!foundByAsset) {
            revert NotExists(assetToken);
        }

        emit DepositoryUnregistered(assetToken, depository);
    }

    /// @notice Returns the depository for a given market
    /// @dev This function reverts if a depository is not found for a given assetToken.
    /// This returns the default colalteral pair based on internal routing logic.
    /// This is currently set to return the first depository registered for a given assetToken.
    /// @param assetToken The assetToken to return the depository for
    /// @return depository the address of the depository for a given market.
    function findDepositoryForAssetDeposit(address assetToken, uint256) external view returns (address) {
        return _firstDepositoryForAsset(assetToken);
    }

    function findDepositoryForRedeem(address assetToken, uint256) external view returns (address) {
        return _firstDepositoryForAsset(assetToken);
    }

    function depositoriesForAsset(address assetToken) external view returns (address[] memory) {
        return _depositoriesForAsset[assetToken];
    }

    function _firstDepositoryForAsset(address assetToken) internal view returns (address) {
       address[] storage depositories = _depositoriesForAsset[assetToken];
        if (depositories.length == 0) {
            revert NotExists(assetToken);
        }
        return depositories[0]; 
    }


    function _checkDepositoriesForAsset(
        address assetToken,
        address checkFor
    ) internal view returns (address) {
        address[] storage byAsset = _depositoriesForAsset[assetToken];
        for (uint256 i = 0; i < byAsset.length; i++) {
            if (byAsset[i] == checkFor) {
                return byAsset[i];
            }
        }
        return address(0);
    }
}

//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

struct DepositoryState {
    uint256 assetDeposited;
    uint256 insuranceDeposited;
    uint256 redeemableUnderManagement;
    uint256 totalFeesPaid;
    uint256 redeemableSoftCap;
}

interface IDepository {

    function assetToken() external view returns (address);

    function deposit(address token, uint256 amount) external returns (uint256);
    function redeem(address token, uint256 amountToRedeem) external returns (uint256);

    function transferOwnership(address newOwner) external;
    
    function getUnrealizedPnl() external view returns (int256);
}

//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

error ErrZeroAddress();

//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

import {IDepository} from "../integrations/IDepository.sol";

interface IUXDRouter {
    function registerDepository(address depository, address asset)
        external;

    function unregisterDepository(address depository, address asset)
        external;

    function findDepositoryForAssetDeposit(address asset, uint256 amount)
        external
        view
        returns (address);

    function findDepositoryForRedeem(address asset, uint256 redeemAmount)
        external
        view
        returns (address);
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