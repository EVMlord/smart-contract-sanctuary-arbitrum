pragma solidity >=0.8.0;
import "interfaces/IGmxRewardRouterV2.sol";
import "interfaces/IBentoBoxV1.sol";
import "interfaces/IGmxRewardTracker.sol";

library GmxLib {
    function getTrackers(address rewardRouter, bool isGlp) external view returns (address stakedTracker, address feeTracker) {
        if (!isGlp) return (IGmxRewardRouterV2(rewardRouter).stakedGmxTracker(), IGmxRewardRouterV2(rewardRouter).feeGmxTracker());
        return (IGmxRewardRouterV2(rewardRouter).stakedGlpTracker(), IGmxRewardRouterV2(rewardRouter).feeGlpTracker());
    }

    function getClaimable(address feeTracker, address user) external view returns (uint256) {
        return IGmxRewardTracker(feeTracker).claimable(user);
    }

    function unstake(IBentoBoxV1 bentoBox, IERC20 collateral, address rewardRouter, uint256 collateralShare, bool isGLP) external {
        uint256 amount = bentoBox.toAmount(collateral, collateralShare, false);
        if (!isGLP) {
            IGmxRewardRouterV2(rewardRouter).unstakeGmx(amount);
        }
        bentoBox.deposit(collateral, address(this), address(this), 0, collateralShare);
    }

    function stake(IBentoBoxV1 bentoBox, IERC20 collateral, address rewardRouter, uint256 collateralShare, bool isGLP) external {
        (uint256 amount, ) = bentoBox.withdraw(collateral, address(this), address(this), 0, collateralShare);
        if (!isGLP) {
            IGmxRewardRouterV2(rewardRouter).stakeGmx(amount);
        }
    }

    function harvest(
        address rewardRouter,
        address user,
        uint256 userCollateralShare,
        uint256 userRwardDebt,
        uint256 rewardPershare,
        uint256 totalCollateralShare
    ) external returns (uint256) {
        uint256 lastBalance = address(this).balance;
        IGmxRewardRouterV2(rewardRouter).handleRewards({
            shouldClaimGmx: true,
            shouldStakeGmx: true,
            shouldClaimEsGmx: true,
            shouldStakeEsGmx: true,
            shouldStakeMultiplierPoints: true,
            shouldClaimWeth: true,
            shouldConvertWethToEth: true
        });
        uint256 tcs = totalCollateralShare;
        if (tcs > 0) {
            rewardPershare += ((address(this).balance - lastBalance) * 1e20) / tcs;
        }
        uint256 last = userRwardDebt;
        uint256 curr = (userCollateralShare * rewardPershare) / 1e20;

        if (curr > last) {
            payable(user).call{value: curr - last, gas: 21000}("");
        }
        return rewardPershare;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGmxRewardRouterV2 {
    event StakeGlp(address account, uint256 amount);
    event StakeGmx(address account, address token, uint256 amount);
    event UnstakeGlp(address account, uint256 amount);
    event UnstakeGmx(address account, address token, uint256 amount);

    function acceptTransfer(address _sender) external;

    function batchCompoundForAccounts(address[] memory _accounts) external;

    function batchStakeGmxForAccount(address[] memory _accounts, uint256[] memory _amounts) external;

    function bnGmx() external view returns (address);

    function weth() external view returns (address);

    function bonusGmxTracker() external view returns (address);

    function claim() external;

    function claimEsGmx() external;

    function claimFees() external;

    function compound() external;

    function compoundForAccount(address _account) external;

    function esGmx() external view returns (address);

    function feeGlpTracker() external view returns (address);

    function feeGmxTracker() external view returns (address);

    function glp() external view returns (address);

    function glpManager() external view returns (address);

    function glpVester() external view returns (address);

    function gmx() external view returns (address);

    function gmxVester() external view returns (address);

    function gov() external view returns (address);

    function handleRewards(
        bool shouldClaimGmx,
        bool shouldStakeGmx,
        bool shouldClaimEsGmx,
        bool shouldStakeEsGmx,
        bool shouldStakeMultiplierPoints,
        bool shouldClaimWeth,
        bool shouldConvertWethToEth
    ) external;

    function initialize(
        address _weth,
        address _gmx,
        address _esGmx,
        address _bnGmx,
        address _glp,
        address _stakedGmxTracker,
        address _bonusGmxTracker,
        address _feeGmxTracker,
        address _feeGlpTracker,
        address _stakedGlpTracker,
        address _glpManager,
        address _gmxVester,
        address _glpVester
    ) external;

    function isInitialized() external view returns (bool);

    function pendingReceivers(address) external view returns (address);

    function setGov(address _gov) external;

    function signalTransfer(address _receiver) external;

    function stakeEsGmx(uint256 _amount) external;

    function stakeGmx(uint256 _amount) external;

    function stakeGmxForAccount(address _account, uint256 _amount) external;

    function stakedGlpTracker() external view returns (address);

    function stakedGmxTracker() external view returns (address);

    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);

    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);

    function unstakeEsGmx(uint256 _amount) external;

    function unstakeGmx(uint256 _amount) external;

    function withdrawToken(address _token, address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IStrategy.sol";

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

interface IBatchFlashBorrower {
    /// @notice The callback for batched flashloans. Every amount + fee needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param tokens Array of addresses for ERC-20 tokens that is loaned.
    /// @param amounts A one-to-one map to `tokens` that is loaned.
    /// @param fees A one-to-one map to `tokens` that needs to be paid on top for each loan. Needs to be the same token.
    /// @param data Additional data that was passed to the flashloan function.
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

interface IBentoBoxV1 {
    function balanceOf(IERC20, address) external view returns (uint256);

    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);

    function batchFlashLoan(
        IBatchFlashBorrower borrower,
        address[] calldata receivers,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function claimOwnership() external;

    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable returns (address);

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingStrategy(IERC20) external view returns (IStrategy);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerProtocol() external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setStrategy(IERC20 token, IStrategy newStrategy) external;

    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;

    function strategy(IERC20) external view returns (IStrategy);

    function strategyData(IERC20)
        external
        view
        returns (
            uint64 strategyStartDate,
            uint64 targetPercentage,
            uint128 balance
        );

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (Rebase memory totals_);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function whitelistMasterContract(address masterContract, bool approved) external;

    function whitelistedMasterContracts(address) external view returns (bool);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGmxRewardTracker {
    function rewardToken() external view returns (address);

    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface IStrategy {
    /// @notice Send the assets to the Strategy and call skim to invest them.
    /// @param amount The amount of tokens to invest.
    function skim(uint256 amount) external;

    /// @notice Harvest any profits made converted to the asset and pass them to the caller.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @param sender The address of the initiator of this transaction. Can be used for reimbursements, etc.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    /// @notice Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    /// @dev The `actualAmount` should be very close to the amount.
    /// The difference should NOT be used to report a loss. That's what harvest is for.
    /// @param amount The requested amount the caller wants to withdraw.
    /// @return actualAmount The real amount that is withdrawn.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    /// @notice Withdraw all assets in the safest way possible. This shouldn't fail.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function exit(uint256 balance) external returns (int256 amountAdded);
}