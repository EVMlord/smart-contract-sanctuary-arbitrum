// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

abstract contract LimitPoolFactoryStorage {
    mapping(bytes32 => address) public pools;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @notice Minimal proxy library.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @author Minimal proxy by 0age (https://github.com/0age)
/// @author Clones with immutable args by wighawag, zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
///
/// @dev Minimal proxy:
/// Although the sw0nt pattern saves 5 gas over the erc-1167 pattern during runtime,
/// it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
/// which saves 4 gas over the erc-1167 pattern during runtime, and has the smallest bytecode.
///
/// @dev Clones with immutable args (CWIA):
/// The implementation of CWIA here implements a `receive()` method that emits the
/// `ReceiveETH(uint256)` event. This skips the `DELEGATECALL` when there is no calldata,
/// enabling us to accept hard gas-capped `sends` & `transfers` for maximum backwards
/// composability. The minimal proxy implementation does not offer this feature.
library LibClone {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the clone.
    error DeploymentFailed();

    /// @dev The salt must start with either the zero address or the caller.
    error SaltDoesNotStartWithCaller();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  MINIMAL PROXY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a deterministic clone of `implementation`,
    /// using immutable  arguments encoded in `data`, with `salt`.
    function cloneDeterministic(address implementation, bytes memory data, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create2(0, sub(data, 0x4c), add(extraLength, 0x6c), salt)

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`
    /// using immutable arguments encoded in `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(address implementation, bytes memory data)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Compute and store the bytecode hash.
            hash := keccak256(sub(data, 0x4c), add(extraLength, 0x6c))

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    function predictDeterministicAddress(
        address implementation,
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash(implementation, data);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address when a contract with initialization code hash,
    /// `hash`, is deployed with `salt`, by `deployer`.
    function predictDeterministicAddress(bytes32 hash, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /// @dev Reverts if `salt` does not start with either the zero address or the caller.
    function checkStartsWithCaller(bytes32 salt) internal view {
        /// @solidity memory-safe-assembly
        assembly {
            // If the salt does not start with the zero address or the caller.
            if iszero(or(iszero(shr(96, salt)), eq(caller(), shr(96, salt)))) {
                // Store the function selector of `SaltDoesNotStartWithCaller()`.
                mstore(0x00, 0x2f634836)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/// @title Callback for mints
/// @notice Any contract that calls the `mint` function must implement this interface.
interface ICoverPoolMintCallback {
    /// @notice Called to `msg.sender` after executing a mint.
    /// @param amount0Delta The amount of token0 either received by (positive) or sent from (negative) the user.
    /// @param amount1Delta The amount of token1 either received by (positive) or sent from (negative) the user.
    function coverPoolMintCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}


/// @title Callback for swaps
/// @notice Any contract that calls the `swap` function must implement this interface.
interface ICoverPoolSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 either received by (positive) or sent from (negative) the user.
    /// @param amount1Delta The amount of token1 either received by (positive) or sent from (negative) the user.
    function coverPoolSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/// @title Callback for mints
/// @notice Any contract that calls the `mint` function must implement this interface.
interface ILimitPoolMintCallback {
    /// @notice Called to `msg.sender` after executing a mint.
    /// @param amount0Delta The amount of token0 either received by (positive) or sent from (negative) the user.
    /// @param amount1Delta The amount of token1 either received by (positive) or sent from (negative) the user.
    function limitPoolMintCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/// @title Callback for swaps
/// @notice Any contract that calls the `swap` function must implement this interface.
interface ILimitPoolSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 either received by (positive) or sent from (negative) the user.
    /// @param amount1Delta The amount of token1 either received by (positive) or sent from (negative) the user.
    function limitPoolSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../structs/PoolsharkStructs.sol';

/**
 * @title ICoverPool
 * @author Poolshark
 * @notice Defines the basic interface for a Cover Pool.
 */
interface ICoverPool is PoolsharkStructs {

    function immutables(
    ) external view returns (
        CoverImmutables memory constants
    );

    /**
     * @notice Deposits `amountIn` of asset to be auctioned off each time price range is crossed further into.
     * - E.g. User supplies 1 WETH in the range 1500 USDC per WETH to 1400 USDC per WETH
              As latestTick crosses from 1500 USDC per WETH to 1400 USDC per WETH,
              the user's liquidity within each tick spacing is auctioned off.
     * @dev The position will be shrunk onto the correct side of latestTick.
     * @dev The position will be minted with the `to` address as the owner.
     * @param params The parameters for the function. See MintCoverParams.
     */
    function mint(
        MintCoverParams memory params
    ) external;

    /**
     * @notice Withdraws the input token and returns any filled and/or unfilled amounts to the 'to' address specified. 
     * - E.g. User supplies 1 WETH in the range 1500 USDC per WETH to 1400 USDC per WETH
              As latestTick crosses from 1500 USDC per WETH to 1400 USDC per WETH,
              the user's liquidity within each tick spacing is auctioned off.
     * @dev The position will be shrunk based on the claim tick passed.
     * @dev The position amounts will be returned to the `to` address specified.
     * @dev The `sync` flag can be set to false so users can exit safely without syncing latestTick.
     * @param params The parameters for the function. See BurnCoverParams.
     */
    function burn(
        BurnCoverParams memory params
    ) external;

    /**
     * @notice Swaps `tokenIn` for `tokenOut`. 
               `tokenIn` will be `token0` if `zeroForOne` is true.
               `tokenIn` will be `token1` if `zeroForOne` is false.
               The pool price represents token1 per token0.
               The pool price will decrease if `zeroForOne` is true.
               The pool price will increase if `zeroForOne` is false. 
     * @param params The parameters for the function. See SwapParams above.
     * @return amount0Delta The amount of token0 spent (negative) or received (positive) by the user
     * @return amount1Delta The amount of token1 spent (negative) or received (positive) by the user
     */
    function swap(
        SwapParams memory params
    ) external returns (
        int256 amount0Delta,
        int256 amount1Delta
    );

    /**
     * @notice Quotes the amount of `tokenIn` for `tokenOut`. 
               `tokenIn` will be `token0` if `zeroForOne` is true.
               `tokenIn` will be `token1` if `zeroForOne` is false.
               The pool price represents token1 per token0.
               The pool price will decrease if `zeroForOne` is true.
               The pool price will increase if `zeroForOne` is false. 
     * @param params The parameters for the function. See SwapParams above.
     * @return inAmount  The amount of tokenIn to be spent
     * @return outAmount The amount of tokenOut to be received
     * @return priceAfter The Q64.96 square root price after the swap
     */
    function quote(
        QuoteParams memory params
    ) external view returns (
        int256 inAmount,
        int256 outAmount,
        uint256 priceAfter
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

abstract contract ICoverPoolFactory {

    struct CoverPoolParams {
        bytes32 poolType;
        address tokenIn;
        address tokenOut;
        uint16 feeTier;
        int16  tickSpread;
        uint16 twapLength;
    }

    /**
     * @notice Creates a new CoverPool.
     * @param params The CoverPoolParams struct referenced above.
     */
    function createCoverPool(
        CoverPoolParams memory params
    ) external virtual returns (
        address pool,
        address poolToken
    );

    /**
     * @notice Fetches an existing CoverPool.
     * @param params The CoverPoolParams struct referenced above.
     */
    function getCoverPool(
        CoverPoolParams memory params
    ) external view virtual returns (
        address pool,
        address poolToken
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../structs/PoolsharkStructs.sol';

interface ITwapSource {
    function initialize(
        PoolsharkStructs.CoverImmutables memory constants
    ) external returns (
        uint8 initializable,
        int24 startingTick
    );

    function calculateAverageTick(
        PoolsharkStructs.CoverImmutables memory constants,
        int24 latestTick
    ) external view returns (
        int24 averageTick
    );

    function getPool(
        address tokenA,
        address tokenB,
        uint16 feeTier
    ) external view returns (
        address pool
    );

    function feeTierTickSpacing(
        uint16 feeTier
    ) external view returns (
        int24 tickSpacing
    );

    function factory()
    external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../interfaces/structs/PoolsharkStructs.sol';

interface IPool is PoolsharkStructs {
    function immutables() external view returns (LimitImmutables memory);
    
    function swap(
        SwapParams memory params
    ) external returns (
        int256 amount0,
        int256 amount1
    );

    function quote(
        QuoteParams memory params
    ) external view returns (
        int256 inAmount,
        int256 outAmount,
        uint160 priceAfter
    );

    function fees(
        FeesParams memory params
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );

    function sample(
        uint32[] memory secondsAgo
    ) external view returns (
        int56[]   memory tickSecondsAccum,
        uint160[] memory secondsPerLiquidityAccum,
        uint160 averagePrice,
        uint128 averageLiquidity,
        int24 averageTick
    );

    function snapshotRange(
        uint32 positionId
    ) external view returns(
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum,
        uint128 feesOwed0,
        uint128 feesOwed1
    );

    function snapshotLimit(
        SnapshotLimitParams memory params
    ) external view returns(
        uint128,
        uint128
    );

    function globalState() external view returns (
        RangePoolState memory pool,
        LimitPoolState memory pool0,
        LimitPoolState memory pool1,
        uint128 liquidityGlobal,
        uint32 epoch,
        uint8 unlocked
    );

    function samples(uint256) external view returns (
        uint32,
        int56,
        uint160
    );

    function ticks(int24) external view returns (
        RangeTick memory,
        LimitTick memory
    );

    function positions(uint32) external view returns (
        uint256 feeGrowthInside0Last,
        uint256 feeGrowthInside1Last,
        uint128 liquidity,
        int24 lower,
        int24 upper
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../structs/LimitPoolStructs.sol';

interface ILimitPool is LimitPoolStructs {
    function initialize(
        uint160 startPrice
    ) external;

    function mintLimit(
        MintLimitParams memory params
    ) external;

    function burnLimit(
        BurnLimitParams memory params
    ) external;

    function snapshotLimit(
        SnapshotLimitParams memory params
    ) external view returns(
        uint128,
        uint128
    );

    function fees(
        FeesParams memory params
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );

    function immutables(
    ) external view returns(
        LimitImmutables memory
    );

    function priceBounds(
        int16 tickSpacing
    ) external pure returns (
        uint160 minPrice,
        uint160 maxPrice
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '../structs/PoolsharkStructs.sol';
import '../../base/storage/LimitPoolFactoryStorage.sol';

abstract contract ILimitPoolFactory is LimitPoolFactoryStorage, PoolsharkStructs {
    function createLimitPool(
        LimitPoolParams memory params
    ) external virtual returns (
        address pool,
        address poolToken
    );

    function getLimitPool(
        bytes32 poolType,
        address tokenIn,
        address tokenOut,
        uint16  swapFee
    ) external view virtual returns (
        address pool,
        address poolToken
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../structs/RangePoolStructs.sol';
import './IRangePoolManager.sol';

interface IRangePool is RangePoolStructs {
    function mintRange(
        MintRangeParams memory mintParams
    ) external;

    function burnRange(
        BurnRangeParams memory burnParams
    ) external;

    function swap(
        SwapParams memory params
    ) external returns (
        int256 amount0,
        int256 amount1
    );

    function quote(
        QuoteParams memory params
    ) external view returns (
        uint256 inAmount,
        uint256 outAmount,
        uint160 priceAfter
    );

    function snapshotRange(
        uint32 positionId
    ) external view returns(
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum,
        uint128 feesOwed0,
        uint128 feesOwed1
    );

    function sample(
        uint32[] memory secondsAgo
    ) external view returns(
        int56[]   memory tickSecondsAccum,
        uint160[] memory secondsPerLiquidityAccum,
        uint160 averagePrice,
        uint128 averageLiquidity,
        int24 averageTick
    );

    function increaseSampleCount(
        uint16 newSampleCountMax
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../structs/RangePoolStructs.sol';

interface IRangePoolManager {
    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function protocolFees(address pool) external view returns (uint16);
    function feeTiers(uint16 swapFee) external view returns (int24);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import './PoolsharkStructs.sol';

interface LimitPoolStructs is PoolsharkStructs {

    struct LimitPosition {
        uint128 liquidity; // expected amount to be used not actual
        uint32 epochLast;  // epoch when this position was created at
        int24 lower;       // lower price tick of position range
        int24 upper;       // upper price tick of position range
        bool crossedInto;  // whether the position was crossed into already
    }

    struct MintLimitCache {
        GlobalState state;
        LimitPosition position;
        LimitImmutables constants;
        LimitPoolState pool;
        SwapCache swapCache;
        uint256 liquidityMinted;
        uint256 mintSize;
        uint256 priceLimit;
        int256 amountIn;
        uint256 amountOut;
        uint256 priceLower;
        uint256 priceUpper;
        int24 tickLimit;
    }

    struct BurnLimitCache {
        GlobalState state;
        LimitPoolState pool;
        LimitTick claimTick;
        LimitPosition position;
        PoolsharkStructs.LimitImmutables constants;
        uint160 priceLower;
        uint160 priceClaim;
        uint160 priceUpper;
        uint128 liquidityBurned;
        uint128 amountIn;
        uint128 amountOut;
        int24 claim;
        bool removeLower;
        bool removeUpper;
    }

    struct InsertSingleLocals {
        int24 previousFullTick;
        int24 nextFullTick;
        uint256 priceNext;
        uint256 pricePrevious;
        uint256 amountInExact;
        uint256 amountOutExact;
        uint256 amountToCross;
    }

    struct GetDeltasLocals {
        int24 previousFullTick;
        uint256 pricePrevious;
        uint256 priceNext;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../cover/ITwapSource.sol';

interface PoolsharkStructs {
    struct GlobalState {
        RangePoolState pool;
        LimitPoolState pool0;
        LimitPoolState pool1;
        uint128 liquidityGlobal;
        uint32  positionIdNext;
        uint32 epoch;
        uint8 unlocked;
    }

    struct LimitPoolState {
        uint160 price; /// @dev Starting price current
        uint128 liquidity; /// @dev Liquidity currently active
        uint128 protocolFees;
        uint16 protocolFillFee;
        int24 tickAtPrice;
    }

    struct RangePoolState {
        SampleState  samples;
        uint200 feeGrowthGlobal0;
        uint200 feeGrowthGlobal1;
        uint160 secondsPerLiquidityAccum;
        uint160 price;               /// @dev Starting price current
        uint128 liquidity;           /// @dev Liquidity currently active
        int56   tickSecondsAccum;
        int24   tickAtPrice;
        uint16 protocolSwapFee0;
        uint16 protocolSwapFee1;
    }

    struct Tick {
        RangeTick range;
        LimitTick limit;
    }

    struct LimitTick {
        uint160 priceAt;
        int128 liquidityDelta;
        uint128 liquidityAbsolute;
    }

    struct RangeTick {
        uint200 feeGrowthOutside0;
        uint200 feeGrowthOutside1;
        uint160 secondsPerLiquidityAccumOutside;
        int56 tickSecondsAccumOutside;
        int128 liquidityDelta;
        uint128 liquidityAbsolute;
    }

    struct Sample {
        uint32  blockTimestamp;
        int56   tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
    }

    struct SampleState {
        uint16  index;
        uint16  count;
        uint16  countMax;
    }

    struct LimitPoolParams {
        bytes32 poolType;
        address tokenIn;
        address tokenOut;
        uint160 startPrice;
        uint16  swapFee;
    }

    struct SwapParams {
        address to;
        uint160 priceLimit;
        uint128  amount;
        bool exactIn;
        bool zeroForOne;
        bytes callbackData;
    }

    struct MintLimitParams {
        address to;
        uint128 amount;
        uint96 mintPercent;
        uint32 positionId;
        int24 lower;
        int24 upper;
        bool zeroForOne;
        bytes callbackData;
    }

    struct BurnLimitParams {
        address to;
        uint128 burnPercent;
        uint32 positionId;
        int24 claim;
        bool zeroForOne;
    }

    struct MintRangeParams {
        address to;
        int24 lower;
        int24 upper;
        uint32 positionId;
        uint128 amount0;
        uint128 amount1;
        bytes callbackData;
    }

    struct BurnRangeParams {
        address to;
        uint32 positionId;
        uint128 burnPercent;
    }

    struct QuoteParams {
        uint160 priceLimit;
        uint128 amount;
        bool exactIn;
        bool zeroForOne;
    }

    struct FeesParams {
        uint16 protocolSwapFee0;
        uint16 protocolSwapFee1;
        uint16 protocolFillFee0;
        uint16 protocolFillFee1;
        uint8 setFeesFlags;
    }

    struct SnapshotLimitParams {
        address owner;
        uint128 burnPercent;
        uint32 positionId;
        int24 claim;
        bool zeroForOne;
    }

    /**
     * @custom:struct MintCoverParams
     */
    struct MintCoverParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the minted position
         */
        address to;

        /**
         * @custom:field amount
         * @notice Token amount to be deposited into the minted position
         */
        uint128 amount;

        /**
         * @custom:field positionId
         * @notice 0 if creating a new position; id of previous if adding liquidity
         */
        uint32 positionId;

        /**
         * @custom:field lower
         * @notice The lower price tick for the position range
         */
        int24 lower;

        /**
         * @custom:field upper
         * @notice The upper price tick for the position range
         */
        int24 upper;

        /**
         * @custom:field zeroForOne
         * @notice True if depositing token0, the first token address in lexographical order
         * @notice False if depositing token1, the second token address in lexographical order 
         */
        bool zeroForOne;

        /**
         * @custom:field callbackData
         * @notice callback data which gets passed back to msg.sender at the end of a `mint` call
         */
        bytes callbackData;
    }

    /**
     * @custom:struct BurnCoverParams
     */
    struct BurnCoverParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the collected position amounts
         */
        address to;

        /**
         * @custom:field burnPercent
         * @notice Percent of the remaining liquidity to be removed
         * @notice 1e38 represents 100%
         * @notice 5e37 represents 50%
         * @notice 1e37 represents 10%
         */
        uint128 burnPercent;

        /**
         * @custom:field positionId
         * @notice 0 if creating a new position; id of previous if adding liquidity
         */
        uint32 positionId;

        /**
         * @custom:field claim
         * @notice The most recent tick crossed in this range
         * @notice if `zeroForOne` is true, claim tick progresses from upper => lower
         * @notice if `zeroForOne` is false, claim tick progresses from lower => upper
         */
        int24 claim;

        /**
         * @custom:field zeroForOne
         * @notice True if deposited token0, the first token address in lexographical order
         * @notice False if deposited token1, the second token address in lexographical order 
         */
        bool zeroForOne;

        /**
         * @custom:field sync
         * @notice True will sync the pool latestTick
         * @notice False will skip syncing latestTick 
         */
        bool sync;
    }

    /**
     * @custom:struct SnapshotCoverParams
     */
    struct SnapshotCoverParams {
        /**
         * @custom:field to
         * @notice Address of the position owner
         */
        address owner;

        /**
         * @custom:field positionId
         * @notice id of position
         */
        uint32 positionId;

        /**
         * @custom:field burnPercent
         * @notice Percent of the remaining liquidity to be removed
         * @notice 1e38 represents 100%
         * @notice 5e37 represents 50%
         * @notice 1e37 represents 10%
         */
        uint128 burnPercent;

        /**
         * @custom:field claim
         * @notice The most recent tick crossed in this range
         * @notice if `zeroForOne` is true, claim tick progresses from upper => lower
         * @notice if `zeroForOne` is false, claim tick progresses from lower => upper
         */
        int24 claim;

        /**
         * @custom:field zeroForOne
         * @notice True if deposited token0, the first token address in lexographical order
         * @notice False if deposited token1, the second token address in lexographical order 
         */
        bool zeroForOne;
    }

    struct QuoteResults {
        address pool;
        int256 amountIn;
        int256 amountOut;
        uint160 priceAfter;
    }
    
    struct LimitImmutables {
        address owner;
        address poolImpl;
        address factory;
        PriceBounds bounds;
        address token0;
        address token1;
        address poolToken;
        uint32 genesisTime;
        int16 tickSpacing;
        uint16 swapFee;
    }

    struct CoverImmutables {
        ITwapSource source;
        PriceBounds bounds;
        address owner;
        address token0;
        address token1;
        address poolImpl;
        address poolToken;
        address inputPool;
        uint128 minAmountPerAuction;
        uint32 genesisTime;
        int16  minPositionWidth;
        int16  tickSpread;
        uint16 twapLength;
        uint16 auctionLength;
        uint16 sampleInterval;
        uint8 token0Decimals;
        uint8 token1Decimals;
        bool minAmountLowerPriced;
    }

    struct PriceBounds {
        uint160 min;
        uint160 max;
    }

    struct TickMap {
        uint256 blocks;                     /// @dev - sets of words
        mapping(uint256 => uint256) words;  /// @dev - sets to words
        mapping(uint256 => uint256) ticks;  /// @dev - words to ticks
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs0; /// @dev - ticks to epochs
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs1; /// @dev - ticks to epochs
    }

    struct SwapCache {
        GlobalState state;
        LimitImmutables constants;
        uint256 price;
        uint256 liquidity;
        uint256 amountLeft;
        uint256 input;
        uint256 output;
        uint160 crossPrice;
        uint160 averagePrice;
        uint160 secondsPerLiquidityAccum;
        uint128 feeAmount;
        int56   tickSecondsAccum;
        int56   tickSecondsAccumBase;
        int24   crossTick;
        uint8   crossStatus;
        bool    limitActive;
        bool    exactIn;
        bool    cross;
    }  

    enum CrossStatus {
        RANGE,
        LIMIT,
        BOTH
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import './PoolsharkStructs.sol';

interface RangePoolStructs is PoolsharkStructs {

    struct RangePosition {
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
        uint128 liquidity;
        int24 lower;
        int24 upper;
    }

    struct CompoundRangeParams {
        uint160 priceLower;
        uint160 priceUpper;
        uint128 amount0;
        uint128 amount1;
        uint32 positionId;
    }

    struct SampleParams {
        uint16 sampleIndex;
        uint16 sampleLength;
        uint32 time;
        uint32[] secondsAgo;
        int24 tick;
        uint128 liquidity;
        PoolsharkStructs.LimitImmutables constants;
    }

    struct UpdateParams {
        int24 lower;
        int24 upper;
        uint32 positionId;
        uint128 burnPercent;
    }

    struct MintRangeCache {
        GlobalState state;
        RangePosition position;
        PoolsharkStructs.LimitImmutables constants;
        uint256 liquidityMinted;
        uint160 priceLower;
        uint160 priceUpper;
        int128 amount0;
        int128 amount1;
    }

    struct BurnRangeCache {
        GlobalState state;
        RangePosition position;
        PoolsharkStructs.LimitImmutables constants;
        uint256 liquidityBurned;
        uint160 priceLower;
        uint160 priceUpper;
        int128 amount0;
        int128 amount1;
    }

    struct RangePositionCache {
        uint256 liquidityAmount;
        uint256 rangeFeeGrowth0;
        uint256 rangeFeeGrowth1;
        uint128 amountFees0;
        uint128 amountFees1;
        uint128 feesBurned0;
        uint128 feesBurned1;
    }

    struct SnapshotRangeCache {
        RangePosition position;
        SampleState samples;
        PoolsharkStructs.LimitImmutables constants;
        uint160 price;
        uint160 secondsPerLiquidityAccum;
        uint160 secondsPerLiquidityAccumLower;
        uint160 secondsPerLiquidityAccumUpper;
        uint128 liquidity;
        uint128 amount0;
        uint128 amount1;
        int56   tickSecondsAccum;
        int56   tickSecondsAccumLower;
        int56   tickSecondsAccumUpper;
        uint32  secondsOutsideLower;
        uint32  secondsOutsideUpper;
        uint32  blockTimestamp;
        int24   tick;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        if((z = uint128(y)) != y) require(false, 'Uint256ToUint128:Overflow()');
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(int128 y) internal pure returns (uint128 z) {
        if(y < 0) require(false, 'Int128ToUint128:Underflow()');
        z = uint128(y);
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        if((z = uint160(y)) != y) require(false, 'Uint256ToUint160:Overflow()');
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint32(uint256 y) internal pure returns (uint32 z) {
        if((z = uint32(y)) != y) require(false, 'Uint256ToUint32:Overflow()');
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        if ((z = int128(y)) != y) require(false, 'Int256ToInt128:Overflow()');
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(uint128 y) internal pure returns (int128 z) {
        if(y > uint128(type(int128).max)) require(false, 'Uint128ToInt128:Overflow()');
        z = int128(y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        if(y > uint256(type(int256).max)) require(false, 'Uint256ToInt256:Overflow()');
        z = int256(y);
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint256(int256 y) internal pure returns (uint256 z) {
        if(y < 0) require(false, 'Int256ToUint256:Underflow()');
        z = uint256(y);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

library SafeTransfers {
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    // slither-disable-next-line assembly
    function transferIn(address token, uint256 amount) internal returns (uint256) {
        if (token == address(0)) {
            if (msg.value < amount) require(false, 'TransferFailed(msg.sender, address(this)');
            return amount;
        }
        if (amount == 0) return 0;
        IERC20 erc20Token = IERC20(token);
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        erc20Token.transferFrom(msg.sender, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) require(false, 'TransferFailed(msg.sender, address(this)');

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    // slither-disable-next-line assembly
    function transferOut(
        address to,
        address token,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            if (address(this).balance < amount) require(false, 'TransferFailed(address(this), to');
            payable(to).transfer(amount);
            return;
        }
        if (amount == 0) return;
        IERC20 erc20Token = IERC20(token);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        erc20Token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) require(false, 'TransferFailed(address(this), msg.sender');
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    // slither-disable-next-line assembly
    function transferInto(address token, address sender, uint256 amount) internal returns (uint256) {
        if (token == address(0)) {
            if (msg.value < amount) require(false, 'TransferFailed(msg.sender, address(this)');
            return amount;
        }
        IERC20 erc20Token = IERC20(token);
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        /// @dev - msg.sender here is the pool
        erc20Token.transferFrom(sender, msg.sender, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) require(false, 'TransferFailed(msg.sender, address(this)');

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../interfaces/IPool.sol';
import '../interfaces/range/IRangePool.sol';
import '../interfaces/limit/ILimitPool.sol';
import '../interfaces/cover/ICoverPool.sol';
import '../interfaces/cover/ICoverPoolFactory.sol';
import '../interfaces/limit/ILimitPoolFactory.sol';
import '../interfaces/callbacks/ILimitPoolCallback.sol';
import '../interfaces/callbacks/ICoverPoolCallback.sol';
import '../libraries/utils/SafeTransfers.sol';
import '../libraries/utils/SafeCast.sol';
import '../interfaces/structs/PoolsharkStructs.sol';
import '../external/solady/LibClone.sol';

contract PoolsharkRouter is
    PoolsharkStructs,
    ILimitPoolMintCallback,
    ILimitPoolSwapCallback,
    ICoverPoolSwapCallback,
    ICoverPoolMintCallback
{
    using SafeCast for uint256;
    using SafeCast for int256;

    address public immutable limitPoolFactory;
    address public immutable coverPoolFactory;

    event RouterDeployed(
        address router,
        address limitPoolFactory,
        address coverPoolFactory
    );

    event PoolQuoted(
        address pool,
        uint256 amountIn,
        uint256 amountOut,
        uint160 priceAfter
    );

    event PoolQuoteSorted(
        address pool,
        uint256 amountIn,
        uint256 amountOut,
        uint160 priceAfter,
        uint256 sortIndex,
        uint256 sorted
    );

    struct MintCallbackData {
        address sender;
    }

    struct SwapCallbackData {
        address sender;
    }

    constructor(
        address limitPoolFactory_,
        address coverPoolFactory_
    ) {
        limitPoolFactory = limitPoolFactory_;
        coverPoolFactory = coverPoolFactory_;
        emit RouterDeployed(
            address(this),
            limitPoolFactory,
            coverPoolFactory
        );
    }

    /// @inheritdoc ILimitPoolMintCallback
    function limitPoolMintCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        PoolsharkStructs.LimitImmutables memory constants = ILimitPool(msg.sender).immutables();

        // validate sender is a canonical limit pool
        canonicalLimitPoolsOnly(constants);

        // decode original sender
        MintCallbackData memory _data = abi.decode(data, (MintCallbackData));
        
        // transfer from swap caller
        if (amount0Delta < 0) {
            SafeTransfers.transferInto(constants.token0, _data.sender, uint256(-amount0Delta));
        }
        if (amount1Delta < 0) {
            SafeTransfers.transferInto(constants.token1, _data.sender, uint256(-amount1Delta));
        }
    }

    /// @inheritdoc ILimitPoolSwapCallback
    function limitPoolSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        PoolsharkStructs.LimitImmutables memory constants = ILimitPool(msg.sender).immutables();

        // validate sender is a canonical limit pool
        canonicalLimitPoolsOnly(constants);

        // decode original sender
        SwapCallbackData memory _data = abi.decode(data, (SwapCallbackData));
        
        // transfer from swap caller
        if (amount0Delta < 0) {
            SafeTransfers.transferInto(constants.token0, _data.sender, uint256(-amount0Delta));
        } else {
            SafeTransfers.transferInto(constants.token1, _data.sender, uint256(-amount1Delta));
        }
    }

    /// @inheritdoc ICoverPoolSwapCallback
    function coverPoolSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        PoolsharkStructs.CoverImmutables memory constants = ICoverPool(msg.sender).immutables();

        // validate sender is a canonical cover pool
        canonicalCoverPoolsOnly(constants);

        // decode original sender
        SwapCallbackData memory _data = abi.decode(data, (SwapCallbackData));
        
        // transfer from swap caller
        if (amount0Delta < 0) {
            SafeTransfers.transferInto(constants.token0, _data.sender, uint256(-amount0Delta));
        } else {
            SafeTransfers.transferInto(constants.token1, _data.sender, uint256(-amount1Delta));
        }
    }

    /// @inheritdoc ICoverPoolMintCallback
    function coverPoolMintCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        PoolsharkStructs.CoverImmutables memory constants = ICoverPool(msg.sender).immutables();

        // validate sender is a canonical cover pool
        canonicalCoverPoolsOnly(constants);

        // decode original sender
        MintCallbackData memory _data = abi.decode(data, (MintCallbackData));

        // transfer from swap caller
        if (amount0Delta < 0) {
            SafeTransfers.transferInto(constants.token0, _data.sender, uint256(-amount0Delta));
        } else {
            SafeTransfers.transferInto(constants.token1, _data.sender, uint256(-amount1Delta));
        }
    }

    function multiMintLimit(
        address[] memory pools,
        MintLimitParams[] memory params
    ) external {
        if (pools.length != params.length) require(false, 'InputArrayLengthsMismatch()');
        for (uint i = 0; i < pools.length;) {
            params[i].callbackData = abi.encode(MintCallbackData({sender: msg.sender}));
            ILimitPool(pools[i]).mintLimit(params[i]);
            unchecked {
                ++i;
            }
        }
    }

    function multiMintRange(
        address[] memory pools,
        MintRangeParams[] memory params
    ) external {
        if (pools.length != params.length) require(false, 'InputArrayLengthsMismatch()');
        for (uint i = 0; i < pools.length;) {
            params[i].callbackData = abi.encode(MintCallbackData({sender: msg.sender}));
            IRangePool(pools[i]).mintRange(params[i]);
            unchecked {
                ++i;
            }
        }
    }

    function multiMintCover(
        address[] memory pools,
        PoolsharkStructs.MintCoverParams[] memory params
    ) external {
        if (pools.length != params.length) require(false, 'InputArrayLengthsMismatch()');
        for (uint i = 0; i < pools.length;) {
            params[i].callbackData = abi.encode(MintCallbackData({sender: msg.sender}));
            ICoverPool(pools[i]).mint(params[i]);
            unchecked {
                ++i;
            }
        }
    }

    function multiQuote(
        address[] memory pools,
        QuoteParams[] memory params,
        bool sortResults 
    ) external returns (
        QuoteResults[] memory results
    )
    {
        if (pools.length != params.length) require(false, 'InputArrayLengthsMismatch()');
        if (sortResults) {
            // if sorting results check for matching params
            for (uint i = 0; i < pools.length;) {
                if (i > 0) {
                    if (params[i].zeroForOne != params[0].zeroForOne) require (false, 'ZeroForOneParamMismatch()');
                    if (params[i].exactIn != params[0].exactIn) require(false, 'ExactInParamMismatch()');
                    /// @dev - amount and priceLimit values are allowed to be different
                }
                unchecked {
                    ++i;
                }
            }
        }
        results = new QuoteResults[](pools.length);
        for (uint i = 0; i < pools.length;) {
            results[i].pool = pools[i];
            (
                results[i].amountIn,
                results[i].amountOut,
                results[i].priceAfter
            ) = IPool(pools[i]).quote(params[i]);
            emit PoolQuoted(pools[i], results[i].amountIn.toUint256(), results[i].amountOut.toUint256(), results[i].priceAfter);
            unchecked {
                ++i;
            }
        }
        // sort if true
        if (sortResults) {
            results = sortQuoteResults(params, results);
        }
    }

    function multiSwapSplit(
        address[] memory pools,
        SwapParams[] memory params 
    ) external {
        if (pools.length != params.length) require(false, 'InputArrayLengthsMismatch()');
        for (uint i = 0; i < pools.length;) {
            if (i > 0) {
                if (params[i].zeroForOne != params[0].zeroForOne) require (false, 'ZeroForOneParamMismatch()');
                if (params[i].exactIn != params[0].exactIn) require(false, 'ExactInParamMismatch()');
                if (params[i].amount != params[0].amount) require(false, 'AmountParamMisMatch()');
            }
            unchecked {
                ++i;
            }
        }
        for (uint i = 0; i < pools.length && params[0].amount > 0;) {
            params[i].callbackData = abi.encode(SwapCallbackData({sender: msg.sender}));
            (
                int256 amount0Delta,
                int256 amount1Delta
            ) = IPool(pools[i]).swap(params[i]);
            // if there is another pool to swap against
            if ((i + 1) < pools.length) {
                // calculate amount left and set for next call
                if (params[0].zeroForOne && params[0].exactIn) {
                    params[0].amount -= (-amount0Delta).toUint256().toUint128();
                } else if (params[0].zeroForOne && !params[0].exactIn) {
                    params[0].amount -= (amount1Delta).toUint256().toUint128();
                } else if (!params[0].zeroForOne && !params[0].exactIn) {
                    params[0].amount -= (amount0Delta).toUint256().toUint128();
                } else if (!params[0].zeroForOne && params[0].exactIn) {
                    params[0].amount -= (-amount1Delta).toUint256().toUint128();
                }
                params[i+1].amount = params[0].amount;
            }
            unchecked {
                ++i;
            }
        }
    }

    function createLimitPoolAndMint(
        ILimitPoolFactory.LimitPoolParams memory params,
        MintRangeParams[] memory mintRangeParams,
        MintLimitParams[] memory mintLimitParams
    ) external returns (
        address pool,
        address poolToken 
    ) {
        // check if pool exists
        (
            pool,
            poolToken
        ) = ILimitPoolFactory(limitPoolFactory).getLimitPool(
            params.poolType,
            params.tokenIn,
            params.tokenOut,
            params.swapFee
        );
        // create if pool doesn't exist
        if (pool == address(0)) {
            (
                pool,
                poolToken
            ) = ILimitPoolFactory(limitPoolFactory).createLimitPool(
                params
            );
        }
        // mint initial range positions
        for (uint i = 0; i < mintRangeParams.length;) {
            IRangePool(pool).mintRange(mintRangeParams[i]);
            unchecked {
                ++i;
            }
        }
        // mint initial limit positions
        for (uint i = 0; i < mintLimitParams.length;) {
            ILimitPool(pool).mintLimit(mintLimitParams[i]);
            unchecked {
                ++i;
            }
        }
    }

    function createCoverPoolAndMint(
        ICoverPoolFactory.CoverPoolParams memory params,
        MintCoverParams[] memory mintCoverParams
    ) external returns (
        address pool,
        address poolToken 
    ) {
        // check if pool exists
        (
            pool,
            poolToken
        ) = ICoverPoolFactory(coverPoolFactory).getCoverPool(
            params
        );
        // create if pool doesn't exist
        if (pool == address(0)) {
            (
                pool,
                poolToken
            ) = ICoverPoolFactory(coverPoolFactory).createCoverPool(
                params
            );
        }
        // mint initial cover positions
        for (uint i = 0; i < mintCoverParams.length;) {
            ICoverPool(pool).mint(mintCoverParams[i]);
            unchecked {
                ++i;
            }
        }
    }

    struct SortQuoteResultsLocals {
        QuoteResults[] sortedResults;
        QuoteResults[] prunedResults;
        bool[] sortedFlags;
        uint256 emptyResults;
        int256 sortAmount;
        uint256 sortIndex;
        uint256 prunedIndex;
    }

    function sortQuoteResults(
        QuoteParams[] memory params,
        QuoteResults[] memory results
    ) internal returns (
        QuoteResults[] memory
    ) {
        SortQuoteResultsLocals memory locals;
        locals.sortedResults = new QuoteResults[](results.length);
        locals.sortedFlags = new bool[](results.length);
        locals.emptyResults = 0;
        for (uint sorted = 0; sorted < results.length;) {
            // if exactIn, sort by most output
            // if exactOut, sort by least input
            locals.sortAmount = params[0].exactIn ? int256(0) : type(int256).max;
            locals.sortIndex = type(uint256).max;
            for (uint index = 0; index < results.length;) {
                // check if result already sorted
                if (!locals.sortedFlags[index]) {
                    if (params[0].exactIn) {
                        if (results[index].amountOut >= locals.sortAmount) {
                            locals.sortIndex = index;
                            locals.sortAmount = results[index].amountOut;
                        }
                    } else {
                        if (results[index].amountIn <= locals.sortAmount) {
                            locals.sortIndex = index;
                            locals.sortAmount = results[index].amountIn;
                        }
                    }
                }
                // continue finding nth element
                unchecked {
                    ++index;
                }
            }
            if (locals.sortIndex != type(uint256).max) {
                emit PoolQuoteSorted(results[locals.sortIndex].pool, results[locals.sortIndex].amountIn.toUint256(), results[locals.sortIndex].amountOut.toUint256(), results[locals.sortIndex].priceAfter, locals.sortIndex, sorted);
                // add the sorted result
                locals.sortedResults[sorted].pool = results[locals.sortIndex].pool;
                locals.sortedResults[sorted].amountIn = results[locals.sortIndex].amountIn;
                locals.sortedResults[sorted].amountOut = results[locals.sortIndex].amountOut;
                locals.sortedResults[sorted].priceAfter = results[locals.sortIndex].priceAfter;

                // indicate this result was already sorted
                locals.sortedFlags[locals.sortIndex] = true;
            } else {
                ++locals.emptyResults;
            }
            // find next sorted element
            unchecked {
                ++sorted;
            }
        }
        // if any results were empty, prune them
        if (locals.emptyResults > 0) {
            locals.prunedResults = new QuoteResults[](results.length - locals.emptyResults);
            locals.prunedIndex = 0;
            for (uint sorted = 0; sorted < results.length;) {
                // empty results are omitted
                if (locals.sortedResults[sorted].pool != address(0)) {
                    locals.prunedResults[locals.prunedIndex] = locals.sortedResults[sorted];
                    unchecked {
                        ++locals.prunedIndex;
                    }
                }
                unchecked {
                    ++sorted;
                }
            }
        } else {
            locals.prunedResults = locals.sortedResults;
        }
        return locals.prunedResults;
    }

    function canonicalLimitPoolsOnly(
        PoolsharkStructs.LimitImmutables memory constants
    ) private view {
        // generate key for pool
        bytes32 key = keccak256(abi.encode(
            constants.poolImpl,
            constants.token0,
            constants.token1,
            constants.swapFee
        ));

        // compute address
        address predictedAddress = LibClone.predictDeterministicAddress(
            constants.poolImpl,
            encodeLimit(constants),
            key,
            limitPoolFactory
        );

        // revert on sender mismatch
        if (msg.sender != predictedAddress) require(false, 'InvalidCallerAddress()');
    }

    function canonicalCoverPoolsOnly(
        PoolsharkStructs.CoverImmutables memory constants
    ) private view {
        // generate key for pool
        bytes32 key = keccak256(abi.encode(
            constants.token0,
            constants.token1,
            constants.source,
            constants.inputPool,
            constants.tickSpread,
            constants.twapLength
        ));

        // compute address
        address predictedAddress = LibClone.predictDeterministicAddress(
            constants.poolImpl,
            encodeCover(constants),
            key,
            coverPoolFactory
        );

        // revert on sender mismatch
        if (msg.sender != predictedAddress) require(false, 'InvalidCallerAddress()');
    }

    function encodeLimit(
        LimitImmutables memory constants
    ) private pure returns (bytes memory) {
        return abi.encodePacked(
                constants.owner,
                constants.token0,
                constants.token1,
                constants.poolToken,
                constants.bounds.min,
                constants.bounds.max,
                constants.genesisTime,
                constants.tickSpacing,
                constants.swapFee
        );
    }

    function encodeCover(
        CoverImmutables memory constants
    ) private pure returns (bytes memory) {
        bytes memory value1 = abi.encodePacked(
            constants.owner,
            constants.token0,
            constants.token1,
            constants.source,
            constants.poolToken,
            constants.inputPool,
            constants.bounds.min,
            constants.bounds.max,
            constants.minAmountPerAuction,
            constants.genesisTime,
            constants.minPositionWidth,
            constants.tickSpread,
            constants.twapLength,
            constants.auctionLength
        );
        bytes memory value2 = abi.encodePacked(
            constants.sampleInterval,
            constants.token0Decimals,
            constants.token1Decimals,
            constants.minAmountLowerPriced
        );
        return abi.encodePacked(value1, value2);
    }
}