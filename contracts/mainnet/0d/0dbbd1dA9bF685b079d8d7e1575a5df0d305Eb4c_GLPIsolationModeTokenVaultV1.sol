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

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { ProxyContractHelpers } from "../helpers/ProxyContractHelpers.sol";
import { IIsolationModeVaultFactory } from "../interfaces/IIsolationModeVaultFactory.sol";
import { IGLPIsolationModeTokenVaultV1 } from "../interfaces/gmx/IGLPIsolationModeTokenVaultV1.sol";
import { IGLPIsolationModeVaultFactory } from "../interfaces/gmx/IGLPIsolationModeVaultFactory.sol";
import { IGmxRewardRouterV2 } from "../interfaces/gmx/IGmxRewardRouterV2.sol";
import { IGmxVester } from "../interfaces/gmx/IGmxVester.sol";
import { ISGMX } from "../interfaces/gmx/ISGMX.sol";
import { IsolationModeTokenVaultV1 } from "../proxies/abstract/IsolationModeTokenVaultV1.sol";


/**
 * @title   GLPIsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  Implementation (for an upgradeable proxy) for a per-user vault that holds the sGLP token that can be used to
 *          to credit a user's Dolomite balance. sGLP held in the vault is considered to be in isolation mode - that is
 *          it cannot be borrowed by other users, may only be seized via liquidation, and cannot be held in the same
 *          position as other "isolated" tokens.
 */
contract GLPIsolationModeTokenVaultV1 is
    IGLPIsolationModeTokenVaultV1,
    IsolationModeTokenVaultV1,
    ProxyContractHelpers
{
    using SafeERC20 for IERC20;

    // ==================================================================
    // =========================== Constants ============================
    // ==================================================================

    bytes32 private constant _FILE = "GLPIsolationModeTokenVaultV1";
    bytes32 private constant _IS_ACCEPTING_FULL_ACCOUNT_TRANSFER_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.isAcceptingFullAccountTransfer")) - 1);
    bytes32 private constant _HAS_ACCEPTED_FULL_ACCOUNT_TRANSFER_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.hasAcceptedFullAccountTransfer")) - 1);

    // ==================================================================
    // ======================= External Functions =======================
    // ==================================================================

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldDepositWethIntoDolomite
    )
    external
    override
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _handleRewards(
            _shouldClaimGmx,
            _shouldStakeGmx,
            _shouldClaimEsGmx,
            _shouldStakeEsGmx,
            _shouldStakeMultiplierPoints,
            _shouldClaimWeth,
            _shouldDepositWethIntoDolomite,
            /* _depositAccountNumberForWeth = */ 0
        );
    }

    function handleRewardsWithSpecificDepositAccountNumber(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldDepositWethIntoDolomite,
        uint256 _depositAccountNumberForWeth
    )
    external
    override
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _handleRewards(
            _shouldClaimGmx,
            _shouldStakeGmx,
            _shouldClaimEsGmx,
            _shouldStakeEsGmx,
            _shouldStakeMultiplierPoints,
            _shouldClaimWeth,
            _shouldDepositWethIntoDolomite,
            _depositAccountNumberForWeth
        );
    }

    function stakeGmx(uint256 _amount) external override onlyVaultOwner(msg.sender) {
        IERC20 _gmx = gmx();
        _gmx.safeTransferFrom(msg.sender, address(this), _amount);

        _stakeGmx(_gmx, _amount);
    }

    function unstakeGmx(uint256 _amount) external override onlyVaultOwner(msg.sender) {
        gmxRewardsRouter().unstakeGmx(_amount);

        gmx().safeTransfer(msg.sender, _amount);
    }

    function stakeEsGmx(uint256 _amount) external override onlyVaultOwner(msg.sender) {
        gmxRewardsRouter().stakeEsGmx(_amount);
    }

    function unstakeEsGmx(uint256 _amount) external override onlyVaultOwner(msg.sender) {
        gmxRewardsRouter().unstakeEsGmx(_amount);
    }

    function acceptFullAccountTransfer(
        address _sender
    )
    external
    override
    nonReentrant
    onlyVaultOwnerOrVaultFactory(msg.sender) {
        Require.that(
            _sender != address(0),
            _FILE,
            "Invalid sender"
        );
        Require.that(
            !hasAcceptedFullAccountTransfer() && underlyingBalanceOf() == 0,
            _FILE,
            "Cannot transfer more than once"
        );

        gmxRewardsRouter().acceptTransfer(_sender);

        // set this flag so we don't materialize the transfer. This is needed because the assets are spot settled in
        // this vault via the call to #acceptTransfer
        _setIsAcceptingFullAccountTransfer(true);

        // the amount of fsGLP being deposited is the current balance of fsGLP, since we should have started at 0.
        uint amountWei = underlyingBalanceOf();
        IIsolationModeVaultFactory(VAULT_FACTORY()).depositIntoDolomiteMargin(/* _toAccountNumber = */ 0, amountWei);

        // reset the flag back to false
        _setIsAcceptingFullAccountTransfer(false);

        // set this flag so we don't allow full account transfers again
        _setHasAcceptedFullAccountTransfer(true);
    }

    function vestGlp(uint256 _esGmxAmount) external override onlyVaultOwner(msg.sender) {
        _vestEsGmx(vGlp(), _esGmxAmount);
    }

    function unvestGlp(bool _shouldStakeGmx) external override onlyVaultOwner(msg.sender) {
        _unvestEsGmx(vGlp(), _shouldStakeGmx);
    }

    function vestGmx(uint256 _esGmxAmount) external override onlyVaultOwner(msg.sender) {
        _vestEsGmx(vGmx(), _esGmxAmount);
    }

    function unvestGmx(bool _shouldStakeGmx) external override onlyVaultOwner(msg.sender) {
        _unvestEsGmx(vGmx(), _shouldStakeGmx);
    }

    // ==================================================================
    // ======================== Public Functions ========================
    // ==================================================================

    function executeDepositIntoVault(
        address _from,
        uint256 _amount
    )
    public
    override
    onlyVaultFactory(msg.sender) {
        if (isAcceptingFullAccountTransfer()) {
            // The fsGLP is already in this vault, so don't materialize a transfer from the vault owner
            assert(_amount == underlyingBalanceOf());
        } else {
            sGlp().safeTransferFrom(_from, address(this), _amount);
        }
    }

    function executeWithdrawalFromVault(
        address _recipient,
        uint256 _amount
    )
    public
    override
    onlyVaultFactory(msg.sender) {
        if (super.underlyingBalanceOf() < _amount) {
            // There's not enough value in the vault to cover the withdrawal, so we need to withdraw from vGLP
            vGlp().withdraw();
            _withdrawAllGmx(_proxySelf().owner());
        }

        assert(_recipient != address(this));
        // we can't use the fsGLP because it's not transferable. sGLP contains the authorization and logic for
        // transferring fsGLP tokens.
        sGlp().safeTransfer(_recipient, _amount);
    }

    function esGmx() public view returns (IERC20) {
        return IERC20(IGLPIsolationModeVaultFactory(VAULT_FACTORY()).gmxRegistry().esGmx());
    }

    function gmxRewardsRouter() public view returns (IGmxRewardRouterV2) {
        return IGLPIsolationModeVaultFactory(VAULT_FACTORY()).gmxRegistry().gmxRewardsRouter();
    }

    function underlyingBalanceOf() public view override returns (uint256) {
        return vGlp().pairAmounts(address(this)) + super.underlyingBalanceOf();
    }

    function gmxBalanceOf() public view returns (uint256) {
        address account = address(this);
        // sGmx reflects the amount of GMX tokens the user owns. The `depositBalances` mapping isn't updated when the
        // sbfGMX tokens are transferred to the vGMX vesting contract, so this seems reliable. Moreover, this contract
        // only holds staked-GMX tokens, which is why we only check the sGMX contract. sGMX reflects any sbfGMX that is
        // moved into vGMX vesting too.
        return sGmx().depositBalances(account, address(gmx()));
    }

    function esGmxBalanceOf() public view returns (uint256) {
        IERC20 _esGmx = esGmx();
        address account = address(this);
        // We need to pull the esGMX being held here, in the vesting contracts for GMX and GLP, and being staked in the
        // sGMX contract
        return _esGmx.balanceOf(account)
            + vGmx().balanceOf(account)
            + vGlp().balanceOf(account)
            + sGmx().depositBalances(account, address(_esGmx));
    }

    function getGlpAmountNeededForEsGmxVesting(uint256 _esGmxAmount) public view returns (uint256) {
        return _getPairAmountNeededForEsGmxVesting(vGlp(), _esGmxAmount);
    }

    function getGmxAmountNeededForEsGmxVesting(uint256 _esGmxAmount) public view returns (uint256) {
        return _getPairAmountNeededForEsGmxVesting(vGmx(), _esGmxAmount);
    }

    function gmx() public view returns (IERC20) {
        return IERC20(IGLPIsolationModeVaultFactory(VAULT_FACTORY()).gmxRegistry().gmx());
    }

    function sGlp() public view returns (IERC20) {
        return IERC20(IGLPIsolationModeVaultFactory(VAULT_FACTORY()).gmxRegistry().sGlp());
    }

    function sGmx() public view returns (ISGMX) {
        return ISGMX(IGLPIsolationModeVaultFactory(VAULT_FACTORY()).gmxRegistry().sGmx());
    }

    function vGlp() public view returns (IGmxVester) {
        return IGmxVester(IGLPIsolationModeVaultFactory(VAULT_FACTORY()).gmxRegistry().vGlp());
    }

    function vGmx() public view returns (IGmxVester) {
        return IGmxVester(IGLPIsolationModeVaultFactory(VAULT_FACTORY()).gmxRegistry().vGmx());
    }

    function isAcceptingFullAccountTransfer() public view returns (bool) {
        return _getUint256(_IS_ACCEPTING_FULL_ACCOUNT_TRANSFER_SLOT) == 1;
    }

    function hasAcceptedFullAccountTransfer() public view returns (bool) {
        return _getUint256(_HAS_ACCEPTED_FULL_ACCOUNT_TRANSFER_SLOT) == 1;
    }

    // ==================================================================
    // ======================= Internal Functions =======================
    // ==================================================================

    function _handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldDepositWethIntoDolomite,
        uint256 _depositAccountNumberForWeth
    ) internal {
        Require.that(
            (!_shouldClaimWeth && !_shouldDepositWethIntoDolomite) || _shouldClaimWeth,
            _FILE,
            "Can only deposit ETH if claiming"
        );

        if (_shouldStakeGmx) {
            // we don't know how much GMX will be staked, so we have to approve all
            _approveGmxForStaking(gmx(), type(uint256).max);
        }
        gmxRewardsRouter().handleRewards(
            _shouldClaimGmx,
            _shouldStakeGmx,
            _shouldClaimEsGmx,
            _shouldStakeEsGmx,
            _shouldStakeMultiplierPoints,
            _shouldClaimWeth,
            /* _shouldConvertWethToEth = */ false
        );

        if (_shouldStakeGmx) {
            // we can reset the allowance back to 0 here
            _approveGmxForStaking(gmx(), 0);
        } else {
            // If the user isn't staking GMX, transfer it to the vault owner
            _withdrawAllGmx(msg.sender);
        }

        if (_shouldClaimWeth) {
            address factory = VAULT_FACTORY();
            address weth = IGLPIsolationModeVaultFactory(factory).WETH();
            uint256 wethAmountWei = IERC20(weth).balanceOf(address(this));
            if (_shouldDepositWethIntoDolomite) {
                IERC20(weth).safeApprove(address(DOLOMITE_MARGIN()), wethAmountWei);
                IIsolationModeVaultFactory(factory).depositOtherTokenIntoDolomiteMarginForVaultOwner(
                    _depositAccountNumberForWeth,
                    IGLPIsolationModeVaultFactory(factory).WETH_MARKET_ID(),
                    wethAmountWei
                );
            } else {
                IERC20(weth).safeTransfer(msg.sender, wethAmountWei);
            }
        }
    }

    function _stakeGmx(IERC20 _gmx, uint256 _amount) internal {
        _approveGmxForStaking(_gmx, _amount);
        gmxRewardsRouter().stakeGmx(_amount);
    }

    function _vestEsGmx(IGmxVester _vester, uint256 _esGmxAmount) internal {
        _vester.deposit(_esGmxAmount);
    }

    function _unvestEsGmx(IGmxVester _vester, bool _shouldStakeGmx) internal {
        _vester.withdraw();
        if (_shouldStakeGmx) {
            IERC20 _gmx = gmx();
            _stakeGmx(_gmx, _gmx.balanceOf(address(this)));
        } else {
            _withdrawAllGmx(msg.sender);
        }
    }

    function _approveGmxForStaking(IERC20 _gmx, uint256 _amount) internal {
        address _sGmx = address(sGmx());
        uint256 allowance = _gmx.allowance(address(this), _sGmx);
        if (_amount > 0 && allowance > 0) {
            // reset the allowance to 0 if the approval is greater than zero and there is a non-zero allowance
            _gmx.safeApprove(_sGmx, 0);
        }

        _gmx.safeApprove(_sGmx, _amount);
    }

    function _withdrawAllGmx(address _recipient) internal {
        IERC20 _gmx = gmx();
        _gmx.safeTransfer(_recipient, _gmx.balanceOf(address(this)));
    }

    function _setIsAcceptingFullAccountTransfer(bool _isAcceptingFullAccountTransfer) internal {
        _setUint256(_IS_ACCEPTING_FULL_ACCOUNT_TRANSFER_SLOT, _isAcceptingFullAccountTransfer ? 1 : 0);
    }

    function _setHasAcceptedFullAccountTransfer(bool _hasAcceptingFullAccountTransfer) internal {
        _setUint256(_HAS_ACCEPTED_FULL_ACCOUNT_TRANSFER_SLOT, _hasAcceptingFullAccountTransfer ? 1 : 0);
    }

    function _getPairAmountNeededForEsGmxVesting(
        IGmxVester _vester,
        uint256 _esGmxAmount
    ) internal view returns (uint256) {
        address account = address(this);
        uint256 pairAmount = _vester.pairAmounts(account);
        uint256 nextPairAmount = _vester.getPairAmount(account, _esGmxAmount + _vester.balanceOf(account));
        if (nextPairAmount > pairAmount) {
            return nextPairAmount - pairAmount;
        } else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   ProxyContractHelpers
 * @author  Dolomite
 *
 * @notice  Helper functions for upgradeable proxy contracts to use
 */
abstract contract ProxyContractHelpers {

    // ================ Internal Functions ==================

    function _callImplementation(address _implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _setAddress(bytes32 slot, address _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function _setUint256(bytes32 slot, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function _getAddress(bytes32 slot) internal view returns (address value) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := sload(slot)
        }
    }

    function _getUint256(bytes32 slot) internal view returns (uint256 value) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := sload(slot)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IGLPIsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that are available on the GLPIsolationModeTokenVaultV1 implementation
 *          contract for each user's proxy vault.
 */
interface IGLPIsolationModeTokenVaultV1 {

    /**
     * @notice  Allows the user to claim all rewards and stake them if the user wants to. This function must be called
     *          by the vault owner.
     *
     * @param  _shouldClaimGmx                  `true` to claim GMX tokens from vGLP and vGMX vesting contracts, or
     *                                          `false` to skip.
     * @param  _shouldStakeGmx                  `true` to stake the claimed GMX tokens in this vault, or `false` to send
     *                                          them to the vault's owner.
     * @param  _shouldClaimEsGmx                `true` to claim esGMX tokens from sGMX and sGLP contracts, or `false` to
     *                                          skip.
     * @param  _shouldStakeEsGmx                `true` to stake the claimed esGMX tokens in this vault, or `false`
     *                                          to keep them idle in the vault. These tokens are non-transferable to the
     *                                          vault's owner.
     * @param  _shouldStakeMultiplierPoints     `true` to stake the claimed multiplier points in this vault, or `false`
     *                                          to skip.
     * @param  _shouldClaimWeth                 `true` to claim WETH tokens fee-tracking GLP/GMX contracts, or `false`
     *                                          to skip.
     * @param  _shouldDepositWethIntoDolomite   `true` to deposit the claimed WETH tokens into the vault owner's
     *                                          Dolomite account, or `false` to send them to the vault owner.
     * @param  _depositAccountNumberForWeth     The account number to which the WETH tokens should be deposited if
     *                                          the user decides to deposit them into Dolomite.
     */
    function handleRewardsWithSpecificDepositAccountNumber(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldDepositWethIntoDolomite,
        uint256 _depositAccountNumberForWeth
    )
    external;

    /**
     * @notice  The same function as #handleRewardsWithSpecificDepositAccountNumber but defaults
     *          `_depositAccountNumberForWeth` to `0`.
     */
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldDepositWethIntoDolomite
    )
    external;

    /**
     * @notice Transfers GMX tokens from the vault owner's account to this vault and stakes it.
     *
     * @param  _amount  The amount of GMX to stake. This function must be called by the vault owner.
     */
    function stakeGmx(uint256 _amount) external;

    /**
     * @notice Sends the unstaked GMX to the vault owner.
     *
     * @param  _amount  The amount of GMX to unstake. This function must be called by the vault owner.
     */
    function unstakeGmx(uint256 _amount) external;

    /**
     *
     * @param  _amount  The amount of esGMX to stake. This function must be called by the vault owner.
     */
    function stakeEsGmx(uint256 _amount) external;

    /**
     *
     * @param  _amount  The amount of esGMX to unstake. This function must be called by the vault owner.
     */
    function unstakeEsGmx(uint256 _amount) external;

    /**
     * @notice  Accepts a full account transfer from the sender's GMX account. There must not be any tokens in vesting
     *          and this contract must not have interacted with GMX yet for this to function. This function must be
     *          called by the vault owner.
     *
     * @param  _sender  The address of the GMX account whose entire account will be transferred to this vault
     */
    function acceptFullAccountTransfer(address _sender) external;

    /**
     * @notice  Deposits `_esGmxAmount` into the vesting contract along with GLP to be converted into GMX tokens. This
     *          function must be called by the vault owner.
     *
     * @param  _esGmxAmount The amount of esGMX to deposit into the vesting contract.
     */
    function vestGlp(uint256 _esGmxAmount) external;

    /**
     * @notice  Withdraws all esGMX that is vesting along with the paired fsGLP tokens used to vest the esGMX. Any
     *          remaining esGMX stays in this vault (it's non-transferable) along with the withdrawn fsGLP. The vested
     *          GMX tokens are sent to the vault owner. This function must be called by the vault owner.
     *
     * @param  _shouldStakeGmx  `true` to stake the GMX tokens in this vault, or `false` to send them to the vault
     *                          owner.
     */
    function unvestGlp(bool _shouldStakeGmx) external;

    /**
     * @notice  Deposits `_esGmxAmount` into the vesting contract along with sbfGMX to be converted into GMX tokens.
     *          This function must be called by the vault owner.
     *
     * @param  _esGmxAmount The amount of esGMX to deposit into the vesting contract.
     */
    function vestGmx(uint256 _esGmxAmount) external;

    /**
     * @notice  Withdraws all esGMX that is vesting along with the paired sbfGMX tokens used to vest the esGMX. Any
     *          remaining esGMX stays in this vault (it's non-transferable) along with the withdrawn sbfGMX. The vested
     *          GMX tokens are sent to the vault owner. This function must be called by the vault owner.
     *
     * @param  _shouldStakeGmx  `true` to stake the GMX tokens in this vault, or `false` to send them to the vault
     *                          owner.
     */
    function unvestGmx(bool _shouldStakeGmx) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IGmxRegistryV1 } from "./IGmxRegistryV1.sol";
import { IIsolationModeVaultFactory } from "../IIsolationModeVaultFactory.sol";


/**
 * @title   IGLPIsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  Interface for a subclass of IsolationModeVaultFactory that creates vaults for staked-GLP tokens.
 */
interface IGLPIsolationModeVaultFactory is IIsolationModeVaultFactory {

    // ================================================
    // ==================== Events ====================
    // ================================================

    event GmxRegistrySet(address _gmxRegistry);

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function createVaultAndAcceptFullAccountTransfer(address _sender) external returns (address);

    function setGmxRegistry(address _gmxRegistry) external;

    function WETH() external view returns (address);

    function WETH_MARKET_ID() external view returns (uint256);

    function gmxRegistry() external view returns (IGmxRegistryV1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IGLPManager
 * @author  Dolomite
 *
 * @notice  Interface for getting the AUM (highest bid and lowest ask) of GLP.
 */
interface IGLPManager {

    function getAumInUsdg(bool _maximise) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IGLPRewardsRouterV2
 * @author  Dolomite
 *
 * @notice  Interface of the GMX Reward Router V2 contract, taken from:
 *          https://arbiscan.io/address/0xB95DB5B167D75e6d04227CfFFA61069348d271F5#code
 */
interface IGLPRewardsRouterV2 {

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minAmountOut,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGLPManager } from "./IGLPManager.sol";
import { IGLPRewardsRouterV2 } from "./IGLPRewardsRouterV2.sol";
import { IGmxRegistryV1 } from "./IGmxRegistryV1.sol";
import { IGmxRewardRouterV2 } from "./IGmxRewardRouterV2.sol";
import { IGmxVault } from "./IGmxVault.sol";


/**
 * @title   IGmxRegistryV1
 * @author  Dolomite
 *
 * @notice  A registry contract for storing all of the different addresses that can interact with the GMX ecosystem
 */
interface IGmxRegistryV1 {

    // ================================================
    // ==================== Events ====================
    // ================================================

    event EsGmxSet(address _esGmx);
    event FSGlpSet(address _fsGlp);
    event GlpSet(address _glp);
    event GlpManagerSet(address _glpManager);
    event GlpRewardsRouterSet(address _glpRewardsRouter);
    event GmxSet(address _gmx);
    event GmxRewardsRouterSet(address _gmxRewardsRouter);
    event GmxVaultSet(address _gmxVaultSet);
    event SGlpSet(address _sGlp);
    event SGmxSet(address _sGmx);
    event SbfGmxSet(address _sbfGmx);
    event VGlpSet(address _vGlp);
    event VGmxSet(address _vGmx);

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function ownerSetEsGmx(address _esGmx) external;

    function ownerSetFSGlp(address _fsGlp) external;

    function ownerSetGlp(address _glp) external;

    function ownerSetGlpManager(address _glpManager) external;

    function ownerSetGlpRewardsRouter(address _glpRewardsRouter) external;

    function ownerSetGmx(address _gmx) external;

    function ownerSetGmxRewardsRouter(address _gmxRewardsRouter) external;

    function ownerSetGmxVault(address _gmxVault) external;

    function ownerSetSGlp(address _sGlp) external;

    function ownerSetSGmx(address _sGmx) external;

    function ownerSetSbfGmx(address _sbfGmx) external;

    function ownerSetVGlp(address _vGlp) external;

    function ownerSetVGmx(address _vGmx) external;

    function esGmx() external view returns (address);

    function fsGlp() external view returns (IERC20);

    function glp() external view returns (IERC20);

    function glpManager() external view returns (IGLPManager);

    function glpRewardsRouter() external view returns (IGLPRewardsRouterV2);

    function gmx() external view returns (IERC20);

    function gmxRewardsRouter() external view returns (IGmxRewardRouterV2);

    function gmxVault() external view returns (IGmxVault);

    function sGlp() external view returns (address);

    function sGmx() external view returns (address);

    function sbfGmx() external view returns (address);

    function vGlp() external view returns (address);

    function vGmx() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IGmxRewardRouterV2
 * @author  Dolomite
 *
 * @notice  Interface of the GMX Reward Router V2 contract, taken from:
 *          https://arbiscan.io/address/0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1#code
 */
interface IGmxRewardRouterV2 {

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function stakeGmx(uint256 _amount) external;

    function unstakeGmx(uint256 _amount) external;

    function stakeEsGmx(uint256 _amount) external;

    function unstakeEsGmx(uint256 _amount) external;

    function signalTransfer(address _receiver) external;

    function acceptTransfer(address _sender) external;

    /**
     * @notice              Checks if a pending transfer has been queued from `_sender` via a call to #signalTransfer
     *
     * @param  _sender      The address to check if a transfer from which has been queued
     * @return _receiver    The address to which the transfer will be sent if it's executed from the queue
     */
    function pendingReceivers(address _sender) external view returns (address _receiver);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IGmxVault
 * @author  Dolomite
 *
 * @notice  The vault contract used by GMX for holding the assets that back GLP.
 */
interface IGmxVault {

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) external view returns (uint256);

    function usdg() external view returns (address);

    function getMinPrice(address _token) external view returns (uint256);

    function whitelistedTokens(address _token) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title   IGmxVester
 * @author  Dolomite
 *
 * @notice  The interface contract used by GMX for vesting esGMX into GMX.
 */
interface IGmxVester is IERC20 {

    /**
     * @notice          Deposits esGMX for vesting into GMX.  msg.sender will also need to pay sGLP tokens.
     *
     * @param  _amount  The amount of esGMX to deposit for vesting into GMX.
     */
    function deposit(uint256 _amount) external;

    /**
     * @notice  Withdraws all of msg.sender's tokens from the vault and stops vesting for esGMX into GMX.  msg.sender
     *          will receive GMX, esGMX, and sGLP tokens.
     */
    function withdraw() external;

    /**
     * @notice Gets the account's sGLP balance, which is paired with esGMX for vesting into GMX.
     *
     * @param  _account The account whose sGLP balance should be retrieved.
     */
    function pairAmounts(address _account) external view returns (uint256);

    /**
     * @notice Gets the amount of GMX  will be received for the given amount of esGMX.
     */
    function getPairAmount(address _account, uint256 _esAmount) external view returns (uint256);

    function getMaxVestableAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title   ISGMX
 * @author  Dolomite
 *
 * @notice  This is the intermediary token used during the staking process for GMX. We use this contract to distinguish
 *          between GMX esGMX deposited for staking to receive sbfGMX. The contract address on Arbitrum Mainnet is:
 *          0x908C4D94D34924765f1eDc22A1DD098397c59dD4
 */
interface ISGMX is IERC20 {

    function depositBalances(address _account, address _depositToken) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IAuthorizationBase
 * @author  Dolomite
 *
 * @notice  Interface for allowing only trusted callers to invoke functions that use the `requireIsCallerAuthorized`
 *          modifier.
 */
interface IAuthorizationBase {

    function setIsCallerAuthorized(address _caller, bool _isAuthorized) external;

    function isCallerAuthorized(address _caller) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IAuthorizationBase } from "./IAuthorizationBase.sol";
import { AccountBalanceLib } from "../lib/AccountBalanceLib.sol";


/**
 * @title   IBorrowPositionProxyV2
 * @author  Dolomite
 *
 * @notice  Interface for allowing only trusted callers to invoke borrow related functions for transferring funds
 *          between account owners.
 */
interface IBorrowPositionProxyV2 is IAuthorizationBase {

    // ========================= Functions =========================

    /**
     *
     * @param  _fromAccountOwner    The account from which the user will be sourcing the deposit
     * @param  _fromAccountNumber   The index from which `_toAccountOwner` will be sourcing the deposit
     * @param  _toAccountOwner      The account into which `_fromAccountOwner` will be depositing
     * @param  _toAccountNumber     The index into which `_fromAccountOwner` will be depositing
     * @param  _collateralMarketId  The ID of the market being deposited
     * @param  _amountWei           The amount, in Wei, to deposit
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function openBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  This method can only be called once the user's debt has been reduced to zero. Sends all
     *          `_collateralMarketIds` from `_borrowAccountNumber` to `_toAccountNumber`.
     *
     * @param  _borrowAccountOwner  The account from which collateral will be withdrawn
     * @param  _borrowAccountNumber The index from which `msg.sender` collateral will be withdrawn
     * @param  _toAccountOwner      The account into which `_borrowAccountOwner` will be depositing leftover collateral
     * @param  _toAccountNumber     The index into which `_borrowAccountOwner` will be depositing leftover collateral
     * @param  _collateralMarketIds The IDs of the markets being withdrawn, to close the position
     */
    function closeBorrowPositionWithDifferentAccounts(
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external;

    /**
     *
     * @param  _fromAccountOwner    The account from which assets will be withdrawn
     * @param  _fromAccountNumber   The index from which `msg.sender` will be withdrawing assets
     * @param  _toAccountOwner      The account to which assets will be deposited
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _amountWei           The amount, in Wei, to transfer
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function transferBetweenAccountsWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     *
     * @param  _fromAccountOwner    The account from which assets will be withdrawn for repayment
     * @param  _fromAccountNumber   The index from which `msg.sender` will be depositing assets
     * @param  _borrowAccountOwner  The account of the borrow position that will receive the deposited assets
     * @param  _borrowAccountNumber The index of the borrow position for that will receive the deposited assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_borrowAccountNumber`, or both accounts
     *                              can go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function repayAllForBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { AccountBalanceLib } from "../lib/AccountBalanceLib.sol";


/**
 * @title   IIsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice Interface for the implementation contract used by proxy user vault contracts.
 */
interface IIsolationModeTokenVaultV1 {

    // ===========================================================
    // ======================== Functions ========================
    // ===========================================================

    /**
     * @notice  End-user function for depositing the vault factory's underlying token into DolomiteMargin. Should only
     *          be executable by the vault owner OR the vault factory.
     */
    function depositIntoVaultForDolomiteMargin(uint256 _toAccountNumber, uint256 _amountWei) external;

    /**
     * @notice  End-user function for withdrawing the vault factory's underlying token from DolomiteMargin. Should only
     *          be executable by the vault owner.
     */
    function withdrawFromVaultForDolomiteMargin(uint256 _fromAccountNumber, uint256 _amountWei) external;

    /**
     * @notice  End-user function for opening a borrow position involving the vault factory's underlying token. Should
     *          only be executable by the vault owner.
     */
    function openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) external;

    /**
     * @notice  End-user function for closing a borrow position involving the vault factory's underlying token. Should
     *          only be executable by the vault owner.
     */
    function closeBorrowPositionWithUnderlyingVaultToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber
    ) external;

    /**
     * @notice  End-user function for closing a borrow position involving anything BUT the vault factory's underlying
     *          token. Should only be executable by the vault owner. Throws if any of the `collateralMarketIds` is set
     *          to the vault factory's underlying token.
     */
    function closeBorrowPositionWithOtherTokens(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata collateralMarketIds
    ) external;

    /**
     * @notice  End-user function for transferring collateral into a position using the vault factory's underlying
     *          token. Should only be executable by the vault owner.
     */
    function transferIntoPositionWithUnderlyingToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _amountWei
    ) external;

    /**
     * @notice  End-user function for transferring collateral into a position using anything BUT the vault factory's
     *          underlying token. Should only be executable by the vault owner. Throws if the `_marketId` is set to the
     *          vault factory's underlying token.
     */
    function transferIntoPositionWithOtherToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  End-user function for transferring collateral from a position using the vault factory's underlying
     *          token. Should only be executable by the vault owner.
     */
    function transferFromPositionWithUnderlyingToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) external;

    /**
     * @notice  End-user function for transferring collateral from a position using anything BUT the vault factory's
     *          underlying token. Should only be executable by the vault owner. Throws if the `_marketId` is set to the
     *          vault factory's underlying token.
     */
    function transferFromPositionWithOtherToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  End-user function for transferring collateral involving anything BUT the vault factory's underlying
     *          token. Should only be executable by the vault owner. Throws if the `_marketId` is set to the vault
     *          factory's underlying token.
     */
    function repayAllForBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  Attempts to deposit assets into this vault from the vault's owner. Should revert if the caller is not
     *          the Vault Factory.
     *
     * @param  _from    The sender of the tokens into this vault.
     * @param  _amount  The amount of the vault's underlying token to transfer.
     */
    function executeDepositIntoVault(address _from, uint256 _amount) external;

    /**
     * @notice  Attempts to withdraw assets from this vault to the recipient. Should revert if the caller is not the
     *          Vault Factory.
     *
     * @param  _recipient   The address to receive the withdrawal.
     * @param  _amount      The amount of the vault's underlying token to transfer out.
     */
    function executeWithdrawalFromVault(address _recipient, uint256 _amount) external;

    /**
     * @return The amount of `UNDERLYING_TOKEN` that are currently in this vault.
     */
    function underlyingBalanceOf() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IIsolationModeUpgradeableProxy
 * @author  Dolomite
 *
 * @notice  The interface for the upgradeable proxy contract that holds each user's tokens that are wrapped by the
 *          IsolationModeVaultFactory.
 */
interface IIsolationModeUpgradeableProxy {

    /**
     *
     * @param  _account The owner of this vault contract
     */
    function initialize(address _account) external;

    function isInitialized() external view returns (bool);

    function implementation() external view returns (address);

    function vaultFactory() external view returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IBorrowPositionProxyV2 } from "./IBorrowPositionProxyV2.sol";
import { IOnlyDolomiteMargin } from "./IOnlyDolomiteMargin.sol";


/**
 * @title   IIsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice A wrapper contract around a certain token to offer isolation mode features for DolomiteMargin.
 */
interface IIsolationModeVaultFactory is IOnlyDolomiteMargin {

    // =================================================
    // ==================== Structs ====================
    // =================================================

    struct QueuedTransfer {
        address from;
        address to;
        uint256 amount;
        address vault;
        bool isExecuted;
    }

    // ================================================
    // ==================== Events ====================
    // ================================================

    event UserVaultImplementationSet(
        address indexed previousUserVaultImplementation,
        address indexed newUserVaultImplementation
    );

    event TokenConverterSet(address indexed tokenConverter, bool isTrusted);

    event VaultCreated(address indexed account, address vault);

    event Initialized();

    event TransferQueued(
        uint256 indexed transferCursor,
        address from,
        address to,
        uint256 amountWei,
        address vault
    );

    // ======================================================
    // ================== Admin Functions ===================
    // ======================================================

    /**
     * @notice  Initializes this contract's variables that are dependent on this token being added to DolomiteMargin.
     */
    function ownerInitialize(address[] calldata _tokenConverters) external;

    /**
     *
     * @param  _userVaultImplementation  The address of the new vault implementation contract
     */
    function ownerSetUserVaultImplementation(address _userVaultImplementation) external;

    /**
     * @notice  A token converter is used to convert this underlying token into a Dolomite-compatible one for deposit
     *          or withdrawal
     *
     * @param  _tokenConverter   The address of the token converter contract to set whether or not it's trusted for
     *                          executing transfers to/from vaults
     * @param  _isTrusted        True if the token converter is trusted, false otherwise
     */
    function ownerSetIsTokenConverterTrusted(address _tokenConverter, bool _isTrusted) external;

    // ======================================================
    // ================== User Functions ===================
    // ======================================================

    /**
     * @notice  Creates the vault for `_account`
     *
     * @param  _account  The account owner to create the vault for
     */
    function createVault(address _account) external returns (address);

    /**
     * @notice  Creates the vault for `msg.sender`
     *
     * @param  _toAccountNumber  The account number of the account to which the tokens will be deposited
     * @param  _amountWei        The amount of tokens to deposit
     */
    function createVaultAndDepositIntoDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) external returns (address);

    /**
     * @notice  Deposits a token into the vault owner's account at `_toAccountNumber`. This function can only be called
     *          by a user's vault contract. Reverts if `_marketId` is set to the market ID of this vault.
     *
     * @param  _toAccountNumber  The account number of the account to which the tokens will be deposited
     * @param  _marketId         The market ID of the token to deposit
     * @param  _amountWei        The amount of tokens to deposit
     */
    function depositOtherTokenIntoDolomiteMarginForVaultOwner(
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  Enqueues a transfer into Dolomite Margin from the vault. Assumes msg.sender is a trusted token
     *          converter, else reverts. Reverts if `_vault` is not a valid vault contract.
     *
     * @param  _vault        The address of the vault that the token converter is interacting with
     * @param  _amountWei    The amount of tokens to transfer into Dolomite Margin
     */
    function enqueueTransferIntoDolomiteMargin(
        address _vault,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  Enqueues a transfer from Dolomite Margin to the token converter. Assumes msg.sender is a trusted token
     *          converter, else reverts. Reverts if `_vault` is not a valid vault contract.
     *
     * @param  _vault        The address of the vault that the token converter is interacting with
     * @param  _amountWei    The amount of tokens to transfer from Dolomite Margin to the token converter
     */
    function enqueueTransferFromDolomiteMargin(
        address _vault,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  This function should only be called by a user's vault contract
     *
     * @param  _toAccountNumber  The account number of the account to which the tokens will be deposited
     * @param  _amountWei        The amount of tokens to deposit
     */
    function depositIntoDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  This function should only be called by a user's vault contract
     *
     * @param  _fromAccountNumber    The account number of the account from which the tokens will be withdrawn
     * @param  _amountWei            The amount of tokens to withdraw
     */
    function withdrawFromDolomiteMargin(
        uint256 _fromAccountNumber,
        uint256 _amountWei
    )
    external;

    // ============================================
    // ================= Constants ================
    // ============================================

    /**
     * @return  The market ID of the single element array returned by #allowableCollateralMarketIds() if no other
     *          collateral assets are allowed
     */
    function NONE() external view returns (uint256);

    /**
     * @return The address of the token that this vault wraps around
     */
    function UNDERLYING_TOKEN() external view returns (address);

    /**
     * @return  The address of the BorrowPositionProxyV2 contract
     */
    function BORROW_POSITION_PROXY() external view returns (IBorrowPositionProxyV2);

    // =================================================
    // ================= View Functions ================
    // =================================================

    /**
     * @return  The market ID of this token contract according to DolomiteMargin. This value is initializes in the
     *          #initialize function
     */
    function marketId() external view returns (uint256);

    /**
     * @return  This function should always return `true`. It's used by The Graph to index this contract as a Wrapper.
     */
    function isIsolationAsset() external view returns (bool);

    /**
     *
     * @param  _transferCursor   The cursor used to key into the mapping of queued transfers
     * @return The transfer enqueued in the mapping at the cursor's position
     */
    function getQueuedTransferByCursor(uint256 _transferCursor) external view returns (QueuedTransfer memory);

    /**
     * @return  The market IDs of the assets that can be borrowed in a position with this wrapped asset. An empty array
     *          indicates that any non-isolation mode asset can be borrowed against it.
     */
    function allowableDebtMarketIds() external view returns (uint256[] memory);

    /**
     * @return  The market IDs of the assets that can be used as collateral in a position with this wrapped asset. An
     *          empty array indicates that any non-isolation mode asset can be borrowed against it. To indicate that no
     *          assets can be used as collateral, return an array with a single element containing #NONE.
     */
    function allowableCollateralMarketIds() external view returns (uint256[] memory);

    /**
     * @return  The address of the current vault implementation contract
     */
    function userVaultImplementation() external view returns (address);

    /**
     *
     * @param  _account  The account owner to get the vault for
     * @return  _vault   The address of the vault created for `_account`. Returns address(0) if no vault has been
     *                   created yet for this account.
     */
    function getVaultByAccount(address _account) external view returns (address _vault);

    /**
     * @notice  Same as `getVaultByAccount`, but always returns the user's non-zero vault address.
     */
    function calculateVaultByAccount(address _account) external view returns (address _vault);

    /**
     *
     * @param  _vault    The vault that's used by an account for depositing/withdrawing
     * @return  _account The address of the account that owns the `_vault`
     */
    function getAccountByVault(address _vault) external view returns (address _account);

    /**
     * @notice  A token converter is used to convert this underlying token into a Dolomite-compatible one for deposit
     *          or withdrawal
     * @return  True if the token converter is currently in-use by this contract.
     */
    function isTokenConverterTrusted(address _tokenConverter) external view returns (bool);

    function getProxyVaultInitCodeHash() external pure returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   IOnlyDolomiteMargin
 * @author  Dolomite
 *
 * @notice  This interface is for contracts that need to add modifiers for only DolomiteMargin / Owner caller.
 */
interface IOnlyDolomiteMargin {

    function DOLOMITE_MARGIN() external view returns (IDolomiteMargin);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../../protocol/interfaces/IDolomiteStructs.sol";

import { Require } from "../../protocol/lib/Require.sol";
import { TypesLib } from "../../protocol/lib/TypesLib.sol";


/**
 * @title   AccountBalanceLib
 * @author  Dolomite
 *
 * @notice  Library contract that checks a user's balance after transaction to be non-negative
 */
library AccountBalanceLib {
    using TypesLib for IDolomiteStructs.Par;

    // ============ Types ============

    /// Checks that either BOTH, FROM, or TO accounts all have non-negative balances
    enum BalanceCheckFlag {
        Both,
        From,
        To,
        None
    }

    // ============ Constants ============

    bytes32 private constant _FILE = "AccountBalanceLib";

    // ============ Functions ============

    /**
     *  Checks that the account's balance is non-negative. Reverts if the check fails
     */
    function verifyBalanceIsNonNegative(
        IDolomiteMargin dolomiteMargin,
        address _accountOwner,
        uint256 _accountNumber,
        uint256 _marketId
    ) internal view {
        IDolomiteStructs.AccountInfo memory account = IDolomiteStructs.AccountInfo({
            owner: _accountOwner,
            number: _accountNumber
        });
        IDolomiteStructs.Par memory par = dolomiteMargin.getAccountPar(account, _marketId);
        Require.that(
            par.isPositive() || par.isZero(),
            _FILE,
            "account cannot go negative",
            _accountOwner,
            _accountNumber,
            _marketId
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IDolomiteMargin } from "../../../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../../../protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "../../../protocol/lib/Require.sol";
import { TypesLib } from "../../../protocol/lib/TypesLib.sol";
import { IBorrowPositionProxyV2 } from "../../interfaces/IBorrowPositionProxyV2.sol";
import { IIsolationModeTokenVaultV1 } from "../../interfaces/IIsolationModeTokenVaultV1.sol";
import { IIsolationModeUpgradeableProxy } from "../../interfaces/IIsolationModeUpgradeableProxy.sol";
import { IIsolationModeVaultFactory } from "../../interfaces/IIsolationModeVaultFactory.sol";
import { AccountBalanceLib } from "../../lib/AccountBalanceLib.sol";


/**
 * @title   IsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  Abstract implementation (for an upgradeable proxy) for wrapping tokens via a per-user vault that can be used
 *          with DolomiteMargin
 */
abstract contract IsolationModeTokenVaultV1 is IIsolationModeTokenVaultV1 {
    using SafeERC20 for IERC20;
    using TypesLib for IDolomiteMargin.Par;

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "IsolationModeTokenVaultV1";
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // =================================================
    // ================ Field Variables ================
    // =================================================

    uint256 private _reentrancyGuard;

    // ===================================================
    // ==================== Modifiers ====================
    // ===================================================

    modifier onlyVaultFactory(address _from) {
        Require.that(
            _from == address(VAULT_FACTORY()),
            _FILE,
            "Only factory can call",
            _from
        );
        _;
    }

    modifier onlyVaultOwner(address _from) {
        Require.that(
            _from == _proxySelf().owner(),
            _FILE,
            "Only owner can call",
            _from
        );
        _;
    }

    modifier onlyVaultOwnerOrVaultFactory(address _from) {
        Require.that(
            _from == address(_proxySelf().owner()) || _from == VAULT_FACTORY(),
            _FILE,
            "Only owner or factory can call",
            _from
        );
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly. Calling a `nonReentrant` function from
     *      another `nonReentrant` function is not supported. It is possible to prevent this from happening by making
     *      the `nonReentrant` function external, and making it call a `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _reentrancyGuard will be _NOT_ENTERED
        Require.that(
            _reentrancyGuard != _ENTERED,
            _FILE,
            "Reentrant call"
        );

        // Any calls to nonReentrant after this point will fail
        _reentrancyGuard = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyGuard = _NOT_ENTERED;
    }

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function initialize() external {
        Require.that(
            _reentrancyGuard == 0,
            _FILE,
            "Already initialized"
        );

        _reentrancyGuard = _NOT_ENTERED;
    }

    function depositIntoVaultForDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external
    onlyVaultOwnerOrVaultFactory(msg.sender) {
        // This implementation requires we deposit into index 0
        Require.that(
            _toAccountNumber == 0,
            _FILE,
            "Invalid toAccountNumber",
            _toAccountNumber
        );
        IIsolationModeVaultFactory(VAULT_FACTORY()).depositIntoDolomiteMargin(_toAccountNumber, _amountWei);
    }

    function withdrawFromVaultForDolomiteMargin(
        uint256 _fromAccountNumber,
        uint256 _amountWei
    )
    external
    onlyVaultOwner(msg.sender) {
        // This implementation requires we withdraw from index 0
        Require.that(
            _fromAccountNumber == 0,
            _FILE,
            "Invalid fromAccountNumber",
            _fromAccountNumber
        );
        IIsolationModeVaultFactory(VAULT_FACTORY()).withdrawFromDolomiteMargin(_fromAccountNumber, _amountWei);
    }

    function openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external
    virtual
    onlyVaultOwner(msg.sender) {
        _openBorrowPosition(_fromAccountNumber, _toAccountNumber, _amountWei);
    }

    function closeBorrowPositionWithUnderlyingVaultToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber
    )
    external
    virtual
    onlyVaultOwner(msg.sender) {
        Require.that(
            _borrowAccountNumber != 0,
            _FILE,
            "Invalid borrowAccountNumber",
            _borrowAccountNumber
        );
        Require.that(
            _toAccountNumber == 0,
            _FILE,
            "Invalid toAccountNumber",
            _toAccountNumber
        );

        uint256[] memory collateralMarketIds = new uint256[](1);
        collateralMarketIds[0] = marketId();

        BORROW_POSITION_PROXY().closeBorrowPositionWithDifferentAccounts(
            /* _borrowAccountOwner = */ address(this),
            _borrowAccountNumber,
            /* _toAccountOwner = */ address(this),
            _toAccountNumber,
            collateralMarketIds
        );
    }

    function closeBorrowPositionWithOtherTokens(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    )
    external
    virtual
    onlyVaultOwner(msg.sender) {
        _closeBorrowPositionWithOtherTokens(_borrowAccountNumber, _toAccountNumber, _collateralMarketIds);
    }

    function transferIntoPositionWithUnderlyingToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _amountWei
    )
    external
    virtual
    onlyVaultOwner(msg.sender) {
        _transferIntoPositionWithUnderlyingToken(_fromAccountNumber, _borrowAccountNumber, _amountWei);
    }

    function transferIntoPositionWithOtherToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    )
    external
    virtual
    onlyVaultOwner(msg.sender) {
        Require.that(
            _marketId != marketId(),
            _FILE,
            "Invalid marketId",
            _marketId
        );

        BORROW_POSITION_PROXY().transferBetweenAccountsWithDifferentAccounts(
            /* _fromAccountOwner = */ msg.sender,
            _fromAccountNumber,
            /* _toAccountOwner = */ address(this),
            _borrowAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag
        );

        _checkAllowableCollateralMarket(address(this), _borrowAccountNumber, _marketId);
    }

    function transferFromPositionWithUnderlyingToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external
    virtual
    onlyVaultOwner(msg.sender) {
        Require.that(
            _borrowAccountNumber != 0,
            _FILE,
            "Invalid borrowAccountNumber",
            _borrowAccountNumber
        );
        Require.that(
            _toAccountNumber == 0,
            _FILE,
            "Invalid toAccountNumber",
            _toAccountNumber
        );

        BORROW_POSITION_PROXY().transferBetweenAccountsWithDifferentAccounts(
            /* _fromAccountOwner = */ address(this),
            _borrowAccountNumber,
            /* _toAccountOwner = */ address(this),
            _toAccountNumber,
            marketId(),
            _amountWei,
            AccountBalanceLib.BalanceCheckFlag.Both
        );
    }

    function transferFromPositionWithOtherToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    )
    external
    virtual
    onlyVaultOwner(msg.sender) {
        _transferFromPositionWithOtherToken(
            _borrowAccountNumber,
            _toAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag
        );
    }

    function repayAllForBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    )
    external
    virtual
    onlyVaultOwner(msg.sender) {
        Require.that(
            _marketId != marketId(),
            _FILE,
            "Invalid marketId",
            _marketId
        );
        BORROW_POSITION_PROXY().repayAllForBorrowPositionWithDifferentAccounts(
            /* _fromAccountOwner = */ msg.sender,
            _fromAccountNumber,
            /* _borrowAccountOwner = */ address(this),
            _borrowAccountNumber,
            _marketId,
            _balanceCheckFlag
        );
    }

    // ======== Public functions ========

    function executeDepositIntoVault(
        address _from,
        uint256 _amount
    )
    public
    virtual
    onlyVaultFactory(msg.sender) {
        IERC20(UNDERLYING_TOKEN()).safeTransferFrom(_from, address(this), _amount);
    }

    function executeWithdrawalFromVault(
        address _recipient,
        uint256 _amount
    )
    public
    virtual
    onlyVaultFactory(msg.sender) {
        assert(_recipient != address(this));
        IERC20(UNDERLYING_TOKEN()).safeTransfer(_recipient, _amount);
    }

    function UNDERLYING_TOKEN() public view returns (address) {
        return IIsolationModeVaultFactory(VAULT_FACTORY()).UNDERLYING_TOKEN();
    }

    function DOLOMITE_MARGIN() public view returns (IDolomiteMargin) {
        return IIsolationModeVaultFactory(VAULT_FACTORY()).DOLOMITE_MARGIN();
    }

    function BORROW_POSITION_PROXY() public view returns (IBorrowPositionProxyV2) {
        return IIsolationModeVaultFactory(VAULT_FACTORY()).BORROW_POSITION_PROXY();
    }

    function VAULT_FACTORY() public virtual view returns (address) {
        return _proxySelf().vaultFactory();
    }

    function marketId() public view returns (uint256) {
        return IIsolationModeVaultFactory(VAULT_FACTORY()).marketId();
    }

    function underlyingBalanceOf() public override virtual view returns (uint256) {
        return IERC20(UNDERLYING_TOKEN()).balanceOf(address(this));
    }

    // ============ Internal Functions ============

    function _openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    internal {
        Require.that(
            _fromAccountNumber == 0,
            _FILE,
            "Invalid fromAccountNumber",
            _fromAccountNumber
        );
        Require.that(
            _toAccountNumber != 0,
            _FILE,
            "Invalid toAccountNumber",
            _toAccountNumber
        );

        BORROW_POSITION_PROXY().openBorrowPositionWithDifferentAccounts(
        /* _fromAccountOwner = */ address(this),
            _fromAccountNumber,
            /* _toAccountOwner = */ address(this),
            _toAccountNumber,
            marketId(),
            _amountWei,
            AccountBalanceLib.BalanceCheckFlag.Both
        );
    }

    function _closeBorrowPositionWithOtherTokens(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    )
    internal {
        uint256 underlyingMarketId = marketId();
        for (uint256 i = 0; i < _collateralMarketIds.length; i++) {
            Require.that(
                _collateralMarketIds[i] != underlyingMarketId,
                _FILE,
                "Cannot withdraw market to wallet",
                underlyingMarketId
            );
        }

        BORROW_POSITION_PROXY().closeBorrowPositionWithDifferentAccounts(
        /* _borrowAccountOwner = */ address(this),
            _borrowAccountNumber,
            /* _toAccountOwner = */ msg.sender,
            _toAccountNumber,
            _collateralMarketIds
        );
    }

    function _transferIntoPositionWithUnderlyingToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _amountWei
    ) internal {
        Require.that(
            _fromAccountNumber == 0,
            _FILE,
            "Invalid fromAccountNumber",
            _fromAccountNumber
        );
        Require.that(
            _borrowAccountNumber != 0,
            _FILE,
            "Invalid borrowAccountNumber",
            _borrowAccountNumber
        );

        BORROW_POSITION_PROXY().transferBetweenAccountsWithDifferentAccounts(
            /* _fromAccountOwner = */ address(this),
            _fromAccountNumber,
            /* _toAccountOwner = */ address(this),
            _borrowAccountNumber,
            marketId(),
            _amountWei,
            AccountBalanceLib.BalanceCheckFlag.Both
        );
    }

    function _transferFromPositionWithOtherToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) internal {
        Require.that(
            _marketId != marketId(),
            _FILE,
            "Invalid marketId",
            _marketId
        );

        BORROW_POSITION_PROXY().transferBetweenAccountsWithDifferentAccounts(
        /* _fromAccountOwner = */ address(this),
            _borrowAccountNumber,
            /* _toAccountOwner = */ msg.sender,
            _toAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag
        );

        _checkAllowableDebtMarket(address(this), _borrowAccountNumber, _marketId);
    }

    function _checkAllowableCollateralMarket(
        address _accountOwner,
        uint256 _accountNumber,
        uint256 _marketId
    ) internal view {
        // If the balance is positive, check that the collateral is for an allowable market. We use the Par balance
        // because, it uses less gas than getting the Wei balance, and we're only checking whether the balance is
        // positive.
        IDolomiteStructs.Par memory balancePar = DOLOMITE_MARGIN().getAccountPar(
            IDolomiteStructs.AccountInfo({
                owner: _accountOwner,
                number: _accountNumber
            }),
            _marketId
        );
        if (balancePar.isPositive()) {
            // Check the allowable collateral markets for the position:
            IIsolationModeVaultFactory vaultFactory = IIsolationModeVaultFactory(VAULT_FACTORY());
            uint256[] memory allowableCollateralMarketIds = vaultFactory.allowableCollateralMarketIds();
            if (allowableCollateralMarketIds.length != 0) {
                bool isAllowable = false;
                for (uint256 i = 0; i < allowableCollateralMarketIds.length; i++) {
                    if (allowableCollateralMarketIds[i] == _marketId) {
                        isAllowable = true;
                        break;
                    }
                }
                Require.that(
                    isAllowable,
                    _FILE,
                    "Market not allowed as collateral",
                    _marketId
                );
            }
        }
    }

    function _proxySelf() internal view returns (IIsolationModeUpgradeableProxy) {
        return IIsolationModeUpgradeableProxy(address(this));
    }

    function _checkAllowableDebtMarket(
        address _accountOwner,
        uint256 _accountNumber,
        uint256 _marketId
    ) internal view {
        // If the balance is negative, check that the debt is for an allowable market. We use the Par balance because,
        // it uses less gas than getting the Wei balance, and we're only checking whether the balance is negative.
        IDolomiteStructs.Par memory balancePar = DOLOMITE_MARGIN().getAccountPar(
            IDolomiteStructs.AccountInfo({
                owner: _accountOwner,
                number: _accountNumber
            }),
            _marketId
        );
        if (balancePar.isNegative()) {
            // Check the allowable debt markets for the position:
            IIsolationModeVaultFactory vaultFactory = IIsolationModeVaultFactory(VAULT_FACTORY());
            uint256[] memory allowableDebtMarketIds = vaultFactory.allowableDebtMarketIds();
            if (allowableDebtMarketIds.length != 0) {
                bool isAllowable = false;
                for (uint256 i = 0; i < allowableDebtMarketIds.length; i++) {
                    if (allowableDebtMarketIds[i] == _marketId) {
                        isAllowable = true;
                        break;
                    }
                }
                Require.that(
                    isAllowable,
                    _FILE,
                    "Market not allowed as debt",
                    _marketId
                );
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteInterestSetter
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that for an interest setter that can be used to determine the interest
 *          rate of a market.
 */
interface IDolomiteInterestSetter {

    // ============ Structs ============

    struct InterestRate {
        uint256 value;
    }

    // ============ Functions ============

    /**
     * Get the interest rate of a token given some borrowed and supplied amounts
     *
     * @param  token        The address of the ERC20 token for the market
     * @param  borrowWei    The total borrowed token amount for the market
     * @param  supplyWei    The total supplied token amount for the market
     * @return              The interest rate per second
     */
    function getInterestRate(
        address token,
        uint256 borrowWei,
        uint256 supplyWei
    )
    external
    view
    returns (InterestRate memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomiteMarginAdmin } from "./IDolomiteMarginAdmin.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteMargin
 * @author  Dolomite
 *
 * @notice  The interface for interacting with the main entry-point to DolomiteMargin
 */
interface IDolomiteMargin is IDolomiteMarginAdmin {

    // ==================================================
    // ================= Write Functions ================
    // ==================================================

    /**
     * The main entry-point to DolomiteMargin that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        AccountInfo[] calldata accounts,
        ActionArgs[] calldata actions
    ) external;

    /**
     * Approves/disapproves any number of operators. An operator is an external address that has the
     * same permissions to manipulate an account as the owner of the account. Operators are simply
     * addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
     *
     * Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
     * operator is a smart contract and implements the IAutoTrader interface.
     *
     * @param  args  A list of OperatorArgs which have an address and a boolean. The boolean value
     *               denotes whether to approve (true) or revoke approval (false) for that address.
     */
    function setOperators(
        OperatorArg[] calldata args
    ) external;

    // ==================================================
    // ================= Read Functions ================
    // ==================================================

    // ============ Getters for Markets ============

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  token    The token to query
     * @return          The token's marketId if the token is valid
     */
    function getMarketIdByTokenAddress(
        address token
    ) external view returns (uint256);

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  marketId  The market to query
     * @return           The token address
     */
    function getMarketTokenAddress(
        uint256 marketId
    ) external view returns (address);

    /**
     * Return true if a particular market is in closing mode. Additional borrows cannot be taken
     * from a market that is closing.
     *
     * @param  marketId  The market to query
     * @return           True if the market is closing
     */
    function getMarketIsClosing(
        uint256 marketId
    )
    external
    view
    returns (bool);

    /**
     * Get the price of the token for a market.
     *
     * @param  marketId  The market to query
     * @return           The price of each atomic unit of the token
     */
    function getMarketPrice(
        uint256 marketId
    ) external view returns (MonetaryPrice memory);

    /**
     * Get the total number of markets.
     *
     * @return  The number of markets
     */
    function getNumMarkets() external view returns (uint256);

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalPar(
        uint256 marketId
    ) external view returns (TotalPar memory);

    /**
     * Get the most recently cached interest index for a market.
     *
     * @param  marketId  The market to query
     * @return           The most recent index
     */
    function getMarketCachedIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the interest index for a market if it were to be updated right now.
     *
     * @param  marketId  The market to query
     * @return           The estimated current index
     */
    function getMarketCurrentIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the price oracle address for a market.
     *
     * @param  marketId  The market to query
     * @return           The price oracle address
     */
    function getMarketPriceOracle(
        uint256 marketId
    ) external view returns (IDolomitePriceOracle);

    /**
     * Get the interest-setter address for a market.
     *
     * @param  marketId  The market to query
     * @return           The interest-setter address
     */
    function getMarketInterestSetter(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter);

    /**
     * Get the margin premium for a market. A margin premium makes it so that any positions that
     * include the market require a higher collateralization to avoid being liquidated.
     *
     * @param  marketId  The market to query
     * @return           The market's margin premium
     */
    function getMarketMarginPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketSpreadPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Return true if this market can be removed and its ID can be recycled and reused
     *
     * @param  marketId  The market to query
     * @return           True if the market is recyclable
     */
    function getMarketIsRecyclable(
        uint256 marketId
    ) external view returns (bool);

    /**
     * Gets the recyclable markets, up to `n` length. If `n` is greater than the length of the list, 0's are returned
     * for the empty slots.
     *
     * @param  n    The number of markets to get, bounded by the linked list being smaller than `n`
     * @return      The list of recyclable markets, in the same order held by the linked list
     */
    function getRecyclableMarkets(
        uint256 n
    ) external view returns (uint[] memory);

    /**
     * Get the current borrower interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current interest rate
     */
    function getMarketInterestRate(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter.InterestRate memory);

    /**
     * Get basic information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A Market struct with the current state of the market
     */
    function getMarket(
        uint256 marketId
    ) external view returns (Market memory);

    /**
     * Get comprehensive information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A tuple containing the values:
     *                    - A Market struct with the current state of the market
     *                    - The current estimated interest index
     *                    - The current token price
     *                    - The current market interest rate
     */
    function getMarketWithInfo(
        uint256 marketId
    )
    external
    view
    returns (
        Market memory,
        InterestIndex memory,
        MonetaryPrice memory,
        IDolomiteInterestSetter.InterestRate memory
    );

    /**
     * Get the number of excess tokens for a market. The number of excess tokens is calculated by taking the current
     * number of tokens held in DolomiteMargin, adding the number of tokens owed to DolomiteMargin by borrowers, and
     * subtracting the number of tokens owed to suppliers by DolomiteMargin.
     *
     * @param  marketId  The market to query
     * @return           The number of excess tokens
     */
    function getNumExcessTokens(
        uint256 marketId
    ) external view returns (Wei memory);

    // ============ Getters for Accounts ============

    /**
     * Get the principal value for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountPar(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the principal value for a particular account and market, with no check the market is valid. Meaning, markets
     * that don't exist return 0.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountParNoMarketCheck(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the token balance for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The token amount
     */
    function getAccountWei(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Wei memory);

    /**
     * Get the status of an account (Normal, Liquidating, or Vaporizing).
     *
     * @param  account  The account to query
     * @return          The account's status
     */
    function getAccountStatus(
        AccountInfo calldata account
    ) external view returns (AccountStatus);

    /**
     * Get a list of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256[] memory);

    /**
     * Get the number of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the marketId for an account's market with a non-zero balance at the given index
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketWithBalanceAtIndex(
        AccountInfo calldata account,
        uint256 index
    ) external view returns (uint256);

    /**
     * Get the number of markets with which an account has a negative balance.
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithDebt(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the total supplied and total borrowed value of an account.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account
     *                   - The borrowed value of the account
     */
    function getAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get the total supplied and total borrowed values of an account adjusted by the marginPremium
     * of each market. Supplied values are divided by (1 + marginPremium) for each market and
     * borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
     * adjusted values gives the margin-ratio of the account which will be compared to the global
     * margin-ratio when determining if the account can be liquidated.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account (adjusted for marginPremium)
     *                   - The borrowed value of the account (adjusted for marginPremium)
     */
    function getAdjustedAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The market IDs for each market
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(
        AccountInfo calldata account
    ) external view returns (uint[] memory, address[] memory, Par[] memory, Wei[] memory);

    // ============ Getters for Account Permissions ============

    /**
     * Return true if a particular address is approved as an operator for an owner's accounts.
     * Approved operators can act on the accounts of the owner as if it were the operator's own.
     *
     * @param  owner     The owner of the accounts
     * @param  operator  The possible operator
     * @return           True if operator is approved for owner's accounts
     */
    function getIsLocalOperator(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * Return true if a particular address is approved as a global operator. Such an address can
     * act on any account as if it were the operator's own.
     *
     * @param  operator  The address to query
     * @return           True if operator is a global operator
     */
    function getIsGlobalOperator(
        address operator
    ) external view returns (bool);

    /**
     * Checks if the autoTrader can only be called invoked by a global operator
     *
     * @param  autoTrader    The trader that should be checked for special call privileges.
     */
    function getIsAutoTraderSpecial(address autoTrader) external view returns (bool);

    /**
     * @return The address that owns the DolomiteMargin protocol
     */
    function owner() external view returns (address);

    // ============ Getters for Risk Params ============

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @return  The global margin-ratio
     */
    function getMarginRatio() external view returns (Decimal memory);

    /**
     * Get the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     *
     * @return  The global liquidation spread
     */
    function getLiquidationSpread() external view returns (Decimal memory);

    /**
     * Get the adjusted liquidation spread for some market pair. This is equal to the global
     * liquidation spread multiplied by (1 + spreadPremium) for each of the two markets.
     *
     * @param  heldMarketId  The market for which the account has collateral
     * @param  owedMarketId  The market for which the account has borrowed tokens
     * @return               The adjusted liquidation spread
     */
    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal memory);

    /**
     * Get the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     *
     * @return  The global earnings rate
     */
    function getEarningsRate() external view returns (Decimal memory);

    /**
     * Get the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     *
     * @return  The global minimum borrow value
     */
    function getMinBorrowedValue() external view returns (MonetaryValue memory);

    /**
     * Get all risk parameters in a single struct.
     *
     * @return  All global risk parameters
     */
    function getRiskParams() external view returns (RiskParams memory);

    /**
     * Get all risk parameter limits in a single struct. These are the maximum limits at which the
     * risk parameters can be set by the admin of DolomiteMargin.
     *
     * @return  All global risk parameter limits
     */
    function getRiskLimits() external view returns (RiskLimits memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";
import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomiteMarginAdmin
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that can be called by the owner of DolomiteMargin.
 */
interface IDolomiteMarginAdmin is IDolomiteStructs {

    // ============ Token Functions ============

    /**
     * Withdraw an ERC20 token for which there is an associated market. Only excess tokens can be withdrawn. The number
     * of excess tokens is calculated by taking the current number of tokens held in DolomiteMargin, adding the number
     * of tokens owed to DolomiteMargin by borrowers, and subtracting the number of tokens owed to suppliers by
     * DolomiteMargin.
     */
    function ownerWithdrawExcessTokens(
        uint256 marketId,
        address recipient
    )
    external
    returns (uint256);

    /**
     * Withdraw an ERC20 token for which there is no associated market.
     */
    function ownerWithdrawUnsupportedTokens(
        address token,
        address recipient
    )
    external
    returns (uint256);

    // ============ Market Functions ============

    /**
     * Sets the number of non-zero balances an account may have within the same `accountIndex`. This ensures a user
     * cannot DOS the system by filling their account with non-zero balances (which linearly increases gas costs when
     * checking collateralization) and disallowing themselves to close the position, because the number of gas units
     * needed to process their transaction exceed the block's gas limit. In turn, this would  prevent the user from also
     * being liquidated, causing the all of the capital to be "stuck" in the position.
     *
     * Lowering this number does not "freeze" user accounts that have more than the new limit of balances, because this
     * variable is enforced by checking the users number of non-zero balances against the max or if it sizes down before
     * each transaction finishes.
     */
    function ownerSetAccountMaxNumberOfMarketsWithBalances(
        uint256 accountMaxNumberOfMarketsWithBalances
    )
    external;

    /**
     * Add a new market to DolomiteMargin. Must be for a previously-unsupported ERC20 token.
     */
    function ownerAddMarket(
        address token,
        IDolomitePriceOracle priceOracle,
        IDolomiteInterestSetter interestSetter,
        Decimal calldata marginPremium,
        Decimal calldata spreadPremium,
        uint256 maxWei,
        bool isClosing,
        bool isRecyclable
    )
    external;

    /**
     * Removes a market from DolomiteMargin, sends any remaining tokens in this contract to `salvager` and invokes the
     * recyclable callback
     */
    function ownerRemoveMarkets(
        uint[] calldata marketIds,
        address salvager
    )
    external;

    /**
     * Set (or unset) the status of a market to "closing". The borrowedValue of a market cannot increase while its
     * status is "closing".
     */
    function ownerSetIsClosing(
        uint256 marketId,
        bool isClosing
    )
    external;

    /**
     * Set the price oracle for a market.
     */
    function ownerSetPriceOracle(
        uint256 marketId,
        IDolomitePriceOracle priceOracle
    )
    external;

    /**
     * Set the interest-setter for a market.
     */
    function ownerSetInterestSetter(
        uint256 marketId,
        IDolomiteInterestSetter interestSetter
    )
    external;

    /**
     * Set a premium on the minimum margin-ratio for a market. This makes it so that any positions that include this
     * market require a higher collateralization to avoid being liquidated.
     */
    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal calldata marginPremium
    )
    external;

    function ownerSetMaxWei(
        uint256 marketId,
        uint256 maxWei
    )
    external;

    /**
     * Set a premium on the liquidation spread for a market. This makes it so that any liquidations that include this
     * market have a higher spread than the global default.
     */
    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal calldata spreadPremium
    )
    external;

    // ============ Risk Functions ============

    /**
     * Set the global minimum margin-ratio that every position must maintain to prevent being liquidated.
     */
    function ownerSetMarginRatio(
        Decimal calldata ratio
    )
    external;

    /**
     * Set the global liquidation spread. This is the spread between oracle prices that incentivizes the liquidation of
     * risky positions.
     */
    function ownerSetLiquidationSpread(
        Decimal calldata spread
    )
    external;

    /**
     * Set the global earnings-rate variable that determines what percentage of the interest paid by borrowers gets
     * passed-on to suppliers.
     */
    function ownerSetEarningsRate(
        Decimal calldata earningsRate
    )
    external;

    /**
     * Set the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     */
    function ownerSetMinBorrowedValue(
        MonetaryValue calldata minBorrowedValue
    )
    external;

    // ============ Global Operator Functions ============

    /**
     * Approve (or disapprove) an address that is permissioned to be an operator for all accounts in DolomiteMargin.
     * Intended only to approve smart-contracts.
     */
    function ownerSetGlobalOperator(
        address operator,
        bool approved
    )
    external;

    /**
     * Approve (or disapprove) an auto trader that can only be called by a global operator. IE for expirations
     */
    function ownerSetAutoTraderSpecial(
        address autoTrader,
        bool special
    )
    external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomitePriceOracle
 * @author  Dolomite
 *
 * @notice  Interface that Price Oracles for DolomiteMargin must implement in order to report prices.
 */
interface IDolomitePriceOracle {

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^(36 - decimals).
     *                So a USD-stable coin with 6 decimal places would return `price * 10^30`.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(
        address token
    )
    external
    view
    returns (IDolomiteStructs.MonetaryPrice memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteStructs
 * @author  Dolomite
 *
 * @notice  This interface defines the structs used by DolomiteMargin
 */
interface IDolomiteStructs {

    // ========================= Enums =========================

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    // ========================= Structs =========================

    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    /**
     * Most-recently-cached account status.
     *
     * Normal: Can only be liquidated if the account values are violating the global margin-ratio.
     * Liquid: Can be liquidated no matter the account values.
     *         Can be vaporized if there are no more positive account values.
     * Vapor:  Has only negative (or zeroed) account values. Can be vaporized.
     *
     */
    enum AccountStatus {
        Normal,
        Liquid,
        Vapor
    }

    /*
     * Arguments that are passed to DolomiteMargin in an ordered list as part of a single operation.
     * Each ActionArgs has an actionType which specifies which action struct that this data will be
     * parsed into before being processed.
     */
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Decimal {
        uint256 value;
    }

    struct InterestIndex {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

    struct Market {
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Whether this market can be removed and its ID can be recycled and reused
        bool isRecyclable;

        // Total aggregated supply and borrow amount of the entire market
        TotalPar totalPar;

        // Interest index of the market
        InterestIndex index;

        // Contract address of the price oracle for this market
        IDolomitePriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IDolomiteInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal spreadPremium;

        // The maximum amount that can be held by the external. This allows the external to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be below 0.
        Wei maxWei;
    }

    /*
     * The price of a base-unit of an asset. Has `36 - token.decimals` decimals
     */
    struct MonetaryPrice {
        uint256 value;
    }

    struct MonetaryValue {
        uint256 value;
    }

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    struct Par {
        bool sign;
        uint256 value;
    }

    struct RiskLimits {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        // The highest min margin ratio premium that can be applied to a particular market. Meaning, a value of 100%
        // (1e18) would require borrowers to maintain an extra 100% collateral to maintain a healthy margin ratio. This
        // value works by increasing the debt owed and decreasing the supply held for the particular market by this
        // amount, plus 1e18 (since a value of 10% needs to be applied as `decimal.plusOne`)
        uint64 marginPremiumMax;
        // The highest liquidation reward that can be applied to a particular market. This percentage is applied
        // in addition to the liquidation spread in `RiskParams`. Meaning a value of 1e18 is 100%. It is calculated as:
        // `liquidationSpread * Decimal.onePlus(spreadPremium)`
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        MonetaryValue minBorrowedValue;

        // The maximum number of markets a user can have a non-zero balance for a given account.
        uint256 accountMaxNumberOfMarketsWithBalances;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct Wei {
        bool sign;
        uint256 value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { Require } from "./Require.sol";


/**
 * @title   DolomiteMarginMath
 * @author  dYdX
 *
 * @notice  Library for non-standard Math functions
 */
library DolomiteMarginMath {

    // ============ Constants ============

    bytes32 internal constant _FILE = "DolomiteMarginMath";

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        return target * numerator / denominator;
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.1 rounds to 102
     * instead of 101.
     */
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            return 0;
        }
        return (((target * numerator) - 1) / denominator) + 1;
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.5 rounds to 102
     * instead of 101.
     */
    function getPartialRoundHalfUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            return 0;
        }
        return (((target * numerator) + (denominator / 2)) / denominator);
    }

    function to128(
        uint256 number
    )
    internal
    pure
    returns (uint128)
    {
        uint128 result = uint128(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint128",
            number
        );
        return result;
    }

    function to96(
        uint256 number
    )
    internal
    pure
    returns (uint96)
    {
        uint96 result = uint96(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint96",
            number
        );
        return result;
    }

    function to32(
        uint256 number
    )
    internal
    pure
    returns (uint32)
    {
        uint32 result = uint32(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint32",
            number
        );
        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   Require
 * @author  dYdX
 *
 * @notice  Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 private constant _ASCII_ZERO = 48; // '0'
    uint256 private constant _ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 private constant _ASCII_LOWER_EX = 120; // 'x'
    bytes2 private constant _COLON = 0x3a20; // ': '
    bytes2 private constant _COMMA = 0x2c20; // ', '
    bytes2 private constant _LPAREN = 0x203c; // ' <'
    bytes1 private constant _RPAREN = 0x3e; // '>'
    uint256 private constant _FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason)
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _COMMA,
                    _stringify(payloadC),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _COMMA,
                    _stringify(payloadC),
                    _RPAREN
                )
            )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
    internal
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solhint-disable-next-line no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function _stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            i--;

            // take last decimal digit
            bstr[i] = bytes1(uint8(_ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function _stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(uint160(input));

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _char(
        uint256 input
    )
    private
    pure
    returns (bytes1)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return bytes1(uint8(input + _ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return bytes1(uint8(input + _ASCII_RELATIVE_ZERO));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";
import { IDolomiteStructs } from "../interfaces/IDolomiteStructs.sol";


/**
 * @title   TypesLib
 * @author  dYdX
 *
 * @notice  Library for interacting with the basic structs used in DolomiteMargin
 */
library TypesLib {
    using DolomiteMarginMath for uint256;

    // ============ Par (Principal Amount) ============

    function zeroPar()
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return IDolomiteStructs.Par({
            sign: false,
            value: 0
        });
    }

    function sub(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return add(a, negative(b));
    }

    function add(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        IDolomiteStructs.Par memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = (a.value + b.value).to128();
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = (a.value - b.value).to128();
            } else {
                result.sign = b.sign;
                result.value = (b.value - a.value).to128();
            }
        }
        return result;
    }

    function equals(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return IDolomiteStructs.Par({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value == 0;
    }

    function isLessThanZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value > 0 && !a.sign;
    }

    function isGreaterThanOrEqualToZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return isZero(a) || a.sign;
    }

    // ============ Wei (Token Amount) ============

    function zeroWei()
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return IDolomiteStructs.Wei({
            sign: false,
            value: 0
        });
    }

    function sub(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return add(a, negative(b));
    }

    function add(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        IDolomiteStructs.Wei memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = a.value + b.value;
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = a.value - b.value;
            } else {
                result.sign = b.sign;
                result.value = b.value - a.value;
            }
        }
        return result;
    }

    function equals(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return IDolomiteStructs.Wei({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value == 0;
    }
}