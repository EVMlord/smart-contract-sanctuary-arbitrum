//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
     .--------.
    / .------. \
   / /        \ \
   | |        | |
  _| |________| |_
.' |_|        |_| '.
'._____ ____ _____.'
|     .'____'.     |
'.__.'.'    '.'.__.'
'  )$&3b7*3=&*:.  .'
|   '.'.____.'.'   |
'.____'.____.'____.'
'.________________.'


 _______     _ _  ______                      _     
(_______)   | | |(_____ \           _        | |    
 _____ _   _| | | _____) )___ ___ _| |_ _____| |  _ 
|  ___) | | | | ||  ____/ ___) _ (_   _) ___ | |_/ )
| |   | |_| | | || |   | |  | |_| || |_| ____|  _ ( 
|_|   |____/ \_)_)_|   |_|   \___/  \__)_____)_| \_)
                                                    


 */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./KarrotInterfaces.sol";

/**
FullProtec: The only place to protec your karrots from rabbits
- user's deposited balance is registered on deposit, but the equivalent amount of tokens are burned (avoiding debase)
- this amount is then minted back to the user on withdraw
 */

contract KarrotFullProtec is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IConfig public config;

    struct UserInfo {
        uint256 amount;
        uint256 lockEndedTimestamp;
    }

    uint32 public fullProtecLockDuration = 4 days;
    uint224 public thresholdFullProtecKarrotBalance = 1000000000 * 1e18; //default value to be changed based on token price (1B)
    uint256 public totalStaked;
    address public outputAddress;
    bool public depositsEnabled;

    // Info of each user.
    mapping(address => UserInfo) public userInfo;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event SetLockDuration(uint256 fullProtecLockDuration);
    event SetDepositsEnabled(bool enabled);

    error ForwardFailed();
    error CallerIsNotConfig();
    error DepositsDisabled();
    error InvalidAmount();
    error StillLocked();
    error NoOutputAddressSet();
    error InvalidAllowance();

    constructor(address _configManager) {
        config = IConfig(_configManager);
    }

    modifier onlyConfig() {
        if (msg.sender != address(config)) {
            revert CallerIsNotConfig();
        }
        _;
    }

    function deposit(uint256 _amount) external nonReentrant {

        if(!depositsEnabled){
            revert DepositsDisabled();
        }

        if(_amount == 0){
            revert InvalidAmount();
        }

        if(IKarrotsToken(config.karrotsAddress()).allowance(msg.sender, address(this)) < _amount){
            revert InvalidAllowance();
        }

        UserInfo storage user = userInfo[msg.sender];
        user.lockEndedTimestamp = block.timestamp + fullProtecLockDuration;
        address karrotsAddress = config.karrotsAddress();
        IERC20(karrotsAddress).safeTransferFrom(address(msg.sender), address(this), _amount);
        IKarrotsToken(karrotsAddress).burn(_amount);

        totalStaked += _amount;
        user.amount += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        if(_amount == 0){
            revert InvalidAmount();
        }
        UserInfo storage user = userInfo[msg.sender];


        if(user.lockEndedTimestamp > block.timestamp){
            revert StillLocked();
        }

        if(user.amount < _amount){
            revert InvalidAmount();
        }

        user.lockEndedTimestamp = block.timestamp + fullProtecLockDuration; //reset lock
        user.amount -= _amount;
        totalStaked -= _amount;
        IKarrotsToken(config.karrotsAddress()).mint(address(msg.sender), _amount);

        emit Withdraw(msg.sender, _amount);
    }

    function getUserStakedAmount(address _user) external view returns (uint256) {
        return userInfo[_user].amount;
    }

    function getTotalStakedAmount() external view returns (uint256) {
        return totalStaked;
    }

    function getIsUserAboveThresholdToAvoidClaimTax(address _user) external view returns (bool) {
        return userInfo[_user].amount >= thresholdFullProtecKarrotBalance;
    }

    //=========================================================================
    // SETTERS
    //=========================================================================

    function setOutputAddress(address _outputAddress) external onlyOwner {
        outputAddress = _outputAddress;
    }

    function openFullProtecDeposits() external onlyConfig {
        depositsEnabled = true;
    }

    function setFullProtecLockDuration(uint32 _lockDuration) external onlyConfig{
        fullProtecLockDuration = _lockDuration;
    }

    function setThresholdFullProtecKarrotBalance(uint224 _threshold) external onlyConfig {
        thresholdFullProtecKarrotBalance = _threshold;
    }

    //=========================================================================
    // WITHDRAWALS
    //=========================================================================

    function withdrawERC20FromContract(address _to, address _token) external onlyOwner {
        bool os = IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
        if (!os) {
            revert ForwardFailed();
        }
    }

    function withdrawEthFromContract() external onlyOwner {
        if(outputAddress == address(0)){
            revert NoOutputAddressSet();
        }

        (bool os, ) = payable(outputAddress).call{value: address(this).balance}("");
        
        if (!os) {
            revert ForwardFailed();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
pragma solidity ^0.8.19;

//================================================================================
// COMPLETE (interfaces with all functions used across contracts)
//================================================================================

interface IConfig {
    function dexInterfacerAddress() external view returns (address);
    function karrotsAddress() external view returns (address);
    function karrotChefAddress() external view returns (address);
    function karrotStolenPoolAddress() external view returns (address);
    function karrotFullProtecAddress() external view returns (address);
    function karrotsPoolAddress() external view returns (address);
    function rabbitAddress() external view returns (address);
    function randomizerAddress() external view returns (address);
    function sushiswapRouterAddress() external view returns (address);
    function sushiswapFactoryAddress() external view returns (address);
    function treasuryAddress() external view returns (address);
    function treasuryBAddress() external view returns (address);
    function teamSplitterAddress() external view returns (address);
    function presaleDistributorAddress() external view returns (address);
    function attackRewardCalculatorAddress() external view returns (address);
}

interface IKarrotChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function claim(uint256 _pid) external;
    function attack() external;
    function randomizerWithdrawKarrotChef(address _to, uint256 _amount) external;
    function getUserStakedAmount(address _user) external view returns (uint256);
    function getTotalStakedAmount() external view returns (uint256);
    function updateConfig() external;
    function setAllocationPoint(uint256 _pid, uint128 _allocPoint, bool _withUpdatePools) external;
    function setLockDuration(uint256 _pid, uint256 _lockDuration) external;
    function updateRewardPerBlock(uint88 _rewardPerBlock) external;
    function setCompoundRatio(uint48 _compoundRatio) external;
    function openKarrotChefDeposits() external;
    function setDepositIsPaused(bool _isPaused) external;
    function setThresholdFullProtecKarrotBalance(uint256 _thresholdFullProtecKarrotBalance) external;
    function setClaimTaxRate(uint16 _maxTaxRate) external;
    function randomzierWithdraw(address _to, uint256 _amount) external;
    function setRandomizerClaimCallbackGasLimit(uint24 _randomizerClaimCallbackGasLimit) external;
    function setFullProtecLiquidityProportion(uint16 _fullProtecLiquidityProportion) external;
    function setClaimTaxChance(uint16 _claimTaxChance) external;
}

interface IKarrotsToken {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function updateConfig() external;
    function addDexAddress(address _dexAddress) external;
    function removeDexAddress(address _dexAddress) external;
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferUnderlying(address to, uint256 value) external returns (bool);
    function fragmentToKarrots(uint256 value) external view returns (uint256);
    function karrotsToFragment(uint256 karrots) external view returns (uint256);
    function balanceOfUnderlying(address who) external view returns (uint256);
    function setSellTaxRate(uint16 _sellTaxRate) external;
    function setBuyTaxRate(uint16 _buyTaxRate) external;
    function setSellTaxIsActive(bool _sellTaxIsActive) external;
    function setBuyTaxIsActive(bool _buyTaxIsActive) external;
    function setTradingIsOpen(bool _tradingIsOpen) external;
    function setMaxIndexDelta(uint256 _maxIndexDelta) external;
    function setTransferTradingBlockIsOn(bool _transferTradingBlockIsOn) external;
}

interface IRabbit {
    function getRabbitSupply() external view returns (uint256);
    function getRabbitIdsByOwner(address _owner) external view returns (uint256[] memory);
    function updateConfig() external;
    function randomizerWithdrawRabbit(address _to, uint256 _amount) external;
    function setRabbitMintIsOpen(bool _isOpen) external;
    function setRabbitBatchSize(uint16 _batchSize) external;
    function setRabbitMintSecondsBetweenBatches(uint32 _secondsBetweenBatches) external;
    function setRabbitMaxPerWallet(uint8 _maxPerWallet) external;
    function setRabbitMintPriceInKarrots(uint72 _priceInKarrots) external;
    function setRabbitRerollPriceInKarrots(uint72 _priceInKarrots) external;
    function setRabbitMintKarrotFeePercentageToBurn(uint16 _karrotFeePercentageToBurn) external;
    function setRabbitMintKarrotFeePercentageToTreasury(uint16 _karrotFeePercentageToTreasury) external;
    function setRabbitMintTier1Threshold(uint16 _tier1Threshold) external;
    function setRabbitMintTier2Threshold(uint16 _tier2Threshold) external;
    function setRabbitTier1HP(uint8 _tier1HP) external;
    function setRabbitTier2HP(uint8 _tier2HP) external;
    function setRabbitTier3HP(uint8 _tier3HP) external;
    function setRabbitTier1HitRate(uint16 _tier1HitRate) external;
    function setRabbitTier2HitRate(uint16 _tier2HitRate) external;
    function setRabbitTier3HitRate(uint16 _tier3HitRate) external;
    function setRabbitAttackIsOpen(bool _isOpen) external;
    function setAttackCooldownSeconds(uint32 _attackCooldownSeconds) external;
    function setAttackHPDeductionAmount(uint8 _attackHPDeductionAmount) external;
    function setAttackHPDeductionThreshold(uint16 _attackHPDeductionThreshold) external;
    function setRandomizerMintCallbackGasLimit(uint24 _randomizerMintCallbackGasLimit) external;
    function setRandomizerAttackCallbackGasLimit(uint24 _randomizerAttackCallbackGasLimit) external;
}

interface IFullProtec {
    function getUserStakedAmount(address _user) external view returns (uint256);
    function getTotalStakedAmount() external view returns (uint256);
    function getIsUserAboveThresholdToAvoidClaimTax(address _user) external view returns (bool);
    function updateConfig() external;
    function openFullProtecDeposits() external;
    function setFullProtecLockDuration(uint32 _lockDuration) external;
    function setThresholdFullProtecKarrotBalance(uint224 _thresholdFullProtecKarrotBalance) external;
}

interface IStolenPool {
    function deposit(uint256 _amount) external;
    function attack(address _sender, uint256 _rabbitTier, uint256 _rabbitId) external;
    function updateConfig() external;
    function setStolenPoolOpenTimestamp() external;
    function setStolenPoolAttackIsOpen(bool _isOpen) external;
    function setAttackBurnPercentage(uint16 _attackBurnPercentage) external;
    function setStolenPoolEpochLength(uint32 _epochLength) external;
}

interface IAttackRewardCalculator {
    function calculateRewardPerAttackByTier(
        uint256 tier1Attacks,
        uint256 tier2Attacks,
        uint256 tier3Attacks,
        uint256 tier1Weight,
        uint256 tier2Weight,
        uint256 tier3Weight,
        uint256 totalKarrotsDepositedThisEpoch
    ) external view returns (uint256[] memory);
}

interface IDexInterfacer {
    function updateConfig() external;
    function depositEth() external payable;
    function depositErc20(uint256 _amount) external;
    function getPoolIsCreated() external view returns (bool);
    function getPoolIsFunded() external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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