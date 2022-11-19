// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

// propose pools to users according to their balances on front-end
// change router into allowancetarget to be more parametric in case router changes
// add withdraw functions to withdraw any balance left (ETH and ERC20)
// solidly : change ISwapPair

import "../core/interfaces/ISwapPair.sol";
import "../core/interfaces/ISwapFactory.sol";
import "../periphery/interfaces/IRouter.sol";
import "../periphery/interfaces/IWETH.sol";
import "../core/SwapPair.sol";
import "./libraries/Babylonian.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Zap {
  address public immutable router;
  address public immutable factory;
  address public immutable weth;

  constructor(
    address _router,
    address _factory,
    address _weth
  ) {
    router = _router;
    factory = _factory;
    weth = _weth;
  }

  event zappedOut(address indexed _zapper, address indexed _pool, address indexed _token, uint256 _amountOut);
  event zappedIn(address indexed _zapper, address indexed _pool, address indexed _token, uint256 _poolTokens);

  receive() external payable {}

  fallback() external payable {}

  // ***** ZAP METHODS *****

  function zapIn(
    address _token,
    uint256 _amount,
    address _pool,
    uint256 _minPoolTokens,
    bytes memory _swapData,
    address _to
  ) public payable virtual returns (uint256 poolTokens) {
    uint256 toInvest_;
    if (_token == address(0)) {
      require(msg.value > 0, "no ETH sent");
      toInvest_ = msg.value;
    } else {
      require(msg.value == 0, "ETH sent");
      require(_amount > 0, "invalid amount");
      IERC20(_token).transferFrom(msg.sender, address(this), _amount);
      toInvest_ = _amount;
    }

    (address _token0, address _token1) = _getTokens(_pool);
    bool stable_ = ISwapPair(_pool).stable();

    address tempToken_;
    uint256 tempAmount_;

    if (_token != _token0 && _token != _token1) {
      (tempToken_, tempAmount_) = _swapIn(_token, _pool, toInvest_, _swapData);
    } else {
      (tempToken_, tempAmount_) = (_token, _amount);
    }

    (uint256 amount0_, uint256 amount1_) = _swapOptimalAmount(
      tempToken_,
      _pool,
      _token0,
      _token1,
      tempAmount_,
      stable_
    );
    poolTokens = _provideLiquidity(_token0, _token1, amount0_, amount1_, stable_, _to);
    require(poolTokens >= _minPoolTokens, "not enough LP tokens received");

    emit zappedIn(_to, _pool, _token, poolTokens);
  }

  function zapOut(
    address _tokenOut,
    address _pool,
    uint256 _poolTokens,
    uint256 _amountOutMin,
    bool _stable,
    bytes[] memory _swapData,
    address _to
  ) public virtual returns (uint256 amountOut) {
    require(_poolTokens > 0, "invalid amount");
    ISwapPair(_pool).transferFrom(msg.sender, address(this), _poolTokens);
    (uint256 amount0_, uint256 amount1_) = _withdrawLiquidity(_pool, _poolTokens, _stable);

    amountOut = _swapTokens(_pool, amount0_, amount1_, _tokenOut, _swapData);
    require(amountOut >= _amountOutMin, "high slippage");

    if (_tokenOut == address(0)) {
      payable(_to).transfer(amountOut);
    } else {
      IERC20(_tokenOut).transfer(_to, amountOut);
    }
    emit zappedOut(_to, _pool, _tokenOut, amountOut);
  }

  // ***** INTERNAL *****

  function _getTokens(address _pool) internal view returns (address token0, address token1) {
    (token0, token1) = ISwapPair(_pool).tokens();
  }

  function _getOptimalAmount(
    uint256 r,
    uint256 a,
    bool stable
  ) internal pure returns (uint256) {
    return stable ? a / 2 : (Babylonian.sqrt(r * (r * 398920729 + a * 398920000)) - r * (19973)) / 19946;
  }

  function _swapOptimalAmount(
    address _tokenIn,
    address _pool,
    address _token0,
    address _token1,
    uint256 _amount,
    bool _stable
  ) internal returns (uint256 amount0, uint256 amount1) {
    ISwapPair pair = ISwapPair(_pool);
    (uint256 reserve0_, uint256 reserve1_, ) = pair.getReserves();
    if (_tokenIn == _token0) {
      uint256 optimalAmount = _getOptimalAmount(reserve0_, _amount, _stable);
      if (optimalAmount <= 0) {
        optimalAmount = _amount / 2;
      }

      amount1 = _swapTokensForTokens(_tokenIn, _token1, optimalAmount, _stable);
      amount0 = _amount - optimalAmount;
    } else {
      uint256 optimalAmount = _getOptimalAmount(reserve1_, _amount, _stable);
      if (optimalAmount <= 0) {
        optimalAmount = _amount / 2;
      }

      amount0 = _swapTokensForTokens(_tokenIn, _token0, optimalAmount, _stable);
      amount1 = _amount - optimalAmount;
    }
  }

  function _swapIn(
    address _token,
    address _pool,
    uint256 _amount,
    bytes memory _swapData
  ) internal returns (address tokenOut, uint256 amountOut) {
    uint256 value_;
    IERC20 token_ = IERC20(_token);
    if (_token == address(0)) {
      value_ = _amount;
    } else {
      token_.approve(address(router), 0);
      token_.approve(address(router), _amount + 1);
    }
    (address token0_, address token1_) = _getTokens(_pool);
    IERC20 token0 = IERC20(token0_);
    uint256 preBalance0 = token0.balanceOf(address(this));
    // _to parameter in _swapData MUST be set to the address of this contract
    (bool success, bytes memory data) = address(router).call{ value: value_ }(_swapData);
    require(success, "error entering pair");
    uint256[] memory out = abi.decode(data, (uint256[]));
    amountOut = out[out.length - 1];
    require(amountOut > 0, "amount too low entering pair");
    uint256 postBalance0 = token0.balanceOf(address(this));
    preBalance0 != postBalance0 ? tokenOut = token0_ : tokenOut = token1_;
  }

  function _swapOut(
    address _tokenIn,
    address _tokenOut,
    uint256 _amount,
    bytes memory _swapData
  ) internal returns (uint256 amountOut) {
    if (_tokenIn == weth && _tokenOut == address(0)) {
      IWETH(weth).withdraw(_amount);
      return _amount;
    }
    uint256 value_;
    if (_tokenIn == address(0)) {
      value_ = _amount;
    } else {
      IERC20(_tokenIn).approve(address(router), _amount);
    }
    uint256 preBalance = _tokenOut == address(0) ? address(this).balance : IERC20(_tokenOut).balanceOf(address(this));

    (bool success, ) = address(router).call{ value: value_ }(_swapData);
    require(success, "error swapping tokens");

    amountOut =
      (_tokenOut == address(0) ? address(this).balance : IERC20(_tokenOut).balanceOf(address(this))) -
      preBalance;
    require(amountOut > 0, "wapped to Invalid Intermediate");
  }

  function _swapTokens(
    address _pool,
    uint256 _amount0,
    uint256 _amount1,
    address _tokenOut,
    bytes[] memory _swapData
  ) internal returns (uint256 amountOut) {
    (address token0_, address token1_) = _getTokens(_pool);
    if (token0_ == _tokenOut) {
      amountOut += _amount0;
    } else {
      amountOut += _swapOut(token0_, _tokenOut, _amount0, _swapData[0]);
    }

    if (token1_ == _tokenOut) {
      amountOut += _amount1;
    } else {
      amountOut += _swapOut(token1_, _tokenOut, _amount1, _swapData[1]);
    }
  }

  function _swapTokensForTokens(
    address _tokenIn,
    address _tokenOut,
    uint256 _amount,
    bool _stable
  ) internal returns (uint256 amountOut) {
    require(_tokenIn != _tokenOut, "tokens are the same");
    require(ISwapFactory(factory).getPair(_tokenIn, _tokenOut, _stable) != address(0), "pair does not exist");
    IERC20(_tokenIn).approve(address(router), 0);
    IERC20(_tokenIn).approve(address(router), _amount);
    route[] memory routes = new route[](1);
    routes[0] = route(_tokenIn, _tokenOut, _stable);
    amountOut = IRouter(router).swapExactTokensForTokens(_amount, 1, routes, address(this), block.timestamp)[1];
    require(amountOut > 0, "amount out too low");
  }

  function _provideLiquidity(
    address _token0,
    address _token1,
    uint256 _amount0,
    uint256 _amount1,
    bool _stable,
    address _to
  ) internal returns (uint256) {
    IERC20(_token0).approve(address(router), 0);
    IERC20(_token1).approve(address(router), 0);
    IERC20(_token0).approve(address(router), _amount0);
    IERC20(_token1).approve(address(router), _amount1);
    (uint256 amountA, uint256 amountB, uint256 poolTokens) = IRouter(router).addLiquidity(
      _token0,
      _token1,
      _stable,
      _amount0,
      _amount1,
      1,
      1,
      _to,
      block.timestamp
    );
    // Returning Residue in token0, if any
    if (_amount0 - amountA > 0) {
      IERC20(_token0).transfer(msg.sender, _amount0 - amountA);
    }
    // Returning Residue in token1, if any
    if (_amount1 - amountB > 0) {
      IERC20(_token1).transfer(msg.sender, _amount1 - amountB);
    }
    return poolTokens;
  }

  function _withdrawLiquidity(
    address _pool,
    uint256 _poolTokens,
    bool _stable
  ) internal returns (uint256 amount0, uint256 amount1) {
    require(_pool != address(0), "this pool does not exist");
    (address token0_, address token1_) = ISwapPair(_pool).tokens();
    IERC20(_pool).approve(router, _poolTokens);
    (amount0, amount1) = IRouter(router).removeLiquidity(
      token0_,
      token1_,
      _stable,
      _poolTokens,
      1,
      1,
      address(this),
      block.timestamp
    );
    require(amount0 > 0 && amount1 > 0, "removed insufficient liquidity");
  }

  function withdraw() public {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwapPair {
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external returns (bool);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function mint(address to) external returns (uint256 liquidity);

  function getReserves()
    external
    view
    returns (
      uint112 _reserve0,
      uint112 _reserve1,
      uint32 _blockTimestampLast
    );

  function getAmountOut(uint256, address) external view returns (uint256);

  function claimFees() external returns (uint256, uint256);

  function tokens() external view returns (address, address);

  function claimable0(address _account) external view returns (uint256);

  function claimable1(address _account) external view returns (uint256);

  function index0() external view returns (uint256);

  function index1() external view returns (uint256);

  function balanceOf(address _account) external view returns (uint256);

  function approve(address _spender, uint256 _value) external returns (bool);

  function reserve0() external view returns (uint256);

  function reserve1() external view returns (uint256);

  function current(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut);

  function currentCumulativePrices()
    external
    view
    returns (
      uint256 reserve0Cumulative,
      uint256 reserve1Cumulative,
      uint256 blockTimestamp
    );

  function sample(
    address tokenIn,
    uint256 amountIn,
    uint256 points,
    uint256 window
  ) external view returns (uint256[] memory);

  function quote(
    address tokenIn,
    uint256 amountIn,
    uint256 granularity
  ) external view returns (uint256 amountOut);

  function stable() external view returns (bool);

  function skim(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwapFactory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function fee(bool stable) external view returns (uint);
    function feeCollector() external view returns (address);
    function setFeeTier(bool stable, uint fee) external;
    function admin() external view returns (address);
    function setAdmin(address _admin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

struct route {
    address from;
    address to;
    bool stable;
}

interface IRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountA,
        uint amountB,
        uint amountMinA,
        uint amountMinB,
        address to,
        uint deadline
    ) external returns (uint a, uint b, uint l);

    function addLiquidityETH(
        address token,
        bool stable,
        uint amountDesired,
        uint amountMin,
        uint amountMinETH,
        address to,
        uint deadline
    ) external payable returns (uint a, uint b, uint l);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint out, bool stable);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity
    ) external view returns (uint amountA, uint amountB);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title WETH9 Interface
/// @author Ricsson W. Ngo
interface IWETH is IERC20 {
    /* ===== UPDATE ===== */

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./SwapFactory.sol";
import "./SwapFees.sol";
import "./libraries/Math.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {cIERC20} from "./interfaces/IERC20.sol";
import "./interfaces/callback/ISwapCallee.sol";
import "./interfaces/ISwapFactory.sol";

// The base pair of pools, either stable or volatile
contract SwapPair {

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    // Used to denote stable or volatile pair, not immutable since construction happens in the initialize method for CREATE2 deterministic addresses
    bool public immutable stable;

    uint public totalSupply = 0;

    mapping(address => mapping (address => uint)) public allowance;
    mapping(address => uint) public balanceOf;

    bytes32 internal DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 internal constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    uint internal constant MINIMUM_LIQUIDITY = 10**3;

    address public immutable token0;
    address public immutable token1;
    address public immutable fees;
    address public immutable factory;
    uint public immutable fee;

    // Structure to capture time period obervations every 30 minutes, used for local oracles
    struct Observation {
        uint timestamp;
        uint reserve0Cumulative;
        uint reserve1Cumulative;
    }

    // Capture oracle reading every 30 minutes
    uint constant periodSize = 1800;

    Observation[] public observations;

    uint internal immutable decimals0;
    uint internal immutable decimals1;

    uint public reserve0;
    uint public reserve1;
    uint public blockTimestampLast;

    uint public reserve0CumulativeLast;
    uint public reserve1CumulativeLast;

    // index0 and index1 are used to accumulate fees, this is split out from normal trades to keep the swap "clean"
    // this further allows LP holders to easily claim fees for tokens they have/staked
    uint public index0 = 0;
    uint public index1 = 0;

    // position assigned to each LP to track their current index0 & index1 vs the global position
    mapping(address => uint) public supplyIndex0;
    mapping(address => uint) public supplyIndex1;

    // tracks the amount of unclaimed, but claimable tokens off of fees for token0 and token1
    mapping(address => uint) public claimable0;
    mapping(address => uint) public claimable1;

    event Fees(address indexed sender, uint amount0, uint amount1);
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
    event Sync(uint reserve0, uint reserve1);
    event Claim(address indexed sender, address indexed recipient, uint amount0, uint amount1);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    constructor() {
        factory = msg.sender;
        (address _token0, address _token1, bool _stable, uint _fee) = SwapFactory(msg.sender).getInitializable();
        (token0, token1, stable, fee) = (_token0, _token1, _stable, _fee);
        fees = address(new SwapFees(_token0, _token1)); 
        if (_stable) {
            name = string(abi.encodePacked("Stable Pair - ", cIERC20(_token0).symbol(), "/", cIERC20(_token1).symbol()));
            symbol = string(abi.encodePacked("sAMM-", cIERC20(_token0).symbol(), "/", cIERC20(_token1).symbol()));
        } else {
            name = string(abi.encodePacked("Variable Pair - ", cIERC20(_token0).symbol(), "/", cIERC20(_token1).symbol()));
            symbol = string(abi.encodePacked("vAMM-", cIERC20(_token0).symbol(), "/", cIERC20(_token1).symbol()));
        } 

        decimals0 = 10**cIERC20(_token0).decimals();
        decimals1 = 10**cIERC20(_token1).decimals();

        observations.push(Observation(block.timestamp, 0, 0));
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function observationLength() external view returns (uint) {
        return observations.length;
    }

    function lastObservation() public view returns (Observation memory) {
        return observations[observations.length-1];
    }

    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1) {
        return (decimals0, decimals1, reserve0, reserve1, stable, token0, token1);
    }

    function tokens() external view returns (address, address) {
        return (token0, token1);
    }

    // claim accumulated but unclaimed fees (viewable via claimable0 and claimable1)
    function claimFees() external returns (uint claimed0, uint claimed1) {
        _updateFor(msg.sender);

        claimed0 = claimable0[msg.sender];
        claimed1 = claimable1[msg.sender];

        if (claimed0 > 0 || claimed1 > 0) {
            claimable0[msg.sender] = 0;
            claimable1[msg.sender] = 0;

            SwapFees(fees).claimFeesFor(msg.sender, claimed0, claimed1);

            emit Claim(msg.sender, msg.sender, claimed0, claimed1);
        }
    }

    // Accrue fees on token0
    function _update0(uint amount) internal {
        address _feeTo = ISwapFactory(factory).feeCollector();
        uint256 _protocolFee = amount / 10; // 10% of the amount
        uint256 _feeIncrease = amount - _protocolFee; // Might leave tokens in this contract due to rounding but ok, reserves updated after this function
        _safeTransfer(token0, _feeTo, _protocolFee);
        _safeTransfer(token0, fees, _feeIncrease); // transfer the fees out to SwapFees
        uint256 _ratio = _feeIncrease * 1e18 / totalSupply; // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index0 += _ratio;
        }
        emit Fees(msg.sender, _feeIncrease, 0);
    }

    // Accrue fees on token1
    function _update1(uint amount) internal {
        address _feeTo = ISwapFactory(factory).feeCollector();
        uint256 _protocolFee = amount / 10; // 10% of the amount
        uint256 _feeIncrease = amount - _protocolFee; // Might leave tokens in this contract due to rounding but ok, reserves updated after this function
        _safeTransfer(token1, _feeTo, _protocolFee); // Transfer protocol fee to _feeTo
        _safeTransfer(token1, fees, _feeIncrease); // transfer the fees out to SwapFees
        uint256 _ratio = _feeIncrease * 1e18 / totalSupply;
        if (_ratio > 0) {
            index1 += _ratio;
        }
        emit Fees(msg.sender, 0, _feeIncrease);
    }

    // this function MUST be called on any balance changes, otherwise can be used to infinitely claim fees
    // Fees are segregated from core funds, so fees can never put liquidity at risk
    function _updateFor(address recipient) internal {
        uint _supplied = balanceOf[recipient]; // get LP balance of `recipient`
        if (_supplied > 0) {
            uint _supplyIndex0 = supplyIndex0[recipient]; // get last adjusted index0 for recipient
            uint _supplyIndex1 = supplyIndex1[recipient];
            uint _index0 = index0; // get global index0 for accumulated fees
            uint _index1 = index1;
            supplyIndex0[recipient] = _index0; // update user current position to global position
            supplyIndex1[recipient] = _index1;
            uint _delta0 = _index0 - _supplyIndex0; // see if there is any difference that need to be accrued
            uint _delta1 = _index1 - _supplyIndex1;
            if (_delta0 > 0) {
                uint _share = _supplied * _delta0 / 1e18; // add accrued difference for each supplied token
                claimable0[recipient] += _share;
            }
            if (_delta1 > 0) {
                uint _share = _supplied * _delta1 / 1e18;
                claimable1[recipient] += _share;
            }
        } else {
            supplyIndex0[recipient] = index0; // new users are set to the default global state
            supplyIndex1[recipient] = index1;
        }
    }

    function getReserves() public view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint _reserve0, uint _reserve1) internal {
        uint blockTimestamp = block.timestamp;
        uint timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            unchecked {
                reserve0CumulativeLast += _reserve0 * timeElapsed;
                reserve1CumulativeLast += _reserve1 * timeElapsed;
            }
        }

        Observation memory _point = lastObservation();
        timeElapsed = blockTimestamp - _point.timestamp; // compare the last observation with current timestamp, if greater than 30 minutes, record a new event
        if (timeElapsed > periodSize) {
            observations.push(Observation(blockTimestamp, reserve0CumulativeLast, reserve1CumulativeLast));
        }
        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices() public view returns (uint reserve0Cumulative, uint reserve1Cumulative, uint blockTimestamp) {
        blockTimestamp = block.timestamp;
        reserve0Cumulative = reserve0CumulativeLast;
        reserve1Cumulative = reserve1CumulativeLast;

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint _reserve0, uint _reserve1, uint _blockTimestampLast) = getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint timeElapsed = blockTimestamp - _blockTimestampLast;
            reserve0Cumulative += _reserve0 * timeElapsed;
            reserve1Cumulative += _reserve1 * timeElapsed;
        }
    }

    // gives the current twap price measured from amountIn * tokenIn gives amountOut
    function current(address tokenIn, uint amountIn) external view returns (uint amountOut) {
        Observation memory _observation = lastObservation();
        (uint reserve0Cumulative, uint reserve1Cumulative,) = currentCumulativePrices();
        if (block.timestamp == _observation.timestamp) {
            _observation = observations[observations.length-2];
        }

        uint timeElapsed = block.timestamp - _observation.timestamp;
        uint _reserve0 = (reserve0Cumulative - _observation.reserve0Cumulative) / timeElapsed;
        uint _reserve1 = (reserve1Cumulative - _observation.reserve1Cumulative) / timeElapsed;
        amountOut = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    // as per `current`, however allows user configured granularity, up to the full window size
    function quote(address tokenIn, uint amountIn, uint granularity) external view returns (uint amountOut) {
        uint [] memory _prices = sample(tokenIn, amountIn, granularity, 1);
        uint priceAverageCumulative;
        for (uint i = 0; i < _prices.length; i++) {
            priceAverageCumulative += _prices[i];
        }
        return priceAverageCumulative / granularity;
    }

    // returns a memory set of twap prices
    function prices(address tokenIn, uint amountIn, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, points, 1);
    }

    function sample(address tokenIn, uint amountIn, uint points, uint window) public view returns (uint[] memory) {
        uint[] memory _prices = new uint[](points);

        uint length = observations.length-1;
        uint i = length - (points * window);
        uint nextIndex = 0;
        uint index = 0;

        for (; i < length; i+=window) {
            nextIndex = i + window;
            uint timeElapsed = observations[nextIndex].timestamp - observations[i].timestamp;
            uint _reserve0 = (observations[nextIndex].reserve0Cumulative - observations[i].reserve0Cumulative) / timeElapsed;
            uint _reserve1 = (observations[nextIndex].reserve1Cumulative - observations[i].reserve1Cumulative) / timeElapsed;
            _prices[index] = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
            index = index + 1;
        }
        return _prices;
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function mint(address to) external lock returns (uint liquidity) {
        (uint _reserve0, uint _reserve1) = (reserve0, reserve1);
        uint _balance0 = IERC20(token0).balanceOf(address(this));
        uint _balance1 = IERC20(token1).balanceOf(address(this));
        uint _amount0 = _balance0 - _reserve0;
        uint _amount1 = _balance1 - _reserve1;

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(_amount0 * _amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(_amount0 * _totalSupply / _reserve0, _amount1 * _totalSupply / _reserve1);
        }
        require(liquidity > 0, 'ILM'); // SwapPair: INSUFFICIENT_LIQUIDITY_MINTED
        _mint(to, liquidity);

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, _amount0, _amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint _reserve0, uint _reserve1) = (reserve0, reserve1);
        (address _token0, address _token1) = (token0, token1);
        uint _balance0 = IERC20(_token0).balanceOf(address(this));
        uint _balance1 = IERC20(_token1).balanceOf(address(this));
        uint _liquidity = balanceOf[address(this)];

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = _liquidity * _balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = _liquidity * _balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'ILB'); // SwapPair: INSUFFICIENT_LIQUIDITY_BURNED
        _burn(address(this), _liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        _balance0 = IERC20(_token0).balanceOf(address(this));
        _balance1 = IERC20(_token1).balanceOf(address(this));

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(!SwapFactory(factory).isPaused());
        require(amount0Out > 0 || amount1Out > 0, 'IOA'); // SwapPair: INSUFFICIENT_OUTPUT_AMOUNT
        (uint _reserve0, uint _reserve1) =  (reserve0, reserve1);
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'IL'); // SwapPair: INSUFFICIENT_LIQUIDITY

        uint _balance0;
        uint _balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        (address _token0, address _token1) = (token0, token1);
        require(to != _token0 && to != _token1, 'IT'); // SwapPair: INVALID_TO
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) ISwapCallee(to).hook(msg.sender, amount0Out, amount1Out, data); // callback, used for flash loans
        _balance0 = IERC20(_token0).balanceOf(address(this));
        _balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = _balance0 > _reserve0 - amount0Out ? _balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = _balance1 > _reserve1 - amount1Out ? _balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'IIA'); // SwapPair: INSUFFICIENT_INPUT_AMOUNT
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        (address _token0, address _token1) = (token0, token1);
        if (amount0In > 0) _update0(amount0In * fee / 1e6); // accrue fees for token0 and move them out of pool
        if (amount1In > 0) _update1(amount1In * fee / 1e6); // accrue fees for token1 and move them out of pool
        _balance0 = IERC20(_token0).balanceOf(address(this)); // since we removed tokens, we need to reconfirm balances, can also simply use previous balance - amountIn/ 10000, but doing balanceOf again as safety check
        _balance1 = IERC20(_token1).balanceOf(address(this));
        // The curve, either x3y+y3x for stable pools, or x*y for volatile pools
        require(_k(_balance0, _balance1) >= _k(_reserve0, _reserve1), 'K'); // SwapPair: K
        }

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        (address _token0, address _token1) = (token0, token1);
        uint toSkim0 = IERC20(_token0).balanceOf(address(this)) - (reserve0);
        uint toSkim1 = IERC20(_token1).balanceOf(address(this)) - (reserve1);
        if (toSkim0 != 0) _safeTransfer(_token0, to, toSkim0);
        if (toSkim1 != 0) _safeTransfer(_token1, to, toSkim1);
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _f(uint x0, uint y) internal pure returns (uint) {
        return x0*(y*y/1e18*y/1e18)/1e18+(x0*x0/1e18*x0/1e18)*y/1e18;
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        return 3*x0*(y*y/1e18)/1e18+(x0*x0/1e18*x0/1e18);
    }

    function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
        for (uint i = 0; i < 255; i++) {
            uint y_prev = y;
            uint k = _f(x0, y);
            if (k < xy) {
                uint dy = (xy - k)*1e18/_d(x0, y);
                y = y + dy;
            } else {
                uint dy = (k - xy)*1e18/_d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint) {
        (uint _reserve0, uint _reserve1) = (reserve0, reserve1);
        amountIn -= amountIn * fee / 1e6; // remove fee from amount received
        return _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    function _getAmountOut(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1) internal view returns (uint) {
        if (stable) {
            uint xy =  _k(_reserve0, _reserve1);
            _reserve0 = _reserve0 * 1e18 / decimals0;
            _reserve1 = _reserve1 * 1e18 / decimals1;
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn = tokenIn == token0 ? amountIn * 1e18 / decimals0 : amountIn * 1e18 / decimals1;
            uint y = reserveB - _get_y(amountIn+reserveA, xy, reserveB);
            return y * (tokenIn == token0 ? decimals1 : decimals0) / 1e18;
        } else {
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            return amountIn * reserveB / (reserveA + amountIn);
        }
    }

    function _k(uint x, uint y) internal view returns (uint) {
        if (stable) {
            uint _x = x * 1e18 / decimals0;
            uint _y = y * 1e18 / decimals1;
            uint _a = (_x * _y) / 1e18;
            uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return _a * _b / 1e18;  // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }

    function _mint(address dst, uint amount) internal {
        _updateFor(dst); // balances must be updated on mint/burn/transfer
        totalSupply += amount;
        balanceOf[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint amount) internal {
        _updateFor(dst);
        totalSupply -= amount;
        balanceOf[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'SwapPair: EXPIRED');
        require(v == 27 || v == 28, 'SwapPair: INVALID_SIGNATURE');
        require(
            s < 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1,
            'SwapPair: INVALID_SIGNATURE'
        );
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256('1'),
                block.chainid,
                address(this)
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'SwapPair: INVALID_SIGNATURE');
        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowance[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        _updateFor(src); // update fee position for src
        _updateFor(dst); // update fee position for dst

        balanceOf[src] -= amount;
        balanceOf[dst] += amount;

        emit Transfer(src, dst, amount);
    }

    function _safeTransfer(address token,address to,uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
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
pragma solidity ^0.8.11;

import "./SwapPair.sol";

contract SwapFactory {

    bool public isPaused;
    address public pauser;
    address public pendingPauser;
    address public admin;

    mapping(address => mapping(address => mapping(bool => address))) public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals
    mapping(bool => uint) public fee;
    address public immutable feeCollector;

    address internal _temp0;
    address internal _temp1;
    bool internal _temp2;
    uint internal _temp3;

    event PairCreated(address indexed token0, address indexed token1, bool stable, address pair, uint);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Voter: only admin");
        _;
    }

    constructor(address _feeCollector) {
        require(
            _feeCollector != address(0),
            "SwapFactory: zero address provided in constructor"
        );
        pauser = msg.sender;
        fee[true] = 369; // 0.0369% for stable swaps (hundredth of a basis point / 369/1000000)
        fee[false] = 2700; // 0.27% for vaiable swaps (hundredth of a basis point / 2700/1000000)
        feeCollector = _feeCollector;
        admin = msg.sender;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function setPauser(address _pauser) external {
        require(msg.sender == pauser);
        pendingPauser = _pauser;
    }

    function acceptPauser() external {
        require(msg.sender == pendingPauser);
        pauser = pendingPauser;
    }

    function setPause(bool _state) external {
        require(msg.sender == pauser);
        isPaused = _state;
    }

    function setFeeTier(bool _stable, uint _fee) external {
        require(msg.sender == admin, "SwapFactory: only admin");
        fee[_stable] = _fee;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin && _admin != address(0), "SwapFactory; wrong input parameters");
        admin = _admin;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(SwapPair).creationCode);
    }

    function getInitializable() external view returns (address, address, bool, uint) {
        return (_temp0, _temp1, _temp2, _temp3);
    }

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair) {
        require(tokenA != tokenB, 'IA'); // BaseV1: IDENTICAL_ADDRESSES
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZA'); // BaseV1: ZERO_ADDRESS
        require(getPair[token0][token1][stable] == address(0), 'PE'); // BaseV1: PAIR_EXISTS - single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable)); // notice salt includes stable as well, 3 parameters
        (_temp0, _temp1, _temp2, _temp3) = (token0, token1, stable, fee[stable]);
        pair = address(new SwapPair{salt:salt}());
        getPair[token0][token1][stable] = pair;
        getPair[token1][token0][stable] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;
        emit PairCreated(token0, token1, stable, pair, allPairs.length);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// Fees contract is used as a 1:1 pair relationship to split out fees, this ensures that the curve does not need to be modified for LP shares
contract SwapFees {

    address internal immutable pair; // The pair it is bonded to
    address internal immutable token0; // token0 of pair, saved localy and statically for gas optimization
    address internal immutable token1; // Token1 of pair, saved localy and statically for gas optimization

    constructor(address _token0, address _token1) {
        require(
            _token0 != address(0) &&
            _token1 != address(0),
            "SwapFees: zero address provided in constructor"
        );
        pair = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    function _safeTransfer(address token,address to,uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    // Allow the pair to transfer fees to users
    function claimFeesFor(address recipient, uint amount0, uint amount1) external {
        require(msg.sender == pair);
        if (amount0 > 0) _safeTransfer(token0, recipient, amount0);
        if (amount1 > 0) _safeTransfer(token1, recipient, amount1);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Math {
    function divUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
        if (x % y != 0) z++;
    }

    function shiftRightUp(uint256 x, uint8 y) internal pure returns (uint256 z) {
        z = x >> y;
        if (x != z << y) z++;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Custom ERC20 interface for 2 methods.

interface cIERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwapCallee {
    function hook(address sender, uint amount0, uint amount1, bytes calldata data) external;
}