// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IPepePool } from "./interfaces/IPepePool.sol";

/**
 * @title PepePool - $PEPE version
 */

contract PepePool is Ownable, IPepePool {
    IERC20 public immutable IPEPE;

    address public pepeBetAddress;
    address public serviceWallet;

    event UpdatedPepeBetAddress(address indexed oldAddress, address indexed newAddress);
    event Payout(address indexed user, uint256 indexed betId, uint256 amount);
    event FundedServiceWallet(address indexed serviceWallet, uint256 amount);
    event UpdatedServiceWallet(address indexed oldAddress, address indexed newAddress);
    event AdminWithdrawal(address indexed admin, uint256 amount);

    error NotPepeBet();
    error NotServiceWallet();
    error InvalidAddress();
    error WithdrawalFailed();
    error FundingServiceWalletFailed();
    error InsufficientFunds(uint256 requested, uint256 available);

    constructor(address _pepeAddress) {
        IPEPE = IERC20(_pepeAddress);
    }

    modifier onlyPepeBet() {
        if (msg.sender != pepeBetAddress) revert NotPepeBet();
        _;
    }

    modifier onlyServiceWallet() {
        if (msg.sender != serviceWallet) revert NotServiceWallet();
        _;
    }

    function payout(address user, uint256 amount, uint256 betId) external override onlyPepeBet {
        uint256 contractBalance = IPEPE.balanceOf(address(this));
        require(amount <= contractBalance, "PepePool: InsufficientFunds");
        bool success = IPEPE.transfer(pepeBetAddress, amount);
        require(success, "PepePool: PayoutFailed");
        emit Payout(user, betId, amount);
    }

    function setNewPepeBetAddress(address newPepeBet) external override onlyOwner {
        if (newPepeBet == address(0)) revert InvalidAddress();
        address oldPepeBet = pepeBetAddress;
        pepeBetAddress = newPepeBet;
        emit UpdatedPepeBetAddress(oldPepeBet, newPepeBet);
    }

    function setNewServiceWallet(address newServiceWallet) external override onlyOwner {
        if (newServiceWallet == address(0)) revert InvalidAddress();
        address oldServiceWallet = serviceWallet;
        serviceWallet = newServiceWallet;
        emit UpdatedServiceWallet(oldServiceWallet, newServiceWallet);
    }

    function fundServiceWallet(uint256 amount) external override onlyServiceWallet {
        uint256 contractBalance = IPEPE.balanceOf(address(this));
        if (amount > contractBalance) revert InsufficientFunds(amount, contractBalance);
        bool success = IPEPE.transfer(serviceWallet, amount);
        if (!success) revert FundingServiceWalletFailed();
        emit FundedServiceWallet(serviceWallet, amount);
    }

    function withdraw(uint256 amount) external override onlyOwner {
        uint256 contractBalance = IPEPE.balanceOf(address(this));

        if (amount > contractBalance) revert InsufficientFunds(amount, contractBalance);
        bool success = IPEPE.transfer(owner(), amount);
        if (!success) revert WithdrawalFailed();
        emit AdminWithdrawal(owner(), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPepePool {
    function payout(address user, uint256 amount, uint256 betId) external;

    function setNewPepeBetAddress(address newPepeBet) external;

    function setNewServiceWallet(address newServiceWallet) external;

    function fundServiceWallet(uint256 amount) external;

    function withdraw(uint256 amount) external;
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