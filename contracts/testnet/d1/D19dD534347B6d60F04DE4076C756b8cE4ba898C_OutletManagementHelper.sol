// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IOutletManagement.sol";

interface IOutletDescriptor {
  function outletURI(IOutletManagement outletManagement, uint256 outletId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper interface
interface IOutletManagement {
    // Outlet Data
    struct OutletData {
        // outlet name
        string name;
        // the manager account
        address manager;
        // active flag
        bool isActive;
        // credit quota
        uint256 creditQuota;
        // curculation units
        uint256 circulation;
    }

    function allOutletIds() external view returns (uint256[] memory);

    function outletIdsOf(address account) external view returns (uint256[] memory);

    function getOutletData(uint256 outletId) external view returns (OutletData memory);

    function outletURI(uint256 outletId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../solv/interfaces/IVNFT.sol";
import "../solv/openzeppelin/token/ERC721/IERC721EnumerableUpgradeable.sol";
import "../solv/openzeppelin/token/ERC721/IERC721MetadataUpgradeable.sol";

interface ISurfVoucher is IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable , IVNFT {
    function slotAdminOf(uint256 slot) external view returns (address);

    function mint(uint256 slot, address user, uint256 units) external returns (uint256);

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./solv/openzeppelin/access/Ownable2StepUpgradeable.sol";
import "./solv/openzeppelin/introspection/IERC165Upgradeable.sol";
import "./solv/openzeppelin/proxy/Initializable.sol";
import "./solv/openzeppelin/utils/EnumerableSetUpgradeable.sol";
import "./solv/openzeppelin/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./solv/openzeppelin/Errors.sol";
import "./interfaces/ISurfVoucher.sol";
import "./interfaces/IOutletDescriptor.sol";
import "./interfaces/IOutletManagement.sol";

contract OutletManagement is
    IOutletManagement,
    Initializable,
    IERC165Upgradeable,
    IVNFTReceiver,
    IERC721ReceiverUpgradeable,
    Ownable2StepUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /// constants

    /// variables

    // slot id using in SurfVoucher
    uint256 public slotId;

    // The SurfVoucher
    ISurfVoucher public surfVoucher;

    // The IOutletDescriptor
    IOutletDescriptor public outletDescriptor;

    // outlet id set
    EnumerableSetUpgradeable.UintSet private outletIdSet;

    // outlet id -> OutletData mapping
    mapping(uint256 => OutletData) private outletDataMapping;

    // address -> token set in standby state 
    mapping(address => EnumerableSetUpgradeable.UintSet) private standbyTokenSetMapping;

    // id of outlet, start from 1
    uint32 private nextOutletId;

    /// events

    // emits when add new outlet
    event AddedOutlet(
        uint256 outletId,
        string name,
        address manager,
        bool isActive,
        uint256 creditQuota
    );

    // emits when outlet is removed
    event RemovedOutlet(uint256 outletId);

    // emits when deactivate outlet
    event DeactivatedOutlet(uint256 outletId);

    // emits when activate outlet
    event ActivatedOutlet(uint256 outletId);

    // emits when credit quota of outlet changed
    event OutletCreditQuotaChanged(
        uint256 outletId,
        uint256 previousQuota,
        uint256 currentQuota
    );

    // emits when manager of outlet changed
    event OutletManagerChanged(
        uint256 outletId,
        address previousManager,
        address currentManager
    );

    // emits when manager of outlet changed
    event OutletNameChanged(uint256 outletId, string previousName, string currentName);

    // emits when outlet descriptor changed
    event OutletDescriptorChanged(
        IOutletDescriptor previousDescriptor,
        IOutletDescriptor currentDescriptor
    );

    // emits when outlet issues new units
    event OutletIssuance(uint256 outletId, address receiver, uint256 units);

    // emits when outlet releases units
    event OutletReleasement(uint256 outletId, uint256 units);

    // emits when token entered standby status
    event StandbyEntrance(address from, uint256 tokenId);

    // emits when token cancelled standby status
    event StandbyCancelled(address from, uint256 tokenId);

    function initialize(
        ISurfVoucher surfVoucher_,
        uint256 slotId_,
        address initOwner
    ) external initializer {
        require(
            address(surfVoucher_) != address(0),
            Errors.INVALID_INPUT
        );
        require(initOwner != address(0), Errors.INVALID_INPUT);

        // initialize owner
        _transferOwnership(initOwner);

        slotId = slotId_;
        surfVoucher = surfVoucher_;

        nextOutletId = 1;
    }

    // ERC165
    function supportsInterface(
        bytes4 interfaceId
    ) external pure override returns (bool) {
        return interfaceId == type(IERC721ReceiverUpgradeable).interfaceId 
            || interfaceId == type(IVNFTReceiver).interfaceId;
    }

    // implements IVNFTReceiver
    // reject
    function onVNFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        uint256 units,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return bytes4(0);
    }

    // implements IERC721ReceiverUpgradeable 
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        uint256 slotId_ = surfVoucher.slotOf(tokenId);
        // only token of slotId 
        if (slotId_ != slotId) {
            return bytes4(0);
        }

        EnumerableSetUpgradeable.UintSet storage tokenSet = standbyTokenSetMapping[from];
        if (tokenSet.add(tokenId)) {
            emit StandbyEntrance(from, tokenId);
        }

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    // returns next outlet id
    function _generateOutletId() internal returns (uint256) {
        return nextOutletId++;
    }

    /// View functions

    /**
     * returns all outlet id set
     */
    function allOutletIds() external view override returns (uint256[] memory) {
        return outletIdSet.values();
    }

    /**
     * returns outlet id set with given manager
     */
    function outletIdsOf(address manager) external view override returns (uint256[] memory) {
        uint256[] memory outletIdSet_ = outletIdSet.values();

        uint count = 0;
        for (uint i = 0; i < outletIdSet_.length; i++) {
            OutletData memory outletData = outletDataMapping[outletIdSet_[i]];
            if (outletData.manager == manager) {
                count++;
            }
        }

        if (count == 0) {
            return new uint256[] (0);
        }

        uint256[] memory result = new uint256[] (count);
        count = 0;
        for (uint i = 0; i < outletIdSet_.length; i++) {
            OutletData memory outletData = outletDataMapping[outletIdSet_[i]];
            if (outletData.manager == manager) {
                result[count] = outletIdSet_[i];
                count++;
            }
        }

        return result;
    }

    /**
     * returns outlet data by given id
     */
    function getOutletData( uint256 outletId) external view override returns (OutletData memory) {
        require(_exists(outletId), Errors.NONEXISTENCE);

        return outletDataMapping[outletId];
    }

    /**
     * returns standby token id set of given account
     */
    function getStandbyTokenIds(address account) external view returns (uint256[] memory) {
        return standbyTokenSetMapping[account].values();
    }

    /**
     * returns outlet metadata
     */
    function outletURI(uint256 outletId) external view override returns (string memory) {
        require(_exists(outletId), Errors.NONEXISTENCE);

        return outletDescriptor.outletURI(this, outletId);
    }

    /// Change state functions

    /**
     * issue new units
     * @dev only manager of outlet
     */
    function issue(uint256 outletId, address receiver, uint256 units) external returns (uint256 tokenId) {
        require(_exists(outletId), Errors.NONEXISTENCE);
        require(receiver != address(0), Errors.INVALID_INPUT);

        OutletData storage outletData = outletDataMapping[outletId];
        require(outletData.manager == _msgSender(), Errors.NON_AUTH);
        require(outletData.isActive, Errors.ILLEGAL_STATE);

        uint256 aviaiableQuota = _calcAviaiableQuota(outletData);
        require(units <= aviaiableQuota, Errors.EXCEEDS);

        // mint new token
        tokenId = surfVoucher.mint(slotId, receiver, units);

        // accumulate circulation
        outletData.circulation = outletData.circulation + units;

        emit OutletIssuance(outletId, receiver, units);
    }

    /**
     * release token
     */
    function release(uint256 tokenId, uint256 outletId) external {
        require(_exists(outletId), Errors.NONEXISTENCE);

        EnumerableSetUpgradeable.UintSet storage tokenSet = standbyTokenSetMapping[_msgSender()];
        require(tokenSet.contains(tokenId), Errors.ILLEGAL_STATE);

        // update storage
        OutletData storage outletData = outletDataMapping[outletId];
        require(outletData.isActive, Errors.ILLEGAL_STATE);

        // get units in token
        uint256 unitsInToken = surfVoucher.unitsInToken(tokenId);
        require(outletData.circulation >= unitsInToken, Errors.EXCEEDS);

        // burn token
        surfVoucher.burn(tokenId);

        // deduct circulation
        outletData.circulation = outletData.circulation - unitsInToken;

        // remove from standby
        tokenSet.remove(tokenId);

        emit OutletReleasement(outletId, unitsInToken);
    }

    /**
     * release token by owner
     * 
     * @dev only owner
     */
    function delegateRelease(uint256 tokenId, uint256 outletId) external onlyOwner {
        uint256 slotId_ = surfVoucher.slotOf(tokenId);
        require(slotId_ == slotId, Errors.ILLEGAL_STATE);

        require(_exists(outletId), Errors.NONEXISTENCE);

        // update storage
        OutletData storage outletData = outletDataMapping[outletId];

        // get units in token
        uint256 unitsInToken = surfVoucher.unitsInToken(tokenId);
        require(outletData.circulation >= unitsInToken, Errors.EXCEEDS);

        // burn token
        surfVoucher.burn(tokenId);

        // deduct circulation
        outletData.circulation = outletData.circulation - unitsInToken;

        emit OutletReleasement(outletId, unitsInToken);
    }

    /**
     * Cancel standby status
     */
    function cancelStandby(uint256 tokenId) external {
        EnumerableSetUpgradeable.UintSet storage tokenSet = standbyTokenSetMapping[_msgSender()];
        if (tokenSet.remove(tokenId)) {
            surfVoucher.safeTransferFrom(address(this), _msgSender(), tokenId);

            emit StandbyCancelled(_msgSender(), tokenId);
        }
    }

    /// internal functions

    /**
     * return if outletId exists
     */
    function _exists(uint256 outletId) internal view returns (bool) {
        return outletIdSet.contains(outletId);
    }

    /**
     * calculate avaiable redit quota
     */
    function _calcAviaiableQuota(
        OutletData memory outletData
    ) internal pure returns (uint256) {
        return
            outletData.creditQuota > outletData.circulation
                ? outletData.creditQuota - outletData.circulation
                : 0;
    }

    /// Administrative functions

    /**
     * add new outLet
     */
    function addOutlet(
        string memory name,
        address manager,
        uint256 creditQuota
    ) external onlyOwner {
        require(manager != address(0), Errors.INVALID_INPUT);

        // update state
        uint256 outletId = _generateOutletId();
        outletIdSet.add(outletId);
        outletDataMapping[outletId] = OutletData({
            name: name,
            manager: manager,
            isActive: true,
            creditQuota: creditQuota,
            circulation: 0
        });

        emit AddedOutlet(outletId, name, manager, true, creditQuota);
    }

    /**
     * deactivate outLet
     */
    function deactivateOutlet(uint256 outletId) external onlyOwner {
        require(_exists(outletId), Errors.NONEXISTENCE);

        OutletData storage outletData = outletDataMapping[outletId];

        // update state
        if (outletData.isActive) {
            outletData.isActive = false;
            emit DeactivatedOutlet(outletId);
        }
    }

    /**
     * activate outLet
     */
    function activateOutlet(uint256 outletId) external onlyOwner {
        require(_exists(outletId), Errors.NONEXISTENCE);

        OutletData storage outletData = outletDataMapping[outletId];

        // update state
        if (!outletData.isActive) {
            outletData.isActive = true;
            emit ActivatedOutlet(outletId);
        }
    }

    /**
     * set credit quota
     */
    function setCreditQuota(
        uint256 outletId,
        uint256 creditQuota_
    ) external onlyOwner {
        require(_exists(outletId), Errors.NONEXISTENCE);

        OutletData storage outletData = outletDataMapping[outletId];

        // update state
        uint256 previousQuota = outletData.creditQuota;
        outletData.creditQuota = creditQuota_;

        emit OutletCreditQuotaChanged(
            outletId,
            previousQuota,
            outletData.creditQuota
        );
    }

    /**
     * remove outLet
     */
    function removeOutlet(uint256 outletId) external onlyOwner {
        require(_exists(outletId), Errors.NONEXISTENCE);

        OutletData memory outletData = outletDataMapping[outletId];
        require(outletData.circulation == 0, Errors.ILLEGAL_STATE);

        // update state
        delete outletDataMapping[outletId];
        outletIdSet.remove(outletId);

        emit RemovedOutlet(outletId);
    }

    /**
     * set outlet name
     */
    function setName(uint256 outletId, string memory name) external onlyOwner {
        require(_exists(outletId), Errors.NONEXISTENCE);

        OutletData storage outletData = outletDataMapping[outletId];

        // update state
        string memory previousName = outletData.name;
        outletData.name = name;

        emit OutletNameChanged(outletId, previousName, name);
    }

    /**
     * set outlet manager
     */
    function setManager(uint256 outletId, address manager) external onlyOwner {
        require(_exists(outletId), Errors.NONEXISTENCE);
        require(manager != address(0), Errors.INVALID_INPUT);

        OutletData storage outletData = outletDataMapping[outletId];

        // update state
        address previousManager = outletData.manager;
        outletData.manager = manager;

        emit OutletManagerChanged(outletId, previousManager, manager);
    }

    /**
     * set OutletDescriptor
     */
    function setOutletDescriptor(
        IOutletDescriptor outletDescriptor_
    ) external onlyOwner {
        require(
            address(outletDescriptor_) != address(0),
            Errors.INVALID_INPUT
        );

        IOutletDescriptor previousDescriptor = outletDescriptor;
        outletDescriptor = outletDescriptor_;

        emit OutletDescriptorChanged(previousDescriptor, outletDescriptor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OutletManagement.sol";
import "./interfaces/ISurfVoucher.sol";

contract OutletManagementHelper {
    OutletManagement public outletManagement;

    constructor(OutletManagement _outletManagement) {
        outletManagement = _outletManagement;
    }

    function allOutletIds() external view returns (uint256[] memory) {
        return outletManagement.allOutletIds();
    }

    function outletIdsOf(address account) external view returns (uint256[] memory) {
        return outletManagement.outletIdsOf(account);
    }

    function getOutletData(uint256 outletId) external view returns (OutletManagement.OutletData memory) {
        return outletManagement.getOutletData(outletId);
    }

    function outletURI(uint256 outletId) external view returns (string memory) {
        return outletManagement.outletURI(outletId);
    }

    function isOwner(address account) external view returns (bool) {
        return outletManagement.owner() == account;
    }

    function isManager(address account) external view returns (bool) {
        return outletManagement.outletIdsOf(account).length > 0;
    }

    function batchGetOutletData(uint256[] memory outletIds) external view returns (OutletManagement.OutletData[] memory) {
        OutletManagement.OutletData[] memory result = new OutletManagement.OutletData[] (outletIds.length);
        for (uint i = 0; i < outletIds.length; i++) {
            result[i] = outletManagement.getOutletData(outletIds[i]);
        }

        return result;
    }

    function batchGetOutletURI(uint256[] memory outletIds) external view returns (string[] memory) {
        string[] memory result = new string[] (outletIds.length);

        for (uint i = 0; i < outletIds.length; i++) {
            result[i] = outletManagement.outletURI(outletIds[i]);
        }

        return result;
    }

    function summary() external view returns (uint256[] memory) {
        uint256[] memory outletIds = outletManagement.allOutletIds();

        uint256 totalCreditQuota; 
        uint256 totalCirculation; 
        for (uint i = 0; i < outletIds.length; i++) {
            OutletManagement.OutletData memory outletData = outletManagement.getOutletData(outletIds[i]);
            totalCreditQuota = totalCreditQuota + outletData.creditQuota;
            totalCirculation = totalCirculation + outletData.circulation;
        }

        uint256[] memory result = new uint256[] (3);
        result[0] = totalCreditQuota;
        result[1] = totalCirculation;

        ISurfVoucher surfVoucher = outletManagement.surfVoucher();
        result[2] = surfVoucher.tokensInSlot(outletManagement.slotId());

        return result;
    }

    function getTokenIds(address account) external view returns (uint256[] memory) {
        ISurfVoucher surfVoucher = outletManagement.surfVoucher();
        uint256 balance = surfVoucher.balanceOf(account);

        uint256[] memory result = new uint256[] (balance);
        for (uint256 i = 0; i < balance; i++) {
            result[i] = surfVoucher.tokenOfOwnerByIndex(account, i);
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* is ERC721, ERC165 */
interface IVNFT {
    event TransferUnits(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        uint256 targetTokenId,
        uint256 transferUnits
    );

    event Split(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 newTokenId,
        uint256 splitUnits
    );

    event Merge(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed targetTokenId,
        uint256 mergeUnits
    );

    event ApprovalUnits(
        address indexed approval,
        uint256 indexed tokenId,
        uint256 allowance
    );

    function slotOf(uint256 tokenId) external view returns (uint256 slot);

    function unitDecimals() external view returns (uint8);

    function unitsInSlot(uint256 slot) external view returns (uint256);

    function tokensInSlot(uint256 slot)
        external
        view
        returns (uint256 tokenCount);

    function tokenOfSlotByIndex(uint256 slot, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function unitsInToken(uint256 tokenId)
        external
        view
        returns (uint256 units);

    function approve(
        address to,
        uint256 tokenId,
        uint256 units
    ) external;

    function allowance(uint256 tokenId, address spender)
        external
        view
        returns (uint256 allowed);

    function split(uint256 tokenId, uint256[] calldata units)
        external
        returns (uint256[] memory newTokenIds);

    function merge(uint256[] calldata tokenIds, uint256 targetTokenId) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) external returns (uint256 newTokenId);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 units,
        bytes calldata data
    ) external returns (uint256 newTokenId);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 units
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 units,
        bytes calldata data
    ) external;
}

interface IVNFTReceiver {
    function onVNFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        uint256 units,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/Initializable.sol";
import "../Errors.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, Errors.ILLEGAL_STATE);
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
import "../Errors.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
        require(owner() == _msgSender(), Errors.NOT_OWNER);
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
        require(newOwner != address(0), Errors.INVALID_INPUT);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
  string public constant INVALID_INPUT = "00";
  string public constant NON_AUTH = "01";
  string public constant NONEXISTENCE = "02";
  string public constant ILLEGAL_STATE = "03";
  string public constant EXCEEDS = "04";
  string public constant NOT_OWNER = "05";
  string public constant INSUFFICIENT_BALANCE = "06";
  string public constant FAILED = "99";
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../utils/AddressUpgradeable.sol";
import "../Errors.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            Errors.ILLEGAL_STATE
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, Errors.ILLEGAL_STATE);
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, Errors.ILLEGAL_STATE);
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, Errors.ILLEGAL_STATE);
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

import "../Errors.sol";

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, Errors.INSUFFICIENT_BALANCE);

        (bool success, ) = recipient.call{value: amount}("");
        require(success, Errors.FAILED);
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, Errors.FAILED);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, Errors.FAILED);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, Errors.INSUFFICIENT_BALANCE);
        require(isContract(target), Errors.ILLEGAL_STATE);

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, Errors.FAILED);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), Errors.ILLEGAL_STATE);

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}