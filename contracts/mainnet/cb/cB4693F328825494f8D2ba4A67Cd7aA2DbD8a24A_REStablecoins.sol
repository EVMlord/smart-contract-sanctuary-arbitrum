// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20Full is IERC20Metadata, IERC20Permit {
    /** This function might not exist */
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

interface IOwned
{
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    error NotOwner();
    error AlreadyInitialized();

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
    function claimOwnership() external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "../Library/CheapSafeERC20.sol";

interface IRECoverable
{
    error NotRECoverableOwner();
    
    function recoverERC20(IERC20 token) external;
    function recoverNative() external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "./IUUPSUpgradeableVersion.sol";
import "./IRECoverable.sol";
import "./IOwned.sol";

interface IUpgradeableBase is IUUPSUpgradeableVersion, IRECoverable, IOwned
{
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

interface IUUPSUpgradeable
{
    event Upgraded(address newImplementation);

    error ProxyDelegateCallRequired();
    error DelegateCallForbidden();
    error ProxyNotActive();
    error NotUUPS();
    error UnsupportedProxiableUUID();
    error UpgradeCallFailed();
    
    function proxiableUUID() external view returns (bytes32);
    
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "./IUUPSUpgradeable.sol";

interface IUUPSUpgradeableVersion is IUUPSUpgradeable
{
    error UpgradeToSameVersion();

    function contractVersion() external view returns (uint256);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "./IOwned.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
    Allows contract ownership, but not renunciation
 */
abstract contract Owned is IOwned
{
    bytes32 private constant OwnerSlot = keccak256("SLOT:Owned:owner");
    bytes32 private constant PendingOwnerSlot = keccak256("SLOT:Owned:pendingOwner");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable firstOwner = msg.sender;

    function owner() public view returns (address)
    {
        address o = StorageSlot.getAddressSlot(OwnerSlot).value;
        return o == address(0) ? firstOwner : o;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        StorageSlot.getAddressSlot(PendingOwnerSlot).value = newOwner;
    }

    function claimOwnership()
        public
    {
        StorageSlot.AddressSlot storage pending = StorageSlot.getAddressSlot(PendingOwnerSlot);
        if (pending.value != msg.sender) { revert NotOwner(); }
        emit OwnershipTransferred(owner(), msg.sender);
        pending.value = address(0);
        StorageSlot.getAddressSlot(OwnerSlot).value = msg.sender;
    }

    modifier onlyOwner() 
    {
        if (msg.sender != owner()) { revert NotOwner(); }
        _;
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "./IRECoverable.sol";

using CheapSafeERC20 for IERC20;

/**
    Allows for recovery of funds
 */
abstract contract RECoverable is IRECoverable 
{
    // Probably implemented using "Owned" contract functions
    function getRECoverableOwner() internal virtual view returns (address);

    function recoverERC20(IERC20 token)
        public
    {
        if (msg.sender != getRECoverableOwner()) { revert NotRECoverableOwner(); }
        beforeRecoverERC20(token);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function beforeRecoverERC20(IERC20 token) internal virtual {}

    function recoverNative()
        public
    {
        if (msg.sender != getRECoverableOwner()) { revert NotRECoverableOwner(); }
        beforeRecoverNative();
        (bool success,) = msg.sender.call{ value: address(this).balance }(""); 
        assert(success);
    }

    function beforeRecoverNative() internal virtual {}
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "./UUPSUpgradeableVersion.sol";
import "./RECoverable.sol";
import "./Owned.sol";
import "./IUpgradeableBase.sol";

/**
    All deployable upgradeable contracts should derive from this
 */
abstract contract UpgradeableBase is UUPSUpgradeableVersion, RECoverable, Owned, IUpgradeableBase
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 __contractVersion)
        UUPSUpgradeableVersion(__contractVersion)
    {
    }

    function getRECoverableOwner() internal override view returns (address) { return owner(); }
    
    function beforeUpgradeVersion(address newImplementation)
        internal
        override
        view
        onlyOwner
    {
        checkUpgradeBase(newImplementation);
    }

    function checkUpgradeBase(address newImplementation) internal virtual view;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "./IUUPSUpgradeable.sol";

/**
    Adapted from openzeppelin's UUPSUpgradeable

    However, with some notable differences
        
        We don't use the whole "initializers" scheme.  It's error-prone and awkward.  A couple contracts
        may have an initialize function, but it's not some special built-in scheme that can be screwed up.

        We don't use beacons, and we don't need to upgrade from old UUPS or other types of proxies.  We
        only support UUPS.  We don't support rollbacks.

        We don't use default-slot storage.  It's also error-prone and awkward.  It's weird that it was ever
        done that way in the first place.  But regardless, we don't.

        We have no concept of "Admin" at this stage.  Whoever implements "beforeUpgrade" can decide to
        check access if they want to.  For us, we do this in "UpgradeableBase".

 */

abstract contract UUPSUpgradeable is IUUPSUpgradeable
{
    bytes32 private constant ImplementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable self = address(this);

    function beforeUpgrade(address newImplementation) internal virtual view;
    
    modifier notDelegated()
    {
        if (address(this) != self) { revert DelegateCallForbidden(); }
        _;
    }

    modifier onlyProxy()
    {
        if (address(this) == self) { revert ProxyDelegateCallRequired(); }
        if (StorageSlot.getAddressSlot(ImplementationSlot).value != self) { revert ProxyNotActive(); }
        _;
    }

    function proxiableUUID()
        public
        virtual
        view
        notDelegated
        returns (bytes32)
    {
        return ImplementationSlot;
    }

    function upgradeTo(address newImplementation)
        public
        onlyProxy
    {
        try IUUPSUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot)
        {
            if (slot != ImplementationSlot) { revert UnsupportedProxiableUUID(); }
            beforeUpgrade(newImplementation);
            StorageSlot.getAddressSlot(ImplementationSlot).value = newImplementation;
            emit Upgraded(newImplementation);
        }
        catch
        {
            revert NotUUPS();
        }
    }
    
    function upgradeToAndCall(address newImplementation, bytes memory data)
        public
    {
        upgradeTo(newImplementation);
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool success, bytes memory returndata) = newImplementation.delegatecall(data);
        if (!success)
        {
            if (returndata.length > 0)
            {
                assembly
                {                                
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            revert UpgradeCallFailed();
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "./UUPSUpgradeable.sol";
import "./IUUPSUpgradeableVersion.sol";

/**
    Adds contract versioning

    Contract upgrades to a new contract with the same version will be rejected
 */
abstract contract UUPSUpgradeableVersion is UUPSUpgradeable, IUUPSUpgradeableVersion
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable _contractVersion;

    function contractVersion() public virtual view returns (uint256) { return _contractVersion; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 __contractVersion)
    {
        _contractVersion = __contractVersion;
    }

    function beforeUpgrade(address newImplementation)
        internal
        override
        view
    {
        if (IUUPSUpgradeableVersion(newImplementation).contractVersion() == contractVersion()) { revert UpgradeToSameVersion(); }        
        beforeUpgradeVersion(newImplementation);
    }

    function beforeUpgradeVersion(address newImplementation) internal virtual view;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Base/IUpgradeableBase.sol";

interface IREStablecoins is IUpgradeableBase
{
    struct StablecoinConfigWithName
    {
        IERC20 token;
        uint8 decimals;
        string name;
        string symbol;
    }

    error TokenNotSupported();
    error TokenMisconfigured();
    error StablecoinAlreadyExists();
    error StablecoinDoesNotExist();
    error StablecoinBakedIn();

    function isREStablecoins() external view returns (bool);
    function supported() external view returns (StablecoinConfigWithName[] memory);
    function getMultiplyFactor(IERC20 token) external view returns (uint256);

    function add(IERC20 stablecoin) external;
    function remove(IERC20 stablecoin) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

/*
    Adapted from openzeppelin's `Address.sol`    
*/

library CheapSafeCall
{
    /**
        Makes a call
        Returns true if the call succeeded, and it was to a contract address, and either nothing was returned or 'true' was returned
        It does not revert on failures
     */
    function callOptionalBooleanNoThrow(address addr, bytes memory data) 
        internal
        returns (bool)
    {
        (bool success, bytes memory result) = addr.call(data);
        return success && (result.length == 0 ? addr.code.length > 0 : abi.decode(result, (bool)));        
    }
    /**
        Makes a call
        Returns true if the call succeeded, and it was to a contract address, and either nothing was returned or 'true' was returned
        Returns false if 'false' was returned
        Returns false if the call failed and nothing was returned
        Bubbles up the revert reason if the call reverted
     */
    function callOptionalBoolean(address addr, bytes memory data) 
        internal
        returns (bool)
    {
        (bool success, bytes memory result) = addr.call(data);
        if (success) 
        {
            return result.length == 0 ? addr.code.length > 0 : abi.decode(result, (bool));
        }
        else 
        {
            if (result.length == 0) { return false; }
            assembly 
            {
                let resultSize := mload(result)
                revert(add(32, result), resultSize)
            }
        }        
    }
    /**
        Makes a call
        Success, to a contract:  Returns true
        Success, with any result:  Returns true
        Failure:  Returns false
        Reverted:  Reverts
     */
    function call(address addr, bytes memory data)
        internal
        returns (bool)
    {
        (bool success, bytes memory result) = addr.call(data);
        if (success)
        {
            return result.length > 0 || addr.code.length > 0;
        }
        if (result.length == 0) { return false; }
        assembly 
        {
            let resultSize := mload(result)
            revert(add(32, result), resultSize)
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CheapSafeCall.sol";

/*
    Adapted from openzeppelin's `SafeERC20.sol`

    But implemented using custom errors, and with different 'safeApprove' functionality
*/

library CheapSafeERC20 
{
    error TransferFailed();
    error ApprovalFailed();

    /**
        Calls 'transfer' on an ERC20
        On failure, reverts with either the ERC20's error message or 'TransferFailed'
     */
    function safeTransfer(IERC20 token, address to, uint256 value) 
        internal 
    {
        if (!CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.transfer.selector, to, value))) { revert TransferFailed(); }
    }

    /**
        Calls 'transferFrom' on an ERC20
        On failure, reverts with either the ERC20's error message or 'TransferFailed'
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) 
        internal 
    {
        if (!CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value))) { revert TransferFailed(); }
    }

    /**
        Calls 'approve' on an ERC20
        If it fails, it attempts to approve for 0 amount then to the requested amount
        If that also fails, it will revert with either the ERC20's error message or 'ApprovalFailed'
     */
    function safeApprove(IERC20 token, address spender, uint256 value)
        internal
    {
        if (!CheapSafeCall.callOptionalBooleanNoThrow(address(token), abi.encodeWithSelector(token.approve.selector, spender, value)))
        {
            if (value == 0 ||
                !CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.approve.selector, spender, 0)) ||
                !CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.approve.selector, spender, value)))
            {
                revert ApprovalFailed(); 
            }
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.19;

import "./IREStablecoins.sol";
import "./Base/UpgradeableBase.sol";
import "./Base/IERC20Full.sol";

/**
    Supported stablecoins configuration

    The "baked in" stablecoins are a gas optimization.  We support up to 3 of them, or could increase this (but we probably won't!)

    At present, we limit stablecoins to 6 or 18 decimals, but this is only a gas optimization.

    External contracts probably just call "getStablecoinDecimals".  Everything else is front-end helpers or admin, pretty much.

    Version 2 -> 3 ... Simplifying it.  Stop tracking permit abilities.  It's better suited on front end.  Other future-use plans have changed, so this simplification made sense.
 */
contract REStablecoins is UpgradeableBase(4), IREStablecoins
{
    IERC20[] private moreStablecoinAddresses;
    mapping (IERC20 => uint256) private moreStablecoinMultiplyFactors;

    //------------------ end of storage
    
    bool public constant isREStablecoins = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 private immutable stablecoin1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 private immutable stablecoin2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 private immutable stablecoin3;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable factor1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable factor2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable factor3;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _stablecoin1, IERC20 _stablecoin2, IERC20 _stablecoin3)
    {
        stablecoin1 = _stablecoin1;
        stablecoin2 = _stablecoin2;
        stablecoin3 = _stablecoin3;
        factor1 = loadFactor(_stablecoin1);
        factor2 = loadFactor(_stablecoin2);
        factor3 = loadFactor(_stablecoin3);
    }

    function loadFactor(IERC20 _token) 
        private
        view
        returns (uint256 factor)
    {
        if (address(_token) == address(0)) { return 0; }
        uint8 decimals = IERC20Full(address(_token)).decimals();
        if (decimals != 6 && decimals != 18) { revert TokenNotSupported(); }
        return decimals == 6 ? 10**12 : 1;
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREStablecoins(newImplementation).isREStablecoins());
    }

    function supported()
        public
        view
        returns (StablecoinConfigWithName[] memory stablecoins)
    {
        unchecked
        {
            uint256 builtInCount = 0;
            if (address(stablecoin1) != address(0)) { ++builtInCount; }
            if (address(stablecoin2) != address(0)) { ++builtInCount; }
            if (address(stablecoin3) != address(0)) { ++builtInCount; }
            stablecoins = new StablecoinConfigWithName[](builtInCount + moreStablecoinAddresses.length);
            uint256 at = 0;
            if (address(stablecoin1) != address(0)) { stablecoins[at++] = toStablecoinConfigWithName(stablecoin1); }
            if (address(stablecoin2) != address(0)) { stablecoins[at++] = toStablecoinConfigWithName(stablecoin2); }
            if (address(stablecoin3) != address(0)) { stablecoins[at++] = toStablecoinConfigWithName(stablecoin3); }
            for (uint256 x = moreStablecoinAddresses.length; x > 0;) 
            {
                stablecoins[at++] = toStablecoinConfigWithName(moreStablecoinAddresses[--x]);
            }
        }
    }

    function toStablecoinConfigWithName(IERC20 token)
        private
        view
        returns (StablecoinConfigWithName memory configWithName)
    {
        return StablecoinConfigWithName({
            token: token,
            decimals: IERC20Full(address(token)).decimals(),
            name: IERC20Full(address(token)).name(),
            symbol: IERC20Full(address(token)).symbol()
        });
    }

    /** Returns a number which can be multiplied by a token amount to standardize to 18 decimal places
        If a token supports 18 decimals, this returns 1
        If a token supports 6 decimals, this returns 10**12
        Generally:  10 ** [18 - decimals]
        If a token is not in our list of supported stablecoins, this reverts with TokenNotSupported
     */
    function getMultiplyFactor(IERC20 token)
        public
        view
        returns (uint256 factor)
    {
        unchecked
        {
            if (address(token) == address(0)) { revert TokenNotSupported(); }
            if (token == stablecoin1) { return factor1; }
            if (token == stablecoin2) { return factor2; }
            if (token == stablecoin3) { return factor3; }
            factor = moreStablecoinMultiplyFactors[token];
            if (factor == 0) { revert TokenNotSupported(); }            
        }
    }

    function add(IERC20 stablecoin)
        public
        onlyOwner
    {
        if (stablecoin == stablecoin1 ||
            stablecoin == stablecoin2 ||
            stablecoin == stablecoin3 ||
            moreStablecoinMultiplyFactors[stablecoin] > 0)
        {
            revert StablecoinAlreadyExists();
        }
        if (address(stablecoin) == address(0)) { revert TokenNotSupported(); }
        moreStablecoinMultiplyFactors[stablecoin] = loadFactor(stablecoin);
        moreStablecoinAddresses.push(stablecoin);
    }

    function remove(IERC20 stablecoin)
        public
        onlyOwner
    {
        if (moreStablecoinMultiplyFactors[stablecoin] > 0)
        {
            moreStablecoinMultiplyFactors[stablecoin] = 0;
            for (uint256 x = moreStablecoinAddresses.length - 1; ; --x) 
            {
                if (moreStablecoinAddresses[x] == stablecoin) 
                {
                    moreStablecoinAddresses[x] = moreStablecoinAddresses[moreStablecoinAddresses.length - 1];
                    moreStablecoinAddresses.pop();
                    return;
                }
            }
        }
        if (stablecoin == stablecoin1 ||
            stablecoin == stablecoin2 ||
            stablecoin == stablecoin3)
        {
            revert StablecoinBakedIn();
        }
        revert StablecoinDoesNotExist();        
    }
}