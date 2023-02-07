// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

interface IAMM {
    function swapExactInput(
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external returns (uint256);

    function buySweep(address _token, uint256 _amountIn, uint256 _amountOutMin)
        external
        returns (uint256);

    function sellSweep(address _token, uint256 _amountIn, uint256 _amountOutMin)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function withdraw(uint) external;
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ========================== WETHAsset.sol ===========================
// ====================================================================

/**
 * @title WETH Asset
 * @author MAXOS Team - https://maxos.finance/
 */
import "../AMM/IAMM.sol";
import "./WETH/IWETH.sol";
import "../Common/Owned.sol";
import "../Common/ERC20/IERC20.sol";
import "../Oracle/AggregatorV3Interface.sol";
import "../Utils/Uniswap/V3/libraries/TransferHelper.sol";

contract WETHAsset is Owned {
    IWETH public WETH;
    IERC20 public usdx;
    IAMM public uniswap_amm;
    address public stabilizer;

    // oracle to fetch price WETH / USDC
    AggregatorV3Interface private immutable oracle;
    uint256 private PRICE_PRECISION = 1e6;

    // Events
    event Deposited(address collateral_address, uint256 amount);
    event Withdrawed(address collateral_address, uint256 amount);

    constructor(
        address _sweep_address,
        address _weth_address,
        address _usdx_address,
        address _uniswap_amm,
        address _stabilizer_address,
        address _chainlink_oracle
    ) Owned(_sweep_address) {
        WETH = IWETH(_weth_address);
        usdx = IERC20(_usdx_address);
        uniswap_amm = IAMM(_uniswap_amm);
        stabilizer = _stabilizer_address;
        oracle = AggregatorV3Interface(_chainlink_oracle);
    }

    modifier onlyStabilizer() {
        require(msg.sender == stabilizer, "only stabilizer");
        _;
    }

    // ACTIONS ===========================
    /**
     * @notice Current Value of investment.
     * @return usdx_amount Returns the value of the investment in the USD coin
     * @dev the price is obtained from Chainlink
     */
    function currentValue() external view returns (uint256) {
        uint256 weth_balance = WETH.balanceOf(address(this));
        (, int256 price, , , ) = oracle.latestRoundData();        
        
        uint256 usdx_amount = 
            (weth_balance * uint256(price) * PRICE_PRECISION) /
            (10**(WETH.decimals() + oracle.decimals()));
        
        return usdx_amount;
    }

    /**
     * @notice Function to deposit USDX from Stabilizer to Asset
     * @param amount USDX amount of asset to be deposited
     */
    function deposit(uint256 amount, uint256) external onlyStabilizer {
        address usdx_address = address(usdx);
        TransferHelper.safeTransferFrom(
            address(usdx),
            msg.sender,
            address(this),
            amount
        );
        
        TransferHelper.safeApprove(usdx_address, address(uniswap_amm), amount);
        uint256 weth_amount = uniswap_amm.swapExactInput(
            usdx_address,
            address(WETH),
            amount,
            0
        );

        emit Deposited(address(usdx), weth_amount);
    }

    /**
     * @notice Function to withdraw USDX from ASSET to Stabilizer
     * @param amount Amount of tokens to be withdrew
     */
    function withdraw(uint256 amount) external onlyStabilizer {
        uint256 weth_amount = amount;
        if(amount != type(uint256).max) {
            (, int256 price, , , ) = oracle.latestRoundData();
            weth_amount =
                (amount * (10**(WETH.decimals() + oracle.decimals()))) /
                (uint256(price) * PRICE_PRECISION);
        }
        
        uint256 weth_balance = WETH.balanceOf(address(this));
        
        if(weth_amount > weth_balance) weth_amount = weth_balance;
        
        address usdx_address = address(usdx);
        address weth_address = address(WETH);
        
        TransferHelper.safeApprove(weth_address, address(uniswap_amm), weth_amount);
        uint256 usdx_amount = uniswap_amm.swapExactInput(
            weth_address,
            usdx_address,
            weth_amount,
            0
        );

        TransferHelper.safeTransfer(usdx_address, stabilizer, usdx_amount);

        emit Withdrawed(usdx_address, usdx_amount);
    }

    /**
     * @notice Liquidate
     * @param to address to receive the tokens
     * @param amount token amount to send
     */
    function liquidate(address to, uint256 amount)
        external
        onlyStabilizer
    {
        (, int256 price, , , ) = oracle.latestRoundData();
        uint256 weth_amount =
                (amount * (10**(WETH.decimals() + oracle.decimals()))) /
                (uint256(price) * PRICE_PRECISION);
        
        WETH.transfer(to, weth_amount);
    }

    /**
     * @notice compliance with the IAsset.sol
     */
    function withdrawRewards(address) external pure {}

    function updateValue(uint256) external pure {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
pragma solidity 0.8.16;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

// ==========================================================
// ====================== Owned ========================
// ==========================================================

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "../Sweep/ISweep.sol";

contract Owned {
    address public sweep_address;
    ISweep public SWEEP;

    // Events
    event SetSweep(address indexed sweep_address);

    // Errors
    error OnlyAdmin();
    error OnlyCollateralAgent();
    error ZeroAddressDetected();

    constructor(address _sweep_address) {
        sweep_address = _sweep_address;
        SWEEP = ISweep(_sweep_address);
    }

    modifier onlyAdmin() {
        if (msg.sender != SWEEP.owner()) revert OnlyAdmin();
        _;
    }

    modifier onlyCollateralAgent() {
        if (msg.sender != SWEEP.collateral_agency())
            revert OnlyCollateralAgent();
        _;
    }

    /**
     * @notice setSweep
     * @param _sweep_address.
     */
    function setSweep(address _sweep_address) external onlyAdmin {
        if (_sweep_address == address(0)) revert ZeroAddressDetected();
        sweep_address = _sweep_address;
        SWEEP = ISweep(_sweep_address);

        emit SetSweep(_sweep_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface ISweep {
    struct Minter {
        uint256 max_amount;
        uint256 minted_amount;
        bool is_listed;
        bool is_enabled;
    }

    function DEFAULT_ADMIN_ADDRESS() external view returns (address);

    function balancer() external view returns (address);

    function treasury() external view returns (address);

    function collateral_agency() external view returns (address);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function isValidMinter(address) external view returns (bool);

    function amm_price() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function minter_burn_from(uint256 amount) external;

    function minter_mint(address m_address, uint256 m_amount) external;

    function minters(address m_address) external returns (Minter memory);

    function target_price() external view returns (uint256);

    function interest_rate() external view returns (int256);

    function period_time() external view returns (uint256);

    function step_value() external view returns (int256);

    function setInterestRate(int256 interest_rate) external;

    function setTargetPrice(uint256 current_target_price, uint256 next_target_price) external;    

    function startNewPeriod() external;

    function setUniswapOracle(address uniswap_oracle_address) external;

    function setTimelock(address new_timelock) external;

    function symbol() external view returns (string memory);

    function timelock_address() external view returns (address);

    function totalSupply() external view returns (uint256);

    function convertToUSDX(uint256 amount) external view returns (uint256);

    function convertToSWEEP(uint256 amount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "../../../../Common/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}