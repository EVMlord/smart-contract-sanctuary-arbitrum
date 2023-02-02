// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IClearingHouse } from "./interface/IClearingHouse.sol";
import { IClearingHouseConfig } from "./interface/IClearingHouseConfig.sol";
import { IPositionMgmt } from "./interface/IPositionMgmt.sol";
import { IMarketTaker } from "./interface/IMarketTaker.sol";
import { ILiquidityProvider } from "./interface/ILiquidityProvider.sol";
import { IAmm } from "./interface/IAmm.sol";
import { IAmmFactory } from "./interface/IAmmFactory.sol";
import { IVault } from "./interface/IVault.sol";
import { IIndexPrice } from "./interface/IIndexPrice.sol";
import { IFairtradeReader } from "./interface/IFairtradeReader.sol";
import { Account } from "./lib/Account.sol";
import { Funding } from "./lib/Funding.sol";
import { FairtradeMath } from "./lib/FairtradeMath.sol";
import { FullMath } from "./lib/FullMath.sol";

contract FairtradeReader is Initializable, IFairtradeReader {
    using FairtradeMath for int256;
    using FairtradeMath for uint256;

    address internal _clearingHouse;
    address internal _clearingHouseConfig;
    address internal _positionMgmt;
    address internal _marketTaker;
    address internal _liquidityProvider;
    address internal _insuranceFund;
    address internal _ammFactory;
    address internal _vault;

    function initialize(
        address clearingHouseArg,
        address clearingHouseConfigArg,
        address positionMgmtArg,
        address marketTakerArg,
        address liquidityProviderArg,
        address insuranceFundArg,
        address ammFactoryArg,
        address vaultArg
    ) external initializer {
        _clearingHouse = clearingHouseArg;
        _clearingHouseConfig = clearingHouseConfigArg;
        _positionMgmt = positionMgmtArg;
        _marketTaker = marketTakerArg;
        _liquidityProvider = liquidityProviderArg;
        _insuranceFund = insuranceFundArg;
        _ammFactory = ammFactoryArg;
        _vault = vaultArg;
    }

    // long:
    // accountValue - positionSizeOfTokenX * (indexPrice - liqPrice) =
    //      totalPositionValue * mmRatio - positionSizeOfTokenX * (indexPrice - liqPrice) * mmRatio
    // liqPrice = indexPrice - ((accountValue - totalPositionValue * mmRatio) /  ((1 - mmRatio) * positionSizeOfTokenX))
    // short:
    // accountValue - positionSizeOfTokenX * (indexPrice - liqPrice) =
    //      totalPositionValue * mmRatio + positionSizeOfTokenX * (indexPrice - liqPrice) * mmRatio
    // liqPrice = indexPrice - ((accountValue - totalPositionValue * mmRatio) /  ((1 + mmRatio) * positionSizeOfTokenX))
    function getLiquidationPrice(address trader, address baseToken) external view override returns (uint256) {
        int256 accountValue = IClearingHouse(_clearingHouse).getAccountValue(trader);
        int256 positionSize = IPositionMgmt(_positionMgmt).getTotalPositionSize(trader, baseToken);

        if (positionSize == 0) return 0;

        uint256 indexPrice = IIndexPrice(baseToken).getIndexPrice(
            IClearingHouseConfig(_clearingHouseConfig).getTwapInterval()
        );
        uint256 totalPositionValue = IPositionMgmt(_positionMgmt).getTotalAbsPositionValue(trader);
        uint24 mmRatio = IClearingHouseConfig(_clearingHouseConfig).getMmRatio();

        int256 multiplier = positionSize > 0 ? uint256(1e6 - mmRatio).toInt256() : uint256(1e6 + mmRatio).toInt256();
        int256 remainedAccountValue = accountValue - (totalPositionValue.mulRatio(mmRatio).toInt256());
        int256 multipliedPositionSize = FairtradeMath.mulDiv(positionSize, multiplier, 1e6);
        int256 liquidationPrice = indexPrice.toInt256() - ((remainedAccountValue * 1e18) / multipliedPositionSize);

        return liquidationPrice >= 0 ? liquidationPrice.toUint256() : 0;
    }

    // ClearingHouse view functions
    function getAccountValue(address trader) external view returns (int256) {
        return IClearingHouse(_clearingHouse).getAccountValue(trader);
    }

    function getQuoteToken() external view returns (address) {
        return IClearingHouse(_clearingHouse).getQuoteToken();
    }

    // MarketTaker view functions
    function getAllPendingFundingPayment(address trader) external view returns (int256) {
        return IMarketTaker(_marketTaker).getAllPendingFundingPayment(trader);
    }

    function getPendingFundingPayment(address trader, address baseToken) external view returns (int256) {
        return IMarketTaker(_marketTaker).getPendingFundingPayment(trader, baseToken);
    }

    function getPnlToBeRealized(IMarketTaker.RealizePnlParams memory params) external view returns (int256) {
        return IMarketTaker(_marketTaker).getPnlToBeRealized(params);
    }

    // // LiquidityProvider view functions
    // function updateLPOrderDebt(
    //     bytes32 orderId,
    //     int256 base,
    //     int256 quote
    // ) external {
    //     return ILiquidityProvider(_liquidityProvider).updateLPOrderDebt(orderId, base, quote);
    // }

    function getOpenOrder(address trader, address baseToken) external view returns (Account.LPInfo memory) {
        return ILiquidityProvider(_liquidityProvider).getOpenOrder(trader, baseToken);
    }

    function getTotalLPQuoteAmountAndPendingFee(address trader, address[] calldata baseTokens)
        external
        view
        returns (int256 totalQuoteAmountInAmms, uint256 totalPendingFee)
    {
        return ILiquidityProvider(_liquidityProvider).getTotalLPQuoteAmountAndPendingFee(trader, baseTokens);
    }

    function getTotalTokenAmountInAmmAndPendingFee(
        address trader,
        address baseToken,
        bool fetchBase
    ) external view returns (uint256 tokenAmount, uint256 totalPendingFee) {
        return
            ILiquidityProvider(_liquidityProvider).getTotalTokenAmountInAmmAndPendingFee(trader, baseToken, fetchBase);
    }

    function getTotalLPOrderDebt(
        address trader,
        address baseToken,
        bool fetchBase
    ) external view returns (uint256) {
        return ILiquidityProvider(_liquidityProvider).getTotalLPOrderDebt(trader, baseToken, fetchBase);
    }

    /// @dev this is the view version of updateFundingGrowthAndLiquidityFundingPayment()
    /// @return liquidityFundingPayment the funding payment of all orders/liquidity of a maker
    function getLiquidityFundingPayment(
        address trader,
        address baseToken,
        Funding.Growth memory fundingGrowthGlobal
    ) external view returns (int256 liquidityFundingPayment) {
        return
            ILiquidityProvider(_liquidityProvider).getLiquidityFundingPayment(trader, baseToken, fundingGrowthGlobal);
    }

    function getPendingFee(address trader, address baseToken) external view returns (uint256) {
        return ILiquidityProvider(_liquidityProvider).getPendingFee(trader, baseToken);
    }

    // AmmFactory view functions
    function getAmm(address baseToken) external view returns (address) {
        return IAmmFactory(_ammFactory).getAmm(baseToken);
    }

    function getExchangeFeeRatio(address baseToken) external view returns (uint24) {
        return IAmmFactory(_ammFactory).getExchangeFeeRatio(baseToken);
    }

    function getInsuranceFundFeeRatio(address baseToken) external view returns (uint24) {
        return IAmmFactory(_ammFactory).getInsuranceFundFeeRatio(baseToken);
    }

    function getAmmInfo(address baseToken) external view returns (IAmmFactory.AmmInfo memory) {
        return IAmmFactory(_ammFactory).getAmmInfo(baseToken);
    }

    function hasAmm(address baseToken) external view returns (bool) {
        return IAmmFactory(_ammFactory).hasAmm(baseToken);
    }

    // Amm view functions
    function getDy(
        address baseToken,
        uint256 dx,
        bool isSwapWithBase,
        bool isSell
    ) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        if (isSwapWithBase) {
            return IAmm(amm).getDy(1, 0, dx, isSell);
        }

        return IAmm(amm).getDy(0, 1, dx, isSell);
    }

    function getA(address baseToken) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).getA();
    }

    function getGamma(address baseToken) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).getGamma();
    }

    function getCoins(address baseToken, uint256 i) external view returns (address) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).getCoins(i);
    }

    function getBalances(address baseToken, uint256 i) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).getBalances(i);
    }

    function getPriceScale(address baseToken) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).getPriceScale();
    }

    function getPriceOracle(address baseToken) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).getPriceOracle();
    }

    function getPriceLast(address baseToken) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).getPriceLast();
    }

    function getPriceCurrent(address baseToken) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).getPriceCurrent();
    }

    function getTwapMarkPrice(address baseToken, uint256 interval) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).getTwapMarkPrice(interval);
    }

    function getTotalLiquidity(address baseToken) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).getTotalLiquidity();
    }

    function calcTokenAmountsByLiquidity(address baseToken, uint256 liquidity)
        external
        view
        returns (uint256 amount0, uint256 amount1)
    {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).calcTokenAmountsByLiquidity(liquidity);
    }

    function calcLiquidityByTokenAmounts(
        address baseToken,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256) {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        return IAmm(amm).calcLiquidityByTokenAmounts(amount0Desired, amount1Desired);
    }

    function simulatedSwap(
        address baseToken,
        uint256 dx,
        bool isSwapWithBase,
        bool isSell
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address amm = IAmmFactory(_ammFactory).getAmm(baseToken);
        if (isSwapWithBase) {
            return IAmm(amm).simulatedSwap(1, 0, dx, isSell);
        }

        return IAmm(amm).simulatedSwap(0, 1, dx, isSell);
    }

    // PositionMgmt view functions
    function getBaseTokens(address trader) external view returns (address[] memory) {
        return IPositionMgmt(_positionMgmt).getBaseTokens(trader);
    }

    function getAccountInfo(address trader, address baseToken) external view returns (Account.TakerInfo memory) {
        return IPositionMgmt(_positionMgmt).getAccountInfo(trader, baseToken);
    }

    function getTakerOpenNotional(address trader, address baseToken) external view returns (int256) {
        return IPositionMgmt(_positionMgmt).getTakerOpenNotional(trader, baseToken);
    }

    function getTotalOpenNotional(address trader, address baseToken) external view returns (int256) {
        return IPositionMgmt(_positionMgmt).getTotalOpenNotional(trader, baseToken);
    }

    function getTotalDebtValue(address trader) external view returns (uint256) {
        return IPositionMgmt(_positionMgmt).getTotalDebtValue(trader);
    }

    function getMarginRequirementForLiquidation(address trader) external view returns (int256) {
        return IPositionMgmt(_positionMgmt).getMarginRequirementForLiquidation(trader);
    }

    function getPnlAndPendingFee(address trader)
        external
        view
        returns (
            int256 owedRealizedPnl,
            int256 unrealizedPnl,
            uint256 pendingFee
        )
    {
        return IPositionMgmt(_positionMgmt).getPnlAndPendingFee(trader);
    }

    function hasOrder(address trader) external view returns (bool) {
        return IPositionMgmt(_positionMgmt).hasOrder(trader);
    }

    function getBase(address trader, address baseToken) external view returns (int256) {
        return IPositionMgmt(_positionMgmt).getBase(trader, baseToken);
    }

    function getQuote(address trader, address baseToken) external view returns (int256) {
        return IPositionMgmt(_positionMgmt).getQuote(trader, baseToken);
    }

    function getTakerPositionSize(address trader, address baseToken) external view returns (int256) {
        return IPositionMgmt(_positionMgmt).getTakerPositionSize(trader, baseToken);
    }

    function getTotalPositionSize(address trader, address baseToken) external view returns (int256) {
        return IPositionMgmt(_positionMgmt).getTotalPositionSize(trader, baseToken);
    }

    function getTotalPositionValue(address trader, address baseToken) external view returns (int256) {
        return IPositionMgmt(_positionMgmt).getTotalPositionValue(trader, baseToken);
    }

    function getTotalAbsPositionValue(address trader) external view returns (uint256) {
        return IPositionMgmt(_positionMgmt).getTotalAbsPositionValue(trader);
    }

    // ClearingHouseConfig view functions
    function getMaxAmmsPerAccount() external view returns (uint8) {
        return IClearingHouseConfig(_clearingHouseConfig).getMaxAmmsPerAccount();
    }

    function getImRatio() external view returns (uint24) {
        return IClearingHouseConfig(_clearingHouseConfig).getImRatio();
    }

    function getMmRatio() external view returns (uint24) {
        return IClearingHouseConfig(_clearingHouseConfig).getMmRatio();
    }

    function getLiquidationPenaltyRatio() external view returns (uint24) {
        return IClearingHouseConfig(_clearingHouseConfig).getLiquidationPenaltyRatio();
    }

    function getPartialCloseRatio() external view returns (uint24) {
        return IClearingHouseConfig(_clearingHouseConfig).getPartialCloseRatio();
    }

    function getTwapInterval() external view returns (uint32) {
        return IClearingHouseConfig(_clearingHouseConfig).getTwapInterval();
    }

    function getSettlementTokenBalanceCap() external view returns (uint256) {
        return IClearingHouseConfig(_clearingHouseConfig).getSettlementTokenBalanceCap();
    }

    function getMaxFundingRate() external view returns (uint24) {
        return IClearingHouseConfig(_clearingHouseConfig).getMaxFundingRate();
    }

    function getFluctuationLimitRatio() external view returns (uint24) {
        return IClearingHouseConfig(_clearingHouseConfig).getFluctuationLimitRatio();
    }

    // Vault view functions
    function getBalance(address account) external view returns (int256) {
        return IVault(_vault).getBalance(account);
    }

    function getFreeCollateral(address trader) external view returns (uint256) {
        return IVault(_vault).getFreeCollateral(trader);
    }

    function getFreeCollateralByRatio(address trader, uint24 ratio) external view returns (int256) {
        return IVault(_vault).getFreeCollateralByRatio(trader, ratio);
    }

    function getSettlementToken() external view returns (address) {
        return IVault(_vault).getSettlementToken();
    }

    function vaultDecimals() external view returns (uint8) {
        return IVault(_vault).decimals();
    }

    function getTotalDebt() external view returns (uint256) {
        return IVault(_vault).getTotalDebt();
    }

    // view functions

    function getClearingHouse() external view returns (address) {
        return _clearingHouse;
    }

    function getClearingHouseConfig() external view returns (address) {
        return _clearingHouseConfig;
    }

    function getPositionMgmt() external view returns (address) {
        return _positionMgmt;
    }

    function getMarketTaker() external view returns (address) {
        return _marketTaker;
    }

    function getLiquidityProvider() external view returns (address) {
        return _liquidityProvider;
    }

    function getInsuranceFund() external view returns (address) {
        return _insuranceFund;
    }

    function getAmmFactory() external view returns (address) {
        return _ammFactory;
    }

    function getVault() external view returns (address) {
        return _vault;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface IAmm {
    /// @param coinPairs 0: quote token address, 1: base token address
    struct InitializeParams {
        uint256 A;
        uint256 gamma;
        uint256 adjustmentStep;
        uint256 maHalfTime;
        uint256 initialPrice;
        address baseToken;
        address quoteToken;
        address clearingHouse;
        address marketTaker;
        address liquidityProvider;
    }

    // Events
    event TokenExchange(address indexed buyer, uint256 i, uint256 dx, uint256 j, uint256 dy, bool isSell);

    event AddLiquidity(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity,
        uint256 totalLiquidity
    );

    event RemoveLiquidity(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity,
        uint256 totalLiquidity
    );

    event CommitNewParameters(uint256 indexed deadline, uint256 adjustmentStep, uint256 maHalfTime);

    event NewParameters(uint256 adjustmentStep, uint256 maHalfTime);

    event RampAgamma(
        uint256 initialA,
        uint256 futureA,
        uint256 initialGamma,
        uint256 futureGamma,
        uint256 initialTime,
        uint256 futureTime
    );

    event Repegging(
        address sender,
        uint256 accumulatedFees,
        uint256 loss,
        uint256 newD,
        uint256 priceScale,
        uint256 priceOracle
    );

    event StopRampA(uint256 currentA, uint256 currentGamma, uint256 time);

    event CalcPriceAfterSwap(address sender, uint256 amountIn, uint256 amountOut, uint256 priceAfter, bool isSell);

    event ClearingHouseChanged(address clearingHouse);

    event MarketTakerChanged(address marketTaker);

    event LiquidityProviderChanged(address liquidityProvider);

    event TotalValueLockedCapChanged(uint256 cap);

    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 minLiquidity
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(
        uint256 liquidity,
        uint256 minAmount0,
        uint256 minAmount1
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 dyLimit,
        bool isSell
    ) external returns (uint256);

    function simulatedSwap(
        uint256 i,
        uint256 j,
        uint256 dx,
        bool isSell
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function getDy(
        uint256 i,
        uint256 j,
        uint256 dx,
        bool isSell
    ) external view returns (uint256);

    function getA() external view returns (uint256);

    function getGamma() external view returns (uint256);

    function getCoins(uint256 i) external view returns (address);

    function getBalances(uint256 i) external view returns (uint256);

    function getPriceScale() external view returns (uint256);

    function getPriceOracle() external view returns (uint256);

    function getPriceLast() external view returns (uint256);

    function getPriceCurrent() external view returns (uint256);

    function getTwapMarkPrice(uint256 interval) external view returns (uint256);

    function getTotalLiquidity() external view returns (uint256);

    function getTotalVauleLockedCap() external view returns (uint256);

    function calcTokenAmountsByLiquidity(uint256 liquidity) external view returns (uint256 amount0, uint256 amount1);

    function calcLiquidityByTokenAmounts(uint256 amount0Desired, uint256 amount1Desired)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

interface IAmmFactory {
    struct AmmInfo {
        address amm;
        uint24 exchangeFeeRatio;
        uint24 insuranceFundFeeRatio;
    }

    event AmmAdded(address indexed baseToken, uint24 indexed exchangeFeeRatio, address indexed amm);

    event ExchangeFeeRatioChanged(address baseToken, uint24 exchangeFeeRatio);

    event InsuranceFundFeeRatioChanged(uint24 insuranceFundFeeRatio);

    function addAmm(
        address baseToken,
        address amm,
        uint24 exchangeFeeRatio
    ) external;

    function setExchangeFeeRatio(address baseToken, uint24 exchangeFeeRatio) external;

    function setInsuranceFundFeeRatio(address baseToken, uint24 insuranceFundFeeRatioArg) external;

    function getAmm(address baseToken) external view returns (address);

    function getExchangeFeeRatio(address baseToken) external view returns (uint24);

    function getInsuranceFundFeeRatio(address baseToken) external view returns (uint24);

    function getAmmInfo(address baseToken) external view returns (AmmInfo memory);

    function getQuoteToken() external view returns (address);

    function hasAmm(address baseToken) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

interface IClearingHouse {
    struct AddLiquidityParams {
        address baseToken;
        uint256 base;
        uint256 quote;
        uint256 minLiquidity;
        uint256 deadline;
    }

    struct RemoveLiquidityParams {
        address baseToken;
        uint256 liquidity;
        uint256 minBase;
        uint256 minQuote;
        uint256 deadline;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 fee;
        uint256 liquidity;
    }

    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 fee;
    }

    // Open Long
    //      isSwapWithBase = true, isSell = false -> open long with exact btc
    //      isSwapWithBase = false, isSell = true -> open long with exact usdc
    // Open Short
    //      isSwapWithBase = true, isSell = true -> open short with exact btc
    //      isSwapWithBase = false, isSell = false -> open short with exact usdc
    // Close Long
    //      isSwapWithBase = true, isSell = true -> close long with exact btc
    // Close Short
    //      isSwapWithBase = true, isSell = false -> close short with exact btc
    //
    /// @param amountLimit
    //      isSell = true: the price cannot be less than amountLimit after the swap
    //      isSell = false: the price cannot be greater than amountLimit after the swap
    struct OpenPositionParams {
        address baseToken;
        bool isSwapWithBase;
        bool isSell;
        uint256 amount;
        uint256 amountLimit;
        uint256 deadline;
        bytes32 referralCode;
    }

    struct ClosePositionParams {
        address baseToken;
        uint256 amountLimit;
        uint256 deadline;
        bytes32 referralCode;
    }

    /// @notice Emitted when open position with non-zero referral code
    /// @param referralCode The referral code by partners
    event ReferredPositionChanged(bytes32 indexed referralCode);

    event PositionLiquidated(
        address indexed trader,
        address indexed baseToken,
        uint256 positionNotional,
        uint256 positionSize,
        uint256 liquidationFee,
        address liquidator
    );

    /// @param base the amount of base token added (> 0) / removed (< 0) as liquidity; fees not included
    /// @param quote the amount of quote token added ... (same as the above)
    /// @param liquidity the amount of liquidity unit added (> 0) / removed (< 0)
    /// @param quoteFee the amount of quote token the maker received as fees
    event LiquidityChanged(
        address indexed maker,
        address indexed baseToken,
        address indexed quoteToken,
        int256 base,
        int256 quote,
        int256 liquidity,
        uint256 quoteFee
    );

    event PositionChanged(
        address indexed trader,
        address indexed baseToken,
        int256 exchangedPositionSize,
        int256 exchangedPositionNotional,
        uint256 fee,
        int256 openNotional,
        int256 realizedPnl,
        uint256 priceAfter
    );

    /// @param fundingPayment > 0: payment, < 0 : receipt
    event FundingPaymentSettled(address indexed trader, address indexed baseToken, int256 fundingPayment);

    event TrustedForwarderChanged(address indexed forwarder);

    /// @dev tx will fail if adding base == 0 && quote == 0 / liquidity == 0
    function addLiquidity(AddLiquidityParams calldata params) external returns (AddLiquidityResponse memory);

    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (RemoveLiquidityResponse memory response);

    function settleAllFunding(address trader) external;

    function openPositionFor(address tarder, OpenPositionParams memory params)
        external
        returns (
            uint256 base,
            uint256 quote,
            uint256 fee
        );

    function openPosition(OpenPositionParams memory params) external returns (uint256 base, uint256 quote);

    function closePosition(ClosePositionParams calldata params) external returns (uint256 base, uint256 quote);

    function liquidate(
        address trader,
        address baseToken,
        uint256 amountLimit
    ) external;

    function cancelOpenOrder(address maker, address baseToken) external;

    function getAccountValue(address trader) external view returns (int256);

    function getQuoteToken() external view returns (address);

    function getClearingHouseConfig() external view returns (address);

    function getVault() external view returns (address);

    function getMarketTaker() external view returns (address);

    function getLiquidityProvider() external view returns (address);

    function getPositionMgmt() external view returns (address);

    function getInsuranceFund() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface IClearingHouseConfig {
    event PartialCloseRatioChanged(uint24 partialCloseRatio);

    event LiquidationPenaltyRatioChanged(uint24 liquidationPenaltyRatio);

    event MaxFundingRateChanged(uint24 maxFundingRate);

    event FluctuationLimitRatioChanged(uint24 fluctuationLimitRatio);

    event TwapIntervalChanged(uint32 twapInterval);

    event MaxAmmsPerAccountChanged(uint8 maxAmmsPerAccount);

    event SettlementTokenBalanceCapChanged(uint256 cap);

    event BackstopLiquidityProviderChanged(address indexed account, bool indexed isProvider);

    function getImRatio() external view returns (uint24);

    function getMmRatio() external view returns (uint24);

    function getPartialCloseRatio() external view returns (uint24);

    function getLiquidationPenaltyRatio() external view returns (uint24);

    function getMaxFundingRate() external view returns (uint24);

    function getFluctuationLimitRatio() external view returns (uint24);

    function getTwapInterval() external view returns (uint32);

    function getMaxAmmsPerAccount() external view returns (uint8);

    function getSettlementTokenBalanceCap() external view returns (uint256);

    function isBackstopLiquidityProvider(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface IFairtradeReader {
    function getLiquidationPrice(address trader, address baseToken) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface IIndexPrice {
    /// @dev Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    function getIndexPrice(uint256 interval) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { Funding } from "../lib/Funding.sol";
import { Account } from "../lib/Account.sol";

interface ILiquidityProvider {
    struct AddLiquidityParams {
        address maker;
        address baseToken;
        uint256 base;
        uint256 quote;
        uint256 minLiquidity;
        Funding.Growth fundingGrowthGlobal;
    }

    struct RemoveLiquidityParams {
        address maker;
        address baseToken;
        uint256 liquidity;
        uint256 minBase;
        uint256 minQuote;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 fee;
        uint256 liquidity;
    }

    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 fee;
        int256 takerBase;
        int256 takerQuote;
    }

    /// @param trader the address of trader contract
    event MarketTakerChanged(address indexed trader);

    function addLiquidity(AddLiquidityParams calldata params) external returns (AddLiquidityResponse memory);

    function removeLiquidity(RemoveLiquidityParams calldata params) external returns (RemoveLiquidityResponse memory);

    // function updateLPOrderDebt(
    //     address trader,
    //     address baseToken,
    //     int256 base,
    //     int256 quote
    // ) external;

    function getOpenOrder(address trader, address baseToken) external view returns (Account.LPInfo memory);

    function hasOrder(address trader, address[] calldata tokens) external view returns (bool);

    function getTotalLPQuoteAmountAndPendingFee(address trader, address[] calldata baseTokens)
        external
        view
        returns (int256 totalQuoteAmountInAmms, uint256 totalPendingFee);

    /// @dev the returned quote amount does not include funding payment because
    ///      the latter is counted directly toward realizedPnl.
    ///      the return value includes maker fee.
    ///      please refer to _getTotalTokenAmountInAmm() docstring for specs
    function getTotalTokenAmountInAmmAndPendingFee(
        address trader,
        address baseToken,
        bool fetchBase
    ) external view returns (uint256 tokenAmount, uint256 totalPendingFee);

    function getTotalLPOrderDebt(
        address trader,
        address baseToken,
        bool fetchBase
    ) external view returns (uint256);

    /// @dev this is the view version of updateFundingGrowthAndLiquidityFundingPayment()
    /// @return liquidityFundingPayment the funding payment of all orders/liquidity of a maker
    function getLiquidityFundingPayment(
        address trader,
        address baseToken,
        Funding.Growth memory fundingGrowthGlobal
    ) external view returns (int256 liquidityFundingPayment);

    function getPendingFee(address trader, address baseToken) external view returns (uint256);

    /// @dev this is the non-view version of getLiquidityFundingPayment()
    /// @return liquidityFundingPayment the funding payment of all orders/liquidity of a maker
    function updateFundingGrowthAndLiquidityFundingPayment(
        address trader,
        address baseToken,
        Funding.Growth memory fundingGrowthGlobal
    ) external returns (int256 liquidityFundingPayment);

    function getMarketTaker() external view returns (address);

    function updateLPCalcFeeRatio(address baseToken, uint256 fee) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { Funding } from "../lib/Funding.sol";

interface IMarketTaker {
    /// @param amount when closing position, amount(uint256) == takerPositionSize(int256),
    ///        as amount is assigned as takerPositionSize in ClearingHouse.closePosition()
    struct SwapParams {
        address trader;
        address baseToken;
        bool isSwapWithBase;
        bool isSell;
        bool isClose;
        uint256 amount;
        uint256 amountLimit;
    }

    struct SwapResponse {
        int256 base;
        int256 quote;
        int256 exchangedPositionSize;
        int256 exchangedPositionNotional;
        uint256 fee;
        uint256 insuranceFundFee;
        int256 pnlToBeRealized;
    }

    struct RealizePnlParams {
        address trader;
        address baseToken;
        int256 base;
        int256 quote;
    }

    event FundingUpdated(address indexed baseToken, uint256 markTwap, uint256 indexTwap);

    /// @param positionMgmt The address of positionMgmt contract
    event PositionMgmtChanged(address positionMgmt);

    function swap(SwapParams memory params) external returns (SwapResponse memory);

    /// @dev this function should be called at the beginning of every high-level function, such as openPosition()
    ///      while it doesn't matter who calls this function
    ///      this function 1. settles personal funding payment 2. updates global funding growth
    ///      personal funding payment is settled whenever there is pending funding payment
    ///      the global funding growth update only happens once per unique timestamp (not blockNumber, due to Arbitrum)
    /// @return fundingPayment the funding payment of a trader in one amm should be settled into owned realized Pnl
    /// @return fundingGrowthGlobal the up-to-date globalFundingGrowth, usually used for later calculations
    function settleFunding(address trader, address baseToken)
        external
        returns (int256 fundingPayment, Funding.Growth memory fundingGrowthGlobal);

    function resetAccumulatedFee(address baseToken) external;

    function getAccumulatedFee(address baseToken) external view returns (uint256);

    function getAllPendingFundingPayment(address trader) external view returns (int256);

    /// @dev this is the view version of _updateFundingGrowth()
    /// @return the pending funding payment of a trader in one amm, including liquidity & position
    function getPendingFundingPayment(address trader, address baseToken) external view returns (int256);

    function getMarkPrice(address baseToken) external view returns (uint256);

    function getTwapMarkPrice(address baseToken, uint32 twapInterval) external view returns (uint256);

    function getPnlToBeRealized(RealizePnlParams memory params) external view returns (int256);

    function getLiquidityProvider() external view returns (address);

    function getPositionMgmt() external view returns (address);

    function getClearingHouseConfig() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { Account } from "../lib/Account.sol";

interface IPositionMgmt {
    /// @param vault The address of the vault contract
    event VaultChanged(address indexed vault);

    /// @dev Emit whenever a trader's `owedRealizedPnl` is updated
    /// @param trader The address of the trader
    /// @param amount The amount changed
    event PnlRealized(address indexed trader, int256 amount);

    function modifyTakerBalance(
        address trader,
        address baseToken,
        int256 base,
        int256 quote
    ) external returns (int256, int256);

    function modifyOwedRealizedPnl(address trader, int256 amount) external;

    function settleQuoteToOwedRealizedPnl(
        address trader,
        address baseToken,
        int256 amount
    ) external;

    /// @dev this function is now only called by Vault.withdraw()
    function settleOwedRealizedPnl(address trader) external returns (int256 pnl);

    /// @dev Settle account balance and deregister base token
    /// @param maker The address of the maker
    /// @param baseToken The address of the amm's base token
    /// @param realizedPnl Amount of pnl realized
    /// @param fee Amount of fee collected from amm
    function settleBalanceAndDeregister(
        address maker,
        address baseToken,
        int256 takerBase,
        int256 takerQuote,
        int256 realizedPnl,
        int256 fee
    ) external;

    /// @dev every time a trader's position value is checked, the base token list of this trader will be traversed;
    ///      thus, this list should be kept as short as possible
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    function registerBaseToken(address trader, address baseToken) external;

    /// @dev this function is expensive
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    function deregisterBaseToken(address trader, address baseToken) external;

    function updateTwPremiumGrowthGlobal(
        address trader,
        address baseToken,
        int256 lastTwPremiumGrowthGlobal
    ) external;

    function getClearingHouseConfig() external view returns (address);

    function getLiquidityProvider() external view returns (address);

    function getVault() external view returns (address);

    function getBaseTokens(address trader) external view returns (address[] memory);

    function getAccountInfo(address trader, address baseToken) external view returns (Account.TakerInfo memory);

    function getTakerOpenNotional(address trader, address baseToken) external view returns (int256);

    /// @return totalOpenNotional the amount of quote token paid for a position when opening
    function getTotalOpenNotional(address trader, address baseToken) external view returns (int256);

    function getTotalDebtValue(address trader) external view returns (uint256);

    /// @dev this is different from Vault._getTotalMarginRequirement(), which is for freeCollateral calculation
    /// @return int instead of uint, as it is compared with ClearingHouse.getAccountValue(), which is also an int
    function getMarginRequirementForLiquidation(address trader) external view returns (int256);

    /// @return owedRealizedPnl the pnl realized already but stored temporarily in PositionMgmt
    /// @return unrealizedPnl the pnl not yet realized
    /// @return pendingFee the pending fee of maker earned
    function getPnlAndPendingFee(address trader)
        external
        view
        returns (
            int256 owedRealizedPnl,
            int256 unrealizedPnl,
            uint256 pendingFee
        );

    function hasOrder(address trader) external view returns (bool);

    function getBase(address trader, address baseToken) external view returns (int256);

    function getQuote(address trader, address baseToken) external view returns (int256);

    function getTakerPositionSize(address trader, address baseToken) external view returns (int256);

    function getTotalPositionSize(address trader, address baseToken) external view returns (int256);

    /// @dev a negative returned value is only be used when calculating pnl
    /// @dev we use 15 mins twap to calc position value
    function getTotalPositionValue(address trader, address baseToken) external view returns (int256);

    /// @return sum up positions value of every amm, it calls `getTotalPositionValue` internally
    function getTotalAbsPositionValue(address trader) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface IVault {
    event Deposited(address indexed collateralToken, address indexed trader, uint256 amount);

    event Withdrawn(address indexed collateralToken, address indexed trader, uint256 amount);

    /// @param token the address of the token to deposit;
    ///        once multi-collateral is implemented, the token is not limited to settlementToken
    /// @param amountX10_D the amount of the token to deposit in decimals D (D = _decimals)
    function deposit(address token, uint256 amountX10_D) external;

    /// @notice Deposit the collateral token for other account
    /// @param to The address of the account to deposit to
    /// @param token The address of collateral token
    /// @param amountX10_D The amount of the token to deposit
    function depositFor(
        address to,
        address token,
        uint256 amountX10_D
    ) external;

    /// @param token the address of the token sender is going to withdraw
    ///        once multi-collateral is implemented, the token is not limited to settlementToken
    /// @param amountX10_D the amount of the token to withdraw in decimals D (D = _decimals)
    function withdraw(address token, uint256 amountX10_D) external;

    function getBalance(address account) external view returns (int256);

    /// @param trader The address of the trader to query
    /// @return freeCollateral Max(0, amount of collateral available for withdraw or opening new positions or orders)
    function getFreeCollateral(address trader) external view returns (uint256);

    /// @dev there are three configurations for different insolvency risk tolerances: conservative, moderate, aggressive
    ///      we will start with the conservative one and gradually move to aggressive to increase capital efficiency
    /// @param trader the address of the trader
    /// @param ratio the margin requirement ratio, imRatio or mmRatio
    /// @return freeCollateralByRatio freeCollateral, by using the input margin requirement ratio; can be negative
    function getFreeCollateralByRatio(address trader, uint24 ratio) external view returns (int256);

    function getSettlementToken() external view returns (address);

    /// @dev cached the settlement token's decimal for gas optimization
    function decimals() external view returns (uint8);

    function getTotalDebt() external view returns (uint256);

    function getClearingHouseConfig() external view returns (address);

    function getPositionMgmt() external view returns (address);

    function getInsuranceFund() external view returns (address);

    function getMarketTaker() external view returns (address);

    function getClearingHouse() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

library Account {
    struct TakerInfo {
        int256 takerPositionSize;
        int256 takerOpenNotional;
        int256 lastTwPremiumGrowthGlobal;
    }

    struct LPInfo {
        uint256 liquidity;
        uint256 lastExchangeFeeIndex;
        int256 lastTwPremiumGrowth;
        int256 lastTwPremiumWithLiquidityGrowth;
        uint256 baseDebt;
        uint256 quoteDebt;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

library Constant {
    address internal constant ADDRESS_ZERO = address(0);
    uint256 internal constant DECIMAL_ONE = 1e18;
    int256 internal constant DECIMAL_ONE_SIGNED = 1e18;
    uint256 internal constant IQ96 = 0x1000000000000000000000000;
    int256 internal constant IQ96_SIGNED = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { FullMath } from "./FullMath.sol";
import { Constant } from "./Constant.sol";

library FairtradeMath {
    function copy(uint256[2] memory data) internal pure returns (uint256[2] memory) {
        uint256[2] memory result;
        for (uint8 i = 0; i < 2; i++) {
            result[i] = data[i];
        }
        return result;
    }

    function shift(uint256 x, int256 _shift) internal pure returns (uint256) {
        if (_shift > 0) {
            return x << abs(_shift);
        } else if (_shift < 0) {
            return x >> abs(_shift);
        }

        return x;
    }

    function bitwiseOr(uint256 x, uint256 y) internal pure returns (uint256) {
        return x | y;
    }

    function bitwiseAnd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x & y;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? toUint256(value) : toUint256(neg256(value));
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "FairtradeMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -toInt256(a);
    }

    function formatX1e18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, Constant.IQ96, 1 ether);
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : toInt256(unsignedResult);

        return result;
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0, "denominator must be greater than 0");
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

import { FairtradeMath } from "./FairtradeMath.sol";
import { Account } from "./Account.sol";
import { Constant } from "./Constant.sol";

library Funding {
    using FairtradeMath for int256;
    using FairtradeMath for uint256;

    //
    // STRUCT
    //

    /// @dev tw: time-weighted
    /// @param twPremium overflow inspection (as twPremium > twPremiumWithLiquidity):
    //         max = 2 ^ (255 - 96) = 2 ^ 159 = 7.307508187E47
    //         assume premium = 10000, time = 10 year = 60 * 60 * 24 * 365 * 10 -> twPremium = 3.1536E12
    struct Growth {
        int256 twPremium;
        int256 twPremiumWithLiquidity;
    }

    //
    // CONSTANT
    //

    /// @dev block-based funding is calculated as: premium * timeFraction / 1 day, for 1 day as the default period
    int256 internal constant _DEFAULT_FUNDING_PERIOD = 1 days;

    //
    // INTERNAL PURE
    //

    function calcPendingFundingPayment(
        int256 baseBalance,
        int256 twPremiumGrowthGlobal,
        Growth memory fundingGrowthGlobal,
        int256 liquidityFundingPayment
    ) internal pure returns (int256) {
        int256 positionFundingPayment = FairtradeMath.mulDiv(
            baseBalance,
            (fundingGrowthGlobal.twPremium - twPremiumGrowthGlobal),
            Constant.IQ96
        );

        int256 pendingFundingPayment = (liquidityFundingPayment + positionFundingPayment) / _DEFAULT_FUNDING_PERIOD;

        // make RoundingUp to avoid bed debt
        // if pendingFundingPayment > 0: long pay 1wei more, short got 1wei less
        // if pendingFundingPayment < 0: long got 1wei less, short pay 1wei more
        if (pendingFundingPayment != 0) {
            pendingFundingPayment++;
        }

        return pendingFundingPayment;
    }

    /// @return liquidityFundingPayment the funding payment of an LP order
    function calcLiquidityFundingPayment(Account.LPInfo memory order, Funding.Growth memory fundingGrowthGlobal)
        internal
        pure
        returns (int256)
    {
        if (order.liquidity == 0) {
            return 0;
        }

        int256 fundingPaymentLP = order.liquidity.toInt256() *
            (fundingGrowthGlobal.twPremiumWithLiquidity - order.lastTwPremiumWithLiquidityGrowth);
        return fundingPaymentLP / Constant.IQ96_SIGNED;
    }
}