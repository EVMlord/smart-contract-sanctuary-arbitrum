// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Querier {
    function decimals() external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrategyInfo {
    /// @dev Uniswap-Transaction-related Variable
    function transactionDeadlineDuration() external view returns (uint256);

    /// @dev get Liquidity-NFT-related Variable
    function liquidityNftId() external view returns (uint256);

    function tickSpreadUpper() external view returns (int24);

    function tickSpreadLower() external view returns (int24);

    function tickSpacing() external view returns (int24);

    /// @dev get Pool-related Variable
    function poolAddress() external view returns (address);

    function poolFee() external view returns (uint24);

    function token0Address() external view returns (address);

    function token1Address() external view returns (address);

    /// @dev get Tracker-Token-related Variable
    function trackerTokenAddress() external view returns (address);

    /// @dev get User-Management-related Variable
    function isInUserList(address userAddress) external view returns (bool);

    function userIndex(address userAddress) external view returns (uint256);

    function getAllUsersInUserList() external view returns (address[] memory);

    /// @dev get User-Share-Management-related Variable
    function userShare(address userAddress) external view returns (uint256);

    function totalUserShare() external view returns (uint256);

    /// @dev get Reward-Management-related Variable
    function rewardToken0Amount() external view returns (uint256);

    function rewardToken1Amount() external view returns (uint256);

    function rewardUsdtAmount() external view returns (uint256);

    /// @dev get User-Reward-Management-related Variable
    function userUsdtReward(
        address userAddress
    ) external view returns (uint256);

    function totalUserUsdtReward() external view returns (uint256);

    /// @dev get Buyback-related Variable
    function buyBackToken() external view returns (address);

    function buyBackNumerator() external view returns (uint24);

    /// @dev get Fund-Manager-related Variable
    struct FundManagerVault {
        address fundManagerVaultAddress;
        uint256 fundManagerProfitVaultNumerator;
    }

    function getAllFundManagerVaults()
        external
        view
        returns (FundManagerVault[3] memory);

    /// @dev get Earn-Loop-Control-related Variable
    function earnLoopSegmentSize() external view returns (uint256);

    function earnLoopDistributedAmount() external view returns (uint256);

    function earnLoopStartIndex() external view returns (uint256);

    function isEarning() external view returns (bool);

    /// @dev get Rescale-related Variable
    function dustToken0Amount() external view returns (uint256);

    function dustToken1Amount() external view returns (uint256);

    /// @dev get Constant Variable
    function getBuyBackDenominator() external pure returns (uint24);

    function getFundManagerProfitVaultDenominator()
        external
        pure
        returns (uint24);

    function getFarmAddress() external pure returns (address);

    function getControllerAddress() external pure returns (address);

    function getSwapAmountCalculatorAddress() external pure returns (address);

    function getZapAddress() external pure returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface INonfungiblePositionManager {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    )
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IUniswapV3Factory {
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IUniswapV3Pool {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Constants {
    /// @dev ArbiturmOne & Goerli uniswap V3
    address public constant UNISWAP_V3_FACTORY_ADDRESS =
        address(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address public constant NONFUNGIBLE_POSITION_MANAGER_ADDRESS =
        address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address public constant SWAP_ROUTER_ADDRESS =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @dev ArbiturmOne token address
    address public constant WETH_ADDRESS =
        address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public constant ARB_ADDRESS =
        address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address public constant WBTC_ADDRESS =
        address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    address public constant USDC_ADDRESS =
        address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    address public constant USDCE_ADDRESS =
        address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address public constant USDT_ADDRESS =
        address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    address public constant RDNT_ADDRESS =
        address(0x3082CC23568eA640225c2467653dB90e9250AaA0);
    address public constant LINK_ADDRESS =
        address(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4);

    /// @dev Goerli token address
    address public constant TESTNET_WETH_ADDRESS =
        address(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    address public constant TESTNET_UNI_ADDRESS =
        address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    address public constant TESTNET_USDT_ADDRESS =
        address(0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49);
    address public constant TESTNET_RXD_ADDRESS =
        address(0xa5bF25Fa92e2181234367DFDE58f31D865b0CDBA);

    /// @dev black hole address
    address public constant BLACK_HOLE_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/external/IERC20Querier.sol";
import "../interfaces/uniswapV3/IUniswapV3Factory.sol";
import "../interfaces/uniswapV3/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library PoolHelper {
    using SafeMath for uint256;

    function getPoolAddress(
        address uniswapV3FactoryAddress,
        address tokenA,
        address tokenB,
        uint24 poolFee
    ) internal view returns (address poolAddress) {
        return
            IUniswapV3Factory(uniswapV3FactoryAddress).getPool(
                tokenA,
                tokenB,
                poolFee
            );
    }

    function getPoolInfo(
        address poolAddress
    )
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 poolFee,
            int24 tick,
            uint160 sqrtPriceX96,
            uint256 decimal0,
            uint256 decimal1
        )
    {
        (sqrtPriceX96, tick, , , , , ) = IUniswapV3Pool(poolAddress).slot0();
        token0 = IUniswapV3Pool(poolAddress).token0();
        token1 = IUniswapV3Pool(poolAddress).token1();
        poolFee = IUniswapV3Pool(poolAddress).fee();
        decimal0 = IERC20Querier(token0).decimals();
        decimal1 = IERC20Querier(token1).decimals();
    }

    /// @dev formula explanation
    /*
    [Original formula (without decimal precision)]
    (token1 * (10^decimal1)) / (token0 * (10^decimal0)) = (sqrtPriceX96 / (2^96))^2   
    tokenPrice = token1/token0 = (sqrtPriceX96 / (2^96))^2 * (10^decimal0) / (10^decimal1)

    [Formula with decimal precision & decimal adjustment]
    tokenPriceWithDecimalAdj = tokenPrice * (10^decimalPrecision)
        = (sqrtPriceX96 * (10^decimalPrecision) / (2^96))^2 
            / 10^(decimalPrecision + decimal1 - decimal0)
    */
    function getTokenPriceWithDecimalsByPool(
        address poolAddress,
        uint256 decimalPrecision
    ) internal view returns (uint256 tokenPriceWithDecimals) {
        (
            ,
            ,
            ,
            ,
            uint160 sqrtPriceX96,
            uint256 decimal0,
            uint256 decimal1
        ) = getPoolInfo(poolAddress);

        // when decimalPrecision is 18,
        // calculation restriction: 79228162514264337594 <= sqrtPriceX96 <= type(uint160).max
        uint256 scaledPriceX96 = uint256(sqrtPriceX96)
            .mul(10 ** decimalPrecision)
            .div(2 ** 96);
        uint256 tokenPriceWithoutDecimalAdj = scaledPriceX96.mul(
            scaledPriceX96
        );
        uint256 decimalAdj = decimalPrecision.add(decimal1).sub(decimal0);
        uint256 result = tokenPriceWithoutDecimalAdj.div(10 ** decimalAdj);
        require(result > 0, "token price too small");
        tokenPriceWithDecimals = result;
    }

    function getTokenDecimalAdjustment(
        address token
    ) internal view returns (uint256 decimalAdjustment) {
        uint256 tokenDecimalStandard = 18;
        uint256 decimal = IERC20Querier(token).decimals();
        return tokenDecimalStandard.sub(decimal);
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

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
        uint256 twos = (~denominator) + 1;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./FullMath.sol";
import "./FixedPoint96.sol";

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
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(
            sqrtRatioAX96,
            sqrtRatioBX96,
            FixedPoint96.Q96
        );
        return
            toUint128(
                FullMath.mulDiv(
                    amount0,
                    intermediate,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
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
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount1,
                    FixedPoint96.Q96,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
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
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(
                sqrtRatioX96,
                sqrtRatioBX96,
                amount0
            );
            uint128 liquidity1 = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioX96,
                amount1
            );

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
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
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 originalResult = FullMath.mulDiv(
            uint256(liquidity) << FixedPoint96.RESOLUTION,
            sqrtRatioBX96 - sqrtRatioAX96,
            sqrtRatioBX96
        ) / sqrtRatioAX96;

        /// @dev handle overflow issue
        if (originalResult != 0) {
            return originalResult;
        } else {
            return
                FullMath.mulDiv(
                    (uint256(liquidity) << FixedPoint96.RESOLUTION) /
                        sqrtRatioAX96,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                );
        }
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
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                liquidity,
                sqrtRatioBX96 - sqrtRatioAX96,
                FixedPoint96.Q96
            );
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
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioX96,
                sqrtRatioBX96,
                liquidity
            );
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioX96,
                liquidity
            );
        } else {
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

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
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(
        int24 tick
    ) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/constants/Constants.sol";
import "./libraries/uniswapV3/LiquidityAmounts.sol";
import "./libraries/uniswapV3/TickMath.sol";
import "./libraries/PoolHelper.sol";
import "./interfaces/IStrategyInfo.sol";
import "./interfaces/uniswapV3/INonfungiblePositionManager.sol";
import "./interfaces/uniswapV3/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @dev verified, public contract
contract StrategyInfoQuerier {
    using SafeMath for uint256;

    /// @dev Uniswap-Transaction-related Variable
    function getTransactionDeadlineDuration(
        address _strategyContract
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).transactionDeadlineDuration();
    }

    /// @dev get Liquidity-NFT-related Variable
    function getLiquidityNftId(
        address _strategyContract
    ) public view returns (uint256) {
        return IStrategyInfo(_strategyContract).liquidityNftId();
    }

    function getTickSpreadUpper(
        address _strategyContract
    ) external view returns (int24) {
        return IStrategyInfo(_strategyContract).tickSpreadUpper();
    }

    function getTickSpreadLower(
        address _strategyContract
    ) external view returns (int24) {
        return IStrategyInfo(_strategyContract).tickSpreadLower();
    }

    function getTickSpacing(
        address _strategyContract
    ) external view returns (int24) {
        return IStrategyInfo(_strategyContract).tickSpacing();
    }

    /// @dev get Pool-related Variable
    function getPoolAddress(
        address _strategyContract
    ) public view returns (address) {
        return IStrategyInfo(_strategyContract).poolAddress();
    }

    function getPoolFee(
        address _strategyContract
    ) external view returns (uint24) {
        return IStrategyInfo(_strategyContract).poolFee();
    }

    function getToken0Address(
        address _strategyContract
    ) external view returns (address) {
        return IStrategyInfo(_strategyContract).token0Address();
    }

    function getToken1Address(
        address _strategyContract
    ) external view returns (address) {
        return IStrategyInfo(_strategyContract).token1Address();
    }

    /// @dev get Tracker-Token-related Variable
    function getTrackerTokenAddress(
        address _strategyContract
    ) external view returns (address) {
        return IStrategyInfo(_strategyContract).trackerTokenAddress();
    }

    /// @dev get User-Management-related Variable
    function getIsInUserList(
        address _strategyContract,
        address _userAddress
    ) external view returns (bool) {
        return IStrategyInfo(_strategyContract).isInUserList(_userAddress);
    }

    function getUserIndex(
        address _strategyContract,
        address _userAddress
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).userIndex(_userAddress);
    }

    function getAllUsersInUserList(
        address _strategyContract
    ) external view returns (address[] memory userList) {
        return IStrategyInfo(_strategyContract).getAllUsersInUserList();
    }

    /// @dev get User-Share-Management-related Variable
    function getUserShare(
        address _strategyContract,
        address _userAddress
    ) public view returns (uint256 userShare) {
        return IStrategyInfo(_strategyContract).userShare(_userAddress);
    }

    function getTotalUserShare(
        address _strategyContract
    ) public view returns (uint256) {
        return IStrategyInfo(_strategyContract).totalUserShare();
    }

    /// @dev get Reward-Management-related Variable
    function getRewardToken0Amount(
        address _strategyContract
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).rewardToken0Amount();
    }

    function getRewardToken1Amount(
        address _strategyContract
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).rewardToken1Amount();
    }

    function getRewardUsdtAmount(
        address _strategyContract
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).rewardUsdtAmount();
    }

    /// @dev get User-Reward-Management-related Variable
    function getUserUsdtReward(
        address _strategyContract,
        address _userAddress
    ) external view returns (uint256 userUsdtReward) {
        return IStrategyInfo(_strategyContract).userUsdtReward(_userAddress);
    }

    function getTotalUserUsdtReward(
        address _strategyContract
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).totalUserUsdtReward();
    }

    /// @dev get Buyback-related Variable
    function getBuyBackToken(
        address _strategyContract
    ) external view returns (address) {
        return IStrategyInfo(_strategyContract).buyBackToken();
    }

    function getBuyBackNumerator(
        address _strategyContract
    ) external view returns (uint24) {
        return IStrategyInfo(_strategyContract).buyBackNumerator();
    }

    /// @dev get Fund-Manager-related Variable
    function getAllFundManagerVaults(
        address _strategyContract
    )
        external
        view
        returns (IStrategyInfo.FundManagerVault[3] memory fundManagerVaults)
    {
        return IStrategyInfo(_strategyContract).getAllFundManagerVaults();
    }

    /// @dev get Earn-Loop-Control-related Variable
    function getEarnLoopSegmentSize(
        address _strategyContract
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).earnLoopSegmentSize();
    }

    function getEarnLoopDistributedAmount(
        address _strategyContract
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).earnLoopDistributedAmount();
    }

    function getEarnLoopStartIndex(
        address _strategyContract
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).earnLoopStartIndex();
    }

    function getIsEarning(
        address _strategyContract
    ) external view returns (bool) {
        return IStrategyInfo(_strategyContract).isEarning();
    }

    /// @dev get Rescale-related Variable
    function getDustToken0Amount(
        address _strategyContract
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).dustToken0Amount();
    }

    function getDustToken1Amount(
        address _strategyContract
    ) external view returns (uint256) {
        return IStrategyInfo(_strategyContract).dustToken1Amount();
    }

    /// @dev get Constant Variable
    function getBuyBackDenominator(
        address _strategyContract
    ) external pure returns (uint24) {
        return IStrategyInfo(_strategyContract).getBuyBackDenominator();
    }

    function getFundManagerProfitVaultDenominator(
        address _strategyContract
    ) external pure returns (uint24) {
        return
            IStrategyInfo(_strategyContract)
                .getFundManagerProfitVaultDenominator();
    }

    function getFarmAddress(
        address _strategyContract
    ) external pure returns (address) {
        return IStrategyInfo(_strategyContract).getFarmAddress();
    }

    function getControllerAddress(
        address _strategyContract
    ) external pure returns (address) {
        return IStrategyInfo(_strategyContract).getControllerAddress();
    }

    function getSwapAmountCalculatorAddress(
        address _strategyContract
    ) external pure returns (address) {
        return
            IStrategyInfo(_strategyContract).getSwapAmountCalculatorAddress();
    }

    function getZapAddress(
        address _strategyContract
    ) external pure returns (address) {
        return IStrategyInfo(_strategyContract).getZapAddress();
    }

    /// @dev get tick info
    function getTickAndPrice(
        address _strategyContract
    ) external view returns (int24, uint256) {
        // get poolAddress
        address poolAddress = getPoolAddress(_strategyContract);

        // get tick
        (, int24 tick, , , , , ) = IUniswapV3Pool(poolAddress).slot0();

        // calculate tokenPrice
        uint256 tokenPriceWithDecimals = getTokenPriceWithDecimalsByPoolAndTick(
            poolAddress,
            tick
        );

        return (tick, tokenPriceWithDecimals);
    }

    function getTickLowerAndPrice(
        address _strategyContract
    ) external view returns (int24, uint256) {
        // get poolAddress
        address poolAddress = getPoolAddress(_strategyContract);

        // get tickLower
        uint256 liquidityNftId = getLiquidityNftId(_strategyContract);
        verifyLiquidityNftIdIsNotZero(liquidityNftId);

        (, , , , , int24 tickLower, , , , , , ) = INonfungiblePositionManager(
            Constants.NONFUNGIBLE_POSITION_MANAGER_ADDRESS
        ).positions(liquidityNftId);

        // calculate tokenPrice
        uint256 tokenPriceWithDecimals = getTokenPriceWithDecimalsByPoolAndTick(
            poolAddress,
            tickLower
        );

        return (tickLower, tokenPriceWithDecimals);
    }

    function getTickUpperAndPrice(
        address _strategyContract
    ) external view returns (int24, uint256) {
        // get poolAddress
        address poolAddress = getPoolAddress(_strategyContract);

        // get tickUpper
        uint256 liquidityNftId = getLiquidityNftId(_strategyContract);
        verifyLiquidityNftIdIsNotZero(liquidityNftId);

        (, , , , , , int24 tickUpper, , , , , ) = INonfungiblePositionManager(
            Constants.NONFUNGIBLE_POSITION_MANAGER_ADDRESS
        ).positions(liquidityNftId);

        // calculate tokenPrice
        uint256 tokenPriceWithDecimals = getTokenPriceWithDecimalsByPoolAndTick(
            poolAddress,
            tickUpper
        );

        return (tickUpper, tokenPriceWithDecimals);
    }

    /// @dev formula explanation
    /*
    [Original formula (without decimal precision)]
    (token1 * (10^decimal1)) / (token0 * (10^decimal0)) = (sqrtPriceX96 / (2^96))^2   
    tokenPrice = token1/token0 = (sqrtPriceX96 / (2^96))^2 * (10^decimal0) / (10^decimal1)

    [Formula with decimal precision & decimal adjustment]
    tokenPriceWithDecimalAdj = tokenPrice * (10^decimalPrecision)
        = (sqrtPriceX96 * (10^decimalPrecision) / (2^96))^2 
            / 10^(decimalPrecision + decimal1 - decimal0)
    */
    function getTokenPriceWithDecimalsByPoolAndTick(
        address poolAddress,
        int24 tick
    ) internal view returns (uint256 tokenPriceWithDecimals) {
        (, , , , , uint256 decimal0, uint256 decimal1) = PoolHelper.getPoolInfo(
            poolAddress
        );

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        uint256 decimalPrecision = 18;

        // when decimalPrecision is 18,
        // calculation restriction: 79228162514264337594 <= sqrtPriceX96 <= type(uint160).max
        uint256 scaledPriceX96 = uint256(sqrtPriceX96)
            .mul(10 ** decimalPrecision)
            .div(2 ** 96);
        uint256 tokenPriceWithoutDecimalAdj = scaledPriceX96.mul(
            scaledPriceX96
        );
        uint256 decimalAdj = decimalPrecision.add(decimal1).sub(decimal0);
        uint256 result = tokenPriceWithoutDecimalAdj.div(10 ** decimalAdj);
        require(result > 0, "token price too small");
        tokenPriceWithDecimals = result;
    }

    /// @dev get liquidity token0 token1 balance info
    function getUserLiquidityTokenBalance(
        address _strategyContract,
        address _userAddress
    ) external view returns (uint256 amount0, uint256 amount1) {
        (
            uint160 sqrtPriceX96,
            uint160 sqrtRatioAX96,
            uint160 sqrtRatioBX96,
            uint128 liquidity
        ) = getSqrtPriceAndLiquidityInfo(_strategyContract);

        // calculate user liquidity
        uint256 userShare = getUserShare(_strategyContract, _userAddress);
        uint256 totalShare = getTotalUserShare(_strategyContract);
        uint256 userLiquidity = uint256(liquidity).mul(userShare).div(
            totalShare
        );

        // calculate token amount
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            uint128(userLiquidity)
        );
    }

    function getStrategyLiquidityTokenBalance(
        address _strategyContract
    ) external view returns (uint256 amount0, uint256 amount1) {
        (
            uint160 sqrtPriceX96,
            uint160 sqrtRatioAX96,
            uint160 sqrtRatioBX96,
            uint128 liquidity
        ) = getSqrtPriceAndLiquidityInfo(_strategyContract);

        // calculate token amount
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            liquidity
        );
    }

    function getSqrtPriceAndLiquidityInfo(
        address _strategyContract
    )
        internal
        view
        returns (
            uint160 sqrtPriceX96,
            uint160 sqrtRatioAX96,
            uint160 sqrtRatioBX96,
            uint128 liquidity
        )
    {
        // get poolAddress
        address poolAddress = getPoolAddress(_strategyContract);

        // get tick
        (, int24 tick, , , , , ) = IUniswapV3Pool(poolAddress).slot0();

        // get tickUpper & tickLower
        uint256 liquidityNftId = getLiquidityNftId(_strategyContract);
        verifyLiquidityNftIdIsNotZero(liquidityNftId);

        int24 tickLower;
        int24 tickUpper;
        (
            ,
            ,
            ,
            ,
            ,
            tickLower,
            tickUpper,
            liquidity,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(
            Constants.NONFUNGIBLE_POSITION_MANAGER_ADDRESS
        ).positions(liquidityNftId);

        // calculate sqrtPrice
        sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
    }

    function verifyLiquidityNftIdIsNotZero(
        uint256 liquidityNftId
    ) internal pure {
        require(
            liquidityNftId != 0,
            "not allow calling when liquidityNftId is 0"
        );
    }
}