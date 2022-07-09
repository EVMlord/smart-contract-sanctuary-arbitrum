// SPDX-License-Identifier: UNLICENSED
// Author: @stevieraykatz
// https://github.com/coinlander/Coinlander

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISeekers.sol";
import "./interfaces/IVault.sol";
// import "hardhat/console.sol";

/*

      /@@@#       &@@@@    /@@     @&@@@@@    ,@@            [email protected]@@,     @@@@@@@     @@,[email protected]@@        &@@@@     @@@@@@@   
   @@   @@@,   /@(  @@@&   @@@   @@@&  @@@@   @@@          @@   @@@   @@@@  @@@@   @@@   @@@    (@(  @@@&  @@@@  @@@@  
  @@@   @@&   @@@(  @@@&   @@@   @@@&  @@@@   @@@         @@@   @@@   @@@@  @@@@   @@@   @@@   @@@(  @     @@@@  @@@@  
  @@@         @@@(  @@@&   @@@   @@@&  @@@@   @@@         @@@   @@@   @@@@  @@@@   @@@   @@@   @@@(        @@@@  @@    
  @@@         @@@(  @@@&   @@@   @@@&  @@@@   @@@         @@@&  @@@   @@@@  @@@@   @@@   @@@   @@@@@&      @@@@ @@@    
  @@@         @@@(  @@@&   @@@   @@@&  @@@@   @@@         @@@   @@@   @@@@  @@@@   @@@   @@@   @@@(        @@@@  @@@@  
  @@@         @@@(  @@@&   @@@   @@@&  @@@@   @@@         @@@   @@@   @@@@  @@@@   @@@   @@@   @@@(        @@@@  @@@@  
  @@@     @,  @@@(  @@@&   @@@   @@@&  @@@@   @@@         @@@   @@@   @@@@  @@@@   @@@   @@@   @@@(    @&  @@@@  @@@@  
  @@@   @@@,  @@@(  @@@&   @@@   @@@&  @@@@   @@@   *@@   @@@   @@@   @@@@  @@@@   @@@   @@@   @@@(  @@@&  @@@@  @@@@  
  @@@   @@@,  @@@(  @@@&   @@@   @@@&  @@@@   @@@   @@@   @@@   @@@   @@@@  @@@@   @@@   @@@   @@@(  @@@&  @@@@  @@@@  
  @@@   @     @@@(  @      @@@   @@@&  @@@@   @@@   @     @@@   @@@   @@@@  @@@@   @@@   @     @@@(  @     @@@@  @@@@  
    @@#         @@@%       @     @@    @@      ,@@.%      @     @,    @@    @@      *@@%^        @@@       @@    @@    
            
*/

contract SeasonOne is ERC1155, Ownable, ReentrancyGuard {

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                        INIT SHIT                                             //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////
    // Coin IDs
    uint256 public constant ONECOIN = 0;
    uint256 public constant SHARD = 1;

    string private _contractURI;

    // COINLANDER PARAMETERS
    address public COINLANDER;
    bool public released = false;
    bool public shardSpendable = false;
    bool private transferIsSteal = false;
    bool public gameStarted = false;
    bool public firstCommunitySoftLock = true;
    bool public secondCommunitySoftLock = true;
    uint32 public lastSeizureTime = 0;
     
    using Counters for Counters.Counter;
    Counters.Counter public seizureCount; 

    // GAME CONSTANTS
    uint256 public constant FIRSTCOMMUNITYSOFTLOCK = 111; // discord user lock
    uint256 public constant SECONDCOMMUNITYSOFTLOCK = 222; // twitter follower lock
    uint256 public constant FIRSTSEEKERMINTTHRESH = 333;
    uint256 public constant CLOAKINGTHRESH = 444;
    uint256 public constant SHARDSPENDABLE = 555;
    uint256 public constant SECONDSEEKERMINTTHRESH = 666;
    uint256 public constant THIRDSEEKERMINTTHRESH = 777;
    uint256 public constant GOODSONLYEND = 888;
    uint256 public constant CLOINRELEASE = 999;
    uint256 public constant SWEETRELEASE = 1111;

    // ECONOMIC CONSTANTS  
    uint256 public constant PERCENTRATEINCREASE = 60; // 0.6% increase for each successive seizure 
    uint256 public constant PERCENTPRIZE = 100; // 1.0% of take goes to prize pool     
    uint256 constant PERCENTBASIS = 10000;
    
    // ECONOMIC STATE VARS 
    // uint256 public seizureStake = 5 * 10**16; // First price for Coinlander 0.05Eth
    uint256 public seizureStake = 5 * 10**12; // test value
    uint256 private previousSeizureStake = 0; 
    uint256 public prize = 0; // Prize pool balance
    uint256 private keeperShardsMinted = 0;

    // SHARD CONSTANTS
    uint256 constant KEEPERSHARDS = 111; // Keepers can mint up to 100 shards for community rewards
    uint256 constant SEEKERSHARDDROP = 1; // At least one shard to each Seeker holder 
    uint256 constant SHARDDROPRAND = 4; // Up to 3 additional shard drops (used as mod, so add 1)
    uint256 constant POWERPERSHARD = 8; // Eight power units per Shard 
    uint256 public constant SHARDTOFRAGMENTMULTIPLIER = 5; // One fragment per 5 Shards 
    uint256 constant BASESHARDREWARD = 1; // 1 Shard guaranteed per seizure
    uint256 constant INCRSHARDREWARD = 5; // .5 Eth/Shard
    uint256 constant INCRBASIS = 10; //

    // BALANCES AND ECONOMIC PARAMETERS 
    // Refund structure, tracks Eth withdraw value, earned Shard and owed Seekers 
    // value can be safely stored as a uint120
    // each seeker owed will have a unique time associated with it
    struct withdrawParams {
        uint120 _withdrawValue;
        uint16 _shardOwed;
        uint32[] _timeHeld;
    } 

    mapping(address => withdrawParams) public pendingWithdrawals;
    mapping(uint256 => bool) public claimedAirdropBySeekerId;
    mapping(address => bool) public hasBeenCoinlander;

    struct cloinDeposit {
        address depositor; 
        uint16 amount;
        uint80 blockNumber;
    }
    cloinDeposit[] public cloinDeposits;

    ISeekers public seekers; 
    IVault private vault;

    event SweetRelease(address winner);
    event Seized(address previousOwner, address newOwner, 
            uint256 seizurePrice, uint256 nextSeizurePrice, 
            uint256 currentPrize, uint256 seizureNumber);
    event ShardSpendable();
    event NewCloinDeposit(address depositor, uint16 amount, uint256 depositIdx);
    event ClaimedAll(address claimer);
    event AirdropClaim(uint256 id);
    
    //@TODO we need to figure out what the url schema for metadata looks like and plop that here in the constructor
    constructor(address seekersContract, address keepeersVault) ERC1155("https://api.coinlander.dev/meta/season-one/{id}") {
        // Create the One Coin and set the deployer as initial COINLANDER
        _mint(msg.sender, ONECOIN, 1, "0x0");
        COINLANDER = msg.sender;

        // Add interface for seekers contract 
        seekers = ISeekers(seekersContract);
        vault = IVault(keepeersVault);

        // Set contract uri 
        //@Todo change this to a real endpoint
        _contractURI = "https://api.coinlander.dev/meta/season-one";
    }

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                          MODIFIERS                                           //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////

    modifier postReleaseOnly() {
        require(released == true, "E-000-004");
        _;
    }

    modifier shardSpendableOnly() {
        require(shardSpendable == true, "E-000-005");
        _;
    }

    modifier validShardQty(uint256 amount) {
        require(amount > 0, "E-000-006");
        require(balanceOf(msg.sender, SHARD) >= amount, "E-000-007");
        _;
    }
    


//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                       TOKEN OVERRIDES                                        //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // No constraints post release 
        if (!released) {
            // Check the id arry for One Coin 
            for (uint i=0; i < ids.length; i++){
                // If One Coin transfer is being attempted, check constraints 
                if (ids[i] == ONECOIN){
                    if (from != address(0) && !transferIsSteal) {
                        revert("E-000-004");
                    }
                } 
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
    function _stealTransfer(address holder, address newOwner) internal {
        transferIsSteal = true;
        _safeTransferFrom(holder, newOwner, ONECOIN, 1, "0x0"); // There is only 1 
        transferIsSteal = false;
        if (!released) {
            COINLANDER = newOwner;
        }
    }

    function changeURI(string calldata _newURI) external onlyOwner {
        _setURI(_newURI);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }



//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                  COINLANDER GAME LOGIC                                       //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////

    function seize() external payable nonReentrant {
        require(gameStarted, "E-000-013");
        require(released == false, "E-000-001");
        require(msg.value == seizureStake, "E-000-002");
        require(msg.sender != COINLANDER, "E-000-003");
        //@TODO turn this back on for launch, off for testing 
        //require(!hasBeenCoinlander[msg.sender], "E-000-014");

        address previousOwner = COINLANDER;
        address newOwner = msg.sender;
        hasBeenCoinlander[newOwner] = true;
        
        seizureCount.increment();

        // Perform the steal
        _stealTransfer(previousOwner, newOwner);

        // Establish rewards and refunds 
        _processPaymentsAndRewards(previousOwner, previousSeizureStake);

        emit Seized(previousOwner, newOwner, msg.value, seizureStake, prize, seizureCount.current());

        // Trigger game events if price is worthy 
        _processGameEvents();
    }


    function _processPaymentsAndRewards(address previousOwner, uint256 value) internal {

        // Track time regardless of which count 
        uint32 holdTime = uint32(block.timestamp) - lastSeizureTime;
        lastSeizureTime = uint32(block.timestamp);

        // Exclude first seizure since deployer doesnt get rewards
        if (seizureCount.current() != 1) {

            // Set aside funds for prize pool
            uint256 _prize = (value * PERCENTPRIZE) / PERCENTBASIS;
            prize += _prize; 

            uint256 deposit = value - _prize;
            pendingWithdrawals[previousOwner]._withdrawValue += uint120(deposit);

            uint16 shardReward = _calculateShardReward(previousSeizureStake);
            pendingWithdrawals[previousOwner]._shardOwed += shardReward;
        }
            
        // Handle all cases except the last; the winner seeker is special cased
        if (!released) {

            // We allocate a seeker for every previous Coinlander and track the time of each hold. 
            pendingWithdrawals[previousOwner]._timeHeld.push(holdTime);

            // Store current seizure as previous
            previousSeizureStake = seizureStake;
            // Determine what it will cost to seize next time
            seizureStake = seizureStake + ((seizureStake * PERCENTRATEINCREASE) / PERCENTBASIS);
        }
    }

    // Autonomous game events triggered by Coinlander seizure count 
    function _processGameEvents() internal {
        uint256 count = seizureCount.current();

        if (count == FIRSTCOMMUNITYSOFTLOCK) {
            if (firstCommunitySoftLock) {
                gameStarted = false;
            }
        }

        if (count == SECONDCOMMUNITYSOFTLOCK) {
            if (secondCommunitySoftLock) {
                gameStarted = false;
            }
        }

        if (count == FIRSTSEEKERMINTTHRESH) {
            seekers.activateFirstMint();
        }

        if (count == SECONDSEEKERMINTTHRESH) {
            seekers.activateSecondMint();
        }

        if (count == THIRDSEEKERMINTTHRESH) {
            seekers.activateThirdMint();
        }

        if (count == GOODSONLYEND) {
            seekers.endGoodsOnly();
        }

        if (count > THIRDSEEKERMINTTHRESH) {
            seekers.seizureMintIncrement();
        }

        if (count == CLOAKINGTHRESH) {
            seekers.performCloakingCeremony();
        }

        if (count == SHARDSPENDABLE) {
            shardSpendable = true; 
            emit ShardSpendable();
        }

        if (count == SWEETRELEASE) {
            _triggerRelease();
        }
    }

    function _triggerRelease() internal {
        released = true;
        emit SweetRelease(msg.sender);

        // Process rewards and refund for the winner 
        _processPaymentsAndRewards(msg.sender,msg.value);

        // Send prize purse to keepers vault
        vault.fundPrizePurse{value: prize}();
        vault.setSweetRelease();
        prize = 0;

        // Send winning Seeker to winner  
        seekers.sendWinnerSeeker(msg.sender);
    }

    function getSeizureCount() external view returns(uint256) {
        return seizureCount.current();
    }


//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                  IN IT TO WIN IT -- SHARD LYFE                               //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////

    function burnShardForPower(uint256 seekerId, uint256 amount) 
        external 
        nonReentrant 
        shardSpendableOnly 
        validShardQty(amount) {

        _burn(msg.sender, SHARD, amount);
        uint256 power = amount * POWERPERSHARD;
        seekers.addPower(seekerId, power);
    }

    function stakeShardForCloin(uint256 amount) 
        external 
        nonReentrant 
        shardSpendableOnly
        validShardQty(amount) {

        _burn(msg.sender, SHARD, amount);
        
        cloinDeposit memory _deposit;
        _deposit.depositor = msg.sender;
        _deposit.amount = uint16(amount);
        _deposit.blockNumber = uint80(block.number); 
        
        cloinDeposits.push(_deposit);
        uint256 depositsLength = cloinDeposits.length;
        emit NewCloinDeposit(msg.sender, uint16(amount), depositsLength);
    }

    function burnShardForFragments(uint256 amount) 
        external 
        nonReentrant 
        shardSpendableOnly 
        validShardQty(amount) {

        require((amount % SHARDTOFRAGMENTMULTIPLIER) == 0, "E-000-008"); // must be even multiple of the exch. rate
    
        uint256 fragmentReward = amount / SHARDTOFRAGMENTMULTIPLIER; 
        _burn(msg.sender, SHARD, amount);
        vault.requestFragments(msg.sender, fragmentReward);
    }

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                  MAGIC INTERNET MONEY BUSINESS                               //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////

    // Method for claiming all owed rewards and payments: ether refunds, shards and seekers 
    // @todo change seeks logic to times length 
    function claimAll() external nonReentrant {

        uint256 withdrawal = pendingWithdrawals[msg.sender]._withdrawValue;
        uint256 shard = pendingWithdrawals[msg.sender]._shardOwed;
        uint256 seeks = pendingWithdrawals[msg.sender]._timeHeld.length;

        if (withdrawal == 0 && shard == 0 && seeks == 0) {
            revert("E-000-010");
        }

        if (withdrawal > 0) {
            pendingWithdrawals[msg.sender]._withdrawValue = 0;
            (bool success, ) = msg.sender.call{value:withdrawal}("");
            require(success, "E-000-009");
        }

        if (shard > 0) {
            pendingWithdrawals[msg.sender]._shardOwed = 0;
            _mint(msg.sender, SHARD, shard, "0x0");

        }

        if (seeks > 0) {

            // Mint seekers 
            for (uint256 i = 0; i < seeks; i++){
                // uint32 holdTime = times[i];
                uint32 holdTime = pendingWithdrawals[msg.sender]._timeHeld[i];
                seekers.birthSeeker(msg.sender, holdTime);
            }
            delete pendingWithdrawals[msg.sender]._timeHeld;
        }

        emit ClaimedAll(msg.sender);
    }

    // Claim seeker release valve if too many in withdraw struct
    function claimSingleSeeker() external nonReentrant {
        uint256 seeks = pendingWithdrawals[msg.sender]._timeHeld.length;
        require(seeks > 0, "E-000-010");

        // Cant pop directly into holdTime since the compiler doesnt know if _timeHeld will have a nonzero length
        uint32 holdTime = pendingWithdrawals[msg.sender]._timeHeld[seeks - 1];
        pendingWithdrawals[msg.sender]._timeHeld.pop();

        seekers.birthSeeker(msg.sender, holdTime);
    }
    
    function airdropClaimBySeekerId(uint256 id) external nonReentrant postReleaseOnly {
        require(seekers.ownerOf(id) == msg.sender, "E-000-011");
        require(!claimedAirdropBySeekerId[id], "E-000-012");
        claimedAirdropBySeekerId[id] = true;
        uint256 amount;
        uint256 r1 = _getRandomNumber(SHARDDROPRAND, id);
        uint256 r2 = _getRandomNumber(SHARDDROPRAND, r1);
        amount = SEEKERSHARDDROP + r1 + r2;
        emit AirdropClaim(id);
        _mint(msg.sender, SHARD, amount, "0x0");
    }

    function keeperShardMint(uint256 amount) external onlyOwner {
        require((keeperShardsMinted + amount) <= KEEPERSHARDS);
        require(amount > 0);

        keeperShardsMinted += amount; 
        _mint(msg.sender, SHARD, amount, "0x0");
    }

    function startGame() external onlyOwner {
        gameStarted = true;
    }
    
    function disableFirstCommunitySoftLock() external onlyOwner {
        firstCommunitySoftLock = false;
    }

    function disableSecondCommunitySoftLock() external onlyOwner {
        secondCommunitySoftLock = false;
    }

    function _calculateShardReward(uint256 _value) private pure returns (uint16) {
        uint256 reward = BASESHARDREWARD;
        // @todo need a test multiplier for shard reward
        reward += ((_value * 10**4)/10**18) * INCRBASIS / INCRSHARDREWARD;
        // reward += (_value/10**18) * INCRBASIS / INCRSHARDREWARD;
        return uint16(reward);  
    }

    function _getRandomNumber(uint256 mod, uint256 r) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
            abi.encodePacked(
                mod,
                r,
                blockhash(block.number - 1),
                gasleft(),
                block.timestamp,
                msg.sender
                )));
        return random % mod;
    }

// @todo return length of times array 
    function getPendingWithdrawal(address _user) external view returns (uint256[3] memory) {
        return [
            uint256(pendingWithdrawals[_user]._withdrawValue),
            uint256(pendingWithdrawals[_user]._shardOwed),
            pendingWithdrawals[_user]._timeHeld.length
        ];
    }

    function getAirdropStatus(uint256 _id) external view returns (bool) {
        return claimedAirdropBySeekerId[_id];
    }

    // If someone messes up and pays us without using the seize method, revert 
    receive() external payable {
        revert("E-000-009");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Author: @stevieraykatz
// https://github.com/coinlander/Coinlander

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard extended for compatibiltiy with Seekers
 * @dev External Seekers.sol methods made available to inheriting contracts
 */

interface ISeekers is IERC721Enumerable {
    event FirstMintActivated();
    event SecondMintActivated();
    event ThirdMintActivated();
    event CloakingAvailable();
    event SeekerCloaked(uint256 indexed seekerId);
    event DethscalesRerolled(uint256 id);
    event PowerAdded(uint256 indexed seekerId, uint256 powerAdded, uint256 newPower);
    event PowerBurned(uint256 indexed seekerId, uint256 powerBurned, uint256 newPower);
    event SeekerDeclaredToClan(uint256 indexed seekerId, address indexed clan);


    function summonSeeker(uint256 summonCount) external payable;
    function birthSeeker(address to, uint32 holdTime) external returns (uint256);
    function keepersSummonSeeker(uint256 summonCount) external;
    function activateFirstMint() external;
    function activateSecondMint() external;
    function activateThirdMint() external;
    function seizureMintIncrement() external;
    function endGoodsOnly() external;
    function performCloakingCeremony() external;
    function sendWinnerSeeker(address winner) external;
    function cloakSeeker(uint256 id) external;
    function rerollDethscales(uint256 id) external;
    function addPower(uint256 id, uint256 powerToAdd) external;
    function burnPower(uint256 id, uint16 powerToBurn) external;
    function declareForClan(uint id, address clanAddress) external;
    function ownerWithdraw() external payable;

    /**
    * @dev Externally callable methods for Seeker attributes
    */
    function getOriginById(uint256 id) external view returns (bool);
    function getAlignmentById(uint256 id) external view returns (string memory);
    function getApById(uint256 id) external view returns (uint8[4] memory);
    function getPowerById(uint256 id) external view returns (uint16);
    function getClanById(uint256 id) external view returns (address);
    function getDethscalesById(uint256 id) external view returns (uint16);
    function getCloakStatusById(uint256 id) external view returns (bool);
    function getFullCloak(uint256 id) external view returns (uint32[32] memory);
}

// SPDX-License-Identifier: UNLICENSED
// Author: @stevieraykatz
// https://github.com/coinlander/Coinlander

pragma solidity ^0.8.10;

// @TODO investigate EIP-712 for external method calls 

interface IVault {

    event VaultUnlocked(address winner);
    event RandomnessOracleChanged(address currentOracle, address newOracle);
    event RandomnessRequested(address requester, uint16 requestId);
    event RandomnessFulfilled(uint16 requestId, uint16 result);
    function requestFragments(address _requester, uint256 amount) external;
    function setSweetRelease() external;
    function claimKeepersVault() external;
    function fundPrizePurse() payable external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}