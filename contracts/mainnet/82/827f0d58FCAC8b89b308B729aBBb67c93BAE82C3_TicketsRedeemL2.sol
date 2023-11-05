// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
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
pragma solidity ^0.8.17;

import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface BeastContract {
    function safeMint(address to) external returns (uint256);
}

contract TicketsRedeemL2 is Ownable {
    address public l1Target;
    BeastContract public originBeasts;
    BeastContract public beasts;


    enum BeastCollection {
        OriginBeast,
        StarterBeast
    }

    event BeastRedeemed(uint indexed tokenId, BeastCollection indexed collection, bool fromGoldenTicket);
    event TicketsRedeemed(address indexed from, uint[] ids, uint[] amounts);

    constructor(address _l1Target, address _originBeasts, address _beasts) {
        l1Target = _l1Target;
        originBeasts = BeastContract(_originBeasts);
        beasts = BeastContract(_beasts);
    }

    function updateL1Target(address _l1Target) external onlyOwner {
        l1Target = _l1Target;
    }

    function _random() internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender,
                        gasleft()
                    )
                )
            ) % 100;
    }

    function redeemTickets(
        address from,
        uint[] calldata ids,
        uint[] calldata amounts
    ) public {
        require(
            msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1Target),
            "Can only be called by L1 contract"
        );

        for (uint i = 0; i < ids.length; i++) {
            uint256 tokenId = ids[i];
            uint256 amount = amounts[i];
            if (tokenId == 1) {
                uint originId = originBeasts.safeMint(from);
                uint starterId = beasts.safeMint(from);
                emit BeastRedeemed(originId, BeastCollection.OriginBeast, true);
                emit BeastRedeemed(starterId, BeastCollection.StarterBeast, true);
            } else if (tokenId == 2) {
                uint originId = originBeasts.safeMint(from);
                emit BeastRedeemed(originId, BeastCollection.OriginBeast, false);


                if (_random() < 10) {
                    uint starterId = beasts.safeMint(from);
                    emit BeastRedeemed(starterId, BeastCollection.StarterBeast, false);
                }
            }
        }

        emit TicketsRedeemed(from, ids, amounts);
    }
}