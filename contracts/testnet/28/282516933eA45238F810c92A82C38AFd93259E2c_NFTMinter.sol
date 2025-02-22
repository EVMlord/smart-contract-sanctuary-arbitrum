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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//contracts/NFTContract.sol
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface INFTToken is IERC721 {
    function mint(address recipient, uint256 amount) external;
}

contract NFTMinter is ReentrancyGuard, Ownable {
    struct Project {
        address addr;
        uint256 supply;
        uint256 slotPerAddress;
        uint256 mintStartAt;
        uint256 mintEndAt;
        uint256 mintPrice;
        uint256 publicRoundSupply;
        uint256 publicMintStartAt;
        uint256 publicMintEndAt;
        uint256 publicMintPrice;
        address payAsset; // address(0) if users need to spend ETH to buy
        bool whitelist;
        Status status;
        uint256 mintedAmount;
    }

    struct PublicRound {
        uint256 publicRoundSupply;
        uint256 publicMintStartAt;
        uint256 publicMintEndAt;
        uint256 publicMintPrice;
    }

    enum Status {
        Pending,
        Open,
        Close,
        Cancel
    }

    event NewProject(
        uint256 indexed id,
        address nftContract,
        uint256 mintStartAt,
        uint256 publicMintStartAt
    );

    address public _operator;
    address public _treasury;

    mapping(uint256 => Project) private _projects;
    mapping(uint256 => mapping(address => bool)) private _projectsWhitelist;
    mapping(uint256 => mapping(address => uint256)) private _hasMinted;

    uint256 private currentProjectId;

    constructor(address owner, address operator, address treasury) {
        transferOwnership(owner);
        _operator = operator;
        _treasury = owner;
        _treasury = treasury;
    }

    function addProject(
        address addr,
        uint256 supply,
        uint256 slotPerAddress,
        uint256 mintStartAt,
        uint256 mintEndAt,
        uint256 mintPrice,
        PublicRound calldata publicRound,
        address payAsset,
        bool whitelist
    ) public onlyOperator returns (uint256) {
        require(
            mintStartAt > block.timestamp,
            "open time must greater than now"
        );
        require(
            mintEndAt > mintStartAt,
            "close time must greater than open time"
        );

        currentProjectId++;
        _projects[currentProjectId] = Project(
            addr,
            supply,
            slotPerAddress,
            mintStartAt,
            mintEndAt,
            mintPrice,
            publicRound.publicRoundSupply,
            publicRound.publicMintStartAt,
            publicRound.publicMintEndAt,
            publicRound.publicMintPrice,
            payAsset,
            whitelist,
            Status.Pending,
            0
        );
        emit NewProject(
            currentProjectId,
            addr,
            mintStartAt,
            publicRound.publicMintStartAt
        );
        return currentProjectId;
    }

    function viewProject(
        uint256 projectId
    ) external view returns (Project memory) {
        return _projects[projectId];
    }

    function mint(
        uint256 projectId,
        uint256 amount
    ) external payable onlyWhitelist(projectId) {
        // TODO: Check status
        require(
            _projects[projectId].mintStartAt <= block.timestamp,
            "not open yet"
        );
        require(
            _projects[projectId].mintEndAt >= block.timestamp,
            "closed project"
        );

        // Check products quantity
        require(
            _projects[projectId].mintedAmount <= _projects[projectId].supply,
            "out-of-stock"
        );

        require(
            _hasMinted[projectId][_msgSender()] <=
                _projects[projectId].slotPerAddress,
            "out-of-range"
        );

        // Check balance
        if (_projects[projectId].payAsset == address(0)) {
            require(
                _projects[projectId].mintPrice <= msg.value,
                "insufficient balance"
            );
        } else {
            require(
                IERC20(_projects[projectId].payAsset).balanceOf(_msgSender()) >=
                    _projects[projectId].mintPrice,
                "insufficient balance"
            );
        }

        // Mint NFT tokens
        INFTToken(_projects[projectId].addr).mint(_msgSender(), amount);
        _hasMinted[projectId][_msgSender()] = amount;

        if (_projects[projectId].payAsset == address(0)) {
            // Transfer minting fee
            if (_projects[projectId].mintPrice > 0) {
                (bool success, ) = _treasury.call{
                    value: _projects[projectId].mintPrice
                }("");
                require(success, "Failed to send Ether");
            }

            // Refund redundant ETH
            if ((msg.value - _projects[projectId].mintPrice) > 0) {
                (bool success, ) = msg.sender.call{
                    value: msg.value - _projects[projectId].mintPrice
                }("");
                require(success, "Failed to refund Ether");
            }
        } else {
            IERC20(_projects[projectId].payAsset).transferFrom(
                _msgSender(),
                _treasury,
                _projects[projectId].mintPrice * amount
            );
        }
    }

    function mintPublicRound(
        uint256 projectId,
        uint256 amount
    ) external payable {
        require(
            _projects[projectId].publicMintStartAt <= block.timestamp &&
                _projects[projectId].status == Status.Open,
            "not open yet"
        );
        require(
            _projects[projectId].publicMintEndAt >= block.timestamp,
            "project is closed"
        );

        // Check products quantity
        require(
            _projects[projectId].mintedAmount <=
                _projects[projectId].publicRoundSupply,
            "out-of-stock"
        );

        require(
            _hasMinted[projectId][_msgSender()] <=
                _projects[projectId].slotPerAddress,
            "out-of-range"
        );

        // Check balance
        if (_projects[projectId].payAsset == address(0)) {
            require(
                _projects[projectId].mintPrice <= msg.value,
                "insufficient balance"
            );
        } else {
            require(
                IERC20(_projects[projectId].payAsset).balanceOf(_msgSender()) >=
                    _projects[projectId].publicMintPrice,
                "insufficient balance"
            );
        }

        // Mint NFT tokens
        INFTToken(_projects[projectId].addr).mint(_msgSender(), amount);
        _hasMinted[projectId][_msgSender()] = amount;

        if (_projects[projectId].payAsset == address(0)) {
            // Transfer minting fee
            if (_projects[projectId].publicMintPrice > 0) {
                (bool success, ) = _treasury.call{
                    value: _projects[projectId].publicMintPrice
                }("");
                require(success, "Failed to send Ether");
            }

            // Refund redundant ETH
            if ((msg.value - _projects[projectId].publicMintPrice) > 0) {
                (bool success, ) = msg.sender.call{
                    value: msg.value - _projects[projectId].publicMintPrice
                }("");
                require(success, "Failed to refund Ether");
            }
        } else {
            IERC20(_projects[projectId].payAsset).transferFrom(
                _msgSender(),
                _treasury,
                _projects[projectId].publicMintPrice * amount
            );
        }
    }

    /**
     * Using for operator to add addresses as a whitelist of a project
     * @param projectId project id
     * @param accounts list of address
     */
    function setWhitelist(
        uint256 projectId,
        address[] calldata accounts,
        bool value
    ) external onlyOperator {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (_projectsWhitelist[projectId][accounts[i]] != value) {
                _projectsWhitelist[projectId][accounts[i]] = value;
            }
        }
    }

    /**
     * Set new treasury for contract
     * @param treasury address of new treasury
     */
    function setTreasury(address treasury) external onlyOwner {
        require(_treasury != treasury, "no value change");
        _treasury = treasury;
    }

    modifier onlyWhitelist(uint256 projectId) {
        if (_projects[projectId].whitelist == true) {
            require(
                _projectsWhitelist[projectId][_msgSender()] == true,
                "not in whitelist"
            );
        }
        _;
    }

    modifier onlyOperator() {
        require(_operator == _msgSender(), "not operator");
        _;
    }
}