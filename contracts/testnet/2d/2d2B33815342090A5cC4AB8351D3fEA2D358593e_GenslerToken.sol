// SPDX-License-Identifier: MIT
// Based on Uniswap V2 @ https://github.com/Uniswap/v2-core/releases/tag/v1.0.1

pragma solidity =0.5.16;

import "uniswap-v2-core/contracts/UniswapV2ERC20.sol";

/**
 * @title Sec-urity Gensler Meme Coin
 * @author The Security Team
 * @notice the goal of this coin is to satirize institutions in their futile war against the crypto space
 * @notice We are the army!
 * @notice We are the crypto army!!
 * @notice We are the meme crypto army!!!
 * 
 * Supply Allocation
 * - 20% team supply divided into 3 years on a weekly basis
 * - 10% marketing
 * - 10% fondo DAO
 * - 10% liquidità
 * - 50% LP farm community
 * 
 * Launchpad: meme-factory (https://github.com/meme-factory)
 * Project: https://github.com/meme-factory/Sec-urity-Gensler
 * White Paper: https://github.com/meme-factory/Sec-urity-Gensler/blob/v1.0.0/white-paper.md
 * 
 * Don't Trust, Verify.
 */
contract GenslerToken is UniswapV2ERC20 {
    string public constant name = 'Sec-urity Gensler';
    string public constant symbol = 'GENSLER';

    address public constant TEAM_SUPPLY_VAULT = 0x31a244fA299aEcca49906592C5507711e97F54f8;
    address public constant MARKETING_VAULT = 0x11D9cc102D239bBC8da8B2538A76DfE3a5352b86;
    address public constant DAO_FUND_VAULT = 0xAA2dAC35ab325CBd58b290A440685F72D677661f;
    address public constant LIQUIDITY_VAULT = 0xCe933adDc23E2502F55220de5D87f891581FE5c0;
    address public constant LP_FARM_COMMUNITY_VAULT = 0x3635D03636AA8F2eE10a9594faB47C05A87C03e2;
    
    uint256 public constant TEAM_SUPPLY_ALLOCATION = 84_000_000_000 ether;
    uint256 public constant MARKETING_ALLOCATION = 42_000_000_000 ether;
    uint256 public constant DAO_FUND_ALLOCATION = 42_000_000_000 ether;
    uint256 public constant LIQUIDITY_ALLOCATION = 42_000_000_000 ether;
    uint256 public constant LP_FARM_COMMUNITY_ALLOCATION = 210_000_000_000 ether;
    uint256 public constant GENSLER_TOTAL_SUPPLY_ALLOCATION = 420_000_000_000 ether;

    constructor() public {
        require(
            TEAM_SUPPLY_ALLOCATION +
            MARKETING_ALLOCATION +
            DAO_FUND_ALLOCATION +
            LIQUIDITY_ALLOCATION +
            LP_FARM_COMMUNITY_ALLOCATION ==
            GENSLER_TOTAL_SUPPLY_ALLOCATION
        );

        _mint(TEAM_SUPPLY_VAULT, TEAM_SUPPLY_ALLOCATION);
        _mint(MARKETING_VAULT, MARKETING_ALLOCATION);
        _mint(DAO_FUND_VAULT, DAO_FUND_ALLOCATION);
        _mint(LIQUIDITY_VAULT, LIQUIDITY_ALLOCATION);
        _mint(LP_FARM_COMMUNITY_VAULT, LP_FARM_COMMUNITY_ALLOCATION);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
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
}

pragma solidity =0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

pragma solidity =0.5.16;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/SafeMath.sol';

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant name = 'Uniswap V2';
    string public constant symbol = 'UNI-V2';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}