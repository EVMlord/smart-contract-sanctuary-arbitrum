// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IStrategyVault} from "./interfaces/IStrategyVault.sol";
import {IEarthquakeV2} from "./interfaces/IEarthquakeV2.sol";
import {IHook} from "../src/interfaces/IHook.sol";

contract VaultData is Ownable {
    struct VaultInfo {
        string name;
        string symbol;
        address vaultAddress;
        address depositAsset;
        uint256 deploymentId;
        uint256 maxQueueSize;
        uint256 minDeposit;
        address owner;
        bool fundsDeployed;
        uint8 weightId;
        uint256 weightProportion;
        uint256[] weights;
        address[] marketAddresses;
        uint256[] marketIds;
        uint256 underlyingBalance;
        uint256 emissionBalance;
        uint256 totalSharesIssued;
        address hook;
        uint16 hookCommand;
    }

    event NewVaultInfo(VaultInfo vault);
    event NewVaultInfoBulk(VaultInfo[] vaults);
    event UpdateMarkets(
        address[] markets,
        uint256[] marketIds,
        string[] marketName,
        bool[] isWeth,
        uint256[] strike,
        string[] symbol,
        address[] token,
        address[] depositAsset
    );
    event RemoveVaults(address[] strategyVaults);

    constructor() {}

    //////////////////////////////////////////////
    //                 PUBLIC - ADMIN          //
    //////////////////////////////////////////////
    function updateMarkets(address[] calldata markets) external onlyOwner {
        (
            string[] memory marketName,
            bool[] memory isWeth,
            uint256[] memory strike,
            string[] memory symbol,
            address[] memory token,
            address[] memory depositAsset,
            uint256[] memory marketId
        ) = _fetchMarketInfo(markets);
        emit UpdateMarkets(
            markets,
            marketId,
            marketName,
            isWeth,
            strike,
            symbol,
            token,
            depositAsset
        );
    }

    function _fetchMarketInfo(
        address[] calldata markets
    )
        internal
        view
        returns (
            string[] memory marketName,
            bool[] memory isWeth,
            uint256[] memory strike,
            string[] memory symbol,
            address[] memory token,
            address[] memory depositAsset,
            uint256[] memory marketId
        )
    {
        marketName = new string[](markets.length);
        isWeth = new bool[](markets.length);
        strike = new uint256[](markets.length);
        symbol = new string[](markets.length);
        token = new address[](markets.length);
        depositAsset = new address[](markets.length);
        marketId = new uint256[](markets.length);

        for (uint256 i; i < markets.length; ) {
            marketName[i] = IEarthquakeV2(markets[i]).name();
            isWeth[i] = IEarthquakeV2(markets[i]).isWETH();
            strike[i] = IEarthquakeV2(markets[i]).strike();
            symbol[i] = IEarthquakeV2(markets[i]).symbol();
            token[i] = IEarthquakeV2(markets[i]).token();
            depositAsset[i] = IEarthquakeV2(markets[i]).asset();
            marketId[i] = uint256(
                keccak256(
                    abi.encodePacked(token[i], strike[i], depositAsset[i])
                )
            );
            unchecked {
                i++;
            }
        }
    }

    /**
        @notice Emits an event for list of vaults
        @dev Subgraph recognising 1 as blacklist and 2 for un-blacklist
     */
    function removeVaults(
        address[] calldata strategyVaults
    ) external onlyOwner {
        emit RemoveVaults(strategyVaults);
    }

    //////////////////////////////////////////////
    //                 PUBLIC - CONFIG          //
    //////////////////////////////////////////////
    function addNewVault(address _strategyVault) external {
        VaultInfo memory vaultInfo = _addNewVault(_strategyVault);
        emit NewVaultInfo(vaultInfo);
    }

    /**
        @notice Loops through an array of new strategy vaults and emits events for each
     */
    function addNewVaults(address[] memory _strategyVaults) external {
        VaultInfo[] memory vaultInfos = new VaultInfo[](_strategyVaults.length);

        for (uint256 i; i < _strategyVaults.length; ) {
            vaultInfos[i] = _addNewVault(_strategyVaults[i]);
            unchecked {
                i++;
            }
        }

        emit NewVaultInfoBulk(vaultInfos);
    }

    //////////////////////////////////////////////
    //                 INTERNAL - CONFIG        //
    //////////////////////////////////////////////
    function _addNewVault(
        address _vault
    ) internal view returns (VaultInfo memory info) {
        IStrategyVault iVault = IStrategyVault(_vault);

        // Querying Strategy Vault for basic info
        info = _fetchBasicInfo(info, iVault);

        // Querying Markets for market info
        address[] memory vaultList = iVault.fetchVaultList();
        info.marketAddresses = vaultList;
        info.marketIds = _fetchMarketIds(vaultList);
    }

    function _fetchBasicInfo(
        VaultInfo memory info,
        IStrategyVault vault
    ) internal view returns (VaultInfo memory) {
        // Basic Info
        info.name = vault.name();
        info.symbol = vault.symbol();
        info.vaultAddress = address(vault);
        info.depositAsset = vault.asset();
        info.deploymentId = vault.deploymentId();
        info.owner = vault.owner();
        info.maxQueueSize = vault.maxQueuePull();
        info.minDeposit = vault.minDeposit();
        info.fundsDeployed = vault.fundsDeployed();
        info.underlyingBalance = vault.totalAssets();
        info.emissionBalance = IERC20(vault.emissionToken()).balanceOf(
            address(vault)
        );
        info.totalSharesIssued = vault.totalSupply();

        // Weight Info
        info.weightId = vault.weightStrategy();
        info.weightProportion = vault.weightProportion();
        info.weights = vault.fetchVaultWeights();

        // Hook info
        (info.hook, info.hookCommand) = vault.hook();
        return info;
    }

    function _fetchMarketIds(
        address[] memory vaultList
    ) internal view returns (uint256[] memory marketIds) {
        marketIds = new uint256[](vaultList.length);

        for (uint256 i; i < vaultList.length; ) {
            marketIds[i] = (_fetchMarketId(vaultList[i]));
            unchecked {
                i++;
            }
        }
    }

    function _fetchMarketId(
        address _strategyVault
    ) internal view returns (uint256) {
        IEarthquakeV2 earthquakeVault = IEarthquakeV2(_strategyVault);
        // We know this is a V2 market
        address _token = earthquakeVault.token();
        uint256 _strikePrice = earthquakeVault.strike();
        address _underlying = earthquakeVault.asset();
        return
            uint256(
                keccak256(abi.encodePacked(_token, _strikePrice, _underlying))
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IStrategyVault {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function asset() external view returns (address);

    function emissionToken() external view returns (address);

    function owner() external view returns (address);

    function maxQueuePull() external view returns (uint256);

    function minDeposit() external view returns (uint256);

    function fundsDeployed() external view returns (bool);

    function deploymentId() external view returns (uint256);

    function weightStrategy() external view returns (uint8);

    function weightId() external view returns (uint256);

    function weightProportion() external view returns (uint256);

    function fetchVaultWeights() external view returns (uint256[] memory);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function hook() external view returns (address addr, uint16 command);

    function fetchVaultList()
        external
        view
        returns (address[] memory vaultList);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IEarthquakeV2 {
    function asset() external view returns (address asset);

    function token() external view returns (address token);

    function strike() external view returns (uint256 strike);

    function name() external view returns (string memory name);

    function symbol() external view returns (string memory symbol);

    function isWETH() external view returns (bool isWeth);
}

pragma solidity 0.8.18;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

interface IHook {
    function beforeDeposit() external;

    function afterDeposit(uint256 amount) external;

    function beforeWithdraw(uint256 amount) external;

    function beforeDeploy() external;

    function afterDeploy() external;

    function beforeClose() external;

    function afterClose() external;

    function afterCloseTransferAssets() external view returns (ERC20[] memory);

    function totalAssets() external view returns (uint256);

    function availableAmounts(
        address[] memory vaults,
        uint256[] memory epochIds,
        uint256 weightStrategy
    ) external view returns (uint256[] memory);
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