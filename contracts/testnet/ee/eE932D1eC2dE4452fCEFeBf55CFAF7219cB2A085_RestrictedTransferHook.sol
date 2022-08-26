// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import "./interfaces/IRestrictedTransferHook.sol";
import "./interfaces/IAccountList.sol";
import "./BlocklistTransferHook.sol";

contract RestrictedTransferHook is
  IRestrictedTransferHook,
  BlocklistTransferHook
{
  IAccountList private _sourceAllowlist;
  IAccountList private _destinationAllowlist;

  constructor() {}

  function hook(
    address _from,
    address _to,
    uint256 _amount
  ) public virtual override(BlocklistTransferHook, ITransferHook) {
    super.hook(_from, _to, _amount);
    if (_sourceAllowlist.isIncluded(_from)) return;
    require(_destinationAllowlist.isIncluded(_to), "Destination not allowed");
  }

  function setSourceAllowlist(IAccountList _newSourceAllowlist)
    external
    override
    onlyOwner
  {
    _sourceAllowlist = _newSourceAllowlist;
    emit SourceAllowlistChange(_newSourceAllowlist);
  }

  function setDestinationAllowlist(IAccountList _newDestinationAllowlist)
    external
    override
    onlyOwner
  {
    _destinationAllowlist = _newDestinationAllowlist;
    emit DestinationAllowlistChange(_newDestinationAllowlist);
  }

  function getSourceAllowlist() external view override returns (IAccountList) {
    return _sourceAllowlist;
  }

  function getDestinationAllowlist()
    external
    view
    override
    returns (IAccountList)
  {
    return _destinationAllowlist;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import "./IBlocklistTransferHook.sol";
import "./IAccountList.sol";

/**
 * @notice Hook for restricting transfers of an ERC20 token.
 * @dev Transfers of the specified token are restricted by default.
 *
 * Any address can send to an allowlisted destination address.
 *
 * Allowlisted source addresses are able to send to any other address
 * (including addresses not on the destination allowlist).
 *
 * Blocklisted addresses cannot send or receive tokens, even if allowlisted.
 */
interface IRestrictedTransferHook is IBlocklistTransferHook {
  /**
   * @dev Emitted via `setSourceAllowlist()`.
   * @param newSourceAllowlist Address of the `IAccountList` contract
   */
  event SourceAllowlistChange(IAccountList newSourceAllowlist);

  /**
   * @dev Emitted via `setDestinationAllowlist()`.
   * @param newDestinationAllowlist Address of the `IAccountList` contract
   */
  event DestinationAllowlistChange(IAccountList newDestinationAllowlist);

  /**
   * @notice Sets the external `IAccountList` contract that specifies the
   * allowlisted source addresses.
   * @param newSourceAllowlist Address of the `IAccountList` contract
   */
  function setSourceAllowlist(IAccountList newSourceAllowlist) external;

  /**
   * @notice Sets the external `IAccountList` contract that specifies the
   * allowlisted destination addresses.
   * @param newDestinationAllowlist Address of the `IAccountList` contract
   */
  function setDestinationAllowlist(IAccountList newDestinationAllowlist)
    external;

  ///@return The source allowlist contract
  function getSourceAllowlist() external view returns (IAccountList);

  ///@return The destination allowlist contract
  function getDestinationAllowlist() external view returns (IAccountList);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

/**
 * @notice Stores whether an address is included in a set.
 */
interface IAccountList {
  /**
   * @notice Sets whether an address in `accounts` is included.
   * @dev Whether an account is included is based on the boolean value at its
   * respective index in `included`. This function will only edit the
   * inclusion of addresses in `accounts`.
   *
   * The length of `accounts` and `included` must match.
   *
   * Only callable by `owner()`.
   * @param accounts Addresses to change inclusion for
   * @param included Whether to include corresponding address in `accounts`
   */
  function set(address[] calldata accounts, bool[] calldata included) external;

  /**
   * @notice Removes every address from the set. Atomically includes any
   * addresses in `newIncludedAccounts`.
   * @dev Only callable by `owner()`.
   * @param newIncludedAccounts Addresses to include after reset
   */
  function reset(address[] calldata newIncludedAccounts) external;

  /**
   * @param account Address to check inclusion for
   * @return Whether `account` is included
   */
  function isIncluded(address account) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import "./interfaces/IBlocklistTransferHook.sol";
import "./interfaces/IAccountList.sol";
import "prepo-shared-contracts/contracts/SafeOwnable.sol";

contract BlocklistTransferHook is IBlocklistTransferHook, SafeOwnable {
  IAccountList private _blocklist;

  constructor() {}

  function hook(
    address _from,
    address _to,
    uint256 _amount
  ) public virtual override {
    require(!_blocklist.isIncluded(_from), "Sender blocked");
    require(!_blocklist.isIncluded(_to), "Recipient blocked");
  }

  function setBlocklist(IAccountList _newBlocklist)
    external
    override
    onlyOwner
  {
    _blocklist = _newBlocklist;
    emit BlocklistChange(_newBlocklist);
  }

  function getBlocklist() external view override returns (IAccountList) {
    return _blocklist;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import "./ITransferHook.sol";
import "./IAccountList.sol";

/**
 * @notice Hook that provides blocklist functionality for token transfers.
 * A blocked address cannot send or receive the specified ERC20 token.
 */
interface IBlocklistTransferHook is ITransferHook {
  /**
   * @dev Emitted via `setBlocklist()`.
   * @param newBlocklist Address of the `IAccountList` contract
   */
  event BlocklistChange(IAccountList newBlocklist);

  /**
   * @notice Sets the `IAccountList` contract that specifies the addresses to
   * block.
   * @param newBlocklist Address of the `IAccountList` contract
   */
  function setBlocklist(IAccountList newBlocklist) external;

  ///@return The blocklist contract
  function getBlocklist() external view returns (IAccountList);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

///@notice External hook to be called before or after an ERC20 token transfer.
interface ITransferHook {
  /**
   * @notice A generic hook function, to be called before or after a token
   * transfer.
   * @dev This function should reside in an ERC20's `_beforeTokenTransfer()`
   * or `_afterTokenTransfer()` internal functions.
   * @param from Address tokens are coming from
   * @param to Address tokens are going to
   * @param amount Token amount being transferred
   */
  function hook(
    address from,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISafeOwnable.sol";

contract SafeOwnable is ISafeOwnable, Ownable {
  address private _nominee;

  modifier onlyNominee() {
    require(_msgSender() == _nominee, "msg.sender != nominee");
    _;
  }

  function transferOwnership(address _newNominee)
    public
    virtual
    override(ISafeOwnable, Ownable)
    onlyOwner
  {
    _setNominee(_newNominee);
  }

  function acceptOwnership() public virtual override onlyNominee {
    _transferOwnership(_nominee);
    _setNominee(address(0));
  }

  function renounceOwnership()
    public
    virtual
    override(ISafeOwnable, Ownable)
    onlyOwner
  {
    super.renounceOwnership();
    _setNominee(address(0));
  }

  function getNominee() public view virtual override returns (address) {
    return _nominee;
  }

  function _setNominee(address _newNominee) internal virtual {
    address _oldNominee = _nominee;
    _nominee = _newNominee;
    emit NomineeUpdate(_oldNominee, _newNominee);
  }
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

/**
 * @notice An extension of OpenZeppelin's `Ownable.sol` contract that requires
 * an address to be nominated, and then accept that nomination, before
 * ownership is transferred.
 */
interface ISafeOwnable {
  /**
   * @dev Emitted via `transferOwnership()`.
   * @param previousNominee The previous nominee
   * @param newNominee The new nominee
   */
  event NomineeUpdate(
    address indexed previousNominee,
    address indexed newNominee
  );

  /**
   * @notice Nominates an address to be owner of the contract.
   * @dev Only callable by `owner()`.
   * @param nominee The address that will be nominated
   */
  function transferOwnership(address nominee) external;

  /**
   * @notice Renounces ownership of contract and leaves the contract
   * without any owner.
   * @dev Only callable by `owner()`.
   * Sets nominee back to zero address.
   * It will not be possible to call `onlyOwner` functions anymore.
   */
  function renounceOwnership() external;

  /**
   * @notice Accepts ownership nomination.
   * @dev Only callable by the current nominee. Sets nominee back to zero
   * address.
   */
  function acceptOwnership() external;

  /// @return The current nominee
  function getNominee() external view returns (address);
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