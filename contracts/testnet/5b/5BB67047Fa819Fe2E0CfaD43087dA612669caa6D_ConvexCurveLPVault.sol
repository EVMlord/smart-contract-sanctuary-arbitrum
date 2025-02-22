// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IncentiveVault} from './IncentiveVault.sol';
import {IERC20} from './IERC20.sol';
import {SafeERC20} from './SafeERC20.sol';
import {IERC20Detailed} from './IERC20Detailed.sol';
import {IConvexBooster} from './IConvexBooster.sol';
import {IConvexBaseRewardPool} from './IConvexBaseRewardPool.sol';
import {Errors} from './Errors.sol';
import {NatriumInternalAsset} from './NatriumInternalAsset.sol';
import {PercentageMath} from './PercentageMath.sol';
import {DataTypes} from './DataTypes.sol';
import {ILendingPool} from './ILendingPool.sol';

interface IRewards {
  function rewardToken() external view returns (address);
}

/**
 * @title ConvexCurveLPVault
 * @notice Curve LP Token Vault by using Convex on Ethereum
 * @author Natrium
 **/
contract ConvexCurveLPVault is IncentiveVault {
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;

  address public convexBooster;
  address internal curveLPToken;
  address internal internalAssetToken;
  uint256 internal convexPoolId;

  uint256 internal _incentiveRatio;

  /**
   * @dev Emitted on setConfiguration()
   * @param _curveLpToken The address of Curve LP Token
   * @param _convexPoolId The convex pool Id
   * @param _internalToken The address of internal asset
   */
  event SetParameters(address _curveLpToken, uint256 _convexPoolId, address _internalToken);

  /**
   * @dev The function to set parameters related to convex/curve
   * @param _lpToken The address of Curve LP Token which will be used in vault
   * @param _poolId  The convex pool Id for Curve LP Token
   */
  function setConfiguration(address _lpToken, uint256 _poolId) external payable onlyAdmin {
    require(_lpToken != address(0), Errors.VT_INVALID_CONFIGURATION);
    require(internalAssetToken == address(0), Errors.VT_INVALID_CONFIGURATION);

    convexBooster = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    curveLPToken = _lpToken;
    convexPoolId = _poolId;
    NatriumInternalAsset _interalToken = new NatriumInternalAsset(
      string(abi.encodePacked('Natrium ', IERC20Detailed(_lpToken).symbol())),
      string(abi.encodePacked('c', IERC20Detailed(_lpToken).symbol())),
      IERC20Detailed(_lpToken).decimals()
    );
    internalAssetToken = address(_interalToken);

    emit SetParameters(_lpToken, _poolId, internalAssetToken);
  }

  /**
   * @dev The function to get internal asset address
   */
  function getInternalAsset() external view returns (address) {
    return internalAssetToken;
  }

  /**
   * @dev The function to get rewards token address
   */
  function getBaseRewardPool() internal view returns (address) {
    IConvexBooster.PoolInfo memory poolInfo = IConvexBooster(convexBooster).poolInfo(convexPoolId);
    return poolInfo.crvRewards;
  }

  /**
   * @dev The function to send rewards to YieldManager & Treasury
   * @param _asset The rewards token address
   */
  function _transferYield(address _asset) internal {
    require(_asset != address(0), Errors.VT_PROCESS_YIELD_INVALID);
    uint256 yieldAmount = IERC20(_asset).balanceOf(address(this));

    // Some ERC20 do not allow zero amounts to be sent:
    if (yieldAmount == 0) return;

    uint256 incentiveAmount;
    uint256 fee = _incentiveRatio;
    bool isIncentiveToken = (getIncentiveToken() == _asset);
    if (isIncentiveToken && fee != 0) {
      incentiveAmount = yieldAmount.percentMul(fee);
      _sendIncentive(incentiveAmount);
    }

    // Move some yield to treasury
    fee = _vaultFee;
    if (fee != 0) {
      uint256 treasuryAmount = yieldAmount.percentMul(fee);
      IERC20(_asset).safeTransfer(_treasuryAddress, treasuryAmount);
      yieldAmount -= treasuryAmount;
    }

    if (incentiveAmount > 0) {
      yieldAmount -= incentiveAmount;
    }

    // transfer to yieldManager
    if (yieldAmount > 0) {
      address yieldManager = _addressesProvider.getAddress('YIELD_MANAGER');
      IERC20(_asset).safeTransfer(yieldManager, yieldAmount);
    }

    emit ProcessYield(_asset, yieldAmount);
  }

  function processYield() external override {
    // Claim Rewards(CRV, CVX, Extra incentive tokens)
    address baseRewardPool = getBaseRewardPool();
    IConvexBaseRewardPool(baseRewardPool).getReward();

    // Transfer CRV to YieldManager
    _transferYield(IConvexBaseRewardPool(baseRewardPool).rewardToken());

    // Transfer CVX to YieldManager
    _transferYield(IConvexBooster(convexBooster).minter());
  }

  /**
   * @dev The function to transfer extra incentive token to YieldManager
   * @param _offset extraRewards start offset.
   * @param _count extraRewards count
   */
  function processExtraYield(uint256 _offset, uint256 _count) external payable onlyAdmin {
    address baseRewardPool = getBaseRewardPool();
    uint256 extraRewardsLength = IConvexBaseRewardPool(baseRewardPool).extraRewardsLength();

    require(_offset + _count <= extraRewardsLength, Errors.VT_EXTRA_REWARDS_INDEX_INVALID);

    for (uint256 i; i < _count; ++i) {
      address _extraReward = IConvexBaseRewardPool(baseRewardPool).extraRewards(_offset + i);
      address _rewardToken = IRewards(_extraReward).rewardToken();
      _transferYield(_rewardToken);
    }
  }

  /**
   * @dev Get yield amount based on strategy
   */
  function getYieldAmount() external view returns (uint256) {
    return _getYieldAmount(internalAssetToken);
  }

  /**
   * @dev Get price per share based on yield strategy
   */
  function pricePerShare() external view override returns (uint256) {
    uint256 decimals = IERC20Detailed(internalAssetToken).decimals();
    return 10**decimals;
  }

  /**
   * @dev Deposit to yield pool based on strategy and mint internal asset
   */
  function _depositToYieldPool(address _asset, uint256 _amount)
    internal
    override
    returns (address, uint256)
  {
    // receive Curve LP Token from user
    address token = curveLPToken;
    require(_asset == token, Errors.VT_COLLATERAL_DEPOSIT_INVALID);
    IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

    // deposit Curve LP Token to Convex
    address convexVault = convexBooster;
    IERC20(token).safeApprove(convexVault, 0);
    IERC20(token).safeApprove(convexVault, _amount);
    IConvexBooster(convexVault).deposit(convexPoolId, _amount, true);

    // mint
    address internalAsset = internalAssetToken;
    address lendingPoolAddress = _addressesProvider.getLendingPool();
    NatriumInternalAsset(internalAsset).mint(address(this), _amount);
    IERC20(internalAsset).safeApprove(lendingPoolAddress, 0);
    IERC20(internalAsset).safeApprove(lendingPoolAddress, _amount);

    return (internalAsset, _amount);
  }

  /**
   * @dev Get Withdrawal amount of Curve LP Token based on strategy
   */
  function _getWithdrawalAmount(address _asset, uint256 _amount)
    internal
    view
    override
    returns (address, uint256)
  {
    require(_asset == curveLPToken, Errors.VT_COLLATERAL_WITHDRAW_INVALID);

    // In this vault, return same amount of asset.
    return (internalAssetToken, _amount);
  }

  function _withdraw(uint256 _amount, address _to) internal returns (uint256) {
    // Withdraw from Convex
    address baseRewardPool = getBaseRewardPool();
    IConvexBaseRewardPool(baseRewardPool).withdrawAndUnwrap(_amount, false);

    // Deliver Curve LP Token
    IERC20(curveLPToken).safeTransfer(_to, _amount);

    // Burn
    NatriumInternalAsset(internalAssetToken).burn(address(this), _amount);

    return _amount;
  }

  function withdrawOnLiquidation(address _asset, uint256 _amount)
    external
    override
    returns (uint256)
  {
    require(_asset == curveLPToken, Errors.LP_LIQUIDATION_CALL_FAILED);
    require(msg.sender == _addressesProvider.getLendingPool(), Errors.LP_LIQUIDATION_CALL_FAILED);

    return _withdraw(_amount, msg.sender);
  }

  /**
   * @dev Withdraw from yield pool based on strategy and deliver asset
   */
  function _withdrawFromYieldPool(
    address,
    uint256 _amount,
    address _to
  ) internal override returns (uint256) {
    return _withdraw(_amount, _to);
  }

  function getIncentiveToken() public view override returns (address) {
    address baseRewardPool = getBaseRewardPool();
    return IConvexBaseRewardPool(baseRewardPool).rewardToken();
  }

  function getCurrentTotalIncentiveAmount() external view override returns (uint256) {
    if (_incentiveRatio > 0) {
      address baseRewardPool = getBaseRewardPool();
      uint256 earned = IConvexBaseRewardPool(baseRewardPool).earned(address(this));
      return earned.percentMul(_incentiveRatio);
    }
    return 0;
  }

  function getIncentiveRatio() external view override returns (uint256) {
    return _incentiveRatio;
  }

  function setIncentiveRatio(uint256 _ratio) external override onlyAdmin {
    require(_vaultFee + _ratio <= PercentageMath.PERCENTAGE_FACTOR, Errors.VT_FEE_TOO_BIG);

    // Get all available rewards & Send it to YieldDistributor,
    // so that the changing ratio does not affect asset's cumulative index
    if (_incentiveRatio != 0) {
      _clearRewards();
    }

    _incentiveRatio = _ratio;

    emit SetIncentiveRatio(_ratio);
  }

  function _getAToken() internal view override returns (address) {
    address internalAsset = internalAssetToken;
    DataTypes.ReserveData memory reserveData = ILendingPool(_addressesProvider.getLendingPool())
      .getReserveData(internalAsset);
    return reserveData.aTokenAddress;
  }

  function _clearRewards() internal override {
    address baseRewardPool = getBaseRewardPool();
    IConvexBaseRewardPool(baseRewardPool).getReward();
    _transferYield(IConvexBaseRewardPool(baseRewardPool).rewardToken());
  }
}