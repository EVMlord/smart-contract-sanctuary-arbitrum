// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import './AuthorizedHelpers.sol';
import './interfaces/IAuthorized.sol';
import './interfaces/IAuthorizer.sol';

/**
 * @title Authorized
 * @dev Implementation using an authorizer as its access-control mechanism. It offers `auth` and `authP` modifiers to
 * tag its own functions in order to control who can access them against the authorizer referenced.
 */
contract Authorized is IAuthorized, Initializable, AuthorizedHelpers {
    // Authorizer reference
    address public override authorizer;

    /**
     * @dev Modifier that should be used to tag protected functions
     */
    modifier auth() {
        _authenticate(msg.sender, msg.sig);
        _;
    }

    /**
     * @dev Modifier that should be used to tag protected functions with params
     */
    modifier authP(uint256[] memory params) {
        _authenticate(msg.sender, msg.sig, params);
        _;
    }

    /**
     * @dev Creates a new authorized contract. Note that initializers are disabled at creation time.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the authorized contract. It does call upper contracts initializers.
     * @param _authorizer Address of the authorizer to be set
     */
    function __Authorized_init(address _authorizer) internal onlyInitializing {
        __Authorized_init_unchained(_authorizer);
    }

    /**
     * @dev Initializes the authorized contract. It does not call upper contracts initializers.
     * @param _authorizer Address of the authorizer to be set
     */
    function __Authorized_init_unchained(address _authorizer) internal onlyInitializing {
        authorizer = _authorizer;
    }

    /**
     * @dev Reverts if `who` is not allowed to call `what`
     * @param who Address to be authenticated
     * @param what Function selector to be authenticated
     */
    function _authenticate(address who, bytes4 what) internal view {
        _authenticate(who, what, new uint256[](0));
    }

    /**
     * @dev Reverts if `who` is not allowed to call `what` with `how`
     * @param who Address to be authenticated
     * @param what Function selector to be authenticated
     * @param how Params to be authenticated
     */
    function _authenticate(address who, bytes4 what, uint256[] memory how) internal view {
        if (!_isAuthorized(who, what, how)) revert AuthSenderNotAllowed(who, what, how);
    }

    /**
     * @dev Tells whether `who` has any permission on this contract
     * @param who Address asking permissions for
     */
    function _hasPermissions(address who) internal view returns (bool) {
        return IAuthorizer(authorizer).hasPermissions(who, address(this));
    }

    /**
     * @dev Tells whether `who` is allowed to call `what`
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     */
    function _isAuthorized(address who, bytes4 what) internal view returns (bool) {
        return _isAuthorized(who, what, new uint256[](0));
    }

    /**
     * @dev Tells whether `who` is allowed to call `what` with `how`
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function _isAuthorized(address who, bytes4 what, uint256[] memory how) internal view returns (bool) {
        return IAuthorizer(authorizer).isAuthorized(who, address(this), what, how);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.17;

/**
 * @title AuthorizedHelpers
 * @dev Syntax sugar methods to operate with authorizer params easily
 */
contract AuthorizedHelpers {
    function authParams(address p1) internal pure returns (uint256[] memory r) {
        return authParams(uint256(uint160(p1)));
    }

    function authParams(bytes32 p1) internal pure returns (uint256[] memory r) {
        return authParams(uint256(p1));
    }

    function authParams(uint256 p1) internal pure returns (uint256[] memory r) {
        r = new uint256[](1);
        r[0] = p1;
    }

    function authParams(address p1, bool p2) internal pure returns (uint256[] memory r) {
        r = new uint256[](2);
        r[0] = uint256(uint160(p1));
        r[1] = p2 ? 1 : 0;
    }

    function authParams(address p1, uint256 p2) internal pure returns (uint256[] memory r) {
        r = new uint256[](2);
        r[0] = uint256(uint160(p1));
        r[1] = p2;
    }

    function authParams(address p1, address p2) internal pure returns (uint256[] memory r) {
        r = new uint256[](2);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
    }

    function authParams(bytes32 p1, bytes32 p2) internal pure returns (uint256[] memory r) {
        r = new uint256[](2);
        r[0] = uint256(p1);
        r[1] = uint256(p2);
    }

    function authParams(address p1, address p2, uint256 p3) internal pure returns (uint256[] memory r) {
        r = new uint256[](3);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
        r[2] = p3;
    }

    function authParams(address p1, address p2, address p3) internal pure returns (uint256[] memory r) {
        r = new uint256[](3);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
        r[2] = uint256(uint160(p3));
    }

    function authParams(address p1, address p2, bytes4 p3) internal pure returns (uint256[] memory r) {
        r = new uint256[](3);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
        r[2] = uint256(uint32(p3));
    }

    function authParams(address p1, uint256 p2, uint256 p3) internal pure returns (uint256[] memory r) {
        r = new uint256[](3);
        r[0] = uint256(uint160(p1));
        r[1] = p2;
        r[2] = p3;
    }

    function authParams(uint256 p1, uint256 p2, uint256 p3, uint256 p4) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = p1;
        r[1] = p2;
        r[2] = p3;
        r[3] = p4;
    }

    function authParams(address p1, address p2, uint256 p3, uint256 p4) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
        r[2] = p3;
        r[3] = p4;
    }

    function authParams(address p1, uint256 p2, uint256 p3, uint256 p4) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = uint256(uint160(p1));
        r[1] = p2;
        r[2] = p3;
        r[3] = p4;
    }

    function authParams(bytes32 p1, address p2, uint256 p3, bool p4) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = uint256(p1);
        r[1] = uint256(uint160(p2));
        r[2] = p3;
        r[3] = p4 ? 1 : 0;
    }

    function authParams(address p1, uint256 p2, uint256 p3, uint256 p4, uint256 p5)
        internal
        pure
        returns (uint256[] memory r)
    {
        r = new uint256[](5);
        r[0] = uint256(uint160(p1));
        r[1] = p2;
        r[2] = p3;
        r[3] = p4;
        r[4] = p5;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import './AuthorizedHelpers.sol';
import './interfaces/IAuthorizer.sol';

/**
 * @title Authorizer
 * @dev Authorization mechanism based on permissions
 */
contract Authorizer is IAuthorizer, AuthorizedHelpers, Initializable, ReentrancyGuardUpgradeable {
    // Constant used to denote that a permission is open to anyone
    address public constant ANYONE = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    // Constant used to denote that a permission is open to anywhere
    address public constant ANYWHERE = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    // Param logic op types
    enum Op {
        NONE,
        EQ,
        NEQ,
        GT,
        LT,
        GTE,
        LTE
    }

    /**
     * @dev Permission information
     * @param authorized Whether it is authorized or not
     * @param params List of params defined for each permission
     */
    struct Permission {
        bool authorized;
        Param[] params;
    }

    /**
     * @dev Permissions list information
     * @param count Number of permissions
     * @param permissions List of permissions indexed by what
     */
    struct PermissionsList {
        uint256 count;
        mapping (bytes4 => Permission) permissions;
    }

    // List of permissions indexed by who => where
    mapping (address => mapping (address => PermissionsList)) private _permissionsLists;

    /**
     * @dev Creates a new authorizer contract. Note that initializers are disabled at creation time.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialization function.
     * @param owners List of addresses that will be allowed to authorize and unauthorize permissions
     */
    function initialize(address[] memory owners) external virtual initializer {
        __ReentrancyGuard_init();
        for (uint256 i = 0; i < owners.length; i++) {
            _authorize(owners[i], address(this), IAuthorizer.authorize.selector, new Param[](0));
            _authorize(owners[i], address(this), IAuthorizer.unauthorize.selector, new Param[](0));
        }
    }

    /**
     * @dev Tells whether `who` has any permission on `where`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     */
    function hasPermissions(address who, address where) external view override returns (bool) {
        return _permissionsLists[who][where].count > 0;
    }

    /**
     * @dev Tells the number of permissions `who` has on `where`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     */
    function getPermissionsLength(address who, address where) external view override returns (uint256) {
        return _permissionsLists[who][where].count;
    }

    /**
     * @dev Tells whether `who` has permission to call `what` on `where`. Note `how` is not evaluated here,
     * which means `who` might be authorized on or not depending on the call at the moment of the execution
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     */
    function hasPermission(address who, address where, bytes4 what) external view override returns (bool) {
        return _permissionsLists[who][where].permissions[what].authorized;
    }

    /**
     * @dev Tells whether `who` is allowed to call `what` on `where` with `how`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function isAuthorized(address who, address where, bytes4 what, uint256[] memory how)
        public
        view
        override
        returns (bool)
    {
        if (_isAuthorized(who, where, what, how)) return true; // direct permission
        if (_isAuthorized(ANYONE, where, what, how)) return true; // anyone is allowed
        if (_isAuthorized(who, ANYWHERE, what, how)) return true; // direct permission on anywhere
        if (_isAuthorized(ANYONE, ANYWHERE, what, how)) return true; // anyone allowed anywhere
        return false;
    }

    /**
     * @dev Tells the params set for a given permission
     * @param who Address asking permission params of
     * @param where Target address asking permission params of
     * @param what Function selector asking permission params of
     */
    function getPermissionParams(address who, address where, bytes4 what)
        external
        view
        override
        returns (Param[] memory)
    {
        return _permissionsLists[who][where].permissions[what].params;
    }

    /**
     * @dev Executes a list of permission changes. Sender must be authorized.
     * @param changes List of permission changes to be executed
     */
    function changePermissions(PermissionChange[] memory changes) external override {
        for (uint256 i = 0; i < changes.length; i++) {
            PermissionChange memory change = changes[i];
            for (uint256 j = 0; j < change.grants.length; j++) {
                GrantPermission memory grant = change.grants[j];
                authorize(grant.who, change.where, grant.what, grant.params);
            }
            for (uint256 j = 0; j < change.revokes.length; j++) {
                RevokePermission memory revoke = change.revokes[j];
                unauthorize(revoke.who, change.where, revoke.what);
            }
        }
    }

    /**
     * @dev Authorizes `who` to call `what` on `where` restricted by `params`. Sender must be authorized.
     * @param who Address to be authorized
     * @param where Target address to be granted for
     * @param what Function selector to be granted
     * @param params Optional params to restrict a permission attempt
     */
    function authorize(address who, address where, bytes4 what, Param[] memory params) public override nonReentrant {
        uint256[] memory how = authParams(who, where, what);
        _authenticate(msg.sender, IAuthorizer.authorize.selector, how);
        _authorize(who, where, what, params);
    }

    /**
     * @dev Unauthorizes `who` to call `what` on `where`. Sender must be authorized.
     * @param who Address to be authorized
     * @param where Target address to be revoked for
     * @param what Function selector to be revoked
     */
    function unauthorize(address who, address where, bytes4 what) public override nonReentrant {
        uint256[] memory how = authParams(who, where, what);
        _authenticate(msg.sender, IAuthorizer.unauthorize.selector, how);
        _unauthorize(who, where, what);
    }

    /**
     * @dev Validates whether `who` is authorized to call `what` with `how`
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function _authenticate(address who, bytes4 what, uint256[] memory how) internal view {
        bool allowed = isAuthorized(who, address(this), what, how);
        if (!allowed) revert AuthorizerSenderNotAllowed(who, address(this), what, how);
    }

    /**
     * @dev Tells whether `who` is allowed to call `what` on `where` with `how`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function _isAuthorized(address who, address where, bytes4 what, uint256[] memory how) internal view returns (bool) {
        Permission storage permission = _permissionsLists[who][where].permissions[what];
        return permission.authorized && _evalParams(permission.params, how);
    }

    /**
     * @dev Authorizes `who` to call `what` on `where` restricted by `params`
     * @param who Address to be authorized
     * @param where Target address to be granted for
     * @param what Function selector to be granted
     * @param params Optional params to restrict a permission attempt
     */
    function _authorize(address who, address where, bytes4 what, Param[] memory params) internal {
        PermissionsList storage list = _permissionsLists[who][where];
        Permission storage permission = list.permissions[what];
        if (!permission.authorized) list.count++;
        permission.authorized = true;
        delete permission.params;
        for (uint256 i = 0; i < params.length; i++) permission.params.push(params[i]);
        emit Authorized(who, where, what, params);
    }

    /**
     * @dev Unauthorizes `who` to call `what` on `where`
     * @param who Address to be authorized
     * @param where Target address to be revoked for
     * @param what Function selector to be revoked
     */
    function _unauthorize(address who, address where, bytes4 what) internal {
        PermissionsList storage list = _permissionsLists[who][where];
        Permission storage permission = list.permissions[what];
        if (permission.authorized) list.count--;
        delete list.permissions[what];
        emit Unauthorized(who, where, what);
    }

    /**
     * @dev Evaluates a list of params defined for a permission against a list of values given by a call
     * @param params List of expected params
     * @param how List of actual given values
     * @return True if all the given values hold against the list of params
     */
    function _evalParams(Param[] memory params, uint256[] memory how) private pure returns (bool) {
        for (uint256 i = 0; i < params.length; i++) {
            Param memory param = params[i];
            if ((i < how.length && !_evalParam(param, how[i])) || (i >= how.length && Op(param.op) != Op.NONE)) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Evaluates a single param defined for a permission against a single value
     * @param param Expected params
     * @param how Actual given value
     * @return True if the given value hold against the expected param
     */
    function _evalParam(Param memory param, uint256 how) private pure returns (bool) {
        if (Op(param.op) == Op.NONE) return true;
        if (Op(param.op) == Op.EQ) return how == param.value;
        if (Op(param.op) == Op.NEQ) return how != param.value;
        if (Op(param.op) == Op.GT) return how > param.value;
        if (Op(param.op) == Op.LT) return how < param.value;
        if (Op(param.op) == Op.GTE) return how >= param.value;
        if (Op(param.op) == Op.LTE) return how <= param.value;
        revert AuthorizerInvalidParamOp(param.op);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @dev Authorized interface
 */
interface IAuthorized {
    /**
     * @dev Sender `who` is not allowed to call `what` with `how`
     */
    error AuthSenderNotAllowed(address who, bytes4 what, uint256[] how);

    /**
     * @dev Tells the address of the authorizer reference
     */
    function authorizer() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @dev Authorizer interface
 */
interface IAuthorizer {
    /**
     * @dev Permission change
     * @param where Address of the contract to change a permission for
     * @param changes List of permission changes to be executed
     */
    struct PermissionChange {
        address where;
        GrantPermission[] grants;
        RevokePermission[] revokes;
    }

    /**
     * @dev Grant permission data
     * @param who Address to be authorized
     * @param what Function selector to be authorized
     * @param params List of params to restrict the given permission
     */
    struct GrantPermission {
        address who;
        bytes4 what;
        Param[] params;
    }

    /**
     * @dev Revoke permission data
     * @param who Address to be unauthorized
     * @param what Function selector to be unauthorized
     */
    struct RevokePermission {
        address who;
        bytes4 what;
    }

    /**
     * @dev Params used to validate permissions params against
     * @param op ID of the operation to compute in order to validate a permission param
     * @param value Comparison value
     */
    struct Param {
        uint8 op;
        uint248 value;
    }

    /**
     * @dev Sender is not authorized to call `what` on `where` with `how`
     */
    error AuthorizerSenderNotAllowed(address who, address where, bytes4 what, uint256[] how);

    /**
     * @dev The operation param is invalid
     */
    error AuthorizerInvalidParamOp(uint8 op);

    /**
     * @dev Emitted every time `who`'s permission to perform `what` on `where` is granted with `params`
     */
    event Authorized(address indexed who, address indexed where, bytes4 indexed what, Param[] params);

    /**
     * @dev Emitted every time `who`'s permission to perform `what` on `where` is revoked
     */
    event Unauthorized(address indexed who, address indexed where, bytes4 indexed what);

    /**
     * @dev Tells whether `who` has any permission on `where`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     */
    function hasPermissions(address who, address where) external view returns (bool);

    /**
     * @dev Tells the number of permissions `who` has on `where`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     */
    function getPermissionsLength(address who, address where) external view returns (uint256);

    /**
     * @dev Tells whether `who` has permission to call `what` on `where`. Note `how` is not evaluated here,
     * which means `who` might be authorized on or not depending on the call at the moment of the execution
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     */
    function hasPermission(address who, address where, bytes4 what) external view returns (bool);

    /**
     * @dev Tells whether `who` is allowed to call `what` on `where` with `how`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function isAuthorized(address who, address where, bytes4 what, uint256[] memory how) external view returns (bool);

    /**
     * @dev Tells the params set for a given permission
     * @param who Address asking permission params of
     * @param where Target address asking permission params of
     * @param what Function selector asking permission params of
     */
    function getPermissionParams(address who, address where, bytes4 what) external view returns (Param[] memory);

    /**
     * @dev Executes a list of permission changes
     * @param changes List of permission changes to be executed
     */
    function changePermissions(PermissionChange[] memory changes) external;

    /**
     * @dev Authorizes `who` to call `what` on `where` restricted by `params`
     * @param who Address to be authorized
     * @param where Target address to be granted for
     * @param what Function selector to be granted
     * @param params Optional params to restrict a permission attempt
     */
    function authorize(address who, address where, bytes4 what, Param[] memory params) external;

    /**
     * @dev Unauthorizes `who` to call `what` on `where`. Sender must be authorized.
     * @param who Address to be authorized
     * @param where Target address to be revoked for
     * @param what Function selector to be revoked
     */
    function unauthorize(address who, address where, bytes4 what) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../AuthorizedHelpers.sol';

contract AuthorizedHelpersMock is AuthorizedHelpers {
    function getAuthParams(address p1) external pure returns (uint256[] memory r) {
        return authParams(p1);
    }

    function getAuthParams(bytes32 p1) external pure returns (uint256[] memory r) {
        return authParams(p1);
    }

    function getAuthParams(uint256 p1) external pure returns (uint256[] memory r) {
        return authParams(p1);
    }

    function getAuthParams(address p1, bool p2) external pure returns (uint256[] memory r) {
        return authParams(p1, p2);
    }

    function getAuthParams(address p1, uint256 p2) external pure returns (uint256[] memory r) {
        return authParams(p1, p2);
    }

    function getAuthParams(address p1, address p2) external pure returns (uint256[] memory r) {
        return authParams(p1, p2);
    }

    function getAuthParams(bytes32 p1, bytes32 p2) external pure returns (uint256[] memory r) {
        return authParams(p1, p2);
    }

    function getAuthParams(address p1, address p2, uint256 p3) external pure returns (uint256[] memory r) {
        return authParams(p1, p2, p3);
    }

    function getAuthParams(address p1, address p2, address p3) external pure returns (uint256[] memory r) {
        return authParams(p1, p2, p3);
    }

    function getAuthParams(address p1, address p2, bytes4 p3) external pure returns (uint256[] memory r) {
        return authParams(p1, p2, p3);
    }

    function getAuthParams(address p1, uint256 p2, uint256 p3) external pure returns (uint256[] memory r) {
        return authParams(p1, p2, p3);
    }

    function getAuthParams(address p1, address p2, uint256 p3, uint256 p4) external pure returns (uint256[] memory r) {
        return authParams(p1, p2, p3, p4);
    }

    function getAuthParams(address p1, uint256 p2, uint256 p3, uint256 p4) external pure returns (uint256[] memory r) {
        return authParams(p1, p2, p3, p4);
    }

    function getAuthParams(bytes32 p1, address p2, uint256 p3, bool p4) external pure returns (uint256[] memory r) {
        return authParams(p1, p2, p3, p4);
    }

    function getAuthParams(address p1, uint256 p2, uint256 p3, uint256 p4, uint256 p5)
        external
        pure
        returns (uint256[] memory r)
    {
        return authParams(p1, p2, p3, p4, p5);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../Authorized.sol';

contract AuthorizedMock is Authorized {
    event LogUint256(uint256 x);
    event LogBytes32(bytes32 x);
    event LogAddress(address x);

    function initialize(address _authorizer) external virtual initializer {
        __Authorized_init(_authorizer);
    }

    function setUint256(uint256 x) external authP(authParams(x)) {
        emit LogUint256(x);
    }

    function setBytes32(bytes32 x) external authP(authParams(x)) {
        emit LogBytes32(x);
    }

    function setAddress(address x) external authP(authParams(x)) {
        emit LogAddress(x);
    }
}