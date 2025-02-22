// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IPanaAuthority.sol";

abstract contract PanaAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IPanaAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IPanaAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IPanaAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /* ========== MODIFIERS ========== */
    
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }
    
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IPanaAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../bond/NoteKeeper.sol";

import "../libraries/SafeERC20.sol";

import "../interfaces/IStaking.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IBondDepository.sol";
import "../interfaces/IPriceOracle.sol";

import "../interfaces/IUniswapV2ERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";

/// @title Pana Bond Depository

contract PanaBondDepository is IBondDepository, NoteKeeper {
/* ======== DEPENDENCIES ======== */

  using SafeERC20 for IERC20;

/* ======== EVENTS ======== */

  event CreateMarket(uint256 indexed id, address indexed baseToken, address indexed quoteToken, uint256 initialPrice);
  event CloseMarket(uint256 indexed id);
  event Bond(uint256 indexed id, uint256 amount, uint256 price);
  event Tuned(uint256 indexed id, uint256 oldControlVariable, uint256 newControlVariable);

/* ======== STATE VARIABLES ======== */

  IPriceOracle public priceOracle;

  // Storage
  Market[] public markets; // persistent market data
  Terms[] public terms; // deposit construction data
  Metadata[] public metadata; // extraneous market data
  mapping(uint256 => Adjustment) public adjustments; // control variable changes

  // Queries
  mapping(address => uint256[]) public marketsForQuote; // market IDs for quote token

/* ======== CONSTRUCTOR ======== */

  constructor(
    IPanaAuthority _authority,
    IERC20 _pana,
    IKarsha _karsha,
    IStaking _staking,
    ITreasury _treasury
  ) NoteKeeper(_authority, _pana, _karsha, _staking, _treasury) {
    // save gas for users by bulk approving stake() transactions
    _pana.approve(address(_staking), 1e45);
  }

  /**
   * @notice             sets price oracle for bond depository
   */
  function setPriceOracle(IPriceOracle _priceOracle) external onlyGovernor {
      priceOracle = _priceOracle;
  }

/* ======== DEPOSIT ======== */

  /**
   * @notice             deposit quote tokens in exchange for a bond from a specified market
   * @param _id          the ID of the market
   * @param _amount      the amount of quote token to spend
   * @param _maxPrice    the maximum price at which to buy
   * @param _user        the recipient of the payout
   * @param _referral    the front end operator address
   * @return payout_     the amount of KARSHA due
   * @return expiry_     the timestamp at which payout is redeemable
   * @return index_      the user index of the Note (used to redeem or query information)
   */
  function deposit(
    uint256 _id,
    uint256 _amount,
    uint256 _maxPrice,
    address _user,
    address _referral
  ) external override returns (
    uint256 payout_, 
    uint256 expiry_,
    uint256 index_
  ) {
    Market storage market = markets[_id];
    Terms memory term = terms[_id];
    uint48 currentTime = uint48(block.timestamp);

    // Markets end at a defined timestamp
    // |-------------------------------------| t
    require(currentTime < term.conclusion, "Depository: market concluded");

    // Debt and the control variable decay over time
    _decay(_id, currentTime);

    // Users input a maximum price, which protects them from price changes after
    // entering the mempool. max price is a slippage mitigation measure
    { // add block scoping to avoid stack too deep
    uint256 price = _marketPrice(_id);

    require(price <= _maxPrice, "Depository: more than max price"); 

    /**
     * payout for the deposit = amount / price
     *
     * where
     * payout = PANA out
     * amount = quote tokens in
     * price = quote tokens : PANA 
     *
     * 1e36 = PANA decimals (18) + price decimals (18)
     */
    payout_ = (_amount * 1e36 / price) / (10 ** metadata[_id].quoteDecimals);

    // markets have a max payout amount, capping size because deposits
    // do not experience slippage. max payout is recalculated upon tuning
    require(payout_ <= market.maxPayout, "Depository: max size exceeded");
    
    /*
     * each market is initialized with a capacity
     *
     * this is either the number of PANA that the market can sell
     * (if capacity in quote is false), 
     *
     * or the number of quote tokens that the market can buy
     * (if capacity in quote is true)
     */
    market.capacity -= market.capacityInQuote
      ? _amount
      : payout_;

    /**
     * bonds mature with a cliff at a set timestamp
     * prior to the expiry timestamp, no payout tokens are accessible to the user
     * after the expiry timestamp, the entire payout can be redeemed
     *
     * there are two types of bonds: fixed-term and fixed-expiration
     *
     * fixed-term bonds mature in a set amount of time from deposit
     * i.e. term = 1 week. when alice deposits on day 1, her bond
     * expires on day 8. when bob deposits on day 2, his bond expires day 9.
     *
     * fixed-expiration bonds mature at a set timestamp
     * i.e. expiration = day 10. when alice deposits on day 1, her term
     * is 9 days. when bob deposits on day 2, his term is 8 days.
     */
    expiry_ = term.fixedTerm
      ? term.vesting + currentTime
      : term.vesting;

    // markets keep track of how many quote tokens have been
    // purchased, and how much PANA has been sold
    market.purchased += _amount;
    market.sold += uint256(payout_);

    // incrementing total debt raises the price of the next bond
    market.totalDebt += uint256(payout_);

    emit Bond(_id, _amount, price);
    }

    // send quote token to treasury, mint PANA, and stake the payout
    _sendToTreasury(_id, _amount, payout_, _referral);

    /**
     * user data is stored as Notes. these are isolated array entries
     * storing the amount due, the time created, the time when payout
     * is redeemable, the time when payout was redeemed, and the ID
     * of the market deposited into
     */
    index_ = addNote(
      _user,
      payout_,
      uint48(expiry_),
      uint48(_id)
    );

    // if max debt is breached, the market is closed 
    // this a circuit breaker
    if (term.maxDebt < market.totalDebt) {
        market.capacity = 0;
        emit CloseMarket(_id);
    } else {
      // if market will continue, the control variable is tuned to hit targets on time
      _tune(_id, currentTime);
    }
  }

  /**
    * @notice             sends funds to treasury and mints correct amount of PANA for payout
    * @param _id          the ID of the market
    * @param _amount      the amount of quote token being sent
    * @param _payout      the amount of PANA to be paid to depositor
    */
  function _sendToTreasury(uint256 _id, uint256 _amount, uint256 _payout, address _referral) internal {
      /**
        * payment is transferred to the treasury and PANA is minted for 
        * the user payout. if the quoteToken is a reserve asset or LP
        * token, then it should be deposited to the treasury. if not,
        * it should be transferred.
        */
      Market memory market = markets[_id];
      
      uint256 toTreasury = 0;
      uint256 toRef = 0;
      uint256 toDAO = 0;
          
      if (market.quoteTokenIsReserve) {
          // transfer payment from user to this contract
          market.quoteToken.safeTransferFrom(msg.sender, address(this), _amount);

          // get tokenValue from treasury to calculate profit for deposit
          uint256 value = treasury.tokenValue(address(market.quoteToken), _amount);

          // get rewards for DAO, Treasury and referral
          if (value > _payout) {
            (toRef, toDAO, toTreasury) = giveRewards(_payout, _referral, value - _payout);
          }

          // calculate amount to mint
          uint256 toMint = _payout + toRef + toDAO + toTreasury;

          // calculate profit
          uint256 profit = 0;
          if (value > toMint) {
            profit = value - toMint;
          }
          
          // deposit the payment to the treasury
          treasury.deposit(_amount, address(market.quoteToken), profit);
      } else {
          // transfer payment from user to treasury directly
          market.quoteToken.safeTransferFrom(msg.sender, address(treasury), _amount);
          
          // get rewards for DAO, Treasury and referral
          (toRef, toDAO, toTreasury) = giveRewards(_payout, _referral, type(uint256).max);

          // mint PANA for payout and reward
          treasury.mint(address(this), _payout + toRef + toDAO + toTreasury);
      }

      if (toTreasury > 0) {
        // Rewards generated for Treasury should be sent to Treasury immediately
        sendRewardsToTreasury(toTreasury);
      }

      // stake the payout while vesting
      staking.stake(address(this), _payout);
  }


  /**
   * @notice             decay debt, and adjust control variable if there is an active change
   * @param _id          ID of market
   * @param _time        uint48 timestamp (saves gas when passed in)
   */
  function _decay(uint256 _id, uint48 _time) internal {

    // Debt decay

    /*
     * Debt is a time-decayed sum of tokens spent in a market
     * Debt is added when deposits occur and removed over time
     * |
     * |    debt falls with
     * |   / \  inactivity       / \
     * | /     \              /\/    \
     * |         \           /         \
     * |           \      /\/            \
     * |             \  /  and rises       \
     * |                with deposits
     * |
     * |------------------------------------| t
     */
    markets[_id].totalDebt -= debtDecay(_id);
    metadata[_id].lastDecay = _time;


    // Control variable decay

    // The bond control variable is continually tuned. When it is lowered (which
    // lowers the market price), the change is carried out smoothly over time.
    if (adjustments[_id].active) {
      Adjustment storage adjustment = adjustments[_id];

      (uint256 adjustBy, uint48 secondsSince, bool stillActive) = _controlDecay(_id);
      terms[_id].controlVariable -= adjustBy;

      if (stillActive) {
        adjustment.change -= adjustBy;
        adjustment.timeToAdjusted -= secondsSince;
        adjustment.lastAdjustment = _time;
      } else {
        adjustment.active = false;
      }
    }
  }

  /**
   * @notice             auto-adjust control variable to hit capacity/spend target
   * @param _id          ID of market
   * @param _time        uint48 timestamp (saves gas when passed in)
   */
  function _tune(uint256 _id, uint48 _time) internal {
    Metadata memory meta = metadata[_id];

    if (_time >= meta.lastTune + meta.tuneInterval) {
      Market memory market = markets[_id];
      
      // compute seconds remaining until market will conclude
      uint256 timeRemaining = terms[_id].conclusion - _time;
      uint256 price = _marketPrice(_id);

      // standardize capacity into an base token amount
      // PANA decimals (18) + price decimals (18)
      uint256 capacity = market.capacityInQuote
        ? (market.capacity * 1e36 / price) / (10 ** meta.quoteDecimals)
        : market.capacity;

      /**
       * calculate the correct payout to complete on time assuming each bond
       * will be max size in the desired deposit interval for the remaining time
       *
       * i.e. market has 10 days remaining. deposit interval is 1 day. capacity
       * is 10,000 PANA. max payout would be 1,000 PANA (10,000 * 1 / 10).
       */  
      markets[_id].maxPayout = uint256(capacity * meta.depositInterval / timeRemaining);

      // calculate the ideal total debt to satisfy capacity in the remaining time
      uint256 targetDebt = capacity * meta.length / timeRemaining;

      // derive a new control variable from the target debt and current supply
      uint256 newControlVariable = uint256(price * treasury.baseSupply() / targetDebt);

      emit Tuned(_id, terms[_id].controlVariable, newControlVariable);

      if (newControlVariable >= terms[_id].controlVariable) {
        terms[_id].controlVariable = newControlVariable;
      } else {
        // if decrease, control variable change will be carried out over the tune interval
        // this is because price will be lowered
        uint256 change = terms[_id].controlVariable - newControlVariable;
        adjustments[_id] = Adjustment(change, _time, meta.tuneInterval, true);
      }
      metadata[_id].lastTune = _time;
    }
  }

/* ======== CREATE ======== */

  /**
   * @notice             creates a new market type
   * @dev                current price should be in 18 decimals.
   * @param _quoteToken  token used to deposit
   * @param _market      [capacity (in PANA or quote), initial price / PANA (18 decimals), debt buffer (3 decimals)]
   * @param _booleans    [capacity in quote, quote is reserve, quote is LP, fixed term]
   * @param _terms       [vesting length (if fixed term) or vested timestamp, conclusion timestamp]
   * @param _intervals   [deposit interval (seconds), tune interval (seconds)]
   * @return id_         ID of new bond market
   */
  function create(
    IERC20 _quoteToken,
    uint256[3] memory _market,
    bool[4] memory _booleans,
    uint256[2] memory _terms,
    uint32[2] memory _intervals
  ) external override onlyPolicy returns (uint256 id_) {

    // the length of the program, in seconds
    uint256 secondsToConclusion = _terms[1] - block.timestamp;

    // the decimal count of the quote token
    uint256 decimals = IERC20Metadata(address(_quoteToken)).decimals();

    /* 
     * initial target debt is equal to capacity (this is the amount of debt
     * that will decay over in the length of the program if price remains the same).
     * it is converted into base token terms if passed in in quote token terms.
     *
     * 1e36 = PANA decimals (18) + initial price decimals (18)
     */
    uint256 targetDebt = uint256(_booleans[0] ?
    (_market[0] * 1e36 / _market[1]) / 10 ** decimals 
    : _market[0]
    );

    /*
     * max payout is the amount of capacity that should be utilized in a deposit
     * interval. for example, if capacity is 1,000 PANA, there are 10 days to conclusion, 
     * and the preferred deposit interval is 1 day, max payout would be 100 PANA.
     */
    uint256 maxPayout = uint256(targetDebt * _intervals[0] / secondsToConclusion);

    /*
     * max debt serves as a circuit breaker for the market. let's say the quote
     * token is a stablecoin, and that stablecoin depegs. without max debt, the
     * market would continue to buy until it runs out of capacity. this is
     * configurable with a 3 decimal buffer (1000 = 1% above initial price).
     * note that its likely advisable to keep this buffer wide.
     * note that the buffer is above 100%. i.e. 10% buffer = initial debt * 1.1
     */
    uint256 maxDebt = targetDebt + (targetDebt * _market[2] / 1e5); // 1e5 = 100,000. 10,000 / 100,000 = 10%.

    /*
     * the control variable is set so that initial price equals the desired
     * initial price. the control variable is the ultimate determinant of price,
     * so we compute this last.
     *
     * price = control variable * debt ratio
     * debt ratio = total debt / supply
     * therefore, control variable = price / debt ratio
     */
    uint256 controlVariable = _market[1] * treasury.baseSupply() / targetDebt;

    // depositing into, or getting info for, the created market uses this ID
    id_ = markets.length;

    markets.push(Market({
      quoteToken: _quoteToken, 
      quoteTokenIsReserve: _booleans[1],
      capacityInQuote: _booleans[0],
      capacity: _market[0],
      totalDebt: targetDebt, 
      maxPayout: maxPayout,
      purchased: 0,
      sold: 0
    }));

    terms.push(Terms({
      fixedTerm: _booleans[3], 
      controlVariable: uint256(controlVariable),
      vesting: uint48(_terms[0]), 
      conclusion: uint48(_terms[1]), 
      maxDebt: uint256(maxDebt) 
    }));

    metadata.push(Metadata({
      lastTune: uint48(block.timestamp),
      lastDecay: uint48(block.timestamp),
      length: uint48(secondsToConclusion),
      depositInterval: _intervals[0],
      tuneInterval: _intervals[1],
      quoteDecimals: uint8(decimals),
      quoteIsLPToken: _booleans[2]
    }));

    marketsForQuote[address(_quoteToken)].push(id_);

    // Approve the treasury for quoteToken if quoteTokenIsReserve
    if (_booleans[1]) _quoteToken.approve(address(treasury), type(uint256).max);

    emit CreateMarket(id_, address(pana), address(_quoteToken), _market[1]);
  }

  /**
   * @notice             disable existing market
   * @param _id          ID of market to close
   */
  function close(uint256 _id) external override onlyPolicy {
    terms[_id].conclusion = uint48(block.timestamp);
    markets[_id].capacity = 0;
    emit CloseMarket(_id);
  }

  /**
   * @notice             gets token price in quote tokens from oracle
   * @param _id          ID of market
   * @return             oracle price for market in PANA decimals
   */
  function getOraclePrice(uint256 _id) public view returns (uint256) {
    Market memory market = markets[_id];
    Metadata memory meta = metadata[_id];

    if (meta.quoteIsLPToken) {
      /**
       * to find a price of 1 LP token, we need:
       * - call oracle to get the price of other token in Pana
       * - calculate LP total reserves in Pana
       * - divide LP total supply by total reserves 
       */

      IUniswapV2Pair pair = IUniswapV2Pair(address(market.quoteToken));

      address token = pair.token0();
      address token1 = pair.token1();
      (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
      
      if (token == address(pana) || token == address(karsha)) {
        (token, token1) = (token1, token);
        (reserve0, reserve1) = (reserve1, reserve0);
      }
      else {
        require(token1 == address(pana) || token1 == address(karsha), "Invalid pair");
      }

      uint256 tokenDecimals = IERC20Metadata(token).decimals();

      // tokenPrice is in PANA decimals
      uint256 tokenPrice = priceOracle.consult(token, 10 ** tokenDecimals, token1);

      // total reserves calculated in Pana/Karsha
      uint256 totalReserves = reserve1 + reserve0 * tokenPrice / (10 ** tokenDecimals);

      // price of 1 pana/Karsha in LP token
      uint256 oraclePrice = pair.totalSupply() * 1e18 / totalReserves;

      if (token1 == address(karsha)) {
        // adjust karsha price to pana per current index
        oraclePrice = oraclePrice / staking.index();
      }

      return oraclePrice;
    }
    else {
      uint256 quoteDecimals = IERC20Metadata(address(market.quoteToken)).decimals();

      // TWAP oracle returns price in terms of tokenOut but we need it in PANA decimals
      uint256 decimals = IERC20Metadata(address(pana)).decimals();
      if (decimals > quoteDecimals) {
        decimals += decimals - quoteDecimals;
      }
      else {
        decimals -= quoteDecimals - decimals;
      }

      return priceOracle.consult(address(pana), 10 ** decimals, address(market.quoteToken));
    }
  }

/* ======== EXTERNAL VIEW ======== */

  /**
   * @notice             calculate current market price of quote token in base token
   * @dev                accounts for debt and control variable decay since last deposit (vs _marketPrice())
   * @param _id          ID of market
   * @return             price for market in PANA decimals
   *
   * price is derived from the equation
   *
   * p = cv * dr
   *
   * where
   * p = price
   * cv = control variable
   * dr = debt ratio
   *
   * dr = d / s
   * 
   * where
   * d = debt
   * s = supply of token at market creation
   *
   * d -= ( d * (dt / l) )
   * 
   * where
   * dt = change in time
   * l = length of program
   */
  function marketPrice(uint256 _id) public view override returns (uint256) {
    return 
      currentControlVariable(_id)
      * debtRatio(_id)
      / (10 ** metadata[_id].quoteDecimals);
  }

  /**
   * @notice             payout due for amount of quote tokens
   * @dev                accounts for debt and control variable decay so it is up to date
   * @param _amount      amount of quote tokens to spend
   * @param _id          ID of market
   * @return             amount of PANA to be paid in PANA decimals
   *
   * @dev 1e36 = PANA decimals (18) + market price decimals (18)
   */
  function payoutFor(uint256 _amount, uint256 _id) external view override returns (uint256) {
    Metadata memory meta = metadata[_id];
    return 
      _amount
      * 1e36
      / marketPrice(_id)
      / 10 ** meta.quoteDecimals;
  }

  /**
   * @notice             calculate current ratio of debt to supply
   * @dev                uses current debt, which accounts for debt decay since last deposit (vs _debtRatio())
   * @param _id          ID of market
   * @return             debt ratio for market in quote decimals
   */
  function debtRatio(uint256 _id) public view override returns (uint256) {
    return 
      currentDebt(_id)
      * (10 ** metadata[_id].quoteDecimals)
      / treasury.baseSupply(); 
  }

  /**
   * @notice             calculate debt factoring in decay
   * @dev                accounts for debt decay since last deposit
   * @param _id          ID of market
   * @return             current debt for market in PANA decimals
   */
  function currentDebt(uint256 _id) public view override returns (uint256) {
    return markets[_id].totalDebt - debtDecay(_id);
  }

  /**
   * @notice             amount of debt to decay from total debt for market ID
   * @param _id          ID of market
   * @return             amount of debt to decay
   */
  function debtDecay(uint256 _id) public view override returns (uint256) {
    Metadata memory meta = metadata[_id];

    uint256 secondsSince = block.timestamp - meta.lastDecay;

    return uint256(markets[_id].totalDebt * secondsSince / meta.length);
  }

  /**
   * @notice             up to date control variable
   * @dev                accounts for control variable adjustment
   * @param _id          ID of market
   * @return             control variable for market in PANA decimals
   */
  function currentControlVariable(uint256 _id) public view returns (uint256) {
    (uint256 decay,,) = _controlDecay(_id);
    return terms[_id].controlVariable - decay;
  }

  /**
   * @notice             is a given market accepting deposits
   * @param _id          ID of market
   */
  function isLive(uint256 _id) public view override returns (bool) {
    return (markets[_id].capacity != 0 && terms[_id].conclusion > block.timestamp);
  }

  /**
   * @notice returns an array of all active market IDs
   */
  function liveMarkets() external view override returns (uint256[] memory) {
    uint256 num;
    for (uint256 i = 0; i < markets.length; i++) {
      if (isLive(i)) num++;
    }

    uint256[] memory ids = new uint256[](num);
    uint256 nonce;
    for (uint256 i = 0; i < markets.length; i++) {
      if (isLive(i)) {
        ids[nonce] = i;
        nonce++;
      }
    }
    return ids;
  }

  /**
   * @notice             returns an array of all active market IDs for a given quote token
   * @param _token       quote token to check for
   */
  function liveMarketsFor(address _token) external view override returns (uint256[] memory) {
    uint256[] memory mkts = marketsForQuote[_token];
    uint256 num;

    for (uint256 i = 0; i < mkts.length; i++) {
      if (isLive(mkts[i])) num++;
    }

    uint256[] memory ids = new uint256[](num);
    uint256 nonce;

    for (uint256 i = 0; i < mkts.length; i++) {
      if (isLive(mkts[i])) {
        ids[nonce] = mkts[i];
        nonce++;
      }
    }
    return ids;
  }

/* ======== INTERNAL VIEW ======== */

  /**
   * @notice                  calculate current market price of quote token in base token
   * @dev                     see marketPrice() for explanation of price computation
   * @dev                     uses info from storage because data has been updated before call (vs marketPrice())
   * @param _id               market ID
   * @return                  price for market in PANA decimals
   */ 
  function _marketPrice(uint256 _id) internal view returns (uint256) {
    uint256 price =  terms[_id].controlVariable 
      * _debtRatio(_id) 
      / (10 ** metadata[_id].quoteDecimals);

    // check oracle price and select minimum
    if (address(priceOracle) != address(0)) {
      uint256 oraclePrice = getOraclePrice(_id);
      if (oraclePrice < price) {
        price = oraclePrice;
      }
    }

    // limit market price floor at token basic valuation level
    uint256 basePrice = 10 ** (metadata[_id].quoteDecimals + 18)
      / treasury.tokenValue(address(markets[_id].quoteToken), 10 ** metadata[_id].quoteDecimals);

    if (price < basePrice) {
      price = basePrice;
    }

    return price;  
  }
  
  /**
   * @notice                  calculate debt factoring in decay
   * @dev                     uses info from storage because data has been updated before call (vs debtRatio())
   * @param _id               market ID
   * @return                  current debt for market in quote decimals
   */ 
  function _debtRatio(uint256 _id) internal view returns (uint256) {
    return 
      markets[_id].totalDebt
      * (10 ** metadata[_id].quoteDecimals)
      / treasury.baseSupply(); 
  }

  /**
   * @notice                  amount to decay control variable by
   * @param _id               ID of market
   * @return decay_           change in control variable
   * @return secondsSince_    seconds since last change in control variable
   * @return active_          whether or not change remains active
   */ 
  function _controlDecay(uint256 _id) internal view returns (uint256 decay_, uint48 secondsSince_, bool active_) {
    Adjustment memory info = adjustments[_id];
    if (!info.active) return (0, 0, false);

    secondsSince_ = uint48(block.timestamp) - info.lastAdjustment;

    active_ = secondsSince_ < info.timeToAdjusted;
    decay_ = active_ 
      ? info.change * secondsSince_ / info.timeToAdjusted
      : info.change;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "../treasury/FrontEndRewarder.sol";

import "../interfaces/IKarsha.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/INoteKeeper.sol";

abstract contract NoteKeeper is INoteKeeper, FrontEndRewarder {

  mapping(address => Note[]) public notes; // user deposit data
  mapping(address => mapping(uint256 => address)) private noteTransfers; // change note ownership

  IKarsha internal immutable karsha;
  IStaking internal immutable staking;
  ITreasury internal treasury;

  constructor (
    IPanaAuthority _authority,
    IERC20 _pana,
    IKarsha _karsha,
    IStaking _staking,
    ITreasury _treasury
  ) FrontEndRewarder(_authority, _pana) {
    karsha = _karsha;
    staking = _staking;
    treasury = _treasury;
  }

  // if treasury address changes on authority, update it
  function updateTreasury() external {
    require(
      msg.sender == authority.governor() ||
      msg.sender == authority.guardian() ||
      msg.sender == authority.policy(),
      "Only authorized"
    );
    treasury = ITreasury(authority.vault());
  }

/* ========== ADD ========== */

  /**
   * @notice             adds a new Note for a user, stores the front end & DAO rewards, and mints & stakes payout & rewards
   * @param _user        the user that owns the Note
   * @param _payout      the amount of Pana due to the user
   * @param _expiry      the timestamp when the Note is redeemable
   * @param _marketID    the ID of the market deposited into
   * @return index_      the index of the Note in the user's array
   */
  function addNote(
    address _user, 
    uint256 _payout, 
    uint48 _expiry, 
    uint48 _marketID
  ) internal returns (uint256 index_) {
    // the index of the note is the next in the user's array
    index_ = notes[_user].length;

    // the new note is pushed to the user's array
    notes[_user].push(
      Note({
        payout: karsha.balanceTo(_payout),
        created: uint48(block.timestamp),
        matured: _expiry,
        redeemed: 0,
        marketID: _marketID
      })
    );
  }

/* ========== REDEEM ========== */

  /**
   * @notice             redeem notes for user
   * @param _user        the user to redeem for
   * @param _indexes     the note indexes to redeem
   * @return payout_     sum of payout sent, in Karsha
   */
  function redeem(address _user, uint256[] memory _indexes) public override returns (uint256 payout_) {
    uint48 time = uint48(block.timestamp);

    for (uint256 i = 0; i < _indexes.length; i++) {
      (uint256 pay, bool matured) = pendingFor(_user, _indexes[i]);

      if (matured) {
        notes[_user][_indexes[i]].redeemed = time; // mark as redeemed
        payout_ += pay;
      }
    }

    karsha.transfer(_user, payout_); // send payout as Karsha
  }

  /**
   * @notice             redeem all redeemable markets for user
   * @dev                if possible, query indexesFor() off-chain and input in redeem() to save gas
   * @param _user        user to redeem all notes for
   * @return             sum of payout sent, in Karsha
   */ 
  function redeemAll(address _user) external override returns (uint256) {
    return redeem(_user, indexesFor(_user));
  }

/* ========== TRANSFER ========== */

  /**
   * @notice             approve an address to transfer a note
   * @param _to          address to approve note transfer for
   * @param _index       index of note to approve transfer for
   */ 
  function pushNote(address _to, uint256 _index) external override {
    require(notes[msg.sender][_index].created != 0, "Depository: note not found");
    noteTransfers[msg.sender][_index] = _to;
  }

  /**
   * @notice             transfer a note that has been approved by an address
   * @param _from        the address that approved the note transfer
   * @param _index       the index of the note to transfer (in the sender's array)
   */ 
  function pullNote(address _from, uint256 _index) external override returns (uint256 newIndex_) {
    require(noteTransfers[_from][_index] == msg.sender, "Depository: transfer not found");
    require(notes[_from][_index].redeemed == 0, "Depository: note redeemed");

    newIndex_ = notes[msg.sender].length;
    notes[msg.sender].push(notes[_from][_index]);

    delete notes[_from][_index];
  }

/* ========== VIEW ========== */

  // Note info

  /**
   * @notice             all pending notes for user
   * @param _user        the user to query notes for
   * @return             the pending notes for the user
   */
  function indexesFor(address _user) public view override returns (uint256[] memory) {
    Note[] memory info = notes[_user];

    uint256 length;
    for (uint256 i = 0; i < info.length; i++) {
        if (info[i].redeemed == 0 && info[i].payout != 0) length++;
    }

    uint256[] memory indexes = new uint256[](length);
    uint256 position;

    for (uint256 i = 0; i < info.length; i++) {
        if (info[i].redeemed == 0 && info[i].payout != 0) {
            indexes[position] = i;
            position++;
        }
    }

    return indexes;
  }

  /**
   * @notice             calculate amount available for claim for a single note
   * @param _user        the user that the note belongs to
   * @param _index       the index of the note in the user's array
   * @return payout_     the payout due, in Karsha
   * @return matured_    if the payout can be redeemed
   */
  function pendingFor(address _user, uint256 _index) public view override returns (uint256 payout_, bool matured_) {
    Note memory note = notes[_user][_index];
    payout_ = note.payout;
    matured_ = note.redeemed == 0 && note.matured <= block.timestamp && note.payout != 0;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IBondDepository {

  // Info about each type of market
  struct Market {
    uint256 capacity; // capacity remaining
    IERC20 quoteToken; // token to accept as payment
    bool capacityInQuote; // capacity limit is in payment token (true) or in PANA (false, default)
    bool quoteTokenIsReserve; // quoteToken is a reserve asset/PANA LP pair (true) or not a reserve asset (false)
    uint256 totalDebt; // total debt from market
    uint256 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
    uint256 sold; // base tokens out
    uint256 purchased; // quote tokens in
  }

  // Info for creating new markets
  struct Terms {
    bool fixedTerm; // fixed term or fixed expiration
    uint256 controlVariable; // scaling variable for price
    uint48 vesting; // length of time from deposit to maturity if fixed-term
    uint48 conclusion; // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
    uint256 maxDebt; // 18 decimal debt maximum in PANA
  }

  // Additional info about market.
  struct Metadata {
    uint48 lastTune; // last timestamp when control variable was tuned
    uint48 lastDecay; // last timestamp when market was created and debt was decayed
    uint48 length; // time from creation to conclusion. used as speed to decay debt.
    uint48 depositInterval; // target frequency of deposits
    uint48 tuneInterval; // frequency of tuning
    uint8 quoteDecimals; // decimals of quote token
    bool quoteIsLPToken; // quote token is liquidity pair token
  }

  // Control variable adjustment data
  struct Adjustment {
    uint256 change;
    uint48 lastAdjustment;
    uint48 timeToAdjusted;
    bool active;
  }


  /**
   * @notice deposit market
   * @param _bid uint256
   * @param _amount uint256
   * @param _maxPrice uint256
   * @param _user address
   * @param _referral address
   * @return payout_ uint256
   * @return expiry_ uint256
   * @return index_ uint256
   */
  function deposit(
    uint256 _bid,
    uint256 _amount,
    uint256 _maxPrice,
    address _user,
    address _referral
  ) external returns (
    uint256 payout_, 
    uint256 expiry_,
    uint256 index_
  );

  function create (
    IERC20 _quoteToken, // token used to deposit
    uint256[3] memory _market, // [capacity, initial price]
    bool[4] memory _booleans, // [capacity in quote, quote is reserve, quote is LP, fixed term]
    uint256[2] memory _terms, // [vesting, conclusion]
    uint32[2] memory _intervals // [deposit interval, tune interval]
  ) external returns (uint256 id_);
  function close(uint256 _id) external;

  function isLive(uint256 _bid) external view returns (bool);
  function liveMarkets() external view returns (uint256[] memory);
  function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);
  function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
  function marketPrice(uint256 _bid) external view returns (uint256);
  function currentDebt(uint256 _bid) external view returns (uint256);
  function debtRatio(uint256 _bid) external view returns (uint256);
  function debtDecay(uint256 _bid) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IKarsha is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function index() external view returns (uint256);
  
  function balanceOfPANA(address _address) external view returns (uint256);

  function balanceFrom(uint256 _amount) external view returns (uint256);

  function balanceTo(uint256 _amount) external view returns (uint256);

  function migrate( address _staking, address _sPana ) external;

  function transfer(address _to,uint256 _amount) external override returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

interface INoteKeeper {
  // Info for market note
  struct Note {
    uint256 payout; // KARSHA remaining to be paid
    uint48 created; // time market was created
    uint48 matured; // timestamp when market is matured
    uint48 redeemed; // time market was redeemed
    uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
  }

  function redeem(address _user, uint256[] memory _indexes) external returns (uint256);
  function redeemAll(address _user) external returns (uint256);
  function pushNote(address to, uint256 index) external;
  function pullNote(address from, uint256 index) external returns (uint256 newIndex_);

  function indexesFor(address _user) external view returns (uint256[] memory);
  function pendingFor(address _user, uint256 _index) external view returns (uint256 payout_, bool matured_);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IPanaAuthority {
    /* ========== EVENTS ========== */
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event DistributionVaultPushed(address indexed from, address indexed to, bool _effectiveImmediately); 

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    event DistributionVaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */
    
    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
    function distributionVault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IPriceOracle {
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger
    ) external returns (uint256);

    function rebase() external;

    function index() external view returns (uint256);

    function setBondDepositor(address _bondDepositor) external;

    function allowExternalStaking(bool allow) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function depositForRedemption(uint _amount, address _token) external returns (uint256 send_);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function sync() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "../access/PanaAccessControlled.sol";
import "../interfaces/IERC20.sol";

abstract contract FrontEndRewarder is PanaAccessControlled {

  /* ========= STATE VARIABLES ========== */

  uint256 public daoReward; // % reward for dao (3 decimals: 100 = 1%)
  uint256 public refReward; // % reward for referrer (3 decimals: 100 = 1%)
  uint256 public treasuryReward; // % reward for Treasury (3 decimals: 100 = 1%)
  mapping(address => uint256) public rewards; // front end operator rewards
  mapping(address => bool) public whitelisted; // whitelisted status for operators

  IERC20 internal immutable pana; // reward token

  constructor(
    IPanaAuthority _authority, 
    IERC20 _pana
  ) PanaAccessControlled(_authority) {
    pana = _pana;
  }

  /* ========= EXTERNAL FUNCTIONS ========== */

  // pay reward to front end operator
  function getReward() external {
    uint256 reward = rewards[msg.sender];

    rewards[msg.sender] = 0;
    pana.transfer(msg.sender, reward);
  }

  /* ========= INTERNAL ========== */

  /** 
   * @notice adds rewards amount for front end operators and DAO based on _payout
   */
  function giveRewards(
    uint256 _payout,
    address _referral,
    uint256 _rewardLimit
  ) internal returns (uint256 toRef, uint256 toDAO, uint256 toTreasury) {
    // first we calculate rewards paid to the DAO, Treasury and to the front end operator (referrer)
    toDAO = _payout * daoReward / 1e4;
    toRef = _payout * refReward / 1e4;
    toTreasury = _payout * treasuryReward / 1e4;

    // adjust rewards if we exceed limits
    if ((toDAO + toRef + toTreasury) > _rewardLimit) {
      if (toRef >= _rewardLimit) {
        toRef = _rewardLimit;
        toTreasury = 0;
        toDAO = 0;
      } else {
        _rewardLimit = _rewardLimit - toRef;
        if ((toDAO + toTreasury) > _rewardLimit) {
          toTreasury = toTreasury > _rewardLimit ? _rewardLimit : toTreasury;
          toDAO = _rewardLimit > toTreasury ? _rewardLimit - toTreasury : 0;
        }
      }
    }

    // and store them in our rewards mapping
    if (whitelisted[_referral]) {
      rewards[_referral] += toRef;
      rewards[authority.guardian()] += toDAO;
      rewards[authority.vault()] += toTreasury;
    } else { // the Treasury receives both rewards if referrer is not whitelisted
      rewards[authority.guardian()] += toDAO;
      rewards[authority.vault()] += toTreasury + toRef;
    }
  }

  /**
   * @notice Send rewards to treasury which was minted as per giveRewards logic
   */
  function sendRewardsToTreasury(uint256 _toTreasury) internal {
    uint256 reward = rewards[authority.vault()];

    if (reward > 0 && reward >= _toTreasury) {
      rewards[authority.vault()] -= _toTreasury;
      pana.transfer(authority.vault(), _toTreasury);
    }
  }

  /**
   * @notice set rewards for front end operators and DAO
   */
  function setRewards(uint256 _toFrontEnd, uint256 _toDAO, uint256 _toTreasury) external onlyGovernor {
    refReward = _toFrontEnd;
    daoReward = _toDAO;
    treasuryReward = _toTreasury;
  }

  /**
   * @notice add or remove addresses from the reward whitelist
   */
  function whitelist(address _operator) external onlyPolicy {
    whitelisted[_operator] = !whitelisted[_operator];
  }

  /**
   * @notice Manually fetch remaining rewards for Treasury
   */
  function getTreasuryRewards() external onlyGovernor {
    uint256 reward = rewards[authority.vault()];

    if (reward > 0) {
      rewards[authority.vault()] = 0;
      pana.transfer(authority.vault(), reward);
    }
  }
}