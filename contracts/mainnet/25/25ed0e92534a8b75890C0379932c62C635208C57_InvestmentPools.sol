// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
            "Initializable: contract is already initialized"
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
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
        require(_initializing, "Initializable: contract is not initializing");
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface InvestmentPoolsInterface {
    function getUserBalancePerPool(
        address addr,
        uint256 poolId
    ) external view returns (uint256);

    function getAmountRaisedPerPool(
        uint256 poolId
    ) external view returns (uint256);

    function creatorPerPoolId(uint256 poolId) external view returns (address);

    function checkIfUserHasInvestedInPoolId(
        address user,
        uint256 poolId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface TokenSaleInterface {
    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

// https://twitter.com/dealmpoker1
// https://discord.gg/hdgaZUqBSs
// https://t.me/+OZenwkiHEpliOGY0
// https://www.facebook.com/dealmpoker

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./storage/InvestmentPoolsStorage.sol";
import "./interfaces/TokenSaleInterface.sol";

contract InvestmentPools is
    Initializable,
    OwnableUpgradeable,
    InvestmentPoolsStorage
{
    modifier onlyController() {
        require(controller[msg.sender] == true, "Caller is not controller");
        _;
    }

    modifier isDmpNftHolder() {
        require(
            IERC721(dmpNftContractAddress).balanceOf(msg.sender) > 0,
            "You don't hold DMP Nft"
        );
        _;
    }

    function initialize() public initializer {
        protocolFeePercentage = 5;
        __Ownable_init();
    }

    function createPool(
        uint256 amount,
        uint256 date,
        uint256 markUp,
        uint256 entryFee,
        string memory tournamentType,
        string memory description
    ) public isDmpNftHolder {
        require(date > block.timestamp, "The pool is expired!");
        require(
            markUp >= 1e18,
            "Markup should be greater than 1, or equal to 1"
        );
        require(
            bannedUsersMapping[msg.sender] == false,
            "Banned - You can't create a pool"
        );

        pools.push(
            Pools(
                msg.sender,
                amount,
                uint256(0),
                date,
                totalPools,
                markUp,
                tournamentType,
                description,
                false,
                false,
                false,
                false
            )
        );

        tournamentEntryFeePerPoolId[totalPools] = entryFee;

        uint256 toDlmPrice = amount *
            TokenSaleInterface(tokenSaleContractAddress).getPrice();

        uint256 protocolFeeAmount = (toDlmPrice * protocolFeePercentage) / 100;

        IERC20(feeTokenAddress).transferFrom(
            msg.sender,
            address(this),
            protocolFeeAmount
        );

        creatorFeePerPool[totalPools] = protocolFeeAmount;

        totalPools++;

        emit InvestmentPoolCreated(
            msg.sender,
            totalPools - 1,
            amount,
            block.timestamp,
            date,
            description
        );
    }

    function investInPool(uint256 poolId, uint256 amount) public {
        require(amount > 1e15, "Amount too low");
        require(
            amount + pools[poolId].amountRaised <= pools[poolId].targetAmount,
            "Amount too big"
        );
        require(
            pools[poolId].endTimestamp > block.timestamp,
            "The pool is expired!"
        );
        require(pools[poolId].claimed == false, "The pool is claimed!");
        require(pools[poolId].canceled == false, "The pool is canceled!");
        require(pools[poolId].validated == true, "The pool is not validated!");

        IERC20(paymentTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        investorsPerPoolId[poolId].push(InvestorsPerPool(msg.sender, amount));
        investments.push(Investments(msg.sender, amount, poolId));
        userBalancePerPool[poolId][msg.sender] += amount;
        userHaveInvestedInPoolId[msg.sender][poolId] = true;

        pools[poolId].amountRaised += amount;

        emit PoolInvestment(msg.sender, poolId, amount, block.timestamp);
    }

    function removeInvestmentFromPool(uint256 poolId) public {
        require(
            userBalancePerPool[poolId][msg.sender] > 0,
            "You have not invested in this pool!"
        );
        require(pools[poolId].claimed == false, "The pool is already claimed!");
        require(
            pools[poolId].canceled == false,
            "The pool is already canceled!"
        );

        require(
            pools[poolId].endTimestamp < block.timestamp,
            "The pool is not expired!"
        );

        IERC20(paymentTokenAddress).transfer(
            msg.sender,
            userBalancePerPool[poolId][msg.sender]
        );
        pools[poolId].amountRaised -= userBalancePerPool[poolId][msg.sender];
        userBalancePerPool[poolId][msg.sender] = 0;
    }

    function claimAndCancelPool(uint256 poolId) public {
        require(
            pools[poolId].creator == msg.sender,
            "You are not the pool creator!"
        );
        require(pools[poolId].claimed == false, "The pool is already claimed!");
        require(
            pools[poolId].canceled == false,
            "The pool is already canceled!"
        );

        require(
            pools[poolId].endTimestamp > block.timestamp,
            "The pool is expired!"
        );
        require(pools[poolId].amountRaised > 0, "Pool is empty!");

        if (pools[poolId].amountRaised > 0) {
            IERC20(paymentTokenAddress).transfer(
                msg.sender,
                pools[poolId].amountRaised
            );
        }

        pools[poolId].claimed = true;
        pools[poolId].canceled = true;

        emit PoolClaimed(
            msg.sender,
            poolId,
            pools[poolId].amountRaised,
            block.timestamp
        );
    }

    function cancelPool(uint256 poolId) public {
        require(
            pools[poolId].creator == msg.sender,
            "You are not the pool creator!"
        );
        require(
            pools[poolId].canceled == false,
            "The pool is already canceled!"
        );
        require(pools[poolId].validated == false, "Can't cancel valid pool!");
        require(pools[poolId].rejected == false, "Can't cancel rejected pool!");

        IERC20(feeTokenAddress).transfer(msg.sender, creatorFeePerPool[poolId]);

        pools[poolId].canceled = true;

        emit PoolCanceled(
            msg.sender,
            poolId,
            creatorFeePerPool[poolId],
            block.timestamp
        );
    }

    function setProfileDescription(
        address to,
        string memory profileDesc
    ) public isDmpNftHolder {
        require(msg.sender == to, "You can't set profile description");
        profileDescription[to] = profileDesc;
    }

    function setProfilePicture(
        address to,
        string memory profilePic
    ) public isDmpNftHolder {
        require(msg.sender == to, "You can't set profile picture");
        profilePicture[to] = profilePic;
    }

    function validatePool(uint256 poolId) external virtual onlyController {
        require(!pools[poolId].validated, "Already validated!");

        IERC20(feeTokenAddress).transfer(
            protocolFeeReceiver,
            creatorFeePerPool[poolId]
        );

        pools[poolId].validated = true;
    }

    function rejectPool(uint256 poolId) external virtual onlyController {
        require(!pools[poolId].rejected, "Already rejected!");
        require(!pools[poolId].validated, "Already validated!");
        require(!pools[poolId].canceled, "Already canceled!");
        require(!pools[poolId].claimed, "Already claimed!");

        IERC20(feeTokenAddress).transfer(
            pools[poolId].creator,
            creatorFeePerPool[poolId]
        );

        pools[poolId].rejected = true;
    }

    function getUserBalancePerPool(
        address addr,
        uint256 poolId
    ) external view override returns (uint256) {
        return userBalancePerPool[poolId][addr];
    }

    function getAmountRaisedPerPool(
        uint256 poolId
    ) external view override returns (uint256) {
        return pools[poolId].amountRaised;
    }

    function creatorPerPoolId(
        uint256 poolId
    ) external view override returns (address) {
        return pools[poolId].creator;
    }

    function checkIfUserHasInvestedInPoolId(
        address user,
        uint256 poolId
    ) external view override returns (bool) {
        return userHaveInvestedInPoolId[user][poolId];
    }

    function setDmpNftContractAddress(
        address newDmpNftContractAddress
    ) external virtual onlyController {
        dmpNftContractAddress = newDmpNftContractAddress;
    }

    function setTokenSaleContractAddress(
        address _newTokenSaleContractAddress
    ) external virtual onlyController {
        tokenSaleContractAddress = _newTokenSaleContractAddress;
    }

    function setFeeTokenAddress(
        address _newFeeTokenAddress
    ) external virtual onlyController {
        feeTokenAddress = _newFeeTokenAddress;
    }

    function setPaymentTokenAddress(
        address _newPaymentTokenAddress
    ) external virtual onlyController {
        paymentTokenAddress = _newPaymentTokenAddress;
    }

    function setProtocolFeeReceiver(
        address _newProtocolFeeReceiver
    ) external virtual onlyController {
        protocolFeeReceiver = _newProtocolFeeReceiver;
    }

    function setProtocolFeePercentage(
        uint256 _newProtocolFeePercentage
    ) external virtual onlyController {
        protocolFeePercentage = _newProtocolFeePercentage;
    }

    function banUnban(
        address _addr,
        bool _value
    ) external virtual onlyController {
        bannedUsersMapping[_addr] = _value;
    }

    function setController(
        address _addr,
        bool _value
    ) external virtual onlyOwner {
        controller[_addr] = _value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../interfaces/InvestmentPoolsInterface.sol";

abstract contract InvestmentPoolsStorage is InvestmentPoolsInterface {
    uint256 public totalPools;

    uint256 public protocolFeePercentage;

    address public dmpNftContractAddress;

    address public tokenSaleContractAddress;

    address public paymentTokenAddress;

    address public feeTokenAddress;

    address public protocolFeeReceiver;

    mapping(address => bool) public controller;

    mapping(address => bool) public bannedUsersMapping;

    mapping(uint256 => uint256) public creatorFeePerPool;

    mapping(uint256 => uint256) public tournamentEntryFeePerPoolId;

    mapping(uint256 => mapping(address => uint256)) public userBalancePerPool;

    mapping(address => mapping(uint256 => bool))
        public userHaveInvestedInPoolId;

    mapping(uint256 => InvestorsPerPool[]) public investorsPerPoolId;

    mapping(address => string) public profileDescription;

    mapping(address => string) public profilePicture;

    struct InvestorsPerPool {
        address user;
        uint256 amount;
    }

    Investments[] public investments;

    struct Investments {
        address user;
        uint256 amount;
        uint256 poolId;
    }

    Pools[] public pools;

    struct Pools {
        address creator;
        uint256 targetAmount;
        uint256 amountRaised;
        uint256 endTimestamp;
        uint256 poolId;
        uint256 markUp;
        string tournamentType;
        string description;
        bool claimed;
        bool canceled;
        bool validated;
        bool rejected;
    }

    /// @dev Events
    event InvestmentPoolCreated(
        address account,
        uint256 poolId,
        uint256 amount,
        uint256 createdTimestamp,
        uint256 endTimestamp,
        string description
    );

    event PoolClaimed(
        address account,
        uint256 poolId,
        uint256 amountRaised,
        uint256 claimedTimetamp
    );

    event PoolCanceled(
        address account,
        uint256 poolId,
        uint256 feeReturned,
        uint256 canceledTimetamp
    );

    event PoolInvestment (
        address account,
        uint256 poolId,
        uint256 amountInvested,
        uint256 investmentTimetamp
    );
}