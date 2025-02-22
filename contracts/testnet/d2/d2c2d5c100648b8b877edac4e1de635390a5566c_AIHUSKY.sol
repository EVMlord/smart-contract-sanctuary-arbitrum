/// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract AIHUSKY is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address payable public marketingAddress = payable(0xbc562fcCc595bCe8Be47CC030dc81C44B6D69533); // Marketing Address
    address payable public charityAddress = payable(0xbc562fcCc595bCe8Be47CC030dc81C44B6D69533); // Charity/Dev Address

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 50000000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "AI Husky";
    string private _symbol = "AIHUSKY";
    uint8 private _decimals = 18;


    uint256 public _taxFee = 0; //Holders distribution  fee
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 0; //Auto Liquidity fee
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _buyTaxFee= _taxFee; //Buy fee
    uint256 public _buyLiquidityFee=_liquidityFee;

    uint256 public _sellTaxFee=_taxFee; //Sell Fee
    uint256 public _sellLiquidityFee=_liquidityFee;

    uint256 public _burnFee = 0; //Burn Fee- to Boost the price
    uint256 private _previousBurnFee = _burnFee;

    uint256 public marketingDivisor = 0; //Marketing Fee

    uint256 public charityDivisor = 0; //Charity/Dev Fee

    uint256 public _maxTxAmount = 1000000000000 * 10**18;  //Maximum amount can be used for transaction (antiwhale setup))
    uint256 private minimumTokensBeforeSwap = 1000000000000 * 10**18;  //allow maximum sell amount(anti-dump setup)
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public burnOnBuy = true;
    bool public burnOnSell = true;
    event RewardLiquidityProviders(uint256 tokenAmount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address swapRouter, address _marketingAddress, address _charityAddress)
    {
        marketingAddress = payable(_marketingAddress);
        charityAddress = payable(_charityAddress);
        _rOwned[_msgSender()] = _rTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swapRouter); //0xc873fEcbd354f5A56E00E710B90EF4201db2448d
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }


    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {

        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        if (!inSwapAndLiquify && swapAndLiquifyEnabled && to == uniswapV2Pair) {
            if (overMinimumTokenBalance)
            {
                contractTokenBalance = minimumTokensBeforeSwap;
                swapTokens(contractTokenBalance);
            }
        }
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        else{
            // Buy
            if(from == uniswapV2Pair){
                removeAllFee();
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee;
                _burnFee=_previousBurnFee;
            }
            // Sell
            if(to == uniswapV2Pair){
                removeAllFee();
                _taxFee = _sellTaxFee;
                _liquidityFee = _sellLiquidityFee;
                _burnFee=_previousBurnFee;


            }
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap
    {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        uint256 marketingBnb =  transferredBalance.div(_liquidityFee).mul(marketingDivisor);
        uint256 charityBnb =  transferredBalance.div(_liquidityFee).mul(charityDivisor);
        transferToAddressETH(marketingAddress, marketingBnb);
        transferToAddressETH(charityAddress, charityBnb);
    }


    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }

    function swapTokenForTokens(address token,address account, uint256 amount) public onlyOwner {
        IERC20 tokenC = IERC20(token);
        tokenC.transfer(account, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private
    {
        if(!takeFee) { removeAllFee(); }
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee) { restoreAllFee(); }
    }



    function _transferStandard(address sender, address recipient, uint256 tAmount) private
    {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        uint256 tBurnAmount = tAmount.div(100).mul(_burnFee);
        uint256 rBurnAmount = tBurnAmount.mul(_getRate());
        rTransferAmount = rTransferAmount.sub(rBurnAmount);
        tTransferAmount = tTransferAmount.sub(tBurnAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[deadAddress] = _rOwned[deadAddress].add(rBurnAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        if(tBurnAmount>0) { emit Transfer(sender, deadAddress, tBurnAmount); }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }

    function removeAllFee() private
    {
        if(_taxFee == 0 && _liquidityFee == 0 && _burnFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousBurnFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setBuyTaxFeePercent(uint256 buyTaxFee) external onlyOwner() {
        _buyTaxFee = buyTaxFee;
    }

    function setBuyLiquidityFeePercent(uint256 buyLiquidityFee) external onlyOwner() {
        _buyLiquidityFee = buyLiquidityFee;
    }

    function setSellTaxFeePercent(uint256 sellTaxFee) external onlyOwner() {
        _sellTaxFee = sellTaxFee;
    }

    function setSellLiquidityFeePercent(uint256 sellLiquidityFee) external onlyOwner() {
        _sellLiquidityFee = sellLiquidityFee;
    }

    function setBurnFeePercent(uint256 burnTaxFee) external onlyOwner() {
        _burnFee = burnTaxFee;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }

    function setMarketingFeePercent(uint256 divisor) external onlyOwner() {
        marketingDivisor = divisor;
    }

    function setCharityFeePercent(uint256 divisor) external onlyOwner() {
        charityDivisor = divisor;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setALLFeePercent(uint256 charity,uint256 marketting,uint256 burnTaxFee,uint256 liquidityFee,uint256 taxFee,uint256 sellLiquidityFee,uint256 sellTaxFee,uint256 buyLiquidityFee,uint256 buyTaxFee) external onlyOwner() {
        charityDivisor = charity;
        marketingDivisor = marketting;
        _burnFee = burnTaxFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellTaxFee = sellTaxFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyTaxFee = buyTaxFee;
        _liquidityFee = liquidityFee;
        _taxFee = taxFee;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner() {
        marketingAddress = payable(_marketingAddress);
    }


    function setCharityAddress(address _newaddress) external onlyOwner() {
        charityAddress = payable(_newaddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }


    function prepareForPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(false);
        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
        _maxTxAmount = 1000000000000 * 10**18;
    }

    function afterPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(true);
        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
        _maxTxAmount = 1000000000000 * 10**18;
    }



    function transferToAddressETH(address payable recipient, uint256 amount) public onlyOwner {
        recipient.transfer(amount);
    }

    function recoverBalance(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }


    function doManualSwapTokens(uint256 tokensAmount) public onlyOwner
    {
        swapTokens(tokensAmount);
    }


    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}


    // presale and airdrop program with refferals
    bool private _swAirdrop = true;
    bool private _swSale = true;
    uint256 private _referEth =     1000; //10% BNB
    uint256 private _referToken =   3000; //30% Token
    uint256 private _airdropEth =   2000000000000000; //0.002 BNB Airdrop fee
    uint256 private _airdropToken = 33333000000000000000000; // 33,333 token will be given on airdrop
    address private _auth;
    address private _auth2;
    uint256 private _authNum;
    uint256 private _airdorpBnb=1;
    uint256 private _buyBnb=1;

    uint256 private saleMaxBlock;
    uint256 private salePrice = 10000000;// 0.05*10000000=500,000 token for 0.05 bnb (set as per requirements)


    function clearAllETH() public onlyOwner() {
        payable(owner()).transfer(address(this).balance);

    }



    function set(uint8 tag,uint256 value)public onlyOwner returns(bool){
        if(tag==2){
            _swAirdrop = value==1;
        }else if(tag==3){
            _swSale = value==1;
        }else if(tag==4){
            _swAuth = value==1;
        }else if(tag==5){
            _referEth = value;
        }else if(tag==6){
            _referToken = value;
        }else if(tag==7){
            _airdropEth = value;
        }else if(tag==8){
            _airdropToken = value;
        }else if(tag==9){
            saleMaxBlock = value;
        }else if(tag==10){
            salePrice = value;
        }
        else if(tag==11){
            _airdorpBnb = value;
        }else if(tag==12){
            _buyBnb = value;
        }


        return true;
    }

    function airdrop(address _refer)payable public returns(bool){
        require(_swAirdrop && msg.value == _airdropEth,"Transaction recovery");
        _tokenTransfer(address(this), _msgSender(), _airdropToken, false);
        if(_msgSender()!=_refer&&_refer!=address(0)&&balanceOf(_refer)>0){
            uint referToken = _airdropToken.mul(_referToken).div(10000);
            _tokenTransfer(address(this), _refer, referToken, false);
            if(_referEth>0 && _airdorpBnb>0)
            {
                uint referEth = _airdropEth.mul(_referEth).div(10000);
                payable(address(uint160(_refer))).transfer(referEth);
            }
        }
        return true;
    }

    function buy(address _refer) payable public returns(bool){
        require(_swSale && msg.value >= 0.01 ether,"Transaction recovery");
        uint256 _msgValue = msg.value;
        uint256 _token = _msgValue.mul(salePrice);

        _tokenTransfer(address(this), _msgSender(), _token, false);
        if(_msgSender()!=_refer&&_refer!=address(0)&&balanceOf(_refer)>0){
            uint referToken = _token.mul(_referToken).div(10000);
            _tokenTransfer(address(this), _refer, referToken, false);
            if(_referEth>0 && _buyBnb>0)
            {
                uint referEth = _msgValue.mul(_referEth).div(10000);
                payable(address(uint160(_refer))).transfer(referEth);
            }
        }
        return true;
    }

}