// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IVaultAdapter } from "./interfaces/IVaultAdapter.sol";
import { IControllerZooMinimal } from "./interfaces/IControllerZooMinimal.sol";
import { IERC20TokenReceiver } from "./interfaces/IERC20TokenReceiver.sol";

import { PausableAccessControl } from "./utils/PausableAccessControl.sol";
import { TokenUtils } from "./utils/TokenUtils.sol";
import { SafeCast } from "./utils/SafeCast.sol";
import "./utils/Errors.sol";

contract Zoo is IERC20TokenReceiver, PausableAccessControl, ReentrancyGuard {
	/// @notice A structure to store the informations related to a user CDP.
	struct UserInfo {
		/// @notice Total user deposit.
		uint256 totalDeposited;
		/// @notice Total user debt.
		int256 totalDebt;
		/// @notice Weight used to calculate % of total deposited earned by user since last update.
		uint256 lastAccumulatedYieldWeight;
	}

	/// @notice The scalar used for conversion of integral numbers to fixed point numbers.
	uint256 public constant FIXED_POINT_SCALAR = 1e18;

	/// @notice The token that this contract is using as the collateral asset.
	address public immutable collatToken;

	/// @notice The token that this contract is using as the native token.
	address public immutable nativeToken;

	/// @notice The token that this contract is using as the debt asset.
	address public immutable debtToken;

	uint8 public immutable nativeTokenDecimals;

	uint8 public immutable debtTokenDecimals;

	/// @notice The total amount the native token deposited into the system that is owned by external users.
	uint256 public totalDeposited;

	/// @notice The maximum value allowed for {totalDebt}.
	int256 public maxDebt;

	/// @notice The current debt owned by the zoo contract.
	/// @notice The debt is calculated as the difference between the total amount of debt tokens minted by the contract and the total amount of debt tokens transferred to the zoo.
	int256 public totalDebt;

	/// @notice The address of the contract which will control the health of user position.
	/// @notice A callback from the controller is called before and after each user operation. The function call reverts if the action is not allowed by the controller.
	address public controller;

	/// @notice The address of the contract which will convert synthetic tokens back into native tokens.
	address public keeper;

	/// @notice The address of the contract which will manage the native token deposited into vaults.
	address public vaultAdapter;

	/// @notice The accumlated yield weight used to calculate users' rewards
	uint256 public accumulatedYieldWeight;

	/// @notice A mapping of all of the user CDPs. If a user wishes to have multiple CDPs they will have to either
	/// create a new address or set up a proxy contract that interfaces with this contract.
	mapping(address => UserInfo) private _userInfos;

	constructor(
		address _collatToken,
		address _nativeToken,
		address _debtToken
	) {
		collatToken = _collatToken;
		nativeToken = _nativeToken;
		debtToken = _debtToken;

		nativeTokenDecimals = TokenUtils.expectDecimals(_nativeToken);
		debtTokenDecimals = TokenUtils.expectDecimals(_debtToken);
	}

	function setVaultAdapter(address _vaultAdapter) external {
		_onlyAdmin();
		if (_vaultAdapter == address(0)) {
			revert ZeroAddress();
		}

		vaultAdapter = _vaultAdapter;
	}

	/// @notice Sets the address of the controller.
	///
	/// @notice Reverts with an {OnlyAdminAllowed} error if the caller is missing the admin role.
	///
	/// @notice Emits a {ControllerUpdated} event.
	///
	/// @param _controller The address of the new controller.
	function setController(address _controller) external {
		_onlyAdmin();
		if (_controller == address(0)) {
			revert ZeroAddress();
		}
		controller = _controller;

		emit ControllerUpdated(_controller);
	}

	/// @notice Sets the address of the keeper.
	///
	/// @notice Reverts with an {OnlyAdminAllowed} error if the caller is missing the admin role.
	/// @notice Reverts with an {ZeroAddress} error if the new keeper is the 0 address.
	///
	/// @notice Emits a {KeeperUpdated} event.
	///
	/// @param _keeper The address of the new keeper.
	function setKeeper(address _keeper) external {
		_onlyAdmin();
		if (_keeper == address(0)) {
			revert ZeroAddress();
		}
		keeper = _keeper;

		emit KeeperUpdated(_keeper);
	}

	/// @notice Sets the maximum debt.
	///
	/// @notice Reverts with an {OnlyAdminAllowed} error if the caller is missing the admin role.
	///
	/// @notice Emits a {MaxDebtUpdated} event.
	///
	/// @param _maxDebt The new max debt.
	function setMaxDebt(int256 _maxDebt) external {
		_onlyAdmin();
		maxDebt = _maxDebt;

		emit MaxDebtUpdated(_maxDebt);
	}

	/// @inheritdoc IERC20TokenReceiver
	function onERC20Received(address _token, uint256 _amount) external nonReentrant {
		_distribute();
	}

	/// @notice Deposits `_amount` of tokens into the zoo.
	/// @notice Transfers `_amount` of tokens from the caller to the zoo and increases caller collateral position by an equivalent amount.
	/// @notice Controller is called before and after to check if the action is allowed.
	///
	/// @notice Reverts with an {ContractPaused} error if the contract is in pause state.
	/// @notice Reverts with an {ZeroValue} error if the deposited amount is 0.
	///
	/// @notice Emits a {TokensDeposited} event.
	///
	/// @param _amount the amount of tokens to deposit.
	function deposit(uint256 _amount) external nonReentrant {
		_checkNotPaused();
		if (_amount == 0) {
			revert ZeroValue();
		}
		_distribute();
		_update(msg.sender);

		address _controller = controller;
		IControllerZooMinimal(_controller).controlBeforeDeposit(address(this), msg.sender, _amount);

		_deposit(msg.sender, _amount);

		IControllerZooMinimal(_controller).controlAfterDeposit(address(this), msg.sender, _amount);
	}

	/// @notice Withdraws `_amount` of tokens from the zoo.
	/// @notice Transfers `_amount` of tokens from the zoo to the caller and decreases caller collateral position by an equivalent amount.
	/// @notice Controller is called before and after to check if the action is allowed.
	///
	/// @notice Reverts with an {ZeroValue} error if the withdrawn amount is 0.
	///
	/// @notice Emits a {TokensWithdrawn} event.
	///
	/// @param _amount the amount of tokens to withdraw.
	function withdraw(uint256 _amount) external nonReentrant {
		if (_amount == 0) {
			revert ZeroValue();
		}
		_distribute();
		_update(msg.sender);

		address _controller = controller;
		IControllerZooMinimal(_controller).controlBeforeWithdraw(address(this), msg.sender, _amount);

		_withdraw(msg.sender, _amount);

		IControllerZooMinimal(_controller).controlAfterWithdraw(address(this), msg.sender, _amount);
	}

	function selfLiquidate(uint256 _amount) external nonReentrant {
		if (_amount == 0) {
			revert ZeroValue();
		}
		_distribute();
		_update(msg.sender);

		// Computes effective debt reduction allowed for user
		uint256 _liquidateAmount = _getEffectiveDebtReducedFor(msg.sender, _amount);

		address _controller = controller;
		IControllerZooMinimal(_controller).controlBeforeLiquidate(address(this), msg.sender, _liquidateAmount);

		_selfLiquidate(msg.sender, _liquidateAmount);

		IControllerZooMinimal(_controller).controlAfterLiquidate(address(this), msg.sender, _liquidateAmount);
	}

	/// @notice Mints `_amount` of debt tokens and transfers them to the caller.
	/// @notice Controller is called before and after to check if the action is allowed.
	///
	/// @notice Reverts with an {ZeroValue} error if the minted amount is 0.
	///
	/// @notice Emits a {TokensMinted} event.
	///
	/// @param _amount the amount of debt tokens to mint.
	function mint(uint256 _amount) external nonReentrant {
		_checkNotPaused();
		if (_amount == 0) {
			revert ZeroValue();
		}
		_distribute();
		_update(msg.sender);

		address _controller = controller;
		IControllerZooMinimal(_controller).controlBeforeMint(address(this), msg.sender, _amount);

		_mint(msg.sender, _amount);

		IControllerZooMinimal(_controller).controlAfterMint(address(this), msg.sender, _amount);
	}

	/// @notice Burns `_amount` of debt tokens from the caller.
	/// @notice If the user debt is lower than the amount, then the entire debt is burned.
	/// @notice Controller is called before and after to check if the action is allowed.
	///
	/// @notice Reverts with an {ZeroValue} error if the burned amount is 0.
	///
	/// @notice Emits a {TokensBurned} event.
	///
	/// @param _amount The amount of debt tokens to burn.
	function burn(uint256 _amount) external nonReentrant {
		if (_amount == 0) {
			revert ZeroValue();
		}
		_distribute();
		_update(msg.sender);

		// Computes effective debt reduction allowed for user
		uint256 _burnAmount = _getEffectiveDebtReducedFor(msg.sender, _amount);

		address _controller = controller;
		IControllerZooMinimal(_controller).controlBeforeBurn(address(this), msg.sender, _burnAmount);

		_burn(msg.sender, _amount);

		IControllerZooMinimal(_controller).controlAfterBurn(address(this), msg.sender, _burnAmount);
	}

	function liquidate(address _toLiquidate) external {
		// Transfers GLP from liquidator
		// Computes amount to liquidate for user
	}

	/// @notice Allows controller to update distribution and user information.
	/// @notice Controller needs to gather synchronised informations from multiple sources to check if an action is allowed.
	///
	/// @notice Reverts with an {OnlyControllerAllowed} error if the caller is not the controller.
	///
	/// @notice _owner The address of the user to update.
	function sync(address _owner) external {
		_distribute();
		_update(_owner);
	}

	/// @notice Gets the total amount of tokens deposited and the total debt for `_owner`.
	///
	/// @param _owner The address of the account to query.
	///
	/// @return totalDeposit The amount of tokens deposited as a collateral.
	/// @return totalDebt The amount of debt contracted by the user.
	function userInfo(address _owner) external view returns (uint256, int256) {
		UserInfo storage _userInfo = _userInfos[_owner];

		uint256 _userTotalDeposited = _userInfo.totalDeposited;

		uint256 _earnedYield = ((accumulatedYieldWeight - _userInfo.lastAccumulatedYieldWeight) * _userTotalDeposited) /
			FIXED_POINT_SCALAR;

		uint256 _normalisedEarnedYield = (_earnedYield * 10**(uint256(debtTokenDecimals))) /
			10**(uint256(nativeTokenDecimals));

		int256 _userTotalDebt = _userInfo.totalDebt - SafeCast.toInt256(_normalisedEarnedYield);
		return (_userTotalDeposited, _userTotalDebt);
	}

	function _deposit(address _user, uint256 _amount) internal {
		// Transfers tokens from user and deposits into the vault manager
		TokenUtils.safeTransferFrom(collatToken, _user, vaultAdapter, _amount);
		IVaultAdapter(vaultAdapter).deposit(_amount);

		// Increases deposit for user
		_increaseDepositFor(_user, _amount);

		emit TokensDeposited(_user, _amount);
	}

	function _withdraw(address _user, uint256 _amount) internal {
		// Decreases deposit for user
		_decreaseDepositFor(_user, _amount);

		// Transfers tokens from vault to user
		IVaultAdapter(vaultAdapter).withdraw(_user, _amount);

		emit TokensWithdrawn(_user, _amount);
	}

	function _selfLiquidate(address _user, uint256 _amount) internal {
		// Decreases deposit for user
		TokenUtils.safeTransferFrom(nativeToken, _user, address(this), _amount);

		// Decreases debt for user
		_increaseDebtFor(_user, -SafeCast.toInt256(_amount));

		// Transfers liquidated native tokens to the keeper
		_distributeToKeeper(_amount);

		emit TokensLiquidated(_user, _amount);
	}

	function _mint(address _user, uint256 _amount) internal {
		// Increases debt for user
		_increaseDebtFor(_user, SafeCast.toInt256(_amount));

		// Mints debt tokens
		_mintDebtToken(_user, _amount);

		emit TokensMinted(_user, _amount);
	}

	function _burn(address _user, uint256 _amount) internal {
		// Burns debt tokens from user
		_burnDebtToken(_user, _amount);

		// Decreases debt for user
		_increaseDebtFor(_user, -SafeCast.toInt256(_amount));

		emit TokensBurned(_user, _amount);
	}

	/// @notice Increases the amount of collateral collatToken deposited in the platform by `_increasedAmount` for `_owner`.
	/// @notice Updates the total amount deposited in the platform.
	///
	/// @param _owner The address of the account to update deposit for.
	/// @param _increasedAmount The increase amount of asset deposited by `_owner`.
	function _increaseDepositFor(address _owner, uint256 _increasedAmount) internal {
		UserInfo storage _userInfo = _userInfos[_owner];
		_userInfo.totalDeposited += _increasedAmount;
		totalDeposited += _increasedAmount;
	}

	/// @notice Decreases the amount of collateral collatToken deposited in the platform by `_decreasedAmount` for `_owner`.
	/// @notice Updates the total amount deposited in the platform.
	///
	/// @param _owner The address of the account to update deposit for.
	/// @param _decreasedAmount The decrease amount of asset deposited by `_owner`.
	function _decreaseDepositFor(address _owner, uint256 _decreasedAmount) internal {
		UserInfo storage _userInfo = _userInfos[_owner];
		_userInfo.totalDeposited -= _decreasedAmount;
		totalDeposited -= _decreasedAmount;
	}

	/// @notice Increases the amount of debt by `_increasedAmount` for `_owner`.
	/// @notice As `_increasedAmount` can be a negative value, this function is also used to decreased the debt.
	/// @notice Updates the total debt from the plateform.
	///
	/// @notice Reverts with an {MaxDebtBreached} error if the platform debt is greater than the maximum allowed debt.
	///
	/// @param _owner The address of the account to update debt for.
	/// @param _amount The additional amount of debt (can be negative) owned by `_owner`.
	function _increaseDebtFor(address _owner, int256 _amount) internal {
		UserInfo storage _userInfo = _userInfos[_owner];
		_userInfo.totalDebt += _amount;
	}

	/// @notice Gets the effective debt reduction that will be attempted for `_owner`.
	/// @notice `_owner` wishes to liquidate/burn `_wishedDebtReducedAmount` amounts.
	/// @notice The effective attempted debt reduction is the minimum between the user debt and `_wishedDebtReducedAmount`.
	///
	/// @param _owner The address of the account that wants to reduce its debt.
	/// @param _wishedDebtReducedAmount The wished amount of debt the user wants to reimburse.
	///
	/// @return The amount of debt that `_owner` will effectively try to reimburse.
	function _getEffectiveDebtReducedFor(address _owner, uint256 _wishedDebtReducedAmount)
		internal
		view
		returns (uint256)
	{
		UserInfo storage _userInfo = _userInfos[_owner];

		int256 _userDebt = _userInfo.totalDebt;
		// Dont attempt to reduce if no debt
		if (_userDebt <= 0) {
			revert NoPositiveDebt(_userDebt);
		}

		// Dont attempt to reduce more than debt
		uint256 _effectiveDebtReduced = Math.min(_wishedDebtReducedAmount, uint256(_userDebt));

		return _effectiveDebtReduced;
	}

	/// @notice Updates the debt position for `_owner` according to the earned yield since the last update.
	///
	/// @param _owner the address of the user to update.
	function _update(address _owner) internal {
		UserInfo storage _userInfo = _userInfos[_owner];

		uint256 _earnedYield = ((accumulatedYieldWeight - _userInfo.lastAccumulatedYieldWeight) *
			_userInfo.totalDeposited) / FIXED_POINT_SCALAR;

		uint256 _normalisedEarnedYield = (_earnedYield * 10**(uint256(debtTokenDecimals))) /
			10**(uint256(nativeTokenDecimals));

		_userInfo.totalDebt -= SafeCast.toInt256(_normalisedEarnedYield);
		_userInfo.lastAccumulatedYieldWeight = accumulatedYieldWeight;
	}

	/// @notice Distributes rewards deposited into the zoo by the vaultAdapter.
	/// @notice Fees are deducted from the rewards and sent to the fee receiver.
	/// @notice Remaining rewards reduce users' debts and are sent to the keeper.
	function _distribute() internal {
		uint256 _harvestedAmount = TokenUtils.safeBalanceOf(nativeToken, address(this));

		if (_harvestedAmount > 0) {
			// Updates users' debt
			uint256 _weight = (_harvestedAmount * FIXED_POINT_SCALAR) / totalDeposited;
			accumulatedYieldWeight += _weight;

			// Distributes harvest to keeper
			_distributeToKeeper(_harvestedAmount);
		}

		emit HarvestRewardDistributed(_harvestedAmount);
	}

	/// @notice Mints `_amount` of debt tokens and send them to `_recipient`.
	///
	/// @param _recipient The beneficiary of the minted tokens.
	/// @param _amount The amount of tokens to mint.
	function _mintDebtToken(address _recipient, uint256 _amount) internal {
		// Checks max debt breached
		int256 _totalDebt = totalDebt + SafeCast.toInt256(_amount);
		if (_totalDebt > maxDebt) {
			revert MaxDebtBreached();
		}
		totalDebt = _totalDebt;
		// Mints debt tokens to user
		TokenUtils.safeMint(debtToken, _recipient, _amount);
	}

	/// @notice Burns `_amount` of debt tokens from `_origin`.
	///
	/// @param _origin The origin of the burned tokens.
	/// @param _amount The amount of tokens to burn.
	function _burnDebtToken(address _origin, uint256 _amount) internal {
		TokenUtils.safeBurnFrom(debtToken, _origin, _amount);
		totalDebt -= SafeCast.toInt256(_amount);
	}

	/// @notice Distributes `_amount` of vault tokens to the keeper.
	///
	/// @param _amount The amount of vault tokens to send to the keeper.
	function _distributeToKeeper(uint256 _amount) internal {
		// Reduces platform debt
		totalDebt -= SafeCast.toInt256(_amount);

		address _keeper = keeper;
		TokenUtils.safeTransfer(nativeToken, _keeper, _amount);
		IERC20TokenReceiver(_keeper).onERC20Received(nativeToken, _amount);
	}

	/// @notice Emitted when `account` deposits `amount `tokens into the zoo.
	///
	/// @param account The address of the account owner.
	/// @param amount The amount of tokens deposited.
	event TokensDeposited(address indexed account, uint256 amount);

	/// @notice Emitted when `account` withdraws tokens.
	///
	/// @param account The address of the account owner.
	/// @param amount The amount of tokens requested to withdraw by `account`.
	event TokensWithdrawn(address indexed account, uint256 amount);

	/// @notice Emitted when `account` mints `amount` of debt tokens.
	///
	/// @param account The address of the account owner.
	/// @param amount The amount of debt tokens minted.
	event TokensMinted(address indexed account, uint256 amount);

	/// @notice Emitted when `account` burns `amount`debt tokens.
	///
	/// @param account The address of the account owner.
	/// @param amount The amount of debt tokens burned.
	event TokensBurned(address indexed account, uint256 amount);

	/// @notice Emitted when `account` liquidates a debt by using a part of it collateral position.
	///
	/// @param account The address of the account owner.
	/// @param requestedAmount the amount of tokens requested to pay debt by `account`.
	event TokensLiquidated(address indexed account, uint256 requestedAmount);

	/// @notice Emitted when the controller address is updated.
	///
	/// @param controller The address of the controller.
	event ControllerUpdated(address controller);

	/// @notice Emitted when the keeper address is updated.
	///
	/// @param keeper The address of the keeper.
	event KeeperUpdated(address keeper);

	/// @notice Emitted when the max debt is updated.
	///
	/// @param maxDebtAmount The maximum debt.
	event MaxDebtUpdated(int256 maxDebtAmount);

	/// @notice Emitted when rewards are distributed.
	///
	/// @param amount The amount of native tokens distributed.
	event HarvestRewardDistributed(uint256 amount);

	/// @notice Indicates that a mint operation failed because the max debt is breached.
	error MaxDebtBreached();

	/// @notice Indiciated that the user does not have any debt.
	///
	/// @param debt The current debt owner by the user.
	error NoPositiveDebt(int256 debt);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title IVaultAdapter
/// @author Koala Money
interface IVaultAdapter {
	/// @notice Deposits funds into the vault
	///
	/// @param _amount The amount of funds to deposit
	function deposit(uint256 _amount) external;

	/// @notice Withdraw `_amount` of tokens from the vaults and send the withdrawn tokens to `_recipient`.
	///
	/// @param _recipient The address of the recipient of the funds.
	/// @param _amount    The amount of funds to requested.
	function withdraw(address _recipient, uint256 _amount) external;

	/// @notice Harvests rewards.
	///
	/// @param _recipient The address of the recipient of the harvested rewards.
	function harvest(address _recipient) external;

	/// @notice Gets the token that the adapter accepts.
	function token() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title IControllerZooMinimal
/// @author Koala Money
interface IControllerZooMinimal {
	function controlBeforeDeposit(
		address _zoo,
		address _owner,
		uint256 _amount
	) external;

	function controlBeforeWithdraw(
		address _zoo,
		address _owner,
		uint256 _amount
	) external;

	function controlBeforeMint(
		address _zoo,
		address _owner,
		uint256 _amount
	) external;

	function controlBeforeBurn(
		address _zoo,
		address _owner,
		uint256 _amount
	) external;

	function controlBeforeLiquidate(
		address _zoo,
		address _owner,
		uint256 _amount
	) external;

	function controlAfterDeposit(
		address _zoo,
		address _owner,
		uint256 _amount
	) external;

	function controlAfterWithdraw(
		address _zoo,
		address _owner,
		uint256 _amount
	) external;

	function controlAfterMint(
		address _zoo,
		address _owner,
		uint256 _amount
	) external;

	function controlAfterBurn(
		address _zoo,
		address _owner,
		uint256 _amount
	) external;

	function controlAfterLiquidate(
		address _zoo,
		address _owner,
		uint256 _amount
	) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title IERC20TokenReceiver
/// @author Alchemix Finance
interface IERC20TokenReceiver {
	/// @notice Informs implementors of this interface that an ERC20 token has been transferred.
	///
	/// @param token The token that was transferred.
	/// @param value The amount of the token that was transferred.
	function onERC20Received(address token, uint256 value) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { AdminAccessControl } from "./AdminAccessControl.sol";

/// @title  PausableAccessControl
/// @author Koala Money
///
/// @notice An admin access control with sentinel role and pausable state.
contract PausableAccessControl is AdminAccessControl {
	/// @notice The identifier of the role which can pause/unpause contract
	bytes32 public constant SENTINEL_ROLE = keccak256("SENTINEL");

	/// @notice Check if the token is paused.
	bool public paused;

	/// @notice Emitted when the contract enters the pause state.
	event Pause();

	/// @notice Emitted when the contract enters the unpause state.
	event Unpause();

	/// @notice Indicates that the caller is missing the sentinel role.
	error OnlySentinelAllowed();

	/// @notice Indicates that the contract is in pause state.
	error ContractPaused();

	/// @notice indicates that the contract is not in pause state.
	error ContractNotPaused();

	/// @notice Sets the contract in the pause state.
	///
	/// @notice Reverts if the caller does not have sentinel role.
	function pause() external {
		_onlySentinel();
		paused = true;
		emit Pause();
	}

	/// @notice Sets the contract in the unpause state.
	///
	/// @notice Reverts if the caller does not have sentinel role.
	function unpause() external {
		_onlySentinel();
		paused = false;
		emit Unpause();
	}

	/// @notice Checks that the contract is in the unpause state.
	function _checkNotPaused() internal view {
		if (paused) {
			revert ContractPaused();
		}
	}

	/// @notice Checks that the contract is in the pause state.
	function _checkPaused() internal view {
		if (!paused) {
			revert ContractNotPaused();
		}
	}

	/// @notice Checks that the caller has the sentinel role.
	function _onlySentinel() internal view {
		if (!hasRole(SENTINEL_ROLE, msg.sender)) {
			revert OnlySentinelAllowed();
		}
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "../interfaces/token/IERC20Burnable.sol";
import "../interfaces/token/IERC20Metadata.sol";
import "../interfaces/token/IERC20Minimal.sol";
import "../interfaces/token/IERC20Mintable.sol";

/// @title  TokenUtils
/// @author Alchemix Finance
library TokenUtils {
	/// @notice An error used to indicate that a call to an ERC20 contract failed.
	///
	/// @param target  The target address.
	/// @param success If the call to the token was a success.
	/// @param data    The resulting data from the call. This is error data when the call was not a success. Otherwise,
	///                this is malformed data when the call was a success.
	error ERC20CallFailed(address target, bool success, bytes data);

	/// @dev A safe function to get the decimals of an ERC20 token.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
	///
	/// @param token The target token.
	///
	/// @return The amount of decimals of the token.
	function expectDecimals(address token) internal view returns (uint8) {
		(bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20Metadata.decimals.selector));

		if (!success || data.length < 32) {
			revert ERC20CallFailed(token, success, data);
		}

		return abi.decode(data, (uint8));
	}

	/// @dev Gets the balance of tokens held by an account.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
	///
	/// @param token   The token to check the balance of.
	/// @param account The address of the token holder.
	///
	/// @return The balance of the tokens held by an account.
	function safeBalanceOf(address token, address account) internal view returns (uint256) {
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, account)
		);

		if (!success || data.length < 32) {
			revert ERC20CallFailed(token, success, data);
		}

		return abi.decode(data, (uint256));
	}

	/// @dev Gets the total supply of tokens.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
	///
	/// @param token   The token to check the total supply of.
	///
	/// @return The balance of the tokens held by an account.
	function safeTotalSupply(address token) internal view returns (uint256) {
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(IERC20Minimal.totalSupply.selector)
		);

		if (!success || data.length < 32) {
			revert ERC20CallFailed(token, success, data);
		}

		return abi.decode(data, (uint256));
	}

	/// @dev Transfers tokens to another address.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.
	///
	/// @param token     The token to transfer.
	/// @param recipient The address of the recipient.
	/// @param amount    The amount of tokens to transfer.
	function safeTransfer(
		address token,
		address recipient,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Minimal.transfer.selector, recipient, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Approves tokens for the smart contract.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.
	///
	/// @param token   The token to approve.
	/// @param spender The contract to spend the tokens.
	/// @param value   The amount of tokens to approve.
	function safeApprove(
		address token,
		address spender,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Minimal.approve.selector, spender, value)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Transfer tokens from one address to another address.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.
	///
	/// @param token     The token to transfer.
	/// @param owner     The address of the owner.
	/// @param recipient The address of the recipient.
	/// @param amount    The amount of tokens to transfer.
	function safeTransferFrom(
		address token,
		address owner,
		address recipient,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, owner, recipient, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Mints tokens to an address.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the mint fails or returns an unexpected value.
	///
	/// @param token     The token to mint.
	/// @param recipient The address of the recipient.
	/// @param amount    The amount of tokens to mint.
	function safeMint(
		address token,
		address recipient,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Mintable.mint.selector, recipient, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Burns tokens.
	///
	/// Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.
	///
	/// @param token  The token to burn.
	/// @param amount The amount of tokens to burn.
	function safeBurn(address token, uint256 amount) internal {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Burnable.burn.selector, amount));

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Burns tokens from its total supply.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.
	///
	/// @param token  The token to burn.
	/// @param owner  The owner of the tokens.
	/// @param amount The amount of tokens to burn.
	function safeBurnFrom(
		address token,
		address owner,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Burnable.burnFrom.selector, owner, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.15;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
	error SafeCastError();

	/// @notice Cast a uint256 to a int256, revert on overflow
	/// @param y The uint256 to be casted
	/// @return z The casted integer, now type int256
	function toInt256(uint256 y) internal pure returns (int256 z) {
		if (y >= 2**255) {
			revert SafeCastError();
		}
		z = int256(y);
	}

	/// @notice Cast a int256 to a uint256, revert on underflow
	/// @param y The int256 to be casted
	/// @return z The casted integer, now type uint256
	function toUint256(int256 y) internal pure returns (uint256 z) {
		if (y < 0) {
			revert SafeCastError();
		}
		z = uint256(y);
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

/// @notice An error used to indicate that an action could not be completed because a zero address argument was passed to the function.
error ZeroAddress();

/// @notice An error used to indicate that an action could not be completed because a zero amount argument was passed to the function.
error ZeroValue();

/// @notice An error used to indicate that an action could not be completed because a function was called with an out of bounds argument.
error OutOfBoundsArgument();

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title  AdminAccessControl
/// @author Koala Money
///
/// @notice An access control with admin role granted to the contract deployer.
contract AdminAccessControl is AccessControl {
	/// @notice Indicates that the caller is missing the admin role.
	error OnlyAdminAllowed();

	constructor() {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function _onlyAdmin() internal view {
		if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
			revert OnlyAdminAllowed();
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IERC20Burnable {
	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title  IERC20Metadata
/// @author Alchemix Finance
interface IERC20Metadata {
	/// @notice Gets the name of the token.
	///
	/// @return The name.
	function name() external view returns (string memory);

	/// @notice Gets the symbol of the token.
	///
	/// @return The symbol.
	function symbol() external view returns (string memory);

	/// @notice Gets the number of decimals that the token has.
	///
	/// @return The number of decimals.
	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title  IERC20Minimal
/// @author Alchemix Finance
interface IERC20Minimal {
	/// @notice An event which is emitted when tokens are transferred between two parties.
	///
	/// @param owner     The owner of the tokens from which the tokens were transferred.
	/// @param recipient The recipient of the tokens to which the tokens were transferred.
	/// @param amount    The amount of tokens which were transferred.
	event Transfer(address indexed owner, address indexed recipient, uint256 amount);

	/// @notice An event which is emitted when an approval is made.
	///
	/// @param owner   The address which made the approval.
	/// @param spender The address which is allowed to transfer tokens on behalf of `owner`.
	/// @param amount  The amount of tokens that `spender` is allowed to transfer.
	event Approval(address indexed owner, address indexed spender, uint256 amount);

	/// @notice Gets the current total supply of tokens.
	///
	/// @return The total supply.
	function totalSupply() external view returns (uint256);

	/// @notice Gets the balance of tokens that an account holds.
	///
	/// @param account The account address.
	///
	/// @return The balance of the account.
	function balanceOf(address account) external view returns (uint256);

	/// @notice Gets the allowance that an owner has allotted for a spender.
	///
	/// @param owner   The owner address.
	/// @param spender The spender address.
	///
	/// @return The number of tokens that `spender` is allowed to transfer on behalf of `owner`.
	function allowance(address owner, address spender) external view returns (uint256);

	/// @notice Transfers `amount` tokens from `msg.sender` to `recipient`.
	///
	/// @notice Emits a {Transfer} event.
	///
	/// @param recipient The address which will receive the tokens.
	/// @param amount    The amount of tokens to transfer.
	///
	/// @return If the transfer was successful.
	function transfer(address recipient, uint256 amount) external returns (bool);

	/// @notice Approves `spender` to transfer `amount` tokens on behalf of `msg.sender`.
	///
	/// @notice Emits a {Approval} event.
	///
	/// @param spender The address which is allowed to transfer tokens on behalf of `msg.sender`.
	/// @param amount  The amount of tokens that `spender` is allowed to transfer.
	///
	/// @return If the approval was successful.
	function approve(address spender, uint256 amount) external returns (bool);

	/// @notice Transfers `amount` tokens from `owner` to `recipient` using an approval that `owner` gave to `msg.sender`.
	///
	/// @notice Emits a {Approval} event.
	/// @notice Emits a {Transfer} event.
	///
	/// @param owner     The address to transfer tokens from.
	/// @param recipient The address that will receive the tokens.
	/// @param amount    The amount of tokens to transfer.
	///
	/// @return If the transfer was successful.
	function transferFrom(
		address owner,
		address recipient,
		uint256 amount
	) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IERC20Mintable {
	function mint(address _recipient, uint256 _amount) external;

	function burnFrom(address account, uint256 amount) external;
}