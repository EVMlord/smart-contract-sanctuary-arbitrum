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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../interfaces/ILendVault.sol";
import "../interfaces/IBorrower.sol";
import "../interfaces/IReserve.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/IAddressProvider.sol";
import "../interfaces/IWETH.sol";
import "../libraries/AddressArray.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/BlockNonEOAUpgradeable.sol";
import "../utils/ReentrancyGuardUpgradeable.sol";
import "../utils/AccessControl.sol";
import "./LendVaultStorage.sol";
import "../interfaces/IRewards.sol";

/**
 * @notice LendVault manages the lending of multiple tokens
 * @dev In order to allow a token to be deposited and borrowed:
 * - initializeToken needs to be called with IRM data for the tokens that will be used
 * - setCreditLimits needs to be called to allow borrowers to borrow the tokens
 * - Non EOA accounts are blocked by default, setWhitelistUsers needs to be called to allow contract accounts to make transactions
 */
contract LendVault is 
    ILendVault,
    ERC1155Upgradeable,
    AccessControl,
    BlockNonEOAUpgradeable,
    ReentrancyGuardUpgradeable,
    LendVaultStorage 
{
    using SafeERC20 for IERC20;
    using AddressArray for address[];
    using Address for address;

    /**
     * @notice Initializes the upgradeable contract with the provided parameters
     */
    function initialize(address _addressProvider, uint _healthThreshold, uint _maxUtilization, uint _slippage, uint _deleverFee) external initializer {
        __ERC1155_init("LendVault");
        __BlockNonEOAUpgradeable_init(_addressProvider);
        __AccessControl_init(_addressProvider);
        __ReentrancyGuard_init();
        require(_slippage<=PRECISION, "E12");
        require(_deleverFee<=1e18, "E33");
        require(_maxUtilization<=PRECISION, "E36");
        healthThreshold = _healthThreshold;
        maxUtilization = _maxUtilization;
        slippage = _slippage;
        deleverFeeETH = _deleverFee;
        address[] memory initialWhitelist = new address[](1);
        initialWhitelist[0] = provider.reserve();
        bool[] memory allowed = new bool[](1);
        allowed[0] = true;
        setWhitelistUsers(initialWhitelist, allowed);
    }

    function _checkTokenInitialized(address token) internal view {
        require(irmData2[token].initialized, "E24");
    }

    modifier onlyWhitelistedBorrower(address token, address borrower) {
        require(borrowerWhitelist[token][borrower], "E31");
        _;
    }

    modifier tokenInitialized(address token) {
        _checkTokenInitialized(token);
        _;
    }

    /// @inheritdoc ILendVault
    function initializeToken(address token, IRMDataMultiSlope memory data) external restrictAccess(GOVERNOR) {
        for (uint i = 0; i<data.utilizationRates.length; i++) {
            require(data.utilizationRates[i]<=10*PRECISION, "E25");
        }
        for (uint i = 0; i<data.slopes.length; i++) {
            require(data.slopes[i]<=10*PRECISION, "E27");
        }
        require(data.baseBorrowRate<=10*PRECISION, "E26");
        require(data.utilizationRates.length==data.slopes.length-1, "E28");
        require(data.lendingPerformanceFee<=PRECISION, "E29");
        if (data.initialized && !supportedTokens.exists(token)) {
            supportedTokens.push(token);
        }
        if (!data.initialized) {
            uint index = supportedTokens.findFirst(token);
            if (index<supportedTokens.length) {
                supportedTokens[index] = supportedTokens[supportedTokens.length-1];
                supportedTokens.pop();
            }
        }
        irmData2[token] = data;
    }

    // ---------- Owner Functions ----------

    /// @inheritdoc ILendVault
    function setBorrowerWhitelist(address borrower, address token, bool allowBorrow) external restrictAccess(GOVERNOR) tokenInitialized(token) {
        borrowerWhitelist[token][borrower] = allowBorrow;
        if (allowBorrow) {
            // Add borrower to list of borrowers for token
            if (!tokenBorrowers[token].exists(borrower)) {
                tokenBorrowers[token].push(borrower);
            }

            // Add token to list of borrowed tokens for borrower
            if (!borrowerTokens[borrower].exists(token)) {
                borrowerTokens[borrower].push(token);
            }
        } else {
            // Remove borrower if credit limit is 0
            uint borrowerIndex = tokenBorrowers[token].findFirst(borrower);
            if (borrowerIndex<tokenBorrowers[token].length) {
                tokenBorrowers[token][borrowerIndex] = tokenBorrowers[token][tokenBorrowers[token].length-1];
                tokenBorrowers[token].pop();
            }

            // Remove token if credit limit is 0
            uint tokenIndex = borrowerTokens[borrower].findFirst(token);
            if (tokenIndex<borrowerTokens[borrower].length) {
                borrowerTokens[borrower][tokenIndex] = borrowerTokens[borrower][borrowerTokens[borrower].length-1];
                borrowerTokens[borrower].pop();
            }
        }
    }
    
    /// @inheritdoc ILendVault
    function setHealthThreshold(uint _healthThreshold) external restrictAccess(GOVERNOR) {
        healthThreshold = _healthThreshold;
    }
    
    /// @inheritdoc ILendVault
    function setMaxUtilization(uint _maxUtilization) external restrictAccess(GOVERNOR) {
        require(_maxUtilization<=PRECISION, "E36");
        maxUtilization = _maxUtilization;
    }
    
    /// @inheritdoc ILendVault
    function setSlippage(uint _slippage) external restrictAccess(GOVERNOR) {
        require(_slippage<=PRECISION, "E12");
        slippage = _slippage;
    }
    
    /// @inheritdoc ILendVault
    function setDeleverFee(uint _deleverFee) external restrictAccess(GOVERNOR) {
        require(_deleverFee<=1e18, "E33");
        deleverFeeETH = _deleverFee;
    }

    // ---------- View Functions ----------

    /// @inheritdoc ILendVault
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokens.copy();
    }
    
    /// @inheritdoc ILendVault
    function getBorrowerTokens(address borrower) external view returns (address[] memory tokens, uint[] memory amounts) {
        tokens = borrowerTokens[borrower].copy();
        amounts = new uint[](tokens.length);
        for (uint i = 0; i<tokens.length; i++) {
            amounts[i] = getDebt(tokens[i], borrower);
        }
    }

    /// @inheritdoc ILendVault
    function getTokenBorrowers(address token) external view returns (address[] memory borrowers, uint[] memory amounts) {
        borrowers = tokenBorrowers[token].copy();
        amounts = new uint[](borrowers.length);
        for (uint i = 0; i<borrowers.length; i++) {
            amounts[i] = getDebt(token, borrowers[i]);
        }
    }

    /// @inheritdoc ILendVault
    function balanceOf(address lender, address token) public view returns (uint shares) {
        shares = balanceOf(lender, uint(keccak256(abi.encodePacked(token))));
    }

    /// @inheritdoc ILendVault
    function tokenBalanceOf(address lender, address token) external view returns (uint amount) {        
        uint shares = balanceOfWithRewards(lender, token);
        uint totalTokens = totalAssets(token);
        amount = totalTokens * shares / Math.max(1, tokenData[token].totalShares);
    }
 
    /// @inheritdoc ILendVault
    function utilizationRate(address token) public view returns (uint utilization) {
        uint totalTokenAmount = totalAssets(token);
        uint totalDebt = getTotalDebt(token);
        return (totalDebt * PRECISION) / Math.max(1, totalTokenAmount);
    }

    /// @inheritdoc ILendVault
    function totalAssets(address token) public view returns (uint amount) {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        uint totalDebt = getTotalDebt(token);
        amount = tokenBalance + totalDebt;
    }

    /// @inheritdoc ILendVault
    function convertToShares(address token, uint amount) public view returns (uint shares) {
        uint totalTokenAmount = totalAssets(token);
        return Math.max(1, tokenData[token].totalShares) * amount / Math.max(1, totalTokenAmount);
    }

    /// @inheritdoc ILendVault
    function convertToAssets(address token, uint shares) public view returns (uint amount) {
        uint totalTokenAmount = totalAssets(token);
        return Math.max(1, totalTokenAmount) * shares / Math.max(1, tokenData[token].totalShares);
    }

    /// @inheritdoc ILendVault
    function getTotalDebt(address token) public view returns (uint totalDebt) {
        uint elapsedTime = block.timestamp - tokenData[token].lastInterestRateUpdate;
        uint interestAccrued = (tokenData[token].totalDebt * tokenData[token].interestRate * elapsedTime) / (PRECISION * 365 days);
        totalDebt = tokenData[token].totalDebt + interestAccrued;
    }

    /// @inheritdoc ILendVault
    function getDebt(address token, address borrower) public view returns (uint debt) {
        uint totalDebt = getTotalDebt(token);
        uint borrowerDebtShare = debtShare[token][borrower];
        debt = (borrowerDebtShare*totalDebt)/Math.max(1, tokenData[token].totalDebtShares);
    }

    /// @inheritdoc ILendVault
    function getInterestRates(address token) external view returns (uint supplyInterestRate, uint borrowInterestRate) {
        borrowInterestRate = tokenData[token].interestRate;
        uint totalTokenAmount = IERC20(token).balanceOf(address(this)) + tokenData[token].totalDebt;
        uint prevUtilizationRate = (tokenData[token].totalDebt * PRECISION) / Math.max(1, totalTokenAmount);
        supplyInterestRate = (PRECISION - irmData2[token].lendingPerformanceFee) * (prevUtilizationRate * borrowInterestRate / PRECISION) / PRECISION;
    }

    /// @inheritdoc ILendVault
    function checkHealth(address borrower) external view returns (int health) {
        address[] memory tokens = new address[](borrowerTokens[borrower].length);   // Tokens borrowed by borrower
        uint[] memory amounts = new uint[](borrowerTokens[borrower].length);        // Debt amounts for borrowed tokens
        (address[] memory availableTokens, uint[] memory availableAmounts) = IBorrower(borrower).getAmounts();
        uint totalETHValue = ISwapper(provider.swapper()).getETHValue(availableTokens, availableAmounts);

        for (uint i = 0; i<borrowerTokens[borrower].length; i++) {
            address token = borrowerTokens[borrower][i];
            uint debt = getDebt(token, borrower);
            tokens[i] = token;
            amounts[i] = debt;
        }
        uint debtETHValue = ISwapper(provider.swapper()).getETHValue(tokens, amounts);
        health = (int(totalETHValue)-int(debtETHValue))*int(PRECISION)/int(Math.max(1, debtETHValue));
    }

    /// @inheritdoc ILendVault
    function balanceOfWithRewards(address _user, address _token) public view returns (uint256 userBalance){
        userBalance += balanceOf(_user, _token);
        IRewards rewards = IRewards(provider.rewardDistribution());        
        try rewards.balanceOf(address(this), _user, true, address(_token)) {
            userBalance += rewards.balanceOf(address(this), _user, true, address(_token));
        }catch{}                
    }    

    // ---------- Lender/Borrower Functions ----------

    /// @inheritdoc ILendVault
    function deposit(address token, uint amount) external payable onlyEOA nonReentrant tokenInitialized(token) trackInterestAndFee(token) {
        uint shares = convertToShares(token, amount + msg.value);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        require(!(token!=provider.networkToken() && msg.value>0), "Wrong token");
        if(msg.value>0) {
            IWETH networkToken = IWETH(payable(provider.networkToken()));
            networkToken.deposit{value: msg.value}();
        }
        _mint(msg.sender, uint(keccak256(abi.encodePacked(token))), shares, "");
        tokenData[token].totalShares += shares;

        // Repay the funds borrowed from the reserve to provide instant liquidity
        uint reserveShares = balanceOf(provider.reserve(), token);
        if (reserveShares>0) {
            uint sharesToBurn = Math.min(reserveShares, shares);
            uint amountReturned = convertToAssets(token, sharesToBurn);
            _burn(provider.reserve(), uint(keccak256(abi.encodePacked(token))), sharesToBurn);
            tokenData[token].totalShares -= sharesToBurn;
            IERC20(token).safeTransfer(provider.reserve(), amountReturned);
        }

        //Auto emit rewards        
        IRewards rewards = IRewards(provider.rewardDistribution());
        (, bool poolExists) = rewards.getPoolId(address(this), true, address(token));
        if(poolExists){
             setApprovalForAll(provider.rewardDistribution(), true);        
            try rewards.deposit(address(this), shares, msg.sender, true, address(token)){} catch {}                        
        }
       
        emit Deposit(token, msg.sender, amount + msg.value, shares);
    }

    /// @inheritdoc ILendVault
    function withdrawShares(address token, uint shares) external onlyEOA nonReentrant tokenInitialized(token) trackInterestAndFee(token) {
         IRewards rewards = IRewards(provider.rewardDistribution());  
         (, bool poolExists) = rewards.getPoolId(address(this), true, address(token));
         if(poolExists){
            uint256 balanceInRewards = rewards.balanceOf(address(this), msg.sender, true, address(token));         
            if(balanceInRewards > 0){
                try rewards.withdraw(address(this), shares, msg.sender, true, address(token)){} catch {}            
            }    
         }
        
        _withdraw(token, shares);       
    }

    /// @inheritdoc ILendVault
    function withdrawAmount(address token, uint amount) external onlyEOA nonReentrant tokenInitialized(token) trackInterestAndFee(token) {
        uint shares = convertToShares(token, amount);
        IRewards rewards = IRewards(provider.rewardDistribution());   
        (, bool poolExists) = rewards.getPoolId(address(this), true, address(token));
        if(poolExists){
            if(rewards.balanceOf(address(this), msg.sender, true, address(token)) > 0){
                try rewards.withdraw(address(this), shares, msg.sender, true, address(token)){} catch {}
            }  
        }
        _withdraw(token, shares);
    }

    /// @inheritdoc ILendVault
    function withdrawMax(address token) external onlyEOA nonReentrant tokenInitialized(token) trackInterestAndFee(token) {
        uint shares = balanceOfWithRewards(msg.sender, token);            
        IRewards rewards = IRewards(provider.rewardDistribution());   
        (, bool poolExists) = rewards.getPoolId(address(this), true, address(token));
        if(poolExists){
            if(rewards.balanceOf(address(this), msg.sender, true, address(token)) > 0){
                try rewards.withdraw(address(this), shares, msg.sender, true, address(token)){} catch {}
            }  
        }
        _withdraw(token, shares);
    }

    /// @inheritdoc ILendVault
    function borrow(address token, uint amount) external nonReentrant tokenInitialized(token) onlyWhitelistedBorrower(token, msg.sender) trackInterestAndFee(token) {
        uint shares = Math.max(1, tokenData[token].totalDebtShares) * amount / Math.max(1, tokenData[token].totalDebt);
        tokenData[token].totalDebt += amount;
        tokenData[token].totalDebtShares += shares;
        debtShare[token][msg.sender] += shares;
        IERC20(token).safeTransfer(msg.sender, amount);

        require(utilizationRate(token)<=maxUtilization, "E34");

        emit Borrow(token, msg.sender, amount, shares);
    }

    /// @inheritdoc ILendVault
    function repayShares(address token, uint shares) external nonReentrant tokenInitialized(token) trackInterestAndFee(token) {
        _repay(token, shares);
    }

    /// @inheritdoc ILendVault
    function repayAmount(address token, uint amount) external nonReentrant tokenInitialized(token) trackInterestAndFee(token) {
        uint shares = amount*Math.max(1, tokenData[token].totalDebtShares)/Math.max(1, tokenData[token].totalDebt);
        _repay(token, shares);
    }

    /// @inheritdoc ILendVault
    function repayMax(address token) external nonReentrant tokenInitialized(token) trackInterestAndFee(token) {
        uint balance = IERC20(token).balanceOf(msg.sender);
        uint debt = (debtShare[token][msg.sender] * tokenData[token].totalDebt) / Math.max(1, tokenData[token].totalDebtShares);
        uint sharesToRepay = Math.min(balance * debtShare[token][msg.sender]/Math.max(1, debt), debtShare[token][msg.sender]);
        _repay(token, sharesToRepay);
    }

    /// @inheritdoc ILendVault
    function kill(address borrower) external {
        provider.borrowerManager().functionDelegateCall(abi.encodeWithSignature("kill(address)", borrower));
    }

    // ---------- Internal Helper Functions ----------

    modifier trackInterestAndFee(address token) {
        _lendingPerformanceFee(token);
        _;
        _updateInterestRate(token);
    }

    function _lendingPerformanceFee(address token) internal {
        uint prevDebt = tokenData[token].totalDebt;
        _updateInterestRate(token);
        uint debtGrowth = tokenData[token].totalDebt - prevDebt;
        uint lenderInterest = (PRECISION - irmData2[token].lendingPerformanceFee) * debtGrowth / PRECISION;
        uint fee = debtGrowth - lenderInterest;
        if (IERC20(token).balanceOf(address(this))>fee) {
            IERC20(token).safeTransfer(provider.reserve(), fee);
        } else {
            uint shares = Math.max(1, tokenData[token].totalShares) * fee / Math.max(1, totalAssets(token) - fee);
            _mint(provider.reserve(), uint(keccak256(abi.encodePacked(token))), shares, "");
            tokenData[token].totalShares += shares;
        }
    }

    function _updateInterestRate(address token) internal {
        provider.borrowerManager().functionDelegateCall(abi.encodeWithSignature("updateInterestRate(address)", token));
    }

    function _repay(address token, uint shares) internal {
        uint amount = shares*tokenData[token].totalDebt/Math.max(1, tokenData[token].totalDebtShares);
        tokenData[token].totalDebt -= amount;
        tokenData[token].totalDebtShares -= shares;
        debtShare[token][msg.sender] -= shares;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(token, msg.sender, amount, shares);
    }

    function _withdraw(address token, uint shares) internal {
        uint amount = convertToAssets(token, shares);
        _burn(msg.sender, uint(keccak256(abi.encodePacked(token))), shares);
        uint balance = IERC20(token).balanceOf(address(this));
        tokenData[token].totalShares -= shares;

        uint fee;
        if (amount<=balance) {
            IERC20(token).safeTransfer(msg.sender, amount);
        } else {
            uint extraTokens = amount - balance;
            uint fundsReceived = IReserve(provider.reserve()).requestFunds(token, extraTokens);
            if (fundsReceived<extraTokens) {
                bytes memory returnData = provider.borrowerManager().functionDelegateCall(
                    abi.encodeWithSignature("delever(address,uint256)", token, extraTokens-fundsReceived)
                );
                fee = abi.decode(returnData, (uint));
                amount-=fee;
            }
            IERC20(token).safeTransfer(msg.sender, amount);
            
            uint totalTokenAmount = totalAssets(token) - fundsReceived;
            uint reserveShares;
            if (totalTokenAmount>0) {
                reserveShares = (tokenData[token].totalShares * fundsReceived) / totalTokenAmount;
            } else {
                reserveShares = fundsReceived;
            }
            tokenData[token].totalShares += reserveShares;
            
            _mint(provider.reserve(), uint(keccak256(abi.encodePacked(token))), reserveShares, "");
        }
        emit Withdraw(token, msg.sender, amount, shares, fee);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../interfaces/ILendVault.sol";
import "../interfaces/IAddressProvider.sol";
import "../interfaces/ILendVaultStorage.sol";

contract LendVaultStorage is ILendVaultStorage {

    /// @notice Token data for each token
    mapping (address=>TokenData) public tokenData;

    /// @notice Interest rate model data for each token
    mapping (address=>IRMData) public irmData;

    /// @notice Mapping from token to borrower to share of total debt
    /// @dev debtShare is calculated as: debtShare = debt*PRECISION/totalDebt
    mapping (address=>mapping(address=>uint)) public debtShare;

    /// @notice Mapping from token to borrower to amount of tokens that can be borrowed
    /// @dev The credit limit represents the fraction of tokens that a borrower can borrow
    /// @dev Sum of all credit limits for a token should be less than PRECISION
    mapping (address=>mapping(address=>uint)) public creditLimits;

    /// @notice Mapping from borrowers to the list of tokens that they have borrowed or can borrow
    mapping (address=>address[]) public borrowerTokens;

    /// @notice mapping from tokens to addresses that have borrowed or can borrow the token
    mapping (address=>address[]) public tokenBorrowers;

    /// @notice Array of all tokens that have been initialized
    address[] public supportedTokens;

    /// @notice The minimum health that a borrower must have in order to not have its funds siezed
    uint public healthThreshold;

    /// @notice Max utilization rate that can be reached beyond which borrowing will be reverted
    uint public maxUtilization;

    /// @notice Slppage used when using swapper
    uint public slippage;

    /// @notice Fee charged to a lender for withdrawing a large amount that requires the strategies to be delevered
    /// @dev The fee will be used as gas fee for the transactions to adjust the leverage of the strategies by the keeper
    uint public deleverFeeETH;

    /// @notice Mapping from tokens to borrowers to whitelist status
    mapping(address=>mapping(address=>bool)) public borrowerWhitelist;
    
    /// @notice Interest rate model data for each token
    mapping (address=>IRMDataMultiSlope) public irmData2;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IAddressProvider {
    
    function networkToken() external view returns (address);
    function usdc() external view returns (address);
    function usdt() external view returns (address);
    function dai() external view returns (address);
    function swapper() external view returns (address);
    function reserve() external view returns (address);
    function lendVault() external view returns (address);
    function borrowerManager() external view returns (address);
    function oracle() external view returns (address);
    function uniswapV3Integration() external view returns (address);
    function uniswapV3StrategyData() external view returns (address);
    function uniswapV3StrategyMigrator() external view returns (address);
    function uniswapV3StrategyLogic() external view returns (address);
    function borrowerBalanceCalculator() external view returns (address);
    function keeper() external view returns (address);
    function governance() external view returns (address);
    function guardian() external view returns (address);
    function controller() external view returns (address);
    function vaults(uint index) external view returns (address);
    function getVaults() external view returns (address[] memory);
    function rewardDistribution() external view returns (address);
    function rewardToken() external view returns (address);

    function setNetworkToken(address token) external;
    function setUsdc(address token) external;
    function setUsdt(address token) external;
    function setDai(address token) external;
    function setReserve(address _reserve) external;
    function setSwapper(address _swapper) external;
    function setLendVault(address _lendVault) external;
    function setBorrowerManager(address _manager) external;
    function setOracle(address _oracle) external;
    function setUniswapV3Integration(address _integration) external;
    function setUniswapV3StrategyData(address _address) external;
    function setUniswapV3StrategyLogic(address _logic) external;
    function setUniswapV3StrategyMigrator(address _migrator) external;
    function setKeeper(address _keeper) external;
    function setGovernance(address _governance) external;
    function setGuardian(address _guardian) external;
    function setController(address _controller) external;
    function addVault(address _vault) external;
    function removeVault(address _vault) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBorrower {

    /**
     * @notice Returns the equity value of the strategy in terms of its stable token
     * @dev balance can be negative, indicating how much excess debt there is
     */
    function balance() external view returns (int balance);

    /**
     * @notice Returns the value of all the assets in the borrower's possession expressed
     * in terms of the borrower's vault's deposit token
     */
    function tvl() external view returns (uint currentTvl);

    /**
     * @notice Calculate the max amount of stable token that can be supplied and
     * the corresponding amount of stable and volatile tokens that will be borrowed
     * from the LendVault
     */
    function getDepositableAndBorrowables() external view returns (uint depositable, address[] memory tokens, uint[] memory borrowables);

    /**
     * @notice Returns cached balance if balance has previously been calculated
     * otherwise sets the cache with newly calculated balance
     */
    function balanceOptimized() external returns (int balance);

    /**
     * @notice Returns all the tokens in the borrower's posession after liquidating everything
     */
    function getAmounts() external view returns (address[] memory tokens, uint[] memory amounts);
    
    /**
     * @notice Returns all the tokens borrowed
     */
    function getDebts() external view returns (address[] memory tokens, uint[] memory amounts);

    /**
     * @notice Copy the old contract state
     */
    function migrate(address oldStrategyAddress) external;

    /**
     * @notice Use migrator contract to reset pnl trackers
     */
    function resetPnlData() external;

    /**
     * @notice Function to liquidate everything and transfer all funds to LendVault
     * @notice Called in case it is believed that the borrower won't be able to cover its debts
     * @return tokens Siezed tokens
     * @return amounts Amounts of siezed tokens
     */
    function siezeFunds() external returns (address[] memory tokens, uint[] memory amounts);

    /**
     * @notice Updates all tracked variables that are used in pnl calculation
     * @dev This funciton was introduced such that the LendVault can call it after siezing funds
     */
    function updateTrackers() external;

    /**
     * @notice Reduce leverage in order to pay back the specified debt
     * @param token Token that needs to be paid back
     * @param amount Amount of token that needs to be paid back
     */
    function delever(address token, uint amount) external;

    /**
     * @notice Exit liquidity position and repay all debts
     */
    function exit() external;

    /**
     * @notice Deposits all available funds into the appropriate liquidity position
     */
    function deposit() external;

    /**
     * @notice Permissioned function for controller to withdraw a token from the borrower
     */
    function withdrawOther(address token) external;

    /**
     * @notice Permissioned function called from controller or vault to withdraw to vault
     */
    function withdraw(uint256) external;

    /**
     * @notice Permissioned function called from controller or vault to withdraw all funds to vault
     */
    function withdrawAll() external;

    /**
     * @notice Harvest the rewards from the liquidity position, swap them and reinvest them
     */
    function harvest() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ILendVaultStorage.sol";

/**
* @param totalShares The total amount of shares that have been minted on the deposits of the token
* @param totalDebtShares The total number of debt shares that have been issued to borrowers of the token
* @param totalDebt The combined debt for the token from all borrowers
* @param totalDebtPaid The amount of total debt that has been paid for the token
* @param interestRate The current interest rate of the token
* @param lastInterestRateUpdate the last timestamp at which the interest rate was updated
* @param totalCreditLimit Sum of credit limits for all borrowers for the token
* @param lostFunds Funds lost due to borrowers defaulting
*/
struct TokenData {
    uint totalShares;
    uint totalDebtShares;
    uint totalDebt;
    uint interestRate;
    uint lastInterestRateUpdate;
    uint totalCreditLimit;
    uint lostFunds;
}

/**
* @notice Struct representing tokens siezed from a borrower and the debts that need to be paid
* @param borrowedTokens Tokens that have been borrowed and must be repaid
* @param debts Amounts of tokens borrowed
* @param siezedTokens Tokens siezed from borrower
* @param siezedAmounts Amounts of siezed tokens
*/
struct SiezedFunds {
    address[] borrowedTokens;
    uint[] debts;
    address[] siezedTokens;
    uint[] siezedAmounts;
}

/**
* @notice Data for a token needed to track debts
* @param initialized Flag to tell wether the data for the token has been initialized, only initialized tokens are allowed to be interacted with in this contract
* @param optimalUtilizationRate Ideal utilization rate for token
* @param baseBorrowRate The interest rate when utilization rate is 0
* @param slope1 The rate at which the interest rate grows with respect to utilization before utilization is greater than optimalUtilizationRate
* @param slope2 The rate at which the interest rate grows with respect to utilization after utilization is greater than optimalUtilizationRate
*/
struct IRMData {
    bool initialized;
    uint optimalUtilizationRate;
    uint baseBorrowRate;
    uint slope1;
    uint slope2;
}

struct IRMDataMultiSlope {
    bool initialized;
    uint[] utilizationRates;
    uint baseBorrowRate;
    uint[] slopes;
    uint lendingPerformanceFee;
}

interface ILendVault is ILendVaultStorage {
    
    /**
     * @notice Event emitted on a lender depositing tokens
     * @param token Token being deposited
     * @param lender Lender depositing the token
     * @param amount Number of tokens deposited
     * @param shares Number of shares minted
     */
    event Deposit(address indexed token, address indexed lender, uint amount, uint shares);

    /**
     * @notice Event emitted on a lender withdrawing tokens
     * @param token Token being withdrawn
     * @param lender Lender withdrawing the token
     * @param amount Number of tokens withdrawn
     * @param shares Number of shares burnt during the withdrawal
     * @param fee Amount of tokens used up as fee in case borrowers had to deleverage
     */
    event Withdraw(address indexed token, address indexed lender, uint amount, uint shares, uint fee);
    
    /**
     * @notice Event emitted when a borrower borrows
     * @param token Token being borrowed
     * @param borrower Address of the borrower
     * @param amount Number of tokens being borrowed
     * @param shares Number of debt shares minted
     */
    event Borrow(address indexed token, address indexed borrower, uint amount, uint shares);
    
    /**
     * @notice Event emitted when a borrower repays debt
     * @param token Token being repayed
     * @param borrower Address of the borrower
     * @param amount Number of tokens being repayed
     * @param shares Number of debt shares repayed
     */
    event Repay(address indexed token, address indexed borrower, uint amount, uint shares);
    
    /**
     * @notice Initializes the interest rate model data for a token based on provided data
     */
    function initializeToken(address token, IRMDataMultiSlope memory data) external;

    /**
     * @notice Whitelists or blacklists a borrower for a token
     * @param borrower Borrower whose access to borrowing needs to be modified
     * @param token The token to change borrowing access for
     * @param allowBorrow Wether the borrower should be allowed to borrow token or not
     */
    function setBorrowerWhitelist(address borrower, address token, bool allowBorrow) external;

    /**
     @notice Set health threshold
     */
    function setHealthThreshold(uint _healthThreshold) external;
    
    /**
     @notice Set maximum utilization rate beyond which further borrowing will be reverted
     */
    function setMaxUtilization(uint _maxUtilization) external;

    /**
     @notice Set slippage
     */
    function setSlippage(uint _slippage) external;
    
    /**
     @notice Set delever fee
     */
    function setDeleverFee(uint _deleverFee) external;

    /**
     * @notice Get list of supported tokens
     */
    function getSupportedTokens() external view returns (address[] memory);

    /**
     * @notice Get list of tokens and amounts currently borrowed by borrower
     * @return tokens The tokens that the borrower has borrowed or can borrow
     * @return amounts The amount of each borrowed token
     */
    function getBorrowerTokens(address borrower) external view returns (address[] memory tokens, uint[] memory amounts);
    
    /**
     * @notice Get list of borrowers and borrowed amounts for a token
     * @return borrowers The addresses that have borrowed or can borrow the token
     * @return amounts The amount borrowed by each borrower
     */
    function getTokenBorrowers(address token) external view returns (address[] memory borrowers, uint[] memory amounts);

    /**
     * @notice Returns the shares of a lender for a token
     */
    function balanceOf(address lender, address token) external view returns (uint shares);

    /**
     * @notice Get the balance from contract or reward contract staked
     * @param _user the user to consult
     * @param _token the balance of the token to consult
     * @return userBalance The balance of the user     
     */    
    function balanceOfWithRewards(address _user, address _token) external view returns (uint256 userBalance);    

    /**
     * @notice Returns the amount of tokens that belong to the lender based on the lenders shares
     */
    function tokenBalanceOf(address lender, address token) external view returns (uint amount);

    /**
     * @notice Returns the utilization rate for the provided token
     * @dev Utilization rate for a token is calculated as follows
     * - U_t = B_t/D_t
     * - where B_t is the total amount borrowed for the token and D_t is the total amount deposited for the token
     */
    function utilizationRate(address token) external view returns (uint utilization);

    /**
     * @notice Returns the current reserves for a token plus the combined debt that borrowers have for that token
     */
    function totalAssets(address token) external view returns (uint amount);

    /**
     * @notice Calculates the amount of shares that are equivalent to the provided amount of tokens
     * @dev shares = totalShares[token]*amount/totalAssets(token)
     */
    function convertToShares(address token, uint amount) external view returns (uint shares);

    /**
     * @notice Calculates the amount of tokens that are equivalent to the provided amount of shares
     * @dev amount = totalAssets(token)*shares/totalShares(token)
     */
    function convertToAssets(address token, uint shares) external view returns (uint tokens);

    /**
     * @notice Calculates the total debt of a token including accrued interest
     */
    function getTotalDebt(address token) external view returns (uint totalDebt);

    /**
     * @notice Get the current debt of a borrower for a token
     */
    function getDebt(address token, address borrower) external view returns (uint debt);

    /**
     * @notice Calculates and returns the supply and borrow interest rates calculated at the last transaction
     * @dev supplyInterestRate = utilizationRate * borrowInterestRate * (PRECISION - lendingPerformanceFee)
     */
    function getInterestRates(address token) external view returns (uint supplyInterestRate, uint borrowInterestRate);

    /**
     * @notice Get the health of the borrower
     * @dev health can be calculated approximated as:
     *      health = PRECISION*(totalETHValue-debtETHValue)/debtETHValue
     * @dev If a borrower can pay back nothing, health will be -PRECISION
     * @dev If a borrower can pay back exactly the debt and have nothing left, health will be 0
     */
    function checkHealth(address borrower) external view returns (int health);

    /**
     * @notice Accepts a deposit of a token from a user and mints corresponding shares
     * @dev The amount of shares minted are based on the convertToShares function
     */
    function deposit(address token, uint amount) external payable;
    
    /**
     * @notice Burns a user's shares corresponding to a token to redeem the deposited tokens
     * @dev The amount of tokens returned are based on the convertToAssets function
     * @dev In case the LendVault doesn't have enough tokens to pay back, funds will be requested from reserve
     * and tokens will be minted to the reserve corrseponding to how many tokens the reserve provides
     * @dev In case the reserve is unable to meet the demand, the BorrowerManager will delever the strategies
     * This will free up enough funds for the lender to withdraw
     * @dev A fee will also be charged in case deleveraging of borrowers is involved
     * This fee will be used as gas fee to re-optimize the ratio of leverages between borrowers
     */
    function withdrawShares(address token, uint shares) external;

    /**
     * @notice Similar to withdraw shares, but input is in amount of tokens
     */
    function withdrawAmount(address token, uint amount) external;

    /**
     * @notice Withdraws the entirety of a lender's deposit into the LendVault
     */
    function withdrawMax(address token) external;

    /**
     * @notice Function called by a whitelisted borrower to borrow a token
     * @dev For each borrower, debt share is recorded rather than debt amount
     * This makes it easy to accrue interest by simply increasing totalDebt
     * @dev Borrower debt can be calculated as: debt = debtShare*totalDebt/totalDebtShares
     * @param token Token to borrow from the vault
     * @param amount Amount of token to borrow
     */
    function borrow(address token, uint amount) external;

    /**
     * @notice Repay a borrowers debt of a token to the vault
     * @param token Token to repay to the vault
     * @param shares Debt shares to repay
     */
    function repayShares(address token, uint shares) external;

    /**
     * @notice Identical to repayShares, but input is in amount of tokens to repay
     */
    function repayAmount(address token, uint amount) external;

    /**
     * @notice Repays the max amount of tokens that the borrower can repay
     * @dev Repaid amount is calculated as the minimum of the borrower's balance
     * and the size of the borrower's debt
     */
    function repayMax(address token) external;

    /**
     * @notice Seize all the funds of a borrower to cover its debts and set its credit limit to 0
     * @dev Function will revert if the borrower's health is still above healthThreshold
     */
    function kill(address borrower) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ILendVaultStorage {

    function tokenData(address token) external view returns (uint, uint, uint, uint, uint, uint, uint);
    function irmData(address token) external view returns (bool, uint, uint, uint, uint);
    function debtShare(address token, address borrower) external view returns (uint);
    function creditLimits(address token, address borrower) external view returns (uint);
    function borrowerTokens(address borrower, uint index) external view returns (address);
    function tokenBorrowers(address token, uint index) external view returns (address);
    function supportedTokens(uint index) external view returns (address);
    function healthThreshold() external view returns (uint);
    function maxUtilization() external view returns (uint);
    function slippage() external view returns (uint);
    function deleverFeeETH() external view returns (uint);
    function borrowerWhitelist(address token, address borrower) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IReserve {

    /**
     * @notice Returns the expected balance of the reserve in terms of USD
     * @dev balance includes both token balances as well as LendVault shares expressed
     * in terms of USD
     */
    function expectedBalance() external view returns (uint balance);

    /**
     * @notice Request made by LendVault to get funds for withdrawal from a lender in event of high utilization or borrowers defaulting
     * @return fundsSent Amount of tokens sent back
     */
    function requestFunds(address token, uint amount) external returns(uint fundsSent);

    /**
     * @notice Burn the shares that the reserve received from LendVault for assisting withdrawals during low liquidity
     */
    function burnLendVaultShares(address token, uint shares) external;

    /**
     * @notice Withdraw a specified amount of a token to the governance address
     */
    function withdraw(address token, uint amount) external;

    /**
     * @notice Sets the slippage variable to use while using swapper
     * @notice Swaps are performed if a token is requested but the reserve doesn't
     * have enough of the token
     */
    function setSlippage(uint _slippage) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IRewardsStorage.sol";

/**
* @param stakingToken The LP Token to be staked
* @param rewardToken The reward token that is given by the Masterchef
* @param allocationPoints The allocation point for that particular pool (amount of rewards of the pool)
* @param lastRewardBlock The last block that distributes rewards.
* @param accRewardPerShare The accumulated rewards per share
*/
struct Pool {
    address stakingToken;
    address rewardToken;
    uint256 allocationPoints;
    uint256 lastRewardBlock;
    uint256 accRewardPerShare;
    bool isLending;
    address lendingToken;
}


/// @notice Info of each MCV2 user.
/// `amount` LP token amount the user has provided.
/// `rewardPaid` The amount of RUMI paid to the user.
/// `pendingRewards` The amount of RUMI pending to be paid after withdraw
    struct UserInfo {
        uint256 amount;
        uint256 rewardPaid;
        uint256 pendingRewards;
        uint256 rewardDebt;
    }

interface IRewards is IRewardsStorage {
    
    /**
     * @notice Event emitted on a user or vault depositing tokens
     * @param user User that deposits into the vault+masterchef
     * @param pid Pool Id of the deposit
     * @param amount Number of tokens staked     
     */
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @notice Event emitted on a user or vault withdrawing tokens
     * @param user User withdrawing
     * @param pid Pool Id of the deposit
     * @param amount Number of tokens staked to withdraw            
     */
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    
    /**
     * @notice Event emitted on an emergency withdraw scenario
     * @param user User withdrawing
     * @param pid Pool Id of the deposit
     * @param amount Number of tokens staked to withdraw            
     */
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @notice Event emitted on a user  harvesting of tokens
     * @param user User that deposits into the vault+masterchef
     * @param pid Pool Id of the deposit
     * @param amount Number of tokens harvested     
     */
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);    
    

    /**
     * @notice It sets caller whitelist, allowing vaults to call the Masterchef for autostaking
     * @param _callerToWhitelist address of caller to whitelist
     * @param _setOrUnset to set or unset whitelisted user
     */
    function setCallerWhitelist(address _callerToWhitelist, bool _setOrUnset) external;

    /**
     * @notice Change the speed of reward distributions
     * @param _rewardPerBlock the amount of rewards distributed per block
     */
    function changeRewardsPerBlock(uint256 _rewardPerBlock) external;    

    /**
     * @notice Sets the parameters of activation of caller whitelisting and enabling withdraws
     * @param _callerWhitelistActive Parameter to set or unset the caller whitelist
     * @param _withdrawEnabled It activates or deactivates withdrawals from users
     */
    function setParameters(bool _callerWhitelistActive, bool _withdrawEnabled) external;

    /**
     * @notice Returns the length of the pools
     * @return Number of pools
     */
    function poolLength() external view returns (uint256);

    /**
     * @notice Returns the pool id of a pool with address
     * @param _poolAddress address of the pool id to get
     * @param _isLending if the address to search is a lending pool
     * @param _lendingToken the lending token to search for
     * @return poolId Id of the pool
     * @return exists if the pool exists
     */
    function getPoolId(address _poolAddress, bool _isLending, address _lendingToken) external view returns (uint256 poolId, bool exists);

    /**
     * @notice Returns the data of a particular pool
     * @param _poolAddress address of the pool id to get
     * @param _isLending if the address to search is a lending pool
     * @param _lendingToken the lending token to search for
     * @return pool pool data
     */
    function getPoolData(address _poolAddress, bool _isLending, address _lendingToken) external view returns (Pool memory pool);
          
            
    /**
     * @notice It adds a Pool to the Masterchef array of pools
     * @param _stakingToken The Address Strategy or Vault token to be staked
     * @param _rewardToken The reward token to be distributed normally RUMI.
     * @param _allocationPoints The total tokens (allocation points) that the pool will be entitled to.
     * @param _isLending Is it a lending vault token
     * @param _lendingToken the lending token address
     */
    function addPool(address _stakingToken, address _rewardToken, uint256 _allocationPoints, bool _isLending, address _lendingToken) external;

    /**
     * @notice It sets a Poolwith new parameters
     * @param _pid The pool Id
     * @param _allocationPoints The reward token to be distributed normally RUMI.     
     */
    function setPool(uint256 _pid, uint256 _allocationPoints) external;    

    /**
     * @notice It removes pools, it requires the accRewardPerShare (pool not initiated)
     * @param _pid The pool Id     
     */
    function removePool(uint256 _pid) external;     

    /**
     * @notice Sets the new Endblock to finish reward emissions
     * @param _endBlock The ending block     
     */
    function setEndblock(uint256 _endBlock) external;     

    /**
     * @notice Sets the new Startblock to start reward emissions
     * @param _startBlock The ending block     
     */
    function setStartBlock(uint256 _startBlock) external;     

    /**
     * @notice Gets the blocks data
     * @return blockNumber current block number
     * @return _startBlock the block when the rewards started
     * @return blocksElapsed the amount of blocks elapsed since inception
     */
    function getBlocks() external view returns (uint256 blockNumber, uint256 _startBlock, uint256 blocksElapsed);        
    
    /**
     * @notice Gets the pending rewards to be distributed to a user
     * @param _pid Pool id to consult
     * @param _user The address of the user that the function will check for pending rewards
     * @return rewards Returns the amount of rewards
     */
    function getPendingReward(uint256 _pid, address _user) external view returns (uint256 rewards);

    /**
     * @notice Gets the staked balance
     * @param _poolAddress Pool address to check
     * @param _user The address of the user that the function will check for pending rewards
     * @param _isLending is this a lending pool
     * @param _lendingToken the lending token to consult
     * @return stakedBalance Returns the amount of staked tokens
     */
    function balanceOf(address _poolAddress, address _user, bool _isLending, address _lendingToken) external view returns (uint256 stakedBalance);

    /**
     * @notice Gets the staked balance
     * @param _poolAddress Pool address to check
     * @param _user The address of the user that the function will check for pending rewards
     * @param _isLending is this a lending pool
     * @param _lendingToken the lending token to consult
     * @return harvestBalance Returns the amount of pending rewards to be harvested
     */
    function getPendingHarvestableRewards(address _poolAddress, address _user, bool _isLending, address _lendingToken) external view returns (int256 harvestBalance);
    
    /**
     * @notice Deposit into the masterchef, done either by pool or user
     * @param _pid Pool ID to deposit to
     * @param _amount amount to deposit
     * @param _depositor the depositor (user or vault)
     */
    function deposit(uint256 _pid, uint256 _amount, address _depositor) external;

    /**
     * @notice Deposit into the masterchef, done either by pool or user
     * @param _poolAddress Pool address to deposit to
     * @param _amount amount to deposit
     * @param _depositor the depositor (user or vault)
     * @param _isLending is the deposit for a lending token
     * @param _lendingToken if it is lending token what is the address
     */
    function deposit(address _poolAddress, uint256 _amount, address _depositor, bool _isLending, address _lendingToken) external;
    
    /**
     * @notice Withdraw from the masterchef, done either by the pool (unstaking)
     * @param _poolAddress Pool address to withdraw to
     * @param _amount amount to deposit
     * @param _depositor the depositor (user or vault)
     * @param _isLending is the deposit for a lending token
     * @param _lendingToken if it is lending token what is the address
     */
    function withdraw(address _poolAddress, uint256 _amount, address _depositor, bool _isLending, address _lendingToken) external;

    /**
     * @notice Harvest from the masterchef, done by user
     * @param _poolAddress Pool address to withdraw to          
     * @param _isLending is the deposit for a lending token
     * @param _lendingToken if it is lending token what is the address
     */
    function harvest(address _poolAddress, bool _isLending, address _lendingToken) external;


    /**
     * @notice Withdraw everything from the Maserchef
     * @param _pid Pool ID to deposit to       
     */
    function emergencyWithdraw(uint256 _pid) external;    

    /**
     * @notice Withdraw leftover tokens from Masterchef
     * @param _amount amount of tokens to withdraw
     * @param _rewardToken reward token address
     */
    function withdrawAllLeftoverRewards(uint256 _amount, address _rewardToken) external;    

    /**
     * @notice Update reward variables for all pools. Be careful of gas spending!
     * @param pids Pool IDs of all to be updated. Make sure to update all active pools.
     */
    function massUpdatePools(uint256[] calldata pids) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IRewardsStorage {
   
    function rewardPerBlock() external view returns (uint256);
    function totalAllocationPoints(address rewardAddress) external view returns (uint256);
    function startBlock() external view returns (uint256);
    function endBlock() external view returns (uint256);
    function pools(uint position) external view returns (address, address, uint256, uint256, uint256, bool, address);
    function userInfo(uint poolId, address userAddress) external view returns (uint256,uint256, uint256, uint256);    
    function userAccumulatedReward(uint poolId, address userAddress) external view returns (uint256);
        
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ISwapper {

    /**
     @notice Returns the value a the provided token in terms of ETH
     */
    function getETHValue(address token, uint amount) external view returns (uint value);

    /**
     * @notice Returns the value of the provided tokens in terms of ETH
     */
    function getETHValue(address[] memory tokens, uint[] memory amoutns) external view returns (uint value);

    /**
     @notice Get the amount of tokenIn needed to get amountOut tokens of tokenOut
     */
    function getAmountIn(address tokenIn, uint amountOut, address tokenOut) external view returns (uint amountIn);

    /**
     * @notice Returns the amount of tokenOut that can be obtained from amountIn worth of tokenIn
     */
    function getAmountOut(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);

    /**
     * @notice Swap an exact amount of a token for another token
     * @dev slippage represents how much of a loss can be accepted
     * Max slippage is PRECISION, in which case all funds can be lost
     * Min slippage is 0, representing no loss of funds
     */
    function swapExactTokensForTokens(address tokenIn, uint amountIn, address tokenOut, uint slippage) external returns (uint amountOut);

    /**
     * @notice Swap a token for a specific amount of another token
     * @dev slippage represents how much of a loss can be accepted
     * Max slippage is PRECISION, in which case all funds can be lost
     * Min slippage is 0, representing no loss of funds
     */
    function swapTokensForExactTokens(address tokenIn, uint amountOut, address tokenOut, uint slippage) external returns (uint amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

interface IWETH {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

library AddressArray {

    function findFirst(address[] memory self, address toFind) internal pure returns (uint) {
        for (uint i = 0; i < self.length; i++) {
            if (self[i] == toFind) {
                return i;
            }
        }
        return self.length;
    }

    function exists(address[] memory self, address toFind) internal pure returns (bool) {
        for (uint i = 0; i < self.length; i++) {
            if (self[i] == toFind) {
                return true;
            }
        }
        return false;
    }

    function copy(address[] memory self) internal pure returns (address[] memory copied) {
        copied = new address[](self.length);
        for (uint i = 0; i < self.length; i++) {
            copied[i] = self[i];
        }
    }

    function sortDescending(
        address[] memory self,
        uint[] memory nums
    ) internal pure returns (address[] memory, uint[] memory) {
        uint n = nums.length;
        for (uint i = 0; i < n - 1; i++) {
            for (uint j = 0; j < n - i - 1; j++) {
                if (nums[j] < nums[j + 1]) {
                    // Swap nums[j] and nums[j + 1]
                    uint temp = nums[j];
                    nums[j] = nums[j + 1];
                    nums[j + 1] = temp;

                    // Swap self[j] and self[j + 1]
                    address tempAddress = self[j];
                    self[j] = self[j + 1];
                    self[j + 1] = tempAddress;
                }
            }
        }
        return (self, nums);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IAddressProvider.sol";

/**
 * @dev Contract module that handles access control based on an address provider
 *
 * Each access level corresponds to an administrative address
 * A function can restrict access to a specific group of administrative addresses by using restrictAccess
 * In order to restrict access to GOVERNOR and CONTROLLER, the modifier should be restrictAccess(GOVERNOR | CONTROLLER)
 */
contract AccessControl is Initializable {

    uint public constant PRECISION = 1e20;
    
    // Access levels
    uint256 internal constant GOVERNOR = 1;
    uint256 internal constant KEEPER = 2;
    uint256 internal constant GUARDIAN = 4;
    uint256 internal constant CONTROLLER = 8;
    uint256 internal constant LENDVAULT = 16;

    // Address provider that keeps track of all administrative addresses
    IAddressProvider public provider;

    function __AccessControl_init(address _provider) internal onlyInitializing {
        provider = IAddressProvider(_provider);
        provider.governance();
    }

    function getAdmin(uint accessLevel) private view returns (address){
        if (accessLevel==GOVERNOR) return provider.governance();
        if (accessLevel==KEEPER) return provider.keeper();
        if (accessLevel==GUARDIAN) return provider.guardian();
        if (accessLevel==CONTROLLER) return provider.controller();
        if (accessLevel==LENDVAULT) return provider.lendVault();
        return address(0);
    }

    /**
     * @dev Function that checks if the msg.sender has access based on accessLevel
     * The check is performed outside of the modifier to minimize contract size
     */
    function _checkAuthorization(uint accessLevel) private view {
        bool authorized = false;
        for (uint i = 0; i<5; i++) {
            if ((accessLevel & 2**(i)) == 2**(i)) {
                if (msg.sender == getAdmin(2**(i))) {
                    return;
                }
            }

        }
        require(authorized, "Unauthorized");
    }


    modifier restrictAccess(uint accessLevel) {
        _checkAuthorization(accessLevel);
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IAddressProvider.sol";

/**
 * @dev Contract module that manages access from non EOA accounts (other contracts)
 *
 * Inheriting from `BlockNonEOAUpgradeable` will make the {onlyEOA} modifier
 * available, which can be applied to functions to make sure that only whitelisted
 * contracts or EOAs can call them if contract calls are disabled.
 */
abstract contract BlockNonEOAUpgradeable is Initializable {
    
    IAddressProvider public addressProvider;

    bool public allowContractCalls;

    mapping (address=>bool) public whitelistedUsers;

    function __BlockNonEOAUpgradeable_init(address _provider) internal onlyInitializing {
        addressProvider = IAddressProvider(_provider);
    }

    function _checkEOA() private view {
        if (!allowContractCalls && !whitelistedUsers[msg.sender]) {
            require(msg.sender == tx.origin, "E35");
        }
    }

    /**
     * @notice If contract calls are disabled, block non whitelisted contracts
     */
    modifier onlyEOA() {
        _checkEOA();
        _;
    }

    /**
     * @notice Set whether other contracts can call onlyEOA functions
     */
    function setAllowContractCalls(bool _allowContractCalls) public {
        require(msg.sender==addressProvider.governance(), "Unauthorized");
        allowContractCalls = _allowContractCalls;
    }

    /**
     * @notice Whitelist or remove whitelist access for nonEOAs for accessing onlyEOA functions
     */
    function setWhitelistUsers(address[] memory users, bool[] memory allowed) public {
        require(msg.sender==addressProvider.governance(), "Unauthorized");
        for (uint i = 0; i<users.length; i++) {
            whitelistedUsers[users[i]] = allowed[i];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;

    uint256 internal _status;

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}