// SPDX-License-Identifier: BSL

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./DefiEdgeStrategy.sol";
import "./interfaces/IStrategyBase.sol";
import "./interfaces/IDefiEdgeStrategyDeployer.sol";

/**
 * @title DefiEdge Strategy Deployer
 * @notice The contract seperately deploys the strategy contracts and factory connects it with manager
 */

contract DefiEdgeStrategyDeployer is IDefiEdgeStrategyDeployer {
    function createStrategy(
        IStrategyFactory _factory,
        IRamsesV2Pool _pool,
        FeedRegistryInterface _chainlinkRegistry,
        IStrategyManager _manager,
        bool[2] memory _usdAsBase,
        IStrategyBase.Tick[] memory _ticks
    ) external override returns (address strategy) {
        strategy = address(new DefiEdgeStrategy(_factory, _pool, _chainlinkRegistry, _manager, _usdAsBase, _ticks));

        emit StrategyDeployed(address(strategy));
    }
}

// SPDX-License-Identifier: BSL

pragma solidity ^0.7.6;
pragma abicoder v2;

// contracts
import "./interfaces/ramses/IRamsesV2Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "./base/UniswapV3LiquidityManager.sol";

// libraries
import "./libraries/LiquidityHelper.sol";

contract DefiEdgeStrategy is UniswapV3LiquidityManager {
    using SafeMath for uint256;

    // events
    event Mint(address indexed user, uint256 share, uint256 amount0, uint256 amount1);
    event Burn(address indexed user, uint256 share, uint256 amount0, uint256 amount1);
    event Hold();
    event Rebalance(NewTick[] ticks);
    event PartialRebalance(PartialTick[] ticks);

    struct NewTick {
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0;
        uint256 amount1;
    }

    struct PartialTick {
        uint256 index;
        bool burn;
        uint256 amount0;
        uint256 amount1;
    }

    /**
     * @param _factory Address of the strategy factory
     * @param _pool Address of the pool
     * @param _chainlinkRegistry Chainlink registry address
     * @param _manager Address of the manager
     * @param _usdAsBase If the Chainlink feed is pegged with USD
     * @param _ticks Array of the ticks
     */
    constructor(
        IStrategyFactory _factory,
        IRamsesV2Pool _pool,
        FeedRegistryInterface _chainlinkRegistry,
        IStrategyManager _manager,
        bool[2] memory _usdAsBase,
        Tick[] memory _ticks
    ) {
        require(!isInvalidTicks(_ticks), "IT");
        // checks for valid ticks length
        require(_ticks.length <= MAX_TICK_LENGTH, "ITL");
        manager = _manager;
        factory = _factory;
        chainlinkRegistry = _chainlinkRegistry;
        pool = _pool;
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
        usdAsBase = _usdAsBase;
        for (uint256 i = 0; i < _ticks.length; i++) {
            ticks.push(Tick(_ticks[i].tickLower, _ticks[i].tickUpper));
        }
    }

    /**
     * @notice Adds liquidity to the primary range
     * @param _amount0 Amount of token0
     * @param _amount1 Amount of token1
     * @param _amount0Min Minimum amount of token0 to be minted
     * @param _amount1Min Minimum amount of token1 to be minted
     * @param _minShare Minimum amount of shares to be received to the user
     * @return amount0 Amount of token0 deployed
     * @return amount1 Amount of token1 deployed
     * @return share Number of shares minted
     */
    function mint(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _amount0Min,
        uint256 _amount1Min,
        uint256 _minShare
    )
        external
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 share
        )
    {
        require(!onlyValidStrategy(), "DL");
        require(manager.isUserWhiteListed(msg.sender), "UA");

        // claim rewards
        _getReward();

        // get total amounts with fees
        (uint256 totalAmount0, uint256 totalAmount1, , ) = this.getAUMWithFees(true);

        if (_amount0 > 0 && _amount1 > 0 && ticks.length > 0) {
            Tick storage tick = ticks[0];
            // index 0 will always be an primary tick
            (amount0, amount1) = mintLiquidity(tick.tickLower, tick.tickUpper, _amount0, _amount1, msg.sender);
        } else {
            amount0 = _amount0;
            amount1 = _amount1;

            if (amount0 > 0) {
                TransferHelper.safeTransferFrom(address(token0), msg.sender, address(this), amount0);
            }
            if (amount1 > 0) {
                TransferHelper.safeTransferFrom(address(token1), msg.sender, address(this), amount1);
            }
            _updateReserves(reserve0.add(amount0), reserve1.add(amount1));
        }

        // issue share based on the liquidity added
        share = issueShare(amount0, amount1, totalAmount0, totalAmount1, msg.sender);

        // prevent front running of strategy fee
        require(share >= _minShare, "SC");

        // price slippage check
        require(amount0 >= _amount0Min && amount1 >= _amount1Min, "S");

        uint256 _shareLimit = manager.limit();
        // share limit
        if (_shareLimit != 0) {
            require(totalSupply() <= _shareLimit, "L");
        }
        emit Mint(msg.sender, share, amount0, amount1);
    }

    /**
     * @notice Burn liquidity and transfer tokens back to the user
     * @param _shares Shares to be burned
     * @param _amount0Min Mimimum amount of token0 to be received
     * @param _amount1Min Minimum amount of token1 to be received
     * @return collect0 The amount of token0 returned to the user
     * @return collect1 The amount of token1 returned to the user
     */
    function burn(
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external nonReentrant returns (uint256 collect0, uint256 collect1) {
        // check if the user has sufficient shares
        require(balanceOf(msg.sender) >= _shares && _shares != 0, "INS");

        // claim rewards
        _getReward();

        uint256 amount0;
        uint256 amount1;

        // burn liquidity based on shares from existing ticks
        for (uint256 i = 0; i < ticks.length; i++) {
            Tick storage tick = ticks[i];

            uint256 fee0;
            uint256 fee1;
            // burn liquidity and collect fees
            (amount0, amount1, fee0, fee1) = burnLiquidity(tick.tickLower, tick.tickUpper, _shares, 0);

            // add to total amounts
            collect0 = collect0.add(amount0);
            collect1 = collect1.add(amount1);
        }

        // give from unused amounts
        uint256 total0 = reserve0;
        uint256 total1 = reserve1;

        uint256 _totalSupply = totalSupply();

        if (total0 > collect0) {
            collect0 = collect0.add(FullMath.mulDiv(total0 - collect0, _shares, _totalSupply));
        }

        if (total1 > collect1) {
            collect1 = collect1.add(FullMath.mulDiv(total1 - collect1, _shares, _totalSupply));
        }

        // check slippage
        require(_amount0Min <= collect0 && _amount1Min <= collect1, "S");

        // burn shares
        _burn(msg.sender, _shares);

        // transfer tokens
        if (collect0 > 0) {
            TransferHelper.safeTransfer(address(token0), msg.sender, collect0);
        }
        if (collect1 > 0) {
            TransferHelper.safeTransfer(address(token1), msg.sender, collect1);
        }

        _updateReserves(reserve0.sub(collect0), reserve1.sub(collect1));

        emit Burn(msg.sender, _shares, collect0, collect1);
    }

    /**
     * @notice Rebalances the strategy
     * @param _zeroToOne swap direction - true if swapping token0 to token1 else false
     * @param _amountIn amount of token to swap
     * @param _isOneInchSwap true if swap is happening from one inch
     * @param _swapData Swap data to perform exchange from 1inch
     * @param _existingTicks Array of existing ticks to rebalance
     * @param _newTicks New ticks in case there are any
     * @param _burnAll When burning into new ticks, should we burn all liquidity?
     */
    function rebalance(
        bool _zeroToOne,
        uint256 _amountIn,
        bool _isOneInchSwap,
        bytes calldata _swapData,
        PartialTick[] calldata _existingTicks,
        NewTick[] calldata _newTicks,
        bool _burnAll
    ) external nonReentrant {
        require(onlyOperator(), "N");
        require(!onlyValidStrategy(), "DL");

        // claim rewards
        _getReward();

        if (_burnAll) {
            require(_existingTicks.length == 0, "IA");
            onHold = true;
            burnAllLiquidity();
            delete ticks;
            emit Hold();
        }

        //swap from 1inch if needed
        if (_swapData.length > 0) {
            _swap(_zeroToOne, _amountIn, _isOneInchSwap, _swapData);
        }

        // redeploy the partial ticks
        if (_existingTicks.length > 0) {
            for (uint256 i = 0; i < _existingTicks.length; i++) {
                if (i > 0) require(_existingTicks[i - 1].index > _existingTicks[i].index, "IO"); // invalid order

                Tick memory _tick = ticks[_existingTicks[i].index];

                if (_existingTicks[i].burn) {
                    // burn liquidity from range
                    _burnLiquiditySingle(_existingTicks[i].index);
                }

                if (_existingTicks[i].amount0 > 0 || _existingTicks[i].amount1 > 0) {
                    // mint liquidity
                    mintLiquidity(_tick.tickLower, _tick.tickUpper, _existingTicks[i].amount0, _existingTicks[i].amount1, address(this));
                } else if (_existingTicks[i].burn) {
                    // shift the index element at last of array
                    ticks[_existingTicks[i].index] = ticks[ticks.length - 1];
                    // remove last element
                    ticks.pop();
                }
            }

            emit PartialRebalance(_existingTicks);
        }

        // deploy liquidity into new ticks
        if (_newTicks.length > 0) {
            redeploy(_newTicks);
            emit Rebalance(_newTicks);
        }

        require(!isInvalidTicks(ticks), "IT");
        // checks for valid ticks length
        require(ticks.length <= MAX_TICK_LENGTH + 10, "ITL");
    }

    /**
     * @notice Redeploys between ticks
     * @param _ticks Array of the ticks with amounts
     */
    function redeploy(NewTick[] memory _ticks) internal {
        require(!onlyHasDeviation(), "D");
        // set hold false
        onHold = false;
        // redeploy the liquidity
        for (uint256 i = 0; i < _ticks.length; i++) {
            NewTick memory tick = _ticks[i];

            // mint liquidity
            mintLiquidity(tick.tickLower, tick.tickUpper, tick.amount0, tick.amount1, address(this));

            // push to ticks array
            ticks.push(Tick(tick.tickLower, tick.tickUpper));
        }
    }

    /**
     * @notice Withdraws funds from the contract in case of emergency
     * @dev only governance can withdraw the funds, it can be frozen from the factory permenently
     * @param _token Token to transfer
     * @param _to Where to transfer the token
     * @param _amount Amount to be withdrawn
     * @param _newTicks Ticks data to burn liquidity from
     */
    function emergencyWithdraw(
        address _token,
        address _to,
        uint256 _amount,
        NewTick[] calldata _newTicks
    ) external {
        require(onlyGovernance() && !factory.freezeEmergency());
        if (_newTicks.length > 0) {
            for (uint256 tickIndex = 0; tickIndex < _newTicks.length; tickIndex++) {
                NewTick memory tick = _newTicks[tickIndex];
                (uint128 currentLiquidity, , , , , ) = pool.positions(PositionKey.compute(address(this), 0, tick.tickLower, tick.tickUpper));
                pool.burn(tick.tickLower, tick.tickUpper, currentLiquidity);
                pool.collect(address(this), tick.tickLower, tick.tickUpper, type(uint128).max, type(uint128).max);
            }
        }
        if (_amount > 0) {
            TransferHelper.safeTransfer(_token, _to, _amount);
        }
        _updateReserves(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    /**
     * @notice Withdraws airdropped tokens
     * @dev only governance can withdraw the funds
     * @param _token Token to transfer
     * @param _to Where to transfer the token
     */
    function airdropWithdraw(address _token, address _to) external {
        require(onlyGovernance());
        require(_token != address(token0) && _token != address(token1), "IT");

        uint256 _amount = IERC20(_token).balanceOf(address(this));
        if (_amount > 0) {
            TransferHelper.safeTransfer(_token, _to, _amount);
        }
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStrategyFactory.sol";
import "./ramses/IRamsesV2Pool.sol";
import "./IStrategyManager.sol";

interface IStrategyBase {
    struct Tick {
        int24 tickLower;
        int24 tickUpper;
    }

    event ClaimFee(uint256 managerFee, uint256 protocolFee);

    function onHold() external view returns (bool);

    function accManagementFeeShares() external view returns (uint256);

    function accPerformanceFeeShares() external view returns (uint256);

    function accProtocolPerformanceFeeShares() external view returns (uint256);

    function factory() external view returns (IStrategyFactory);

    function pool() external view returns (IRamsesV2Pool);

    function manager() external view returns (IStrategyManager);

    function usdAsBase(uint256 index) external view returns (bool);

    function claimFee() external;
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStrategyFactory.sol";
import "./IStrategyManager.sol";
import "./IStrategyBase.sol";
import "./ramses/IRamsesV2Pool.sol";
import "@chainlink/contracts/src/v0.7/interfaces/FeedRegistryInterface.sol";

interface IDefiEdgeStrategyDeployer {
    function createStrategy(
        IStrategyFactory _factory,
        IRamsesV2Pool _pool,
        FeedRegistryInterface _chainlinkRegistry,
        IStrategyManager _manager,
        bool[2] memory _usdAsBase,
        IStrategyBase.Tick[] memory _ticks
    ) external returns (address);

    event StrategyDeployed(address strategy);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./pool/IRamsesV2PoolImmutables.sol";
import "./pool/IRamsesV2PoolState.sol";
import "./pool/IRamsesV2PoolDerivedState.sol";
import "./pool/IRamsesV2PoolActions.sol";
import "./pool/IRamsesV2PoolOwnerActions.sol";
import "./pool/IRamsesV2PoolEvents.sol";

/// @title The interface for a Ramses V2 Pool
/// @notice A Ramses pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IRamsesV2Pool is
    IRamsesV2PoolImmutables,
    IRamsesV2PoolState,
    IRamsesV2PoolDerivedState,
    IRamsesV2PoolActions,
    IRamsesV2PoolOwnerActions,
    IRamsesV2PoolEvents
{
    /// @notice Initializes a pool with parameters provided
    function initialize(
        address _factory,
        address _nfpManager,
        address _veRam,
        address _voter,
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickSpacing
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

//SPDX-License-Identifier: BSL
pragma solidity ^0.7.6;
pragma abicoder v2;

// contracts
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "../base/StrategyBase.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// libraries
import "../libraries/LiquidityHelper.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

// interfaces
import "../interfaces/ramses/callback/IRamsesV2MintCallback.sol";
import "../interfaces/ISwapProxy.sol";

contract UniswapV3LiquidityManager is StrategyBase, ReentrancyGuard, IRamsesV2MintCallback {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    event Sync(uint256 reserve0, uint256 reserve1);

    event Swap(uint256 amountIn, uint256 amountOut, bool _zeroForOne);

    event FeesClaim(address indexed strategy, uint256 amount0, uint256 amount1);

    struct MintCallbackData {
        address payer;
        IRamsesV2Pool pool;
    }

    // to handle stake too deep error inside swap function
    struct LocalVariables_Balances {
        uint256 tokenInBalBefore;
        uint256 tokenOutBalBefore;
        uint256 tokenInBalAfter;
        uint256 tokenOutBalAfter;
        uint256 shareSupplyBefore;
    }

    /**
     * @notice Mints liquidity from V3 Pool
     * @param _tickLower Lower tick
     * @param _tickUpper Upper tick
     * @param _amount0 Amount of token0
     * @param _amount1 Amount of token1
     * @param _payer Address which is adding the liquidity
     * @return amount0 Amount of token0 deployed to the pool
     * @return amount1 Amount of token1 deployed to the pool
     */
    function mintLiquidity(
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _amount0,
        uint256 _amount1,
        address _payer
    ) internal returns (uint256 amount0, uint256 amount1) {
        require(!onlyHasDeviation(), "D");
        uint128 liquidity = LiquidityHelper.getLiquidityForAmounts(pool, _tickLower, _tickUpper, _amount0, _amount1);
        // add liquidity to Uniswap pool
        (amount0, amount1) = pool.mint(
            address(this),
            0,
            _tickLower,
            _tickUpper,
            liquidity,
            veRamTokenId,
            abi.encode(MintCallbackData({payer: _payer, pool: pool}))
        );
    }

    /**
     * @notice Burns liquidity in the given range
     * @param _tickLower Lower Tick
     * @param _tickUpper Upper Tick
     * @param _shares The amount of liquidity to be burned based on shares
     * @param _currentLiquidity Liquidity to be burned
     */
    function burnLiquidity(
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _shares,
        uint128 _currentLiquidity
    )
        internal
        returns (
            uint256 tokensBurned0,
            uint256 tokensBurned1,
            uint256 fee0,
            uint256 fee1
        )
    {
        require(!onlyHasDeviation(), "D");
        uint256 collect0;
        uint256 collect1;

        if (_shares > 0) {
            (_currentLiquidity, , , , , ) = pool.positions(PositionKey.compute(address(this), 0, _tickLower, _tickUpper));
            if (_currentLiquidity > 0) {
                uint256 liquidity = FullMath.mulDiv(_currentLiquidity, _shares, totalSupply());

                (tokensBurned0, tokensBurned1) = pool.burn(_tickLower, _tickUpper, liquidity.toUint128());
            }
        } else {
            (tokensBurned0, tokensBurned1) = pool.burn(_tickLower, _tickUpper, _currentLiquidity);
        }
        // collect fees
        (collect0, collect1) = pool.collect(address(this), _tickLower, _tickUpper, type(uint128).max, type(uint128).max);

        fee0 = collect0 > tokensBurned0 ? uint256(collect0).sub(tokensBurned0) : 0;
        fee1 = collect1 > tokensBurned1 ? uint256(collect1).sub(tokensBurned1) : 0;

        _updateReserves(reserve0.add(collect0), reserve1.add(collect1));

        // mint performance fees
        addPerformanceFees(fee0, fee1);
    }

    /**
     * @notice Splits and stores the performance feees in the local variables
     * @param _fee0 Amount of accumulated fee for token0
     * @param _fee1 Amount of accumulated fee for token1
     */
    function addPerformanceFees(uint256 _fee0, uint256 _fee1) internal {
        // // transfer performance fee to manager
        // uint256 performanceFeeRate = manager.performanceFeeRate();
        // address feeTo = manager.feeTo();

        // get total amounts with fees
        (uint256 totalAmount0, uint256 totalAmount1, , ) = this.getAUMWithFees(false);

        (uint256 _accPerformanceFeeShares, uint256 _accProtocolPerformanceFeeShares) = ShareHelper.calculatePerformanceFees(
            manager,
            usdAsBase,
            _fee0,
            _fee1,
            totalAmount0,
            totalAmount1
        );

        accPerformanceFeeShares = accPerformanceFeeShares.add(_accPerformanceFeeShares);
        accProtocolPerformanceFeeShares = accProtocolPerformanceFeeShares.add(_accProtocolPerformanceFeeShares);

        // accPerformanceFeeShares = accPerformanceFeeShares.add(
        //     ShareHelper.calculateShares(
        //         factory,
        //         chainlinkRegistry,
        //         pool,
        //         usdAsBase,
        //         FullMath.mulDiv(_fee0, performanceFeeRate, FEE_PRECISION),
        //         FullMath.mulDiv(_fee1, performanceFeeRate, FEE_PRECISION),
        //         totalAmount0,
        //         totalAmount1,
        //         totalSupply()
        //     )
        // );

        // // protocol performance fee
        // uint256 _protocolPerformanceFee = factory.getProtocolPerformanceFeeRate(address(pool), address(this));

        // accProtocolPerformanceFeeShares = accProtocolPerformanceFeeShares.add(
        //     ShareHelper.calculateShares(
        //         factory,
        //         chainlinkRegistry,
        //         pool,
        //         usdAsBase,
        //         FullMath.mulDiv(_fee0, _protocolPerformanceFee, FEE_PRECISION),
        //         FullMath.mulDiv(_fee1, _protocolPerformanceFee, FEE_PRECISION),
        //         totalAmount0,
        //         totalAmount1,
        //         totalSupply()
        //     )
        // );

        emit FeesClaim(address(this), _fee0, _fee1);
    }

    /**
     * @notice Burns all the liquidity and collects fees
     */
    function burnAllLiquidity() internal {
        for (uint256 _tickIndex = 0; _tickIndex < ticks.length; _tickIndex++) {
            Tick storage tick = ticks[_tickIndex];

            (uint128 currentLiquidity, , , , , ) = pool.positions(PositionKey.compute(address(this), 0, tick.tickLower, tick.tickUpper));

            if (currentLiquidity > 0) {
                burnLiquidity(tick.tickLower, tick.tickUpper, 0, currentLiquidity);
            }
        }
    }

    /**
     * @notice Burn liquidity from specific tick
     * @param _tickIndex Index of tick which needs to be burned
     * @return amount0 Amount of token0's liquidity burned
     * @return amount1 Amount of token1's liquidity burned
     * @return fee0 Fee of token0 accumulated in the position which is being burned
     * @return fee1 Fee of token1 accumulated in the position which is being burned
     */
    function burnLiquiditySingle(uint256 _tickIndex)
        public
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        )
    {
        require(!onlyHasDeviation(), "D");
        require(manager.isAllowedToBurn(msg.sender), "N");

        // claim rewards
        _getReward();

        (amount0, amount1, fee0, fee1) = _burnLiquiditySingle(_tickIndex);
        // shift the index element at last of array
        ticks[_tickIndex] = ticks[ticks.length - 1];
        // remove last element
        ticks.pop();
    }

    /**
     * @notice Burn liquidity from specific tick
     * @param _tickIndex Index of tick which needs to be burned
     */
    function _burnLiquiditySingle(uint256 _tickIndex)
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        )
    {
        Tick storage tick = ticks[_tickIndex];

        (uint128 currentLiquidity, , , , , ) = pool.positions(PositionKey.compute(address(this), 0, tick.tickLower, tick.tickUpper));

        if (currentLiquidity > 0) {
            (amount0, amount1, fee0, fee1) = burnLiquidity(tick.tickLower, tick.tickUpper, 0, currentLiquidity);
        }
    }

    /**
     * @notice Swap the funds through swap proxy
     * @param zeroToOne swap direction - true if swapping token0 to token1 else false
     * @param amountIn amount of token to swap
     * @param isOneInchSwap true if swap is happening from one inch
     * @param data Swap data to perform exchange from 1inch
     */
    function swap(bool zeroToOne, uint256 amountIn, bool isOneInchSwap, bytes calldata data) public nonReentrant {
        require(onlyOperator(), "N");
        require(!onlyValidStrategy(), "DL");
        _swap(zeroToOne, amountIn, isOneInchSwap, data);
    }

    /**
     * @notice Swap the funds to 1Inch
     * @param data Swap data to perform exchange from 1inch
     */
    function _swap(bool zeroToOne, uint256 amountIn, bool isOneInchSwap, bytes calldata data) internal {
        require(!onlyHasDeviation(), "D");
        LocalVariables_Balances memory balances;

        address swapProxy = factory.swapProxy();

        IERC20 srcToken;
        IERC20 dstToken;

        if (zeroToOne) {
            token0.safeIncreaseAllowance(swapProxy, amountIn);
            srcToken = token0;
            dstToken = token1;
        } else {
            token1.safeIncreaseAllowance(swapProxy, amountIn);
            srcToken = token1;
            dstToken = token0;
        }

        balances.tokenInBalBefore = srcToken.balanceOf(address(this));
        balances.tokenOutBalBefore = dstToken.balanceOf(address(this));
        balances.shareSupplyBefore = totalSupply();

        if(isOneInchSwap){
            ISwapProxy(swapProxy).aggregatorSwap(data);
        } else {
            // Interact with 1inch through contract call with data
            (bool success, bytes memory returnData) = address(swapProxy).call(data);

            // Verify return status and data
            if (!success) {
                uint256 length = returnData.length;
                if (length < 68) {
                    // If the returnData length is less than 68, then the transaction failed silently.
                    revert("swap");
                } else {
                    // Look for revert reason and bubble it up if present
                    uint256 t;
                    assembly {
                        returnData := add(returnData, 4)
                        t := mload(returnData) // Save the content of the length slot
                        mstore(returnData, sub(length, 4)) // Set proper length
                    }
                    string memory reason = abi.decode(returnData, (string));
                    assembly {
                        mstore(returnData, t) // Restore the content of the length slot
                    }
                    revert(reason);
                }
            }
        }

        require(balances.shareSupplyBefore == totalSupply());

        balances.tokenInBalAfter = srcToken.balanceOf(address(this));
        balances.tokenOutBalAfter = dstToken.balanceOf(address(this));

        uint256 amountInFinal = balances.tokenInBalBefore.sub(balances.tokenInBalAfter);
        uint256 amountOutFinal = balances.tokenOutBalAfter.sub(balances.tokenOutBalBefore);

        // revoke approval after swap
        if (zeroToOne) {
            token0.safeApprove(swapProxy, 0);
            _updateReserves(reserve0.sub(amountInFinal), reserve1.add(amountOutFinal));
        } else {
            token1.safeApprove(swapProxy, 0);
            _updateReserves(reserve0.add(amountOutFinal), reserve1.sub(amountInFinal));
        }

        manager.increamentSwapCounter();

        require(
            OracleLibrary.allowSwap(pool, factory, amountInFinal, amountOutFinal, address(srcToken), address(dstToken), [usdAsBase[0], usdAsBase[1]]),
            "S"
        );
    }

    /**
     * @dev Callback for Uniswap V3 pool.
     */
    function ramsesV2MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        // check if the callback is received from Uniswap V3 Pool
        if (decoded.payer == address(this)) {
            // transfer tokens already in the contract
            if (amount0 > 0) {
                TransferHelper.safeTransfer(address(token0), msg.sender, amount0);
            }
            if (amount1 > 0) {
                TransferHelper.safeTransfer(address(token1), msg.sender, amount1);
            }
            _updateReserves(reserve0.sub(amount0), reserve1.sub(amount1));
        } else {
            // take and transfer tokens to Uniswap V3 pool from the user
            if (amount0 > 0) {
                TransferHelper.safeTransferFrom(address(token0), decoded.payer, msg.sender, amount0);
            }
            if (amount1 > 0) {
                TransferHelper.safeTransferFrom(address(token1), decoded.payer, msg.sender, amount1);
            }
        }
    }

    /**
     * @notice Get's assets under management with realtime fees
     * @param _includeFee Whether to include pool fees in AUM or not. (passing true will also collect fees from pool)
     * @param amount0 Total AUM of token0 including the fees  ( if _includeFee is passed true)
     * @param amount1 Total AUM of token1 including the fees  ( if _includeFee is passed true)
     * @param totalFee0 Total fee of token0 including the fees  ( if _includeFee is passed true)
     * @param totalFee1 Total fee of token1 including the fees  ( if _includeFee is passed true)
     */
    function getAUMWithFees(bool _includeFee)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 totalFee0,
            uint256 totalFee1
        )
    {
        // get unused amounts
        amount0 = reserve0;
        amount1 = reserve1;

        // get fees accumulated in each tick
        for (uint256 i = 0; i < ticks.length; i++) {
            Tick memory tick = ticks[i];

            // get current liquidity from the pool
            (uint128 currentLiquidity, , , , , ) = pool.positions(PositionKey.compute(address(this), 0, tick.tickLower, tick.tickUpper));

            if (currentLiquidity > 0) {
                // calculate current positions in the pool from currentLiquidity
                (uint256 position0, uint256 position1) = LiquidityHelper.getAmountsForLiquidity(
                    pool,
                    tick.tickLower,
                    tick.tickUpper,
                    currentLiquidity
                );

                amount0 = amount0.add(position0);
                amount1 = amount1.add(position1);
            }

            // collect fees
            if (_includeFee && currentLiquidity > 0) {
                // update fees earned in Uniswap pool
                // Uniswap recalculates the fees and updates the variables when amount is passed as 0
                pool.burn(tick.tickLower, tick.tickUpper, 0);

                (uint256 fee0, uint256 fee1) = pool.collect(
                    address(this),
                    tick.tickLower,
                    tick.tickUpper,
                    type(uint128).max,
                    type(uint128).max
                );

                totalFee0 = totalFee0.add(fee0);
                totalFee1 = totalFee1.add(fee1);

                emit FeesClaim(address(this), totalFee0, totalFee1);
            }
        }

        _updateReserves(reserve0.add(totalFee0), reserve1.add(totalFee1));

        if (_includeFee && (totalFee0 > 0 || totalFee1 > 0)) {
            amount0 = amount0.add(totalFee0);
            amount1 = amount1.add(totalFee1);

            // mint performance fees
            addPerformanceFees(totalFee0, totalFee1);
        }
    }

    // update reserves
    function _updateReserves(uint256 balance0, uint256 balance1) internal {
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(reserve0, reserve1);
    }

    // force balances to match reserves
    function skim(address to) external {
        require(onlyOperator());
        TransferHelper.safeTransfer(address(token0), to, token0.balanceOf(address(this)).sub(reserve0));
        TransferHelper.safeTransfer(address(token1), to, token1.balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external {
        require(onlyOperator());
        _updateReserves(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    // claim rewards from ramses gauge
    function _getReward() internal {
        (IGaugeV2 gauge, address receiver, address[] memory rewardTokens) = manager.getRewardParameters();
        //claim rewards for all positions
        for (uint256 i = 0; i < ticks.length; i++) {
            gauge.getReward(address(this), uint256(0), ticks[i].tickLower, ticks[i].tickUpper, rewardTokens, receiver);
        }
    }

    // claim rewards from ramses gauge
    function getReward() external {
        _getReward();
    }

    // change veRAM token id to attach with ramses pool
    function transferVeRamTokenId(uint256 _newVeRamTokenId) external {
        require(onlyOperator());
        veRamTokenId = _newVeRamTokenId;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

// contracts
import "@openzeppelin/contracts/math/SafeMath.sol";

// libraries
import "../interfaces/ramses/IRamsesV2Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

library LiquidityHelper {
    using SafeMath for uint256;

    /**
     * @notice Calculates the liquidity amount using current ranges
     * @param _pool Pool instance
     * @param _tickLower Lower tick
     * @param _tickUpper Upper tick
     * @param _amount0 Amount to be added for token0
     * @param _amount1 Amount to be added for token1
     * @return liquidity Liquidity amount derived from token amounts
     */
    function getLiquidityForAmounts(
        IRamsesV2Pool _pool,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _amount0,
        uint256 _amount1
    ) public view returns (uint128 liquidity) {
        // get sqrtRatios required to calculate liquidity
        (uint160 sqrtRatioX96, , , , , , ) = _pool.slot0();

        // calculate liquidity needs to be added
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(_tickLower),
            TickMath.getSqrtRatioAtTick(_tickUpper),
            _amount0,
            _amount1
        );
    }

    /**
     * @notice Calculates the liquidity amount using current ranges
     * @param _pool Instance of the pool
     * @param _tickLower Lower tick
     * @param _tickUpper Upper tick
     * @param _liquidity Liquidity of the pool
     */
    function getAmountsForLiquidity(
        IRamsesV2Pool _pool,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity
    ) public view returns (uint256 amount0, uint256 amount1) {
        // get sqrtRatios required to calculate liquidity
        (uint160 sqrtRatioX96, , , , , , ) = _pool.slot0();

        // calculate liquidity needs to be added
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(_tickLower),
            TickMath.getSqrtRatioAtTick(_tickUpper),
            _liquidity
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IRamsesV2PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IRamsesV2Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The contract that manages RamsesV2 NFPs, which must adhere to the INonfungiblePositionManager interface
    /// @return The contract address
    function nfpManager() external view returns (address);

    /// @notice The contract that manages veRamses NFTs, which must adhere to the IVotinEscrow interface
    /// @return The contract address
    function veRam() external view returns (address);

    /// @notice The contract that manages Ramses votes, which must adhere to the IVoter interface
    /// @return The contract address
    function voter() external view returns (address);

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
interface IRamsesV2PoolState {
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

    /// @notice Returns the last tick of a given period
    /// @param period The period in question
    /// @return previousPeriod The period before current period
    /// @dev this is because there might be periods without trades
    ///  startTick The start tick of the period
    ///  lastTick The last tick of the period, if the period is finished
    ///  endSecondsPerLiquidityPeriodX128 Seconds per liquidity at period's end
    ///  endSecondsPerBoostedLiquidityPeriodX128 Seconds per boosted liquidity at period's end
    function periods(
        uint256 period
    )
        external
        view
        returns (
            uint32 previousPeriod,
            int24 startTick,
            int24 lastTick,
            uint160 endSecondsPerLiquidityCumulativeX128,
            uint160 endSecondsPerBoostedLiquidityCumulativeX128
        );

    /// @notice The last period where a trade or liquidity change happened
    function lastPeriod() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees()
        external
        view
        returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice The currently in range derived liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function boostedLiquidity() external view returns (uint128);

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
    function ticks(
        int24 tick
    )
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint128 boostedLiquidityGross,
            int128 boostedLiquidityNet,
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
    /// Returns attachedVeRamId the veRam tokenId attached to the position
    function positions(
        bytes32 key
    )
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1,
            uint256 attachedVeRamId
        );

    /// @notice Returns a period's total boost amount and total veRam attached
    /// @param period Period timestamp
    /// @return totalBoostAmount The total amount of boost this period has,
    /// Returns totalVeRamAmount The total amount of veRam attached to this period
    function boostInfos(
        uint256 period
    ) external view returns (uint128 totalBoostAmount, int128 totalVeRamAmount);

    /// @notice Returns the veRam tokenId a position has attached
    /// @param positionHash The position's hash
    function attachedVeRamTokenId(
        bytes32 positionHash
    ) external view returns (uint256);

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(
        uint256 index
    )
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized,
            uint160 secondsPerBoostedLiquidityPeriodX128
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IRamsesV2PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerBoostedLiquidityPeriodX128s Cumulative seconds per boosted liquidity-in-range value as of each `secondsAgos` from the current block timestamp
    function observe(
        uint32[] calldata secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s,
            uint160[] memory secondsPerBoostedLiquidityPeriodX128s
        );

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsPerBoostedLiquidityInsideX128 The snapshot of seconds per boosted liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint160 secondsPerBoostedLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IRamsesV2PoolActions {
    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position at index 0
    /// @dev The caller of this method receives a callback in the form of IRamsesV2MintCallback#ramsesV2MintCallback
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

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IRamsesV2MintCallback#ramsesV2MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param index The index for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param veRamTokenId The veRam tokenId to attach to the position
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 veRamTokenId,
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

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param index The index of the position to be collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position at index 0
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

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param index The index for which the liquidity will be burned
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IRamsesV2SwapCallback#ramsesV2SwapCallback
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
    /// @dev The caller of this method receives a callback in the form of IRamsesV2FlashCallback#ramsesV2FlashCallback
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
    function increaseObservationCardinalityNext(
        uint16 observationCardinalityNext
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IRamsesV2PoolOwnerActions {
    /// @notice Set the protocol's % share of the fees
    /// @dev Fees start at 50%, with 5% increments
    function setFeeProtocol() external;

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

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IRamsesV2PoolEvents {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
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
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: BSL
pragma solidity ^0.7.6;
pragma abicoder v2;

// contracts
import "../ERC20.sol";

// libraries
import "../libraries/ShareHelper.sol";
import "../libraries/OracleLibrary.sol";

contract StrategyBase is ERC20, IStrategyBase {
    using SafeMath for uint256;

    uint256 public constant FEE_PRECISION = 1e8;
    bool public override onHold;

    uint256 public constant MINIMUM_LIQUIDITY = 1e12;

    // store ticks
    Tick[] public ticks;

    uint256 public override accManagementFeeShares; // stores the management fee shares
    uint256 public override accPerformanceFeeShares; // stores the performance fee shares
    uint256 public override accProtocolPerformanceFeeShares; // stores the protocol performance fee shares

    IStrategyFactory public override factory; // instance of the strategy factory
    IRamsesV2Pool public override pool; // instance of the Uniswap V3 pool

    IERC20 internal token0;
    IERC20 internal token1;

    FeedRegistryInterface internal chainlinkRegistry;

    IStrategyManager public override manager; // instance of manager contract

    bool[2] public override usdAsBase; // for Chainlink oracle

    uint256 public constant MAX_TICK_LENGTH = 20;

    uint256 public reserve0; // reserve for token0 balance
    uint256 public reserve1; // reserve for token1 balance

    uint256 public veRamTokenId;
    
    // Modifiers
    function onlyOperator() internal view returns(bool isOperator){
        if(manager.isAllowedToManage(msg.sender)){
            isOperator = true;
        }
    }

    /**
     * @dev Replaces old ticks with new ticks
     * @param _ticks New ticks
     * @return invalid true if the ticks are valid and not repeated
     */
    function isInvalidTicks(Tick[] memory _ticks) internal pure returns (bool invalid) {
        for (uint256 i = 0; i < _ticks.length; i++) {
            int24 tickLower = _ticks[i].tickLower;
            int24 tickUpper = _ticks[i].tickUpper;

            // check that two tick upper and tick lowers are not in array cannot be same
            for (uint256 j = 0; j < i; j++) {
                if (tickLower == _ticks[j].tickLower) {
                    if (tickUpper == _ticks[j].tickUpper) {
                        invalid = true;
                        return invalid;
                    }
                }
            }
        }
    }

    /**
     * @dev Checks if it's valid strategy or not
     */
    function onlyValidStrategy() internal view returns (bool isInvalidStrategy){
        // check if strategy is in denylist
        if(factory.denied(address(this))){
            isInvalidStrategy = true;
        }
    }

    /**
     * @dev checks if the pool is manipulated
     */
    function onlyHasDeviation() internal view returns (bool hasDeviation){
        if(OracleLibrary.hasDeviation(factory, pool, chainlinkRegistry, usdAsBase, address(manager))){
            hasDeviation = true;
        }
    }

    /**
     * @dev checks if caller is governance
     */
    function onlyGovernance() internal view returns(bool isGov){
        if(msg.sender == factory.governance()){
            isGov = true;
        }
    }


    /**
     * @notice Updates the shares of the user
     * @param _amount0 Amount of token0
     * @param _amount1 Amount of token1
     * @param _totalAmount0 Total amount0 in the specific strategy
     * @param _totalAmount1 Total amount1 in the specific strategy
     * @param _user address where shares should be issued
     * @return share Number of shares issued
     */
    function issueShare(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _totalAmount0,
        uint256 _totalAmount1,
        address _user
    ) internal returns (uint256 share) {
        uint256 _shareTotalSupply = totalSupply();
        // calculate number of shares
        share = ShareHelper.calculateShares(
            factory,
            chainlinkRegistry,
            pool,
            usdAsBase,
            _amount0,
            _amount1,
            _totalAmount0,
            _totalAmount1,
            _shareTotalSupply
        );

        uint256 managerShare;
        uint256 managementFeeRate = manager.managementFeeRate();

        if (_shareTotalSupply == 0) {
            share = share.sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
        }

        // strategy owner fees
        if (managementFeeRate > 0) {
            managerShare = share.mul(managementFeeRate).div(FEE_PRECISION);
            accManagementFeeShares = accManagementFeeShares.add(managerShare);
            share = share.sub(managerShare);
        }

        // issue shares
        _mint(_user, share);
    }

    /**
     * @notice Adds all the shares stored in the state variables
     * @return total supply of shares, including virtual supply
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply.add(accManagementFeeShares).add(accPerformanceFeeShares).add(accProtocolPerformanceFeeShares);
    }

    /**
     * @notice Claims the fee for protocol and management
     * Protocol receives X percentage from manager fee
     */
    function claimFee() external override {
        (address managerFeeTo, address protocolFeeTo, uint256 managerShare, uint256 protocolShare) = ShareHelper.calculateFeeShares(
            factory,
            manager,
            accManagementFeeShares,
            accPerformanceFeeShares,
            accProtocolPerformanceFeeShares
        );

        if (managerShare > 0) {
            _mint(managerFeeTo, managerShare);
        }

        if (protocolShare > 0) {
            _mint(protocolFeeTo, protocolShare);
        }

        // set the variables to 0
        accManagementFeeShares = 0;
        accPerformanceFeeShares = 0;
        accProtocolPerformanceFeeShares = 0;

        emit ClaimFee(managerShare, protocolShare);
    }

    /**
     * @notice Returns the current ticks
     * @return Array of the ticks
     */
    function getTicks() public view returns (Tick[] memory) {
        return ticks;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    constructor () {
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IRamsesV2PoolActions#mint
/// @notice Any contract that calls IRamsesV2PoolActions#mint must implement this interface
interface IRamsesV2MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IRamsesV2Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a RamsesV2Pool deployed by the canonical RamsesV2Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IRamsesV2PoolActions#mint call
    function ramsesV2MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

interface ISwapProxy {
    function aggregatorSwap(bytes calldata swapData) external;
    function isAllowedOneInchCaller(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
abstract contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) public override allowance; // map approval of from to to address

    uint256 internal _totalSupply;

    bytes32 public constant name = "DefiEdge Share";
    bytes32 public constant symbol = "DEShare";
    uint8 public constant decimals = 18;

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        _approve(
            sender,
            _msgSender(),
            allowance[sender][_msgSender()].sub(amount, "a")
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            allowance[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            allowance[_msgSender()][spender].sub(subtractedValue, "a")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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
        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "b");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
}

//SPDX-License-Identifier: BSL
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/ramses/IRamsesV2Pool.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

import "./OracleLibrary.sol";

library ShareHelper {
    using SafeMath for uint256;

    uint256 public constant DIVISOR = 100e18;

    uint256 public constant FEE_PRECISION = 1e8;

    struct LocalVariables_Inputs {
        IStrategyFactory _factory;
        FeedRegistryInterface _registry;
        IStrategyBase _strategy;
        IRamsesV2Pool _pool;
        uint256 _totalShares;
        uint256 _performanceFeeRate;
        uint256 _protocolPerformanceFee;
    }

    /**
     * @dev Calculates the shares to be given for specific position
     * @param _registry Chainlink registry interface
     * @param _pool The token0
     * @param _isBase Is USD used as base
     * @param _amount0 Amount of token0
     * @param _amount1 Amount of token1
     * @param _totalAmount0 Total amount of token0
     * @param _totalAmount1 Total amount of token1
     * @param _totalShares Total Number of shares
     */
    function calculateShares(
        IStrategyFactory _factory,
        FeedRegistryInterface _registry,
        IRamsesV2Pool _pool,
        bool[2] memory _isBase,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _totalAmount0,
        uint256 _totalAmount1,
        uint256 _totalShares
    ) public view returns (uint256 share) {
        share = _calculateShares(_factory, _registry, _pool, _isBase, _amount0, _amount1, _totalAmount0, _totalAmount1, _totalShares);
    }

    /**
     * @notice Calculates the fee shares from accumulated fees
     * @param _factory Strategy factory address
     * @param _manager Strategy manager contract address
     * @param _accManagementFee Accumulated management fees in terms of shares, decimal 18
     * @param _accPerformanceFee Accumulated performance fee in terms of shares, decimal 18
     * @param _accProtocolPerformanceFee Accumulated performance fee in terms of shares, decimal 18
     */
    function calculateFeeShares(
        IStrategyFactory _factory,
        IStrategyManager _manager,
        uint256 _accManagementFee,
        uint256 _accPerformanceFee,
        uint256 _accProtocolPerformanceFee
    ) public view returns (address managerFeeTo, address protocolFeeTo, uint256 managerShare, uint256 protocolShare) {
        uint256 managementProtocolShare;
        uint256 managementManagerShare;
        uint256 protocolFeeRate = _factory.protocolFeeRate();

        // calculate the fees for protocol and manager from management fees
        if (_accManagementFee > 0) {
            managementProtocolShare = FullMath.mulDiv(_accManagementFee, protocolFeeRate, 1e8);
            managementManagerShare = _accManagementFee.sub(managementProtocolShare);
        }

        // calculate the fees for protocol and manager from performance fees
        if (_accPerformanceFee > 0) {
            protocolShare = FullMath.mulDiv(_accPerformanceFee, protocolFeeRate, 1e8);
            managerShare = _accPerformanceFee.sub(protocolShare);
        }

        managerShare = managementManagerShare.add(managerShare);
        protocolShare = managementProtocolShare.add(protocolShare).add(_accProtocolPerformanceFee);

        // moved here for saving bytecode
        managerFeeTo = _manager.feeTo();
        protocolFeeTo = _factory.feeTo();
    }

    function calculatePerformanceFees(
        IStrategyManager _manager,
        bool[2] memory _isBase,
        uint256 _fee0,
        uint256 _fee1,
        uint256 _totalAmount0,
        uint256 _totalAmount1
    ) public view returns (uint256 _accPerformanceFeeShares, uint256 _accProtocolPerformanceFeeShares) {
        LocalVariables_Inputs memory inputs;

        inputs._factory = _manager.factory();
        inputs._registry = inputs._factory.chainlinkRegistry();
        inputs._strategy = IStrategyBase(_manager.strategy());
        inputs._pool = inputs._strategy.pool();
        inputs._totalShares = IERC20Minimal(address(inputs._strategy)).totalSupply();

        // transfer performance fee to manager
        inputs._performanceFeeRate = _manager.performanceFeeRate();

        // protocol performance fee
        inputs._protocolPerformanceFee = inputs._factory.getProtocolPerformanceFeeRate(address(inputs._pool), address(inputs._strategy));

        // calculate manager performance fees
        if (inputs._performanceFeeRate > 0) {
            _accPerformanceFeeShares = _calculateShares(
                inputs._factory,
                inputs._registry,
                inputs._pool,
                _isBase,
                FullMath.mulDiv(_fee0, inputs._performanceFeeRate, FEE_PRECISION),
                FullMath.mulDiv(_fee1, inputs._performanceFeeRate, FEE_PRECISION),
                _totalAmount0,
                _totalAmount1,
                inputs._totalShares
            );
        }

        // calculate protocol performance fees
        if (inputs._protocolPerformanceFee > 0) {
            _accProtocolPerformanceFeeShares = _calculateShares(
                inputs._factory,
                inputs._registry,
                inputs._pool,
                _isBase,
                FullMath.mulDiv(_fee0, inputs._protocolPerformanceFee, FEE_PRECISION),
                FullMath.mulDiv(_fee1, inputs._protocolPerformanceFee, FEE_PRECISION),
                _totalAmount0,
                _totalAmount1,
                inputs._totalShares
            );
        }
    }

    function _calculateShares(
        IStrategyFactory _factory,
        FeedRegistryInterface _registry,
        IRamsesV2Pool _pool,
        bool[2] memory _isBase,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _totalAmount0,
        uint256 _totalAmount1,
        uint256 _totalShares
    ) internal view returns (uint256 share) {
        address _token0 = _pool.token0();
        address _token1 = _pool.token1();

        _amount0 = OracleLibrary.normalise(_token0, _amount0);
        _amount1 = OracleLibrary.normalise(_token1, _amount1);
        _totalAmount0 = OracleLibrary.normalise(_token0, _totalAmount0);
        _totalAmount1 = OracleLibrary.normalise(_token1, _totalAmount1);

        // price in USD
        uint256 token0Price = OracleLibrary.getPriceInUSD(_factory, _registry, _token0, _isBase[0]);

        uint256 token1Price = OracleLibrary.getPriceInUSD(_factory, _registry, _token1, _isBase[1]);

        if (_totalShares > 0) {
            uint256 numerator = (token0Price.mul(_amount0)).add(token1Price.mul(_amount1));

            uint256 denominator = (token0Price.mul(_totalAmount0)).add(token1Price.mul(_totalAmount1));

            share = FullMath.mulDiv(numerator, _totalShares, denominator);
        } else {
            share = ((token0Price.mul(_amount0)).add(token1Price.mul(_amount1))).div(DIVISOR);
        }
    }
}

//SPDX-License-Identifier: BSL
pragma solidity 0.7.6;
pragma abicoder v2;

// contracts
import "@chainlink/contracts/src/v0.7/Denominations.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

// libraries
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "./PositionKey.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "./CommonMath.sol";

// interfaces
import "@chainlink/contracts/src/v0.7/interfaces/FeedRegistryInterface.sol";
import "../interfaces/ramses/IRamsesV2Pool.sol";
import "../interfaces/IStrategyFactory.sol";
import "../interfaces/IStrategyManager.sol";
import "../interfaces/IERC20Minimal.sol";

library OracleLibrary {
    uint256 public constant BASE = 1e18;

    using SafeMath for uint256;

    function normalise(address _token, uint256 _amount) internal view returns (uint256 normalised) {
        // return uint256(_amount) * (10**(18 - IERC20Minimal(_token).decimals()));
        normalised = _amount;
        uint256 _decimals = IERC20Minimal(_token).decimals();

        if (_decimals < 18) {
            uint256 missingDecimals = uint256(18).sub(_decimals);
            normalised = uint256(_amount).mul(10**(missingDecimals));
        } else if (_decimals > 18) {
            uint256 extraDecimals = _decimals.sub(uint256(18));
            normalised = uint256(_amount).div(10**(extraDecimals));
        }
    }

    /**
     * @notice Gets latest Uniswap price in the pool, price of token1 represented in token0
     * @notice _pool Address of the Uniswap V3 pool
     */
    function getUniswapPrice(IRamsesV2Pool _pool) internal view returns (uint256 price) {
        (uint160 sqrtPriceX96, , , , , , ) = _pool.slot0();
        uint256 priceX192 = uint256(sqrtPriceX96).mul(sqrtPriceX96);
        price = FullMath.mulDiv(priceX192, BASE, 1 << 192);

        uint256 token0Decimals = IERC20Minimal(_pool.token0()).decimals();
        uint256 token1Decimals = IERC20Minimal(_pool.token1()).decimals();

        bool decimalCheck = token0Decimals > token1Decimals;

        uint256 decimalsDelta = decimalCheck ? token0Decimals - token1Decimals : token1Decimals - token0Decimals;

        // normalise the price to 18 decimals

        if (token0Decimals == token1Decimals) {
            return price;
        }

        if (decimalCheck) {
            price = price.mul(CommonMath.safePower(10, decimalsDelta));
        } else {
            price = price.div(CommonMath.safePower(10, decimalsDelta));
        }
    }

    /**
     * @notice Returns latest Chainlink price, and normalise it
     * @param _registry registry
     * @param _base Base Asset
     * @param _quote Quote Asset
     */
    function getChainlinkPrice(
        FeedRegistryInterface _registry,
        address _base,
        address _quote,
        uint256 _validPeriod
    ) internal view returns (uint256 price) {
        (, int256 _price, , uint256 updatedAt, ) = _registry.latestRoundData(_base, _quote);

        require(block.timestamp.sub(updatedAt) < _validPeriod, "OLD_PRICE");

        if (_price <= 0) {
            return 0;
        }

        // normalise the price to 18 decimals
        uint256 _decimals = _registry.decimals(_base, _quote);

        if (_decimals < 18) {
            uint256 missingDecimals = uint256(18).sub(_decimals);
            price = uint256(_price).mul(10**(missingDecimals));
        } else if (_decimals > 18) {
            uint256 extraDecimals = _decimals.sub(uint256(18));
            price = uint256(_price).div(10**(extraDecimals));
        }

        return price;
    }

    /**
     * @notice Gets price in USD, if USD feed is not available use ETH feed
     * @param _registry Interface of the Chainlink registry
     * @param _token the token we want to convert into USD
     * @param _isBase if the token supports base as USD or requires conversion from ETH
     */
    function getPriceInUSD(
        IStrategyFactory _factory,
        FeedRegistryInterface _registry,
        address _token,
        bool _isBase
    ) internal view returns (uint256 price) {
        if (_isBase) {
            price = getChainlinkPrice(_registry, _token, Denominations.USD, _factory.getHeartBeat(_token, Denominations.USD));
        } else {
            price = getChainlinkPrice(_registry, _token, Denominations.ETH, _factory.getHeartBeat(_token, Denominations.ETH));

            price = FullMath.mulDiv(
                price,
                getChainlinkPrice(
                    _registry,
                    Denominations.ETH,
                    Denominations.USD,
                    _factory.getHeartBeat(Denominations.ETH, Denominations.USD)
                ),
                BASE
            );
        }
    }

    /**
     * @notice Checks if the the current price has deviation from the pool price
     * @param _pool Address of the pool
     * @param _registry Chainlink registry interface
     * @param _usdAsBase checks if pegged to USD
     * @param _manager Manager contract address to check allowed deviation
     */
    function hasDeviation(
        IStrategyFactory _factory,
        IRamsesV2Pool _pool,
        FeedRegistryInterface _registry,
        bool[2] memory _usdAsBase,
        address _manager
    ) public view returns (bool) {
        // get price of token0 Uniswap and convert it to USD
        uint256 uniswapPriceInUSD = FullMath.mulDiv(
            getUniswapPrice(_pool),
            getPriceInUSD(_factory, _registry, _pool.token1(), _usdAsBase[1]),
            BASE
        );

        // get price of token0 from Chainlink in USD
        uint256 chainlinkPriceInUSD = getPriceInUSD(_factory, _registry, _pool.token0(), _usdAsBase[0]);

        uint256 diff;

        diff = FullMath.mulDiv(uniswapPriceInUSD, BASE, chainlinkPriceInUSD);

        uint256 _allowedDeviation = IStrategyManager(_manager).allowedDeviation();

        // check if the price is above deviation and return
        return diff > BASE.add(_allowedDeviation) || diff < BASE.sub(_allowedDeviation);
    }

    // /**
    //  * @notice Checks the if swap exceed allowed swap deviation or not
    //  * @param _pool Address of the pool
    //  * @param _registry Chainlink registry interface
    //  * @param _amountIn Amount to be swapped
    //  * @param _amountOut Amount received after swap
    //  * @param _tokenIn Token to be swapped
    //  * @param _tokenOut Token to which tokenIn should be swapped
    //  * @param _usdAsBase checks if pegged to USD
    //  * @param _manager Manager contract address to check allowed deviation
    //  */
    // function isSwapExceedDeviation(
    //     IStrategyFactory _factory,
    //     IUniswapV3Pool _pool,
    //     FeedRegistryInterface _registry,
    //     uint256 _amountIn,
    //     uint256 _amountOut,
    //     address _tokenIn,
    //     address _tokenOut,
    //     bool[2] memory _usdAsBase,
    //     address _manager
    // ) public view returns (bool) {
    //     _amountIn = normalise(_tokenIn, _amountIn);
    //     _amountOut = normalise(_tokenOut, _amountOut);

    //     (bool usdAsBaseAmountIn, bool usdAsBaseAmountOut) = _pool.token0() == _tokenIn
    //         ? (_usdAsBase[0], _usdAsBase[1])
    //         : (_usdAsBase[1], _usdAsBase[0]);

    //     // get tokenIn prce in USD fron chainlink
    //     uint256 amountInUSD = _amountIn.mul(getPriceInUSD(_factory, _registry, _tokenIn, usdAsBaseAmountIn));

    //     // get tokenout prce in USD fron chainlink
    //     uint256 amountOutUSD = _amountOut.mul(getPriceInUSD(_factory, _registry, _tokenOut, usdAsBaseAmountOut));

    //     uint256 diff;

    //     diff = amountInUSD.div(amountOutUSD.div(BASE));

    //     // check price deviation
    //     uint256 deviation;
    //     if (diff > BASE) {
    //         deviation = diff.sub(BASE);
    //     } else {
    //         deviation = BASE.sub(diff);
    //     }

    //     if (deviation > IStrategyManager(_manager).allowedSwapDeviation()) {
    //         return true;
    //     }
    //     return false;
    // }

    /**
     * @notice Checks for price slippage at the time of swap
     * @param _pool Address of the pool
     * @param _factory Address of the DefiEdge strategy factory
     * @param _amountIn Amount to be swapped
     * @param _amountOut Amount received after swap
     * @param _tokenIn Token to be swapped
     * @param _tokenOut Token to which tokenIn should be swapped
     * @param _isBase to take token as bas etoken or not
     * @return true if the swap is allowed, else false
     */
    function allowSwap(
        IRamsesV2Pool _pool,
        IStrategyFactory _factory,
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        bool[2] memory _isBase
    ) public view returns (bool) {
        _amountIn = normalise(_tokenIn, _amountIn);
        _amountOut = normalise(_tokenOut, _amountOut);

        (bool usdAsBaseAmountIn, bool usdAsBaseAmountOut) = _pool.token0() == _tokenIn
            ? (_isBase[0], _isBase[1])
            : (_isBase[1], _isBase[0]);

        // get price of token0 Uniswap and convert it to USD
        uint256 amountInUSD = _amountIn.mul(
            getPriceInUSD(_factory, FeedRegistryInterface(_factory.chainlinkRegistry()), _tokenIn, usdAsBaseAmountIn)
        );

        // get price of token0 Uniswap and convert it to USD
        uint256 amountOutUSD = _amountOut.mul(
            getPriceInUSD(_factory, FeedRegistryInterface(_factory.chainlinkRegistry()), _tokenOut, usdAsBaseAmountOut)
        );

        uint256 diff;

        diff = amountInUSD.div(amountOutUSD.div(BASE));

        uint256 _allowedSlippage = _factory.allowedSlippage(address(_pool));
        // check if the price is above deviation
        if (diff > (BASE.add(_allowedSlippage)) || diff < (BASE.sub(_allowedSlippage))) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
pragma solidity >=0.4.0;

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
            require(denominator > 0);
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
        uint256 twos = -denominator & denominator;
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
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(address owner, uint256 index, int24 tickLower, int24 tickUpper) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, index, tickLower, tickUpper));
    }
}

//SPDX-License-Identifier: BSL

pragma solidity ^0.7.6;

/*
    Copyright 2018 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
import "@openzeppelin/contracts/math/SafeMath.sol";

library CommonMath {
    using SafeMath for uint256;

    /**
     * Calculates and returns the maximum value for a uint256
     *
     * @return  The maximum value for uint256
     */
    function maxUInt256() internal pure returns (uint256) {
        return 2**256 - 1;
    }

    /**
     * @dev Performs the power on a specified value, reverts on overflow.
     */
    function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
        require(a > 0);

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++) {
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }

    /**
     * Checks for rounding errors and returns value of potential partial amounts of a principal
     *
     * @param  _principal       Number fractional amount is derived from
     * @param  _numerator       Numerator of fraction
     * @param  _denominator     Denominator of fraction
     * @return uint256          Fractional amount of principal calculated
     */
    function getPartialAmount(
        uint256 _principal,
        uint256 _numerator,
        uint256 _denominator
    ) internal pure returns (uint256) {
        // Get remainder of partial amount (if 0 not a partial amount)
        uint256 remainder = mulmod(_principal, _numerator, _denominator);

        // Return if not a partial amount
        if (remainder == 0) {
            return _principal.mul(_numerator).div(_denominator);
        }

        // Calculate error percentage
        uint256 errPercentageTimes1000000 = remainder.mul(1000000).div(
            _numerator.mul(_principal)
        );

        // Require error percentage is less than 0.1%.
        require(
            errPercentageTimes1000000 < 1000,
            "CommonMath.getPartialAmount: Rounding error exceeds bounds"
        );

        return _principal.mul(_numerator).div(_denominator);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(
    address base,
    address quote
  )
    external
    view
    returns (
      uint8
    );

  function description(
    address base,
    address quote
  )
    external
    view
    returns (
      string memory
    );

  function version(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256
    );

  function latestRoundData(
    address base,
    address quote
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

  function getRoundData(
    address base,
    address quote,
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

  // V2 AggregatorInterface

  function latestAnswer(
    address base,
    address quote
  )
    external
    view
    returns (
      int256 answer
    );

  function latestTimestamp(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 timestamp
    );

  function latestRound(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 roundId
    );

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      int256 answer
    );

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      uint256 timestamp
    );

  // Registry getters

  function getFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function isFeedEnabled(
    address aggregator
  )
    external
    view
    returns (
      bool
    );

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      Phase memory phase
    );

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    );

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 previousRoundId
    );

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 nextRoundId
    );

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface proposedAggregator
    );

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(
    address base,
    address quote
  )
    external
    view
    returns (
      uint16 currentPhaseId
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ramses/IRamsesV2Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@chainlink/contracts/src/v0.7/interfaces/FeedRegistryInterface.sol";
import "./IStrategyBase.sol";
import "./IDefiEdgeStrategyDeployer.sol";

interface IStrategyFactory {
    struct CreateStrategyParams {
        // address of the strategy operator (manager)
        address operator;
        // address where all the strategy's fees should go
        address feeTo;
        // management fee rate, 1e8 is 100%
        uint256 managementFeeRate;
        // performance fee rate, 1e8 is 100%
        uint256 performanceFeeRate;
        // limit in the form of shares
        uint256 limit;
        // address of the pool
        IRamsesV2Pool pool;
        // Chainlink's pair with USD, if token0 has pair with USD it should be true and v.v. same for token1
        bool[2] usdAsBase;
        // initial ticks to setup
        IStrategyBase.Tick[] ticks;
    }

    function totalIndex() external view returns (uint256);

    function strategyCreationFee() external view returns (uint256); // fee for strategy creation in native token

    function defaultAllowedSlippage() external view returns (uint256); // 1e18 means 100%

    function defaultAllowedDeviation() external view returns (uint256); // 1e18 means 100%

    function defaultAllowedSwapDeviation() external view returns (uint256); // 1e18 means 100%

    function allowedDeviation(address _pool) external view returns (uint256); // 1e18 means 100%

    function allowedSwapDeviation(address _pool) external view returns (uint256); // 1e18 means 100%

    function allowedSlippage(address _pool) external view returns (uint256); // 1e18 means 100%

    function isValidStrategy(address) external view returns (bool);
    
    function swapProxy() external view returns (address);

    function strategyByIndex(uint256) external view returns (address);

    function strategyByManager(address) external view returns (address);

    function feeTo() external view returns (address);

    function denied(address) external view returns (bool);

    function protocolFeeRate() external view returns (uint256); // 1e8 means 100%

    function protocolPerformanceFeeRateByPool(address) external view returns (uint256); // 1e8 means 100%

    function protocolPerformanceFeeRateByStrategy(address) external view returns (uint256); // 1e8 means 100%

    function defaultProtocolPerformanceFeeRate() external view returns (uint256); // 1e8 means 100%

    function getProtocolPerformanceFeeRate(address pool, address strategy) external view returns(uint256 _feeRate); // 1e8 means 100% 

    function governance() external view returns (address);

    function pendingGovernance() external view returns (address);

    function deployerProxy() external view returns (IDefiEdgeStrategyDeployer);

    function uniswapV3Factory() external view returns (IUniswapV3Factory);

    function chainlinkRegistry() external view returns (FeedRegistryInterface);

    function freezeEmergency() external view returns (bool);

    function getHeartBeat(address _base, address _quote) external view returns (uint256);

    function createStrategy(CreateStrategyParams calldata params) external payable;

    function freezeEmergencyFunctions() external;

    function changeAllowedSlippage(address, uint256) external;

    function changeAllowedDeviation(address, uint256) external;

    function changeAllowedSwapDeviation(address, uint256) external;

    function changeDefaultValues(
        uint256,
        uint256,
        uint256
    ) external;

    event NewStrategy(address indexed strategy, address indexed creater);
    event ChangeProtocolFee(uint256 fee);
    event ChangeProtocolPerformanceFee(address strategyOrPool, uint256 _feeRate);
    event StrategyStatusChanged(bool status);
    event ChangeStrategyCreationFee(uint256 amount);
    event ClaimFees(address to, uint256 amount);
    event ChangeAllowedSlippage(address pool, uint256 value);
    event ChangeAllowedDeviation(address pool, uint256 value);
    event ChangeAllowedSwapDeviation(address pool, uint256 value);
    event EmergencyFrozen();
    event ChangeSwapProxy(address newSwapProxy);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "./IStrategyFactory.sol";

interface IGaugeV2 {
    function getRewardTokens() external view returns (address[] memory);
    function getReward(
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        address[] memory tokens,
        address receiver
    ) external;
}

interface IStrategyManager {
    function isUserWhiteListed(address _account) external view returns (bool);

    function isAllowedToManage(address) external view returns (bool);

    function isAllowedToBurn(address) external view returns (bool);

    function managementFeeRate() external view returns (uint256); // 1e8 decimals

    function performanceFeeRate() external view returns (uint256); // 1e8 decimals

    function operator() external view returns (address);

    function limit() external view returns (uint256);

    function allowedDeviation() external view returns (uint256); // 1e18 decimals

    function allowedSwapDeviation() external view returns (uint256); // 1e18 decimals

    function feeTo() external view returns (address);

    function factory() external view returns (IStrategyFactory);

    function increamentSwapCounter() external;

    function strategy() external view returns (address);

    function getRewardParameters() external view returns(IGaugeV2 _gauge, address _rewardReceiver, address[] memory _rewardTokens);
}

pragma solidity ^0.7.6;

interface IERC20Minimal {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}