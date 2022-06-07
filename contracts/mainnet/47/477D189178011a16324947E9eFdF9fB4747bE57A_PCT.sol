// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/Bank/IHandle.sol";
import "../interfaces/Bank/ITreasury.sol";
import "../interfaces/Bank/IPCT.sol";
import "../interfaces/Bank/IPCTProtocolInterface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./HandlePausable.sol";

/**
 * @dev Implements a scalable pool for keeping track of user collateral shares
        and an interface to interact with bridges to external investment
        protocols.
 */
contract PCT is
    IPCT,
    Initializable,
    UUPSUpgradeable,
    HandlePausable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string internal constant notAnInterface = "PCT: not an interface";
    string internal constant accessDenied = "PCT: access denied";

    /** @dev The Handle contract interface */
    IHandle private handle;
    /** @dev The Treasury contract interface */
    ITreasury private treasury;

    /** @dev mapping(collateral => PCT pool data) */
    mapping(address => Pool) private pools;
    /** @dev Ratio of accrued interest sent to protocol, where 1 ETH = 100% */
    uint256 public override protocolFee;

    modifier validInterface(address collateralToken, address pia) {
        require(pools[collateralToken].protocolInterfaces[pia], notAnInterface);
        _;
    }

    /** @dev Proxy initialisation function */
    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    receive() external payable {}

    /**
     * @dev Setter for Handle contract reference
     * @param _handle The Handle contract address
     */
    function setHandleContract(address _handle) public override onlyOwner {
        handle = IHandle(_handle);
        treasury = ITreasury(handle.treasury());
    }

    /** @dev Getter for Handle contract address */
    function handleAddress() public view override returns (address) {
        return address(handle);
    }

    /**
     * @dev Stakes tokens
     * @param account The account to stake with
     * @param amount The amount to stake
     * @param fxToken The deposit fxToken
     * @param collateralToken The pool token address
     */
    function stake(
        address account,
        uint256 amount,
        address fxToken,
        address collateralToken
    ) external override notPaused nonReentrant returns (uint256 errorCode) {
        require(
            msg.sender == account || msg.sender == address(treasury),
            accessDenied
        );
        if (amount == 0) return 1;
        uint256 vaultCollateral =
            handle.getCollateralBalance(account, collateralToken, fxToken);
        // User must hold enough collateral.
        if (vaultCollateral < amount) return 2;
        // Transfer must not exceed per-user upper bound.
        uint256 maxDueToUpperBound =
            vaultCollateral.mul(handle.pctCollateralUpperBound()).div(1 ether);
        // Assert that current stake does not exceed max for vault.
        uint256 stake = balanceOfStake(account, fxToken, collateralToken);
        if (stake >= maxDueToUpperBound) return 3;
        // Calculate max stake remaining and cap amount if needed.
        uint256 maxStakeRemaining = maxDueToUpperBound.sub(stake);
        if (amount > maxStakeRemaining) amount = maxStakeRemaining;
        // Proceed with staking.
        Pool storage pool = pools[collateralToken];
        Deposit storage deposit = pool.deposits[account][fxToken];
        checkUpdateConfirmedDeposit(pool, deposit);
        // Withdraw existing collateral rewards, if any.
        _claimInterest(account, fxToken, collateralToken);
        // Update total deposits.
        pool.totalDeposits = pool.totalDeposits.add(amount);
        // Update deposit properties.
        deposit.amount_flagged = deposit.amount_flagged.add(amount);
        deposit.S = pool.S;
        deposit.N = pool.N.add(1);
        emit Stake(account, fxToken, collateralToken, amount);
        return 0;
    }

    /**
     * @dev Will do one of two things:
            1) Notifies PCT that staked collateral might no longer be
               available in Treasury if already invested.
            2) If the staked amount hasn't been invested yet,
               simply unstake it.
     * @param account The account to unstake with
     * @param amount The amount to unstake
     * @param fxToken The deposit fxToken
     * @param collateralToken The pool token address
     */
    function unstake(
        address account,
        uint256 amount,
        address fxToken,
        address collateralToken
    ) external override notPaused nonReentrant returns (uint256 errorCode) {
        require(
            msg.sender == account || msg.sender == address(treasury),
            accessDenied
        );
        uint256 stakedAmount =
            balanceOfStake(account, fxToken, collateralToken);
        if (amount > stakedAmount) amount = stakedAmount;
        if (amount == 0) return 1;
        Pool storage pool = pools[collateralToken];
        Deposit storage deposit = pool.deposits[account][fxToken];
        checkUpdateConfirmedDeposit(pool, deposit);
        // Withdraw existing collateral rewards, if any.
        _claimInterest(account, fxToken, collateralToken);
        // Accrue new interest from this point.
        deposit.S = pool.S;
        if (amount <= deposit.amount_flagged) {
            // Remove only flagged amount, which hasn't been invested yet.
            deposit.amount_flagged = deposit.amount_flagged.sub(amount);
            // Total deposits should only subtract flagged deposit, as
            // the confirmed deposit is subtracted during investment withdrawal.
            pool.totalDeposits = pool.totalDeposits.sub(amount);
        } else {
            uint256 unstakeConfirmed = amount.sub(deposit.amount_flagged);
            pool.totalDeposits = pool.totalDeposits.sub(deposit.amount_flagged);
            deposit.amount_flagged = 0;
            deposit.amount_confirmed = deposit.amount_confirmed.sub(
                unstakeConfirmed
            );
        }
        emit Unstake(account, fxToken, collateralToken, amount);
        return 0;
    }

    /**
     * @dev Claims interest from pool
     * @param fxToken The deposit fxToken
     * @param collateralToken The pool token address
     */
    function claimInterest(address fxToken, address collateralToken)
        external
        override
        notPaused
        nonReentrant
    {
        Pool storage pool = pools[collateralToken];
        Deposit storage deposit = pool.deposits[msg.sender][fxToken];
        checkUpdateConfirmedDeposit(pool, deposit);
        uint256 claimed = _claimInterest(msg.sender, fxToken, collateralToken);
        require(claimed > 0, "PCT: no claimable interest");
        // Update deposit S value so new interest is accrued from this point.
        deposit.S = pool.S;
    }

    /**
     * @dev Claims interest from pool
     * @param account The account to claim interest with
     * @param fxToken The deposit fxToken
     * @param collateralToken The pool token address
     */
    function _claimInterest(
        address account,
        address fxToken,
        address collateralToken
    ) private returns (uint256 claimed) {
        Pool storage pool = pools[collateralToken];
        Deposit storage deposit = pool.deposits[account][fxToken];
        // Withdraw all collateral rewards.
        claimed = _balanceOfClaimableInterest(pool, deposit);
        if (claimed == 0) return 0;
        // Reduce from total accrued.
        pool.totalAccrued = pool.totalAccrued.sub(claimed);
        // Increase collateral balance.
        handle.updateCollateralBalance(
            account,
            claimed,
            fxToken,
            collateralToken,
            true
        );
        emit ClaimInterest(account, collateralToken, claimed);
    }

    /**
     * @dev Sets a protocol interface as valid
     * @param collateralToken The pool token
     * @param pia The protocol interface address
     */
    function setProtocolInterface(address collateralToken, address pia)
        external
        override
        onlyOwner
    {
        IPCTProtocolInterface pi = IPCTProtocolInterface(pia);
        require(
            pi.investedToken() == collateralToken,
            "PCT: interface token mismatch"
        );
        Pool storage pool = pools[collateralToken];
        require(!pool.protocolInterfaces[pia], "PCT: interface already set");
        pool.protocolInterfaces[pia] = true;
        emit SetProtocolInterface(pia, collateralToken);
    }

    /**
     * @dev Removes a protocol interface
     * @param collateralToken The pool token
     * @param pia The protocol interface address
     */
    function unsetProtocolInterface(address collateralToken, address pia)
        external
        override
        onlyOwner
    {
        Pool storage pool = pools[collateralToken];
        require(pool.protocolInterfaces[pia], notAnInterface);
        pools[collateralToken].protocolInterfaces[pia] = false;
        emit UnsetProtocolInterface(pia, collateralToken);
    }

    /**
     * @dev Claims accrued interest from external protocol.
     * @param collateralToken The pool token
     * @param pia The protocol interface address
     */
    function claimProtocolInterest(address collateralToken, address pia)
        external
        override
        onlyOwner
        nonReentrant
        validInterface(collateralToken, pia)
    {
        uint256 balanceA = IERC20(collateralToken).balanceOf(address(treasury));
        IPCTProtocolInterface pi = IPCTProtocolInterface(pia);
        uint256 amount = pi.withdrawRewards();
        uint256 balanceB = IERC20(collateralToken).balanceOf(address(treasury));
        require(balanceB == balanceA.add(amount), "PCT: claim transfer failed");
        distributeInterest(collateralToken, amount);
        ensureUpperBoundLimit(pi, collateralToken);
        emit ProtocolClaimInterest(pia, collateralToken, amount);
    }

    /**
     * @dev Deposits funds into a protocol as an investment
     * @param collateralToken The collateral to deposit
     * @param pia The protocol interface address
     * @param ratio The ratio (0 to 1, 18 decimals) of available collateral
             to deposit into the protocol. 
     */
    function depositProtocolFunds(
        address collateralToken,
        address pia,
        uint256 ratio
    )
        external
        override
        onlyOwner
        nonReentrant
        validInterface(collateralToken, pia)
    {
        require(ratio > 0 && ratio <= 1 ether, "PCT: invalid ratio (0<R<=1)");
        Pool storage pool = pools[collateralToken];
        require(pool.totalDeposits > 0, "PCT: no funds available");
        uint256 amount = pool.totalDeposits.mul(ratio).div(1 ether);
        // Request withdraw via protocol interface, which will call returnFunds.
        IPCTProtocolInterface(pia).deposit(amount);
        // Increase investments; decrease deposits.
        pool.totalInvestments = pool.totalInvestments.add(amount);
        pool.protocolInvestments[pia] = pool.protocolInvestments[pia].add(
            amount
        );
        pool.totalDeposits = pool.totalDeposits.sub(amount);
        // Total amount staked during investment. Used to calculate shares.
        pool.totalDepositsAtInvestment = pool.totalDeposits.add(
            pool.totalInvestments
        );
        // Increase N to confirm recent deposits.
        pool.N = pool.N.add(1);
        emit ProtocolDepositFunds(pia, collateralToken, amount);
    }

    /**
     * @dev Withdraws invested funds from a protocol
     * @param collateralToken The collateral to withdraw
     * @param pia The protocol interface address
     * @param amount The amount of collateral to withdraw
     */
    function withdrawProtocolFunds(
        address collateralToken,
        address pia,
        uint256 amount
    ) external override onlyOwner nonReentrant {
        Pool storage pool = pools[collateralToken];
        uint256 currentInvestments = pool.protocolInvestments[pia];
        require(currentInvestments > 0, "PCT: not invested");
        IPCTProtocolInterface pi = IPCTProtocolInterface(pia);
        // Withdraw any unstaked collateral first.
        ensureUpperBoundLimit(pi, collateralToken);
        // Cap amount to totalInvestments.
        uint256 totalInvestments = pool.totalInvestments;
        if (amount > totalInvestments) amount = totalInvestments;
        // Request withdraw via protocol interface, which will call returnFunds.
        pi.withdraw(amount);
        // Decrease investments; increase deposits.
        pool.totalInvestments = totalInvestments.sub(amount);
        pool.protocolInvestments[pia] = currentInvestments.sub(amount);
        pool.totalDeposits = pool.totalDeposits.add(amount);
    }

    /**
     * @dev Requests funds from Treasury for a PCT protocol interface
     * @param collateralToken The pool token invested
     * @param requestedToken The token to request (protocol token or collateral token)
     * @param amount The amount of token to request
     */
    function requestTreasuryFunds(
        address collateralToken,
        address requestedToken,
        uint256 amount
    ) external override notPaused validInterface(collateralToken, msg.sender) {
        treasury.requestFundsPCT(requestedToken, amount);
        IERC20(requestedToken).safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Returns funds to Treasury from a PCT protocol interface
     * @param collateralToken The pool token invested
     * @param returnedToken The token to return (protocol token or collateral)
     * @param amount The amount of token to send
     */
    function returnTreasuryFunds(
        address collateralToken,
        address returnedToken,
        uint256 amount
    ) external override notPaused validInterface(collateralToken, msg.sender) {
        IERC20(returnedToken).safeTransferFrom(
            msg.sender,
            address(treasury),
            amount
        );
        emit ProtocolReturnFunds(msg.sender, returnedToken, amount);
    }

    function setProtocolFee(uint256 ratio) external override onlyOwner {
        require(ratio <= 1 ether, "PCT: invalid ratio (0<=R<=1)");
        protocolFee = ratio;
    }

    /**
     * @dev Distributes interest for stakers
     * @param collateralToken The pool token
     * @param amount The amount to distribute
     */
    function distributeInterest(address collateralToken, uint256 amount)
        private
    {
        // Calculate and transfer fee.
        uint256 fee = amount.mul(protocolFee).div(1 ether);
        treasury.requestFundsPCT(collateralToken, fee);
        IERC20(collateralToken).safeTransfer(handle.FeeRecipient(), fee);
        amount = amount.sub(fee);
        // Distribute pool rewards.
        Pool storage pool = pools[collateralToken];
        uint256 deltaS =
            amount.mul(1 ether).div(pool.totalDepositsAtInvestment);
        pool.S = pool.S.add(deltaS);
        pool.totalAccrued = pool.totalAccrued.add(amount);
    }

    /**
     * @dev Checks the Treasury's collateral balance and total invested funds
            against maximum upper bound and withdraws from external protocol
            into Treasury if needed.
     * @param pi The PCT protocol interface
     * @param collateralToken The pool token address
     */
    function ensureUpperBoundLimit(
        IPCTProtocolInterface pi,
        address collateralToken
    ) private {
        Pool storage pool = pools[collateralToken];
        address pia = address(pi);
        uint256 totalInvested = pool.totalInvestments;
        uint256 totalFunds =
            IERC20(collateralToken).balanceOf(address(treasury)).add(
                totalInvested
            );
        uint256 upperBound = handle.pctCollateralUpperBound();
        uint256 maxInvestmentAmount = totalFunds.mul(upperBound).div(1 ether);
        if (totalInvested <= maxInvestmentAmount) return;
        // Upper bound limit has been exceeded; withdraw from external protocol.
        uint256 diff = totalInvested.sub(maxInvestmentAmount);
        assert(pool.protocolInvestments[pia] >= diff);
        pi.withdraw(diff);
        pool.totalInvestments = pool.totalInvestments.sub(diff);
        pool.protocolInvestments[pia] = pool.protocolInvestments[pia].sub(diff);
    }

    /**
     * @dev retrieves the total staked amount for account vault
     * @param account The address to fetch balance from
     * @param fxToken The deposit fxToken
     * @param collateralToken The pool token address
     */
    function balanceOfStake(
        address account,
        address fxToken,
        address collateralToken
    ) public view override returns (uint256 amount) {
        Deposit storage deposit =
            pools[collateralToken].deposits[account][fxToken];
        return deposit.amount_confirmed.add(deposit.amount_flagged);
    }

    /**
     * @dev Retrieves account's current claimable interest amount
     * @param account The address to fetch claimable interest from
     * @param fxToken The deposit fxToken
     * @param collateralToken The pool token address
     */
    function balanceOfClaimableInterest(
        address account,
        address fxToken,
        address collateralToken
    ) public view override returns (uint256 amount) {
        Pool storage pool = pools[collateralToken];
        Deposit storage deposit = pool.deposits[account][fxToken];
        return _balanceOfClaimableInterest(pool, deposit);
    }

    /**
     * @dev Getter for user's balance of claimable interest
     * @param pool The pool reference
     * @param deposit The deposit reference
     */
    function _balanceOfClaimableInterest(
        Pool storage pool,
        Deposit storage deposit
    ) private view returns (uint256 amount) {
        // Return zero if pool was not initialised.
        if (pool.S == 0) return 0;
        // It should be impossible for deposit.S > pool.S.
        uint256 deltaS = pool.S.sub(deposit.S);
        uint256 confirmedDeposit = getConfirmedDeposit(pool, deposit);
        amount = confirmedDeposit.mul(deltaS).div(1 ether);
        // Subtract 1 wei from total amount in case the final value
        // had a "decimal" >= 0.5 wei and was therefore rounded up.
        if (amount > 0) amount = amount - 1;
    }

    /**
     * @dev Checks whether the deposit has been confirmed
     * @param pool The pool reference
     * @param deposit The deposit reference
     */
    function getConfirmedDeposit(Pool storage pool, Deposit storage deposit)
        private
        view
        returns (uint256)
    {
        // If deposit N > pool N then flagged deposit has not been confirmed.
        return
            deposit.N <= pool.N
                ? deposit.amount_flagged.add(deposit.amount_confirmed)
                : deposit.amount_confirmed;
    }

    /**
     * @dev Checks whether the user deposit has been confirmed.
     * @param pool The pool reference
     * @param deposit The deposit reference
     */
    function checkUpdateConfirmedDeposit(
        Pool storage pool,
        Deposit storage deposit
    ) private {
        // If deposit N > pool N then deposit has not been confirmed.
        if (deposit.N > pool.N) return;
        // Add to confirmed and reset flagged.
        deposit.amount_confirmed = deposit.amount_confirmed.add(
            deposit.amount_flagged
        );
        deposit.amount_flagged = 0;
    }

    /**
     * @dev Getter for total pool deposit/stake
     * @param collateralToken The pool token
     */
    function getTotalDeposits(address collateralToken)
        external
        view
        override
        returns (uint256 amount)
    {
        return pools[collateralToken].totalDeposits;
    }

    /**
     * @dev Getter for total investments across all protocol interfaces
     * @param collateralToken The pool token
     */
    function getTotalInvestments(address collateralToken)
        external
        view
        override
        returns (uint256 amount)
    {
        return pools[collateralToken].totalInvestments;
    }

    /**
     * @dev Getter for total invested amounts per protocol interface
     * @param collateralToken The pool token
     * @param pia The protocol interface address
     */
    function getProtocolInvestments(address collateralToken, address pia)
        external
        view
        override
        returns (uint256 amount)
    {
        return pools[collateralToken].protocolInvestments[pia];
    }

    /**
     * @dev Getter for total pool accrued interest
     * @param collateralToken The pool token
     */
    function getTotalAccruedInterest(address collateralToken)
        external
        view
        override
        returns (uint256 amount)
    {
        return pools[collateralToken].totalAccrued;
    }

    /** @dev Protected UUPS upgrade authorization function */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
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
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallSecure(newImplementation, data, true);
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

pragma abicoder v2;

interface IHandle {
    struct Vault {
        // Collateral token address => balance
        mapping(address => uint256) collateralBalance;
        uint256 debt;
        // Collateral token address => R0
        mapping(address => uint256) R0;
    }

    struct CollateralData {
        uint256 mintCR;
        uint256 liquidationFee;
        uint256 interestRate;
    }

    event UpdateDebt(address indexed account, address indexed fxToken);

    event UpdateCollateral(
        address indexed account,
        address indexed fxToken,
        address indexed collateralToken
    );

    event ConfigureCollateralToken(address indexed collateralToken);

    event ConfigureFxToken(address indexed fxToken, bool removed);

    function setCollateralUpperBoundPCT(uint256 ratio) external;

    function setPaused(bool value) external;

    function setFxToken(address token) external;

    function removeFxToken(address token) external;

    function setCollateralToken(
        address token,
        uint256 mintCR,
        uint256 liquidationFee,
        uint256 interestRatePerMille
    ) external;

    function removeCollateralToken(address token) external;

    function getAllCollateralTypes()
        external
        view
        returns (address[] memory collateral);

    function getCollateralDetails(address collateral)
        external
        view
        returns (CollateralData memory);

    function WETH() external view returns (address);

    function treasury() external view returns (address payable);

    function comptroller() external view returns (address);

    function vaultLibrary() external view returns (address);

    function fxKeeperPool() external view returns (address);

    function pct() external view returns (address);

    function liquidator() external view returns (address);

    function interest() external view returns (address);

    function referral() external view returns (address);

    function forex() external view returns (address);

    function rewards() external view returns (address);

    function pctCollateralUpperBound() external view returns (uint256);

    function isFxTokenValid(address fxToken) external view returns (bool);

    function isCollateralValid(address collateral) external view returns (bool);

    function setComponents(address[] memory components) external;

    function updateDebtPosition(
        address account,
        uint256 amount,
        address fxToken,
        bool increase
    ) external;

    function updateCollateralBalance(
        address account,
        uint256 amount,
        address fxToken,
        address collateralToken,
        bool increase
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFees(
        uint256 withdrawFeePerMille,
        uint256 depositFeePerMille,
        uint256 mintFeePerMille,
        uint256 burnFeePerMille
    ) external;

    function getCollateralBalance(
        address account,
        address collateralType,
        address fxToken
    ) external view returns (uint256 balance);

    function getBalance(address account, address fxToken)
        external
        view
        returns (address[] memory collateral, uint256[] memory balances);

    function getDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function getPrincipalDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function getCollateralR0(
        address account,
        address fxToken,
        address collateral
    ) external view returns (uint256 R0);

    function getTokenPrice(address token) external view returns (uint256 quote);

    function setOracle(address fxToken, address oracle) external;

    function FeeRecipient() external view returns (address);

    function mintFeePerMille() external view returns (uint256);

    function burnFeePerMille() external view returns (uint256);

    function withdrawFeePerMille() external view returns (uint256);

    function depositFeePerMille() external view returns (uint256);

    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITreasury {
    function depositCollateral(
        address account,
        uint256 depositAmount,
        address collateralType,
        address fxToken,
        address referral
    ) external;

    function depositCollateralETH(
        address account,
        address fxToken,
        address referral
    ) external payable;

    function withdrawCollateral(
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function withdrawCollateralETH(
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function withdrawCollateralFrom(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function forceWithdrawCollateral(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function forceWithdrawAnyCollateral(
        address from,
        address to,
        uint256 amount,
        address fxToken,
        bool requireFullAmount
    )
        external
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        );

    function requestFundsPCT(address token, uint256 amount) external;

    function setMaximumTotalDepositAllowed(uint256 value) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IPCT {
    struct Pool {
        // account -> fxToken -> Deposit
        mapping(address => mapping(address => Deposit)) deposits;
        // Protocol interface address => whether protocol is valid
        mapping(address => bool) protocolInterfaces;
        // Protocol interface address => invested amount
        mapping(address => uint256) protocolInvestments;
        // Deposits that are either flagged (not confirmed) or confirmed and not invested.
        uint256 totalDeposits;
        // Total deposit amount during last investment round, including invested amount.
        uint256 totalDepositsAtInvestment;
        // Amount of deposits that have been invested (<= totalDepositsAtInvestment).
        uint256 totalInvestments;
        // Total accrued interest from investments.
        uint256 totalAccrued;
        // Current pool reward ratio over total deposits.
        uint256 S;
        // Current investment round number.
        uint256 N;
    }

    struct Deposit {
        uint256 amount_flagged;
        uint256 amount_confirmed;
        uint256 S;
        uint256 N;
    }

    event Stake(
        address indexed account,
        address indexed fxToken,
        address indexed collateralToken,
        uint256 amount
    );

    event Unstake(
        address indexed account,
        address indexed fxToken,
        address indexed collateralToken,
        uint256 amount
    );

    event ClaimInterest(
        address indexed acount,
        address indexed collateralToken,
        uint256 amount
    );

    event SetProtocolInterface(
        address indexed protocolInterfaceAddress,
        address indexed collateralToken
    );

    event UnsetProtocolInterface(
        address indexed protocolInterfaceAddress,
        address indexed collateralToken
    );

    event ProtocolClaimInterest(
        address indexed protocolInterfaceAddress,
        address indexed collateralToken,
        uint256 amount
    );

    event ProtocolReturnFunds(
        address indexed protocolInterfaceAddress,
        address indexed collateralToken,
        uint256 amount
    );

    event ProtocolDepositFunds(
        address indexed protocolInterfaceAddress,
        address indexed collateralToken,
        uint256 amount
    );

    function stake(
        address account,
        uint256 amount,
        address fxToken,
        address collateralToken
    ) external returns (uint256 errorCode);

    function unstake(
        address account,
        uint256 amount,
        address fxToken,
        address collateralToken
    ) external returns (uint256 errorCode);

    function claimInterest(address fxToken, address collateralToken) external;

    function setProtocolInterface(
        address collateralToken,
        address protocolInterfaceAddress
    ) external;

    function unsetProtocolInterface(
        address collateralToken,
        address protocolInterfaceAddress
    ) external;

    function claimProtocolInterest(
        address collateralToken,
        address protocolInterfaceAddress
    ) external;

    function depositProtocolFunds(
        address collateralToken,
        address protocolInterfaceAddress,
        uint256 ratio
    ) external;

    function withdrawProtocolFunds(
        address collateralToken,
        address protocolInterfaceAddress,
        uint256 amount
    ) external;

    function requestTreasuryFunds(
        address collateralToken,
        address requestedToken,
        uint256 amount
    ) external;

    function returnTreasuryFunds(
        address collateralToken,
        address returnedToken,
        uint256 amount
    ) external;

    function setProtocolFee(uint256 ratio) external;

    function protocolFee() external view returns (uint256);

    function balanceOfStake(
        address account,
        address fxToken,
        address collateralToken
    ) external view returns (uint256 amount);

    function balanceOfClaimableInterest(
        address account,
        address fxToken,
        address collateralToken
    ) external view returns (uint256 amount);

    function getTotalDeposits(address collateralToken)
        external
        view
        returns (uint256 amount);

    function getTotalInvestments(address collateralToken)
        external
        view
        returns (uint256 amount);

    function getProtocolInvestments(
        address collateralToken,
        address protocolInterfaceAddress
    ) external view returns (uint256 amount);

    function getTotalAccruedInterest(address collateralToken)
        external
        view
        returns (uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IPCTProtocolInterface {
    function investedToken() external view returns (address);

    function protocolToken() external view returns (address);

    function principal() external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawRewards() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/Bank/IHandle.sol";
import "../interfaces/Bank/IHandleComponent.sol";

abstract contract HandlePausable is IHandleComponent {
    function handleAddress() public view virtual override returns (address);

    modifier notPaused() {
        require(!IHandle(handleAddress()).isPaused(), "Paused");
        _;
    }
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
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
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IHandleComponent {
    function setHandleContract(address hanlde) external;

    function handleAddress() external view returns (address);
}