/**
 *Submitted for verification at Arbiscan on 2023-06-04
*/

/* Tribeone: ExchangerWithFeeRecAlternatives.sol
* Latest source (may be newer): https://github.com/TribeOneDefi/tribeone-v3-contracts/blob/master/contracts/ExchangerWithFeeRecAlternatives.sol
* Docs: https://docs.tribeone.io/contracts/ExchangerWithFeeRecAlternatives
*
* Contract Dependencies: 
*	- Exchanger
*	- IAddressResolver
*	- IExchanger
*	- MinimalProxyFactory
*	- MixinResolver
*	- MixinSystemSettings
*	- Owned
* Libraries: 
*	- ExchangeSettlementLib
*	- SafeDecimalMath
*	- SafeMath
*
* MIT License
* ===========
*
* Copyright (c) 2023 Tribeone
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;

// https://docs.tribeone.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// https://docs.tribeone.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getTribe(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// https://docs.tribeone.io/contracts/source/interfaces/itribe
interface ITribe {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableTribes(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Tribeone
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/iissuer
interface IIssuer {
    // Views

    function allNetworksDebtInfo()
        external
        view
        returns (
            uint256 debt,
            uint256 sharesSupply,
            bool isStale
        );

    function anyTribeOrHAKARateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableTribeCount() external view returns (uint);

    function availableTribes(uint index) external view returns (ITribe);

    function canBurnTribes(address account) external view returns (bool);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint debtBalance);

    function issuanceRatio() external view returns (uint);

    function lastIssueEvent(address account) external view returns (uint);

    function maxIssuableTribes(address issuer) external view returns (uint maxIssuable);

    function minimumStakeTime() external view returns (uint);

    function remainingIssuableTribes(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function tribes(bytes32 currencyKey) external view returns (ITribe);

    function getTribes(bytes32[] calldata currencyKeys) external view returns (ITribe[] memory);

    function tribesByAddress(address tribeAddress) external view returns (bytes32);

    function totalIssuedTribes(bytes32 currencyKey, bool excludeOtherCollateral) external view returns (uint);

    function transferableTribeoneAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid);

    function liquidationAmounts(address account, bool isSelfLiquidation)
        external
        view
        returns (
            uint totalRedeemed,
            uint debtToRemove,
            uint escrowToLiquidate,
            uint initialDebtBalance
        );

    // Restricted: used internally to Tribeone
    function addTribes(ITribe[] calldata tribesToAdd) external;

    function issueTribes(address from, uint amount) external;

    function issueTribesOnBehalf(
        address issueFor,
        address from,
        uint amount
    ) external;

    function issueMaxTribes(address from) external;

    function issueMaxTribesOnBehalf(address issueFor, address from) external;

    function burnTribes(address from, uint amount) external;

    function burnTribesOnBehalf(
        address burnForAddress,
        address from,
        uint amount
    ) external;

    function burnTribesToTarget(address from) external;

    function burnTribesToTargetOnBehalf(address burnForAddress, address from) external;

    function burnForRedemption(
        address deprecatedTribeProxy,
        address account,
        uint balance
    ) external;

    function setCurrentPeriodId(uint128 periodId) external;

    function liquidateAccount(address account, bool isSelfLiquidation)
        external
        returns (
            uint totalRedeemed,
            uint debtRemoved,
            uint escrowToLiquidate
        );

    function issueTribesWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external returns (bool rateInvalid);

    function burnTribesWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external returns (bool rateInvalid);

    function modifyDebtSharesForMigration(address account, uint amount) external;
}


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getTribe(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.tribes(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/mixinresolver
contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}


// https://docs.tribeone.io/contracts/source/interfaces/iflexiblestorage
interface IFlexibleStorage {
    // Views
    function getUIntValue(bytes32 contractName, bytes32 record) external view returns (uint);

    function getUIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint[] memory);

    function getIntValue(bytes32 contractName, bytes32 record) external view returns (int);

    function getIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (int[] memory);

    function getAddressValue(bytes32 contractName, bytes32 record) external view returns (address);

    function getAddressValues(bytes32 contractName, bytes32[] calldata records) external view returns (address[] memory);

    function getBoolValue(bytes32 contractName, bytes32 record) external view returns (bool);

    function getBoolValues(bytes32 contractName, bytes32[] calldata records) external view returns (bool[] memory);

    function getBytes32Value(bytes32 contractName, bytes32 record) external view returns (bytes32);

    function getBytes32Values(bytes32 contractName, bytes32[] calldata records) external view returns (bytes32[] memory);

    // Mutative functions
    function deleteUIntValue(bytes32 contractName, bytes32 record) external;

    function deleteIntValue(bytes32 contractName, bytes32 record) external;

    function deleteAddressValue(bytes32 contractName, bytes32 record) external;

    function deleteBoolValue(bytes32 contractName, bytes32 record) external;

    function deleteBytes32Value(bytes32 contractName, bytes32 record) external;

    function setUIntValue(
        bytes32 contractName,
        bytes32 record,
        uint value
    ) external;

    function setUIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        uint[] calldata values
    ) external;

    function setIntValue(
        bytes32 contractName,
        bytes32 record,
        int value
    ) external;

    function setIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        int[] calldata values
    ) external;

    function setAddressValue(
        bytes32 contractName,
        bytes32 record,
        address value
    ) external;

    function setAddressValues(
        bytes32 contractName,
        bytes32[] calldata records,
        address[] calldata values
    ) external;

    function setBoolValue(
        bytes32 contractName,
        bytes32 record,
        bool value
    ) external;

    function setBoolValues(
        bytes32 contractName,
        bytes32[] calldata records,
        bool[] calldata values
    ) external;

    function setBytes32Value(
        bytes32 contractName,
        bytes32 record,
        bytes32 value
    ) external;

    function setBytes32Values(
        bytes32 contractName,
        bytes32[] calldata records,
        bytes32[] calldata values
    ) external;
}


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/mixinsystemsettings
contract MixinSystemSettings is MixinResolver {
    // must match the one defined SystemSettingsLib, defined in both places due to sol v0.5 limitations
    bytes32 internal constant SETTING_CONTRACT_NAME = "SystemSettings";

    bytes32 internal constant SETTING_WAITING_PERIOD_SECS = "waitingPeriodSecs";
    bytes32 internal constant SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR = "priceDeviationThresholdFactor";
    bytes32 internal constant SETTING_ISSUANCE_RATIO = "issuanceRatio";
    bytes32 internal constant SETTING_FEE_PERIOD_DURATION = "feePeriodDuration";
    bytes32 internal constant SETTING_TARGET_THRESHOLD = "targetThreshold";
    bytes32 internal constant SETTING_LIQUIDATION_DELAY = "liquidationDelay";
    bytes32 internal constant SETTING_LIQUIDATION_RATIO = "liquidationRatio";
    bytes32 internal constant SETTING_LIQUIDATION_ESCROW_DURATION = "liquidationEscrowDuration";
    bytes32 internal constant SETTING_LIQUIDATION_PENALTY = "liquidationPenalty";
    bytes32 internal constant SETTING_HAKA_LIQUIDATION_PENALTY = "snxLiquidationPenalty";
    bytes32 internal constant SETTING_SELF_LIQUIDATION_PENALTY = "selfLiquidationPenalty";
    bytes32 internal constant SETTING_FLAG_REWARD = "flagReward";
    bytes32 internal constant SETTING_LIQUIDATE_REWARD = "liquidateReward";
    bytes32 internal constant SETTING_RATE_STALE_PERIOD = "rateStalePeriod";
    /* ========== Exchange Fees Related ========== */
    bytes32 internal constant SETTING_EXCHANGE_FEE_RATE = "exchangeFeeRate";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD = "exchangeDynamicFeeThreshold";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY = "exchangeDynamicFeeWeightDecay";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS = "exchangeDynamicFeeRounds";
    bytes32 internal constant SETTING_EXCHANGE_MAX_DYNAMIC_FEE = "exchangeMaxDynamicFee";
    /* ========== End Exchange Fees Related ========== */
    bytes32 internal constant SETTING_MINIMUM_STAKE_TIME = "minimumStakeTime";
    bytes32 internal constant SETTING_AGGREGATOR_WARNING_FLAGS = "aggregatorWarningFlags";
    bytes32 internal constant SETTING_TRADING_REWARDS_ENABLED = "tradingRewardsEnabled";
    bytes32 internal constant SETTING_DEBT_SNAPSHOT_STALE_TIME = "debtSnapshotStaleTime";
    bytes32 internal constant SETTING_CROSS_DOMAIN_DEPOSIT_GAS_LIMIT = "crossDomainDepositGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_ESCROW_GAS_LIMIT = "crossDomainEscrowGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_REWARD_GAS_LIMIT = "crossDomainRewardGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_WITHDRAWAL_GAS_LIMIT = "crossDomainWithdrawalGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_FEE_PERIOD_CLOSE_GAS_LIMIT = "crossDomainCloseGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_RELAY_GAS_LIMIT = "crossDomainRelayGasLimit";
    bytes32 internal constant SETTING_ETHER_WRAPPER_MAX_ETH = "etherWrapperMaxETH";
    bytes32 internal constant SETTING_ETHER_WRAPPER_MINT_FEE_RATE = "etherWrapperMintFeeRate";
    bytes32 internal constant SETTING_ETHER_WRAPPER_BURN_FEE_RATE = "etherWrapperBurnFeeRate";
    bytes32 internal constant SETTING_WRAPPER_MAX_TOKEN_AMOUNT = "wrapperMaxTokens";
    bytes32 internal constant SETTING_WRAPPER_MINT_FEE_RATE = "wrapperMintFeeRate";
    bytes32 internal constant SETTING_WRAPPER_BURN_FEE_RATE = "wrapperBurnFeeRate";
    bytes32 internal constant SETTING_INTERACTION_DELAY = "interactionDelay";
    bytes32 internal constant SETTING_COLLAPSE_FEE_RATE = "collapseFeeRate";
    bytes32 internal constant SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK = "atomicMaxVolumePerBlock";
    bytes32 internal constant SETTING_ATOMIC_TWAP_WINDOW = "atomicTwapWindow";
    bytes32 internal constant SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING = "atomicEquivalentForDexPricing";
    bytes32 internal constant SETTING_ATOMIC_EXCHANGE_FEE_RATE = "atomicExchangeFeeRate";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = "atomicVolConsiderationWindow";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD = "atomicVolUpdateThreshold";
    bytes32 internal constant SETTING_PURE_CHAINLINK_PRICE_FOR_ATOMIC_SWAPS_ENABLED = "pureChainlinkForAtomicsEnabled";
    bytes32 internal constant SETTING_CROSS_TRIBEONE_TRANSFER_ENABLED = "crossChainTribeTransferEnabled";

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    enum CrossDomainMessageGasLimits {Deposit, Escrow, Reward, Withdrawal, CloseFeePeriod, Relay}

    struct DynamicFeeConfig {
        uint threshold;
        uint weightDecay;
        uint rounds;
        uint maxFee;
    }

    constructor(address _resolver) internal MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_FLEXIBLESTORAGE;
    }

    function flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    function _getGasLimitSetting(CrossDomainMessageGasLimits gasLimitType) internal pure returns (bytes32) {
        if (gasLimitType == CrossDomainMessageGasLimits.Deposit) {
            return SETTING_CROSS_DOMAIN_DEPOSIT_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Escrow) {
            return SETTING_CROSS_DOMAIN_ESCROW_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Reward) {
            return SETTING_CROSS_DOMAIN_REWARD_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Withdrawal) {
            return SETTING_CROSS_DOMAIN_WITHDRAWAL_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Relay) {
            return SETTING_CROSS_DOMAIN_RELAY_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.CloseFeePeriod) {
            return SETTING_CROSS_DOMAIN_FEE_PERIOD_CLOSE_GAS_LIMIT;
        } else {
            revert("Unknown gas limit type");
        }
    }

    function getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits gasLimitType) internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, _getGasLimitSetting(gasLimitType));
    }

    function getTradingRewardsEnabled() internal view returns (bool) {
        return flexibleStorage().getBoolValue(SETTING_CONTRACT_NAME, SETTING_TRADING_REWARDS_ENABLED);
    }

    function getWaitingPeriodSecs() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_WAITING_PERIOD_SECS);
    }

    function getPriceDeviationThresholdFactor() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR);
    }

    function getIssuanceRatio() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ISSUANCE_RATIO);
    }

    function getFeePeriodDuration() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_FEE_PERIOD_DURATION);
    }

    function getTargetThreshold() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_TARGET_THRESHOLD);
    }

    function getLiquidationDelay() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_DELAY);
    }

    function getLiquidationRatio() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_RATIO);
    }

    function getLiquidationEscrowDuration() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_ESCROW_DURATION);
    }

    function getLiquidationPenalty() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_PENALTY);
    }

    function getSnxLiquidationPenalty() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_HAKA_LIQUIDATION_PENALTY);
    }

    function getSelfLiquidationPenalty() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_SELF_LIQUIDATION_PENALTY);
    }

    function getFlagReward() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_FLAG_REWARD);
    }

    function getLiquidateReward() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATE_REWARD);
    }

    function getRateStalePeriod() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_RATE_STALE_PERIOD);
    }

    /* ========== Exchange Related Fees ========== */
    function getExchangeFeeRate(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_EXCHANGE_FEE_RATE, currencyKey))
            );
    }

    /// @notice Get exchange dynamic fee related keys
    /// @return threshold, weight decay, rounds, and max fee
    function getExchangeDynamicFeeConfig() internal view returns (DynamicFeeConfig memory) {
        bytes32[] memory keys = new bytes32[](4);
        keys[0] = SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD;
        keys[1] = SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY;
        keys[2] = SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS;
        keys[3] = SETTING_EXCHANGE_MAX_DYNAMIC_FEE;
        uint[] memory values = flexibleStorage().getUIntValues(SETTING_CONTRACT_NAME, keys);
        return DynamicFeeConfig({threshold: values[0], weightDecay: values[1], rounds: values[2], maxFee: values[3]});
    }

    /* ========== End Exchange Related Fees ========== */

    function getMinimumStakeTime() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MINIMUM_STAKE_TIME);
    }

    function getAggregatorWarningFlags() internal view returns (address) {
        return flexibleStorage().getAddressValue(SETTING_CONTRACT_NAME, SETTING_AGGREGATOR_WARNING_FLAGS);
    }

    function getDebtSnapshotStaleTime() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_DEBT_SNAPSHOT_STALE_TIME);
    }

    function getEtherWrapperMaxETH() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_MAX_ETH);
    }

    function getEtherWrapperMintFeeRate() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_MINT_FEE_RATE);
    }

    function getEtherWrapperBurnFeeRate() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_BURN_FEE_RATE);
    }

    function getWrapperMaxTokenAmount(address wrapper) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_WRAPPER_MAX_TOKEN_AMOUNT, wrapper))
            );
    }

    function getWrapperMintFeeRate(address wrapper) internal view returns (int) {
        return
            flexibleStorage().getIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_WRAPPER_MINT_FEE_RATE, wrapper))
            );
    }

    function getWrapperBurnFeeRate(address wrapper) internal view returns (int) {
        return
            flexibleStorage().getIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_WRAPPER_BURN_FEE_RATE, wrapper))
            );
    }

    function getInteractionDelay(address collateral) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_INTERACTION_DELAY, collateral))
            );
    }

    function getCollapseFeeRate(address collateral) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_COLLAPSE_FEE_RATE, collateral))
            );
    }

    function getAtomicMaxVolumePerBlock() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK);
    }

    function getAtomicTwapWindow() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ATOMIC_TWAP_WINDOW);
    }

    function getAtomicEquivalentForDexPricing(bytes32 currencyKey) internal view returns (address) {
        return
            flexibleStorage().getAddressValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING, currencyKey))
            );
    }

    function getAtomicExchangeFeeRate(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_EXCHANGE_FEE_RATE, currencyKey))
            );
    }

    function getAtomicVolatilityConsiderationWindow(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW, currencyKey))
            );
    }

    function getAtomicVolatilityUpdateThreshold(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD, currencyKey))
            );
    }

    function getPureChainlinkPriceForAtomicSwapsEnabled(bytes32 currencyKey) internal view returns (bool) {
        return
            flexibleStorage().getBoolValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_PURE_CHAINLINK_PRICE_FOR_ATOMIC_SWAPS_ENABLED, currencyKey))
            );
    }

    function getCrossChainTribeTransferEnabled(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_CROSS_TRIBEONE_TRANSFER_ENABLED, currencyKey))
            );
    }

    function getExchangeMaxDynamicFee() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_MAX_DYNAMIC_FEE);
    }

    function getExchangeDynamicFeeRounds() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS);
    }

    function getExchangeDynamicFeeThreshold() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD);
    }

    function getExchangeDynamicFeeWeightDecay() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY);
    }
}


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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// Libraries


// https://docs.tribeone.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint a, uint b) internal pure returns (uint) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int x) internal pure returns (uint) {
        return uint(signedAbs(x));
    }
}


// https://docs.tribeone.io/contracts/source/interfaces/isystemstatus
interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function systemSuspended() external view returns (bool);

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireFuturesActive() external view;

    function requireFuturesMarketActive(bytes32 marketKey) external view;

    function requireExchangeBetweenTribesAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireTribeActive(bytes32 currencyKey) external view;

    function tribeSuspended(bytes32 currencyKey) external view returns (bool);

    function requireTribesActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function futuresSuspension() external view returns (bool suspended, uint248 reason);

    function tribeExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function tribeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function futuresMarketSuspension(bytes32 marketKey) external view returns (bool suspended, uint248 reason);

    function getTribeExchangeSuspensions(bytes32[] calldata tribes)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getTribeSuspensions(bytes32[] calldata tribes)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    function getFuturesMarketSuspensions(bytes32[] calldata marketKeys)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendIssuance(uint256 reason) external;

    function suspendTribe(bytes32 currencyKey, uint256 reason) external;

    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


// https://docs.tribeone.io/contracts/source/interfaces/ICircuitBreaker
interface ICircuitBreaker {
    // Views
    function isInvalid(address oracleAddress, uint value) external view returns (bool);

    function priceDeviationThresholdFactor() external view returns (uint);

    function isDeviationAboveThreshold(uint base, uint comparison) external view returns (bool);

    function lastValue(address oracleAddress) external view returns (uint);

    function circuitBroken(address oracleAddress) external view returns (bool);

    // Mutative functions
    function resetLastValue(address[] calldata oracleAddresses, uint[] calldata values) external;

    function probeCircuitBreaker(address oracleAddress, uint value) external returns (bool circuitBroken);
}


// https://docs.tribeone.io/contracts/source/interfaces/ifeepool
interface IFeePool {
    // Views

    // solhint-disable-next-line func-name-mixedcase
    function FEE_ADDRESS() external view returns (address);

    function feesAvailable(address account) external view returns (uint, uint);

    function feesBurned(address account) external view returns (uint);

    function feesToBurn(address account) external view returns (uint);

    function feePeriodDuration() external view returns (uint);

    function isFeesClaimable(address account) external view returns (bool);

    function targetThreshold() external view returns (uint);

    function totalFeesAvailable() external view returns (uint);

    function totalFeesBurned() external view returns (uint);

    function totalRewardsAvailable() external view returns (uint);

    // Mutative Functions
    function claimFees() external returns (bool);

    function claimOnBehalf(address claimingForAddress) external returns (bool);

    function closeCurrentFeePeriod() external;

    function closeSecondary(uint snxBackedDebt, uint debtShareSupply) external;

    function recordFeePaid(uint hUSDAmount) external;

    function setRewardsToDistribute(uint amount) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/idelegateapprovals
interface IDelegateApprovals {
    // Views
    function canBurnFor(address authoriser, address delegate) external view returns (bool);

    function canIssueFor(address authoriser, address delegate) external view returns (bool);

    function canClaimFor(address authoriser, address delegate) external view returns (bool);

    function canExchangeFor(address authoriser, address delegate) external view returns (bool);

    // Mutative
    function approveAllDelegatePowers(address delegate) external;

    function removeAllDelegatePowers(address delegate) external;

    function approveBurnOnBehalf(address delegate) external;

    function removeBurnOnBehalf(address delegate) external;

    function approveIssueOnBehalf(address delegate) external;

    function removeIssueOnBehalf(address delegate) external;

    function approveClaimOnBehalf(address delegate) external;

    function removeClaimOnBehalf(address delegate) external;

    function approveExchangeOnBehalf(address delegate) external;

    function removeExchangeOnBehalf(address delegate) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/itradingrewards
interface ITradingRewards {
    /* ========== VIEWS ========== */

    function getAvailableRewards() external view returns (uint);

    function getUnassignedRewards() external view returns (uint);

    function getRewardsToken() external view returns (address);

    function getPeriodController() external view returns (address);

    function getCurrentPeriod() external view returns (uint);

    function getPeriodIsClaimable(uint periodID) external view returns (bool);

    function getPeriodIsFinalized(uint periodID) external view returns (bool);

    function getPeriodRecordedFees(uint periodID) external view returns (uint);

    function getPeriodTotalRewards(uint periodID) external view returns (uint);

    function getPeriodAvailableRewards(uint periodID) external view returns (uint);

    function getUnaccountedFeesForAccountForPeriod(address account, uint periodID) external view returns (uint);

    function getAvailableRewardsForAccountForPeriod(address account, uint periodID) external view returns (uint);

    function getAvailableRewardsForAccountForPeriods(address account, uint[] calldata periodIDs)
        external
        view
        returns (uint totalRewards);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claimRewardsForPeriod(uint periodID) external;

    function claimRewardsForPeriods(uint[] calldata periodIDs) external;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function recordExchangeFeeForAccount(uint usdFeeAmount, address account) external;

    function closeCurrentPeriodWithRewards(uint rewards) external;

    function recoverTokens(address tokenAddress, address recoverAddress) external;

    function recoverUnassignedRewardTokens(address recoverAddress) external;

    function recoverAssignedRewardTokensAndDestroyPeriod(address recoverAddress, uint periodID) external;

    function setPeriodController(address newPeriodController) external;
}


interface IVirtualTribe {
    // Views
    function balanceOfUnderlying(address account) external view returns (uint);

    function rate() external view returns (uint);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function settled() external view returns (bool);

    function tribe() external view returns (ITribe);

    // Mutative functions
    function settle(address account) external;
}


pragma experimental ABIEncoderV2;


// https://docs.tribeone.io/contracts/source/interfaces/iexchanger
interface IExchanger {
    struct ExchangeEntrySettlement {
        bytes32 src;
        uint amount;
        bytes32 dest;
        uint reclaim;
        uint rebate;
        uint srcRoundIdAtPeriodEnd;
        uint destRoundIdAtPeriodEnd;
        uint timestamp;
    }

    struct ExchangeEntry {
        uint sourceRate;
        uint destinationRate;
        uint destinationAmount;
        uint exchangeFeeRate;
        uint exchangeDynamicFeeRate;
        uint roundIdForSrc;
        uint roundIdForDest;
        uint sourceAmountAfterSettlement;
    }

    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint amount,
        uint refunded
    ) external view returns (uint amountAfterSettlement);

    function isTribeRateInvalid(bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries
        );

    function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint);

    function dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint feeRate, bool tooVolatile);

    function getAmountsForExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate
        );

    function priceDeviationThresholdFactor() external view returns (uint);

    function waitingPeriodSecs() external view returns (uint);

    function lastExchangeRate(bytes32 currencyKey) external view returns (uint);

    // Mutative functions
    function exchange(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bool virtualTribe,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualTribe vTribe);

    function exchangeAtomically(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bytes32 trackingCode,
        uint minAmount
    ) external returns (uint amountReceived);

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );
}

// Used to have strongly-typed access to internal mutative functions in Tribeone
interface ITribeoneInternal {
    function emitExchangeTracking(
        bytes32 trackingCode,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        uint256 fee
    ) external;

    function emitTribeExchange(
        address account,
        bytes32 fromCurrencyKey,
        uint fromAmount,
        bytes32 toCurrencyKey,
        uint toAmount,
        address toAddress
    ) external;

    function emitAtomicTribeExchange(
        address account,
        bytes32 fromCurrencyKey,
        uint fromAmount,
        bytes32 toCurrencyKey,
        uint toAmount,
        address toAddress
    ) external;

    function emitExchangeReclaim(
        address account,
        bytes32 currencyKey,
        uint amount
    ) external;

    function emitExchangeRebate(
        address account,
        bytes32 currencyKey,
        uint amount
    ) external;
}

interface IExchangerInternalDebtCache {
    function updateCachedTribeDebtsWithRates(bytes32[] calldata currencyKeys, uint[] calldata currencyRates) external;

    function updateCachedTribeDebts(bytes32[] calldata currencyKeys) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/IDirectIntegration
interface IDirectIntegrationManager {
    struct ParameterIntegrationSettings {
        bytes32 currencyKey;
        address dexPriceAggregator;
        address atomicEquivalentForDexPricing;
        uint atomicExchangeFeeRate;
        uint atomicTwapWindow;
        uint atomicMaxVolumePerBlock;
        uint atomicVolatilityConsiderationWindow;
        uint atomicVolatilityUpdateThreshold;
        uint exchangeFeeRate;
        uint exchangeMaxDynamicFee;
        uint exchangeDynamicFeeRounds;
        uint exchangeDynamicFeeThreshold;
        uint exchangeDynamicFeeWeightDecay;
    }

    function getExchangeParameters(address integration, bytes32 key)
        external
        view
        returns (ParameterIntegrationSettings memory settings);

    function setExchangeParameters(
        address integration,
        bytes32[] calldata currencyKeys,
        ParameterIntegrationSettings calldata params
    ) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint[] calldata roundIds) external view returns (bool);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        );

    function effectiveAtomicValueAndRates(
        IDirectIntegrationManager.ParameterIntegrationSettings calldata sourceSettings,
        uint sourceAmount,
        IDirectIntegrationManager.ParameterIntegrationSettings calldata destinationSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings calldata usdSettings
    )
        external
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        );

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint);

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint numRounds,
        uint roundId
    ) external view returns (uint[] memory rates, uint[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory);

    function tribeTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool);

    function tribeTooVolatileForAtomicExchange(IDirectIntegrationManager.ParameterIntegrationSettings calldata settings)
        external
        view
        returns (bool);

    function rateWithSafetyChecks(bytes32 currencyKey)
        external
        returns (
            uint rate,
            bool broken,
            bool invalid
        );
}


// https://docs.tribeone.io/contracts/source/interfaces/iexchangestate
interface IExchangeState {
    // Views
    struct ExchangeEntry {
        bytes32 src;
        uint amount;
        bytes32 dest;
        uint amountReceived;
        uint exchangeFeeRate;
        uint timestamp;
        uint roundIdForSrc;
        uint roundIdForDest;
    }

    function getLengthOfEntries(address account, bytes32 currencyKey) external view returns (uint);

    function getEntryAt(
        address account,
        bytes32 currencyKey,
        uint index
    )
        external
        view
        returns (
            bytes32 src,
            uint amount,
            bytes32 dest,
            uint amountReceived,
            uint exchangeFeeRate,
            uint timestamp,
            uint roundIdForSrc,
            uint roundIdForDest
        );

    function getMaxTimestamp(address account, bytes32 currencyKey) external view returns (uint);

    // Mutative functions
    function appendExchangeEntry(
        address account,
        bytes32 src,
        uint amount,
        bytes32 dest,
        uint amountReceived,
        uint exchangeFeeRate,
        uint timestamp,
        uint roundIdForSrc,
        uint roundIdForDest
    ) external;

    function removeEntries(address account, bytes32 currencyKey) external;
}


interface IDebtCache {
    // Views

    function cachedDebt() external view returns (uint);

    function cachedTribeDebt(bytes32 currencyKey) external view returns (uint);

    function cacheTimestamp() external view returns (uint);

    function cacheInvalid() external view returns (bool);

    function cacheStale() external view returns (bool);

    function isInitialized() external view returns (bool);

    function currentTribeDebts(bytes32[] calldata currencyKeys)
        external
        view
        returns (
            uint[] memory debtValues,
            uint futuresDebt,
            uint excludedDebt,
            bool anyRateIsInvalid
        );

    function cachedTribeDebts(bytes32[] calldata currencyKeys) external view returns (uint[] memory debtValues);

    function totalNonSnxBackedDebt() external view returns (uint excludedDebt, bool isInvalid);

    function currentDebt() external view returns (uint debt, bool anyRateIsInvalid);

    function cacheInfo()
        external
        view
        returns (
            uint debt,
            uint timestamp,
            bool isInvalid,
            bool isStale
        );

    function excludedIssuedDebts(bytes32[] calldata currencyKeys) external view returns (uint[] memory excludedDebts);

    // Mutative functions

    function updateCachedTribeDebts(bytes32[] calldata currencyKeys) external;

    function updateCachedTribeDebtWithRate(bytes32 currencyKey, uint currencyRate) external;

    function updateCachedTribeDebtsWithRates(bytes32[] calldata currencyKeys, uint[] calldata currencyRates) external;

    function updateDebtCacheValidity(bool currentlyInvalid) external;

    function purgeCachedTribeDebt(bytes32 currencyKey) external;

    function takeDebtSnapshot() external;

    function recordExcludedDebtChange(bytes32 currencyKey, int256 delta) external;

    function updateCachedhUSDDebt(int amount) external;

    function importExcludedIssuedDebts(IDebtCache prevDebtCache, IIssuer prevIssuer) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/itribeetix
interface ITribeone {
    // Views
    function anyTribeOrHAKARateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableTribeCount() external view returns (uint);

    function availableTribes(uint index) external view returns (ITribe);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint);

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function maxIssuableTribes(address issuer) external view returns (uint maxIssuable);

    function remainingIssuableTribes(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function tribes(bytes32 currencyKey) external view returns (ITribe);

    function tribesByAddress(address tribeAddress) external view returns (bytes32);

    function totalIssuedTribes(bytes32 currencyKey) external view returns (uint);

    function totalIssuedTribesExcludeOtherCollateral(bytes32 currencyKey) external view returns (uint);

    function transferableTribeone(address account) external view returns (uint transferable);

    function getFirstNonZeroEscrowIndex(address account) external view returns (uint);

    // Mutative Functions
    function burnTribes(uint amount) external;

    function burnTribesOnBehalf(address burnForAddress, uint amount) external;

    function burnTribesToTarget() external;

    function burnTribesToTargetOnBehalf(address burnForAddress) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithTrackingForInitiator(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithVirtual(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualTribe vTribe);

    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint minAmount
    ) external returns (uint amountReceived);

    function issueMaxTribes() external;

    function issueMaxTribesOnBehalf(address issueForAddress) external;

    function issueTribes(uint amount) external;

    function issueTribesOnBehalf(address issueForAddress, uint amount) external;

    function mint() external returns (bool);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    // Liquidations
    function liquidateDelinquentAccount(address account) external returns (bool);

    function liquidateDelinquentAccountEscrowIndex(address account, uint escrowStartIndex) external returns (bool);

    function liquidateSelf() external returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint amount) external;

    function mintSecondaryRewards(uint amount) external;

    function burnSecondary(address account, uint amount) external;

    function revokeAllEscrow(address account) external;

    function migrateAccountBalances(address account) external returns (uint totalEscrowRevoked, uint totalLiquidBalance);
}


library ExchangeSettlementLib {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    struct ResolvedAddresses {
        IExchangeState exchangeState;
        IExchangeRates exchangeRates;
        ICircuitBreaker circuitBreaker;
        IExchangerInternalDebtCache debtCache;
        IIssuer issuer;
        ITribeone tribeone;
    }

    bytes32 internal constant hUSD = "hUSD";

    function internalSettle(
        ResolvedAddresses calldata resolvedAddresses,
        address from,
        bytes32 currencyKey,
        bool updateCache,
        uint waitingPeriod
    )
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntriesSettled
        )
    {
        require(
            maxSecsLeftInWaitingPeriod(resolvedAddresses.exchangeState, from, currencyKey, waitingPeriod) == 0,
            "Cannot settle during waiting period"
        );

        (uint reclaimAmount, uint rebateAmount, uint entries, IExchanger.ExchangeEntrySettlement[] memory settlements) =
            _settlementOwing(resolvedAddresses, from, currencyKey, waitingPeriod);

        if (reclaimAmount > rebateAmount) {
            reclaimed = reclaimAmount.sub(rebateAmount);
            _reclaim(resolvedAddresses, from, currencyKey, reclaimed);
        } else if (rebateAmount > reclaimAmount) {
            refunded = rebateAmount.sub(reclaimAmount);
            _refund(resolvedAddresses, from, currencyKey, refunded);
        }

        // by checking a reclaim or refund we also check that the currency key is still a valid tribe,
        // as the deviation check will return 0 if the tribe has been removed.
        if (updateCache && (reclaimed > 0 || refunded > 0)) {
            bytes32[] memory key = new bytes32[](1);
            key[0] = currencyKey;
            resolvedAddresses.debtCache.updateCachedTribeDebts(key);
        }

        // emit settlement event for each settled exchange entry
        for (uint i = 0; i < settlements.length; i++) {
            emit ExchangeEntrySettled(
                from,
                settlements[i].src,
                settlements[i].amount,
                settlements[i].dest,
                settlements[i].reclaim,
                settlements[i].rebate,
                settlements[i].srcRoundIdAtPeriodEnd,
                settlements[i].destRoundIdAtPeriodEnd,
                settlements[i].timestamp
            );
        }

        numEntriesSettled = entries;

        // Now remove all entries, even if no reclaim and no rebate
        resolvedAddresses.exchangeState.removeEntries(from, currencyKey);
    }

    function maxSecsLeftInWaitingPeriod(
        IExchangeState exchangeState,
        address account,
        bytes32 currencyKey,
        uint waitingPeriod
    ) public view returns (uint) {
        return _secsLeftInWaitingPeriodForExchange(exchangeState.getMaxTimestamp(account, currencyKey), waitingPeriod);
    }

    function _secsLeftInWaitingPeriodForExchange(uint timestamp, uint waitingPeriod) internal view returns (uint) {
        if (timestamp == 0 || now >= timestamp.add(waitingPeriod)) {
            return 0;
        }

        return timestamp.add(waitingPeriod).sub(now);
    }

    function _reclaim(
        ResolvedAddresses memory resolvedAddresses,
        address from,
        bytes32 currencyKey,
        uint amount
    ) internal {
        // burn amount from user
        resolvedAddresses.issuer.tribes(currencyKey).burn(from, amount);
        ITribeoneInternal(address(resolvedAddresses.tribeone)).emitExchangeReclaim(from, currencyKey, amount);
    }

    function _refund(
        ResolvedAddresses memory resolvedAddresses,
        address from,
        bytes32 currencyKey,
        uint amount
    ) internal {
        // issue amount to user
        resolvedAddresses.issuer.tribes(currencyKey).issue(from, amount);
        ITribeoneInternal(address(resolvedAddresses.tribeone)).emitExchangeRebate(from, currencyKey, amount);
    }

    function hasWaitingPeriodOrSettlementOwing(
        ResolvedAddresses calldata resolvedAddresses,
        address account,
        bytes32 currencyKey,
        uint waitingPeriod
    ) external view returns (bool) {
        if (maxSecsLeftInWaitingPeriod(resolvedAddresses.exchangeState, account, currencyKey, waitingPeriod) != 0) {
            return true;
        }

        (uint reclaimAmount, , , ) = _settlementOwing(resolvedAddresses, account, currencyKey, waitingPeriod);

        return reclaimAmount > 0;
    }

    function settlementOwing(
        ResolvedAddresses calldata resolvedAddresses,
        address account,
        bytes32 currencyKey,
        uint waitingPeriod
    )
        external
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries,
            IExchanger.ExchangeEntrySettlement[] memory
        )
    {
        return _settlementOwing(resolvedAddresses, account, currencyKey, waitingPeriod);
    }

    // Internal function to aggregate each individual rebate and reclaim entry for a tribe
    function _settlementOwing(
        ResolvedAddresses memory resolvedAddresses,
        address account,
        bytes32 currencyKey,
        uint waitingPeriod
    )
        internal
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries,
            IExchanger.ExchangeEntrySettlement[] memory
        )
    {
        // Need to sum up all reclaim and rebate amounts for the user and the currency key
        numEntries = resolvedAddresses.exchangeState.getLengthOfEntries(account, currencyKey);

        // For each unsettled exchange
        IExchanger.ExchangeEntrySettlement[] memory settlements = new IExchanger.ExchangeEntrySettlement[](numEntries);
        for (uint i = 0; i < numEntries; i++) {
            // fetch the entry from storage
            IExchangeState.ExchangeEntry memory exchangeEntry =
                _getExchangeEntry(resolvedAddresses.exchangeState, account, currencyKey, i);

            // determine the last round ids for src and dest pairs when period ended or latest if not over
            (uint srcRoundIdAtPeriodEnd, uint destRoundIdAtPeriodEnd) =
                _getRoundIdsAtPeriodEnd(resolvedAddresses.exchangeRates, exchangeEntry, waitingPeriod);

            // given these round ids, determine what effective value they should have received
            uint amountShouldHaveReceived;
            {
                (uint destinationAmount, , ) =
                    resolvedAddresses.exchangeRates.effectiveValueAndRatesAtRound(
                        exchangeEntry.src,
                        exchangeEntry.amount,
                        exchangeEntry.dest,
                        srcRoundIdAtPeriodEnd,
                        destRoundIdAtPeriodEnd
                    );

                // and deduct the fee from this amount using the exchangeFeeRate from storage
                amountShouldHaveReceived = _deductFeesFromAmount(destinationAmount, exchangeEntry.exchangeFeeRate);
            }

            // SIP-65 settlements where the amount at end of waiting period is beyond the threshold, then
            // settle with no reclaim or rebate
            bool sip65condition =
                resolvedAddresses.circuitBreaker.isDeviationAboveThreshold(
                    exchangeEntry.amountReceived,
                    amountShouldHaveReceived
                );

            uint reclaim;
            uint rebate;

            if (!sip65condition) {
                if (exchangeEntry.amountReceived > amountShouldHaveReceived) {
                    // if they received more than they should have, add to the reclaim tally
                    reclaim = exchangeEntry.amountReceived.sub(amountShouldHaveReceived);
                    reclaimAmount = reclaimAmount.add(reclaim);
                } else if (amountShouldHaveReceived > exchangeEntry.amountReceived) {
                    // if less, add to the rebate tally
                    rebate = amountShouldHaveReceived.sub(exchangeEntry.amountReceived);
                    rebateAmount = rebateAmount.add(rebate);
                }
            }

            settlements[i] = IExchanger.ExchangeEntrySettlement({
                src: exchangeEntry.src,
                amount: exchangeEntry.amount,
                dest: exchangeEntry.dest,
                reclaim: reclaim,
                rebate: rebate,
                srcRoundIdAtPeriodEnd: srcRoundIdAtPeriodEnd,
                destRoundIdAtPeriodEnd: destRoundIdAtPeriodEnd,
                timestamp: exchangeEntry.timestamp
            });
        }

        return (reclaimAmount, rebateAmount, numEntries, settlements);
    }

    function _getExchangeEntry(
        IExchangeState exchangeState,
        address account,
        bytes32 currencyKey,
        uint index
    ) internal view returns (IExchangeState.ExchangeEntry memory) {
        (
            bytes32 src,
            uint amount,
            bytes32 dest,
            uint amountReceived,
            uint exchangeFeeRate,
            uint timestamp,
            uint roundIdForSrc,
            uint roundIdForDest
        ) = exchangeState.getEntryAt(account, currencyKey, index);

        return
            IExchangeState.ExchangeEntry({
                src: src,
                amount: amount,
                dest: dest,
                amountReceived: amountReceived,
                exchangeFeeRate: exchangeFeeRate,
                timestamp: timestamp,
                roundIdForSrc: roundIdForSrc,
                roundIdForDest: roundIdForDest
            });
    }

    function _getRoundIdsAtPeriodEnd(
        IExchangeRates exRates,
        IExchangeState.ExchangeEntry memory exchangeEntry,
        uint waitingPeriod
    ) internal view returns (uint srcRoundIdAtPeriodEnd, uint destRoundIdAtPeriodEnd) {
        srcRoundIdAtPeriodEnd = exRates.getLastRoundIdBeforeElapsedSecs(
            exchangeEntry.src,
            exchangeEntry.roundIdForSrc,
            exchangeEntry.timestamp,
            waitingPeriod
        );
        destRoundIdAtPeriodEnd = exRates.getLastRoundIdBeforeElapsedSecs(
            exchangeEntry.dest,
            exchangeEntry.roundIdForDest,
            exchangeEntry.timestamp,
            waitingPeriod
        );
    }

    function _deductFeesFromAmount(uint destinationAmount, uint exchangeFeeRate)
        internal
        pure
        returns (uint amountReceived)
    {
        amountReceived = destinationAmount.multiplyDecimal(SafeDecimalMath.unit().sub(exchangeFeeRate));
    }

    function appendExchange(
        ResolvedAddresses calldata resolvedAddresses,
        address account,
        bytes32 src,
        uint amount,
        bytes32 dest,
        uint amountReceived,
        uint exchangeFeeRate
    ) external {
        uint roundIdForSrc = resolvedAddresses.exchangeRates.getCurrentRoundId(src);
        uint roundIdForDest = resolvedAddresses.exchangeRates.getCurrentRoundId(dest);
        resolvedAddresses.exchangeState.appendExchangeEntry(
            account,
            src,
            amount,
            dest,
            amountReceived,
            exchangeFeeRate,
            now,
            roundIdForSrc,
            roundIdForDest
        );

        emit ExchangeEntryAppended(
            account,
            src,
            amount,
            dest,
            amountReceived,
            exchangeFeeRate,
            roundIdForSrc,
            roundIdForDest
        );
    }

    // ========== EVENTS ==========
    event ExchangeEntryAppended(
        address indexed account,
        bytes32 src,
        uint256 amount,
        bytes32 dest,
        uint256 amountReceived,
        uint256 exchangeFeeRate,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    );

    event ExchangeEntrySettled(
        address indexed from,
        bytes32 src,
        uint256 amount,
        bytes32 dest,
        uint256 reclaim,
        uint256 rebate,
        uint256 srcRoundIdAtPeriodEnd,
        uint256 destRoundIdAtPeriodEnd,
        uint256 exchangeTimestamp
    );
}


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/proxy
contract Proxy is Owned {
    Proxyable public target;

    constructor(address _owner) public Owned(_owner) {}

    function setTarget(Proxyable _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(_target);
    }

    function _emit(
        bytes calldata callData,
        uint numTopics,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4
    ) external onlyTarget {
        uint size = callData.length;
        bytes memory _callData = callData;

        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi).
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
                case 0 {
                    log0(add(_callData, 32), size)
                }
                case 1 {
                    log1(add(_callData, 32), size, topic1)
                }
                case 2 {
                    log2(add(_callData, 32), size, topic1, topic2)
                }
                case 3 {
                    log3(add(_callData, 32), size, topic1, topic2, topic3)
                }
                case 4 {
                    log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
                }
        }
    }

    // solhint-disable no-complex-fallback
    function() external payable {
        // Mutable call setting Proxyable.messageSender as this is using call not delegatecall
        target.setMessageSender(msg.sender);

        assembly {
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize)

            /* We must explicitly forward ether to the underlying contract as well. */
            let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize)

            if iszero(result) {
                revert(free_ptr, returndatasize)
            }
            return(free_ptr, returndatasize)
        }
    }

    modifier onlyTarget {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/proxyable
contract Proxyable is Owned {
    // This contract should be treated like an abstract contract

    /* The proxy this contract exists behind. */
    Proxy public proxy;

    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */
    address public messageSender;

    constructor(address payable _proxy) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setProxy(address payable _proxy) external onlyOwner {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setMessageSender(address sender) external onlyProxy {
        messageSender = sender;
    }

    modifier onlyProxy {
        _onlyProxy();
        _;
    }

    function _onlyProxy() private view {
        require(Proxy(msg.sender) == proxy, "Only the proxy can call");
    }

    modifier optionalProxy {
        _optionalProxy();
        _;
    }

    function _optionalProxy() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
    }

    modifier optionalProxy_onlyOwner {
        _optionalProxy_onlyOwner();
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _optionalProxy_onlyOwner() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
    }

    event ProxyUpdated(address proxyAddress);
}


// Inheritance


// Libraries


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/exchanger
contract Exchanger is Owned, MixinSystemSettings, IExchanger {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant CONTRACT_NAME = "Exchanger";

    bytes32 internal constant hUSD = "hUSD";

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXCHANGESTATE = "ExchangeState";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_TRIBEONEETIX = "Tribeone";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_TRADING_REWARDS = "TradingRewards";
    bytes32 private constant CONTRACT_DELEGATEAPPROVALS = "DelegateApprovals";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_DEBTCACHE = "DebtCache";
    bytes32 private constant CONTRACT_CIRCUIT_BREAKER = "CircuitBreaker";
    bytes32 private constant CONTRACT_DIRECT_INTEGRATION_MANAGER = "DirectIntegrationManager";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](11);
        newAddresses[0] = CONTRACT_SYSTEMSTATUS;
        newAddresses[1] = CONTRACT_EXCHANGESTATE;
        newAddresses[2] = CONTRACT_EXRATES;
        newAddresses[3] = CONTRACT_TRIBEONEETIX;
        newAddresses[4] = CONTRACT_FEEPOOL;
        newAddresses[5] = CONTRACT_TRADING_REWARDS;
        newAddresses[6] = CONTRACT_DELEGATEAPPROVALS;
        newAddresses[7] = CONTRACT_ISSUER;
        newAddresses[8] = CONTRACT_DEBTCACHE;
        newAddresses[9] = CONTRACT_CIRCUIT_BREAKER;
        newAddresses[10] = CONTRACT_DIRECT_INTEGRATION_MANAGER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function exchangeState() internal view returns (IExchangeState) {
        return IExchangeState(requireAndGetAddress(CONTRACT_EXCHANGESTATE));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function circuitBreaker() internal view returns (ICircuitBreaker) {
        return ICircuitBreaker(requireAndGetAddress(CONTRACT_CIRCUIT_BREAKER));
    }

    function tribeone() internal view returns (ITribeone) {
        return ITribeone(requireAndGetAddress(CONTRACT_TRIBEONEETIX));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function tradingRewards() internal view returns (ITradingRewards) {
        return ITradingRewards(requireAndGetAddress(CONTRACT_TRADING_REWARDS));
    }

    function delegateApprovals() internal view returns (IDelegateApprovals) {
        return IDelegateApprovals(requireAndGetAddress(CONTRACT_DELEGATEAPPROVALS));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function debtCache() internal view returns (IExchangerInternalDebtCache) {
        return IExchangerInternalDebtCache(requireAndGetAddress(CONTRACT_DEBTCACHE));
    }

    function directIntegrationManager() internal view returns (IDirectIntegrationManager) {
        return IDirectIntegrationManager(requireAndGetAddress(CONTRACT_DIRECT_INTEGRATION_MANAGER));
    }

    function resolvedAddresses() internal view returns (ExchangeSettlementLib.ResolvedAddresses memory) {
        return
            ExchangeSettlementLib.ResolvedAddresses(
                exchangeState(),
                exchangeRates(),
                circuitBreaker(),
                debtCache(),
                issuer(),
                tribeone()
            );
    }

    function waitingPeriodSecs() external view returns (uint) {
        return getWaitingPeriodSecs();
    }

    function tradingRewardsEnabled() external view returns (bool) {
        return getTradingRewardsEnabled();
    }

    function priceDeviationThresholdFactor() external view returns (uint) {
        return getPriceDeviationThresholdFactor();
    }

    function lastExchangeRate(bytes32 currencyKey) external view returns (uint) {
        return circuitBreaker().lastValue(address(exchangeRates().aggregators(currencyKey)));
    }

    function settlementOwing(address account, bytes32 currencyKey)
        public
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries
        )
    {
        (reclaimAmount, rebateAmount, numEntries, ) = ExchangeSettlementLib.settlementOwing(
            resolvedAddresses(),
            account,
            currencyKey,
            getWaitingPeriodSecs()
        );
    }

    function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool) {
        return
            ExchangeSettlementLib.hasWaitingPeriodOrSettlementOwing(
                resolvedAddresses(),
                account,
                currencyKey,
                getWaitingPeriodSecs()
            );
    }

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) public view returns (uint) {
        return
            ExchangeSettlementLib._secsLeftInWaitingPeriodForExchange(
                exchangeState().getMaxTimestamp(account, currencyKey),
                getWaitingPeriodSecs()
            );
    }

    /* ========== SETTERS ========== */

    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint amount,
        uint refunded
    ) public view returns (uint amountAfterSettlement) {
        amountAfterSettlement = amount;

        // balance of a tribe will show an amount after settlement
        uint balanceOfSourceAfterSettlement = IERC20(address(issuer().tribes(currencyKey))).balanceOf(from);

        // when there isn't enough supply (either due to reclamation settlement or because the number is too high)
        if (amountAfterSettlement > balanceOfSourceAfterSettlement) {
            // then the amount to exchange is reduced to their remaining supply
            amountAfterSettlement = balanceOfSourceAfterSettlement;
        }

        if (refunded > 0) {
            amountAfterSettlement = amountAfterSettlement.add(refunded);
        }
    }

    function isTribeRateInvalid(bytes32 currencyKey) external view returns (bool) {
        (, bool invalid) = exchangeRates().rateAndInvalid(currencyKey);
        return invalid;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function exchange(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bool virtualTribe,
        address rewardAddress,
        bytes32 trackingCode
    ) external onlyTribeoneorTribe returns (uint amountReceived, IVirtualTribe vTribe) {
        uint fee;
        if (from != exchangeForAddress) {
            require(delegateApprovals().canExchangeFor(exchangeForAddress, from), "Not approved to act on behalf");
        }

        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(from, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(from, destinationCurrencyKey);

        (amountReceived, fee, vTribe) = _exchange(
            exchangeForAddress,
            sourceSettings,
            sourceAmount,
            destinationSettings,
            destinationAddress,
            virtualTribe
        );

        _processTradingRewards(fee, rewardAddress);

        if (trackingCode != bytes32(0)) {
            _emitTrackingEvent(trackingCode, destinationCurrencyKey, amountReceived, fee);
        }
    }

    function exchangeAtomically(
        address,
        bytes32,
        uint,
        bytes32,
        address,
        bytes32,
        uint
    ) external returns (uint) {
        _notImplemented();
    }

    function _emitTrackingEvent(
        bytes32 trackingCode,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        uint256 fee
    ) internal {
        ITribeoneInternal(address(tribeone())).emitExchangeTracking(trackingCode, toCurrencyKey, toAmount, fee);
    }

    function _processTradingRewards(uint fee, address rewardAddress) internal {
        if (fee > 0 && rewardAddress != address(0) && getTradingRewardsEnabled()) {
            tradingRewards().recordExchangeFeeForAccount(fee, rewardAddress);
        }
    }

    function _updateHAKAIssuedDebtOnExchange(bytes32[2] memory currencyKeys, uint[2] memory currencyRates) internal {
        bool includesHUSD = currencyKeys[0] == hUSD || currencyKeys[1] == hUSD;
        uint numKeys = includesHUSD ? 2 : 3;

        bytes32[] memory keys = new bytes32[](numKeys);
        keys[0] = currencyKeys[0];
        keys[1] = currencyKeys[1];

        uint[] memory rates = new uint[](numKeys);
        rates[0] = currencyRates[0];
        rates[1] = currencyRates[1];

        if (!includesHUSD) {
            keys[2] = hUSD; // And we'll also update hUSD to account for any fees if it wasn't one of the exchanged currencies
            rates[2] = SafeDecimalMath.unit();
        }

        // Note that exchanges can't invalidate the debt cache, since if a rate is invalid,
        // the exchange will have failed already.
        debtCache().updateCachedTribeDebtsWithRates(keys, rates);
    }

    function _settleAndCalcSourceAmountRemaining(
        uint sourceAmount,
        address from,
        bytes32 sourceCurrencyKey
    ) internal returns (uint sourceAmountAfterSettlement) {
        (, uint refunded, uint numEntriesSettled) =
            ExchangeSettlementLib.internalSettle(
                resolvedAddresses(),
                from,
                sourceCurrencyKey,
                false,
                getWaitingPeriodSecs()
            );

        sourceAmountAfterSettlement = sourceAmount;

        // when settlement was required
        if (numEntriesSettled > 0) {
            // ensure the sourceAmount takes this into account
            sourceAmountAfterSettlement = calculateAmountAfterSettlement(from, sourceCurrencyKey, sourceAmount, refunded);
        }
    }

    function _exchange(
        address from,
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        uint sourceAmount,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings,
        address destinationAddress,
        bool virtualTribe
    )
        internal
        returns (
            uint amountReceived,
            uint fee,
            IVirtualTribe vTribe
        )
    {
        if (!_ensureCanExchange(sourceSettings.currencyKey, destinationSettings.currencyKey, sourceAmount)) {
            return (0, 0, IVirtualTribe(0));
        }

        // Using struct to resolve stack too deep error
        IExchanger.ExchangeEntry memory entry;
        ExchangeSettlementLib.ResolvedAddresses memory addrs = resolvedAddresses();

        entry.roundIdForSrc = addrs.exchangeRates.getCurrentRoundId(sourceSettings.currencyKey);
        entry.roundIdForDest = addrs.exchangeRates.getCurrentRoundId(destinationSettings.currencyKey);

        entry.sourceAmountAfterSettlement = _settleAndCalcSourceAmountRemaining(
            sourceAmount,
            from,
            sourceSettings.currencyKey
        );

        // If, after settlement the user has no balance left (highly unlikely), then return to prevent
        // emitting events of 0 and don't revert so as to ensure the settlement queue is emptied
        if (entry.sourceAmountAfterSettlement == 0) {
            return (0, 0, IVirtualTribe(0));
        }

        (entry.destinationAmount, entry.sourceRate, entry.destinationRate) = addrs
            .exchangeRates
            .effectiveValueAndRatesAtRound(
            sourceSettings.currencyKey,
            entry.sourceAmountAfterSettlement,
            destinationSettings.currencyKey,
            entry.roundIdForSrc,
            entry.roundIdForDest
        );

        // rates must also be good for the round we are doing
        _ensureCanExchangeAtRound(
            sourceSettings.currencyKey,
            destinationSettings.currencyKey,
            entry.roundIdForSrc,
            entry.roundIdForDest
        );

        bool tooVolatile;
        (entry.exchangeFeeRate, tooVolatile) = _feeRateForExchangeAtRounds(
            sourceSettings,
            destinationSettings,
            entry.roundIdForSrc,
            entry.roundIdForDest
        );

        if (tooVolatile) {
            // do not exchange if rates are too volatile, this to prevent charging
            // dynamic fees that are over the max value
            return (0, 0, IVirtualTribe(0));
        }

        amountReceived = ExchangeSettlementLib._deductFeesFromAmount(entry.destinationAmount, entry.exchangeFeeRate);
        // Note: `fee` is denominated in the destinationCurrencyKey.
        fee = entry.destinationAmount.sub(amountReceived);

        // Note: We don't need to check their balance as the _convert() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if their balance is not sufficient.
        vTribe = _convert(
            sourceSettings.currencyKey,
            from,
            entry.sourceAmountAfterSettlement,
            destinationSettings.currencyKey,
            amountReceived,
            destinationAddress,
            virtualTribe
        );

        // When using a virtual tribe, it becomes the destinationAddress for event and settlement tracking
        if (vTribe != IVirtualTribe(0)) {
            destinationAddress = address(vTribe);
        }

        // Remit the fee if required
        if (fee > 0) {
            // Normalize fee to hUSD
            // Note: `fee` is being reused to avoid stack too deep errors.
            fee = addrs.exchangeRates.effectiveValue(destinationSettings.currencyKey, fee, hUSD);

            // Remit the fee in hUSDs
            issuer().tribes(hUSD).issue(feePool().FEE_ADDRESS(), fee);

            // Tell the fee pool about this
            feePool().recordFeePaid(fee);
        }

        // Note: As of this point, `fee` is denominated in hUSD.

        // Nothing changes as far as issuance data goes because the total value in the system hasn't changed.
        // But we will update the debt snapshot in case exchange rates have fluctuated since the last exchange
        // in these currencies
        _updateHAKAIssuedDebtOnExchange(
            [sourceSettings.currencyKey, destinationSettings.currencyKey],
            [entry.sourceRate, entry.destinationRate]
        );

        // Let the DApps know there was a Tribe exchange
        ITribeoneInternal(address(tribeone())).emitTribeExchange(
            from,
            sourceSettings.currencyKey,
            entry.sourceAmountAfterSettlement,
            destinationSettings.currencyKey,
            amountReceived,
            destinationAddress
        );

        // iff the waiting period is gt 0
        if (getWaitingPeriodSecs() > 0) {
            // persist the exchange information for the dest key
            ExchangeSettlementLib.appendExchange(
                addrs,
                destinationAddress,
                sourceSettings.currencyKey,
                entry.sourceAmountAfterSettlement,
                destinationSettings.currencyKey,
                amountReceived,
                entry.exchangeFeeRate
            );
        }
    }

    function _convert(
        bytes32 sourceCurrencyKey,
        address from,
        uint sourceAmountAfterSettlement,
        bytes32 destinationCurrencyKey,
        uint amountReceived,
        address recipient,
        bool virtualTribe
    ) internal returns (IVirtualTribe vTribe) {
        // Burn the source amount
        issuer().tribes(sourceCurrencyKey).burn(from, sourceAmountAfterSettlement);

        // Issue their new tribes
        ITribe dest = issuer().tribes(destinationCurrencyKey);

        if (virtualTribe) {
            Proxyable tribe = Proxyable(address(dest));
            vTribe = _createVirtualTribe(IERC20(address(tribe.proxy())), recipient, amountReceived, destinationCurrencyKey);
            dest.issue(address(vTribe), amountReceived);
        } else {
            dest.issue(recipient, amountReceived);
        }
    }

    function _createVirtualTribe(
        IERC20,
        address,
        uint,
        bytes32
    ) internal returns (IVirtualTribe) {
        _notImplemented();
    }

    // Note: this function can intentionally be called by anyone on behalf of anyone else (the caller just pays the gas)
    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntriesSettled
        )
    {
        systemStatus().requireTribeActive(currencyKey);
        return ExchangeSettlementLib.internalSettle(resolvedAddresses(), from, currencyKey, true, getWaitingPeriodSecs());
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // gets the exchange parameters for a given direct integration (returns default params if no overrides exist)
    function _exchangeSettings(address from, bytes32 currencyKey)
        internal
        view
        returns (IDirectIntegrationManager.ParameterIntegrationSettings memory settings)
    {
        settings = directIntegrationManager().getExchangeParameters(from, currencyKey);
    }

    // runs basic checks and calls `rateWithSafetyChecks` (which can trigger circuit breakers)
    // returns if there are any problems found with the rate of the given currencyKey but not reverted
    function _ensureCanExchange(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey,
        uint sourceAmount
    ) internal returns (bool) {
        require(sourceCurrencyKey != destinationCurrencyKey, "Can't be same tribe");
        require(sourceAmount > 0, "Zero amount");

        (, bool srcBroken, bool srcStaleOrInvalid) =
            sourceCurrencyKey != hUSD ? exchangeRates().rateWithSafetyChecks(sourceCurrencyKey) : (0, false, false);
        (, bool dstBroken, bool dstStaleOrInvalid) =
            destinationCurrencyKey != hUSD
                ? exchangeRates().rateWithSafetyChecks(destinationCurrencyKey)
                : (0, false, false);

        require(!srcStaleOrInvalid, "src rate stale or flagged");
        require(!dstStaleOrInvalid, "dest rate stale or flagged");

        return !srcBroken && !dstBroken;
    }

    // runs additional checks to verify a rate is valid at a specific round`
    function _ensureCanExchangeAtRound(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    ) internal view {
        require(sourceCurrencyKey != destinationCurrencyKey, "Can't be same tribe");

        bytes32[] memory tribeKeys = new bytes32[](2);
        tribeKeys[0] = sourceCurrencyKey;
        tribeKeys[1] = destinationCurrencyKey;

        uint[] memory roundIds = new uint[](2);
        roundIds[0] = roundIdForSrc;
        roundIds[1] = roundIdForDest;
        require(!exchangeRates().anyRateIsInvalidAtRound(tribeKeys, roundIds), "src/dest rate stale or flagged");
    }

    /* ========== Exchange Related Fees ========== */
    /// @notice public function to get the total fee rate for a given exchange
    /// @param sourceCurrencyKey The source currency key
    /// @param destinationCurrencyKey The destination currency key
    /// @return The exchange fee rate, and whether the rates are too volatile
    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint) {
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(msg.sender, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(msg.sender, destinationCurrencyKey);

        (uint feeRate, bool tooVolatile) = _feeRateForExchange(sourceSettings, destinationSettings);
        require(!tooVolatile, "too volatile");
        return feeRate;
    }

    /// @notice public function to get the dynamic fee rate for a given exchange
    /// @param sourceCurrencyKey The source currency key
    /// @param destinationCurrencyKey The destination currency key
    /// @return The exchange dynamic fee rate and if rates are too volatile
    function dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint feeRate, bool tooVolatile)
    {
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(msg.sender, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(msg.sender, destinationCurrencyKey);

        return _dynamicFeeRateForExchange(sourceSettings, destinationSettings);
    }

    /// @notice Calculate the exchange fee for a given source and destination currency key
    /// @param sourceSettings The source currency key
    /// @param destinationSettings The destination currency key
    /// @return The exchange fee rate
    /// @return The exchange dynamic fee rate and if rates are too volatile
    function _feeRateForExchange(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings
    ) internal view returns (uint feeRate, bool tooVolatile) {
        // Get the exchange fee rate as per the source currencyKey and destination currencyKey
        uint baseRate = sourceSettings.exchangeFeeRate.add(destinationSettings.exchangeFeeRate);
        uint dynamicFee;
        (dynamicFee, tooVolatile) = _dynamicFeeRateForExchange(sourceSettings, destinationSettings);
        return (baseRate.add(dynamicFee), tooVolatile);
    }

    /// @notice Calculate the exchange fee for a given source and destination currency key
    /// @param sourceSettings The source currency key
    /// @param destinationSettings The destination currency key
    /// @param roundIdForSrc The round id of the source currency.
    /// @param roundIdForDest The round id of the target currency.
    /// @return The exchange fee rate
    /// @return The exchange dynamic fee rate
    function _feeRateForExchangeAtRounds(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings,
        uint roundIdForSrc,
        uint roundIdForDest
    ) internal view returns (uint feeRate, bool tooVolatile) {
        // Get the exchange fee rate as per the source currencyKey and destination currencyKey
        uint baseRate = sourceSettings.exchangeFeeRate.add(destinationSettings.exchangeFeeRate);
        uint dynamicFee;
        (dynamicFee, tooVolatile) = _dynamicFeeRateForExchangeAtRounds(
            sourceSettings,
            destinationSettings,
            roundIdForSrc,
            roundIdForDest
        );
        return (baseRate.add(dynamicFee), tooVolatile);
    }

    function _dynamicFeeRateForExchange(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings
    ) internal view returns (uint dynamicFee, bool tooVolatile) {
        (uint dynamicFeeDst, bool dstVolatile) = _dynamicFeeRateForCurrency(destinationSettings);
        (uint dynamicFeeSrc, bool srcVolatile) = _dynamicFeeRateForCurrency(sourceSettings);
        dynamicFee = dynamicFeeDst.add(dynamicFeeSrc);
        // cap to maxFee
        bool overMax = dynamicFee > sourceSettings.exchangeMaxDynamicFee;
        dynamicFee = overMax ? sourceSettings.exchangeMaxDynamicFee : dynamicFee;
        return (dynamicFee, overMax || dstVolatile || srcVolatile);
    }

    function _dynamicFeeRateForExchangeAtRounds(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings,
        uint roundIdForSrc,
        uint roundIdForDest
    ) internal view returns (uint dynamicFee, bool tooVolatile) {
        (uint dynamicFeeDst, bool dstVolatile) = _dynamicFeeRateForCurrencyRound(destinationSettings, roundIdForDest);
        (uint dynamicFeeSrc, bool srcVolatile) = _dynamicFeeRateForCurrencyRound(sourceSettings, roundIdForSrc);
        dynamicFee = dynamicFeeDst.add(dynamicFeeSrc);
        // cap to maxFee
        bool overMax = dynamicFee > sourceSettings.exchangeMaxDynamicFee;
        dynamicFee = overMax ? sourceSettings.exchangeMaxDynamicFee : dynamicFee;
        return (dynamicFee, overMax || dstVolatile || srcVolatile);
    }

    /// @notice Get dynamic dynamicFee for a given currency key (SIP-184)
    /// @param settings The given currency key
    /// @return The dynamic fee and if it exceeds max dynamic fee set in config
    function _dynamicFeeRateForCurrency(IDirectIntegrationManager.ParameterIntegrationSettings memory settings)
        internal
        view
        returns (uint dynamicFee, bool tooVolatile)
    {
        // no dynamic dynamicFee for hUSD or too few rounds
        if (settings.currencyKey == hUSD || settings.exchangeDynamicFeeRounds <= 1) {
            return (0, false);
        }
        uint roundId = exchangeRates().getCurrentRoundId(settings.currencyKey);
        return _dynamicFeeRateForCurrencyRound(settings, roundId);
    }

    /// @notice Get dynamicFee for a given currency key (SIP-184)
    /// @param settings The given currency key
    /// @param roundId The round id
    /// @return The dynamic fee and if it exceeds max dynamic fee set in config
    function _dynamicFeeRateForCurrencyRound(
        IDirectIntegrationManager.ParameterIntegrationSettings memory settings,
        uint roundId
    ) internal view returns (uint dynamicFee, bool tooVolatile) {
        // no dynamic dynamicFee for hUSD or too few rounds
        if (settings.currencyKey == hUSD || settings.exchangeDynamicFeeRounds <= 1) {
            return (0, false);
        }
        uint[] memory prices;
        (prices, ) = exchangeRates().ratesAndUpdatedTimeForCurrencyLastNRounds(
            settings.currencyKey,
            settings.exchangeDynamicFeeRounds,
            roundId
        );
        dynamicFee = _dynamicFeeCalculation(
            prices,
            settings.exchangeDynamicFeeThreshold,
            settings.exchangeDynamicFeeWeightDecay
        );
        // cap to maxFee
        bool overMax = dynamicFee > settings.exchangeMaxDynamicFee;
        dynamicFee = overMax ? settings.exchangeMaxDynamicFee : dynamicFee;
        return (dynamicFee, overMax);
    }

    /// @notice Calculate dynamic fee according to SIP-184
    /// @param prices A list of prices from the current round to the previous rounds
    /// @param threshold A threshold to clip the price deviation ratop
    /// @param weightDecay A weight decay constant
    /// @return uint dynamic fee rate as decimal
    function _dynamicFeeCalculation(
        uint[] memory prices,
        uint threshold,
        uint weightDecay
    ) internal pure returns (uint) {
        // don't underflow
        if (prices.length == 0) {
            return 0;
        }

        uint dynamicFee = 0; // start with 0
        // go backwards in price array
        for (uint i = prices.length - 1; i > 0; i--) {
            // apply decay from previous round (will be 0 for first round)
            dynamicFee = dynamicFee.multiplyDecimal(weightDecay);
            // calculate price deviation
            uint deviation = _thresholdedAbsDeviationRatio(prices[i - 1], prices[i], threshold);
            // add to total fee
            dynamicFee = dynamicFee.add(deviation);
        }
        return dynamicFee;
    }

    /// absolute price deviation ratio used by dynamic fee calculation
    /// deviationRatio = (abs(current - previous) / previous) - threshold
    /// if negative, zero is returned
    function _thresholdedAbsDeviationRatio(
        uint price,
        uint previousPrice,
        uint threshold
    ) internal pure returns (uint) {
        if (previousPrice == 0) {
            return 0; // don't divide by zero
        }
        // abs difference between prices
        uint absDelta = price > previousPrice ? price - previousPrice : previousPrice - price;
        // relative to previous price
        uint deviationRatio = absDelta.divideDecimal(previousPrice);
        // only the positive difference from threshold
        return deviationRatio > threshold ? deviationRatio - threshold : 0;
    }

    function getAmountsForExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate
        )
    {
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(msg.sender, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(msg.sender, destinationCurrencyKey);

        require(sourceCurrencyKey == hUSD || !exchangeRates().rateIsInvalid(sourceCurrencyKey), "src tribe rate invalid");

        require(
            destinationCurrencyKey == hUSD || !exchangeRates().rateIsInvalid(destinationCurrencyKey),
            "dest tribe rate invalid"
        );

        // The checks are added for consistency with the checks performed in _exchange()
        // The reverts (instead of no-op returns) are used order to prevent incorrect usage in calling contracts
        // (The no-op in _exchange() is in order to trigger system suspension if needed)

        // check tribes active
        systemStatus().requireTribeActive(sourceCurrencyKey);
        systemStatus().requireTribeActive(destinationCurrencyKey);

        bool tooVolatile;
        (exchangeFeeRate, tooVolatile) = _feeRateForExchange(sourceSettings, destinationSettings);

        // check rates volatility result
        require(!tooVolatile, "exchange rates too volatile");

        (uint destinationAmount, , ) =
            exchangeRates().effectiveValueAndRates(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

        amountReceived = ExchangeSettlementLib._deductFeesFromAmount(destinationAmount, exchangeFeeRate);
        fee = destinationAmount.sub(amountReceived);
    }

    function _notImplemented() internal pure {
        revert("Cannot be run on this layer");
    }

    // ========== MODIFIERS ==========

    modifier onlyTribeoneorTribe() {
        ITribeone _tribeetix = tribeone();
        require(
            msg.sender == address(_tribeetix) || _tribeetix.tribesByAddress(msg.sender) != bytes32(0),
            "Exchanger: Only tribeone or a tribe contract can perform this action"
        );
        _;
    }

    // ========== EVENTS ==========
    // note bot hof these events are actually emitted from `ExchangeSettlementLib`
    // but they are defined here for interface reasons
    event ExchangeEntryAppended(
        address indexed account,
        bytes32 src,
        uint256 amount,
        bytes32 dest,
        uint256 amountReceived,
        uint256 exchangeFeeRate,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    );

    event ExchangeEntrySettled(
        address indexed from,
        bytes32 src,
        uint256 amount,
        bytes32 dest,
        uint256 reclaim,
        uint256 rebate,
        uint256 srcRoundIdAtPeriodEnd,
        uint256 destRoundIdAtPeriodEnd,
        uint256 exchangeTimestamp
    );
}


// https://docs.tribeone.io/contracts/source/contracts/minimalproxyfactory
contract MinimalProxyFactory {
    function _cloneAsMinimalProxy(address _base, string memory _revertMsg) internal returns (address clone) {
        bytes memory createData = _generateMinimalProxyCreateData(_base);

        assembly {
            clone := create(
                0, // no value
                add(createData, 0x20), // data
                55 // data is always 55 bytes (10 constructor + 45 code)
            )
        }

        // If CREATE fails for some reason, address(0) is returned
        require(clone != address(0), _revertMsg);
    }

    function _generateMinimalProxyCreateData(address _base) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                //---- constructor -----
                bytes10(0x3d602d80600a3d3981f3),
                //---- proxy code -----
                bytes10(0x363d3d373d3d3d363d73),
                _base,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );
    }
}


// Inheritance


// Internal references


interface IVirtualTribeInternal {
    function initialize(
        IERC20 _tribe,
        IAddressResolver _resolver,
        address _recipient,
        uint _amount,
        bytes32 _currencyKey
    ) external;
}

// https://docs.tribeone.io/contracts/source/contracts/exchangerwithfeereclamationalternatives
contract ExchangerWithFeeRecAlternatives is MinimalProxyFactory, Exchanger {
    bytes32 public constant CONTRACT_NAME = "ExchangerWithFeeRecAlternatives";

    using SafeMath for uint;

    struct ExchangeVolumeAtPeriod {
        uint64 time;
        uint192 volume;
    }

    ExchangeVolumeAtPeriod public lastAtomicVolume;

    constructor(address _owner, address _resolver) public MinimalProxyFactory() Exchanger(_owner, _resolver) {}

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_VIRTUALTRIBEONE_MASTERCOPY = "VirtualTribeMastercopy";

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = Exchanger.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_VIRTUALTRIBEONE_MASTERCOPY;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    /* ========== VIEWS ========== */

    function atomicMaxVolumePerBlock() external view returns (uint) {
        return getAtomicMaxVolumePerBlock();
    }

    function feeRateForAtomicExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint exchangeFeeRate)
    {
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(msg.sender, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(msg.sender, destinationCurrencyKey);
        exchangeFeeRate = _feeRateForAtomicExchange(sourceSettings, destinationSettings);
    }

    function getAmountsForAtomicExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate
        )
    {
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(msg.sender, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(msg.sender, destinationCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory usdSettings = _exchangeSettings(msg.sender, hUSD);

        (amountReceived, fee, exchangeFeeRate, , , ) = _getAmountsForAtomicExchangeMinusFees(
            sourceAmount,
            sourceSettings,
            destinationSettings,
            usdSettings
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function exchangeAtomically(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bytes32 trackingCode,
        uint minAmount
    ) external onlyTribeoneorTribe returns (uint amountReceived) {
        uint fee;
        (amountReceived, fee) = _exchangeAtomically(
            from,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            destinationAddress
        );

        require(amountReceived >= minAmount, "The amount received is below the minimum amount specified.");

        _processTradingRewards(fee, destinationAddress);

        if (trackingCode != bytes32(0)) {
            _emitTrackingEvent(trackingCode, destinationCurrencyKey, amountReceived, fee);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _virtualTribeMastercopy() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_VIRTUALTRIBEONE_MASTERCOPY);
    }

    function _createVirtualTribe(
        IERC20 tribe,
        address recipient,
        uint amount,
        bytes32 currencyKey
    ) internal returns (IVirtualTribe) {
        // prevent inverse tribes from being allowed due to purgeability
        require(currencyKey[0] != 0x69, "Cannot virtualize this tribe");

        IVirtualTribeInternal vTribe =
            IVirtualTribeInternal(_cloneAsMinimalProxy(_virtualTribeMastercopy(), "Could not create new vTribe"));
        vTribe.initialize(tribe, resolver, recipient, amount, currencyKey);
        emit VirtualTribeCreated(address(tribe), recipient, address(vTribe), currencyKey, amount);

        return IVirtualTribe(address(vTribe));
    }

    function _exchangeAtomically(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress
    ) internal returns (uint amountReceived, uint fee) {
        uint sourceAmountAfterSettlement;
        uint exchangeFeeRate;
        uint systemSourceRate;
        uint systemDestinationRate;

        {
            IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
                _exchangeSettings(from, sourceCurrencyKey);
            IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
                _exchangeSettings(from, destinationCurrencyKey);

            if (!_ensureCanExchange(sourceCurrencyKey, destinationCurrencyKey, sourceAmount)) {
                return (0, 0);
            }
            require(!exchangeRates().tribeTooVolatileForAtomicExchange(sourceSettings), "Src tribe too volatile");
            require(!exchangeRates().tribeTooVolatileForAtomicExchange(destinationSettings), "Dest tribe too volatile");

            sourceAmountAfterSettlement = _settleAndCalcSourceAmountRemaining(sourceAmount, from, sourceCurrencyKey);

            // If, after settlement the user has no balance left (highly unlikely), then return to prevent
            // emitting events of 0 and don't revert so as to ensure the settlement queue is emptied
            if (sourceAmountAfterSettlement == 0) {
                return (0, 0);
            }

            // sometimes we need parameters for USD and USD has parameters which could be overridden
            IDirectIntegrationManager.ParameterIntegrationSettings memory usdSettings = _exchangeSettings(from, hUSD);

            uint systemConvertedAmount;

            // Note: also ensures the given tribes are allowed to be atomically exchanged
            (
                amountReceived, // output amount with fee taken out (denominated in dest currency)
                fee, // fee amount (denominated in dest currency)
                exchangeFeeRate, // applied fee rate
                systemConvertedAmount, // current system value without fees (denominated in dest currency)
                systemSourceRate, // current system rate for src currency
                systemDestinationRate // current system rate for dest currency
            ) = _getAmountsForAtomicExchangeMinusFees(
                sourceAmountAfterSettlement,
                sourceSettings,
                destinationSettings,
                usdSettings
            );

            // Sanity check atomic output's value against current system value (checking atomic rates)
            require(
                !circuitBreaker().isDeviationAboveThreshold(systemConvertedAmount, amountReceived.add(fee)),
                "Atomic rate deviates too much"
            );

            // Determine hUSD value of exchange
            uint sourceSusdValue;
            if (sourceCurrencyKey == hUSD) {
                // Use after-settled amount as this is amount converted (not sourceAmount)
                sourceSusdValue = sourceAmountAfterSettlement;
            } else if (destinationCurrencyKey == hUSD) {
                // In this case the systemConvertedAmount would be the fee-free hUSD value of the source tribe
                sourceSusdValue = systemConvertedAmount;
            } else {
                // Otherwise, convert source to hUSD value
                (uint amountReceivedInUSD, uint sUsdFee, , , , ) =
                    _getAmountsForAtomicExchangeMinusFees(
                        sourceAmountAfterSettlement,
                        sourceSettings,
                        usdSettings,
                        usdSettings
                    );
                sourceSusdValue = amountReceivedInUSD.add(sUsdFee);
            }

            // Check and update atomic volume limit
            _checkAndUpdateAtomicVolume(sourceSettings, sourceSusdValue);
        }

        // Note: We don't need to check their balance as the _convert() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if their balance is not sufficient.

        _convert(
            sourceCurrencyKey,
            from,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress,
            false // no vtribes
        );

        // Remit the fee if required
        if (fee > 0) {
            // Normalize fee to hUSD
            // Note: `fee` is being reused to avoid stack too deep errors.
            fee = exchangeRates().effectiveValue(destinationCurrencyKey, fee, hUSD);

            // Remit the fee in hUSDs
            issuer().tribes(hUSD).issue(feePool().FEE_ADDRESS(), fee);

            // Tell the fee pool about this
            feePool().recordFeePaid(fee);
        }

        // Note: As of this point, `fee` is denominated in hUSD.

        // Note: this update of the debt snapshot will not be accurate because the atomic exchange
        // was executed with a different rate than the system rate. To be perfect, issuance data,
        // priced in system rates, should have been adjusted on the src and dest tribe.
        // The debt pool is expected to be deprecated soon, and so we don't bother with being
        // perfect here. For now, an inaccuracy will slowly accrue over time with increasing atomic
        // exchange volume.
        _updateHAKAIssuedDebtOnExchange(
            [sourceCurrencyKey, destinationCurrencyKey],
            [systemSourceRate, systemDestinationRate]
        );

        // Let the DApps know there was a Tribe exchange
        ITribeoneInternal(address(tribeone())).emitTribeExchange(
            from,
            sourceCurrencyKey,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress
        );

        // Emit separate event to track atomic exchanges
        ITribeoneInternal(address(tribeone())).emitAtomicTribeExchange(
            from,
            sourceCurrencyKey,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress
        );

        // No need to persist any exchange information, as no settlement is required for atomic exchanges
    }

    function _checkAndUpdateAtomicVolume(
        IDirectIntegrationManager.ParameterIntegrationSettings memory settings,
        uint sourceSusdValue
    ) internal {
        uint currentVolume =
            uint(lastAtomicVolume.time) == block.timestamp
                ? uint(lastAtomicVolume.volume).add(sourceSusdValue)
                : sourceSusdValue;
        require(currentVolume <= settings.atomicMaxVolumePerBlock, "Surpassed volume limit");
        lastAtomicVolume.time = uint64(block.timestamp);
        lastAtomicVolume.volume = uint192(currentVolume); // Protected by volume limit check above
    }

    function _feeRateForAtomicExchange(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings
    ) internal view returns (uint) {
        // Get the exchange fee rate as per source and destination currencyKey
        uint baseRate = sourceSettings.atomicExchangeFeeRate.add(destinationSettings.atomicExchangeFeeRate);
        if (baseRate == 0) {
            // If no atomic rate was set, fallback to the regular exchange rate
            baseRate = sourceSettings.exchangeFeeRate.add(destinationSettings.exchangeFeeRate);
        }

        return baseRate;
    }

    function _getAmountsForAtomicExchangeMinusFees(
        uint sourceAmount,
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory usdSettings
    )
        internal
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate,
            uint systemConvertedAmount,
            uint systemSourceRate,
            uint systemDestinationRate
        )
    {
        uint destinationAmount;
        (destinationAmount, systemConvertedAmount, systemSourceRate, systemDestinationRate) = exchangeRates()
            .effectiveAtomicValueAndRates(sourceSettings, sourceAmount, destinationSettings, usdSettings);

        exchangeFeeRate = _feeRateForAtomicExchange(sourceSettings, destinationSettings);
        amountReceived = ExchangeSettlementLib._deductFeesFromAmount(destinationAmount, exchangeFeeRate);
        fee = destinationAmount.sub(amountReceived);
    }

    event VirtualTribeCreated(
        address indexed tribe,
        address indexed recipient,
        address vTribe,
        bytes32 currencyKey,
        uint amount
    );
}