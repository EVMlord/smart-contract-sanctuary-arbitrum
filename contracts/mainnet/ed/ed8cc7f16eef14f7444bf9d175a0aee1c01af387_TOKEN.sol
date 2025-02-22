/**
 *Submitted for verification at Arbiscan on 2023-02-07
*/

// SPDX-License-Identifier: Unlicensed

        pragma solidity ^0.8.4;

        interface IERC20 {
            
            function totalSupply() external view returns (uint256);
            function balanceOf(address account) external view returns (uint256);
            function transfer(address recipient, uint256 amount) external returns (bool);
            function allowance(address owner, address spender) external view returns (uint256);
            function approve(address spender, uint256 amount) external returns (bool);
            function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
            
            event Transfer(address indexed from, address indexed to, uint256 value);
            event Approval(address indexed owner, address indexed spender, uint256 value);
        }

        library SafeMath {
        

            function add(uint256 a, uint256 b) internal pure returns (uint256) {
                return a + b;
            }


            function sub(uint256 a, uint256 b) internal pure returns (uint256) {
                return a - b;
            }


            function mul(uint256 a, uint256 b) internal pure returns (uint256) {
                return a * b;
            }
            
            function div(uint256 a, uint256 b) internal pure returns (uint256) {
                return a / b;
            }
    
            function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
                unchecked {
                    require(b <= a, errorMessage);
                    return a - b;
                }
            }
            
            function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
                unchecked {
                    require(b > 0, errorMessage);
                    return a / b;
                }
            }        
            
    }

        abstract contract Context {
            function _msgSender() internal view virtual returns (address) {
                return msg.sender;
            }

            function _msgData() internal view virtual returns (bytes calldata) {
                this; 
                return msg.data;
            }
        }


        abstract contract Ownable is Context {
            address internal _owner;
            address private _previousOwner;

            event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
            constructor () {
                _owner = _msgSender();
                emit OwnershipTransferred(address(0), _owner);
            }
            
            function owner() public view virtual returns (address) {
                return _owner;
            }
            
            modifier onlyOwner() {
                require(owner() == _msgSender(), "Ownable: caller is not the owner");
                _;
            }
            
            function renounceOwnership() public virtual onlyOwner {
                emit OwnershipTransferred(_owner, address(0));
                _owner = address(0);
            }


            function transferOwnership(address newOwner) public virtual onlyOwner {
                require(newOwner != address(0), "Ownable: new owner is the zero address");
                emit OwnershipTransferred(_owner, newOwner);
                _owner = newOwner;
            }
        }

    
        interface IERC20Metadata is IERC20 {
            function name() external view returns (string memory);
            function symbol() external view returns (string memory);
            function decimals() external view returns (uint8);
        }
        contract ERC20 is Context,Ownable, IERC20, IERC20Metadata {
            using SafeMath for uint256;

            mapping(address => uint256) private _balances;

            mapping(address => mapping(address => uint256)) private _allowances;

            uint256 private _totalSupply;

            string private _name;
            string private _symbol;

            constructor(string memory name_, string memory symbol_) {
                _name = name_;
                _symbol = symbol_;
            }

            function name() public view virtual override returns (string memory) {
                return _name;
            }

            function symbol() public view virtual override returns (string memory) {
                return _symbol;
            }
            function decimals() public view virtual override returns (uint8) {
                return 18;
            }
            function totalSupply() public view virtual override returns (uint256) {
                return _totalSupply;
            }
            function balanceOf(address account) public view virtual override returns (uint256) {
                return _balances[account];
            }
            function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
                _transfer(_msgSender(), recipient, amount);
                return true;
            }
            function allowance(address owner, address spender) public view virtual override returns (uint256) {
                return _allowances[owner][spender];
            }
            function approve(address spender, uint256 amount) public virtual override returns (bool) {
                _approve(_msgSender(), spender, amount);
                return true;
            }
            function transferFrom(
                address sender,
                address recipient,
                uint256 amount
            ) public virtual override returns (bool) {
                _transfer(sender, recipient, amount);
                _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
                return true;
            }
            function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
                _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
                return true;
            }
            function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
                _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
                return true;
            }
            function _transfer(
                address sender,
                address recipient,
                uint256 amount
            ) internal virtual {
                require(sender != address(0), "ERC20: transfer from the zero address");
                require(recipient != address(0), "ERC20: transfer to the zero address");

                _beforeTokenTransfer(sender, recipient, amount);

                _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
                _balances[recipient] = _balances[recipient].add(amount);
                emit Transfer(sender, recipient, amount);
            }
            function _mint(address account, uint256 amount) internal virtual {
                require(account != address(0), "ERC20: mint to the zero address");

                _beforeTokenTransfer(address(0), account, amount);

                _totalSupply = _totalSupply.add(amount);
                _balances[account] = _balances[account].add(amount);
                emit Transfer(address(0), account, amount);
            }
            function _burn(address account, uint256 amount) internal virtual {
                require(account != address(0), "ERC20: burn from the zero address");

                _beforeTokenTransfer(account, address(0), amount);

                _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
                _totalSupply = _totalSupply.sub(amount);
                emit Transfer(account, address(0), amount);
            }
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
            function _beforeTokenTransfer(
                address from,
                address to,
                uint256 amount
            ) internal virtual {}
        }


        interface IUniswapV2Factory {
            function createPair(address tokenA, address tokenB) external returns (address pair);
        }

        interface IUniswapV2Pair {
            function factory() external view returns (address);
        }

        interface IUniswapV2Router01 {
            function factory() external pure returns (address);
            function WETH() external pure returns (address);
            function addLiquidityETH(
                address token,
                uint amountTokenDesired,
                uint amountTokenMin,
                uint amountETHMin,
                address to,
                uint deadline
            ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
        }

        interface IUniswapV2Router02 is IUniswapV2Router01 {
            function swapExactTokensForETHSupportingFeeOnTransferTokens(
                uint amountIn,
                uint amountOutMin,
                address[] calldata path,
                address to,
                uint deadline
            ) external;
        }

        contract TOKEN is ERC20 {
            using SafeMath for uint256;

            mapping (address => bool) private _isExcludedFromFee;
            mapping(address => bool) private _isExcludedFromMaxWallet;
            mapping(address => bool) private _isExcludedFromMaxTnxLimit;

            address constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
            address public _marketingWalletAddress;   
            address public _devWalletAddress;
            uint256 public _liquidityFee;
            
            uint256 public _buyLiquidityFee = 2;  
            uint256 public _buyMarketingFee = 5;  
            uint256 public _buyDevFee = 5;  

            uint256 public _sellLiquidityFee = 2; 
            uint256 public _sellMarketingFee = 5; 
            uint256 public _sellDevFee = 5;

            IUniswapV2Router02 public uniswapV2Router;
            address public uniswapV2Pair;
            bool inSwapAndLiquify;
            bool public swapAndLiquifyEnabled = true;
            uint256 public numTokensSellToAddToLiquidity;

            uint256 public _maxWalletBalance;
            uint256 public _maxTxAmount;
            event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
            event SwapAndLiquifyEnabledUpdated(bool enabled);
            
            constructor () ERC20("TEST88", "T8T"){ // The  TEST1 is token name and Symbol : T3T you can cahnge it 

                numTokensSellToAddToLiquidity = 10000 * 10 ** decimals();

                _marketingWalletAddress = 0xf63e6E7f810419fAA3Dc45dF91128b91BfE7E6F6;  // here you can change the markeitng wallet address just replace this address
                _devWalletAddress = 0x8147387327fb314A23E274C5fF2267e27881F420; // here you can chagne the dev wallet address just replace this address with new one 
                
                IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
                // Create a uniswap pair for this new token
                uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                    .createPair(address(this), _uniswapV2Router.WETH());

                // set the rest of the contract variables
                uniswapV2Router = _uniswapV2Router;
                
                //exclude owner and this contract from fee
                _isExcludedFromFee[_msgSender()] = true;
                _isExcludedFromFee[address(this)] = true;
            
                // exclude from the Max wallet balance 
                _isExcludedFromMaxWallet[owner()] = true;
                _isExcludedFromMaxWallet[address(this)] = true;
                _isExcludedFromMaxWallet[_marketingWalletAddress] = true;

                // exclude from the max tnx limit 
                _isExcludedFromMaxTnxLimit[owner()] = true;
                _isExcludedFromMaxTnxLimit[address(this)] = true;
                _isExcludedFromMaxTnxLimit[_marketingWalletAddress] = true;

                /*
                    _mint is an internal function in ERC20.sol that is only called here,
                    and CANNOT be called ever again
                */
                _mint(owner(), 100000000 * 10 ** decimals()); // here is total supply of token you can chagne this now 100,000,000
                		
                _maxWalletBalance = (totalSupply() * 2 ) / 100; // here Max wallet is 1% you can change it  to any % lie 2 hee now its 2% 
                _maxTxAmount = (totalSupply() * 2 ) / 100;		// Here you can change the max tnx amount now it's 1% you cna chang it to2% or 3%
                
            }

            function excludeFromFee(address account) public onlyOwner {
                _isExcludedFromFee[account] = true;
            }
            
            function includeInFee(address account) public onlyOwner {
                _isExcludedFromFee[account] = false;
            }

            function includeAndExcludedFromMaxWallet(address account, bool value) public onlyOwner {
                _isExcludedFromMaxWallet[account] = value;
                }

            function includeAndExcludedFromMaxTnxLimit(address account, bool value) public onlyOwner {
                _isExcludedFromMaxTnxLimit[account] = value;
            }

            function isExcludedFromMaxWallet(address account) public view returns(bool){
               return _isExcludedFromMaxWallet[account];
             }

            function isExcludedFromMaxTnxLimit(address account) public view returns(bool) {
                return _isExcludedFromMaxTnxLimit[account];
            }

            function setMaxWalletBalance(uint256 maxBalancePercent) external onlyOwner {
              _maxWalletBalance = maxBalancePercent * 10** decimals();
            }

            function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
              _maxTxAmount = maxTxAmount * 10** decimals();
             }

            function setSellFeePercent(
                uint256 lFee,
                uint256 mFee,
                uint256 dFee
            ) external onlyOwner {
                _sellLiquidityFee = lFee;
                _sellMarketingFee = mFee;
                _sellDevFee = dFee;
                uint256 sellTotalFees = _sellLiquidityFee + _sellMarketingFee + _sellDevFee;
                require(sellTotalFees <= 99, "Must keep fees at 99% or less"); 
            }

            function setBuyFeePercent(
                uint256 lFee,
                uint256 mFee,
                uint256 dFee
            ) external onlyOwner {
                _buyLiquidityFee = lFee;
                _buyMarketingFee = mFee;
                _buyDevFee = dFee;
                uint256 buyTotalFees = _buyLiquidityFee + _buyMarketingFee + _buyDevFee;
                require(buyTotalFees <= 99, "Must keep fees at 99% or less");   

            }

            function setMarketingWalletAddress(address _addr) external onlyOwner {
                _marketingWalletAddress = _addr;
            }

            function setDevWalletAddress(address _addr) external onlyOwner {
                _devWalletAddress = _addr;
            }
            
            function setNumTokensSellToAddToLiquidity(uint256 amount) external onlyOwner {
                numTokensSellToAddToLiquidity = amount * 10 ** decimals();
            }

            function setRouterAddress(address newRouter) external onlyOwner {
                IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouter);
                uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
                uniswapV2Router = _uniswapV2Router;
            }

            function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
                swapAndLiquifyEnabled = _enabled;
                emit SwapAndLiquifyEnabledUpdated(_enabled);
            }
            
            //to recieve ETH from uniswapV2Router when swaping
            receive() external payable {}

            // to withdraw stucked ETH 
            function withdrawStuckedFunds(uint amount) external onlyOwner{
                // This is the current recommended method to use.
                (bool sent,) = _owner.call{value: amount}("");
                require(sent, "Failed to send ETH");    
            }

            // Withdraw stuked tokens 
            function withdrawStuckedTokens(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success){
            return IERC20(tokenAddress).transfer(msg.sender, tokens);
            }
        

            function isExcludedFromFee(address account) public view returns(bool) {
                return _isExcludedFromFee[account];
            }

            function _transfer(
                address from,
                address to,
                uint256 amount
            ) internal override {
                require(from != address(0), "ERC20: transfer from the zero address");
                require(to != address(0), "ERC20: transfer to the zero address");
                require(amount > 0, "Transfer amount must be greater than zero");
                
                if (from != owner() && to != owner())
                    require( _isExcludedFromMaxTnxLimit[from] || _isExcludedFromMaxTnxLimit[to] || 
                        amount <= _maxTxAmount,
                        "ERC20: Transfer amount exceeds the maxTxAmount."
                    );    
                
                if (
                    from != owner() &&
                    to != address(this) &&
                    to != _burnAddress &&
                    to != uniswapV2Pair ) 
                {
                    uint256 currentBalance = balanceOf(to);
                    require(_isExcludedFromMaxWallet[to] || (currentBalance + amount <= _maxWalletBalance),
                            "ERC20: Reached max wallet holding");
                }
                uint256 contractTokenBalance = balanceOf(address(this)); 
                bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
                if (
                    overMinTokenBalance &&
                    !inSwapAndLiquify &&
                    from != uniswapV2Pair &&
                    swapAndLiquifyEnabled
                ) {
                    contractTokenBalance = numTokensSellToAddToLiquidity;
                    inSwapAndLiquify = true;
                    swapBack(contractTokenBalance);
                    inSwapAndLiquify = false;
                }
                
               bool takeFee = true;
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                super._transfer(from, to, amount);
                takeFee = false;
            } else {

            if (from == uniswapV2Pair) {
                // Buy
                uint256 liquidityTokens = amount.mul(_buyLiquidityFee).div(100);
                uint256 marketingTokens = amount.mul(_buyMarketingFee).div(100);
                uint256 devTokens = amount.mul(_buyDevFee).div(100);

                amount= amount.sub(liquidityTokens.add(marketingTokens).add(devTokens));
                super._transfer(from, address(this), liquidityTokens.add(marketingTokens).add(devTokens));
                super._transfer(from, to, amount);

            } else if (to == uniswapV2Pair) {
                // Sell
                uint256 liquidityTokens = amount.mul(_sellLiquidityFee).div(100);
                uint256 marketingTokens = amount.mul(_sellMarketingFee).div(100);
                uint256 devTokens = amount.mul(_sellDevFee).div(100);

                amount= amount.sub(liquidityTokens.add(marketingTokens).add(devTokens));
                super._transfer(from, address(this), liquidityTokens.add(marketingTokens).add(devTokens));
                super._transfer(from, to, amount);
            } else {
                // Transfer
                super._transfer(from, to, amount);
            }

        }
            }

            function swapBack(uint256 contractBalance) private {

                uint256 tokensForLiquidity = contractBalance.mul(_sellLiquidityFee).div(100);
                uint256 marketingTokens = contractBalance.mul(_sellMarketingFee).div(100);
                uint256 devTokens = contractBalance.mul(_sellDevFee).div(100);


                uint256 totalTokensToSwap = tokensForLiquidity + marketingTokens + devTokens ;
                
                if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

                bool success;
                
                // Halve the amount of liquidity tokens
                uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
                
                swapTokensForEth(contractBalance - liquidityTokens); 
                
                uint256 ethBalance = address(this).balance;
                uint256 ethForLiquidity = ethBalance;

                uint256 ethForMarketing = ethBalance * marketingTokens / (totalTokensToSwap - (tokensForLiquidity/2));
                uint256 ethForDev = ethBalance * devTokens / (totalTokensToSwap - (tokensForLiquidity/2));

                ethForLiquidity -= ethForMarketing + ethForDev ;
                                
                if(liquidityTokens > 0 && ethForLiquidity > 0){
                    addLiquidity(liquidityTokens, ethForLiquidity);

                }

                (success,) = address(_marketingWalletAddress).call{value: ethForMarketing}("");
                (success,) = address(_devWalletAddress).call{value: ethForDev}("");

        }       

            function swapTokensForEth(uint256 tokenAmount) private {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = uniswapV2Router.WETH();
                _approve(address(this), address(uniswapV2Router), tokenAmount);
                uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0, // accept any amount of ETH
                    path,
                    address(this),
                    block.timestamp
                );
            }

            function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
                _approve(address(this), address(uniswapV2Router), tokenAmount);
                uniswapV2Router.addLiquidityETH{value: ethAmount}(
                    address(this),
                    tokenAmount,
                    0, // slippage is unavoidable
                    0, // slippage is unavoidable
                    owner(),
                    block.timestamp
                );
            }
        }