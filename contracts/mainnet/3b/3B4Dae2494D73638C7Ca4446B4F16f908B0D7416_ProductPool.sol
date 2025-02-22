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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library ConfigurationParam {
    address internal constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address internal constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address internal constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address internal constant WBTCCHAIN = 0xd0C7101eACbB49F3deCcCc166d238410D6D46d57;
    address internal constant WETHCHAIN = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    address internal constant ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address internal constant GUARDIAN = 0x366e2E5Ed08AA510c45138035d0F502A13F4718A;
    uint256 internal constant STABLEC_DECIMAL = 1e6;
    uint256 internal constant WETH_DECIMAL = 1e18;
    uint256 internal constant WBTC_DECIMAL = 1e8;
    uint256 internal constant ORACLE_DECIMAL = 1e8;
    uint256 internal constant FEE_DECIMAL = 1e6;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library DataTypes {
    struct PurchaseProduct {
        uint256 customerId;
        address customerAddress;
        uint256 amount;
        uint256 releaseHeight;
        address tokenAddress;
        uint256 customerReward;
        uint256 cryptoQuantity;
    }

    struct CustomerByCrypto {
        address customerAddress;
        address cryptoAddress;
        uint256 amount;
    }

    struct ExchangeTotal {
        address tokenIn;
        address tokenOut;
        uint256 tokenInAmount;
        uint256 tokenOutAmount;
    }

    struct ProductInfo {
        uint256 productId;
        uint256 conditionAmount;
        uint256 customerQuantity;
        address cryptoType;
        ProgressStatus resultByCondition;
        address cryptoExchangeAddress;
        uint256 releaseHeight;
        ProductType productType;
        uint256 soldTotalAmount;
        uint256 sellStartTime;
        uint256 sellEndTime;
        uint256 saleTotalAmount;
        uint256 maturityDate;
    }

    struct HedgingAggregatorInfo {
        uint256 customerId;
        uint256 productId;
        address customerAddress;
        uint256 amount;
        uint256 releaseHeight;
    }

    struct TransferHelperInfo {
        address from;
        address to;
        uint256 amount;
        address tokenAddress;
        TransferHelperStatus typeValue;
    }

    enum ProductType {
        BUY_LOW,
        SELL_HIGH
    }

    enum ProgressStatus {
        UNDELIVERED,
        REACHED,
        UNREACHED
    }

    //typeValue 0: customer to this, 1: this to customer principal, 2: this to customer reward, 3: this to valut, 4: this to manageWallet, 5 guardian withdraw
    enum TransferHelperStatus {
        TOTHIS,
        TOCUSTOMERP,
        TOCUSTOMERR,
        TOVALUT,
        TOMANAGE,
        GUARDIANW
    }
}

// SPDX-License-Identifier: GPL-3.0

/// This contract is responsible for recording product information.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../library/common/DataTypes.sol";
import {ConfigurationParam} from "../library/common/ConfigurationParam.sol";

contract ProductPool is Ownable, ReentrancyGuard {
    address public adminAddress;
    mapping(uint256 => DataTypes.ProductInfo) productPool;
    uint256[] productIdList;

    constructor(address _adminAddress) {
        adminAddress = _adminAddress;
    }

    /**
     * notice Launch new products.
     * @param product Product info.
     */
    function _s_publishProduct(DataTypes.ProductInfo memory product) external onlyOwner returns (bool) {
        require(product.cryptoType != address(0), "BasePositionManager: the cryptoType is null address");
        require(
            product.cryptoType == ConfigurationParam.WETH || product.cryptoType == ConfigurationParam.WBTC,
            "BasePositionManager: the cryptoType is error address"
        );
        if (product.cryptoType == ConfigurationParam.WETH) {
            product.cryptoExchangeAddress = ConfigurationParam.WETHCHAIN;
        } else {
            product.cryptoExchangeAddress = ConfigurationParam.WBTCCHAIN;
        }
        productPool[product.productId] = product;
        productIdList.push(product.productId);
        emit AddProduct(msg.sender, product);
        return true;
    }

    /**
     * notice Update product solds.
     * @param productId Product id.
     * @param sellAmount Sell amount.
     */
    function updateSoldTotalAmount(uint256 productId, uint256 sellAmount) external onlyAdmin returns (bool) {
        productPool[productId].soldTotalAmount = productPool[productId].soldTotalAmount + sellAmount;
        return true;
    }

    /**
     * notice Renew the amount available for sale.
     * @param productId Product id.
     * @param amount Sale amount.
     * @param boo Increase or decrease.
     */
    function setSaleTotalAmount(uint256 productId, uint256 amount, bool boo) external onlyOwner returns (bool) {
        if (boo) {
            productPool[productId].saleTotalAmount = productPool[productId].saleTotalAmount + amount;
        } else {
            uint256 TotalAmount = productPool[productId].saleTotalAmount - amount;
            require(
                TotalAmount >= productPool[productId].soldTotalAmount,
                "ProductManager: cannot be less than the pre-sale limit"
            );
            productPool[productId].saleTotalAmount = TotalAmount;
        }
        return true;
    }

    /**
     * notice Update product delivery status.
     * @param productId Product id.
     * @param resultByCondition ResultByCondition state.
     */
    function _s_retireProductAndUpdateInfo(
        uint256 productId,
        DataTypes.ProgressStatus resultByCondition
    ) external onlyAdmin returns (bool) {
        productPool[productId].resultByCondition = resultByCondition;
        return true;
    }

    function getProductInfoByPid(uint256 productId) external view returns (DataTypes.ProductInfo memory) {
        return productPool[productId];
    }

    function getProductList() public view returns (DataTypes.ProductInfo[] memory) {
        uint256 count;
        for (uint256 i = 0; i < productIdList.length; i++) {
            if (productPool[productIdList[i]].resultByCondition == DataTypes.ProgressStatus.UNDELIVERED) {
                count++;
            }
        }
        DataTypes.ProductInfo[] memory ProductList = new DataTypes.ProductInfo[](count);
        uint256 j;
        for (uint256 i = 0; i < productIdList.length; i++) {
            if (productPool[productIdList[i]].resultByCondition == DataTypes.ProgressStatus.UNDELIVERED) {
                ProductList[j] = productPool[productIdList[i]];
                j++;
            }
        }
        return ProductList;
    }

    modifier onlyAdmin() {
        require(adminAddress == msg.sender, "Ownable: caller is not the admin");
        _;
    }

    event AddProduct(address indexed owner, DataTypes.ProductInfo indexed productId);
}