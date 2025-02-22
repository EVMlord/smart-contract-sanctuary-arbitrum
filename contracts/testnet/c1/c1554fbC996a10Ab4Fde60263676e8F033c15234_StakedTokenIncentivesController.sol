// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {SafeERC20} from './SafeERC20.sol';
import {DistributionTypes} from './DistributionTypes.sol';
import {VersionedInitializable} from './VersionedInitializable.sol';
import {DistributionManager} from './DistributionManager.sol';
import {IERC20} from './IERC20.sol';
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IPoissonIncentivesController} from './IPoissonIncentivesController.sol';
import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {IAToken} from './IAToken.sol';
import {ILendingPool} from './ILendingPool.sol';
import {IReserveInterestRateStrategy} from './IReserveInterestRateStrategy.sol';
import {IYieldDistribution} from './IYieldDistribution.sol';
import {IYieldDistributorAdapter} from './IYieldDistributorAdapter.sol';
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';

/**
 * @title StakedTokenIncentivesController
 * @notice Distributor contract for rewards to the Poisson protocol, using a staked token as rewards asset.
 * The contract stakes the rewards before redistributing them to the Poisson protocol participants.
 * @author Poisson
 **/
contract StakedTokenIncentivesController is
  IPoissonIncentivesController,
  VersionedInitializable,
  DistributionManager
{
  using SafeERC20 for IERC20;

  uint256 private constant REVISION = 3;
  address private constant Poisson_TOKEN = 0x4a7412dff5BfaE87867FcCe7010A69d8b2842a6A;

  mapping(address => uint256) internal _usersUnclaimedRewards;
  ILendingPoolAddressesProvider internal _addressProvider;

  // this mapping allows whitelisted addresses to claim on behalf of others
  // useful for contracts that hold tokens to be rewarded but don't have any native logic to claim Liquidity Mining rewards
  mapping(address => address) internal _authorizedClaimers;

  modifier onlyAuthorizedClaimers(address claimer, address user) {
    require(_authorizedClaimers[user] == claimer, Errors.CLAIMER_UNAUTHORIZED);
    _;
  }

  constructor(address emissionManager) DistributionManager(emissionManager) {}

  /**
   * @dev Initialize IStakedTokenIncentivesController
   * @param _provider the address of the corresponding addresses provider
   **/
  function initialize(ILendingPoolAddressesProvider _provider) external initializer {
    _addressProvider = _provider;
  }

  /// @inheritdoc IPoissonIncentivesController
  function configureAssets(
    address[] calldata assets,
    uint256[] calldata emissionsPerSecond
  ) external payable override onlyEmissionManager {
    uint256 length = assets.length;
    require(length == emissionsPerSecond.length, Errors.YD_INVALID_CONFIGURATION);

    DistributionTypes.AssetConfigInput[]
      memory assetsConfig = new DistributionTypes.AssetConfigInput[](assets.length);

    for (uint256 i; i < length; ++i) {
      assetsConfig[i].underlyingAsset = assets[i];
      assetsConfig[i].emissionPerSecond = uint104(emissionsPerSecond[i]);

      require(
        assetsConfig[i].emissionPerSecond == emissionsPerSecond[i],
        Errors.YD_INVALID_CONFIGURATION
      );

      assetsConfig[i].totalStaked = IScaledBalanceToken(assets[i]).scaledTotalSupply();
    }
    _configureAssets(assetsConfig);
  }

  /// @inheritdoc IPoissonIncentivesController
  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external override {
    ILendingPoolAddressesProvider provider = _addressProvider;
    address reserveAsset = IAToken(msg.sender).UNDERLYING_ASSET_ADDRESS();
    require(reserveAsset != address(0), Errors.YD_INVALID_CONFIGURATION);

    IYieldDistributorAdapter distributorAdapter = IYieldDistributorAdapter(
      _addressProvider.getAddress('YIELD_DISTRIBUTOR_ADAPTER')
    );
    address[] memory sYieldDistributors = distributorAdapter.getStableYieldDistributors(
      reserveAsset
    );
    uint256 length = sYieldDistributors.length;
    if (length != 0) {
      for (uint256 i = 0; i < length; ++i) {
        IYieldDistribution(sYieldDistributors[i]).handleAction(
          user,
          msg.sender,
          totalSupply,
          userBalance
        );
      }
    }

    address vYieldDistributor = distributorAdapter.getVariableYieldDistributor(reserveAsset);
    if (vYieldDistributor != address(0)) {
      IYieldDistribution(vYieldDistributor).handleAction(
        user,
        msg.sender,
        totalSupply,
        userBalance
      );
    }

    if (assets[msg.sender].emissionPerSecond == 0) return;

    uint256 accruedRewards = _updateUserAssetInternal(user, msg.sender, userBalance, totalSupply);
    if (accruedRewards != 0) {
      _usersUnclaimedRewards[user] += accruedRewards;
      emit RewardsAccrued(user, accruedRewards);
    }
  }

  /// @inheritdoc IPoissonIncentivesController
  function getRewardsBalance(
    address[] calldata assets,
    address user
  ) external view override returns (uint256) {
    uint256 unclaimedRewards = _usersUnclaimedRewards[user];
    uint256 length = assets.length;
    DistributionTypes.UserStakeInput[] memory userState = new DistributionTypes.UserStakeInput[](
      length
    );
    for (uint256 i; i < length; ++i) {
      userState[i].underlyingAsset = assets[i];
      (userState[i].stakedByUser, userState[i].totalStaked) = IScaledBalanceToken(assets[i])
        .getScaledUserBalanceAndSupply(user);
    }
    unclaimedRewards += _getUnclaimedRewards(user, userState);
    return unclaimedRewards;
  }

  /// @inheritdoc IPoissonIncentivesController
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external override returns (uint256) {
    require(to != address(0), Errors.YD_INVALID_CONFIGURATION);
    return _claimRewards(assets, amount, msg.sender, msg.sender, to);
  }

  /// @inheritdoc IPoissonIncentivesController
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to
  ) external override onlyAuthorizedClaimers(msg.sender, user) returns (uint256) {
    require(user != address(0), Errors.YD_INVALID_CONFIGURATION);
    require(to != address(0), Errors.YD_INVALID_CONFIGURATION);
    return _claimRewards(assets, amount, msg.sender, user, to);
  }

  /**
   * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards.
   * @param amount Amount of rewards to claim
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/

  /// @inheritdoc IPoissonIncentivesController
  function setClaimer(address user, address caller) external payable override onlyEmissionManager {
    _authorizedClaimers[user] = caller;
    emit ClaimerSet(user, caller);
  }

  /// @inheritdoc IPoissonIncentivesController
  function getClaimer(address user) external view override returns (address) {
    return _authorizedClaimers[user];
  }

  /// @inheritdoc IPoissonIncentivesController
  function getUserUnclaimedRewards(address _user) external view override returns (uint256) {
    return _usersUnclaimedRewards[_user];
  }

  /// @inheritdoc IPoissonIncentivesController
  function REWARD_TOKEN() external view override returns (address) {
    return Poisson_TOKEN;
  }

  /// @inheritdoc IPoissonIncentivesController
  function DISTRIBUTION_END()
    external
    view
    override(DistributionManager, IPoissonIncentivesController)
    returns (uint256)
  {
    return _distributionEnd;
  }

  /// @inheritdoc IPoissonIncentivesController
  function getAssetData(
    address asset
  )
    public
    view
    override(DistributionManager, IPoissonIncentivesController)
    returns (uint256, uint256, uint256)
  {
    return (
      assets[asset].index,
      assets[asset].emissionPerSecond,
      assets[asset].lastUpdateTimestamp
    );
  }

  /// @inheritdoc IPoissonIncentivesController
  function getUserAssetData(
    address user,
    address asset
  ) public view override(DistributionManager, IPoissonIncentivesController) returns (uint256) {
    return assets[asset].users[user];
  }

  /**
   * @dev returns the revision of the implementation contract
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function PRECISION() external pure override returns (uint8) {
    return _PRECISION;
  }

  /**
   * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards.
   * @param amount Amount of rewards to claim
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function _claimRewards(
    address[] calldata assets,
    uint256 amount,
    address claimer,
    address user,
    address to
  ) internal returns (uint256) {
    if (amount == 0) {
      return 0;
    }
    uint256 unclaimedRewards = _usersUnclaimedRewards[user];
    uint256 length = assets.length;
    DistributionTypes.UserStakeInput[] memory userState = new DistributionTypes.UserStakeInput[](
      length
    );
    for (uint256 i; i < length; ++i) {
      userState[i].underlyingAsset = assets[i];
      (userState[i].stakedByUser, userState[i].totalStaked) = IScaledBalanceToken(assets[i])
        .getScaledUserBalanceAndSupply(user);
    }

    uint256 accruedRewards = _claimRewards(user, userState);
    if (accruedRewards != 0) {
      unclaimedRewards += accruedRewards;
      emit RewardsAccrued(user, accruedRewards);
    }

    if (unclaimedRewards == 0) {
      return 0;
    }

    uint256 amountToClaim = amount > unclaimedRewards ? unclaimedRewards : amount;
    _usersUnclaimedRewards[user] = unclaimedRewards - amountToClaim; // Safe due to the previous line

    if (IERC20(Poisson_TOKEN).balanceOf(address(this)) >= amountToClaim) {
      IERC20(Poisson_TOKEN).safeTransfer(to, amountToClaim);
    }

    emit RewardsClaimed(user, to, claimer, amountToClaim);

    return amountToClaim;
  }
}