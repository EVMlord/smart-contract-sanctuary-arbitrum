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
    event Earn(uint256 val, uint256 amt);

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

    function burn(address ast, uint256 sha, bytes calldata dat) external auth statusAbove(S_WITHDRAW) returns (uint256) {
        uint256 amt = _burn(ast, sha, dat);
        totalShares -= sha;
        emit Burn(ast, amt, sha);
        return amt;
    }

    function earn() public {
        uint256 bef = rate(totalShares);
        _earn();
        uint256 aft = rate(totalShares);
        emit Earn(aft, aft - min(aft, bef));
    }

    function _rate(uint256) internal view virtual returns (uint256) {
        // calculate vault / lp value in usd (1e18) terms
        return 0;
    }

    function _earn() internal virtual { }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal virtual returns (uint256) { }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal virtual returns (uint256) { }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Strategy} from "./Strategy.sol";
import {IERC20} from "./interfaces/IERC20.sol";

interface IRewardRouter {
    function glpManager() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    )
        external
        returns (uint256);
    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    )
        external
        returns (uint256);
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
}

interface IGlpManager {
    function getAumInUsdg(bool) external view returns (uint256);
    function glp() external view returns (address);
}

interface IRewardTracker {
    function claimable(address) external view returns (uint256);
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
}

interface IOracle {
    function latestAnswer() external view returns (int256);
}

contract StrategyGMXGLP is Strategy {
    string public constant name = "GMX GLP";
    IRewardRouter public rewardRouter;
    IRewardRouter public rewardRouterClaiming;
    IGlpManager public glpManager;
    IERC20 public glp;
    IERC20 public weth;

    constructor(
        address _strategyHelper,
        address _rewardRouter,
        address _rewardRouterClaiming,
        address _weth
    ) Strategy(_strategyHelper) {
        rewardRouter = IRewardRouter(_rewardRouter);
        rewardRouterClaiming = IRewardRouter(_rewardRouterClaiming);
        glpManager = IGlpManager(rewardRouter.glpManager());
        glp = IERC20(glpManager.glp());
        weth = IERC20(_weth);
    }

    function _rate(uint256 sha) internal view override returns (uint256) {
        if (sha == 0 || totalShares == 0) return 0;
        uint256 tot = glp.totalSupply();
        uint256 amt = IERC20(rewardRouter.stakedGlpTracker()).balanceOf(address(this));
        uint256 val = glpManager.getAumInUsdg(false);
        uint256 rew = IRewardTracker(rewardRouter.feeGlpTracker()).claimable(address(this));
        uint256 amtval = (val * amt / tot) + strategyHelper.value(address(weth), rew);
        return sha * amtval / totalShares;
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        earn();
        pull(IERC20(ast), msg.sender, amt);
        uint256 slp = getSlippage(dat);
        uint256 tma = IERC20(rewardRouter.stakedGlpTracker()).balanceOf(address(this));
        uint256 pri = glpManager.getAumInUsdg(true) * 1e18 / glp.totalSupply();
        uint256 minUsd = strategyHelper.value(ast, amt) * slp / 10000;
        uint256 minGlp = minUsd * 1e18 / pri;
        IERC20(ast).approve(address(glpManager), amt);
        uint256 out = rewardRouter.mintAndStakeGlp(ast, amt, minUsd, minGlp);
        return tma == 0 ? out : out * totalShares / tma;
    }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal override returns (uint256) {
        earn();
        uint256 slp = getSlippage(dat);
        uint256 tma = IERC20(rewardRouter.stakedGlpTracker()).balanceOf(address(this));
        uint256 amt = sha * tma / totalShares;
        uint256 pri = glpManager.getAumInUsdg(false) * 1e18 / glp.totalSupply();
        uint256 min = (amt * pri / 1e18) * slp / 10000;
        min = min * (10 ** IERC20(ast).decimals()) / 1e18;
        return rewardRouter.unstakeAndRedeemGlp(ast, amt, min, msg.sender);
    }

    function _earn() internal override {
        rewardRouterClaiming.handleRewards(true, true, true, true, true, true, false);
        uint256 amt = weth.balanceOf(address(this));
        if (amt > 0) {
            weth.approve(address(glpManager), amt);
            rewardRouter.mintAndStakeGlp(address(weth), amt, 0, 0);
        }
    }

    function exit(address str) public auth {
        IERC20 fsglp = IERC20(rewardRouter.stakedGlpTracker());
        push(fsglp, str, fsglp.balanceOf(address(this)));
    }

    function move(address old) public auth {
        require(totalShares != 0, "ts!=0");
        // We should now be holding the fsGLP balance from the old strategy
        totalShares = StrategyGMXGLP(old).totalShares();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from './interfaces/IERC20.sol';

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