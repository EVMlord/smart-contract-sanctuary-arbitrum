// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract RatelNFT is ERC721A, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20; 
  using SafeMath for uint;
  using Counters for Counters.Counter;

  // event
  event OnBabyMarketItemCreated (
    uint indexed itemId,
    uint indexed babyId,
    address seller,
    uint price
  );
  event OnRatelBreed(
    uint babyId, 
    uint generation, 
    uint maleTokenId, 
    uint femaleTokenId
  );
  event OnBabySold(
    address seller, 
    address owner, 
    uint babyId, 
    uint price
  );
  event OnCancelOrder(
    address seller, 
    uint babyId
  );
  event OnTakeGrownupRatel(
    uint father_tokenId, 
    uint mother_tokenId, 
    uint generation,
    uint babyId,
    uint tokenId
  );

  event Claim(address indexed to, uint256 amount);

  Counters.Counter internal token_Ids; //
  Counters.Counter internal _itemIds; // will increment token ids when minting new tokens.
  Counters.Counter internal _itemsSold; 

  uint internal constant FATHER = 0;
  uint internal constant MOTHER = 1;
  uint internal constant MAX_BREED_COUNT = 5; 
  uint internal constant FIVE_DAY_SECONDS = 30; //TODO 432000;

  // price for pre sale stage (0.3 ETH)
  uint internal preSalePrice = 0.003 ether; //TODO 0.3 ether;

  // price for publicsale stage (0.4 ETH)
  uint internal publicSalePrice =  0.004 ether;  //TODO 0.4 ether;

  // fee for take grownup rate
  uint internal takeGrownupFee = 0.02 ether;

  // fee(HRGT) for breed  
  uint internal breedFee = 60000 * (10**6);

  uint256 internal _teamTotal = 600;

  // max airdrop  quota allowed
  uint internal maxAirdropCount = 400;

  // max presale quota allowed
  uint internal maxPrivateSale = 3000;

  // max supply NFT 
  uint public maxSupply = 10000;

  enum MintMode {ADMINMINT, AIRDROP, PRESALE, PUBLICSALE, BREED}

  uint internal chainlinkFee = 1 * 10**18; // 1 LINK token
  
  uint256 internal mintedByOwner = 0; //team
  uint internal _totalAirdrop;     //airdrop
  uint internal _totalPrivateSale; //total of presale 
  uint internal _totalPublicSale;  //total of pubsale
  uint internal _totalBreed;       //total of baby
  uint internal MAX_SALE_USER_AMOUNT = 3000; 

  //flag for admin mint
  bool public adminmint = false; 

  //flag for airdrop
  bool public airdrop = false; 

  // flag for pre sale
  bool public preSale = false; 

  // flag for publicsale
  bool public publicSale = false;

  // flag for contract online status
  bool public isOnline = false;

  struct Baby {
        uint father_tokenId;
        uint mother_tokenId;
        uint generation;
        uint birthTime;
  }

  Baby[] private babies;

  mapping (uint => address) private babyToOwner;
  mapping (address => uint) private ownerBabyCount;
  mapping(address => bool) private babyOwner; 
  mapping(address => uint) private saleMintedLimits;
  mapping(uint => mapping(uint => uint)) private parents;                                                         
  mapping(uint => uint) private breedCounts;

  uint internal maleTotal;
  uint internal femaleTotal;

  uint internal level2_rand;      
  uint internal level3_rand;       
  uint internal count_level_2 = 0;  
  uint internal count_level_3 = 0; 

  string  nftName = "Metaverse Ratel NFT";
  bytes32 internal airdrop_merkleRoot;
  bytes32 internal preSale_merkleRoot;

    /// @notice Mapping of addresses who have claimed tokens
  mapping(address => bool) internal hasClaimed;
  
  struct Character {
      uint strength; 
      uint dexterity; 
      uint luck; 
      uint defense;
      uint wisdom;
      uint attack;
      uint gender;
      string name; 
      uint generation;
  }

  mapping(uint => Character) internal characters;

  uint internal randomResult; 
  bytes32 internal requestId_;

  mapping(uint => uint) internal tokenIdToSeed; 

  mapping(address => uint) lastBlockNumberCalled;

  IERC20 internal ratelGameToken;

  address marketContractAddress;

  address payable private multiSigWalletAddress;

  /// ============ Errors ============
  /// @notice Thrown if address has already claimed
  error AlreadyClaimed();

  constructor(IERC20 _hrgt_token) 
        ERC721A("Metaverse Ratel NFT", "RATELNFT") 
  {
      ratelGameToken = _hrgt_token;
  }

  receive() external payable {}

  fallback() external payable {}
  
  /***
    * @dev ensure contract is online
    */
  modifier online() {
      require(isOnline, "Contract must be online.");
      _;
  }

  /**
    * @dev ensure contract is offline
    */
  modifier offline() {
      require(!isOnline, "Contract must be offline.");
      _;
  }

  /**
    * @dev ensure caller is not contract 
    */
  modifier onlyNonContract() {
      _onlyNonContract();
      _;
  }

  function _onlyNonContract() internal view {
      require(tx.origin == _msgSender(), "ONC");
  }

  /**
    * @dev ensure caller is not one block 
    */
  modifier oncePerBlock(address user) {
      _oncePerBlock(user);
      _;
  }

  function _oncePerBlock(address user) internal {
      require(lastBlockNumberCalled[user] < block.number, "OCB");
      lastBlockNumberCalled[user] = block.number;
  }

  /**
    * @dev ensure collector pays for breed an cub
    */
  modifier breedable(uint maleTokenId, uint femaleTokenId) {
      require(_msgSender() == ownerOf(maleTokenId), "Male owner error.");
      require(_msgSender() == ownerOf(femaleTokenId), "Female owner error.");
      _;
  }


  /**
    * @dev set MultiSigWalletAddress
    * @notice only owner can call this method
    */
  function setMultiSigWalletAddress(address _multiSigWalletAddress) public onlyOwner {
      multiSigWalletAddress = payable(_multiSigWalletAddress);
  }

  function setMarketContractAddress(address _marketContractAddress) public onlyOwner {
      marketContractAddress = _marketContractAddress;
  }

  /**
    * @dev change status from online to offline and vice versa
    * @notice only owner can call this method
    */
  function toggleActive() public onlyOwner returns (bool) {
      isOnline = !isOnline;
      return true;
  }

  /**
    * @dev change sale stage to private sale and PublicSale
    * @notice only owner can call this method
    */
  function toggleModeChange(uint flag) public onlyOwner returns (bool) {
      if (flag == 0) adminmint = !adminmint;
      if (flag == 1) airdrop = !airdrop;
      if (flag == 2) preSale = !preSale;
      if (flag == 3) publicSale = !publicSale;
      return true;
  }

  function baseURI() public view  returns (string memory) {
        return _baseURI();
  }

  function getTokenURI(uint256 tokenId) public view  returns (string memory) {
        return tokenURI(tokenId);
  }
    
  //Call this method after contract depolyed
  function requestRandomNumber(      
        uint256 seed,
        uint256 salt,
        uint256 sugar
    ) public onlyOwner returns (bool) {
      randomResult = uint256(keccak256(abi.encodePacked(block.timestamp, seed, salt, sugar)));
      return true;
  }
  
  /**
   * @dev mint a NFT for address: _to
   */
  function _mint(address _to, uint _level, uint _quantity, uint babyId) internal returns(uint) {

    uint tokenId;
    for (uint i=0; i< _quantity; i++) {
      tokenId = _generateCharacters(_level, babyId);
    }

    saleMintedLimits[_to] += _quantity;

    _safeMint(_to, _quantity); //ERC721A

    setApprovalForAll(marketContractAddress, true);

    return tokenId;

  }


  function getMintMode() public view returns(MintMode) {
    if (adminmint) return MintMode.ADMINMINT; //0
    if (airdrop) return MintMode.AIRDROP;  //1
    if (preSale) return MintMode.PRESALE; //2
    if (publicSale) return MintMode.PUBLICSALE; //3
    return MintMode.BREED; // 4
  }


  function _generateCharacters(uint level, uint babyId) 
    internal 
    returns(uint)
  {
   //start with 0
    uint newId = token_Ids.current();
    token_Ids.increment();

    uint base = 40;
    uint generation = 1;
    uint gender = 0;
    uint rand = 20;
    
    if (maleTotal * 6 >= femaleTotal * 4 )  {
        gender = 0;
        femaleTotal++;
    } else {
        gender = 1;
        maleTotal++;
    }

    if (getMintMode() == MintMode.BREED) {
      if (level==0) {
        base = 40;
        rand = 60;
      } else {
        base = (level+1) * 20;
      }
      parents[newId][FATHER] = babies[babyId].father_tokenId;
      parents[newId][MOTHER] = babies[babyId].mother_tokenId;
      generation = babies[babyId].generation;

      randomResult = uint(keccak256(abi.encode(randomResult, tokenIdToSeed[babies[babyId].father_tokenId], tokenIdToSeed[babies[babyId].mother_tokenId])));

    } else if (getMintMode() == MintMode.ADMINMINT) {
        randomResult = uint(keccak256(abi.encode(block.timestamp, block.number, randomResult)));
        base = (level+1) * 20;
    } else if (getMintMode() == MintMode.AIRDROP) {
        randomResult = uint(keccak256(abi.encode(block.timestamp, block.number, randomResult)));
        base = 40;
    } else {
        randomResult = uint(keccak256(abi.encode(block.timestamp, block.number, randomResult)));

        if (level2_rand == 0) {
          level2_rand = uint(keccak256(abi.encode(randomResult, 6))) % 3 + 8 ; //8-10
        }
        if (level3_rand == 0) {
          level3_rand = uint(keccak256(abi.encode(randomResult, 7))) % 20 + 180; //180-199
        }

        if (((newId+1) % level2_rand == 0 && count_level_2 < 950) || (level == 2)) {
              base = 60;
              count_level_2 +=1;
              level2_rand = 0; 
        }

        if (( (newId+1) % level3_rand == 0 && count_level_3 < 50 ) || (level == 3)) {
              base = 80;
              count_level_3 +=1;
              level3_rand = 0; 
        }
    }

    uint strength = uint(keccak256(abi.encode(randomResult, 1))) % rand + base;  
    uint dexterity = uint(keccak256(abi.encode(randomResult, 2))) % rand + base; 
    uint luck = uint(keccak256(abi.encode(randomResult, 3))) % rand + base;      
    uint defense = uint(keccak256(abi.encode(randomResult, 4))) % rand + base;   
    uint wisdom = uint(keccak256(abi.encode(randomResult, 5))) % rand + base;    
    uint attack = uint(keccak256(abi.encode(randomResult, 6))) % rand + base;    

    characters[newId] = Character(
              strength,
              dexterity,
              luck,
              defense,
              wisdom,
              attack,
              gender,
              nftName,
              generation
          );

    tokenIdToSeed[newId] = randomResult; 

    return newId;
  }

  function preSaleMint(bytes32[] calldata _merkleProof, uint256 _quantity)
        public
        payable
        offline
        onlyNonContract
  {
      require(getMintMode() == MintMode.PRESALE, "presale is not active");   
      require(msg.value == preSalePrice.mul(_quantity) , "Payment error.");
      require(_quantity<=2, "Max 2 nfts could be minted");
      require(
            _msgSender() != owner(),
            "This function can only be called by an outsider"
      );
      require(saleMintedLimits[_msgSender()] + _quantity <= MAX_SALE_USER_AMOUNT, "Max sale amount exceeded.");
      require(_totalPrivateSale + _quantity <= maxPrivateSale, "Cannot oversell");
      require(_merkleProof.length>0, "_merkleProof is empty");
      require(preSale_merkleRoot != bytes32(0), "preSale merkleRoot not set");
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(
          MerkleProof.verify(_merkleProof, preSale_merkleRoot, leaf),
          "Not in whitelisted"
      );
      uint256 supply = totalSupply();
      require(
          supply + _quantity <= maxSupply,
          "max NFT limit exceeded, Try minting less NFTs"
      );

      _totalPrivateSale += _quantity;

      _mint(_msgSender(), 0, _quantity, 0);

      payable(address(this)).transfer(msg.value);

  }

  function pubSaleMint(uint _quantity) 
    public 
    payable 
    offline 
    onlyNonContract  
  {
    require(getMintMode() == MintMode.PUBLICSALE, "public sale is not active");   
    require(msg.value == publicSalePrice.mul(_quantity) , "Payment error.");
    require(saleMintedLimits[_msgSender()] + 1 <= MAX_SALE_USER_AMOUNT, "Max sale amount exceeded.");
    require(_teamTotal + _totalAirdrop + _totalPrivateSale + _totalPublicSale + 1 <= maxSupply, "Max publicsale amount exceeded.");
  
    payable(address(this)).transfer(msg.value);

    _totalPublicSale += _quantity;
    
    _mint(_msgSender(), 0, _quantity, 0);
  }

  function claim(bytes32[] calldata _merkleProof)
        external
        offline
        onlyNonContract
  {
      require(getMintMode() == MintMode.AIRDROP, "Airdrop is not active");   
      require(
            _msgSender() != owner(),
            "This function can only be called by an outsider"
      );
      require(saleMintedLimits[_msgSender()] + 1 <= MAX_SALE_USER_AMOUNT, "Max sale amount exceeded.");
      require(_totalAirdrop <= maxAirdropCount, "Max airdrop count exceeded");
      
      // Throw if address has already claimed tokens
      if (hasClaimed[_msgSender()]) revert AlreadyClaimed();
     
      // Set address to claimed
      hasClaimed[_msgSender()] = true;

      _totalAirdrop += 1;
      require(_merkleProof.length>0, "_merkleProof is empty");
      require(airdrop_merkleRoot != bytes32(0), "airdrop merkleRoot not set");
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(
          MerkleProof.verify(_merkleProof, airdrop_merkleRoot, leaf),
          "Not in whitelisted"
      );
      uint256 supply = totalSupply();
      require(
          supply + 1 <= maxSupply,
          "max NFT limit exceeded, Try minting less NFTs"
      );

      _mint(_msgSender(), 0, 1, 0);

      // Emit claim event
      emit Claim(_msgSender(), 1);
  }

  function adminMint(uint level, address[] memory receivers, uint[] memory counts)
    external
    onlyOwner
    returns (bool) 
  {
    require(level > 0, "level must between 1-3");
    require(counts.length==receivers.length, "two array length is not equal");
    require(counts.length<=200, "length must less than 200");
    if (getMintMode() == MintMode.ADMINMINT) {
        require(
            mintedByOwner + counts.length <= _teamTotal,
            "Owner's NFT quota Ended"
        );
        mintedByOwner += counts.length;
    }
          
    for(uint i = 0; i < receivers.length; i++) {
        _mint(receivers[i], level, counts[i], 0);
    }
    return true;
  }

  function setPreSaleMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        preSale_merkleRoot = _merkleRoot;
  }

  function setAirdropMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        airdrop_merkleRoot = _merkleRoot;
  }

  function totalPrivateSale() public view returns(uint) {
    return _totalPrivateSale;
  }

  function totalPublicSale() public view returns(uint) {
    return _totalPublicSale;
  }

  function totalBreed() public view returns(uint) {
    return _totalBreed;
  }


  function getGender(uint tokenId) public view returns (uint) {
      return characters[tokenId].gender;
  }

  function getGeneration(uint tokenId) public view returns (uint) {
      return characters[tokenId].generation;
  }

  function getNumberOfCharacters() public view returns (uint) {
      return token_Ids.current();
  }

  function getCharacterOverView(uint tokenId)
      public
      view
      returns (
          string memory,
          uint,
          uint,
          uint
      )
  {
      return (
          characters[tokenId].name,
          characters[tokenId].strength + characters[tokenId].dexterity + characters[tokenId].luck + characters[tokenId].defense + characters[tokenId].wisdom + characters[tokenId].attack,
          characters[tokenId].gender,
          characters[tokenId].generation
      );
  }

  function getCharacterStats(uint tokenId)
      public
      view
      returns (
          uint,
          uint,
          uint,
          uint,
          uint,
          uint,
          uint
      )
  {
      return (
          characters[tokenId].strength,
          characters[tokenId].dexterity,
          characters[tokenId].luck,
          characters[tokenId].defense,
          characters[tokenId].wisdom,
          characters[tokenId].attack,
          characters[tokenId].gender
      );
  }

  function getRatelFamily(uint tokenId) 
    public 
    view 
    returns(uint, uint, uint) 
  {
     return  (
       parents[tokenId][FATHER],
       parents[tokenId][MOTHER],
       characters[tokenId].generation
     );
  }

  function getRatelListByOwner(address owner) 
    public 
    view 
    returns (uint[] memory) 
  {
      uint count = balanceOf(owner);
      uint[] memory result = new uint[](count);
      uint counter = 0;
      for (uint i = 1; i < token_Ids.current() + 1; i++) {
          if (ownerOf(i) == owner) {
              result[counter] = i;
              counter++;
          }
      }
      return result;
  }
  
  function getBabyInfo(uint babyId) 
    public
    view
    returns(address, uint, uint, uint, uint) 
  {
    return (
      babyToOwner[babyId],
      babies[babyId].father_tokenId,
      babies[babyId].mother_tokenId,
      babies[babyId].generation, 
      babies[babyId].birthTime
    );
  }

  function getBabyOwnCount(address addr) 
    public 
    view 
    returns(uint) 
  {
    if (babyOwner[addr] == false) return 0;
    return ownerBabyCount[addr];
  }

  function getBabiesByOwner(address owner) 
    public 
    view 
    returns (uint[] memory) 
  {
      uint[] memory result = new uint[](ownerBabyCount[owner]);
      uint counter = 0;
      for (uint i = 0; i < babies.length; i++) {
          if (babyToOwner[i] == owner) {
              result[counter] = i;
              counter++;
          }
      }
      return result;
  }

 function residualBreedCount(uint tokenId)
    public 
    view 
    returns(uint)
 {
   return MAX_BREED_COUNT - breedCounts[tokenId];
 }
 
  function getBreedFee(uint maleTokenId, uint femaleTokenId) 
    public 
    view 
    returns(uint)
  {
    uint breedFee1 = breedFee.mul( breedCounts[maleTokenId].add(1));
    uint breedFee2 = breedFee.mul( breedCounts[femaleTokenId].add(1));
    return breedFee1.add(breedFee2);
  }

  function breed(uint maleTokenId, uint femaleTokenId)
    public 
    online
    breedable(maleTokenId, femaleTokenId)
    nonReentrant
    returns(bool)
  {
    require(characters[maleTokenId].gender == 1, "Father not male");
    require(characters[femaleTokenId].gender == 0, "Mother not female");

    uint father1; 
    uint mother1; 
    uint generation1; 
    (father1, mother1, generation1)= getRatelFamily(maleTokenId);

    uint father2; 
    uint mother2;
    uint generation2;
    (father2, mother2, generation2)= getRatelFamily(femaleTokenId);

    require(generation1 == generation2, "Different generation error");

    if (generation1 >1) {
      require(father1 != father2 && mother1 != mother2, "Same father error");
    }

    require(breedCounts[maleTokenId] < MAX_BREED_COUNT && breedCounts[femaleTokenId] < MAX_BREED_COUNT, "Max breed error.");

    uint _fee = getBreedFee(maleTokenId, femaleTokenId);

    ratelGameToken.safeTransferFrom(_msgSender(), address(this), _fee);

    breedCounts[maleTokenId]  += 1;
    breedCounts[femaleTokenId] += 1;

    uint newBabyId = babies.length;
    babies.push(Baby(
      maleTokenId,
      femaleTokenId,
      generation1 +1, 
      block.timestamp
    ));

    babyToOwner[newBabyId] = _msgSender();
    ownerBabyCount[_msgSender()] += 1;

    if(babyOwner[_msgSender()] == false) {
      babyOwner[_msgSender()] = true;
    }
    
    _totalBreed++;

    emit OnRatelBreed( newBabyId, generation1+1, maleTokenId, femaleTokenId);
    return true; 
  }

  /**
    * @dev take the grownup ratel after 5 days
    */
  function takeGrownupRatel(uint babyId) 
    public
    payable
    online
  {
    require(msg.value == takeGrownupFee, "Payment take error.");
    require(babyOwner[_msgSender()], "Not owner error");
    require(babyToOwner[babyId] == _msgSender(), "Not owner error");
    require(block.timestamp - babies[babyId].birthTime >= FIVE_DAY_SECONDS, "Less than 5 days" );

    babyToOwner[babyId] = address(0); 
    ownerBabyCount[_msgSender()] -= 1; 
    if (ownerBabyCount[_msgSender()] == 0) {
      babyOwner[_msgSender()] = false;
    }

    payable(address(this)).transfer(msg.value);
    
    _totalBreed--;

    uint tokenId = _mint(_msgSender(), 0, 1, babyId);

    (, uint father_tokenId, uint mother_tokenId, uint generation, ) = getBabyInfo(babyId);

    emit OnTakeGrownupRatel(father_tokenId, mother_tokenId, generation, babyId, tokenId);

  }

  /**
  * @dev withdraw ether to owner/admin wallet
  * @notice only owner can call this method
  */
  function withdraw() public onlyOwner returns(bool){
      multiSigWalletAddress.transfer(address(this).balance);
      return true; 
  }

  /**
  * @dev Withdraw ERC20 Token from this contract
  * @notice only owner can call this method
  */
  function withdrawToken() public onlyOwner returns(bool){
    uint balance = ratelGameToken.balanceOf(address(this));
    ratelGameToken.safeTransfer(multiSigWalletAddress, balance);
    return true; 
  }

  struct MarketItem {
    uint itemId;
    uint babyId;
    address payable seller;
    address payable owner; 
    uint price;
    bool sold;
  }

  mapping(uint => MarketItem) private idToMarketItem;

  function createBabyMarketItem(uint babyId, uint price) 
    public 
    nonReentrant 
    returns(bool)
  {
    require(price > 0, "price must be more than 0");
    require(babyToOwner[babyId] == _msgSender(), "Not owner");

    _itemIds.increment();
    uint itemId = _itemIds.current();

    idToMarketItem[itemId] = MarketItem(
      itemId,
      babyId,
      payable(_msgSender()),
      payable(address(0)), 
      price,
      false 
    );

    babyToOwner[babyId] = address(0); 
    ownerBabyCount[idToMarketItem[itemId].seller] -= 1;
    if (ownerBabyCount[idToMarketItem[itemId].seller] == 0) {
       babyOwner[idToMarketItem[itemId].seller] = false;
    }

    emit OnBabyMarketItemCreated(itemId, babyId, _msgSender(), price);    
    return true;
  }

  function createBabyMarketSale(uint itemId) 
    public 
    payable 
    nonReentrant 
    returns(bool) 
  {
    require(itemId <= _itemIds.current(), "item not exists" );
    uint price = idToMarketItem[itemId].price;
    uint babyId = idToMarketItem[itemId].babyId;

    require(msg.value >= price, "the price payed is incorrect");
    require(idToMarketItem[itemId].sold == false, "already sold");

    // transfer the price of the baby (sending money) from the buyer to the seller
    idToMarketItem[itemId].seller.transfer(msg.value.mul(97).div(100));

    //手续费转到合约  
    payable(address(this)).transfer(msg.value.mul(3).div(100));
    
    // change the owner infomation to the buyer
    babyToOwner[babyId] = _msgSender();
    ownerBabyCount[_msgSender()] += 1;
    babyOwner[_msgSender()] = true;

    babies[babyId].birthTime = block.timestamp;
      
    // set the local value for the owner.
    idToMarketItem[itemId].owner = payable(_msgSender());
    idToMarketItem[itemId].sold = true;

    _itemsSold.increment();

    emit OnBabySold(idToMarketItem[itemId].seller, payable(_msgSender()), babyId, price);

    return true;
  }

  function cancelOrder(uint itemId) 
    public 
    nonReentrant 
    returns (bool) 
  {
      require(itemId <= _itemIds.current(), "item not exists" );
      MarketItem storage item = idToMarketItem[itemId];
      require(item.seller == _msgSender(), "not the seller of this item");
      require(item.owner == address(0), "owner not address zero");
      require(item.sold, "already sold");

      babyToOwner[item.babyId] = _msgSender();
      ownerBabyCount[_msgSender()] += 1;
      babyOwner[_msgSender()] = true;
    
      item.owner = payable(_msgSender());
      item.sold = true;

      babies[item.babyId].birthTime = block.timestamp;
      
      emit OnCancelOrder(idToMarketItem[itemId].seller, item.babyId);

      return true;
  }

  function babyMarketItemInfo(uint itemId) 
    public 
    view
    returns (MarketItem memory) 
  {
      require(itemId <= _itemIds.current(), "item not exists" );
      MarketItem memory item = idToMarketItem[itemId];
      return item;
  }

  function fetchBabyMarketItems() 
    public 
    view 
    returns (MarketItem[] memory) 
  {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;
    MarketItem[] memory items = new MarketItem[](unsoldItemCount);

    for (uint index = 0; index < itemCount; index++) {
      if(idToMarketItem[index+1].owner == address(0)){
        uint currentId = idToMarketItem[index +1].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex +=1;
      }
    }

    return items;
  }

  function fetchMyBabiesMarket() 
    public 
    view 
    returns (MarketItem[] memory) 
  {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint index = 1; index < totalItemCount; index++) {
      if(idToMarketItem[index].owner == _msgSender()){
        itemCount +=1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint index = 1; index < totalItemCount; index++) {
      if(idToMarketItem[index].owner == _msgSender()){
        uint currentId = idToMarketItem[index].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex = currentIndex+1; 
      }
    }
    return items;
  }

  function fetchBabyItemsCreated() 
    public 
    view 
    returns (MarketItem[] memory) 
  {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint index = 1; index < totalItemCount; index++) {
      if(idToMarketItem[index].seller == _msgSender()){
        itemCount +=1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint index = 1; index < totalItemCount; index++) {
      if(idToMarketItem[index].seller == _msgSender()){
        uint currentId = idToMarketItem[index].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex = currentIndex+1; 
      }
    }
    return items;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error AuxQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return 'https://api.meta-ratel.xyz/metadata/';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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