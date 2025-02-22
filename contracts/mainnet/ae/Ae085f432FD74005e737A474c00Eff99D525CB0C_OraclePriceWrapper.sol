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

pragma solidity ^0.8.0;

interface ISnapshottable {
    function snapshot() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISnapshottable } from './ISnapshottable.sol';

interface ITimeWeightedAveragePricer is ISnapshottable {
    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);

    /**
     * @dev Calculates the current price based on the stored samples.
     * @return The current price as a uint256.
     */
    function calculateToken0Price() external view returns (uint256);

    /**
     * @dev Returns the current price of token0, denominated in token1.
     * @return The current price as a uint256.
     */
    function getToken0Price() external view returns (uint256);

    /**
     * @dev Returns the current price of token1, denominated in token0.
     * @return The current price as a uint256.
     */
    function getToken1Price() external view returns (uint256);

    function getToken0Value(uint256 amount) external view returns (uint256);
    function getToken0ValueAtSnapshot(uint256 _blockNumber, uint256 amount) external view returns (uint256);

    function getToken1Value(uint256 amount) external view returns (uint256);

    /**
     * @dev Returns the block number of the oldest sample.
     * @return The block number of the oldest sample as a uint256.
     */
    function getOldestSampleBlock() external view returns (uint256);

    /**
     * @dev Returns the current price if the oldest sample is still considered fresh.
     * @return The current price as a uint256.
     */
    function getToken0FreshPrice() external view returns (uint256);

    /**
     * @dev Returns the current price if the oldest sample is still considered fresh.
     * @return The current price as a uint256.
     */
    function getToken1FreshPrice() external view returns (uint256);

    /**
     * @dev Returns the next sample index given the current index and sample count.
     * @param i The current sample index.
     * @param max The maximum number of samples.
     * @return The next sample index as a uint64.
     */
    function calculateNext(uint64 i, uint64 max) external pure returns (uint64);

    /**
     * @dev Returns the previous sample index given the current index and sample count.
     * @param i The current sample index.
     * @param max The maximum number of samples.
     * @return The previous sample index as a uint64.
     */
    function calculatePrev(uint64 i, uint64 max) external pure returns (uint64);

    /**
     * @dev Samples the current spot price of the token pair from all pools.
     * @return A boolean indicating whether the price was sampled or not.
     */
    function samplePrice() external returns (bool);

    /**
     * @dev Samples the current spot price of the token pair from all pools, throwing if the previous sample was too recent.
     */
    function enforcedSamplePrice() external;

    /**
     * @dev Calculates the spot price of the token pair from all pools.
     * @return The spot price as a uint256.
     */
    function calculateToken0SpotPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISnapshottable } from '../../legacy/staking/ISnapshottable.sol';

pragma solidity ^0.8.0;


interface IOracle {
    // returns (price, lastUpdated)
    function getPrice(IERC20 token) external view returns (uint256, uint256);
}


struct PriceOracle {
    // snapshots need to know if this datum exists or is a default
    bool exists;
    bool isOracle;
    // if not isOracle, this can be cast to a uint160 to get the price
    IOracle oracle;
}


interface IStakeValuator is ISnapshottable {
    function token() external view returns (IERC20);
    function stakeFor(address _account, uint256 _amount) external;
    function getStakers(uint256 idx) external view returns (address);
    function getStakersCount() external view returns (uint256);
    function getVestedTokens(address user) external view returns (uint256);
    function getVestedTokensAtSnapshot(address user, uint256 blockNumber) external view returns (uint256);

    function getValueAtSnapshot(IERC20 _token, uint256 _blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ITimeWeightedAveragePricer } from '../legacy/staking/ITimeWeightedAveragePricer.sol';
import { IOracle } from './interfaces/IStakeValuator.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

contract OraclePriceWrapper is IOracle, Ownable {
    ITimeWeightedAveragePricer public oracle;

    event OracleSet(ITimeWeightedAveragePricer indexed oldOracle, ITimeWeightedAveragePricer indexed newOracle);

    constructor(ITimeWeightedAveragePricer _oracle) {
        setOracle(_oracle);
    }

    function setOracle(ITimeWeightedAveragePricer _oracle) public onlyOwner {
        emit OracleSet(oracle, _oracle);
        oracle = _oracle;
    }

    function getPrice(IERC20 token) external view override returns (uint256, uint256) {
        if (address(token) == address(oracle.token0())) {
            return (oracle.getToken0Price(), oracle.getOldestSampleBlock());
        } else if (address(token) == address(oracle.token1())) {
            return (oracle.getToken0Price(), oracle.getOldestSampleBlock());
        } else {
            require(false, 'OraclePriceWrapper: invalid token');
        }
    }
}