//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import "./MYPStorage.sol";

import { MYPunk, MYPart, UserPunk } from './libraries/MYP.sol';
import { Constants } from './libraries/MYPConstants.sol';

/**
................................................
................................................
................................................
................................................
...................';::::::;'.';'...............
.............';'.':kNWWWWWWNkcod;...............
.............oXkckNWMMMMMMMMWNkc'.';'...........
.........'::ckWWWWMMMMMMMMMMMMWNkcoxo:'.........
.........;xKWWMMMMWXKNMMMMMMMMMMWNklkXo.........
.........'cOWMMMMN0kxk0XWWXK0KNWMMWWKk:.........
.......':okKWMMMWOldkdlkNNkcccd0NMMWOc'.........
.......;dolOWMWX0d:;::ckXXkc:;;:lkKWKko:'.......
.......':okKWN0dc,.',;:dOOkd:.''..lNOlod:.......
.....':kNklONx;;:,.';:::ccdkc.',. lWMNo.........
.....:xkOKWWWl..:::::::::::c:::;. lWMWk:'.......
.........dWMWl .:::::::;;;;:::::. lNXOkx;.......
. .....':okkk; .;::::::,'',:::::. ;xdc'.........
.......:d:...  .;::::;,,,,,,;:::.  .:d:.........
.. ..........  .';:::,'....',:;'.  .............
..............   .,,,;::::::;'.    .............
..............    .  .''''''.   ................
..............   ....          .................
..............   .;,....    . ..................
..............   .;:::;.    ....................

               Made with <3 from
             @author @goldendilemma

*/

contract MYPAPI is Ownable {

  MYPStorage public assets;

  modifier requireAssets() {
    require(address(assets) != address(0), "ASSETS_NOT_INIT");
    _;
  }

  function setAssetContract (address assetContract) 
  public onlyOwner {
    assets = MYPStorage(assetContract);
  }

  function getPunkId(
    uint16[] memory attributeIndexes,
    uint8[][] memory fillIndexes
  ) 
    external view 
    returns (bytes32) 
  {
    uint fillLength;
    bytes memory attrFillHash;
    for (uint8 i = 0; i < Constants.N_CATEGORY; i++) {
      if (i == Constants.BACKGROUND_INDEX || i == Constants.TYPE_INDEX) continue;
      attrFillHash = abi.encodePacked(attrFillHash, attributeIndexes[i]);
      fillLength = assets.getFillLength(attributeIndexes[i]);
      for (uint8 j = 0; j < fillLength; j++) {
        attrFillHash = abi.encodePacked(attrFillHash, fillIndexes[i][j]);
      }
    }
    return keccak256(abi.encodePacked(attrFillHash));
  }

  function getSVGForPart(MYPart memory part)
  private pure
  returns (string memory) {
    string memory svg = '';
    for (uint i = 0; i < part.asset.length; i++) {
      svg = string(abi.encodePacked(
        svg, 
        part.asset.parts[i],
        i < part.asset.fillLength
          ? string(abi.encodePacked('#', part.fills[i]))
          : '',
        '" />'
      ));
    }
    return svg;
  }

  function getJsonProperty (
    string memory key, 
    string memory value, 
    bool appendComma
  ) 
  private pure 
  returns (string memory) 
  {
    return string(abi.encodePacked(
        '"', key, '":', '"', value, '"',
        appendComma ? ',' : ''
      ));
  }

  function shouldRender (uint16 attrIndex) private pure returns (bool) {
    return (
      attrIndex != Constants.NONE || 
      attrIndex == Constants.ATTR_CLOWN_NOSE_X || 
      attrIndex == Constants.ATTR_CLOWN_NOSE_Y
    );
  }

  function validatePunk(
    uint8 genderIndex,
    uint8 typeIndex,
    uint16[] calldata attributes,
    uint8[][] calldata fillIndexes
  )
    public view
    requireAssets
    returns (bool)
  {
    require(genderIndex >= 0 && genderIndex < 3, "MALFORMED_GENDER_INDEX");
    require(genderIndex == 2 || genderIndex == typeIndex, "MALFORMED_GENDER_TYPE");
    require(typeIndex >= 0 && typeIndex < 2, "MALFORMED_TYPE_INDEX");
    for (uint8 i = 0; i < Constants.N_CATEGORY; i++) {
      uint16 attrIndex = attributes[i];
      if (i == Constants.TYPE_INDEX) continue;
      assets.validate(typeIndex, attributes[i], i);
    }
    return true;
  }

  function renderPunkEnvironment (
    string memory output,
    UserPunk calldata punk
  )
    internal
    view
    returns (string memory)
  {
    output = string(abi.encodePacked(output, '<style id="pd">#punk{transform-origin: center center;}'));
    if (punk.direction == Constants.PD_ALTERNATE) {
      output = string(abi.encodePacked(output, '#punk { animation: flip 4s infinite linear; }'));
    } else {
      output = string(abi.encodePacked(output, '#punk { transform: scaleX(', punk.direction == Constants.PD_RIGHT ? '1' : '-1' ,'); }'));
    }
    output = string(abi.encodePacked(output, '</style>'));

    uint16 bgId = punk.attributeIndexes[Constants.BACKGROUND_INDEX];
    if (bgId != Constants.NONE) {
      output = string(abi.encodePacked(output,
        '<g class="c', Strings.toString(Constants.BACKGROUND_INDEX),'" id="a', Strings.toString(bgId), '">', 
        getSVGForPart(assets.getAsset(bgId, punk.fillIndexes[Constants.BACKGROUND_INDEX])),
        "</g>"
      ));
    }
    if (punk.genderIndex == Constants.TYPE_XYZ) {
      output = string(abi.encodePacked(output,
        '<g class="c1" id="nbf">', 
        getSVGForPart(assets.getAsset(Constants.ATTR_NB_FLAG, punk.fillIndexes[Constants.TYPE_INDEX])),
        "</g>"
      ));
    }
    return output;
  }

  function renderPunk (UserPunk calldata punk)
    public view
    requireAssets
    returns (MYPunk memory)
  {
    string memory svg;
    string memory jsonAttributes = getJsonProperty('Gender', assets.getGenderName(punk.genderIndex), true);
    jsonAttributes = string(abi.encodePacked(jsonAttributes, getJsonProperty('Direction', assets.getDirectionName(punk.direction), true)));

    uint16 attrIndex;
    MYPart memory part;

    svg = renderPunkEnvironment(svg, punk);

    svg = string(abi.encodePacked(svg, '<g id="punk">'));

    for (uint8 i = 0; i < Constants.N_CATEGORY; i++) {

      if (i == Constants.TYPE_INDEX) continue; // attributes that shouldn't be in metadata or render

      attrIndex = punk.attributeIndexes[i];
      part = assets.getAsset(attrIndex, punk.fillIndexes[i]);

      jsonAttributes = string(abi.encodePacked(jsonAttributes,
        getJsonProperty(
          assets.getCategoryNameByIndex(i), 
          part.asset.name, 
          i != Constants.N_CATEGORY - 1
        )
      ));

      if (i == Constants.BACKGROUND_INDEX) continue; // attributes that should be in metadata but not render

      svg = shouldRender(attrIndex)
        ? (string(abi.encodePacked(svg,
          '<g class="c', Strings.toString(i),'" id="a', Strings.toString(attrIndex), '">', 
          getSVGForPart(part),
          '</g>'
          )))
        : svg;

    }

    if (
      punk.attributeIndexes[Constants.NOSE_INDEX] == Constants.ATTR_CLOWN_NOSE_X || 
      punk.attributeIndexes[Constants.NOSE_INDEX] == Constants.ATTR_CLOWN_NOSE_Y
    ) {
      svg = string(abi.encodePacked(svg,
        '<g class="c', Strings.toString(Constants.NOSE_INDEX),'" id="a', Strings.toString(Constants.NOSE_INDEX), '">', 
        getSVGForPart(assets.getAsset(punk.attributeIndexes[Constants.NOSE_INDEX], punk.fillIndexes[Constants.NOSE_INDEX])),
        "</g>"
      ));
    }

    svg = string(abi.encodePacked(svg, '</g>'));

    return MYPunk({
      svg: svg,
      jsonAttributes: jsonAttributes
    });
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './MYPAssetsA.sol';
import './MYPAssetsB.sol';
import './MYPAssetsC.sol';

import { MYPart } from './libraries/MYP.sol';
import { Constants } from './libraries/MYPConstants.sol';

/**
................................................
................................................
................................................
................................................
...................';::::::;'.';'...............
.............';'.':kNWWWWWWNkcod;...............
.............oXkckNWMMMMMMMMWNkc'.';'...........
.........'::ckWWWWMMMMMMMMMMMMWNkcoxo:'.........
.........;xKWWMMMMWXKNMMMMMMMMMMWNklkXo.........
.........'cOWMMMMN0kxk0XWWXK0KNWMMWWKk:.........
.......':okKWMMMWOldkdlkNNkcccd0NMMWOc'.........
.......;dolOWMWX0d:;::ckXXkc:;;:lkKWKko:'.......
.......':okKWN0dc,.',;:dOOkd:.''..lNOlod:.......
.....':kNklONx;;:,.';:::ccdkc.',. lWMNo.........
.....:xkOKWWWl..:::::::::::c:::;. lWMWk:'.......
.........dWMWl .:::::::;;;;:::::. lNXOkx;.......
. .....':okkk; .;::::::,'',:::::. ;xdc'.........
.......:d:...  .;::::;,,,,,,;:::.  .:d:.........
.. ..........  .';:::,'....',:;'.  .............
..............   .,,,;::::::;'.    .............
..............    .  .''''''.   ................
..............   ....          .................
..............   .;,....    . ..................
..............   .;:::;.    ....................

               Made with <3 from
             @author @goldendilemma

    TODO: Remove "Hacking" background before deploy

*/

contract MYPStorage {

  IMYPAssetStorage[3] assets;

  constructor() {
    assets[0] = new MYPAssetsA();
    assets[1] = new MYPAssetsB();
    assets[2] = new MYPAssetsC();
  }

  function getAssetIndexFromIndex (uint index)
  private pure
  returns (uint) {
    if (index < 44) return 0;
		if (index < 88) return 1;
		if (index < 132) return 2;
    revert();
  }

  function getOffsetFromIndex (uint index)
  private pure
  returns (uint) {
    if (index < 44) return 0;
		if (index < 88) return 44;
		if (index < 132) return 88;
    revert();
  }

  function getGenderName (uint8 index) 
  external pure
  returns (string memory) {
    return ['Male', 'Female', 'Non-Binary'][index];
  }

  function getDirectionName (uint8 index) 
  external pure
  returns (string memory) {
    return ['Alternate', 'Right', 'Left'][index];
  }

  function getCategoryNameByIndex (uint index) 
  external pure 
  returns (string memory) {
    return ['Background','Type Secret','Head','Skin','Ear','Hair','Neck','Nose','Mouth','Beard','Smoke','Eyes','Glasses'][index];
  }

  function getColorByIndex(uint8 index) 
  internal pure 
  returns (string memory) { 
    return ['DBB180','000000','FFFFFF','C8FBFB','7DA269','352410','856F56','EAD9D9','FF8EBE','D60000','FB4747','2858B1','1C1A00','534C00','80DBDA','F0F0F0','328DFD','AD2160','C77514','C6C6C6','FFD926','FF0000','1A43C8','FFF68E','710CC7','28B143','E22626','CA4E11','A66E2C','E65700','2D6B62','51360C','229000','005580','FFC926','5F1D09','68461F','794B11','692F08','740000','B90000','0060C3','E4EB17','595959','4C4C4C','743939','26314A','A39797','ACACAC','0000FF','FF00FF','00FF00','FEF433','9A59CF','AE8B61','713F1D'][index]; 
  }

  function validate (uint8 typeIndex, uint16 attrIndex, uint8 catIndex) 
  external pure {
  uint8 attrType = [uint8(2),1,0,1,0,2,1,0,0,0,0,1,0,1,1,0,1,0,1,0,1,0,1,1,0,1,1,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,1,1,1,1,1,0,1,1,1,1,0,1,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,1,0,0,0,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0][attrIndex];
  uint8 attrCatIndex = [uint8(0),0,0,0,0,1,2,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,7,7,7,7,7,7,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,11,11,11,11,11,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12][attrIndex];
  uint16 catLength = [uint16(5),1,7,7,2,49,4,6,6,12,6,5,22][attrCatIndex];
  uint16 catIndexStart = [uint16(0),5,6,13,20,22,71,75,81,87,99,105,110][attrCatIndex];
  bool isRemovable = [true,true,false,true,true,true,true,false,false,true,true,false,true][attrCatIndex];
    if (attrIndex == Constants.NONE) {
      require(isRemovable, "MALFORMED_PUNK_4");
    } else {
      require(attrType == typeIndex || attrType == 2, "MALFORMED_PUNK_1");
      require(catIndexStart < catIndexStart + catLength, "MALFORMED_PUNK_2");
      require(catIndex == attrCatIndex, "MALFORMED_PUNK_3");
    }
  }

  function fillIndexToFills (
  uint8[] memory fillIndexes,
  AssetData memory asset
  ) 
  private pure
  returns (string[8] memory) 
  {
    string[8] memory out; // NOTE: MAX n in string[n] fills per attribute.
    for (uint i = 0; i < asset.fillLength; i++) {
      out[i] = getColorByIndex(fillIndexes[i]);
    }
    return out;
  }

  function getStoreFromIndex (uint attrIndex) private view returns (IMYPAssetStorage) { return assets[getAssetIndexFromIndex(attrIndex)]; }

  function getFillLength (uint16 attrIndex) 
  external view 
  returns (uint)
  {
    IMYPAssetStorage store = getStoreFromIndex(attrIndex);
    AssetData memory asset = store.getAssetFromIndex(attrIndex - getOffsetFromIndex(attrIndex));
    return asset.fillLength;
  }

  function getAsset(uint16 attrIndex, uint8[] calldata fillIndexes) 
  external view 
  returns (MYPart memory) 
  {
    IMYPAssetStorage store = getStoreFromIndex(attrIndex);
    AssetData memory asset = store.getAssetFromIndex(attrIndex - getOffsetFromIndex(attrIndex));
    return MYPart({
      fills: fillIndexToFills(fillIndexes, asset),
      asset: asset
    });
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
................................................
................................................
................................................
................................................
...................';::::::;'.';'...............
.............';'.':kNWWWWWWNkcod;...............
.............oXkckNWMMMMMMMMWNkc'.';'...........
.........'::ckWWWWMMMMMMMMMMMMWNkcoxo:'.........
.........;xKWWMMMMWXKNMMMMMMMMMMWNklkXo.........
.........'cOWMMMMN0kxk0XWWXK0KNWMMWWKk:.........
.......':okKWMMMWOldkdlkNNkcccd0NMMWOc'.........
.......;dolOWMWX0d:;::ckXXkc:;;:lkKWKko:'.......
.......':okKWN0dc,.',;:dOOkd:.''..lNOlod:.......
.....':kNklONx;;:,.';:::ccdkc.',. lWMNo.........
.....:xkOKWWWl..:::::::::::c:::;. lWMWk:'.......
.........dWMWl .:::::::;;;;:::::. lNXOkx;.......
. .....':okkk; .;::::::,'',:::::. ;xdc'.........
.......:d:...  .;::::;,,,,,,;:::.  .:d:.........
.. ..........  .';:::,'....',:;'.  .............
..............   .,,,;::::::;'.    .............
..............    .  .''''''.   ................
..............   ....          .................
..............   .;,....    . ..................
..............   .;:::;.    ....................

               Made with <3 from
             @author @goldendilemma

*/

struct AssetSVG {
  AssetData asset;
  string svg;
}

struct AssetData {
  string[8] parts;
  string name;
  uint8 fillLength;
  uint8 length;
}

struct MYPart {
  AssetData asset;
  string[8] fills;
}

struct MYPunk {
  string svg;
  string jsonAttributes;
}

struct UserPunk {
  string name;
  bool isNamed;
  uint8 direction;
  uint8 genderIndex;
  uint8 typeIndex;
  uint16[] attributeIndexes;
  uint8[][] fillIndexes;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
................................................
................................................
................................................
................................................
...................';::::::;'.';'...............
.............';'.':kNWWWWWWNkcod;...............
.............oXkckNWMMMMMMMMWNkc'.';'...........
.........'::ckWWWWMMMMMMMMMMMMWNkcoxo:'.........
.........;xKWWMMMMWXKNMMMMMMMMMMWNklkXo.........
.........'cOWMMMMN0kxk0XWWXK0KNWMMWWKk:.........
.......':okKWMMMWOldkdlkNNkcccd0NMMWOc'.........
.......;dolOWMWX0d:;::ckXXkc:;;:lkKWKko:'.......
.......':okKWN0dc,.',;:dOOkd:.''..lNOlod:.......
.....':kNklONx;;:,.';:::ccdkc.',. lWMNo.........
.....:xkOKWWWl..:::::::::::c:::;. lWMWk:'.......
.........dWMWl .:::::::;;;;:::::. lNXOkx;.......
. .....':okkk; .;::::::,'',:::::. ;xdc'.........
.......:d:...  .;::::;,,,,,,;:::.  .:d:.........
.. ..........  .';:::,'....',:;'.  .............
..............   .,,,;::::::;'.    .............
..............    .  .''''''.   ................
..............   ....          .................
..............   .;,....    . ..................
..............   .;:::;.    ....................

               Made with <3 from
             @author @goldendilemma

*/

library Constants {

  uint8 internal constant N_CATEGORY = 13;

  uint8 internal constant NONE = 0;
  uint8 internal constant ATTR_NB_FLAG = 5;
  uint8 internal constant ATTR_CLOWN_NOSE_X = 75;
  uint8 internal constant ATTR_CLOWN_NOSE_Y = 76;

  uint8 internal constant TYPE_Y = 0;
  uint8 internal constant TYPE_X = 1;
  uint8 internal constant TYPE_XYZ = 2;

  uint8 internal constant PD_ALTERNATE = 0;
  uint8 internal constant PD_RIGHT = 1;
  uint8 internal constant PD_LEFT = 2;

  uint8 internal constant BACKGROUND_INDEX = 0;
  uint8 internal constant TYPE_INDEX = 1;
  uint8 internal constant HEAD_INDEX = 2;
  uint8 internal constant SKIN_INDEX = 3;
  uint8 internal constant EAR_INDEX = 4;
  uint8 internal constant HAIR_INDEX = 5;
  uint8 internal constant NECK_INDEX = 6;
  uint8 internal constant NOSE_INDEX = 7;
  uint8 internal constant MOUTH_INDEX = 8;
  uint8 internal constant BEARD_INDEX = 9;
  uint8 internal constant SMOKE_INDEX = 10;
  uint8 internal constant EYES_INDEX = 11;
  uint8 internal constant GLASSES_INDEX = 12;

  bytes32 internal constant MYP_MINTER = keccak256("MYP_MINTER");

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AssetData } from './libraries/MYP.sol';
import { IMYPAssetStorage } from './interfaces/IMYPAssets.sol';

/**
................................................
................................................
................................................
................................................
...................';::::::;'.';'...............
.............';'.':kNWWWWWWNkcod;...............
.............oXkckNWMMMMMMMMWNkc'.';'...........
.........'::ckWWWWMMMMMMMMMMMMWNkcoxo:'.........
.........;xKWWMMMMWXKNMMMMMMMMMMWNklkXo.........
.........'cOWMMMMN0kxk0XWWXK0KNWMMWWKk:.........
.......':okKWMMMWOldkdlkNNkcccd0NMMWOc'.........
.......;dolOWMWX0d:;::ckXXkc:;;:lkKWKko:'.......
.......':okKWN0dc,.',;:dOOkd:.''..lNOlod:.......
.....':kNklONx;;:,.';:::ccdkc.',. lWMNo.........
.....:xkOKWWWl..:::::::::::c:::;. lWMWk:'.......
.........dWMWl .:::::::;;;;:::::. lNXOkx;.......
. .....':okkk; .;::::::,'',:::::. ;xdc'.........
.......:d:...  .;::::;,,,,,,;:::.  .:d:.........
.. ..........  .';:::,'....',:;'.  .............
..............   .,,,;::::::;'.    .............
..............    .  .''''''.   ................
..............   ....          .................
..............   .;,....    . ..................
..............   .;:::;.    ....................

               Made with <3 from
             @author @goldendilemma

*/

contract MYPAssetsA is IMYPAssetStorage {

  function getAssetFromIndex (uint index)
  external override pure
  returns (AssetData memory)
  {
    uint16 partIndex = [uint16(0),0,1,2,4,6,10,13,16,20,24,28,31,34,35,36,37,38,39,40,41,43,45,48,51,54,55,56,58,60,62,64,65,67,69,71,72,75,78,79,80,83,86,87][index];
    uint8 length = [uint8(0),1,1,2,2,4,3,3,4,4,4,3,3,1,1,1,1,1,1,1,2,2,3,3,3,1,1,2,2,2,2,1,2,2,2,1,3,3,1,1,3,3,1,2][index];
    
    string[8] memory parts;
    for (uint i = 0; i < length; i++) {
      parts[i] = ['<rect width="24" height="24" fill="','<rect width="24" height="24" fill="','<rect width="24" height="24" fill="','<path d="M24 0H0V24H24V0ZM23 1V6H22V1L23 1ZM20 1V2H19V1L20 1ZM17 10V1L16 1V10H17ZM15 1V8H14V1L15 1ZM13 14L13 1L12 1L12 14L13 14ZM11 3H10V0.999999L11 0.999999V3ZM8 2V0.999999L7 0.999999V2H8ZM6 0.999999V3H5V0.999999L6 0.999999ZM4 6L4 0.999999L3 0.999999L3 6H4ZM2 0.999999V2L1 2L1 0.999999L2 0.999999Z" fill-opacity="0.9" class="eo" fill="black','<rect width="24" height="24" fill="','<path d="M24 0H0V24H24V0ZM23 1V6H22V1L23 1ZM20 1V2H19V1L20 1ZM17 10V1L16 1V10H17ZM15 1V8H14V1L15 1ZM13 14L13 1L12 1L12 14L13 14ZM11 3H10V0.999999L11 0.999999V3ZM8 2V0.999999L7 0.999999V2H8ZM6 0.999999V3H5V0.999999L6 0.999999ZM4 6L4 0.999999L3 0.999999L3 6H4ZM2 0.999999V2L1 2L1 0.999999L2 0.999999Z" fill-opacity="0.9" class="eo" fill="black','<rect x="10" y="10" width="4" height="1" fill="#FEF433','<rect x="10" y="11" width="4" height="1" fill="white','<rect x="10" y="12" width="4" height="1" fill="#9A59CF','<rect x="10" y="13" width="4" height="1" fill="black','<path d="M9 8H10H11H12H13H14H15V9H16V19H15V20H14V21H13H12H11V20H10V21H11V22H12V24H11H10H9V19H8V14H7V12H8V9H9V8Z" class="eo" fill="','<path d="M9 7H15V8H9V7ZM8 9V8H9V9H8ZM7 12H8V9H7V12ZM7 14V12H6V15H7V19H8V24H9V19H8V14H7ZM16 9H15V8H16V9ZM16 19V9H17V19H16ZM15 20V19H16V20H15ZM14 21V20H15V21H14ZM11 21H14V22H13V24H12V22H11V21ZM11 21H10V20H11V21Z" class="eo" fill="black','<rect x="9" y="9" width="1" height="1" fill-opacity="0.31" fill="white','<path d="M8 6H9H10H11H12H13H14H15V7H16V20H15V21H14H13H12H11H10V24H9H8H7V14H6V12H7V7H8V6Z" class="eo" fill="','<path d="M8 5H15V6H8V5ZM7 7V6H8V7H7ZM6 12V7H7V12H6ZM6 12V14H7V24H6V15H5V12H6ZM16 7H15V6H16V7ZM16 20V7H17V20H16ZM15 21V20H16V21H15ZM11 22H15V21H10V22V24H11V22Z" class="eo" fill="black','<path opacity="0.3" d="M10 7H9V8H8V9H9V8H10V7Z" class="eo" fill="white','<path d="M8 6H9H10H11H12H13H14H15V7H16V20H15V21H14H13H12H11H10V24H9H8H7V14H6V13H5V12H6H7V7H8V6Z" class="eo" fill="','<path d="M8 5H15V6H8V5ZM7 7V6H8V7H7ZM6 12H7V7H6V11H5V12H4V13H5V15H6V24H7V14H6V13H5V12H6ZM16 7H15V6H16V7ZM16 20V7H17V20H16ZM15 21V20H16V21H15ZM15 21V22H11V24H10V22V21H15Z" class="eo" fill="black','<path d="M10 7H9V8H8V9H9V8H10V7Z" class="eo" fill="white','<rect x="6" y="12" width="1" height="1" fill-opacity="0.15" fill="black','<path d="M8 6H9H10H11H12H13H14H15V7H16V20H15V21H14H13H12H11H10V24H9H8H7V14H6V12H7V7H8V6Z" class="eo" fill="','<path d="M8 5H15V6H8V5ZM7 7V6H8V7H7ZM6 12V7H7V12H6ZM6 12V14H7V24H6V15H5V12H6ZM16 7H15V6H16V7ZM16 20V7H17V20H16ZM15 21V20H16V21H15ZM11 22H15V21H10V22V24H11V22Z" class="eo" fill="black','<path d="M10 7H9V8H8V9H9V8H10V7Z" fill-opacity="0.25" class="eo" fill="white','<path d="M9 11H11V12H9V11ZM11 19H12V20H11V19ZM10 13H9V14H10V13ZM14 13H15V14H14V13ZM16 11H14V12H16V11Z" fill-opacity="0.3" class="eo" fill="black','<path d="M8 6H9H10H11H12H13H14H15V7H16V10H15H14H13H12H11H10H9H8V15H9V16H10V17H9V18H8V20H9V21H10V24H9H8H7V14H6V12H7V7H8V6ZM15 16H16V17H15V16Z" class="eo" fill="','<path d="M9 10H8V15H9V16H10V17H9V20H10V21H11H12H13H14H15V20H16V17H15V16H16V10H15H14H13H12H11H10H9Z" class="eo" fill="','<path d="M8 5H15V6H8V5ZM7 7V6H8V7H7ZM6 12V7H7V12H6ZM6 12V14H7V24H6V15H5V12H6ZM16 7H15V6H16V7ZM16 20V7H17V20H16ZM15 21V20H16V21H15ZM10 21H15V22H11V24H10V22V21ZM9 20V21H10V20H9ZM9 20H8V18H9V20Z" class="eo" fill="black','<rect x="9" y="9" width="6" height="1" fill="black','<path d="M9 8H10H11H12H13H14H15V9H16V19H15V20H14V21H13H12H11V20H10V21H11V22H12V24H11H10H9V19H8V14H7V12H8V9H9V8Z" class="eo" fill="','<path d="M9 7H15V8H9V7ZM8 9V8H9V9H8ZM7 12H8V9H7V12ZM7 14V12H6V15H7V19H8V24H9V19H8V14H7ZM16 9H15V8H16V9ZM16 19V9H17V19H16ZM15 20V19H16V20H15ZM14 21V20H15V21H14ZM11 21H14V22H13V24H12V22H11V21ZM11 21H10V20H11V21Z" class="eo" fill="black','<rect x="9" y="9" width="1" height="1" fill="white','<path d="M8 6H9H10H11H12H13H14H15V7H16V20H15V21H14H13H12H11H10V24H9H8H7V14H6V12H7V7H8V6Z" class="eo" fill="','<path d="M8 5H15V6H8V5ZM7 7V6H8V7H7ZM6 12V7H7V12H6ZM6 12V14H7V24H6V15H5V12H6ZM16 7H15V6H16V7ZM16 20V7H17V20H16ZM15 21V20H16V21H15ZM11 22H15V21H10V22V24H11V22Z" class="eo" fill="black','<path d="M10 7H9V8H8V9H9V8H10V7Z" class="eo" fill="white','<path d="M14 9H15V10H14V9ZM11 10H12V11H11V10ZM15 14H14V15H15V14ZM7 13H8V14H7V13ZM10 16H9V17H10V16ZM12 20H13V21H12V20ZM16 17H15V18H16V17Z" fill-opacity="0.12" class="eo" fill="white','<path d="M11 15H9V16H11V15ZM16 15H14V16H16V15Z" fill-opacity="0.12" class="eo" fill="#740000','<path d="M9 15H10H11V16H10V17H9V15ZM16 15H15V17H16V15Z" fill-opacity="0.18" class="eo" fill="#B90000','<rect x="9" y="16" width="1" height="1" fill-opacity="0.32" fill="black','<rect x="8" y="16" width="1" height="1" fill-opacity="0.38" fill="black','<path d="M14 9H15V10H14V9ZM11 10H12V11H11V10ZM15 14H14V15H15V14ZM7 13H8V14H7V13ZM10 16H9V17H10V16ZM12 20H13V21H12V20ZM16 17H15V18H16V17Z" fill-opacity="0.27" class="eo" fill="black','<path d="M11 8H10V9H11V8ZM15 8H14V9H15V8ZM14 14H15V15H14V14ZM16 17H15V18H16V17ZM9 16H10V17H9V16ZM8 13H7V14H8V13ZM8 20H9V21H8V20ZM13 20H12V21H13V20Z" fill-opacity="0.29" class="eo" fill="black','<rect x="6" y="14" width="1" height="1" fill="','<path d="M7 13H6V14H5V15H6V16H7V15H8V14H7V13ZM7 14V15H6V14H7Z" class="eo" fill="black','<rect x="5" y="14" width="1" height="1" fill="','<path d="M6 13H5V14H4V15H5V16H6V15H7V14H6V13ZM6 14V15H5V14H6Z" class="eo" fill="black','<path d="M9 6H15V7H16V8H17V10H16H15H9H8H7V8H8V7H9V6Z" class="eo" fill="','<path d="M12 7H11V8H12V9H13V8H12V7Z" class="eo" fill="','<path d="M17 10H7V11H6V13H5V18H6V19V20H7V21H9V20V19H8V14H7V13H8V12H9V11H11V12H12V13H13V12H14V11H16V19H15V21H16H17V20H18V18H19V13H18V11H17V10Z" class="eo" fill="','<path d="M8 6H16V7H17V9H16V10H15V11H12V10H7H6V11H5V12H4V13H3V10H2V9H3H4H5H6V8H7V7H8V6Z" class="eo" fill="','<path d="M7 9H6V10H5V11H4V12H5V11H6V10H7V9Z" fill-opacity="0.3" class="eo" fill="black','<path d="M16 6H8V7H7V8H6V9H5V10H4V9H3V10H4V11H5V10H6V9H7V8H8V7H16V9H15V10H12V9H8V10H12V11H15V10H16V9H17V7H16V6Z" fill-opacity="0.15" class="eo" fill="black','<path d="M8 5H16V6H17V8H16V9H15V10H12V9H7H6V10H5V11H4V12H3V9H2V8H3H4H5H6V7H7V6H8V5Z" class="eo" fill="','<path d="M7 8H6V9H5V10H4V11H5V10H6V9H7V8Z" fill-opacity="0.3" class="eo" fill="black','<path d="M16 5H8V6H7V7H6V8H5V9H4V8H3V9H4V10H5V9H6V8H7V7H8V6H16V8H15V9H12V8H8V9H12V10H15V9H16V8H17V6H16V5Z" fill-opacity="0.15" class="eo" fill="black','<path d="M10 5H9V6H8V7H7V9H6V14H7V15H8V14H7V12H8V11H9V10H10H13V11H12V12H13V11H14V10H15H16V14H15V15H16V14H17V8H16V7H15V6H14V5H10Z" class="eo" fill="','<path d="M9 5H10H11H12H13H14H15V6H16V7H17V8H18V15H19V17H20V18H19H18H17V19H16H15V18H16V9H15V8H14V9H13V10H12V11H11V10H10H9V9H8V11V12H7V14H8V17H9V18H10V19H6V18H4V17H5V12V11H6V8H7V6H8H9V5Z" class="eo" fill="','<path d="M16 5H9V6H8V7H7V8V9V10H21V9H20V8H17V7V6H16V5Z" class="eo" fill="','<path d="M15 6H14V7H15V8H16V7H15V6Z" fill-opacity="0.33" class="eo" fill="white','<path d="M8 4H15V5H16V6V7H19V8H20V9H19H16H6V6H7V5H8V4Z" class="eo" fill="','<path d="M14 5H13V6H14V7H15V6H14V5Z" fill-opacity="0.33" class="eo" fill="white','<path d="M13 3H10V4H7V5H6V6H5V7H4V9H3V11V12H4V15H5V16H6V17H7V16V15H6V12H7V11H8V10H10V9H14V10H16V12V13H17V14H18V15H17V17H18V15H19V14V13V12H20V10V9H19V7H18V6H17V5H16V4H13V3Z" class="eo" fill="','<rect x="17" y="14" width="1" height="1" fill="black','<path d="M7 4H9V5H8V6V7H7V8V9V11V12H6V13V14H5V13H4V12H3V11H2V9H4V8V7H5V6H6V5H7V4ZM19 9H21V11H20V12H19V13H18V14H17V13H16V12V11V9V8V7H15V6V5H14V4H16V5H17V6H18V7H19V8V9Z" class="eo" fill="','<path d="M17 14H18V15H17V14Z" class="eo" fill="black','<path d="M11 3H10V5H9V4H8V5H9V6H7V4H6V6H5V7V8V9H4V8H3V9H4V10H5V11V12H4V13H5V14H4V15H5V16H6V17H7V16V15H6V14V13V12H7V11H8V10V9H9V8H14V9H16V10V11V12H17V13V17H18V15H19V14H18V13H19V12H20V11H19V10H20V9H17V8H19V7H17V6H20V5H17V6H16V5V4H15V5H13V3H12V5H11V3ZM7 7H6V6H7V7ZM7 7H8V8H7V7Z" class="eo" fill="','<path d="M7 2H8V3H9V4H10V3H11H12V2H13V3H14V4H13V5H14V4H15H16V3H17V5H18V6H19H20V7H19V8H18H17V9H16V8H15V9H14V8H13V9H12V8H11H10V9H9V10H8V9H7H6V11H5V14H4V12H3V10H4V8H3H2V6H3V7H4H5V6H4V5H5H6V3H7V2ZM4 14V15H3V14H4Z" class="eo" fill="','<rect x="5" y="11" width="1" height="1" fill="black','<path d="M10 4H9H8V5H7V6H6V7H5V12H4V16H5V18H7V19H8V18V16V12H9V11H10V10H11V12H12V13H13V12H14V11H15H16V19H17V18H18V17H19V12H18V7H17V6H16V5H15V4H14H13H12H11H10Z" class="eo" fill="','<path d="M10 5H9V6H8V7H9V6H10V5Z" fill-opacity="0.17" class="eo" fill="white','<path d="M8 3H9H10H11H12H13H14H15V4H16V5H17V6H18V10H17V11H16V10H15H14V11H13V12H12V11H11V9H10V10H9V11H8V14H7V15H6H5V6H6V5H7V4H8V3Z" class="eo" fill="','<path d="M10 4H9V5H8V6H9V5H10V4Z" fill-opacity="0.17" class="eo" fill="white','<path d="M12 5H9V6H7V7H6V8H5V9V10V11H4V13V19H3V22H4H8V24H9V18H8V13H9V11V10H10V9H11V8H15V7H13V6H12V5Z" class="eo" fill="','<path d="M15 6H9V7H8V8H7V9V10H17V9V8H16V7H15V6Z" class="eo" fill="','<path d="M9 5H15V6H9V5ZM8 7V6H9V7H8ZM7 8V7H8V8H7ZM7 8V10H6V8H7ZM16 7H15V6H16V7ZM17 8V7H16V8H17ZM17 8V10H18V8H17Z" class="eo" fill="black','<path d="M17 8H7V9V10H8V9H9V10H10V9H11V10H12V9H13V10H14V9H15V10H16V9H17V8Z" fill-opacity="0.3" class="eo" fill="black','<path d="M15 6H8V7H7V8H6V9V10H17V9V8H16V7H15V6Z" class="eo" fill="','<path d="M8 5H15V6H8V5ZM7 7V6H8V7H7ZM6 8V7H7V8H6ZM6 8V10H5V8H6ZM16 7H15V6H16V7ZM17 8V7H16V8H17ZM17 8V10H18V8H17Z" class="eo" fill="black','<path d="M6 8H17V9V10H16V9H15V10H14V9H13V10H12V9H11V10H10V9H9V10H8V9H7V10H6V9V8Z" fill-opacity="0.3" class="eo" fill="black','<path d="M14 4H8V5H7V6H6V7H5V8H6V9H5V10H7V11V12H8V11H9V10H10V9H12V11H13V9V8H14V9H15V10H18V9H17V8V7H18V6H16V5V4H15V5H14V4ZM9 10H8V9H9V10Z" class="eo" fill="','<path d="M9 4H8V5H7V6H6V7H5V8H6V9H5V10H6V12H7V10H8V11H9V10H10V9H12V11H13V8H14V9H15V10H16V12H17V10H18V9H17V7H18V6H17H16V4H15V5H14V4H13H12H10H9ZM9 10H8V9H9V10Z" class="eo" fill="','<path d="M14 4H13V5H12V6H11V7H10V8H12V9H13V10H14V9V8V7V6V5V4Z" class="eo" fill="','<path d="M13 3H15V4V7H14V4H13V3ZM12 5V4H13V5H12ZM11 6V5H12V6H11ZM11 6V7H10V6H11Z" class="eo" fill="black','<path d="M12 6H11V7H10V8H11V7H12V6Z" fill-opacity="0.25" class="eo" fill="black','<path d="M13 2H12V3H11V4H10V5H9V6H11V7H12V8H13V7V6V5V4V3V2Z" class="eo" fill="','<path d="M12 1H14V2V5H13V2H12V1ZM11 3V2H12V3H11ZM10 4V3H11V4H10ZM10 4V5H9V4H10Z" class="eo" fill="black','<path d="M11 4H10V5H9V6H10V5H11V4Z" fill-opacity="0.25" class="eo" fill="black','<path d="M10 6H14V7H16V8H17V10H18V15H19V22H18H17V23H16H15H14V21H15V20H16V11H15V10H14V11H13V10H9V11H8V13H7V15H6V11H7V8H8V7H9H10V6Z" class="eo" fill="','<path d="M15 5H9V6H8V8H7V7H6V6H4V7H3V8H2V9V10V12H3V13H4V12H5V10H6V9H7V10V11V12H8V11H9V10H10V9H15V10H16V11H17V10V9H18V10H19V12H20V13H21V12H22V10V9V8H21V7H20V6H18V7H17V8H16V6H15V5Z" class="eo" fill="','<path d="M8 7H7V8H8V7ZM17 7H16V8H17V7Z" class="eo" fill="'][partIndex + i];
    }
    return AssetData({
      parts: parts,
      name: ['None','Solid','Solid','Hacker','Hacker','Flag','Regular','Regular','Alien','Zombie','Ape','Albino','Albino','Light Spots','Rosy Cheeks','Rosy Cheeks','Mole','Mole','Spots','Spots','Earring','Earring','Pink with Hat','Basker','Basker','Blonde Short','Blonde Bob','Cap','Cap','Clown Hair','Clown Hair','Crazy Hair','Crazy Hair','Frumpy Hair','Frumpy Hair','Half Shaved','Knitted Cap','Knitted Cap','Messy Hair','Messy Hair','Mohawk','Mohawk','Orange Side','Pig Tails'][index],
      fillLength: [uint8(0),1,1,1,1,0,1,1,1,1,2,1,1,0,0,0,0,0,0,0,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2][index],
      length: length
    });
  }
    
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AssetData } from './libraries/MYP.sol';
import { IMYPAssetStorage } from './interfaces/IMYPAssets.sol';

/**
................................................
................................................
................................................
................................................
...................';::::::;'.';'...............
.............';'.':kNWWWWWWNkcod;...............
.............oXkckNWMMMMMMMMWNkc'.';'...........
.........'::ckWWWWMMMMMMMMMMMMWNkcoxo:'.........
.........;xKWWMMMMWXKNMMMMMMMMMMWNklkXo.........
.........'cOWMMMMN0kxk0XWWXK0KNWMMWWKk:.........
.......':okKWMMMWOldkdlkNNkcccd0NMMWOc'.........
.......;dolOWMWX0d:;::ckXXkc:;;:lkKWKko:'.......
.......':okKWN0dc,.',;:dOOkd:.''..lNOlod:.......
.....':kNklONx;;:,.';:::ccdkc.',. lWMNo.........
.....:xkOKWWWl..:::::::::::c:::;. lWMWk:'.......
.........dWMWl .:::::::;;;;:::::. lNXOkx;.......
. .....':okkk; .;::::::,'',:::::. ;xdc'.........
.......:d:...  .;::::;,,,,,,;:::.  .:d:.........
.. ..........  .';:::,'....',:;'.  .............
..............   .,,,;::::::;'.    .............
..............    .  .''''''.   ................
..............   ....          .................
..............   .;,....    . ..................
..............   .;:::;.    ....................

               Made with <3 from
             @author @goldendilemma

*/

contract MYPAssetsB is IMYPAssetStorage {

  function getAssetFromIndex (uint index)
  external override pure
  returns (AssetData memory)
  {
    uint16 partIndex = [uint16(0),3,4,5,6,7,10,12,13,14,15,16,22,25,27,29,31,34,36,38,40,42,43,48,49,51,53,54,55,56,57,58,59,60,61,62,63,64,65,66,68,69,70,71][index];
    uint8 length = [uint8(3),1,1,1,1,3,2,1,1,1,1,6,3,2,2,2,3,2,2,2,2,1,5,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,2][index];
    
    string[8] memory parts;
    for (uint i = 0; i < length; i++) {
      parts[i] = ['<path d="M15 5H9V6H15V5ZM11 9H13V10H16H17V20H16V11H8V21H7V15H6V11H7V10H8H11V9Z" class="eo" fill="','<path d="M16 6H8V7H7V9V10H10H11V9H13V10H14H17V9V7H16V6ZM16 7V9H14V8H13V7H16ZM10 9V8H11V7H8V9H10Z" class="eo" fill="','<path d="M11 7H8V8V9H10V8H11V7ZM13 7H16V8V9H14V8H13V7Z" class="eo" fill="','<path d="M13 4H12V5H11V6H10V7H11V8H12H13V4Z" class="eo" fill="','<path d="M10 7H9V8H8V9H7V10H6V13H5V23H6H7H8V13H9V11H10V10H15V11H16V18H15V21H14V22H13V23H14H15H16V22H17V9H16V8H15V7H10Z" class="eo" fill="','<path d="M11 8H10V9H9V10H8V11H9V10H10V11H11V10H12V11H13V10H14V11H15V10H16V9H15V8H14V9H13V8H12V9H11V8ZM12 9H13V10H12V9ZM14 9H15V10H14V9ZM11 9V10H10V9H11Z" class="eo" fill="','<path d="M9 6H10V8H9V6ZM9 8V10H8V8H9ZM11 8H10V9H11V10H12V9H11V8ZM11 8V6H12V8H11ZM14 6H13V8H14V10H15V8H14V6Z" class="eo" fill="','<path d="M13 3H12V4H11V5H10V6H9V7H8V8H9V9H8V10H7V19H6V20H7V21H8V20H9V19H8V11H9V10H15V11H16V19H15V20H16V21H17V20H18V19H17V9H16V8H15V7H14V6H13V5H14V4H13V3ZM12 5H13V4H12V5ZM12 6V5H11V6H10V7H9V8H10V9H11V8H12V9H13V8H14V9H15V10H16V9H15V8H14V7H13V6H12ZM12 7V6H11V7H10V8H11V7H12ZM12 7V8H13V7H12Z" class="eo" fill="','<path d="M12 3H11V4H10V5H11V6H10V7H9V8H8V9H7V10H8V9H9V8H10V9H11V8H12V9H13V8H14V9H15V10H16V9H15V8H16V7H15V6H14V5H13V4H12V3ZM12 5V4H11V5H12ZM12 6V5H13V6H12ZM12 7V6H11V7H10V8H11V7H12ZM13 7H12V8H13V7ZM14 7V6H13V7H14ZM14 7V8H15V7H14Z" class="eo" fill="','<path d="M11 2H13V3H11V2ZM10 4V3H11V4H10ZM9 6V4H10V6H9ZM8 7V6H9V7H8ZM7 9V7H8V9H7ZM6 19V9H7V19H6ZM6 20H5V19H6V20ZM7 21H6V20H7V21ZM8 21V22H7V21H8ZM8 21V20H9V21H8ZM14 4H13V3H14V4ZM15 6H14V4H15V6ZM16 7H15V6H16V7ZM17 9H16V7H17V9ZM18 19H17V9H18V19ZM18 20V19H19V20H18ZM17 21V20H18V21H17ZM16 21V22H17V21H16ZM16 21H15V20H16V21Z" class="eo" fill="black','<path d="M12 8H9V9H12V10H11V11H12V12H13V11H14V10H13V9H15V8H13V9H12V8ZM13 10V11H12V10H13Z" class="eo" fill="','<rect x="12" y="10" width="1" height="1" fill="','<path d="M12 3H11V4H12V5V6H11V5H10V4H8V5H6V6H5V7H4V8H3V9H5V10H4V11H3V12H4V13H3V14H4V15H3V16H4V17V18H5V19H6V18H7V17H8V16H7V15H6V14V13V12H8V11V10H10V11H11V10H10V9H14V10V11H13V12H14V11H15V10H16V11H17V12V14V15V16H16V17H17V16H18V18H19H20V17H19V16H20V15V14H21V12H20V11H21V10H20V9H18V8H19V7H21V6H17V5H18V4H17V5H16V4V3H14V4H12V3ZM20 10V11H19V10H20ZM19 16V15H18V16H19ZM16 6H15V7H16V6ZM9 6H8V7H9V6ZM6 8V7H7V8H6ZM5 17V16H6V17H5Z" class="eo" fill="','<path d="M14 2H15V3H14V2ZM19 5H18V6H17V5V4V3H16V4H14V3H13V4H12V5H11V4H10V3H9V5H8V4H7V3H6V4H5V5V6H4V5H3V6H4V7H3V8H4V9H3V10H2V11H4V12H3V13V14H4V16H5V15H6V17H5V18H6V17H7V19H8V17V14V12V11H9V10H11V11H12H13V10H12V9H14V10H15V11H16V15V18V19H17V18H18V19H19V18H18V15H19H20V14H19V12H20V11H19V10H18V9H19V8H20V7H19V6V5ZM19 5V4H20V5H19ZM4 14V13H5V14H4ZM6 4V5H7V4H6Z" class="eo" fill="','<path d="M8 3H6V4V5H4V4H3V5V6V7H4V8H3V9H2V10H4V11H3V12V13H4V14V15H7V14H8V13V12V11V10H9V9H11V10H13V9H12V8H14V9H15V10H17V11V12V15H18V12H19V11V10H18V9H19V8V7H20V6H19V5H20V4H18V5H16V4H17V3H12V4H8V3ZM4 13V12H5V13H4Z" class="eo" fill="','<path d="M10 5H14V6H15V7H16V8H17V9H18V8H19V10H18V11H19V12H18V13H19V15H20V16H19H18V17H17V12H16V11H15V10H13V13H12V10H11V9H10V10H9V11V12H8V13H7V14V17H5V15H3V14H4V13H5V14H6V13H5V12H6V11H5V10H6V9H5V8H7V7V6H8V7H9V6H10V5ZM5 11H4V12H5V11ZM5 17V18H4V17H5ZM10 10H11V11H10V10ZM13 13H14V14H13V13ZM18 17V18H19V17H18ZM19 13V12H20V13H19ZM18 8H17V7H18V8ZM15 6V5H16V6H15Z" class="eo" fill="','<path d="M8 5H9H10V7H9V8H8V9H7H6V7H7V6H8V5Z" class="eo" fill="','<path d="M11 5H10V7H9V8H8V9H9H10H11H13H14H15V8H14V7H13V5H11Z" class="eo" fill="','<path d="M14 5H13V7H14V8H15V9H16H17V7H16V6H15V5H14Z" class="eo" fill="','<rect x="9" y="3" width="5" height="1" fill="','<rect x="8" y="9" width="7" height="1" fill="','<rect x="11" y="4" width="1" height="1" fill="black','<path d="M8 5H15V6H16V7H10V8H9V9H7V8V7V6H8V5ZM10 8V9H18V8H10Z" class="eo" fill="','<path d="M8 4H15V5H8V4ZM7 6V5H8V6H7ZM9 9H7V6H6V9V10H19V9V8H18V7H17V6H16V5H15V6H16V7H10V8H9V9ZM10 9H18V8H10V9Z" class="eo" fill="black','<path d="M8 5H9V6H8V5ZM8 6V7H7V6H8ZM18 8H10V9H18V8Z" fill-opacity="0.35" class="eo" fill="black','<path d="M10 3H8V4H7V7H6V8H3V7H2V8V9H3V10H20V9H21V8V7H20V8H17V7H16V4H15V3H13V4H10V3Z" class="eo" fill="','<rect x="6" y="7" width="11" height="1" fill-opacity="0.43" fill="black','<path d="M15 6H8V7H7V8V9V10H16V9V8V7H15V6Z" class="eo" fill="','<path d="M10 7H9V8H8V9H9V8H10V7Z" fill-opacity="0.12" class="eo" fill="white','<path d="M9 3H14V4H15V5V6H16V7H17V8H19V9H20V10H3V9H4V8H6V7H7V6H8V5V4H9V3Z" class="eo" fill="','<rect x="6" y="7" width="11" height="1" fill="','<path d="M16 7H8V8H7V9H6V10H5V15H4V20H5V22H6H7H8V19H7V12H8V9H16V20H15V21H14V22H15H16H17H18V21H19V19H20V15H19V10H18V9H17V8H16V7Z" class="eo" fill="','<rect x="8" y="9" width="8" height="1" fill="','<rect x="8" y="10" width="8" height="1" fill="','<rect x="7" y="7" width="9" height="1" fill="','<rect x="7" y="8" width="9" height="1" fill="','<path d="M10 4H13V5H15V6H16V7H17V8H18V9V10V11H19V14H18V12H17V10H16V9H15V8H8V9H7V10H6V12H5V14H4V11H5V10V9V8H6V7H7V6H8V5H10V4ZM4 19H3V14H4V19ZM5 21H4V19H5V21ZM5 21H6V24H5V21ZM19 19H20V14H19V19ZM18 20V19H19V20H18ZM17 21H18V20H17V21ZM16 22V21H17V22H16ZM13 23V22H16V23H13ZM13 23H12V24H13V23Z" class="eo" fill="','<path d="M13 3H10V4H8V5H7V6H6V7H5V8H4V11H3V14H2V19H3V21H4V24H5V21H6V14V12H7V10H8V9H15V10H16V11V12H17V20H16V21H15V22H16V23H13V22H12H11V23V24H12V23H13V24H16V23H17V22H18V21H19V20H20V19H21V14H20V11H19V8H18V7H17V6H16V5H15V4H13V3ZM13 4V5H15V6H16V7H17V8H18V11H19V14H18V12H17V11V10H16V9H15V8H8V9H7V10H6V12H5V14H4V11H5V8H6V7H7V6H8V5H10V4H13ZM4 19H3V14H4V19ZM19 19V20H18V19H19ZM19 19H20V14H19V19ZM17 21V20H18V21H17ZM17 21V22H16V21H17ZM4 19H5V21H4V19Z" class="eo" fill="black','<rect x="12" y="4" width="1" height="5" fill="','<path d="M13 3H12V4H11V9H12V4H13V9H14V4H13V3Z" class="eo" fill="black','<rect x="11" y="2" width="1" height="5" fill="','<path d="M12 1H11V2H10V7H11V2H12V7H13V2H12V1Z" class="eo" fill="black','<path d="M10 1H9V2H8V3V4H7V5V6H10V7H11V8H12V7H13V6H16V5V4H15V3V2H14V1H13V2H12V1H11V2H10V1Z" class="eo" fill="','<path d="M10 4H13V5H17V7H6V5H10V4ZM17 9V8H9V9H17Z" class="eo" fill="','<rect x="11" y="5" width="1" height="1" fill="','<path d="M7 7H8V8H7V7ZM9 7H10V8H9V7ZM12 7H11V8H12V7ZM13 7H14V8H13V7ZM16 7H15V8H16V7Z" class="eo" fill="','<path d="M8 7H9V8H8V7ZM10 7H11V8H10V7ZM13 7H12V8H13V7ZM14 7H15V8H14V7ZM17 7H16V8H17V7Z" class="eo" fill="','<path d="M13 3H10V4H6V5H5V7H6V8V9H9V10H17H18V8H17V9H9V8H7V7H6V5H10V4H13V5H17V7H18V5H17V4H13V3Z" class="eo" fill="black','<path d="M10 3H9V4H8V5H7V4H6V5H4V6H5V7H3V8H4V9H2V10H4V11H2V12H3V13H2V14H4V15H3V16H5V17H4V18H5V19H6V18V17V16V15V14H5V13V12H7V11V10H8V9H9V8H15V9H16V10H17V9V8V7H16V6H15V5H14V4H12V3H11V4H10V3Z" class="eo" fill="','<path d="M8 6H9H10H11H12H13H14H15V7H16V10H15V9H14H13H12H11H10H9H8V10H7V7H8V6Z" class="eo" fill="','<path d="M10 7H9V8H8V9H9V8H10V7Z" fill-opacity="0.2" class="eo" fill="white','<path d="M16 1H7V2H6V6H17V2H16V1ZM18 7H5V8H4V9H19V8H18V7Z" class="eo" fill="','<rect x="6" y="6" width="11" height="1" fill="','<path d="M9 6H8V7H7V10H8V8H9V7H11V8H12V10H13V8H14V7H15V8H16V7H15V6H14H13H12H11H9ZM7 16H8V18H9V19H8H7V16Z" class="eo" fill="','<path d="M9 20H10V21H11V22H12V23H11H10V22H9V20Z" class="eo" fill="','<path d="M7 22H8H9H10V23H9H8H7V22Z" class="eo" fill="','<path d="M9 22H10H11H12V23H11H10H9V22Z" class="eo" fill="','<path d="M7 20H8V21H7V20ZM9 22V21H8V22H9ZM9 22V23H10V22H9Z" class="eo" fill="','<rect x="12" y="15" width="2" height="2" fill="','<rect x="12" y="14" width="2" height="2" fill="','<rect x="12" y="14" width="1" height="3" fill-opacity="0.12" fill="black','<path d="M12 15H11V16H12V15ZM14 15H13V16H14V15Z" class="eo" fill="','<rect x="12" y="16" width="1" height="1" fill="','<rect x="12" y="15" width="2" height="1" fill="','<rect x="11" y="18" width="3" height="1" fill="','<rect x="11" y="18" width="3" height="1" fill="','<rect x="12" y="18" width="1" height="1" fill="','<path d="M12 18H11V19H12V18ZM14 18H13V19H14V18Z" class="eo" fill="','<path d="M14 18H11V19H10V20H11V19H14V18Z" class="eo" fill="','<path d="M11 17H10V18H11V19H14V18H11V17Z" class="eo" fill="','<rect x="10" y="18" width="5" height="1" fill="','<path d="M7 13H8V14H7V13ZM9 15H8V14H9V15ZM15 15H9V18H8V19H9V20H10V21H14V20H15V19H16V18H15V15ZM15 15V14H16V15H15Z" class="eo" fill="','<path d="M12 15H13V16H12V15ZM9 17H10V18H9V17ZM15 17H14V18H15V17Z" fill-opacity="0.12" class="eo" fill="black'][partIndex + i];
    }
    return AssetData({
      parts: parts,
      name: ['Pilot Helmet','Red Mohawk','Straight Hair','Stringy Hair','Stringy Hair','Tassle Hat','Tiara','Wild Blonde','Wild Hair','Wild Hair','Wild White Hair','Beanie','Cap Forward','Cowboy Hat','Do-Rag','Fedora','Headband','Headband','Hoodie','Mohawk Thin','Mohawk Thin','Peak Spike','Police Cap','Purple Hair','Shaved Head','Top Hat','Vampire Hair','Choker','Silver Chain','Gold Chain','Gold Chain','Clown Nose','Clown Nose','Alien Nose','Ape Nose','Regular','Regular','Regular','Regular','Buck Teeth','Frown','Smile','Long','Medical Mask'][index],
      fillLength: [uint8(3),1,1,1,1,2,2,1,1,1,1,5,1,1,1,2,3,2,1,1,1,1,4,1,1,2,1,1,1,1,1,1,1,0,1,1,1,1,1,2,1,1,1,1][index],
      length: length
    });
  }
  
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AssetData } from './libraries/MYP.sol';
import { IMYPAssetStorage } from './interfaces/IMYPAssets.sol';

/**
................................................
................................................
................................................
................................................
...................';::::::;'.';'...............
.............';'.':kNWWWWWWNkcod;...............
.............oXkckNWMMMMMMMMWNkc'.';'...........
.........'::ckWWWWMMMMMMMMMMMMWNkcoxo:'.........
.........;xKWWMMMMWXKNMMMMMMMMMMWNklkXo.........
.........'cOWMMMMN0kxk0XWWXK0KNWMMWWKk:.........
.......':okKWMMMWOldkdlkNNkcccd0NMMWOc'.........
.......;dolOWMWX0d:;::ckXXkc:;;:lkKWKko:'.......
.......':okKWN0dc,.',;:dOOkd:.''..lNOlod:.......
.....':kNklONx;;:,.';:::ccdkc.',. lWMNo.........
.....:xkOKWWWl..:::::::::::c:::;. lWMWk:'.......
.........dWMWl .:::::::;;;;:::::. lNXOkx;.......
. .....':okkk; .;::::::,'',:::::. ;xdc'.........
.......:d:...  .;::::;,,,,,,;:::.  .:d:.........
.. ..........  .';:::,'....',:;'.  .............
..............   .,,,;::::::;'.    .............
..............    .  .''''''.   ................
..............   ....          .................
..............   .;,....    . ..................
..............   .;:::;.    ....................

               Made with <3 from
             @author @goldendilemma

*/

contract MYPAssetsC is IMYPAssetStorage {

  function getAssetFromIndex (uint index)
  external override pure
  returns (AssetData memory)
  {
    uint16 partIndex = [uint16(0),2,4,6,7,8,10,12,13,14,17,18,22,26,30,34,37,40,44,48,51,54,56,59,62,65,68,71,75,79,82,85,86,87,88,89,91,93,95,97,98,99,100,104][index];
    uint8 length = [uint8(2),2,2,1,1,2,2,1,1,3,1,4,4,4,4,3,3,4,4,3,3,2,3,3,3,3,3,4,4,3,3,1,1,1,1,2,2,2,2,1,1,1,4,4][index];
    
    string[8] memory parts;
    for (uint i = 0; i < length; i++) {
      parts[i] = ['<path d="M7 12H6V13H7V14H8V15H9V18H8H7V19H8H9V20H10V21H14V20H15V19H16V18H15V15H16V14H15V15H9V14H8V13H7V12Z" class="eo" fill="','<path d="M12 15H13V16H12V15ZM9 17H10V18H9V17ZM15 17H14V18H15V17Z" fill-opacity="0.12" class="eo" fill="black','<path d="M16 16H9V17H7V18H6V19V20V21H8V22H11V23H16V22H17V21V20V19V18V17H16V16ZM14 19H11V18H14V19Z" class="eo" fill="','<path d="M16 16H17V17H16V16ZM17 22V17H18V22H17ZM16 23H17V22H16V23ZM8 22H11V23H16V24H10V23H8V22ZM6 21H8V22H6V21ZM6 18V21H5V18H6ZM6 18V17H7V18H6Z" class="eo" fill="black','<path d="M8 15H7V18H8V20H9V21H10H11V22H14V21H15V20H16V16H15V20H10V18H9V16H8V15Z" class="eo" fill="','<path d="M17 19H16V20H15V21H14V22H11V21H10V22H11V23H14V22H15V21H16V20H17V19Z" class="eo" fill="black','<path d="M10 17H15V18V19V20H14V22H11V20H10V18V17ZM11 18H14V19H11V18Z" class="eo" fill="','<path d="M14 20H11V22H12V23H13V22H14V20Z" class="eo" fill="','<path d="M15 17H10V18V20H11V18H14V20H15V18V17Z" class="eo" fill="','<path d="M11 17H10V18H11V17ZM15 17H14V18H15V17Z" fill-opacity="0.22" class="eo" fill="white','<path d="M8 15H7V20H8V22H9V23H10V22H11H14H15V20H16V16H15V17H14H11H10V16H9H8V15ZM11 18V19H14V18H11Z" class="eo" fill="','<path d="M6 14H7V20H6V14ZM10 22H15V23H10V22ZM16 20H15V21V22H16V21V20ZM16 20V15H17V20H16Z" class="eo" fill="black','<rect x="10" y="17" width="5" height="1" fill-opacity="0.58" fill="','<path d="M8 15H7V18H8V19H9H10V17H9V16H8V15ZM16 16H15V19H16V16Z" class="eo" fill="','<path d="M8 15H7V19H8V20H9V21H10H11H14H15V20H16V16H15V17H14H11H10H9V16H8V15ZM14 18V19H11V18H14Z" class="eo" fill="','<rect x="11" y="18" width="3" height="1" fill="','<path d="M16 16H17V20H16V16ZM15 21H16V20H15V21ZM15 21V22H10V21H15Z" class="eo" fill="black','<path d="M7 15H8V16H9V17H11H14H15V16H16V20H15V21H14H11H9V20H8V19H7V15ZM11 18H14V19H11V18Z" fill-opacity="0.28" class="eo" fill="','<rect x="14" y="18" width="5" height="1" fill="','<rect x="19" y="18" width="1" height="1" fill="','<rect x="19" y="10" width="1" height="6" fill-opacity="0.58" fill="','<path d="M20 17H14V18H13V19H14V20H20V19H21V18H20V17ZM20 18V19H14V18H20Z" class="eo" fill="black','<rect x="14" y="18" width="5" height="1" fill="','<rect x="19" y="18" width="1" height="1" fill="','<rect x="19" y="10" width="1" height="6" fill-opacity="0.58" fill="','<path d="M20 17H14V18H13V19H14V20H20V19H21V18H20V17ZM20 18V19H14V18H20Z" class="eo" fill="black','<path d="M14 19H15V20H14V19ZM16 21H15V20H16V21ZM17 22H16V21H17V22ZM19 22H17V23H21V22H22V20H19V22Z" class="eo" fill="','<path d="M21 11H20V12H19V14H22V12H21V11ZM21 15H20V16H21V15ZM21 17H20V18H21V17Z" fill-opacity="0.58" class="eo" fill="','<path d="M15 18H14V19H13V20H14V21H15V22H16V23H17V24H21V23H22V22H23V20V19H18V20V21H17V20H16V19H15V18ZM15 20H14V19H15V20ZM16 21H15V20H16V21ZM17 22H16V21H17V22ZM17 22H18H19V20H22V22H21V23H17V22Z" class="eo" fill="black','<path d="M19 21H20V22H19V21ZM21 22H20V23H21V22ZM21 22V21H22V22H21Z" fill-opacity="0.18" class="eo" fill="black','<path d="M14 19H15V20H14V19ZM16 21H15V20H16V21ZM17 22H16V21H17V22ZM19 22H17V23H21V22H22V20H19V22Z" class="eo" fill="','<path d="M21 11H20V12H19V14H22V12H21V11ZM21 15H20V16H21V15ZM21 17H20V18H21V17Z" fill-opacity="0.58" class="eo" fill="','<path d="M15 18H14V19H13V20H14V21H15V22H16V23H17V24H21V23H22V22H23V20V19H18V20V21H17V20H16V19H15V18ZM15 20H14V19H15V20ZM16 21H15V20H16V21ZM17 22H16V21H17V22ZM17 22H18H19V20H22V22H21V23H17V22Z" class="eo" fill="black','<path d="M19 21H20V22H19V21ZM21 22H20V23H21V22ZM21 22V21H22V22H21Z" fill-opacity="0.18" class="eo" fill="black','<rect x="14" y="18" width="5" height="1" fill="','<rect x="19" y="18" width="1" height="1" fill="','<path d="M21 17H14V18H13V19H14V20H21V19V18V17ZM20 19H14V18H20V19Z" class="eo" fill="black','<rect x="14" y="18" width="5" height="1" fill="','<rect x="19" y="18" width="1" height="1" fill="','<path d="M21 17H14V18H13V19H14V20H21V19V18V17ZM20 19H14V18H20V19Z" class="eo" fill="black','<path d="M11 12H9V14H11V12ZM16 12H14V14H16V12Z" class="eo" fill="','<path d="M10 13H9V14H10V13ZM15 13H14V14H15V13Z" class="eo" fill="black','<path d="M11 12H9V13H11V12ZM16 12H14V13H16V12Z" fill-opacity="0.33" class="eo" fill="black','<path d="M11 13H10V14H11V13ZM16 13H15V14H16V13Z" fill-opacity="0.14" class="eo" fill="black','<path d="M11 11H9V13H11V11ZM16 11H14V13H16V11Z" class="eo" fill="','<path d="M11 11H9V12H11V11ZM16 11H14V12H16V11Z" fill-opacity="0.34" class="eo" fill="black','<path d="M11 12H10V13H11V12ZM16 12H15V13H16V12Z" fill-opacity="0.11" class="eo" fill="black','<path d="M10 12H9V13H10V12ZM15 12H14V13H15V12Z" class="eo" fill="black','<path d="M11 11H10V12H9V13H10V12H11V11ZM16 11H15V12H14V13H15V12H16V11Z" class="eo" fill="black','<path d="M10 11H9V12H10V11ZM15 11H14V12H15V11Z" fill-opacity="0.26" class="eo" fill="black','<path d="M11 12H10V13H11V12ZM16 12H15V13H16V12Z" fill-opacity="0.12" class="eo" fill="black','<path d="M10 12H9V13H10V12ZM15 12H14V13H15V12Z" class="eo" fill="black','<path d="M11 12H10V13H11V12ZM16 12H15V13H16V12Z" fill-opacity="0.39" class="eo" fill="white','<path d="M11 11H9V12H11V11ZM16 11H14V12H16V11Z" fill-opacity="0.25" class="eo" fill="black','<path d="M10 12H9V13H10V12ZM15 12H14V13H15V12Z" class="eo" fill="','<path d="M11 12H10V13H11V12ZM16 12H15V13H16V12Z" class="eo" fill="black','<path d="M9 11H10V12H11V14H10V13H9V11ZM10 14V15H9V14H10ZM15 14H14V15H15V14ZM15 13V14H16V12H15V11H14V13H15Z" class="eo" fill="','<path d="M11 12H9V13H11V12ZM16 12H14V13H16V12Z" fill-opacity="0.21" class="eo" fill="black','<path d="M11 13H10V14H11V13ZM16 13H15V14H16V13Z" fill-opacity="0.42" class="eo" fill="black','<path d="M9 10H10V11H11V13H10V12H9V10ZM10 13V14H9V13H10ZM15 13H14V14H15V13ZM15 12V13H16V11H15V10H14V12H15Z" class="eo" fill="','<path d="M11 11H9V12H11V11ZM16 11H14V12H16V11Z" fill-opacity="0.21" class="eo" fill="black','<path d="M11 12H10V13H11V12ZM16 12H15V13H16V12Z" fill-opacity="0.42" class="eo" fill="black','<path d="M8 7H9V8H8V7ZM8 8V10H9V11H8V12H7V8H8ZM12 7H11V8H12V10H11V11H12V10H13V11H14V10H13V8H14V7H13H12ZM16 10H17V12H16V10ZM17 7H16V8H17V7Z" class="eo" fill="','<path d="M11 7H9V8H8V10H9V11H11V10H12V8H11V7ZM11 8V10H9V8H11ZM13 8H14V10H13V8ZM16 10V11H14V10H16ZM16 8V7H14V8H16ZM16 8V10H17V8H16Z" class="eo" fill="','<path d="M11 8H9V10H11V8ZM16 8H14V10H16V8Z" class="eo" fill="','<path d="M8 11H7V13H8V15H9H16H17V12V11H9H8ZM12 14H9V12H12V14ZM13 14H16V12H13V14Z" class="eo" fill="','<rect x="9" y="12" width="3" height="2" fill="','<rect x="13" y="12" width="3" height="2" fill="','<path d="M6 10H7H8H9H17V11V14H16H9H8V12H7V11H6V10ZM13 13H16V11H13V13ZM12 13V11H9V13H12Z" class="eo" fill="','<rect x="9" y="11" width="3" height="2" fill="','<rect x="13" y="11" width="3" height="2" fill="','<path d="M12 11H7V12V13H6V14H7V15H8V16H11V15H12V13H13V15H14V16H17V15H18V12V11H13V12H12V11ZM17 15H14V12H17V15ZM11 15H8V12H11V15Z" class="eo" fill="','<path d="M11 12H8V15H11V12ZM17 12H14V15H17V12Z" class="eo" fill="','<path d="M11 12H8V14H11V12ZM17 12H14V14H17V12Z" fill-opacity="0.24" class="eo" fill="black','<path d="M11 12H8V13H11V12ZM17 12H14V13H17V12Z" fill-opacity="0.18" class="eo" fill="black','<path d="M12 9H7V10V11H6V12H7V13H8V14H11V13H12V11H13V13H14V14H17V13H18V10V9H13V10H12V9ZM17 13H14V10H17V13ZM11 13H8V10H11V13Z" class="eo" fill="','<path d="M11 10H8V13H11V10ZM17 10H14V13H17V10Z" class="eo" fill="','<path d="M11 10H8V12H11V10ZM17 10H14V12H17V10Z" fill-opacity="0.24" class="eo" fill="black','<path d="M11 10H8V11H11V10ZM17 10H14V11H17V10Z" fill-opacity="0.18" class="eo" fill="black','<path d="M7 11H17V12V14H16V12H14V14H13V12H12V14H11V12H9V14H8V12H7V11ZM9 14H11V15H9V14ZM14 14H16V15H14V14Z" class="eo" fill="','<path d="M11 12H9V14H11V12ZM16 12H14V14H16V12Z" class="eo" fill="','<path d="M11 12H9V13H11V12ZM16 12H14V13H16V12Z" fill-opacity="0.51" class="eo" fill="black','<path d="M6 10H17V11V13H16V11H14V13H13V11H12V13H11V11H9V13H8V11H6V10ZM9 13H11V14H9V13ZM14 13H16V14H14V13Z" class="eo" fill="','<path d="M11 11H9V13H11V11ZM16 11H14V13H16V11Z" class="eo" fill="','<path d="M11 11H9V12H11V11ZM16 11H14V12H16V11Z" fill-opacity="0.51" class="eo" fill="black','<path d="M7 11H16V12H12V14H11V15H9V14H8V12H7V11Z" class="eo" fill="','<path d="M16 10H7V11H8V12V13H9V14H11V13H12V12V11H16V10Z" class="eo" fill="','<path d="M7 11H8H9H16H17V15H16H9H8H7H6V13H7V11ZM14 12H16V14H14V12ZM9 14H11V12H9V14Z" class="eo" fill="','<path d="M9 10H7V12H6V14H7H9H16H17V10H16H9ZM14 11H16V13H14V11ZM9 13H11V11H9V13Z" class="eo" fill="','<path d="M17 11H7V12H11V13H13V12H17V11Z" class="eo" fill="','<path d="M11 12H8V15H11V12ZM16 12H13V15H16V12Z" fill-opacity="0.41" class="eo" fill="','<path d="M7 10H17H18V11V12H17V11H13V12H11V11H8V12H7V11V10Z" class="eo" fill="','<path d="M11 11H8V14H11V11ZM16 11H13V14H16V11Z" fill-opacity="0.41" class="eo" fill="','<path d="M9 11H8V12H7V13H8V14H9V15H11V14H12V13H13V14H14V15H16V14H17V12V11H14H13V12H12V11H9ZM16 14V12H14V14H16ZM11 14H9V12H11V14Z" class="eo" fill="','<path d="M11 12H9V14H11V12ZM16 12H14V14H16V12Z" class="eo" fill="','<path d="M9 10H8V11H6V12H8V14H9H12V13V12H13V14H14H17V13V10H16H14H13V11H12V10H11H9ZM14 11V13H16V11H14ZM9 11H11V13H9V11Z" class="eo" fill="','<path d="M11 11H9V13H11V11ZM16 11H14V13H16V11Z" class="eo" fill="','<path d="M6 11H17V12V13H16V14H14V13H13V12H12V13H11V14H9V13H8V12H6V11Z" class="eo" fill="','<path d="M5 11H18V12V13H17V14H15V13H14V12H12V13H11V14H9V13H8V12H5V11Z" class="eo" fill="','<path d="M7 11H16V12V14H14V12H11V14H9V12H7V11Z" class="eo" fill="','<path d="M17 12H8V13H7V15H8V16H17V15V13V12ZM16 13H9V15H16V13Z" class="eo" fill="','<rect x="9" y="13" width="7" height="2" fill="','<path d="M8 12H9V13H8V12ZM8 15H7V13H8V15ZM8 15H9V16H8V15ZM16 12H17V13H16V12ZM17 15H16V16H17V15Z" fill-opacity="0.23" class="eo" fill="black','<path d="M17 11H8V12H7V13H6V15H7V16H8V17H17V16H18V12H17V11ZM17 12V16H8V15H7V13H8V12H17Z" class="eo" fill="black','<path d="M17 10H8V11H7V13H8V14H17V13V11V10ZM16 11H9V13H16V11Z" class="eo" fill="','<rect x="9" y="11" width="7" height="2" fill="','<path d="M8 10H9V11H8V10ZM8 13H7V11H8V13ZM8 13H9V14H8V13ZM16 10H17V11H16V10ZM17 13H16V14H17V13Z" fill-opacity="0.23" class="eo" fill="black','<path d="M17 9H8V10H7V11H6V13H7V14H8V15H17V14H18V10H17V9ZM17 10V14H8V13H7V11H8V10H17Z" class="eo" fill="black'][partIndex + i];
    }
    return AssetData({
      parts: parts,
      name: ['Medical Mask','Big Beard','Chin Strap','Front Beard','Goat','Handlebars','Luxurious Beard','Mustache','Muttonchops','Normal Beard','Shadow Beard','Cigarette','Cigarette','Pipe','Pipe','Vape','Vape','Regular','Regular','Alien','Ape','Zombie','Clown Eyes','Clown Eyes','Welding Goggles','3D Glasses','3D Glasses','Big Shades','Big Shades','Classic Shades','Classic Shades','Eye Patch','Eye Patch','Face Mask','Face Mask','Horned Rim Glasses','Horned Rim Glasses','Nerd Glasses','Nerd Glasses','Regular Shades','Regular Shades','Small Shades','VR','VR'][index],
      fillLength: [uint8(1),1,1,1,1,1,1,1,1,2,1,3,3,2,2,2,2,1,1,0,0,1,1,1,3,3,3,2,2,2,2,1,1,1,1,2,2,2,2,1,1,1,2,2][index],
      length: length
    });
  }
  
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AssetData } from '../libraries/MYP.sol';

/**
................................................
................................................
................................................
................................................
...................';::::::;'.';'...............
.............';'.':kNWWWWWWNkcod;...............
.............oXkckNWMMMMMMMMWNkc'.';'...........
.........'::ckWWWWMMMMMMMMMMMMWNkcoxo:'.........
.........;xKWWMMMMWXKNMMMMMMMMMMWNklkXo.........
.........'cOWMMMMN0kxk0XWWXK0KNWMMWWKk:.........
.......':okKWMMMWOldkdlkNNkcccd0NMMWOc'.........
.......;dolOWMWX0d:;::ckXXkc:;;:lkKWKko:'.......
.......':okKWN0dc,.',;:dOOkd:.''..lNOlod:.......
.....':kNklONx;;:,.';:::ccdkc.',. lWMNo.........
.....:xkOKWWWl..:::::::::::c:::;. lWMWk:'.......
.........dWMWl .:::::::;;;;:::::. lNXOkx;.......
. .....':okkk; .;::::::,'',:::::. ;xdc'.........
.......:d:...  .;::::;,,,,,,;:::.  .:d:.........
.. ..........  .';:::,'....',:;'.  .............
..............   .,,,;::::::;'.    .............
..............    .  .''''''.   ................
..............   ....          .................
..............   .;,....    . ..................
..............   .;:::;.    ....................

               Made with <3 from
             @author @goldendilemma

*/

interface IMYPAssetStorage {

  function getAssetFromIndex (uint index)
  external pure
  returns (AssetData memory);
  
}