// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IPositionManager} from "src/IPositionManager.sol";
import {IPriceUtils} from "src/IPriceUtils.sol";
import {TokenExposure} from "src/TokenExposure.sol";
import {IVaultReader} from "gmx/IVaultReader.sol";
import {IGlpUtils} from "src/IGlpUtils.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPoolCommitter} from "perp-pool/IPoolCommitter.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {TokenAllocation} from "src/TokenAllocation.sol";
import {GlpTokenAllocation} from "src/GlpTokenAllocation.sol";
import {DeltaNeutralRebalancer} from "src/DeltaNeutralRebalancer.sol";
import {IRewardRouter} from "gmx/IRewardRouter.sol";

contract GlpPositionManager is IPositionManager, Ownable, Test {
  uint256 private constant USDC_MULTIPLIER = 1*10**6;
  uint256 private constant GLP_MULTIPLIER = 1*10**18;
  uint256 private constant PERCENT_DIVISOR = 1000;
  uint256 private constant BASIS_POINTS_DIVISOR = 10000;
  uint256 private constant DEFAULT_SLIPPAGE = 30;
  uint256 private constant PRICE_PRECISION = 10 ** 30;

  uint256 private _costBasis;
  uint256 private tokenAmount;

  IPriceUtils private priceUtils;
  IGlpUtils private glpUtils;
  IPoolCommitter private poolCommitter;
  DeltaNeutralRebalancer private deltaNeutralRebalancer;
  ERC20 private usdcToken;
  IRewardRouter private rewardRouter;
  address[] private glpTokens;

  modifier onlyRebalancer {
    require(msg.sender == address(deltaNeutralRebalancer));
    _;
  }

  constructor(address _priceUtilsAddress, address _glpUtilsAddress, address _poolCommitterAddress, address _usdcAddress, address _rewardRouterAddress, address _deltaNeutralRebalancerAddress) {
    priceUtils = IPriceUtils(_priceUtilsAddress);
    glpUtils = IGlpUtils(_glpUtilsAddress);
    poolCommitter = IPoolCommitter(_poolCommitterAddress);
    usdcToken = ERC20(_usdcAddress);
    deltaNeutralRebalancer = DeltaNeutralRebalancer(_deltaNeutralRebalancerAddress);
    rewardRouter = IRewardRouter(_rewardRouterAddress);
  }

  function positionWorth() override public view returns (uint256) {
    uint256 glpPrice = priceUtils.glpPrice();
    return (tokenAmount * glpPrice / GLP_MULTIPLIER);
  }

  function costBasis() override public view returns (uint256) {
    return _costBasis;
  }

  function buy(uint256 usdcAmount) override external returns (uint256) {
    uint256 currentPrice = priceUtils.glpPrice();
    uint256 glpToPurchase = usdcAmount * currentPrice / USDC_MULTIPLIER;
    usdcToken.transferFrom(address(deltaNeutralRebalancer), address(this), usdcAmount);

    uint256 glpAmountAfterSlippage = glpToPurchase * (BASIS_POINTS_DIVISOR - DEFAULT_SLIPPAGE) / BASIS_POINTS_DIVISOR;
    usdcToken.approve(address(rewardRouter), usdcAmount);
    uint256 glpAmount = rewardRouter.mintAndStakeGlp(address(usdcToken), usdcAmount, 0, glpAmountAfterSlippage);

    _costBasis += usdcAmount;
    tokenAmount += glpAmount;  
    return glpAmount;
  }

  function sell(uint256 usdcAmount) override external returns (uint256) {
    uint256 currentPrice = priceUtils.glpPrice();
    uint256 glpToSell = usdcAmount * currentPrice / USDC_MULTIPLIER;
    uint256 usdcAmountAfterSlippage = usdcAmount * (BASIS_POINTS_DIVISOR - DEFAULT_SLIPPAGE) / BASIS_POINTS_DIVISOR;

    uint256 usdcRetrieved = rewardRouter.unstakeAndRedeemGlp(address(usdcToken), glpToSell, usdcAmountAfterSlippage, address(deltaNeutralRebalancer));
    _costBasis -= usdcRetrieved;
    tokenAmount -= glpToSell;
    return usdcRetrieved;
  }

  function pnl() override external view returns (int256) {
    return int256(positionWorth()) - int256(costBasis());
  }

  function exposures() override external view returns (TokenExposure[] memory) {
    return glpUtils.getGlpTokenExposure(positionWorth(), glpTokens);
  }

  function allocation() override external view returns (TokenAllocation[] memory) {
    GlpTokenAllocation[] memory glpAllocations = glpUtils.getGlpTokenAllocations(glpTokens);
    TokenAllocation[] memory tokenAllocations = new TokenAllocation[](glpAllocations.length);

    for (uint i = 0; i < glpAllocations.length; i++) {
      tokenAllocations[i] = TokenAllocation({
        tokenAddress: glpAllocations[i].tokenAddress,
        percentage: glpAllocations[i].allocation,
        leverage: 1
      });
    }

    return tokenAllocations;
  }

  function canRebalance() override external pure returns (bool) {
    return true;
  }

  function price() override external view returns (uint256) {
    return priceUtils.glpPrice();
  }

  function setGlpTokens(address[] memory _glpTokens) external onlyOwner() {
    glpTokens = _glpTokens;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Script.sol";
import "ds-test/test.sol";

// Wrappers around Cheatcodes to avoid footguns
abstract contract Test is DSTest, Script {
    using stdStorage for StdStorage;

    uint256 internal constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    StdStorage internal stdstore;

    /*//////////////////////////////////////////////////////////////////////////
                                    STD-LOGS
    //////////////////////////////////////////////////////////////////////////*/

    event log_array(uint256[] val);
    event log_array(int256[] val);
    event log_array(address[] val);
    event log_named_array(string key, uint256[] val);
    event log_named_array(string key, int256[] val);
    event log_named_array(string key, address[] val);

    /*//////////////////////////////////////////////////////////////////////////
                                    STD-CHEATS
    //////////////////////////////////////////////////////////////////////////*/

    // Skip forward or rewind time by the specified number of seconds
    function skip(uint256 time) internal {
        vm.warp(block.timestamp + time);
    }

    function rewind(uint256 time) internal {
        vm.warp(block.timestamp - time);
    }

    // Setup a prank from an address that has some ether
    function hoax(address who) internal {
        vm.deal(who, 1 << 128);
        vm.prank(who);
    }

    function hoax(address who, uint256 give) internal {
        vm.deal(who, give);
        vm.prank(who);
    }

    function hoax(address who, address origin) internal {
        vm.deal(who, 1 << 128);
        vm.prank(who, origin);
    }

    function hoax(address who, address origin, uint256 give) internal {
        vm.deal(who, give);
        vm.prank(who, origin);
    }

    // Start perpetual prank from an address that has some ether
    function startHoax(address who) internal {
        vm.deal(who, 1 << 128);
        vm.startPrank(who);
    }

    function startHoax(address who, uint256 give) internal {
        vm.deal(who, give);
        vm.startPrank(who);
    }

    // Start perpetual prank from an address that has some ether
    // tx.origin is set to the origin parameter
    function startHoax(address who, address origin) internal {
        vm.deal(who, 1 << 128);
        vm.startPrank(who, origin);
    }

    function startHoax(address who, address origin, uint256 give) internal {
        vm.deal(who, give);
        vm.startPrank(who, origin);
    }

    function changePrank(address who) internal {
        vm.stopPrank();
        vm.startPrank(who);
    }

    // creates a labeled address and the corresponding private key
    function makeAddrAndKey(string memory name) internal returns(address addr, uint256 privateKey) {
        privateKey = uint256(keccak256(abi.encodePacked(name)));
        addr = vm.addr(privateKey);
        vm.label(addr, name);
    }

    // creates a labeled address
    function makeAddr(string memory name) internal returns(address addr) {
        (addr,) = makeAddrAndKey(name);
    }

    // DEPRECATED: Use `deal` instead
    function tip(address token, address to, uint256 give) internal {
        emit log_named_string("WARNING", "Test tip(address,address,uint256): The `tip` stdcheat has been deprecated. Use `deal` instead.");
        stdstore
            .target(token)
            .sig(0x70a08231)
            .with_key(to)
            .checked_write(give);
    }

    // The same as Vm's `deal`
    // Use the alternative signature for ERC20 tokens
    function deal(address to, uint256 give) internal {
        vm.deal(to, give);
    }

    // Set the balance of an account for any ERC20 token
    // Use the alternative signature to update `totalSupply`
    function deal(address token, address to, uint256 give) internal {
        deal(token, to, give, false);
    }

    function deal(address token, address to, uint256 give, bool adjust) internal {
        // get current balance
        (, bytes memory balData) = token.call(abi.encodeWithSelector(0x70a08231, to));
        uint256 prevBal = abi.decode(balData, (uint256));

        // update balance
        stdstore
            .target(token)
            .sig(0x70a08231)
            .with_key(to)
            .checked_write(give);

        // update total supply
        if(adjust){
            (, bytes memory totSupData) = token.call(abi.encodeWithSelector(0x18160ddd));
            uint256 totSup = abi.decode(totSupData, (uint256));
            if(give < prevBal) {
                totSup -= (prevBal - give);
            } else {
                totSup += (give - prevBal);
            }
            stdstore
                .target(token)
                .sig(0x18160ddd)
                .checked_write(totSup);
        }
    }

    function bound(uint256 x, uint256 min, uint256 max) internal virtual returns (uint256 result) {
        require(min <= max, "Test bound(uint256,uint256,uint256): Max is less than min.");

        uint256 size = max - min;

        if (size == 0)
        {
            result = min;
        }
        else if (size == UINT256_MAX)
        {
            result = x;
        }
        else
        {
            ++size; // make `max` inclusive
            uint256 mod = x % size;
            result = min + mod;
        }

        emit log_named_uint("Bound Result", result);
    }

    // Deploy a contract by fetching the contract bytecode from
    // the artifacts directory
    // e.g. `deployCode(code, abi.encode(arg1,arg2,arg3))`
    function deployCode(string memory what, bytes memory args)
        internal
        returns (address addr)
    {
        bytes memory bytecode = abi.encodePacked(vm.getCode(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(
            addr != address(0),
            "Test deployCode(string,bytes): Deployment failed."
        );
    }

    function deployCode(string memory what)
        internal
        returns (address addr)
    {
        bytes memory bytecode = vm.getCode(what);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(
            addr != address(0),
            "Test deployCode(string): Deployment failed."
        );
    }

    /// deploy contract with value on construction
    function deployCode(string memory what, bytes memory args, uint256 val)
        internal
        returns (address addr)
    {
        bytes memory bytecode = abi.encodePacked(vm.getCode(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(val, add(bytecode, 0x20), mload(bytecode))
        }

        require(
            addr != address(0),
            "Test deployCode(string,bytes,uint256): Deployment failed."
        );
    }

    function deployCode(string memory what, uint256 val)
        internal
        returns (address addr)
    {
        bytes memory bytecode = vm.getCode(what);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(val, add(bytecode, 0x20), mload(bytecode))
        }

        require(
            addr != address(0),
            "Test deployCode(string,uint256): Deployment failed."
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    STD-ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function fail(string memory err) internal virtual {
        emit log_named_string("Error", err);
        fail();
    }

    function assertFalse(bool data) internal virtual {
        assertTrue(!data);
    }

    function assertFalse(bool data, string memory err) internal virtual {
        assertTrue(!data, err);
    }

    function assertEq(bool a, bool b) internal {
        if (a != b) {
            emit log                ("Error: a == b not satisfied [bool]");
            emit log_named_string   ("  Expected", b ? "true" : "false");
            emit log_named_string   ("    Actual", a ? "true" : "false");
            fail();
        }
    }

    function assertEq(bool a, bool b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes memory a, bytes memory b) internal {
        assertEq0(a, b);
    }

    function assertEq(bytes memory a, bytes memory b, string memory err) internal {
        assertEq0(a, b, err);
    }

    function assertEq(uint256[] memory a, uint256[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [uint[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(int256[] memory a, int256[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [int[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(address[] memory a, address[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [address[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(uint256[] memory a, uint256[] memory b, string memory err) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(int256[] memory a, int256[] memory b, string memory err) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }


    function assertEq(address[] memory a, address[] memory b, string memory err) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertApproxEqAbs(
        uint256 a,
        uint256 b,
        uint256 maxDelta
    ) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log            ("Error: a ~= b not satisfied [uint]");
            emit log_named_uint ("  Expected", b);
            emit log_named_uint ("    Actual", a);
            emit log_named_uint (" Max Delta", maxDelta);
            emit log_named_uint ("     Delta", delta);
            fail();
        }
    }

    function assertApproxEqAbs(
        uint256 a,
        uint256 b,
        uint256 maxDelta,
        string memory err
    ) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string   ("Error", err);
            assertApproxEqAbs(a, b, maxDelta);
        }
    }

    function assertApproxEqAbs(
        int256 a,
        int256 b,
        uint256 maxDelta
    ) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log            ("Error: a ~= b not satisfied [int]");
            emit log_named_int  ("  Expected", b);
            emit log_named_int  ("    Actual", a);
            emit log_named_uint (" Max Delta", maxDelta);
            emit log_named_uint ("     Delta", delta);
            fail();
        }
    }

    function assertApproxEqAbs(
        int256 a,
        int256 b,
        uint256 maxDelta,
        string memory err
    ) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string   ("Error", err);
            assertApproxEqAbs(a, b, maxDelta);
        }
    }

    function assertApproxEqRel(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta // An 18 decimal fixed point number, where 1e18 == 100%
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log                    ("Error: a ~= b not satisfied [uint]");
            emit log_named_uint         ("    Expected", b);
            emit log_named_uint         ("      Actual", a);
            emit log_named_decimal_uint (" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint ("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRel(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        string memory err
    ) internal virtual {
        if (b == 0) return assertEq(a, b, err); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string       ("Error", err);
            assertApproxEqRel(a, b, maxPercentDelta);
        }
    }

    function assertApproxEqRel(
        int256 a,
        int256 b,
        uint256 maxPercentDelta
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log                   ("Error: a ~= b not satisfied [int]");
            emit log_named_int         ("    Expected", b);
            emit log_named_int         ("      Actual", a);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRel(
        int256 a,
        int256 b,
        uint256 maxPercentDelta,
        string memory err
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string      ("Error", err);
            assertApproxEqRel(a, b, maxPercentDelta);
        }
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                STD-ERRORS
//////////////////////////////////////////////////////////////////////////*/

library stdError {
    bytes public constant assertionError = abi.encodeWithSignature("Panic(uint256)", 0x01);
    bytes public constant arithmeticError = abi.encodeWithSignature("Panic(uint256)", 0x11);
    bytes public constant divisionError = abi.encodeWithSignature("Panic(uint256)", 0x12);
    bytes public constant enumConversionError = abi.encodeWithSignature("Panic(uint256)", 0x21);
    bytes public constant encodeStorageError = abi.encodeWithSignature("Panic(uint256)", 0x22);
    bytes public constant popError = abi.encodeWithSignature("Panic(uint256)", 0x31);
    bytes public constant indexOOBError = abi.encodeWithSignature("Panic(uint256)", 0x32);
    bytes public constant memOverflowError = abi.encodeWithSignature("Panic(uint256)", 0x41);
    bytes public constant zeroVarError = abi.encodeWithSignature("Panic(uint256)", 0x51);
    // DEPRECATED: Use Vm's `expectRevert` without any arguments instead
    bytes public constant lowLevelError = bytes(""); // `0x`
}

/*//////////////////////////////////////////////////////////////////////////
                                STD-STORAGE
//////////////////////////////////////////////////////////////////////////*/

struct StdStorage {
    mapping (address => mapping(bytes4 => mapping(bytes32 => uint256))) slots;
    mapping (address => mapping(bytes4 =>  mapping(bytes32 => bool))) finds;

    bytes32[] _keys;
    bytes4 _sig;
    uint256 _depth;
    address _target;
    bytes32 _set;
}

library stdStorage {
    event SlotFound(address who, bytes4 fsig, bytes32 keysHash, uint slot);
    event WARNING_UninitedSlot(address who, uint slot);

    uint256 private constant UINT256_MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    int256 private constant INT256_MAX = 57896044618658097711785492504343953926634992332820282019728792003956564819967;

    Vm private constant vm_std_store = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

    function sigs(
        string memory sigStr
    )
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(bytes(sigStr)));
    }

    /// @notice find an arbitrary storage slot given a function sig, input data, address of the contract and a value to check against
    // slot complexity:
    //  if flat, will be bytes32(uint256(uint));
    //  if map, will be keccak256(abi.encode(key, uint(slot)));
    //  if deep map, will be keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))));
    //  if map struct, will be bytes32(uint256(keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))))) + structFieldDepth);
    function find(
        StdStorage storage self
    )
        internal
        returns (uint256)
    {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        // calldata to test against
        if (self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
        }
        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        vm_std_store.record();
        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32*field_depth);
        }

        (bytes32[] memory reads, ) = vm_std_store.accesses(address(who));
        if (reads.length == 1) {
            bytes32 curr = vm_std_store.load(who, reads[0]);
            if (curr == bytes32(0)) {
                emit WARNING_UninitedSlot(who, uint256(reads[0]));
            }
            if (fdat != curr) {
                require(false, "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported.");
            }
            emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[0]));
            self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[0]);
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
        } else if (reads.length > 1) {
            for (uint256 i = 0; i < reads.length; i++) {
                bytes32 prev = vm_std_store.load(who, reads[i]);
                if (prev == bytes32(0)) {
                    emit WARNING_UninitedSlot(who, uint256(reads[i]));
                }
                // store
                vm_std_store.store(who, reads[i], bytes32(hex"1337"));
                bool success;
                bytes memory rdat;
                {
                    (success, rdat) = who.staticcall(cald);
                    fdat = bytesToBytes32(rdat, 32*field_depth);
                }

                if (success && fdat == bytes32(hex"1337")) {
                    // we found which of the slots is the actual one
                    emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[i]));
                    self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[i]);
                    self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
                    vm_std_store.store(who, reads[i], prev);
                    break;
                }
                vm_std_store.store(who, reads[i], prev);
            }
        } else {
            require(false, "stdStorage find(StdStorage): No storage use detected for target.");
        }

        require(self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))], "stdStorage find(StdStorage): Slot(s) not found.");

        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;

        return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        self._target = _target;
        return self;
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        self._sig = _sig;
        return self;
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        self._sig = sigs(_sig);
        return self;
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        self._keys.push(bytes32(uint256(uint160(who))));
        return self;
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        self._keys.push(bytes32(amt));
        return self;
    }
    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        self._keys.push(key);
        return self;
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        self._depth = _depth;
        return self;
    }

    function checked_write(StdStorage storage self, address who) internal {
        checked_write(self, bytes32(uint256(uint160(who))));
    }

    function checked_write(StdStorage storage self, uint256 amt) internal {
        checked_write(self, bytes32(amt));
    }

    function checked_write(StdStorage storage self, bool write) internal {
        bytes32 t;
        /// @solidity memory-safe-assembly
        assembly {
            t := write
        }
        checked_write(self, t);
    }

    function checked_write(
        StdStorage storage self,
        bytes32 set
    ) internal {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        if (!self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            find(self);
        }
        bytes32 slot = bytes32(self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]);

        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32*field_depth);
        }
        bytes32 curr = vm_std_store.load(who, slot);

        if (fdat != curr) {
            require(false, "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported.");
        }
        vm_std_store.store(who, slot, set);
        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;
    }

    function read(StdStorage storage self) private returns (bytes memory) {
        address t = self._target;
        uint256 s = find(self);
        return abi.encode(vm_std_store.load(t, bytes32(s)));
    }

    function read_bytes32(StdStorage storage self) internal returns (bytes32) {
        return abi.decode(read(self), (bytes32));
    }


    function read_bool(StdStorage storage self) internal returns (bool) {
        int256 v = read_int(self);
        if (v == 0) return false;
        if (v == 1) return true;
        revert("stdStorage read_bool(StdStorage): Cannot decode. Make sure you are reading a bool.");
    }

    function read_address(StdStorage storage self) internal returns (address) {
        return abi.decode(read(self), (address));
    }

    function read_uint(StdStorage storage self) internal returns (uint256) {
        return abi.decode(read(self), (uint256));
    }

    function read_int(StdStorage storage self) internal returns (int256) {
        return abi.decode(read(self), (int256));
    }

    function bytesToBytes32(bytes memory b, uint offset) public pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function flatten(bytes32[] memory b) private pure returns (bytes memory)
    {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                STD-MATH
//////////////////////////////////////////////////////////////////////////*/

library stdMath {
    int256 private constant INT256_MIN = -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function abs(int256 a) internal pure returns (uint256) {
        // Required or it will fail when `a = type(int256).min`
        if (a == INT256_MIN)
            return 57896044618658097711785492504343953926634992332820282019728792003956564819968;

        return uint256(a > 0 ? a : -a);
    }

    function delta(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b
            ? a - b
            : b - a;
    }

    function delta(int256 a, int256 b) internal pure returns (uint256) {
        // a and b are of the same sign
        // this works thanks to two's complement, the left-most bit is the sign bit
        if ((a ^ b) > -1) {
            return delta(abs(a), abs(b));
        }

        // a and b are of opposite signs
        return abs(a) + abs(b);
    }

    function percentDelta(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);

        return absDelta * 1e18 / b;
    }

    function percentDelta(int256 a, int256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);
        uint256 absB = abs(b);

        return absDelta * 1e18 / absB;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenExposure,NetTokenExposure} from "src/TokenExposure.sol";
import {TokenAllocation} from "src/TokenAllocation.sol";
import {RebalanceAction} from "src/RebalanceAction.sol";

abstract contract IPositionManager {
  function positionWorth() virtual external view returns (uint256);
  function costBasis() virtual external view returns (uint256);
  function pnl() virtual external view returns (int256);
  function exposures() virtual external view returns (TokenExposure[] memory);
  function allocation() virtual external view returns (TokenAllocation[] memory );
  function buy(uint256) virtual external returns (uint256);
  function sell(uint256) virtual external returns (uint256);
  function price() virtual external view returns (uint256);
  function canRebalance() virtual external view returns (bool);
  function rebalance(uint256 usdcAmountToHave) virtual external returns (bool) {
    RebalanceAction rebalanceAction = this.getRebalanceAction(usdcAmountToHave);
    uint256 worth = this.positionWorth();
    if (rebalanceAction == RebalanceAction.Buy) {
      this.buy(usdcAmountToHave - worth);
    } else if (rebalanceAction == RebalanceAction.Sell) {
      this.sell(worth - usdcAmountToHave);
    }

    return true;
  }

  function allocationByToken(address tokenAddress) external view returns (TokenAllocation memory) {
    TokenAllocation[] memory tokenAllocations = this.allocation();
    for (uint256 i = 0; i < tokenAllocations.length; i++) {
        if (tokenAllocations[i].tokenAddress == tokenAddress) {
          return tokenAllocations[i];
        }
    } 

    revert("Token not found");
  }

  function getRebalanceAction(uint256 usdcAmountToHave) external view returns (RebalanceAction) {
    uint256 worth = this.positionWorth();
    if (usdcAmountToHave > worth) return RebalanceAction.Buy;
    if (usdcAmountToHave < worth) return RebalanceAction.Sell;
    return RebalanceAction.Nothing; 
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PositionType} from "src/PositionType.sol";

interface IPriceUtils {
  function glpPrice() external view returns (uint256);
  function perpPoolTokenPrice(address leveragedPoolAddress, PositionType positionType) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPositionManager} from "src/IPositionManager.sol";

struct TokenExposure {
  int256 amount;
  address token; 
}

struct NetTokenExposure {
  int256 amount;
  address token; 
  uint32 amountOfPositions;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVaultReader {
  function getVaultTokenInfoV3(address _vault, address _positionManager, address _weth, uint256 _usdgAmount, address[] memory _tokens) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenExposure} from "src/TokenExposure.sol";
import {GlpTokenAllocation} from "src/GlpTokenAllocation.sol";

interface IGlpUtils {
    function getGlpTokenAllocations(address[] memory tokens)
        external
        view
        returns (GlpTokenAllocation[] memory);

    function getGlpTokenExposure(
        uint256 glpPositionWorth,
        address[] memory tokens
    ) external view returns (TokenExposure[] memory);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPoolCommitter {
    /// Type of commit
    enum CommitType {
        ShortMint, // Mint short tokens
        ShortBurn, // Burn short tokens
        LongMint, // Mint long tokens
        LongBurn, // Burn long tokens
        LongBurnShortMint, // Burn Long tokens, then instantly mint in same upkeep
        ShortBurnLongMint // Burn Short tokens, then instantly mint in same upkeep
    }

    function isMint(CommitType t) external pure returns (bool);

    function isBurn(CommitType t) external pure returns (bool);

    function isLong(CommitType t) external pure returns (bool);

    function isShort(CommitType t) external pure returns (bool);

    // Pool balances and supplies
    struct BalancesAndSupplies {
        uint256 newShortBalance;
        uint256 newLongBalance;
        uint256 longMintPoolTokens;
        uint256 shortMintPoolTokens;
        uint256 longBurnInstantMintSettlement;
        uint256 shortBurnInstantMintSettlement;
        uint256 totalLongBurnPoolTokens;
        uint256 totalShortBurnPoolTokens;
    }

    // User aggregate balance
    struct Balance {
        uint256 longTokens;
        uint256 shortTokens;
        uint256 settlementTokens;
    }

    // Token Prices
    struct Prices {
        bytes16 longPrice;
        bytes16 shortPrice;
    }

    // Commit information
    struct Commit {
        uint256 amount;
        CommitType commitType;
        uint40 created;
        address owner;
    }

    // Commit information
    struct TotalCommitment {
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        uint256 longBurnShortMintPoolTokens;
    }

    // User updated aggregate balance
    struct BalanceUpdate {
        uint256 _updateIntervalId;
        uint256 _newLongTokensSum;
        uint256 _newShortTokensSum;
        uint256 _newSettlementTokensSum;
        uint256 _longSettlementFee;
        uint256 _shortSettlementFee;
        uint8 _maxIterations;
    }

    // Track the relevant data when executing a range of update interval's commitments (stack too deep)
    struct CommitmentExecutionTracking {
        uint256 longTotalSupply;
        uint256 shortTotalSupply;
        uint256 longTotalSupplyBefore;
        uint256 shortTotalSupplyBefore;
        uint256 _updateIntervalId;
    }

    /**
     * @notice Creates a notification when a commit is created
     * @param user The user making the commitment
     * @param amount Amount of the commit
     * @param commitType Type of the commit (Short v Long, Mint v Burn)
     * @param appropriateUpdateIntervalId Id of update interval where this commit can be executed as part of upkeep
     * @param fromAggregateBalance whether or not to commit from aggregate (unclaimed) balance
     * @param payForClaim whether or not to request this commit be claimed automatically
     * @param mintingFee Minting fee at time of commit creation
     */
    event CreateCommit(
        address indexed user,
        uint256 indexed amount,
        CommitType indexed commitType,
        uint256 appropriateUpdateIntervalId,
        bool fromAggregateBalance,
        bool payForClaim,
        bytes16 mintingFee
    );

    /**
     * @notice Creates a notification when a user's aggregate balance is updated
     */
    event AggregateBalanceUpdated(address indexed user);

    /**
     * @notice Creates a notification when the PoolCommitter's leveragedPool address has been updated.
     * @param newPool the address of the new leveraged pool
     */
    event PoolChanged(address indexed newPool);

    /**
     * @notice Creates a notification when commits for a given update interval are executed
     * @param updateIntervalId Unique identifier for the relevant update interval
     * @param burningFee Burning fee at the time of commit execution
     */
    event ExecutedCommitsForInterval(uint256 indexed updateIntervalId, bytes16 burningFee);

    /**
     * @notice Creates a notification when a claim is made, depositing pool tokens in user's wallet
     */
    event Claim(address indexed user);

    /*
     * @notice Creates a notification when the burningFee is updated
     */
    event BurningFeeSet(uint256 indexed _burningFee);

    /**
     * @notice Creates a notification when the mintingFee is updated
     */
    event MintingFeeSet(uint256 indexed _mintingFee);

    /**
     * @notice Creates a notification when the changeInterval is updated
     */
    event ChangeIntervalSet(uint256 indexed _changeInterval);

    /**
     * @notice Creates a notification when the feeController is updated
     */
    event FeeControllerSet(address indexed _feeController);

    // #### Functions

    function initialize(
        address _factory,
        address _autoClaim,
        address _factoryOwner,
        address _feeController,
        address _invariantCheck,
        uint256 mintingFee,
        uint256 burningFee,
        uint256 _changeInterval
    ) external;

    function unAggregatedCommitments(address,uint256) external view returns(uint256);

    function userCommitments(address,uint256) external view returns(UserCommitment memory);

    function commit(bytes32 args) external payable;

    function updateIntervalId() external view returns (uint128);

    function pendingMintSettlementAmount() external view returns (uint256);

    function pendingShortBurnPoolTokens() external view returns (uint256);

    function pendingLongBurnPoolTokens() external view returns (uint256);

    function claim(address user) external;

    function executeCommitments(
        uint256 lastPriceTimestamp,
        uint256 updateInterval,
        uint256 longBalance,
        uint256 shortBalance
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function updateAggregateBalance(address user) external;

    function getAggregateBalance(address user) external view returns (Balance memory _balance);

    function getAppropriateUpdateIntervalId() external view returns (uint128);

    function setPool(address _leveragedPool) external;

    function setBurningFee(uint256 _burningFee) external;

    function setMintingFee(uint256 _mintingFee) external;

    function setChangeInterval(uint256 _changeInterval) external;

    function setFeeController(address _feeController) external;
}

struct UserCommitment {
    uint256 longMintSettlement;
    uint256 longBurnPoolTokens;
    uint256 shortMintSettlement;
    uint256 shortBurnPoolTokens;
    uint256 shortBurnLongMintPoolTokens;
    uint256 longBurnShortMintPoolTokens;
    uint256 updateIntervalId;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

uint32 constant PERCENTAGE_DIVISOR = 1000;

struct TokenAllocation {
  uint256 percentage;
  address tokenAddress;
  uint256 leverage;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct GlpTokenAllocation {
  address tokenAddress;
  uint256 poolAmount;
  uint256 usdgAmount;
  uint256 weight;
  uint256 allocation;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {IPositionManager} from "src/IPositionManager.sol";
import {NetTokenExposure} from "src/TokenExposure.sol";
import {TokenAllocation} from "src/TokenAllocation.sol";
import {TokenExposure} from "src/TokenExposure.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IPriceUtils} from "src/IPriceUtils.sol";
import {RebalanceAction} from "src/RebalanceAction.sol";

uint256 constant FACTOR_ONE_MULTIPLIER = 1*10**6;
uint256 constant FACTOR_TWO_MULTIPLIER = 1*10**12;
uint256 constant FACTOR_THREE_MULTIPLIER = 1*10**18;

struct Trade {
  uint256 usdcAmount;
  IPositionManager positionManager; 
}

struct RebalanceData {
  TokenAllocation glpBtcAllocation;
  TokenAllocation glpEthAllocation;
  TokenAllocation btcPerpAllocation;
  TokenAllocation ethPerpAllocation;
  uint256 Pglp;
  uint256 Pbtcperp;
  uint256 Pethperp;
  uint256 totalLiquidity;
  uint256 glpMultiplier;
  uint256 btcPerpMultiplier;
}

struct RebalanceQueueData {
  IPositionManager positionManager;
  uint256 usdcAmountToHave;
}

struct RebalanceQueue {
  RebalanceQueueData[] rebalanceQueueData;
  uint256 buyIndex;
  uint256 sellIndex;
}

contract DeltaNeutralRebalancer is Test {
  IPositionManager private glpPositionManager;
  IPositionManager private btcPerpPoolPositionManager;
  IPositionManager private ethPerpPoolPositionManager;
  address private btcAddress;
  address private ethAddress;
  ERC20 private usdcToken;

  constructor(
    address _btcAddress,
    address _ethAddress,
    address _usdcAddress
  ) {
    btcAddress = _btcAddress;
    ethAddress = _ethAddress; 
    usdcToken = ERC20(_usdcAddress); 
  }

  function rebalance() external {
    (uint256 amountOfGlpToHave, uint256 amountOfPerpPoolBtcToHave, uint256 amountOfPerpPoolEthToHave) = this.getRebalancedAllocation();
    RebalanceQueue memory rebalanceQueue = this.getRebalanceQueue(amountOfGlpToHave, amountOfPerpPoolBtcToHave, amountOfPerpPoolEthToHave);
    for (uint8 i = 0; i < rebalanceQueue.rebalanceQueueData.length; i++) {
      if (!rebalanceQueue.rebalanceQueueData[i].positionManager.canRebalance()) {
        revert("Position manager cannot rebalance");
      }
      rebalanceQueue.rebalanceQueueData[i].positionManager.rebalance(rebalanceQueue.rebalanceQueueData[i].usdcAmountToHave);
    }
  }

  function getRebalanceQueue(uint256 amountOfGlpToHave, uint256 amountOfPerpPoolBtcToHave, uint256 amountOfPerpPoolEthToHave) external view returns (RebalanceQueue memory) {
    RebalanceQueue memory rebalanceQueue = RebalanceQueue({
      rebalanceQueueData: new RebalanceQueueData[](3),
      sellIndex: 0,
      buyIndex: 2
    });

    RebalanceQueue memory rebalanceQueue1 = this.addPositionManagerToRebalanceQueue(glpPositionManager, amountOfGlpToHave, rebalanceQueue);
    RebalanceQueue memory rebalanceQueue2 = this.addPositionManagerToRebalanceQueue(btcPerpPoolPositionManager, amountOfPerpPoolBtcToHave, rebalanceQueue1);
    RebalanceQueue memory rebalanceQueue3 = this.addPositionManagerToRebalanceQueue(ethPerpPoolPositionManager, amountOfPerpPoolEthToHave, rebalanceQueue2);
    return rebalanceQueue3;
  }

  function addPositionManagerToRebalanceQueue(IPositionManager positionManager, uint256 amountOfPositionToHave, RebalanceQueue memory rebalanceQueue) external view returns (RebalanceQueue memory) {
    uint256 usdcAmountToHave = amountOfPositionToHave * positionManager.price() / FACTOR_ONE_MULTIPLIER;
    RebalanceAction action = positionManager.getRebalanceAction(usdcAmountToHave);
    if (action == RebalanceAction.Buy) {
      rebalanceQueue.rebalanceQueueData[rebalanceQueue.buyIndex] = RebalanceQueueData({
        positionManager: positionManager,
        usdcAmountToHave: usdcAmountToHave 
      });
      if (rebalanceQueue.buyIndex > 0) {
        rebalanceQueue.buyIndex -= 1;
      }
    } else if (action == RebalanceAction.Sell) {
      rebalanceQueue.rebalanceQueueData[rebalanceQueue.sellIndex] = RebalanceQueueData({
        positionManager: positionManager,
        usdcAmountToHave: usdcAmountToHave  
      });
      rebalanceQueue.sellIndex += 1;
    } else {
      rebalanceQueue.rebalanceQueueData[rebalanceQueue.buyIndex] = RebalanceQueueData({
        positionManager: positionManager,
        usdcAmountToHave: usdcAmountToHave 
      });

      if (rebalanceQueue.buyIndex > 0) {
        rebalanceQueue.buyIndex -= 1;
      }
    }

    return rebalanceQueue;
  }

  function helloworld() external {
    TokenAllocation memory glpBtcAllocation = glpPositionManager.allocationByToken(btcAddress);
    TokenAllocation memory glpEthAllocation = glpPositionManager.allocationByToken(ethAddress);
    TokenAllocation memory btcPerpAllocation = btcPerpPoolPositionManager.allocationByToken(btcAddress);
    TokenAllocation memory ethPerpAllocation = ethPerpPoolPositionManager.allocationByToken(ethAddress);
  }
  function getRebalancedAllocation() external view returns (uint256, uint256, uint256) {
    uint256 totalLiquidity = this.getTotalLiquidity();
    // Get allocation information of assets inside positions
    TokenAllocation memory glpBtcAllocation = glpPositionManager.allocationByToken(btcAddress);
    TokenAllocation memory glpEthAllocation = glpPositionManager.allocationByToken(ethAddress);
    TokenAllocation memory btcPerpAllocation = btcPerpPoolPositionManager.allocationByToken(btcAddress);
    TokenAllocation memory ethPerpAllocation = ethPerpPoolPositionManager.allocationByToken(ethAddress);

    uint256 Pglp = glpPositionManager.price();
    uint256 Pbtcperp = btcPerpPoolPositionManager.price(); 
    uint256 Pethperp = ethPerpPoolPositionManager.price(); 

    RebalanceData memory rebalanceData = RebalanceData({
        glpBtcAllocation: glpBtcAllocation,
        glpEthAllocation: glpEthAllocation,
        btcPerpAllocation: btcPerpAllocation,
        ethPerpAllocation: ethPerpAllocation,
        Pglp: Pglp,
        Pbtcperp: Pbtcperp,
        Pethperp: Pethperp,
        totalLiquidity: totalLiquidity,
        glpMultiplier: 0,
        btcPerpMultiplier: 0
    });
    
    return this.calculateRebalancedPositions(rebalanceData);
  }

  function calculateRebalancedPositions(
    RebalanceData memory d
  )
  external view returns (uint256, uint256, uint256) {
    (uint256 glpMultiplier, uint256 btcPerpMultiplier) = this.calculateMultipliers(d);
    d.glpMultiplier = glpMultiplier;
    d.btcPerpMultiplier = btcPerpMultiplier;
    return this.calculatePositionsToHave(d);
  }

  function calculateMultipliers(RebalanceData memory d) external pure returns (uint256, uint256) {
    uint256 glpMultiplier = d.Pbtcperp*d.btcPerpAllocation.leverage*d.btcPerpAllocation.percentage*FACTOR_ONE_MULTIPLIER/(d.Pglp*d.glpBtcAllocation.leverage*d.glpBtcAllocation.percentage);
    uint256 btcPerpMultiplier = FACTOR_TWO_MULTIPLIER * d.Pethperp * d.ethPerpAllocation.leverage * d.ethPerpAllocation.percentage / (d.Pglp * glpMultiplier * d.glpEthAllocation.leverage * d.glpEthAllocation.percentage);
    
    return (glpMultiplier, btcPerpMultiplier);
  }

  function calculatePositionsToHave(RebalanceData memory d) external view returns (uint256, uint256, uint256) {
    uint256 amountOfPerpEthToHave = this.calculateAmountOfEthToHave(d);
    uint256 amountOfPerpBtcToHave = this.calculateAmountOfPerpBtcToHave(d, amountOfPerpEthToHave);
    uint256 amountOfGlpToHave = this.calculateAmountOfGlpToHave(d, amountOfPerpBtcToHave);

    return (amountOfGlpToHave, amountOfPerpBtcToHave, amountOfPerpEthToHave);
  }

  function calculateAmountOfEthToHave(RebalanceData memory d) external pure returns (uint256) {
    return d.totalLiquidity * FACTOR_THREE_MULTIPLIER / (d.Pglp*d.glpMultiplier*d.btcPerpMultiplier + d.Pbtcperp*d.btcPerpMultiplier*FACTOR_ONE_MULTIPLIER + (d.Pethperp*FACTOR_TWO_MULTIPLIER));
  }

  function calculateAmountOfPerpBtcToHave(RebalanceData memory d, uint256 amountOfPerpEthToHave) external pure returns (uint256) {
    return FACTOR_ONE_MULTIPLIER * d.Pethperp * amountOfPerpEthToHave * d.ethPerpAllocation.leverage * d.ethPerpAllocation.percentage / (d.Pglp * d.glpMultiplier * d.glpEthAllocation.leverage * d.glpEthAllocation.percentage);
  }

  function calculateAmountOfGlpToHave(RebalanceData memory d, uint256 amountOfPerpBtcToHave) external pure returns (uint256) {
    return d.Pbtcperp*amountOfPerpBtcToHave*d.btcPerpAllocation.leverage*d.btcPerpAllocation.percentage/(d.Pglp*d.glpBtcAllocation.leverage*d.glpBtcAllocation.percentage);
  }

  function setGlpPositionManager(address glpPositionManagerAddress) external {
    glpPositionManager = IPositionManager(glpPositionManagerAddress);
    usdcToken.approve(address(glpPositionManager), 2**256 - 1);
  }

  function setBtcPerpPoolManager(address btcPerpPoolPositionManagerAddress) external {
    btcPerpPoolPositionManager = IPositionManager(btcPerpPoolPositionManagerAddress);
    usdcToken.approve(address(btcPerpPoolPositionManager), 2**256 - 1);
  }

  function setEthPerpPoolManager(address ethPerpPoolPositionManagerAddress) external {
    ethPerpPoolPositionManager = IPositionManager(ethPerpPoolPositionManagerAddress);
    usdcToken.approve(address(ethPerpPoolPositionManager), 2**256 - 1);
  }

  function getTotalLiquidity() external view returns (uint256) {
    uint256 availableLiquidity = 0;
    availableLiquidity += usdcToken.balanceOf(address(this));
    availableLiquidity += glpPositionManager.positionWorth();
    availableLiquidity += btcPerpPoolPositionManager.positionWorth();
    availableLiquidity += ethPerpPoolPositionManager.positionWorth();
    
    return availableLiquidity;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRewardRouter {
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Vm.sol";
import "./console.sol";
import "./console2.sol";

abstract contract Script {
    bool public IS_SCRIPT = true;
    address constant private VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    Vm public constant vm = Vm(VM_ADDRESS);

    /// @dev Compute the address a contract will be deployed at for a given deployer address and nonce
    /// @notice adapated from Solmate implementation (https://github.com/transmissions11/solmate/blob/main/src/utils/LibRLP.sol)
    function computeCreateAddress(address deployer, uint256 nonce) internal pure returns (address) {
        // The integer zero is treated as an empty byte string, and as a result it only has a length prefix, 0x80, computed via 0x80 + 0.
        // A one byte integer uses its own value as its length prefix, there is no additional "0x80 + length" prefix that comes before it.
        if (nonce == 0x00)             return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))));
        if (nonce <= 0x7f)             return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))));

        // Nonces greater than 1 byte all follow a consistent encoding scheme, where each value is preceded by a prefix of 0x80 + length.
        if (nonce <= 2**8 - 1)  return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), uint8(nonce))));
        if (nonce <= 2**16 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployer, bytes1(0x82), uint16(nonce))));
        if (nonce <= 2**24 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployer, bytes1(0x83), uint24(nonce))));

        // More details about RLP encoding can be found here: https://eth.wiki/fundamentals/rlp
        // 0xda = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x84 ++ nonce)
        // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
        // 0x84 = 0x80 + 0x04 (0x04 = the bytes length of the nonce, 4 bytes, in hex)
        // We assume nobody can have a nonce large enough to require more than 32 bytes.
        return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), deployer, bytes1(0x84), uint32(nonce))));
    }

    function addressFromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.5.0;

contract DSTest {
    event log                    (string);
    event logs                   (bytes);

    event log_address            (address);
    event log_bytes32            (bytes32);
    event log_int                (int);
    event log_uint               (uint);
    event log_bytes              (bytes);
    event log_string             (string);

    event log_named_address      (string key, address val);
    event log_named_bytes32      (string key, bytes32 val);
    event log_named_decimal_int  (string key, int val, uint decimals);
    event log_named_decimal_uint (string key, uint val, uint decimals);
    event log_named_int          (string key, int val);
    event log_named_uint         (string key, uint val);
    event log_named_bytes        (string key, bytes val);
    event log_named_string       (string key, string val);

    bool public IS_TEST = true;
    bool private _failed;

    address constant HEVM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    modifier mayRevert() { _; }
    modifier testopts(string memory) { _; }

    function failed() public returns (bool) {
        if (_failed) {
            return _failed;
        } else {
            bool globalFailed = false;
            if (hasHEVMContext()) {
                (, bytes memory retdata) = HEVM_ADDRESS.call(
                    abi.encodePacked(
                        bytes4(keccak256("load(address,bytes32)")),
                        abi.encode(HEVM_ADDRESS, bytes32("failed"))
                    )
                );
                globalFailed = abi.decode(retdata, (bool));
            }
            return globalFailed;
        }
    } 

    function fail() internal {
        if (hasHEVMContext()) {
            (bool status, ) = HEVM_ADDRESS.call(
                abi.encodePacked(
                    bytes4(keccak256("store(address,bytes32,bytes32)")),
                    abi.encode(HEVM_ADDRESS, bytes32("failed"), bytes32(uint256(0x01)))
                )
            );
            status; // Silence compiler warnings
        }
        _failed = true;
    }

    function hasHEVMContext() internal view returns (bool) {
        uint256 hevmCodeSize = 0;
        assembly {
            hevmCodeSize := extcodesize(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D)
        }
        return hevmCodeSize > 0;
    }

    modifier logs_gas() {
        uint startGas = gasleft();
        _;
        uint endGas = gasleft();
        emit log_named_uint("gas", startGas - endGas);
    }

    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
    }

    function assertTrue(bool condition, string memory err) internal {
        if (!condition) {
            emit log_named_string("Error", err);
            assertTrue(condition);
        }
    }

    function assertEq(address a, address b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [address]");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }
    function assertEq(address a, address b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes32 a, bytes32 b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [bytes32]");
            emit log_named_bytes32("  Expected", b);
            emit log_named_bytes32("    Actual", a);
            fail();
        }
    }
    function assertEq(bytes32 a, bytes32 b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq32(bytes32 a, bytes32 b) internal {
        assertEq(a, b);
    }
    function assertEq32(bytes32 a, bytes32 b, string memory err) internal {
        assertEq(a, b, err);
    }

    function assertEq(int a, int b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [int]");
            emit log_named_int("  Expected", b);
            emit log_named_int("    Actual", a);
            fail();
        }
    }
    function assertEq(int a, int b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq(uint a, uint b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [uint]");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            fail();
        }
    }
    function assertEq(uint a, uint b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEqDecimal(int a, int b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal int]");
            emit log_named_decimal_int("  Expected", b, decimals);
            emit log_named_decimal_int("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Expected", b, decimals);
            emit log_named_decimal_uint("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }

    function assertGt(uint a, uint b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGt(uint a, uint b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGt(int a, int b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGt(int a, int b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGtDecimal(int a, int b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }

    function assertGe(uint a, uint b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGe(uint a, uint b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGe(int a, int b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGe(int a, int b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGeDecimal(int a, int b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertLt(uint a, uint b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLt(uint a, uint b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLt(int a, int b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLt(int a, int b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLtDecimal(int a, int b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }

    function assertLe(uint a, uint b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLe(uint a, uint b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLe(int a, int b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLe(int a, int b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLeDecimal(int a, int b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLeDecimal(a, b, decimals);
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertEq(string memory a, string memory b) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log("Error: a == b not satisfied [string]");
            emit log_named_string("  Expected", b);
            emit log_named_string("    Actual", a);
            fail();
        }
    }
    function assertEq(string memory a, string memory b, string memory err) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function checkEq0(bytes memory a, bytes memory b) internal pure returns (bool ok) {
        ok = true;
        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    ok = false;
                }
            }
        } else {
            ok = false;
        }
    }
    function assertEq0(bytes memory a, bytes memory b) internal {
        if (!checkEq0(a, b)) {
            emit log("Error: a == b not satisfied [bytes]");
            emit log_named_bytes("  Expected", b);
            emit log_named_bytes("    Actual", a);
            fail();
        }
    }
    function assertEq0(bytes memory a, bytes memory b, string memory err) internal {
        if (!checkEq0(a, b)) {
            emit log_named_string("Error", err);
            assertEq0(a, b);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

enum RebalanceAction {
  Nothing,
  Buy,
  Sell
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

enum PositionType {
  Long,
  Short
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
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface Vm {
    struct Log {
        bytes32[] topics;
        bytes data;
    }

    // Sets block.timestamp (newTimestamp)
    function warp(uint256) external;
    // Sets block.height (newHeight)
    function roll(uint256) external;
    // Sets block.basefee (newBasefee)
    function fee(uint256) external;
    // Sets block.difficulty (newDifficulty)
    function difficulty(uint256) external;
    // Sets block.chainid
    function chainId(uint256) external;
    // Loads a storage slot from an address (who, slot)
    function load(address,bytes32) external returns (bytes32);
    // Stores a value to an address' storage slot, (who, slot, value)
    function store(address,bytes32,bytes32) external;
    // Signs data, (privateKey, digest) => (v, r, s)
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    // Gets the address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
    // Gets the nonce of an account
    function getNonce(address) external returns (uint64);
    // Sets the nonce of an account; must be higher than the current nonce of the account
    function setNonce(address, uint64) external;
    // Performs a foreign function call via the terminal, (stringInputs) => (result)
    function ffi(string[] calldata) external returns (bytes memory);
    // Sets environment variables, (name, value)
    function setEnv(string calldata, string calldata) external;
    // Reads environment variables, (name) => (value)
    function envBool(string calldata) external returns (bool);
    function envUint(string calldata) external returns (uint256);
    function envInt(string calldata) external returns (int256);
    function envAddress(string calldata) external returns (address);
    function envBytes32(string calldata) external returns (bytes32);
    function envString(string calldata) external returns (string memory);
    function envBytes(string calldata) external returns (bytes memory);
    // Reads environment variables as arrays, (name, delim) => (value[])
    function envBool(string calldata, string calldata) external returns (bool[] memory);
    function envUint(string calldata, string calldata) external returns (uint256[] memory);
    function envInt(string calldata, string calldata) external returns (int256[] memory);
    function envAddress(string calldata, string calldata) external returns (address[] memory);
    function envBytes32(string calldata, string calldata) external returns (bytes32[] memory);
    function envString(string calldata, string calldata) external returns (string[] memory);
    function envBytes(string calldata, string calldata) external returns (bytes[] memory);
    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address,address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address,address) external;
    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
    // Sets an address' balance, (who, newBalance)
    function deal(address, uint256) external;
    // Sets an address' code, (who, newCode)
    function etch(address, bytes calldata) external;
    // Expects an error on next call
    function expectRevert(bytes calldata) external;
    function expectRevert(bytes4) external;
    function expectRevert() external;
    // Records all storage reads and writes
    function record() external;
    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address) external returns (bytes32[] memory reads, bytes32[] memory writes);
    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(bool,bool,bool,bool) external;
    function expectEmit(bool,bool,bool,bool,address) external;
    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address,bytes calldata,bytes calldata) external;
    // Mocks a call to an address with a specific msg.value, returning specified data.
    // Calldata match takes precedence over msg.value in case of ambiguity.
    function mockCall(address,uint256,bytes calldata,bytes calldata) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expects a call to an address with the specified calldata.
    // Calldata can either be a strict or a partial match
    function expectCall(address,bytes calldata) external;
    // Expects a call to an address with the specified msg.value and calldata
    function expectCall(address,uint256,bytes calldata) external;
    // Gets the code from an artifact file. Takes in the relative path to the json file
    function getCode(string calldata) external returns (bytes memory);
    // Labels an address in call traces
    function label(address, string calldata) external;
    // If the condition is false, discard this run's fuzz inputs and generate new ones
    function assume(bool) external;
    // Sets block.coinbase (who)
    function coinbase(address) external;
    // Using the address that calls the test contract, has the next call (at this call depth only) create a transaction that can later be signed and sent onchain
    function broadcast() external;
    // Has the next call (at this call depth only) create a transaction with the address provided as the sender that can later be signed and sent onchain
    function broadcast(address) external;
    // Using the address that calls the test contract, has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast() external;
    // Has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast(address) external;
    // Stops collecting onchain transactions
    function stopBroadcast() external;
    // Reads the entire content of file to string, (path) => (data)
    function readFile(string calldata) external returns (string memory);
    // Reads next line of file to string, (path) => (line)
    function readLine(string calldata) external returns (string memory);
    // Writes data to file, creating a file if it does not exist, and entirely replacing its contents if it does.
    // (path, data) => ()
    function writeFile(string calldata, string calldata) external;
    // Writes line to file, creating a file if it does not exist.
    // (path, data) => ()
    function writeLine(string calldata, string calldata) external;
    // Closes file for reading, resetting the offset and allowing to read it from beginning with readLine.
    // (path) => ()
    function closeFile(string calldata) external;
    // Removes file. This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - Path points to a directory.
    // - The file doesn't exist.
    // - The user lacks permissions to remove the file.
    // (path) => ()
    function removeFile(string calldata) external;
    // Convert values to a string, (value) => (stringified value)
    function toString(address) external returns(string memory);
    function toString(bytes calldata) external returns(string memory);
    function toString(bytes32) external returns(string memory);
    function toString(bool) external returns(string memory);
    function toString(uint256) external returns(string memory);
    function toString(int256) external returns(string memory);
    // Record all the transaction logs
    function recordLogs() external;
    // Gets all the recorded logs, () => (logs)
    function getRecordedLogs() external returns (Log[] memory);
    // Snapshot the current state of the evm.
    // Returns the id of the snapshot that was created.
    // To revert a snapshot use `revertTo`
    function snapshot() external returns(uint256);
    // Revert the state of the evm to a previous snapshot
    // Takes the snapshot id to revert to.
    // This deletes the snapshot and all snapshots taken after the given snapshot id.
    function revertTo(uint256) external returns(bool);
    // Creates a new fork with the given endpoint and block and returns the identifier of the fork
    function createFork(string calldata,uint256) external returns(uint256);
    // Creates a new fork with the given endpoint and the _latest_ block and returns the identifier of the fork
    function createFork(string calldata) external returns(uint256);
    // Creates _and_ also selects a new fork with the given endpoint and block and returns the identifier of the fork
    function createSelectFork(string calldata,uint256) external returns(uint256);
    // Creates _and_ also selects a new fork with the given endpoint and the latest block and returns the identifier of the fork
    function createSelectFork(string calldata) external returns(uint256);
    // Takes a fork identifier created by `createFork` and sets the corresponding forked state as active.
    function selectFork(uint256) external;
    /// Returns the currently active fork
    /// Reverts if no fork is currently active
    function activeFork() external returns(uint256);
    // Updates the currently active fork to given block number
    // This is similar to `roll` but for the currently active fork
    function rollFork(uint256) external;
    // Updates the given fork to given block number
    function rollFork(uint256 forkId, uint256 blockNumber) external;
    /// Returns the RPC url for the given alias

    // Marks that the account(s) should use persistent storage across fork swaps in a multifork setup
    // Meaning, changes made to the state of this account will be kept when switching forks
    function makePersistent(address) external;
    function makePersistent(address, address) external;
    function makePersistent(address, address, address) external;
    function makePersistent(address[] calldata) external;
    // Revokes persistent status from the address, previously added via `makePersistent`
    function revokePersistent(address) external;
    function revokePersistent(address[] calldata) external;
    // Returns true if the account is marked as persistent
    function isPersistent(address) external returns (bool);

    function rpcUrl(string calldata) external returns(string memory);
    /// Returns all rpc urls and their aliases `[alias, url][]`
    function rpcUrls() external returns(string[2][] memory);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path m/44'/60'/0'/0/{index}
    function deriveKey(string calldata, uint32) external returns (uint256);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path {path}{index}
    function deriveKey(string calldata, string calldata, uint32) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// The orignal console.sol uses `int` and `uint` for computing function selectors, but it should
// use `int256` and `uint256`. This modified version fixes that. This version is recommended
// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
// Reference: https://github.com/NomicFoundation/hardhat/issues/2178

library console2 {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}