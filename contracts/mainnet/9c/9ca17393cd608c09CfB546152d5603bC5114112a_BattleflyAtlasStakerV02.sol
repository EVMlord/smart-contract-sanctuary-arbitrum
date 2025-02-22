// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IAtlasMine.sol";
import "./interfaces/IBattleflyAtlasStakerV02.sol";
import "./interfaces/IVault.sol";
import "./libraries/BattleflyAtlasStakerUtils.sol";
import "./interfaces/vaults/IBattleflyTreasuryFlywheelVault.sol";

/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract BattleflyAtlasStakerV02 is
    IBattleflyAtlasStakerV02,
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // ========== CONSTANTS ==========

    uint96 public constant FEE_DENOMINATOR = 10000;
    uint256 public constant ONE = 1e28;
    address public BATTLEFLY_BOT;

    IERC20Upgradeable public override MAGIC;
    IAtlasMine public ATLAS_MINE;
    IBattleflyTreasuryFlywheelVault public TREASURY_VAULT;

    IAtlasMine.Lock[] public LOCKS;
    IAtlasMine.Lock[] public allowedLocks;

    // ========== Operator States ==========
    uint256 public override currentDepositId;
    uint64 public override currentEpoch;
    uint256 public pausedUntil;
    uint256 public nextExecution;

    /**
     * @dev active positionIds in AtlasMine for this contract.
     *
     */
    EnumerableSetUpgradeable.UintSet private activePositionIds;

    /**
     * @dev Total emissions harvested from Atlas Mine for a particular lock period and epoch
     *      { lock } => { epoch } => { emissions }
     */
    mapping(IAtlasMine.Lock => mapping(uint64 => uint256)) public totalEmissionsAtEpochForLock;

    /**
     * @dev Total amount of magic staked in Atlas Mine for a particular lock period and epoch
     *      { lock } => { epoch } => { magic }
     */
    mapping(IAtlasMine.Lock => mapping(uint64 => uint256)) public totalStakedAtEpochForLock;

    /**
     * @dev Total amount of emissions per share in magic for a particular lock period and epoch
     *      { lock } => { epoch } => { emissionsPerShare }
     */
    mapping(IAtlasMine.Lock => mapping(uint64 => uint256)) public totalPerShareAtEpochForLock;

    /**
     * @dev Total amount of unstaked Magic at a particular epoch
     *      { epoch } => { unstaked magic }
     */
    mapping(uint64 => uint256) public unstakeAmountAtEpoch;

    /**
     * @dev Legion ERC721 NFT stakers data
     *      { tokenId } => { depositor }
     */
    mapping(uint256 => address) public legionStakers;

    /**
     * @dev TREASURE ERC1155 NFT stakers data
     *      { tokenId } => { depositor } => { deposit amount }
     */
    mapping(uint256 => mapping(address => uint256)) public treasureStakers;

    /**
     * @dev Vaultstakes per depositId
     *      { depositId } => { VaultStake }
     */
    mapping(uint256 => VaultStake) public vaultStakes;

    /**
     * @dev Vaults' all deposits
     *      { address } => { depositId }
     */
    mapping(address => EnumerableSetUpgradeable.UintSet) private depositIdByVault;

    /**
     * @dev Magic amount that is not staked to AtlasMine
     *      { Lock } => { unstaked amount }
     */
    mapping(IAtlasMine.Lock => uint256) public unstakedAmount;

    // ========== Access Control States ==========
    mapping(address => bool) public superAdmins;

    /**
     * @dev Whitelisted vaults
     *      { vault address } => { Vault }
     */
    mapping(address => Vault) public vaults;

    // ========== CONTRACT UPGRADE FOR BATCHED HARVESTING (ArbGas limit) ======= //

    uint256 public accruedEpochEmission;
    EnumerableSetUpgradeable.UintSet private atlasPositionsToRemove;

    // Disable initializer to save contract space

    /*  function initialize(
        address _magic,
        address _atlasMine,
        address _treasury,
        address _battleflyBot,
        IAtlasMine.Lock[] memory _allowedLocks
    ) external initializer {
        __ERC1155Holder_init();
        __ERC721Holder_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        require(_magic != address(0), "BattleflyAtlasStaker: invalid address");
        require(_atlasMine != address(0), "BattleflyAtlasStaker: invalid address");
        MAGIC = IERC20Upgradeable(_magic);
        ATLAS_MINE = IAtlasMine(_atlasMine);

        superAdmins[msg.sender] = true;
        LOCKS = [
            IAtlasMine.Lock.twoWeeks,
            IAtlasMine.Lock.oneMonth,
            IAtlasMine.Lock.threeMonths,
            IAtlasMine.Lock.sixMonths,
            IAtlasMine.Lock.twelveMonths
        ];

        nextExecution = block.timestamp;

        setTreasury(_treasury);
        setBattleflyBot(_battleflyBot);
        setAllowedLocks(_allowedLocks);

        approveLegion(true);
        approveTreasure(true);
    }  */

    // ============================== Vault Operations ==============================

    /**
     * @dev deposit an amount of MAGIC in the AtlasStaker for a particular lock period
     */
    function deposit(uint256 _amount, IAtlasMine.Lock _lock)
        external
        override
        onlyWhitelistedVaults
        nonReentrant
        whenNotPaused
        onlyAvailableLock(_lock)
        returns (uint256)
    {
        require(_amount > 0, "BattflyAtlasStaker: cannot deposit 0");
        // Transfer MAGIC from Vault
        MAGIC.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 newDepositId = ++currentDepositId;
        _deposit(newDepositId, _amount, _lock);
        return newDepositId;
    }

    /**
     * @dev withdraw a vaultstake from the AtlasStaker with a specific depositId
     */
    function withdraw(uint256 _depositId) public override nonReentrant whenNotPaused returns (uint256 amount) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        require(vaultStake.vault == msg.sender, "BattleflyAtlasStaker: caller is not a correct vault");
        // withdraw can only happen if the retention period has passed.
        require(canWithdraw(_depositId), "BattleflyAtlasStaker: position is locked");

        amount = vaultStake.amount;
        // Withdraw MAGIC to user
        MAGIC.safeTransfer(msg.sender, amount);

        // claim remaining emissions
        (uint256 emission, ) = getClaimableEmission(_depositId);
        if (emission > 0) {
            amount += _claim(_depositId);
        }

        // Reset vault stake data
        delete vaultStakes[_depositId];
        depositIdByVault[msg.sender].remove(_depositId);
        emit WithdrawPosition(msg.sender, amount, _depositId);
    }

    /**
     * @dev Claim emissions from a vaultstake in the AtlasStaker with a specific depositId
     */
    function claim(uint256 _depositId) public override nonReentrant whenNotPaused returns (uint256 amount) {
        amount = _claim(_depositId);
    }

    /**
     * @dev Request a withdrawal for a specific depositId. This is required because the vaultStake will be restaked in blocks of 2 weeks after the unlock period has passed.
     * This function is used to notify the AtlasStaker that it should not restake the vaultStake on the next iteration and the initial stake becomes unlocked.
     */
    function requestWithdrawal(uint256 _depositId) public override nonReentrant whenNotPaused returns (uint64) {
        VaultStake storage vaultStake = vaultStakes[_depositId];
        require(vaultStake.vault == msg.sender, "BattleflyAtlasStaker: caller is not a correct vault");
        require(vaultStake.retentionUnlock == 0, "BattleflyAtlasStaker: withdrawal already requested");
        // Every epoch is 1 day; We can start requesting for a withdrawal 14 days before the unlock period.
        require(currentEpoch >= (vaultStake.unlockAt - 14), "BattleflyAtlasStaker: position not yet unlockable");

        // We set the retention period before the withdrawal can happen to the nearest epoch in the future
        uint64 retentionUnlock = currentEpoch < vaultStake.unlockAt
            ? vaultStake.unlockAt
            : currentEpoch + (14 - ((currentEpoch - vaultStake.unlockAt) % 14));
        vaultStake.retentionUnlock = retentionUnlock - 1 == currentEpoch ? retentionUnlock + 14 : retentionUnlock;
        unstakeAmountAtEpoch[vaultStake.retentionUnlock - 1] += vaultStake.amount;
        emit RequestWithdrawal(msg.sender, vaultStake.retentionUnlock, _depositId);
        return vaultStake.retentionUnlock;
    }

    // ============================== Super Admin Operations ==============================

    /**
     * @dev Execute the daily cron job to deposit funds to AtlasMine & claim emissions from AtlasMine
     *      The Battlefly CRON BOT will use this function to execute deposit/claim.
     */
    function startHarvestAndDistribute() external onlyBattleflyBot {
        //require(block.timestamp >= nextExecution, "BattleflyAtlasStaker: Executed less than 24h ago");
        // set to 24 hours - 5 minutes to take blockchain tx delays into account.
        nextExecution = block.timestamp + 86100;
        accruedEpochEmission = 0;
    }

    /**
     * @dev Execute the daily cron job to harvest all emissions from AtlasMine
     */
    function executeHarvestAll(uint256 _position, uint256 _batchSize) external onlyBattleflyBot {
        uint256 endPosition = activePositionIds.length() < (_position + _batchSize)
            ? activePositionIds.length()
            : (_position + _batchSize);
        uint256 pendingHarvest = _updateEmissionsForEpoch(_position, endPosition);
        uint256 preHarvest = MAGIC.balanceOf(address(this));
        for (uint256 i = _position; i < endPosition; i++) {
            ATLAS_MINE.harvestPosition(activePositionIds.at(i));
        }
        uint256 harvested = MAGIC.balanceOf(address(this)) - preHarvest;
        require(pendingHarvest == harvested, "BattleflyAtlasStaker: pending harvest and actual harvest are not equal");
    }

    /**
     * @dev Execute the daily cron job to update emissions
     */
    function executeUpdateEmissions() external onlyBattleflyBot {
        // Calculate the accrued emissions per share by (totalEmission * 1e18) / totalStaked
        // Set the total emissions to the accrued emissions of the current epoch + the previous epochs
        for (uint256 k = 0; k < LOCKS.length; k++) {
            uint256 totalStaked = totalStakedAtEpochForLock[LOCKS[k]][currentEpoch];
            if (totalStaked > 0) {
                uint256 accruedRewardsPerShare = (accruedEpochEmission * ONE) / totalStaked;
                totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch] = currentEpoch > 0
                    ? totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch - 1] + accruedRewardsPerShare
                    : accruedRewardsPerShare;
            } else {
                totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch] = currentEpoch > 0
                    ? totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch - 1]
                    : 0;
            }
        }
    }

    /**
     * @dev Execute the daily cron job to withdraw all positions from AtlasMine
     */
    function executeWithdrawAll(uint256 _position, uint256 _batchSize) external onlyBattleflyBot {
        uint256[] memory depositIds = activePositionIds.values();
        uint256 endPosition = depositIds.length < (_position + _batchSize)
            ? depositIds.length
            : (_position + _batchSize);
        for (uint256 i = _position; i < endPosition; i++) {
            (uint256 amount, , , uint256 lockedUntil, , , IAtlasMine.Lock lock) = ATLAS_MINE.userInfo(
                address(this),
                depositIds[i]
            );
            uint256 totalLockedPeriod = lockedUntil + ATLAS_MINE.getVestingTime(lock);

            // If the position is available to withdraw
            if (totalLockedPeriod <= block.timestamp) {
                ATLAS_MINE.withdrawPosition(depositIds[i], type(uint256).max);
                atlasPositionsToRemove.add(depositIds[i]);
                // Directly register for restaking, unless a withdrawal is requested (we correct this in executeDepositAll())
                unstakedAmount[IAtlasMine.Lock.twoWeeks] += uint256(amount);
            }
        }
    }

    /**
     * @dev Execute the daily cron job to deposit all to AtlasMine
     */
    function executeDepositAll() external onlyBattleflyBot {
        // Increment the epoch
        currentEpoch++;
        // Possibly correct the amount to be deposited due to users withdrawing their stake.
        if (unstakedAmount[IAtlasMine.Lock.twoWeeks] >= unstakeAmountAtEpoch[currentEpoch]) {
            unstakedAmount[IAtlasMine.Lock.twoWeeks] -= unstakeAmountAtEpoch[currentEpoch];
        } else {
            //If not enough withdrawals available from current epoch, request more from the next epoch
            unstakeAmountAtEpoch[currentEpoch + 1] += (unstakeAmountAtEpoch[currentEpoch] -
                unstakedAmount[IAtlasMine.Lock.twoWeeks]);
            unstakedAmount[IAtlasMine.Lock.twoWeeks] = 0;
        }

        uint256 unstaked;
        for (uint256 i = 0; i < LOCKS.length; i++) {
            uint256 amount = unstakedAmount[LOCKS[i]];
            if (amount > 0) {
                unstaked += amount;
                MAGIC.safeApprove(address(ATLAS_MINE), amount);
                ATLAS_MINE.deposit(amount, LOCKS[i]);
                activePositionIds.add(ATLAS_MINE.currentId(address(this)));
                unstakedAmount[LOCKS[i]] = 0;
            }
        }
        emit DepositedAllToMine(unstaked);
    }

    /**
     * @dev Finish the daily cron job to deposit funds to AtlasMine & claim emissions from AtlasMine
     *      The Battlefly CRON BOT will use this function to execute deposit/claim.
     */
    function finishHarvestAndDistribute() external onlyBattleflyBot {
        uint256[] memory toRemove = atlasPositionsToRemove.values();
        for (uint256 i = 0; i < toRemove.length; i++) {
            activePositionIds.remove(toRemove[i]);
            atlasPositionsToRemove.remove(toRemove[i]);
        }
    }

    /**
     * @dev Approve TREASURE ERC1155 NFT transfer to deposit into AtlasMine contract
     */
    function approveTreasure(bool _approve) public onlySuperAdmin {
        getTREASURE().setApprovalForAll(address(ATLAS_MINE), _approve);
    }

    /**
     * @dev Approve LEGION ERC721 NFT transfer to deposit into AtlasMine contract
     */
    function approveLegion(bool _approve) public onlySuperAdmin {
        getLEGION().setApprovalForAll(address(ATLAS_MINE), _approve);
    }

    /**
     * @dev Stake TREASURE ERC1155 NFT
     */
    function stakeTreasure(uint256 _tokenId, uint256 _amount) external onlySuperAdmin nonReentrant {
        require(_amount > 0, "BattleflyAtlasStaker: Invalid TREASURE amount");

        // Caller's balance check already implemented in _safeTransferFrom() in ERC1155Upgradeable contract
        getTREASURE().safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        treasureStakers[_tokenId][msg.sender] += _amount;

        // Token Approval is already done in constructor
        ATLAS_MINE.stakeTreasure(_tokenId, _amount);
        emit StakedTreasure(msg.sender, _tokenId, _amount);
    }

    /**
     * @dev Unstake TREASURE ERC1155 NFT
     */
    function unstakeTreasure(uint256 _tokenId, uint256 _amount) external onlySuperAdmin nonReentrant {
        require(_amount > 0, "BattleflyAtlasStaker: Invalid TREASURE amount");
        require(treasureStakers[_tokenId][msg.sender] >= _amount, "BattleflyAtlasStaker: Invalid TREASURE amount");
        // Unstake TREASURE from AtlasMine
        ATLAS_MINE.unstakeTreasure(_tokenId, _amount);

        // Transfer TREASURE to the staker
        getTREASURE().safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        treasureStakers[_tokenId][msg.sender] -= _amount;
        emit UnstakedTreasure(msg.sender, _tokenId, _amount);
    }

    /**
     * @dev Stake LEGION ERC721 NFT
     */
    function stakeLegion(uint256 _tokenId) external onlySuperAdmin nonReentrant {
        // TokenId ownership validation is already implemented in safeTransferFrom function
        getLEGION().safeTransferFrom(msg.sender, address(this), _tokenId, "");
        legionStakers[_tokenId] = msg.sender;

        // Token Approval is already done in constructor
        ATLAS_MINE.stakeLegion(_tokenId);
        emit StakedLegion(msg.sender, _tokenId);
    }

    /**
     * @dev Unstake LEGION ERC721 NFT
     */
    function unstakeLegion(uint256 _tokenId) external onlySuperAdmin nonReentrant {
        require(legionStakers[_tokenId] == msg.sender, "BattleflyAtlasStaker: Invalid staker");
        // Unstake LEGION from AtlasMine
        ATLAS_MINE.unstakeLegion(_tokenId);

        // Transfer LEGION to the staker
        getLEGION().safeTransferFrom(address(this), msg.sender, _tokenId, "");
        legionStakers[_tokenId] = address(0);
        emit UnstakedLegion(msg.sender, _tokenId);
    }

    // ============================== Owner Operations ==============================

    /**
     * @dev Add super admin permission
     */
    function addSuperAdmin(address _admin) public onlyOwner {
        require(!superAdmins[_admin], "BattleflyAtlasStaker: admin already exists");
        superAdmins[_admin] = true;
        emit AddedSuperAdmin(_admin);
    }

    /**
     * @dev Batch adding super admin permission
     */
    function addSuperAdmins(address[] calldata _admins) external onlyOwner {
        for (uint256 i = 0; i < _admins.length; i++) {
            addSuperAdmin(_admins[i]);
        }
    }

    /**
     * @dev Remove super admin permission
     */
    function removeSuperAdmin(address _admin) public onlyOwner {
        require(superAdmins[_admin], "BattleflyAtlasStaker: admin does not exist");
        superAdmins[_admin] = false;
        emit RemovedSuperAdmin(_admin);
    }

    /**
     * @dev Batch removing super admin permission
     */
    function removeSuperAdmins(address[] calldata _admins) external onlyOwner {
        for (uint256 i = 0; i < _admins.length; i++) {
            removeSuperAdmin(_admins[i]);
        }
    }

    /**
     * @dev Add vault address
     */
    function addVault(address _vault, Vault calldata _vaultData) public onlyOwner {
        require(!vaults[_vault].enabled, "BattleflyAtlasStaker: vault is already added");
        require(_vaultData.fee + _vaultData.claimRate == FEE_DENOMINATOR, "BattleflyAtlasStaker: invalid vault info");

        Vault storage vault = vaults[_vault];
        vault.fee = _vaultData.fee;
        vault.claimRate = _vaultData.claimRate;
        vault.enabled = true;
        emit AddedVault(_vault, vault.fee, vault.claimRate);
    }

    /**
     * @dev Remove vault address
     */
    function removeVault(address _vault) public onlyOwner {
        Vault storage vault = vaults[_vault];
        require(vault.enabled, "BattleflyAtlasStaker: vault does not exist");
        vault.enabled = false;
        emit RemovedVault(_vault);
    }

    /**
     * @dev Set allowed locks
     */
    function setAllowedLocks(IAtlasMine.Lock[] memory _locks) public onlyOwner {
        allowedLocks = _locks;
    }

    /**
     * @dev Set treasury wallet address
     */
    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "BattleflyAtlasStaker: invalid address");
        TREASURY_VAULT = IBattleflyTreasuryFlywheelVault(_treasury);
        emit SetTreasury(_treasury);
    }

    /**
     * @dev Set daily bot address
     */
    function setBattleflyBot(address _battleflyBot) public onlyOwner {
        require(_battleflyBot != address(0), "BattleflyAtlasStaker: invalid address");
        BATTLEFLY_BOT = _battleflyBot;
        emit SetBattleflyBot(_battleflyBot);
    }

    function setPause(bool _paused) external override onlyOwner {
        pausedUntil = _paused ? block.timestamp + 48 hours : 0;
        emit SetPause(_paused);
    }

    // ============================== VIEW ==============================

    /**
     * @dev Validate the lock period
     */
    function isValidLock(IAtlasMine.Lock _lock) public view returns (bool) {
        for (uint256 i = 0; i < allowedLocks.length; i++) {
            if (allowedLocks[i] == _lock) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Get AtlasMine TREASURE ERC1155 NFT address
     */
    function getTREASURE() public view returns (IERC1155Upgradeable) {
        return IERC1155Upgradeable(ATLAS_MINE.treasure());
    }

    /**
     * @dev Get AtlasMine LEGION ERC721 NFT address
     */
    function getLEGION() public view returns (IERC721Upgradeable) {
        return IERC721Upgradeable(ATLAS_MINE.legion());
    }

    /**
     * @dev Get Unstaked MAGIC amount
     */
    function getUnstakedAmount() public view returns (uint256 amount) {
        IAtlasMine.Lock[] memory locks = LOCKS;
        for (uint256 i = 0; i < locks.length; i++) {
            amount += unstakedAmount[locks[i]];
        }
    }

    /**
     * @dev Get claimable MAGIC emission.
     * Emissions are:
     *      Emissions from normal lock period +
     *      Emissions from retention period -
     *      Already received emissions
     */
    function getClaimableEmission(uint256 _depositId) public view override returns (uint256 emission, uint256 fee) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        if (currentEpoch > 0) {
            uint64 retentionLock = vaultStake.retentionUnlock == 0 ? currentEpoch + 1 : vaultStake.retentionUnlock;
            uint64 x = vaultStake.retentionUnlock == 0 || vaultStake.retentionUnlock != vaultStake.unlockAt ? 0 : 1;
            emission =
                _getEmissionsForPeriod(vaultStake.amount, vaultStake.lockAt, vaultStake.unlockAt - x, vaultStake.lock) +
                _getEmissionsForPeriod(vaultStake.amount, vaultStake.unlockAt, retentionLock, vaultStake.lock) -
                vaultStake.paidEmission;
        }
        Vault memory vault = vaults[vaultStake.vault];
        fee = (emission * vault.fee) / FEE_DENOMINATOR;
        emission -= fee;
    }

    /**
     * @dev Get staked amount
     */
    function getDepositedAmount(uint256[] memory _depositIds) public view returns (uint256 amount) {
        for (uint256 i = 0; i < _depositIds.length; i++) {
            amount += vaultStakes[_depositIds[i]].amount;
        }
    }

    /**
     * @dev Get allowed locks
     */
    function getAllowedLocks() public view override returns (IAtlasMine.Lock[] memory) {
        return allowedLocks;
    }

    /**
     * @dev Get vault staked data
     */
    function getVaultStake(uint256 _depositId) public view override returns (VaultStake memory) {
        return vaultStakes[_depositId];
    }

    /**
     * @dev Gets the lock period in epochs
     */
    function getLockPeriod(IAtlasMine.Lock _lock) external view override returns (uint64 epoch) {
        return BattleflyAtlasStakerUtils.getLockPeriod(_lock, ATLAS_MINE) / 1 days;
    }

    /**
     * @dev Check if a vaultStake can be withdrawn
     */
    function canWithdraw(uint256 _depositId) public view override returns (bool withdrawable) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        withdrawable = (vaultStake.retentionUnlock > 0) && (vaultStake.retentionUnlock <= currentEpoch);
    }

    /**
     * @dev Check if a vaultStake can request a withdrawal
     */
    function canRequestWithdrawal(uint256 _depositId) public view override returns (bool requestable) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        requestable = (vaultStake.retentionUnlock == 0) && (currentEpoch >= (vaultStake.unlockAt - 14));
    }

    /**
     * @dev Get the depositIds of a user
     */
    function depositIdsOfVault(address vault) public view override returns (uint256[] memory depositIds) {
        return depositIdByVault[vault].values();
    }

    /**
     * @dev Get the number of active AtlasMine positions
     */
    function activeAtlasPositionSize() public view override returns (uint256) {
        return activePositionIds.length();
    }

    // ============================== Internal ==============================

    /**
     * @dev recalculate and update the emissions per share per lock period and per epoch
     *      1 share is 1 wei of Magic.
     */
    function _updateEmissionsForEpoch(uint256 position, uint256 endPosition) private returns (uint256 totalEmission) {
        uint256[] memory positionIds = activePositionIds.values();

        // Total emissions of the current epoch are at least as much as the total emissions of the previous epoch
        if (position == 0) {
            for (uint256 i = 0; i < LOCKS.length; i++) {
                totalEmissionsAtEpochForLock[LOCKS[i]][currentEpoch] = currentEpoch > 0
                    ? totalEmissionsAtEpochForLock[LOCKS[i]][currentEpoch - 1]
                    : 0;
            }
        }

        // Calculate the total amount of pending emissions and the total deposited amount for each lock period in the current epoch
        for (uint256 j = position; j < endPosition; j++) {
            uint256 pendingRewards = ATLAS_MINE.pendingRewardsPosition(address(this), positionIds[j]);
            (, uint256 currentAmount, , , , , IAtlasMine.Lock _lock) = ATLAS_MINE.userInfo(
                address(this),
                positionIds[j]
            );
            totalEmission += pendingRewards;
            accruedEpochEmission += pendingRewards;
            totalEmissionsAtEpochForLock[_lock][currentEpoch] += pendingRewards;
            totalStakedAtEpochForLock[_lock][currentEpoch] += currentAmount;
        }
    }

    /**
     * @dev get the total amount of emissions of a certain period between two epochs.
     */
    function _getEmissionsForPeriod(
        uint256 amount,
        uint64 startEpoch,
        uint64 stopEpoch,
        IAtlasMine.Lock lock
    ) private view returns (uint256 emissions) {
        if (stopEpoch >= startEpoch && currentEpoch >= startEpoch) {
            uint256 totalEmissions = (amount * totalPerShareAtEpochForLock[lock][currentEpoch - 1]);
            uint256 emissionsTillExclusion = (amount * totalPerShareAtEpochForLock[lock][stopEpoch - 1]);
            uint256 emissionsTillInclusion = (amount * totalPerShareAtEpochForLock[lock][startEpoch - 1]);
            uint256 emissionsFromExclusion = emissionsTillExclusion > 0 ? (totalEmissions - emissionsTillExclusion) : 0;
            emissions = (totalEmissions - emissionsFromExclusion - emissionsTillInclusion) / ONE;
        }
    }

    /**
     * @dev Deposit MAGIC to AtlasMine
     */
    function _deposit(
        uint256 _depositId,
        uint256 _amount,
        IAtlasMine.Lock _lock
    ) private returns (uint256) {
        // We only deposit to AtlasMine in the next epoch. We can unlock after the lock period has passed.
        uint64 lockAt = currentEpoch + 1;
        uint64 unlockAt = currentEpoch + 1 + (BattleflyAtlasStakerUtils.getLockPeriod(_lock, ATLAS_MINE) / 1 days);

        vaultStakes[_depositId] = VaultStake(lockAt, unlockAt, 0, _amount, 0, msg.sender, _lock);
        // Updated unstaked MAGIC amount
        unstakedAmount[_lock] += _amount;
        depositIdByVault[msg.sender].add(_depositId);
        emit NewDeposit(msg.sender, _amount, unlockAt, _depositId);
        return unlockAt;
    }

    /**
     * @dev Claim emissions for a depositId
     */
    function _claim(uint256 _depositId) internal returns (uint256) {
        VaultStake storage vaultStake = vaultStakes[_depositId];
        require(vaultStake.vault == msg.sender, "BattleflyAtlasStaker: caller is not a correct vault");

        (uint256 emission, uint256 fee) = getClaimableEmission(_depositId);
        if (emission > 0) {
            MAGIC.safeTransfer(msg.sender, emission);
            if (fee > 0) {
                MAGIC.approve(address(TREASURY_VAULT), fee);
                TREASURY_VAULT.topupMagic(fee);
            }
            uint256 amount = emission + fee;
            vaultStake.paidEmission += amount;
            emit ClaimEmission(msg.sender, emission, _depositId);
        }
        return emission;
    }

    // ============================== Modifiers ==============================

    modifier onlySuperAdmin() {
        require(superAdmins[msg.sender], "BattleflyAtlasStaker: caller is not a super admin");
        _;
    }

    modifier onlyWhitelistedVaults() {
        require(vaults[msg.sender].enabled, "BattleflyAtlasStaker: caller is not whitelisted");
        _;
    }

    modifier onlyAvailableLock(IAtlasMine.Lock _lock) {
        require(isValidLock(_lock), "BattleflyAtlasStaker: invalid lock period");
        _;
    }

    modifier onlyBattleflyBot() {
        require(msg.sender == BATTLEFLY_BOT, "BattleflyAtlasStaker: caller is not a battlefly bot");
        _;
    }

    modifier whenNotPaused() {
        require(block.timestamp > pausedUntil, "BattleflyAtlasStaker: contract paused");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
     * - input must fit into 8 bits.
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
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IAtlasMine {
    enum Lock {
        twoWeeks,
        oneMonth,
        threeMonths,
        sixMonths,
        twelveMonths
    }
    struct UserInfo {
        uint256 originalDepositAmount;
        uint256 depositAmount;
        uint256 lpAmount;
        uint256 lockedUntil;
        uint256 vestingLastUpdate;
        int256 rewardDebt;
        Lock lock;
    }

    function treasure() external view returns (address);

    function legion() external view returns (address);

    function unlockAll() external view returns (bool);

    function boosts(address user) external view returns (uint256);

    function userInfo(address user, uint256 depositId)
        external
        view
        returns (
            uint256 originalDepositAmount,
            uint256 depositAmount,
            uint256 lpAmount,
            uint256 lockedUntil,
            uint256 vestingLastUpdate,
            int256 rewardDebt,
            Lock lock
        );

    function getLockBoost(Lock _lock) external pure returns (uint256 boost, uint256 timelock);

    function getVestingTime(Lock _lock) external pure returns (uint256 vestingTime);

    function stakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function unstakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function stakeLegion(uint256 _tokenId) external;

    function unstakeLegion(uint256 _tokenId) external;

    function withdrawPosition(uint256 _depositId, uint256 _amount) external returns (bool);

    function withdrawAll() external;

    function pendingRewardsAll(address _user) external view returns (uint256 pending);

    function deposit(uint256 _amount, Lock _lock) external;

    function harvestAll() external;

    function harvestPosition(uint256 _depositId) external;

    function currentId(address _user) external view returns (uint256);

    function pendingRewardsPosition(address _user, uint256 _depositId) external view returns (uint256);

    function getAllUserDepositIds(address) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IAtlasMine.sol";

interface IBattleflyAtlasStakerV02 {
    struct Vault {
        uint16 fee;
        uint16 claimRate;
        bool enabled;
    }

    struct VaultStake {
        uint64 lockAt;
        uint64 unlockAt;
        uint64 retentionUnlock;
        uint256 amount;
        uint256 paidEmission;
        address vault;
        IAtlasMine.Lock lock;
    }

    function MAGIC() external returns (IERC20Upgradeable);

    function deposit(uint256, IAtlasMine.Lock) external returns (uint256);

    function withdraw(uint256) external returns (uint256);

    function claim(uint256) external returns (uint256);

    function requestWithdrawal(uint256) external returns (uint64);

    function currentDepositId() external view returns (uint256);

    function getAllowedLocks() external view returns (IAtlasMine.Lock[] memory);

    function getVaultStake(uint256) external view returns (VaultStake memory);

    function getClaimableEmission(uint256) external view returns (uint256, uint256);

    function canWithdraw(uint256 _depositId) external view returns (bool withdrawable);

    function canRequestWithdrawal(uint256 _depositId) external view returns (bool requestable);

    function currentEpoch() external view returns (uint64 epoch);

    function getLockPeriod(IAtlasMine.Lock) external view returns (uint64 epoch);

    function setPause(bool _paused) external;

    function depositIdsOfVault(address vault) external view returns (uint256[] memory depositIds);

    function activeAtlasPositionSize() external view returns (uint256);

    // ========== Events ==========
    event AddedSuperAdmin(address who);
    event RemovedSuperAdmin(address who);

    event AddedVault(address indexed vault, uint16 fee, uint16 claimRate);
    event RemovedVault(address indexed vault);

    event StakedTreasure(address staker, uint256 tokenId, uint256 amount);
    event UnstakedTreasure(address staker, uint256 tokenId, uint256 amount);

    event StakedLegion(address staker, uint256 tokenId);
    event UnstakedLegion(address staker, uint256 tokenId);

    event SetTreasury(address treasury);
    event SetBattleflyBot(address bot);

    event NewDeposit(address indexed vault, uint256 amount, uint256 unlockedAt, uint256 indexed depositId);
    event WithdrawPosition(address indexed vault, uint256 amount, uint256 indexed depositId);
    event ClaimEmission(address indexed vault, uint256 amount, uint256 indexed depositId);
    event RequestWithdrawal(address indexed vault, uint64 withdrawalEpoch, uint256 indexed depositId);

    event DepositedAllToMine(uint256 amount);

    event SetPause(bool paused);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IVault {
    function isAutoCompounded(uint256) external view returns (bool);

    function updatePosition(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAtlasMine.sol";

library BattleflyAtlasStakerUtils {
    /**
     * @dev Get lock period
     *      Need to consider about adding 1 more day to lock period regarding the daily cron job
     */
    function getLockPeriod(IAtlasMine.Lock _lock, IAtlasMine ATLAS_MINE) external pure returns (uint64) {
        if (_lock == IAtlasMine.Lock.twoWeeks) {
            return 14 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.oneMonth) {
            return 30 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.threeMonths) {
            return 90 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.sixMonths) {
            return 180 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.twelveMonths) {
            return 365 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }

        revert("BattleflyAtlasStaker: Invalid Lock");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "../IAtlasMine.sol";

interface IBattleflyTreasuryFlywheelVault {
    struct UserStake {
        uint64 lockAt;
        uint256 amount;
        address owner;
        IAtlasMine.Lock lock;
    }

    function deposit(uint128 _amount) external returns (uint256 atlasStakerDepositId);

    function withdraw(uint256[] memory _depositIds, address user) external returns (uint256 amount);

    function withdrawAll(address user) external returns (uint256 amount);

    function requestWithdrawal(uint256[] memory _depositIds) external;

    function claim(uint256 _depositId, address user) external returns (uint256 emission);

    function claimAll(address user) external returns (uint256 amount);

    function claimAllAndRestake() external returns (uint256 amount);

    function topupMagic(uint256 amount) external;

    function withdrawLiquidAmount(uint256 amount) external;

    function getAllowedLocks() external view returns (IAtlasMine.Lock[] memory);

    function getClaimableEmission(uint256) external view returns (uint256);

    function canRequestWithdrawal(uint256 _depositId) external view returns (bool requestable);

    function canWithdraw(uint256 _depositId) external view returns (bool withdrawable);

    function initialUnlock(uint256 _depositId) external view returns (uint64 epoch);

    function retentionUnlock(uint256 _depositId) external view returns (uint64 epoch);

    function getCurrentEpoch() external view returns (uint64 epoch);

    function getDepositIds() external view returns (uint256[] memory ids);

    function getName() external pure returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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