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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IAutoTrader } from "../interfaces/IAutoTrader.sol";
import { ICallee } from "../interfaces/ICallee.sol";
import { Account } from "../lib/Account.sol";
import { Actions } from "../lib/Actions.sol";
import { Cache } from "../lib/Cache.sol";
import { Decimal } from "../lib/Decimal.sol";
import { EnumerableSet } from "../lib/EnumerableSet.sol";
import { Events } from "../lib/Events.sol";
import { Exchange } from "../lib/Exchange.sol";
import { Interest } from "../lib/Interest.sol";
import { DolomiteMarginMath } from "../lib/DolomiteMarginMath.sol";
import { Monetary } from "../lib/Monetary.sol";
import { Require } from "../lib/Require.sol";
import { Storage } from "../lib/Storage.sol";
import { Types } from "../lib/Types.sol";
import { CallImpl } from "./CallImpl.sol";
import { DepositImpl } from "./DepositImpl.sol";
import { LiquidateOrVaporizeImpl } from "./LiquidateOrVaporizeImpl.sol";
import { TradeImpl } from "./TradeImpl.sol";
import { TransferImpl } from "./TransferImpl.sol";
import { WithdrawalImpl } from "./WithdrawalImpl.sol";


/**
 * @title OperationImpl
 * @author dYdX
 *
 * Logic for processing actions
 */
library OperationImpl {
    using Cache for Cache.MarketCache;
    using EnumerableSet for EnumerableSet.Set;
    using SafeMath for uint256;
    using Storage for Storage.State;
    using Types for Types.Par;
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "OperationImpl";

    // ============ Public Functions ============

    function operate(
        Storage.State storage state,
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    )
        public
    {
        Events.logOperation();

        _verifyInputs(accounts, actions);

        (
            bool[] memory primaryAccounts,
            uint256[] memory numberOfMarketsWithBalancesPerAccount,
            Cache.MarketCache memory cache
        ) = _runPreprocessing(
            state,
            accounts,
            actions
        );

        _runActions(
            state,
            accounts,
            actions,
            cache
        );

        _verifyFinalState(
            state,
            accounts,
            primaryAccounts,
            numberOfMarketsWithBalancesPerAccount,
            cache
        );
    }

    // ============ Helper Functions ============

    function _verifyInputs(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    )
        private
        pure
    {
        Require.that(
            accounts.length != 0,
            FILE,
            "Cannot have zero accounts"
        );
        Require.that(
            actions.length != 0,
            FILE,
            "Cannot have zero actions"
        );

        for (uint256 a = 0; a < accounts.length; a++) {
            for (uint256 b = a + 1; b < accounts.length; b++) {
                Require.that(
                    !Account.equals(accounts[a], accounts[b]),
                    FILE,
                    "Cannot duplicate accounts",
                    accounts[a].owner,
                    accounts[a].number
                );
            }
        }
    }

    function _runPreprocessing(
        Storage.State storage state,
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    )
        private
        returns (
            bool[] memory,
            uint256[] memory,
            Cache.MarketCache memory
        )
    {
        uint256 numMarkets = state.numMarkets;
        bool[] memory primaryAccounts = new bool[](accounts.length);
        uint256[] memory numberOfMarketsWithBalancesPerAccount = new uint256[](accounts.length);
        Cache.MarketCache memory cache = Cache.create(numMarkets);

        // keep track of primary accounts and indexes that need updating
        for (uint256 i = 0; i < actions.length; i++) {
            Actions.ActionArgs memory arg = actions[i];
            Actions.ActionType actionType = arg.actionType;
            Actions.MarketLayout marketLayout = Actions.getMarketLayout(actionType);
            Actions.AccountLayout accountLayout = Actions.getAccountLayout(actionType);

            // parse out primary accounts
            if (accountLayout != Actions.AccountLayout.OnePrimary) {
                Require.that(
                    arg.accountId != arg.otherAccountId,
                    FILE,
                    "Duplicate accounts in action",
                    i
                );
                if (accountLayout == Actions.AccountLayout.TwoPrimary) {
                    primaryAccounts[arg.otherAccountId] = true;
                } else {
                    // accountLayout == Actions.AccountLayout.PrimaryAndSecondary
                    Require.that(
                        !primaryAccounts[arg.otherAccountId],
                        FILE,
                        "Requires non-primary account",
                        arg.otherAccountId
                    );
                }
            }
            primaryAccounts[arg.accountId] = true;

            // keep track of indexes to update
            if (marketLayout == Actions.MarketLayout.OneMarket) {
                _updateMarket(state, cache, arg.primaryMarketId);
            } else if (marketLayout == Actions.MarketLayout.TwoMarkets) {
                Require.that(
                    arg.primaryMarketId != arg.secondaryMarketId,
                    FILE,
                    "Duplicate markets in action",
                    i
                );
                _updateMarket(state, cache, arg.primaryMarketId);
                _updateMarket(state, cache, arg.secondaryMarketId);
            }
        }

        // get any other markets for which an account has a balance
        for (uint256 a = 0; a < accounts.length; a++) {
            uint[] memory marketIdsWithBalance = state.getMarketsWithBalances(accounts[a]);
            numberOfMarketsWithBalancesPerAccount[a] = marketIdsWithBalance.length;
            for (uint256 i = 0; i < marketIdsWithBalance.length; i++) {
                _updateMarket(state, cache, marketIdsWithBalance[i]);
            }
        }

        state.initializeCache(cache);

        for (uint i = 0; i < cache.getNumMarkets(); i++) {
            Events.logOraclePrice(cache.getAtIndex(i));
        }

        return (primaryAccounts, numberOfMarketsWithBalancesPerAccount, cache);
    }

    function _updateMarket(
        Storage.State storage state,
        Cache.MarketCache memory cache,
        uint256 marketId
    )
        private
    {
        if (!cache.hasMarket(marketId)) {
            cache.set(marketId);
            Events.logIndexUpdate(marketId, state.updateIndex(marketId));
        }
    }

    function _runActions(
        Storage.State storage state,
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions,
        Cache.MarketCache memory cache
    )
        private
    {
        for (uint256 i = 0; i < actions.length; i++) {
            Actions.ActionArgs memory action = actions[i];
            Actions.ActionType actionType = action.actionType;

            if (actionType == Actions.ActionType.Deposit) {
                Actions.DepositArgs memory depositArgs = Actions.parseDepositArgs(accounts, action);
                DepositImpl.deposit(
                    state,
                    depositArgs,
                    cache.get(depositArgs.market).index
                );
            } else if (actionType == Actions.ActionType.Withdraw) {
                Actions.WithdrawArgs memory withdrawArgs = Actions.parseWithdrawArgs(accounts, action);
                WithdrawalImpl.withdraw(
                    state,
                    withdrawArgs,
                    cache.get(withdrawArgs.market).index
                );
            } else if (actionType == Actions.ActionType.Transfer) {
                Actions.TransferArgs memory transferArgs = Actions.parseTransferArgs(accounts, action);
                TransferImpl.transfer(
                    state,
                    transferArgs,
                    cache.get(transferArgs.market).index
                );
            } else if (actionType == Actions.ActionType.Buy) {
                Actions.BuyArgs memory buyArgs = Actions.parseBuyArgs(accounts, action);
                TradeImpl.buy(
                    state,
                    buyArgs,
                    cache.get(buyArgs.takerMarket).index,
                    cache.get(buyArgs.makerMarket).index
                );
            } else if (actionType == Actions.ActionType.Sell) {
                Actions.SellArgs memory sellArgs = Actions.parseSellArgs(accounts, action);
                TradeImpl.sell(
                    state,
                    sellArgs,
                    cache.get(sellArgs.takerMarket).index,
                    cache.get(sellArgs.makerMarket).index
                );
            } else if (actionType == Actions.ActionType.Trade) {
                Actions.TradeArgs memory tradeArgs = Actions.parseTradeArgs(accounts, action);
                TradeImpl.trade(
                    state,
                    tradeArgs,
                    cache.get(tradeArgs.inputMarket).index,
                    cache.get(tradeArgs.outputMarket).index
                );
            } else if (actionType == Actions.ActionType.Liquidate) {
                LiquidateOrVaporizeImpl.liquidate(
                    state,
                    cache,
                    Actions.parseLiquidateArgs(accounts, action)
                );
            } else if (actionType == Actions.ActionType.Vaporize) {
                LiquidateOrVaporizeImpl.vaporize(
                    state,
                    cache,
                    Actions.parseVaporizeArgs(accounts, action)
                );
            } else {
                assert(actionType == Actions.ActionType.Call);
                // solium-disable-next-line
                CallImpl.call(
                    state,
                    Actions.parseCallArgs(accounts, action)
                );
            }
        }
    }

    function _verifyFinalState(
        Storage.State storage state,
        Account.Info[] memory accounts,
        bool[] memory primaryAccounts,
        uint256[] memory numberOfMarketsWithBalancesPerAccount,
        Cache.MarketCache memory cache
    )
        private
    {
        // verify no increase in borrowPar for closing markets
        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 i = 0; i < numMarkets; i++) {
            uint256 marketId = cache.getAtIndex(i).marketId;
            Types.TotalPar memory totalPar = state.getTotalPar(marketId);
            if (cache.getAtIndex(i).isClosing) {
                Require.that(
                    totalPar.borrow <= cache.getAtIndex(i).borrowPar,
                    FILE,
                    "Market is closing",
                    marketId
                );
            }

            Types.Wei memory maxWei = state.getMaxWei(marketId);
            if (maxWei.value != 0) {
                // require total supply is less than the max OR it scaled down
                Interest.Index memory index = cache.getAtIndex(i).index;
                (Types.Wei memory totalSupplyWei,) = Interest.totalParToWei(totalPar, index);
                Types.Wei memory cachedSupplyWei = Interest.parToWei(
                    Types.Par(true, cache.getAtIndex(i).supplyPar),
                    index
                );
                Require.that(
                    totalSupplyWei.value <= maxWei.value || totalSupplyWei.value <= cachedSupplyWei.value,
                    FILE,
                    "Total supply exceeds max supply",
                    marketId
                );
            }

            if (state.markets[marketId].isRecyclable) {
                // This market is recyclable. Check that only the `token` is the owner
                for (uint256 a = 0; a < accounts.length; a++) {
                    if (accounts[a].owner != cache.getAtIndex(i).token) {
                        // If the owner of the recyclable token isn't the TokenProxy,
                        // THEN check that the account doesn't have a balance for this recyclable `marketId`
                        Require.that(
                            !state.getMarketsWithBalancesSet(accounts[a]).contains(marketId),
                            FILE,
                            "Invalid recyclable owner",
                            accounts[a].owner,
                            accounts[a].number,
                            marketId
                        );
                    }
                }
            }
        }

        // verify account collateralization
        for (uint256 a = 0; a < accounts.length; a++) {
            Account.Info memory account = accounts[a];

            _verifyNumberOfMarketsWithBalances(state, account, numberOfMarketsWithBalancesPerAccount[a]);

            // don't check collateralization for non-primary accounts
            if (!primaryAccounts[a]) {
                continue;
            }

            // validate minBorrowedValue
            bool collateralized = state.isCollateralized(account, cache, /* requireMinBorrow = */ true);

            // check collateralization for primary accounts
            Require.that(
                collateralized,
                FILE,
                "Undercollateralized account",
                account.owner,
                account.number
            );

            // ensure status is normal for primary accounts
            if (state.getStatus(account) != Account.Status.Normal) {
                state.setStatus(account, Account.Status.Normal);
            }
        }
    }

    function _verifyNumberOfMarketsWithBalances(
        Storage.State storage state,
        Account.Info memory account,
        uint256 cachedNumberOfMarketsWithBalances
    )
        private view
    {
        // The account should either have less markets with balances than at the start of the transaction OR
        // less markets with balances than the max number of markets with balances per account
        uint256 actualNumberOfMarketsWithBalances = state.getNumberOfMarketsWithBalances(account);
        Require.that(
            actualNumberOfMarketsWithBalances <= cachedNumberOfMarketsWithBalances ||
            actualNumberOfMarketsWithBalances <= state.riskParams.accountMaxNumberOfMarketsWithBalances,
            FILE,
            "Too many non-zero balances",
            account.owner,
            account.number
        );
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Bits } from "./Bits.sol";
import { Interest } from "./Interest.sol";
import { Monetary } from "./Monetary.sol";
import { Require } from "./Require.sol";


/**
 * @title Cache
 * @author dYdX
 *
 * Library for caching information about markets
 */
library Cache {

    // ============ Constants ============

    bytes32 internal constant FILE = "Cache";

    // ============ Structs ============

    struct MarketInfo {
        uint marketId;
        address token;
        bool isClosing;
        uint128 borrowPar;
        uint128 supplyPar;
        Interest.Index index;
        Monetary.Price price;
    }

    struct MarketCache {
        MarketInfo[] markets;
        uint256[] marketBitmaps;
        uint256 marketsLength;
    }

    // ============ Setter Functions ============

    /**
     * Initialize an empty cache for some given number of total markets.
     */
    function create(
        uint256 numMarkets
    )
        internal
        pure
        returns (MarketCache memory)
    {
        return MarketCache({
            markets: new MarketInfo[](0),
            marketBitmaps: Bits.createBitmaps(numMarkets),
            marketsLength: 0
        });
    }

    // ============ Getter Functions ============

    function getNumMarkets(
        MarketCache memory cache
    )
        internal
        pure
        returns (uint256)
    {
        return cache.markets.length;
    }

    function hasMarket(
        MarketCache memory cache,
        uint256 marketId
    )
        internal
        pure
        returns (bool)
    {
        return Bits.hasBit(cache.marketBitmaps, marketId);
    }

    function get(
        MarketCache memory cache,
        uint256 marketId
    )
        internal
        pure
        returns (MarketInfo memory)
    {
        Require.that(
            cache.markets.length > 0,
            FILE,
            "not initialized"
        );
        return _getInternal(
            cache.markets,
            0,
            cache.marketsLength,
            marketId
        );
    }

    function set(
        MarketCache memory cache,
        uint256 marketId
    )
        internal
        pure
    {
        // Devs should not be able to call this function once the `markets` array has been initialized (non-zero length)
        Require.that(
            cache.markets.length == 0,
            FILE,
            "already initialized"
        );

        Bits.setBit(cache.marketBitmaps, marketId);

        cache.marketsLength += 1;
    }

    function getAtIndex(
        MarketCache memory cache,
        uint256 index
    )
        internal
        pure
        returns (MarketInfo memory)
    {
        Require.that(
            index < cache.markets.length,
            FILE,
            "invalid index",
            index,
            cache.markets.length
        );
        return cache.markets[index];
    }

    // ============ Private Functions ============

    function _getInternal(
        MarketInfo[] memory data,
        uint beginInclusive,
        uint endExclusive,
        uint marketId
    ) private pure returns (MarketInfo memory) {
        uint len = endExclusive - beginInclusive;
        // If length equals 0 OR length equals 1 but the item wasn't found, revert
        assert(!(len == 0 || (len == 1 && data[beginInclusive].marketId != marketId)));

        uint mid = beginInclusive + len / 2;
        uint midMarketId = data[mid].marketId;
        if (marketId < midMarketId) {
            return _getInternal(
                data,
                beginInclusive,
                mid,
                marketId
            );
        } else if (marketId > midMarketId) {
            return _getInternal(
                data,
                mid + 1,
                endExclusive,
                marketId
            );
        } else {
            return data[mid];
        }
    }

}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";


/**
 * @title Types
 * @author dYdX
 *
 * Library for interacting with the basic structs used in DolomiteMargin
 */
library Types {
    using DolomiteMarginMath for uint256;

    // ============ Permission ============

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    // ============ AssetAmount ============

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    // ============ Par (Principal Amount) ============

    // Total borrow and supply values for a market
    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    // Individual principal amount for an account
    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    function zeroPar()
        internal
        pure
        returns (Par memory)
    {
        return Par({
            sign: false,
            value: 0
        });
    }

    function sub(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (Par memory)
    {
        return add(a, negative(b));
    }

    function add(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (Par memory)
    {
        Par memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value).to128();
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value).to128();
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value).to128();
            }
        }
        return result;
    }

    function equals(
        Par memory a,
        Par memory b
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
        Par memory a
    )
        internal
        pure
        returns (Par memory)
    {
        return Par({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value == 0;
    }

    function isLessThanZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value > 0 && !a.sign;
    }

    function isGreaterThanOrEqualToZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return isZero(a) || a.sign;
    }

    // ============ Wei (Token Amount) ============

    // Individual token amount for an account
    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    function zeroWei()
        internal
        pure
        returns (Wei memory)
    {
        return Wei({
            sign: false,
            value: 0
        });
    }

    function sub(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (Wei memory)
    {
        return add(a, negative(b));
    }

    function add(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (Wei memory)
    {
        Wei memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }
        return result;
    }

    function equals(
        Wei memory a,
        Wei memory b
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
        Wei memory a
    )
        internal
        pure
        returns (Wei memory)
    {
        return Wei({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value == 0;
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";


/**
 * @title Token
 * @author dYdX
 *
 * This library contains basic functions for interacting with ERC20 tokens. Modified to work with
 * tokens that don't adhere strictly to the ERC20 standard (for example tokens that don't return a
 * boolean value on success).
 */
library Token {

    // ============ Library Functions ============

    function transfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        if (amount == 0 || to == address(this)) {
            return;
        }

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20Detailed(token).transfer.selector, to, amount),
            "Token: transfer failed"
        );
    }

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        if (amount == 0 || to == from) {
            return;
        }

        // solium-disable arg-overflow
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20Detailed(token).transferFrom.selector, from, to, amount),
            "Token: transferFrom failed"
        );
        // solium-enable arg-overflow
    }

    // ============ Private Functions ============

    function _callOptionalReturn(address token, bytes memory data, string memory error) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        // 1. The target address is checked to contain contract code. Not needed since tokens are manually added
        // 2. The call itself is made, and success asserted
        // 3. The return value is decoded, which in turn checks the size of the returned data.

        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory returnData) = token.call(data);
        require(success, error);

        if (returnData.length > 0) {
            // Return data is optional
            require(abi.decode(returnData, (bool)), error);
        }
    }

}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";


/**
 * @title Time
 * @author dYdX
 *
 * Library for dealing with time, assuming timestamps fit within 32 bits (valid until year 2106)
 */
library Time {

    // ============ Library Functions ============

    function currentTime()
        internal
        view
        returns (uint32)
    {
        return DolomiteMarginMath.to32(block.timestamp);
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Account } from "./Account.sol";
import { Bits } from "./Bits.sol";
import { Cache } from "./Cache.sol";
import { Decimal } from "./Decimal.sol";
import { Interest } from "./Interest.sol";
import { EnumerableSet } from "./EnumerableSet.sol";
import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";
import { Monetary } from "./Monetary.sol";
import { Require } from "./Require.sol";
import { Time } from "./Time.sol";
import { Token } from "./Token.sol";
import { Types } from "./Types.sol";
import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";
import { IInterestSetter } from "../interfaces/IInterestSetter.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";


/**
 * @title Storage
 * @author dYdX
 *
 * Functions for reading, writing, and verifying state in DolomiteMargin
 */
library Storage {
    using Cache for Cache.MarketCache;
    using Storage for Storage.State;
    using DolomiteMarginMath for uint256;
    using Types for Types.Par;
    using Types for Types.Wei;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Set;

    // ============ Constants ============

    bytes32 internal constant FILE = "Storage";

    // ============ Structs ============

    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Whether this market can be removed and its ID can be recycled and reused
        bool isRecyclable;

        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;

        // Interest index of the market
        Interest.Index index;

        // Contract address of the price oracle for this market
        IPriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal.D256 marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal.D256 spreadPremium;

        // The maximum amount that can be held by the protocol. This allows the protocol to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be below 0.
        Types.Wei maxWei;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal.D256 marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal.D256 liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal.D256 earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Monetary.Value minBorrowedValue;

        // The maximum number of markets a user can have a non-zero balance for a given account.
        uint256 accountMaxNumberOfMarketsWithBalances;
    }

    // The maximum RiskParam values that can be set
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

    // The entire storage state of DolomiteMargin
    struct State {
        // number of markets
        uint256 numMarkets;

        // marketId => Market
        mapping (uint256 => Market) markets;

        // token address => marketId
        mapping (address => uint256) tokenToMarketId;

        // Linked list from marketId to the next recycled market id
        mapping(uint256 => uint256) recycledMarketIds;

        // owner => account number => Account
        mapping (address => mapping (uint256 => Account.Storage)) accounts;

        // Addresses that can control other users accounts
        mapping (address => mapping (address => bool)) operators;

        // Addresses that can control all users accounts
        mapping (address => bool) globalOperators;

        // Addresses of auto traders that can only be called by global operators. IE for expirations
        mapping (address => bool) specialAutoTraders;

        // mutable risk parameters of the system
        RiskParams riskParams;

        // immutable risk limits of the system
        RiskLimits riskLimits;
    }

    // ============ Functions ============

    function getToken(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (address)
    {
        return state.markets[marketId].token;
    }

    function getTotalPar(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Types.TotalPar memory)
    {
        return state.markets[marketId].totalPar;
    }

    function getMaxWei(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Types.Wei memory)
    {
        return state.markets[marketId].maxWei;
    }

    function getIndex(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Interest.Index memory)
    {
        return state.markets[marketId].index;
    }

    function getNumExcessTokens(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Types.Wei memory)
    {
        Interest.Index memory index = state.getIndex(marketId);
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);

        address token = state.getToken(marketId);

        Types.Wei memory balanceWei = Types.Wei({
            sign: true,
            value: IERC20Detailed(token).balanceOf(address(this))
        });

        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = Interest.totalParToWei(totalPar, index);

        // borrowWei is negative, so subtracting it makes the value more positive
        return balanceWei.sub(borrowWei).sub(supplyWei);
    }

    function getStatus(
        Storage.State storage state,
        Account.Info memory account
    )
        internal
        view
        returns (Account.Status)
    {
        return state.accounts[account.owner][account.number].status;
    }

    function getPar(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId
    )
        internal
        view
        returns (Types.Par memory)
    {
        return state.accounts[account.owner][account.number].balances[marketId];
    }

    function getWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Interest.Index memory index
    )
        internal
        view
        returns (Types.Wei memory)
    {
        Types.Par memory par = state.getPar(account, marketId);

        if (par.isZero()) {
            return Types.zeroWei();
        }

        return Interest.parToWei(par, index);
    }

    function getMarketsWithBalancesSet(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (EnumerableSet.Set storage)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet;
    }

    function getMarketsWithBalances(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (uint256[] memory)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.values();
    }

    function getAccountMarketWithBalanceAtIndex(
        Storage.State storage state,
        Account.Info memory account,
        uint256 index
    )
    internal
    view
    returns (uint256)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.getAtIndex(index);
    }

    function getNumberOfMarketsWithBalances(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (uint256)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.length();
    }

    function getAccountNumberOfMarketsWithDebt(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (uint256)
    {
        return state.accounts[account.owner][account.number].numberOfMarketsWithDebt;
    }

    function getLiquidationSpreadForPair(
        Storage.State storage state,
        uint256 heldMarketId,
        uint256 owedMarketId
    )
        internal
        view
        returns (Decimal.D256 memory)
    {
        uint256 result = state.riskParams.liquidationSpread.value;
        result = Decimal.mul(result, Decimal.onePlus(state.markets[heldMarketId].spreadPremium));
        result = Decimal.mul(result, Decimal.onePlus(state.markets[owedMarketId].spreadPremium));
        return Decimal.D256({
            value: result
        });
    }

    function fetchNewIndex(
        Storage.State storage state,
        uint256 marketId,
        Interest.Index memory index
    )
        internal
        view
        returns (Interest.Index memory)
    {
        Interest.Rate memory rate = state.fetchInterestRate(marketId, index);

        return Interest.calculateNewIndex(
            index,
            rate,
            state.getTotalPar(marketId),
            state.riskParams.earningsRate
        );
    }

    function fetchInterestRate(
        Storage.State storage state,
        uint256 marketId,
        Interest.Index memory index
    )
        internal
        view
        returns (Interest.Rate memory)
    {
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);
        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = Interest.totalParToWei(totalPar, index);

        Interest.Rate memory rate = state.markets[marketId].interestSetter.getInterestRate(
            state.getToken(marketId),
            borrowWei.value,
            supplyWei.value
        );

        return rate;
    }

    function fetchPrice(
        Storage.State storage state,
        uint256 marketId,
        address token
    )
        internal
        view
        returns (Monetary.Price memory)
    {
        IPriceOracle oracle = IPriceOracle(state.markets[marketId].priceOracle);
        Monetary.Price memory price = oracle.getPrice(token);
        Require.that(
            price.value != 0,
            FILE,
            "Price cannot be zero",
            marketId
        );
        return price;
    }

    function getAccountValues(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache,
        bool adjustForLiquidity
    )
        internal
        view
        returns (Monetary.Value memory, Monetary.Value memory)
    {
        Monetary.Value memory supplyValue;
        Monetary.Value memory borrowValue;

        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 i = 0; i < numMarkets; i++) {
            Types.Wei memory userWei = state.getWei(account, cache.getAtIndex(i).marketId, cache.getAtIndex(i).index);

            if (userWei.isZero()) {
                continue;
            }

            uint256 assetValue = userWei.value.mul(cache.getAtIndex(i).price.value);
            Decimal.D256 memory adjust = Decimal.one();
            if (adjustForLiquidity) {
                adjust = Decimal.onePlus(state.markets[cache.getAtIndex(i).marketId].marginPremium);
            }

            if (userWei.sign) {
                supplyValue.value = supplyValue.value.add(Decimal.div(assetValue, adjust));
            } else {
                borrowValue.value = borrowValue.value.add(Decimal.mul(assetValue, adjust));
            }
        }

        return (supplyValue, borrowValue);
    }

    function isCollateralized(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache,
        bool requireMinBorrow
    )
        internal
        view
        returns (bool)
    {
        if (state.getAccountNumberOfMarketsWithDebt(account) == 0) {
            // The user does not have a balance with a borrow amount, so they must be collateralized
            return true;
        }

        // get account values (adjusted for liquidity)
        (
            Monetary.Value memory supplyValue,
            Monetary.Value memory borrowValue
        ) = state.getAccountValues(account, cache, /* adjustForLiquidity = */ true);

        if (requireMinBorrow) {
            Require.that(
                borrowValue.value >= state.riskParams.minBorrowedValue.value,
                FILE,
                "Borrow value too low",
                account.owner,
                account.number
            );
        }

        uint256 requiredMargin = Decimal.mul(borrowValue.value, state.riskParams.marginRatio);

        return supplyValue.value >= borrowValue.value.add(requiredMargin);
    }

    function isGlobalOperator(
        Storage.State storage state,
        address operator
    )
        internal
        view
        returns (bool)
    {
        return state.globalOperators[operator];
    }

    function isAutoTraderSpecial(
        Storage.State storage state,
        address autoTrader
    )
        internal
        view
        returns (bool)
    {
        return state.specialAutoTraders[autoTrader];
    }

    function isLocalOperator(
        Storage.State storage state,
        address owner,
        address operator
    )
        internal
        view
        returns (bool)
    {
        return state.operators[owner][operator];
    }

    function requireIsGlobalOperator(
        Storage.State storage state,
        address operator
    )
        internal
        view
    {
        bool isValidOperator = state.isGlobalOperator(operator);

        Require.that(
            isValidOperator,
            FILE,
            "Unpermissioned global operator",
            operator
        );
    }

    function requireIsOperator(
        Storage.State storage state,
        Account.Info memory account,
        address operator
    )
        internal
        view
    {
        bool isValidOperator =
            operator == account.owner
            || state.isGlobalOperator(operator)
            || state.isLocalOperator(account.owner, operator);

        Require.that(
            isValidOperator,
            FILE,
            "Unpermissioned operator",
            operator
        );
    }

    /**
     * Determine and set an account's balance based on the intended balance change. Return the
     * equivalent amount in wei
     */
    function getNewParAndDeltaWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Interest.Index memory index,
        Types.AssetAmount memory amount
    )
        internal
        view
        returns (Types.Par memory, Types.Wei memory)
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        if (amount.value == 0 && amount.ref == Types.AssetReference.Delta) {
            return (oldPar, Types.zeroWei());
        }

        Types.Wei memory oldWei = Interest.parToWei(oldPar, index);
        Types.Par memory newPar;
        Types.Wei memory deltaWei;

        if (amount.denomination == Types.AssetDenomination.Wei) {
            deltaWei = Types.Wei({
                sign: amount.sign,
                value: amount.value
            });
            if (amount.ref == Types.AssetReference.Target) {
                deltaWei = deltaWei.sub(oldWei);
            }
            newPar = Interest.weiToPar(oldWei.add(deltaWei), index);
        } else { // AssetDenomination.Par
            newPar = Types.Par({
                sign: amount.sign,
                value: amount.value.to128()
            });
            if (amount.ref == Types.AssetReference.Delta) {
                newPar = oldPar.add(newPar);
            }
            deltaWei = Interest.parToWei(newPar, index).sub(oldWei);
        }

        return (newPar, deltaWei);
    }

    function getNewParAndDeltaWeiForLiquidation(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Interest.Index memory index,
        Types.AssetAmount memory amount
    )
        internal
        view
        returns (Types.Par memory, Types.Wei memory)
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        Require.that(
            !oldPar.isPositive(),
            FILE,
            "Owed balance cannot be positive",
            account.owner,
            account.number
        );

        (
            Types.Par memory newPar,
            Types.Wei memory deltaWei
        ) = state.getNewParAndDeltaWei(
            account,
            marketId,
            index,
            amount
        );

        // if attempting to over-repay the owed asset, bound it by the maximum
        if (newPar.isPositive()) {
            newPar = Types.zeroPar();
            deltaWei = state.getWei(account, marketId, index).negative();
        }

        Require.that(
            !deltaWei.isNegative() && oldPar.value >= newPar.value,
            FILE,
            "Owed balance cannot increase",
            account.owner,
            account.number
        );

        // if not paying back enough wei to repay any par, then bound wei to zero
        if (oldPar.equals(newPar)) {
            deltaWei = Types.zeroWei();
        }

        return (newPar, deltaWei);
    }

    function isVaporizable(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache
    )
        internal
        view
        returns (bool)
    {
        bool hasNegative = false;
        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 i = 0; i < numMarkets; i++) {
            Types.Par memory par = state.getPar(account, cache.getAtIndex(i).marketId);
            if (par.isZero()) {
                continue;
            } else if (par.sign) {
                return false;
            } else {
                hasNegative = true;
            }
        }
        return hasNegative;
    }

    // =============== Setter Functions ===============

    function updateIndex(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        returns (Interest.Index memory)
    {
        Interest.Index memory index = state.getIndex(marketId);
        if (index.lastUpdate == Time.currentTime()) {
            return index;
        }
        return state.markets[marketId].index = state.fetchNewIndex(marketId, index);
    }

    function setStatus(
        Storage.State storage state,
        Account.Info memory account,
        Account.Status status
    )
        internal
    {
        state.accounts[account.owner][account.number].status = status;
    }

    function setPar(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.Par memory newPar
    )
        internal
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        if (Types.equals(oldPar, newPar)) {
            // GUARD statement
            return;
        }

        // updateTotalPar
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);

        // roll-back oldPar
        if (oldPar.sign) {
            totalPar.supply = uint256(totalPar.supply).sub(oldPar.value).to128();
        } else {
            totalPar.borrow = uint256(totalPar.borrow).sub(oldPar.value).to128();
        }

        // roll-forward newPar
        if (newPar.sign) {
            totalPar.supply = uint256(totalPar.supply).add(newPar.value).to128();
        } else {
            totalPar.borrow = uint256(totalPar.borrow).add(newPar.value).to128();
        }

        if (oldPar.isLessThanZero() && newPar.isGreaterThanOrEqualToZero()) {
            // user went from borrowing to repaying or positive
            state.accounts[account.owner][account.number].numberOfMarketsWithDebt -= 1;
        } else if (oldPar.isGreaterThanOrEqualToZero() && newPar.isLessThanZero()) {
            // user went from zero or positive to borrowing
            state.accounts[account.owner][account.number].numberOfMarketsWithDebt += 1;
        }

        if (newPar.isZero() && (!oldPar.isZero())) {
            // User went from a non-zero balance to zero. Remove the market from the set.
            state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.remove(marketId);
        } else if ((!newPar.isZero()) && oldPar.isZero()) {
            // User went from zero to non-zero. Add the market to the set.
            state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.add(marketId);
        }

        state.markets[marketId].totalPar = totalPar;
        state.accounts[account.owner][account.number].balances[marketId] = newPar;
    }

    /**
     * Determine and set an account's balance based on a change in wei
     */
    function setParFromDeltaWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Interest.Index memory index,
        Types.Wei memory deltaWei
    )
        internal
    {
        if (deltaWei.isZero()) {
            return;
        }
        Types.Wei memory oldWei = state.getWei(account, marketId, index);
        Types.Wei memory newWei = oldWei.add(deltaWei);
        Types.Par memory newPar = Interest.weiToPar(newWei, index);
        state.setPar(
            account,
            marketId,
            newPar
        );
    }

    /**
     * Initializes the cache using the set bits
     */
    function initializeCache(
        Storage.State storage state,
        Cache.MarketCache memory cache
    ) internal view {
        cache.markets = new Cache.MarketInfo[](cache.marketsLength);
        uint counter = 0;

        // Really neat byproduct of iterating through a bitmap using the least significant bit, where each set flag
        // represents the marketId, --> the initialized `cache.markets` array is sorted in O(n)!
        // Meaning, this function call is O(n) where `n` is the number of markets in the cache
        for (uint i = 0; i < cache.marketBitmaps.length; i++) {
            uint bitmap = cache.marketBitmaps[i];
            while (bitmap != 0) {
                uint nextSetBit = Bits.getLeastSignificantBit(bitmap);
                uint marketId = Bits.getMarketIdFromBit(i, nextSetBit);
                address token = state.getToken(marketId);
                Types.TotalPar memory totalPar = state.getTotalPar(marketId);
                cache.markets[counter++] = Cache.MarketInfo({
                    marketId: marketId,
                    token: token,
                    isClosing: state.markets[marketId].isClosing,
                    borrowPar: totalPar.borrow,
                    supplyPar: totalPar.supply,
                    index: state.getIndex(marketId),
                    price: state.fetchPrice(marketId, token)
                });

                // unset the set bit
                bitmap = Bits.unsetBit(bitmap, nextSetBit);
            }
            if (counter == cache.marketsLength) {
                break;
            }
        }

        Require.that(
            cache.marketsLength == counter,
            FILE,
            "cache initialized improperly",
            cache.marketsLength,
            cache.markets.length
        );
    }
}

/*

    Copyright 2022 Dolomite.

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { ILiquidationCallback } from "../interfaces/ILiquidationCallback.sol";
import { Account } from "../lib/Account.sol";
import { ExcessivelySafeCall } from "../lib/ExcessivelySafeCall.sol";
import { DolomiteMarginMath } from "../lib/DolomiteMarginMath.sol";
import { Types } from "../lib/Types.sol";


library SafeLiquidationCallback {
    using Address for address;
    using ExcessivelySafeCall for address;

    // ============ Events ============

    event LogLiquidationCallbackSuccess(address indexed liquidAccountOwner, uint liquidAccountNumber);

    event LogLiquidationCallbackFailure(address indexed liquidAccountOwner, uint liquidAccountNumber, string reason);

    // ============ Functions ============

    function callLiquidateCallbackIfNecessary(
        Account.Info memory liquidAccount,
        uint heldMarket,
        Types.Wei memory heldDeltaWei,
        uint owedMarket,
        Types.Wei memory owedDeltaWei
    ) internal {
        if (liquidAccount.owner.isContract()) {
            uint16 maxCopyBytes = 256;
            (bool isCallSuccessful, bytes memory result) = liquidAccount.owner.excessivelySafeCall(
                /* _gas= */ Math.min(gasleft(), 1000000), // send, at most, 1,000,000 gas to the liquidation callback
                maxCopyBytes, // receive at-most this many bytes worth of return data
                abi.encodeWithSelector(
                    ILiquidationCallback(liquidAccount.owner).onLiquidate.selector,
                    liquidAccount.number,
                    heldMarket,
                    heldDeltaWei,
                    owedMarket,
                    owedDeltaWei
                )
            );

            if (isCallSuccessful) {
                emit LogLiquidationCallbackSuccess(liquidAccount.owner, liquidAccount.number);
            } else {
                // For reversions:
                // - the first 4 bytes is the method ID
                // - the next 32 bytes is the offset (hardcoded 0x20)
                // - the next 32 bytes is the length of the string
                // Here is an example result. The first 68 bytes (136 hexadecimal characters) are the templated
                // 08c379a0                                                         // erroring method ID
                // 0000000000000000000000000000000000000000000000000000000000000020 // offset to where string is
                // 0000000000000000000000000000000000000000000000000000000000000001 // string length
                // 2100000000000000000000000000000000000000000000000000000000000000 // string itself - not templated
                if (result.length < 68) {
                    result = bytes("");
                } else {
                    // parse the result bytes error message into a human-readable string
                    uint length;
                    // solium-disable-next-line security/no-inline-assembly
                    assembly {
                        result := add(result, 0x04)
                        length := mload(add(result, 0x40))
                        if gt(length, sub(maxCopyBytes, 0x44)) {
                            // if the length from `result` is longer than the max length, subtract the 68 bytes
                            // from the maxCopyBytes
                            mstore(add(result, 0x40), sub(maxCopyBytes, 0x44))
                        }
                    }
                    result = bytes(abi.decode(result, (string)));
                }
                emit LogLiquidationCallbackFailure(
                    liquidAccount.owner,
                    liquidAccount.number,
                    string(result)
                );
            }
        }
    }

}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


/**
 * @title Require
 * @author dYdX
 *
 * Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 constant ASCII_ZERO = 48; // '0'
    uint256 constant ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 constant ASCII_LOWER_EX = 120; // 'x'
    bytes2 constant COLON = 0x3a20; // ': '
    bytes2 constant COMMA = 0x2c20; // ', '
    bytes2 constant LPAREN = 0x203c; // ' <'
    byte constant RPAREN = 0x3e; // '>'
    uint256 constant FOUR_BIT_MASK = 0xf;

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
                        COLON,
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
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
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
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
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
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
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
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
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
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
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
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
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
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
        private
        pure
        returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solium-disable-next-line security/no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringify(
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
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // take last decimal digit
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
        private
        pure
        returns (bytes memory)
    {
        uint256 z = uint256(input);

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function stringify(
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
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
        private
        pure
        returns (byte)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


/**
 * @title Monetary
 * @author dYdX
 *
 * Library for types involving money
 */
library Monetary {

    /*
     * The price of a base-unit of an asset. Has `36 - token.decimals` decimals
     */
    struct Price {
        uint256 value;
    }

    /*
     * Total value of an some amount of an asset. Equal to (price * amount). Has 36 decimals.
     */
    struct Value {
        uint256 value;
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Decimal } from "./Decimal.sol";
import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";
import { Time } from "./Time.sol";
import { Types } from "./Types.sol";


/**
 * @title Interest
 * @author dYdX
 *
 * Library for managing the interest rate and interest indexes of DolomiteMargin
 */
library Interest {
    using DolomiteMarginMath for uint256;
    using SafeMath for uint256;

    // ============ Constants ============

    bytes32 constant FILE = "Interest";
    uint64 constant BASE = 10**18;

    // ============ Structs ============

    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

    // ============ Library Functions ============

    /**
     * Get a new market Index based on the old index and market interest rate.
     * Calculate interest for borrowers by using the formula rate * time. Approximates
     * continuously-compounded interest when called frequently, but is much more
     * gas-efficient to calculate. For suppliers, the interest rate is adjusted by the earningsRate,
     * then prorated across all suppliers.
     *
     * @param  index         The old index for a market
     * @param  rate          The current interest rate of the market
     * @param  totalPar      The total supply and borrow par values of the market
     * @param  earningsRate  The portion of the interest that is forwarded to the suppliers
     * @return               The updated index for a market
     */
    function calculateNewIndex(
        Index memory index,
        Rate memory rate,
        Types.TotalPar memory totalPar,
        Decimal.D256 memory earningsRate
    )
        internal
        view
        returns (Index memory)
    {
        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = totalParToWei(totalPar, index);

        // get interest increase for borrowers
        uint32 currentTime = Time.currentTime();
        uint256 borrowInterest = rate.value.mul(uint256(currentTime).sub(index.lastUpdate));

        // get interest increase for suppliers
        uint256 supplyInterest;
        if (Types.isZero(supplyWei)) {
            supplyInterest = 0;
        } else {
            supplyInterest = Decimal.mul(borrowInterest, earningsRate);
            if (borrowWei.value < supplyWei.value) {
                // scale down the interest by the amount being supplied. Why? Because interest is only being paid on
                // the borrowWei, which means it's split amongst all of the supplyWei. Scaling it down normalizes it
                // for the suppliers to share what's being paid by borrowers
                supplyInterest = DolomiteMarginMath.getPartial(supplyInterest, borrowWei.value, supplyWei.value);
            }
        }
        assert(supplyInterest <= borrowInterest);

        return Index({
            borrow: DolomiteMarginMath.getPartial(index.borrow, borrowInterest, BASE).add(index.borrow).to96(),
            supply: DolomiteMarginMath.getPartial(index.supply, supplyInterest, BASE).add(index.supply).to96(),
            lastUpdate: currentTime
        });
    }

    function newIndex()
        internal
        view
        returns (Index memory)
    {
        return Index({
            borrow: BASE,
            supply: BASE,
            lastUpdate: Time.currentTime()
        });
    }

    /*
     * Convert a principal amount to a token amount given an index.
     */
    function parToWei(
        Types.Par memory input,
        Index memory index
    )
        internal
        pure
        returns (Types.Wei memory)
    {
        uint256 inputValue = uint256(input.value);
        if (input.sign) {
            return Types.Wei({
                sign: true,
                value: inputValue.getPartialRoundHalfUp(index.supply, BASE)
            });
        } else {
            return Types.Wei({
                sign: false,
                value: inputValue.getPartialRoundHalfUp(index.borrow, BASE)
            });
        }
    }

    /*
     * Convert a token amount to a principal amount given an index.
     */
    function weiToPar(
        Types.Wei memory input,
        Index memory index
    )
        internal
        pure
        returns (Types.Par memory)
    {
        if (input.sign) {
            return Types.Par({
                sign: true,
                value: input.value.getPartialRoundHalfUp(BASE, index.supply).to128()
            });
        } else {
            return Types.Par({
                sign: false,
                value: input.value.getPartialRoundHalfUp(BASE, index.borrow).to128()
            });
        }
    }

    /*
     * Convert the total supply and borrow principal amounts of a market to total supply and borrow
     * token amounts.
     */
    function totalParToWei(
        Types.TotalPar memory totalPar,
        Index memory index
    )
        internal
        pure
        returns (Types.Wei memory, Types.Wei memory)
    {
        Types.Par memory supplyPar = Types.Par({
            sign: true,
            value: totalPar.supply
        });
        Types.Par memory borrowPar = Types.Par({
            sign: false,
            value: totalPar.borrow
        });
        Types.Wei memory supplyWei = parToWei(supplyPar, index);
        Types.Wei memory borrowWei = parToWei(borrowPar, index);
        return (supplyWei, borrowWei);
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Require } from "./Require.sol";
import { Token } from "./Token.sol";
import { Types } from "./Types.sol";
import { IExchangeWrapper } from "../interfaces/IExchangeWrapper.sol";


/**
 * @title Exchange
 * @author dYdX
 *
 * Library for transferring tokens and interacting with ExchangeWrappers by using the Wei struct
 */
library Exchange {
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "Exchange";

    // ============ Library Functions ============

    function transferOut(
        address token,
        address to,
        Types.Wei memory deltaWei
    )
        internal
    {
        Require.that(
            !deltaWei.isPositive(),
            FILE,
            "Cannot transferOut positive",
            deltaWei.value
        );

        Token.transfer(
            token,
            to,
            deltaWei.value
        );
    }

    function transferIn(
        address token,
        address from,
        Types.Wei memory deltaWei
    )
        internal
    {
        Require.that(
            !deltaWei.isNegative(),
            FILE,
            "Cannot transferIn negative",
            deltaWei.value
        );

        Token.transferFrom(
            token,
            from,
            address(this),
            deltaWei.value
        );
    }

    function getCost(
        address exchangeWrapper,
        address supplyToken,
        address borrowToken,
        Types.Wei memory desiredAmount,
        bytes memory orderData
    )
        internal
        view
        returns (Types.Wei memory)
    {
        Require.that(
            !desiredAmount.isNegative(),
            FILE,
            "Cannot getCost negative",
            desiredAmount.value
        );

        Types.Wei memory result;
        result.sign = false;
        result.value = IExchangeWrapper(exchangeWrapper).getExchangeCost(
            supplyToken,
            borrowToken,
            desiredAmount.value,
            orderData
        );

        return result;
    }

    function exchange(
        address exchangeWrapper,
        address accountOwner,
        address supplyToken,
        address borrowToken,
        Types.Wei memory requestedFillAmount,
        bytes memory orderData
    )
        internal
        returns (Types.Wei memory)
    {
        Require.that(
            !requestedFillAmount.isPositive(),
            FILE,
            "Cannot exchange positive",
            requestedFillAmount.value
        );

        transferOut(borrowToken, exchangeWrapper, requestedFillAmount);

        Types.Wei memory result;
        result.sign = true;
        result.value = IExchangeWrapper(exchangeWrapper).exchange(
            accountOwner,
            address(this),
            supplyToken,
            borrowToken,
            requestedFillAmount.value,
            orderData
        );

        transferIn(supplyToken, exchangeWrapper, result);

        return result;
    }
}

/*

    Copyright 2022 Dolomite.

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

pragma solidity ^0.5.7;


/**
 * @author https://github.com/nomad-xyz
 */
library ExcessivelySafeCall {

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returndata = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid mem-copying a very large returnData
        // returned by a malicious contract
        /* solium-disable security/no-inline-assembly */
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                0, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returndata, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returndata, 0x20), 0, _toCopy)
        }
        /* solium-enable security/no-inline-assembly */
        return (_success, _returndata);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returndata = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid mem-copying a very large returndata
        // returned by a malicious contract
        /* solium-disable security/no-inline-assembly */
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returndata, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returndata, 0x20), 0, _toCopy)
        }
        /* solium-enable security/no-inline-assembly */
        return (_success, _returndata);
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "./Account.sol";
import { Actions } from "./Actions.sol";
import { Cache } from "./Cache.sol";
import { Interest } from "./Interest.sol";
import { Monetary } from "./Monetary.sol";
import { Storage } from "./Storage.sol";
import { Types } from "./Types.sol";


/**
 * @title Events
 * @author dYdX
 *
 * Library to parse and emit logs from which the state of all accounts and indexes can be followed
 */
library Events {
    using Types for Types.Wei;
    using Storage for Storage.State;

    // ============ Events ============

    event LogIndexUpdate(
        uint256 indexed market,
        Interest.Index index
    );

    event LogOraclePrice(
        uint256 indexed market,
        Monetary.Price price
    );

    event LogOperation(
        address sender
    );

    event LogDeposit(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 market,
        BalanceUpdate update,
        address from
    );

    event LogWithdraw(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 market,
        BalanceUpdate update,
        address to
    );

    event LogTransfer(
        address indexed accountOneOwner,
        uint256 accountOneNumber,
        address indexed accountTwoOwner,
        uint256 accountTwoNumber,
        uint256 market,
        BalanceUpdate updateOne,
        BalanceUpdate updateTwo
    );

    event LogBuy(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 takerMarket,
        uint256 makerMarket,
        BalanceUpdate takerUpdate,
        BalanceUpdate makerUpdate,
        address exchangeWrapper
    );

    event LogSell(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 takerMarket,
        uint256 makerMarket,
        BalanceUpdate takerUpdate,
        BalanceUpdate makerUpdate,
        address exchangeWrapper
    );

    event LogTrade(
        address indexed takerAccountOwner,
        uint256 takerAccountNumber,
        address indexed makerAccountOwner,
        uint256 makerAccountNumber,
        uint256 inputMarket,
        uint256 outputMarket,
        BalanceUpdate takerInputUpdate,
        BalanceUpdate takerOutputUpdate,
        BalanceUpdate makerInputUpdate,
        BalanceUpdate makerOutputUpdate,
        address autoTrader
    );

    event LogCall(
        address indexed accountOwner,
        uint256 accountNumber,
        address callee
    );

    event LogLiquidate(
        address indexed solidAccountOwner,
        uint256 solidAccountNumber,
        address indexed liquidAccountOwner,
        uint256 liquidAccountNumber,
        uint256 heldMarket,
        uint256 owedMarket,
        BalanceUpdate solidHeldUpdate,
        BalanceUpdate solidOwedUpdate,
        BalanceUpdate liquidHeldUpdate,
        BalanceUpdate liquidOwedUpdate
    );

    event LogVaporize(
        address indexed solidAccountOwner,
        uint256 solidAccountNumber,
        address indexed vaporAccountOwner,
        uint256 vaporAccountNumber,
        uint256 heldMarket,
        uint256 owedMarket,
        BalanceUpdate solidHeldUpdate,
        BalanceUpdate solidOwedUpdate,
        BalanceUpdate vaporOwedUpdate
    );

    // ============ Structs ============

    struct BalanceUpdate {
        Types.Wei deltaWei;
        Types.Par newPar;
    }

    // ============ Internal Functions ============

    function logIndexUpdate(
        uint256 marketId,
        Interest.Index memory index
    )
        internal
    {
        emit LogIndexUpdate(
            marketId,
            index
        );
    }

    function logOraclePrice(
        Cache.MarketInfo memory marketInfo
    )
        internal
    {
        emit LogOraclePrice(
            marketInfo.marketId,
            marketInfo.price
        );
    }

    function logOperation()
        internal
    {
        emit LogOperation(msg.sender);
    }

    function logDeposit(
        Storage.State storage state,
        Actions.DepositArgs memory args,
        Types.Wei memory deltaWei
    )
        internal
    {
        emit LogDeposit(
            args.account.owner,
            args.account.number,
            args.market,
            getBalanceUpdate(
                state,
                args.account,
                args.market,
                deltaWei
            ),
            args.from
        );
    }

    function logWithdraw(
        Storage.State storage state,
        Actions.WithdrawArgs memory args,
        Types.Wei memory deltaWei
    )
        internal
    {
        emit LogWithdraw(
            args.account.owner,
            args.account.number,
            args.market,
            getBalanceUpdate(
                state,
                args.account,
                args.market,
                deltaWei
            ),
            args.to
        );
    }

    function logTransfer(
        Storage.State storage state,
        Actions.TransferArgs memory args,
        Types.Wei memory deltaWei
    )
        internal
    {
        emit LogTransfer(
            args.accountOne.owner,
            args.accountOne.number,
            args.accountTwo.owner,
            args.accountTwo.number,
            args.market,
            getBalanceUpdate(
                state,
                args.accountOne,
                args.market,
                deltaWei
            ),
            getBalanceUpdate(
                state,
                args.accountTwo,
                args.market,
                deltaWei.negative()
            )
        );
    }

    function logBuy(
        Storage.State storage state,
        Actions.BuyArgs memory args,
        Types.Wei memory takerWei,
        Types.Wei memory makerWei
    )
        internal
    {
        emit LogBuy(
            args.account.owner,
            args.account.number,
            args.takerMarket,
            args.makerMarket,
            getBalanceUpdate(
                state,
                args.account,
                args.takerMarket,
                takerWei
            ),
            getBalanceUpdate(
                state,
                args.account,
                args.makerMarket,
                makerWei
            ),
            args.exchangeWrapper
        );
    }

    function logSell(
        Storage.State storage state,
        Actions.SellArgs memory args,
        Types.Wei memory takerWei,
        Types.Wei memory makerWei
    )
        internal
    {
        emit LogSell(
            args.account.owner,
            args.account.number,
            args.takerMarket,
            args.makerMarket,
            getBalanceUpdate(
                state,
                args.account,
                args.takerMarket,
                takerWei
            ),
            getBalanceUpdate(
                state,
                args.account,
                args.makerMarket,
                makerWei
            ),
            args.exchangeWrapper
        );
    }

    function logTrade(
        Storage.State storage state,
        Actions.TradeArgs memory args,
        Types.Wei memory inputWei,
        Types.Wei memory outputWei
    )
        internal
    {
        BalanceUpdate[4] memory updates = [
            getBalanceUpdate(
                state,
                args.takerAccount,
                args.inputMarket,
                inputWei.negative()
            ),
            getBalanceUpdate(
                state,
                args.takerAccount,
                args.outputMarket,
                outputWei.negative()
            ),
            getBalanceUpdate(
                state,
                args.makerAccount,
                args.inputMarket,
                inputWei
            ),
            getBalanceUpdate(
                state,
                args.makerAccount,
                args.outputMarket,
                outputWei
            )
        ];

        emit LogTrade(
            args.takerAccount.owner,
            args.takerAccount.number,
            args.makerAccount.owner,
            args.makerAccount.number,
            args.inputMarket,
            args.outputMarket,
            updates[0],
            updates[1],
            updates[2],
            updates[3],
            args.autoTrader
        );
    }

    function logCall(
        Actions.CallArgs memory args
    )
        internal
    {
        emit LogCall(
            args.account.owner,
            args.account.number,
            args.callee
        );
    }

    function logLiquidate(
        Storage.State storage state,
        Actions.LiquidateArgs memory args,
        Types.Wei memory heldWei,
        Types.Wei memory owedWei
    )
        internal
    {
        BalanceUpdate memory solidHeldUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.heldMarket,
            heldWei.negative()
        );
        BalanceUpdate memory solidOwedUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.owedMarket,
            owedWei.negative()
        );
        BalanceUpdate memory liquidHeldUpdate = getBalanceUpdate(
            state,
            args.liquidAccount,
            args.heldMarket,
            heldWei
        );
        BalanceUpdate memory liquidOwedUpdate = getBalanceUpdate(
            state,
            args.liquidAccount,
            args.owedMarket,
            owedWei
        );

        emit LogLiquidate(
            args.solidAccount.owner,
            args.solidAccount.number,
            args.liquidAccount.owner,
            args.liquidAccount.number,
            args.heldMarket,
            args.owedMarket,
            solidHeldUpdate,
            solidOwedUpdate,
            liquidHeldUpdate,
            liquidOwedUpdate
        );
    }

    function logVaporize(
        Storage.State storage state,
        Actions.VaporizeArgs memory args,
        Types.Wei memory heldWei,
        Types.Wei memory owedWei,
        Types.Wei memory excessWei
    )
        internal
    {
        BalanceUpdate memory solidHeldUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.heldMarket,
            heldWei.negative()
        );
        BalanceUpdate memory solidOwedUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.owedMarket,
            owedWei.negative()
        );
        BalanceUpdate memory vaporOwedUpdate = getBalanceUpdate(
            state,
            args.vaporAccount,
            args.owedMarket,
            owedWei.add(excessWei)
        );

        emit LogVaporize(
            args.solidAccount.owner,
            args.solidAccount.number,
            args.vaporAccount.owner,
            args.vaporAccount.number,
            args.heldMarket,
            args.owedMarket,
            solidHeldUpdate,
            solidOwedUpdate,
            vaporOwedUpdate
        );
    }

    // ============ Private Functions ============

    function getBalanceUpdate(
        Storage.State storage state,
        Account.Info memory account,
        uint256 market,
        Types.Wei memory deltaWei
    )
        private
        view
        returns (BalanceUpdate memory)
    {
        return BalanceUpdate({
            deltaWei: deltaWei,
            newPar: state.getPar(account, market)
        });
    }
}

/*

    Copyright 2021 Dolomite.

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


library EnumerableSet {

    struct Set {
        // Storage of set values
        uint256[] _values;
        // Value to the index in `_values` array, plus 1 because index 0 means a value is not in the set.
        mapping(uint256 => uint256) _valueToIndexMap;
    }

    /**
    * @dev Add a value to a set. O(1).
     *
     * @return true if the value was added to the set, that is if it was not already present.
     */
    function add(Set storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._valueToIndexMap[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * @return true if the value was removed from the set, that is if it was present.
     */
    function remove(Set storage set, uint256 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._valueToIndexMap[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._valueToIndexMap[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored, which is the last index
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._valueToIndexMap[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._valueToIndexMap[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value at the corresponding index. O(1).
     */
    function getAtIndex(Set storage set, uint256 index) internal view returns (uint256) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (uint256[] memory) {
        return set._values;
    }

}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Require } from "./Require.sol";


/**
 * @title Math
 * @author dYdX
 *
 * Library for non-standard Math functions
 */
library DolomiteMarginMath {
    using SafeMath for uint256;

    // ============ Constants ============

    bytes32 constant FILE = "Math";

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
        return target.mul(numerator).div(denominator);
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
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
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
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        uint result = target.mul(numerator);
        // round the denominator comparator up to ensure a fair comparison is done on the `result`'s modulo.
        // For example, 51 / 103 == 0; 51 % 103 == 51; ((103 - 1) / 2) + 1 == 52; 51 < 52, therefore no round up
        return result.div(denominator).add(result.mod(denominator) >= denominator.sub(1).div(2).add(1) ? 1 : 0);
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
            FILE,
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
            FILE,
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
            FILE,
            "Unsafe cast to uint32",
            number
        );
        return result;
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";


/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Functions ============

    function one()
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function onePlus(
        D256 memory d
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(BASE) });
    }

    function mul(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return DolomiteMarginMath.getPartial(target, d.value, BASE);
    }

    function div(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return DolomiteMarginMath.getPartial(target, BASE, d.value);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Require } from "./Require.sol";


/**
 * @title Bits
 * @author Dolomite
 *
 * Library for caching information about markets
 */
library Bits {

    // ============ Constants ============

    uint internal constant ONE = 1;
    uint256 internal constant MAX_UINT_BITS = 256;

    // ============ Functions ============

    function createBitmaps(uint maxLength) internal pure returns (uint[] memory) {
        return new uint[]((maxLength / MAX_UINT_BITS) + ONE);
    }

    function getMarketIdFromBit(
        uint index,
        uint bit
    ) internal pure returns (uint) {
        return (MAX_UINT_BITS * index) + bit;
    }

    function setBit(
        uint[] memory bitmaps,
        uint marketId
    ) internal pure {
        uint bucketIndex = marketId / MAX_UINT_BITS;
        uint indexFromRight = marketId % MAX_UINT_BITS;
        bitmaps[bucketIndex] |= (ONE << indexFromRight);
    }

    function hasBit(
        uint[] memory bitmaps,
        uint marketId
    ) internal pure returns (bool) {
        uint bucketIndex = marketId / MAX_UINT_BITS;
        uint indexFromRight = marketId % MAX_UINT_BITS;
        uint bit = bitmaps[bucketIndex] & (ONE << indexFromRight);
        return bit > 0;
    }

    function unsetBit(
        uint bitmap,
        uint bit
    ) internal pure returns (uint) {
        return bitmap - (ONE << bit);
    }

    // solium-disable security/no-assign-params
    function getLeastSignificantBit(uint256 x) internal pure returns (uint) {
        // gas usage peaks at 350 per call

        uint lsb = 255;

        if (x & uint128(-1) > 0) {
            lsb -= 128;
        } else {
            x >>= 128;
        }

        if (x & uint64(-1) > 0) {
            lsb -= 64;
        } else {
            x >>= 64;
        }

        if (x & uint32(-1) > 0) {
            lsb -= 32;
        } else {
            x >>= 32;
        }

        if (x & uint16(-1) > 0) {
            lsb -= 16;
        } else {
            x >>= 16;
        }

        if (x & uint8(-1) > 0) {
            lsb -= 8;
        } else {
            x >>= 8;
        }

        if (x & 0xf > 0) {
            lsb -= 4;
        } else {
            x >>= 4;
        }

        if (x & 0x3 > 0) {
            lsb -= 2;
        } else {
            x >>= 2;
            // solium-enable security/no-assign-params
        }

        if (x & 0x1 > 0) {
            lsb -= 1;
        }

        return lsb;
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "./Account.sol";
import { Types } from "./Types.sol";


/**
 * @title Actions
 * @author dYdX
 *
 * Library that defines and parses valid Actions
 */
library Actions {

    // ============ Constants ============

    bytes32 constant FILE = "Actions";

    // ============ Enums ============

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

    enum AccountLayout {
        OnePrimary,
        TwoPrimary,
        PrimaryAndSecondary
    }

    enum MarketLayout {
        ZeroMarkets,
        OneMarket,
        TwoMarkets
    }

    // ============ Structs ============

    /*
     * Arguments that are passed to DolomiteMargin in an ordered list as part of a single operation.
     * Each ActionArgs has an actionType which specifies which action struct that this data will be
     * parsed into before being processed.
     */
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    // ============ Action Types ============

    /*
     * Moves tokens from an address to DolomiteMargin. Can either repay a borrow or provide additional supply.
     */
    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    /*
     * Moves tokens from DolomiteMargin to another address. Can either borrow tokens or reduce the amount
     * previously supplied.
     */
    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    /*
     * Transfers balance between two accounts. The msg.sender must be an operator for both accounts.
     * The amount field applies to accountOne.
     * This action does not require any token movement since the trade is done internally to DolomiteMargin.
     */
    struct TransferArgs {
        Types.AssetAmount amount;
        Account.Info accountOne;
        Account.Info accountTwo;
        uint256 market;
    }

    /*
     * Acquires a certain amount of tokens by spending other tokens. Sends takerMarket tokens to the
     * specified exchangeWrapper contract and expects makerMarket tokens in return. The amount field
     * applies to the makerMarket.
     */
    struct BuyArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 makerMarket;
        uint256 takerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    /*
     * Spends a certain amount of tokens to acquire other tokens. Sends takerMarket tokens to the
     * specified exchangeWrapper and expects makerMarket tokens in return. The amount field applies
     * to the takerMarket.
     */
    struct SellArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 takerMarket;
        uint256 makerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    /*
     * Trades balances between two accounts using any external contract that implements the
     * AutoTrader interface. The AutoTrader contract must be an operator for the makerAccount (for
     * which it is trading on-behalf-of). The amount field applies to the makerAccount and the
     * inputMarket. This proposed change to the makerAccount is passed to the AutoTrader which will
     * quote a change for the makerAccount in the outputMarket (or will disallow the trade).
     * This action does not require any token movement since the trade is done internally to DolomiteMargin.
     */
    struct TradeArgs {
        Types.AssetAmount amount;
        Account.Info takerAccount;
        Account.Info makerAccount;
        uint256 inputMarket;
        uint256 outputMarket;
        address autoTrader;
        bytes tradeData;
    }

    /*
     * Each account must maintain a certain margin-ratio (specified globally). If the account falls
     * below this margin-ratio, it can be liquidated by any other account. This allows anyone else
     * (arbitrageurs) to repay any borrowed asset (owedMarket) of the liquidating account in
     * exchange for any collateral asset (heldMarket) of the liquidAccount. The ratio is determined
     * by the price ratio (given by the oracles) plus a spread (specified globally). Liquidating an
     * account also sets a flag on the account that the account is being liquidated. This allows
     * anyone to continue liquidating the account until there are no more borrows being taken by the
     * liquidating account. Liquidators do not have to liquidate the entire account all at once but
     * can liquidate as much as they choose. The liquidating flag allows liquidators to continue
     * liquidating the account even if it becomes collateralized through partial liquidation or
     * price movement.
     */
    struct LiquidateArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    /*
     * Similar to liquidate, but vaporAccounts are accounts that have only negative balances remaining. The arbitrageur
     * pays back the negative asset (owedMarket) of the vaporAccount in exchange for a collateral asset (heldMarket) at
     * a favorable spread. However, since the liquidAccount has no collateral assets, the collateral must come from
     * DolomiteMargin's excess tokens.
     */
    struct VaporizeArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info vaporAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    /*
     * Passes arbitrary bytes of data to an external contract that implements the Callee interface.
     * Does not change any asset amounts. This function may be useful for setting certain variables
     * on layer-two contracts for certain accounts without having to make a separate Ethereum
     * transaction for doing so. Also, the second-layer contracts can ensure that the call is coming
     * from an operator of the particular account.
     */
    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }

    // ============ Helper Functions ============

    function getMarketLayout(
        ActionType actionType
    )
        internal
        pure
        returns (MarketLayout)
    {
        if (
            actionType == Actions.ActionType.Deposit
            || actionType == Actions.ActionType.Withdraw
            || actionType == Actions.ActionType.Transfer
        ) {
            return MarketLayout.OneMarket;
        }
        else if (actionType == Actions.ActionType.Call) {
            return MarketLayout.ZeroMarkets;
        }
        return MarketLayout.TwoMarkets;
    }

    function getAccountLayout(
        ActionType actionType
    )
        internal
        pure
        returns (AccountLayout)
    {
        if (
            actionType == Actions.ActionType.Transfer
            || actionType == Actions.ActionType.Trade
        ) {
            return AccountLayout.TwoPrimary;
        } else if (
            actionType == Actions.ActionType.Liquidate
            || actionType == Actions.ActionType.Vaporize
        ) {
            return AccountLayout.PrimaryAndSecondary;
        }
        return AccountLayout.OnePrimary;
    }

    // ============ Parsing Functions ============

    function parseDepositArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (DepositArgs memory)
    {
        return DepositArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            market: args.primaryMarketId,
            from: args.otherAddress
        });
    }

    function parseWithdrawArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (WithdrawArgs memory)
    {
        return WithdrawArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            market: args.primaryMarketId,
            to: args.otherAddress
        });
    }

    function parseTransferArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (TransferArgs memory)
    {
        return TransferArgs({
            amount: args.amount,
            accountOne: accounts[args.accountId],
            accountTwo: accounts[args.otherAccountId],
            market: args.primaryMarketId
        });
    }

    function parseBuyArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (BuyArgs memory)
    {
        return BuyArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            makerMarket: args.primaryMarketId,
            takerMarket: args.secondaryMarketId,
            exchangeWrapper: args.otherAddress,
            orderData: args.data
        });
    }

    function parseSellArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (SellArgs memory)
    {
        return SellArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            takerMarket: args.primaryMarketId,
            makerMarket: args.secondaryMarketId,
            exchangeWrapper: args.otherAddress,
            orderData: args.data
        });
    }

    function parseTradeArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (TradeArgs memory)
    {
        return TradeArgs({
            amount: args.amount,
            takerAccount: accounts[args.accountId],
            makerAccount: accounts[args.otherAccountId],
            inputMarket: args.primaryMarketId,
            outputMarket: args.secondaryMarketId,
            autoTrader: args.otherAddress,
            tradeData: args.data
        });
    }

    function parseLiquidateArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (LiquidateArgs memory)
    {
        return LiquidateArgs({
            amount: args.amount,
            solidAccount: accounts[args.accountId],
            liquidAccount: accounts[args.otherAccountId],
            owedMarket: args.primaryMarketId,
            heldMarket: args.secondaryMarketId
        });
    }

    function parseVaporizeArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (VaporizeArgs memory)
    {
        return VaporizeArgs({
            amount: args.amount,
            solidAccount: accounts[args.accountId],
            vaporAccount: accounts[args.otherAccountId],
            owedMarket: args.primaryMarketId,
            heldMarket: args.secondaryMarketId
        });
    }

    function parseCallArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (CallArgs memory)
    {
        return CallArgs({
            account: accounts[args.accountId],
            callee: args.otherAddress,
            data: args.data
        });
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Types } from "./Types.sol";
import { EnumerableSet } from "./EnumerableSet.sol";


/**
 * @title Account
 * @author dYdX
 *
 * Library of structs and functions that represent an account
 */
library Account {
    // ============ Enums ============

    /*
     * Most-recently-cached account status.
     *
     * Normal: Can only be liquidated if the account values are violating the global margin-ratio.
     * Liquid: Can be liquidated no matter the account values.
     *         Can be vaporized if there are no more positive account values.
     * Vapor:  Has only negative (or zeroed) account values. Can be vaporized.
     *
     */
    enum Status {
        Normal,
        Liquid,
        Vapor
    }

    // ============ Structs ============

    // Represents the unique key that specifies an account
    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    // The complete storage for any account
    struct Storage {
        Status status;
        uint32 numberOfMarketsWithDebt;
        EnumerableSet.Set marketsWithNonZeroBalanceSet;
        mapping (uint256 => Types.Par) balances; // Mapping from marketId to principal
    }

    // ============ Library Functions ============

    function equals(
        Info memory a,
        Info memory b
    )
        internal
        pure
        returns (bool)
    {
        return a.owner == b.owner && a.number == b.number;
    }
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Monetary } from "../lib/Monetary.sol";


/**
 * @title IPriceOracle
 * @author dYdX
 *
 * Interface that Price Oracles for DolomiteMargin must implement in order to report prices.
 */
contract IPriceOracle {

    // ============ Constants ============

    uint256 public constant ONE_DOLLAR = 10 ** 36;

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^36.
     *                So a USD-stable coin with 18 decimal places would return 10^18.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(
        address token
    )
        public
        view
        returns (Monetary.Price memory);
}

/*

    Copyright 2021 Dolomite.

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

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "../lib/Types.sol";


interface ILiquidationCallback {

    /**
     * A callback function to notify the smart contract that it is being liquidated. This function is called before the
     * new balances are set in state, so calling `getAccountPar/Wei` will return this liquidated account's balance
     * before `heldDeltaWei` or `owedDeltaWei` are applied.
     *
     * @param accountNumber The account number being liquidated
     * @param heldMarketId  The market that was positive for this account, whose collateral is being seized
     * @param heldDeltaWei  The amount of seized collateral; always negative or 0
     * @param owedMarketId  The borrowed balance that is being forcefully repaid
     * @param owedDeltaWei  The amount of borrowed assets to be repaid. Always 0 or positive, since the user's balance
     *                      is going from negative to 0.
     */
    function onLiquidate(
        uint accountNumber,
        uint heldMarketId,
        Types.Wei calldata heldDeltaWei,
        uint owedMarketId,
        Types.Wei calldata owedDeltaWei
    ) external;
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Interest } from "../lib/Interest.sol";


/**
 * @title IInterestSetter
 * @author dYdX
 *
 * Interface that Interest Setters for DolomiteMargin must implement in order to report interest rates.
 */
interface IInterestSetter {

    // ============ Public Functions ============

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
        returns (Interest.Rate memory);
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


/**
 * @title IExchangeWrapper
 * @author dYdX
 *
 * Interface that Exchange Wrappers for DolomiteMargin must implement in order to trade ERC20 tokens.
 */
interface IExchangeWrapper {

    // ============ Public Functions ============

    /**
     * Exchange some amount of takerToken for makerToken.
     *
     * @param  tradeOriginator      Address of the initiator of the trade (however, this value
     *                              cannot always be trusted as it is set at the discretion of the
     *                              msg.sender)
     * @param  receiver             Address to set allowance on once the trade has completed
     * @param  makerToken           Address of makerToken, the token to receive (target asset; IE path[path.length - 1])
     * @param  takerToken           Address of takerToken, the token to pay (originator asset; IE path[0])
     * @param  requestedFillAmount  Amount of takerToken being paid
     * @param  orderData            Arbitrary bytes data for any information to pass to the exchange
     * @return                      The amount of makerToken received
     */
    function exchange(
        address tradeOriginator,
        address receiver,
        address makerToken,
        address takerToken,
        uint256 requestedFillAmount,
        bytes calldata orderData
    )
        external
        returns (uint256);

    /**
     * Get amount of takerToken required to buy a certain amount of makerToken for a given trade.
     * Should match the takerToken amount used in exchangeForAmount. If the order cannot provide
     * exactly desiredMakerToken, then it must return the price to buy the minimum amount greater
     * than desiredMakerToken
     *
     * @param  makerToken         Address of makerToken, the token to receive
     * @param  takerToken         Address of takerToken, the token to pay
     * @param  desiredMakerToken  Amount of makerToken requested
     * @param  orderData          Arbitrary bytes data for any information to pass to the exchange
     * @return                    Amount of takerToken the needed to complete the exchange
     */
    function getExchangeCost(
        address makerToken,
        address takerToken,
        uint256 desiredMakerToken,
        bytes calldata orderData
    )
        external
        view
        returns (uint256);
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title IERC20
 * @author dYdX
 *
 * Interface for using ERC20 Tokens. We have to use a special interface to call ERC20 functions so
 * that we don't automatically revert when calling non-compliant tokens that have no return value for
 * transfer(), transferFrom(), or approve().
 */
contract IERC20Detailed is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "../lib/Account.sol";


/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for DolomiteMargin must implement in order to ingest data.
 */
contract ICallee {

    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  sender       The msg.sender to DolomiteMargin
     * @param  accountInfo  The account from which the data is being sent
     * @param  data         Arbitrary data given by the sender
     */
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    )
        public;
}

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "../lib/Account.sol";
import { Types } from "../lib/Types.sol";


/**
 * @title IAutoTrader
 * @author dYdX
 *
 * Interface that Auto-Traders for DolomiteMargin must implement in order to approve trades.
 */
contract IAutoTrader {

    // ============ Public Functions ============

    /**
     * Allows traders to make trades approved by this smart contract. The active trader's account is
     * the takerAccount and the passive account (for which this contract approves trades
     * on-behalf-of) is the makerAccount.
     *
     * @param  inputMarketId   The market for which the trader specified the original amount
     * @param  outputMarketId  The market for which the trader wants the resulting amount specified
     * @param  makerAccount    The account for which this contract is making trades
     * @param  takerAccount    The account requesting the trade
     * @param  oldInputPar     The old principal amount for the makerAccount for the inputMarketId
     * @param  newInputPar     The new principal amount for the makerAccount for the inputMarketId
     * @param  inputWei        The change in token amount for the makerAccount for the inputMarketId
     * @param  data            Arbitrary data passed in by the trader
     * @return                 The AssetAmount for the makerAccount for the outputMarketId
     */
    function getTradeCost(
        uint256 inputMarketId,
        uint256 outputMarketId,
        Account.Info memory makerAccount,
        Account.Info memory takerAccount,
        Types.Par memory oldInputPar,
        Types.Par memory newInputPar,
        Types.Wei memory inputWei,
        bytes memory data
    )
        public
        returns (Types.AssetAmount memory);
}

/*

    Copyright 2021 Dolomite

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Actions } from "../lib/Actions.sol";
import { Events } from "../lib/Events.sol";
import { Exchange } from "../lib/Exchange.sol";
import { Interest } from "../lib/Interest.sol";
import { Require } from "../lib/Require.sol";
import { Storage } from "../lib/Storage.sol";
import { Types } from "../lib/Types.sol";


library WithdrawalImpl {
    using Storage for Storage.State;

    // ============ Constants ============

    bytes32 constant FILE = "WithdrawalImpl";

    // ============ Account Actions ============

    function withdraw(
        Storage.State storage state,
        Actions.WithdrawArgs memory args,
        Interest.Index memory index
    )
    public
    {
        state.requireIsOperator(args.account, msg.sender);

        (
            Types.Par memory newPar,
            Types.Wei memory deltaWei
        ) = state.getNewParAndDeltaWei(
            args.account,
            args.market,
            index,
            args.amount
        );

        state.setPar(
            args.account,
            args.market,
            newPar
        );

        // requires a negative deltaWei
        Exchange.transferOut(
            state.getToken(args.market),
            args.to,
            deltaWei
        );

        Events.logWithdraw(
            state,
            args,
            deltaWei
        );
    }
}

/*

    Copyright 2021 Dolomite

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Actions } from "../lib/Actions.sol";
import { Events } from "../lib/Events.sol";
import { Interest } from "../lib/Interest.sol";
import { Storage } from "../lib/Storage.sol";
import { Types } from "../lib/Types.sol";


library TransferImpl {
    using Storage for Storage.State;
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "TransferImpl";

    // ============ Account Actions ============

    function transfer(
        Storage.State storage state,
        Actions.TransferArgs memory args,
        Interest.Index memory index
    )
    public
    {
        state.requireIsOperator(args.accountOne, msg.sender);
        state.requireIsOperator(args.accountTwo, msg.sender);

        (
            Types.Par memory newPar,
            Types.Wei memory deltaWei
        ) = state.getNewParAndDeltaWei(
            args.accountOne,
            args.market,
            index,
            args.amount
        );

        state.setPar(
            args.accountOne,
            args.market,
            newPar
        );

        state.setParFromDeltaWei(
            args.accountTwo,
            args.market,
            index,
            deltaWei.negative()
        );

        Events.logTransfer(
            state,
            args,
            deltaWei
        );
    }
}

/*

    Copyright 2021 Dolomite

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { IAutoTrader } from "../interfaces/IAutoTrader.sol";

import { Actions } from "../lib/Actions.sol";
import { Cache } from "../lib/Cache.sol";
import { Events } from "../lib/Events.sol";
import { Exchange } from "../lib/Exchange.sol";
import { Interest } from "../lib/Interest.sol";
import { Require } from "../lib/Require.sol";
import { Storage } from "../lib/Storage.sol";
import { Types } from "../lib/Types.sol";


library TradeImpl {
    using Storage for Storage.State;
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "TradeImpl";

    // ============ Account Actions ============

    function buy(
        Storage.State storage state,
        Actions.BuyArgs memory args,
        Interest.Index memory takerIndex,
        Interest.Index memory makerIndex
    )
    public
    {
        state.requireIsOperator(args.account, msg.sender);

        address takerToken = state.getToken(args.takerMarket);
        address makerToken = state.getToken(args.makerMarket);

        (
            Types.Par memory makerPar,
            Types.Wei memory makerWei
        ) = state.getNewParAndDeltaWei(
            args.account,
            args.makerMarket,
            makerIndex,
            args.amount
        );

        Types.Wei memory takerWei = Exchange.getCost(
            args.exchangeWrapper,
            makerToken,
            takerToken,
            makerWei,
            args.orderData
        );

        Types.Wei memory tokensReceived = Exchange.exchange(
            args.exchangeWrapper,
            args.account.owner,
            makerToken,
            takerToken,
            takerWei,
            args.orderData
        );

        Require.that(
            tokensReceived.value >= makerWei.value,
            FILE,
            "Buy amount less than promised",
            tokensReceived.value
        );

        state.setPar(
            args.account,
            args.makerMarket,
            makerPar
        );

        state.setParFromDeltaWei(
            args.account,
            args.takerMarket,
            takerIndex,
            takerWei
        );

        Events.logBuy(
            state,
            args,
            takerWei,
            makerWei
        );
    }

    function sell(
        Storage.State storage state,
        Actions.SellArgs memory args,
        Interest.Index memory takerIndex,
        Interest.Index memory makerIndex
    )
    public
    {
        state.requireIsOperator(args.account, msg.sender);

        address takerToken = state.getToken(args.takerMarket);
        address makerToken = state.getToken(args.makerMarket);

        (
            Types.Par memory takerPar,
            Types.Wei memory takerWei
        ) = state.getNewParAndDeltaWei(
            args.account,
            args.takerMarket,
            takerIndex,
            args.amount
        );

        Types.Wei memory makerWei = Exchange.exchange(
            args.exchangeWrapper,
            args.account.owner,
            makerToken,
            takerToken,
            takerWei,
            args.orderData
        );

        state.setPar(
            args.account,
            args.takerMarket,
            takerPar
        );

        state.setParFromDeltaWei(
            args.account,
            args.makerMarket,
            makerIndex,
            makerWei
        );

        Events.logSell(
            state,
            args,
            takerWei,
            makerWei
        );
    }

    function trade(
        Storage.State storage state,
        Actions.TradeArgs memory args,
        Interest.Index memory inputIndex,
        Interest.Index memory outputIndex
    )
    public
    {
        state.requireIsOperator(args.takerAccount, msg.sender);
        state.requireIsOperator(args.makerAccount, args.autoTrader);
        if (state.isAutoTraderSpecial(args.autoTrader)) {
            Require.that(
                state.isGlobalOperator(msg.sender),
                FILE,
                "Unpermissioned trade operator"
            );
        }

        Types.Par memory oldInputPar = state.getPar(
            args.makerAccount,
            args.inputMarket
        );

        (
            Types.Par memory newInputPar,
            Types.Wei memory inputWei
        ) = state.getNewParAndDeltaWei(
            args.makerAccount,
            args.inputMarket,
            inputIndex,
            args.amount
        );

        Types.AssetAmount memory outputAmount = IAutoTrader(args.autoTrader).getTradeCost(
            args.inputMarket,
            args.outputMarket,
            args.makerAccount,
            args.takerAccount,
            oldInputPar,
            newInputPar,
            inputWei,
            args.tradeData
        );

        (
            Types.Par memory newOutputPar,
            Types.Wei memory outputWei
        ) = state.getNewParAndDeltaWei(
            args.makerAccount,
            args.outputMarket,
            outputIndex,
            outputAmount
        );

        Require.that(
            outputWei.isZero() || inputWei.isZero() || outputWei.sign != inputWei.sign,
            FILE,
            "Trades cannot be one-sided",
            args.autoTrader
        );

        // set the balance for the maker
        state.setPar(
            args.makerAccount,
            args.inputMarket,
            newInputPar
        );
        state.setPar(
            args.makerAccount,
            args.outputMarket,
            newOutputPar
        );

        // set the balance for the taker
        state.setParFromDeltaWei(
            args.takerAccount,
            args.inputMarket,
            inputIndex,
            inputWei.negative()
        );
        state.setParFromDeltaWei(
            args.takerAccount,
            args.outputMarket,
            outputIndex,
            outputWei.negative()
        );

        Events.logTrade(
            state,
            args,
            inputWei,
            outputWei
        );
    }
}

pragma solidity ^0.5.5;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/*

    Copyright 2021 Dolomite

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ILiquidationCallback } from "../interfaces/ILiquidationCallback.sol";
import { Account } from "../lib/Account.sol";
import { Actions } from "../lib/Actions.sol";
import { Cache } from "../lib/Cache.sol";
import { Decimal } from "../lib/Decimal.sol";
import { Events } from "../lib/Events.sol";
import { Interest } from "../lib/Interest.sol";
import { DolomiteMarginMath } from "../lib/DolomiteMarginMath.sol";
import { Monetary } from "../lib/Monetary.sol";
import { Require } from "../lib/Require.sol";
import { SafeLiquidationCallback } from "../lib/SafeLiquidationCallback.sol";
import { Storage } from "../lib/Storage.sol";
import { Types } from "../lib/Types.sol";


/**
 * @dev A library that combines shares code for executing Liquidation or Vaporization actions.
 */
library LiquidateOrVaporizeImpl {
    using Cache for Cache.MarketCache;
    using SafeMath for uint256;
    using Storage for Storage.State;
    using Types for Types.Par;
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "LiquidateOrVaporizeImpl";

    // ============ Account Functions ============

    function liquidate(
        Storage.State storage state,
        Cache.MarketCache memory cache,
        Actions.LiquidateArgs memory args
    )
    public
    {
        state.requireIsGlobalOperator(msg.sender);

        // verify liquidatable
        if (Account.Status.Liquid != state.getStatus(args.liquidAccount)) {
            Require.that(
                !state.isCollateralized(args.liquidAccount, cache, /* requireMinBorrow = */ false),
                FILE,
                "Unliquidatable account",
                args.liquidAccount.owner,
                args.liquidAccount.number
            );
            state.setStatus(args.liquidAccount, Account.Status.Liquid);
        }

        Types.Wei memory maxHeldWei = state.getWei(
            args.liquidAccount,
            args.heldMarket,
            cache.get(args.heldMarket).index
        );

        Require.that(
            !maxHeldWei.isNegative(),
            FILE,
            "Collateral cannot be negative",
            args.heldMarket
        );

        Interest.Index memory owedIndex = cache.get(args.owedMarket).index;
        Interest.Index memory heldIndex = cache.get(args.heldMarket).index;
        (
            Types.Par memory owedPar,
            Types.Wei memory owedWei
        ) = state.getNewParAndDeltaWeiForLiquidation(
            args.liquidAccount,
            args.owedMarket,
            owedIndex,
            args.amount
        );

        (
            Monetary.Price memory heldPrice,
            Monetary.Price memory owedPriceAdj
        ) = _getLiquidationPrices(
            state,
            cache,
            args.heldMarket,
            args.owedMarket
        );

        Types.Wei memory heldWei = _owedWeiToHeldWei(owedWei, heldPrice, owedPriceAdj);

        // if attempting to over-borrow the held asset, bound it by the maximum
        if (heldWei.value > maxHeldWei.value) {
            heldWei = maxHeldWei.negative();
            owedWei = _heldWeiToOwedWei(heldWei, heldPrice, owedPriceAdj);

            SafeLiquidationCallback.callLiquidateCallbackIfNecessary(
                args.liquidAccount,
                args.heldMarket,
                heldWei,
                args.owedMarket,
                owedWei
            );

            state.setPar(
                args.liquidAccount,
                args.heldMarket,
                Types.zeroPar()
            );
            state.setParFromDeltaWei(
                args.liquidAccount,
                args.owedMarket,
                owedIndex,
                owedWei
            );
        } else {
            SafeLiquidationCallback.callLiquidateCallbackIfNecessary(
                args.liquidAccount,
                args.heldMarket,
                heldWei,
                args.owedMarket,
                owedWei
            );

            state.setPar(
                args.liquidAccount,
                args.owedMarket,
                owedPar
            );
            state.setParFromDeltaWei(
                args.liquidAccount,
                args.heldMarket,
                heldIndex,
                heldWei
            );
        }

        // set the balances for the solid account
        state.setParFromDeltaWei(
            args.solidAccount,
            args.owedMarket,
            owedIndex,
            owedWei.negative()
        );
        state.setParFromDeltaWei(
            args.solidAccount,
            args.heldMarket,
            heldIndex,
            heldWei.negative()
        );

        Events.logLiquidate(
            state,
            args,
            heldWei,
            owedWei
        );
    }

    function vaporize(
        Storage.State storage state,
        Cache.MarketCache memory cache,
        Actions.VaporizeArgs memory args
    )
    public
    {
        state.requireIsOperator(args.solidAccount, msg.sender);

        // verify vaporizable
        if (Account.Status.Vapor != state.getStatus(args.vaporAccount)) {
            Require.that(
                state.isVaporizable(args.vaporAccount, cache),
                FILE,
                "Unvaporizable account",
                args.vaporAccount.owner,
                args.vaporAccount.number
            );
            state.setStatus(args.vaporAccount, Account.Status.Vapor);
        }

        // First, attempt to refund using the same token
        // cache.get(args.owedMarket).index is not stored in a variable here to avoid the "stack too deep" error
        (
            bool fullyRepaid,
            Types.Wei memory excessWei
        ) = _vaporizeUsingExcess(state, args, cache.get(args.owedMarket).index);
        if (fullyRepaid) {
            Events.logVaporize(
                state,
                args,
                Types.zeroWei(),
                Types.zeroWei(),
                excessWei
            );
            return;
        }

        Types.Wei memory maxHeldWei = state.getNumExcessTokens(args.heldMarket);

        Require.that(
            !maxHeldWei.isNegative(),
            FILE,
            "Excess cannot be negative",
            args.heldMarket
        );

        (
            Types.Par memory owedPar,
            Types.Wei memory owedWei
        ) = state.getNewParAndDeltaWeiForLiquidation(
            args.vaporAccount,
            args.owedMarket,
            cache.get(args.owedMarket).index,
            args.amount
        );

        (
            Monetary.Price memory heldPrice,
            Monetary.Price memory owedPrice
        ) = _getLiquidationPrices(
            state,
            cache,
            args.heldMarket,
            args.owedMarket
        );

        Types.Wei memory heldWei = _owedWeiToHeldWei(owedWei, heldPrice, owedPrice);

        // if attempting to over-borrow the held asset, bound it by the maximum
        if (heldWei.value > maxHeldWei.value) {
            heldWei = maxHeldWei.negative();
            owedWei = _heldWeiToOwedWei(heldWei, heldPrice, owedPrice);

            SafeLiquidationCallback.callLiquidateCallbackIfNecessary(
                args.vaporAccount,
                args.heldMarket,
                Types.zeroWei(),
                args.owedMarket,
                owedWei
            );

            state.setParFromDeltaWei(
                args.vaporAccount,
                args.owedMarket,
                cache.get(args.owedMarket).index,
                owedWei
            );
        } else {
            SafeLiquidationCallback.callLiquidateCallbackIfNecessary(
                args.vaporAccount,
                args.heldMarket,
                Types.zeroWei(),
                args.owedMarket,
                owedWei
            );

            state.setPar(
                args.vaporAccount,
                args.owedMarket,
                owedPar
            );
        }

        // set the balances for the solid account
        state.setParFromDeltaWei(
            args.solidAccount,
            args.owedMarket,
            cache.get(args.owedMarket).index,
            owedWei.negative()
        );
        state.setParFromDeltaWei(
            args.solidAccount,
            args.heldMarket,
            cache.get(args.heldMarket).index,
            heldWei.negative()
        );

        Events.logVaporize(
            state,
            args,
            heldWei,
            owedWei,
            excessWei
        );
    }

    /**
     * Attempt to vaporize an account's balance using the excess tokens in the protocol. Return a
     * bool and a wei value. The boolean is true if and only if the balance was fully vaporized. The
     * Wei value is how many excess tokens were used to partially or fully vaporize the account's
     * negative balance.
     */
    function _vaporizeUsingExcess(
        Storage.State storage state,
        Actions.VaporizeArgs memory args,
        Interest.Index memory owedIndex
    )
    internal
    returns (bool, Types.Wei memory)
    {
        Types.Wei memory excessWei = state.getNumExcessTokens(args.owedMarket);

        // There are no excess funds, return zero
        if (!excessWei.isPositive()) {
            return (false, Types.zeroWei());
        }

        Types.Wei memory maxRefundWei = state.getWei(
            args.vaporAccount,
            args.owedMarket,
            owedIndex
        );
        maxRefundWei.sign = true;

        // The account is fully vaporizable using excess funds
        if (excessWei.value >= maxRefundWei.value) {
            state.setPar(
                args.vaporAccount,
                args.owedMarket,
                Types.zeroPar()
            );
            return (true, maxRefundWei);
        }

        // The account is only partially vaporizable using excess funds
        else {
            state.setParFromDeltaWei(
                args.vaporAccount,
                args.owedMarket,
                owedIndex,
                excessWei
            );
            return (false, excessWei);
        }
    }

    /**
     * For the purposes of liquidation or vaporization, get the value-equivalent amount of owedWei
     * given heldWei and the (spread-adjusted) prices of each asset.
     */
    function _heldWeiToOwedWei(
        Types.Wei memory heldWei,
        Monetary.Price memory heldPrice,
        Monetary.Price memory owedPrice
    )
    internal
    pure
    returns (Types.Wei memory)
    {
        return Types.Wei({
        sign: true,
        value: DolomiteMarginMath.getPartialRoundUp(heldWei.value, heldPrice.value, owedPrice.value)
        });
    }

    /**
     * For the purposes of liquidation or vaporization, get the value-equivalent amount of heldWei
     * given owedWei and the (spread-adjusted) prices of each asset.
     */
    function _owedWeiToHeldWei(
        Types.Wei memory owedWei,
        Monetary.Price memory heldPrice,
        Monetary.Price memory owedPrice
    )
    internal
    pure
    returns (Types.Wei memory)
    {
        return Types.Wei({
        sign: false,
        value: DolomiteMarginMath.getPartial(owedWei.value, owedPrice.value, heldPrice.value)
        });
    }

    /**
     * Return the (spread-adjusted) prices of two assets for the purposes of liquidation or
     * vaporization.
     */
    function _getLiquidationPrices(
        Storage.State storage state,
        Cache.MarketCache memory cache,
        uint256 heldMarketId,
        uint256 owedMarketId
    )
    internal
    view
    returns (
        Monetary.Price memory,
        Monetary.Price memory
    )
    {
        uint256 owedPrice = cache.get(owedMarketId).price.value;
        Decimal.D256 memory spread = state.getLiquidationSpreadForPair(
            heldMarketId,
            owedMarketId
        );

        Monetary.Price memory owedPriceAdj = Monetary.Price({
            value: owedPrice.add(Decimal.mul(owedPrice, spread))
        });

        return (cache.get(heldMarketId).price, owedPriceAdj);
    }
}

/*

    Copyright 2021 Dolomite

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Actions } from "../lib/Actions.sol";
import { Events } from "../lib/Events.sol";
import { Exchange } from "../lib/Exchange.sol";
import { Interest } from "../lib/Interest.sol";
import { Require } from "../lib/Require.sol";
import { Storage } from "../lib/Storage.sol";
import { Types } from "../lib/Types.sol";


library DepositImpl {
    using Storage for Storage.State;

    // ============ Constants ============

    bytes32 constant FILE = "DepositImpl";

    // ============ Account Actions ============

    function deposit(
        Storage.State storage state,
        Actions.DepositArgs memory args,
        Interest.Index memory index
    )
        public
    {
        state.requireIsOperator(args.account, msg.sender);

        Require.that(
            args.from == msg.sender || args.from == args.account.owner,
            FILE,
            "Invalid deposit source",
            args.from
        );

        (
            Types.Par memory newPar,
            Types.Wei memory deltaWei
        ) = state.getNewParAndDeltaWei(
            args.account,
            args.market,
            index,
            args.amount
        );

        state.setPar(
            args.account,
            args.market,
            newPar
        );

        // requires a positive deltaWei
        Exchange.transferIn(
            state.getToken(args.market),
            args.from,
            deltaWei
        );

        Events.logDeposit(
            state,
            args,
            deltaWei
        );
    }
}

/*

    Copyright 2021 Dolomite

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { ICallee } from "../interfaces/ICallee.sol";
import { Actions } from "../lib/Actions.sol";
import { Cache } from "../lib/Cache.sol";
import { Events } from "../lib/Events.sol";
import { Storage } from "../lib/Storage.sol";


library CallImpl {
    using Cache for Cache.MarketCache;
    using Storage for Storage.State;

    // ============ Constants ============

    bytes32 constant FILE = "CallImpl";

    // ============ Account Actions ============

    function call(
        Storage.State storage state,
        Actions.CallArgs memory args
    )
    public
    {
        state.requireIsOperator(args.account, msg.sender);

        ICallee(args.callee).callFunction(
            msg.sender,
            args.account,
            args.data
        );

        Events.logCall(args);
    }
}