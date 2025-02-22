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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

enum OptionType {
    LONG_CALL,
    LONG_PUT
}

enum PositionState {
    EMPTY,
    PENDING,
    ACTIVE,
    CLOSED
}

struct OptionPosition {
    uint256 strikeId;
    PositionState state;
    OptionType optionType;
    uint256 amount;
    uint256 premium;
}

interface IOptionToken {
    
    event Initialize(address indexed vault);
    event UpdateBaseURI(string baseURI);
    event OpenPosition(address indexed to, uint256 indexed positionId, OptionType optionType, uint256 strikeId, uint256 amount);
    event ActivePosition(uint256 indexed positionId, uint256 premium);
    event ClosePosition(uint256 indexed positionId);
    event ForceClosePosition(uint256 indexed positionId);
    
    function vault() external view returns(address);
    function setBaseURI(string memory baseURI) external;
    function openPosition(address to, OptionType optionType, uint256 strikeId, uint256 amount) external returns(uint256 positionId);
    function activePosition(uint256 positionId, uint256 premium) external;
    function closePosition(uint256 positionId) external;
    function forceClosePosition(uint256 positionId) external;
    function optionPositionState(uint256 positionId) external view returns(PositionState);
    function optionPosition(uint256 positionId) external view returns(OptionPosition memory);
    function lockedValue(uint256 positionId) external view returns(uint256);
    function totalValue() external view returns(uint256);

    error OnlyVault(address thrower, address caller, address vault);
    error ZeroVaultAddress(address thrower);
    error ZeroAmount(address thrower);
    error IsNotPending(address thrower, uint256 positionId, PositionState state);
    error IsNotActive(address thrower, uint256 positionId, PositionState state);
    error NonexistentPosition(address thrower, uint256 positionId);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {OptionType} from "./IOptionToken.sol";
import {TradeType} from "./IVault.sol";

struct TradeParameters {
  OptionType optionType;
  TradeType tradeType;
  uint256 spotPrice;
  uint256 strikePrice;
  uint256 duration;
  uint256 expiry;
  uint256 amount;
}

/************
@title IPriceOracle interface
@notice Interface for the Aave price oracle.*/
interface IOracle {
  /***********
    @dev returns the asset price in wei
     */
  function getAssetPrice(address asset) external view returns (uint256);

  function getAssetPriceAndVol(address asset) external view returns (uint256 price, uint256 vol);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {OptionType, PositionState} from "./IOptionToken.sol";

enum TradeType {
    OPEN,
    CLOSE
}

struct Strike {
    uint256 spotPrice;
    uint256 strikePrice;
    uint256 duration;
    uint256 expiry;
}

interface IVault {
    struct CollectionConfiguration {
        bool paused;
        bool activated;
        uint32 id;
        uint32 weight; // percentage: 1000000 means 100%
        address optionToken;
    }

    event CreateStrike(uint256 indexed strikeId, uint256 duration, uint256 expiration, uint256 spotPrice, uint256 strikePrice);
    event DestoryStrike(uint256 indexed strikeId);
    event OpenPosition(address indexed collection, uint256 indexed strikeId, uint256 indexed positionId, uint256 estimatedPremium);
    event ReceivePremium(address indexed user, uint256 amountToReserve, uint256 amountToLiquidityPool);
    event SendRevenue(address indexed receiver, uint256 amount, uint256 fee);
    event CreateMarket(address indexed collection, uint32 weight, address optionToken);

    function reserve() external view returns(address);
    function unrealizedPNL() external view returns(int256);
    function updateUnrealizedPNL() external returns(int256);
    function unrealizedPremium() external view returns(uint256);
    function deposit(uint256 amount, address onBehalfOf) external;
    function claimLPToken(address user) external;
    function withdraw(uint256 amount, address to) external returns(uint256);
    function totalAssets() external view returns(uint256);
    function totalLockedAssets() external view returns(uint256);
    function openPosition(address collection, address onBehalfOf, OptionType optionType, uint256 strikePrice, uint256 expiry, uint256 amount) external returns(uint256 positionId, uint256 premium);
    function activePosition(address collection, uint256 positionId) external returns(uint256 premium);
    function closePosition(address collection, address to, uint256 positionId) external returns(uint256);
    function forceClosePendingPosition(address collection, uint256 positionId) external;
    function strike(uint256 strikeId) external view returns(Strike memory);
    function addMarket(address collection, uint32 weight, address optionToken) external returns(uint32);
    function markets() external view returns(address[] memory);
    function marketConfiguration(address collection) external view returns(CollectionConfiguration memory);
    function maximumOptionAmount(address collection, OptionType optionType) external view returns(uint256);

    error ZeroAmount(address thrower);
    error InvalidStrikePrice(address thrower, uint strikePrice, uint spotPrice);
    error InvalidDuration(address thrower, uint duration);
    error InsufficientLiquidityForCollection(address thrower, address collection, uint256 totalLockedAssets, uint256 amountToBeLocked, uint256 vaultLiquidity);
    error InsufficientLiquidity(address thrower, uint256 totalLockedAssets, uint256 amountToBeLocked, uint256 vaultLiquidity);
    error InvalidStrikeId(address thrower, uint256 strikeId);
    error PremiumTransferFailed(address thrower, address sender, address receiver, uint256 premium);
    error PositionNotActive(address thrower, uint256 positionId, PositionState state);
    error PositionNotExpired(address thrower, uint256 positionId, uint256 expiry, uint256 blockTimestamp);
    error RevenueTransferFailed(address thrower, address receiver, uint256 revenue);
    error CollectionAlreadyExists(address thrower, address collection);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

uint256 constant GENERAL_DECIMALS = 6;
uint256 constant GENERAL_UNIT = 10 ** GENERAL_DECIMALS;

uint256 constant DECIMALS = 18;
uint256 constant UNIT = 10 ** DECIMALS;

uint256 constant HIGH_PRECISION_DECIMALS = 27;
uint256 constant HIGH_PRECISION_UNIT = 10 ** HIGH_PRECISION_DECIMALS;

library DataTypes {
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOracle.sol";
import { GENERAL_UNIT, UNIT } from "./libraries/DataTypes.sol";



/**
 * @title NFTCallOracle
 * @author NFTCall
 */
contract NFTCallOracle is IOracle, Ownable, Pausable {
    // asset address
    mapping(address => uint256) private _addressIndexes;
    mapping(address => bool) private _emergencyAdmin;
    address[] private _addressList;
    address private _operator;

    // price
    struct Price {
        uint32 v1;
        uint32 v2;
        uint32 v3;
        uint32 v4;
        uint32 v5;
        uint32 v6;
        uint32 v7;
        uint32 v8;
    }
    Price[50] private _prices;
    struct UpdateInput {
        uint16 price; // Retain two decimals. If floor price is 10.3 ,the input price is 1030
        uint16 vol; // Retain one decimal. If volatility is 3.56% , the input vol is 36
        uint256 index; // 1 ~ 8
    }
    uint256 public constant PRICE_UNIT = 100;
    uint256 public constant PRICE_DECIMALS = 2;
    uint256 public constant VOL_UNIT = 1000;
    uint256 public constant VOL_DECIMALS = 3;
    uint16 private constant VOL_LIMIT = 300; // 30%

    // Event
    event SetAssetData(uint256[] indexes, UpdateInput[][] inputs);
    event ChangeOperator(
        address indexed oldOperator,
        address indexed newOperator
    );
    event SetEmergencyAdmin(address indexed admin, bool enabled);
    event ReplaceAsset(address indexed oldAsset, address indexed newAsset);

    /**
     * @dev Constructor
     * @param newOperator The address of the operator
     * @param assets The addresses of the assets
     */
    constructor(address newOperator, address[] memory assets) {
        require(newOperator != address(0));
        _setOperator(newOperator);
        _addAssets(assets);
    }

    function _addAssets(address[] memory addresses) private {
        uint256 index = _addressList.length + 1;
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if (_addressIndexes[addr] == 0) {
                _addressIndexes[addr] = index;
                _addressList.push(addr);
                index++;
            }
        }
    }

    function _setOperator(address newOperator) private {
        address oldOperator = _operator;
        _operator = newOperator;
        emit ChangeOperator(oldOperator, newOperator);
    }

    function pack(uint16 a, uint16 b) private pure returns (uint32) {
        return (uint32(a) << 16) | uint32(b);
    }

    function unpack(uint32 c) private pure returns (uint16 a, uint16 b) {
        a = uint16(c >> 16);
        b = uint16(c);
    }

    function operator() external view returns (address) {
        return _operator;
    }

    function isEmergencyAdmin(address admin) external view returns (bool) {
        return _emergencyAdmin[admin];
    }

    function getAddressList() external view returns (address[] memory) {
        return _addressList;
    }

    function getIndexes(
        address asset
    ) public view returns (uint256 OuterIndex, uint256 InnerIndex) {
        uint256 index = _addressIndexes[asset];
        OuterIndex = (index - 1) / 8;
        InnerIndex = index % 8;
        if (InnerIndex == 0) {
            InnerIndex = 8;
        }
    }

    function addAssets(address[] memory assets) external onlyOwner {
        require(assets.length > 0);
        _addAssets(assets);
    }

    function replaceAsset(
        address oldAsset,
        address newAsset
    ) external onlyOwner {
        uint256 index = _addressIndexes[oldAsset];
        require(index != 0, "invalid index");
        _addressList[index - 1] = newAsset;
        emit ReplaceAsset(oldAsset, newAsset);
    }

    function setPause(bool val) external {
        require(
            _emergencyAdmin[_msgSender()],
            "caller is not the emergencyAdmin"
        );
        if (val) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "invalid operator");
        _setOperator(newOperator);
    }

    function setEmergencyAdmin(address admin, bool enabled) external onlyOwner {
        require(admin != address(0), "invalid admin");
        _emergencyAdmin[admin] = enabled;
        emit SetEmergencyAdmin(admin, enabled);
    }

    function _getPriceByIndex(
        address asset
    ) private view returns (uint16, uint16) {
        uint256 index = _addressIndexes[asset];
        if (index == 0) {
            return unpack(0);
        }
        (uint256 OuterIndex, uint256 InnerIndex) = getIndexes(asset);
        Price memory cachePrice = _prices[OuterIndex];
        uint32 value = 0;
        if (InnerIndex == 1) {
            value = cachePrice.v1;
        } else if (InnerIndex == 2) {
            value = cachePrice.v2;
        } else if (InnerIndex == 3) {
            value = cachePrice.v3;
        } else if (InnerIndex == 4) {
            value = cachePrice.v4;
        } else if (InnerIndex == 5) {
            value = cachePrice.v5;
        } else if (InnerIndex == 6) {
            value = cachePrice.v6;
        } else if (InnerIndex == 7) {
            value = cachePrice.v7;
        } else if (InnerIndex == 8) {
            value = cachePrice.v8;
        }
        return unpack(value);
    }

    function _getAsset(
        address asset
    ) private view returns (uint256 price, uint256 vol) {
        (uint16 p, uint16 v) = _getPriceByIndex(asset);
        price = uint256(p) * (UNIT / PRICE_UNIT);
        vol = uint256(v) * (UNIT / VOL_UNIT);
    }

    function getAssetPriceAndVol(address asset) external view returns (uint256 price, uint256 vol) {
        (price, vol) = _getAsset(asset);
    }

    function getAssetPrice(
        address asset
    ) external view returns (uint256 price) {
        (price, ) = _getAsset(asset);
    }

    function getAssetVol(address asset) external view returns (uint256 vol) {
        (, vol) = _getAsset(asset);
    }

    function getAssets(
        address[] memory assets
    ) external view returns (uint256[2][] memory prices) {
        prices = new uint256[2][](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            (uint256 price, uint256 vol) = _getAsset(assets[i]);
            prices[i] = [price, vol];
        }
        return prices;
    }

    function _setAssetPrice(
        uint256 index,
        UpdateInput[] memory inputs
    ) private {
        Price storage cachePrice = _prices[index];
        for (uint256 i = 0; i < inputs.length; i++) {
            UpdateInput memory input = inputs[i];
            require(input.vol >= VOL_LIMIT, "invalid vol");
            uint256 InnerIndex = input.index;
            uint32 value = pack(input.price, input.vol);
            if (InnerIndex == 1) {
                cachePrice.v1 = value;
            } else if (InnerIndex == 2) {
                cachePrice.v2 = value;
            } else if (InnerIndex == 3) {
                cachePrice.v3 = value;
            } else if (InnerIndex == 4) {
                cachePrice.v4 = value;
            } else if (InnerIndex == 5) {
                cachePrice.v5 = value;
            } else if (InnerIndex == 6) {
                cachePrice.v6 = value;
            } else if (InnerIndex == 7) {
                cachePrice.v7 = value;
            } else if (InnerIndex == 8) {
                cachePrice.v8 = value;
            }
        }
        _prices[index] = cachePrice;
    }

    function batchSetAssetPrice(
        uint256[] memory indexes,
        UpdateInput[][] memory inputs
    ) external whenNotPaused {
        require(_operator == _msgSender(), "caller is not the operator");
        require(indexes.length == inputs.length, "length must be equal");

        for (uint256 i = 0; i < indexes.length; i++) {
            _setAssetPrice(indexes[i], inputs[i]);
        }
        emit SetAssetData(indexes, inputs);
    }
}