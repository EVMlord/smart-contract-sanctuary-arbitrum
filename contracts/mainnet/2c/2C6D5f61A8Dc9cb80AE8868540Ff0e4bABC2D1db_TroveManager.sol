// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Interfaces/ITroveManager.sol";
import "./Dependencies/VestaBase.sol";
import "./Dependencies/CheckContract.sol";

contract TroveManager is VestaBase, CheckContract, ITroveManager {
	using SafeMathUpgradeable for uint256;
	string public constant NAME = "TroveManager";

	// --- Connected contract declarations ---

	address public borrowerOperationsAddress;

	IStabilityPoolManager public stabilityPoolManager;

	address gasPoolAddress;

	ICollSurplusPool collSurplusPool;

	IVSTToken public override vstToken;

	IVSTAStaking public override vstaStaking;

	// A doubly linked list of Troves, sorted by their sorted by their collateral ratios
	ISortedTroves public sortedTroves;

	// --- Data structures ---

	uint256 public constant SECONDS_IN_ONE_MINUTE = 60;
	/*
	 * Half-life of 12h. 12h = 720 min
	 * (1/2) = d^720 => d = (1/2)^(1/720)
	 */
	uint256 public constant MINUTE_DECAY_FACTOR = 999037758833783000;

	/*
	 * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
	 * Corresponds to (1 / ALPHA) in the white paper.
	 */
	uint256 public constant BETA = 2;

	mapping(address => uint256) public baseRate;

	// The timestamp of the latest fee operation (redemption or new VST issuance)
	mapping(address => uint256) public lastFeeOperationTime;

	mapping(address => mapping(address => Trove)) public Troves;

	mapping(address => uint256) public totalStakes;

	// Snapshot of the value of totalStakes, taken immediately after the latest liquidation
	mapping(address => uint256) public totalStakesSnapshot;

	// Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
	mapping(address => uint256) public totalCollateralSnapshot;

	/*
	 * L_ETH and L_VSTDebt track the sums of accumulated liquidation rewards per unit staked. During its lifetime, each stake earns:
	 *
	 * An ETH gain of ( stake * [L_ETH - L_ETH(0)] )
	 * A VSTDebt increase  of ( stake * [L_VSTDebt - L_VSTDebt(0)] )
	 *
	 * Where L_ETH(0) and L_VSTDebt(0) are snapshots of L_ETH and L_VSTDebt for the active Trove taken at the instant the stake was made
	 */
	mapping(address => uint256) public L_ASSETS;
	mapping(address => uint256) public L_VSTDebts;

	// Map addresses with active troves to their RewardSnapshot
	mapping(address => mapping(address => RewardSnapshot)) public rewardSnapshots;

	// Object containing the ETH and VST snapshots for a given active trove
	struct RewardSnapshot {
		uint256 asset;
		uint256 VSTDebt;
	}

	// Array of all active trove addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
	mapping(address => address[]) public TroveOwners;

	// Error trackers for the trove redistribution calculation
	mapping(address => uint256) public lastETHError_Redistribution;
	mapping(address => uint256) public lastVSTDebtError_Redistribution;

	bool public isInitialized;

	modifier onlyBorrowerOperations() {
		require(
			msg.sender == borrowerOperationsAddress,
			"TroveManager: Caller is not the BorrowerOperations contract"
		);
		_;
	}

	modifier troveIsActive(address _asset, address _borrower) {
		require(
			isTroveActive(_asset, _borrower),
			"TroveManager: Trove does not exist or is closed"
		);
		_;
	}

	// --- Dependency setter ---

	function setAddresses(
		address _borrowerOperationsAddress,
		address _stabilityPoolManagerAddress,
		address _gasPoolAddress,
		address _collSurplusPoolAddress,
		address _vstTokenAddress,
		address _sortedTrovesAddress,
		address _vstaStakingAddress,
		address _vestaParamsAddress
	) external override initializer {
		require(!isInitialized, "Already initialized");
		checkContract(_borrowerOperationsAddress);
		checkContract(_stabilityPoolManagerAddress);
		checkContract(_gasPoolAddress);
		checkContract(_collSurplusPoolAddress);
		checkContract(_vstTokenAddress);
		checkContract(_sortedTrovesAddress);
		checkContract(_vstaStakingAddress);
		checkContract(_vestaParamsAddress);
		isInitialized = true;

		__Ownable_init();

		borrowerOperationsAddress = _borrowerOperationsAddress;
		stabilityPoolManager = IStabilityPoolManager(_stabilityPoolManagerAddress);
		gasPoolAddress = _gasPoolAddress;
		collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
		vstToken = IVSTToken(_vstTokenAddress);
		sortedTroves = ISortedTroves(_sortedTrovesAddress);
		vstaStaking = IVSTAStaking(_vstaStakingAddress);

		setVestaParameters(_vestaParamsAddress);

		emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
		emit StabilityPoolAddressChanged(_stabilityPoolManagerAddress);
		emit GasPoolAddressChanged(_gasPoolAddress);
		emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
		emit VSTTokenAddressChanged(_vstTokenAddress);
		emit SortedTrovesAddressChanged(_sortedTrovesAddress);
		emit VSTAStakingAddressChanged(_vstaStakingAddress);
	}

	// --- Getters ---

	function getTroveOwnersCount(address _asset) external view override returns (uint256) {
		return TroveOwners[_asset].length;
	}

	function getTroveFromTroveOwnersArray(address _asset, uint256 _index)
		external
		view
		override
		returns (address)
	{
		return TroveOwners[_asset][_index];
	}

	// --- Trove Liquidation functions ---

	// Single liquidation function. Closes the trove if its ICR is lower than the minimum collateral ratio.
	function liquidate(address _asset, address _borrower)
		external
		override
		troveIsActive(_asset, _borrower)
	{
		address[] memory borrowers = new address[](1);
		borrowers[0] = _borrower;
		batchLiquidateTroves(_asset, borrowers);
	}

	// --- Inner single liquidation functions ---

	// Liquidate one trove, in Normal Mode.
	function _liquidateNormalMode(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		address _borrower,
		uint256 _VSTInStabPool
	) internal returns (LiquidationValues memory singleLiquidation) {
		LocalVariables_InnerSingleLiquidateFunction memory vars;

		(
			singleLiquidation.entireTroveDebt,
			singleLiquidation.entireTroveColl,
			vars.pendingDebtReward,
			vars.pendingCollReward
		) = getEntireDebtAndColl(_asset, _borrower);

		_movePendingTroveRewardsToActivePool(
			_asset,
			_activePool,
			_defaultPool,
			vars.pendingDebtReward,
			vars.pendingCollReward
		);
		_removeStake(_asset, _borrower);

		singleLiquidation.collGasCompensation = _getCollGasCompensation(
			_asset,
			singleLiquidation.entireTroveColl
		);
		singleLiquidation.VSTGasCompensation = vestaParams.VST_GAS_COMPENSATION(_asset);
		uint256 collToLiquidate = singleLiquidation.entireTroveColl.sub(
			singleLiquidation.collGasCompensation
		);

		(
			singleLiquidation.debtToOffset,
			singleLiquidation.collToSendToSP,
			singleLiquidation.debtToRedistribute,
			singleLiquidation.collToRedistribute
		) = _getOffsetAndRedistributionVals(
			singleLiquidation.entireTroveDebt,
			collToLiquidate,
			_VSTInStabPool
		);

		_closeTrove(_asset, _borrower, Status.closedByLiquidation);
		emit TroveLiquidated(
			_asset,
			_borrower,
			singleLiquidation.entireTroveDebt,
			singleLiquidation.entireTroveColl,
			TroveManagerOperation.liquidateInNormalMode
		);
		emit TroveUpdated(_asset, _borrower, 0, 0, 0, TroveManagerOperation.liquidateInNormalMode);
		return singleLiquidation;
	}

	// Liquidate one trove, in Recovery Mode.
	function _liquidateRecoveryMode(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		address _borrower,
		uint256 _ICR,
		uint256 _VSTInStabPool,
		uint256 _TCR,
		uint256 _price
	) internal returns (LiquidationValues memory singleLiquidation) {
		LocalVariables_InnerSingleLiquidateFunction memory vars;
		if (TroveOwners[_asset].length <= 1) {
			return singleLiquidation;
		} // don't liquidate if last trove
		(
			singleLiquidation.entireTroveDebt,
			singleLiquidation.entireTroveColl,
			vars.pendingDebtReward,
			vars.pendingCollReward
		) = getEntireDebtAndColl(_asset, _borrower);

		singleLiquidation.collGasCompensation = _getCollGasCompensation(
			_asset,
			singleLiquidation.entireTroveColl
		);
		singleLiquidation.VSTGasCompensation = vestaParams.VST_GAS_COMPENSATION(_asset);
		vars.collToLiquidate = singleLiquidation.entireTroveColl.sub(
			singleLiquidation.collGasCompensation
		);

		// If ICR <= 100%, purely redistribute the Trove across all active Troves
		if (_ICR <= vestaParams._100pct()) {
			_movePendingTroveRewardsToActivePool(
				_asset,
				_activePool,
				_defaultPool,
				vars.pendingDebtReward,
				vars.pendingCollReward
			);
			_removeStake(_asset, _borrower);

			singleLiquidation.debtToOffset = 0;
			singleLiquidation.collToSendToSP = 0;
			singleLiquidation.debtToRedistribute = singleLiquidation.entireTroveDebt;
			singleLiquidation.collToRedistribute = vars.collToLiquidate;

			_closeTrove(_asset, _borrower, Status.closedByLiquidation);
			emit TroveLiquidated(
				_asset,
				_borrower,
				singleLiquidation.entireTroveDebt,
				singleLiquidation.entireTroveColl,
				TroveManagerOperation.liquidateInRecoveryMode
			);
			emit TroveUpdated(
				_asset,
				_borrower,
				0,
				0,
				0,
				TroveManagerOperation.liquidateInRecoveryMode
			);

			// If 100% < ICR < MCR, offset as much as possible, and redistribute the remainder
		} else if ((_ICR > vestaParams._100pct()) && (_ICR < vestaParams.MCR(_asset))) {
			_movePendingTroveRewardsToActivePool(
				_asset,
				_activePool,
				_defaultPool,
				vars.pendingDebtReward,
				vars.pendingCollReward
			);
			_removeStake(_asset, _borrower);

			(
				singleLiquidation.debtToOffset,
				singleLiquidation.collToSendToSP,
				singleLiquidation.debtToRedistribute,
				singleLiquidation.collToRedistribute
			) = _getOffsetAndRedistributionVals(
				singleLiquidation.entireTroveDebt,
				vars.collToLiquidate,
				_VSTInStabPool
			);

			_closeTrove(_asset, _borrower, Status.closedByLiquidation);
			emit TroveLiquidated(
				_asset,
				_borrower,
				singleLiquidation.entireTroveDebt,
				singleLiquidation.entireTroveColl,
				TroveManagerOperation.liquidateInRecoveryMode
			);
			emit TroveUpdated(
				_asset,
				_borrower,
				0,
				0,
				0,
				TroveManagerOperation.liquidateInRecoveryMode
			);
			/*
			 * If 110% <= ICR < current TCR (accounting for the preceding liquidations in the current sequence)
			 * and there is VST in the Stability Pool, only offset, with no redistribution,
			 * but at a capped rate of 1.1 and only if the whole debt can be liquidated.
			 * The remainder due to the capped rate will be claimable as collateral surplus.
			 */
		} else if (
			(_ICR >= vestaParams.MCR(_asset)) &&
			(_ICR < _TCR) &&
			(singleLiquidation.entireTroveDebt <= _VSTInStabPool)
		) {
			_movePendingTroveRewardsToActivePool(
				_asset,
				_activePool,
				_defaultPool,
				vars.pendingDebtReward,
				vars.pendingCollReward
			);
			assert(_VSTInStabPool != 0);

			_removeStake(_asset, _borrower);
			singleLiquidation = _getCappedOffsetVals(
				_asset,
				singleLiquidation.entireTroveDebt,
				singleLiquidation.entireTroveColl,
				_price
			);

			_closeTrove(_asset, _borrower, Status.closedByLiquidation);
			if (singleLiquidation.collSurplus > 0) {
				collSurplusPool.accountSurplus(_asset, _borrower, singleLiquidation.collSurplus);
			}

			emit TroveLiquidated(
				_asset,
				_borrower,
				singleLiquidation.entireTroveDebt,
				singleLiquidation.collToSendToSP,
				TroveManagerOperation.liquidateInRecoveryMode
			);
			emit TroveUpdated(
				_asset,
				_borrower,
				0,
				0,
				0,
				TroveManagerOperation.liquidateInRecoveryMode
			);
		} else {
			// if (_ICR >= MCR && ( _ICR >= _TCR || singleLiquidation.entireTroveDebt > _VSTInStabPool))
			LiquidationValues memory zeroVals;
			return zeroVals;
		}

		return singleLiquidation;
	}

	/* In a full liquidation, returns the values for a trove's coll and debt to be offset, and coll and debt to be
	 * redistributed to active troves.
	 */
	function _getOffsetAndRedistributionVals(
		uint256 _debt,
		uint256 _coll,
		uint256 _VSTInStabPool
	)
		internal
		pure
		returns (
			uint256 debtToOffset,
			uint256 collToSendToSP,
			uint256 debtToRedistribute,
			uint256 collToRedistribute
		)
	{
		if (_VSTInStabPool > 0) {
			/*
			 * Offset as much debt & collateral as possible against the Stability Pool, and redistribute the remainder
			 * between all active troves.
			 *
			 *  If the trove's debt is larger than the deposited VST in the Stability Pool:
			 *
			 *  - Offset an amount of the trove's debt equal to the VST in the Stability Pool
			 *  - Send a fraction of the trove's collateral to the Stability Pool, equal to the fraction of its offset debt
			 *
			 */
			debtToOffset = VestaMath._min(_debt, _VSTInStabPool);
			collToSendToSP = _coll.mul(debtToOffset).div(_debt);
			debtToRedistribute = _debt.sub(debtToOffset);
			collToRedistribute = _coll.sub(collToSendToSP);
		} else {
			debtToOffset = 0;
			collToSendToSP = 0;
			debtToRedistribute = _debt;
			collToRedistribute = _coll;
		}
	}

	/*
	 *  Get its offset coll/debt and ETH gas comp, and close the trove.
	 */
	function _getCappedOffsetVals(
		address _asset,
		uint256 _entireTroveDebt,
		uint256 _entireTroveColl,
		uint256 _price
	) internal view returns (LiquidationValues memory singleLiquidation) {
		singleLiquidation.entireTroveDebt = _entireTroveDebt;
		singleLiquidation.entireTroveColl = _entireTroveColl;
		uint256 cappedCollPortion = _entireTroveDebt.mul(vestaParams.MCR(_asset)).div(_price);

		singleLiquidation.collGasCompensation = _getCollGasCompensation(_asset, cappedCollPortion);
		singleLiquidation.VSTGasCompensation = vestaParams.VST_GAS_COMPENSATION(_asset);

		singleLiquidation.debtToOffset = _entireTroveDebt;
		singleLiquidation.collToSendToSP = cappedCollPortion.sub(
			singleLiquidation.collGasCompensation
		);
		singleLiquidation.collSurplus = _entireTroveColl.sub(cappedCollPortion);
		singleLiquidation.debtToRedistribute = 0;
		singleLiquidation.collToRedistribute = 0;
	}

	/*
	 * Liquidate a sequence of troves. Closes a maximum number of n under-collateralized Troves,
	 * starting from the one with the lowest collateral ratio in the system, and moving upwards
	 */
	function liquidateTroves(address _asset, uint256 _n) external override {
		ContractsCache memory contractsCache = ContractsCache(
			vestaParams.activePool(),
			vestaParams.defaultPool(),
			IVSTToken(address(0)),
			IVSTAStaking(address(0)),
			sortedTroves,
			ICollSurplusPool(address(0)),
			address(0)
		);
		IStabilityPool stabilityPoolCached = stabilityPoolManager.getAssetStabilityPool(_asset);

		LocalVariables_OuterLiquidationFunction memory vars;

		LiquidationTotals memory totals;

		vars.price = vestaParams.priceFeed().fetchPrice(_asset);
		vars.VSTInStabPool = stabilityPoolCached.getTotalVSTDeposits();
		vars.recoveryModeAtStart = _checkRecoveryMode(_asset, vars.price);

		// Perform the appropriate liquidation sequence - tally the values, and obtain their totals
		if (vars.recoveryModeAtStart) {
			totals = _getTotalsFromLiquidateTrovesSequence_RecoveryMode(
				_asset,
				contractsCache,
				vars.price,
				vars.VSTInStabPool,
				_n
			);
		} else {
			// if !vars.recoveryModeAtStart
			totals = _getTotalsFromLiquidateTrovesSequence_NormalMode(
				_asset,
				contractsCache.activePool,
				contractsCache.defaultPool,
				vars.price,
				vars.VSTInStabPool,
				_n
			);
		}

		require(totals.totalDebtInSequence > 0, "TroveManager: nothing to liquidate");

		// Move liquidated ETH and VST to the appropriate pools
		stabilityPoolCached.offset(totals.totalDebtToOffset, totals.totalCollToSendToSP);
		_redistributeDebtAndColl(
			_asset,
			contractsCache.activePool,
			contractsCache.defaultPool,
			totals.totalDebtToRedistribute,
			totals.totalCollToRedistribute
		);
		if (totals.totalCollSurplus > 0) {
			contractsCache.activePool.sendAsset(
				_asset,
				address(collSurplusPool),
				totals.totalCollSurplus
			);
		}

		// Update system snapshots
		_updateSystemSnapshots_excludeCollRemainder(
			_asset,
			contractsCache.activePool,
			totals.totalCollGasCompensation
		);

		vars.liquidatedDebt = totals.totalDebtInSequence;
		vars.liquidatedColl = totals.totalCollInSequence.sub(totals.totalCollGasCompensation).sub(
			totals.totalCollSurplus
		);
		emit Liquidation(
			_asset,
			vars.liquidatedDebt,
			vars.liquidatedColl,
			totals.totalCollGasCompensation,
			totals.totalVSTGasCompensation
		);

		// Send gas compensation to caller
		_sendGasCompensation(
			_asset,
			contractsCache.activePool,
			msg.sender,
			totals.totalVSTGasCompensation,
			totals.totalCollGasCompensation
		);
	}

	/*
	 * This function is used when the liquidateTroves sequence starts during Recovery Mode. However, it
	 * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
	 */
	function _getTotalsFromLiquidateTrovesSequence_RecoveryMode(
		address _asset,
		ContractsCache memory _contractsCache,
		uint256 _price,
		uint256 _VSTInStabPool,
		uint256 _n
	) internal returns (LiquidationTotals memory totals) {
		LocalVariables_AssetBorrowerPrice memory assetVars = LocalVariables_AssetBorrowerPrice(
			_asset,
			address(0),
			_price
		);

		LocalVariables_LiquidationSequence memory vars;
		LiquidationValues memory singleLiquidation;

		vars.remainingVSTInStabPool = _VSTInStabPool;
		vars.backToNormalMode = false;
		vars.entireSystemDebt = getEntireSystemDebt(assetVars._asset);
		vars.entireSystemColl = getEntireSystemColl(assetVars._asset);

		vars.user = _contractsCache.sortedTroves.getLast(assetVars._asset);
		address firstUser = _contractsCache.sortedTroves.getFirst(assetVars._asset);
		for (vars.i = 0; vars.i < _n && vars.user != firstUser; vars.i++) {
			// we need to cache it, because current user is likely going to be deleted
			address nextUser = _contractsCache.sortedTroves.getPrev(assetVars._asset, vars.user);

			vars.ICR = getCurrentICR(assetVars._asset, vars.user, assetVars._price);

			if (!vars.backToNormalMode) {
				// Break the loop if ICR is greater than MCR and Stability Pool is empty
				if (vars.ICR >= vestaParams.MCR(_asset) && vars.remainingVSTInStabPool == 0) {
					break;
				}

				uint256 TCR = VestaMath._computeCR(
					vars.entireSystemColl,
					vars.entireSystemDebt,
					assetVars._price
				);

				singleLiquidation = _liquidateRecoveryMode(
					assetVars._asset,
					_contractsCache.activePool,
					_contractsCache.defaultPool,
					vars.user,
					vars.ICR,
					vars.remainingVSTInStabPool,
					TCR,
					assetVars._price
				);

				// Update aggregate trackers
				vars.remainingVSTInStabPool = vars.remainingVSTInStabPool.sub(
					singleLiquidation.debtToOffset
				);
				vars.entireSystemDebt = vars.entireSystemDebt.sub(singleLiquidation.debtToOffset);
				vars.entireSystemColl = vars
					.entireSystemColl
					.sub(singleLiquidation.collToSendToSP)
					.sub(singleLiquidation.collGasCompensation)
					.sub(singleLiquidation.collSurplus);

				// Add liquidation values to their respective running totals
				totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

				vars.backToNormalMode = !_checkPotentialRecoveryMode(
					_asset,
					vars.entireSystemColl,
					vars.entireSystemDebt,
					assetVars._price
				);
			} else if (vars.backToNormalMode && vars.ICR < vestaParams.MCR(_asset)) {
				singleLiquidation = _liquidateNormalMode(
					assetVars._asset,
					_contractsCache.activePool,
					_contractsCache.defaultPool,
					vars.user,
					vars.remainingVSTInStabPool
				);

				vars.remainingVSTInStabPool = vars.remainingVSTInStabPool.sub(
					singleLiquidation.debtToOffset
				);

				// Add liquidation values to their respective running totals
				totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
			} else break; // break if the loop reaches a Trove with ICR >= MCR

			vars.user = nextUser;
		}
	}

	function _getTotalsFromLiquidateTrovesSequence_NormalMode(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _price,
		uint256 _VSTInStabPool,
		uint256 _n
	) internal returns (LiquidationTotals memory totals) {
		LocalVariables_LiquidationSequence memory vars;
		LiquidationValues memory singleLiquidation;
		ISortedTroves sortedTrovesCached = sortedTroves;

		vars.remainingVSTInStabPool = _VSTInStabPool;

		for (vars.i = 0; vars.i < _n; vars.i++) {
			vars.user = sortedTrovesCached.getLast(_asset);
			vars.ICR = getCurrentICR(_asset, vars.user, _price);

			if (vars.ICR < vestaParams.MCR(_asset)) {
				singleLiquidation = _liquidateNormalMode(
					_asset,
					_activePool,
					_defaultPool,
					vars.user,
					vars.remainingVSTInStabPool
				);

				vars.remainingVSTInStabPool = vars.remainingVSTInStabPool.sub(
					singleLiquidation.debtToOffset
				);

				// Add liquidation values to their respective running totals
				totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
			} else break; // break if the loop reaches a Trove with ICR >= MCR
		}
	}

	/*
	 * Attempt to liquidate a custom list of troves provided by the caller.
	 */
	function batchLiquidateTroves(address _asset, address[] memory _troveArray) public override {
		require(_troveArray.length != 0, "TroveManager: Calldata address array must not be empty");

		IActivePool activePoolCached = vestaParams.activePool();
		IDefaultPool defaultPoolCached = vestaParams.defaultPool();
		IStabilityPool stabilityPoolCached = stabilityPoolManager.getAssetStabilityPool(_asset);

		LocalVariables_OuterLiquidationFunction memory vars;
		LiquidationTotals memory totals;

		vars.VSTInStabPool = stabilityPoolCached.getTotalVSTDeposits();
		vars.price = vestaParams.priceFeed().fetchPrice(_asset);

		vars.recoveryModeAtStart = _checkRecoveryMode(_asset, vars.price);

		// Perform the appropriate liquidation sequence - tally values and obtain their totals.
		if (vars.recoveryModeAtStart) {
			totals = _getTotalFromBatchLiquidate_RecoveryMode(
				_asset,
				activePoolCached,
				defaultPoolCached,
				vars.price,
				vars.VSTInStabPool,
				_troveArray
			);
		} else {
			//  if !vars.recoveryModeAtStart
			totals = _getTotalsFromBatchLiquidate_NormalMode(
				_asset,
				activePoolCached,
				defaultPoolCached,
				vars.price,
				vars.VSTInStabPool,
				_troveArray
			);
		}

		require(totals.totalDebtInSequence > 0, "TroveManager: nothing to liquidate");

		// Move liquidated ETH and VST to the appropriate pools
		stabilityPoolCached.offset(totals.totalDebtToOffset, totals.totalCollToSendToSP);
		_redistributeDebtAndColl(
			_asset,
			activePoolCached,
			defaultPoolCached,
			totals.totalDebtToRedistribute,
			totals.totalCollToRedistribute
		);
		if (totals.totalCollSurplus > 0) {
			activePoolCached.sendAsset(_asset, address(collSurplusPool), totals.totalCollSurplus);
		}

		// Update system snapshots
		_updateSystemSnapshots_excludeCollRemainder(
			_asset,
			activePoolCached,
			totals.totalCollGasCompensation
		);

		vars.liquidatedDebt = totals.totalDebtInSequence;
		vars.liquidatedColl = totals.totalCollInSequence.sub(totals.totalCollGasCompensation).sub(
			totals.totalCollSurplus
		);
		emit Liquidation(
			_asset,
			vars.liquidatedDebt,
			vars.liquidatedColl,
			totals.totalCollGasCompensation,
			totals.totalVSTGasCompensation
		);

		// Send gas compensation to caller
		_sendGasCompensation(
			_asset,
			activePoolCached,
			msg.sender,
			totals.totalVSTGasCompensation,
			totals.totalCollGasCompensation
		);
	}

	/*
	 * This function is used when the batch liquidation sequence starts during Recovery Mode. However, it
	 * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
	 */
	function _getTotalFromBatchLiquidate_RecoveryMode(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _price,
		uint256 _VSTInStabPool,
		address[] memory _troveArray
	) internal returns (LiquidationTotals memory totals) {
		LocalVariables_LiquidationSequence memory vars;
		LiquidationValues memory singleLiquidation;

		vars.remainingVSTInStabPool = _VSTInStabPool;
		vars.backToNormalMode = false;
		vars.entireSystemDebt = getEntireSystemDebt(_asset);
		vars.entireSystemColl = getEntireSystemColl(_asset);

		for (vars.i = 0; vars.i < _troveArray.length; vars.i++) {
			vars.user = _troveArray[vars.i];
			// Skip non-active troves
			if (Troves[vars.user][_asset].status != Status.active) {
				continue;
			}

			vars.ICR = getCurrentICR(_asset, vars.user, _price);

			if (!vars.backToNormalMode) {
				// Skip this trove if ICR is greater than MCR and Stability Pool is empty
				if (vars.ICR >= vestaParams.MCR(_asset) && vars.remainingVSTInStabPool == 0) {
					continue;
				}

				uint256 TCR = VestaMath._computeCR(
					vars.entireSystemColl,
					vars.entireSystemDebt,
					_price
				);

				singleLiquidation = _liquidateRecoveryMode(
					_asset,
					_activePool,
					_defaultPool,
					vars.user,
					vars.ICR,
					vars.remainingVSTInStabPool,
					TCR,
					_price
				);

				// Update aggregate trackers
				vars.remainingVSTInStabPool = vars.remainingVSTInStabPool.sub(
					singleLiquidation.debtToOffset
				);
				vars.entireSystemDebt = vars.entireSystemDebt.sub(singleLiquidation.debtToOffset);
				vars.entireSystemColl = vars
					.entireSystemColl
					.sub(singleLiquidation.collToSendToSP)
					.sub(singleLiquidation.collGasCompensation)
					.sub(singleLiquidation.collSurplus);

				// Add liquidation values to their respective running totals
				totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

				vars.backToNormalMode = !_checkPotentialRecoveryMode(
					_asset,
					vars.entireSystemColl,
					vars.entireSystemDebt,
					_price
				);
			} else if (vars.backToNormalMode && vars.ICR < vestaParams.MCR(_asset)) {
				singleLiquidation = _liquidateNormalMode(
					_asset,
					_activePool,
					_defaultPool,
					vars.user,
					vars.remainingVSTInStabPool
				);
				vars.remainingVSTInStabPool = vars.remainingVSTInStabPool.sub(
					singleLiquidation.debtToOffset
				);

				// Add liquidation values to their respective running totals
				totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
			} else continue; // In Normal Mode skip troves with ICR >= MCR
		}
	}

	function _getTotalsFromBatchLiquidate_NormalMode(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _price,
		uint256 _VSTInStabPool,
		address[] memory _troveArray
	) internal returns (LiquidationTotals memory totals) {
		LocalVariables_LiquidationSequence memory vars;
		LiquidationValues memory singleLiquidation;

		vars.remainingVSTInStabPool = _VSTInStabPool;

		for (vars.i = 0; vars.i < _troveArray.length; vars.i++) {
			vars.user = _troveArray[vars.i];
			vars.ICR = getCurrentICR(_asset, vars.user, _price);

			if (vars.ICR < vestaParams.MCR(_asset)) {
				singleLiquidation = _liquidateNormalMode(
					_asset,
					_activePool,
					_defaultPool,
					vars.user,
					vars.remainingVSTInStabPool
				);
				vars.remainingVSTInStabPool = vars.remainingVSTInStabPool.sub(
					singleLiquidation.debtToOffset
				);

				// Add liquidation values to their respective running totals
				totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
			}
		}
	}

	// --- Liquidation helper functions ---

	function _addLiquidationValuesToTotals(
		LiquidationTotals memory oldTotals,
		LiquidationValues memory singleLiquidation
	) internal pure returns (LiquidationTotals memory newTotals) {
		// Tally all the values with their respective running totals
		newTotals.totalCollGasCompensation = oldTotals.totalCollGasCompensation.add(
			singleLiquidation.collGasCompensation
		);
		newTotals.totalVSTGasCompensation = oldTotals.totalVSTGasCompensation.add(
			singleLiquidation.VSTGasCompensation
		);
		newTotals.totalDebtInSequence = oldTotals.totalDebtInSequence.add(
			singleLiquidation.entireTroveDebt
		);
		newTotals.totalCollInSequence = oldTotals.totalCollInSequence.add(
			singleLiquidation.entireTroveColl
		);
		newTotals.totalDebtToOffset = oldTotals.totalDebtToOffset.add(
			singleLiquidation.debtToOffset
		);
		newTotals.totalCollToSendToSP = oldTotals.totalCollToSendToSP.add(
			singleLiquidation.collToSendToSP
		);
		newTotals.totalDebtToRedistribute = oldTotals.totalDebtToRedistribute.add(
			singleLiquidation.debtToRedistribute
		);
		newTotals.totalCollToRedistribute = oldTotals.totalCollToRedistribute.add(
			singleLiquidation.collToRedistribute
		);
		newTotals.totalCollSurplus = oldTotals.totalCollSurplus.add(singleLiquidation.collSurplus);

		return newTotals;
	}

	function _sendGasCompensation(
		address _asset,
		IActivePool _activePool,
		address _liquidator,
		uint256 _VST,
		uint256 _ETH
	) internal {
		if (_VST > 0) {
			vstToken.returnFromPool(gasPoolAddress, _liquidator, _VST);
		}

		if (_ETH > 0) {
			_activePool.sendAsset(_asset, _liquidator, _ETH);
		}
	}

	// Move a Trove's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
	function _movePendingTroveRewardsToActivePool(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _VST,
		uint256 _amount
	) internal {
		_defaultPool.decreaseVSTDebt(_asset, _VST);
		_activePool.increaseVSTDebt(_asset, _VST);
		_defaultPool.sendAssetToActivePool(_asset, _amount);
	}

	// --- Redemption functions ---

	// Redeem as much collateral as possible from _borrower's Trove in exchange for VST up to _maxVSTamount
	function _redeemCollateralFromTrove(
		address _asset,
		ContractsCache memory _contractsCache,
		address _borrower,
		uint256 _maxVSTamount,
		uint256 _price,
		address _upperPartialRedemptionHint,
		address _lowerPartialRedemptionHint,
		uint256 _partialRedemptionHintNICR
	) internal returns (SingleRedemptionValues memory singleRedemption) {
		LocalVariables_AssetBorrowerPrice memory vars = LocalVariables_AssetBorrowerPrice(
			_asset,
			_borrower,
			_price
		);

		// Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Trove minus the liquidation reserve
		singleRedemption.VSTLot = VestaMath._min(
			_maxVSTamount,
			Troves[vars._borrower][vars._asset].debt.sub(vestaParams.VST_GAS_COMPENSATION(_asset))
		);

		// Get the ETHLot of equivalent value in USD
		singleRedemption.ETHLot = singleRedemption.VSTLot.mul(DECIMAL_PRECISION).div(_price);

		// Decrease the debt and collateral of the current Trove according to the VST lot and corresponding ETH to send
		uint256 newDebt = (Troves[vars._borrower][vars._asset].debt).sub(singleRedemption.VSTLot);
		uint256 newColl = (Troves[vars._borrower][vars._asset].coll).sub(singleRedemption.ETHLot);

		if (newDebt == vestaParams.VST_GAS_COMPENSATION(_asset)) {
			// No debt left in the Trove (except for the liquidation reserve), therefore the trove gets closed
			_removeStake(vars._asset, vars._borrower);
			_closeTrove(vars._asset, vars._borrower, Status.closedByRedemption);
			_redeemCloseTrove(
				vars._asset,
				_contractsCache,
				vars._borrower,
				vestaParams.VST_GAS_COMPENSATION(vars._asset),
				newColl
			);
			emit TroveUpdated(
				vars._asset,
				vars._borrower,
				0,
				0,
				0,
				TroveManagerOperation.redeemCollateral
			);
		} else {
			uint256 newNICR = VestaMath._computeNominalCR(newColl, newDebt);

			/*
			 * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
			 * certainly result in running out of gas.
			 *
			 * If the resultant net debt of the partial is less than the minimum, net debt we bail.
			 */
			if (
				newNICR != _partialRedemptionHintNICR ||
				_getNetDebt(vars._asset, newDebt) < vestaParams.MIN_NET_DEBT(vars._asset)
			) {
				singleRedemption.cancelledPartial = true;
				return singleRedemption;
			}

			_contractsCache.sortedTroves.reInsert(
				vars._asset,
				vars._borrower,
				newNICR,
				_upperPartialRedemptionHint,
				_lowerPartialRedemptionHint
			);

			Troves[vars._borrower][vars._asset].debt = newDebt;
			Troves[vars._borrower][vars._asset].coll = newColl;
			_updateStakeAndTotalStakes(vars._asset, vars._borrower);

			emit TroveUpdated(
				vars._asset,
				vars._borrower,
				newDebt,
				newColl,
				Troves[vars._borrower][vars._asset].stake,
				TroveManagerOperation.redeemCollateral
			);
		}

		return singleRedemption;
	}

	/*
	 * Called when a full redemption occurs, and closes the trove.
	 * The redeemer swaps (debt - liquidation reserve) VST for (debt - liquidation reserve) worth of ETH, so the VST liquidation reserve left corresponds to the remaining debt.
	 * In order to close the trove, the VST liquidation reserve is burned, and the corresponding debt is removed from the active pool.
	 * The debt recorded on the trove's struct is zero'd elswhere, in _closeTrove.
	 * Any surplus ETH left in the trove, is sent to the Coll surplus pool, and can be later claimed by the borrower.
	 */
	function _redeemCloseTrove(
		address _asset,
		ContractsCache memory _contractsCache,
		address _borrower,
		uint256 _VST,
		uint256 _ETH
	) internal {
		_contractsCache.vstToken.burn(gasPoolAddress, _VST);
		// Update Active Pool VST, and send ETH to account
		_contractsCache.activePool.decreaseVSTDebt(_asset, _VST);

		// send ETH from Active Pool to CollSurplus Pool
		_contractsCache.collSurplusPool.accountSurplus(_asset, _borrower, _ETH);
		_contractsCache.activePool.sendAsset(
			_asset,
			address(_contractsCache.collSurplusPool),
			_ETH
		);
	}

	function _isValidFirstRedemptionHint(
		address _asset,
		ISortedTroves _sortedTroves,
		address _firstRedemptionHint,
		uint256 _price
	) internal view returns (bool) {
		if (
			_firstRedemptionHint == address(0) ||
			!_sortedTroves.contains(_asset, _firstRedemptionHint) ||
			getCurrentICR(_asset, _firstRedemptionHint, _price) < vestaParams.MCR(_asset)
		) {
			return false;
		}

		address nextTrove = _sortedTroves.getNext(_asset, _firstRedemptionHint);
		return
			nextTrove == address(0) ||
			getCurrentICR(_asset, nextTrove, _price) < vestaParams.MCR(_asset);
	}

	/* Send _VSTamount VST to the system and redeem the corresponding amount of collateral from as many Troves as are needed to fill the redemption
	 * request.  Applies pending rewards to a Trove before reducing its debt and coll.
	 *
	 * Note that if _amount is very large, this function can run out of gas, specially if traversed troves are small. This can be easily avoided by
	 * splitting the total _amount in appropriate chunks and calling the function multiple times.
	 *
	 * Param `_maxIterations` can also be provided, so the loop through Troves is capped (if it’s zero, it will be ignored).This makes it easier to
	 * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
	 * of the trove list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
	 * costs can vary.
	 *
	 * All Troves that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
	 * If the last Trove does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
	 * A frontend should use getRedemptionHints() to calculate what the ICR of this Trove will be after redemption, and pass a hint for its position
	 * in the sortedTroves list along with the ICR value that the hint was found for.
	 *
	 * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it
	 * is very likely that the last (partially) redeemed Trove would end up with a different ICR than what the hint is for. In this case the
	 * redemption will stop after the last completely redeemed Trove and the sender will keep the remaining VST amount, which they can attempt
	 * to redeem later.
	 */
	function redeemCollateral(
		address _asset,
		uint256 _VSTamount,
		address _firstRedemptionHint,
		address _upperPartialRedemptionHint,
		address _lowerPartialRedemptionHint,
		uint256 _partialRedemptionHintNICR,
		uint256 _maxIterations,
		uint256 _maxFeePercentage
	) external override {
		require(
			block.timestamp >= vestaParams.redemptionBlock(_asset),
			"TroveManager: Redemption is blocked"
		);

		ContractsCache memory contractsCache = ContractsCache(
			vestaParams.activePool(),
			vestaParams.defaultPool(),
			vstToken,
			vstaStaking,
			sortedTroves,
			collSurplusPool,
			gasPoolAddress
		);
		RedemptionTotals memory totals;

		_requireValidMaxFeePercentage(_asset, _maxFeePercentage);
		totals.price = vestaParams.priceFeed().fetchPrice(_asset);
		_requireTCRoverMCR(_asset, totals.price);
		_requireAmountGreaterThanZero(_VSTamount);
		_requireVSTBalanceCoversRedemption(contractsCache.vstToken, msg.sender, _VSTamount);

		totals.totalVSTSupplyAtStart = getEntireSystemDebt(_asset);
		totals.remainingVST = _VSTamount;
		address currentBorrower;

		if (
			_isValidFirstRedemptionHint(
				_asset,
				contractsCache.sortedTroves,
				_firstRedemptionHint,
				totals.price
			)
		) {
			currentBorrower = _firstRedemptionHint;
		} else {
			currentBorrower = contractsCache.sortedTroves.getLast(_asset);
			// Find the first trove with ICR >= MCR
			while (
				currentBorrower != address(0) &&
				getCurrentICR(_asset, currentBorrower, totals.price) < vestaParams.MCR(_asset)
			) {
				currentBorrower = contractsCache.sortedTroves.getPrev(_asset, currentBorrower);
			}
		}

		// Loop through the Troves starting from the one with lowest collateral ratio until _amount of VST is exchanged for collateral
		if (_maxIterations == 0) {
			_maxIterations = type(uint256).max;
		}
		while (currentBorrower != address(0) && totals.remainingVST > 0 && _maxIterations > 0) {
			_maxIterations--;
			// Save the address of the Trove preceding the current one, before potentially modifying the list
			address nextUserToCheck = contractsCache.sortedTroves.getPrev(_asset, currentBorrower);

			_applyPendingRewards(
				_asset,
				contractsCache.activePool,
				contractsCache.defaultPool,
				currentBorrower
			);

			SingleRedemptionValues memory singleRedemption = _redeemCollateralFromTrove(
				_asset,
				contractsCache,
				currentBorrower,
				totals.remainingVST,
				totals.price,
				_upperPartialRedemptionHint,
				_lowerPartialRedemptionHint,
				_partialRedemptionHintNICR
			);

			if (singleRedemption.cancelledPartial) break; // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last Trove

			totals.totalVSTToRedeem = totals.totalVSTToRedeem.add(singleRedemption.VSTLot);
			totals.totalAssetDrawn = totals.totalAssetDrawn.add(singleRedemption.ETHLot);

			totals.remainingVST = totals.remainingVST.sub(singleRedemption.VSTLot);
			currentBorrower = nextUserToCheck;
		}
		require(totals.totalAssetDrawn > 0, "TroveManager: Unable to redeem any amount");

		// Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
		// Use the saved total VST supply value, from before it was reduced by the redemption.
		_updateBaseRateFromRedemption(
			_asset,
			totals.totalAssetDrawn,
			totals.price,
			totals.totalVSTSupplyAtStart
		);

		// Calculate the ETH fee
		totals.ETHFee = _getRedemptionFee(_asset, totals.totalAssetDrawn);

		_requireUserAcceptsFee(totals.ETHFee, totals.totalAssetDrawn, _maxFeePercentage);

		// Send the ETH fee to the VSTA staking contract
		contractsCache.activePool.sendAsset(
			_asset,
			address(contractsCache.vstaStaking),
			totals.ETHFee
		);
		contractsCache.vstaStaking.increaseF_Asset(_asset, totals.ETHFee);

		totals.ETHToSendToRedeemer = totals.totalAssetDrawn.sub(totals.ETHFee);

		emit Redemption(
			_asset,
			_VSTamount,
			totals.totalVSTToRedeem,
			totals.totalAssetDrawn,
			totals.ETHFee
		);

		// Burn the total VST that is cancelled with debt, and send the redeemed ETH to msg.sender
		contractsCache.vstToken.burn(msg.sender, totals.totalVSTToRedeem);
		// Update Active Pool VST, and send ETH to account
		contractsCache.activePool.decreaseVSTDebt(_asset, totals.totalVSTToRedeem);
		contractsCache.activePool.sendAsset(_asset, msg.sender, totals.ETHToSendToRedeemer);
	}

	// --- Helper functions ---

	// Return the nominal collateral ratio (ICR) of a given Trove, without the price. Takes a trove's pending coll and debt rewards from redistributions into account.
	function getNominalICR(address _asset, address _borrower)
		public
		view
		override
		returns (uint256)
	{
		(uint256 currentAsset, uint256 currentVSTDebt) = _getCurrentTroveAmounts(
			_asset,
			_borrower
		);

		uint256 NICR = VestaMath._computeNominalCR(currentAsset, currentVSTDebt);
		return NICR;
	}

	// Return the current collateral ratio (ICR) of a given Trove. Takes a trove's pending coll and debt rewards from redistributions into account.
	function getCurrentICR(
		address _asset,
		address _borrower,
		uint256 _price
	) public view override returns (uint256) {
		(uint256 currentAsset, uint256 currentVSTDebt) = _getCurrentTroveAmounts(
			_asset,
			_borrower
		);

		uint256 ICR = VestaMath._computeCR(currentAsset, currentVSTDebt, _price);
		return ICR;
	}

	function _getCurrentTroveAmounts(address _asset, address _borrower)
		internal
		view
		returns (uint256, uint256)
	{
		uint256 pendingAssetReward = getPendingAssetReward(_asset, _borrower);
		uint256 pendingVSTDebtReward = getPendingVSTDebtReward(_asset, _borrower);

		uint256 currentAsset = Troves[_borrower][_asset].coll.add(pendingAssetReward);
		uint256 currentVSTDebt = Troves[_borrower][_asset].debt.add(pendingVSTDebtReward);

		return (currentAsset, currentVSTDebt);
	}

	function applyPendingRewards(address _asset, address _borrower)
		external
		override
		onlyBorrowerOperations
	{
		return
			_applyPendingRewards(
				_asset,
				vestaParams.activePool(),
				vestaParams.defaultPool(),
				_borrower
			);
	}

	// Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
	function _applyPendingRewards(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		address _borrower
	) internal {
		if (!hasPendingRewards(_asset, _borrower)) {
			return;
		}

		assert(isTroveActive(_asset, _borrower));

		// Compute pending rewards
		uint256 pendingAssetReward = getPendingAssetReward(_asset, _borrower);
		uint256 pendingVSTDebtReward = getPendingVSTDebtReward(_asset, _borrower);

		// Apply pending rewards to trove's state
		Troves[_borrower][_asset].coll = Troves[_borrower][_asset].coll.add(pendingAssetReward);
		Troves[_borrower][_asset].debt = Troves[_borrower][_asset].debt.add(pendingVSTDebtReward);

		_updateTroveRewardSnapshots(_asset, _borrower);

		// Transfer from DefaultPool to ActivePool
		_movePendingTroveRewardsToActivePool(
			_asset,
			_activePool,
			_defaultPool,
			pendingVSTDebtReward,
			pendingAssetReward
		);

		emit TroveUpdated(
			_asset,
			_borrower,
			Troves[_borrower][_asset].debt,
			Troves[_borrower][_asset].coll,
			Troves[_borrower][_asset].stake,
			TroveManagerOperation.applyPendingRewards
		);
	}

	// Update borrower's snapshots of L_ETH and L_VSTDebt to reflect the current values
	function updateTroveRewardSnapshots(address _asset, address _borrower)
		external
		override
		onlyBorrowerOperations
	{
		return _updateTroveRewardSnapshots(_asset, _borrower);
	}

	function _updateTroveRewardSnapshots(address _asset, address _borrower) internal {
		rewardSnapshots[_borrower][_asset].asset = L_ASSETS[_asset];
		rewardSnapshots[_borrower][_asset].VSTDebt = L_VSTDebts[_asset];
		emit TroveSnapshotsUpdated(_asset, L_ASSETS[_asset], L_VSTDebts[_asset]);
	}

	// Get the borrower's pending accumulated ETH reward, earned by their stake
	function getPendingAssetReward(address _asset, address _borrower)
		public
		view
		override
		returns (uint256)
	{
		uint256 snapshotAsset = rewardSnapshots[_borrower][_asset].asset;
		uint256 rewardPerUnitStaked = L_ASSETS[_asset].sub(snapshotAsset);

		if (rewardPerUnitStaked == 0 || !isTroveActive(_asset, _borrower)) {
			return 0;
		}

		uint256 stake = Troves[_borrower][_asset].stake;

		uint256 pendingAssetReward = stake.mul(rewardPerUnitStaked).div(DECIMAL_PRECISION);

		return pendingAssetReward;
	}

	// Get the borrower's pending accumulated VST reward, earned by their stake
	function getPendingVSTDebtReward(address _asset, address _borrower)
		public
		view
		override
		returns (uint256)
	{
		uint256 snapshotVSTDebt = rewardSnapshots[_borrower][_asset].VSTDebt;
		uint256 rewardPerUnitStaked = L_VSTDebts[_asset].sub(snapshotVSTDebt);

		if (rewardPerUnitStaked == 0 || !isTroveActive(_asset, _borrower)) {
			return 0;
		}

		uint256 stake = Troves[_borrower][_asset].stake;

		uint256 pendingVSTDebtReward = stake.mul(rewardPerUnitStaked).div(DECIMAL_PRECISION);

		return pendingVSTDebtReward;
	}

	function hasPendingRewards(address _asset, address _borrower)
		public
		view
		override
		returns (bool)
	{
		if (!isTroveActive(_asset, _borrower)) {
			return false;
		}

		return (rewardSnapshots[_borrower][_asset].asset < L_ASSETS[_asset]);
	}

	function getEntireDebtAndColl(address _asset, address _borrower)
		public
		view
		override
		returns (
			uint256 debt,
			uint256 coll,
			uint256 pendingVSTDebtReward,
			uint256 pendingAssetReward
		)
	{
		debt = Troves[_borrower][_asset].debt;
		coll = Troves[_borrower][_asset].coll;

		pendingVSTDebtReward = getPendingVSTDebtReward(_asset, _borrower);
		pendingAssetReward = getPendingAssetReward(_asset, _borrower);

		debt = debt.add(pendingVSTDebtReward);
		coll = coll.add(pendingAssetReward);
	}

	function removeStake(address _asset, address _borrower)
		external
		override
		onlyBorrowerOperations
	{
		return _removeStake(_asset, _borrower);
	}

	function _removeStake(address _asset, address _borrower) internal {
		uint256 stake = Troves[_borrower][_asset].stake;
		totalStakes[_asset] = totalStakes[_asset].sub(stake);
		Troves[_borrower][_asset].stake = 0;
	}

	function updateStakeAndTotalStakes(address _asset, address _borrower)
		external
		override
		onlyBorrowerOperations
		returns (uint256)
	{
		return _updateStakeAndTotalStakes(_asset, _borrower);
	}

	// Update borrower's stake based on their latest collateral value
	function _updateStakeAndTotalStakes(address _asset, address _borrower)
		internal
		returns (uint256)
	{
		uint256 newStake = _computeNewStake(_asset, Troves[_borrower][_asset].coll);
		uint256 oldStake = Troves[_borrower][_asset].stake;
		Troves[_borrower][_asset].stake = newStake;

		totalStakes[_asset] = totalStakes[_asset].sub(oldStake).add(newStake);
		emit TotalStakesUpdated(_asset, totalStakes[_asset]);

		return newStake;
	}

	// Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
	function _computeNewStake(address _asset, uint256 _coll) internal view returns (uint256) {
		uint256 stake;
		if (totalCollateralSnapshot[_asset] == 0) {
			stake = _coll;
		} else {
			/*
			 * The following assert() holds true because:
			 * - The system always contains >= 1 trove
			 * - When we close or liquidate a trove, we redistribute the pending rewards, so if all troves were closed/liquidated,
			 * rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
			 */
			assert(totalStakesSnapshot[_asset] > 0);
			stake = _coll.mul(totalStakesSnapshot[_asset]).div(totalCollateralSnapshot[_asset]);
		}
		return stake;
	}

	function _redistributeDebtAndColl(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _debt,
		uint256 _coll
	) internal {
		if (_debt == 0) {
			return;
		}

		/*
		 * Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
		 * error correction, to keep the cumulative error low in the running totals L_ETH and L_VSTDebt:
		 *
		 * 1) Form numerators which compensate for the floor division errors that occurred the last time this
		 * function was called.
		 * 2) Calculate "per-unit-staked" ratios.
		 * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
		 * 4) Store these errors for use in the next correction when this function is called.
		 * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
		 */
		uint256 ETHNumerator = _coll.mul(DECIMAL_PRECISION).add(
			lastETHError_Redistribution[_asset]
		);
		uint256 VSTDebtNumerator = _debt.mul(DECIMAL_PRECISION).add(
			lastVSTDebtError_Redistribution[_asset]
		);

		// Get the per-unit-staked terms
		uint256 ETHRewardPerUnitStaked = ETHNumerator.div(totalStakes[_asset]);
		uint256 VSTDebtRewardPerUnitStaked = VSTDebtNumerator.div(totalStakes[_asset]);

		lastETHError_Redistribution[_asset] = ETHNumerator.sub(
			ETHRewardPerUnitStaked.mul(totalStakes[_asset])
		);
		lastVSTDebtError_Redistribution[_asset] = VSTDebtNumerator.sub(
			VSTDebtRewardPerUnitStaked.mul(totalStakes[_asset])
		);

		// Add per-unit-staked terms to the running totals
		L_ASSETS[_asset] = L_ASSETS[_asset].add(ETHRewardPerUnitStaked);
		L_VSTDebts[_asset] = L_VSTDebts[_asset].add(VSTDebtRewardPerUnitStaked);

		emit LTermsUpdated(_asset, L_ASSETS[_asset], L_VSTDebts[_asset]);

		_activePool.decreaseVSTDebt(_asset, _debt);
		_defaultPool.increaseVSTDebt(_asset, _debt);
		_activePool.sendAsset(_asset, address(_defaultPool), _coll);
	}

	function closeTrove(address _asset, address _borrower)
		external
		override
		onlyBorrowerOperations
	{
		return _closeTrove(_asset, _borrower, Status.closedByOwner);
	}

	function _closeTrove(
		address _asset,
		address _borrower,
		Status closedStatus
	) internal {
		assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

		uint256 TroveOwnersArrayLength = TroveOwners[_asset].length;
		_requireMoreThanOneTroveInSystem(_asset, TroveOwnersArrayLength);

		Troves[_borrower][_asset].status = closedStatus;
		Troves[_borrower][_asset].coll = 0;
		Troves[_borrower][_asset].debt = 0;

		rewardSnapshots[_borrower][_asset].asset = 0;
		rewardSnapshots[_borrower][_asset].VSTDebt = 0;

		_removeTroveOwner(_asset, _borrower, TroveOwnersArrayLength);
		sortedTroves.remove(_asset, _borrower);
	}

	function _updateSystemSnapshots_excludeCollRemainder(
		address _asset,
		IActivePool _activePool,
		uint256 _collRemainder
	) internal {
		totalStakesSnapshot[_asset] = totalStakes[_asset];

		uint256 activeColl = _activePool.getAssetBalance(_asset);
		uint256 liquidatedColl = vestaParams.defaultPool().getAssetBalance(_asset);
		totalCollateralSnapshot[_asset] = activeColl.sub(_collRemainder).add(liquidatedColl);

		emit SystemSnapshotsUpdated(
			_asset,
			totalStakesSnapshot[_asset],
			totalCollateralSnapshot[_asset]
		);
	}

	function addTroveOwnerToArray(address _asset, address _borrower)
		external
		override
		onlyBorrowerOperations
		returns (uint256 index)
	{
		return _addTroveOwnerToArray(_asset, _borrower);
	}

	function _addTroveOwnerToArray(address _asset, address _borrower)
		internal
		returns (uint128 index)
	{
		TroveOwners[_asset].push(_borrower);

		index = uint128(TroveOwners[_asset].length.sub(1));
		Troves[_borrower][_asset].arrayIndex = index;

		return index;
	}

	function _removeTroveOwner(
		address _asset,
		address _borrower,
		uint256 TroveOwnersArrayLength
	) internal {
		Status troveStatus = Troves[_borrower][_asset].status;
		assert(troveStatus != Status.nonExistent && troveStatus != Status.active);

		uint128 index = Troves[_borrower][_asset].arrayIndex;
		uint256 length = TroveOwnersArrayLength;
		uint256 idxLast = length.sub(1);

		assert(index <= idxLast);

		address addressToMove = TroveOwners[_asset][idxLast];

		TroveOwners[_asset][index] = addressToMove;
		Troves[addressToMove][_asset].arrayIndex = index;
		emit TroveIndexUpdated(_asset, addressToMove, index);

		TroveOwners[_asset].pop();
	}

	function getTCR(address _asset, uint256 _price) external view override returns (uint256) {
		return _getTCR(_asset, _price);
	}

	function checkRecoveryMode(address _asset, uint256 _price)
		external
		view
		override
		returns (bool)
	{
		return _checkRecoveryMode(_asset, _price);
	}

	function _checkPotentialRecoveryMode(
		address _asset,
		uint256 _entireSystemColl,
		uint256 _entireSystemDebt,
		uint256 _price
	) internal view returns (bool) {
		uint256 TCR = VestaMath._computeCR(_entireSystemColl, _entireSystemDebt, _price);

		return TCR < vestaParams.CCR(_asset);
	}

	function _updateBaseRateFromRedemption(
		address _asset,
		uint256 _ETHDrawn,
		uint256 _price,
		uint256 _totalVSTSupply
	) internal returns (uint256) {
		uint256 decayedBaseRate = _calcDecayedBaseRate(_asset);

		uint256 redeemedVSTFraction = _ETHDrawn.mul(_price).div(_totalVSTSupply);

		uint256 newBaseRate = decayedBaseRate.add(redeemedVSTFraction.div(BETA));
		newBaseRate = VestaMath._min(newBaseRate, DECIMAL_PRECISION);
		assert(newBaseRate > 0);

		baseRate[_asset] = newBaseRate;
		emit BaseRateUpdated(_asset, newBaseRate);

		_updateLastFeeOpTime(_asset);

		return newBaseRate;
	}

	function getRedemptionRate(address _asset) public view override returns (uint256) {
		return _calcRedemptionRate(_asset, baseRate[_asset]);
	}

	function getRedemptionRateWithDecay(address _asset) public view override returns (uint256) {
		return _calcRedemptionRate(_asset, _calcDecayedBaseRate(_asset));
	}

	function _calcRedemptionRate(address _asset, uint256 _baseRate)
		internal
		view
		returns (uint256)
	{
		return
			VestaMath._min(
				vestaParams.REDEMPTION_FEE_FLOOR(_asset).add(_baseRate),
				DECIMAL_PRECISION
			);
	}

	function _getRedemptionFee(address _asset, uint256 _assetDraw)
		internal
		view
		returns (uint256)
	{
		return _calcRedemptionFee(getRedemptionRate(_asset), _assetDraw);
	}

	function getRedemptionFeeWithDecay(address _asset, uint256 _assetDraw)
		external
		view
		override
		returns (uint256)
	{
		return _calcRedemptionFee(getRedemptionRateWithDecay(_asset), _assetDraw);
	}

	function _calcRedemptionFee(uint256 _redemptionRate, uint256 _assetDraw)
		internal
		pure
		returns (uint256)
	{
		uint256 redemptionFee = _redemptionRate.mul(_assetDraw).div(DECIMAL_PRECISION);
		require(
			redemptionFee < _assetDraw,
			"TroveManager: Fee would eat up all returned collateral"
		);
		return redemptionFee;
	}

	function getBorrowingRate(address _asset) public view override returns (uint256) {
		return _calcBorrowingRate(_asset, baseRate[_asset]);
	}

	function getBorrowingRateWithDecay(address _asset) public view override returns (uint256) {
		return _calcBorrowingRate(_asset, _calcDecayedBaseRate(_asset));
	}

	function _calcBorrowingRate(address _asset, uint256 _baseRate)
		internal
		view
		returns (uint256)
	{
		return
			VestaMath._min(
				vestaParams.BORROWING_FEE_FLOOR(_asset).add(_baseRate),
				vestaParams.MAX_BORROWING_FEE(_asset)
			);
	}

	function getBorrowingFee(address _asset, uint256 _VSTDebt)
		external
		view
		override
		returns (uint256)
	{
		return _calcBorrowingFee(getBorrowingRate(_asset), _VSTDebt);
	}

	function getBorrowingFeeWithDecay(address _asset, uint256 _VSTDebt)
		external
		view
		override
		returns (uint256)
	{
		return _calcBorrowingFee(getBorrowingRateWithDecay(_asset), _VSTDebt);
	}

	function _calcBorrowingFee(uint256 _borrowingRate, uint256 _VSTDebt)
		internal
		pure
		returns (uint256)
	{
		return _borrowingRate.mul(_VSTDebt).div(DECIMAL_PRECISION);
	}

	function decayBaseRateFromBorrowing(address _asset)
		external
		override
		onlyBorrowerOperations
	{
		uint256 decayedBaseRate = _calcDecayedBaseRate(_asset);
		assert(decayedBaseRate <= DECIMAL_PRECISION);

		baseRate[_asset] = decayedBaseRate;
		emit BaseRateUpdated(_asset, decayedBaseRate);

		_updateLastFeeOpTime(_asset);
	}

	// Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
	function _updateLastFeeOpTime(address _asset) internal {
		uint256 timePassed = block.timestamp.sub(lastFeeOperationTime[_asset]);

		if (timePassed >= SECONDS_IN_ONE_MINUTE) {
			lastFeeOperationTime[_asset] = block.timestamp;
			emit LastFeeOpTimeUpdated(_asset, block.timestamp);
		}
	}

	function _calcDecayedBaseRate(address _asset) internal view returns (uint256) {
		uint256 minutesPassed = _minutesPassedSinceLastFeeOp(_asset);
		uint256 decayFactor = VestaMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

		return baseRate[_asset].mul(decayFactor).div(DECIMAL_PRECISION);
	}

	function _minutesPassedSinceLastFeeOp(address _asset) internal view returns (uint256) {
		return (block.timestamp.sub(lastFeeOperationTime[_asset])).div(SECONDS_IN_ONE_MINUTE);
	}

	function _requireVSTBalanceCoversRedemption(
		IVSTToken _vstToken,
		address _redeemer,
		uint256 _amount
	) internal view {
		require(
			_vstToken.balanceOf(_redeemer) >= _amount,
			"TroveManager: Requested redemption amount must be <= user's VST token balance"
		);
	}

	function _requireMoreThanOneTroveInSystem(address _asset, uint256 TroveOwnersArrayLength)
		internal
		view
	{
		require(
			TroveOwnersArrayLength > 1 && sortedTroves.getSize(_asset) > 1,
			"TroveManager: Only one trove in the system"
		);
	}

	function _requireAmountGreaterThanZero(uint256 _amount) internal pure {
		require(_amount > 0, "TroveManager: Amount must be greater than zero");
	}

	function _requireTCRoverMCR(address _asset, uint256 _price) internal view {
		require(
			_getTCR(_asset, _price) >= vestaParams.MCR(_asset),
			"TroveManager: Cannot redeem when TCR < MCR"
		);
	}

	function _requireValidMaxFeePercentage(address _asset, uint256 _maxFeePercentage)
		internal
		view
	{
		require(
			_maxFeePercentage >= vestaParams.REDEMPTION_FEE_FLOOR(_asset) &&
				_maxFeePercentage <= DECIMAL_PRECISION,
			"Max fee percentage must be between 0.5% and 100%"
		);
	}

	function isTroveActive(address _asset, address _borrower) internal view returns (bool) {
		return this.getTroveStatus(_asset, _borrower) == uint256(Status.active);
	}

	// --- Trove property getters ---

	function getTroveStatus(address _asset, address _borrower)
		external
		view
		override
		returns (uint256)
	{
		return uint256(Troves[_borrower][_asset].status);
	}

	function getTroveStake(address _asset, address _borrower)
		external
		view
		override
		returns (uint256)
	{
		return Troves[_borrower][_asset].stake;
	}

	function getTroveDebt(address _asset, address _borrower)
		external
		view
		override
		returns (uint256)
	{
		return Troves[_borrower][_asset].debt;
	}

	function getTroveColl(address _asset, address _borrower)
		external
		view
		override
		returns (uint256)
	{
		return Troves[_borrower][_asset].coll;
	}

	// --- Trove property setters, called by BorrowerOperations ---

	function setTroveStatus(
		address _asset,
		address _borrower,
		uint256 _num
	) external override onlyBorrowerOperations {
		Troves[_borrower][_asset].asset = _asset;
		Troves[_borrower][_asset].status = Status(_num);
	}

	function increaseTroveColl(
		address _asset,
		address _borrower,
		uint256 _collIncrease
	) external override onlyBorrowerOperations returns (uint256) {
		uint256 newColl = Troves[_borrower][_asset].coll.add(_collIncrease);
		Troves[_borrower][_asset].coll = newColl;
		return newColl;
	}

	function decreaseTroveColl(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external override onlyBorrowerOperations returns (uint256) {
		uint256 newColl = Troves[_borrower][_asset].coll.sub(_collDecrease);
		Troves[_borrower][_asset].coll = newColl;
		return newColl;
	}

	function increaseTroveDebt(
		address _asset,
		address _borrower,
		uint256 _debtIncrease
	) external override onlyBorrowerOperations returns (uint256) {
		uint256 newDebt = Troves[_borrower][_asset].debt.add(_debtIncrease);
		Troves[_borrower][_asset].debt = newDebt;
		return newDebt;
	}

	function decreaseTroveDebt(
		address _asset,
		address _borrower,
		uint256 _debtDecrease
	) external override onlyBorrowerOperations returns (uint256) {
		uint256 newDebt = Troves[_borrower][_asset].debt.sub(_debtDecrease);
		Troves[_borrower][_asset].debt = newDebt;
		return newDebt;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./IVestaBase.sol";
import "./IStabilityPool.sol";
import "./IVSTToken.sol";
import "./IVSTAStaking.sol";
import "./ICollSurplusPool.sol";
import "./ISortedTroves.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IStabilityPoolManager.sol";

// Common interface for the Trove Manager.
interface ITroveManager is IVestaBase {
	enum Status {
		nonExistent,
		active,
		closedByOwner,
		closedByLiquidation,
		closedByRedemption
	}

	// Store the necessary data for a trove
	struct Trove {
		address asset;
		uint256 debt;
		uint256 coll;
		uint256 stake;
		Status status;
		uint128 arrayIndex;
	}

	/*
	 * --- Variable container structs for liquidations ---
	 *
	 * These structs are used to hold, return and assign variables inside the liquidation functions,
	 * in order to avoid the error: "CompilerError: Stack too deep".
	 **/

	struct LocalVariables_OuterLiquidationFunction {
		uint256 price;
		uint256 VSTInStabPool;
		bool recoveryModeAtStart;
		uint256 liquidatedDebt;
		uint256 liquidatedColl;
	}

	struct LocalVariables_InnerSingleLiquidateFunction {
		uint256 collToLiquidate;
		uint256 pendingDebtReward;
		uint256 pendingCollReward;
	}

	struct LocalVariables_LiquidationSequence {
		uint256 remainingVSTInStabPool;
		uint256 i;
		uint256 ICR;
		address user;
		bool backToNormalMode;
		uint256 entireSystemDebt;
		uint256 entireSystemColl;
	}

	struct LocalVariables_AssetBorrowerPrice {
		address _asset;
		address _borrower;
		uint256 _price;
	}

	struct LiquidationValues {
		uint256 entireTroveDebt;
		uint256 entireTroveColl;
		uint256 collGasCompensation;
		uint256 VSTGasCompensation;
		uint256 debtToOffset;
		uint256 collToSendToSP;
		uint256 debtToRedistribute;
		uint256 collToRedistribute;
		uint256 collSurplus;
	}

	struct LiquidationTotals {
		uint256 totalCollInSequence;
		uint256 totalDebtInSequence;
		uint256 totalCollGasCompensation;
		uint256 totalVSTGasCompensation;
		uint256 totalDebtToOffset;
		uint256 totalCollToSendToSP;
		uint256 totalDebtToRedistribute;
		uint256 totalCollToRedistribute;
		uint256 totalCollSurplus;
	}

	struct ContractsCache {
		IActivePool activePool;
		IDefaultPool defaultPool;
		IVSTToken vstToken;
		IVSTAStaking vstaStaking;
		ISortedTroves sortedTroves;
		ICollSurplusPool collSurplusPool;
		address gasPoolAddress;
	}
	// --- Variable container structs for redemptions ---

	struct RedemptionTotals {
		uint256 remainingVST;
		uint256 totalVSTToRedeem;
		uint256 totalAssetDrawn;
		uint256 ETHFee;
		uint256 ETHToSendToRedeemer;
		uint256 decayedBaseRate;
		uint256 price;
		uint256 totalVSTSupplyAtStart;
	}

	struct SingleRedemptionValues {
		uint256 VSTLot;
		uint256 ETHLot;
		bool cancelledPartial;
	}

	// --- Events ---

	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
	event VSTTokenAddressChanged(address _newVSTTokenAddress);
	event StabilityPoolAddressChanged(address _stabilityPoolAddress);
	event GasPoolAddressChanged(address _gasPoolAddress);
	event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
	event SortedTrovesAddressChanged(address _sortedTrovesAddress);
	event VSTAStakingAddressChanged(address _VSTAStakingAddress);

	event Liquidation(
		address indexed _asset,
		uint256 _liquidatedDebt,
		uint256 _liquidatedColl,
		uint256 _collGasCompensation,
		uint256 _VSTGasCompensation
	);
	event Redemption(
		address indexed _asset,
		uint256 _attemptedVSTAmount,
		uint256 _actualVSTAmount,
		uint256 _AssetSent,
		uint256 _AssetFee
	);
	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 stake,
		uint8 operation
	);
	event TroveLiquidated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint8 operation
	);
	event BaseRateUpdated(address indexed _asset, uint256 _baseRate);
	event LastFeeOpTimeUpdated(address indexed _asset, uint256 _lastFeeOpTime);
	event TotalStakesUpdated(address indexed _asset, uint256 _newTotalStakes);
	event SystemSnapshotsUpdated(
		address indexed _asset,
		uint256 _totalStakesSnapshot,
		uint256 _totalCollateralSnapshot
	);
	event LTermsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_VSTDebt);
	event TroveSnapshotsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_VSTDebt);
	event TroveIndexUpdated(address indexed _asset, address _borrower, uint256 _newIndex);

	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 _stake,
		TroveManagerOperation _operation
	);
	event TroveLiquidated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		TroveManagerOperation _operation
	);

	enum TroveManagerOperation {
		applyPendingRewards,
		liquidateInNormalMode,
		liquidateInRecoveryMode,
		redeemCollateral
	}

	// --- Functions ---

	function setAddresses(
		address _borrowerOperationsAddress,
		address _stabilityPoolAddress,
		address _gasPoolAddress,
		address _collSurplusPoolAddress,
		address _vstTokenAddress,
		address _sortedTrovesAddress,
		address _VSTAStakingAddress,
		address _vestaParamsAddress
	) external;

	function stabilityPoolManager() external view returns (IStabilityPoolManager);

	function vstToken() external view returns (IVSTToken);

	function vstaStaking() external view returns (IVSTAStaking);

	function getTroveOwnersCount(address _asset) external view returns (uint256);

	function getTroveFromTroveOwnersArray(address _asset, uint256 _index)
		external
		view
		returns (address);

	function getNominalICR(address _asset, address _borrower) external view returns (uint256);

	function getCurrentICR(
		address _asset,
		address _borrower,
		uint256 _price
	) external view returns (uint256);

	function liquidate(address _asset, address borrower) external;

	function liquidateTroves(address _asset, uint256 _n) external;

	function batchLiquidateTroves(address _asset, address[] memory _troveArray) external;

	function redeemCollateral(
		address _asset,
		uint256 _VSTAmount,
		address _firstRedemptionHint,
		address _upperPartialRedemptionHint,
		address _lowerPartialRedemptionHint,
		uint256 _partialRedemptionHintNICR,
		uint256 _maxIterations,
		uint256 _maxFee
	) external;

	function updateStakeAndTotalStakes(address _asset, address _borrower)
		external
		returns (uint256);

	function updateTroveRewardSnapshots(address _asset, address _borrower) external;

	function addTroveOwnerToArray(address _asset, address _borrower)
		external
		returns (uint256 index);

	function applyPendingRewards(address _asset, address _borrower) external;

	function getPendingAssetReward(address _asset, address _borrower)
		external
		view
		returns (uint256);

	function getPendingVSTDebtReward(address _asset, address _borrower)
		external
		view
		returns (uint256);

	function hasPendingRewards(address _asset, address _borrower) external view returns (bool);

	function getEntireDebtAndColl(address _asset, address _borrower)
		external
		view
		returns (
			uint256 debt,
			uint256 coll,
			uint256 pendingVSTDebtReward,
			uint256 pendingAssetReward
		);

	function closeTrove(address _asset, address _borrower) external;

	function removeStake(address _asset, address _borrower) external;

	function getRedemptionRate(address _asset) external view returns (uint256);

	function getRedemptionRateWithDecay(address _asset) external view returns (uint256);

	function getRedemptionFeeWithDecay(address _asset, uint256 _assetDraw)
		external
		view
		returns (uint256);

	function getBorrowingRate(address _asset) external view returns (uint256);

	function getBorrowingRateWithDecay(address _asset) external view returns (uint256);

	function getBorrowingFee(address _asset, uint256 VSTDebt) external view returns (uint256);

	function getBorrowingFeeWithDecay(address _asset, uint256 _VSTDebt)
		external
		view
		returns (uint256);

	function decayBaseRateFromBorrowing(address _asset) external;

	function getTroveStatus(address _asset, address _borrower) external view returns (uint256);

	function getTroveStake(address _asset, address _borrower) external view returns (uint256);

	function getTroveDebt(address _asset, address _borrower) external view returns (uint256);

	function getTroveColl(address _asset, address _borrower) external view returns (uint256);

	function setTroveStatus(
		address _asset,
		address _borrower,
		uint256 num
	) external;

	function increaseTroveColl(
		address _asset,
		address _borrower,
		uint256 _collIncrease
	) external returns (uint256);

	function decreaseTroveColl(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external returns (uint256);

	function increaseTroveDebt(
		address _asset,
		address _borrower,
		uint256 _debtIncrease
	) external returns (uint256);

	function decreaseTroveDebt(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external returns (uint256);

	function getTCR(address _asset, uint256 _price) external view returns (uint256);

	function checkRecoveryMode(address _asset, uint256 _price) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./BaseMath.sol";
import "./VestaMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/IVestaBase.sol";

/*
 * Base contract for TroveManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
contract VestaBase is BaseMath, IVestaBase, OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;
	address public constant ETH_REF_ADDRESS = address(0);

	IVestaParameters public override vestaParams;

	function setVestaParameters(address _vaultParams) public onlyOwner {
		vestaParams = IVestaParameters(_vaultParams);
		emit VaultParametersBaseChanged(_vaultParams);
	}

	// --- Gas compensation functions ---

	// Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
	function _getCompositeDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt.add(vestaParams.VST_GAS_COMPENSATION(_asset));
	}

	function _getNetDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt.sub(vestaParams.VST_GAS_COMPENSATION(_asset));
	}

	// Return the amount of ETH to be drawn from a trove's collateral and sent as gas compensation.
	function _getCollGasCompensation(address _asset, uint256 _entireColl)
		internal
		view
		returns (uint256)
	{
		return _entireColl / vestaParams.PERCENT_DIVISOR(_asset);
	}

	function getEntireSystemColl(address _asset) public view returns (uint256 entireSystemColl) {
		uint256 activeColl = vestaParams.activePool().getAssetBalance(_asset);
		uint256 liquidatedColl = vestaParams.defaultPool().getAssetBalance(_asset);

		return activeColl.add(liquidatedColl);
	}

	function getEntireSystemDebt(address _asset) public view returns (uint256 entireSystemDebt) {
		uint256 activeDebt = vestaParams.activePool().getVSTDebt(_asset);
		uint256 closedDebt = vestaParams.defaultPool().getVSTDebt(_asset);

		return activeDebt.add(closedDebt);
	}

	function _getTCR(address _asset, uint256 _price) internal view returns (uint256 TCR) {
		uint256 entireSystemColl = getEntireSystemColl(_asset);
		uint256 entireSystemDebt = getEntireSystemDebt(_asset);

		TCR = VestaMath._computeCR(entireSystemColl, entireSystemDebt, _price);

		return TCR;
	}

	function _checkRecoveryMode(address _asset, uint256 _price) internal view returns (bool) {
		uint256 TCR = _getTCR(_asset, _price);

		return TCR < vestaParams.CCR(_asset);
	}

	function _requireUserAcceptsFee(
		uint256 _fee,
		uint256 _amount,
		uint256 _maxFeePercentage
	) internal view {
		uint256 feePercentage = _fee.mul(vestaParams.DECIMAL_PRECISION()).div(_amount);
		require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract CheckContract {
	function checkContract(address _account) internal view {
		require(_account != address(0), "Account cannot be zero address");

		uint256 size;
		assembly {
			size := extcodesize(_account)
		}
		require(size > 0, "Account code size cannot be zero");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./IVestaParameters.sol";

interface IVestaBase {
	event VaultParametersBaseChanged(address indexed newAddress);

	function vestaParams() external view returns (IVestaParameters);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IDeposit.sol";

interface IStabilityPool is IDeposit {
	// --- Events ---
	event StabilityPoolAssetBalanceUpdated(uint256 _newBalance);
	event StabilityPoolVSTBalanceUpdated(uint256 _newBalance);

	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
	event VSTTokenAddressChanged(address _newVSTTokenAddress);
	event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
	event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

	event P_Updated(uint256 _P);
	event S_Updated(uint256 _S, uint128 _epoch, uint128 _scale);
	event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
	event EpochUpdated(uint128 _currentEpoch);
	event ScaleUpdated(uint128 _currentScale);

	event DepositSnapshotUpdated(address indexed _depositor, uint256 _P, uint256 _S, uint256 _G);
	event SystemSnapshotUpdated(uint256 _P, uint256 _G);
	event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);
	event StakeChanged(uint256 _newSystemStake, address _depositor);

	event AssetGainWithdrawn(address indexed _depositor, uint256 _Asset, uint256 _VSTLoss);
	event VSTAPaidToDepositor(address indexed _depositor, uint256 _VSTA);
	event AssetSent(address _to, uint256 _amount);

	// --- Functions ---

	/*
	 * Called only once on init, to set addresses of other Vesta contracts
	 * Callable only by owner, renounces ownership at the end
	 */
	function setAddresses(
		address _assetAddress,
		address _borrowerOperationsAddress,
		address _troveManagerAddress,
		address _vstTokenAddress,
		address _sortedTrovesAddress,
		address _communityIssuanceAddress,
		address _vestaParamsAddress
	) external;

	/*
	 * Initial checks:
	 * - Frontend is registered or zero address
	 * - Sender is not a registered frontend
	 * - _amount is not zero
	 * ---
	 * - Triggers a VSTA issuance, based on time passed since the last issuance. The VSTA issuance is shared between *all* depositors and front ends
	 * - Tags the deposit with the provided front end tag param, if it's a new deposit
	 * - Sends depositor's accumulated gains (VSTA, ETH) to depositor
	 * - Sends the tagged front end's accumulated VSTA gains to the tagged front end
	 * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
	 */
	function provideToSP(uint256 _amount) external;

	/*
	 * Initial checks:
	 * - _amount is zero or there are no under collateralized troves left in the system
	 * - User has a non zero deposit
	 * ---
	 * - Triggers a VSTA issuance, based on time passed since the last issuance. The VSTA issuance is shared between *all* depositors and front ends
	 * - Removes the deposit's front end tag if it is a full withdrawal
	 * - Sends all depositor's accumulated gains (VSTA, ETH) to depositor
	 * - Sends the tagged front end's accumulated VSTA gains to the tagged front end
	 * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
	 *
	 * If _amount > userDeposit, the user withdraws all of their compounded deposit.
	 */
	function withdrawFromSP(uint256 _amount) external;

	/*
	 * Initial checks:
	 * - User has a non zero deposit
	 * - User has an open trove
	 * - User has some ETH gain
	 * ---
	 * - Triggers a VSTA issuance, based on time passed since the last issuance. The VSTA issuance is shared between *all* depositors and front ends
	 * - Sends all depositor's VSTA gain to  depositor
	 * - Sends all tagged front end's VSTA gain to the tagged front end
	 * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
	 * - Leaves their compounded deposit in the Stability Pool
	 * - Updates snapshots for deposit and tagged front end stake
	 */
	function withdrawAssetGainToTrove(address _upperHint, address _lowerHint) external;

	/*
	 * Initial checks:
	 * - Caller is TroveManager
	 * ---
	 * Cancels out the specified debt against the VST contained in the Stability Pool (as far as possible)
	 * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
	 * Only called by liquidation functions in the TroveManager.
	 */
	function offset(uint256 _debt, uint256 _coll) external;

	/*
	 * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
	 * to exclude edge cases like ETH received from a self-destruct.
	 */
	function getAssetBalance() external view returns (uint256);

	/*
	 * Returns VST held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
	 */
	function getTotalVSTDeposits() external view returns (uint256);

	/*
	 * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
	 */
	function getDepositorAssetGain(address _depositor) external view returns (uint256);

	/*
	 * Calculate the VSTA gain earned by a deposit since its last snapshots were taken.
	 * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
	 * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
	 * which they made their deposit.
	 */
	function getDepositorVSTAGain(address _depositor) external view returns (uint256);

	/*
	 * Return the user's compounded deposit.
	 */
	function getCompoundedVSTDeposit(address _depositor) external view returns (uint256);

	/*
	 * Return the front end's compounded stake.
	 *
	 * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
	 */
	function getCompoundedTotalStake() external view returns (uint256);

	function getNameBytes() external view returns (bytes32);

	function getAssetType() external view returns (address);

	/*
	 * Fallback function
	 * Only callable by Active Pool, it just accounts for ETH received
	 * receive() external payable;
	 */
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "../Dependencies/ERC20Permit.sol";
import "../Interfaces/IStabilityPoolManager.sol";

abstract contract IVSTToken is ERC20Permit {
	// --- Events ---

	event TroveManagerAddressChanged(address _troveManagerAddress);
	event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

	event VSTTokenBalanceUpdated(address _user, uint256 _amount);

	function emergencyStopMinting(address _asset, bool status) external virtual;

	function mint(
		address _asset,
		address _account,
		uint256 _amount
	) external virtual;

	function burn(address _account, uint256 _amount) external virtual;

	function sendToPool(
		address _sender,
		address poolAddress,
		uint256 _amount
	) external virtual;

	function returnFromPool(
		address poolAddress,
		address user,
		uint256 _amount
	) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface IVSTAStaking {
	// --- Events --

	event TreasuryAddressChanged(address _treausury);
	event SentToTreasury(address indexed _asset, uint256 _amount);
	event VSTATokenAddressSet(address _VSTATokenAddress);
	event VSTTokenAddressSet(address _vstTokenAddress);
	event TroveManagerAddressSet(address _troveManager);
	event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
	event ActivePoolAddressSet(address _activePoolAddress);

	event StakeChanged(address indexed staker, uint256 newStake);
	event StakingGainsAssetWithdrawn(
		address indexed staker,
		address indexed asset,
		uint256 AssetGain
	);
	event StakingGainsVSTWithdrawn(address indexed staker, uint256 VSTGain);
	event F_AssetUpdated(address indexed _asset, uint256 _F_ASSET);
	event F_VSTUpdated(uint256 _F_VST);
	event TotalVSTAStakedUpdated(uint256 _totalVSTAStaked);
	event AssetSent(address indexed _asset, address indexed _account, uint256 _amount);
	event StakerSnapshotsUpdated(address _staker, uint256 _F_Asset, uint256 _F_VST);

	function vstaToken() external view returns (IERC20Upgradeable);

	// --- Functions ---

	function setAddresses(
		address _VSTATokenAddress,
		address _vstTokenAddress,
		address _troveManagerAddress,
		address _borrowerOperationsAddress,
		address _activePoolAddress,
		address _treasury
	) external;

	function stake(uint256 _VSTAamount) external;

	function unstake(uint256 _VSTAamount) external;

	function increaseF_Asset(address _asset, uint256 _AssetFee) external;

	function increaseF_VST(uint256 _VSTAFee) external;

	function getPendingAssetGain(address _asset, address _user) external view returns (uint256);

	function getPendingVSTGain(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IDeposit.sol";

interface ICollSurplusPool is IDeposit {
	// --- Events ---

	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event ActivePoolAddressChanged(address _newActivePoolAddress);

	event CollBalanceUpdated(address indexed _account, uint256 _newBalance);
	event AssetSent(address _to, uint256 _amount);

	// --- Contract setters ---

	function setAddresses(
		address _borrowerOperationsAddress,
		address _troveManagerAddress,
		address _activePoolAddress
	) external;

	function getAssetBalance(address _asset) external view returns (uint256);

	function getCollateral(address _asset, address _account) external view returns (uint256);

	function accountSurplus(
		address _asset,
		address _account,
		uint256 _amount
	) external;

	function claimColl(address _asset, address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {
	// --- Events ---

	event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
	event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
	event NodeAdded(address indexed _asset, address _id, uint256 _NICR);
	event NodeRemoved(address indexed _asset, address _id);

	// --- Functions ---

	function setParams(address _TroveManagerAddress, address _borrowerOperationsAddress)
		external;

	function insert(
		address _asset,
		address _id,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external;

	function remove(address _asset, address _id) external;

	function reInsert(
		address _asset,
		address _id,
		uint256 _newICR,
		address _prevId,
		address _nextId
	) external;

	function contains(address _asset, address _id) external view returns (bool);

	function isFull(address _asset) external view returns (bool);

	function isEmpty(address _asset) external view returns (bool);

	function getSize(address _asset) external view returns (uint256);

	function getMaxSize(address _asset) external view returns (uint256);

	function getFirst(address _asset) external view returns (address);

	function getLast(address _asset) external view returns (address);

	function getNext(address _asset, address _id) external view returns (address);

	function getPrev(address _asset, address _id) external view returns (address);

	function validInsertPosition(
		address _asset,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external view returns (bool);

	function findInsertPosition(
		address _asset,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./IPool.sol";

interface IActivePool is IPool {
	// --- Events ---
	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event ActivePoolVSTDebtUpdated(address _asset, uint256 _VSTDebt);
	event ActivePoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---
	function sendAsset(
		address _asset,
		address _account,
		uint256 _amount
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./IPool.sol";

interface IDefaultPool is IPool {
	// --- Events ---
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event DefaultPoolVSTDebtUpdated(address _asset, uint256 _VSTDebt);
	event DefaultPoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---
	function sendAssetToActivePool(address _asset, uint256 _amount) external;
}

pragma solidity ^0.8.10;

import "./IStabilityPool.sol";

interface IStabilityPoolManager {
	function isStabilityPool(address stabilityPool) external view returns (bool);

	function addStabilityPool(address asset, address stabilityPool) external;

	function getAssetStabilityPool(address asset) external view returns (IStabilityPool);

	function unsafeGetAssetStabilityPool(address asset) external view returns (address);
}

pragma solidity ^0.8.10;

import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IPriceFeed.sol";
import "./IVestaBase.sol";

interface IVestaParameters {
	error SafeCheckError(
		string parameter,
		uint256 valueEntered,
		uint256 minValue,
		uint256 maxValue
	);

	event MCRChanged(uint256 oldMCR, uint256 newMCR);
	event CCRChanged(uint256 oldCCR, uint256 newCCR);
	event GasCompensationChanged(uint256 oldGasComp, uint256 newGasComp);
	event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
	event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
	event BorrowingFeeFloorChanged(uint256 oldBorrowingFloorFee, uint256 newBorrowingFloorFee);
	event MaxBorrowingFeeChanged(uint256 oldMaxBorrowingFee, uint256 newMaxBorrowingFee);
	event RedemptionFeeFloorChanged(
		uint256 oldRedemptionFeeFloor,
		uint256 newRedemptionFeeFloor
	);
	event RedemptionBlockRemoved(address _asset);
	event PriceFeedChanged(address indexed addr);

	function DECIMAL_PRECISION() external view returns (uint256);

	function _100pct() external view returns (uint256);

	// Minimum collateral ratio for individual troves
	function MCR(address _collateral) external view returns (uint256);

	// Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
	function CCR(address _collateral) external view returns (uint256);

	function VST_GAS_COMPENSATION(address _collateral) external view returns (uint256);

	function MIN_NET_DEBT(address _collateral) external view returns (uint256);

	function PERCENT_DIVISOR(address _collateral) external view returns (uint256);

	function BORROWING_FEE_FLOOR(address _collateral) external view returns (uint256);

	function REDEMPTION_FEE_FLOOR(address _collateral) external view returns (uint256);

	function MAX_BORROWING_FEE(address _collateral) external view returns (uint256);

	function redemptionBlock(address _collateral) external view returns (uint256);

	function activePool() external view returns (IActivePool);

	function defaultPool() external view returns (IDefaultPool);

	function priceFeed() external view returns (IPriceFeed);

	function setAddresses(
		address _activePool,
		address _defaultPool,
		address _priceFeed,
		address _adminContract
	) external;

	function setPriceFeed(address _priceFeed) external;

	function setMCR(address _asset, uint256 newMCR) external;

	function setCCR(address _asset, uint256 newCCR) external;

	function sanitizeParameters(address _asset) external;

	function setAsDefault(address _asset) external;

	function setAsDefaultWithRemptionBlock(address _asset, uint256 blockInDays) external;

	function setVSTGasCompensation(address _asset, uint256 gasCompensation) external;

	function setMinNetDebt(address _asset, uint256 minNetDebt) external;

	function setPercentDivisor(address _asset, uint256 precentDivisor) external;

	function setBorrowingFeeFloor(address _asset, uint256 borrowingFeeFloor) external;

	function setMaxBorrowingFee(address _asset, uint256 maxBorrowingFee) external;

	function setRedemptionFeeFloor(address _asset, uint256 redemptionFeeFloor) external;

	function removeRedemptionBlock(address _asset) external;
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.10;

interface IPriceFeed {
	struct ChainlinkResponse {
		uint80 roundId;
		int256 answer;
		uint256 timestamp;
		bool success;
		uint8 decimals;
	}

	struct RegisterOracle {
		AggregatorV3Interface chainLinkOracle;
		AggregatorV3Interface chainLinkIndex;
		bool isRegistered;
	}

	enum Status {
		chainlinkWorking,
		chainlinkUntrusted
	}

	// --- Events ---
	event PriceFeedStatusChanged(Status newStatus);
	event LastGoodPriceUpdated(address indexed token, uint256 _lastGoodPrice);
	event LastGoodIndexUpdated(address indexed token, uint256 _lastGoodIndex);
	event RegisteredNewOracle(
		address token,
		address chainLinkAggregator,
		address chianLinkIndex
	);

	// --- Function ---
	function addOracle(
		address _token,
		address _chainlinkOracle,
		address _chainlinkIndexOracle
	) external;

	function fetchPrice(address _token) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IDeposit.sol";

// Common interface for the Pools.
interface IPool is IDeposit {
	// --- Events ---

	event AssetBalanceUpdated(uint256 _newBalance);
	event VSTBalanceUpdated(uint256 _newBalance);
	event ActivePoolAddressChanged(address _newActivePoolAddress);
	event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
	event AssetAddressChanged(address _assetAddress);
	event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
	event AssetSent(address _to, address indexed _asset, uint256 _amount);

	// --- Functions ---

	function getAssetBalance(address _asset) external view returns (uint256);

	function getVSTDebt(address _asset) external view returns (uint256);

	function increaseVSTDebt(address _asset, uint256 _amount) external;

	function decreaseVSTDebt(address _asset, uint256 _amount) external;
}

pragma solidity ^0.8.10;

interface IDeposit {
	function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IERC2612Permit {
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
	function permit(
		address owner,
		address spender,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/**
	 * @dev Returns the current ERC2612 nonce for `owner`. This value must be
	 * included whenever a signature is generated for {permit}.
	 *
	 * Every successful call to {permit} increases ``owner``'s nonce by one. This
	 * prevents a signature from being used multiple times.
	 */
	function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
	using Counters for Counters.Counter;

	mapping(address => Counters.Counter) private _nonces;

	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_TYPEHASH =
		0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

	bytes32 public DOMAIN_SEPARATOR;

	constructor() {
		uint256 chainID;
		assembly {
			chainID := chainid()
		}

		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256(
					"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
				),
				keccak256(bytes(name())),
				keccak256(bytes("1")), // Version
				chainID,
				address(this)
			)
		);
	}

	/**
	 * @dev See {IERC2612Permit-permit}.
	 *
	 */
	function permit(
		address owner,
		address spender,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual override {
		require(block.timestamp <= deadline, "Permit: expired deadline");

		bytes32 hashStruct = keccak256(
			abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline)
		);

		bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

		address signer = ecrecover(_hash, v, r, s);
		require(signer != address(0) && signer == owner, "ERC20Permit: Invalid signature");

		_nonces[owner].increment();
		_approve(owner, spender, amount);
	}

	/**
	 * @dev See {IERC2612Permit-nonces}.
	 */
	function nonces(address owner) public view override returns (uint256) {
		return _nonces[owner].current();
	}

	function chainId() public view returns (uint256 chainID) {
		assembly {
			chainID := chainid()
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract BaseMath {
	uint256 public constant DECIMAL_PRECISION = 1 ether;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library VestaMath {
	using SafeMathUpgradeable for uint256;

	uint256 internal constant DECIMAL_PRECISION = 1 ether;

	/* Precision for Nominal ICR (independent of price). Rationale for the value:
	 *
	 * - Making it “too high” could lead to overflows.
	 * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
	 *
	 * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
	 * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
	 *
	 */
	uint256 internal constant NICR_PRECISION = 1e20;

	function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a < _b) ? _a : _b;
	}

	function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a : _b;
	}

	/*
	 * Multiply two decimal numbers and use normal rounding rules:
	 * -round product up if 19'th mantissa digit >= 5
	 * -round product down if 19'th mantissa digit < 5
	 *
	 * Used only inside the exponentiation, _decPow().
	 */
	function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
		uint256 prod_xy = x.mul(y);

		decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
	}

	/*
	 * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
	 *
	 * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
	 *
	 * Called by two functions that represent time in units of minutes:
	 * 1) TroveManager._calcDecayedBaseRate
	 * 2) CommunityIssuance._getCumulativeIssuanceFraction
	 *
	 * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
	 * "minutes in 1000 years": 60 * 24 * 365 * 1000
	 *
	 * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
	 * negligibly different from just passing the cap, since:
	 *
	 * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
	 * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
	 */
	function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
		if (_minutes > 525600000) {
			_minutes = 525600000;
		} // cap to avoid overflow

		if (_minutes == 0) {
			return DECIMAL_PRECISION;
		}

		uint256 y = DECIMAL_PRECISION;
		uint256 x = _base;
		uint256 n = _minutes;

		// Exponentiation-by-squaring
		while (n > 1) {
			if (n % 2 == 0) {
				x = decMul(x, x);
				n = n.div(2);
			} else {
				// if (n % 2 != 0)
				y = decMul(x, y);
				x = decMul(x, x);
				n = (n.sub(1)).div(2);
			}
		}

		return decMul(x, y);
	}

	function _getAbsoluteDifference(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
	}

	function _computeNominalCR(uint256 _coll, uint256 _debt) internal pure returns (uint256) {
		if (_debt > 0) {
			return _coll.mul(NICR_PRECISION).div(_debt);
		}
		// Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
		else {
			// if (_debt == 0)
			return 2**256 - 1;
		}
	}

	function _computeCR(
		uint256 _coll,
		uint256 _debt,
		uint256 _price
	) internal pure returns (uint256) {
		if (_debt > 0) {
			uint256 newCollRatio = _coll.mul(_price).div(_debt);

			return newCollRatio;
		}
		// Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
		else {
			// if (_debt == 0)
			return type(uint256).max;
		}
	}
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}