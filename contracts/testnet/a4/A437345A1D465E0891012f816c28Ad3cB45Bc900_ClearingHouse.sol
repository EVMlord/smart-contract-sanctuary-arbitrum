// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SigmaMath } from "../lib/SigmaMath.sol";
import { Funding } from "../lib/Funding.sol";
import { Account } from "../lib/Account.sol";
import { SettlementToken } from "../lib/SettlementToken.sol";
import { IERC20Metadata } from "../interface/IERC20Metadata.sol";
import { IVault } from "../interface/IVault.sol";
import { IMarketTaker } from "../interface/IMarketTaker.sol";
import { ILiquidityProvider } from "../interface/ILiquidityProvider.sol";
import { IClearingHouseConfig } from "../interface/IClearingHouseConfig.sol";
import { IPositionMgmt } from "../interface/IPositionMgmt.sol";
import { IClearingHouse } from "../interface/IClearingHouse.sol";
import { OwnerPausable } from "../base/OwnerPausable.sol";
import { BaseRelayRecipient } from "../gsn/BaseRelayRecipient.sol";
import { ClearingHouseStorageV1 } from "../storage/ClearingHouseStorage.sol";
import { ClearingHouseValidation } from "./ClearingHouseValidation.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract ClearingHouse is
    IClearingHouse,
    ReentrancyGuardUpgradeable,
    OwnerPausable,
    BaseRelayRecipient,
    ClearingHouseValidation,
    ClearingHouseStorageV1
{
    using AddressUpgradeable for address;
    using SigmaMath for uint256;
    using SigmaMath for int256;

    struct InternalOpenPositionParams {
        address trader;
        address baseToken;
        bool isSwapWithBase;
        bool isSell;
        bool isClose;
        uint256 amount;
        uint256 amountLimit;
        bool isLiquidation;
    }

    struct InternalClosePositionParams {
        address trader;
        address baseToken;
        uint256 amountLimit;
        bool isLiquidation;
    }

    /// @dev this function is public for testing
    // solhint-disable-next-line func-order
    function initialize(
        address clearingHouseConfigArg,
        address vaultArg,
        address quoteTokenArg,
        address marketTakerArg,
        address positionMgmtArg,
        address insuranceFundArg
    ) public initializer {
        // CH_VANC: Vault address is not contract
        require(vaultArg.isContract(), "CH_VANC");
        // CH_QANC: QuoteToken address is not contract
        require(quoteTokenArg.isContract(), "CH_QANC");
        // CH_QDN18: QuoteToken decimals is not 18
        require(IERC20Metadata(quoteTokenArg).decimals() == 18, "CH_QDN18");
        // CH_CCNC: ClearingHouseConfig address is not contract
        require(clearingHouseConfigArg.isContract(), "CH_CCNC");
        // CH_PMNC: PositionMgmt is not contract
        require(positionMgmtArg.isContract(), "CH_PMNC");
        // CH_MTNC: MarketTaker is not contract
        require(marketTakerArg.isContract(), "CH_MTNC");
        // CH_IFANC: InsuranceFund address is not contract
        require(insuranceFundArg.isContract(), "CH_IFANC");

        address liquidityProviderArg = IMarketTaker(marketTakerArg).getLiquidityProvider();
        // CH_OBNC: liquidityProvider is not contract
        require(liquidityProviderArg.isContract(), "CH_LPNC");

        __ReentrancyGuard_init();
        __OwnerPausable_init();

        _clearingHouseConfig = clearingHouseConfigArg;
        _vault = vaultArg;
        _quoteToken = quoteTokenArg;
        _marketTaker = marketTakerArg;
        _liquidityProvider = liquidityProviderArg;
        _positionMgmt = positionMgmtArg;
        _insuranceFund = insuranceFundArg;

        _settlementTokenDecimals = IVault(_vault).decimals();
    }

    // solhint-disable-next-line func-order
    function setTrustedForwarder(address trustedForwarderArg) external onlyOwner {
        // CH_TFNC: TrustedForwarder is not contract
        require(trustedForwarderArg.isContract(), "CH_TFNC");
        _setTrustedForwarder(trustedForwarderArg);
        emit TrustedForwarderChanged(trustedForwarderArg);
    }

    function approve(address token, address account) external onlyOwner {
        IERC20Metadata(token).approve(account, type(uint256).max);
    }

    /// @inheritdoc IClearingHouse
    function addLiquidity(AddLiquidityParams calldata params)
        external
        override
        whenNotPaused
        nonReentrant
        checkDeadline(params.deadline)
        returns (AddLiquidityResponse memory)
    {
        address trader = _msgSender();

        // register token if it's the first time
        IPositionMgmt(_positionMgmt).registerBaseToken(trader, params.baseToken);

        // must settle funding first
        Funding.Growth memory fundingGrowthGlobal = _settleFunding(trader, params.baseToken);

        ILiquidityProvider.AddLiquidityResponse memory response = ILiquidityProvider(_liquidityProvider).addLiquidity(
            ILiquidityProvider.AddLiquidityParams({
                maker: trader,
                baseToken: params.baseToken,
                base: params.base,
                quote: params.quote,
                minLiquidity: params.minLiquidity,
                fundingGrowthGlobal: fundingGrowthGlobal
            })
        );

        // fees always have to be collected to owedRealizedPnl, as long as there is a change in liquidity
        IPositionMgmt(_positionMgmt).modifyOwedRealizedPnl(trader, response.fee.toInt256());

        // after token balances are updated, we can check if there is enough free collateral
        _requireEnoughFreeCollateral(trader);

        emit LiquidityChanged(
            trader,
            params.baseToken,
            _quoteToken,
            response.base.toInt256(),
            response.quote.toInt256(),
            response.liquidity.toInt256(),
            response.fee
        );

        return
            AddLiquidityResponse({
                base: response.base,
                quote: response.quote,
                fee: response.fee,
                liquidity: response.liquidity
            });
    }

    /// @inheritdoc IClearingHouse
    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        override
        whenNotPaused
        nonReentrant
        checkDeadline(params.deadline)
        returns (RemoveLiquidityResponse memory)
    {
        // input requirement checks:
        //   baseToken: in MarketTaker.settleFunding()
        //   minBase, minQuote & deadline: here

        address trader = _msgSender();

        // must settle funding first
        _settleFunding(trader, params.baseToken);

        ILiquidityProvider.RemoveLiquidityResponse memory response = ILiquidityProvider(_liquidityProvider)
            .removeLiquidity(
                ILiquidityProvider.RemoveLiquidityParams({
                    maker: trader,
                    baseToken: params.baseToken,
                    liquidity: params.liquidity,
                    minBase: params.minBase,
                    minQuote: params.minQuote
                })
            );

        int256 realizedPnl = _settleBalanceAndRealizePnl(trader, params.baseToken, response);

        emit LiquidityChanged(
            trader,
            params.baseToken,
            _quoteToken,
            response.base.neg256(),
            response.quote.neg256(),
            params.liquidity.neg256(),
            response.fee
        );

        int256 openNotional = IPositionMgmt(_positionMgmt).getTakerOpenNotional(trader, params.baseToken);
        uint256 markPriceAfter = IMarketTaker(_marketTaker).getMarkPrice(params.baseToken);

        emit PositionChanged(
            trader,
            params.baseToken,
            response.takerBase, // exchangedPositionSize
            response.takerQuote, // exchangedPositionNotional
            0,
            openNotional,
            realizedPnl,
            markPriceAfter
        );

        return RemoveLiquidityResponse({ quote: response.quote, base: response.base, fee: response.fee });
    }

    function settleAllFunding(address trader) external override {
        address[] memory baseTokens = IPositionMgmt(_positionMgmt).getBaseTokens(trader);
        uint256 baseTokenLength = baseTokens.length;
        for (uint256 i = 0; i < baseTokenLength; i++) {
            _settleFunding(trader, baseTokens[i]);
        }
    }

    /// @inheritdoc IClearingHouse
    function openPositionFor(address trader, OpenPositionParams memory params)
        external
        override
        whenNotPaused
        nonReentrant
        checkDeadline(params.deadline)
        returns (
            uint256 base,
            uint256 quote,
            uint256 fee
        )
    {
        // input requirement checks:
        //   baseToken: in MarketTaker.settleFunding()
        //   isSell: X
        //   deadline: here

        // register token if it's the first time
        IPositionMgmt(_positionMgmt).registerBaseToken(trader, params.baseToken);

        // must settle funding first
        _settleFunding(trader, params.baseToken);

        IMarketTaker.SwapResponse memory response = _openPosition(
            InternalOpenPositionParams({
                trader: trader,
                baseToken: params.baseToken,
                isSwapWithBase: params.isSwapWithBase,
                isSell: params.isSell,
                amount: params.amount,
                amountLimit: params.amountLimit,
                isClose: false,
                isLiquidation: false
            })
        );

        return (response.base.abs(), response.quote.abs(), response.fee);
    }

    /// @inheritdoc IClearingHouse
    function openPosition(OpenPositionParams memory params)
        external
        override
        whenNotPaused
        nonReentrant
        checkDeadline(params.deadline)
        returns (uint256 base, uint256 quote)
    {
        // input requirement checks:
        //   baseToken: in MarketTaker.settleFunding()
        //   isSell: X
        //   deadline: here

        address trader = _msgSender();
        // register token if it's the first time
        IPositionMgmt(_positionMgmt).registerBaseToken(trader, params.baseToken);

        // must settle funding first
        _settleFunding(trader, params.baseToken);

        IMarketTaker.SwapResponse memory response = _openPosition(
            InternalOpenPositionParams({
                trader: trader,
                baseToken: params.baseToken,
                isSwapWithBase: params.isSwapWithBase,
                isSell: params.isSell,
                amount: params.amount,
                amountLimit: params.amountLimit,
                isClose: false,
                isLiquidation: false
            })
        );

        if (params.referralCode != 0) {
            emit ReferredPositionChanged(params.referralCode);
        }
        return (response.base.abs(), response.quote.abs());
    }

    /// @inheritdoc IClearingHouse
    function closePosition(ClosePositionParams calldata params)
        external
        override
        whenNotPaused
        nonReentrant
        checkDeadline(params.deadline)
        returns (uint256 base, uint256 quote)
    {
        // input requirement checks:
        //   baseToken: in MarketTaker.settleFunding()
        //   deadline: here

        address trader = _msgSender();

        // must settle funding first
        _settleFunding(trader, params.baseToken);

        IMarketTaker.SwapResponse memory response = _closePosition(
            InternalClosePositionParams({
                trader: trader,
                baseToken: params.baseToken,
                amountLimit: params.amountLimit,
                isLiquidation: false
            })
        );

        if (params.referralCode != 0) {
            emit ReferredPositionChanged(params.referralCode);
        }
        return (response.base.abs(), response.quote.abs());
    }

    /// @inheritdoc IClearingHouse
    function liquidate(
        address trader,
        address baseToken,
        uint256 amountLimit
    ) external override whenNotPaused nonReentrant {
        // liquidation trigger:
        //   accountMarginRatio < accountMaintenanceMarginRatio
        //   => accountValue / sum(abs(positionValue_amm)) <
        //        sum(mmRatio * abs(positionValue_amm)) / sum(abs(positionValue_amm))
        //   => accountValue < sum(mmRatio * abs(positionValue_amm))
        //   => accountValue < sum(abs(positionValue_amm)) * mmRatio = totalMinimumMarginRequirement
        //

        // input requirement checks:
        //   trader: here
        //   baseToken: in MarketTaker.settleFunding()

        // CH_CLWHO: cannot liquidate when there is still order
        require(!IPositionMgmt(_positionMgmt).hasOrder(trader), "CH_CLWHO");

        // CH_EAV: enough account value
        require(
            getAccountValue(trader) < IPositionMgmt(_positionMgmt).getMarginRequirementForLiquidation(trader),
            "CH_EAV"
        );

        // must settle funding first
        _settleFunding(trader, baseToken);
        IMarketTaker.SwapResponse memory response = _closePosition(
            InternalClosePositionParams({
                trader: trader,
                baseToken: baseToken,
                amountLimit: amountLimit,
                isLiquidation: true
            })
        );

        // trader's pnl-- as liquidation penalty
        uint256 liquidationFee = response.quote.abs().mulRatio(
            IClearingHouseConfig(_clearingHouseConfig).getLiquidationPenaltyRatio()
        );

        IPositionMgmt(_positionMgmt).modifyOwedRealizedPnl(trader, liquidationFee.neg256());

        // increase liquidator's pnl liquidation reward
        address liquidator = _msgSender();
        IPositionMgmt(_positionMgmt).modifyOwedRealizedPnl(liquidator, liquidationFee.toInt256());

        emit PositionLiquidated(
            trader,
            baseToken,
            response.quote.abs(),
            response.base.abs(),
            liquidationFee,
            liquidator
        );
    }

    /// @inheritdoc IClearingHouse
    function cancelOpenOrder(address maker, address baseToken) external override whenNotPaused nonReentrant {
        // only cancel open orders if there are not enough free collateral with mmRatio
        // or account is able to being liquidated.
        // CH_NEXO: not excess orders
        require(
            (_getFreeCollateralByRatio(maker, IClearingHouseConfig(_clearingHouseConfig).getMmRatio()) < 0) ||
                getAccountValue(maker) < IPositionMgmt(_positionMgmt).getMarginRequirementForLiquidation(maker),
            "CH_NEXO"
        );

        // must settle funding first
        _settleFunding(maker, baseToken);

        Account.LPInfo memory order = ILiquidityProvider(_liquidityProvider).getOpenOrder(maker, baseToken);
        ILiquidityProvider.RemoveLiquidityResponse memory response = ILiquidityProvider(_liquidityProvider)
            .removeLiquidity(
                ILiquidityProvider.RemoveLiquidityParams({
                    maker: maker,
                    baseToken: baseToken,
                    liquidity: order.liquidity,
                    minBase: 0,
                    minQuote: 0
                })
            );

        emit LiquidityChanged(
            maker,
            baseToken,
            _quoteToken,
            response.base.neg256(),
            response.quote.neg256(),
            order.liquidity.neg256(),
            response.fee
        );

        int256 realizedPnl = _settleBalanceAndRealizePnl(maker, baseToken, response);

        int256 openNotional = IPositionMgmt(_positionMgmt).getTakerOpenNotional(maker, baseToken);
        uint256 markPriceAfter = IMarketTaker(_marketTaker).getMarkPrice(baseToken);
        emit PositionChanged(
            maker,
            baseToken,
            response.takerBase, // exchangedPositionSize
            response.takerQuote, // exchangedPositionNotional
            0,
            openNotional,
            realizedPnl,
            markPriceAfter
        );
    }

    //
    // EXTERNAL VIEW
    //

    /// @inheritdoc IClearingHouse
    function getQuoteToken() external view override returns (address) {
        return _quoteToken;
    }

    /// @inheritdoc IClearingHouse
    function getClearingHouseConfig() external view override returns (address) {
        return _clearingHouseConfig;
    }

    /// @inheritdoc IClearingHouse
    function getVault() external view override returns (address) {
        return _vault;
    }

    /// @inheritdoc IClearingHouse
    function getMarketTaker() external view override returns (address) {
        return _marketTaker;
    }

    /// @inheritdoc IClearingHouse
    function getLiquidityProvider() external view override returns (address) {
        return _liquidityProvider;
    }

    /// @inheritdoc IClearingHouse
    function getPositionMgmt() external view override returns (address) {
        return _positionMgmt;
    }

    /// @inheritdoc IClearingHouse
    function getInsuranceFund() external view override returns (address) {
        return _insuranceFund;
    }

    /// @inheritdoc IClearingHouse
    function getAccountValue(address trader) public view override returns (int256) {
        int256 fundingPayment = IMarketTaker(_marketTaker).getAllPendingFundingPayment(trader);
        (int256 owedRealizedPnl, int256 unrealizedPnl, uint256 pendingFee) = IPositionMgmt(_positionMgmt)
            .getPnlAndPendingFee(trader);

        // settlement token decimals -> 1e18
        int256 balance = SettlementToken.parseSettlementToken(
            IVault(_vault).getBalance(trader),
            _settlementTokenDecimals
        );

        // accountValue = collateralValue + owedRealizedPnl - fundingPayment + unrealizedPnl + pendingLPFee
        return balance + owedRealizedPnl - fundingPayment + unrealizedPnl + pendingFee.toInt256();
    }

    //
    // INTERNAL NON-VIEW
    //
    function _settleBalanceAndRealizePnl(
        address maker,
        address baseToken,
        ILiquidityProvider.RemoveLiquidityResponse memory response
    ) internal returns (int256) {
        int256 pnlToBeRealized;
        if (response.takerBase != 0) {
            pnlToBeRealized = IMarketTaker(_marketTaker).getPnlToBeRealized(
                IMarketTaker.RealizePnlParams({
                    trader: maker,
                    baseToken: baseToken,
                    base: response.takerBase,
                    quote: response.takerQuote
                })
            );
        }

        // pnlToBeRealized is realized here
        IPositionMgmt(_positionMgmt).settleBalanceAndDeregister(
            maker,
            baseToken,
            response.takerBase,
            response.takerQuote,
            pnlToBeRealized,
            response.fee.toInt256()
        );

        return pnlToBeRealized;
    }

    function _openPosition(InternalOpenPositionParams memory params)
        internal
        returns (IMarketTaker.SwapResponse memory)
    {
        IMarketTaker.SwapResponse memory response = IMarketTaker(_marketTaker).swap(
            IMarketTaker.SwapParams({
                trader: params.trader,
                baseToken: params.baseToken,
                isSwapWithBase: params.isSwapWithBase,
                isSell: params.isSell,
                isClose: params.isClose,
                amount: params.amount,
                amountLimit: params.amountLimit
            })
        );

        IPositionMgmt(_positionMgmt).modifyOwedRealizedPnl(_insuranceFund, response.insuranceFundFee.toInt256());

        IPositionMgmt(_positionMgmt).modifyTakerBalance(params.trader, params.baseToken, response.base, response.quote);

        if (response.pnlToBeRealized != 0) {
            IPositionMgmt(_positionMgmt).settleQuoteToOwedRealizedPnl(
                params.trader,
                params.baseToken,
                response.pnlToBeRealized
            );

            // if realized pnl is not zero, that means trader is reducing or closing position
            // trader cannot reduce/close position if bad debt happen
            // unless it's a liquidation from backstop liquidity provider
            // CH_BD: trader has bad debt after reducing/closing position
            require(
                (params.isLiquidation &&
                    IClearingHouseConfig(_clearingHouseConfig).isBackstopLiquidityProvider(_msgSender())) ||
                    getAccountValue(params.trader) >= 0,
                "CH_BD"
            );
        }

        // if not closing a position, check margin ratio after swap
        if (!params.isClose) {
            _requireEnoughFreeCollateral(params.trader);
        }

        int256 openNotional = IPositionMgmt(_positionMgmt).getTakerOpenNotional(params.trader, params.baseToken);
        uint256 markPriceAfter = IMarketTaker(_marketTaker).getMarkPrice(params.baseToken);

        emit PositionChanged(
            params.trader,
            params.baseToken,
            response.exchangedPositionSize,
            response.exchangedPositionNotional,
            response.fee,
            openNotional,
            response.pnlToBeRealized,
            markPriceAfter
        );

        IPositionMgmt(_positionMgmt).deregisterBaseToken(params.trader, params.baseToken);

        return response;
    }

    function _closePosition(InternalClosePositionParams memory params)
        internal
        returns (IMarketTaker.SwapResponse memory)
    {
        int256 positionSize = IPositionMgmt(_positionMgmt).getTakerPositionSize(params.trader, params.baseToken);

        // CH_PSZ: position size is zero
        require(positionSize != 0, "CH_PS0");

        // old position is long. when closing, it's baseToQuote && exactInput (sell exact base)
        // old position is short. when closing, it's quoteToBase && exactOutput (buy exact base back)
        bool isSell = positionSize > 0;

        return
            _openPosition(
                InternalOpenPositionParams({
                    trader: params.trader,
                    baseToken: params.baseToken,
                    isSwapWithBase: true,
                    isSell: isSell,
                    isClose: true,
                    amount: positionSize.abs(),
                    amountLimit: params.amountLimit,
                    isLiquidation: params.isLiquidation
                })
            );
    }

    function _settleFunding(address trader, address baseToken)
        internal
        returns (Funding.Growth memory fundingGrowthGlobal)
    {
        int256 fundingPayment;
        (fundingPayment, fundingGrowthGlobal) = IMarketTaker(_marketTaker).settleFunding(trader, baseToken);

        if (fundingPayment != 0) {
            IPositionMgmt(_positionMgmt).modifyOwedRealizedPnl(trader, fundingPayment.neg256());
            emit FundingPaymentSettled(trader, baseToken, fundingPayment);
        }

        IPositionMgmt(_positionMgmt).updateTwPremiumGrowthGlobal(trader, baseToken, fundingGrowthGlobal.twPremium);
        return fundingGrowthGlobal;
    }

    //
    // INTERNAL VIEW
    //

    /// @inheritdoc BaseRelayRecipient
    function _msgSender() internal view override(BaseRelayRecipient, OwnerPausable) returns (address) {
        return super._msgSender();
    }

    /// @inheritdoc BaseRelayRecipient
    function _msgData() internal view override(BaseRelayRecipient, OwnerPausable) returns (bytes memory) {
        return super._msgData();
    }

    function _getFreeCollateralByRatio(address trader, uint24 ratio) internal view returns (int256) {
        return IVault(_vault).getFreeCollateralByRatio(trader, ratio);
    }

    function _requireEnoughFreeCollateral(address trader) internal view {
        // CH_NEFCI: not enough free collateral by imRatio
        require(
            _getFreeCollateralByRatio(trader, IClearingHouseConfig(_clearingHouseConfig).getImRatio()) >= 0,
            "CH_NEFCI"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { FullMath } from "./FullMath.sol";
import { Constant } from "./Constant.sol";

library SigmaMath {
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
        require(a > -2**255, "SigmaMath: inversion overflow");
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

import { SigmaMath } from "./SigmaMath.sol";
import { Account } from "./Account.sol";
import { Constant } from "./Constant.sol";

library Funding {
    using SigmaMath for int256;
    using SigmaMath for uint256;

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
        int256 positionFundingPayment = SigmaMath.mulDiv(
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

/// @dev decimals of settlementToken token MUST be less than 18
library SettlementToken {
    // returns number with 18 decimals
    function parseSettlementToken(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        return amount * (10**(18 - decimals));
    }

    // returns number with 18 decimals
    function parseSettlementToken(int256 amount, uint8 decimals) internal pure returns (int256) {
        return amount * (int256(10**(18 - decimals)));
    }

    // returns number with settlementToken's decimals
    function formatSettlementToken(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        return amount / (10**(18 - decimals));
    }

    // returns number with settlementToken's decimals
    function formatSettlementToken(int256 amount, uint8 decimals) internal pure returns (int256) {
        return amount / (int256(10**(18 - decimals)));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { SafeOwnable } from "./SafeOwnable.sol";

abstract contract OwnerPausable is SafeOwnable, PausableUpgradeable {
    // __gap is reserved storage
    uint256[50] private __gap;

    // solhint-disable-next-line func-order
    function __OwnerPausable_init() internal initializer {
        __SafeOwnable_init();
        __Pausable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _msgSender() internal view virtual override returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes memory) {
        return super._msgData();
    }
}

// copied from @opengsn/provider-2.2.4,
// https://github.com/opengsn/gsn/blob/master/packages/contracts/src/BaseRelayRecipient.sol
// for adding `payable` property at the return value of _msgSender()
// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity 0.8.0;

import "./IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address internal _trustedForwarder;

    // __gap is reserved storage
    uint256[50] private __gap;

    event TrustedForwarderUpdated(address trustedForwarder);

    function getTrustedForwarder() external view returns (address) {
        return _trustedForwarder;
    }

    /// @inheritdoc IRelayRecipient
    function versionRecipient() external pure override returns (string memory) {
        return "2.0.0";
    }

    /// @inheritdoc IRelayRecipient
    function isTrustedForwarder(address forwarder) public view virtual override returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _setTrustedForwarder(address trustedForwarderArg) internal {
        _trustedForwarder = trustedForwarderArg;
        emit TrustedForwarderUpdated(trustedForwarderArg);
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    /// @inheritdoc IRelayRecipient
    function _msgSender() internal view virtual override returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    /// @inheritdoc IRelayRecipient
    function _msgData() internal view virtual override returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

/// @notice For future upgrades, do not change ClearingHouseStorageV1. Create a new
/// contract which implements ClearingHouseStorageV1 and following the naming convention
/// ClearingHouseStorageVX.
abstract contract ClearingHouseStorageV1 {
    // --------- IMMUTABLE ---------
    address internal _quoteToken;

    // cache the settlement token's decimals for gas optimization
    uint8 internal _settlementTokenDecimals;
    // --------- ^^^^^^^^^ ---------

    address internal _clearingHouseConfig;
    address internal _vault;
    address internal _marketTaker;
    address internal _liquidityProvider;
    address internal _positionMgmt;
    address internal _insuranceFund;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

import { BlockContext } from "../base/BlockContext.sol";

abstract contract ClearingHouseValidation is BlockContext {
    modifier checkDeadline(uint256 deadline) {
        // CHV_TE: transaction expires
        require(_blockTimestamp() <= deadline, "CHV_TE");
        _;
    }

    modifier checkRatio(uint24 ratio) {
        // CHV_RO: ratio overflow
        require(ratio <= 1e6, "CHV_RO");
        _;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
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

library Constant {
    address internal constant ADDRESS_ZERO = address(0);
    uint256 internal constant DECIMAL_ONE = 1e18;
    int256 internal constant DECIMAL_ONE_SIGNED = 1e18;
    uint256 internal constant IQ96 = 0x1000000000000000000000000;
    int256 internal constant IQ96_SIGNED = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Constant } from "../lib/Constant.sol";

abstract contract SafeOwnable is ContextUpgradeable {
    address private _owner;
    address private _candidate;

    // __gap is reserved storage
    uint256[50] private __gap;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // SO_CNO: caller not owner
        require(owner() == _msgSender(), "SO_CNO");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __SafeOwnable_init() internal initializer {
        __Context_init();
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(Constant.ADDRESS_ZERO, msgSender);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, Constant.ADDRESS_ZERO);
        _owner = Constant.ADDRESS_ZERO;
        _candidate = Constant.ADDRESS_ZERO;
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) external onlyOwner {
        // SO_NW0: newOwner is 0
        require(newOwner != Constant.ADDRESS_ZERO, "SO_NW0");
        // SO_SAO: same as original
        require(newOwner != _owner, "SO_SAO");
        // SO_SAC: same as candidate
        require(newOwner != _candidate, "SO_SAC");

        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() external {
        // SO_C0: candidate is zero
        require(_candidate != Constant.ADDRESS_ZERO, "SO_C0");
        // SO_CNC: caller is not candidate
        require(_candidate == _msgSender(), "SO_CNC");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = Constant.ADDRESS_ZERO;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the candidate that can become the owner.
     */
    function candidate() external view returns (address) {
        return _candidate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

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
pragma solidity 0.8.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {
    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns (bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal view virtual returns (bytes calldata);

    function versionRecipient() external view virtual returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

abstract contract BlockContext {
    function _blockTimestamp() internal view virtual returns (uint256) {
        // Reply from Arbitrum
        // block.timestamp returns timestamp at the time at which the sequencer receives the tx.
        // It may not actually correspond to a particular L1 block
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}