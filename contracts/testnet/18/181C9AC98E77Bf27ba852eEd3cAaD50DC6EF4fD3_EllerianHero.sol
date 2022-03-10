pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IEllerianHeroUpgradeable.sol";
import "./IVRFHelper.sol";

// Interface for Whitelist Verifier using Merkle Tree
contract IWhitelistVerifier {
  function verify(bytes32 leaf, bytes32[] memory proof) external view returns (bool) {}
} 

contract ITokenUriHelper {
  function GetTokenUri(uint256 _class, uint256 _rarity) external view returns (string memory) {}
  function GetClassName(uint256 _class) external view returns (string memory) {}
}

/** 
 * Tales of Elleria
*/
contract EllerianHero is ERC721 {

  using Strings for uint256;

  uint256 private currentSupply;  // Keeps track of the current supply.
  bool private globalMintOpened;  // Can minting happen?

  // Variables to make the pre-sales go smoothly. 
  // Mint will be locked on deployment, and needs to be manually enabled by the owner.
  mapping (address => bool) private isWhitelisted;
  mapping (address => uint256) private presalesMinted;
  bool private requiresWhitelist;
  bool private presalesMintOpened;
  uint256 private mintCostInWEI;
  uint256 private maximumMintable;
  uint256 private maximumMintsPerWallet;

  // We define the initial minimum stats for minting.
  // Caters for different 'banners', for expansion, and for different options in the future.
  uint256[][] private minStats = [
  [0, 0, 0, 0, 0, 0],
  [20, 1, 10, 1, 1, 1],
  [10, 20, 1, 1, 1, 1],
  [1, 1, 1, 1, 20, 10],
  [20, 10, 1, 1, 1, 1]];

  // We define the initial maximum stats for minting.
  // Maximum stats cannot be adjusted after a class is added.
  uint256[][] private maxStats = [
  [0, 0, 0, 0, 0, 0],
  [100, 75, 90, 80, 50, 50],
  [90, 100, 75, 50, 50, 80],
  [50, 80, 50, 75, 100, 90],
  [100, 90, 75, 50, 50, 80]];

  // Keeps track of the main and secondary stats for each class.
  uint256[] private mainStatIndex = [ 0, 0, 1, 4, 0 ];
  uint256[] private subStatIndex = [ 0, 2, 0, 5, 1 ];

  // Keeps track of the possibilities of minting each class,
  // Can be adjusted for each banner during minting events, after presales, etc.
  // or to introduce legendary characters, exclusive banners, etc.
  uint256[][] private classPossibilities = [[0, 2500, 5000, 7500, 10000], 
  [0, 7000, 8000, 9000, 10000], [0, 1000, 2000, 3000, 10000]];

  uint256[] private maximumMintsForClass = [0, 0, 0, 0, 0]; // Allows certain classes to have a maximum mint cap for rarity.
  mapping(uint256 => uint256) private currentMintsForClass; // Keeps track of the number of mints.

  // Keeps track of dungeon, job & marketplace addresses to prevent needless EXP loss.
  mapping (address => bool) private _approvedAddresses;
  mapping (address => bool) private _isBlacklisted; // Prevents banned addresses from transacting.

  address private ownerAddress;             // The contract owner's address.
  address private tokenMinterAddress;       // Reference to the NFT's minting logic.

  IEllerianHeroUpgradeable upgradeableAbi;  // Reference to the NFT's upgrade logic.
  IVRFHelper vrfAbi;                        // Reference to the Randomizer.
  IWhitelistVerifier verifierAbi;           // Reference to the Whitelist
  ITokenUriHelper uriAbi;                   // Reference to the tokenUri handler.

  constructor() 
    ERC721("EllerianHeroes", "EllerianHeroes") {
      ownerAddress = msg.sender;
    }
    
    function _onlyOwner() private view {
      require(msg.sender == ownerAddress, "O");
    }

    modifier onlyOwner() {
      _onlyOwner();
      _;
    }


  /**
    * Returns the number of remaining mints.
    */
  function GetRemainingMints() external view returns (uint256) {
    return maximumMintable - currentSupply;
  }

  /**
    * Checks if someone is blacklisted.
    */
  function CheckIfBlacklisted(address _address) external view returns (bool) {
    return _isBlacklisted[_address];
  }
  
  /*
  * Custom tokenURI to allow for customisability.
  * Returns imageUri, 
  * str, agi, vit, end, int, wil, 
  * totalAttr, class name, summonedTime,
  * level
  * 
  */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {

    uint256[9] memory heroDetails = upgradeableAbi.GetHeroDetails(tokenId);

    return string(abi.encodePacked(
      uriAbi.GetTokenUri(
        upgradeableAbi.GetHeroClass(tokenId), 
        upgradeableAbi.GetAttributeRarity(tokenId)),
      Strings.toString(heroDetails[0]),
      Strings.toString(heroDetails[1]),
      Strings.toString(heroDetails[2]),
      Strings.toString(heroDetails[3]),
      Strings.toString(heroDetails[4]),
      Strings.toString(heroDetails[5]),
      Strings.toString(heroDetails[6]),
      uriAbi.GetClassName(heroDetails[7]),
      Strings.toString(heroDetails[8]),
      upgradeableAbi.GetHeroLevel(tokenId)));
  }

  /**
    * Allows the ownership of the contract to be transferred to a safer multi-sig wallet once deployed.
    */ 
  function TransferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0));
    ownerAddress = _newOwner;
  }

  /**
    * Allows presales minting variables to be adjusted.
    */
  function SetMintable(bool _presalesOpened, uint256 _newMintCostInWEI, uint256 _maxMints,  bool _requireWhitelist, uint256 _max) external onlyOwner {
    presalesMintOpened = _presalesOpened;
    requiresWhitelist = _requireWhitelist;
    mintCostInWEI = _newMintCostInWEI;
    maximumMintable = _max;
    maximumMintsPerWallet = _maxMints;
    globalMintOpened = false; // Locks the mint in case of accidents. To be manually enabled again.
  }

  /**
    * Allows the owner to add new classes. 
    * When a new class is added, minting will automatically be locked.
    */
  function AddNewClass(uint256[6] memory _new_class_min, uint256[6] memory _new_class_max, uint256 _main_stat, uint256 _sub_stat, uint256[][] memory _classPossibilities, uint256[] memory _maximumClassMints) external onlyOwner {
    minStats.push(_new_class_min);
    maxStats.push(_new_class_max);
    mainStatIndex.push(_main_stat);
    subStatIndex.push(_sub_stat);
    UpdateClassPossibilities(_classPossibilities, _maximumClassMints);
    globalMintOpened = false; // Locks the mint in case of accidents. Remember to re-open!
  }

  /*
   * Allows the owner to block or allow minting.
   */
  function SetGlobalMint(bool _allow) external onlyOwner {
    globalMintOpened = _allow;
  }

  /*
   * Allows the owner to blacklist/unblacklist addresses.
   */
  function SetBlacklistStatus(address[] memory _addresses, bool _isBlacklist) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _isBlacklisted[_addresses[i]] = _isBlacklist;
    }
  }

  /*
   * Allows the owner to modify the possibilities for getting different classes, as well as impose a limit on different classes.
   *  Classes 1-4 (the OG ones) are exempted from the limit.
   */
  function UpdateClassPossibilities(uint256[][] memory _classPossibilities, uint256[] memory _maximumClassMint) public onlyOwner {
    for (uint256 i = 0; i < _classPossibilities.length; i++) {
      require(_classPossibilities[i].length == maxStats.length, "12");
    }
    
    require(_maximumClassMint.length == maxStats.length, "12");
    classPossibilities = _classPossibilities;
    maximumMintsForClass = _maximumClassMint;
  }
 
  /*
   * Allows the owner to modify minimum stats for different events if necessary.
   */
  function SetRandomStatMinimums(uint256[][] memory _newMinStats) external onlyOwner {
    require(minStats.length == _newMinStats.length);
    minStats = _newMinStats;
  }

  /*
   * Link with other contracts necessary for this to function.
   */
  function SetAddresses(address _upgradeableAddr, address _tokenMinterAddr, address _vrfAddr, address _verifierAddr, address _uriAddr) external onlyOwner {
    tokenMinterAddress = _tokenMinterAddr;

    upgradeableAbi = IEllerianHeroUpgradeable(_upgradeableAddr);
    vrfAbi = IVRFHelper(_vrfAddr);
    verifierAbi = IWhitelistVerifier(_verifierAddr);
    uriAbi = ITokenUriHelper(_uriAddr);
  }

  /**
    * Allows approval of certain contracts
    * for transfers. (bridge, marketplace, staking)
    */
  function SetApprovedAddress(address _address, bool _allowed) public onlyOwner {
      _approvedAddresses[_address] = _allowed;
  }   

  /**
  *  Allows batch minting of Heroes! (for presales only).
  */
  function mintPresales (address _owner, uint256 _amount, uint256 _variant, bytes32[] memory _proof) public payable {
      require (currentSupply + _amount < maximumMintable + 1, "8");
      require (tx.origin == msg.sender, "9");
      require (msg.sender == _owner, "9");
      require (globalMintOpened, "20");
      require (presalesMinted[msg.sender] + _amount < maximumMintsPerWallet + 1, "39");
      require (msg.value == mintCostInWEI * _amount, "ERR19");

      if (requiresWhitelist) {
        require (verifierAbi.verify(keccak256(abi.encode(_owner)), _proof), "13");
      }
      
      presalesMinted[msg.sender] = presalesMinted[msg.sender] + _amount;

      for (uint256 a = 0; a < _amount; a++) {
          uint256 id = currentSupply;
          _safeMint(msg.sender, id);
          _processMintedToken(id, _variant);
      }
  }

  /**
  * Allows the minting of NFTs using tokens.
  * This function must be called by a delegated minter contract.
  */
  function mintUsingToken(address _recipient, uint256 _amount, uint256 _variant) public {
    require (currentSupply + _amount < maximumMintable + 1, "8");
    require(tokenMinterAddress == msg.sender, "15");
    require (globalMintOpened, "20");

    for (uint256 a = 0; a < _amount; a++) {
          uint256 id = currentSupply;
          _safeMint(_recipient, id);
          _processMintedToken(id, _variant);
    }
  }
  
  /*
  * Allows the owner to airdrop NFTs for distributions/rewards/team.
  * Cannot airdrop exceeding maximum supply!
  */ 
  function airdrop (address _to, uint256 _amount, uint256 _variant) public onlyOwner {
    require( currentSupply + _amount < maximumMintable + 1, "8");
    for (uint256 a = 0; a < _amount; a++) {
        uint256 id = currentSupply;
        _safeMint(_to, id);
        _processMintedToken(id, _variant);
    }
  }

  function safeTransferFrom (address _from, address _to, uint256 _tokenId) public override {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /* 
   * Do not allow transfers to non approved addresses.
   */
  function safeTransferFrom (address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
    require(_isApprovedOrOwner(_msgSender(), _tokenId), "SFF");
     
    if (_approvedAddresses[_from] || _approvedAddresses[_to]) {
    } else if (_to != address(0)) {
      // Reset experience for non-exempted addresses.
      upgradeableAbi.ResetHeroExperience(_tokenId, 0);
    }

    _safeTransfer(_from, _to, _tokenId, _data);
  }

  /* 
   * Allows burning and approval check for heroes.
   */
  function burn (uint256 _tokenId, bool _isBurnt) public {
    require(_isApprovedOrOwner(_msgSender(), _tokenId), "22");
    if (_isBurnt) {
      _burn(_tokenId);
    }
  }

  /* 
   * Allows the withdrawal of presale funds into the owner's wallet.
   * For fund allocation, refer to the whitepaper.
   */
  function withdraw() public onlyOwner {
    (bool success, ) = (msg.sender).call{value:address(this).balance}("");
    require(success, "2");
  }

  /* 
   * Internal function to generate stats. 
   * Owner must have enabled global minting.
   */
  function _processMintedToken(uint256 id, uint256 _variant) internal {

    uint256 randomClass = _getClass(id, _variant); // Base Classes = 1: Warrior, 2: Assassin, 3: Mage, 4: Ranger
    if (randomClass > 4 && (currentMintsForClass[randomClass] > maximumMintsForClass[randomClass])) {
      randomClass = (vrfAbi.GetVRF(id) % 4) + 1; 
    }

    uint256[6] memory placeholderStats = [uint256(0), 0, 0, 0, 0, 0];

    for (uint256 b = 0; b < 6; b++) {
      placeholderStats[b] = (vrfAbi.GetVRF(id * randomClass * b) % (maxStats[randomClass][b] - minStats[randomClass][b] + 1)) + minStats[randomClass][b];
    }
    
    upgradeableAbi.initHero(id, placeholderStats[0], placeholderStats[1], placeholderStats[2],
    placeholderStats[3],placeholderStats[4],placeholderStats[5],
    placeholderStats[0] + placeholderStats[1] + placeholderStats[2] + placeholderStats[3] + placeholderStats[4] + placeholderStats[5],
    randomClass);

    ++currentSupply;
    ++currentMintsForClass[randomClass];
  }

  /* 
   * Random function to allow weighted randomness for classes.
   * Will kick in when legendary/rare characters are introduced further into the game.
   */
  function _getClass(uint256 _seed, uint256 _variant) internal view returns (uint256) {
    uint256 classRandom = vrfAbi.GetVRF(_seed) % 10000;
    for (uint256 i = 0; i < classPossibilities[_variant].length; i++) {
      if (classRandom < classPossibilities[_variant][i])
        return i;
      }

      return classPossibilities[_variant].length - 1;
  }
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for the randomizer.
contract IVRFHelper {
    function GetVRF(uint256) external view returns (uint256) {}
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for upgradeable logic.
contract IEllerianHeroUpgradeable {

    function GetHeroDetails(uint256 _tokenId) external view returns (uint256[9] memory) {}
    function GetHeroClass(uint256 _tokenId) external view returns (uint256) {}
    function GetHeroLevel(uint256 _tokenId) external view returns (uint256) {}
    function GetHeroName(uint256 _tokenId) external view returns (string memory) {}
    function GetHeroExperience(uint256 _tokenId) external view returns (uint256[2] memory) {}
    function GetAttributeRarity(uint256 _tokenId) external view returns (uint256) {}

    function GetUpgradeCost(uint256 _level) external view returns (uint256[2] memory) {}
    function GetUpgradeCostFromTokenId(uint256 _tokenId) public view returns (uint256[2] memory) {}

    function ResetHeroExperience(uint256 _tokenId, uint256 _exp) external {}
    function UpdateHeroExperience(uint256 _tokenId, uint256 _exp) external {}

    function SetHeroLevel (uint256 _tokenId, uint256 _level) external {}
    function SetNameChangeFee(uint256 _feeInWEI) external {}
    function SetHeroName(uint256 _tokenId, string memory _name) public {}

    function SynchronizeHero (uint256 _tokenId, uint256 _level, uint256 _exp, string memory _name) external {}

    function initHero(uint256 _tokenId, uint256 _str, uint256 _agi, uint256 _vit, uint256 _end, uint256 _intel, uint256 _will, uint256 _total, uint256 _class) external {}

    function AttemptHeroUpgrade(address sender, uint256 tokenId, uint256 goldAmountInEther, uint256 tokenAmountInEther) public {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        safeTransferFrom(from, to, tokenId, "");
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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