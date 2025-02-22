//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "solmate/src/tokens/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {DataTypes} from "@yield-protocol/vault-v2/contracts/interfaces/DataTypes.sol";
import {ICauldron} from "@yield-protocol/vault-v2/contracts/interfaces/ICauldron.sol";

import "../../libraries/CodecLib.sol";
import "../../ContangoPositionNFT.sol";
import "../../interfaces/IContangoQuoter.sol";
import "../../libraries/QuoterDataTypes.sol";
import "../../libraries/ErrorLib.sol";
import "../../libraries/QuoterLib.sol";
import "./YieldUtils.sol";
import "./ContangoYield.sol";

/// @title Contract for quoting position operations
contract ContangoYieldQuoter is IContangoQuoter {
    using SafeCast for uint256;
    using SafeCast for int256;
    using SignedMath for int256;
    using CodecLib for uint256;
    using QuoterLib for IQuoter;
    using YieldUtils for *;

    ContangoPositionNFT public immutable positionNFT;
    ContangoYield public immutable contangoYield;
    ICauldron public immutable cauldron;
    IQuoter public immutable quoter;
    int256 private collateralSlippage;
    uint128 private maxAvailableDebt;

    constructor(ContangoPositionNFT _positionNFT, ContangoYield _contangoYield, ICauldron _cauldron, IQuoter _quoter) {
        positionNFT = _positionNFT;
        contangoYield = _contangoYield;
        cauldron = _cauldron;
        quoter = _quoter;
    }

    /// @inheritdoc IContangoQuoter
    function positionStatus(PositionId positionId, uint24 uniswapFee)
        external
        override
        returns (PositionStatus memory result)
    {
        (, Instrument memory instrument, YieldInstrument memory yieldInstrument) =
            _validatePosition(positionId, uniswapFee);
        DataTypes.Balances memory balances = cauldron.balances(positionId.toVaultId());

        result = _positionStatus(balances, instrument, yieldInstrument);

        result.liquidating = cauldron.vaults(positionId.toVaultId()).owner != address(contangoYield);
    }

    /// @inheritdoc IContangoQuoter
    function modifyCostForPosition(ModifyCostParams calldata params)
        external
        override
        returns (ModifyCostResult memory result)
    {
        (Position memory position, Instrument memory instrument, YieldInstrument memory yieldInstrument) =
            _validateActivePosition(params.positionId, params.uniswapFee);
        DataTypes.Balances memory balances = cauldron.balances(params.positionId.toVaultId());

        if (params.quantity > 0) {
            _checkClosingOnly(position.symbol, instrument);
        }

        result = _modifyCostForLongPosition(
            balances, instrument, yieldInstrument, params.quantity, params.collateral, params.collateralSlippage
        );
        if (result.needsBatchedCall || params.quantity == 0) {
            uint256 aggregateCost = (result.cost + result.financingCost).abs() + result.debtDelta.abs();
            result.fee = QuoterLib.fee(contangoYield, positionNFT, params.positionId, position.symbol, aggregateCost);
        } else {
            result.fee =
                QuoterLib.fee(contangoYield, positionNFT, params.positionId, position.symbol, result.cost.abs());
        }
    }

    /// @inheritdoc IContangoQuoter
    function openingCostForPosition(OpeningCostParams calldata params)
        external
        override
        returns (ModifyCostResult memory result)
    {
        (Instrument memory instrument, YieldInstrument memory yieldInstrument) =
            _instrument(params.symbol, params.uniswapFee);

        _checkClosingOnly(params.symbol, instrument);

        result = _modifyCostForLongPosition(
            DataTypes.Balances({art: 0, ink: 0}),
            instrument,
            yieldInstrument,
            int256(params.quantity),
            int256(params.collateral),
            params.collateralSlippage
        );

        result.fee = QuoterLib.fee(contangoYield, positionNFT, PositionId.wrap(0), params.symbol, result.cost.abs());
    }

    /// @inheritdoc IContangoQuoter
    function deliveryCostForPosition(PositionId positionId) external override returns (uint256) {
        (Position memory position,, YieldInstrument memory yieldInstrument) = _validateExpiredPosition(positionId);
        DataTypes.Balances memory balances = cauldron.balances(positionId.toVaultId());

        return _deliveryCostForPosition(balances, yieldInstrument, position);
    }

    // ============================================== private functions ==============================================

    function _checkClosingOnly(Symbol symbol, Instrument memory instrument) private view {
        if (contangoYield.closingOnly()) {
            revert ClosingOnly();
        }
        if (instrument.closingOnly) {
            revert InstrumentClosingOnly(symbol);
        }
    }

    function _positionStatus(
        DataTypes.Balances memory balances,
        Instrument memory instrument,
        YieldInstrument memory yieldInstrument
    ) private returns (PositionStatus memory result) {
        result.spotCost = quoter.spot(instrument, int128(balances.ink));
        result.underlyingDebt = balances.art;

        DataTypes.Series memory series = cauldron.series(yieldInstrument.quoteId);
        DataTypes.SpotOracle memory spotOracle = cauldron.spotOracles(series.baseId, yieldInstrument.baseId);

        (result.underlyingCollateral,) = spotOracle.oracle.get(yieldInstrument.baseId, series.baseId, balances.ink);
        result.liquidationRatio = uint256(spotOracle.ratio);
    }

    function _modifyCostForLongPosition(
        DataTypes.Balances memory balances,
        Instrument memory instrument,
        YieldInstrument memory yieldInstrument,
        int256 quantity,
        int256 collateral,
        uint256 _collateralSlippage
    ) internal returns (ModifyCostResult memory result) {
        collateralSlippage = 1e18 + int256(_collateralSlippage);
        result.minDebt = yieldInstrument.minQuoteDebt;
        DataTypes.Series memory series = cauldron.series(yieldInstrument.quoteId);
        DataTypes.Debt memory debt = cauldron.debt(series.baseId, yieldInstrument.baseId);
        maxAvailableDebt = uint128(debt.max * (10 ** debt.dec)) - debt.sum;
        _evaluateLiquidity(yieldInstrument, balances, result, quantity, collateral);

        if (!result.insufficientLiquidity) {
            _assignLiquidity(yieldInstrument, balances, result, quantity, collateral);

            if (quantity >= 0) {
                _increasingCostForLongPosition(
                    result, balances, series, instrument, yieldInstrument, quantity.toUint256(), collateral
                );
            } else {
                _closingCostForLongPosition(
                    result, balances, series, instrument, yieldInstrument, quantity.abs(), collateral
                );
            }
        }
    }

    // **** NEW **** //
    function _increasingCostForLongPosition(
        ModifyCostResult memory result,
        DataTypes.Balances memory balances,
        DataTypes.Series memory series,
        Instrument memory instrument,
        YieldInstrument memory yieldInstrument,
        uint256 quantity,
        int256 collateral
    ) private {
        uint256 hedge;
        int256 quoteQty;

        if (quantity > 0) {
            if (result.baseLendingLiquidity < quantity) {
                hedge = result.baseLendingLiquidity == 0
                    ? 0
                    : yieldInstrument.basePool.buyFYTokenPreviewZero(uint128(result.baseLendingLiquidity));
                uint256 toMint = quantity - result.baseLendingLiquidity;
                hedge += toMint;
            } else {
                hedge = yieldInstrument.basePool.buyFYTokenPreviewZero(quantity.toUint128());
            }

            quoteQty = -int256(quoter.spot(instrument, -int256(hedge)));
            result.spotCost = -int256(quoter.spot(instrument, -int256(quantity)));
        }

        DataTypes.SpotOracle memory spotOracle = cauldron.spotOracles(series.baseId, yieldInstrument.baseId);
        (result.underlyingCollateral,) =
            spotOracle.oracle.get(yieldInstrument.baseId, series.baseId, balances.ink + quantity); // ink * spot
        result.liquidationRatio = uint256(spotOracle.ratio);

        _calculateMinCollateral(balances, yieldInstrument, result, quoteQty);
        _calculateMaxCollateral(balances, yieldInstrument, result, quoteQty);
        _assignCollateralUsed(result, collateral);
        _calculateCost(balances, yieldInstrument, result, quoteQty, true);
    }

    /// @notice Quotes the bid rate, the base/quote are derived from the positionId
    // **** NEW **** //
    function _closingCostForLongPosition(
        ModifyCostResult memory result,
        DataTypes.Balances memory balances,
        DataTypes.Series memory series,
        Instrument memory instrument,
        YieldInstrument memory yieldInstrument,
        uint256 quantity,
        int256 collateral
    ) private {
        uint256 amountRealBaseReceivedFromSellingLendingPosition =
            yieldInstrument.basePool.sellFYTokenPreview(quantity.toUint128());

        result.spotCost = int256(quoter.spot(instrument, int256(quantity)));
        int256 hedgeCost = int256(quoter.spot(instrument, int256(amountRealBaseReceivedFromSellingLendingPosition)));

        DataTypes.SpotOracle memory spotOracle = cauldron.spotOracles(series.baseId, yieldInstrument.baseId);
        result.liquidationRatio = uint256(spotOracle.ratio);

        if (balances.ink == quantity) {
            uint256 costRecovered;
            if (balances.art != 0) {
                if (result.quoteLendingLiquidity < balances.art) {
                    costRecovered = result.quoteLendingLiquidity > 0
                        ? result.quoteLendingLiquidity
                            - yieldInstrument.quotePool.buyFYTokenPreviewZero(uint128(result.quoteLendingLiquidity))
                        : 0;
                } else {
                    costRecovered = balances.art - yieldInstrument.quotePool.buyFYTokenPreviewZero(balances.art);
                }
            }
            result.cost = hedgeCost + int256(costRecovered);
        } else {
            (result.underlyingCollateral,) =
                spotOracle.oracle.get(yieldInstrument.baseId, series.baseId, balances.ink - quantity);
            _calculateMinCollateral(balances, yieldInstrument, result, hedgeCost);
            _calculateMaxCollateral(balances, yieldInstrument, result, hedgeCost);
            _assignCollateralUsed(result, collateral);
            _calculateCost(balances, yieldInstrument, result, hedgeCost, false);
        }
    }

    function _calculateMinCollateral(
        DataTypes.Balances memory balances,
        YieldInstrument memory instrument,
        ModifyCostResult memory result,
        int256 spotCost
    ) private view {
        uint128 maxDebtAfterModify = ((result.underlyingCollateral * 1e6) / result.liquidationRatio).toUint128();

        if (balances.art < maxDebtAfterModify) {
            uint128 diff = maxDebtAfterModify - balances.art;
            uint128 maxBorrowableAmount = uint128(Math.min(instrument.quotePool.maxFYTokenIn.cap(), maxAvailableDebt));
            uint256 refinancingRoomPV =
                instrument.quotePool.sellFYTokenPreview(diff > maxBorrowableAmount ? maxBorrowableAmount : diff);
            result.minCollateral -= spotCost + int256(refinancingRoomPV);
        }

        if (balances.art > maxDebtAfterModify) {
            uint128 diff = balances.art - maxDebtAfterModify;
            uint128 liquidity = instrument.quotePool.maxFYTokenOut.cap();
            uint256 minDebtThatHasToBeBurnedPV = diff > liquidity
                ? instrument.quotePool.buyFYTokenPreviewZero(liquidity) + (diff - liquidity)
                : instrument.quotePool.buyFYTokenPreviewZero(diff);

            result.minCollateral = int256(minDebtThatHasToBeBurnedPV) - spotCost;
        }

        if (collateralSlippage != 1e18) {
            result.minCollateral = result.minCollateral > 0
                ? SignedMath.min((result.minCollateral * collateralSlippage) / 1e18, -spotCost)
                : (result.minCollateral * 1e18) / collateralSlippage;
        }
    }

    function _calculateMaxCollateral(
        DataTypes.Balances memory balances,
        YieldInstrument memory instrument,
        ModifyCostResult memory result,
        int256 spotCost
    ) private view {
        // this covers the case where there is no existing debt, which applies to new positions or fully liquidated positions
        if (balances.art == 0) {
            uint256 minDebtPV = instrument.quotePool.sellFYTokenPreview(result.minDebt);
            result.maxCollateral = int256(spotCost.abs()) - int256(minDebtPV);
        } else {
            uint128 maxFYTokenOut = instrument.quotePool.maxFYTokenOut.cap();
            uint128 maxDebtThatCanBeBurned = balances.art - result.minDebt;
            uint256 maxDebtThatCanBeBurnedPV;
            if (maxDebtThatCanBeBurned > 0) {
                uint128 inputValue = maxFYTokenOut < maxDebtThatCanBeBurned ? maxFYTokenOut : maxDebtThatCanBeBurned;
                maxDebtThatCanBeBurnedPV = instrument.quotePool.buyFYTokenPreviewZero(inputValue);

                // when minting 1:1
                if (maxDebtThatCanBeBurned > inputValue) {
                    maxDebtThatCanBeBurnedPV += maxDebtThatCanBeBurned - inputValue;
                }
            }
            result.maxCollateral = int256(maxDebtThatCanBeBurnedPV) - spotCost;
        }

        if (collateralSlippage != 1e18) {
            result.maxCollateral = result.maxCollateral < 0
                ? (result.maxCollateral * collateralSlippage) / 1e18
                : (result.maxCollateral * 1e18) / collateralSlippage;
        }
    }

    // NEEDS BATCHED CALL
    // * decrease and withdraw more than we get from spot
    // * decrease and post at the same time SUPPORTED
    // * increase and withdraw at the same time ???
    // * increase and post more than what we need to pay the spot

    function _calculateCost(
        DataTypes.Balances memory balances,
        YieldInstrument memory instrument,
        ModifyCostResult memory result,
        int256 spotCost,
        bool isIncrease
    ) private view {
        int256 quoteUsedToRepayDebt = result.collateralUsed + spotCost;
        result.underlyingDebt = balances.art;
        uint128 debtDelta128;

        if (quoteUsedToRepayDebt > 0) {
            uint128 baseToSell = uint128(uint256(quoteUsedToRepayDebt));
            uint128 maxBaseIn = instrument.quotePool.maxBaseIn.cap();
            if (maxBaseIn < baseToSell) {
                debtDelta128 = instrument.quotePool.sellBasePreviewZero(uint128(maxBaseIn));
                // remainder is paid by minting 1:1
                debtDelta128 += baseToSell - uint128(maxBaseIn);
            } else {
                debtDelta128 = instrument.quotePool.sellBasePreview(baseToSell);
            }
            result.debtDelta = -int256(uint256(debtDelta128));
            result.underlyingDebt -= debtDelta128;
            if (isIncrease && spotCost != 0) {
                // this means we're increasing, and posting more than what we need to pay the spot
                result.needsBatchedCall = true;
            }
        }
        if (quoteUsedToRepayDebt < 0) {
            debtDelta128 = instrument.quotePool.buyBasePreview(quoteUsedToRepayDebt.abs().toUint128());
            result.debtDelta = int256(uint256(debtDelta128));
            result.underlyingDebt += debtDelta128;
            if (!isIncrease && spotCost != 0) {
                // this means that we're decreasing, and withdrawing more than we get from the spot
                result.needsBatchedCall = true;
            }
        }
        result.financingCost = result.debtDelta + quoteUsedToRepayDebt;
        result.cost -= result.collateralUsed + result.debtDelta;
    }

    function _assignLiquidity(
        YieldInstrument memory instrument,
        DataTypes.Balances memory balances,
        ModifyCostResult memory result,
        int256 quantity,
        int256 collateral
    ) private view {
        // Opening / Increasing
        if (quantity > 0) {
            result.baseLendingLiquidity = instrument.basePool.maxFYTokenOut.cap();
        }

        // Add collateral
        if (balances.art != 0 && collateral > 0) {
            result.quoteLendingLiquidity = instrument.quotePool.maxBaseIn.cap();
        }

        // Decrease position
        if (quantity < 0) {
            result.quoteLendingLiquidity = instrument.quotePool.maxBaseIn.cap();
        }

        // Close position
        if (quantity == -int128(balances.ink)) {
            result.quoteLendingLiquidity = instrument.quotePool.maxFYTokenOut.cap();
        }
    }

    function _evaluateLiquidity(
        YieldInstrument memory instrument,
        DataTypes.Balances memory balances,
        ModifyCostResult memory result,
        int256 quantity,
        int256 collateral
    ) private view {
        // If we're opening a new position
        if (balances.art == 0 && quantity > 0) {
            result.insufficientLiquidity =
                Math.min(instrument.quotePool.maxFYTokenIn.cap(), maxAvailableDebt) < result.minDebt;
        }

        // If we're withdrawing from a position
        if (quantity == 0 && collateral < 0) {
            result.insufficientLiquidity = instrument.quotePool.maxBaseOut.cap() < collateral.abs();
        }

        // If we're reducing a position
        if (quantity < 0) {
            result.insufficientLiquidity = instrument.basePool.maxFYTokenIn.cap() < quantity.abs();
        }
    }

    function _assignCollateralUsed(ModifyCostResult memory result, int256 collateral) private pure {
        // if 'collateral' is above the max, use result.maxCollateral
        result.collateralUsed = SignedMath.min(collateral, result.maxCollateral);
        // if result.collateralUsed is lower than max, but still lower than the min, use the min
        result.collateralUsed = SignedMath.max(result.minCollateral, result.collateralUsed);
    }

    function _deliveryCostForPosition(
        DataTypes.Balances memory balances,
        YieldInstrument memory yieldInstrument,
        Position memory position
    ) internal returns (uint256) {
        return cauldron.debtToBase(yieldInstrument.quoteId, balances.art) + position.protocolFees;
    }

    function _validatePosition(PositionId positionId, uint24 uniswapFee)
        private
        view
        returns (Position memory position, Instrument memory instrument, YieldInstrument memory yieldInstrument)
    {
        position = contangoYield.position(positionId);
        if (position.openQuantity == 0 && position.openCost == 0) {
            if (position.collateral <= 0) {
                revert InvalidPosition(positionId);
            }
        }
        (instrument, yieldInstrument) = _instrument(position.symbol, uniswapFee);
    }

    function _validateActivePosition(PositionId positionId, uint24 uniswapFee)
        private
        view
        returns (Position memory position, Instrument memory instrument, YieldInstrument memory yieldInstrument)
    {
        (position, instrument, yieldInstrument) = _validatePosition(positionId, uniswapFee);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrument.maturity <= timestamp) {
            revert PositionExpired(positionId, instrument.maturity, timestamp);
        }
    }

    function _validateExpiredPosition(PositionId positionId)
        private
        view
        returns (Position memory position, Instrument memory instrument, YieldInstrument memory yieldInstrument)
    {
        (position, instrument, yieldInstrument) = _validatePosition(positionId, 0);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrument.maturity > timestamp) {
            revert PositionActive(positionId, instrument.maturity, timestamp);
        }
    }

    function _instrument(Symbol symbol, uint24 uniswapFee)
        private
        view
        returns (Instrument memory instrument, YieldInstrument memory yieldInstrument)
    {
        (instrument, yieldInstrument) = contangoYield.yieldInstrument(symbol);
        instrument.uniswapFeeTransient = uniswapFee;
    }

    receive() external payable {
        revert ViewOnly();
    }

    /// @notice reverts on fallback for informational purposes
    fallback() external payable {
        revert FunctionNotFound(msg.sig);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/DataTypes.sol";

/// @title ContangoPositionNFT
/// @notice An ERC721 NFT that represents ownership of each position created through the protocol
/// @author Bruno Bonanno
/// @dev Instances can only be minted by other contango contracts
contract ContangoPositionNFT is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant ARTIST = keccak256("ARTIST");

    PositionId public nextPositionId = PositionId.wrap(1);

    constructor() ERC721("Contango Position", "CTGP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice creates a new position in the protocol by minting a new NFT instance
    /// @param to The would be owner of the newly minted position
    /// @return positionId The newly created positionId
    function mint(address to) external onlyRole(MINTER) returns (PositionId positionId) {
        positionId = nextPositionId;
        uint256 _positionId = PositionId.unwrap(positionId);
        nextPositionId = PositionId.wrap(_positionId + 1);
        _safeMint(to, _positionId);
    }

    /// @notice closes a position in the protocol by burning the NFT instance
    /// @param positionId positionId of the closed position
    function burn(PositionId positionId) external onlyRole(MINTER) {
        _burn(PositionId.unwrap(positionId));
    }

    function positionOwner(PositionId positionId) external view returns (address) {
        return ownerOf(PositionId.unwrap(positionId));
    }

    function positionURI(PositionId positionId) external view returns (string memory) {
        return tokenURI(PositionId.unwrap(positionId));
    }

    function setPositionURI(PositionId positionId, string memory _tokenURI) external onlyRole(ARTIST) {
        _setTokenURI(PositionId.unwrap(positionId), _tokenURI);
    }

    /**
     * @dev See EIP-165: ERC-165 Standard Interface Detection
     * https://eips.ethereum.org/EIPS/eip-165.
     *
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
    }

    /// @dev returns all the positions a trader has between the provided boundaries
    /// @param owner Trader that owns the positions
    /// @param from Starting position to consider for the search (inclusive)
    /// @param to Ending position to consider for the search (exclusive)
    /// @return tokens Array with all the positions the trader owns within the range.
    /// Array size could be bigger than effective result set if the trader owns positions outside the range
    /// PositionId == 0 is always invalid, so as soon it shows up in the array is safe to assume the rest of it is empty
    function positions(address owner, PositionId from, PositionId to)
        external
        view
        returns (PositionId[] memory tokens)
    {
        uint256 count;
        uint256 balance = balanceOf(owner);
        tokens = new PositionId[](balance);
        uint256 _from = PositionId.unwrap(from);
        uint256 _to = Math.min(PositionId.unwrap(to), PositionId.unwrap(nextPositionId));

        for (uint256 i = _from; i < _to; i++) {
            if (_exists(i) && ownerOf(i) == owner) {
                tokens[count++] = PositionId.wrap(i);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";

library DataTypes {
    // ======== Cauldron data types ========
    struct Series {
        IFYToken fyToken; // Redeemable token for the series.
        bytes6 baseId; // Asset received on redemption.
        uint32 maturity; // Unix time at which redemption becomes possible.
        // bytes2 free
    }

    struct Debt {
        uint96 max; // Maximum debt accepted for a given underlying, across all series
        uint24 min; // Minimum debt accepted for a given underlying, across all series
        uint8 dec; // Multiplying factor (10**dec) for max and min
        uint128 sum; // Current debt for a given underlying, across all series
    }

    struct SpotOracle {
        IOracle oracle; // Address for the spot price oracle
        uint32 ratio; // Collateralization ratio to multiply the price for
        // bytes8 free
    }

    struct Vault {
        address owner;
        bytes6 seriesId; // Each vault is related to only one series, which also determines the underlying.
        bytes6 ilkId; // Asset accepted as collateral
    }

    struct Balances {
        uint128 art; // Debt amount
        uint128 ink; // Collateral amount
    }

    // ======== Witch data types ========
    struct Auction {
        address owner;
        uint32 start;
        bytes6 baseId; // We cache the baseId here
        uint128 ink;
        uint128 art;
        address auctioneer;
        bytes6 ilkId; // We cache the ilkId here
        bytes6 seriesId; // We cache the seriesId here
    }

    struct Line {
        uint32 duration; // Time that auctions take to go to minimal price and stay there
        uint64 vaultProportion; // Proportion of the vault that is available each auction (1e18 = 100%)
        uint64 collateralProportion; // Proportion of collateral that is sold at auction start (1e18 = 100%)
    }

    struct Limits {
        uint128 max; // Maximum concurrent auctioned collateral
        uint128 sum; // Current concurrent auctioned collateral
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";
import "./DataTypes.sol";

interface ICauldron {
    /// @dev Variable rate lending oracle for an underlying
    function lendingOracles(bytes6 baseId) external view returns (IOracle);

    /// @dev An user can own one or more Vaults, with each vault being able to borrow from a single series.
    function vaults(bytes12 vault)
        external
        view
        returns (DataTypes.Vault memory);

    /// @dev Series available in Cauldron.
    function series(bytes6 seriesId)
        external
        view
        returns (DataTypes.Series memory);

    /// @dev Assets available in Cauldron.
    function assets(bytes6 assetsId) external view returns (address);

    /// @dev Each vault records debt and collateral balances_.
    function balances(bytes12 vault)
        external
        view
        returns (DataTypes.Balances memory);

    /// @dev Max, min and sum of debt per underlying and collateral.
    function debt(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.Debt memory);

    // @dev Spot price oracle addresses and collateralization ratios
    function spotOracles(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.SpotOracle memory);

    /// @dev Create a new vault, linked to a series (and therefore underlying) and up to 5 collateral types
    function build(
        address owner,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vault) external;

    /// @dev Change a vault series and/or collateral types.
    function tweak(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Give a vault to another user.
    function give(bytes12 vaultId, address receiver)
        external
        returns (DataTypes.Vault memory);

    /// @dev Move collateral and debt between vaults.
    function stir(
        bytes12 from,
        bytes12 to,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory, DataTypes.Balances memory);

    /// @dev Manipulate a vault debt and collateral.
    function pour(
        bytes12 vaultId,
        int128 ink,
        int128 art
    ) external returns (DataTypes.Balances memory);

    /// @dev Change series and debt of a vault.
    /// The module calling this function also needs to buy underlying in the pool for the new series, and sell it in pool for the old series.
    function roll(
        bytes12 vaultId,
        bytes6 seriesId,
        int128 art
    ) external returns (DataTypes.Vault memory, DataTypes.Balances memory);

    /// @dev Reduce debt and collateral from a vault, ignoring collateralization checks.
    function slurp(
        bytes12 vaultId,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory);

    // ==== Helpers ====

    /// @dev Convert a debt amount for a series from base to fyToken terms.
    /// @notice Think about rounding if using, since we are dividing.
    function debtFromBase(bytes6 seriesId, uint128 base)
        external
        returns (uint128 art);

    /// @dev Convert a debt amount for a series from fyToken to base terms
    function debtToBase(bytes6 seriesId, uint128 art)
        external
        returns (uint128 base);

    // ==== Accounting ====

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId) external;

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId) external returns (uint256);

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function level(bytes12 vaultId) external returns (int256);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library CodecLib {
    error InvalidInt128(int256 n);
    error InvalidUInt128(uint256 n);

    modifier validInt128(int256 n) {
        if (n > type(int128).max || n < type(int128).min) {
            revert InvalidInt128(n);
        }
        _;
    }

    modifier validUInt128(uint256 n) {
        if (n > type(uint128).max) {
            revert InvalidUInt128(n);
        }
        _;
    }

    function encodeU128(uint256 a, uint256 b) internal pure validUInt128(a) validUInt128(b) returns (uint256 encoded) {
        encoded |= uint256(uint128(a)) << 128;
        encoded |= uint256(uint128(b));
    }

    function decodeU128(uint256 encoded) internal pure returns (uint128 a, uint128 b) {
        a = uint128(encoded >> 128);
        b = uint128(encoded);
    }

    function encodeI128(int256 a, int256 b) internal pure validInt128(a) validInt128(b) returns (uint256 encoded) {
        encoded |= uint256(uint128(int128(a))) << 128;
        encoded |= uint256(uint128(int128(b)));
    }

    function decodeI128(uint256 encoded) internal pure returns (int128 a, int128 b) {
        a = int128(uint128(encoded >> 128));
        b = int128(uint128(encoded));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataTypes.sol";

struct OpeningCostParams {
    Symbol symbol; // Instrument to be used
    uint256 quantity; // Size of the position
    uint256 collateral; // How much quote ccy the user will post, if the value is too big/small, a calculated max/min will be used instead
    uint256 collateralSlippage; // How much add to minCollateral and remove from maxCollateral to avoid issues with min/max debt. In %, 1e18 == 100%
    uint24 uniswapFee; // The fee to be used for the quote
}

struct ModifyCostParams {
    PositionId positionId;
    int256 quantity; // How much the size of the position should change by
    int256 collateral; // How much the collateral of the position should change by, if the value is too big/small, a calculated max/min will be used instead
    uint256 collateralSlippage; // How much add to minCollateral and remove from maxCollateral to avoid issues with min/max debt. In %, 1e18 == 100%
    uint24 uniswapFee; // The fee to be used for the quote
}

// What does the signed cost mean?
// In general, it'll be negative when quoting cost to open/increase, and positive when quoting cost to close/decrease.
// However, there are certain situations where that general rule may not hold true, for example when the qty delta is small and the collateral delta is big.
// Scenarios include:
//      * increase position by a tiny bit, but add a lot of collateral at the same time (aka. burn existing debt)
//      * decrease position by a tiny bit, withdraw a lot of excess equity at the same time (aka. issue new debt)
// For this reason, we cannot get rid of the signing, and make assumptions about in which direction the cost will go based on the qty delta alone.
// The effect (or likeliness of this coming into play) is much greater when the funding currency (quote) has a high interest rate.
struct ModifyCostResult {
    int256 spotCost; // The current spot cost of a given position quantity
    int256 cost; // See comment above for explanation of why the cost is signed.
    int256 financingCost; // The cost to increase/decrease collateral. We need to return this breakdown of cost so the UI knows which values to pass to 'modifyCollateral'
    int256 debtDelta; // if negative, it's the amount repaid. If positive, it's the amount of new debt issued.
    int256 collateralUsed; // Collateral used to open/increase position with returned cost
    int256 minCollateral; // Minimum collateral needed to perform modification. If negative, it's the MAXIMUM amount that CAN be withdrawn.
    int256 maxCollateral; // Max collateral allowed to open/increase a position. If negative, it's the MINIMUM amount that HAS TO be withdrawn.
    uint256 underlyingDebt; // Value of debt 1:1 with real underlying (Future Value)
    uint256 underlyingCollateral; // Value of collateral in debt terms
    uint256 liquidationRatio; // The ratio at which a position becomes eligible for liquidation (underlyingCollateral/underlyingDebt)
    uint256 fee;
    uint128 minDebt;
    uint256 baseLendingLiquidity; // Liquidity available for lending, either in PV or FV depending on the operation(s) quoted
    uint256 quoteLendingLiquidity; // Liquidity available for lending, either in PV or FV depending on the operation(s) quoted
    // relevant to closing only
    bool insufficientLiquidity; // Indicates whether there is insufficient liquidity for the desired modification/open.
    // when opening/increasing, this would mean there is insufficient borrowing liquidity of quote ccy.
    // when closing/decreasing, this would mean there is insufficient borrowing liquidity of base ccy (unwind hedge).
    // If this boolean is true, there is nothing we can do.
    bool needsBatchedCall;
}

struct PositionStatus {
    uint256 spotCost; // The current spot cost of a given position quantity
    uint256 underlyingDebt; // Value of debt 1:1 with real underlying (Future Value)
    uint256 underlyingCollateral; // Value of collateral in debt terms
    uint256 liquidationRatio; // The ratio at which a position becomes eligible for liquidation (underlyingCollateral/underlyingDebt)
    bool liquidating; // When true, no actions are allowed over the position
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/QuoterDataTypes.sol";

/// @title Interface to allow for quoting position operations
interface IContangoQuoter {
    /// @notice Quotes the position status
    /// @param positionId The id of a position
    /// @param uniswapFee The fee (pool) to be used for the quote
    /// @return position status
    function positionStatus(PositionId positionId, uint24 uniswapFee) external returns (PositionStatus memory);

    /// @notice Quotes the cost to open a position with the respective collateral used
    /// @param params opening cost parameters
    /// @return opening cost result
    /// Will either be the same as minCollateral in case the collateral passed is insufficient, the same as the collateral passed or capped to the maximum collateralisation possible
    function openingCostForPosition(OpeningCostParams calldata params) external returns (ModifyCostResult memory);

    /// @notice Quotes the cost to modify a position with the respective qty change and collateral
    /// @param params modify cost parameters
    /// @return modify cost result
    function modifyCostForPosition(ModifyCostParams calldata params) external returns (ModifyCostResult memory);

    /// @notice Quotes the cost to deliver an expired position
    /// @param positionId the id of an expired position
    /// @return Cost to deliver position
    function deliveryCostForPosition(PositionId positionId) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataTypes.sol";

error ClosingOnly();

error InstrumentClosingOnly(Symbol symbol);

error FunctionNotFound(bytes4 sig);

error InstrumentAlreadyExists(Symbol symbol);

error InstrumentExpired(Symbol symbol, uint32 maturity, uint256 timestamp);

error InvalidInstrument(Symbol symbol);

error InvalidPayer(PositionId positionId, address payer);

error InvalidPosition(PositionId positionId);

error InvalidPositionDecrease(PositionId positionId, int256 decreaseQuantity, uint256 currentQuantity);

error InvalidQuantity(int256 quantity);

error NotPositionOwner(PositionId positionId, address msgSender, address actualOwner);

error PositionActive(PositionId positionId, uint32 maturity, uint256 timestamp);

error PositionExpired(PositionId positionId, uint32 maturity, uint256 timestamp);

error ViewOnly();

// TODO these should be removed before going live
error NotImplemented(string description);

error Unsupported();

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "../interfaces/IContangoView.sol";
import "../ContangoPositionNFT.sol";

library QuoterLib {
    function spot(IQuoter quoter, Instrument memory instrument, int256 baseAmount) internal returns (uint256) {
        if (baseAmount > 0) {
            return quoter.quoteExactInputSingle({
                tokenIn: address(instrument.base),
                tokenOut: address(instrument.quote),
                fee: instrument.uniswapFeeTransient,
                amountIn: uint256(baseAmount),
                sqrtPriceLimitX96: 0
            });
        } else {
            return quoter.quoteExactOutputSingle({
                tokenIn: address(instrument.quote),
                tokenOut: address(instrument.base),
                fee: instrument.uniswapFeeTransient,
                amountOut: uint256(-baseAmount),
                sqrtPriceLimitX96: 0
            });
        }
    }

    function fee(
        IContangoView contangoView,
        ContangoPositionNFT positionNFT,
        PositionId positionId,
        Symbol symbol,
        uint256 cost
    ) internal view returns (uint256) {
        address trader = PositionId.unwrap(positionId) == 0 ? msg.sender : positionNFT.positionOwner(positionId);
        IFeeModel feeModel = contangoView.feeModel(symbol);
        return address(feeModel) != address(0) ? feeModel.calculateFee(trader, positionId, cost) : 0;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "solmate/src/tokens/WETH.sol";
import {IContangoLadle} from "@yield-protocol/vault-v2/contracts/other/contango/interfaces/IContangoLadle.sol";
import "@yield-protocol/vault-v2/contracts/other/contango/interfaces/IContangoWitchListener.sol";
import "./Yield.sol";
import "./YieldUtils.sol";
import "../ContangoBase.sol";

/// @notice Contract that acts as the main entry point to the protocol with yield-protocol as the underlying
/// @dev This is the main entry point to the system when using yield-protocol as the underlying
contract ContangoYield is ContangoBase, IContangoWitchListener {
    using SafeCast for uint256;
    using YieldUtils for Symbol;

    bytes32 public constant WITCH = keccak256("WITCH");

    // solhint-disable-next-line no-empty-blocks
    constructor(WETH _weth) ContangoBase(_weth) {}

    function initialize(ContangoPositionNFT _positionNFT, address _treasury, IContangoLadle _ladle)
        public
        initializer
    {
        __ContangoBase_init(_positionNFT, _treasury);

        YieldStorageLib.setLadle(_ladle);
        YieldStorageLib.setCauldron(_ladle.cauldron());
    }

    // ============================================== Trading functions ==============================================

    /// @inheritdoc IContango
    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        whenNotClosingOnly(quantity.toInt256())
        returns (PositionId)
    {
        return
            Yield.createPosition(symbol, trader, quantity, limitCost, collateral, payer, lendingLiquidity, uniswapFee);
    }

    /// @inheritdoc IContango
    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external payable override nonReentrant whenNotPaused {
        Yield.modifyCollateral(positionId, collateral, slippageTolerance, payerOrReceiver, lendingLiquidity);
    }

    /// @inheritdoc IContango
    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external payable override nonReentrant whenNotPaused whenNotClosingOnly(quantity) {
        Yield.modifyPosition(positionId, quantity, limitCost, collateral, payerOrReceiver, lendingLiquidity, uniswapFee);
    }

    /// @inheritdoc IContango
    function deliver(PositionId positionId, address payer, address to)
        external
        payable
        override
        nonReentrant
        whenNotPaused
    {
        Yield.deliver(positionId, payer, to);
    }

    // ============================================== Callback functions ==============================================

    // solhint-disable-next-line no-empty-blocks
    function auctionStarted(bytes12 vaultId) external override {}

    function collateralBought(bytes12 vaultId, address, uint256 ink, uint256 art)
        external
        override
        nonReentrant
        onlyRole(WITCH)
    {
        Yield.collateralBought(vaultId, ink, art);
    }

    // solhint-disable-next-line no-empty-blocks
    function auctionEnded(bytes12 vaultId, address owner) external override {}

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        Yield.uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    // ============================================== Yield specific functions ==============================================

    function createYieldInstrument(Symbol _symbol, bytes6 _baseId, bytes6 _quoteId, IFeeModel _feeModel)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (Instrument memory, YieldInstrument memory)
    {
        return YieldStorageLib.createInstrument(_symbol, _baseId, _quoteId, _feeModel);
    }

    function yieldInstrument(Symbol symbol) external view returns (Instrument memory, YieldInstrument memory) {
        return symbol.loadInstrument();
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
import "../../libraries/StorageLib.sol";
import "../../libraries/ErrorLib.sol";
import "../../libraries/DataTypes.sol";

library YieldUtils {
    function loadInstrument(Symbol symbol)
        internal
        view
        returns (Instrument storage instrument, YieldInstrument storage yieldInstrument)
    {
        instrument = StorageLib.getInstruments()[symbol];
        if (instrument.maturity == 0) {
            revert InvalidInstrument(symbol);
        }
        yieldInstrument = YieldStorageLib.getInstruments()[symbol];
    }

    function toVaultId(PositionId positionId) internal pure returns (bytes12) {
        return bytes12(uint96(PositionId.unwrap(positionId)));
    }

    /// @dev Ignores liquidity values that are too small to be useful
    function cap(function() view external returns (uint128) f) internal view returns (uint128) {
        IPool pool = IPool(f.address);
        uint128 liquidity = f();

        if (liquidity > 0) {
            uint256 scaleFactor = pool.scaleFactor();
            if (scaleFactor == 1 && liquidity <= 1e13 || scaleFactor == 1e12 && liquidity <= 1e3) {
                liquidity = 0;
            } else if (f.selector == IPool.maxFYTokenOut.selector) {
                uint128 balance = uint128(pool.fyToken().balanceOf(f.address));
                if (balance < liquidity) {
                    liquidity = balance;
                }
            }
        }

        return liquidity;
    }

    function buyFYTokenPreviewFixed(IPool pool, uint128 fyTokenOut) internal view returns (uint128 baseIn) {
        baseIn = buyFYTokenPreviewZero(pool, fyTokenOut);
        // Math is not exact anymore with the PoolEuler, so we need to transfer a bit more to the pool
        baseIn = baseIn == 0 ? 0 : baseIn + 1;
    }

    function buyFYTokenPreviewZero(IPool pool, uint128 fyTokenOut) internal view returns (uint128 baseIn) {
        baseIn = fyTokenOut == 0 ? 0 : pool.buyFYTokenPreview(fyTokenOut);
    }

    function sellBasePreviewZero(IPool pool, uint128 baseIn) internal view returns (uint128 fyTokenOut) {
        fyTokenOut = baseIn == 0 ? 0 : pool.sellBasePreview(baseIn);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IFeeModel.sol";
import "solmate/src/tokens/ERC20.sol";
import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";

type Symbol is bytes32;

type PositionId is uint256;

struct Position {
    Symbol symbol;
    uint256 openQuantity; // total quantity to which the trader is exposed
    uint256 openCost; // total amount that the trader exchanged for base
    int256 collateral; // Trader collateral
    uint256 protocolFees; // Fees this position accrued
    uint32 maturity; // Position maturity
    IFeeModel feeModel; // Fee model for this position
}

// Represents an execution of a trade, kinda similar to an execution report in FIX
struct Fill {
    uint256 size; // Size of the fill (base ccy)
    uint256 cost; // Amount of quote traded in exchange for the base
    uint256 hedgeSize; // Actual amount of base ccy traded on the spot market
    uint256 hedgeCost; // Actual amount of quote ccy traded on the spot market
    int256 collateral; // Amount of collateral added/removed by this fill
}

struct Instrument {
    //>slot0: 216bits used - 40bits left
    uint32 maturity;
    // This value used to be stored, but now is passed as param. It can't be removed cause of the existent data in the contract
    // So to also avoid a major refactor is used as a transient value, i.e. it's set after the struct is loaded using the user provided value
    uint24 uniswapFeeTransient;
    ERC20 base;
    bool closingOnly;
    //>slot1: 160bits used - 96bits left
    ERC20 quote;
}

struct YieldInstrument {
    //>slot0: 256bits used
    bytes6 baseId;
    bytes6 quoteId;
    IFYToken quoteFyToken;
    //>slot1: 160bits used - 96bits left
    IFYToken baseFyToken;
    //>slot2: 160bits used - 96bits left
    IPool basePool;
    //>slot3: 256bits used
    IPool quotePool;
    uint96 minQuoteDebt;
}

struct NotionalInstrument {
    //>slot0: 161bits used - 95bits left
    uint16 baseId;
    uint16 quoteId;
    uint64 basePrecision;
    uint64 quotePrecision;
    bool isQuoteWeth;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC5095.sol";
import "./IJoin.sol";
import "./IOracle.sol";

interface IFYToken is IERC5095 {

    /// @dev Oracle for the savings rate.
    function oracle() view external returns (IOracle);

    /// @dev Source of redemption funds.
    function join() view external returns (IJoin); 

    /// @dev Asset to be paid out on redemption.
    function underlying() view external returns (address);

    /// @dev Yield id of the asset to be paid out on redemption.
    function underlyingId() view external returns (bytes6);

    /// @dev Time at which redemptions are enabled.
    function maturity() view external returns (uint256);

    /// @dev Spot price (exchange rate) between the base and an interest accruing token at maturity, set to 2^256-1 before maturity
    function chiAtMaturity() view external returns (uint256);
    
    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Mint fyToken providing an equal amount of underlying to the protocol
    function mintWithUnderlying(address to, uint256 amount) external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import {IMaturingToken} from "./IMaturingToken.sol";
import {IERC20Metadata} from  "@yield-protocol/utils-v2/contracts/token/ERC20.sol";

interface IPool is IERC20, IERC2612 {
    function baseToken() external view returns(IERC20Metadata);
    function base() external view returns(IERC20);
    function burn(address baseTo, address fyTokenTo, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256);
    function buyBase(address to, uint128 baseOut, uint128 max) external returns(uint128);
    function buyBasePreview(uint128 baseOut) external view returns(uint128);
    function buyFYToken(address to, uint128 fyTokenOut, uint128 max) external returns(uint128);
    function buyFYTokenPreview(uint128 fyTokenOut) external view returns(uint128);
    function currentCumulativeRatio() external view returns (uint256 currentCumulativeRatio_, uint256 blockTimestampCurrent);
    function cumulativeRatioLast() external view returns (uint256);
    function fyToken() external view returns(IMaturingToken);
    function g1() external view returns(int128);
    function g2() external view returns(int128);
    function getC() external view returns (int128);
    function getCurrentSharePrice() external view returns (uint256);
    function getCache() external view returns (uint104 baseCached, uint104 fyTokenCached, uint32 blockTimestampLast, uint16 g1Fee_);
    function getBaseBalance() external view returns(uint128);
    function getFYTokenBalance() external view returns(uint128);
    function getSharesBalance() external view returns(uint128);
    function init(address to) external returns (uint256, uint256, uint256);
    function maturity() external view returns(uint32);
    function mint(address to, address remainder, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function mu() external view returns (int128);
    function mintWithBase(address to, address remainder, uint256 fyTokenToBuy, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function retrieveBase(address to) external returns(uint128 retrieved);
    function retrieveFYToken(address to) external returns(uint128 retrieved);
    function retrieveShares(address to) external returns(uint128 retrieved);
    function scaleFactor() external view returns(uint96);
    function sellBase(address to, uint128 min) external returns(uint128);
    function sellBasePreview(uint128 baseIn) external view returns(uint128);
    function sellFYToken(address to, uint128 min) external returns(uint128);
    function sellFYTokenPreview(uint128 fyTokenIn) external view returns(uint128);
    function setFees(uint16 g1Fee_) external;
    function sharesToken() external view returns(IERC20Metadata);
    function ts() external view returns(int128);
    function wrap(address receiver) external returns (uint256 shares);
    function wrapPreview(uint256 assets) external view returns (uint256 shares);
    function unwrap(address receiver) external returns (uint256 assets);
    function unwrapPreview(uint256 shares) external view returns (uint256 assets);
    /// Returns the max amount of FYTokens that can be sold to the pool
    function maxFYTokenIn() external view returns (uint128) ;
    /// Returns the max amount of FYTokens that can be bought from the pool
    function maxFYTokenOut() external view returns (uint128) ;
    /// Returns the max amount of Base that can be sold to the pool
    function maxBaseIn() external view returns (uint128) ;
    /// Returns the max amount of Base that can be bought from the pool
    function maxBaseOut() external view returns (uint128);
    /// Returns the result of the total supply invariant function
    function invariant() external view returns (uint128);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/DataTypes.sol";

interface IFeeModel {
    /// @notice Calculates fees for a given trade
    /// @param trader The trade trader
    /// @param positionId The trade position id
    /// @param cost The trade cost
    /// @return calculatedFee The calculated fee of the trade cost
    function calculateFee(address trader, PositionId positionId, uint256 cost)
        external
        view
        returns (uint256 calculatedFee);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IERC5095 is IERC20 {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address underlyingAddress);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256 timestamp);

    /// @dev Converts a specified amount of principal to underlying
    function convertToUnderlying(uint256 principalAmount) external returns (uint256 underlyingAmount);

    /// @dev Converts a specified amount of underlying to principal
    function convertToPrincipal(uint256 underlyingAmount) external returns (uint256 principalAmount);

    /// @dev Gives the maximum amount an address holder can redeem in terms of the principal
    function maxRedeem(address holder) external view returns (uint256 maxPrincipalAmount);

    /// @dev Gives the amount in terms of underlying that the princiapl amount can be redeemed for plus accrual
    function previewRedeem(uint256 principalAmount) external returns (uint256 underlyingAmount);

    /// @dev Burn fyToken after maturity for an amount of principal.
    function redeem(uint256 principalAmount, address to, address from) external returns (uint256 underlyingAmount);

    /// @dev Gives the maximum amount an address holder can withdraw in terms of the underlying
    function maxWithdraw(address holder) external returns (uint256 maxUnderlyingAmount);

    /// @dev Gives the amount in terms of principal that the underlying amount can be withdrawn for plus accrual
    function previewWithdraw(uint256 underlyingAmount) external returns (uint256 principalAmount);

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function withdraw(uint256 underlyingAmount, address to, address from) external returns (uint256 principalAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IJoin {
    /// @dev asset managed by this contract
    function asset() external view returns (address);

    /// @dev amount of assets held by this contract
    function storedBalance() external view returns (uint256);

    /// @dev Add tokens to this contract.
    function join(address user, uint128 wad) external returns (uint128);

    /// @dev Remove tokens to this contract.
    function exit(address user, uint128 wad) external returns (uint128);

    /// @dev Retrieve any tokens other than the `asset`. Useful for airdropped tokens.
    function retrieve(IERC20 token, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 * 
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IMaturingToken is IERC20 {
    function maturity() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/DataTypes.sol";
import "./IFeeModel.sol";

/// @title Interface to state querying
interface IContangoView {
    function position(PositionId positionId) external view returns (Position memory _position);

    function feeModel(Symbol symbol) external view returns (IFeeModel);

    function closingOnly() external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../utils/Balanceless.sol";
import "../ContangoPositionNFT.sol";
import "../batchable/Batchable.sol";
import "../batchable/PermitForwarder.sol";
import "../batchable/WethHandler.sol";
import "../interfaces/IContango.sol";
import "../libraries/DataTypes.sol";
import "../libraries/CodecLib.sol";
import "../libraries/ErrorLib.sol";

/// @notice Base contract that implements all common interfaces and function for all underlying implementations
abstract contract ContangoBase is
    IContango,
    IUniswapV3SwapCallback,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    Balanceless,
    Batchable,
    PermitForwarder,
    WethHandler
{
    using CodecLib for uint256;

    bytes32 public constant EMERGENCY_BREAK = keccak256("EMERGENCY_BREAK");
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    // solhint-disable-next-line no-empty-blocks
    constructor(WETH _weth) WethHandler(_weth) {}

    // solhint-disable-next-line func-name-mixedcase
    function __ContangoBase_init(ContangoPositionNFT _positionNFT, address _treasury) public onlyInitializing {
        __ReentrancyGuard_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __UUPSUpgradeable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        ConfigStorageLib.setTreasury(_treasury);
        ConfigStorageLib.setPositionNFT(_positionNFT);
    }

    // ============================================== Admin functions ==============================================

    function pause() external onlyRole(EMERGENCY_BREAK) {
        _pause();
    }

    function unpause() external onlyRole(EMERGENCY_BREAK) {
        _unpause();
    }

    function setClosingOnly(bool _closingOnly) external onlyRole(OPERATOR) {
        ConfigStorageLib.setClosingOnly(_closingOnly);
    }

    function closingOnly() external view override returns (bool) {
        return ConfigStorageLib.getClosingOnly();
    }

    function setClosingOnly(Symbol symbol, bool _closingOnly) external onlyRole(OPERATOR) {
        StorageLib.setClosingOnly(symbol, _closingOnly);
    }

    function setTrustedToken(address token, bool trusted) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ConfigStorageLib.setTrustedToken(token, trusted);
    }

    function setFeeModel(Symbol symbol, IFeeModel _feeModel) external onlyRole(DEFAULT_ADMIN_ROLE) {
        StorageLib.setFeeModel(symbol, _feeModel);
    }

    function collectBalance(address token, address payable to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _collectBalance(token, to, amount);
    }

    modifier whenNotClosingOnly(int256 quantity) {
        if (quantity > 0 && ConfigStorageLib.getClosingOnly()) {
            revert ClosingOnly();
        }
        _;
    }

    function _authorizeUpgrade(address) internal view override {
        _checkRole(DEFAULT_ADMIN_ROLE);
    }

    // ============================================== View functions ==============================================

    /// @inheritdoc IContangoView
    function position(PositionId positionId) public view virtual override returns (Position memory _position) {
        _position.symbol = StorageLib.getPositionInstrument()[positionId];
        (_position.openQuantity, _position.openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        (int256 collateral, int256 fees) = StorageLib.getPositionBalances()[positionId].decodeI128();
        (_position.collateral, _position.protocolFees) = (collateral, uint256(fees));

        _position.maturity = StorageLib.getInstruments()[_position.symbol].maturity;
        _position.feeModel = feeModel(_position.symbol);
    }

    /// @inheritdoc IContangoView
    function feeModel(Symbol symbol) public view override returns (IFeeModel) {
        return StorageLib.getInstrumentFeeModel()[symbol];
    }

    fallback() external payable {
        revert FunctionNotFound(msg.sig);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
import {ILadle} from "@yield-protocol/vault-v2/contracts/interfaces/ILadle.sol";
import {ICauldron} from "@yield-protocol/vault-v2/contracts/interfaces/ICauldron.sol";
import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {DataTypes} from "@yield-protocol/vault-v2/contracts/interfaces/DataTypes.sol";
import {IContangoLadle} from "@yield-protocol/vault-v2/contracts/other/contango/interfaces/IContangoLadle.sol";

import "../UniswapV3Handler.sol";
import "./YieldUtils.sol";
import "../SlippageLib.sol";
import "../../libraries/PositionLib.sol";
import "../../libraries/ErrorLib.sol";
import "../../ExecutionProcessorLib.sol";

library Yield {
    using YieldUtils for *;
    using SignedMath for int256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using CodecLib for uint256;
    using PositionLib for PositionId;
    using TransferLib for ERC20;

    event ContractTraded(Symbol indexed symbol, address indexed trader, PositionId indexed positionId, Fill fill);
    event CollateralAdded(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );
    event CollateralRemoved(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );

    uint128 public constant BORROWING_BUFFER = 5;

    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external returns (PositionId positionId) {
        if (quantity == 0) {
            revert InvalidQuantity(int256(quantity));
        }

        positionId = ConfigStorageLib.getPositionNFT().mint(trader);
        positionId.validatePayer(payer, trader);

        StorageLib.getPositionInstrument()[positionId] = symbol;
        Instrument memory instrument = _createPosition(symbol, positionId, uniswapFee);

        _open(symbol, positionId, trader, instrument, quantity, limitCost, int256(collateral), payer, lendingLiquidity);
    }

    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external {
        if (quantity == 0) {
            revert InvalidQuantity(quantity);
        }

        (uint256 openQuantity, address trader, Symbol symbol, Instrument memory instrument) =
            positionId.loadActivePosition(uniswapFee);
        if (collateral > 0) {
            positionId.validatePayer(payerOrReceiver, trader);
        }

        if (quantity < 0 && uint256(-quantity) > openQuantity) {
            revert InvalidPositionDecrease(positionId, quantity, openQuantity);
        }

        if (quantity > 0) {
            _open(
                symbol,
                positionId,
                trader,
                instrument,
                uint256(quantity),
                limitCost,
                collateral,
                payerOrReceiver,
                lendingLiquidity
            );
        } else {
            _close(
                symbol,
                positionId,
                trader,
                instrument,
                uint256(-quantity),
                limitCost,
                collateral,
                payerOrReceiver,
                lendingLiquidity
            );
        }

        if (quantity < 0 && uint256(-quantity) == openQuantity) {
            _deletePosition(positionId);
        }
    }

    function collateralBought(bytes12 vaultId, uint256 ink, uint256 art) external {
        PositionId positionId = PositionId.wrap(uint96(vaultId));
        ExecutionProcessorLib.liquidatePosition(
            StorageLib.getPositionInstrument()[positionId],
            positionId,
            ConfigStorageLib.getPositionNFT().positionOwner(positionId),
            ink,
            art
        );
    }

    function _createPosition(Symbol symbol, PositionId positionId, uint24 uniswapFee)
        private
        returns (Instrument memory instrument)
    {
        YieldInstrument storage yieldInsturment;
        (instrument, yieldInsturment) = symbol.loadInstrument();

        // solhint-disable-next-line not-rely-on-time
        if (instrument.maturity < block.timestamp) {
            // solhint-disable-next-line not-rely-on-time
            revert InstrumentExpired(symbol, instrument.maturity, block.timestamp);
        }

        YieldStorageLib.getLadle().deterministicBuild(
            positionId.toVaultId(), yieldInsturment.quoteId, yieldInsturment.baseId
        );

        instrument.uniswapFeeTransient = uniswapFee;
    }

    function _deletePosition(PositionId positionId) private {
        positionId.deletePosition();
        YieldStorageLib.getLadle().destroy(positionId.toVaultId());
    }

    function _open(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        uint256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) private {
        if (instrument.closingOnly) {
            revert InstrumentClosingOnly(symbol);
        }

        YieldInstrument storage yieldInstrument = YieldStorageLib.getInstruments()[symbol];
        address receiver = lendingLiquidity < quantity ? address(this) : address(yieldInstrument.basePool);

        // Use a flash swap to buy enough base to hedge the position, pay directly to the pool where we'll lend it
        _flashBuyHedge(
            instrument,
            yieldInstrument.basePool,
            UniswapV3Handler.CallbackInfo({
                symbol: symbol,
                positionId: positionId,
                trader: trader,
                limitCost: limitCost,
                payerOrReceiver: payerOrReceiver,
                open: true,
                lendingLiquidity: lendingLiquidity
            }),
            quantity,
            int256(collateral),
            receiver
        );
    }

    /// @dev Second step of trading, this executes on the back of the flash swap callback,
    /// it will pay part of the swap by using the trader collateral,
    /// then will borrow the rest from the lending protocol. Fill cost == swap cost + loan interest.
    /// @param callback Info collected before the flash swap started
    function completeOpen(UniswapV3Handler.Callback memory callback) internal {
        YieldInstrument storage yieldInstrument = YieldStorageLib.getInstruments()[callback.info.symbol];

        // Cast is safe as the number was previously casted as uint128
        uint128 ink = uint128(callback.fill.size);

        // Lend the base we just flash bought
        _buyFYToken({
            pool: yieldInstrument.basePool,
            underlying: callback.instrument.base,
            fyToken: yieldInstrument.baseFyToken,
            to: YieldStorageLib.getJoins()[yieldInstrument.baseId], // send the (fy)Base to the join so it can be used as collateral for borrowing
            fyTokenOut: ink,
            lendingLiquidity: callback.info.lendingLiquidity,
            excessExpected: false
        });

        // Use the payer collateral (if any) to pay part/all of the flash swap
        if (callback.fill.collateral > 0) {
            // Trader can contribute up to the spot cost
            callback.fill.collateral = SignedMath.min(callback.fill.collateral, int256(callback.fill.hedgeCost));
            callback.instrument.quote.transferOut(
                callback.info.payerOrReceiver, msg.sender, uint256(callback.fill.collateral)
            );
        }

        uint128 amountToBorrow = (int256(callback.fill.hedgeCost) - callback.fill.collateral).toUint256().toUint128();
        uint128 art;

        // If the collateral wasn't enough to cover the whole trade
        if (amountToBorrow != 0) {
            // Math is not exact anymore with the PoolEuler, so we need to borrow a bit more
            amountToBorrow += BORROWING_BUFFER;
            // How much debt at future value (art) do I need to take on in order to get enough cash at present value (remainder)
            art = yieldInstrument.quotePool.buyBasePreview(amountToBorrow);
        }

        // Deposit collateral (ink) and take on debt if necessary (art)
        YieldStorageLib.getLadle().pour(
            callback.info.positionId.toVaultId(), // Vault that will issue the debt & store the collateral
            address(yieldInstrument.quotePool), // If taking any debt, send it to the pool so it can be sold
            int128(ink), // Use the fyTokens we bought using the flash swap as ink (collateral)
            int128(art) // Amount to borrow in future value
        );

        address sendBorrowedFundsTo;

        if (callback.fill.collateral < 0) {
            // We need to keep the borrowed funds in this contract so we can pay both the trader and uniswap
            sendBorrowedFundsTo = address(this);
            // Cost is spot + financing costs
            callback.fill.cost = callback.fill.hedgeCost + (art - amountToBorrow);
        } else {
            // We can pay to uniswap directly as it's the only reason we are borrowing for
            sendBorrowedFundsTo = msg.sender;
            // Cost is spot + debt + financing costs
            callback.fill.cost = art + uint256(callback.fill.collateral);
        }

        SlippageLib.requireCostBelowTolerance(callback.fill.cost, callback.info.limitCost);

        if (amountToBorrow != 0) {
            // Sell the fyTokens for actual cash (borrow)
            yieldInstrument.quotePool.buyBase({to: sendBorrowedFundsTo, baseOut: amountToBorrow, max: art});
        }

        // Pay uniswap if necessary
        if (sendBorrowedFundsTo == address(this)) {
            callback.instrument.quote.transferOut(address(this), msg.sender, callback.fill.hedgeCost);
        }

        ExecutionProcessorLib.increasePosition(
            callback.info.symbol,
            callback.info.positionId,
            callback.info.trader,
            callback.fill.size,
            callback.fill.cost,
            callback.fill.collateral,
            callback.instrument.quote,
            callback.info.payerOrReceiver,
            yieldInstrument.minQuoteDebt
        );

        emit ContractTraded(callback.info.symbol, callback.info.trader, callback.info.positionId, callback.fill);
    }

    function _close(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        uint256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) private {
        // Execute a flash swap to undo the hedge
        _flashSellHedge(
            instrument,
            YieldStorageLib.getInstruments()[symbol].basePool,
            UniswapV3Handler.CallbackInfo({
                symbol: symbol,
                positionId: positionId,
                limitCost: limitCost,
                trader: trader,
                payerOrReceiver: payerOrReceiver,
                open: false,
                lendingLiquidity: lendingLiquidity
            }),
            quantity,
            collateral,
            address(this) // We must receive the funds ourselves cause the TV pools have a bug & will consume them all otherwise
        );
    }

    /// @dev Second step to reduce/close a position. This executes on the back of the flash swap callback,
    /// then it will repay debt using the proceeds from the flash swap and deal with any excess appropriately.
    /// @param callback Info collected before the flash swap started
    function completeClose(UniswapV3Handler.Callback memory callback) internal {
        YieldInstrument storage yieldInstrument = YieldStorageLib.getInstruments()[callback.info.symbol];
        DataTypes.Balances memory balances =
            YieldStorageLib.getCauldron().balances(callback.info.positionId.toVaultId());
        bool fullyClosing = callback.fill.size == balances.ink;
        int128 art;

        // If there's any debt to repay
        if (balances.art != 0) {
            // Use the quote we just bought to buy/mint fyTokens to reduce the debt and free up the amount we owe for the flash loan
            if (fullyClosing) {
                // If we're fully closing, pay all debt
                art = -int128(balances.art);
                // Buy the exact amount of (fy)Quote we owe (art) using the money from the flash swap (money was sent directly to the quotePool).
                // Send the tokens to the fyToken contract so they can be burnt
                // Cost == swap cost + pnl of cancelling the debt
                uint128 baseIn = _buyFYToken({
                    pool: yieldInstrument.quotePool,
                    underlying: callback.instrument.quote,
                    fyToken: yieldInstrument.quoteFyToken,
                    to: address(yieldInstrument.quoteFyToken),
                    fyTokenOut: balances.art,
                    lendingLiquidity: callback.info.lendingLiquidity,
                    excessExpected: true
                });
                callback.fill.cost = callback.fill.hedgeCost + (balances.art - baseIn);
            } else {
                // Can't withdraw more than what we got from UNI
                if (callback.fill.collateral < 0) {
                    callback.fill.collateral =
                        SignedMath.max(callback.fill.collateral, -int256(callback.fill.hedgeCost));
                }

                int256 quoteUsedToRepayDebt = callback.fill.collateral + int256(callback.fill.hedgeCost);

                if (quoteUsedToRepayDebt > 0) {
                    // If the user is depositing, take the necessary tokens from the payer
                    if (callback.fill.collateral > 0) {
                        callback.instrument.quote.transferOut({
                            payer: callback.info.payerOrReceiver,
                            to: address(this),
                            amount: uint256(callback.fill.collateral)
                        });
                    }

                    // Under normal circumstances, send the required funds to the pool
                    if (uint256(quoteUsedToRepayDebt) < callback.info.lendingLiquidity) {
                        callback.instrument.quote.transferOut({
                            payer: address(this),
                            to: address(yieldInstrument.quotePool),
                            amount: uint256(quoteUsedToRepayDebt)
                        });
                    }

                    // Buy fyTokens with the available tokens
                    art = -int128(
                        _getFYTokensToBurn({
                            pool: yieldInstrument.quotePool,
                            underlying: callback.instrument.quote,
                            fyToken: yieldInstrument.quoteFyToken,
                            availableBase: uint256(quoteUsedToRepayDebt).toUint128(),
                            lendingLiquidity: callback.info.lendingLiquidity
                        })
                    );
                }

                callback.fill.cost = (-(callback.fill.collateral + art)).toUint256();
            }
        } else {
            // Given there's no debt, the cost is the hedgeCost
            callback.fill.cost = callback.fill.hedgeCost;
        }

        SlippageLib.requireCostAboveTolerance(callback.fill.cost, callback.info.limitCost);

        // Burn debt and withdraw collateral from Yield, send the collateral directly to the basePool so it can be sold
        YieldStorageLib.getLadle().pour({
            vaultId: callback.info.positionId.toVaultId(),
            to: address(yieldInstrument.basePool),
            ink: -int256(callback.fill.size).toInt128(),
            art: art
        });
        // Sell collateral (ink) to pay for the flash swap, the amount of ink was pre-calculated to obtain the exact cost of the swap
        yieldInstrument.basePool.sellFYToken(msg.sender, uint128(callback.fill.hedgeSize));

        emit ContractTraded(callback.info.symbol, callback.info.trader, callback.info.positionId, callback.fill);

        if (fullyClosing) {
            ExecutionProcessorLib.closePosition(
                callback.info.symbol,
                callback.info.positionId,
                callback.info.trader,
                callback.fill.cost,
                callback.instrument.quote,
                callback.info.payerOrReceiver
            );
        } else {
            ExecutionProcessorLib.decreasePosition(
                callback.info.symbol,
                callback.info.positionId,
                callback.info.trader,
                callback.fill.size,
                callback.fill.cost,
                callback.fill.collateral,
                callback.instrument.quote,
                callback.info.payerOrReceiver,
                yieldInstrument.minQuoteDebt
            );
        }
    }

    // ============== Physical delivery ==============

    function deliver(PositionId positionId, address payer, address to) external {
        address trader = positionId.positionOwner();
        positionId.validatePayer(payer, trader);

        (, Symbol symbol, Instrument memory instrument) = positionId.validateExpiredPosition();

        _deliver(symbol, positionId, trader, instrument, payer, to);

        _deletePosition(positionId);
    }

    function _deliver(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        address payer,
        address to
    ) private {
        YieldInstrument storage yieldInstrument = YieldStorageLib.getInstruments()[symbol];
        IFYToken baseFyToken = yieldInstrument.baseFyToken;
        ILadle ladle = YieldStorageLib.getLadle();
        ICauldron cauldron = YieldStorageLib.getCauldron();
        DataTypes.Balances memory balances = cauldron.balances(positionId.toVaultId());

        uint256 requiredQuote;
        if (balances.art != 0) {
            bytes6 quoteId = yieldInstrument.quoteId;

            // we need to cater for the interest rate accrued after maturity
            requiredQuote = cauldron.debtToBase(quoteId, balances.art);

            // Send the requiredQuote to the Join
            instrument.quote.transferOut(payer, address(ladle.joins(cauldron.series(quoteId).baseId)), requiredQuote);

            ladle.close(
                positionId.toVaultId(),
                address(baseFyToken), // Send ink to be redeemed on the FYToken contract
                -int128(balances.ink), // withdraw ink
                -int128(balances.art) // repay art
            );
        } else {
            ladle.pour(
                positionId.toVaultId(),
                address(baseFyToken), // Send ink to be redeemed on the FYToken contract
                -int128(balances.ink), // withdraw ink
                0 // no debt to repay
            );
        }

        ExecutionProcessorLib.deliverPosition(
            symbol,
            positionId,
            trader,
            // Burn fyTokens in exchange for underlying, send underlying to `to`
            baseFyToken.redeem(to, balances.ink),
            requiredQuote,
            payer,
            instrument.quote,
            to
        );
    }

    // ============== Collateral management ==============

    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external {
        // uniswapFee is irrelevant as there'll be no trade on UNI
        (, address trader, Symbol symbol, Instrument memory instrument) = positionId.loadActivePosition({uniswapFee: 0});

        if (collateral > 0) {
            positionId.validatePayer(payerOrReceiver, trader);
            _addCollateral(
                symbol,
                positionId,
                trader,
                instrument,
                uint256(collateral),
                slippageTolerance,
                payerOrReceiver,
                lendingLiquidity
            );
        }
        if (collateral < 0) {
            _removeCollateral(symbol, positionId, trader, uint256(-collateral), slippageTolerance, payerOrReceiver);
        }
    }

    function _addCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        uint256 collateral,
        uint256 slippageTolerance,
        address payer,
        uint256 lendingLiquidity
    ) private {
        YieldInstrument storage yieldInstrument = YieldStorageLib.getInstruments()[symbol];
        IPool quotePool = yieldInstrument.quotePool;

        address to = collateral > lendingLiquidity ? address(this) : address(quotePool);
        if (to != payer) {
            // Collect the new collateral from the payer and send wherever's appropriate
            instrument.quote.transferOut({payer: payer, to: to, amount: collateral});
        }

        // Sell the collateral and get as much (fy)Quote (art) as possible
        uint256 art = _getFYTokensToBurn({
            pool: quotePool,
            underlying: instrument.quote,
            fyToken: yieldInstrument.quoteFyToken,
            availableBase: collateral.toUint128(),
            lendingLiquidity: lendingLiquidity
        });

        SlippageLib.requireCostAboveTolerance(art, slippageTolerance);

        // Use the (fy)Quote (art) we bought to burn debt on the vault
        YieldStorageLib.getLadle().pour(
            positionId.toVaultId(),
            address(0), // We're not taking new debt, so no need to pass an address
            0, // We're not changing the collateral
            -int256(art).toInt128() // We burn all the (fy)Quote we just bought
        );

        // The interest pnl is reflected on the position cost
        int256 cost = -int256(art - collateral);

        // cast to int is safe as we prev casted to uint128
        ExecutionProcessorLib.updateCollateral(symbol, positionId, trader, cost, int256(collateral));

        emit CollateralAdded(symbol, trader, positionId, collateral, art);
    }

    function _removeCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 collateral,
        uint256 slippageTolerance,
        address to
    ) private {
        // Borrow whatever the trader wants to withdraw
        uint128 art = YieldStorageLib.getLadle().serve(
            positionId.toVaultId(),
            to, // Send the borrowed funds directly
            0, // We don't deposit any new collateral
            collateral.toUint128(), // Amount to borrow
            type(uint128).max // We don't need slippage control here, we have a general check below
        );

        SlippageLib.requireCostBelowTolerance(art, slippageTolerance);

        // The interest pnl is reflected on the position cost
        int256 cost = int256(art - collateral);

        // cast to int is safe as we prev casted to uint128
        ExecutionProcessorLib.updateCollateral(symbol, positionId, trader, cost, -int256(collateral));

        emit CollateralRemoved(symbol, trader, positionId, collateral, art);
    }

    // ============== Uniswap functions ==============

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        UniswapV3Handler.uniswapV3SwapCallback(amount0Delta, amount1Delta, data, _onUniswapCallback);
    }

    function _onUniswapCallback(UniswapV3Handler.Callback memory callback) internal {
        callback.info.open ? completeOpen(callback) : completeClose(callback);
    }

    function _flashBuyHedge(
        Instrument memory instrument,
        IPool basePool,
        UniswapV3Handler.CallbackInfo memory callbackInfo,
        uint256 quantity,
        int256 collateral,
        address to
    ) private {
        UniswapV3Handler.Callback memory callback;

        callback.info = callbackInfo;
        callback.fill.size = quantity;
        callback.fill.collateral = collateral;
        callback.fill.hedgeSize = _buyFYTokenPreview(basePool, quantity.toUint128(), callbackInfo.lendingLiquidity);

        UniswapV3Handler.flashSwap({callback: callback, instrument: instrument, baseForQuote: false, to: to});
    }

    function _flashSellHedge(
        Instrument memory instrument,
        IPool basePool,
        UniswapV3Handler.CallbackInfo memory callbackInfo,
        uint256 quantity,
        int256 collateral,
        address to
    ) private {
        UniswapV3Handler.Callback memory callback;

        callback.info = callbackInfo;
        callback.fill.size = quantity;
        callback.fill.collateral = collateral;
        callback.fill.hedgeSize = basePool.sellFYTokenPreview(quantity.toUint128());

        UniswapV3Handler.flashSwap({callback: callback, instrument: instrument, baseForQuote: true, to: to});
    }

    // ============== Private functions ==============

    function _getFYTokensToBurn(
        IPool pool,
        ERC20 underlying,
        IFYToken fyToken,
        uint128 availableBase,
        uint256 lendingLiquidity
    ) private returns (uint128 fyTokenOut) {
        if (availableBase > lendingLiquidity) {
            uint128 maxBaseIn = uint128(lendingLiquidity);
            fyTokenOut = pool.sellBasePreviewZero(maxBaseIn);
            if (fyTokenOut > 0) {
                // Transfer max amount that can be sold
                underlying.transferOut({payer: address(this), to: address(pool), amount: maxBaseIn});
                // Sell limited amount to the pool
                fyTokenOut = pool.sellBase({to: address(fyToken), min: fyTokenOut});
            } else {
                maxBaseIn = 0;
            }

            fyTokenOut += _forceLend(underlying, fyToken, address(fyToken), availableBase - maxBaseIn);
        } else {
            fyTokenOut = pool.sellBase({to: address(fyToken), min: availableBase});
        }
    }

    function _buyFYTokenPreview(IPool pool, uint128 fyTokenOut, uint256 lendingLiquidity)
        private
        view
        returns (uint128 baseIn)
    {
        if (fyTokenOut > lendingLiquidity) {
            uint128 maxFYTokenOut = uint128(lendingLiquidity);
            baseIn = maxFYTokenOut == 0
                ? fyTokenOut
                : fyTokenOut - maxFYTokenOut + pool.buyFYTokenPreviewFixed(maxFYTokenOut);
        } else {
            baseIn = pool.buyFYTokenPreviewFixed(fyTokenOut);
        }
    }

    function _buyFYToken(
        IPool pool,
        ERC20 underlying,
        IFYToken fyToken,
        address to,
        uint128 fyTokenOut,
        uint256 lendingLiquidity,
        bool excessExpected
    ) private returns (uint128 baseIn) {
        if (fyTokenOut > lendingLiquidity) {
            uint128 maxFYTokenOut = uint128(lendingLiquidity);

            if (maxFYTokenOut > 0) {
                baseIn = _buyFYToken(pool, underlying, to, maxFYTokenOut);
            }

            baseIn += _forceLend(underlying, fyToken, to, fyTokenOut - maxFYTokenOut);
        } else {
            baseIn = excessExpected
                ? _buyFYToken(pool, underlying, to, fyTokenOut)
                : pool.buyFYToken(to, fyTokenOut, type(uint128).max);
        }
    }

    function _buyFYToken(IPool pool, ERC20 underlying, address to, uint128 fyTokenOut)
        private
        returns (uint128 baseIn)
    {
        baseIn = uint128(underlying.transferOut(address(this), address(pool), pool.buyFYTokenPreviewFixed(fyTokenOut)));
        pool.buyFYToken(to, fyTokenOut, type(uint128).max);
    }

    function _forceLend(ERC20 underlying, IFYToken fyToken, address to, uint128 toMint) internal returns (uint128) {
        underlying.transferOut(address(this), address(fyToken.join()), toMint);
        fyToken.mintWithUnderlying(to, toMint);
        return toMint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../interfaces/ILadle.sol";

interface IContangoLadle is ILadle {
    function deterministicBuild(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory vault);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContangoWitchListener {
    function auctionStarted(bytes12 vaultId) external;

    function collateralBought(
        bytes12 vaultId,
        address buyer,
        uint256 ink,
        uint256 art
    ) external;

    function auctionEnded(bytes12 vaultId, address owner) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "dss-interfaces/src/dss/DaiAbstract.sol";
import "../libraries/StorageLib.sol";

abstract contract PermitForwarder {
    using SafeERC20 for IERC20Permit;

    error UnknownToken(address token);

    /// @dev Execute an ERC2612 permit for the selected token
    function forwardPermit(
        IERC20Permit token,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (ConfigStorageLib.isTrustedToken(address(token))) {
            token.safePermit(msg.sender, spender, amount, deadline, v, r, s);
        } else {
            revert UnknownToken(address(token));
        }
    }

    /// @dev Execute a Dai-style permit for the selected token
    function forwardDaiPermit(
        DaiAbstract token,
        address spender,
        uint256 nonce,
        uint256 deadline,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (ConfigStorageLib.isTrustedToken(address(token))) {
            token.permit(msg.sender, spender, nonce, deadline, allowed, v, r, s);
        } else {
            revert UnknownToken(address(token));
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../libraries/TransferLib.sol";

abstract contract Balanceless {
    using SafeTransferLib for address payable;
    using TransferLib for ERC20;

    event BalanceCollected(address indexed token, address indexed to, uint256 amount);

    /// @dev Contango contracts are never meant to hold a balance.
    function _collectBalance(address token, address payable to, uint256 amount) internal {
        if (token == address(0)) {
            to.safeTransferETH(amount);
        } else {
            ERC20(token).transferOut(address(this), to, amount);
        }
        emit BalanceCollected(token, to, amount);
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// Inspired by: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
abstract contract Batchable {
    error TransactionRevertedSilently();

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @return results An array with the outputs for each call.
    function batch(bytes[] calldata calls) external payable returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint256 i; i < calls.length;) {
            results[i] = _delegatecall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev modified from https://ethereum.stackexchange.com/questions/109457/how-to-bubble-up-a-custom-error-when-using-delegatecall
    function _delegatecall(bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).delegatecall(data);
        if (!success) {
            if (returnData.length == 0) revert TransactionRevertedSilently();
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(32, returnData), mload(returnData))
            }
        }
        return returnData;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IContangoView.sol";

/// @title Interface to allow for position management
interface IContango is IContangoView {
    /// @notice Creates a new position in the system by performing a trade of `quantity` at `limitCost` with `collateral`
    /// @param symbol Symbol of the instrument to be traded
    /// @param trader Which address will own the position
    /// @param quantity Desired position size. Always expressed in base currency, can't be zero
    /// @param limitCost The worst price the user is willing to accept (slippage). Always expressed in quote currency
    /// @param collateral Amount the user will post to secure the leveraged trade. Always expressed in quote currency
    /// @param payer Which address will post the `collateral`
    /// @param lendingLiquidity Liquidity for the lending leg, we'll mint tokens 1:1 if said liquidity is not enough
    /// @param uniswapFee The fee (pool) to be used for the trade
    /// @return positionId Id of the newly created position
    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external payable returns (PositionId positionId);

    /// @notice Modifies an existing position, changing its size & collateral (optional)
    /// @param positionId the id of an exiting position, the caller of this method must be its owner
    /// @param quantity Quantity to be increased (> 0) or decreased (< 0). Always expressed in base currency, can't be zero
    /// @param limitCost The worst price the user is willing to accept (slippage). Always expressed in quote currency
    /// @param collateral < 0 ? How much equity should be sent to `payerOrReceiver` : How much collateral will be taken from `payerOrReceiver` and added to the position
    /// @param payerOrReceiver Which address will receive the funds if `collateral` > 0, or which address will pay for them if `collateral` > 0
    /// @param lendingLiquidity Deals with low liquidity, when decreasing, pay debt 1:1, when increasing lend tokens 1:1
    /// @param uniswapFee The fee (pool) to be used for the trade
    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external payable;

    /// @notice Modifies an existing position, adding or removing collateral
    /// @param positionId the id of an exiting position, the caller of this method must be its owner
    /// @param collateral < 0 ? How much equity should be sent to `payerOrReceiver` : How much collateral will be taken from `payerOrReceiver` and added to the position
    /// @param slippageTolerance the min/max amount the trader is willing to receive/pay
    /// @param payerOrReceiver Which address will pay/receive the `collateral`
    /// @param lendingLiquidity Liquidity for the lending leg, we'll mint tokens 1:1 if said liquidity is not enough. Ignored if `collateral` < 0
    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external payable;

    /// @notice Delivers an expired position by receiving the remaining payment for the leveraged position and physically delivering it
    /// @param positionId the id of an expired position, the caller of this method must be its owner
    /// @param payer Which address will pay for the remaining cost
    /// @param to Which address will receive the base currency
    function deliver(PositionId positionId, address payer, address to) external payable;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "solmate/src/tokens/WETH.sol";
import "solmate/src/utils/SafeTransferLib.sol";

abstract contract WethHandler {
    using SafeTransferLib for address payable;

    error OnlyFromWETH(address weth, address sender);
    error NothingToWrap();

    WETH public immutable weth;

    constructor(WETH _weth) {
        weth = _weth;
    }

    function wrapETH() external payable returns (uint256 wrapped) {
        wrapped = address(this).balance;
        if (wrapped == 0) {
            revert NothingToWrap();
        }
        weth.deposit{value: wrapped}();
    }

    function unwrapWETH(address payable to) external payable returns (uint256 unwrapped) {
        unwrapped = weth.balanceOf(address(this));
        // We don't wanna act on 0 unwrap as some batch calls may add it just in case
        if (unwrapped != 0) {
            weth.withdraw(unwrapped);
            to.safeTransferETH(unwrapped);
        }
    }

    /// @dev `weth.withdraw` will send ether using this function.
    receive() external payable virtual {
        if (msg.sender != address(weth)) {
            revert OnlyFromWETH(address(weth), msg.sender);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "solmate/src/tokens/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import {DataTypes} from "@yield-protocol/vault-v2/contracts/interfaces/DataTypes.sol";
import {IContangoLadle} from "@yield-protocol/vault-v2/contracts/other/contango/interfaces/IContangoLadle.sol";
import {ICauldron} from "@yield-protocol/vault-v2/contracts/interfaces/ICauldron.sol";

import "../liquiditysource/notional/internal/Types.sol";
import "../liquiditysource/notional/internal/interfaces/NotionalProxy.sol";
import "../liquiditysource/notional/ContangoVault.sol";
import "../liquiditysource/notional/NotionalUtils.sol";

import "../interfaces/IFeeModel.sol";
import "solmate/src/utils/SafeTransferLib.sol";
import "./ErrorLib.sol";
import "./DataTypes.sol";
import "../ContangoPositionNFT.sol";

// solhint-disable no-inline-assembly
library StorageLib {
    event FeeModelUpdated(Symbol indexed symbol, IFeeModel feeModel);
    event ClosingOnlySet(Symbol symbol, bool closingOnly);

    /// @dev Offset for the initial slot in lib storage, gives us this number of storage slots available
    /// Make sure it's different from any other StorageLib
    uint256 private constant STORAGE_SLOT_BASE = 1_000_000;

    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum StorageId {
        Unused, // 0
        PositionBalances, // 1
        PositionNotionals, // 2
        InstrumentFeeModel, // 3
        PositionInstrument, // 4
        Instrument // 5
    }

    /// @dev Mapping from a position id to encoded position balances
    function getPositionBalances() internal pure returns (mapping(PositionId => uint256) storage store) {
        return _getUint256ToUint256Mapping(StorageId.PositionBalances);
    }

    /// @dev Mapping from a position id to encoded position notionals
    function getPositionNotionals() internal pure returns (mapping(PositionId => uint256) storage store) {
        return _getUint256ToUint256Mapping(StorageId.PositionNotionals);
    }

    /// @dev Mapping from an instrument symbol to a fee model
    function getInstrumentFeeModel() internal pure returns (mapping(Symbol => IFeeModel) storage store) {
        uint256 slot = getStorageSlot(StorageId.InstrumentFeeModel);
        assembly {
            store.slot := slot
        }
    }

    /// @dev Mapping from a position id to a fee model
    function getInstrumentFeeModel(PositionId positionId) internal view returns (IFeeModel) {
        return getInstrumentFeeModel()[getPositionInstrument()[positionId]];
    }

    /// @dev Mapping from a position id to an instrument symbol
    function getPositionInstrument() internal pure returns (mapping(PositionId => Symbol) storage store) {
        uint256 slot = getStorageSlot(StorageId.PositionInstrument);
        assembly {
            store.slot := slot
        }
    }

    /// @dev Mapping from an instrument symbol to an instrument
    function getInstruments() internal pure returns (mapping(Symbol => Instrument) storage store) {
        uint256 slot = getStorageSlot(StorageId.Instrument);
        assembly {
            store.slot := slot
        }
    }

    function getInstrument(PositionId positionId)
        internal
        view
        returns (Symbol symbol, Instrument storage instrument)
    {
        symbol = StorageLib.getPositionInstrument()[positionId];
        instrument = getInstruments()[symbol];
    }

    function setFeeModel(Symbol symbol, IFeeModel feeModel) internal {
        StorageLib.getInstrumentFeeModel()[symbol] = feeModel;
        emit FeeModelUpdated(symbol, feeModel);
    }

    function setClosingOnly(Symbol symbol, bool closingOnly) internal {
        StorageLib.getInstruments()[symbol].closingOnly = closingOnly;
        emit ClosingOnlySet(symbol, closingOnly);
    }

    function _getUint256ToUint256Mapping(StorageId storageId)
        private
        pure
        returns (mapping(PositionId => uint256) storage store)
    {
        uint256 slot = getStorageSlot(storageId);
        assembly {
            store.slot := slot
        }
    }

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}

library YieldStorageLib {
    using SafeCast for uint256;

    /// @dev Offset for the initial slot in lib storage, gives us this number of storage slots available
    /// Make sure it's different from any other StorageLib
    uint256 private constant YIELD_STORAGE_SLOT_BASE = 2_000_000;

    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum YieldStorageId {
        Unused, // 0
        Instruments, // 1
        Joins, // 2
        Ladle, // 3
        Cauldron, // 4
        PoolView // 5
    }

    error InvalidBaseId(Symbol symbol, bytes6 baseId);
    error InvalidQuoteId(Symbol symbol, bytes6 quoteId);
    error MismatchedMaturity(Symbol symbol, bytes6 baseId, uint256 baseMaturity, bytes6 quoteId, uint256 quoteMaturity);

    event YieldInstrumentCreated(Instrument instrument, YieldInstrument yieldInstrument);
    event LadleSet(IContangoLadle ladle);
    event CauldronSet(ICauldron cauldron);

    function getLadle() internal view returns (IContangoLadle) {
        return IContangoLadle(StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Ladle))).value);
    }

    function setLadle(IContangoLadle ladle) internal {
        StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Ladle))).value = address(ladle);
        emit LadleSet(ladle);
    }

    function getCauldron() internal view returns (ICauldron) {
        return ICauldron(StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Cauldron))).value);
    }

    function setCauldron(ICauldron cauldron) internal {
        StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Cauldron))).value = address(cauldron);
        emit CauldronSet(cauldron);
    }

    /// @dev Mapping from a symbol to instrument
    function getInstruments() internal pure returns (mapping(Symbol => YieldInstrument) storage store) {
        uint256 slot = getStorageSlot(YieldStorageId.Instruments);
        assembly {
            store.slot := slot
        }
    }

    function createInstrument(Symbol symbol, bytes6 baseId, bytes6 quoteId, IFeeModel feeModel)
        internal
        returns (Instrument memory instrument, YieldInstrument memory yieldInstrument)
    {
        ICauldron cauldron = getCauldron();
        (DataTypes.Series memory baseSeries, DataTypes.Series memory quoteSeries) =
            _validInstrumentData(cauldron, symbol, baseId, quoteId);

        StorageLib.getInstrumentFeeModel()[symbol] = feeModel;
        IContangoLadle ladle = getLadle();

        (instrument, yieldInstrument) = _createInstrument(ladle, cauldron, baseId, quoteId, baseSeries, quoteSeries);

        getJoins()[yieldInstrument.baseId] = address(ladle.joins(yieldInstrument.baseId));
        getJoins()[yieldInstrument.quoteId] = address(ladle.joins(yieldInstrument.quoteId));

        StorageLib.getInstruments()[symbol] = instrument;
        getInstruments()[symbol] = yieldInstrument;

        emit YieldInstrumentCreated(instrument, yieldInstrument);
    }

    function _createInstrument(
        IContangoLadle ladle,
        ICauldron cauldron,
        bytes6 baseId,
        bytes6 quoteId,
        DataTypes.Series memory baseSeries,
        DataTypes.Series memory quoteSeries
    ) private view returns (Instrument memory instrument, YieldInstrument memory yieldInstrument) {
        yieldInstrument.baseId = baseId;
        yieldInstrument.quoteId = quoteId;

        yieldInstrument.basePool = IPool(ladle.pools(yieldInstrument.baseId));
        yieldInstrument.quotePool = IPool(ladle.pools(yieldInstrument.quoteId));

        yieldInstrument.baseFyToken = baseSeries.fyToken;
        yieldInstrument.quoteFyToken = quoteSeries.fyToken;

        DataTypes.Debt memory debt = cauldron.debt(quoteSeries.baseId, yieldInstrument.baseId);
        yieldInstrument.minQuoteDebt = debt.min * uint96(10) ** debt.dec;

        instrument.maturity = baseSeries.maturity;
        instrument.base = ERC20(yieldInstrument.baseFyToken.underlying());
        instrument.quote = ERC20(yieldInstrument.quoteFyToken.underlying());
    }

    function getJoins() internal pure returns (mapping(bytes12 => address) storage store) {
        uint256 slot = getStorageSlot(YieldStorageId.Joins);
        assembly {
            store.slot := slot
        }
    }

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `YieldStorageId`
    /// @return slot The storage slot.
    function getStorageSlot(YieldStorageId storageId) internal pure returns (uint256 slot) {
        return uint256(storageId) + YIELD_STORAGE_SLOT_BASE;
    }

    function _validInstrumentData(ICauldron cauldron, Symbol symbol, bytes6 baseId, bytes6 quoteId)
        private
        view
        returns (DataTypes.Series memory baseSeries, DataTypes.Series memory quoteSeries)
    {
        if (StorageLib.getInstruments()[symbol].maturity != 0) {
            revert InstrumentAlreadyExists(symbol);
        }

        baseSeries = cauldron.series(baseId);
        uint256 baseMaturity = baseSeries.maturity;
        if (baseMaturity == 0 || baseMaturity > type(uint32).max) {
            revert InvalidBaseId(symbol, baseId);
        }

        quoteSeries = cauldron.series(quoteId);
        uint256 quoteMaturity = quoteSeries.maturity;
        if (quoteMaturity == 0 || quoteMaturity > type(uint32).max) {
            revert InvalidQuoteId(symbol, quoteId);
        }

        if (baseMaturity != quoteMaturity) {
            revert MismatchedMaturity(symbol, baseId, baseMaturity, quoteId, quoteMaturity);
        }
    }
}

library NotionalStorageLib {
    using NotionalUtils for ERC20;
    using SafeCast for uint256;

    NotionalProxy internal constant NOTIONAL = NotionalProxy(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);

    /// @dev Offset for the initial slot in lib storage, gives us this number of storage slots available
    /// Make sure it's different from any other StorageLib
    uint256 private constant NOTIONAL_STORAGE_SLOT_BASE = 3_000_000;

    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum NotionalStorageId {
        Unused, // 0
        Instruments, // 1
        Vaults // 2
    }

    error InvalidBaseId(Symbol symbol, uint16 currencyId);
    error InvalidQuoteId(Symbol symbol, uint16 currencyId);
    error InvalidMarketIndex(uint16 currencyId, uint256 marketIndex, uint256 max);
    error MismatchedMaturity(Symbol symbol, uint16 baseId, uint32 baseMaturity, uint16 quoteId, uint32 quoteMaturity);

    event NotionalInstrumentCreated(Instrument instrument, NotionalInstrument notionalInstrument, ContangoVault vault);

    function getVaults() internal pure returns (mapping(Symbol => ContangoVault) storage store) {
        uint256 slot = getStorageSlot(NotionalStorageId.Vaults);
        assembly {
            store.slot := slot
        }
    }

    /// @dev Mapping from a symbol to instrument
    function getInstruments() internal pure returns (mapping(Symbol => NotionalInstrument) storage store) {
        uint256 slot = getStorageSlot(NotionalStorageId.Instruments);
        assembly {
            store.slot := slot
        }
    }

    function getInstrument(PositionId positionId) internal view returns (NotionalInstrument storage) {
        return getInstruments()[StorageLib.getPositionInstrument()[positionId]];
    }

    function createInstrument(
        Symbol symbol,
        uint16 baseId,
        uint16 quoteId,
        uint256 marketIndex,
        IFeeModel feeModel,
        ContangoVault vault,
        address weth // sucks but beats doing another SLOAD to fetch from configs
    ) internal returns (Instrument memory instrument, NotionalInstrument memory notionalInstrument) {
        StorageLib.getInstrumentFeeModel()[symbol] = feeModel;

        uint32 maturity = _validInstrumentData(symbol, baseId, quoteId, marketIndex);
        (instrument, notionalInstrument) = _createInstrument(baseId, quoteId, maturity, weth);

        // since the contango contracts should not hold any funds once a transaction is done,
        // and createInstrument is a permissioned manually invoked admin function (therefore with controlled inputs),
        // infinite approve here to the vault is fine
        SafeTransferLib.safeApprove(ERC20(address(instrument.base)), address(vault), type(uint256).max);
        SafeTransferLib.safeApprove(ERC20(address(instrument.quote)), address(vault), type(uint256).max);

        StorageLib.getInstruments()[symbol] = instrument;
        getInstruments()[symbol] = notionalInstrument;
        getVaults()[symbol] = vault;

        emit NotionalInstrumentCreated(instrument, notionalInstrument, vault);
    }

    function _createInstrument(uint16 baseId, uint16 quoteId, uint32 maturity, address weth)
        private
        view
        returns (Instrument memory instrument, NotionalInstrument memory notionalInstrument)
    {
        notionalInstrument.baseId = baseId;
        notionalInstrument.quoteId = quoteId;

        instrument.maturity = maturity;

        (, Token memory baseUnderlyingToken) = NOTIONAL.getCurrency(baseId);
        (, Token memory quoteUnderlyingToken) = NOTIONAL.getCurrency(quoteId);

        address baseAddress = baseUnderlyingToken.tokenType == TokenType.Ether ? weth : baseUnderlyingToken.tokenAddress;
        address quoteAddress =
            quoteUnderlyingToken.tokenType == TokenType.Ether ? weth : quoteUnderlyingToken.tokenAddress;

        instrument.base = ERC20(baseAddress);
        instrument.quote = ERC20(quoteAddress);

        notionalInstrument.basePrecision = (10 ** instrument.base.decimals()).toUint64();
        notionalInstrument.quotePrecision = (10 ** instrument.quote.decimals()).toUint64();

        notionalInstrument.isQuoteWeth = address(instrument.quote) == address(weth);
    }

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `NotionalStorageId`
    /// @return slot The storage slot.
    function getStorageSlot(NotionalStorageId storageId) internal pure returns (uint256 slot) {
        return uint256(storageId) + NOTIONAL_STORAGE_SLOT_BASE;
    }

    function _validInstrumentData(Symbol symbol, uint16 baseId, uint16 quoteId, uint256 marketIndex)
        private
        view
        returns (uint32)
    {
        if (StorageLib.getInstruments()[symbol].maturity != 0) {
            revert InstrumentAlreadyExists(symbol);
        }

        // should never happen in Notional since it validates that the currencyId is valid and has a valid maturity
        uint256 baseMaturity = _validateMarket(NOTIONAL, baseId, marketIndex);
        if (baseMaturity == 0 || baseMaturity > type(uint32).max) {
            revert InvalidBaseId(symbol, baseId);
        }

        // should never happen in Notional since it validates that the currencyId is valid and has a valid maturity
        uint256 quoteMaturity = _validateMarket(NOTIONAL, quoteId, marketIndex);
        if (quoteMaturity == 0 || quoteMaturity > type(uint32).max) {
            revert InvalidQuoteId(symbol, quoteId);
        }

        // should never happen since we're using the exact marketIndex on the same block/timestamp
        if (baseMaturity != quoteMaturity) {
            revert MismatchedMaturity(symbol, baseId, uint32(baseMaturity), quoteId, uint32(quoteMaturity));
        }

        return uint32(baseMaturity);
    }

    function _validateMarket(NotionalProxy notional, uint16 currencyId, uint256 marketIndex)
        private
        view
        returns (uint256 maturity)
    {
        MarketParameters[] memory marketParameters = notional.getActiveMarkets(currencyId);
        if (marketIndex == 0 || marketIndex > marketParameters.length) {
            revert InvalidMarketIndex(currencyId, marketIndex, marketParameters.length);
        }

        maturity = marketParameters[marketIndex - 1].maturity;
    }
}

library ConfigStorageLib {
    bytes32 private constant TREASURY = keccak256("ConfigStorageLib.TREASURY");
    bytes32 private constant NFT = keccak256("ConfigStorageLib.NFT");
    bytes32 private constant CLOSING_ONLY = keccak256("ConfigStorageLib.CLOSING_ONLY");
    bytes32 private constant TRUSTED_TOKENS = keccak256("ConfigStorageLib.TRUSTED_TOKENS");
    bytes32 private constant PROXY_HASH = keccak256("ConfigStorageLib.PROXY_HASH");

    event TreasurySet(address treasury);
    event PositionNFTSet(address positionNFT);
    event ClosingOnlySet(bool closingOnly);
    event TokenTrusted(address indexed token, bool trusted);
    event ProxyHashSet(bytes32 proxyHash);

    function getTreasury() internal view returns (address) {
        return StorageSlot.getAddressSlot(TREASURY).value;
    }

    function setTreasury(address treasury) internal {
        StorageSlot.getAddressSlot(TREASURY).value = treasury;
        emit TreasurySet(address(treasury));
    }

    function getPositionNFT() internal view returns (ContangoPositionNFT) {
        return ContangoPositionNFT(StorageSlot.getAddressSlot(NFT).value);
    }

    function setPositionNFT(ContangoPositionNFT nft) internal {
        StorageSlot.getAddressSlot(NFT).value = address(nft);
        emit PositionNFTSet(address(nft));
    }

    function getClosingOnly() internal view returns (bool) {
        return StorageSlot.getBooleanSlot(CLOSING_ONLY).value;
    }

    function setClosingOnly(bool closingOnly) internal {
        StorageSlot.getBooleanSlot(CLOSING_ONLY).value = closingOnly;
        emit ClosingOnlySet(closingOnly);
    }

    function isTrustedToken(address token) internal view returns (bool) {
        return _getAddressToBoolMapping(TRUSTED_TOKENS)[token];
    }

    function setTrustedToken(address token, bool trusted) internal {
        _getAddressToBoolMapping(TRUSTED_TOKENS)[token] = trusted;
        emit TokenTrusted(token, trusted);
    }

    function getProxyHash() internal view returns (bytes32) {
        return StorageSlot.getBytes32Slot(PROXY_HASH).value;
    }

    function setProxyHash(bytes32 proxyHash) internal {
        StorageSlot.getBytes32Slot(PROXY_HASH).value = proxyHash;
        emit ProxyHashSet(proxyHash);
    }

    function _getAddressToBoolMapping(bytes32 slot) private pure returns (mapping(address => bool) storage store) {
        assembly {
            store.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface DaiAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "solmate/src/tokens/ERC20.sol";
import "solmate/src/tokens/WETH.sol";
import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./internal/interfaces/NotionalProxy.sol";
import "./internal/interfaces/IStrategyVault.sol";
import "./internal/interfaces/ITradingModule.sol";
import "./internal/Types.sol";
import "./internal/Constants.sol";

import "../../libraries/DataTypes.sol";
import "../../libraries/ErrorLib.sol";
import "../../libraries/ProxyLib.sol";
import "../../utils/Balanceless.sol";

import "./NotionalUtils.sol";

// solhint-disable not-rely-on-time, var-name-mixedcase
contract ContangoVault is IStrategyVault, AccessControlUpgradeable, UUPSUpgradeable, Balanceless {
    using NotionalUtils for uint256;
    using ProxyLib for PositionId;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    error CanNotSettleBeforeMaturity();
    error InsufficientBorrowedAmount(uint256 expected, uint256 borrowed);
    error InsufficientWithdrawAmount(uint256 expected, uint256 borrowed);
    error InvalidContangoProxy(address expected, address actual);
    error OnlyContango();
    error OnlyNotional();
    error OnlyVault();
    error Unsupported();

    struct EnterParams {
        // Contango position Id for proxy validation
        PositionId positionId;
        // Amount of underlying lending token to lend
        uint256 lendAmount;
        // Amount of lent fCash to be received from lending lendAmount
        uint256 fCashLendAmount;
        // Amount of underlying borrowing token to send to the receiver
        uint256 borrowAmount;
        // Address paying for the lending position
        address payer;
        // Address receiving the borrowed underlying
        address receiver;
    }

    struct ExitParams {
        // Contango position Id for proxy validation
        PositionId positionId;
        // Amount of underlying lending token to send to the receiver
        uint256 withdrawAmount;
        // Address paying for the borrowing unwind
        address payer;
        // Address receiving the lending unwind
        address receiver;
    }

    struct SettleParams {
        // Address paying for the borrowing unwind
        address payer;
        // Address receiving the lending unwind
        address receiver;
        // Amount of underlying borrowing token to pay back on post maturity redeem
        uint256 repaymentAmount;
        // Amount of underlying lending token to send to the receiver
        uint256 withdrawAmount;
    }

    uint8 private constant INTERNAL_TOKEN_DECIMALS = 8;

    /// @notice Hardcoded on the implementation contract during deployment
    NotionalProxy public immutable notional;
    ITradingModule public immutable tradingModule;
    address public immutable contango;
    bytes32 public immutable contangoProxyHash;

    // TODO alfredo - evaluate using storage to facilitate upgrades

    // Borrow Currency ID the vault is configured with
    uint16 public immutable borrowCurrencyId;
    // True if borrow the underlying is ETH
    bool public immutable borrowUnderlyingIsEth;
    // Address of the borrow underlying token
    ERC20 public immutable borrowUnderlyingToken;
    // Borrow underlying token precision, e.g. 1e18
    uint256 public immutable borrowTokenPrecision;

    // Lend Currency ID the vault is configured with
    uint16 public immutable lendCurrencyId;
    // True if the lend underlying is ETH
    bool public immutable lendUnderlyingIsEth;
    // Address of the lend underlying token
    ERC20 public immutable lendUnderlyingToken;
    // Lend underlying token precision, e.g. 1e18
    uint256 public immutable lendTokenPrecision;

    // Name of the vault (cannot make string immutable)
    string public name;

    constructor(
        NotionalProxy _notional,
        ITradingModule _tradingModule,
        address _contango,
        bytes32 _contangoProxyHash,
        string memory _name,
        address _weth,
        uint16 _lendCurrencyId,
        uint16 _borrowCurrencyId
    ) {
        notional = _notional;
        tradingModule = _tradingModule;
        contango = _contango;
        contangoProxyHash = _contangoProxyHash;
        name = _name;

        (borrowCurrencyId, borrowUnderlyingIsEth, borrowUnderlyingToken, borrowTokenPrecision) =
            _currencyIdConfiguration(_borrowCurrencyId, _weth);
        (lendCurrencyId, lendUnderlyingIsEth, lendUnderlyingToken, lendTokenPrecision) =
            _currencyIdConfiguration(_lendCurrencyId, _weth);
    }

    function initialize() external initializer {
        __AccessControl_init_unchained();
        __UUPSUpgradeable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Allow Notional to pull the lend underlying currency
        lendUnderlyingToken.approve(address(notional), type(uint256).max);
    }

    // ============================================== IStrategyVault functions ==============================================

    /// @notice All strategy vaults MUST implement 8 decimal precision
    function decimals() public pure override returns (uint8) {
        return INTERNAL_TOKEN_DECIMALS;
    }

    function strategy() external pure override returns (bytes4) {
        return bytes4(keccak256("ContangoVault"));
    }

    /// @notice Converts the amount of fCash the vault holds into underlying denomination for the borrow currency.
    /// @param strategyTokens each strategy token is equivalent to 1 unit of fCash
    /// @param maturity the maturity of the fCash
    /// @return underlyingValue the value of the lent fCash in terms of the borrowed currency
    function convertStrategyToUnderlying(
        address, // account
        uint256 strategyTokens,
        uint256 maturity
    ) public view override returns (int256 underlyingValue) {
        int256 pvInternal;
        if (maturity <= block.timestamp) {
            // After maturity, strategy tokens no longer have a present value
            pvInternal = strategyTokens.toInt256();
        } else {
            // This is the non-risk adjusted oracle price for fCash, present value is used in case
            // liquidation is required. The liquidator may need to exit the fCash position in order
            // to repay a flash loan.
            pvInternal = notional.getPresentfCashValue(
                lendCurrencyId, maturity, strategyTokens.toInt256(), block.timestamp, false
            );
        }

        (int256 rate, int256 rateDecimals) =
            tradingModule.getOraclePrice(address(lendUnderlyingToken), address(borrowUnderlyingToken));

        // Convert this back to the borrow currency, external precision
        // (pv (8 decimals) * borrowTokenPrecision * rate) / (rateDecimals * 8 decimals)
        underlyingValue = (pvInternal * int256(borrowTokenPrecision) * rate)
            / (rateDecimals * int256(Constants.INTERNAL_TOKEN_PRECISION));
    }

    // TODO alfredo - natspec
    function depositFromNotional(
        address account,
        uint256 depositUnderlyingExternal,
        uint256 maturity,
        bytes calldata data
    ) external payable override onlyNotional returns (uint256 lentFCashAmount) {
        if (maturity <= block.timestamp) {
            revert NotImplemented("deposit after maturity");
        }

        // 4. Take lending underlying from the payer and lend to get fCash
        EnterParams memory params = abi.decode(data, (EnterParams));

        if (depositUnderlyingExternal < params.borrowAmount) {
            revert InsufficientBorrowedAmount(params.borrowAmount, depositUnderlyingExternal);
        }

        // TODO alfredo - the assumption is that the account is guaranteed to be the msg.sender that called notional initially
        _validateAccount(params.positionId, account);

        if (params.lendAmount > 0) {
            lendUnderlyingToken.safeTransferFrom(params.payer, address(this), params.lendAmount);
            if (lendUnderlyingIsEth) {
                WETH(payable(address(lendUnderlyingToken))).withdraw(params.lendAmount);
            }

            // should only have one portfolio for the lending currency (or none if first time entering)
            // and balance always positive since it's always lending
            (,, PortfolioAsset[] memory portfolio) = notional.getAccount(address(this));
            int256 balanceBefore = portfolio.length == 0 ? int256(0) : portfolio[0].notional;

            // Now we lend the underlying amount
            BalanceActionWithTrades[] memory lendAction = new BalanceActionWithTrades[](1);
            lendAction[0] = NotionalUtils.encodeOpenLendAction({
                currencyId: lendCurrencyId,
                marketIndex: notional.getMarketIndex(maturity, block.timestamp),
                depositActionAmount: params.lendAmount,
                fCashLendAmount: params.fCashLendAmount.toUint88()
            });
            uint256 sendValue = lendUnderlyingIsEth ? params.lendAmount : 0;
            notional.batchBalanceAndTradeAction{value: sendValue}(address(this), lendAction);

            (,, portfolio) = notional.getAccount(address(this));
            lentFCashAmount = uint256(portfolio[0].notional - balanceBefore);
        }

        // 5. Transfer borrowed underlying to the receiver
        if (borrowUnderlyingIsEth) {
            WETH(payable(address(borrowUnderlyingToken))).deposit{value: params.borrowAmount}();
        }
        borrowUnderlyingToken.safeTransfer(params.receiver, params.borrowAmount);
    }

    // TODO alfredo - natspec
    function redeemFromNotional(
        address account,
        address, // receiver,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) external override onlyNotional returns (uint256 transferToReceiver) {
        if (maturity > block.timestamp) {
            _redeemBeforeMaturity(account, strategyTokens, maturity, underlyingToRepayDebt, data);
        } else {
            _redeemAfterMaturity(account, strategyTokens, data);
        }

        // this is always 0 since we already transfer what we can/need on the steps above
        transferToReceiver = 0;
    }

    function _redeemBeforeMaturity(
        address account,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) private {
        ExitParams memory params = abi.decode(data, (ExitParams));

        // TODO alfredo - the assumption is that the account is guaranteed to be the msg.sender that called notional initially
        _validateAccount(params.positionId, account);

        // 4. Take borrowing underlying from the payer to pay for exiting the borrowing position
        if (!borrowUnderlyingIsEth) {
            borrowUnderlyingToken.safeTransferFrom(params.payer, address(notional), underlyingToRepayDebt);
        }

        if (strategyTokens > 0) {
            // 5. Borrow lending fCash to close lending position
            uint256 balanceBefore =
                lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));

            BalanceActionWithTrades[] memory closeLendingAction = new BalanceActionWithTrades[](1);
            closeLendingAction[0] = NotionalUtils.encodeCloseLendAction({
                currencyId: lendCurrencyId,
                marketIndex: notional.getMarketIndex(maturity, block.timestamp),
                fCashAmount: strategyTokens.toUint88()
            });
            notional.batchBalanceAndTradeAction(address(this), closeLendingAction);

            uint256 balanceAfter =
                lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));
            uint256 availableBalance = balanceAfter - balanceBefore;

            if (params.withdrawAmount > availableBalance) {
                revert InsufficientWithdrawAmount(params.withdrawAmount, availableBalance);
            }

            // 6. Transfer remaining lending underlying to the receiver
            if (lendUnderlyingIsEth) {
                WETH(payable(address(lendUnderlyingToken))).deposit{value: params.withdrawAmount}();
            }
            lendUnderlyingToken.safeTransfer(params.receiver, params.withdrawAmount);
        }
    }

    function _redeemAfterMaturity(address account, uint256 strategyTokens, bytes calldata data) private {
        // only vault can settle after maturity
        if (account != address(this)) {
            revert OnlyVault();
        }

        SettleParams memory params = abi.decode(data, (SettleParams));

        // take borrowing underlying from the payer to pay for exiting the full borrowing position
        if (borrowUnderlyingIsEth) {
            payable(address(notional)).safeTransferETH(params.repaymentAmount);
        } else {
            borrowUnderlyingToken.safeTransferFrom(params.payer, address(notional), params.repaymentAmount);
        }

        uint256 balanceBefore =
            lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));

        // withdraw proportional lending fCash to underlying
        (,,, AssetRateParameters memory ar) = notional.getCurrencyAndRates(lendCurrencyId);
        int256 withdrawAmount = strategyTokens.fromNotionalPrecision(lendTokenPrecision, false).toInt256();
        int256 ratePrecision = int256(10 ** ar.rateOracle.decimals());
        int256 withdrawAmountInternal = ((withdrawAmount * ratePrecision) / ar.rate) + 1; // buffer

        BalanceAction[] memory withdrawAction = new BalanceAction[](1);
        withdrawAction[0] = NotionalUtils.encodeWithdrawAction({
            currencyId: lendCurrencyId,
            withdrawAmountInternal: uint256(withdrawAmountInternal)
        });
        notional.batchBalanceAction(address(this), withdrawAction);

        uint256 balanceAfter =
            lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));
        uint256 availableBalance = balanceAfter - balanceBefore;

        if (params.withdrawAmount > availableBalance) {
            revert InsufficientWithdrawAmount(params.withdrawAmount, availableBalance);
        }

        // transfer received funds
        if (lendUnderlyingIsEth) {
            WETH(payable(address(lendUnderlyingToken))).deposit{value: params.withdrawAmount}();
        }
        lendUnderlyingToken.safeTransfer(params.receiver, params.withdrawAmount);
    }

    // TODO alfredo - natspec
    function settleAccount(address account, uint256 maturity, bytes calldata data) external payable onlyContango {
        if (maturity > block.timestamp) {
            revert CanNotSettleBeforeMaturity();
        }

        notional.redeemStrategyTokensToCash({
            maturity: maturity,
            strategyTokensToRedeem: notional.getVaultAccount(account, address(this)).vaultShares,
            vaultData: data
        });

        // If there are no more strategy tokens left, meaning all positions were delivered, then clean and fully settle the vault with Notional
        if (notional.getVaultState(address(this), maturity).totalStrategyTokens == 0) {
            // currency ids in ascending order
            (uint16 currencyId1, uint16 currencyId2) = borrowCurrencyId < lendCurrencyId
                ? (borrowCurrencyId, lendCurrencyId)
                : (lendCurrencyId, borrowCurrencyId);

            // withdraws any remaining balance (dust) on Notional
            BalanceAction[] memory withdrawalsAction = new BalanceAction[](2);
            withdrawalsAction[0] = NotionalUtils.encodeWithdrawAllAction(currencyId1);
            withdrawalsAction[1] = NotionalUtils.encodeWithdrawAllAction(currencyId2);
            notional.batchBalanceAction(address(this), withdrawalsAction);

            // fully settle vault
            notional.settleVault(address(this), maturity);
        }
    }

    function repaySecondaryBorrowCallback(
        address, // token,
        uint256, // underlyingRequired,
        bytes calldata // data
    ) external pure override returns (bytes memory) {
        revert Unsupported();
    }

    // ============================================== Admin functions ==============================================

    function collectBalance(address token, address payable to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _collectBalance(token, to, amount);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @notice reverts on fallback for informational purposes
    fallback() external payable {
        revert FunctionNotFound(msg.sig);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        // Allow ETH transfers to succeed
    }

    // ============================================== Private functions ==============================================

    function _currencyIdConfiguration(uint16 currencyId, address weth)
        private
        view
        returns (uint16 currencyId_, bool underlyingIsEth_, ERC20 underlyingToken_, uint256 tokenPrecision_)
    {
        currencyId_ = currencyId;
        address underlying = _getNotionalUnderlyingToken(currencyId);
        underlyingIsEth_ = underlying == address(0);
        underlyingToken_ = ERC20(underlyingIsEth_ ? weth : underlying);
        tokenPrecision_ = 10 ** underlyingToken_.decimals();
    }

    function _getNotionalUnderlyingToken(uint16 currencyId) private view returns (address) {
        (Token memory assetToken, Token memory underlyingToken) = notional.getCurrency(currencyId);

        return assetToken.tokenType == TokenType.NonMintable ? assetToken.tokenAddress : underlyingToken.tokenAddress;
    }

    function _validateAccount(PositionId positionId, address proxy) private view {
        address expectedProxy = positionId.computeProxyAddress(contango, contangoProxyHash);

        if (proxy != expectedProxy) {
            revert InvalidContangoProxy(expectedProxy, proxy);
        }
    }

    modifier onlyContango() {
        if (msg.sender != contango) {
            revert OnlyContango();
        }
        _;
    }

    modifier onlyNotional() {
        if (msg.sender != address(notional)) {
            revert OnlyNotional();
        }
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./internal/Constants.sol";
import "./internal/Types.sol";
import "./internal/interfaces/NotionalProxy.sol";

import "../../libraries/DataTypes.sol";
import "../../libraries/ErrorLib.sol";
import "../../libraries/MathLib.sol";
import "../../libraries/StorageLib.sol";

import "./ContangoVault.sol";

library NotionalUtils {
    using MathLib for uint256;
    using NotionalUtils for uint256;
    using SafeCast for uint256;

    uint256 private constant NOTIONAL_PRECISION = uint256(Constants.INTERNAL_TOKEN_PRECISION);

    function loadInstrument(Symbol symbol)
        internal
        view
        returns (Instrument storage instrument, NotionalInstrument storage notionalInstrument, ContangoVault vault)
    {
        instrument = StorageLib.getInstruments()[symbol];
        if (instrument.maturity == 0) {
            revert InvalidInstrument(symbol);
        }
        notionalInstrument = NotionalStorageLib.getInstruments()[symbol];
        vault = NotionalStorageLib.getVaults()[symbol];
    }

    function quoteLendOpenCost(
        NotionalProxy notional,
        uint256 fCashAmount,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint256 deposit) {
        (deposit,,,) = notional.getDepositFromfCashLend({
            currencyId: notionalInstrument.baseId,
            fCashAmount: fCashAmount + 1, // buffer lending open to go around dust issue when physically delivering
            maturity: instrument.maturity,
            minLendRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteLendClose(
        NotionalProxy notional,
        uint256 fCashAmount,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint256 principal) {
        (principal,,,) = notional.getPrincipalFromfCashBorrow({
            currencyId: notionalInstrument.baseId,
            fCashBorrow: fCashAmount,
            maturity: instrument.maturity,
            maxBorrowRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteBorrowOpenCost(
        NotionalProxy notional,
        uint256 borrow,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint88 fCashAmount) {
        (fCashAmount,,) = notional.getfCashBorrowFromPrincipal({
            currencyId: notionalInstrument.quoteId,
            borrowedAmountExternal: borrow,
            maturity: instrument.maturity,
            maxBorrowRate: 0, // no limit
            blockTime: block.timestamp, // solhint-disable-line not-rely-on-time
            useUnderlying: true
        });
        // Empirically it appears that the fCash to cash exchange rate is at most 0.01 basis points (0.0001 percent)
        // amount input into the function. This is likely due to rounding errors in calculations. What you can do to
        // buffer these values is to increase the size by x += (x * 100) / 1e9 -> equivalent to x += x / 1e7
        fCashAmount += fCashAmount >= 1e7 ? fCashAmount / 1e7 : 1;
    }

    function quoteBorrowOpen(
        NotionalProxy notional,
        uint256 fCashAmount,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint256 principal) {
        (principal,,,) = notional.getPrincipalFromfCashBorrow({
            currencyId: notionalInstrument.quoteId,
            fCashBorrow: fCashAmount,
            maturity: instrument.maturity,
            maxBorrowRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteBorrowCloseCost(
        NotionalProxy notional,
        uint256 fCashAmount,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint256 deposit) {
        (deposit,,,) = notional.getDepositFromfCashLend({
            currencyId: notionalInstrument.quoteId,
            fCashAmount: fCashAmount,
            maturity: instrument.maturity,
            minLendRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteBorrowClose(
        NotionalProxy notional,
        uint256 deposit,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint256 fCashAmount) {
        (fCashAmount,,) = notional.getfCashLendFromDeposit({
            currencyId: notionalInstrument.quoteId,
            depositAmountExternal: deposit,
            maturity: instrument.maturity,
            minLendRate: 0, // no limit
            blockTime: block.timestamp, // solhint-disable-line not-rely-on-time
            useUnderlying: true
        });
    }

    function toNotionalPrecision(uint256 value, uint256 fromPrecision, bool roundCeiling)
        internal
        pure
        returns (uint256)
    {
        return value.scale(fromPrecision, NOTIONAL_PRECISION, roundCeiling);
    }

    function fromNotionalPrecision(uint256 value, uint256 toPrecision, bool roundCeiling)
        internal
        pure
        returns (uint256)
    {
        return value.scale(NOTIONAL_PRECISION, toPrecision, roundCeiling);
    }

    function buffer(uint256 value, uint256 precision) internal pure returns (uint256) {
        if (value == 0) {
            return 0;
        }
        return value + (precision > NOTIONAL_PRECISION ? precision / NOTIONAL_PRECISION : 1);
    }

    function roundFloorNotionalPrecision(uint256 value, uint256 precision) internal pure returns (uint256 rounded) {
        if (precision > NOTIONAL_PRECISION) {
            rounded = value.toNotionalPrecision(precision, false).fromNotionalPrecision(precision, false);
        } else {
            rounded = value;
        }
    }

    function encodeOpenLendAction(
        uint16 currencyId,
        uint8 marketIndex,
        uint256 depositActionAmount,
        uint88 fCashLendAmount
    ) internal pure returns (BalanceActionWithTrades memory action) {
        action.currencyId = currencyId;
        action.actionType = DepositActionType.DepositUnderlying;
        action.depositActionAmount = depositActionAmount;
        action.trades = new bytes32[](1);
        action.trades[0] = bytes32(abi.encodePacked(uint8(TradeActionType.Lend), marketIndex, fCashLendAmount));
    }

    function encodeCloseLendAction(uint16 currencyId, uint8 marketIndex, uint88 fCashAmount)
        internal
        pure
        returns (BalanceActionWithTrades memory action)
    {
        action.currencyId = currencyId;
        action.actionType = DepositActionType.None;
        action.withdrawEntireCashBalance = true;
        action.redeemToUnderlying = true;
        action.trades = new bytes32[](1);
        action.trades[0] = bytes32(abi.encodePacked(uint8(TradeActionType.Borrow), marketIndex, fCashAmount));
    }

    function encodeWithdrawAction(uint16 currencyId, uint256 withdrawAmountInternal)
        internal
        pure
        returns (BalanceAction memory action)
    {
        action.currencyId = currencyId;
        action.actionType = DepositActionType.None;
        action.withdrawAmountInternalPrecision = withdrawAmountInternal;
        action.redeemToUnderlying = true;
    }

    function encodeWithdrawAllAction(uint16 currencyId) internal pure returns (BalanceAction memory action) {
        action.currencyId = currencyId;
        action.actionType = DepositActionType.None;
        action.withdrawEntireCashBalance = true;
        action.redeemToUnderlying = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./AssetRateAdapter.sol";

/// @dev only necessary types from https://github.com/notional-finance/contracts-v2/blob/master/contracts/global/Types.sol

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
///  - aToken: Aave interest bearing tokens
enum TokenType {
    UnderlyingToken,
    cToken,
    cETH,
    Ether,
    NonMintable,
    aToken
}

/// @notice Specifies the different trade action types in the system. Each trade action type is
/// encoded in a tightly packed bytes32 object. Trade action type is the first big endian byte of the
/// 32 byte trade action object. The schemas for each trade action type are defined below.
enum TradeActionType
// (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
{
    Lend,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
    Borrow,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 assetCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    AddLiquidity,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    RemoveLiquidity,
    // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
    PurchaseNTokenResidual,
    // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
    SettleCashDebt
}

/// @notice Specifies different deposit actions that can occur during BalanceAction or BalanceActionWithTrades
enum DepositActionType
// No deposit action
{
    None,
    // Deposit asset cash, depositActionAmount is specified in asset cash external precision
    DepositAsset,
    // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
    // external precision
    DepositUnderlying,
    // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
    // nTokens into the account
    DepositAssetAndMintNToken,
    // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
    DepositUnderlyingAndMintNToken,
    // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
    // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
    RedeemNToken,
    // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
    // Notional internal 8 decimal precision.
    ConvertCashToNToken
}

/// @notice Used internally for PortfolioHandler state
enum AssetStorageState {
    NoChange,
    Update,
    Delete,
    RevertIfStored
}

/// @notice Defines a balance action for batchAction
struct BalanceAction {
    // Deposit action to take (if any)
    DepositActionType actionType;
    uint16 currencyId;
    // Deposit action amount must correspond to the depositActionType, see documentation above.
    uint256 depositActionAmount;
    // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
    uint256 withdrawAmountInternalPrecision;
    // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
    // residual left from trading.
    bool withdrawEntireCashBalance;
    // If set to true, will redeem asset cash to the underlying token on withdraw.
    bool redeemToUnderlying;
}

/// @notice Defines a balance action with a set of trades to do as well
struct BalanceActionWithTrades {
    DepositActionType actionType;
    uint16 currencyId;
    uint256 depositActionAmount;
    uint256 withdrawAmountInternalPrecision;
    bool withdrawEntireCashBalance;
    bool redeemToUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 maxCollateralBalance;
}

/// @notice In memory ETH exchange rate used during free collateral calculation.
struct ETHRate {
    // The decimals (i.e. 10^rateDecimalPlaces) of the exchange rate, defined by the rate oracle
    int256 rateDecimals;
    // The exchange rate from base to ETH (if rate invert is required it is already done)
    int256 rate;
    // Amount of buffer as a multiple with a basis of 100 applied to negative balances.
    int256 buffer;
    // Amount of haircut as a multiple with a basis of 100 applied to positive balances
    int256 haircut;
    // Liquidation discount as a multiple with a basis of 100 applied to the exchange rate
    // as an incentive given to liquidators.
    int256 liquidationDiscount;
}

/// @dev Asset rate used to convert between underlying cash and asset cash
struct AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals;
}

/// @dev A portfolio asset when loaded in memory
struct PortfolioAsset {
    // Asset currency id
    uint256 currencyId;
    uint256 maturity;
    // Asset type, fCash or liquidity token.
    uint256 assetType;
    // fCash amount or liquidity token amount
    int256 notional;
    // Used for managing portfolio asset state
    uint256 storageSlot;
    // The state of the asset for when it is written to storage
    AssetStorageState storageState;
}

/// @dev Market object as represented in memory
struct MarketParameters {
    bytes32 storageSlot;
    uint256 maturity;
    // Total amount of fCash available for purchase in the market.
    int256 totalfCash;
    // Total amount of cash available for purchase in the market.
    int256 totalAssetCash;
    // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
    int256 totalLiquidity;
    // This is the previous annualized interest rate in RATE_PRECISION that the market traded
    // at. This is used to calculate the rate anchor to smooth interest rates over time.
    uint256 lastImpliedRate;
    // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
    // remaining resistent to flash loan attacks.
    uint256 oracleRate;
    // This is the timestamp of the previous trade
    uint256 previousTradeTime;
}

/// @dev Holds account level context information used to determine settlement and
/// free collateral actions. Total storage is 28 bytes
struct AccountContext {
    // Used to check when settlement must be triggered on an account
    uint40 nextSettleTime;
    // For lenders that never incur debt, we use this flag to skip the free collateral check.
    bytes1 hasDebt;
    // Length of the account's asset array
    uint8 assetArrayLength;
    // If this account has bitmaps set, this is the corresponding currency id
    uint16 bitmapCurrencyId;
    // 9 total active currencies possible (2 bytes each)
    bytes18 activeCurrencies;
}

/// @dev Used in view methods to return account balances in a developer friendly manner
struct AccountBalance {
    uint16 currencyId;
    int256 cashBalance;
    int256 nTokenBalance;
    uint256 lastClaimTime;
    uint256 accountIncentiveDebt;
}

struct VaultConfig {
    address vault;
    uint16 flags;
    uint16 borrowCurrencyId;
    int256 minAccountBorrowSize;
    int256 feeRate;
    int256 minCollateralRatio;
    int256 liquidationRate;
    int256 reserveFeeShare;
    uint256 maxBorrowMarketIndex;
    int256 maxDeleverageCollateralRatio;
    uint16[2] secondaryBorrowCurrencies;
    AssetRateParameters assetRate;
    int256 maxRequiredAccountCollateralRatio;
}

struct VaultAccount {
    int256 fCash;
    uint256 maturity;
    uint256 vaultShares;
    address account;
    // This cash balance is used just within a transaction to track deposits
    // and withdraws for an account. Must be zeroed by the time we store the account
    int256 tempCashBalance;
    uint256 lastEntryBlockHeight;
}

struct VaultState {
    uint256 maturity;
    int256 totalfCash;
    bool isSettled;
    uint256 totalVaultShares;
    uint256 totalAssetCash;
    uint256 totalStrategyTokens;
    int256 settlementStrategyTokenValue;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "../Types.sol";

/// @dev only necessary function from https://github.com/notional-finance/contracts-v2/blob/master/interfaces/notional/NotionalProxy.sol
interface NotionalProxy {
    // TODO alfredo - move to TestNotionalProxy once TradingModule is deployed on mainnet
    function owner() external view returns (address);

    function batchBalanceAction(address account, BalanceAction[] calldata actions) external payable;

    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions) external payable;

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view returns (int256 presentValue);

    function getMarketIndex(uint256 maturity, uint256 blockTime) external pure returns (uint8 marketIndex);

    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (uint88 fCashAmount, uint8 marketIndex, bytes32 encodedTrade);

    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (uint88 fCashDebt, uint8 marketIndex, bytes32 encodedTrade);

    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    )
        external
        view
        returns (uint256 depositAmountUnderlying, uint256 depositAmountAsset, uint8 marketIndex, bytes32 encodedTrade);

    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    )
        external
        view
        returns (uint256 borrowAmountUnderlying, uint256 borrowAmountAsset, uint8 marketIndex, bytes32 encodedTrade);

    function getCurrency(uint16 currencyId)
        external
        view
        returns (Token memory assetToken, Token memory underlyingToken);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    function getCurrencyAndRates(uint16 currencyId)
        external
        view
        returns (
            Token memory assetToken,
            Token memory underlyingToken,
            ETHRate memory ethRate,
            AssetRateParameters memory assetRate
        );

    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        );

    function enterVault(
        address account,
        address vault,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint256 fCash,
        uint32 maxBorrowRate,
        bytes calldata vaultData
    ) external payable returns (uint256 strategyTokensAdded);

    function exitVault(
        address account,
        address vault,
        address receiver,
        uint256 vaultSharesToRedeem,
        uint256 fCashToLend,
        uint32 minLendRate,
        bytes calldata exitVaultData
    ) external payable returns (uint256 underlyingToReceiver);

    function getVaultAccount(address account, address vault) external view returns (VaultAccount memory);

    function getVaultConfig(address vault) external view returns (VaultConfig memory vaultConfig);

    function settleVault(address vault, uint256 maturity) external;

    function getVaultState(address vault, uint256 maturity) external view returns (VaultState memory vaultState);

    function redeemStrategyTokensToCash(uint256 maturity, uint256 strategyTokensToRedeem, bytes calldata vaultData)
        external
        returns (int256 assetCashRequiredToSettle, int256 underlyingCashRequiredToSettle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IJoin.sol";
import "./ICauldron.sol";

interface ILadle {
    function joins(bytes6) external view returns (IJoin);

    function pools(bytes6) external view returns (address);

    function cauldron() external view returns (ICauldron);

    function build(
        bytes6 seriesId,
        bytes6 ilkId,
        uint8 salt
    ) external returns (bytes12 vaultId, DataTypes.Vault memory vault);

    function destroy(bytes12 vaultId) external;

    function pour(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external payable;

    function serve(
        bytes12 vaultId,
        address to,
        uint128 ink,
        uint128 base,
        uint128 max
    ) external payable returns (uint128 art);

    function close(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataTypes.sol";

library ProxyLib {
    /// Computes proxy address following EIP-1014 https://eips.ethereum.org/EIPS/eip-1014#specification
    /// @param positionId Position id used for the salt
    /// @param creator Address that created the proxy
    /// @param proxyHash Proxy bytecode hash
    /// @return computed proxy address
    function computeProxyAddress(PositionId positionId, address creator, bytes32 proxyHash)
        internal
        pure
        returns (address payable)
    {
        return payable(address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", creator, positionId, proxyHash))))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/// @dev https://github.com/notional-finance/leveraged-vaults/blob/master/interfaces/trading/ITradingModule.sol
interface ITradingModule {
    event PriceOracleUpdated(address token, address oracle);
    event MaxOracleFreshnessUpdated(uint32 currentValue, uint32 newValue);

    function setPriceOracle(address token, AggregatorV2V3Interface oracle) external;
    function getOraclePrice(address inToken, address outToken) external view returns (int256 answer, int256 decimals);
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.17;

/// @dev https://github.com/notional-finance/contracts-v2/blob/master/interfaces/notional/IStrategyVault.sol

interface IStrategyVault {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function strategy() external view returns (bytes4 strategyId);

    // Tells a vault to deposit some amount of tokens from Notional and mint strategy tokens with it.
    function depositFromNotional(address account, uint256 depositAmount, uint256 maturity, bytes calldata data)
        external
        payable
        returns (uint256 strategyTokensMinted);

    // Tells a vault to redeem some amount of strategy tokens from Notional and transfer the resulting asset cash
    function redeemFromNotional(
        address account,
        address receiver,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) external returns (uint256 transferToReceiver);

    function convertStrategyToUnderlying(address account, uint256 strategyTokens, uint256 maturity)
        external
        view
        returns (int256 underlyingValue);

    function repaySecondaryBorrowCallback(address token, uint256 underlyingRequired, bytes calldata data)
        external
        returns (bytes memory returnData);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/// @dev only necessary constants from https://github.com/notional-finance/contracts-v2/blob/master/contracts/global/Constants.sol
library Constants {
    // Token precision used for all internal balances, TokenHandler library ensures that we
    // limit the dust amount caused by precision mismatches
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    // Number of decimal places that rates are stored in, equals 100%
    int256 internal constant RATE_PRECISION = 1e9;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "solmate/src/utils/SafeTransferLib.sol";

library TransferLib {
    using SafeTransferLib for ERC20;

    error ZeroAddress(address payer, address to);

    function transferOut(ERC20 token, address payer, address to, uint256 amount) internal returns (uint256) {
        if (payer == address(0) || to == address(0)) {
            revert ZeroAddress(payer, to);
        }

        // If we are the payer, it's because the funds where transferred first or it was WETH wrapping
        payer == address(this) ? token.safeTransfer(to, amount) : token.safeTransferFrom(payer, to, amount);

        return amount;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

library MathLib {
    function scale(uint256 value, uint256 fromPrecision, uint256 toPrecision, bool roundCeiling)
        internal
        pure
        returns (uint256 scaled)
    {
        if (fromPrecision > toPrecision) {
            uint256 adjustment = fromPrecision / toPrecision;
            scaled = roundCeiling ? Math.ceilDiv(value, adjustment) : value / adjustment;
        } else if (fromPrecision < toPrecision) {
            scaled = value * (toPrecision / fromPrecision);
        } else {
            scaled = value;
        }
    }
}

// SPDX-License-Identifier: GPL-v3
pragma solidity 0.8.17;

/// @dev https://github.com/notional-finance/contracts-v2/blob/master/interfaces/notional/AssetRateAdapter.sol

/// @notice Used as a wrapper for tokens that are interest bearing for an
/// underlying token. Follows the cToken interface, however, can be adapted
/// for other interest bearing tokens.
interface AssetRateAdapter {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function underlying() external view returns (address);

    function getExchangeRateStateful() external returns (int256);

    function getExchangeRateView() external view returns (int256);

    function getAnnualizedSupplyRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

import "./interfaces/IFeeModel.sol";
import "./libraries/CodecLib.sol";
import "./libraries/StorageLib.sol";
import "./libraries/TransferLib.sol";

/// @dev This set of methods process the result of an execution, update the internal accounting and transfer funds if required
library ExecutionProcessorLib {
    using SafeCast for uint256;
    using Math for uint256;
    using SignedMath for int256;
    using TransferLib for ERC20;
    using CodecLib for uint256;

    event PositionUpserted(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        uint256 totalFees,
        uint256 txFees,
        int256 realisedPnL
    );

    event PositionLiquidated(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        int256 realisedPnL
    );

    event PositionClosed(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 closedQuantity,
        uint256 closedCost,
        int256 collateral,
        uint256 totalFees,
        uint256 txFees,
        int256 realisedPnL
    );

    event PositionDelivered(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        address to,
        uint256 deliveredQuantity,
        uint256 deliveryCost,
        uint256 totalFees
    );

    error Undercollateralised(PositionId positionId);
    error PositionIsTooSmall(uint256 openCost, uint256 minCost);

    uint256 public constant MIN_DEBT_MULTIPLIER = 5;

    function deliverPosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 deliverableQuantity,
        uint256 deliveryCost,
        address payer,
        ERC20 quoteToken,
        address to
    ) internal {
        delete StorageLib.getPositionNotionals()[positionId];

        mapping(PositionId => uint256) storage balances = StorageLib.getPositionBalances();
        (, uint256 protocolFees) = balances[positionId].decodeU128();
        delete balances[positionId];

        if (protocolFees > 0) {
            quoteToken.transferOut(payer, ConfigStorageLib.getTreasury(), protocolFees);
        }

        emit PositionDelivered(symbol, trader, positionId, to, deliverableQuantity, deliveryCost, protocolFees);
    }

    function updateCollateral(Symbol symbol, PositionId positionId, address trader, int256 cost, int256 amount)
        internal
    {
        (uint256 openQuantity, uint256 openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        (int256 collateral, uint256 protocolFees, uint256 fee) =
            _applyFees(trader, symbol, positionId, cost.abs() + amount.abs());

        openCost = uint256(int256(openCost) + cost);
        collateral = collateral + amount;

        _updatePosition(symbol, positionId, trader, openQuantity, openCost, collateral, protocolFees, fee, 0);
    }

    function increasePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 size,
        uint256 cost,
        int256 collateralDelta,
        ERC20 quoteToken,
        address to,
        uint256 minCost
    ) internal {
        (uint256 openQuantity, uint256 openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        int256 positionCollateral;
        uint256 protocolFees;
        uint256 fee;

        // For a new position
        if (openQuantity == 0) {
            fee = _fee(trader, symbol, positionId, cost);
            positionCollateral = collateralDelta - int256(fee);
            protocolFees = fee;
        } else {
            (positionCollateral, protocolFees, fee) = _applyFees(trader, symbol, positionId, cost);
            positionCollateral = positionCollateral + collateralDelta;

            // When increasing positions, the user can request to withdraw part (or all) the free collateral
            if (collateralDelta < 0 && address(this) != to) {
                quoteToken.transferOut(address(this), to, uint256(-collateralDelta));
            }
        }

        openCost = openCost + cost;
        _validateMinCost(openCost, minCost);
        openQuantity = openQuantity + size;

        _updatePosition(symbol, positionId, trader, openQuantity, openCost, positionCollateral, protocolFees, fee, 0);
    }

    function decreasePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 size,
        uint256 cost,
        int256 collateralDelta,
        ERC20 quoteToken,
        address to,
        uint256 minCost
    ) internal {
        (uint256 openQuantity, uint256 openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        (int256 collateral, uint256 protocolFees, uint256 fee) = _applyFees(trader, symbol, positionId, cost);

        int256 pnl;
        {
            // Proportion of the openCost based on the size of the fill respective of the overall position size
            uint256 closedCost = (size * openCost).ceilDiv(openQuantity);
            pnl = int256(cost) - int256(closedCost);
            openCost = openCost - closedCost;
            _validateMinCost(openCost, minCost);
            openQuantity = openQuantity - size;

            // Crystallised PnL is accounted on the collateral
            collateral = collateral + pnl + collateralDelta;
        }

        // When decreasing positions, the user can request to withdraw part (or all) the proceedings
        if (collateralDelta < 0 && address(this) != to) {
            quoteToken.transferOut(address(this), to, uint256(-collateralDelta));
        }

        _updatePosition(symbol, positionId, trader, openQuantity, openCost, collateral, protocolFees, fee, pnl);
    }

    function closePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 cost,
        ERC20 quoteToken,
        address to
    ) internal {
        mapping(PositionId => uint256) storage notionals = StorageLib.getPositionNotionals();
        (uint256 openQuantity, uint256 openCost) = notionals[positionId].decodeU128();
        (int256 collateral, uint256 protocolFees, uint256 fee) = _applyFees(trader, symbol, positionId, cost);

        int256 pnl = int256(cost) - int256(openCost);

        // Crystallised PnL is accounted on the collateral
        collateral = collateral + pnl;

        delete notionals[positionId];
        delete StorageLib.getPositionBalances()[positionId];

        if (protocolFees > 0) {
            quoteToken.transferOut(address(this), ConfigStorageLib.getTreasury(), protocolFees);
        }
        if (collateral > 0 && to != address(this)) {
            quoteToken.transferOut(address(this), to, uint256(collateral));
        }

        emit PositionClosed(symbol, trader, positionId, openQuantity, openCost, collateral, protocolFees, fee, pnl);
    }

    function liquidatePosition(Symbol symbol, PositionId positionId, address trader, uint256 size, uint256 cost)
        internal
    {
        mapping(PositionId => uint256) storage notionals = StorageLib.getPositionNotionals();
        mapping(PositionId => uint256) storage balances = StorageLib.getPositionBalances();
        (uint256 openQuantity, uint256 openCost) = notionals[positionId].decodeU128();
        (int256 collateral, int256 protocolFees) = balances[positionId].decodeI128();

        // Proportion of the openCost based on the size of the fill respective of the overall position size
        uint256 closedCost = size == openQuantity ? openCost : (size * openCost).ceilDiv(openQuantity);
        int256 pnl = int256(cost) - int256(closedCost);
        openCost = openCost - closedCost;
        openQuantity = openQuantity - size;

        // Crystallised PnL is accounted on the collateral
        collateral = collateral + pnl;

        notionals[positionId] = CodecLib.encodeU128(openQuantity, openCost);
        balances[positionId] = CodecLib.encodeI128(collateral, protocolFees);
        emit PositionLiquidated(symbol, trader, positionId, openQuantity, openCost, collateral, pnl);
    }

    // ============= Private functions ================

    function _applyFees(address trader, Symbol symbol, PositionId positionId, uint256 cost)
        private
        view
        returns (int256 collateral, uint256 protocolFees, uint256 fee)
    {
        int256 iProtocolFees;
        (collateral, iProtocolFees) = StorageLib.getPositionBalances()[positionId].decodeI128();
        protocolFees = uint256(iProtocolFees);
        fee = _fee(trader, symbol, positionId, cost);
        if (fee > 0) {
            collateral = collateral - int256(fee);
            protocolFees = protocolFees + fee;
        }
    }

    function _fee(address trader, Symbol symbol, PositionId positionId, uint256 cost) private view returns (uint256) {
        IFeeModel feeModel = StorageLib.getInstrumentFeeModel()[symbol];
        return address(feeModel) != address(0) ? feeModel.calculateFee(trader, positionId, cost) : 0;
    }

    function _updatePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        uint256 protocolFees,
        uint256 fee,
        int256 pnl
    ) private {
        StorageLib.getPositionNotionals()[positionId] = CodecLib.encodeU128(openQuantity, openCost);
        StorageLib.getPositionBalances()[positionId] = CodecLib.encodeI128(collateral, int256(protocolFees));
        emit PositionUpserted(symbol, trader, positionId, openQuantity, openCost, collateral, protocolFees, fee, pnl);
    }

    function _validateMinCost(uint256 openCost, uint256 minCost) private pure {
        if (openCost < minCost * MIN_DEBT_MULTIPLIER) {
            revert PositionIsTooSmall(openCost, minCost * MIN_DEBT_MULTIPLIER);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../libraries/DataTypes.sol";
import "../dependencies/Uniswap.sol";

library UniswapV3Handler {
    using SignedMath for int256;
    using PoolAddress for address;

    error InvalidCallbackCaller(address caller);

    error InsufficientHedgeAmount(uint256 hedgeSize, uint256 swapAmount);

    error InvalidAmountDeltas(int256 amount0Delta, int256 amount1Delta);

    struct Callback {
        CallbackInfo info;
        Instrument instrument;
        Fill fill;
    }

    struct CallbackInfo {
        Symbol symbol;
        PositionId positionId;
        address trader;
        uint256 limitCost;
        address payerOrReceiver;
        bool open;
        uint256 lendingLiquidity;
    }

    address internal constant UNISWAP_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    /// @notice Executes a flash swap on Uni V3, to buy/sell the hedgeSize
    /// @param callback Info collected before the flash swap started
    /// @param instrument The instrument being swapped
    /// @param baseForQuote True if base if being sold
    /// @param to The address to receive the output of the swap
    function flashSwap(Callback memory callback, Instrument memory instrument, bool baseForQuote, address to)
        internal
    {
        callback.instrument = instrument;

        (address tokenIn, address tokenOut) = baseForQuote
            ? (address(instrument.base), address(instrument.quote))
            : (address(instrument.quote), address(instrument.base));

        bool zeroForOne = tokenIn < tokenOut;
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(tokenIn, tokenOut, instrument.uniswapFeeTransient);

        IUniswapV3Pool(UNISWAP_FACTORY.computeAddress(poolKey)).swap({
            recipient: to,
            zeroForOne: zeroForOne,
            amountSpecified: baseForQuote ? int256(callback.fill.hedgeSize) : -int256(callback.fill.hedgeSize),
            sqrtPriceLimitX96: (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
            data: abi.encode(callback)
        });
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data,
        function(UniswapV3Handler.Callback memory) internal onUniswapCallback
    ) internal {
        if (amount0Delta < 0 && amount1Delta < 0 || amount0Delta > 0 && amount1Delta > 0) {
            revert InvalidAmountDeltas(amount0Delta, amount1Delta);
        }

        Callback memory callback = abi.decode(data, (Callback));
        Instrument memory instrument = callback.instrument;
        PoolAddress.PoolKey memory poolKey =
            PoolAddress.getPoolKey(address(instrument.base), address(instrument.quote), instrument.uniswapFeeTransient);

        if (msg.sender != UNISWAP_FACTORY.computeAddress(poolKey)) {
            revert InvalidCallbackCaller(msg.sender);
        }

        bool amount0isBase = instrument.base < instrument.quote;
        uint256 swapAmount = (amount0isBase ? amount0Delta : amount1Delta).abs();

        if (callback.fill.hedgeSize != swapAmount) {
            revert InsufficientHedgeAmount(callback.fill.hedgeSize, swapAmount);
        }

        callback.fill.hedgeCost = (amount0isBase ? amount1Delta : amount0Delta).abs();
        onUniswapCallback(callback);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./CodecLib.sol";
import "./DataTypes.sol";
import "./ErrorLib.sol";
import "./StorageLib.sol";

library PositionLib {
    using CodecLib for uint256;

    function positionOwner(PositionId positionId) internal view returns (address trader) {
        trader = ConfigStorageLib.getPositionNFT().positionOwner(positionId);
        if (msg.sender != trader) {
            revert NotPositionOwner(positionId, msg.sender, trader);
        }
    }

    function validatePosition(PositionId positionId) internal view returns (uint256 openQuantity) {
        (openQuantity,) = StorageLib.getPositionNotionals()[positionId].decodeU128();

        // Position was fully liquidated
        if (openQuantity == 0) {
            (int256 collateral,) = StorageLib.getPositionBalances()[positionId].decodeI128();
            // Negative collateral means there's nothing left for the trader to get
            if (0 > collateral) {
                revert InvalidPosition(positionId);
            }
        }
    }

    function validateExpiredPosition(PositionId positionId)
        internal
        view
        returns (uint256 openQuantity, Symbol symbol, Instrument memory instrument)
    {
        openQuantity = validatePosition(positionId);
        (symbol, instrument) = StorageLib.getInstrument(positionId);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrument.maturity > timestamp) {
            revert PositionActive(positionId, instrument.maturity, timestamp);
        }
    }

    function validateActivePosition(PositionId positionId, uint24 uniswapFee)
        internal
        view
        returns (uint256 openQuantity, Symbol symbol, Instrument memory instrument)
    {
        openQuantity = validatePosition(positionId);
        (symbol, instrument) = StorageLib.getInstrument(positionId);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrument.maturity <= timestamp) {
            revert PositionExpired(positionId, instrument.maturity, timestamp);
        }
        instrument.uniswapFeeTransient = uniswapFee;
    }

    function loadActivePosition(PositionId positionId, uint24 uniswapFee)
        internal
        view
        returns (uint256 openQuantity, address owner, Symbol symbol, Instrument memory instrument)
    {
        owner = positionOwner(positionId);
        (openQuantity, symbol, instrument) = validateActivePosition(positionId, uniswapFee);
    }

    function validatePayer(PositionId positionId, address payer, address trader) internal view {
        if (payer != trader && payer != address(this) && payer != msg.sender) {
            revert InvalidPayer(positionId, payer);
        }
    }

    function deletePosition(PositionId positionId) internal {
        StorageLib.getPositionInstrument()[positionId] = Symbol.wrap("");
        ConfigStorageLib.getPositionNFT().burn(positionId);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library SlippageLib {
    error CostAboveTolerance(uint256 limitCost, uint256 actualCost);
    error CostBelowTolerance(uint256 limitCost, uint256 actualCost);

    function requireCostAboveTolerance(uint256 cost, uint256 limitCost) internal pure {
        if (cost < limitCost) revert CostBelowTolerance(limitCost, cost);
    }

    function requireCostBelowTolerance(uint256 cost, uint256 limitCost) internal pure {
        if (cost > limitCost) revert CostAboveTolerance(limitCost, cost);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @dev strip down version of https://github.com/Uniswap/v3-core/blob/864efb5bb57bd8bde4689cfd8f7fd7ddeb100524/contracts/libraries/TickMath.sol
/// the published version doesn't compile on solidity 0.8.x
library TickMath {
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
}

/// @dev taken from https://github.com/Uniswap/v3-periphery/blob/090e908ba7d8006a616d41c8951aed26a8c3dd1c/contracts/libraries/PoolAddress.sol
/// added casting to uint160 on L49 to make it compile for solidity 0.8.x
/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1, "Invalid PoolKey");
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}