// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {Util} from "./Util.sol";
import {IStrategyHelper} from "./interfaces/IStrategyHelper.sol";

abstract contract Strategy is Util {
    error OverCap();
    error WrongStatus();
    error SlippageTooHigh();

    uint256 public constant S_LIQUIDATE = 1;
    uint256 public constant S_PAUSE = 2;
    uint256 public constant S_WITHDRAW = 3;
    uint256 public constant S_LIVE = 4;
    uint256 public cap;
    uint256 public totalShares;
    uint256 public slippage = 50;
    uint256 public status = S_LIVE;
    IStrategyHelper public strategyHelper;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event Mint(address indexed ast, uint256 amt, uint256 sha);
    event Burn(address indexed ast, uint256 amt, uint256 sha);
    event Earn(uint256 tvl, uint256 profit);

    constructor(address _strategyHelper) {
        strategyHelper = IStrategyHelper(_strategyHelper);
        exec[msg.sender] = true;
    }

    modifier statusAbove(uint256 sta) {
        if (status < sta) revert WrongStatus();
        _;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "cap") cap = data;
        if (what == "status") status = data;
        if (what == "slippage") slippage = data;
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        emit FileAddress(what, data);
    }

    function getSlippage(bytes memory dat) internal view returns (uint256) {
        if (dat.length > 0) {
            (uint256 slp) = abi.decode(dat, (uint256));
            if (slp > 500) revert SlippageTooHigh();
            return slp;
        }
        return slippage;
    }

    function rate(uint256 sha) public view returns (uint256) {
        if (totalShares == 0) return 0;
        if (status == S_LIQUIDATE) return 0;
        return _rate(sha);
    }

    function mint(address ast, uint256 amt, bytes calldata dat) external auth statusAbove(S_LIVE) returns (uint256) {
        uint256 sha = _mint(ast, amt, dat);
        totalShares += sha;
        if (cap != 0 && rate(totalShares) > cap) revert OverCap();
        emit Mint(ast, amt, sha);
        return sha;
    }

    function burn(address ast, uint256 sha, bytes calldata dat)
        external
        auth
        statusAbove(S_WITHDRAW)
        returns (uint256)
    {
        uint256 amt = _burn(ast, sha, dat);
        totalShares -= sha;
        emit Burn(ast, amt, sha);
        return amt;
    }

    function earn() public {
        if (totalShares == 0) return;
        uint256 bef = rate(totalShares);
        _earn();
        uint256 aft = rate(totalShares);
        emit Earn(aft, aft - min(aft, bef));
    }

    function exit(address str) public auth {
        status = S_PAUSE;
        _exit(str);
    }

    function move(address old) public auth {
        require(totalShares == 0, "ts=0");
        totalShares = Strategy(old).totalShares();
        _move(old);
    }

    function _rate(uint256) internal view virtual returns (uint256) {
        // calculate vault / lp value in usd (1e18) terms
        return 0;
    }

    function _earn() internal virtual {}

    function _mint(address ast, uint256 amt, bytes calldata dat) internal virtual returns (uint256) {}

    function _burn(address ast, uint256 sha, bytes calldata dat) internal virtual returns (uint256) {}

    function _exit(address str) internal virtual {}

    function _move(address old) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";

contract Util {
    error Paused();
    error NoReentering();
    error Unauthorized();
    error TransferFailed();

    bool internal entered;
    bool public paused;
    mapping(address => bool) public exec;

    modifier loop() {
        if (entered) revert NoReentering();
        entered = true;
        _;
        entered = false;
    }

    modifier live() {
        if (paused) revert Paused();
        _;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    // from OZ SignedMath
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }

    // from OZ Math
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 result = 1 << (log2(a) >> 1);
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) result += 1;
        }
        return result;
    }

    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 1e18;
        if (x == 0) return 0;
        require(x >> 255 == 0, "xoob");
        int256 x_int256 = int256(x);
        require(y < uint256(2 ** 254) / 1e20, "yoob");
        int256 y_int256 = int256(y);
        int256 logx_times_y = _ln(x_int256) * y_int256 / 1e18;
        require(-41e18 <= logx_times_y && logx_times_y <= 130e18, "poob");
        return uint256(_exp(logx_times_y));
    }

    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    function _ln(int256 a) private pure returns (int256) {
        if (a < 1e18) return -_ln((1e18 * 1e18) / a);
        int256 sum = 0;
        if (a >= a0 * 1e18) {
            a /= a0;
            sum += x0;
        }
        if (a >= a1 * 1e18) {
            a /= a1;
            sum += x1;
        }
        sum *= 100;
        a *= 100;
        if (a >= a2) {
            a = (a * 1e20) / a2;
            sum += x2;
        }
        if (a >= a3) {
            a = (a * 1e20) / a3;
            sum += x3;
        }
        if (a >= a4) {
            a = (a * 1e20) / a4;
            sum += x4;
        }
        if (a >= a5) {
            a = (a * 1e20) / a5;
            sum += x5;
        }
        if (a >= a6) {
            a = (a * 1e20) / a6;
            sum += x6;
        }
        if (a >= a7) {
            a = (a * 1e20) / a7;
            sum += x7;
        }
        if (a >= a8) {
            a = (a * 1e20) / a8;
            sum += x8;
        }
        if (a >= a9) {
            a = (a * 1e20) / a9;
            sum += x9;
        }
        if (a >= a10) {
            a = (a * 1e20) / a10;
            sum += x10;
        }
        if (a >= a11) {
            a = (a * 1e20) / a11;
            sum += x11;
        }
        int256 z = ((a - 1e20) * 1e20) / (a + 1e20);
        int256 z_squared = (z * z) / 1e20;
        int256 num = z;
        int256 seriesSum = num;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 3;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 5;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 7;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 9;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 11;
        seriesSum *= 2;
        return (sum + seriesSum) / 100;
    }

    function _exp(int256 x) internal pure returns (int256) {
        require(x >= -41e18 && x <= 130e18, "ie");
        if (x < 0) return ((1e18 * 1e18) / _exp(-x));
        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1;
        }
        x *= 100;
        int256 product = 1e20;
        if (x >= x2) {
            x -= x2;
            product = (product * a2) / 1e20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / 1e20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / 1e20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / 1e20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / 1e20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / 1e20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / 1e20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / 1e20;
        }
        int256 seriesSum = 1e20;
        int256 term;
        term = x;
        seriesSum += term;
        term = ((term * x) / 1e20) / 2;
        seriesSum += term;
        term = ((term * x) / 1e20) / 3;
        seriesSum += term;
        term = ((term * x) / 1e20) / 4;
        seriesSum += term;
        term = ((term * x) / 1e20) / 5;
        seriesSum += term;
        term = ((term * x) / 1e20) / 6;
        seriesSum += term;
        term = ((term * x) / 1e20) / 7;
        seriesSum += term;
        term = ((term * x) / 1e20) / 8;
        seriesSum += term;
        term = ((term * x) / 1e20) / 9;
        seriesSum += term;
        term = ((term * x) / 1e20) / 10;
        seriesSum += term;
        term = ((term * x) / 1e20) / 11;
        seriesSum += term;
        term = ((term * x) / 1e20) / 12;
        seriesSum += term;
        return (((product * seriesSum) / 1e20) * firstAN) / 100;
    }

    function pull(IERC20 asset, address usr, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transferFrom(usr, address(this), amt)) revert TransferFailed();
    }

    function pullTo(IERC20 asset, address usr, address to, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transferFrom(usr, to, amt)) revert TransferFailed();
    }

    function push(IERC20 asset, address usr, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transfer(usr, amt)) revert TransferFailed();
    }

    function emergencyForTesting(address target, uint256 value, bytes calldata data) external auth {
        target.call{value: value}(data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancerGauge {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function reward_tokens(uint256) external view returns (address);
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function claim_rewards() external;
}

interface IBalancerGaugeFactory {
    function getPoolGauge(address) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancerPool {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function getRate() external view returns (uint256);
    function getPoolId() external view returns (bytes32);
    function getNormalizedWeights() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancerVault {
    function getPoolTokens(bytes32) external view returns (address[] memory, uint256[] memory, uint256);

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request)
        external
        payable;

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request)
        external;

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        uint8 kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IStrategyHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Strategy} from "../Strategy.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IBalancerPool} from "../interfaces/IBalancerPool.sol";
import {IBalancerVault} from "../interfaces/IBalancerVault.sol";
import {IBalancerGauge, IBalancerGaugeFactory} from "../interfaces/IBalancerGauge.sol";

contract StrategyBalancer is Strategy {
    error LpTokenPriceSlipped();

    string public name;
    IBalancerVault public vault;
    IBalancerGauge public gauge;
    IBalancerPool public pool;
    bytes32 public poolId;
    uint256 public kind;
    address public inputAsset;

    constructor(address _strategyHelper, address _vault, address _gaugeFactory, address _pool, address _inputAsset)
        Strategy(_strategyHelper)
    {
        vault = IBalancerVault(_vault);
        gauge = IBalancerGauge(IBalancerGaugeFactory(_gaugeFactory).getPoolGauge(_pool));
        pool = IBalancerPool(_pool);
        poolId = IBalancerPool(_pool).getPoolId();
        inputAsset = _inputAsset;
        name = IERC20(_pool).name();
    }

    function _rate(uint256 sha) internal view override returns (uint256) {
        uint256 value = gauge.balanceOf(address(this)) * getPoolPrice() / 1e18;
        return sha * value / totalShares;
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        earn();
        pull(IERC20(ast), msg.sender, amt);
        uint256 tma = gauge.balanceOf(address(this));
        uint256 slp = getSlippage(dat);
        uint256 bal = _joinPool(ast, amt, slp);
        pool.approve(address(gauge), bal);
        gauge.deposit(bal);
        return tma == 0 ? bal : bal * totalShares / tma;
    }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal override returns (uint256) {
        earn();
        uint256 slp = getSlippage(dat);
        uint256 tma = gauge.balanceOf(address(this));
        uint256 amt = sha * tma / totalShares;
        gauge.withdraw(amt);

        {
            (address[] memory poolTokens,,) = vault.getPoolTokens(poolId);
            address _inputAsset = inputAsset;
            uint256 length = poolTokens.length;
            uint256[] memory minAmountsOut = new uint256[](length);
            uint256 inputAssetIndex;
            for (uint256 i; i < length; i++) {
                if (poolTokens[i] == _inputAsset) inputAssetIndex = i;
            }

            pool.approve(address(vault), amt);
            vault.exitPool(
                poolId,
                address(this),
                payable(address(this)),
                IBalancerVault.ExitPoolRequest({
                    assets: poolTokens,
                    minAmountsOut: minAmountsOut,
                    userData: abi.encode(uint256(0), amt, inputAssetIndex),
                    toInternalBalance: false
                })
            );
        }

        uint256 bal = IERC20(inputAsset).balanceOf(address(this));
        {
            uint256 value = amt * getPoolPrice() / 1e18;
            uint256 minValue = strategyHelper.value(inputAsset, bal) * (10000 - slp) / 10000;
            if (value < minValue) revert LpTokenPriceSlipped();
        }

        IERC20(inputAsset).approve(address(strategyHelper), bal);
        return strategyHelper.swap(inputAsset, ast, bal, slp, msg.sender);
    }

    function _earn() internal override {
        gauge.claim_rewards();
        address _inputAsset = inputAsset;
        for (uint256 i = 0; i < 5; i++) {
            address token = gauge.reward_tokens(i);
            if (token == address(0)) break;
            uint256 bal = IERC20(token).balanceOf(address(this));
            if (strategyHelper.value(token, bal) < 0.5e18) return;
            IERC20(token).approve(address(strategyHelper), bal);
            strategyHelper.swap(token, _inputAsset, bal, slippage, address(this));
        }
        uint256 balIa = IERC20(_inputAsset).balanceOf(address(this));
        uint256 balLp = _joinPool(_inputAsset, balIa, slippage);
        pool.approve(address(gauge), balLp);
        gauge.deposit(balLp);
    }

    function _exit(address str) internal override {
        earn();
        uint256 bal = gauge.balanceOf(address(this));
        gauge.withdraw(bal);
        push(IERC20(address(pool)), str, bal);
    }

    function _move(address) internal override {
        uint256 bal = pool.balanceOf(address(this));
        totalShares = bal;
        pool.approve(address(gauge), bal);
        gauge.deposit(bal);
    }

    function _joinPool(address ast, uint256 amt, uint256 slp) internal returns (uint256) {
        address _inputAsset = inputAsset;
        (address[] memory poolTokens,,) = vault.getPoolTokens(poolId);

        IERC20(ast).approve(address(strategyHelper), amt);
        uint256 bal = strategyHelper.swap(ast, _inputAsset, amt, slp, address(this));

        uint256 length = poolTokens.length;
        uint256[] memory amountsIn = new uint256[](length);
        uint256[] memory maxAmountsIn = new uint256[](length);
        for (uint256 i; i < length; i++) {
            if (poolTokens[i] == _inputAsset) {
                amountsIn[i] = bal;
                maxAmountsIn[i] = bal;
            }
        }

        IERC20(inputAsset).approve(address(vault), bal);
        vault.joinPool(
            poolId,
            address(this),
            address(this),
            IBalancerVault.JoinPoolRequest({
                assets: poolTokens,
                maxAmountsIn: maxAmountsIn,
                userData: abi.encode(uint256(1), amountsIn, uint256(0)),
                fromInternalBalance: false
            })
        );

        uint256 lpBal = pool.balanceOf(address(this));
        uint256 value = lpBal * getPoolPrice() / 1e18;
        uint256 minValue = strategyHelper.value(inputAsset, bal) * (10000 - slp) / 10000;
        if (value < minValue) revert LpTokenPriceSlipped();
        return lpBal;
    }

    function getPoolPrice() internal view returns (uint256) {
        (address[] memory poolTokens, uint256[] memory balances,) = vault.getPoolTokens(poolId);
        uint256 length = poolTokens.length;
        uint256[] memory weights = pool.getNormalizedWeights();
        uint256 temp = 1e18;
        uint256 invariant = 1e18;
        for (uint256 i = 0; i < length; i++) {
            temp = temp * pow(strategyHelper.price(poolTokens[i]) * 1e18 / weights[i], weights[i]) / 1e18;
            invariant =
                invariant * pow(balances[i] * 1e18 / (10 ** IERC20(poolTokens[i]).decimals()), weights[i]) / 1e18;
        }
        return invariant * temp / pool.totalSupply();
    }
}