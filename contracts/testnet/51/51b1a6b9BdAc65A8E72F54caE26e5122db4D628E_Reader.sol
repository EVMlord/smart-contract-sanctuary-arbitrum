// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../staking/interfaces/IOldTokenFarm.sol";

contract Reader {
    IOldTokenFarm private tokenFarm;
    IERC20 private esVela;

    constructor(IOldTokenFarm _tokenFarm, IERC20 _esVela) {
        tokenFarm = _tokenFarm;
        esVela = _esVela;
    }

    function getUserOldVelaInfo(address _account) external view returns (uint256, uint256, uint256, uint256[] memory) {
        IOldTokenFarm.UserInfo memory userVelaInfo = tokenFarm.userInfo(1, _account);
        IOldTokenFarm.UserInfo memory userEsVelaInfo = tokenFarm.userInfo(2, _account);
        uint256[] memory _amounts = new uint256[](2);
        (,,, uint256[] memory _velaPendingAmounts) = tokenFarm.pendingTokens(1, _account);
        (,,, uint256[] memory _esVelaPendingAmounts) = tokenFarm.pendingTokens(2, _account);
        _amounts[0] = _velaPendingAmounts[0];
        _amounts[1] = _esVelaPendingAmounts[0];
        uint256 esVelaBalance = esVela.balanceOf(_account);
        uint256 userVelaStakedAmount = userVelaInfo.amount;
        uint256 userEsVelaStakedAmount = userEsVelaInfo.amount;
        return (esVelaBalance, userVelaStakedAmount, userEsVelaStakedAmount, _amounts);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @dev Interface of the OldTokenFarm
 */
interface IOldTokenFarm {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 startTimestamp;
    }
    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        returns (
            address[] memory addresses,
            string[] memory symbols,
            uint256[] memory decimals,
            uint256[] memory amounts
        );
    function userInfo(uint256 _pid, address _account) external view returns (UserInfo memory);
}