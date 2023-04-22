// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { ReentrancyGuardUpgradeable } 
    from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol"; 
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20, IERC20Upgradeable as IERC20 } 
    from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ISwapRouter } from "./interfaces/ISwapRouter.sol";
import { ICoinBookPresale } from "./interfaces/ICoinBookPresale.sol";

contract CoinBookPresale is ICoinBookPresale, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    address public wETH;
    IERC20 public usdc;
    IERC20 public book;
    ISwapRouter public sushi;
    uint256 private constant A_FACTOR = 10**18;

    PresaleInfo private whitelistSaleInfo;
    PresaleInfo private publicSaleInfo;
    uint80 public claimStart;
    bool private contractFunded;
    bool public presaleFinalized;

    uint256 public usersInWhitelist;
    uint256 public usersInPublic;

    mapping(address => UserInfo) public contributerInfo;
    mapping(address => bool) public isWhitelisted;

    modifier claimable() {
        require(
            contributerInfo[msg.sender].wlContributed > 0 ||
                contributerInfo[msg.sender].psContributed > 0,
            "User did not participate"
        );
        require(!contributerInfo[msg.sender].claimed, "User already claimed");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    receive() external override payable {
        require(msg.sender == wETH || msg.sender == owner(), "Caller not allowed");
        emit Received(msg.sender, msg.value);
    }

    function initialize(
        address _book,
        uint80 _wlStart, 
        uint80 _wlEnd, 
        uint80 _psStart, 
        uint80 _psEnd, 
        uint80 _claimStart
    ) external reinitializer(3) {
       require(
            _wlEnd > _wlStart && 
                _psStart > _wlEnd && 
                _psEnd > _psStart && 
                _claimStart > _psEnd, 
            "Conflicting timeline"
        );

        book = IERC20(_book);

        whitelistSaleInfo.startTime = _wlStart;
        whitelistSaleInfo.endTime = _wlEnd;

        publicSaleInfo.startTime = _psStart;
        publicSaleInfo.endTime = _psEnd;

        claimStart = _claimStart;

        emit TimesExtended(_wlStart, _wlEnd, _psStart, _psEnd, _claimStart);
    }

    function contributeInWhitelist(uint256 _amount) external override nonReentrant {
        require(isWhitelisted[msg.sender], "User not whitelisted");
        require(_presaleStatus() == 1, "Whitelist Presale not active");
        require(_amount > 0, "Contribution must be more than 0");
        require(
            _amount + contributerInfo[msg.sender].wlContributed <= whitelistSaleInfo.maxSpend, 
            "Contribution exceeds maxSpend"
        );

        if (contributerInfo[msg.sender].wlContributed == 0) {
            usersInWhitelist++;
        }
        contributerInfo[msg.sender].wlContributed += _amount;
        whitelistSaleInfo.raisedAmount += _amount;

        usdc.safeTransferFrom(msg.sender, address(this), _amount);

        emit Contributed(msg.sender, _amount, "Whitelist Sale", block.timestamp);
    }

    function swapAndContributeInWhitelist(uint256 minAmount) external payable override nonReentrant {
        require(isWhitelisted[msg.sender], "User not whitelisted");
        require(_presaleStatus() == 1, "Whitelist Presale not active");
        require(msg.value > 0, "Contribution must be more than 0");

        address[] memory path = new address[](2);
        path[0] = wETH;
        path[1] = address(usdc);
        uint256 swapAmt = msg.value;
        uint256 minOut = minAmount;
        uint256[] memory amounts = sushi.swapExactETHForTokens{
                value: swapAmt
            }(
                minOut, 
                path, 
                address(this), 
                block.timestamp
            );

        uint256 _amount = amounts[1];

        require(
            _amount + contributerInfo[msg.sender].wlContributed <= whitelistSaleInfo.maxSpend, 
            "Contribution exceeds maxSpend"
        );

        if (contributerInfo[msg.sender].wlContributed == 0) {
            usersInWhitelist++;
        }
        contributerInfo[msg.sender].wlContributed += _amount;
        whitelistSaleInfo.raisedAmount += _amount;

        emit SwappedToUSDC(msg.sender, swapAmt, _amount);
        emit Contributed(msg.sender, _amount, "Whitelist Sale", block.timestamp);
    }

    function contributeInPublic(uint256 _amount) external override nonReentrant {
        require(_presaleStatus() == 3, "Public Presale not active");
        require(_amount > 0, "Contribution must be more than 0");
        require(
            _amount + contributerInfo[msg.sender].psContributed <= publicSaleInfo.maxSpend, 
            "Contribution exceeds maxSpend"
        );

        if (contributerInfo[msg.sender].psContributed == 0) {
            usersInPublic++;
        }
        contributerInfo[msg.sender].psContributed += _amount;
        publicSaleInfo.raisedAmount += _amount;

        usdc.safeTransferFrom(msg.sender, address(this), _amount);

        emit Contributed(msg.sender, _amount, "Public Sale", block.timestamp);
    }

    function swapAndContributeInPublic(uint256 minAmount) external payable override nonReentrant {
        require(_presaleStatus() == 3, "Public Presale not active");
        require(msg.value > 0, "Contribution must be more than 0");

        address[] memory path = new address[](2);
        path[0] = wETH;
        path[1] = address(usdc);
        uint256 swapAmt = msg.value;
        uint256 minOut = minAmount;
        uint256[] memory amounts = sushi.swapExactETHForTokens{
                value: swapAmt
            }(
                minOut, 
                path, 
                address(this), 
                block.timestamp
            );

        uint256 _amount = amounts[1];

        require(
            _amount + contributerInfo[msg.sender].psContributed <= publicSaleInfo.maxSpend, 
            "Contribution exceeds maxSpend"
        );

        if (contributerInfo[msg.sender].psContributed == 0) {
            usersInPublic++;
        }
        contributerInfo[msg.sender].psContributed += _amount;
        publicSaleInfo.raisedAmount += _amount;

        emit SwappedToUSDC(msg.sender, swapAmt, _amount);
        emit Contributed(msg.sender, _amount, "Public Sale", block.timestamp);
    }

    function claimBook() external override nonReentrant claimable {
        (uint256 wlBook, uint256 wlRefund, uint256 psBook, uint256 psRefund) = _getClaimableAmounts(msg.sender);
        uint256 bookOwed = wlBook + psBook;
        uint256 refundOwed;
        if (contributerInfo[msg.sender].wlRefunded > 0) {
            refundOwed = psRefund;
        } else {
            refundOwed = wlRefund + psRefund;
            contributerInfo[msg.sender].wlRefunded = wlRefund;
        }

        contributerInfo[msg.sender].wlClaimed = wlBook;
        contributerInfo[msg.sender].psClaimed = psBook;
        contributerInfo[msg.sender].psRefunded = psRefund;
        contributerInfo[msg.sender].claimed = true;

        book.safeTransfer(msg.sender, bookOwed);
        if (refundOwed > 0) {
            usdc.safeTransfer(msg.sender, refundOwed);
        }

        emit Claimed(msg.sender, bookOwed, refundOwed, wlBook, psBook, wlRefund, psRefund, block.timestamp);
    }

    function claimExcessWhitelist(bool moveToPublic) external override nonReentrant {
        require(_presaleStatus() == 3, "Public Presale not active");

        (, uint256 wlRefund,,) = _getClaimableAmounts(msg.sender);
        if (wlRefund == 0) { return; }

        uint256 _amount;
        uint256 _refund;
        if (moveToPublic) {
            if (wlRefund + contributerInfo[msg.sender].psContributed <= publicSaleInfo.maxSpend) {
                _amount = wlRefund;
            } else if (contributerInfo[msg.sender].psContributed <= publicSaleInfo.maxSpend) {
                _amount = publicSaleInfo.maxSpend - contributerInfo[msg.sender].psContributed;
                _refund = wlRefund - _amount;
            } else {
                _refund = wlRefund;
            }

            if (contributerInfo[msg.sender].psContributed == 0) {
                usersInPublic++;
            }
            contributerInfo[msg.sender].psContributed += _amount;
            publicSaleInfo.raisedAmount += _amount;

            if (_refund > 0) { 
                usdc.safeTransfer(msg.sender, _refund); 
            }

            emit Contributed(msg.sender, _amount, "Public Sale", block.timestamp);
        } else {
            _refund = wlRefund;
            usdc.safeTransfer(msg.sender, _refund);
        }
        contributerInfo[msg.sender].wlRefunded = wlRefund;
    }

    function fundContract() external override nonReentrant onlyOwner {
        require(!contractFunded, "Contract already funded");
        uint256 fundAmount = whitelistSaleInfo.saleAmount + publicSaleInfo.saleAmount;
        book.safeTransferFrom(msg.sender, address(this), fundAmount);
        contractFunded = true;
    }

    function finalizePresale() external override nonReentrant onlyOwner {
        require(_presaleStatus() >= 4, "Public Sale has not ended");
        require(!presaleFinalized, "Presale already finalized");        

        uint256 collectableUSDC;
        if (whitelistSaleInfo.raisedAmount > whitelistSaleInfo.target) {
            collectableUSDC += whitelistSaleInfo.target;
        } else {
            collectableUSDC += whitelistSaleInfo.raisedAmount;
        }
        if (publicSaleInfo.raisedAmount > publicSaleInfo.target) {
            collectableUSDC += publicSaleInfo.target;
        } else {
            collectableUSDC += publicSaleInfo.raisedAmount;
        }
        usdc.safeTransfer(owner(), collectableUSDC);

        uint256 excessBook;
        if (whitelistSaleInfo.raisedAmount < whitelistSaleInfo.target) {
            excessBook += whitelistSaleInfo.saleAmount - (
                (((whitelistSaleInfo.raisedAmount * A_FACTOR) / whitelistSaleInfo.target) * 
                    whitelistSaleInfo.saleAmount) / A_FACTOR
            );
        }
        if (publicSaleInfo.raisedAmount < publicSaleInfo.target) {
            excessBook += publicSaleInfo.saleAmount - (
                (((publicSaleInfo.raisedAmount * A_FACTOR) / publicSaleInfo.target) * 
                    publicSaleInfo.saleAmount) / A_FACTOR
            );
        }
        if (excessBook > 0) {
            book.safeTransfer(owner(), excessBook);
        }

        (uint256 t, uint256 w, uint256 p) = _getAmountsRaised();

        presaleFinalized = true;
        emit PresaleFinalized(t, w, p, collectableUSDC, excessBook, block.timestamp);
    }

    function extendTimes(
        uint80 _wlStart, 
        uint80 _wlEnd, 
        uint80 _psStart, 
        uint80 _psEnd, 
        uint80 _claimStart
    ) external override onlyOwner {
        require(
            _wlEnd > _wlStart && 
                _psStart > _wlEnd && 
                _psEnd > _psStart && 
                _claimStart > _psEnd, 
            "Conflicting timeline"
        );
        whitelistSaleInfo.startTime = _wlStart;
        whitelistSaleInfo.endTime = _wlEnd;

        publicSaleInfo.startTime = _psStart;
        publicSaleInfo.endTime = _psEnd;

        claimStart = _claimStart;

        emit TimesExtended(_wlStart, _wlEnd, _psStart, _psEnd, _claimStart);
    }

    function updateManyWhitelist(address[] calldata _users, bool _flag) external override onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            isWhitelisted[_users[i]] = _flag;
        }
        emit UpdatedManyWhitelist(_users, _flag);
    }

    function updateSingleWhitelist(address _user, bool _flag) external override onlyOwner {
        isWhitelisted[_user] = _flag;
        emit UpdatedSingleWhitelist(_user, _flag);
    }

    function getAmountsRaised() external view override returns (
        uint256 totalRaised, 
        uint256 whitelistRaised, 
        uint256 publicRaised
    ) {
        return _getAmountsRaised();
    }

    function getPresaleStatus() external view override returns (uint8 status) {
        return _presaleStatus();
    }

    function getClaimableAmounts(
        address _user
    ) external view override returns (
        uint256 wlBook, 
        uint256 wlRefund, 
        uint256 psBook, 
        uint256 psRefund
    ) {
        return _getClaimableAmounts(_user);
    }

    function getWhitelistSaleInfo() external view override returns (
        uint80 startTime,
    	uint80 endTime,
    	uint256 maxSpend,
    	uint256 target,
    	uint256 saleAmount,
    	uint256 raisedAmount
    ) {
        startTime = whitelistSaleInfo.startTime;
        endTime = whitelistSaleInfo.endTime;
    	maxSpend = whitelistSaleInfo.maxSpend;
    	target = whitelistSaleInfo.target;
    	saleAmount = whitelistSaleInfo.saleAmount;
    	raisedAmount = whitelistSaleInfo.raisedAmount;
    }

    function getPublicSaleInfo() external view override returns (
        uint80 startTime,
    	uint80 endTime,
    	uint256 maxSpend,
    	uint256 target,
    	uint256 saleAmount,
    	uint256 raisedAmount
    ) {
        startTime = publicSaleInfo.startTime;
        endTime = publicSaleInfo.endTime;
    	maxSpend = publicSaleInfo.maxSpend;
    	target = publicSaleInfo.target;
    	saleAmount = publicSaleInfo.saleAmount;
    	raisedAmount = publicSaleInfo.raisedAmount;
    }

    function _getClaimableAmounts(
        address _user
    ) internal view returns (
        uint256 wlBook, 
        uint256 wlRefund, 
        uint256 psBook, 
        uint256 psRefund
    ) {
        UserInfo memory user = contributerInfo[_user];
        if (user.wlContributed > 0) {
            uint256 userRateWL = ((user.wlContributed * A_FACTOR) / whitelistSaleInfo.raisedAmount);
            uint256 refundRateWL = ((whitelistSaleInfo.target * A_FACTOR) / whitelistSaleInfo.raisedAmount);
            if (whitelistSaleInfo.raisedAmount > whitelistSaleInfo.target) {
                wlBook = ((userRateWL * whitelistSaleInfo.saleAmount) / A_FACTOR);
                wlRefund = user.wlRefunded == 0 ? 
                    user.wlContributed - ((refundRateWL * user.wlContributed) / A_FACTOR) : 0;
            } else {
                uint256 adjustedBookWL = (
                    (((whitelistSaleInfo.raisedAmount * A_FACTOR) / whitelistSaleInfo.target) * 
                        whitelistSaleInfo.saleAmount) / A_FACTOR
                );
                wlBook = ((userRateWL * adjustedBookWL) / A_FACTOR);
                wlRefund = 0;
            }
        }

        if (user.psContributed > 0) {
            uint256 userRatePS = ((user.psContributed * A_FACTOR) / publicSaleInfo.raisedAmount);
            uint256 refundRatePS = ((publicSaleInfo.target * A_FACTOR) / publicSaleInfo.raisedAmount);
            if (publicSaleInfo.raisedAmount > publicSaleInfo.target) {
                psBook = ((userRatePS * publicSaleInfo.saleAmount) / A_FACTOR);
                psRefund = user.psContributed - ((refundRatePS * user.psContributed) / A_FACTOR);
            } else {
                uint256 adjustedBookPS = (
                    (((publicSaleInfo.raisedAmount * A_FACTOR) / publicSaleInfo.target) * 
                        publicSaleInfo.saleAmount) / A_FACTOR
                );
                psBook = ((userRatePS * adjustedBookPS) / A_FACTOR);
                psRefund = 0;
            }
        }
    }

    function _getAmountsRaised() internal view returns (
        uint256 totalRaised, 
        uint256 whitelistRaised, 
        uint256 publicRaised
    ) {
        whitelistRaised = whitelistSaleInfo.raisedAmount;
        publicRaised = publicSaleInfo.raisedAmount;
        totalRaised = whitelistRaised + publicRaised;
    }

    function _presaleStatus() internal view returns (uint8 status) {
        if (!contractFunded) {
            return 99; // Contract has not been funded with Book tokens
        }
        if (block.timestamp >= claimStart) {
            return 5; // Presale is claimable
        }
        if (block.timestamp > publicSaleInfo.endTime) {
            return 4; // All Presale rounds have ended and awaiting claimStart
        }
        if (block.timestamp >= publicSaleInfo.startTime) {
            return 3; // Public Sale is active
        }
        if (block.timestamp > whitelistSaleInfo.endTime) {
            return 2; // Whitelist Sale has ended, awaiting start of Public Sale
        }
        if (block.timestamp >= whitelistSaleInfo.startTime) {
            return 1; // Whitelist Sale is active
        }
        if (block.timestamp < whitelistSaleInfo.startTime) {
            return 0; // Awaiting start of Whitelist Sale
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface ICoinBookPresale {

	struct UserInfo {
        uint256 wlContributed;
        uint256 psContributed;
        uint256 wlClaimed;
        uint256 wlRefunded;
        uint256 psClaimed;
        uint256 psRefunded;
        bool claimed;
    }

    struct PresaleInfo {
    	uint80 startTime;
    	uint80 endTime;
    	uint256 maxSpend;
    	uint256 target;
    	uint256 saleAmount;
    	uint256 raisedAmount;
    }

    event Contributed(address indexed user, uint256 amount, string stage, uint256 timeStamp);

    event SwappedToUSDC(address indexed user, uint256 swappedETH, uint256 receivedUSDC);

    event Claimed(
    	address indexed user, 
    	uint256 totalClaimed, 
    	uint256 totalRefunded, 
    	uint256 claimedFromWhitelist, 
    	uint256 claimedFromPublicSale, 
    	uint256 refundedFromWhitelist, 
    	uint256 refundedFromPublicSale, 
    	uint256 timeStamp
    );

    event UpdatedManyWhitelist(address[] users, bool isWhitelisted);

    event UpdatedSingleWhitelist(address user, bool isWhitelisted);

    event PresaleFinalized(
    	uint256 totalRaised, 
    	uint256 whitelistRaised, 
    	uint256 publicRaised,
    	uint256 adjustedCoreRaised,
    	uint256 excessBookNotSold,
    	uint256 timeStamp
    );

    event TimesExtended(
    	uint80 whitelistSaleStart, 
    	uint80 whitelistSaleEnd, 
    	uint80 publicSaleStart, 
    	uint80 publicSaleEnd, 
    	uint80 claimPeriodStart
    );

    event Received(address sender, uint256 amount);

    receive() external payable;

    function contributeInWhitelist(uint256 _amount) external;

    function swapAndContributeInWhitelist(uint256 minAmount) external payable;

    function contributeInPublic(uint256 _amount) external;

    function swapAndContributeInPublic(uint256 minAmount) external payable;

    function claimBook() external;

    function claimExcessWhitelist(bool moveToPublic) external;

    function fundContract() external;

    function finalizePresale() external;

    function extendTimes(
    	uint80 _wlStart, 
    	uint80 _wlEnd, 
    	uint80 _psStart, 
    	uint80 _psEnd, 
    	uint80 _claimStart
    ) external;

    function updateManyWhitelist(address[] calldata _users, bool _flag) external;

    function updateSingleWhitelist(address _user, bool _flag) external;

    function getAmountsRaised() external view returns (
    	uint256 totalRaised, 
    	uint256 whitelistRaised, 
    	uint256 publicRaised
    );

    function getPresaleStatus() external view returns (uint8 status);

    function getClaimableAmounts(
        address _user
    ) external view returns (
        uint256 wlBook, 
        uint256 wlRefund, 
        uint256 psBook, 
        uint256 psRefund
    );

    function getWhitelistSaleInfo() external view returns (
        uint80 startTime,
        uint80 endTime,
        uint256 maxSpend,
        uint256 target,
        uint256 saleAmount,
        uint256 raisedAmount
    );

    function getPublicSaleInfo() external view returns (
        uint80 startTime,
        uint80 endTime,
        uint256 maxSpend,
        uint256 target,
        uint256 saleAmount,
        uint256 raisedAmount
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import { ISwapRouter01 } from "./ISwapRouter01.sol";

interface ISwapRouter is ISwapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface ISwapRouter01 {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function factory() external pure returns (address);
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
interface IERC20PermitUpgradeable {
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