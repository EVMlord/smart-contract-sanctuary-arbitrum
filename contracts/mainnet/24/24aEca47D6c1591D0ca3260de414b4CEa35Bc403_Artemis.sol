/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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



abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}


interface XUSDRoyalty {
    function getFee() external view returns (uint256);
    function getFeeRecipient() external view returns (address);
}

/**
 *  Contract: Artmeis
 */
contract Artemis is IERC20, Ownable, ReentrancyGuard {
    
    using SafeMath for uint256;

    // token data
    string private constant _name = "Artemis";
    string private constant _symbol = "ARTEMIS";
    uint8 private constant _decimals = 18;
    uint256 private constant precision = 10**18;
    
    // 0 initial supply
    uint256 private _totalSupply; 
    
    // balances
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // address -> Fee Exemption
    mapping ( address => bool ) public isTransferFeeExempt;

    // Token Activation
    bool public tokenActivated;

    // UNISWAP Router
    IUniswapV2Router02 public router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    // Underlying Asset Is USDT
    IERC20 public constant underlying = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);

    // Swap Path From WETH -> USDT
    address[] private path = [ router.WETH(), address(underlying) ];

    // Fees
    uint256 public mintFee        = 92000;            // 8% mint fee
    uint256 public sellFee        = 92000;            // 8% redeem fee 
    uint256 public transferFee    = 92000;            // 8% transfer fee
    uint256 private constant feeDenominator = 10**5;

    // Fee Recipient
    address public feeRecipient;
    address public feeRecipientSetter;
    uint256 public feeRecipientPercentage = 500;

    // initialize some stuff
    constructor() {

        // set fee recipient setter
        feeRecipientSetter = address(0);

        // exempt deployer and fee setter
        isTransferFeeExempt[msg.sender] = true;
        isTransferFeeExempt[feeRecipientSetter] = true;

        // let token show on etherscan
        emit Transfer(address(0), msg.sender, 0);
    }

    /** Returns the total number of tokens in existence */
    function totalSupply() external view override returns (uint256) { 
        return _totalSupply; 
    }

    /** Returns the number of tokens owned by `account` */
    function balanceOf(address account) public view override returns (uint256) { 
        return _balances[account]; 
    }

    /** Returns the number of tokens `spender` can transfer from `holder` */
    function allowance(address holder, address spender) external view override returns (uint256) { 
        return _allowances[holder][spender]; 
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        uint256 amount = _allowances[msg.sender][spender].add(addedValue);
        _allowances[msg.sender][spender] = amount ;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 amount = _allowances[msg.sender][spender].sub(subtractedValue, "Decreased allowance below zero");
        _allowances[msg.sender][spender] = amount ;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Token Name */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /** Token Ticker Symbol */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /** Tokens decimals */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /** Approves `spender` to transfer `amount` tokens from caller */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
  
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override nonReentrant returns (bool) {
        if (recipient == msg.sender) {
            emit Transfer(msg.sender, msg.sender, amount);
            return true;
        } else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override nonReentrant returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, 'Insufficient Allowance');
        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(
            recipient != address(0) && 
            sender != address(0),
            "Transfer To Zero"
        );
        require(
            amount > 0, 
            "Transfer Amt Zero"
        );

        if (sender == recipient) {
            emit Transfer(sender, recipient, amount);
            return true;
        }

        // track price change
        uint256 oldPrice = _calculatePrice();

        // amount to give recipient
        uint256 tAmount = (isTransferFeeExempt[sender] || isTransferFeeExempt[recipient]) ? amount : amount.mul(transferFee).div(feeDenominator);
       
        // tax taken from transfer
        uint256 tax = amount.sub(tAmount);
        
        // subtract from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        // give reduced amount to receiver
        _balances[recipient] = _balances[recipient].add(tAmount);

        // burn the tax
        if (tax > 0) {
            // Take Fee
            _takeFee(tax);
            _totalSupply = _totalSupply.sub(tax);
            emit Transfer(sender, address(0), tax);
        }
        
        // require price rises
        _requirePriceRises(oldPrice);

        // Transfer Event
        emit Transfer(sender, recipient, tAmount);
        return true;
    }

    /**
        Mint WhiteLabel Tokens With The Native Token ( Smart Chain ETH )
        This will purchase USDT with ETH received
        It will then mint tokens to `recipient` based on the number of stable coins received
        `minOut` should be set to avoid the Transaction being front runned

        @param recipient Account to receive minted WhiteLabel Tokens
        @param minOut minimum amount out from ETH -> USDT - prevents front run attacks
        @return received number of WhiteLabel tokens received
     */
    function mintWithNative(address recipient, uint256 minOut) external payable returns (uint256) {
        _checkGarbageCollector(address(this));
        return _mintWithNative(recipient, minOut);
    }


    /** 
        Mint WhiteLabel Tokens For `recipient` By Depositing USDT Into The Contract
            Requirements:
                Approval from the USDT prior to purchase
        
        @param numTokens number of USDT tokens to mint WhiteLabel with
        @param recipient Account to receive minted WhiteLabel tokens
        @return tokensMinted number of WhiteLabel tokens minted
    */
    function mintWithBacking(uint256 numTokens, address recipient) external nonReentrant returns (uint256) {
        _checkGarbageCollector(address(this));
        return _mintWithBacking(numTokens, recipient);
    }

    /** 
        Burns Sender's WhiteLabel Tokens and redeems their value in USDT
        @param tokenAmount Number of WhiteLabel Tokens To Redeem, Must be greater than 0
    */
    function sell(uint256 tokenAmount) external nonReentrant returns (uint256) {
        return _sell(tokenAmount, msg.sender);
    }
    
    /** 
        Burns Sender's WhiteLabel Tokens and redeems their value in USDT for `recipient`
        @param tokenAmount Number of WhiteLabel Tokens To Redeem, Must be greater than 0
        @param recipient Recipient Of USDT transfer, Must not be address(0)
    */
    function sell(uint256 tokenAmount, address recipient) external nonReentrant returns (uint256) {
        return _sell(tokenAmount, recipient);
    }
    
    /** 
        Allows A User To Erase Their Holdings From Supply 
        DOES NOT REDEEM UNDERLYING ASSET FOR USER
        @param amount Number of WhiteLabel Tokens To Burn
    */
    function burn(uint256 amount) external nonReentrant {
        // get balance of caller
        uint256 bal = _balances[msg.sender];
        require(bal >= amount && bal > 0, 'Zero Holdings');
        // Track Change In Price
        uint256 oldPrice = _calculatePrice();
        // take fee
        _takeFee(amount);
        // burn tokens from sender + supply
        _burn(msg.sender, amount);
        // require price rises
        _requirePriceRises(oldPrice);
        // Emit Call
        emit Burn(msg.sender, amount);
    }


    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
    
    /** Purchases WhiteLabel Token and Deposits Them in Recipient's Address */
    function _mintWithNative(address recipient, uint256 minOut) internal nonReentrant returns (uint256) {        
        require(
            msg.value > 0, 
            'Zero Value'
        );
        require(
            recipient != address(0), 
            'Zero Address'
        );
        require(
            tokenActivated || msg.sender == this.getOwner(),
            'Token Not Activated'
        );
        
        // calculate price change
        uint256 oldPrice = _calculatePrice();
        
        // previous backing
        uint256 previousBacking = underlying.balanceOf(address(this));
        
        // swap ETH for stable
        uint256 received = _purchaseUSDT(minOut);

        // if this is the first purchase, use new amount
        uint256 relevantBacking = previousBacking == 0 ? underlying.balanceOf(address(this)) : previousBacking;

        // mint to recipient
        return _mintTo(recipient, received, relevantBacking, oldPrice);
    }
    
    /** Stake Tokens and Deposits WhiteLabel in Sender's Address, Must Have Prior Approval For USDT */
    function _mintWithBacking(uint256 numUSDT, address recipient) internal returns (uint256) {
        require(
            tokenActivated || msg.sender == this.getOwner(),
            'Token Not Activated'
        );

        require(recipient != address(0), 'Zero Address');

        // calculate price change
        uint256 oldPrice = _calculatePrice();

        // previous backing
        uint256 previousBacking = underlying.balanceOf(address(this));

        // transfer in token
        uint256 received = _transferIn(address(underlying), numUSDT);

        // if this is the first purchase, use new amount
        uint256 relevantBacking = previousBacking == 0 ? underlying.balanceOf(address(this)) : previousBacking;

        // Handle Minting
        return _mintTo(recipient, received, relevantBacking, oldPrice);
    }
    
    /** Burns WhiteLabel Tokens And Deposits USDT Tokens into Recipients's Address */
    function _sell(uint256 tokenAmount, address recipient) internal returns (uint256) {
        
        // seller of tokens
        address seller = msg.sender;
        
        require(
            tokenAmount > 0 && _balances[seller] >= tokenAmount,
            'Insufficient Balance'
        );
        require(
            recipient != address(0),
            'Invalid Recipient'
        );
        
        // calculate price change
        uint256 oldPrice = _calculatePrice();
        
        // tokens post fee to swap for underlying asset
        uint256 tokensToSwap = isTransferFeeExempt[seller] ? 
            tokenAmount.sub(10, 'Minimum Exemption') :
            tokenAmount.mul(sellFee).div(feeDenominator);

        // value of taxed tokens
        uint256 amountUnderlyingAsset = amountOut(tokensToSwap);

        // Take Fee
        if (!isTransferFeeExempt[msg.sender]) {
            uint fee = tokenAmount.sub(tokensToSwap);
            _takeFee(fee);
        }

        // burn from sender + supply 
        _burn(seller, tokenAmount);

        // send Tokens to Seller
        require(
            underlying.transfer(recipient, amountUnderlyingAsset), 
            'Underlying Transfer Failure'
        );

        // require price rises
        _requirePriceRises(oldPrice);
        // Differentiate Sell
        emit Redeemed(seller, tokenAmount, amountUnderlyingAsset);

        // return token redeemed and amount underlying
        return amountUnderlyingAsset;
    }

    /** Handles Minting Logic To Create New WhiteLabel */
    function _mintTo(address recipient, uint256 received, uint256 totalBacking, uint256 oldPrice) internal returns(uint256) {
        
        // tokens to mint with no tax
        uint256 nTokensToMint = tokensToMint(received, totalBacking);

        // whether fee was applied or not
        bool hasFee = !isTransferFeeExempt[msg.sender] && _totalSupply > 0;
           
        // ensure there are tokens to mint
        require(
            nTokensToMint > 0, 
            'Zero Amount To Mint'
        );
        
        // mint to Buyer
        _mint(recipient, nTokensToMint);

        if (hasFee) {
            uint256 nTokensToMintNoTax = nTokensToMint.mul(mintFee).div(feeDenominator);
            _takeFee(nTokensToMint.sub(nTokensToMintNoTax));
        }


        // require price rises
        _requirePriceRises(oldPrice);
        
        // differentiate purchase
        emit Minted(recipient, nTokensToMint);
        return nTokensToMint;
    }

    /** Takes Fee */
    function _takeFee(uint mFee) internal {

        // send percentage to fee recipient
        uint256 fee = ( mFee * feeRecipientPercentage ) / 1000;
        if (fee > 0 && feeRecipient != address(0)) {
            unchecked {
                _balances[feeRecipient] += fee;
                _totalSupply += fee;
            }
            emit Transfer(address(0), feeRecipient, fee);
        }
    }

    /** Swaps ETH for USDT, must get at least `minOut` USDT back from swap to be successful */
    function _purchaseUSDT(uint256 minOut) internal returns (uint256) {

        // previous amount of Tokens before we received any
        uint256 prevTokenAmount = underlying.balanceOf(address(this));

        // swap ETH For stable of choice
        router.swapExactETHForTokens{value: address(this).balance}(minOut, path, address(this), block.timestamp);

        // amount after swap
        uint256 currentTokenAmount = underlying.balanceOf(address(this));
        require(
            currentTokenAmount > prevTokenAmount,
            'Zero USDT Received'
        );
        return currentTokenAmount - prevTokenAmount;
    }

    /** Requires The Price Of WhiteLabel To Rise For The Transaction To Conclude */
    function _requirePriceRises(uint256 oldPrice) internal {
        // Calculate Price After Transaction
        uint256 newPrice = _calculatePrice();
        // Require Current Price >= Last Price
        require(newPrice >= oldPrice, 'Price Cannot Fall');
        // Emit The Price Change
        emit PriceChange(oldPrice, newPrice, _totalSupply);
    }

    /** Transfers `desiredAmount` of `token` in and verifies the transaction success */
    function _transferIn(address token, uint256 desiredAmount) internal returns (uint256) {
        uint256 balBefore = IERC20(token).balanceOf(address(this));
        bool s = IERC20(token).transferFrom(msg.sender, address(this), desiredAmount);
        uint256 received = IERC20(token).balanceOf(address(this)) - balBefore;
        require(s && received > 0 && received <= desiredAmount);
        return received;
    }
    
    /** Mints Tokens to the Receivers Address */
    function _mint(address receiver, uint amount) internal {
        _balances[receiver] = _balances[receiver].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), receiver, amount);
    }
    
    /** Burns `amount` of tokens from `account` */
    function _burn(address account, uint amount) internal {
        _balances[account] = _balances[account].sub(amount, 'Insufficient Balance');
        _totalSupply = _totalSupply.sub(amount, 'Negative Supply');
        emit Transfer(account, address(0), amount);
    }

    /** Make Sure there's no Native Tokens in contract */
    function _checkGarbageCollector(address burnLocation) internal {
        uint256 bal = _balances[burnLocation];
        if (bal > 10**6) {
            // Track Change In Price
            uint256 oldPrice = _calculatePrice();
            // take fee
            _takeFee(bal);
            // burn amount
            _burn(burnLocation, bal);
            // Emit Collection
            emit GarbageCollected(bal);
            // Require price rises
            _requirePriceRises(oldPrice);
        }
    }
    
    ///////////////////////////////////
    //////    READ FUNCTIONS    ///////
    ///////////////////////////////////
    

    /** Price Of WhiteLabel in USDT With 18 Points Of Precision */
    function calculatePrice() external view returns (uint256) {
        return _calculatePrice();
    }
    
    /** Returns the Current Price of 1 Token */
    function _calculatePrice() internal view returns (uint256) {
        if (_totalSupply == 0) {
            return 10**18;
        }
        uint256 backingValue = underlying.balanceOf(address(this));
        return (backingValue.mul(precision)).div(_totalSupply);
    }

    /** Number Of Tokens To Mint */
    function tokensToMint(uint256 received, uint256 totalBacking) public view returns (uint256) {
        return 
            _totalSupply == 0 ? 
                received : 
                isTransferFeeExempt[msg.sender] ? 
                    _totalSupply.mul(received).div(totalBacking).sub(100) : // sub 100 to avoid any round off error
                    _totalSupply.mul(received).div(totalBacking).mul(mintFee).div(feeDenominator);
    }

    function mintFeeTaken(uint256 amount) public view returns (uint256) {
        uint fee = ( amount * mintFee ) / feeDenominator;
        return amount - fee;
    }

    /**
        Amount Of Underlying To Receive For `numTokens` of WhiteLabel
     */
    function amountOut(uint256 numTokens) public view returns (uint256) {
        return _calculatePrice().mul(numTokens).div(precision);
    }

    /** Returns the value of `holder`'s holdings */
    function getValueOfHoldings(address holder) public view returns(uint256) {
        return amountOut(_balances[holder]);
    }
    
    ///////////////////////////////////
    //////   OWNER FUNCTIONS    ///////
    ///////////////////////////////////

    /** Activates Token, Enabling Trading For All */
    function activateToken() external onlyOwner {
        tokenActivated = true;
        emit TokenActivated(block.number);
    }

    /** Pauses Token Activation */
    function deActivateToken() external onlyOwner {
        tokenActivated = false;
        emit TokenDeActivated(block.number);
    }

    /** Updates The Address Of The Router To Purchase USDT */
    function upgradeRouter(address newRouter) external onlyOwner {
        require(newRouter != address(0));
        router = IUniswapV2Router02(newRouter);
        emit SetRouter(newRouter);
    }

    /** Withdraws Tokens Incorrectly Sent To WhiteLabel */
    function withdrawNonStableToken(IERC20 token) external onlyOwner {
        require(address(token) != address(underlying), 'Cannot Withdraw Underlying Asset');
        require(address(token) != address(0), 'Zero Address');
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    
    /** 
        Sets Mint, Transfer, Sell Fee
        Must Be Within Bounds ( Between 0% - 10% ) 
    */
    function setFees(uint256 _mintFee, uint256 _transferFee, uint256 _sellFee) external onlyOwner {
        require(_mintFee >= 90000);       // capped at 10% fee
        require(_transferFee >= 90000);   // capped at 10% fee
        require(_sellFee >= 90000);       // capped at 10% fee
        
        mintFee = _mintFee;
        transferFee = _transferFee;
        sellFee = _sellFee;
        emit SetFees(_mintFee, _transferFee, _sellFee);
    }
    
    /** Excludes Contract From Transfer Fees */
    function setPermissions(address Contract, bool transferFeeExempt) external onlyOwner {
        require(Contract != address(0), 'Zero Address');
        isTransferFeeExempt[Contract] = transferFeeExempt;
        emit SetPermissions(Contract, transferFeeExempt);
    }

    function setFeeRecipientSetter(address newSetter) external {
        require(msg.sender == feeRecipientSetter, 'Only Setter Can Set New Setter');
        feeRecipientSetter = newSetter;
    }

    function setFeeRecipient(address newRecipient) external {
        require(msg.sender == feeRecipientSetter, 'Only Setter Can Set New Recipient');
        isTransferFeeExempt[feeRecipient] = false;
        feeRecipient = newRecipient;
        isTransferFeeExempt[newRecipient] = true;
    }

    function setFeeRecipientPercentage(uint256 newPercentage) external {
        require(msg.sender == feeRecipientSetter, 'Only Setter Can Set New Recipient');
        require(newPercentage <= 1000, 'MAX PERCENTAGE');
        feeRecipientPercentage = newPercentage;
    }
    
    /** Mint Tokens to Buyer */
    receive() external payable {
        _mintWithNative(msg.sender, 0);
        _checkGarbageCollector(address(this));
    }
    
    
    ///////////////////////////////////
    //////        EVENTS        ///////
    ///////////////////////////////////
    
    // Data Tracking
    event PriceChange(uint256 previousPrice, uint256 currentPrice, uint256 totalSupply);
    event TokenActivated(uint blockNo);
    event TokenDeActivated(uint blockNo);

    // Balance Tracking
    event Burn(address from, uint256 amountTokensErased);
    event GarbageCollected(uint256 amountTokensErased);
    event Redeemed(address seller, uint256 amountWhiteLabel, uint256 amountUSDT);
    event Minted(address recipient, uint256 numTokens);

    // Upgradable Contract Tracking
    event SetMaxHoldings(uint256 maxHoldings);
    event SetRouter(address newRouter);

    // Governance Tracking
    event SetPermissions(address Contract, bool feeExempt);
    event SetMaxHoldingsExempt(address account, bool isExempt);
    event SetFees(uint mintFee, uint transferFee, uint sellFee);
}