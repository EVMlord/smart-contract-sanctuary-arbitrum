// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../../utils/introspection/IERC165Upgradeable.sol";

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCall(target, data, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

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
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        require(isContract(target), "Address: static call to non-contract");

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
import "../proxy/utils/Initializable.sol";

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "./interfaces/IERC721NFT.sol";
import "./libraries/TransferHelper.sol";

contract NFTMarket is IERC721ReceiverUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    function initialize(address _nftContract) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        _pause();
        talonThieves = IERC721NFT(_nftContract);
        availablePayDuration = 1 minutes;
    }

    struct MarketItem {
        uint128 itemId;
        uint256 price;
        address currency;
        address payable seller;
        address payable owner;
        bool sold;
    }

    struct MarketToken {
        uint128 tokenId;
        uint256 price;
        address currency;
        address payable seller;
        address payable owner;
        bool sold;
    }

    uint256 public priceForAttribute;
    uint256 public preyEarnedFromSpin;
    mapping(address => uint256) public treasuryFee;
    mapping(address => uint256) public treasuryPercentage;
    uint256 public availablePayDuration;

    mapping(uint256 => MarketItem) public idToMarketItem;
    mapping(uint256 => MarketToken) public idToMarketToken;
    mapping(address => uint256[]) public listedCounts;
    mapping(address => uint256[]) public listedTokenCounts;
    mapping(address => uint256) private paidTime;

    address public paymentCurrency;
    IERC721NFT public talonThieves;

    event MarketItemCreated(
        uint128 indexed itemId,
        address indexed seller,
        address indexed owner,
        address currency,
        uint256 price
    );
    event MarketItemSold(
        uint128 indexed itemId,
        address indexed buyer,
        address indexed seller,
        address currency,
        uint256 price
    );
    event MarketItemCancel(uint128 indexed _itemId, address _seller);
    event MarketTokenCreated(
        uint128 indexed tokenId,
        address indexed seller,
        address indexed owner,
        address currency,
        uint256 price
    );
    event MarketTokenSold(
        uint128 indexed tokenId,
        address indexed buyer,
        address indexed seller,
        address currency,
        uint256 price
    );
    event MarketTokenCancel(uint128 indexed tokenId, address _seller);
    event LogPremiumWithdraw(address indexed _currency, address indexed _to, uint256 _amount);
    event LogPurchaseAttributes(address indexed _user, uint256 _priceForAttribute);

    /* Returns the listing price of the contract */
    /* Places an item for sale on the marketplace */
    function createMarketItem(
        uint128 _itemId,
        uint256 _price,
        address _currency
    ) public payable whenNotPaused nonReentrant {
        require(_price > 0, "ERR: zero price");
        require(
            idToMarketItem[_itemId].seller == address(0) && idToMarketItem[_itemId].owner == address(0),
            "ERR: item listed already"
        );

        idToMarketItem[_itemId] = MarketItem({
            itemId: _itemId,
            price: _price,
            currency: _currency,
            seller: payable(msg.sender),
            owner: payable(address(this)),
            sold: false
        });
        listedCounts[msg.sender].push(_itemId);

        emit MarketItemCreated(uint128(_itemId), msg.sender, address(0), _currency, _price);
    }

    function executeMarketItem(uint256 _itemId) external payable whenNotPaused nonReentrant {
        require(!idToMarketItem[_itemId].sold, "ERR: item sold already");
        require(idToMarketItem[_itemId].seller != msg.sender, "ERR: not allow seller to purchase its item");
        require(
            idToMarketItem[_itemId].seller != address(0) && idToMarketItem[_itemId].owner == address(this),
            "ERR: item not listed yet"
        );
        uint256 price = idToMarketItem[_itemId].price;
        address currency = idToMarketItem[_itemId].currency;
        address seller = idToMarketItem[_itemId].seller;
        uint256 _treasuryFee = (price * treasuryPercentage[currency]) / 10000;
        uint256 actualPrice = price - _treasuryFee;
        if (currency == address(0)) {
            require(msg.value >= price, "ERR: insufficient payment");
            if (msg.value > price) {
                TransferHelper.safeTransferETH(msg.sender, msg.value - price);
            }
            TransferHelper.safeTransferETH(idToMarketItem[_itemId].seller, actualPrice);
        } else {
            TransferHelper.safeTransferFrom(currency, msg.sender, address(this), price);
            TransferHelper.safeTransfer(currency, idToMarketItem[_itemId].seller, actualPrice);
        }
        delete idToMarketItem[_itemId];
        treasuryFee[currency] += _treasuryFee;
        for (uint256 ii = 0; ii < listedCounts[seller].length; ii++) {
            if (listedCounts[seller][ii] == _itemId) {
                listedCounts[seller][ii] = listedCounts[seller][listedCounts[seller].length - 1];
                listedCounts[seller].pop();
            }
        }
        emit MarketItemSold(uint128(_itemId), msg.sender, seller, currency, price);
    }

    function cancelMarketItem(uint256 _itemId) external whenNotPaused nonReentrant {
        require(!idToMarketItem[_itemId].sold, "ERR: item sold already");
        require(idToMarketItem[_itemId].owner == address(this), "ERR: item not listed yet");
        require(idToMarketItem[_itemId].seller == msg.sender, "ERR: no seller");
        for (uint256 ii = 0; ii < listedCounts[msg.sender].length; ii++) {
            if (listedCounts[msg.sender][ii] == _itemId) {
                listedCounts[msg.sender][ii] = listedCounts[msg.sender][listedCounts[msg.sender].length - 1];
                listedCounts[msg.sender].pop();
            }
        }
        delete idToMarketItem[_itemId];
        emit MarketItemCancel(uint128(_itemId), msg.sender);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketToken(
        uint256 _tokenId,
        uint256 _price,
        address _currency
    ) public payable whenNotPaused nonReentrant {
        require(IERC721Upgradeable(address(talonThieves)).ownerOf(_tokenId) == msg.sender, "ERR: no token owner");
        require(
            IERC721Upgradeable(address(talonThieves)).isApprovedForAll(msg.sender, address(this)),
            "ERR: not approved token"
        );
        require(_price > 0, "ERR: zero price");
        require(
            idToMarketToken[_tokenId].seller == address(0) && idToMarketToken[_tokenId].owner == address(0),
            "ERR: item listed already"
        );
        IERC721Upgradeable(address(talonThieves)).safeTransferFrom(msg.sender, address(this), _tokenId);

        idToMarketToken[_tokenId] = MarketToken({
            tokenId: uint128(_tokenId),
            price: _price,
            currency: _currency,
            seller: payable(msg.sender),
            owner: payable(address(this)),
            sold: false
        });

        listedTokenCounts[msg.sender].push(_tokenId);

        emit MarketTokenCreated(uint128(_tokenId), msg.sender, address(0), _currency, _price);
    }

    function executeMarketToken(uint256 _tokenId) external payable whenNotPaused nonReentrant {
        require(
            IERC721Upgradeable(address(talonThieves)).ownerOf(_tokenId) == address(this),
            "ERR: contract must be owner of token"
        );
        MarketToken memory marketToken = idToMarketToken[_tokenId];
        require(marketToken.owner == address(this), "ERR: not listed yet");
        require(marketToken.seller != msg.sender, "ERR: not allow seller to purchase its token");
        require(!marketToken.sold, "ERR: token sold already");
        uint256 price = marketToken.price;
        address currency = marketToken.currency;
        address seller = marketToken.seller;
        uint256 _treasuryFee = (price * treasuryPercentage[currency]) / 10000;
        (address receiver, uint256 royaltyAmount) = IERC2981Upgradeable(address(talonThieves)).royaltyInfo(
            _tokenId,
            price
        );
        // uint256 actualPrice = price - _treasuryFee;
        uint256 actualPrice = price - royaltyAmount - _treasuryFee;
        if (currency == address(0)) {
            require(msg.value >= price, "ERR: insufficient payment");
            if (msg.value > price) {
                TransferHelper.safeTransferETH(msg.sender, msg.value - price);
            }
            TransferHelper.safeTransferETH(seller, actualPrice);
            if (receiver != address(0) && royaltyAmount > 0) {
                TransferHelper.safeTransferETH(receiver, royaltyAmount);
            }
        } else {
            TransferHelper.safeTransferFrom(currency, msg.sender, address(this), price);
            TransferHelper.safeTransfer(currency, marketToken.seller, actualPrice);
            if (receiver != address(0) && royaltyAmount > 0) {
                TransferHelper.safeTransfer(currency, receiver, royaltyAmount);
            }
        }
        IERC721Upgradeable(address(talonThieves)).safeTransferFrom(address(this), msg.sender, _tokenId);
        treasuryFee[currency] += _treasuryFee;
        for (uint256 ii = 0; ii < listedTokenCounts[seller].length; ii++) {
            if (listedTokenCounts[seller][ii] == _tokenId) {
                listedTokenCounts[seller][ii] = listedTokenCounts[seller][listedTokenCounts[seller].length - 1];
                listedTokenCounts[seller].pop();
            }
        }
        delete idToMarketToken[_tokenId];
        emit MarketTokenSold(uint128(_tokenId), msg.sender, seller, currency, price);
    }

    function cancelMarketToken(uint256 _tokenId) external whenNotPaused nonReentrant {
        require(
            IERC721Upgradeable(address(talonThieves)).ownerOf(_tokenId) == address(this),
            "ERR: contract must be owner of token"
        );
        require(idToMarketToken[_tokenId].owner == address(this), "ERR: not listed yet");
        require(idToMarketToken[_tokenId].seller == msg.sender, "ERR: no seller");
        require(!idToMarketToken[_tokenId].sold, "ERR: token sold already");
        IERC721Upgradeable(address(talonThieves)).safeTransferFrom(address(this), msg.sender, _tokenId);
        for (uint256 ii = 0; ii < listedTokenCounts[msg.sender].length; ii++) {
            if (listedTokenCounts[msg.sender][ii] == _tokenId) {
                listedTokenCounts[msg.sender][ii] = listedTokenCounts[msg.sender][
                    listedTokenCounts[msg.sender].length - 1
                ];
                listedTokenCounts[msg.sender].pop();
            }
        }
        delete idToMarketToken[_tokenId];
        emit MarketTokenCancel(uint128(_tokenId), msg.sender);
    }

    function purchaseAttributes(address _user) external whenNotPaused nonReentrant {
        require(priceForAttribute != 0, "ERR: no determined price yet");
        require(block.timestamp - paidTime[_user] >= availablePayDuration, "ERR: unavailable pay time");
        TransferHelper.safeTransferFrom(paymentCurrency, msg.sender, address(this), priceForAttribute);
        paidTime[_user] = block.timestamp;
        preyEarnedFromSpin += priceForAttribute;
        emit LogPurchaseAttributes(msg.sender, priceForAttribute);
    }

    function customizeNFTAttributes(
        uint256 _tokenId,
        uint256 _multiplier,
        uint256 _unstaking,
        uint256 _claim,
        uint256 _double,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external whenNotPaused nonReentrant {
        require(IERC721Upgradeable(address(talonThieves)).ownerOf(_tokenId) == _msgSender(), "ERR: No Token Owner");
        address signer = _getSigner(_tokenId, _multiplier, _unstaking, _claim, _double, r, s, v);
        require(signer == _msgSender(), "ERR: invalid signer");
        talonThieves.setAttribute(_tokenId, _multiplier, _unstaking, _claim, _double);
    }

    /* Returns all unsold market items */
    function fetchMarketItems(address _account) public view returns (MarketItem[] memory) {
        uint256[] memory itemCount = listedCounts[_account];

        MarketItem[] memory items = new MarketItem[](itemCount.length);
        for (uint256 i = 0; i < itemCount.length; i++) {
            items[i] = idToMarketItem[itemCount[i]];
        }
        return items;
    }

    /* Returns onlyl items that a user has purchased */
    function fetchMarketNFTs(address _account) external view returns (MarketToken[] memory) {
        uint256[] memory itemCount = listedTokenCounts[_account];

        MarketToken[] memory items = new MarketToken[](itemCount.length);
        for (uint256 i = 0; i < itemCount.length; i++) {
            items[i] = idToMarketToken[itemCount[i]];
        }
        return items;
    }

    function _getSigner(
        uint256 _tokenId,
        uint256 _multiplier,
        uint256 _unstaking,
        uint256 _claim,
        uint256 _double,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) private pure returns (address) {
        // bytes32 digest = getSignedMsgHash(productName, priceInUSD, period, conciergePrice);
        bytes32 msgHash = keccak256(abi.encodePacked(_tokenId, _multiplier, _unstaking, _claim, _double));

        // bytes32 msgHash = keccak256(abi.encodePacked(productName));
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        // (bytes32 r, bytes32 s, uint8 v) = splitSignature(sig);
        address recoveredAddress = ecrecover(digest, v, r, s);
        return recoveredAddress;
    }

    function availablePayTime(address _user) external view returns (bool spinable, uint256 remainTime) {
        uint256 timeDiff = block.timestamp - paidTime[_user];
        spinable = timeDiff >= availablePayDuration;
        remainTime = spinable ? 0 : availablePayDuration - timeDiff;
    }

    /** ADMIN FUNCTIONS */
    function setPaymentCurrency(address _currency) external onlyOwner nonReentrant {
        paymentCurrency = _currency;
    }

    function setTreasuryPercentage(address _currency, uint256 _percentage) external onlyOwner nonReentrant {
        require(_percentage <= 100, "ERR: overflow percentage");
        treasuryPercentage[_currency] = _percentage * 100;
    }

    function setAvailablePayDuration(uint256 _duration) external onlyOwner nonReentrant {
        availablePayDuration = _duration;
    }

    function setPriceForAttribute(uint256 _priceForAttribute) external onlyOwner nonReentrant {
        priceForAttribute = _priceForAttribute;
    }

    function setNFTContract(address _nftContract) external onlyOwner nonReentrant {
        require(_nftContract != address(0), "ERR: zero address");
        talonThieves = IERC721NFT(_nftContract);
    }

    function setPaused(bool _paused) external onlyOwner nonReentrant {
        if (_paused) _pause();
        else _unpause();
    }

    function withdrawPremium(
        address _currency,
        address _to,
        uint256 _amount,
        bool _isTreasury
    ) external onlyOwner nonReentrant {
        require(_amount > 0, "ERR: Zero amount");
        if (_isTreasury) {
            require(treasuryFee[_currency] >= _amount, "ERR: Insufficient Treasury Premium");
            if (_currency == address(0)) {
                require(address(this).balance >= _amount, "ERR: Insufficient Premium");
                TransferHelper.safeTransferETH(_to, _amount);
            } else {
                require(IERC20Upgradeable(_currency).balanceOf(address(this)) >= _amount, "ERR: Insufficient Premium");
                TransferHelper.safeTransfer(_currency, _to, _amount);
            }
            treasuryFee[_currency] = treasuryFee[_currency] - _amount;
        } else {
            require(preyEarnedFromSpin >= _amount, "ERR: Insufficient Spin Premium");
            require(
                IERC20Upgradeable(paymentCurrency).balanceOf(address(this)) >= _amount,
                "ERR: Insufficient Premium"
            );
            require(paymentCurrency == _currency, "ERR: not payment currency");
            TransferHelper.safeTransfer(_currency, _to, _amount);
            preyEarnedFromSpin = preyEarnedFromSpin - _amount;
        }
        emit LogPremiumWithdraw(_currency, _to, _amount);
    }

    function withdrawAllPremium(address _currency, address _to) external onlyOwner nonReentrant {
        if (_currency == address(0)) {
            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                TransferHelper.safeTransferETH(_to, ethBalance);
                treasuryFee[address(0)] = 0;
                emit LogPremiumWithdraw(_currency, _to, ethBalance);
            }
        } else if (_currency != address(0)) {
            uint256 preyBalance = IERC20Upgradeable(_currency).balanceOf(address(this));
            if (preyBalance > 0) {
                TransferHelper.safeTransfer(paymentCurrency, _to, preyBalance);
                treasuryFee[paymentCurrency] = 0;
                preyEarnedFromSpin = 0;
                emit LogPremiumWithdraw(_currency, _to, preyBalance);
            }
        }
    }

    /** OTHER */

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        // require(from == address(0x0), "ERR: Cannot send tokens to staking directly");
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721NFT {
    enum TokenType {
        Prey,
        Predator
    }

    enum GenType {
        Gen1,
        Gen2
    }

    struct NFTMetaData {
        TokenType tokenType;
        GenType genType;
        uint256 predatorType;
    }

    struct NFTAttribute {
        uint256 multiplier;
        uint256 unstaking;
        uint256 claim;
        uint256 double;
    }

    function maxSupply() external view returns (uint256);

    function nftMinted() external view returns (uint256);

    function maxSupplyGen1() external view returns (uint256);

    function mint(address _to) external returns (uint256 tokenId);

    function setAttribute(
        uint256 _tokenId,
        uint256 _multiplier,
        uint256 _unstaking,
        uint256 _claim,
        uint256 _double
    ) external;

    function getTokenType(uint256 _tokenId) external view returns (TokenType);

    function getTokenGenType(uint256 _tokenId) external view returns (GenType);

    function getTokenSubType(uint256 _tokenId) external view returns (uint256);

    function getNftAttribute(uint256 _tokenId) external view returns (NFTAttribute memory);

    function getMintedAmountPerType(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}