pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.7.5;

import "../libraries/UQ112x112.sol";
import "../libraries/FixedPoint.sol";
import "../libraries/UniswapV2Library.sol";

import "../interfaces/IPriceOracle.sol";

contract SimpleUniswapOracle is IPriceOracle {
	using UQ112x112 for uint224;
	using FixedPoint for *;
	
	uint32 public constant MIN_T = 1800;
	
	struct Pair {
		uint256 price0CumulativeA;
		uint256 price0CumulativeB;
		uint256 price1CumulativeA;
		uint256 price1CumulativeB;
		uint32 updateA;
		uint32 updateB;
		bool lastIsA;
		bool initialized;
	}

	address public immutable factory;

	mapping(address => Pair) public getPair;

	event PriceUpdate(address indexed pair, uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp, bool lastIsA);
	
	constructor(address factory_) {
 		factory = factory_;
	}

	function toUint224(uint256 input) internal pure returns (uint224) {
		require(input <= uint224(-1), "UniswapOracle: UINT224_OVERFLOW");
		return uint224(input);
	}
	
	function getPriceCumulativeCurrent(address uniswapV2Pair) internal view returns (uint256 price0Cumulative, uint256 price1Cumulative) {
		price0Cumulative = IUniswapV2Pair(uniswapV2Pair).price0CumulativeLast();
		price1Cumulative = IUniswapV2Pair(uniswapV2Pair).price1CumulativeLast();
		(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(uniswapV2Pair).getReserves();
		uint32 timeElapsed = getBlockTimestamp() - blockTimestampLast; // overflow is desired
		
		// * never overflows, and + overflow is desired
		price0Cumulative += uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) * timeElapsed;
		price1Cumulative += uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
	}
	
	function initialize(address uniswapV2Pair) external {
		Pair storage pairStorage = getPair[uniswapV2Pair];
		require(!pairStorage.initialized, "UniswapOracle: ALREADY_INITIALIZED");
		
		(uint256 price0CumulativeCurrent, uint256 price1CumulativeCurrent) = getPriceCumulativeCurrent(uniswapV2Pair);
		uint32 blockTimestamp = getBlockTimestamp();
		pairStorage.price0CumulativeA = price0CumulativeCurrent;
		pairStorage.price0CumulativeB = price0CumulativeCurrent;
		pairStorage.price1CumulativeA = price1CumulativeCurrent;
		pairStorage.price1CumulativeB = price1CumulativeCurrent;
		pairStorage.updateA = blockTimestamp;
		pairStorage.updateB = blockTimestamp;
		pairStorage.lastIsA = true;
		pairStorage.initialized = true;
		emit PriceUpdate(uniswapV2Pair, price0CumulativeCurrent, price1CumulativeCurrent, blockTimestamp, true);
	}
	
	function getResult(address uniswapV2Pair) public returns (uint224 price0, uint224 price1, uint32 T, uint32 lastUpdated) {
		Pair memory pair = getPair[uniswapV2Pair];
		require(pair.initialized, "UniswapOracle: NOT_INITIALIZED");
		Pair storage pairStorage = getPair[uniswapV2Pair];
				
		uint32 timestamp = getBlockTimestamp();
		uint32 updateLast = pair.lastIsA ? pair.updateA : pair.updateB;
		(uint256 price0CumulativeCurrent, uint256 price1CumulativeCurrent) = getPriceCumulativeCurrent(uniswapV2Pair);
		uint256 price0CumulativeLast;
		uint256 price1CumulativeLast;
		
		if (timestamp - updateLast >= MIN_T) {
			// update
			price0CumulativeLast = pair.lastIsA ? pair.price0CumulativeA : pair.price0CumulativeB;
			price1CumulativeLast = pair.lastIsA ? pair.price1CumulativeA : pair.price1CumulativeB;
			lastUpdated = timestamp;
			if (pair.lastIsA) {
				pairStorage.price0CumulativeB = price0CumulativeCurrent;
				pairStorage.price1CumulativeB = price1CumulativeCurrent;
				pairStorage.updateB = timestamp;
			} else {
				pairStorage.price0CumulativeA = price0CumulativeCurrent;
				pairStorage.price1CumulativeA = price1CumulativeCurrent;
				pairStorage.updateA = timestamp;
			}
			pairStorage.lastIsA = !pair.lastIsA;
			emit PriceUpdate(uniswapV2Pair, price0CumulativeCurrent, price1CumulativeCurrent, timestamp, !pair.lastIsA);
		}
		else {
			// don't update and return price using previous priceCumulative
			updateLast = lastUpdated = pair.lastIsA ? pair.updateB : pair.updateA;
			price0CumulativeLast = pair.lastIsA ? pair.price0CumulativeB : pair.price0CumulativeA;
			price1CumulativeLast = pair.lastIsA ? pair.price1CumulativeB : pair.price1CumulativeA;
		}
		
		T = timestamp - updateLast; // overflow is desired
		require(T >= MIN_T, "UniswapOracle: NOT_READY"); //reverts only if the pair has just been initialized
		// / is safe, and - overflow is desired
		price0 = toUint224((price0CumulativeCurrent - price0CumulativeLast) / T);
		price1 = toUint224((price1CumulativeCurrent - price1CumulativeLast) / T);
	}

	function getLastResult(address uniswapV2Pair) public view returns (uint224 price0, uint224 price1, uint32 T, uint32 lastUpdated) {
		Pair memory pair = getPair[uniswapV2Pair];
		require(pair.initialized, "UniswapOracle: NOT_INITIALIZED");

		(uint256 price0CumulativeCurrent, uint256 price1CumulativeCurrent) = getPriceCumulativeCurrent(uniswapV2Pair);

		// don't update and return price using previous priceCumulative
		uint32 updateLast = lastUpdated = pair.lastIsA ? pair.updateB : pair.updateA;
		uint256 price0CumulativeLast = pair.lastIsA ? pair.price0CumulativeB : pair.price0CumulativeA;
		uint256 price1CumulativeLast = pair.lastIsA ? pair.price1CumulativeB : pair.price1CumulativeA;

		T = getBlockTimestamp() - updateLast; // overflow is desired
		require(T >= MIN_T, "UniswapOracle: NOT_READY"); //reverts only if the pair has just been initialized
		// / is safe, and - overflow is desired
		price0 = toUint224((price0CumulativeCurrent - price0CumulativeLast) / T);
		price1 = toUint224((price1CumulativeCurrent - price1CumulativeLast) / T);
	}
	
	function consult(address tokenIn, uint amountIn, address tokenOut) external override returns (uint amountOut) {
		address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
		(uint224 price0, uint224 price1, , ) = getResult(pair);

		(address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
		uint224 price = price0;
		if (token0 == tokenOut) {
			price = price1;
		}

		amountOut = FixedPoint.uq112x112(price).mul(amountIn).decode144();
	}

	function consultReadonly(address tokenIn, uint amountIn, address tokenOut) external override view returns (uint amountOut) {
		address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
		(uint224 price0, uint224 price1, , ) = getLastResult(pair);

		(address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
		uint224 price = price0;
		if (token0 == tokenOut) {
			price = price1;
		}

		amountOut = FixedPoint.uq112x112(price).mul(amountIn).decode144();
	}

	/*** Utilities ***/
	
	function getBlockTimestamp() public view returns (uint32) {
		return uint32(block.timestamp % 2**32);
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IPriceOracle {
    function consult(address tokenIn, uint amountIn, address tokenOut) external returns (uint amountOut);
    function consultReadonly(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./FullMath.sol";


library Babylonian {

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library BitMath {

    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}


library FixedPoint {

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }
    
    function decode112(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827628530496329220096;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
    
    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, "FixedPoint::mul: overflow");
        return uq144x112(z);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.7.5;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // pair = address(uint(keccak256(abi.encodePacked(
        //         hex"ff",
        //         factory,
        //         keccak256(abi.encodePacked(token0, token1)),
        //         hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
        //     ))));

        pair = IUniswapV2Factory(factory).getPair(token0, token1);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) 
        internal view returns (uint reserveA, uint reserveB) {
            (address token0,) = sortTokens(tokenA, tokenB);
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
            (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) 
        internal view returns (uint[] memory amounts) {
            require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
            amounts = new uint[](path.length);
            amounts[0] = amountIn;
            for (uint i; i < path.length - 1; i++) {
                (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
                amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) 
        internal view returns (uint[] memory amounts) {
            require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
            amounts = new uint[](path.length);
            amounts[amounts.length - 1] = amountOut;
            for (uint i = path.length - 1; i > 0; i--) {
                (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
                amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
            }
    }
}